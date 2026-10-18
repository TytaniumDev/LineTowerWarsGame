extends GdUnitTestSuite
## The run screen: content loading, the build phase, and upgrade picking.

const RUN_SCREEN := preload("res://game/run_screen.tscn")


func _run_screen() -> Node:
	var main: Node = auto_free(RUN_SCREEN.instantiate())
	add_child(main)
	await get_tree().process_frame
	return main


func test_starts_a_run_in_the_build_phase() -> void:
	var main := await _run_screen()
	var build: BuildController = main.get_node("BuildController")
	assert_bool(build.active).is_true()
	assert_int(build.player.round_number).is_equal(1)
	assert_int(build.towers.size()).is_equal(3)
	assert_bool(main.get_node("HUD/BuildPanel").visible).is_true()
	assert_bool(main.get_node("HUD/BattleHud").visible).is_false()


func test_upgrading_a_branching_tower_picks_from_the_panel() -> void:
	var main := await _run_screen()
	var build: BuildController = main.get_node("BuildController")
	var panel: BuildPanel = main.get_node("HUD/BuildPanel")
	build.player.gold = 100
	build.player.place_tower(build.towers[0], build.cursor)
	build.choose_tower(0)
	# The first upgrade is linear, so it applies straight away.
	build.call("_request_upgrade")
	var level_2 := build.towers[0].upgrades[0]
	assert_str(build.tower_at_cursor().def.id).is_equal(level_2.id)
	assert_bool(build.active).is_true()
	# Level 2 branches, so the panel takes focus to pick one.
	build.call("_request_upgrade")
	assert_bool(build.active).is_false()
	assert_bool(panel.upgrades_focused()).is_true()
	var choice := get_viewport().gui_get_focus_owner() as Button
	choice.pressed.emit()
	var upgraded := build.tower_at_cursor().def
	assert_bool(upgraded in level_2.upgrades).is_true()
	assert_bool(build.active).is_true()


func test_upgrade_choice_without_gold_stays_in_the_maze() -> void:
	var main := await _run_screen()
	var build: BuildController = main.get_node("BuildController")
	build.player.place_tower(build.towers[0], build.cursor)
	build.player.gold = 0
	build.choose_tower(0)
	build.call("_request_upgrade")
	assert_bool(build.active).is_true()
	assert_str(build.tower_at_cursor().def.id).is_equal(build.towers[0].id)
