class_name MenuButtons
extends RefCounted
## Builds the large, controller-friendly buttons used by every menu.


static func add(parent: Control, text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(320, 56)
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(on_pressed)
	parent.add_child(button)
	return button
