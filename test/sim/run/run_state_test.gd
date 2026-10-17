extends GdUnitTestSuite


func _rules() -> RulesetDef:
	var creep := CreepDef.new()
	creep.id = &"grunt"
	creep.max_hp = 10
	creep.speed = 2000
	creep.group_size = 1
	var entry := WaveEntry.new()
	entry.creep = creep
	entry.count = 2
	var wave := WaveDef.new()
	wave.entries = [entry]
	var rules := RulesetDef.new()
	rules.id = &"test"
	rules.starting_lives = 2
	rules.wins_to_finish = 2
	rules.waves = [wave]
	return rules


func _lane() -> LaneDef:
	var lane := LaneDef.new()
	lane.id = &"lane"
	lane.size = Vector2i(3, 6)
	lane.spawn_cells = [Vector2i(1, 0)]
	lane.exit_cells = [Vector2i(1, 5)]
	return lane


func _killer() -> TowerDef:
	var tower := TowerDef.new()
	tower.id = &"killer"
	tower.damage = 100
	tower.attack_range = 10000
	tower.attack_interval = 1
	return tower


func _play_round(run: RunState) -> Duel.Outcome:
	run.end_build()
	run.duel.run()
	return run.finish_battle()


func test_starts_in_round_one_build_phase() -> void:
	var run := RunState.new(_rules(), _lane(), [], SimRng.new(1))
	assert_int(run.phase).is_equal(RunState.Phase.BUILD)
	assert_int(run.player.round_number).is_equal(1)


func test_end_build_returns_the_players_snapshot_and_starts_the_duel() -> void:
	var run := RunState.new(_rules(), _lane(), [], SimRng.new(1))
	run.player.place_tower(_killer(), Vector2i(0, 2))
	var own := run.end_build()
	assert_int(run.phase).is_equal(RunState.Phase.BATTLE)
	assert_int(own.round_number).is_equal(1)
	assert_int(own.maze.size()).is_equal(1)
	assert_object(run.duel).is_not_null()
	assert_object(run.opponent).is_null()


func test_fights_a_snapshot_from_the_pool() -> void:
	var foe := Snapshot.new()
	foe.round_number = 1
	foe.maze = [PlacedTower.new(_killer(), Vector2i(0, 2))]
	var run := RunState.new(_rules(), _lane(), [foe], SimRng.new(1))
	run.end_build()
	assert_object(run.opponent).is_same(foe)
	# The opponent kills the wave in its lane while the player's empty lane leaks it.
	run.duel.run()
	assert_int(run.finish_battle()).is_equal(Duel.Outcome.LOSS)
	assert_int(run.player.lives).is_equal(1)


func test_win_starts_the_next_round() -> void:
	var run := RunState.new(_rules(), _lane(), [], SimRng.new(1))
	run.player.place_tower(_killer(), Vector2i(0, 2))
	assert_int(_play_round(run)).is_equal(Duel.Outcome.WIN)
	assert_int(run.phase).is_equal(RunState.Phase.BUILD)
	assert_int(run.player.round_number).is_equal(2)
	assert_object(run.duel).is_null()


func test_run_ends_at_the_win_target() -> void:
	var run := RunState.new(_rules(), _lane(), [], SimRng.new(1))
	run.player.place_tower(_killer(), Vector2i(0, 2))
	_play_round(run)
	_play_round(run)
	assert_int(run.phase).is_equal(RunState.Phase.RUN_OVER)
	assert_int(run.player.wins).is_equal(2)
