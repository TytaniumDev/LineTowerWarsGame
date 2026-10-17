extends GdUnitTestSuite


func _tower(id: StringName) -> TowerDef:
	var tower := TowerDef.new()
	tower.id = id
	return tower


func test_default_tower_is_valid() -> void:
	assert_array(_tower(&"t").validate()).is_empty()


func test_branching_upgrades_hold_both_paths() -> void:
	var arrow := _tower(&"arrow")
	arrow.upgrades = [_tower(&"sniper"), _tower(&"rapid")]
	assert_array(arrow.validate()).is_empty()
	(
		assert_array(arrow.upgrades.map(func(t: TowerDef) -> StringName: return t.id))
		. is_equal([&"sniper", &"rapid"])
	)


func test_slow_without_duration_is_invalid() -> void:
	var tower := _tower(&"frost")
	tower.slow_percent = 40
	assert_array(tower.validate()).is_not_empty()


func test_missing_id_is_invalid() -> void:
	assert_array(TowerDef.new().validate()).is_not_empty()


func test_targeting_defaults_to_first() -> void:
	assert_int(TowerDef.new().targeting).is_equal(TowerDef.Targeting.FIRST)
