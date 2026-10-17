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
## The run being played; null until `start_run()`.
var run: RunState


func _init(seed_value: int) -> void:
	rng = SimRng.new(seed_value)


## Starts a new run that draws its randomness from this sim's generator.
func start_run(rules: RulesetDef, lane: LaneDef, opponent_pool: Array[Snapshot]) -> RunState:
	run = RunState.new(rules, lane, opponent_pool, rng)
	return run


## Advances the simulation by exactly one tick. Battles advance one tick per step; the
## build phase waits for player actions instead.
func step() -> void:
	tick += 1
	if run != null and run.phase == RunState.Phase.BATTLE and not run.duel.is_finished():
		run.duel.step()
	ticked.emit(tick)
