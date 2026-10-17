class_name Snapshot
extends RefCounted
## A player's build at the end of one build phase, which other players fight later.
##
## Saved as JSON (PRD §6.4), naming content by id. Maze and army are separate so either
## can be reused on its own.

const SCHEMA_VERSION: int = 1

var round_number: int = 0
var ruleset_id: StringName
var lane_id: StringName
## Towers in placement order. Only `def` and `cell` are saved.
var maze: Array[PlacedTower] = []
## Sends in the order bought.
var army: Array[CreepDef] = []
var gold: int = 0
var income: int = 0
var lives: int = 0
var wins: int = 0
var losses: int = 0
var draws: int = 0
## The game build that saved this snapshot. Set by the app, since sim/ can't read it.
var game_version: String = ""


## Captures `player` as it stands at the end of a build phase.
static func from_player(player: PlayerState) -> Snapshot:
	var snapshot := Snapshot.new()
	snapshot.round_number = player.round_number
	snapshot.ruleset_id = player.ruleset.id
	snapshot.lane_id = player.grid.lane.id
	for tower: PlacedTower in player.towers.values():
		snapshot.maze.append(PlacedTower.new(tower.def, tower.cell))
	snapshot.army = player.army.duplicate()
	snapshot.gold = player.gold
	snapshot.income = player.income
	snapshot.lives = player.lives
	snapshot.wins = player.wins
	snapshot.losses = player.losses
	snapshot.draws = player.draws
	return snapshot


## Rebuilds a snapshot from `to_dict()` output, or returns null if the data is malformed
## or names content that `content` doesn't have.
static func from_dict(data: Dictionary, content: ContentRegistry) -> Snapshot:
	if int(data.get("schema_version", 0)) != SCHEMA_VERSION:
		return null
	var maze_data: Variant = data.get("maze")
	var army_data: Variant = data.get("army")
	var economy: Variant = data.get("economy")
	var meta: Variant = data.get("meta")
	if not (maze_data is Array and army_data is Array):
		return null
	if not (economy is Dictionary and meta is Dictionary):
		return null
	var snapshot := Snapshot.new()
	snapshot.round_number = int(data.get("round", 0))
	for entry: Variant in maze_data:
		var tower := _tower_from_dict(entry, content)
		if tower == null:
			return null
		snapshot.maze.append(tower)
	for id: Variant in army_data:
		var creep := content.creep(StringName(str(id)))
		if creep == null:
			return null
		snapshot.army.append(creep)
	snapshot.gold = int(economy.get("gold", 0))
	snapshot.income = int(economy.get("income", 0))
	snapshot.ruleset_id = StringName(str(meta.get("ruleset_id", "")))
	snapshot.lane_id = StringName(str(meta.get("lane_id", "")))
	snapshot.lives = int(meta.get("lives", 0))
	snapshot.wins = int(meta.get("wins", 0))
	snapshot.losses = int(meta.get("losses", 0))
	snapshot.draws = int(meta.get("draws", 0))
	snapshot.game_version = str(meta.get("game_version", ""))
	return snapshot


func to_dict() -> Dictionary:
	var maze_data: Array[Dictionary] = []
	for tower: PlacedTower in maze:
		maze_data.append({"tower_id": String(tower.def.id), "cell": [tower.cell.x, tower.cell.y]})
	var army_data: Array[String] = []
	for creep: CreepDef in army:
		army_data.append(String(creep.id))
	return {
		"schema_version": SCHEMA_VERSION,
		"round": round_number,
		"maze": maze_data,
		"army": army_data,
		"economy": {"gold": gold, "income": income},
		"meta":
		{
			"ruleset_id": String(ruleset_id),
			"lane_id": String(lane_id),
			"lives": lives,
			"wins": wins,
			"losses": losses,
			"draws": draws,
			"game_version": game_version,
		},
	}


## This snapshot as one side of a duel on `lane`. Towers that no longer fit the lane
## (for example after the lane's shape changed) are left out.
func duel_side(lane: LaneDef) -> DuelSide:
	var grid := LaneGrid.new(lane)
	var towers: Array[TowerState] = []
	for tower: PlacedTower in maze:
		if grid.place(tower.cell) == LaneGrid.PlaceResult.OK:
			towers.append(TowerState.new(tower.def, tower.cell))
	return DuelSide.new(grid, towers, army.duplicate())


static func _tower_from_dict(entry: Variant, content: ContentRegistry) -> PlacedTower:
	if not entry is Dictionary:
		return null
	var cell: Variant = entry.get("cell")
	if not (cell is Array and cell.size() == 2):
		return null
	var def := content.tower(StringName(str(entry.get("tower_id", ""))))
	if def == null:
		return null
	return PlacedTower.new(def, Vector2i(int(cell[0]), int(cell[1])))
