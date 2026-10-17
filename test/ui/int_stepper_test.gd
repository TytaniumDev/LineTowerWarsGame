extends GdUnitTestSuite


func _stepper() -> IntStepper:
	var stepper: IntStepper = auto_free(IntStepper.new())
	stepper.min_value = 0
	stepper.max_value = 20
	stepper.step = 5
	stepper.value = 10
	return stepper


func test_clamps_to_its_range() -> void:
	var stepper := _stepper()
	stepper.value = 99
	assert_int(stepper.value).is_equal(20)
	stepper.value = -3
	assert_int(stepper.value).is_equal(0)


func test_buttons_step_by_the_step_size() -> void:
	var stepper := _stepper()
	(stepper.get_child(2) as Button).pressed.emit()
	assert_int(stepper.value).is_equal(15)
	(stepper.get_child(0) as Button).pressed.emit()
	(stepper.get_child(0) as Button).pressed.emit()
	assert_int(stepper.value).is_equal(5)


func test_emits_only_on_change() -> void:
	var stepper := _stepper()
	var seen: Array[int] = []
	stepper.value_changed.connect(func(value: int) -> void: seen.append(value))
	stepper.value = 10
	stepper.value = 20
	stepper.value = 25
	assert_array(seen).contains_exactly([20])
