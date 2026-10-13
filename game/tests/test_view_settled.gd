extends McpTestSuite
## The Settled Age in the world view (docs/ages.md V10): a slot's art is upgraded in place when the
## age turns, and props appear because of what the settlement chose, not only because a building
## stands.


func suite_name() -> String:
	return "view_settled"


func _view_for(sim: Simulation) -> WorldView:
	var view: WorldView = WorldView.new()
	view.setup(sim, DesktopWindow.new())
	return view


func _free(view: WorldView) -> void:
	view.free()


func test_a_piece_is_found_in_the_newest_age_that_has_it() -> void:
	assert_true(WorldLayout.piece_path(&"building_hut", 0).contains("/cave/"))
	assert_true(WorldLayout.piece_path(&"building_hut", 1).contains("/settled/"))
	assert_true(
		WorldLayout.piece_path(&"building_lookout", 1).contains("/cave/"),
		"A slot the Settled Age did not redraw keeps its Cave art"
	)
	assert_eq(WorldLayout.piece_path(&"no_such_piece", 1), "")
	assert_true(
		WorldLayout.piece_path(&"building_hut", 9).contains("/settled/"),
		"A later age with no folder yet uses the newest there is"
	)


func test_every_building_and_prop_has_art_in_the_settled_age() -> void:
	for building_id: StringName in WorldLayout.BUILDINGS:
		for prefix: String in ["building_", "site_"]:
			var layer: StringName = StringName(prefix + building_id)
			assert_true(
				not WorldLayout.piece_path(layer, 1).is_empty(), "No art for %s" % layer
			)
	for prop_id: StringName in SceneProps.ids():
		assert_true(
			not WorldLayout.piece_path(prop_id, 1).is_empty(), "No art for prop %s" % prop_id
		)
		var at_x: float = SceneProps.at_x_of(prop_id)
		assert_true(
			at_x >= float(WorldLayout.WORLD_LEFT)
			and at_x + 384.0 <= float(WorldLayout.WORLD_RIGHT),
			"%s is inside the world" % prop_id
		)


func test_props_follow_flags() -> void:
	var sim: Simulation = SimFixture.new_sim()
	assert_eq(SceneProps.shown(sim.world).size(), 0, "A new world has none")
	sim.world.flags[&"path_agriculture"] = true
	assert_eq(SceneProps.shown(sim.world), [&"west_plot_farm"] as Array[StringName])
	sim.world.flags[&"path_herding"] = true
	var shown: Array[StringName] = SceneProps.shown(sim.world)
	assert_true(shown.has(&"west_pen") and shown.has(&"west_plot_patch"))
	assert_false(SceneProps.is_shown(&"no_such_prop", sim.world))


func test_props_can_follow_achievements_and_buildings() -> void:
	var sim: Simulation = SimFixture.new_sim()
	assert_false(SceneProps.holds(SceneProps.Kind.ACHIEVEMENT, &"fired_clay", sim.world))
	sim.world.achievements.append(&"fired_clay")
	assert_true(SceneProps.holds(SceneProps.Kind.ACHIEVEMENT, &"fired_clay", sim.world))
	assert_false(SceneProps.holds(SceneProps.Kind.BUILDING, &"hut", sim.world))
	var hut: BuildingState = BuildingState.new()
	hut.def_id = &"hut"
	hut.complete = true
	sim.world.buildings.append(hut)
	assert_true(SceneProps.holds(SceneProps.Kind.BUILDING, &"hut", sim.world))


func test_the_hut_art_is_upgraded_when_the_age_turns() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var view: WorldView = _view_for(sim)
	var hut: Sprite2D = view._buildings[&"hut"]
	assert_true(hut.texture.resource_path.contains("/cave/"), "Cave art in the Cave Age")
	sim.advance_era(&"settled")
	view.on_world_changed()
	assert_true(hut.texture.resource_path.contains("/settled/"), "The roundhouse once settled")
	var lookout: Sprite2D = view._buildings[&"lookout"]
	assert_true(lookout.texture.resource_path.contains("/cave/"), "Untouched slots stay")
	_free(view)


func test_the_view_shows_props_only_when_the_world_says_so() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.advance_era(&"settled")
	var view: WorldView = _view_for(sim)
	for prop_id: StringName in view._props:
		assert_false((view._props[prop_id] as Sprite2D).visible, "%s starts hidden" % prop_id)
	var before: String = view._signature
	sim.world.flags[&"path_herding"] = true
	view.on_world_changed()
	assert_true((view._props[&"west_pen"] as Sprite2D).visible)
	assert_true((view._props[&"west_plot_patch"] as Sprite2D).visible)
	assert_false((view._props[&"west_plot_farm"] as Sprite2D).visible)
	assert_true(view._signature != before, "The click region is rebuilt for the new pieces")
	_free(view)


func test_the_click_region_changes_with_the_age() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var view: WorldView = _view_for(sim)
	var cave: String = view._signature
	sim.advance_era(&"settled")
	view.on_world_changed()
	assert_true(view._signature != cave, "New art has new outlines")
	_free(view)
