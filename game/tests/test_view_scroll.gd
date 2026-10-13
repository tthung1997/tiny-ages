extends McpTestSuite
## The scrolling world: the camera's rules, the skyline that decides what is clickable, and a
## smoke test that the view builds its three pages and pans.


func suite_name() -> String:
	return "view_scroll"


func _texture(width: int, height: int, opaque: Array[Vector2i]) -> ImageTexture:
	var image: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for pixel: Vector2i in opaque:
		image.set_pixelv(pixel, Color(1, 0, 0, 1))
	return ImageTexture.create_from_image(image)


func test_the_camera_starts_inside_its_bounds() -> void:
	assert_eq(ScrollCamera.new(-100.0, 100.0, 0.0).shown, 0.0)
	assert_eq(ScrollCamera.new(-100.0, 100.0, 500.0).shown, 100.0)
	assert_eq(ScrollCamera.new(100.0, -100.0, 0.0).min_x, -100.0, "Bounds are put in order")


func test_panning_stops_at_the_edges_of_the_world() -> void:
	var camera: ScrollCamera = ScrollCamera.new(-384.0, 384.0, 0.0)
	camera.pan_by(-1000.0)
	assert_eq(camera.target, -384.0)
	assert_false(camera.can_go(-1), "Nothing further west")
	assert_true(camera.can_go(1))
	camera.pan_by(5000.0)
	assert_eq(camera.target, 384.0)
	assert_true(camera.can_go(-1))
	assert_false(camera.can_go(1), "Nothing further east")


func test_a_pan_glides_and_never_overshoots() -> void:
	var camera: ScrollCamera = ScrollCamera.new(-384.0, 384.0, 0.0)
	camera.pan_by(288.0)
	assert_eq(camera.shown, 0.0, "A pan does not jump")
	var previous: float = camera.shown
	var frames: int = 0
	while camera.step(1.0 / 30.0) and frames < 600:
		assert_true(camera.shown >= previous, "Moves one way only")
		assert_true(camera.shown <= 288.0, "Never passes the target")
		previous = camera.shown
		frames += 1
	assert_eq(camera.shown, 288.0, "Arrives exactly")
	assert_true(frames < 90, "And within a few seconds")
	assert_false(camera.step(1.0 / 30.0), "Idle once arrived")


func test_dragging_jumps_straight_there() -> void:
	var camera: ScrollCamera = ScrollCamera.new(-384.0, 384.0, 0.0)
	camera.jump_to(-120.0)
	assert_eq(camera.shown, -120.0)
	assert_eq(camera.target, -120.0)
	camera.jump_to(9999.0)
	assert_eq(camera.shown, 384.0, "Dragging past the end stops at the end")


func test_pixel_art_is_drawn_on_whole_pixels() -> void:
	var camera: ScrollCamera = ScrollCamera.new(-384.0, 384.0, 0.0)
	camera.jump_to(12.4)
	assert_eq(camera.pixel_x(), 12)
	camera.jump_to(12.6)
	assert_eq(camera.pixel_x(), 13)


func test_the_page_indicator_follows_the_camera() -> void:
	var camera: ScrollCamera = ScrollCamera.new(-384.0, 384.0, 0.0)
	camera.jump_to(-384.0)
	assert_eq(camera.page_index(384.0), 0)
	camera.jump_to(0.0)
	assert_eq(camera.page_index(384.0), 1)
	camera.jump_to(384.0)
	assert_eq(camera.page_index(384.0), 2)


func test_the_world_is_three_pages_with_the_camp_in_the_middle() -> void:
	assert_eq(WorldLayout.WORLD_WIDTH, 1152)
	assert_eq(WorldLayout.PAGE_COUNT, 3)
	assert_eq(WorldLayout.WORLD_WIDTH, WorldLayout.PAGE_COUNT * WorldLayout.VIEW_SIZE.x)
	assert_eq(WorldLayout.WORLD_LEFT, -WorldLayout.VIEW_SIZE.x)


func test_villagers_stay_on_land_and_arrive_from_the_forest() -> void:
	assert_true(WorldLayout.WANDER_X.x > float(WorldLayout.WORLD_LEFT))
	assert_true(WorldLayout.WANDER_X.y < 298.0, "The camp's river starts at about x = 298")
	assert_true(WorldLayout.WEST_EDGE.x < float(WorldLayout.WORLD_LEFT), "Arrivals come from off the west end")


func test_skyline_finds_the_highest_opaque_pixel_per_column() -> void:
	var skyline: Skyline = Skyline.new(8, 10)
	var texture: ImageTexture = _texture(4, 10, [Vector2i(1, 6), Vector2i(1, 3), Vector2i(2, 8)])
	skyline.add(texture, 2)
	assert_eq(skyline.tops[2], 10, "Empty column")
	assert_eq(skyline.tops[3], 3, "Highest of two pixels")
	assert_eq(skyline.tops[4], 8)
	assert_eq(skyline.tops[0], 10, "Untouched")


func test_skyline_ignores_nearly_transparent_pixels() -> void:
	var image: Image = Image.create(2, 4, false, Image.FORMAT_RGBA8)
	image.set_pixel(0, 1, Color(1, 0, 0, 0.3))
	image.set_pixel(1, 2, Color(1, 0, 0, 0.9))
	var skyline: Skyline = Skyline.new(2, 4)
	skyline.add(ImageTexture.create_from_image(image), 0)
	assert_eq(skyline.tops[0], 4, "A faint pixel is not clickable")
	assert_eq(skyline.tops[1], 2)


func test_skyline_can_mirror_a_piece() -> void:
	var skyline: Skyline = Skyline.new(4, 10)
	skyline.add(_texture(4, 10, [Vector2i(0, 5)]), 0, true)
	assert_eq(skyline.tops[3], 5, "The left column lands on the right when mirrored")
	assert_eq(skyline.tops[0], 10)


func test_skyline_keeps_the_highest_of_overlapping_pieces() -> void:
	var skyline: Skyline = Skyline.new(4, 10)
	skyline.add(_texture(4, 10, [Vector2i(1, 7)]), 0)
	skyline.add(_texture(4, 10, [Vector2i(1, 2)]), 0)
	skyline.add(_texture(4, 10, [Vector2i(1, 9)]), 0)
	assert_eq(skyline.tops[1], 2)


func test_skyline_ignores_the_parts_of_a_piece_outside_the_world() -> void:
	var skyline: Skyline = Skyline.new(4, 10)
	var texture: ImageTexture = _texture(4, 10, [Vector2i(0, 1), Vector2i(3, 1)])
	skyline.add(texture, -2)
	skyline.add(texture, 3)
	assert_eq(skyline.tops[0], 10, "Nothing lands where only the dropped column would")
	assert_eq(skyline.tops[1], 1, "The part of the left overhang that is inside is kept")
	assert_eq(skyline.tops[2], 10)
	assert_eq(skyline.tops[3], 1, "The right overhang's first column is kept")


func test_skyline_slice_clamps_at_the_edges() -> void:
	var skyline: Skyline = Skyline.new(4, 10)
	skyline.add(_texture(4, 10, [Vector2i(0, 2), Vector2i(3, 6)]), 0)
	assert_eq(skyline.slice(-2, 4), PackedInt32Array([2, 2, 2, 10]))
	assert_eq(skyline.slice(2, 4), PackedInt32Array([10, 6, 6, 6]))


func test_the_window_clicks_only_what_is_in_view() -> void:
	var window: DesktopWindow = DesktopWindow.new()
	var skyline: Skyline = Skyline.new(WorldLayout.WORLD_WIDTH, 80)
	skyline.add(_texture(4, 80, [Vector2i(0, 20)]), 500)
	window.set_skyline(skyline.tops)
	window.set_scroll(495)
	var tops: PackedInt32Array = window._view_tops()
	assert_eq(tops.size(), DesktopWindow.ART_SIZE.x)
	assert_eq(tops[5], 20, "Column 500 of the world is column 5 of the view")
	assert_eq(tops[0], 80)
	window.set_scroll(0)
	assert_eq(window._view_tops()[5], 80, "Scrolled away, it is no longer clickable")
	window.free()


func test_extra_regions_stay_clickable_wherever_the_view_is() -> void:
	var window: DesktopWindow = DesktopWindow.new()
	window.set_skyline(Skyline.new(WorldLayout.WORLD_WIDTH, 80).tops)
	var regions: Array[Rect2i] = [Rect2i(0, 44, 15, 36), Rect2i(369, 44, 15, 36)]
	window.set_extra_regions(regions)
	window.set_scroll(300)
	var tops: PackedInt32Array = window._view_tops()
	assert_eq(tops[0], 44)
	assert_eq(tops[14], 44)
	assert_eq(tops[15], 80)
	assert_eq(tops[383], 44)
	window.free()


func _mouse_button(index: MouseButton, pressed: bool, at: Vector2) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = index
	event.pressed = pressed
	event.position = at
	return event


func _mouse_move(at: Vector2) -> InputEventMouseMotion:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = at
	return event


func test_the_wheel_and_the_arrows_pan() -> void:
	var view: WorldView = WorldView.new()
	var window: DesktopWindow = DesktopWindow.new()
	view.setup(SimFixture.new_sim(), window)
	view._unhandled_input(_mouse_button(MOUSE_BUTTON_WHEEL_DOWN, true, Vector2(50, 40)))
	view._process(5.0)
	assert_eq(view.camera_x(), int(WorldLayout.WHEEL_STEP), "Wheel down pans east")
	view._unhandled_input(_mouse_button(MOUSE_BUTTON_WHEEL_UP, true, Vector2(50, 40)))
	view._process(5.0)
	assert_eq(view.camera_x(), 0, "Wheel up pans back")
	view._ui.pan_requested.emit(-1)
	view._process(5.0)
	assert_eq(view.camera_x(), -int(WorldLayout.PAN_STEP), "The left arrow pans west a step")
	view.free()
	window.free()


func test_dragging_the_scene_pans_it_the_other_way() -> void:
	var view: WorldView = WorldView.new()
	var window: DesktopWindow = DesktopWindow.new()
	view.setup(SimFixture.new_sim(), window)
	view._unhandled_input(_mouse_button(MOUSE_BUTTON_LEFT, true, Vector2(200, 40)))
	view._unhandled_input(_mouse_move(Vector2(150, 40)))
	assert_eq(view.camera_x(), 50, "Dragging left reveals the east, with no glide")
	view._unhandled_input(_mouse_move(Vector2(260, 40)))
	assert_eq(view.camera_x(), -60)
	view._unhandled_input(_mouse_button(MOUSE_BUTTON_LEFT, false, Vector2(260, 40)))
	view._unhandled_input(_mouse_move(Vector2(0, 40)))
	assert_eq(view.camera_x(), -60, "Moving after the button is released does nothing")
	view.free()
	window.free()


func test_a_press_outside_the_view_does_not_start_a_drag() -> void:
	var view: WorldView = WorldView.new()
	var window: DesktopWindow = DesktopWindow.new()
	view.setup(SimFixture.new_sim(), window)
	view._unhandled_input(_mouse_button(MOUSE_BUTTON_LEFT, true, Vector2(-30, 40)))
	view._unhandled_input(_mouse_move(Vector2(-80, 40)))
	assert_eq(view.camera_x(), 0)
	view.free()
	window.free()


func test_the_view_builds_three_pages_and_pans() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var window: DesktopWindow = DesktopWindow.new()
	var view: WorldView = WorldView.new()
	view.setup(sim, window)
	var west: int = 0
	var east: int = 0
	for node: Node in view.find_children("*", "Sprite2D", true, false):
		var sprite: Sprite2D = node as Sprite2D
		assert_true(sprite.texture != null, "Every piece has art")
		if sprite.position.x == float(WorldLayout.SIDE_PAGES["west_"]):
			assert_true(sprite.texture.resource_path.contains("west_"), "West page art on the west")
			west += 1
		elif sprite.position.x == float(WorldLayout.SIDE_PAGES["east_"]):
			assert_true(sprite.texture.resource_path.contains("east_"), "East page art on the east")
			east += 1
	var backdrop: int = WorldLayout.BACKDROP.size()
	assert_eq(west, backdrop + WorldLayout.SIDE_STATIC["west_"].size())
	assert_eq(east, backdrop + WorldLayout.SIDE_STATIC["east_"].size())
	assert_eq(view.camera_x(), 0, "Starts on the camp")
	assert_eq(view.clickable_regions().size(), 2, "An arrow region on each edge")
	view.pan_by(-100000.0)
	view._process(5.0)
	assert_eq(view.camera_x(), WorldLayout.WORLD_LEFT, "Stops at the west end")
	view.recenter()
	view._process(5.0)
	assert_eq(view.camera_x(), 0)
	view.jump_camera(100000.0)
	assert_eq(view.camera_x(), WorldLayout.WORLD_RIGHT - WorldLayout.VIEW_SIZE.x)
	view.free()
	window.free()


func test_the_fire_pit_appears_when_the_fire_is_found() -> void:
	var sim: Simulation = SimFixture.new_sim(1, false)
	var window: DesktopWindow = DesktopWindow.new()
	var view: WorldView = WorldView.new()
	view.setup(sim, window)
	assert_false(view._fire_pit.visible, "No pit, and no firelight in the cave, without fire")
	var cold_night: Color = _night_tint(view)
	assert_false(view._fire_glow.visible, "No glow without fire, even at night")
	sim.world.flags[&"fire_found"] = true
	view.on_world_changed()
	assert_true(view._fire_pit.visible)
	assert_true(_night_tint(view).r > cold_night.r, "Night is darker without fire")
	assert_true(view._fire_glow.visible, "The fire lights the night")
	assert_eq(view._fire_glow.modulate.a, 1.0, "Full glow in the dead of night")
	sim.world.tick = sim.config.tick_for_hour(12)
	view.update_light()
	assert_false(view._fire_glow.visible, "No glow in daylight")
	view.free()
	window.free()


func test_the_fire_flickers_only_while_it_is_lit_and_in_view() -> void:
	var sim: Simulation = SimFixture.new_sim(1, false)
	sim.world.tick = sim.config.tick_for_hour(0)
	var window: DesktopWindow = DesktopWindow.new()
	var view: WorldView = WorldView.new()
	view.setup(sim, window)
	var step: float = WorldLayout.FIRE_FRAME_SECONDS + 0.01
	view._process(step)
	assert_eq(view._fire_frame, 0, "No fire, nothing to animate")
	sim.world.flags[&"fire_found"] = true
	view.on_world_changed()
	view._process(step)
	assert_eq(view._fire_frame, 1, "A flame frame passes each interval")
	assert_true(view._fire_pit.texture == view._fire_frames[1])
	assert_true(view._fire_glow.modulate.a < 1.0, "The glow dips with the flame")
	view._process(WorldLayout.FIRE_FRAME_SECONDS * 0.4)
	assert_eq(view._fire_frame, 1, "Not before the interval")
	for _pass: int in WorldLayout.FIRE_FRAMES:
		view._process(step)
	assert_eq(view._fire_frame, 1, "The frames loop")
	view.jump_camera(300.0)
	view._process(step)
	assert_eq(view._fire_frame, 1, "Looking at the river, the fire sleeps")
	view.jump_camera(-384.0)
	view._process(step)
	assert_eq(view._fire_frame, 1, "Looking at the forest, the fire sleeps")
	view.free()
	window.free()


func _night_tint(view: WorldView) -> Color:
	var config: SimConfig = view._sim.config
	view._sim.world.tick = config.tick_for_hour(0)
	view.update_light()
	return view._tint.color
