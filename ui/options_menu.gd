class_name OptionsMenu
extends Control
## Options screen with Graphics, Audio and Controls tabs. Changes apply immediately and
## are saved when the menu closes. LB / RB switch tabs; B or Escape goes back.

signal closed

const WINDOW_MODE_NAMES: Array[String] = ["Windowed", "Fullscreen", "Exclusive fullscreen"]
## Actions shown on the Controls tab, with their labels, in display order.
const CONTROL_ROWS: Array[Array] = [
	[&"cursor_up", "Move cursor up"],
	[&"cursor_down", "Move cursor down"],
	[&"cursor_left", "Move cursor left"],
	[&"cursor_right", "Move cursor right"],
	[&"place_tower", "Place tower"],
	[&"sell_tower", "Sell tower"],
	[&"previous_tower", "Previous tower type"],
	[&"next_tower", "Next tower type"],
	[&"switch_focus", "Switch maze / panel"],
	[&"end_build", "Ready for battle"],
	[&"cycle_speed", "Battle speed"],
	[&"toggle_pause", "Pause menu"],
]

var _tabs: TabContainer
var _window_mode: OptionButton
var _vsync: CheckButton
var _fps: OptionButton
var _sliders: Dictionary[StringName, HSlider] = {}


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
	box.custom_minimum_size = Vector2(760, 560)
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)
	var title := Label.new()
	title.text = "Options"
	title.add_theme_font_size_override("font_size", 36)
	box.add_child(title)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_tabs)
	_tabs.add_child(_graphics_tab())
	_tabs.add_child(_audio_tab())
	_tabs.add_child(_controls_tab())
	MenuButtons.add(box, "Back", close)
	Settings.changed.connect(_refresh)
	_refresh()


## Shows the menu and gives controller focus to the first setting.
func open() -> void:
	_refresh()
	show()
	_tabs.current_tab = 0
	_window_mode.grab_focus()


## Saves and hides the menu.
func close() -> void:
	if not visible:
		return
	var saved := Settings.save()
	if saved != OK:
		push_warning("Couldn't save settings: %s" % error_string(saved))
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
	elif event.is_action_pressed("next_tower"):
		_tabs.current_tab = (_tabs.current_tab + 1) % _tabs.get_tab_count()
	elif event.is_action_pressed("previous_tower"):
		_tabs.current_tab = posmod(_tabs.current_tab - 1, _tabs.get_tab_count())
	else:
		return
	get_viewport().set_input_as_handled()


func _graphics_tab() -> Control:
	var grid := _settings_grid("Graphics")
	_window_mode = OptionButton.new()
	for mode_name: String in WINDOW_MODE_NAMES:
		_window_mode.add_item(mode_name)
	_window_mode.item_selected.connect(
		func(index: int) -> void: _change(func() -> void: Settings.window_mode = index)
	)
	_add_row(grid, "Window mode", _window_mode)
	_vsync = CheckButton.new()
	_vsync.toggled.connect(func(on: bool) -> void: _change(func() -> void: Settings.vsync = on))
	_add_row(grid, "VSync", _vsync)
	_fps = OptionButton.new()
	for cap: int in GameSettings.FPS_CAPS:
		_fps.add_item(str(cap) if cap > 0 else "Unlimited")
	_fps.item_selected.connect(
		func(index: int) -> void:
			_change(func() -> void: Settings.max_fps = GameSettings.FPS_CAPS[index])
	)
	_add_row(grid, "FPS cap", _fps)
	return grid.get_parent()


func _audio_tab() -> Control:
	var grid := _settings_grid("Audio")
	for bus: StringName in GameSettings.AUDIO_BUSES:
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 5
		slider.custom_minimum_size = Vector2(320, 32)
		slider.value_changed.connect(
			func(value: float) -> void: _change(func() -> void: Settings.volumes[bus] = int(value))
		)
		_sliders[bus] = slider
		_add_row(grid, "%s volume" % ("Sound effects" if bus == &"SFX" else String(bus)), slider)
	return grid.get_parent()


func _controls_tab() -> Control:
	var grid := _settings_grid("Controls")
	grid.columns = 3
	for header: String in ["Action", "Keyboard / mouse", "Controller"]:
		var label := Label.new()
		label.text = header
		label.modulate = Color(0.7, 0.75, 0.8)
		grid.add_child(label)
	for row: Array in CONTROL_ROWS:
		for text: String in [
			row[1], InputLabels.keyboard_mouse(row[0]), InputLabels.controller(row[0])
		]:
			var label := Label.new()
			label.text = text
			grid.add_child(label)
	return grid.get_parent()


## A scrollable tab page holding a two-column grid of settings.
func _settings_grid(tab_name: String) -> GridContainer:
	var scroll := ScrollContainer.new()
	scroll.name = tab_name
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 32)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	return grid


func _add_row(grid: GridContainer, label_text: String, control: Control) -> void:
	var label := Label.new()
	label.text = label_text
	grid.add_child(label)
	grid.add_child(control)


func _change(update: Callable) -> void:
	update.call()
	Settings.apply()


## Shows the current settings without re-triggering change handlers.
func _refresh() -> void:
	_window_mode.select(Settings.window_mode)
	_vsync.set_pressed_no_signal(Settings.vsync)
	_fps.select(maxi(0, GameSettings.FPS_CAPS.find(Settings.max_fps)))
	for bus: StringName in _sliders:
		_sliders[bus].set_value_no_signal(Settings.volumes[bus])
