extends GdUnitTestSuite


func _content() -> ContentRegistry:
	var registry := ContentRegistry.new()
	var tower := TowerDef.new()
	tower.id = &"arrow"
	tower.cost = 10
	registry.add_tower(tower)
	var creep := CreepDef.new()
	creep.id = &"grunt"
	creep.send_cost = 5
	creep.group_size = 1
	registry.add_creep(creep)
	return registry


func _lane() -> LaneDef:
	var lane := LaneDef.new()
	lane.id = &"test_lane"
	lane.size = Vector2i(5, 8)
	lane.spawn_cells = [Vector2i(2, 0)]
	lane.exit_cells = [Vector2i(2, 7)]
	return lane


func _player(content: ContentRegistry) -> PlayerState:
	var rules := RulesetDef.new()
	rules.id = &"test_rules"
	rules.starting_gold = 100
	var player := PlayerState.new(rules, _lane())
	player.start_round()
	player.place_tower(content.tower(&"arrow"), Vector2i(1, 3))
	player.place_tower(content.tower(&"arrow"), Vector2i(3, 4))
	player.buy_send(content.creep(&"grunt"))
	player.finish_round(Duel.Outcome.LOSS, 0)
	return player


func test_round_trips_through_json() -> void:
	var content := _content()
	var original := Snapshot.from_player(_player(content))
	var json := JSON.stringify(original.to_dict())
	var restored := Snapshot.from_dict(JSON.parse_string(json), content)
	assert_object(restored).is_not_null()
	assert_dict(restored.to_dict()).is_equal(original.to_dict())
	assert_int(restored.round_number).is_equal(1)
	assert_int(restored.losses).is_equal(1)
	assert_int(restored.gold).is_equal(75)
	assert_str(String(restored.ruleset_id)).is_equal("test_rules")
	assert_object(restored.maze[1].def).is_same(content.tower(&"arrow"))
	assert_object(restored.maze[1].cell).is_equal(Vector2i(3, 4))
	assert_object(restored.army[0]).is_same(content.creep(&"grunt"))


func test_unknown_content_is_rejected() -> void:
	var data := Snapshot.from_player(_player(_content())).to_dict()
	data["army"] = ["dragon"]
	assert_object(Snapshot.from_dict(data, _content())).is_null()


func test_other_schema_versions_are_rejected() -> void:
	var data := Snapshot.from_player(_player(_content())).to_dict()
	data["schema_version"] = Snapshot.SCHEMA_VERSION + 1
	assert_object(Snapshot.from_dict(data, _content())).is_null()


func test_malformed_maze_is_rejected() -> void:
	var data := Snapshot.from_player(_player(_content())).to_dict()
	data["maze"] = [{"tower_id": "arrow", "cell": [1]}]
	assert_object(Snapshot.from_dict(data, _content())).is_null()


func test_duel_side_rebuilds_the_maze() -> void:
	var snapshot := Snapshot.from_player(_player(_content()))
	var side := snapshot.duel_side(_lane())
	assert_int(side.towers.size()).is_equal(2)
	assert_bool(side.grid.is_blocked(Vector2i(1, 3))).is_true()
	assert_int(side.army.size()).is_equal(1)


func test_duel_side_skips_towers_that_no_longer_fit() -> void:
	var snapshot := Snapshot.from_player(_player(_content()))
	var smaller := _lane()
	smaller.size = Vector2i(5, 4)
	smaller.exit_cells = [Vector2i(2, 3)]
	assert_int(snapshot.duel_side(smaller).towers.size()).is_equal(1)
