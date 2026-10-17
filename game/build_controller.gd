class_name BuildController
extends Node
## Turns build-phase input into player actions on the maze: moving the cursor, choosing a
## tower type, placing and selling. Works with mouse, keyboard and controller.

## Emitted after anything the panel or view should reflect.
signal changed
## Emitted when an action is refused, with a reason to show the player.
signal refused(message: String)

const REFUSALS: Dictionary[PlayerState.Result, String] = {
	PlayerState.Result.NOT_ENOUGH_GOLD: "Not enough gold.",
	PlayerState.Result.OUT_OF_BOUNDS: "That's outside the lane.",
	PlayerState.Result.OCCUPIED: "There's already a tower there.",
	PlayerState.Result.RESERVED: "Spawn and exit cells must stay open.",
	PlayerState.Result.BLOCKS_PATH: "That would block the creeps' path.",
	PlayerState.Result.NO_TOWER: "There's no tower there to sell.",
}

## The home lane's view state, updated with the cursor.
var state: LaneViewState
## Returns the home lane cell under the mouse, or (-1, -1); set by the active renderer.
var cell_at_mouse: Callable = func() -> Vector2i: return Vector2i(-1, -1)
var player: PlayerState
var towers: Array[TowerDef] = []
var chosen_tower: int = 0
var cursor: Vector2i = Vector2i(-1, -1)
## False while another control (the panel) has input focus, or outside the build phase.
var active: bool = false


## Starts a build phase for `build_player`, keeping the cursor where it was.
func begin(build_player: PlayerState) -> void:
	player = build_player
	if not player.grid.lane.contains(cursor):
		cursor = Vector2i(player.grid.lane.size.x / 2, player.grid.lane.size.y / 2)
	active = true
	_update_view()


func choose_tower(index: int) -> void:
	chosen_tower = posmod(index, towers.size())
	_update_view()


func _unhandled_input(event: InputEvent) -> void:
	if not active or player == null:
		return
	if event is InputEventMouse:
		var cell: Vector2i = cell_at_mouse.call()
		if cell.x < 0:
			return
		if cell != cursor:
			cursor = cell
			_update_view()
	var handled := true
	if event.is_action_pressed("cursor_left", true):
		_move(Vector2i.LEFT)
	elif event.is_action_pressed("cursor_right", true):
		_move(Vector2i.RIGHT)
	elif event.is_action_pressed("cursor_up", true):
		_move(Vector2i.UP)
	elif event.is_action_pressed("cursor_down", true):
		_move(Vector2i.DOWN)
	elif event.is_action_pressed("next_tower"):
		choose_tower(chosen_tower + 1)
	elif event.is_action_pressed("previous_tower"):
		choose_tower(chosen_tower - 1)
	elif event.is_action_pressed("place_tower"):
		_report(player.place_tower(towers[chosen_tower], cursor))
	elif event.is_action_pressed("sell_tower"):
		_report(player.sell_tower(cursor))
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()


func _move(direction: Vector2i) -> void:
	var next := cursor + direction
	if player.grid.lane.contains(next):
		cursor = next
		_update_view()


func _report(result: PlayerState.Result) -> void:
	if result != PlayerState.Result.OK:
		refused.emit(REFUSALS.get(result, "Can't do that."))
	_update_view()


func _update_view() -> void:
	state.cursor_cell = cursor
	state.cursor_ok = (
		player.towers.has(cursor) or player.grid.check_place(cursor) == LaneGrid.PlaceResult.OK
	)
	changed.emit()
