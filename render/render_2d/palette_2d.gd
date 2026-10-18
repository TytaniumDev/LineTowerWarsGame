class_name Palette2D
extends RefCounted
## Programmer-art colors for the top-down renderer, keyed by content id.

const GROUND := Color(0.13, 0.15, 0.17)
const GRID_LINE := Color(0.2, 0.23, 0.26)
const SPAWN := Color(0.25, 0.2, 0.35)
const EXIT := Color(0.35, 0.18, 0.18)
const PATH := Color(1, 1, 1, 0.25)
const CURSOR_OK := Color(0.4, 1, 0.5, 0.8)
const CURSOR_BAD := Color(1, 0.35, 0.3, 0.8)
const HP_BACK := Color(0, 0, 0, 0.6)
const HP_FILL := Color(0.4, 0.95, 0.4)
const SLOWED := Color(0.55, 0.85, 1)

const TOWERS: Dictionary[StringName, Color] = {
	&"arrow": Color(0.45, 0.75, 0.35),
	&"cannon": Color(0.9, 0.55, 0.2),
	&"frost": Color(0.4, 0.8, 0.95),
	# Upgrades are shades of their base tower's color.
	&"arrow_2": Color(0.35, 0.65, 0.25),
	&"frost_2": Color(0.3, 0.7, 0.9),
	&"cannon_2": Color(0.8, 0.45, 0.15),
	&"sniper": Color(0.25, 0.5, 0.2),
	&"rapid": Color(0.7, 0.95, 0.5),
	&"mortar": Color(0.7, 0.35, 0.1),
	&"bombard": Color(1, 0.75, 0.4),
	&"glacier": Color(0.2, 0.5, 0.85),
	&"blizzard": Color(0.75, 0.95, 1),
}
const CREEPS: Dictionary[StringName, Color] = {
	&"grunt": Color(0.85, 0.8, 0.7),
	&"swarm": Color(0.95, 0.85, 0.3),
	&"tank": Color(0.65, 0.4, 0.3),
	&"runner": Color(0.95, 0.45, 0.6),
}


static func tower(id: StringName) -> Color:
	return TOWERS.get(id, _fallback(id))


static func creep(id: StringName) -> Color:
	return CREEPS.get(id, _fallback(id))


## A stable color for content without an entry, so new content is still visible.
static func _fallback(id: StringName) -> Color:
	return Color.from_hsv(float(hash(id) % 360) / 360.0, 0.6, 0.9)
