class_name TowerDef
extends Resource
## A tower type. Towers occupy one cell and double as maze walls.
##
## Upgrades form a tree: `upgrades` lists the towers this one can become, so one entry is
## a linear upgrade and two or more are a branch the player picks from.

## Which creep in range a tower attacks.
enum Targeting {
	FIRST,  ## Furthest along the path, closest to leaking.
	CLOSEST,  ## Nearest to the tower.
	STRONGEST,  ## Most current HP.
	UNSLOWED,  ## First creep that isn't slowed; falls back to FIRST if all are.
}

@export var id: StringName
@export var display_name: String
## Gold to build, or to upgrade into this tower from its parent.
@export var cost: int = 0
## Attack range in milli-cells, measured between cell centers.
@export var attack_range: int = 1000
@export var damage: int = 0
## Ticks between attacks (30 ticks = one second).
@export var attack_interval: int = 30
@export var targeting: Targeting = Targeting.FIRST

@export_group("Effects")
## Splash radius in milli-cells around the target; 0 hits the target only.
@export var splash_radius: int = 0
## Percent of speed removed from creeps it hits; 0 for no slow.
@export_range(0, 100) var slow_percent: int = 0
## How long the slow lasts, in ticks.
@export var slow_duration: int = 0

@export_group("Upgrades")
@export var upgrades: Array[TowerDef] = []


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty():
		errors.append("id is required")
	if cost < 0 or damage < 0 or splash_radius < 0 or slow_duration < 0:
		errors.append("cost, damage, splash_radius and slow_duration can't be negative")
	if attack_range <= 0:
		errors.append("attack_range must be positive")
	if attack_interval <= 0:
		errors.append("attack_interval must be positive")
	if slow_percent > 0 and slow_duration == 0:
		errors.append("a slow needs a duration")
	for upgrade: TowerDef in upgrades:
		if upgrade == null:
			errors.append("upgrades contains an empty slot")
	return errors
