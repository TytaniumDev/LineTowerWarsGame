class_name RulesetDef
extends Resource
## One playable rules variant. Values Tyler wants to playtest live here, so variants are
## data files picked from a debug menu rather than code branches.

@export var id: StringName
@export var display_name: String

@export_group("Run")
@export var starting_lives: int = 5
## Wins needed to finish a run victorious.
@export var wins_to_finish: int = 10

@export_group("Economy")
@export var starting_gold: int = 40
## Gold gained at the start of every round after the first, before sends raise it.
@export var base_income: int = 15
## Percent refunded when selling gold spent in an earlier round. Gold spent this round
## is always refunded in full.
@export_range(0, 100) var sell_refund_percent: int = 50

@export_group("Battle")
## Ticks between sent creeps entering the lane.
@export var send_spacing: int = 15
## Ticks between neutral wave creeps entering the lane.
@export var wave_spacing: int = 15
## Hard cap on battle length in ticks, so a stalled battle always ends.
@export var battle_tick_limit: int = 30 * 60 * 5
## Neutral waves by round. Rounds past the end of the list repeat the last wave.
@export var waves: Array[WaveDef] = []


## The neutral wave for a 1-based round number.
func wave_for_round(round_number: int) -> WaveDef:
	if waves.is_empty():
		return WaveDef.new()
	return waves[clampi(round_number - 1, 0, waves.size() - 1)]


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty():
		errors.append("id is required")
	if starting_lives <= 0 or wins_to_finish <= 0:
		errors.append("starting_lives and wins_to_finish must be positive")
	if starting_gold < 0 or base_income < 0:
		errors.append("starting_gold and base_income can't be negative")
	if send_spacing < 0 or wave_spacing < 0 or battle_tick_limit <= 0:
		errors.append("spacings can't be negative and battle_tick_limit must be positive")
	for wave: WaveDef in waves:
		if wave == null:
			errors.append("waves contains an empty slot")
		else:
			errors.append_array(wave.validate())
	return errors
