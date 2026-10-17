class_name TowerState
extends RefCounted
## One placed tower in a battle.

var def: TowerDef
var cell: Vector2i
## Ticks until the tower can fire again.
var cooldown: int = 0


func _init(tower_def: TowerDef, tower_cell: Vector2i) -> void:
	def = tower_def
	cell = tower_cell


## Tower center in milli-cells.
func position() -> Vector2i:
	var half := SimConfig.UNITS_PER_CELL / 2
	return cell * SimConfig.UNITS_PER_CELL + Vector2i(half, half)
