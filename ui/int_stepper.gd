class_name IntStepper
extends HBoxContainer
## A whole-number input that works with a controller: focus the value, then press left or
## right to step it. The − and + buttons do the same with a mouse.

signal value_changed(value: int)

var min_value: int = 0
var max_value: int = 1000000
var step: int = 1
var value: int:
	set = set_value

var _value_button: Button


func _init() -> void:
	add_theme_constant_override("separation", 4)
	_add_step_button("−", -1)
	_value_button = Button.new()
	_value_button.custom_minimum_size = Vector2(120, 0)
	_value_button.gui_input.connect(_on_value_input)
	add_child(_value_button)
	_add_step_button("+", 1)
	_show_value()


## Sets the value, clamped to the range, and emits `value_changed` if it changed.
func set_value(new_value: int) -> void:
	new_value = clampi(new_value, min_value, max_value)
	if new_value == value:
		return
	value = new_value
	_show_value()
	value_changed.emit(value)


## Gives focus to the value, the control that takes left and right presses.
func focus() -> void:
	_value_button.grab_focus()


func _add_step_button(text: String, direction: int) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(40, 0)
	# Only the value takes focus, so up and down move between rows.
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: set_value(value + direction * step))
	add_child(button)


func _on_value_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left", true):
		set_value(value - step)
	elif event.is_action_pressed("ui_right", true):
		set_value(value + step)
	else:
		return
	_value_button.accept_event()


func _show_value() -> void:
	if _value_button != null:
		_value_button.text = str(value)
