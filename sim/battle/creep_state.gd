class_name CreepState
extends RefCounted
## One live creep in a battle.
##
## Movement is tracked in "scaled units" (milli-cells × ticks per second) so that
## per-tick movement stays an exact integer for any speed.

var id: int
var def: CreepDef
var hp: int
var path: Array[Vector2i]
## Index of the path cell the creep most recently passed.
var path_index: int = 0
## Scaled distance covered along the current path segment.
var segment_progress: int = 0
## Scaled distance covered along the whole path; higher means closer to leaking.
var distance_traveled: int = 0
var slow_percent: int = 0
var slow_ticks_left: int = 0
## Damage from shots already in flight at this creep. Towers skip creeps it will kill.
var incoming_damage: int = 0


func _init(creep_id: int, creep_def: CreepDef, creep_path: Array[Vector2i]) -> void:
	id = creep_id
	def = creep_def
	hp = creep_def.max_hp
	path = creep_path


func is_slowed() -> bool:
	return slow_ticks_left > 0


## True when shots in flight will already kill this creep.
func is_doomed() -> bool:
	return incoming_damage >= hp


func has_leaked() -> bool:
	return path_index >= path.size() - 1


## Current position in milli-cells, at the center of the cell grid.
func position() -> Vector2i:
	var half := SimConfig.UNITS_PER_CELL / 2
	var from_cell := path[path_index] * SimConfig.UNITS_PER_CELL + Vector2i(half, half)
	if has_leaked():
		return from_cell
	var step := path[path_index + 1] - path[path_index]
	var segment := segment_length(step)
	var offset := step * SimConfig.UNITS_PER_CELL * segment_progress / segment
	return from_cell + offset


## Length of one step between neighboring cells, in scaled units.
static func segment_length(step: Vector2i) -> int:
	var cost := LaneGrid.DIAGONAL_COST if step.x != 0 and step.y != 0 else LaneGrid.STRAIGHT_COST
	return cost * SimConfig.TICKS_PER_SECOND
