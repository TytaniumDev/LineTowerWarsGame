class_name MainMenu
extends Control
## Title screen: Play, Options and Quit. Controller focus starts on Play.

signal play_pressed
signal options_pressed

var _play: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)
	var title := Label.new()
	title.text = ProjectSettings.get_setting("application/config/name", "")
	title.add_theme_font_size_override("font_size", 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_play = MenuButtons.add(box, "Play", play_pressed.emit)
	MenuButtons.add(box, "Options", options_pressed.emit)
	MenuButtons.add(box, "Quit", func() -> void: get_tree().quit())
	var version := Label.new()
	version.text = "v%s" % ProjectSettings.get_setting("application/config/version", "")
	version.modulate = Color(1, 1, 1, 0.5)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(version)
	focus()


## Gives controller focus to the Play button.
func focus() -> void:
	_play.grab_focus()
