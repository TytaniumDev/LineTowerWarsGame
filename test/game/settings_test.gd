extends GdUnitTestSuite

const PATH := "user://test_settings.cfg"


func after_test() -> void:
	DirAccess.remove_absolute(PATH)


func _settings() -> GameSettings:
	var settings: GameSettings = auto_free(GameSettings.new())
	settings.path = PATH
	return settings


func test_values_survive_a_save_and_load() -> void:
	var saved := _settings()
	saved.window_mode = GameSettings.WindowMode.FULLSCREEN
	saved.vsync = false
	saved.max_fps = 60
	saved.volumes[&"Music"] = 25
	assert_int(saved.save()).is_equal(OK)
	var loaded := _settings()
	loaded.load_settings()
	assert_int(loaded.window_mode).is_equal(GameSettings.WindowMode.FULLSCREEN)
	assert_bool(loaded.vsync).is_false()
	assert_int(loaded.max_fps).is_equal(60)
	assert_int(loaded.volumes[&"Music"]).is_equal(25)


func test_missing_file_keeps_defaults() -> void:
	var settings := _settings()
	settings.load_settings()
	assert_int(settings.window_mode).is_equal(GameSettings.WindowMode.WINDOWED)
	assert_int(settings.volumes[&"Master"]).is_equal(80)


func test_invalid_values_are_clamped_or_ignored() -> void:
	var config := ConfigFile.new()
	config.set_value("graphics", "window_mode", 99)
	config.set_value("audio", "SFX", 400)
	config.save(PATH)
	var settings := _settings()
	settings.load_settings()
	assert_int(settings.window_mode).is_equal(GameSettings.WindowMode.WINDOWED)
	assert_int(settings.volumes[&"SFX"]).is_equal(100)


func test_apply_sets_bus_volume() -> void:
	var settings := _settings()
	settings.volumes[&"Master"] = 0
	settings.apply()
	assert_bool(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Master"))).is_true()
	settings.volumes[&"Master"] = 80
	settings.apply()
	assert_bool(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Master"))).is_false()
