extends GdUnitTestSuite


func _creep(armor: int) -> CreepDef:
	var creep := CreepDef.new()
	creep.id = &"c"
	creep.armor = armor
	return creep


func test_armor_reduces_damage_flat() -> void:
	assert_int(_creep(4).damage_after_armor(10)).is_equal(6)


func test_hits_always_deal_at_least_one() -> void:
	assert_int(_creep(4).damage_after_armor(3)).is_equal(1)
	assert_int(_creep(0).damage_after_armor(0)).is_equal(1)


func test_negative_armor_is_invalid() -> void:
	assert_array(_creep(-1).validate()).is_not_empty()
