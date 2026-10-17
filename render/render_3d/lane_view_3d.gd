class_name LaneView3D
extends Node3D
## Draws one lane in 3D from a LaneViewState, with programmer-art primitives.
##
## One world unit is one cell: cell (x, y) sits at X = x, Z = y, with the ground at Y = 0.
## Towers, creeps and shots come from small node pools that are re-synced every frame.

const TOWER_HEIGHT: float = 0.8
const CREEP_RADIUS: float = 0.3
const SHOT_RADIUS: float = 0.08

var state: LaneViewState

var _built_for: LaneDef
var _ground: Node3D
var _path_mesh: ImmediateMesh = ImmediateMesh.new()
var _cursor: MeshInstance3D
var _towers: Array[MeshInstance3D] = []
var _creeps: Array[MeshInstance3D] = []
var _hp_bars: Array[MeshInstance3D] = []
var _shots: Array[MeshInstance3D] = []
var _materials: Dictionary[String, StandardMaterial3D] = {}
var _tower_mesh: BoxMesh
var _creep_mesh: SphereMesh
var _shot_mesh: SphereMesh
var _bar_mesh: BoxMesh


func _ready() -> void:
	_tower_mesh = BoxMesh.new()
	_tower_mesh.size = Vector3(0.8, TOWER_HEIGHT, 0.8)
	_creep_mesh = SphereMesh.new()
	_creep_mesh.radius = CREEP_RADIUS
	_creep_mesh.height = CREEP_RADIUS * 2
	_shot_mesh = SphereMesh.new()
	_shot_mesh.radius = SHOT_RADIUS
	_shot_mesh.height = SHOT_RADIUS * 2
	_bar_mesh = BoxMesh.new()
	_bar_mesh.size = Vector3(0.6, 0.05, 0.08)
	var paths := MeshInstance3D.new()
	paths.mesh = _path_mesh
	paths.material_override = _material(Palette2D.PATH, true)
	add_child(paths)
	_cursor = MeshInstance3D.new()
	var cursor_mesh := BoxMesh.new()
	cursor_mesh.size = Vector3(1, 0.1, 1)
	_cursor.mesh = cursor_mesh
	add_child(_cursor)


func _process(_delta: float) -> void:
	if state == null or state.grid == null:
		return
	if state.grid.lane != _built_for:
		_build_ground(state.grid.lane)
	_update_paths()
	_update_cursor()
	var towers := state.towers()
	_resize_pool(_towers, towers.size(), _tower_mesh)
	for i: int in towers.size():
		var tower := towers[i]
		_towers[i].position = _cell_center(tower.cell, TOWER_HEIGHT / 2)
		_towers[i].material_override = _material(Palette2D.tower(tower.def.id))
	var creeps: Array[CreepState] = []
	if state.battle != null:
		creeps = state.battle.creeps
	_resize_pool(_creeps, creeps.size(), _creep_mesh)
	_resize_pool(_hp_bars, creeps.size(), _bar_mesh)
	for i: int in creeps.size():
		var creep := creeps[i]
		var at := state.creep_position(creep.id)
		_creeps[i].position = Vector3(at.x, CREEP_RADIUS, at.y)
		var color := Palette2D.creep(creep.def.id)
		if creep.is_slowed():
			color = color.lerp(Palette2D.SLOWED, 0.5)
		_creeps[i].material_override = _material(color)
		var fraction := clampf(float(creep.hp) / creep.def.max_hp, 0.05, 1.0)
		_hp_bars[i].position = Vector3(at.x - 0.3 * (1.0 - fraction), CREEP_RADIUS * 2 + 0.2, at.y)
		_hp_bars[i].scale = Vector3(fraction, 1, 1)
		_hp_bars[i].material_override = _material(Palette2D.HP_FILL)
	var shots: Array[Shot] = []
	if state.battle != null:
		for shot: Shot in state.battle.shots:
			if state.is_shot_visible(shot):
				shots.append(shot)
	_resize_pool(_shots, shots.size(), _shot_mesh)
	for i: int in shots.size():
		var at := state.shot_position(shots[i])
		_shots[i].position = Vector3(at.x, CREEP_RADIUS, at.y)
		_shots[i].material_override = _material(
			Palette2D.tower(shots[i].tower_def.id).lightened(0.4)
		)


func _build_ground(lane: LaneDef) -> void:
	_built_for = lane
	if _ground != null:
		_ground.queue_free()
	_ground = Node3D.new()
	add_child(_ground)
	var plane := MeshInstance3D.new()
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(lane.size)
	plane.mesh = plane_mesh
	plane.position = Vector3(lane.size.x / 2.0, 0, lane.size.y / 2.0)
	plane.material_override = _material(Palette2D.GROUND)
	_ground.add_child(plane)
	for cell: Vector2i in lane.spawn_cells:
		_ground.add_child(_tile(cell, Palette2D.SPAWN))
	for cell: Vector2i in lane.exit_cells:
		_ground.add_child(_tile(cell, Palette2D.EXIT))
	var lines := ImmediateMesh.new()
	lines.surface_begin(Mesh.PRIMITIVE_LINES)
	for x: int in range(lane.size.x + 1):
		lines.surface_add_vertex(Vector3(x, 0.01, 0))
		lines.surface_add_vertex(Vector3(x, 0.01, lane.size.y))
	for y: int in range(lane.size.y + 1):
		lines.surface_add_vertex(Vector3(0, 0.01, y))
		lines.surface_add_vertex(Vector3(lane.size.x, 0.01, y))
	lines.surface_end()
	var grid := MeshInstance3D.new()
	grid.mesh = lines
	grid.material_override = _material(Palette2D.GRID_LINE, true)
	_ground.add_child(grid)


func _tile(cell: Vector2i, color: Color) -> MeshInstance3D:
	var tile := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2.ONE
	tile.mesh = mesh
	tile.position = _cell_center(cell, 0.005)
	tile.material_override = _material(color)
	return tile


func _update_paths() -> void:
	_path_mesh.clear_surfaces()
	for path: Array in state.paths():
		if path.size() < 2:
			continue
		_path_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for cell: Vector2i in path:
			_path_mesh.surface_add_vertex(_cell_center(cell, 0.03))
		_path_mesh.surface_end()


func _update_cursor() -> void:
	_cursor.visible = state.grid.lane.contains(state.cursor_cell)
	if _cursor.visible:
		_cursor.position = _cell_center(state.cursor_cell, 0.05)
		var color := Palette2D.CURSOR_OK if state.cursor_ok else Palette2D.CURSOR_BAD
		_cursor.material_override = _material(color, true)


func _resize_pool(pool: Array[MeshInstance3D], count: int, mesh: Mesh) -> void:
	while pool.size() < count:
		var node := MeshInstance3D.new()
		node.mesh = mesh
		add_child(node)
		pool.append(node)
	for i: int in pool.size():
		pool[i].visible = i < count


func _material(color: Color, unshaded: bool = false) -> StandardMaterial3D:
	var key := "%s|%s" % [color.to_html(), unshaded]
	if not _materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		if unshaded:
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		if color.a < 1.0:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_materials[key] = material
	return _materials[key]


static func _cell_center(cell: Vector2i, height: float) -> Vector3:
	return Vector3(cell.x + 0.5, height, cell.y + 0.5)
