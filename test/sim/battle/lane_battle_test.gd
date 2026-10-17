extends GdUnitTestSuite

const TPS := SimConfig.TICKS_PER_SECOND


func _grid(walls: Array[Vector2i] = []) -> LaneGrid:
	var lane := LaneDef.new()
	lane.size = Vector2i(3, 10)
	lane.spawn_cells = [Vector2i(1, 0)]
	lane.exit_cells = [Vector2i(1, 9)]
	lane.allow_diagonal = false
	var grid := LaneGrid.new(lane)
	for wall: Vector2i in walls:
		grid.place(wall)
	return grid


func _creep(hp: int = 100, speed: int = 1000, armor: int = 0) -> CreepDef:
	var creep := CreepDef.new()
	creep.id = &"test"
	creep.max_hp = hp
	creep.speed = speed
	creep.armor = armor
	creep.bounty = 3
	return creep


func _tower(damage: int, attack_range: int = 20000) -> TowerDef:
	var tower := TowerDef.new()
	tower.id = &"test"
	tower.damage = damage
	tower.attack_range = attack_range
	tower.attack_interval = 10
	return tower


func _run(battle: LaneBattle, max_ticks: int = 10000) -> void:
	while not battle.is_finished() and battle.tick < max_ticks:
		battle.step()


func test_unopposed_creep_walks_the_path_and_leaks() -> void:
	var battle := LaneBattle.new(_grid(), [])
	battle.queue_creeps([_creep()], 0, 0)
	_run(battle)
	assert_int(battle.leaks).is_equal(1)
	assert_int(battle.kills).is_equal(0)
	# 9 cells at one cell per second.
	assert_int(battle.tick).is_equal(9 * TPS)


func test_tower_kills_creep_and_earns_bounty() -> void:
	var tower := TowerState.new(_tower(10), Vector2i(0, 5))
	var battle := LaneBattle.new(_grid([Vector2i(0, 5)]), [tower])
	battle.queue_creeps([_creep(20)], 0, 0)
	_run(battle)
	assert_int(battle.kills).is_equal(1)
	assert_int(battle.leaks).is_equal(0)
	assert_int(battle.bounty_earned).is_equal(3)


func test_armor_reduces_each_hit() -> void:
	var tower := TowerState.new(_tower(10), Vector2i(0, 5))
	var battle := LaneBattle.new(_grid([Vector2i(0, 5)]), [tower])
	battle.queue_creeps([_creep(100, 1000, 8)], 0, 0)
	battle.step()
	assert_int(battle.creeps[0].hp).is_equal(98)


func test_out_of_range_tower_never_fires() -> void:
	var tower := TowerState.new(_tower(1000, 100), Vector2i(0, 5))
	var battle := LaneBattle.new(_grid([Vector2i(0, 5)]), [tower])
	battle.queue_creeps([_creep()], 0, 0)
	_run(battle)
	assert_int(battle.leaks).is_equal(1)


func test_splash_hits_nearby_creeps() -> void:
	var def := _tower(10)
	def.splash_radius = 500
	var battle := LaneBattle.new(_grid([Vector2i(0, 5)]), [TowerState.new(def, Vector2i(0, 5))])
	battle.queue_creeps([_creep(), _creep()], 0, 0)
	battle.step()
	assert_int(battle.creeps[0].hp).is_equal(90)
	assert_int(battle.creeps[1].hp).is_equal(90)


func test_slow_delays_the_leak() -> void:
	var def := _tower(0)
	def.slow_percent = 50
	def.slow_duration = 10000
	var battle := LaneBattle.new(_grid([Vector2i(0, 5)]), [TowerState.new(def, Vector2i(0, 5))])
	battle.queue_creeps([_creep()], 0, 0)
	_run(battle)
	assert_int(battle.leaks).is_equal(1)
	assert_int(battle.tick).is_greater(9 * TPS + 4 * TPS)


func test_creeps_spawn_in_the_order_queued() -> void:
	var tank := _creep(300)
	var runner := _creep(30)
	var battle := LaneBattle.new(_grid(), [])
	battle.queue_creeps([tank, runner, tank], 0, 15)
	for i: int in 31:
		battle.step()
	(
		assert_array(battle.creeps.map(func(c: CreepState) -> int: return c.def.max_hp))
		. is_equal([300, 30, 300])
	)


func test_first_targets_the_creep_closest_to_leaking() -> void:
	var tower := TowerState.new(_tower(1), Vector2i(0, 5))
	var battle := LaneBattle.new(_grid([Vector2i(0, 5)]), [tower])
	battle.queue_creeps([_creep(), _creep()], 0, 15)
	for i: int in 16:
		battle.step()
	tower.cooldown = 0
	var target := battle.pick_target(tower)
	assert_int(target.id).is_equal(0)


func test_strongest_targets_the_most_hp() -> void:
	var def := _tower(1)
	def.targeting = TowerDef.Targeting.STRONGEST
	var tower := TowerState.new(def, Vector2i(0, 5))
	var battle := LaneBattle.new(_grid([Vector2i(0, 5)]), [tower])
	battle.queue_creeps([_creep(50), _creep(200)], 0, 15)
	for i: int in 16:
		battle.step()
	assert_int(battle.pick_target(tower).def.max_hp).is_equal(200)


func test_unslowed_skips_slowed_creeps() -> void:
	var def := _tower(1)
	def.targeting = TowerDef.Targeting.UNSLOWED
	var tower := TowerState.new(def, Vector2i(0, 5))
	var battle := LaneBattle.new(_grid([Vector2i(0, 5)]), [tower])
	battle.queue_creeps([_creep(), _creep()], 0, 15)
	for i: int in 16:
		battle.step()
	battle.creeps[0].slow_ticks_left = 30
	battle.creeps[0].slow_percent = 40
	assert_int(battle.pick_target(tower).id).is_equal(1)
	battle.creeps[1].slow_ticks_left = 30
	assert_int(battle.pick_target(tower).id).is_equal(0)


func test_same_inputs_give_same_result_with_real_content() -> void:
	var results: Array[Array] = []
	for run: int in 2:
		var lane: LaneDef = load("res://content/lanes/standard.tres")
		var grid := LaneGrid.new(lane)
		var towers: Array[TowerState] = []
		var tower_files := ["arrow", "cannon", "frost", "arrow"]
		var cells := [Vector2i(4, 10), Vector2i(6, 12), Vector2i(5, 14), Vector2i(3, 16)]
		for i: int in cells.size():
			grid.place(cells[i])
			var def: TowerDef = load("res://content/towers/%s.tres" % tower_files[i])
			towers.append(TowerState.new(def, cells[i]))
		var battle := LaneBattle.new(grid, towers)
		var army: Array[CreepDef] = []
		for creep_file: String in ["tank", "runner", "swarm", "grunt", "grunt", "runner"]:
			army.append(load("res://content/creeps/%s.tres" % creep_file))
		battle.queue_creeps(army, 0, 10)
		_run(battle)
		results.append([battle.tick, battle.leaks, battle.kills, battle.bounty_earned])
	assert_bool(results[0][0] > 0).is_true()
	assert_array(results[0]).is_equal(results[1])


func _homing(damage: int, speed: int) -> TowerDef:
	var def := _tower(damage)
	def.projectile_speed = speed
	return def


func test_homing_shot_lands_after_flight_time() -> void:
	# Tower at (0,5), creep enters at (1,0): about 5 cells away, at 5 cells per second.
	var tower := TowerState.new(_homing(10, 5000), Vector2i(0, 5))
	var battle := LaneBattle.new(_grid([Vector2i(0, 5)]), [tower])
	battle.queue_creeps([_creep()], 0, 0)
	battle.step()
	assert_int(battle.shots.size()).is_equal(1)
	var shot: Shot = battle.shots[0]
	assert_int(shot.land_tick - shot.fire_tick).is_between(28, 32)
	while battle.tick < shot.land_tick:
		battle.step()
	assert_int(battle.creeps[0].hp).is_equal(100)
	battle.step()
	assert_int(battle.creeps[0].hp).is_equal(90)


func test_towers_skip_creeps_that_shots_in_flight_will_kill() -> void:
	var first := TowerState.new(_homing(10, 2000), Vector2i(0, 5))
	var second := TowerState.new(_homing(10, 2000), Vector2i(2, 5))
	var battle := LaneBattle.new(_grid([Vector2i(0, 5), Vector2i(2, 5)]), [first, second])
	battle.queue_creeps([_creep(10)], 0, 0)
	battle.step()
	assert_int(battle.shots.size()).is_equal(1)
	_run(battle)
	assert_int(battle.kills).is_equal(1)


func test_shot_disappears_if_target_already_leaked() -> void:
	var tower := TowerState.new(_homing(1000, 100), Vector2i(0, 8))
	var battle := LaneBattle.new(_grid([Vector2i(0, 8)]), [tower])
	battle.queue_creeps([_creep(100, 6000)], 0, 0)
	_run(battle)
	assert_int(battle.leaks).is_equal(1)
	assert_int(battle.kills).is_equal(0)
	assert_bool(battle.shots.is_empty()).is_true()
