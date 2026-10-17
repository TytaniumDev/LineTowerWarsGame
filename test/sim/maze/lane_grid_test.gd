extends GdUnitTestSuite

const OK := LaneGrid.PlaceResult.OK


func _lane(size: Vector2i, spawn: Vector2i, exit: Vector2i, diagonal: bool = true) -> LaneDef:
	var lane := LaneDef.new()
	lane.size = size
	lane.spawn_cells = [spawn]
	lane.exit_cells = [exit]
	lane.allow_diagonal = diagonal
	return lane


func _grid(diagonal: bool = true) -> LaneGrid:
	return LaneGrid.new(_lane(Vector2i(5, 6), Vector2i(2, 0), Vector2i(2, 5), diagonal))


func test_placing_on_open_cell_succeeds() -> void:
	var grid := _grid()
	assert_int(grid.place(Vector2i(2, 2))).is_equal(OK)
	assert_bool(grid.is_blocked(Vector2i(2, 2))).is_true()


func test_rejects_out_of_bounds_occupied_and_reserved() -> void:
	var grid := _grid()
	grid.place(Vector2i(1, 1))
	assert_int(grid.place(Vector2i(5, 0))).is_equal(LaneGrid.PlaceResult.OUT_OF_BOUNDS)
	assert_int(grid.place(Vector2i(1, 1))).is_equal(LaneGrid.PlaceResult.OCCUPIED)
	assert_int(grid.place(Vector2i(2, 0))).is_equal(LaneGrid.PlaceResult.RESERVED)
	assert_int(grid.place(Vector2i(2, 5))).is_equal(LaneGrid.PlaceResult.RESERVED)


func test_rejects_placement_that_fully_blocks_and_leaves_grid_unchanged() -> void:
	var grid := _grid()
	for x: int in [0, 1, 3, 4]:
		assert_int(grid.place(Vector2i(x, 3))).is_equal(OK)
	assert_int(grid.check_place(Vector2i(2, 3))).is_equal(LaneGrid.PlaceResult.BLOCKS_PATH)
	assert_int(grid.place(Vector2i(2, 3))).is_equal(LaneGrid.PlaceResult.BLOCKS_PATH)
	assert_bool(grid.is_blocked(Vector2i(2, 3))).is_false()
	assert_array(grid.path_to_exit(Vector2i(2, 0))).is_not_empty()


func test_creeps_cannot_squeeze_between_corner_touching_towers() -> void:
	var grid := LaneGrid.new(_lane(Vector2i(3, 3), Vector2i(0, 0), Vector2i(2, 2)))
	assert_int(grid.place(Vector2i(1, 0))).is_equal(OK)
	assert_int(grid.place(Vector2i(0, 1))).is_equal(LaneGrid.PlaceResult.BLOCKS_PATH)


func test_removing_a_tower_reopens_the_cell() -> void:
	var grid := _grid()
	grid.place(Vector2i(2, 2))
	grid.remove(Vector2i(2, 2))
	assert_bool(grid.is_blocked(Vector2i(2, 2))).is_false()
	assert_int(grid.place(Vector2i(2, 2))).is_equal(OK)


func test_open_lane_path_goes_straight_down() -> void:
	var path := _grid().path_to_exit(Vector2i(2, 0))
	assert_array(path).is_equal(
		[
			Vector2i(2, 0),
			Vector2i(2, 1),
			Vector2i(2, 2),
			Vector2i(2, 3),
			Vector2i(2, 4),
			Vector2i(2, 5)
		]
	)
	assert_int(LaneGrid.path_cost(path)).is_equal(5 * LaneGrid.STRAIGHT_COST)


func test_diagonal_lane_uses_diagonal_steps() -> void:
	var grid := LaneGrid.new(_lane(Vector2i(5, 5), Vector2i(0, 0), Vector2i(4, 4)))
	var path := grid.path_to_exit(Vector2i(0, 0))
	assert_int(LaneGrid.path_cost(path)).is_equal(4 * LaneGrid.DIAGONAL_COST)


func test_straight_only_lane_never_moves_diagonally() -> void:
	var grid := LaneGrid.new(_lane(Vector2i(5, 5), Vector2i(0, 0), Vector2i(4, 4), false))
	var path := grid.path_to_exit(Vector2i(0, 0))
	assert_int(path.size()).is_equal(9)
	for i: int in range(1, path.size()):
		var step := path[i] - path[i - 1]
		assert_int(absi(step.x) + absi(step.y)).is_equal(1)


func test_picks_the_nearest_exit() -> void:
	var lane := _lane(Vector2i(5, 6), Vector2i(0, 0), Vector2i(4, 5))
	lane.exit_cells = [Vector2i(4, 5), Vector2i(0, 5)]
	var path := LaneGrid.new(lane).path_to_exit(Vector2i(0, 0))
	assert_object(path.back()).is_equal(Vector2i(0, 5))


func test_same_maze_gives_same_path() -> void:
	var a := _grid()
	var b := _grid()
	for cell: Vector2i in [Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 4)]:
		a.place(cell)
		b.place(cell)
	assert_array(a.path_to_exit(Vector2i(2, 0))).is_equal(b.path_to_exit(Vector2i(2, 0)))


func test_standard_lane_content_is_open_end_to_end() -> void:
	var grid := LaneGrid.new(load("res://content/lanes/standard.tres"))
	for spawn: Vector2i in grid.lane.spawn_cells:
		assert_array(grid.path_to_exit(spawn)).is_not_empty()
