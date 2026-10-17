extends Node
## App entry: shows the main menu, starts runs, and hosts the options screen that both the
## main menu and the in-run pause menu open.

const RUN_SCREEN: PackedScene = preload("res://game/run_screen.tscn")

var _run_screen: RunScreen

@onready var _main_menu: MainMenu = $MenuLayer/MainMenu
@onready var _options: OptionsMenu = $OverlayLayer/OptionsMenu


func _ready() -> void:
	_main_menu.play_pressed.connect(_start_run)
	_main_menu.options_pressed.connect(_options.open)
	_options.closed.connect(_on_options_closed)
	_options.hide()


func _start_run() -> void:
	_main_menu.hide()
	_run_screen = RUN_SCREEN.instantiate()
	_run_screen.options_requested.connect(_options.open)
	_run_screen.exit_requested.connect(_end_run)
	add_child(_run_screen)
	# Keep the run below the options overlay, which must get input first.
	move_child(_run_screen, 0)


func _end_run() -> void:
	_run_screen.queue_free()
	_run_screen = null
	_main_menu.show()
	_main_menu.focus()


func _on_options_closed() -> void:
	if _run_screen != null:
		_run_screen.return_from_options()
	else:
		_main_menu.focus()
