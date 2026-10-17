class_name CreepDef
extends Resource
## A creep type players can send. All numbers are integers so the sim stays deterministic.

@export var id: StringName
@export var display_name: String
@export var max_hp: int = 1
## Movement speed in milli-cells per second (1000 = one cell per second).
@export var speed: int = 1000
## Gold the defender earns for killing one.
@export var bounty: int = 0
## Flat damage removed from every hit; a hit always deals at least 1.
@export var armor: int = 0

@export_group("Sending")
## Gold the sender pays for one send.
@export var send_cost: int = 0
## Permanent income the sender gains per send.
@export var income_bonus: int = 0
## How many creeps one send spawns.
@export var group_size: int = 1


## Damage one hit of `raw_damage` deals after armor.
func damage_after_armor(raw_damage: int) -> int:
	return maxi(1, raw_damage - armor)


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty():
		errors.append("id is required")
	if max_hp <= 0:
		errors.append("max_hp must be positive")
	if speed <= 0:
		errors.append("speed must be positive")
	if send_cost < 0 or bounty < 0 or income_bonus < 0 or armor < 0:
		errors.append("send_cost, bounty, income_bonus and armor can't be negative")
	if group_size <= 0:
		errors.append("group_size must be positive")
	return errors
