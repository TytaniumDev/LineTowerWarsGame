class_name BattleHud
extends PanelContainer
## Battle-phase sidebar: leak counts for both lanes, speed and pause, and the result.

signal continue_pressed

var _status: Label
var _result: Label
var _continue: Button


func setup() -> void:
	custom_minimum_size = Vector2(300, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	_status = Label.new()
	box.add_child(_status)
	var hint := Label.new()
	hint.text = (
		"%s, %s: menu\n%s, %s: speed"
		% [
			InputLabels.keyboard_mouse(&"toggle_pause"),
			InputLabels.controller(&"toggle_pause"),
			InputLabels.keyboard_mouse(&"cycle_speed"),
			InputLabels.controller(&"cycle_speed"),
		]
	)
	hint.modulate = Color(0.7, 0.75, 0.8)
	box.add_child(hint)
	_result = Label.new()
	_result.add_theme_font_size_override("font_size", 28)
	box.add_child(_result)
	_continue = Button.new()
	_continue.text = "Continue"
	_continue.pressed.connect(continue_pressed.emit)
	_continue.visible = false
	box.add_child(_continue)


## Updates the live numbers. Shows the result and Continue once `outcome_text` is set.
func refresh(
	round_number: int,
	duel: Duel,
	opponent_name: String,
	speed: float,
	paused: bool,
	outcome_text: String
) -> void:
	_status.text = (
		"Round %d vs %s\n\nYour leaks: %d\nTheir leaks: %d\n\nSpeed ×%s%s"
		% [
			round_number,
			opponent_name,
			duel.home_leaks(),
			duel.away_leaks(),
			str(speed),
			"   (paused)" if paused else "",
		]
	)
	_result.text = outcome_text
	var finished := not outcome_text.is_empty()
	if finished and not _continue.visible:
		_continue.visible = true
		_continue.grab_focus()
	_continue.visible = finished
