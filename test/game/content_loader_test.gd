extends GdUnitTestSuite


func test_loads_all_towers_and_creeps() -> void:
	var registry := ContentLoader.load_registry()
	# Three base towers, each with a level 2 that branches into two upgrades.
	assert_int(registry.towers.size()).is_equal(12)
	assert_int(registry.creeps.size()).is_equal(4)
	assert_object(registry.tower(&"arrow")).is_not_null()
	assert_object(registry.tower(&"sniper")).is_not_null()
	assert_object(registry.creep(&"grunt")).is_not_null()
