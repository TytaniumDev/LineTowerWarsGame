extends GdUnitTestSuite


func _lane() -> LaneDef:
	var lane := LaneDef.new()
	lane.size = Vector2i(5, 10)
	lane.spawn_cells = [Vector2i(2, 0)]
	lane.exit_cells = [Vector2i(2, 9)]
	return lane


func test_valid_lane_has_no_errors() -> void:
	assert_array(_lane().validate()).is_empty()


func test_contains_checks_bounds() -> void:
	var lane := _lane()
	assert_bool(lane.contains(Vector2i(0, 0))).is_true()
	assert_bool(lane.contains(Vector2i(4, 9))).is_true()
	assert_bool(lane.contains(Vector2i(5, 0))).is_false()
	assert_bool(lane.contains(Vector2i(0, -1))).is_false()


func test_cells_outside_lane_are_invalid() -> void:
	var lane := _lane()
	lane.exit_cells = [Vector2i(2, 10)]
	assert_array(lane.validate()).is_not_empty()


func test_lane_needs_spawn_and_exit() -> void:
	var lane := _lane()
	lane.spawn_cells = []
	assert_array(lane.validate()).is_not_empty()
