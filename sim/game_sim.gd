class_name GameSim
extends RefCounted
## Root of the simulation. Owns all game state and advances it one fixed tick at a time.
##
## Plain data and rules only: no nodes, rendering or input. The same seed and the same
## inputs always produce the same state, which is what snapshots and replays rely on.

## Emitted after each tick so observers (renderers, UI) can read the new state.
signal ticked(tick: int)

## Number of ticks simulated so far.
var tick: int = 0

var rng: SimRng


func _init(seed_value: int) -> void:
	rng = SimRng.new(seed_value)


## Advances the simulation by exactly one tick.
func step() -> void:
	tick += 1
	ticked.emit(tick)
