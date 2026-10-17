extends GdUnitTestSuite


func _lane() -> LaneDef:
	var lane := LaneDef.new()
	lane.id = &"lane"
	lane.size = Vector2i(5, 8)
	lane.spawn_cells = [Vector2i(2, 0)]
	lane.exit_cells = [Vector2i(2, 7)]
	lane.allow_diagonal = false
	return lane


func _rules() -> RulesetDef:
	var rules := RulesetDef.new()
	rules.id = &"test"
	rules.starting_gold = 100
	return rules


func _bot(seed_value: int = 1) -> BuildBot:
	var tower := TowerDef.new()
	tower.id = &"t"
	tower.cost = 10
	var creep := CreepDef.new()
	creep.id = &"c"
	creep.send_cost = 5
	creep.group_size = 1
	return BuildBot.new([tower], [creep], 40, seed_value)


func _played(seed_value: int = 1) -> PlayerState:
	var player := PlayerState.new(_rules(), _lane())
	player.start_round()
	_bot(seed_value).play_build(player)
	return player


func test_spends_the_send_share_then_builds() -> void:
	var player := _played()
	assert_int(player.army.size()).is_equal(8)
	assert_int(player.towers.size()).is_equal(6)
	assert_int(player.gold).is_equal(0)


func test_towers_lengthen_the_path() -> void:
	var player := _played()
	var open_path := LaneGrid.new(_lane()).path_to_exit(Vector2i(2, 0))
	var mazed_path := player.grid.path_to_exit(Vector2i(2, 0))
	assert_int(LaneGrid.path_cost(mazed_path)).is_greater(LaneGrid.path_cost(open_path))


func test_same_seed_builds_the_same_maze() -> void:
	var a := _played(5)
	var b := _played(5)
	assert_array(a.towers.keys()).is_equal(b.towers.keys())
