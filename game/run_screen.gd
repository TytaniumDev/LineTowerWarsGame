class_name RunScreen
extends Node
## One offline run: wires the sim, the 2D and 3D renderers and the UI together.
##
## Build phase: edit your maze and buy sends, then ready up. Battle phase: both lanes play
## side by side (D42) until the duel ends, then Continue applies the result. The pause
## action opens a menu in either phase. Both renderers draw from the same LaneViewStates,
## so toggle_renderer (or the Options setting) swaps views live, even mid-battle.

## The player chose Options from the pause menu. Call `return_from_options()` when done.
signal options_requested
## The player chose to leave the run for the main menu.
signal exit_requested

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

## The rules for this run. Set before adding the screen to the tree; defaults to the
## standard ruleset.
var rules: RulesetDef

var _content: ContentRegistry
var _lane: LaneDef
var _store: SnapshotStore = SnapshotStore.new()
var _sim: GameSim
var _run: RunState
var _speed_index: int = 0
## Whether the maze cursor had input before the pause menu opened.
var _build_was_active: bool = false
## The last finished duel, kept so the run-over screen can still show its leaks.
var _finished_duel: Duel
var _home_state: LaneViewState = LaneViewState.new()
var _away_state: LaneViewState = LaneViewState.new()

@onready var _runner: SimRunner = $SimRunner
@onready var _home_view: LaneView2D = $World/HomeLane
@onready var _away_view: LaneView2D = $World/AwayLane
@onready var _home_title: Label = $World/HomeTitle
@onready var _away_title: Label = $World/AwayTitle
@onready var _view_2d: Node2D = $World
@onready var _view_3d_container: SubViewportContainer = $View3D
@onready var _view_3d_viewport: SubViewport = $View3D/Viewport
@onready var _view_3d: DuelView3D = $View3D/Viewport/DuelView3D
@onready var _build: BuildController = $BuildController
@onready var _build_panel: BuildPanel = $HUD/BuildPanel
@onready var _battle_hud: BattleHud = $HUD/BattleHud
@onready var _pause_menu: PauseMenu = $HUD/PauseMenu


func _ready() -> void:
	_content = ContentLoader.load_registry()
	if rules == null:
		rules = load(RULESET_PATH)
	_lane = load(LANE_PATH)
	var towers := _base_towers()
	_home_view.state = _home_state
	_away_view.state = _away_state
	_view_3d.bind(_home_state, _away_state)
	_build.state = _home_state
	_build.cell_at_mouse = _cell_at_mouse
	Settings.changed.connect(_show_active_renderer)
	_show_active_renderer()
	_build.towers = towers
	_build.changed.connect(_refresh_build_panel)
	_build.refused.connect(_build_panel.show_message)
	_build.upgrade_choice_needed.connect(_choose_upgrade)
	_build_panel.setup(towers, _sorted_creeps())
	_build_panel.tower_chosen.connect(_build.choose_tower)
	_build_panel.upgrade_chosen.connect(_on_upgrade_chosen)
	_build_panel.send_requested.connect(_on_send_requested)
	_build_panel.undo_send_requested.connect(_on_undo_send)
	_build_panel.ready_pressed.connect(_start_battle)
	_battle_hud.setup()
	_battle_hud.continue_pressed.connect(_on_continue)
	_pause_menu.resume_pressed.connect(_close_pause_menu)
	_pause_menu.options_pressed.connect(_on_options_pressed)
	_pause_menu.quit_pressed.connect(exit_requested.emit)
	_pause_menu.hide()
	_start_run()


## Shows the pause menu again after the options screen closes.
func return_from_options() -> void:
	_pause_menu.options_open = false
	_pause_menu.show()
	_pause_menu.focus()


func _process(_delta: float) -> void:
	_home_state.interpolation_alpha = _runner.interpolation_alpha
	_away_state.interpolation_alpha = _runner.interpolation_alpha


func _unhandled_input(event: InputEvent) -> void:
	if _run == null or _is_paused():
		return
	if event.is_action_pressed("ui_cancel") and _build_panel.upgrades_focused():
		# Back out of picking an upgrade before Escape can open the pause menu.
		_return_to_maze()
	elif event.is_action_pressed("toggle_pause"):
		_open_pause_menu()
	elif event.is_action_pressed("toggle_renderer"):
		Settings.toggle_renderer()
	elif _run.phase == RunState.Phase.BUILD:
		if event.is_action_pressed("switch_focus"):
			_toggle_panel_focus()

		elif event.is_action_pressed("end_build"):
			_start_battle()
		else:
			return
	elif _run.phase == RunState.Phase.BATTLE:
		if event.is_action_pressed("cycle_speed"):
			_speed_index = (_speed_index + 1) % SPEEDS.size()
			_runner.speed = SPEEDS[_speed_index]
		else:
			return
		_refresh_battle_hud()
	else:
		return
	get_viewport().set_input_as_handled()


func _is_paused() -> bool:
	return _pause_menu.visible or _pause_menu.options_open


func _open_pause_menu() -> void:
	_build_was_active = _build.active
	_build.active = false
	_runner.paused = true
	_pause_menu.show()
	_pause_menu.focus()


func _close_pause_menu() -> void:
	_pause_menu.hide()
	_runner.paused = false
	_build.active = _build_was_active
	if _run.phase == RunState.Phase.BATTLE:
		_refresh_battle_hud()


func _on_options_pressed() -> void:
	_pause_menu.hide()
	_pause_menu.options_open = true
	options_requested.emit()


func _start_run() -> void:
	var pool := _store.load_all(_content)
	pool.append_array(SnapshotStore.new(SEED_SNAPSHOT_DIR).load_all(_content))
	_sim = GameSim.new(int(Time.get_unix_time_from_system()))
	_sim.ticked.connect(_on_ticked)
	_run = _sim.start_run(rules, _lane, pool)
	_runner.sim = _sim
	_enter_build()


func _enter_build() -> void:
	_runner.paused = false
	_home_state.show_build(_run.player)
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
	_home_state.show_battle(_run.duel.home)
	_away_state.show_battle(_run.duel.away)
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
	_home_state.on_ticked()
	_away_state.on_ticked()
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
		_return_to_maze()


func _return_to_maze() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null:
		focused.release_focus()
	_build.active = true


## The tower under the cursor has several upgrades: let the player pick one in the panel.
func _choose_upgrade() -> void:
	if _build_panel.focus_upgrades():
		_build.active = false
	else:
		_build_panel.show_message("Not enough gold.")


func _on_upgrade_chosen(index: int) -> void:
	var from_choice := _build_panel.upgrades_focused()
	_build.upgrade(index)
	if from_choice:
		_return_to_maze()


func _refresh_build_panel() -> void:
	_build_panel.refresh(_run.player, _build.chosen_tower, _build.tower_at_cursor())


func _refresh_battle_hud() -> void:
	var player := _run.player
	var outcome := ""
	if _run.phase == RunState.Phase.RUN_OVER:
		var won := player.wins >= rules.wins_to_finish
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
	# The 3D view fills the space left of the side panel.
	_view_3d_container.position = Vector2.ZERO
	_view_3d_container.size = Vector2(next_x - MARGIN, get_viewport().get_visible_rect().size.y)
	_view_3d.set_battle_layout(battle, _lane)


func _show_active_renderer() -> void:
	var use_3d := Settings.renderer == GameSettings.Renderer.ANGLED_3D
	_view_3d_container.visible = use_3d
	# Don't spend GPU time on the 3D view while it's hidden.
	_view_3d_viewport.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS if use_3d else SubViewport.UPDATE_DISABLED
	)
	_view_3d.process_mode = PROCESS_MODE_INHERIT if use_3d else PROCESS_MODE_DISABLED
	_view_2d.visible = not use_3d


func _cell_at_mouse() -> Vector2i:
	if _view_3d_container.visible:
		return _view_3d.screen_to_cell(_view_3d_container.get_local_mouse_position())
	return _home_view.screen_to_cell(_home_view.get_global_mouse_position())


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
