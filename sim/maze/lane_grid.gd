class_name LaneGrid
extends RefCounted
## Tower occupancy and creep pathing for one lane.
##
## Towers are walls. A placement is only allowed if every spawn can still reach an exit,
## so a maze can never fully block the creeps.

enum PlaceResult {
	OK,
	OUT_OF_BOUNDS,
	OCCUPIED,
	RESERVED,  ## Spawn and exit cells must stay open.
	BLOCKS_PATH,
}

## Integer step costs so path lengths compare exactly (diagonal ≈ straight × √2).
const STRAIGHT_COST: int = 1000
const DIAGONAL_COST: int = 1414

var lane: LaneDef

var _astar: AStarGrid2D = AStarGrid2D.new()
var _reserved: Dictionary[Vector2i, bool] = {}


func _init(lane_def: LaneDef) -> void:
	lane = lane_def
	_astar.region = Rect2i(Vector2i.ZERO, lane.size)
	_astar.cell_size = Vector2.ONE
	if lane.allow_diagonal:
		_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
		_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
		_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	else:
		_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
		_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
		_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.update()
	for cell: Vector2i in lane.spawn_cells + lane.exit_cells:
		_reserved[cell] = true


func is_blocked(cell: Vector2i) -> bool:
	return lane.contains(cell) and _astar.is_point_solid(cell)


## Checks a placement without changing the grid.
func check_place(cell: Vector2i) -> PlaceResult:
	if not lane.contains(cell):
		return PlaceResult.OUT_OF_BOUNDS
	if _reserved.has(cell):
		return PlaceResult.RESERVED
	if _astar.is_point_solid(cell):
		return PlaceResult.OCCUPIED
	_astar.set_point_solid(cell, true)
	var open := _all_spawns_reach_exit()
	_astar.set_point_solid(cell, false)
	return PlaceResult.OK if open else PlaceResult.BLOCKS_PATH


## Places a wall if allowed. Returns why not otherwise.
func place(cell: Vector2i) -> PlaceResult:
	var result := check_place(cell)
	if result == PlaceResult.OK:
		_astar.set_point_solid(cell, true)
	return result


## Removes a wall. Removing can never block the path.
func remove(cell: Vector2i) -> void:
	if is_blocked(cell):
		_astar.set_point_solid(cell, false)


## Shortest path from `from_cell` to the nearest exit, including both ends.
## Ties go to the exit listed first in the LaneDef. Empty if no exit is reachable.
func path_to_exit(from_cell: Vector2i) -> Array[Vector2i]:
	var best: Array[Vector2i] = []
	var best_cost: int = -1
	for exit_cell: Vector2i in lane.exit_cells:
		var path: Array[Vector2i] = _astar.get_id_path(from_cell, exit_cell)
		if path.is_empty():
			continue
		var cost := path_cost(path)
		if best_cost < 0 or cost < best_cost:
			best = path
			best_cost = cost
	return best


## Integer length of a path in step costs.
static func path_cost(path: Array[Vector2i]) -> int:
	var cost: int = 0
	for i: int in range(1, path.size()):
		var step := path[i] - path[i - 1]
		cost += DIAGONAL_COST if step.x != 0 and step.y != 0 else STRAIGHT_COST
	return cost


func _all_spawns_reach_exit() -> bool:
	for spawn: Vector2i in lane.spawn_cells:
		if path_to_exit(spawn).is_empty():
			return false
	return true
