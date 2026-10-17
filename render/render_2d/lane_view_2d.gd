class_name LaneView2D
extends Node2D
## Draws one lane top-down: the maze during the build phase, or a live battle.
##
## Only reads sim state. Creeps and shots are interpolated between ticks with
## `interpolation_alpha`, and shots travel so they reach the target on their land tick.

const CELL_SIZE: int = 24

## Cell under the build cursor, or (-1, -1) for none.
var cursor_cell: Vector2i = Vector2i(-1, -1)
## Whether placing at the cursor would be accepted.
var cursor_ok: bool = true
## Fraction of a tick since the last sim step, set by the owner every frame.
var interpolation_alpha: float = 0.0

var _grid: LaneGrid
var _player: PlayerState
var _battle: LaneBattle
var _previous_positions: Dictionary[int, Vector2] = {}
var _current_positions: Dictionary[int, Vector2] = {}


## Shows `player`'s maze for building.
func show_build(player: PlayerState) -> void:
	_grid = player.grid
	_player = player
	_battle = null
	queue_redraw()


## Shows a battle in progress on `battle`'s lane.
func show_battle(battle: LaneBattle) -> void:
	_grid = battle.grid
	_player = null
	_battle = battle
	_previous_positions.clear()
	_current_positions.clear()
	cursor_cell = Vector2i(-1, -1)
	on_ticked()


## Records creep positions after a sim tick so the next frames can interpolate.
func on_ticked() -> void:
	_previous_positions = _current_positions
	_current_positions = {}
	if _battle != null:
		for creep: CreepState in _battle.creeps:
			_current_positions[creep.id] = _milli_to_pixels(creep.position())
	queue_redraw()


## Size of the lane in pixels.
func lane_pixel_size() -> Vector2:
	if _grid == null:
		return Vector2.ZERO
	return Vector2(_grid.lane.size * CELL_SIZE)


## The cell at a global screen position, or (-1, -1) if it is outside the lane.
func screen_to_cell(screen_position: Vector2) -> Vector2i:
	if _grid == null:
		return Vector2i(-1, -1)
	var local := to_local(screen_position)
	var cell := Vector2i(floori(local.x / CELL_SIZE), floori(local.y / CELL_SIZE))
	return cell if _grid.lane.contains(cell) else Vector2i(-1, -1)


func _process(_delta: float) -> void:
	if _battle != null:
		queue_redraw()


func _draw() -> void:
	if _grid == null:
		return
	_draw_ground()
	if _player != null:
		_draw_paths()
		for tower: PlacedTower in _player.towers.values():
			_draw_tower(tower.def, tower.cell)
		_draw_cursor()
	if _battle != null:
		for tower: TowerState in _battle.towers:
			_draw_tower(tower.def, tower.cell)
		for creep: CreepState in _battle.creeps:
			_draw_creep(creep)
		for shot: Shot in _battle.shots:
			_draw_shot(shot)


func _draw_ground() -> void:
	var lane := _grid.lane
	draw_rect(Rect2(Vector2.ZERO, lane_pixel_size()), Palette2D.GROUND)
	for cell: Vector2i in lane.spawn_cells:
		draw_rect(_cell_rect(cell), Palette2D.SPAWN)
	for cell: Vector2i in lane.exit_cells:
		draw_rect(_cell_rect(cell), Palette2D.EXIT)
	for x: int in range(lane.size.x + 1):
		draw_line(
			Vector2(x * CELL_SIZE, 0),
			Vector2(x * CELL_SIZE, lane_pixel_size().y),
			Palette2D.GRID_LINE
		)
	for y: int in range(lane.size.y + 1):
		draw_line(
			Vector2(0, y * CELL_SIZE),
			Vector2(lane_pixel_size().x, y * CELL_SIZE),
			Palette2D.GRID_LINE
		)


func _draw_paths() -> void:
	for spawn: Vector2i in _grid.lane.spawn_cells:
		var points := PackedVector2Array()
		for cell: Vector2i in _grid.path_to_exit(spawn):
			points.append(_cell_center(cell))
		if points.size() >= 2:
			draw_polyline(points, Palette2D.PATH, 2.0)


func _draw_tower(def: TowerDef, cell: Vector2i) -> void:
	draw_rect(_cell_rect(cell).grow(-2), Palette2D.tower(def.id))


func _draw_cursor() -> void:
	if not _grid.lane.contains(cursor_cell):
		return
	var color := Palette2D.CURSOR_OK if cursor_ok else Palette2D.CURSOR_BAD
	draw_rect(_cell_rect(cursor_cell), color, false, 2.0)


func _draw_creep(creep: CreepState) -> void:
	var center := _creep_position(creep.id)
	var radius := CELL_SIZE * 0.3
	draw_circle(center, radius, Palette2D.creep(creep.def.id))
	if creep.is_slowed():
		draw_arc(center, radius + 2, 0, TAU, 16, Palette2D.SLOWED, 1.5)
	var bar := Rect2(center + Vector2(-radius, -radius - 5), Vector2(radius * 2, 3))
	draw_rect(bar, Palette2D.HP_BACK)
	bar.size.x *= clampf(float(creep.hp) / creep.def.max_hp, 0.0, 1.0)
	draw_rect(bar, Palette2D.HP_FILL)


func _draw_shot(shot: Shot) -> void:
	if not _current_positions.has(shot.target_id):
		return
	var flight := float(shot.land_tick - shot.fire_tick)
	var elapsed := float(_battle.tick - 1 - shot.fire_tick) + interpolation_alpha
	var t := clampf(elapsed / flight, 0.0, 1.0)
	var from := _milli_to_pixels(shot.origin)
	var at := from.lerp(_creep_position(shot.target_id), t)
	draw_circle(at, 3.0, Palette2D.tower(shot.tower_def.id).lightened(0.4))


func _creep_position(creep_id: int) -> Vector2:
	var current: Vector2 = _current_positions.get(creep_id, Vector2.ZERO)
	var previous: Vector2 = _previous_positions.get(creep_id, current)
	return previous.lerp(current, interpolation_alpha)


func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))


func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell * CELL_SIZE) + Vector2(CELL_SIZE, CELL_SIZE) * 0.5


static func _milli_to_pixels(milli: Vector2i) -> Vector2:
	return Vector2(milli) * CELL_SIZE / SimConfig.UNITS_PER_CELL
