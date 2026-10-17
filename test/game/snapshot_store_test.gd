extends GdUnitTestSuite

const DIR := "user://test_snapshots"


func before_test() -> void:
	_clear()


func after_test() -> void:
	_clear()


func _clear() -> void:
	if not DirAccess.dir_exists_absolute(DIR):
		return
	for file_name: String in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(file_name))
	DirAccess.remove_absolute(DIR)


func test_saved_snapshots_load_back() -> void:
	var content := ContentLoader.load_registry()
	var snapshot := Snapshot.new()
	snapshot.round_number = 2
	snapshot.maze = [PlacedTower.new(content.tower(&"arrow"), Vector2i(1, 5))]
	snapshot.army = [content.creep(&"grunt")]
	var store := SnapshotStore.new(DIR)
	assert_int(store.save(snapshot)).is_equal(OK)
	var loaded := store.load_all(content)
	assert_int(loaded.size()).is_equal(1)
	assert_int(loaded[0].round_number).is_equal(2)
	assert_str(loaded[0].game_version).is_equal("0.1.0")


func test_unreadable_files_are_skipped() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var file := FileAccess.open(DIR.path_join("broken.json"), FileAccess.WRITE)
	file.store_string("{not json")
	file.close()
	assert_array(SnapshotStore.new(DIR).load_all(ContentLoader.load_registry())).is_empty()


func test_missing_folder_loads_nothing() -> void:
	assert_array(SnapshotStore.new(DIR).load_all(ContentRegistry.new())).is_empty()
