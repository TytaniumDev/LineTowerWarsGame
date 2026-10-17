class_name LaneView2D
extends Node2D
## Draws one lane top-down from a LaneViewState: the maze during the build phase, or a
## live battle with interpolated creeps and homing shots.

const CELL_SIZE: int = 24

var state: LaneViewState


## Size of the lane in pixels.
func lane_pixel_size() -> Vector2:
	if state == null or state.grid == null:
		return Vector2.ZERO
	return Vector2(state.grid.lane.size * CELL_SIZE)


## The cell at a global canvas position, or (-1, -1) if it is outside the lane.
func screen_to_cell(canvas_position: Vector2) -> Vector2i:
	if state == null or state.grid == null:
		return Vector2i(-1, -1)
	var local := to_local(canvas_position)
	var cell := Vector2i(floori(local.x / CELL_SIZE), floori(local.y / CELL_SIZE))
	return cell if state.grid.lane.contains(cell) else Vector2i(-1, -1)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if state == null or state.grid == null:
		return
	_draw_ground()
	for path: Array in state.paths():
		_draw_path(path)
	for tower: TowerState in state.towers():
		draw_rect(_cell_rect(tower.cell).grow(-2), Palette2D.tower(tower.def.id))
	_draw_cursor()
	if state.battle != null:
		for creep: CreepState in state.battle.creeps:
			_draw_creep(creep)
		for shot: Shot in state.battle.shots:
			if state.is_shot_visible(shot):
				var at := state.shot_position(shot) * CELL_SIZE
				draw_circle(at, 3.0, Palette2D.tower(shot.tower_def.id).lightened(0.4))


func _draw_ground() -> void:
	var lane := state.grid.lane
	var size := lane_pixel_size()
	draw_rect(Rect2(Vector2.ZERO, size), Palette2D.GROUND)
	for cell: Vector2i in lane.spawn_cells:
		draw_rect(_cell_rect(cell), Palette2D.SPAWN)
	for cell: Vector2i in lane.exit_cells:
		draw_rect(_cell_rect(cell), Palette2D.EXIT)
	for x: int in range(lane.size.x + 1):
		draw_line(Vector2(x * CELL_SIZE, 0), Vector2(x * CELL_SIZE, size.y), Palette2D.GRID_LINE)
	for y: int in range(lane.size.y + 1):
		draw_line(Vector2(0, y * CELL_SIZE), Vector2(size.x, y * CELL_SIZE), Palette2D.GRID_LINE)


func _draw_path(path: Array) -> void:
	var points := PackedVector2Array()
	for cell: Vector2i in path:
		points.append((Vector2(cell) + Vector2(0.5, 0.5)) * CELL_SIZE)
	if points.size() >= 2:
		draw_polyline(points, Palette2D.PATH, 2.0)


func _draw_cursor() -> void:
	if not state.grid.lane.contains(state.cursor_cell):
		return
	var color := Palette2D.CURSOR_OK if state.cursor_ok else Palette2D.CURSOR_BAD
	draw_rect(_cell_rect(state.cursor_cell), color, false, 2.0)


func _draw_creep(creep: CreepState) -> void:
	var center := state.creep_position(creep.id) * CELL_SIZE
	var radius := CELL_SIZE * 0.3
	draw_circle(center, radius, Palette2D.creep(creep.def.id))
	if creep.is_slowed():
		draw_arc(center, radius + 2, 0, TAU, 16, Palette2D.SLOWED, 1.5)
	var bar := Rect2(center + Vector2(-radius, -radius - 5), Vector2(radius * 2, 3))
	draw_rect(bar, Palette2D.HP_BACK)
	bar.size.x *= clampf(float(creep.hp) / creep.def.max_hp, 0.0, 1.0)
	draw_rect(bar, Palette2D.HP_FILL)


func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))
