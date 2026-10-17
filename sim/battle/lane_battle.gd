class_name LaneBattle
extends RefCounted
## Simulates creeps attacking one maze until every creep has died or leaked.
##
## The maze is fixed for the whole battle, so each spawn's path is computed once.
## Everything iterates in a fixed order (towers by placement, creeps by id) and ties
## break on the lowest creep id, so the same inputs always give the same result.

## Emitted when a creep reaches an exit.
signal creep_leaked(creep: CreepState)
## Emitted when a creep dies.
signal creep_killed(creep: CreepState)

var grid: LaneGrid
var towers: Array[TowerState] = []
## Live creeps, in spawn order.
var creeps: Array[CreepState] = []
## Shots in flight, in the order fired.
var shots: Array[Shot] = []
var leaks: int = 0
var kills: int = 0
## Gold earned from bounties.
var bounty_earned: int = 0
var tick: int = 0

var _spawn_paths: Array[Array] = []
## Pending spawns as [tick, queue order, CreepDef], sorted by tick then queue order.
var _spawn_queue: Array[Array] = []
var _queued_count: int = 0
var _next_creep_id: int = 0
var _next_spawn_index: int = 0


func _init(lane_grid: LaneGrid, placed_towers: Array[TowerState]) -> void:
	grid = lane_grid
	towers = placed_towers
	for spawn: Vector2i in grid.lane.spawn_cells:
		_spawn_paths.append(grid.path_to_exit(spawn))


## Queues creeps to enter in the given order, `spacing` ticks apart, starting at `start_tick`.
func queue_creeps(defs: Array[CreepDef], start_tick: int, spacing: int) -> void:
	for i: int in defs.size():
		_spawn_queue.append([start_tick + i * spacing, _queued_count, defs[i]])
		_queued_count += 1
	_spawn_queue.sort_custom(
		func(a: Array, b: Array) -> bool: return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1])
	)


func is_finished() -> bool:
	return _spawn_queue.is_empty() and creeps.is_empty() and shots.is_empty()


func step() -> void:
	_spawn_due()
	_move_creeps()
	_land_shots()
	_fire_towers()
	_remove_dead()
	tick += 1


func _spawn_due() -> void:
	while not _spawn_queue.is_empty() and _spawn_queue[0][0] <= tick:
		var entry: Array = _spawn_queue.pop_front()
		var path: Array[Vector2i] = []
		path.assign(_spawn_paths[_next_spawn_index % _spawn_paths.size()])
		_next_spawn_index += 1
		creeps.append(CreepState.new(_next_creep_id, entry[2], path))
		_next_creep_id += 1


func _move_creeps() -> void:
	for creep: CreepState in creeps:
		var speed := creep.def.speed
		if creep.is_slowed():
			speed = speed * (100 - creep.slow_percent) / 100
			creep.slow_ticks_left -= 1
		var remaining := speed
		while remaining > 0 and not creep.has_leaked():
			var step := creep.path[creep.path_index + 1] - creep.path[creep.path_index]
			var left_in_segment := CreepState.segment_length(step) - creep.segment_progress
			var moved := mini(remaining, left_in_segment)
			creep.segment_progress += moved
			creep.distance_traveled += moved
			remaining -= moved
			if moved == left_in_segment:
				creep.path_index += 1
				creep.segment_progress = 0


func _fire_towers() -> void:
	for tower: TowerState in towers:
		if tower.cooldown > 0:
			tower.cooldown -= 1
			continue
		var target := pick_target(tower)
		if target == null:
			continue
		_fire(tower, target)
		tower.cooldown = tower.def.attack_interval - 1


func _fire(tower: TowerState, target: CreepState) -> void:
	var speed := tower.def.projectile_speed
	if speed <= 0:
		_hit(tower.def, target)
		return
	var d := target.position() - tower.position()
	var distance := SimMath.isqrt(d.x * d.x + d.y * d.y)
	var flight := maxi(1, SimMath.ceil_div(distance * SimConfig.TICKS_PER_SECOND, speed))
	var shot := Shot.new(tower.def, target, tower.position(), tick, tick + flight)
	target.incoming_damage += shot.reserved_damage
	shots.append(shot)


func _land_shots() -> void:
	var in_flight: Array[Shot] = []
	for shot: Shot in shots:
		if shot.land_tick > tick:
			in_flight.append(shot)
			continue
		var target := _find_creep(shot.target_id)
		if target != null:
			target.incoming_damage -= shot.reserved_damage
			_hit(shot.tower_def, target)
	shots = in_flight


func _find_creep(creep_id: int) -> CreepState:
	for creep: CreepState in creeps:
		if creep.id == creep_id:
			return creep if creep.hp > 0 and not creep.has_leaked() else null
	return null


func _hit(tower_def: TowerDef, target: CreepState) -> void:
	var hit_creeps: Array[CreepState] = [target]
	if tower_def.splash_radius > 0:
		var center := target.position()
		for creep: CreepState in creeps:
			if creep != target and creep.hp > 0 and not creep.has_leaked():
				if _within(creep.position(), center, tower_def.splash_radius):
					hit_creeps.append(creep)
	for creep: CreepState in hit_creeps:
		creep.hp -= creep.def.damage_after_armor(tower_def.damage)
		if tower_def.slow_percent > 0:
			# The strongest active slow wins; durations don't stack.
			if not creep.is_slowed() or tower_def.slow_percent >= creep.slow_percent:
				creep.slow_percent = tower_def.slow_percent
			creep.slow_ticks_left = maxi(creep.slow_ticks_left, tower_def.slow_duration)


## The creep `tower` would attack now under its targeting mode, or null if none is in range.
func pick_target(tower: TowerState) -> CreepState:
	var origin := tower.position()
	var best: CreepState = null
	var fallback: CreepState = null
	for creep: CreepState in creeps:
		if creep.hp <= 0 or creep.has_leaked() or creep.is_doomed():
			continue
		if not _within(creep.position(), origin, tower.def.attack_range):
			continue
		match tower.def.targeting:
			TowerDef.Targeting.FIRST:
				if best == null or creep.distance_traveled > best.distance_traveled:
					best = creep
			TowerDef.Targeting.CLOSEST:
				if best == null or _dist_sq(creep, origin) < _dist_sq(best, origin):
					best = creep
			TowerDef.Targeting.STRONGEST:
				if best == null or creep.hp > best.hp:
					best = creep
			TowerDef.Targeting.UNSLOWED:
				if fallback == null or creep.distance_traveled > fallback.distance_traveled:
					fallback = creep
				if not creep.is_slowed():
					if best == null or creep.distance_traveled > best.distance_traveled:
						best = creep
	return best if best != null else fallback


func _remove_dead() -> void:
	var alive: Array[CreepState] = []
	for creep: CreepState in creeps:
		if creep.hp <= 0:
			kills += 1
			bounty_earned += creep.def.bounty
			creep_killed.emit(creep)
		elif creep.has_leaked():
			leaks += 1
			creep_leaked.emit(creep)
		else:
			alive.append(creep)
	creeps = alive


static func _within(a: Vector2i, b: Vector2i, radius: int) -> bool:
	var d := a - b
	return d.x * d.x + d.y * d.y <= radius * radius


static func _dist_sq(creep: CreepState, origin: Vector2i) -> int:
	var d := creep.position() - origin
	return d.x * d.x + d.y * d.y
