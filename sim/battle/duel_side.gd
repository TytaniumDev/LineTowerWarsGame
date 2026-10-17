class_name DuelSide
extends RefCounted
## One side of a duel: the maze it defends and the creeps it sends at the other side.

var grid: LaneGrid
var towers: Array[TowerState] = []
## Sends in the order bought.
var army: Array[CreepDef] = []


func _init(lane_grid: LaneGrid, placed_towers: Array[TowerState], sends: Array[CreepDef]) -> void:
	grid = lane_grid
	towers = placed_towers
	army = sends
