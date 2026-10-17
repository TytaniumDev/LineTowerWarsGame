extends GdUnitTestSuite
## Smoke test: the run screen loads content and opens round 1's build phase.


func test_starts_a_run_in_the_build_phase() -> void:
	var main: Node = auto_free(load("res://game/run_screen.tscn").instantiate())
	add_child(main)
	await get_tree().process_frame
	var build: BuildController = main.get_node("BuildController")
	assert_bool(build.active).is_true()
	assert_int(build.player.round_number).is_equal(1)
	assert_int(build.towers.size()).is_equal(3)
	assert_bool(main.get_node("HUD/BuildPanel").visible).is_true()
	assert_bool(main.get_node("HUD/BattleHud").visible).is_false()
