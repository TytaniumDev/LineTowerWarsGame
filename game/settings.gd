class_name GameSettings
extends Node
## Player settings (graphics and audio), saved to user://settings.cfg and applied at startup.
##
## Registered as the `Settings` autoload. Change values, then call `apply()` to use them
## and `save()` to keep them.

## Emitted after `apply()`, so open menus can refresh.
signal changed

enum WindowMode { WINDOWED, FULLSCREEN, EXCLUSIVE_FULLSCREEN }
enum Renderer { TOP_DOWN_2D, ANGLED_3D }
enum ShadowQuality { OFF, LOW, HIGH }
enum AntiAliasing { OFF, MSAA_2X, MSAA_4X }

const DEFAULT_PATH: String = "user://settings.cfg"
## FPS cap choices offered in the options menu; 0 means uncapped.
const FPS_CAPS: Array[int] = [30, 60, 90, 120, 144, 0]
## 3D render scale choices, in percent of the window resolution.
const RENDER_SCALES: Array[int] = [50, 60, 70, 80, 90, 100]
const AUDIO_BUSES: Array[StringName] = [&"Master", &"Music", &"SFX"]

var window_mode: WindowMode = WindowMode.WINDOWED
var vsync: bool = true
var max_fps: int = 0
## Which view draws the game. Swappable live with the toggle_renderer action.
var renderer: Renderer = Renderer.TOP_DOWN_2D
## 3D view quality. The 3D renderer reads these when `changed` fires.
var shadows: ShadowQuality = ShadowQuality.HIGH
var anti_aliasing: AntiAliasing = AntiAliasing.MSAA_2X
## Percent of the window resolution the 3D view renders at; one of RENDER_SCALES.
var render_scale: int = 100
## Volume per audio bus, 0 to 100.
var volumes: Dictionary[StringName, int] = {&"Master": 80, &"Music": 70, &"SFX": 80}

var path: String = DEFAULT_PATH


func _ready() -> void:
	load_settings()
	apply()


## Reads saved settings, keeping defaults for anything missing or invalid.
func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	var mode := int(config.get_value("graphics", "window_mode", window_mode))
	if mode >= 0 and mode < WindowMode.size():
		window_mode = mode as WindowMode
	var view := int(config.get_value("graphics", "renderer", renderer))
	if view >= 0 and view < Renderer.size():
		renderer = view as Renderer
	var shadow := int(config.get_value("graphics", "shadows", shadows))
	if shadow >= 0 and shadow < ShadowQuality.size():
		shadows = shadow as ShadowQuality
	var aa := int(config.get_value("graphics", "anti_aliasing", anti_aliasing))
	if aa >= 0 and aa < AntiAliasing.size():
		anti_aliasing = aa as AntiAliasing
	var scale := int(config.get_value("graphics", "render_scale", render_scale))
	if scale in RENDER_SCALES:
		render_scale = scale
	vsync = bool(config.get_value("graphics", "vsync", vsync))
	max_fps = maxi(0, int(config.get_value("graphics", "max_fps", max_fps)))
	for bus: StringName in AUDIO_BUSES:
		volumes[bus] = clampi(int(config.get_value("audio", String(bus), volumes[bus])), 0, 100)


func save() -> Error:
	var config := ConfigFile.new()
	config.set_value("graphics", "window_mode", window_mode)
	config.set_value("graphics", "renderer", renderer)
	config.set_value("graphics", "shadows", shadows)
	config.set_value("graphics", "anti_aliasing", anti_aliasing)
	config.set_value("graphics", "render_scale", render_scale)
	config.set_value("graphics", "vsync", vsync)
	config.set_value("graphics", "max_fps", max_fps)
	for bus: StringName in AUDIO_BUSES:
		config.set_value("audio", String(bus), volumes[bus])
	return config.save(path)


## Pushes the current values to the window, renderer and audio buses.
func apply() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(_display_mode())
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
		)
	Engine.max_fps = max_fps
	for bus: StringName in AUDIO_BUSES:
		var index := AudioServer.get_bus_index(bus)
		if index >= 0:
			AudioServer.set_bus_volume_db(index, linear_to_db(volumes[bus] / 100.0))
			AudioServer.set_bus_mute(index, volumes[bus] == 0)
	changed.emit()


## Switches between the 2D and 3D views, then applies and saves the choice.
func toggle_renderer() -> void:
	renderer = Renderer.ANGLED_3D if renderer == Renderer.TOP_DOWN_2D else Renderer.TOP_DOWN_2D
	apply()
	save()


func _display_mode() -> DisplayServer.WindowMode:
	match window_mode:
		WindowMode.FULLSCREEN:
			return DisplayServer.WINDOW_MODE_FULLSCREEN
		WindowMode.EXCLUSIVE_FULLSCREEN:
			return DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	return DisplayServer.WINDOW_MODE_WINDOWED
