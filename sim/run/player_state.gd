class_name PlayerState
extends RefCounted
## One player's run: economy, lives and record, maze, and this round's army.
##
## Build-phase actions are methods that return a Result instead of throwing, so the UI can
## explain why an action was refused.

enum Result {
	OK,
	NOT_ENOUGH_GOLD,
	OUT_OF_BOUNDS,
	OCCUPIED,
	RESERVED,
	BLOCKS_PATH,
	NO_TOWER,
	INVALID_UPGRADE,
	NO_SEND,
}

var ruleset: RulesetDef
var grid: LaneGrid
## 1-based; 0 before the first round starts.
var round_number: int = 0
var gold: int
var income: int
var lives: int
var wins: int = 0
var losses: int = 0
var draws: int = 0
## Towers by cell, in placement order.
var towers: Dictionary[Vector2i, PlacedTower] = {}
## Creeps bought this round, in the order they will be sent.
var army: Array[CreepDef] = []


func _init(rules: RulesetDef, lane: LaneDef) -> void:
	ruleset = rules
	grid = LaneGrid.new(lane)
	gold = rules.starting_gold
	income = rules.base_income
	lives = rules.starting_lives


func is_run_over() -> bool:
	return lives <= 0 or wins >= ruleset.wins_to_finish


## Starts the next build phase: pays income (after round 1) and clears last round's army.
func start_round() -> void:
	round_number += 1
	if round_number > 1:
		gold += income
	army.clear()
	for tower: PlacedTower in towers.values():
		tower.spent_before += tower.spent_this_round
		tower.spent_this_round = 0


func place_tower(def: TowerDef, cell: Vector2i) -> Result:
	if gold < def.cost:
		return Result.NOT_ENOUGH_GOLD
	var placed := grid.place(cell)
	if placed != LaneGrid.PlaceResult.OK:
		return _from_place_result(placed)
	var tower := PlacedTower.new(def, cell)
	tower.spent_this_round = def.cost
	towers[cell] = tower
	gold -= def.cost
	return Result.OK


## Gold returned if the tower at `cell` were sold now.
func sell_value(cell: Vector2i) -> int:
	var tower: PlacedTower = towers.get(cell)
	if tower == null:
		return 0
	return tower.spent_this_round + tower.spent_before * ruleset.sell_refund_percent / 100


func sell_tower(cell: Vector2i) -> Result:
	if not towers.has(cell):
		return Result.NO_TOWER
	gold += sell_value(cell)
	towers.erase(cell)
	grid.remove(cell)
	return Result.OK


## Upgrades the tower at `cell` into its `option_index`-th upgrade, paying that tower's cost.
func upgrade_tower(cell: Vector2i, option_index: int) -> Result:
	var tower: PlacedTower = towers.get(cell)
	if tower == null:
		return Result.NO_TOWER
	if option_index < 0 or option_index >= tower.def.upgrades.size():
		return Result.INVALID_UPGRADE
	var upgrade := tower.def.upgrades[option_index]
	if gold < upgrade.cost:
		return Result.NOT_ENOUGH_GOLD
	gold -= upgrade.cost
	tower.spent_this_round += upgrade.cost
	tower.def = upgrade
	return Result.OK


## Buys one send: pays its cost, adds it to this round's army and raises income.
func buy_send(creep: CreepDef) -> Result:
	if gold < creep.send_cost:
		return Result.NOT_ENOUGH_GOLD
	gold -= creep.send_cost
	income += creep.income_bonus
	for i: int in creep.group_size:
		army.append(creep)
	return Result.OK


## Undoes the most recent send bought this round, refunding it in full.
func undo_last_send() -> Result:
	if army.is_empty():
		return Result.NO_SEND
	var creep: CreepDef = army.back()
	for i: int in creep.group_size:
		army.pop_back()
	gold += creep.send_cost
	income -= creep.income_bonus
	return Result.OK


## Battle-ready tower states for the current maze, in placement order.
func battle_towers() -> Array[TowerState]:
	var result: Array[TowerState] = []
	for tower: PlacedTower in towers.values():
		result.append(TowerState.new(tower.def, tower.cell))
	return result


static func _from_place_result(result: LaneGrid.PlaceResult) -> Result:
	match result:
		LaneGrid.PlaceResult.OUT_OF_BOUNDS:
			return Result.OUT_OF_BOUNDS
		LaneGrid.PlaceResult.OCCUPIED:
			return Result.OCCUPIED
		LaneGrid.PlaceResult.RESERVED:
			return Result.RESERVED
		LaneGrid.PlaceResult.BLOCKS_PATH:
			return Result.BLOCKS_PATH
	return Result.OK
