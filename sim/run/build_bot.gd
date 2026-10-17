class_name BuildBot
extends RefCounted
## A simple rule-based player for build phases, used to generate seed opponents (D37).
##
## Each round it spends `send_percent` of its gold on random sends, then places random
## affordable towers wherever they lengthen the creeps' path the most. Deterministic for
## a given seed.

## Percent of each round's gold spent on sends before building.
var send_percent: int
var towers: Array[TowerDef] = []
var creeps: Array[CreepDef] = []

var _rng: SimRng


func _init(
	tower_defs: Array[TowerDef], creep_defs: Array[CreepDef], spend_percent: int, seed_value: int
) -> void:
	towers = tower_defs
	creeps = creep_defs
	send_percent = spend_percent
	_rng = SimRng.new(seed_value)


## Plays one build phase for `player`.
func play_build(player: PlayerState) -> void:
	var send_budget := player.gold * send_percent / 100
	while true:
		var options := creeps.filter(
			func(c: CreepDef) -> bool: return c.send_cost <= mini(send_budget, player.gold)
		)
		if options.is_empty():
			break
		var creep: CreepDef = options[_rng.range_int(0, options.size() - 1)]
		player.buy_send(creep)
		send_budget -= creep.send_cost
	while true:
		var options := towers.filter(func(t: TowerDef) -> bool: return t.cost <= player.gold)
		if options.is_empty():
			break
		var tower: TowerDef = options[_rng.range_int(0, options.size() - 1)]
		var cell := best_cell(player.grid)
		if cell.x < 0:
			break
		player.place_tower(tower, cell)


## The open cell that makes the creeps' path longest when walled off, or (-1, -1) if no
## cell can take a tower. Ties go to the first cell in row-major order.
static func best_cell(grid: LaneGrid) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_cost := -1
	for y: int in grid.lane.size.y:
		for x: int in grid.lane.size.x:
			var cell := Vector2i(x, y)
			if grid.place(cell) != LaneGrid.PlaceResult.OK:
				continue
			var cost := _total_path_cost(grid)
			grid.remove(cell)
			if cost > best_cost:
				best_cost = cost
				best = cell
	return best


static func _total_path_cost(grid: LaneGrid) -> int:
	var total := 0
	for spawn: Vector2i in grid.lane.spawn_cells:
		total += LaneGrid.path_cost(grid.path_to_exit(spawn))
	return total
