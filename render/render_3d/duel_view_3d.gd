class_name DuelView3D
extends Node3D
## The 3D renderer: your lane, and the opponent's lane beside it during battles, seen
## through a fixed, angled orthographic camera.

## Gap between the two lanes, in cells.
const LANE_GAP: float = 3.0
## Camera pitch below the horizon, in degrees.
const CAMERA_PITCH: float = 55.0
## Extra space around the lanes in the camera frame, in cells.
const FRAME_MARGIN: float = 2.0

@onready var _home: LaneView3D = $HomeLane
@onready var _away: LaneView3D = $AwayLane
@onready var _home_title: Label3D = $HomeLane/Title
@onready var _away_title: Label3D = $AwayLane/Title
@onready var _camera: Camera3D = $Camera


## Connects the lane views to the states they draw.
func bind(home_state: LaneViewState, away_state: LaneViewState) -> void:
	_home.state = home_state
	_away.state = away_state


## Shows one lane for building, or both for a battle, and frames the camera on them.
func set_battle_layout(battle: bool, lane: LaneDef) -> void:
	_away.visible = battle
	_away.position = Vector3(lane.size.x + LANE_GAP, 0, 0)
	_home_title.position = Vector3(lane.size.x / 2.0, 0.1, -1.0)
	_away_title.position = _home_title.position
	var width := float(lane.size.x) * (2 if battle else 1) + (LANE_GAP if battle else 0.0)
	var center := Vector3(width / 2.0, 0, lane.size.y / 2.0)
	_camera.rotation_degrees = Vector3(-CAMERA_PITCH, 0, 0)
	var back := Vector3(0, sin(deg_to_rad(CAMERA_PITCH)), cos(deg_to_rad(CAMERA_PITCH)))
	_camera.position = center + back * 50.0
	# Fit the lane's length, foreshortened by the pitch, plus a margin.
	var visible_depth := lane.size.y * sin(deg_to_rad(CAMERA_PITCH)) + FRAME_MARGIN * 2
	var aspect := float(get_viewport().size.x) / maxf(1.0, get_viewport().size.y)
	_camera.size = maxf(visible_depth, (width + FRAME_MARGIN * 2) / aspect)


## The home lane's cell under a position in this view's viewport, or (-1, -1).
func screen_to_cell(viewport_position: Vector2) -> Vector2i:
	if _home.state == null or _home.state.grid == null:
		return Vector2i(-1, -1)
	var origin := _camera.project_ray_origin(viewport_position)
	var direction := _camera.project_ray_normal(viewport_position)
	if is_zero_approx(direction.y):
		return Vector2i(-1, -1)
	var hit := origin + direction * (-origin.y / direction.y) - _home.position
	var cell := Vector2i(floori(hit.x), floori(hit.z))
	return cell if _home.state.grid.lane.contains(cell) else Vector2i(-1, -1)
