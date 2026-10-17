class_name InputLabels
extends RefCounted
## Short, readable names for input events, for the Controls tab and on-screen hints.

const JOY_BUTTONS: Dictionary[JoyButton, String] = {
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Back",
	JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "D-pad up",
	JOY_BUTTON_DPAD_DOWN: "D-pad down",
	JOY_BUTTON_DPAD_LEFT: "D-pad left",
	JOY_BUTTON_DPAD_RIGHT: "D-pad right",
}
const MOUSE_BUTTONS: Dictionary[MouseButton, String] = {
	MOUSE_BUTTON_LEFT: "Left click",
	MOUSE_BUTTON_RIGHT: "Right click",
	MOUSE_BUTTON_MIDDLE: "Middle click",
}


## Keyboard and mouse bindings of `action`, joined for display.
static func keyboard_mouse(action: StringName) -> String:
	var names: PackedStringArray = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey or event is InputEventMouseButton:
			names.append(describe(event))
	return " / ".join(names)


## Controller bindings of `action`, joined for display.
static func controller(action: StringName) -> String:
	var names: PackedStringArray = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			names.append(describe(event))
	return " / ".join(names)


static func describe(event: InputEvent) -> String:
	if event is InputEventKey:
		var key := event as InputEventKey
		var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
		return OS.get_keycode_string(code)
	if event is InputEventMouseButton:
		return MOUSE_BUTTONS.get((event as InputEventMouseButton).button_index, "Mouse")
	if event is InputEventJoypadButton:
		return JOY_BUTTONS.get((event as InputEventJoypadButton).button_index, "Button")
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		var stick := "Left stick" if motion.axis <= JOY_AXIS_LEFT_Y else "Right stick"
		var vertical := motion.axis == JOY_AXIS_LEFT_Y or motion.axis == JOY_AXIS_RIGHT_Y
		var direction := ""
		if vertical:
			direction = "up" if motion.axis_value < 0 else "down"
		else:
			direction = "left" if motion.axis_value < 0 else "right"
		return "%s %s" % [stick, direction]
	return event.as_text()
