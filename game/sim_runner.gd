class_name SimRunner
extends Node
## Drives a GameSim at its fixed tick rate from the engine's variable frame time.
##
## Frame timing lives here, outside the sim, so the sim itself stays deterministic.
## Renderers use `interpolation_alpha` to draw smoothly between ticks.

## Upper bound on ticks per frame, so a long stall can't freeze the game catching up.
const MAX_TICKS_PER_FRAME: int = 8

## Game-speed multiplier for fast-forward; 1.0 is real time.
@export var speed: float = 1.0
@export var paused: bool = false

var sim: GameSim

## How far the current frame is between the last tick and the next, in [0, 1).
var interpolation_alpha: float:
	get:
		return _accumulator * SimConfig.TICKS_PER_SECOND

var _accumulator: float = 0.0


func _process(delta: float) -> void:
	advance(delta)


## Runs as many ticks as `delta` seconds of game time cover. Returns the number of ticks run.
func advance(delta: float) -> int:
	if sim == null or paused:
		return 0
	var tick_duration: float = 1.0 / SimConfig.TICKS_PER_SECOND
	_accumulator += delta * speed
	var ticks_run: int = 0
	while _accumulator >= tick_duration and ticks_run < MAX_TICKS_PER_FRAME:
		sim.step()
		_accumulator -= tick_duration
		ticks_run += 1
	if ticks_run == MAX_TICKS_PER_FRAME:
		# Too far behind: drop the backlog instead of fast-forwarding.
		_accumulator = 0.0
	return ticks_run
