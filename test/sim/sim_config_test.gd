extends GdUnitTestSuite


func test_ticks_per_second_is_30() -> void:
	assert_int(SimConfig.TICKS_PER_SECOND).is_equal(30)
