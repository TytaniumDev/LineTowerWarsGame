class_name BuildPanel
extends PanelContainer
## Build-phase sidebar: economy and record, tower choice, upgrades for the tower under the
## cursor, sends, and the ready button.
##
## Emits requests only; the owner applies them to the sim and calls `refresh()`.

signal tower_chosen(index: int)
signal upgrade_chosen(index: int)
signal send_requested(creep: CreepDef)
signal undo_send_requested
signal ready_pressed

var _stats: Label
var _tower_buttons: Array[Button] = []
var _send_buttons: Array[Button] = []
var _creeps: Array[CreepDef] = []
var _army: Label
var _selected: Label
var _upgrade_row: HBoxContainer
var _upgrade_buttons: Array[Button] = []
## The tower type whose upgrades the buttons show, so they're rebuilt only on change.
var _upgrades_for: TowerDef
var _message: Label


## Builds the panel's controls for the given towers and creeps.
func setup(towers: Array[TowerDef], creeps: Array[CreepDef]) -> void:
	custom_minimum_size = Vector2(380, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	_stats = Label.new()
	box.add_child(_stats)

	box.add_child(_heading("Towers (Q / E to switch)"))
	var tower_row := HBoxContainer.new()
	box.add_child(tower_row)
	for i: int in towers.size():
		var button := Button.new()
		button.text = "%s  %dg" % [towers[i].display_name, towers[i].cost]
		button.toggle_mode = true
		button.pressed.connect(tower_chosen.emit.bind(i))
		tower_row.add_child(button)
		_tower_buttons.append(button)

	_selected = Label.new()
	_selected.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_selected)
	_upgrade_row = HBoxContainer.new()
	box.add_child(_upgrade_row)

	box.add_child(_heading("Send creeps"))
	_creeps = creeps
	for creep: CreepDef in creeps:
		var button := Button.new()
		var group := " ×%d" % creep.group_size if creep.group_size > 1 else ""
		button.text = (
			"%s%s  %dg  (+%d income)"
			% [creep.display_name, group, creep.send_cost, creep.income_bonus]
		)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(send_requested.emit.bind(creep))
		box.add_child(button)
		_send_buttons.append(button)
	var undo := Button.new()
	undo.text = "Undo last send"
	undo.pressed.connect(undo_send_requested.emit)
	box.add_child(undo)
	_army = Label.new()
	_army.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_army)

	_message = Label.new()
	_message.modulate = Color(1, 0.6, 0.5)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_message)
	var ready_button := Button.new()
	ready_button.text = "Ready for battle (Enter / Start)"
	ready_button.pressed.connect(ready_pressed.emit)
	box.add_child(ready_button)
	box.add_child(_heading("Tab / Y switches between the maze and this panel"))


## Updates the numbers from `player`, highlights the chosen tower, and offers upgrades for
## `selected`, the tower under the cursor (or null).
func refresh(player: PlayerState, chosen_tower: int, selected: PlacedTower = null) -> void:
	_stats.text = (
		"Round %d\nGold %d   Income +%d\nLives %d   Wins %d / %d   Losses %d   Draws %d"
		% [
			player.round_number,
			player.gold,
			player.income,
			player.lives,
			player.wins,
			player.ruleset.wins_to_finish,
			player.losses,
			player.draws,
		]
	)
	for i: int in _tower_buttons.size():
		_tower_buttons[i].button_pressed = i == chosen_tower
	for i: int in _send_buttons.size():
		_send_buttons[i].disabled = player.gold < _creeps[i].send_cost
	_army.text = "Sending: %s" % _army_summary(player.army)
	_show_selected(player, selected)


## Moves controller focus to the first affordable upgrade. Returns false if there's none.
func focus_upgrades() -> bool:
	for button: Button in _upgrade_buttons:
		if not button.disabled:
			button.grab_focus()
			return true
	return false


## Whether one of the upgrade buttons has focus.
func upgrades_focused() -> bool:
	return _upgrade_buttons.any(func(button: Button) -> bool: return button.has_focus())


## Shows why the last action was refused, or clears the message with "".
func show_message(text: String) -> void:
	_message.text = text


## Moves controller focus into the panel.
func grab_panel_focus() -> void:
	for button: Button in _send_buttons:
		if not button.disabled:
			button.grab_focus()
			return
	_tower_buttons[0].grab_focus()


func _show_selected(player: PlayerState, selected: PlacedTower) -> void:
	var def := selected.def if selected != null else null
	if def != _upgrades_for:
		_upgrades_for = def
		for button: Button in _upgrade_buttons:
			button.queue_free()
		_upgrade_buttons.clear()
		if def != null:
			for i: int in def.upgrades.size():
				var button := Button.new()
				button.text = "%s  %dg" % [def.upgrades[i].display_name, def.upgrades[i].cost]
				button.pressed.connect(upgrade_chosen.emit.bind(i))
				_upgrade_row.add_child(button)
				_upgrade_buttons.append(button)
	if def == null:
		_selected.text = ""
	else:
		var hint := (
			"Upgrade (%s):" % _upgrade_keys() if not def.upgrades.is_empty() else "Fully upgraded."
		)
		_selected.text = (
			"%s, sells for %dg. %s" % [def.display_name, player.sell_value(selected.cell), hint]
		)
		for i: int in _upgrade_buttons.size():
			_upgrade_buttons[i].disabled = player.gold < def.upgrades[i].cost


static func _upgrade_keys() -> String:
	return (
		"%s / %s"
		% [InputLabels.keyboard_mouse(&"upgrade_tower"), InputLabels.controller(&"upgrade_tower")]
	)


static func _heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.modulate = Color(0.7, 0.75, 0.8)
	return label


static func _army_summary(army: Array[CreepDef]) -> String:
	if army.is_empty():
		return "nothing yet"
	var counts: Dictionary[String, int] = {}
	for creep: CreepDef in army:
		counts[creep.display_name] = counts.get(creep.display_name, 0) + 1
	var parts: PackedStringArray = []
	for creep_name: String in counts:
		parts.append("%d %s" % [counts[creep_name], creep_name])
	return ", ".join(parts)
