extends GdUnitTestSuite

var _saved: Array = []


func before_test() -> void:
	_saved = [Settings.shadows, Settings.anti_aliasing, Settings.render_scale]


func after_test() -> void:
	Settings.shadows = _saved[0]
	Settings.anti_aliasing = _saved[1]
	Settings.render_scale = _saved[2]


func test_applies_3d_quality_settings_to_its_viewport() -> void:
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.add_child(load("res://render/render_3d/duel_view_3d.tscn").instantiate())
	add_child(viewport)
	Settings.shadows = GameSettings.ShadowQuality.OFF
	Settings.anti_aliasing = GameSettings.AntiAliasing.MSAA_4X
	Settings.render_scale = 70
	(viewport.get_child(0) as DuelView3D).apply_graphics()
	(
		assert_bool((viewport.get_node("DuelView3D/Sun") as DirectionalLight3D).shadow_enabled)
		. is_false()
	)
	assert_int(viewport.msaa_3d).is_equal(Viewport.MSAA_4X)
	assert_float(viewport.scaling_3d_scale).is_equal_approx(0.7, 0.001)
