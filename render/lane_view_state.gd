class_name LaneViewState
extends RefCounted
## What one lane's renderer should show, shared by the 2D and 3D renderers so they can be
## swapped live: the maze being built or the battle being fought, the build cursor, and
## creep positions interpolated between sim ticks.
##
## Positions are in cells as floats (cell (2, 3)'s center is (2.5, 3.5)). Renderers scale
## them to pixels or world units. Only reads sim state.

## Cell under the build cursor, or (-1, -1) for none.
var cursor_cell: Vector2i = Vector2i(-1, -1)
## Whether placing at the cursor would be accepted.
var cursor_ok: bool = true
## Fraction of a tick since the last sim step, set by the owner every frame.
var interpolation_alpha: float = 0.0
var grid: LaneGrid
## The player whose maze is being built; null during a battle.
var player: PlayerState
## The battle being shown; null during the build phase.
var battle: LaneBattle

var _previous_positions: Dictionary[int, Vector2] = {}
var _current_positions: Dictionary[int, Vector2] = {}


## Shows `build_player`'s maze for building.
func show_build(build_player: PlayerState) -> void:
	grid = build_player.grid
	player = build_player
	battle = null


## Shows a battle in progress on `lane_battle`'s lane.
func show_battle(lane_battle: LaneBattle) -> void:
	grid = lane_battle.grid
	player = null
	battle = lane_battle
	cursor_cell = Vector2i(-1, -1)
	_previous_positions.clear()
	_current_positions.clear()
	on_ticked()


## Records creep positions after a sim tick so the next frames can interpolate.
func on_ticked() -> void:
	_previous_positions = _current_positions
	_current_positions = {}
	if battle != null:
		for creep: CreepState in battle.creeps:
			_current_positions[creep.id] = milli_to_cells(creep.position())


## Towers to draw, from the maze being built or the battle.
func towers() -> Array[TowerState]:
	if player != null:
		return player.battle_towers()
	if battle != null:
		return battle.towers
	var none: Array[TowerState] = []
	return none


## A creep's interpolated position in cells.
func creep_position(creep_id: int) -> Vector2:
	var current: Vector2 = _current_positions.get(creep_id, Vector2.ZERO)
	var previous: Vector2 = _previous_positions.get(creep_id, current)
	return previous.lerp(current, interpolation_alpha)


## Whether a shot should be drawn; its target may already be gone.
func is_shot_visible(shot: Shot) -> bool:
	return _current_positions.has(shot.target_id)


## Where a shot is drawn now in cells. It moves from its tower to the target so it
## arrives on its land tick.
func shot_position(shot: Shot) -> Vector2:
	var flight := float(shot.land_tick - shot.fire_tick)
	var elapsed := float(battle.tick - 1 - shot.fire_tick) + interpolation_alpha
	var t := clampf(elapsed / flight, 0.0, 1.0)
	return milli_to_cells(shot.origin).lerp(creep_position(shot.target_id), t)


## Each spawn's current path to the exit, for the build-phase preview.
func paths() -> Array[Array]:
	var result: Array[Array] = []
	if player != null:
		for spawn: Vector2i in grid.lane.spawn_cells:
			result.append(grid.path_to_exit(spawn))
	return result


static func milli_to_cells(milli: Vector2i) -> Vector2:
	return Vector2(milli) / SimConfig.UNITS_PER_CELL
