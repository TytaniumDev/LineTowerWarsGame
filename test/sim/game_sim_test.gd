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
