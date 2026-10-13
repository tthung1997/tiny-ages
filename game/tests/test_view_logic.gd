extends McpTestSuite
## The view's decisions that need no nodes: where villagers go, and the light through the day.


func suite_name() -> String:
	return "view_logic"


func _plan_for(activity: StringName, hour: int = 10) -> VillagerPlan:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.tick = sim.config.tick_for_hour(hour)
	var villager: VillagerState = sim.world.villagers[0]
	villager.activity = activity
	return VillagerPlanner.new().plan(villager, sim.world, sim.config, 0)


func test_asleep_villager_is_hidden_at_night_only() -> void:
	var night: VillagerPlan = _plan_for(VillagerState.ACTIVITY_REST, 23)
	assert_false(night.visible)
	assert_eq(night.hidden_reason, VillagerPlan.HIDDEN_ASLEEP)
	var day: VillagerPlan = _plan_for(VillagerState.ACTIVITY_REST, 12)
	assert_true(day.visible, "Resting by day means sitting by the fire")


func test_away_villager_is_hidden() -> void:
	var plan: VillagerPlan = _plan_for(VillagerState.ACTIVITY_AWAY)
	assert_false(plan.visible)
	assert_eq(plan.hidden_reason, VillagerPlan.HIDDEN_AWAY)


func test_wood_gatherers_chop_at_the_forest_stump() -> void:
	var plan: VillagerPlan = _plan_for(VillagerState.ACTIVITY_GATHER_WOOD)
	assert_eq(plan.pose, &"chop")
	assert_true(WorldLayout.WOOD_SPOTS.has(plan.target))
	assert_eq(plan.focus_x, WorldLayout.CHOP_X)
	assert_true(plan.target.x < 0.0, "Wood is cut in the west forest, not at the camp")


func test_socializing_gathers_at_the_fire() -> void:
	var plan: VillagerPlan = _plan_for(VillagerState.ACTIVITY_SOCIALIZE)
	assert_true(WorldLayout.SOCIAL_SPOTS.has(plan.target))
	assert_eq(plan.pose, &"idle")


func test_without_fire_the_group_gathers_in_the_cave_mouth() -> void:
	for activity: StringName in [
		VillagerState.ACTIVITY_SOCIALIZE, VillagerState.ACTIVITY_REST, VillagerState.ACTIVITY_BUILD,
	]:
		var sim: Simulation = SimFixture.new_sim(1, false)
		sim.world.tick = sim.config.tick_for_hour(10)
		var villager: VillagerState = sim.world.villagers[0]
		villager.activity = activity
		var plan: VillagerPlan = VillagerPlanner.new().plan(villager, sim.world, sim.config, 0)
		assert_true(WorldLayout.COLD_SPOTS.has(plan.target), "%s should wait in the cave mouth" % activity)
		assert_eq(plan.focus_x, WorldLayout.COLD_X)


func test_wanderers_pick_a_point_inside_the_wander_area() -> void:
	for _attempt: int in 20:
		var plan: VillagerPlan = _plan_for(VillagerState.ACTIVITY_WANDER)
		assert_true(plan.wander)
		assert_true(plan.target.x >= WorldLayout.WANDER_X.x and plan.target.x <= WorldLayout.WANDER_X.y)
		assert_true(plan.target.y >= WorldLayout.WANDER_Y.x and plan.target.y <= WorldLayout.WANDER_Y.y)


func test_builders_hammer_at_the_active_site() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var site: BuildingState = BuildingState.new()
	site.def_id = &"hut"
	site.complete = false
	sim.world.buildings.append(site)
	var villager: VillagerState = sim.world.villagers[0]
	villager.activity = VillagerState.ACTIVITY_BUILD
	sim.world.tick = sim.config.tick_for_hour(10)
	var plan: VillagerPlan = VillagerPlanner.new().plan(villager, sim.world, sim.config, 0)
	assert_eq(plan.pose, &"hammer")
	assert_eq(plan.focus_x, float(WorldLayout.BUILDINGS[&"hut"]["cx"]))


func test_builders_with_no_site_wait_at_the_fire() -> void:
	var plan: VillagerPlan = _plan_for(VillagerState.ACTIVITY_BUILD)
	assert_eq(plan.pose, &"idle")
	assert_true(WorldLayout.FIRE_SPOTS.has(plan.target))


func test_hunters_stand_at_the_far_end_of_the_forest_with_a_spear() -> void:
	var plan: VillagerPlan = _plan_for(VillagerState.ACTIVITY_HUNT)
	assert_eq(plan.pose, &"spear")
	assert_true(WorldLayout.HUNT_SPOTS.has(plan.target))
	assert_true(plan.has_focus())
	assert_true(plan.focus_x < plan.target.x, "They face further west")
	for spot: Vector2 in WorldLayout.HUNT_SPOTS:
		assert_true(spot.x < WorldLayout.WANDER_X.x, "Beyond where anyone wanders")
		assert_true(spot.x > float(WorldLayout.WORLD_LEFT), "Inside the world")
		assert_true(spot.y >= WorldLayout.WANDER_Y.x and spot.y <= WorldLayout.WANDER_Y.y)


func test_a_plan_with_no_target_to_face_says_so() -> void:
	var plan: VillagerPlan = _plan_for(VillagerState.ACTIVITY_WANDER)
	assert_false(plan.has_focus(), "Wanderers just face where they walk")
	assert_true(_plan_for(VillagerState.ACTIVITY_GATHER_WOOD).has_focus())


func _actor_at(x: float, focus: float, pose: StringName) -> VillagerActor:
	var actor: VillagerActor = VillagerActor.new()
	actor.setup(&"t", load("%smira.png" % WorldLayout.VILLAGER_DIR) as Texture2D)
	var plan: VillagerPlan = VillagerPlan.new()
	plan.target = Vector2(x, 78.0)
	plan.focus_x = focus
	plan.pose = pose
	actor.apply_plan(plan)
	actor._process(0.1)
	return actor


func test_facing_works_west_of_the_camp() -> void:
	var east_of_stump: VillagerActor = _actor_at(-54.0, WorldLayout.CHOP_X, &"chop")
	var west_of_stump: VillagerActor = _actor_at(-82.0, WorldLayout.CHOP_X, &"chop")
	assert_true(east_of_stump._sprite.flip_h, "East of the stump faces west")
	assert_false(west_of_stump._sprite.flip_h, "West of the stump faces east")
	var hunter: VillagerActor = _actor_at(-300.0, WorldLayout.HUNT_X, &"spear")
	assert_true(hunter._sprite.flip_h, "Hunters face west")
	assert_eq(hunter._sprite.animation, &"spear")
	for actor: VillagerActor in [east_of_stump, west_of_stump, hunter]:
		actor.free()


func test_every_villager_sheet_has_every_pose() -> void:
	var cells: int = 0
	for animation: StringName in VillagerActor.SHEET_FRAMES:
		for cell: int in VillagerActor.SHEET_FRAMES[animation]:
			cells = maxi(cells, cell + 1)
	for look: StringName in SimFixture.load_content().villager_looks:
		var sheet: Texture2D = load("%s%s.png" % [WorldLayout.VILLAGER_DIR, look]) as Texture2D
		assert_eq(sheet.get_width(), cells * WorldLayout.CELL_SIZE.x, "%s's sheet" % look)
		assert_eq(sheet.get_height(), WorldLayout.CELL_SIZE.y)


func test_every_building_has_a_layout_slot() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	for building: BuildingDef in content.buildings:
		assert_true(
			WorldLayout.BUILDINGS.has(building.id), "No layout slot for %s" % building.id
		)


func test_every_villager_look_has_a_sheet() -> void:
	for look: StringName in SimFixture.load_content().villager_looks:
		var path: String = "%s%s.png" % [WorldLayout.VILLAGER_DIR, look]
		assert_true(ResourceLoader.exists(path), "No sheet for look %s" % look)


func test_every_layout_asset_exists() -> void:
	var names: Array[String] = []
	for layer: StringName in WorldLayout.BACKDROP:
		names.append(String(layer))
	for layer: StringName in WorldLayout.STATIC_Z:
		names.append(String(layer))
	for building_id: StringName in WorldLayout.BUILDINGS:
		names.append("building_%s" % building_id)
		names.append("site_%s" % building_id)
	names.append_array(["flower_sprout", "flower_bloom"])
	names.append(String(WorldLayout.FIRE_GLOW))
	for frame: int in WorldLayout.FIRE_FRAMES:
		names.append(String(WorldLayout.fire_frame_name(frame)))
	for prefix: String in WorldLayout.SIDE_PAGES:
		for layer: StringName in WorldLayout.BACKDROP:
			names.append(prefix + layer)
		for layer: StringName in WorldLayout.SIDE_STATIC[prefix]:
			names.append(prefix + layer)
	for asset: String in names:
		assert_true(
			ResourceLoader.exists(WorldLayout.ASSET_DIR + asset + ".png"), "Missing %s" % asset
		)


func test_night_is_darker_and_bluer_than_noon() -> void:
	var noon: Color = DayNight.tint(12.0)
	var midnight: Color = DayNight.tint(0.0)
	assert_true(midnight.r < noon.r)
	assert_true(midnight.b > midnight.r, "Night should read blue")
	assert_eq(DayNight.tint(0.0), DayNight.tint(24.0), "The day should wrap without a jump")


func test_unlit_nights_are_darker_but_days_are_not() -> void:
	assert_eq(DayNight.tint(12.0, false), DayNight.tint(12.0, true), "Days are the same")
	var lit: Color = DayNight.tint(0.0, true)
	var unlit: Color = DayNight.tint(0.0, false)
	assert_true(unlit.r < lit.r and unlit.g < lit.g and unlit.b < lit.b)
	assert_true(unlit.b > unlit.r, "Still reads blue")
	var previous: Color = DayNight.tint(17.0, false)
	for step: int in range(1, 81):
		var current: Color = DayNight.tint(17.0 + float(step) * 0.1, false)
		assert_true(absf(current.r - previous.r) < 0.1, "Unlit dusk jumped at step %d" % step)
		previous = current


func test_night_amount_runs_from_day_to_night() -> void:
	assert_eq(DayNight.night_amount(12.0), 0.0)
	assert_eq(DayNight.night_amount(0.0), 1.0)
	assert_true(DayNight.night_amount(20.0) > 0.0 and DayNight.night_amount(20.0) < 1.0)


func test_light_changes_smoothly_through_dusk() -> void:
	var previous: Color = DayNight.tint(17.0)
	for step: int in range(1, 41):
		var current: Color = DayNight.tint(17.0 + float(step) * 0.1)
		assert_true(absf(current.r - previous.r) < 0.1, "Dusk jumped at step %d" % step)
		previous = current
