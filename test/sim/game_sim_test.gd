extends GdUnitTestSuite


func test_starts_at_tick_zero() -> void:
	assert_int(GameSim.new(1).tick).is_equal(0)


func test_step_advances_one_tick_and_emits_ticked() -> void:
	var sim := GameSim.new(1)
	var emitted: Array[int] = []
	sim.ticked.connect(func(t: int) -> void: emitted.append(t))
	sim.step()
	sim.step()
	assert_int(sim.tick).is_equal(2)
	assert_array(emitted).is_equal([1, 2])


func test_same_seed_and_steps_give_same_state() -> void:
	var a := GameSim.new(2024)
	var b := GameSim.new(2024)
	for i: int in 300:
		a.step()
		b.step()
	assert_int(a.tick).is_equal(b.tick)
	assert_int(a.rng.get_state()).is_equal(b.rng.get_state())


func test_steps_the_duel_during_a_battle() -> void:
	var lane := LaneDef.new()
	lane.id = &"lane"
	lane.size = Vector2i(3, 5)
	lane.spawn_cells = [Vector2i(1, 0)]
	lane.exit_cells = [Vector2i(1, 4)]
	var creep := CreepDef.new()
	creep.id = &"creep"
	creep.max_hp = 10
	creep.speed = 1000
	var entry := WaveEntry.new()
	entry.creep = creep
	entry.count = 1
	var wave := WaveDef.new()
	wave.entries = [entry]
	var rules := RulesetDef.new()
	rules.id = &"rules"
	rules.waves = [wave]
	var sim := GameSim.new(1)
	var run := sim.start_run(rules, lane, [])
	sim.step()
	assert_object(run.duel).is_null()
	run.end_build()
	sim.step()
	sim.step()
	assert_int(run.duel.tick).is_equal(2)
