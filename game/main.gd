extends Node
## Entry scene: wires the sim, the top-down renderer and the UI into a playable offline run.
##
## Build phase: edit your maze and buy sends, then ready up. Battle phase: both lanes play
## side by side (D42) until the duel ends, then Continue applies the result.

const RULESET_PATH: String = "res://content/rulesets/standard.tres"
const LANE_PATH: String = "res://content/lanes/standard.tres"
const SEED_SNAPSHOT_DIR: String = "res://content/snapshots"
const SPEEDS: Array[float] = [1.0, 2.0, 4.0]
const MARGIN: float = 24.0
const LANE_TOP: float = 48.0
const OUTCOME_TEXT: Dictionary[Duel.Outcome, String] = {
	Duel.Outcome.WIN: "You win!",
	Duel.Outcome.LOSS: "You lose a life",
	Duel.Outcome.DRAW: "Draw",
}

var _content: ContentRegistry
var _rules: RulesetDef
var _lane: LaneDef
var _store: SnapshotStore = SnapshotStore.new()
var _sim: GameSim
var _run: RunState
var _speed_index: int = 0
## The last finished duel, kept so the run-over screen can still show its leaks.
var _finished_duel: Duel

@onready var _runner: SimRunner = $SimRunner
@onready var _home_view: LaneView2D = $World/HomeLane
@onready var _away_view: LaneView2D = $World/AwayLane
@onready var _home_title: Label = $World/HomeTitle
@onready var _away_title: Label = $World/AwayTitle
@onready var _build: BuildController = $BuildController
@onready var _build_panel: BuildPanel = $HUD/BuildPanel
@onready var _battle_hud: BattleHud = $HUD/BattleHud


func _ready() -> void:
	_content = ContentLoader.load_registry()
	_rules = load(RULESET_PATH)
	_lane = load(LANE_PATH)
	var towers := _base_towers()
	_build.view = _home_view
	_build.towers = towers
	_build.changed.connect(_refresh_build_panel)
	_build.refused.connect(_build_panel.show_message)
	_build_panel.setup(towers, _sorted_creeps())
	_build_panel.tower_chosen.connect(_build.choose_tower)
	_build_panel.send_requested.connect(_on_send_requested)
	_build_panel.undo_send_requested.connect(_on_undo_send)
	_build_panel.ready_pressed.connect(_start_battle)
	_battle_hud.setup()
	_battle_hud.continue_pressed.connect(_on_continue)
	_start_run()


func _process(_delta: float) -> void:
	_home_view.interpolation_alpha = _runner.interpolation_alpha
	_away_view.interpolation_alpha = _runner.interpolation_alpha


func _unhandled_input(event: InputEvent) -> void:
	if _run == null:
		return
	if _run.phase == RunState.Phase.BUILD:
		if event.is_action_pressed("switch_focus"):
			_toggle_panel_focus()
		elif event.is_action_pressed("end_build"):
			_start_battle()
		else:
			return
	elif _run.phase == RunState.Phase.BATTLE:
		if event.is_action_pressed("toggle_pause"):
			_runner.paused = not _runner.paused
		elif event.is_action_pressed("cycle_speed"):
			_speed_index = (_speed_index + 1) % SPEEDS.size()
			_runner.speed = SPEEDS[_speed_index]
		else:
			return
		_refresh_battle_hud()
	else:
		return
	get_viewport().set_input_as_handled()


func _start_run() -> void:
	var pool := _store.load_all(_content)
	pool.append_array(SnapshotStore.new(SEED_SNAPSHOT_DIR).load_all(_content))
	_sim = GameSim.new(int(Time.get_unix_time_from_system()))
	_sim.ticked.connect(_on_ticked)
	_run = _sim.start_run(_rules, _lane, pool)
	_runner.sim = _sim
	_enter_build()


func _enter_build() -> void:
	_runner.paused = false
	_home_view.show_build(_run.player)
	_away_view.visible = false
	_away_title.visible = false
	_home_title.text = "Your maze"
	_build_panel.visible = true
	_build_panel.show_message("")
	_battle_hud.visible = false
	_layout(false)
	_build.begin(_run.player)


func _start_battle() -> void:
	if _run.phase != RunState.Phase.BUILD:
		return
	_build.active = false
	var own := _run.end_build()
	var saved := _store.save(own)
	if saved != OK:
		push_warning("Couldn't save this round's snapshot: %s" % error_string(saved))
	_home_view.show_battle(_run.duel.home)
	_away_view.show_battle(_run.duel.away)
	_away_view.visible = true
	_away_title.visible = true
	_home_title.text = "Your maze"
	_away_title.text = "Their maze"
	_build_panel.visible = false
	_battle_hud.visible = true
	_layout(true)
	_refresh_battle_hud()


func _on_ticked(_tick: int) -> void:
	if _run.phase != RunState.Phase.BATTLE:
		return
	_home_view.on_ticked()
	_away_view.on_ticked()
	_refresh_battle_hud()


func _on_continue() -> void:
	if _run.phase == RunState.Phase.RUN_OVER:
		_start_run()
		return
	if _run.phase != RunState.Phase.BATTLE or not _run.duel.is_finished():
		return
	_finished_duel = _run.duel
	_run.finish_battle()
	if _run.phase == RunState.Phase.RUN_OVER:
		_refresh_battle_hud()
	else:
		_enter_build()


func _on_send_requested(creep: CreepDef) -> void:
	var result := _run.player.buy_send(creep)
	_build_panel.show_message("" if result == PlayerState.Result.OK else "Not enough gold.")
	_refresh_build_panel()


func _on_undo_send() -> void:
	_run.player.undo_last_send()
	_build_panel.show_message("")
	_refresh_build_panel()


func _toggle_panel_focus() -> void:
	if _build.active:
		_build.active = false
		_build_panel.grab_panel_focus()
	else:
		var focused := get_viewport().gui_get_focus_owner()
		if focused != null:
			focused.release_focus()
		_build.active = true


func _refresh_build_panel() -> void:
	_build_panel.refresh(_run.player, _build.chosen_tower)


func _refresh_battle_hud() -> void:
	var player := _run.player
	var outcome := ""
	if _run.phase == RunState.Phase.RUN_OVER:
		var won := player.wins >= _rules.wins_to_finish
		outcome = "Run won!" if won else "Run over"
		outcome += "\n%d wins, %d losses, %d draws" % [player.wins, player.losses, player.draws]
		_battle_hud.refresh(player.round_number, _finished_duel, "", _runner.speed, false, outcome)
		return
	if _run.duel.is_finished():
		outcome = OUTCOME_TEXT[_run.duel.outcome()]
	(
		_battle_hud
		. refresh(
			player.round_number,
			_run.duel,
			_opponent_name(),
			_runner.speed,
			_runner.paused,
			outcome,
		)
	)


func _opponent_name() -> String:
	var foe := _run.opponent
	if foe == null:
		return "an empty lane"
	return "a round %d build (%dW %dL)" % [foe.round_number, foe.wins, foe.losses]


func _layout(battle: bool) -> void:
	var lane_width := _home_view.lane_pixel_size().x
	_home_view.position = Vector2(MARGIN, LANE_TOP)
	_home_title.position = Vector2(MARGIN, LANE_TOP - 28)
	var next_x := MARGIN + lane_width + MARGIN * 2
	if battle:
		_away_view.position = Vector2(next_x, LANE_TOP)
		_away_title.position = Vector2(next_x, LANE_TOP - 28)
		next_x += lane_width + MARGIN * 2
	_build_panel.position = Vector2(next_x, LANE_TOP)
	_battle_hud.position = Vector2(next_x, LANE_TOP)


## Towers you can build directly, cheapest first. Upgrades are reached from these.
func _base_towers() -> Array[TowerDef]:
	var towers: Array[TowerDef] = []
	for res: Resource in ContentLoader.load_dir(ContentLoader.TOWERS_DIR):
		if res is TowerDef:
			towers.append(res)
	towers.sort_custom(func(a: TowerDef, b: TowerDef) -> bool: return a.cost < b.cost)
	return towers


func _sorted_creeps() -> Array[CreepDef]:
	var creeps: Array[CreepDef] = []
	creeps.assign(_content.creeps.values())
	creeps.sort_custom(func(a: CreepDef, b: CreepDef) -> bool: return a.send_cost < b.send_cost)
	return creeps
