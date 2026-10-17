extends GdUnitTestSuite


func _tower(id: StringName) -> TowerDef:
	var tower := TowerDef.new()
	tower.id = id
	return tower


func test_upgrades_are_registered_with_their_base_tower() -> void:
	var base := _tower(&"arrow")
	var sniper := _tower(&"sniper")
	var marksman := _tower(&"marksman")
	sniper.upgrades = [marksman]
	base.upgrades = [sniper]
	var registry := ContentRegistry.new()
	registry.add_tower(base)
	assert_object(registry.tower(&"arrow")).is_same(base)
	assert_object(registry.tower(&"sniper")).is_same(sniper)
	assert_object(registry.tower(&"marksman")).is_same(marksman)


func test_unknown_ids_return_null() -> void:
	var registry := ContentRegistry.new()
	assert_object(registry.tower(&"nope")).is_null()
	assert_object(registry.creep(&"nope")).is_null()
