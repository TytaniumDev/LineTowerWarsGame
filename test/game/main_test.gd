extends GdUnitTestSuite
## Smoke test of the app flow: main menu, starting a run, options, and back.

const SETTINGS_PATH := "user://test_main_settings.cfg"

var _real_settings_path: String


func before_test() -> void:
	# Closing the options menu saves settings; keep that away from the player's file.
	_real_settings_path = Settings.path
	Settings.path = SETTINGS_PATH


func after_test() -> void:
	Settings.path = _real_settings_path
	DirAccess.remove_absolute(SETTINGS_PATH)


func _main() -> Node:
	var main: Node = auto_free(load("res://game/main.tscn").instantiate())
	add_child(main)
	await get_tree().process_frame
	return main


func test_opens_on_the_main_menu() -> void:
	var main := await _main()
	assert_bool(main.get_node("MenuLayer/MainMenu").visible).is_true()
	assert_bool(main.get_node("OverlayLayer/OptionsMenu").visible).is_false()


func test_play_starts_a_run_and_quitting_returns_to_the_menu() -> void:
	var main := await _main()
	var menu: MainMenu = main.get_node("MenuLayer/MainMenu")
	menu.play_pressed.emit()
	await get_tree().process_frame
	var run: RunScreen = main.get_node("RunScreen")
	assert_bool(menu.visible).is_false()
	run.exit_requested.emit()
	await get_tree().process_frame
	assert_bool(menu.visible).is_true()
	assert_object(main.get_node_or_null("RunScreen")).is_null()


func test_options_open_from_the_menu_and_close() -> void:
	var main := await _main()
	var options: OptionsMenu = main.get_node("OverlayLayer/OptionsMenu")
	main.get_node("MenuLayer/MainMenu").options_pressed.emit()
	assert_bool(options.visible).is_true()
	options.close()
	assert_bool(options.visible).is_false()


func test_playtest_starts_a_run_with_the_tweaked_ruleset() -> void:
	var main := await _main()
	main.get_node("MenuLayer/MainMenu").playtest_pressed.emit()
	var picker: RulesetMenu = main.get_node("MenuLayer/RulesetMenu")
	assert_bool(picker.visible).is_true()
	var stepper: IntStepper = _find_stepper(picker, "Starting Gold")
	stepper.value += 5
	_find_button(picker, "Start run").pressed.emit()
	await get_tree().process_frame
	var run: RunScreen = main.get_node("RunScreen")
	assert_int(run.rules.starting_gold).is_equal(45)
	# The variant file itself is untouched.
	var standard: RulesetDef = load("res://content/rulesets/standard.tres")
	assert_int(standard.starting_gold).is_equal(40)


func test_playtest_back_returns_to_the_main_menu() -> void:
	var main := await _main()
	var menu: MainMenu = main.get_node("MenuLayer/MainMenu")
	menu.playtest_pressed.emit()
	assert_bool(menu.visible).is_false()
	(main.get_node("MenuLayer/RulesetMenu") as RulesetMenu).close()
	assert_bool(menu.visible).is_true()


func _find_stepper(root: Node, label_text: String) -> IntStepper:
	for label: Node in root.find_children("*", "Label", true, false):
		if (label as Label).text == label_text:
			return label.get_parent().get_child(1)
	return null


func _find_button(root: Node, text: String) -> Button:
	for button: Node in root.find_children("*", "Button", true, false):
		if (button as Button).text == text:
			return button
	return null
