extends McpTestSuite
## What seasons and weather look like and say (docs/gameplay.md P14): the looks, the strip glyph,
## the stores line, the thoughts, and that the weather layer sleeps unless something is showing.

const DAY: int = SimFixture.TICKS_PER_DAY


func suite_name() -> String:
	return "view_weather"


func _view_for(sim: Simulation) -> WorldView:
	var view: WorldView = WorldView.new()
	view.setup(sim, DesktopWindow.new())
	return view


func test_every_weather_has_a_look_a_glyph_and_a_name() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	assert_gt(content.weathers.size(), 5)
	for weather: WeatherDef in content.weathers:
		assert_true(WeatherLook.LOOKS.has(weather.id), "%s has a look" % weather.id)
		assert_true(WeatherLook.WEATHER_GLYPHS.has(weather.id), "%s has a glyph" % weather.id)
		assert_true(WeatherLook.NAMES.has(weather.id), "%s has a name" % weather.id)
		assert_true(WeatherLook.WEATHER_GLYPHS[weather.id] < WeatherLook.GLYPH_COUNT)


func test_rain_falls_in_a_storm_and_a_flood_and_snow_in_winter() -> void:
	assert_eq(WeatherLook.fall(&"rain"), WeatherLook.RAIN)
	assert_eq(WeatherLook.fall(&"storm"), WeatherLook.RAIN)
	assert_eq(WeatherLook.fall(&"flood"), WeatherLook.RAIN)
	assert_eq(WeatherLook.fall(&"snow"), WeatherLook.SNOW)
	assert_eq(WeatherLook.fall(&"drought"), &"")
	assert_eq(WeatherLook.fall(&""), &"")


func test_each_piece_belongs_to_its_weather() -> void:
	assert_true(WeatherLook.shows(&"flood", &"water"))
	assert_true(WeatherLook.shows(&"drought", &"cracks"))
	assert_true(WeatherLook.shows(&"drought", &"shimmer"))
	assert_true(WeatherLook.shows(&"tornado", &"funnel"))
	assert_true(WeatherLook.shows(&"storm", &"clouds"))
	assert_false(WeatherLook.shows(&"rain", &"funnel"))
	assert_false(WeatherLook.shows(&"", &"clouds"))


func test_a_clear_sky_leaves_the_light_alone_and_a_storm_darkens_it() -> void:
	assert_eq(WeatherLook.tint(&""), Color.WHITE)
	assert_true(WeatherLook.tint(&"storm").r < WeatherLook.tint(&"rain").r)
	assert_true(WeatherLook.tint(&"rain").r < 1.0)
	assert_true(WeatherLook.tint(&"drought").b < WeatherLook.tint(&"drought").r, "Warm and dry")


func test_the_glyph_shows_the_season_and_the_weather_over_it() -> void:
	var sim: Simulation = SimFixture.new_sim()
	assert_eq(WeatherLook.glyph_cell(sim.world, sim.config), 0, "A new world is in spring")
	sim.world.tick = 25 * DAY
	assert_eq(WeatherLook.glyph_cell(sim.world, sim.config), 1)
	sim.world.tick = 65 * DAY
	assert_eq(WeatherLook.glyph_cell(sim.world, sim.config), 3)
	sim.world.weather = &"storm"
	assert_eq(WeatherLook.glyph_cell(sim.world, sim.config), WeatherLook.WEATHER_GLYPHS[&"storm"])


func test_the_words_name_the_season_and_the_weather() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.tick = 18 * DAY
	assert_eq(WeatherLook.describe(sim.world, sim.config), "Late spring")
	sim.world.weather = &"rain"
	assert_eq(WeatherLook.describe(sim.world, sim.config), "Late spring, rain")
	sim.world.tick = 30 * DAY
	sim.world.weather = &"tornado"
	assert_eq(WeatherLook.describe(sim.world, sim.config), "Summer, a tornado")


func test_the_stores_panel_says_the_season() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.tick = 3 * DAY
	var view: MenuPresenter.Stores = MenuPresenter.stores(sim.world, sim.config, sim.content)
	assert_eq(view.season_line, "Early spring")


func test_the_strip_glyph_follows_the_world_and_can_be_clicked() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var icons: StripIcons = StripIcons.new()
	icons.update_weather(sim.world, sim.config)
	assert_eq(icons.glyph_cell(), 0)
	sim.world.weather = &"flood"
	icons.update_weather(sim.world, sim.config)
	assert_eq(icons.glyph_cell(), WeatherLook.WEATHER_GLYPHS[&"flood"])
	var found: bool = false
	for region: Rect2i in icons.clickable_regions():
		found = found or region.position == Vector2i(StripIcons.GLYPH_POSITION)
	assert_true(found, "The glyph stays clickable in strip mode")
	icons.free()


func test_villagers_think_about_the_weather() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var villager: VillagerState = sim.world.villagers[0]
	villager.activity = VillagerState.ACTIVITY_WANDER
	sim.world.weather = &"drought"
	var thoughts: Dictionary = {}
	for tick: int in 200:
		sim.world.tick = DAY * 2 + tick * VillagerPresenter.THOUGHT_TICKS
		thoughts[VillagerPresenter.thought_for(villager, sim.world, sim.config)] = true
	var heard: bool = false
	for line: String in VillagerPresenter.BY_WEATHER[&"drought"]:
		heard = heard or thoughts.has(line)
	assert_true(heard, "A drought comes up in what they think")
	sim.world.weather = &""
	for tick: int in 200:
		sim.world.tick = DAY * 2 + tick * VillagerPresenter.THOUGHT_TICKS
		var line: String = VillagerPresenter.thought_for(villager, sim.world, sim.config)
		assert_false(VillagerPresenter.BY_WEATHER[&"drought"].has(line))


func test_a_season_changes_the_palette_and_summer_leaves_it_alone() -> void:
	assert_eq(SeasonLook.params(Season.SUMMER)["strength"], 0.0)
	for season: int in [Season.SPRING, Season.AUTUMN, Season.WINTER]:
		assert_true(SeasonLook.params(season)["strength"] > 0.0)
	assert_eq(SeasonLook.params(Season.WINTER)["bare"], 0.0, "Only the tree line goes bare")
	assert_true(SeasonLook.tree_params(Season.WINTER)["bare"] > 0.0)
	assert_eq(SeasonLook.tree_params(Season.AUTUMN)["bare"], 0.0)
	assert_eq(SeasonLook.tint(Season.SUMMER), Color.WHITE)


## A 12x8 layer with a green top at row 3 and a brown row below it.
func _layer() -> Image:
	var image: Image = Image.create_empty(12, 8, false, Image.FORMAT_RGBA8)
	for y: int in range(3, 8):
		for x: int in 12:
			image.set_pixel(x, y, Color("3f9a52") if y < 7 else Color("8a5a36"))
	return image


func test_winter_lays_snow_along_the_top_edge() -> void:
	var overlay: Image = SeasonOverlay.build(_layer(), &"trees", Season.WINTER)
	assert_true(overlay != null)
	for x: int in 12:
		assert_eq(overlay.get_pixel(x, 3), SeasonOverlay.SNOW, "Snow on the edge at %d" % x)
		assert_eq(overlay.get_pixel(x, 2).a, 0.0, "Nothing above it")


func test_summer_and_other_layers_add_nothing() -> void:
	assert_true(SeasonOverlay.build(_layer(), &"trees", Season.SUMMER) == null)
	assert_true(SeasonOverlay.build(_layer(), &"sky", Season.WINTER) == null)


func test_spring_and_autumn_draw_only_over_green() -> void:
	var big: Image = Image.create_empty(64, 16, false, Image.FORMAT_RGBA8)
	big.fill_rect(Rect2i(0, 4, 64, 8), Color("3f9a52"))
	big.fill_rect(Rect2i(0, 12, 64, 4), Color("4f9bd9"))
	for season: int in [Season.SPRING, Season.AUTUMN]:
		var overlay: Image = SeasonOverlay.build(big, &"ground", season)
		assert_true(overlay != null, "A season dresses the ground")
		for y: int in range(12, 16):
			for x: int in 64:
				assert_eq(overlay.get_pixel(x, y).a, 0.0, "Water is left alone")


func test_the_overlay_is_the_same_every_time() -> void:
	var first: Image = SeasonOverlay.build(_layer(), &"trees", Season.AUTUMN)
	var second: Image = SeasonOverlay.build(_layer(), &"trees", Season.AUTUMN)
	assert_eq(first == null, second == null)
	if first != null:
		assert_eq(first.get_data(), second.get_data())


func test_a_broken_building_looks_broken_until_mended() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var field: BuildingState = BuildingState.new()
	field.def_id = &"field"
	field.complete = true
	sim.world.buildings.append(field)
	var view: WorldView = _view_for(sim)
	assert_false((view._wrecks[&"field"] as Sprite2D).visible)
	field.damaged = true
	view.on_world_changed()
	assert_true((view._wrecks[&"field"] as Sprite2D).visible, "Wreckage at its foot")
	assert_true((view._buildings[&"field"] as Sprite2D).modulate != Color.WHITE)
	field.damaged = false
	view.on_world_changed()
	assert_false((view._wrecks[&"field"] as Sprite2D).visible)
	assert_eq((view._buildings[&"field"] as Sprite2D).modulate, Color.WHITE)
	view.free()


func test_the_weather_layer_sleeps_under_a_clear_sky() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var view: WorldView = _view_for(sim)
	assert_false(view._weather.is_animating())
	assert_false(view._weather.is_processing(), "No clock runs when nothing shows")
	sim.world.weather = &"rain"
	view.on_world_changed()
	assert_true(view._weather.is_animating())
	assert_true(view._weather.is_processing())
	sim.world.weather = &""
	view.on_world_changed()
	assert_false(view._weather.is_processing(), "It goes back to sleep when the sky clears")
	view.free()


func test_a_piece_in_the_world_sleeps_while_it_is_off_screen() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var view: WorldView = _view_for(sim)
	view.set_full_scene(false)
	sim.world.weather = &"tornado"
	view.on_world_changed()
	view._weather.set_view(0.0)
	assert_true(view._weather.is_animating(), "The funnel is in the camp")
	view._weather.set_view(-384.0)
	assert_false(view._weather.is_animating(), "Nobody sees it from the west page")
	assert_false(view._weather.is_processing())
	view.free()


func test_the_sky_clouds_only_exist_in_the_opaque_window() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var view: WorldView = _view_for(sim)
	sim.world.weather = &"storm"
	view.set_full_scene(false)
	view.on_world_changed()
	assert_false(view._weather._clouds.visible, "No sky on the desktop")
	view.set_full_scene(true)
	assert_true(view._weather._clouds.visible)
	view.free()


## Rain and snow fall from the top of the viewport. On the desktop there is no sky, and Windows
## only draws inside the click region, so the viewport is part of it while they last.
func test_on_the_desktop_falling_rain_takes_in_the_whole_viewport() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var view: WorldView = _view_for(sim)
	var whole: Rect2i = Rect2i(Vector2i.ZERO, WorldLayout.VIEW_SIZE)
	view.set_full_scene(false)
	view.on_world_changed()
	assert_false(view.covers_sky())
	assert_false(view.clickable_regions().has(whole), "A clear sky leaves the desktop alone")
	sim.world.weather = &"rain"
	view.on_world_changed()
	assert_true(view.covers_sky())
	assert_true(view.clickable_regions().has(whole))
	sim.world.weather = &"snow"
	view.on_world_changed()
	assert_true(view.clickable_regions().has(whole))
	sim.world.weather = &"drought"
	view.on_world_changed()
	assert_false(view.clickable_regions().has(whole), "Nothing falls in a drought")
	sim.world.weather = &"rain"
	view.set_full_scene(true)
	assert_false(view.covers_sky(), "The opaque window draws its own sky")
	assert_false(view.clickable_regions().has(whole))
	view.free()


func test_flood_water_and_cracked_ground_show_with_their_weather() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var view: WorldView = _view_for(sim)
	sim.world.weather = &"flood"
	view.on_world_changed()
	assert_true(view._weather._flood_camp.visible and view._weather._flood_east.visible)
	assert_false(view._weather._cracks_camp.visible)
	sim.world.weather = &"drought"
	view.on_world_changed()
	assert_true(view._weather._cracks_camp.visible)
	assert_false(view._weather._flood_camp.visible)
	view.free()


func test_the_season_is_applied_to_the_world_when_it_turns() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var view: WorldView = _view_for(sim)
	assert_eq(view._applied_season, Season.SPRING)
	sim.world.tick = 65 * DAY
	view.on_world_changed()
	assert_eq(view._applied_season, Season.WINTER)
	assert_eq(view._season_trees.get_shader_parameter("bare"), SeasonLook.BARE[Season.WINTER])
	assert_eq(view._season_ground.get_shader_parameter("bare"), 0.0)
	view.free()
