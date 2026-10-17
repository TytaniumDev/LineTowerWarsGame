extends GdUnitTestSuite


func test_isqrt_matches_floor_of_sqrt() -> void:
	for value: int in [0, 1, 2, 3, 4, 15, 16, 17, 99, 100, 1_000_000, 2_000_000, 123_456_789]:
		var root := SimMath.isqrt(value)
		assert_bool(root * root <= value and (root + 1) * (root + 1) > value).is_true()


func test_isqrt_of_large_squares() -> void:
	assert_int(SimMath.isqrt(30000 * 30000)).is_equal(30000)
	assert_int(SimMath.isqrt(30000 * 30000 - 1)).is_equal(29999)


func test_ceil_div() -> void:
	assert_int(SimMath.ceil_div(10, 5)).is_equal(2)
	assert_int(SimMath.ceil_div(11, 5)).is_equal(3)
	assert_int(SimMath.ceil_div(0, 5)).is_equal(0)
