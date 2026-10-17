extends GdUnitTestSuite


func _labels(tweaks: RulesetTweaks) -> Array[String]:
	var texts: Array[String] = []
	for label: Node in tweaks.find_children("*", "Label", true, false):
		texts.append((label as Label).text)
	return texts


func test_builds_rows_for_whole_number_and_enum_settings() -> void:
	var tweaks: RulesetTweaks = auto_free(RulesetTweaks.new())
	tweaks.edit(RulesetDef.new())
	var labels := _labels(tweaks)
	assert_array(labels).contains(["Economy", "Starting Gold", "Send Timing", "Bounty Percent"])
	# Text and array settings aren't tweakable here.
	assert_array(labels).not_contains(["Id", "Display Name", "Waves", "Resource"])


func test_edits_write_into_the_rules() -> void:
	var rules := RulesetDef.new()
	var tweaks: RulesetTweaks = auto_free(RulesetTweaks.new())
	tweaks.edit(rules)
	for option: Node in tweaks.find_children("*", "OptionButton", true, false):
		(option as OptionButton).item_selected.emit(RulesetDef.SendTiming.BEFORE_WAVE)
	for stepper: Node in tweaks.find_children("*", "IntStepper", true, false):
		var row := stepper.get_parent()
		if (row.get_child(0) as Label).text == "Bounty Percent":
			(stepper as IntStepper).value = 5000
	assert_int(rules.send_timing).is_equal(RulesetDef.SendTiming.BEFORE_WAVE)
	# Clamped to the export range.
	assert_int(rules.bounty_percent).is_equal(1000)
