class_name BuildPanel
extends PanelContainer
## Build-phase sidebar: economy and record, tower choice, sends, and the ready button.
##
## Emits requests only; the owner applies them to the sim and calls `refresh()`.

signal tower_chosen(index: int)
signal send_requested(creep: CreepDef)
signal undo_send_requested
signal ready_pressed

var _stats: Label
var _tower_buttons: Array[Button] = []
var _send_buttons: Array[Button] = []
var _creeps: Array[CreepDef] = []
var _army: Label
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


## Updates the numbers from `player` and highlights the chosen tower.
func refresh(player: PlayerState, chosen_tower: int) -> void:
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
