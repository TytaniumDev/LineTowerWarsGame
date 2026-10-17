class_name Duel
extends RefCounted
## A mirror duel (D4): each lane faces the round's neutral wave plus the other side's
## sends, at the same time. Whoever leaks fewer creeps wins; equal leaks is a draw (D36).
##
## If the ruleset's tick limit runs out, every creep still unresolved counts as a leak.

enum Outcome { WIN, LOSS, DRAW }

## The local player's lane, attacked by the opponent's sends.
var home: LaneBattle
## The opponent's lane, attacked by the local player's sends.
var away: LaneBattle
var tick: int = 0

var _tick_limit: int


func _init(rules: RulesetDef, wave: WaveDef, home_side: DuelSide, away_side: DuelSide) -> void:
	_tick_limit = rules.battle_tick_limit
	home = LaneBattle.new(home_side.grid, home_side.towers)
	away = LaneBattle.new(away_side.grid, away_side.towers)
	var wave_creeps := wave.creeps()
	_queue_round(home, rules, wave_creeps, away_side.army)
	_queue_round(away, rules, wave_creeps, home_side.army)


func is_finished() -> bool:
	return tick >= _tick_limit or (home.is_finished() and away.is_finished())


func step() -> void:
	home.step()
	away.step()
	tick += 1


## Leaks in the local player's lane, counting unresolved creeps once the limit is hit.
func home_leaks() -> int:
	return _leaks(home)


## Leaks in the opponent's lane, counting unresolved creeps once the limit is hit.
func away_leaks() -> int:
	return _leaks(away)


## The result for the local player. Only meaningful once `is_finished()`.
func outcome() -> Outcome:
	var mine := home_leaks()
	var theirs := away_leaks()
	if mine < theirs:
		return Outcome.WIN
	if mine > theirs:
		return Outcome.LOSS
	return Outcome.DRAW


## Steps until finished and returns the local player's result.
func run() -> Outcome:
	while not is_finished():
		step()
	return outcome()


func _leaks(battle: LaneBattle) -> int:
	if tick < _tick_limit:
		return battle.leaks
	return battle.leaks + battle.unresolved_count()


static func _queue_round(
	battle: LaneBattle, rules: RulesetDef, wave: Array[CreepDef], sends: Array[CreepDef]
) -> void:
	var wave_length := wave.size() * rules.wave_spacing
	var send_length := sends.size() * rules.send_spacing
	var wave_start := 0
	var send_start := 0
	match rules.send_timing:
		RulesetDef.SendTiming.WITH_WAVE:
			send_start = rules.wave_spacing / 2
		RulesetDef.SendTiming.AFTER_WAVE:
			send_start = wave_length
		RulesetDef.SendTiming.BEFORE_WAVE:
			wave_start = send_length
	battle.queue_creeps(wave, wave_start, rules.wave_spacing)
	battle.queue_creeps(sends, send_start, rules.send_spacing)
