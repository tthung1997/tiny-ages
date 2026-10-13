extends McpTestSuite
## Villagers put on woven tunics once the group has woven cloth (docs/ages.md V10): the sheet is
## chosen by the world, swapped live without losing the animation, and used for the popup portrait
## too.


func suite_name() -> String:
	return "view_cloth"


func _sheet_of(actor: VillagerActor) -> String:
	var frame: AtlasTexture = actor._sprite.sprite_frames.get_frame_texture(&"idle", 0) as AtlasTexture
	return frame.atlas.resource_path


func test_wearing_cloth_follows_the_achievement() -> void:
	var sim: Simulation = SimFixture.new_sim()
	assert_false(WorldLayout.wears_cloth(sim.world))
	sim.world.achievements.append(&"woven_cloth")
	assert_true(WorldLayout.wears_cloth(sim.world))


func test_every_look_has_a_cloth_sheet_and_a_fur_one() -> void:
	for look: StringName in SimFixture.load_content().villager_looks:
		assert_true(WorldLayout.villager_sheet_path(look, true).contains("/settled/"), "%s" % look)
		assert_true(WorldLayout.villager_sheet_path(look, false).contains("/cave/"), "%s" % look)
		for cloth: bool in [true, false]:
			var sheet: Texture2D = load(WorldLayout.villager_sheet_path(look, cloth)) as Texture2D
			assert_eq(sheet.get_size(), Vector2(308, 30), "%s sheets keep the 11-cell layout" % look)


func test_an_unknown_look_falls_back_to_a_sheet_that_exists() -> void:
	assert_true(WorldLayout.villager_sheet_path(&"nobody", true).ends_with("mira.png"))
	assert_true(WorldLayout.villager_sheet_path(&"nobody", false).ends_with("mira.png"))


func test_villagers_change_clothes_when_the_cloth_is_woven() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var view: WorldView = WorldView.new()
	view.setup(sim, DesktopWindow.new())
	var actor: VillagerActor = view._actors[sim.world.villagers[0].id]
	assert_true(_sheet_of(actor).contains("/cave/"), "Furs to begin with")
	sim.world.achievements.append(&"woven_cloth")
	view.on_world_changed()
	assert_true(_sheet_of(actor).contains("/settled/"), "Woven tunics once there is cloth")
	for other: VillagerActor in view._actors.values():
		assert_true(_sheet_of(other).contains("/settled/"), "Everyone changes")
	view.free()


func test_a_villager_who_arrives_after_the_cloth_is_already_dressed() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.achievements.append(&"woven_cloth")
	var view: WorldView = WorldView.new()
	view.setup(sim, DesktopWindow.new())
	sim.add_villager()
	view.on_world_changed()
	for actor: VillagerActor in view._actors.values():
		assert_true(_sheet_of(actor).contains("/settled/"))
	view.free()


func test_swapping_clothes_keeps_the_animation() -> void:
	var actor: VillagerActor = VillagerActor.new()
	actor.setup(&"t", load(WorldLayout.villager_sheet_path(&"mira", false)) as Texture2D)
	actor._sprite.play(&"chop")
	actor._sprite.frame = 2
	actor.set_sheet(load(WorldLayout.villager_sheet_path(&"mira", true)) as Texture2D)
	assert_eq(actor._sprite.animation, &"chop")
	assert_eq(actor._sprite.frame, 2)
	assert_true(_sheet_of(actor).contains("/settled/"))
	actor.free()


func test_the_popup_portrait_wears_the_same_clothes() -> void:
	var sim: Simulation = SimFixture.new_sim()
	for cloth: bool in [false, true]:
		if cloth:
			sim.world.achievements.append(&"woven_cloth")
		var panel: PanelHost = PanelHost.new()
		panel.show_villager(sim, sim.world.villagers[0].id)
		var checked: int = 0
		for node: Node in panel.find_children("*", "TextureRect", true, false):
			var picture: TextureRect = node as TextureRect
			if picture.custom_minimum_size == PanelHost.PORTRAIT_SIZE:
				var atlas: AtlasTexture = picture.texture as AtlasTexture
				assert_eq(atlas.atlas.resource_path.contains("/settled/"), cloth)
				checked += 1
		assert_eq(checked, 1)
		panel.free()
