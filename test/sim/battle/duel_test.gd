extends GdUnitTestSuite


func _rules() -> RulesetDef:
	var rules := RulesetDef.new()
	rules.id = &"test"
	rules.wave_spacing = 10
	rules.send_spacing = 5
	return rules


func _grid() -> LaneGrid:
	var lane := LaneDef.new()
	lane.size = Vector2i(3, 6)
	lane.spawn_cells = [Vector2i(1, 0)]
	lane.exit_cells = [Vector2i(1, 5)]
	lane.allow_diagonal = false
	return LaneGrid.new(lane)


func _creep() -> CreepDef:
	var creep := CreepDef.new()
	creep.id = &"c"
	creep.max_hp = 10
	creep.speed = 1000
	creep.bounty = 2
	return creep


func _killer_side(sends: Array[CreepDef] = []) -> DuelSide:
	var tower := TowerDef.new()
	tower.id = &"t"
	tower.damage = 100
	tower.attack_range = 10000
	tower.attack_interval = 1
	var grid := _grid()
	grid.place(Vector2i(0, 2))
	return DuelSide.new(grid, [TowerState.new(tower, Vector2i(0, 2))], sends)


func _empty_side(sends: Array[CreepDef] = []) -> DuelSide:
	return DuelSide.new(_grid(), [], sends)


func _wave(count: int) -> WaveDef:
	var entry := WaveEntry.new()
	entry.creep = _creep()
	entry.count = count
	var wave := WaveDef.new()
	wave.entries = [entry]
	return wave


func test_fewer_leaks_wins() -> void:
	var duel := Duel.new(_rules(), _wave(3), _killer_side(), _empty_side())
	assert_int(duel.run()).is_equal(Duel.Outcome.WIN)
	assert_int(duel.home_leaks()).is_equal(0)
	assert_int(duel.away_leaks()).is_equal(3)
	assert_int(duel.home.bounty_earned).is_equal(6)


func test_more_leaks_loses() -> void:
	var duel := Duel.new(_rules(), _wave(2), _empty_side(), _killer_side())
	assert_int(duel.run()).is_equal(Duel.Outcome.LOSS)


func test_equal_leaks_is_a_draw() -> void:
	var duel := Duel.new(_rules(), _wave(2), _empty_side(), _empty_side())
	assert_int(duel.run()).is_equal(Duel.Outcome.DRAW)


func test_each_lane_faces_the_other_sides_sends() -> void:
	var sends: Array[CreepDef] = [_creep(), _creep()]
	var duel := Duel.new(_rules(), WaveDef.new(), _empty_side(sends), _empty_side())
	assert_int(duel.run()).is_equal(Duel.Outcome.WIN)
	assert_int(duel.home_leaks()).is_equal(0)
	assert_int(duel.away_leaks()).is_equal(2)


func test_sends_interleave_with_the_wave_by_default() -> void:
	var sends: Array[CreepDef] = [_creep()]
	var duel := Duel.new(_rules(), _wave(3), _empty_side(), _empty_side(sends))
	# Wave creeps enter at ticks 0, 10, 20; the send enters halfway between the first two.
	assert_int(_spawn_tick(duel, sends[0])).is_equal(5)


func test_sends_can_enter_after_the_wave() -> void:
	var rules := _rules()
	rules.send_timing = RulesetDef.SendTiming.AFTER_WAVE
	var sends: Array[CreepDef] = [_creep()]
	var duel := Duel.new(rules, _wave(3), _empty_side(), _empty_side(sends))
	# Three wave creeps 10 ticks apart, so the send enters at tick 30.
	assert_int(_spawn_tick(duel, sends[0])).is_equal(30)


## Tick at which `send` first appears in the home lane, or -1 if it never does.
func _spawn_tick(duel: Duel, send: CreepDef) -> int:
	while not duel.is_finished():
		duel.step()
		for creep: CreepState in duel.home.creeps:
			if creep.def == send:
				return duel.home.tick - 1
	return -1


func test_sends_can_enter_before_the_wave() -> void:
	var rules := _rules()
	rules.send_timing = RulesetDef.SendTiming.BEFORE_WAVE
	var sends: Array[CreepDef] = [_creep(), _creep()]
	var duel := Duel.new(rules, _wave(1), _empty_side(), _empty_side(sends))
	duel.step()
	assert_object(duel.home.creeps[0].def).is_same(sends[0])


func test_unresolved_creeps_count_as_leaks_at_the_tick_limit() -> void:
	var rules := _rules()
	rules.battle_tick_limit = 1
	var duel := Duel.new(rules, _wave(4), _killer_side(), _empty_side())
	duel.run()
	assert_bool(duel.is_finished()).is_true()
	# The tower killed the first creep instantly; the other three never finished.
	assert_int(duel.home_leaks()).is_equal(3)
	assert_int(duel.away_leaks()).is_equal(4)
	assert_int(duel.outcome()).is_equal(Duel.Outcome.WIN)


func test_same_inputs_give_the_same_result() -> void:
	var a := Duel.new(_rules(), _wave(5), _killer_side([_creep()]), _empty_side([_creep()]))
	var b := Duel.new(_rules(), _wave(5), _killer_side([_creep()]), _empty_side([_creep()]))
	a.run()
	b.run()
	assert_int(a.tick).is_equal(b.tick)
	assert_int(a.home_leaks()).is_equal(b.home_leaks())
	assert_int(a.away_leaks()).is_equal(b.away_leaks())
