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
