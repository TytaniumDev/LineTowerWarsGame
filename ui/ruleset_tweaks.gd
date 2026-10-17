class_name RulesetTweaks
extends VBoxContainer
## Edits a RulesetDef's whole-number and enum settings in place. Rows are built from the
## Resource's exported properties, so new settings show up here without UI changes.

const LABEL_WIDTH: float = 280.0

var _first_input: Control


## Shows rows for `rules`. Edits write straight into it, so pass a copy to keep the
## loaded variant untouched.
func edit(rules: RulesetDef) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_first_input = null
	# Headers wait for their group's first row, so groups with nothing to edit don't show.
	var header := ""
	for property: Dictionary in rules.get_property_list():
		var usage: int = property["usage"]
		if usage & PROPERTY_USAGE_GROUP:
			header = property["name"]
		elif usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property["type"] == TYPE_INT:
			if not header.is_empty():
				_add_header(header)
				header = ""
			_add_row(rules, property)


## Gives controller focus to the first setting.
func focus() -> void:
	if _first_input is IntStepper:
		(_first_input as IntStepper).focus()
	elif _first_input != null:
		_first_input.grab_focus()


func _add_header(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = Color(0.7, 0.75, 0.8)
	add_child(label)


func _add_row(rules: RulesetDef, property: Dictionary) -> void:
	var key: StringName = property["name"]
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = String(key).capitalize()
	label.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
	row.add_child(label)
	var input: Control
	if property["hint"] == PROPERTY_HINT_ENUM:
		input = _enum_input(rules, key, property["hint_string"])
	else:
		input = _int_input(rules, key, property)
	row.add_child(input)
	add_child(row)
	if _first_input == null:
		_first_input = input


func _enum_input(rules: RulesetDef, key: StringName, hint: String) -> OptionButton:
	var input := OptionButton.new()
	for option: String in hint.split(","):
		input.add_item(option.get_slice(":", 0).capitalize())
	input.select(rules.get(key))
	input.item_selected.connect(func(index: int) -> void: rules.set(key, index))
	return input


func _int_input(rules: RulesetDef, key: StringName, property: Dictionary) -> Control:
	var stepper := IntStepper.new()
	if property["hint"] == PROPERTY_HINT_RANGE:
		var bounds := String(property["hint_string"]).split(",")
		stepper.min_value = int(bounds[0])
		stepper.max_value = int(bounds[1])
		if bounds.size() > 2:
			stepper.step = int(bounds[2])
	stepper.value = rules.get(key)
	stepper.value_changed.connect(func(value: int) -> void: rules.set(key, value))
	return stepper
