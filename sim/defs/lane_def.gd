class_name LaneDef
extends Resource
## Shape of one player's lane: grid size plus where creeps enter and leave.
##
## Kept as data so the lane can be resized while playtesting without code changes.

@export var id: StringName
## Lane width and height in cells.
@export var size: Vector2i = Vector2i(11, 30)
## Cells where creeps enter the lane. Towers can't be built on them.
@export var spawn_cells: Array[Vector2i] = []
## Cells creeps walk to; reaching one counts as a leak. Towers can't be built on them.
@export var exit_cells: Array[Vector2i] = []
## Whether creeps may move diagonally. They never cut between two corner-touching towers.
@export var allow_diagonal: bool = true


func contains(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


## Returns a list of problems, empty when the lane is usable.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if size.x <= 0 or size.y <= 0:
		errors.append("size must be positive")
	if spawn_cells.is_empty():
		errors.append("needs at least one spawn cell")
	if exit_cells.is_empty():
		errors.append("needs at least one exit cell")
	for cell: Vector2i in spawn_cells + exit_cells:
		if not contains(cell):
			errors.append("cell %s is outside the lane" % cell)
	return errors
