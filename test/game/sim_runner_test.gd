extends GdUnitTestSuite

const TICK: float = 1.0 / SimConfig.TICKS_PER_SECOND


func _make_runner() -> SimRunner:
	var runner: SimRunner = auto_free(SimRunner.new())
	runner.sim = GameSim.new(1)
	return runner


func test_one_tick_duration_runs_one_tick() -> void:
	var runner := _make_runner()
	assert_int(runner.advance(TICK)).is_equal(1)
	assert_int(runner.sim.tick).is_equal(1)


func test_partial_frames_accumulate_into_a_tick() -> void:
	var runner := _make_runner()
	assert_int(runner.advance(TICK * 0.6)).is_equal(0)
	assert_float(runner.interpolation_alpha).is_equal_approx(0.6, 0.0001)
	assert_int(runner.advance(TICK * 0.6)).is_equal(1)
	assert_float(runner.interpolation_alpha).is_equal_approx(0.2, 0.0001)


func test_speed_multiplies_ticks() -> void:
	var runner := _make_runner()
	runner.speed = 4.0
	assert_int(runner.advance(TICK)).is_equal(4)


func test_paused_runs_no_ticks() -> void:
	var runner := _make_runner()
	runner.paused = true
	assert_int(runner.advance(1.0)).is_equal(0)
	assert_int(runner.sim.tick).is_equal(0)


func test_long_stall_is_capped_and_backlog_dropped() -> void:
	var runner := _make_runner()
	assert_int(runner.advance(5.0)).is_equal(SimRunner.MAX_TICKS_PER_FRAME)
	assert_float(runner.interpolation_alpha).is_equal(0.0)
	assert_int(runner.advance(0.0)).is_equal(0)


func test_without_sim_does_nothing() -> void:
	var runner: SimRunner = auto_free(SimRunner.new())
	assert_int(runner.advance(1.0)).is_equal(0)
