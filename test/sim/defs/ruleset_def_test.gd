extends GdUnitTestSuite


func _wave(creep: CreepDef, count: int) -> WaveDef:
	var entry := WaveEntry.new()
	entry.creep = creep
	entry.count = count
	var wave := WaveDef.new()
	wave.entries = [entry]
	return wave


func test_wave_expands_entries_in_order() -> void:
	var a := CreepDef.new()
	var b := CreepDef.new()
	var wave := _wave(a, 2)
	wave.entries.append(_wave(b, 1).entries[0])
	assert_array(wave.creeps()).is_equal([a, a, b])


func test_rounds_past_the_list_repeat_the_last_wave() -> void:
	var rules := RulesetDef.new()
	var first := _wave(CreepDef.new(), 1)
	var last := _wave(CreepDef.new(), 2)
	rules.waves = [first, last]
	assert_object(rules.wave_for_round(1)).is_same(first)
	assert_object(rules.wave_for_round(2)).is_same(last)
	assert_object(rules.wave_for_round(9)).is_same(last)


func test_no_waves_gives_an_empty_wave() -> void:
	assert_array(RulesetDef.new().wave_for_round(1).creeps()).is_empty()
