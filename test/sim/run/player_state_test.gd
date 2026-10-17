extends GdUnitTestSuite

const OK := PlayerState.Result.OK


func _rules() -> RulesetDef:
	var rules := RulesetDef.new()
	rules.id = &"test"
	rules.starting_gold = 100
	rules.base_income = 10
	rules.sell_refund_percent = 50
	rules.starting_lives = 3
	rules.wins_to_finish = 2
	return rules


func _lane() -> LaneDef:
	var lane := LaneDef.new()
	lane.size = Vector2i(5, 8)
	lane.spawn_cells = [Vector2i(2, 0)]
	lane.exit_cells = [Vector2i(2, 7)]
	return lane


func _tower(cost: int) -> TowerDef:
	var tower := TowerDef.new()
	tower.id = &"t"
	tower.cost = cost
	return tower


func _player() -> PlayerState:
	var player := PlayerState.new(_rules(), _lane())
	player.start_round()
	return player


func test_starts_with_ruleset_gold_lives_and_income() -> void:
	var player := _player()
	assert_int(player.round_number).is_equal(1)
	assert_int(player.gold).is_equal(100)
	assert_int(player.income).is_equal(10)
	assert_int(player.lives).is_equal(3)


func test_income_is_paid_from_round_two() -> void:
	var player := _player()
	player.start_round()
	assert_int(player.gold).is_equal(110)


func test_placing_costs_gold_and_blocks_the_cell() -> void:
	var player := _player()
	assert_int(player.place_tower(_tower(30), Vector2i(1, 3))).is_equal(OK)
	assert_int(player.gold).is_equal(70)
	assert_bool(player.grid.is_blocked(Vector2i(1, 3))).is_true()


func test_cannot_place_without_gold_or_on_bad_cells() -> void:
	var player := _player()
	assert_int(player.place_tower(_tower(500), Vector2i(1, 3))).is_equal(
		PlayerState.Result.NOT_ENOUGH_GOLD
	)
	assert_int(player.place_tower(_tower(1), Vector2i(2, 0))).is_equal(PlayerState.Result.RESERVED)
	assert_int(player.gold).is_equal(100)


func test_selling_same_round_refunds_in_full() -> void:
	var player := _player()
	player.place_tower(_tower(30), Vector2i(1, 3))
	assert_int(player.sell_tower(Vector2i(1, 3))).is_equal(OK)
	assert_int(player.gold).is_equal(100)
	assert_bool(player.grid.is_blocked(Vector2i(1, 3))).is_false()


func test_selling_later_refunds_half_of_older_spend() -> void:
	var player := _player()
	player.place_tower(_tower(30), Vector2i(1, 3))
	player.start_round()
	assert_int(player.sell_value(Vector2i(1, 3))).is_equal(15)


func test_upgrade_this_round_on_old_tower_refunds_upgrade_in_full() -> void:
	var player := _player()
	var base := _tower(30)
	var better := _tower(20)
	base.upgrades = [better]
	player.place_tower(base, Vector2i(1, 3))
	player.start_round()
	assert_int(player.upgrade_tower(Vector2i(1, 3), 0)).is_equal(OK)
	assert_object(player.towers[Vector2i(1, 3)].def).is_same(better)
	assert_int(player.sell_value(Vector2i(1, 3))).is_equal(20 + 15)


func test_branching_upgrade_picks_the_chosen_path() -> void:
	var player := _player()
	var base := _tower(10)
	var left := _tower(5)
	var right := _tower(5)
	base.upgrades = [left, right]
	player.place_tower(base, Vector2i(1, 3))
	assert_int(player.upgrade_tower(Vector2i(1, 3), 1)).is_equal(OK)
	assert_object(player.towers[Vector2i(1, 3)].def).is_same(right)
	assert_int(player.upgrade_tower(Vector2i(1, 3), 0)).is_equal(PlayerState.Result.INVALID_UPGRADE)


func test_sends_cost_gold_raise_income_and_keep_order() -> void:
	var player := _player()
	var swarm := CreepDef.new()
	swarm.send_cost = 6
	swarm.income_bonus = 1
	swarm.group_size = 3
	var tank := CreepDef.new()
	tank.send_cost = 15
	tank.income_bonus = 3
	assert_int(player.buy_send(tank)).is_equal(OK)
	assert_int(player.buy_send(swarm)).is_equal(OK)
	assert_int(player.gold).is_equal(100 - 21)
	assert_int(player.income).is_equal(14)
	assert_array(player.army).is_equal([tank, swarm, swarm, swarm])
	assert_int(player.undo_last_send()).is_equal(OK)
	assert_array(player.army).is_equal([tank])
	assert_int(player.income).is_equal(13)


func test_army_clears_each_round_but_income_stays() -> void:
	var player := _player()
	var grunt := CreepDef.new()
	grunt.send_cost = 5
	grunt.income_bonus = 1
	player.buy_send(grunt)
	player.start_round()
	assert_array(player.army).is_empty()
	assert_int(player.income).is_equal(11)


func test_run_ends_at_zero_lives_or_enough_wins() -> void:
	var player := _player()
	assert_bool(player.is_run_over()).is_false()
	player.wins = 2
	assert_bool(player.is_run_over()).is_true()
	player.wins = 0
	player.lives = 0
	assert_bool(player.is_run_over()).is_true()
