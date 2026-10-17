class_name PlacedTower
extends RefCounted
## A tower in a player's maze between battles, with what it cost for sell refunds.

var def: TowerDef
var cell: Vector2i
## Gold spent on this tower in the current round (fully refundable).
var spent_this_round: int = 0
## Gold spent on this tower in earlier rounds (partly refundable).
var spent_before: int = 0


func _init(tower_def: TowerDef, tower_cell: Vector2i) -> void:
	def = tower_def
	cell = tower_cell
