class_name PauseMenu
extends Control
## In-run menu: Resume, Options, or quit back to the main menu.

signal resume_pressed
signal options_pressed
signal quit_pressed

## True while the options screen opened from this menu is showing.
var options_open: bool = false

var _resume: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.7)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var title := Label.new()
	title.text = "Paused"
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_resume = MenuButtons.add(box, "Resume", resume_pressed.emit)
	MenuButtons.add(box, "Options", options_pressed.emit)
	MenuButtons.add(box, "Quit to main menu", quit_pressed.emit)


## Gives controller focus to Resume.
func focus() -> void:
	_resume.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if (
		visible
		and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("toggle_pause"))
	):
		get_viewport().set_input_as_handled()
		resume_pressed.emit()
