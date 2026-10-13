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


func test_wood_gatherers_chop_near_the_pine() -> void:
	var plan: VillagerPlan = _plan_for(VillagerState.ACTIVITY_GATHER_WOOD)
	assert_eq(plan.pose, &"chop")
	assert_true(WorldLayout.WOOD_SPOTS.has(plan.target))
	assert_eq(plan.focus_x, WorldLayout.PINE_X)


func test_socializing_gathers_at_the_fire() -> void:
	var plan: VillagerPlan = _plan_for(VillagerState.ACTIVITY_SOCIALIZE)
	assert_true(WorldLayout.SOCIAL_SPOTS.has(plan.target))
	assert_eq(plan.pose, &"idle")


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


func test_light_changes_smoothly_through_dusk() -> void:
	var previous: Color = DayNight.tint(17.0)
	for step: int in range(1, 41):
		var current: Color = DayNight.tint(17.0 + float(step) * 0.1)
		assert_true(absf(current.r - previous.r) < 0.1, "Dusk jumped at step %d" % step)
		previous = current
