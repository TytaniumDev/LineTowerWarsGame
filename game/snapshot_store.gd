class_name SnapshotStore
extends RefCounted
## Saves and loads snapshots as JSON files in one folder (D37: your own past rounds).

const DEFAULT_DIR: String = "user://snapshots"

var dir_path: String


func _init(path: String = DEFAULT_DIR) -> void:
	dir_path = path


## Writes `snapshot` as a new file, stamping it with the game version. Returns the
## Godot error code.
func save(snapshot: Snapshot) -> Error:
	var made := DirAccess.make_dir_recursive_absolute(dir_path)
	if made != OK:
		return made
	snapshot.game_version = str(ProjectSettings.get_setting("application/config/version", ""))
	var stamp := int(Time.get_unix_time_from_system() * 1000)
	var path := dir_path.path_join("round_%02d_%d.json" % [snapshot.round_number, stamp])
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot.to_dict(), "\t", false))
	file.close()
	return OK


## Every readable snapshot in the folder, in file name order. Files that fail to parse
## or name unknown content are skipped with a warning.
func load_all(content: ContentRegistry) -> Array[Snapshot]:
	var snapshots: Array[Snapshot] = []
	if not DirAccess.dir_exists_absolute(dir_path):
		return snapshots
	var names := Array(DirAccess.get_files_at(dir_path))
	names.sort()
	for file_name: String in names:
		if not file_name.ends_with(".json"):
			continue
		var path := dir_path.path_join(file_name)
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		var snapshot: Snapshot = null
		if data is Dictionary:
			snapshot = Snapshot.from_dict(data, content)
		if snapshot == null:
			push_warning("Skipping unreadable snapshot %s" % path)
			continue
		snapshots.append(snapshot)
	return snapshots
