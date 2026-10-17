extends GdUnitTestSuite


func _draw(rng: SimRng, count: int) -> Array[int]:
	var values: Array[int] = []
	for i: int in count:
		values.append(rng.range_int(0, 1_000_000))
	return values


func test_same_seed_gives_same_sequence() -> void:
	assert_array(_draw(SimRng.new(42), 20)).is_equal(_draw(SimRng.new(42), 20))


func test_different_seeds_give_different_sequences() -> void:
	assert_array(_draw(SimRng.new(1), 20)).is_not_equal(_draw(SimRng.new(2), 20))


## Pins the exact output for one seed. If a Godot upgrade changes its RNG, this fails
## and stored snapshots would no longer replay the same way.
func test_golden_sequence_is_stable_across_engine_versions() -> void:
	assert_array(_draw(SimRng.new(12345), 5)).is_equal([475635, 539730, 724893, 335957, 463321])


func test_range_int_stays_within_inclusive_bounds() -> void:
	var rng := SimRng.new(7)
	var seen_min := false
	var seen_max := false
	for i: int in 1000:
		var value := rng.range_int(-2, 2)
		assert_int(value).is_between(-2, 2)
		seen_min = seen_min or value == -2
		seen_max = seen_max or value == 2
	assert_bool(seen_min and seen_max).is_true()


func test_chance_extremes() -> void:
	var rng := SimRng.new(3)
	for i: int in 100:
		assert_bool(rng.chance(0, 10)).is_false()
		assert_bool(rng.chance(10, 10)).is_true()


func test_restoring_state_replays_the_sequence() -> void:
	var rng := SimRng.new(99)
	_draw(rng, 3)
	var saved := rng.get_state()
	var expected := _draw(rng, 10)
	rng.set_state(saved)
	assert_array(_draw(rng, 10)).is_equal(expected)
