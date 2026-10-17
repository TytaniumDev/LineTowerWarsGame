extends SceneTree
## Regenerates the seed opponents in res://content/snapshots (D37).
##
## Several BuildBots with different send habits play a run against each other, and every
## build phase is saved as a snapshot. Rerun after balance changes:
##   godot --headless -s res://tools/generate_seed_snapshots.gd

const OUT_DIR: String = "res://content/snapshots"
## Percent of gold each bot spends on sends; one bot per entry.
const SEND_PERCENTS: Array[int] = [0, 20, 40, 60]
const ROUNDS: int = 10


func _init() -> void:
	var rules: RulesetDef = load("res://content/rulesets/standard.tres")
	var lane: LaneDef = load("res://content/lanes/standard.tres")
	var content := ContentLoader.load_registry()
	var tower_defs: Array[TowerDef] = []
	for id: StringName in content.towers:
		tower_defs.append(content.towers[id])
	var creep_defs: Array[CreepDef] = []
	for id: StringName in content.creeps:
		creep_defs.append(content.creeps[id])
	_clear_output()

	var players: Array[PlayerState] = []
	var bots: Array[BuildBot] = []
	for i: int in SEND_PERCENTS.size():
		players.append(PlayerState.new(rules, lane))
		bots.append(BuildBot.new(tower_defs, creep_defs, SEND_PERCENTS[i], i + 1))

	var version := str(ProjectSettings.get_setting("application/config/version", ""))
	var written := 0
	for round_number: int in range(1, ROUNDS + 1):
		var snapshots: Array[Snapshot] = []
		for i: int in players.size():
			players[i].start_round()
			bots[i].play_build(players[i])
			var snapshot := Snapshot.from_player(players[i])
			snapshot.game_version = version
			snapshots.append(snapshot)
			var path := OUT_DIR.path_join("bot_%d_round_%02d.json" % [i + 1, round_number])
			_write(path, snapshot)
			written += 1
		# Each bot fights the next one's build from the same round.
		for i: int in players.size():
			var foe := snapshots[(i + 1) % snapshots.size()]
			var wave := rules.wave_for_round(round_number)
			var duel := Duel.new(rules, wave, players[i].duel_side(), foe.duel_side(lane))
			players[i].finish_round(duel.run(), duel.home.bounty_earned)
	print("Wrote %d seed snapshots to %s" % [written, OUT_DIR])
	quit()


func _clear_output() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	for file_name: String in DirAccess.get_files_at(OUT_DIR):
		if file_name.ends_with(".json"):
			DirAccess.remove_absolute(OUT_DIR.path_join(file_name))


func _write(path: String, snapshot: Snapshot) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(snapshot.to_dict(), "\t", false) + "\n")
	file.close()
