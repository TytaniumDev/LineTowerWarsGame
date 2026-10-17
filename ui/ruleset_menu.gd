class_name RulesetMenu
extends Control
## Playtest screen (D10): pick a RulesetDef variant, tweak its numbers for one run, and
## start. Tweaks apply to a copy, so the variant files never change.

signal start_requested(rules: RulesetDef)
signal closed

var _rulesets: Array[RulesetDef] = []
var _rules: RulesetDef
var _variants: OptionButton
var _tweaks: RulesetTweaks


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.08, 0.09, 0.1)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(760, 680)
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)
	var title := Label.new()
	title.text = "Playtest"
	title.add_theme_font_size_override("font_size", 36)
	box.add_child(title)
	var variant_row := HBoxContainer.new()
	var variant_label := Label.new()
	variant_label.text = "Ruleset"
	variant_label.custom_minimum_size = Vector2(RulesetTweaks.LABEL_WIDTH, 0)
	variant_row.add_child(variant_label)
	_variants = OptionButton.new()
	_variants.item_selected.connect(_choose)
	variant_row.add_child(_variants)
	box.add_child(variant_row)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_tweaks = RulesetTweaks.new()
	_tweaks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_tweaks)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	box.add_child(buttons)
	MenuButtons.add(buttons, "Start run", func() -> void: start_requested.emit(_rules))
	MenuButtons.add(buttons, "Back", close)


## Shows the menu with `rulesets` to choose from, starting on the first.
func open(rulesets: Array[RulesetDef]) -> void:
	_rulesets = rulesets
	_variants.clear()
	for rules: RulesetDef in rulesets:
		_variants.add_item(rules.display_name if not rules.display_name.is_empty() else rules.id)
	show()
	if not rulesets.is_empty():
		_variants.select(0)
		_choose(0)
	_variants.grab_focus()


## Hides the menu.
func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _choose(index: int) -> void:
	_rules = _rulesets[index].duplicate()
	_tweaks.edit(_rules)
