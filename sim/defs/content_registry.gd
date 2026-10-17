class_name ContentRegistry
extends RefCounted
## Towers and creeps by id, so saved data can name content by id instead of file path.

var towers: Dictionary[StringName, TowerDef] = {}
var creeps: Dictionary[StringName, CreepDef] = {}


## Adds a tower and every tower reachable through its upgrades.
func add_tower(def: TowerDef) -> void:
	if towers.has(def.id):
		return
	towers[def.id] = def
	for upgrade: TowerDef in def.upgrades:
		if upgrade != null:
			add_tower(upgrade)


func add_creep(def: CreepDef) -> void:
	creeps[def.id] = def


## The tower with `id`, or null if there is none.
func tower(id: StringName) -> TowerDef:
	return towers.get(id)


## The creep with `id`, or null if there is none.
func creep(id: StringName) -> CreepDef:
	return creeps.get(id)
