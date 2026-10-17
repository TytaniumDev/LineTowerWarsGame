class_name ContentLoader
extends RefCounted
## Loads the content Resources under res://content into a ContentRegistry.

const TOWERS_DIR: String = "res://content/towers"
const CREEPS_DIR: String = "res://content/creeps"


static func load_registry() -> ContentRegistry:
	var registry := ContentRegistry.new()
	for res: Resource in load_dir(TOWERS_DIR):
		if res is TowerDef:
			registry.add_tower(res)
	for res: Resource in load_dir(CREEPS_DIR):
		if res is CreepDef:
			registry.add_creep(res)
	return registry


## Every Resource in `dir_path`, sorted by file name. Uses ResourceLoader's listing so
## it also works in exported builds, where files are remapped.
static func load_dir(dir_path: String) -> Array[Resource]:
	var resources: Array[Resource] = []
	var names := Array(ResourceLoader.list_directory(dir_path))
	names.sort()
	for file_name: String in names:
		if file_name.ends_with("/"):
			continue
		var res := load(dir_path.path_join(file_name))
		if res != null:
			resources.append(res)
	return resources
