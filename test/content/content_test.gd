extends GdUnitTestSuite
## Loads every content file and checks it is valid, so a bad edit fails CI.


func _load_all(dir_path: String) -> Array[Resource]:
	var resources: Array[Resource] = []
	for file_name: String in DirAccess.get_files_at(dir_path):
		if file_name.ends_with(".tres"):
			resources.append(load(dir_path.path_join(file_name)))
	return resources


func _assert_valid_with_unique_ids(resources: Array[Resource]) -> void:
	var ids: Dictionary[StringName, bool] = {}
	for res: Resource in resources:
		var errors: PackedStringArray = res.call("validate")
		(
			assert_array(errors)
			. override_failure_message("%s: %s" % [res.resource_path, errors])
			. is_empty()
		)
		var id: StringName = res.get("id")
		assert_bool(ids.has(id)).override_failure_message("duplicate id %s" % id).is_false()
		ids[id] = true


func test_towers_are_valid() -> void:
	var towers := _load_all("res://content/towers")
	assert_int(towers.size()).is_equal(3)
	for res: Resource in towers:
		assert_object(res).is_instanceof(TowerDef)
	_assert_valid_with_unique_ids(towers)


func test_creeps_are_valid() -> void:
	var creeps := _load_all("res://content/creeps")
	assert_int(creeps.size()).is_equal(4)
	for res: Resource in creeps:
		assert_object(res).is_instanceof(CreepDef)
	_assert_valid_with_unique_ids(creeps)


func test_lanes_are_valid() -> void:
	var lanes := _load_all("res://content/lanes")
	assert_int(lanes.size()).is_greater(0)
	for res: Resource in lanes:
		assert_object(res).is_instanceof(LaneDef)
	_assert_valid_with_unique_ids(lanes)


func test_rulesets_are_valid() -> void:
	var rulesets := _load_all("res://content/rulesets")
	assert_int(rulesets.size()).is_greater(0)
	for res: Resource in rulesets:
		assert_object(res).is_instanceof(RulesetDef)
		var rules: RulesetDef = res
		assert_int(rules.waves.size()).is_greater(0)
	_assert_valid_with_unique_ids(rulesets)
