extends GdUnitTestSuite


func test_loads_all_towers_and_creeps() -> void:
	var registry := ContentLoader.load_registry()
	assert_int(registry.towers.size()).is_equal(3)
	assert_int(registry.creeps.size()).is_equal(4)
	assert_object(registry.tower(&"arrow")).is_not_null()
	assert_object(registry.creep(&"grunt")).is_not_null()
