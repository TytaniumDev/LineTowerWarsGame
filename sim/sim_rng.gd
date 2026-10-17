class_name SimRng
extends RefCounted
## The simulation's only source of randomness.
##
## Wraps Godot's RandomNumberGenerator behind integer-only methods so outcomes never
## depend on float rounding. Nothing in sim/ may call randi(), randf() or create its own
## generator. A golden-sequence test guards against engine upgrades changing the output.

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(seed_value: int) -> void:
	_rng.seed = seed_value


## Returns a random integer in [min_value, max_value], both inclusive.
func range_int(min_value: int, max_value: int) -> int:
	assert(min_value <= max_value, "range_int: min_value must not exceed max_value")
	return _rng.randi_range(min_value, max_value)


## Returns true with a chance of `numerator` out of `denominator`.
func chance(numerator: int, denominator: int) -> bool:
	assert(denominator > 0, "chance: denominator must be positive")
	return range_int(1, denominator) <= numerator


## The generator's internal state, for saving and restoring mid-run.
func get_state() -> int:
	return _rng.state


func set_state(value: int) -> void:
	_rng.state = value
