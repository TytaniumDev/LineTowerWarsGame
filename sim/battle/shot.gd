class_name Shot
extends RefCounted
## A homing shot in flight. It always reaches its target on `land_tick` unless the target
## is already gone, in which case it disappears. Renderers animate it from `origin` to the
## target so the visual impact lines up with the damage.

var tower_def: TowerDef
var target_id: int
## Tower center in milli-cells.
var origin: Vector2i
var fire_tick: int
var land_tick: int
## Damage reserved on the target while this shot is in flight.
var reserved_damage: int


func _init(def: TowerDef, target: CreepState, from: Vector2i, fired: int, lands: int) -> void:
	tower_def = def
	target_id = target.id
	origin = from
	fire_tick = fired
	land_tick = lands
	reserved_damage = target.def.damage_after_armor(def.damage)
