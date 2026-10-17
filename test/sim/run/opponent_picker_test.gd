extends GdUnitTestSuite


func _snapshot(round_number: int, wins: int, losses: int) -> Snapshot:
	var snapshot := Snapshot.new()
	snapshot.round_number = round_number
	snapshot.wins = wins
	snapshot.losses = losses
	return snapshot


func test_prefers_the_same_round_and_closest_record() -> void:
	var expected := _snapshot(3, 2, 0)
	var pool: Array[Snapshot] = [_snapshot(3, 0, 2), expected, _snapshot(4, 2, 0)]
	assert_object(OpponentPicker.pick(pool, 3, 2, 0, SimRng.new(1))).is_same(expected)


func test_falls_back_to_the_latest_earlier_round() -> void:
	var earlier := _snapshot(2, 0, 0)
	var pool: Array[Snapshot] = [_snapshot(1, 0, 0), earlier, _snapshot(5, 0, 0)]
	assert_object(OpponentPicker.pick(pool, 4, 0, 0, SimRng.new(1))).is_same(earlier)


func test_returns_null_when_nothing_fits() -> void:
	var pool: Array[Snapshot] = [_snapshot(5, 0, 0)]
	assert_object(OpponentPicker.pick(pool, 2, 0, 0, SimRng.new(1))).is_null()


func test_ties_are_picked_by_the_rng() -> void:
	var pool: Array[Snapshot] = [_snapshot(1, 0, 0), _snapshot(1, 0, 0)]
	var picks: Dictionary[Snapshot, bool] = {}
	var rng := SimRng.new(7)
	for i: int in 20:
		picks[OpponentPicker.pick(pool, 1, 0, 0, rng)] = true
	assert_int(picks.size()).is_equal(2)
