class_name RunState
extends RefCounted
## One run, round by round: a build phase, then a duel against an opponent snapshot,
## then the result, until the player runs out of lives or reaches the win target.
##
## Saving snapshots is left to the caller, since sim/ does no file I/O.

enum Phase { BUILD, BATTLE, RUN_OVER }

var player: PlayerState
var lane: LaneDef
var phase: Phase = Phase.BUILD
## The current battle; null outside the battle phase.
var duel: Duel
## The snapshot being fought this round; null if the pool had none.
var opponent: Snapshot
## The owning GameSim's generator; used for opponent picks.
var rng: SimRng

var _pool: Array[Snapshot] = []


func _init(
	rules: RulesetDef, lane_def: LaneDef, opponent_pool: Array[Snapshot], sim_rng: SimRng
) -> void:
	lane = lane_def
	player = PlayerState.new(rules, lane_def)
	_pool = opponent_pool
	rng = sim_rng
	player.start_round()


## Ends the build phase and starts the duel. Returns the player's snapshot for saving.
## With no opponent available, the other lane is empty and only faces the wave.
func end_build() -> Snapshot:
	assert(phase == Phase.BUILD, "end_build: not in the build phase")
	var own := Snapshot.from_player(player)
	opponent = OpponentPicker.pick(_pool, player.round_number, player.wins, player.losses, rng)
	var away := DuelSide.new(LaneGrid.new(lane), [], [])
	if opponent != null:
		away = opponent.duel_side(lane)
	var wave := player.ruleset.wave_for_round(player.round_number)
	duel = Duel.new(player.ruleset, wave, player.duel_side(), away)
	phase = Phase.BATTLE
	return own


## Records the finished duel, then starts the next build phase or ends the run.
func finish_battle() -> Duel.Outcome:
	assert(phase == Phase.BATTLE and duel.is_finished(), "finish_battle: duel not finished")
	var outcome := duel.outcome()
	player.finish_round(outcome, duel.home.bounty_earned)
	duel = null
	opponent = null
	if player.is_run_over():
		phase = Phase.RUN_OVER
	else:
		player.start_round()
		phase = Phase.BUILD
	return outcome
