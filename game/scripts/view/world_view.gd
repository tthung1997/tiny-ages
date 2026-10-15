class_name WorldView
extends Node2D
## Draws the settlement from the simulation: the backdrop, always-present props, buildings and
## their construction sites as the world says, the strange flower, villagers walking and
## working, and the light through the day. It only reads WorldState; it never changes it.
## Call `on_world_changed()` after the simulation advances. Clicking a villager (a press and
## release without dragging) reports `villager_clicked`.
##
## The world is three pages wide (WorldLayout): pages west and east of the camp have their own
## art, drawn by tools/art/cave_pages.js.

signal villager_clicked(villager_id: StringName)
## A right click on the strip: the game opens its menu.
signal menu_requested

## How far the pointer may move between press and release and still be a click, in art pixels.
const CLICK_SLOP: float = 3.0

var _sim: Simulation
var _window: DesktopWindow
var _planner: VillagerPlanner = VillagerPlanner.new()
var _full_scene: bool = true
var _clip: Control = Control.new()
var _world: Node2D = Node2D.new()
var _ui: ScrollUi = ScrollUi.new()
var _camera: ScrollCamera = ScrollCamera.new(
	float(WorldLayout.WORLD_LEFT), float(WorldLayout.WORLD_RIGHT - WorldLayout.VIEW_SIZE.x), 0.0
)
var _backdrop: Dictionary = {}
var _static_layers: Array[Sprite2D] = []
var _buildings: Dictionary = {}
var _sites: Dictionary = {}
var _props: Dictionary = {}
var _art_era: int = -1
var _cloth: bool = false
var _flower_sprout: Sprite2D
var _flower_bloom: Sprite2D
var _fire_pit: Sprite2D
var _fire_glow: Sprite2D
var _fire_frames: Array[Texture2D] = []
var _fire_frame: int = 0
var _fire_clock: float = 0.0
var _sea: Sprite2D
var _sea_frames: Array[Texture2D] = []
var _sea_sets: Array = []
var _sea_state: int = WeatherLook.SEA_CALM
var _sea_frame: int = 0
var _sea_clock: float = 0.0
var _flats: Sprite2D
var _life: Sprite2D
var _life_frames: Array[Texture2D] = []
var _life_frame: int = 0
var _life_clock: float = 0.0
var _deer: Sprite2D
var _deer_frames: Array[Texture2D] = []
var _stars: Sprite2D
var _sun: Sprite2D
var _moon: Sprite2D
var _actors: Dictionary = {}
var _tint: CanvasModulate = CanvasModulate.new()
var _signature: String = ""
var _dragging: bool = false
var _drag_mouse_x: float = 0.0
var _press_position: Vector2 = Vector2.ZERO
var _drag_camera_x: float = 0.0
var _applied_pixel: int = -999999
var _season_ground: ShaderMaterial = ShaderMaterial.new()
var _season_trees: ShaderMaterial = ShaderMaterial.new()
var _applied_season: int = -1
var _season_overlays: Array[Sprite2D] = []
var _weather: WeatherLayer = WeatherLayer.new()

const SEASON_SHADER: String = "res://assets/world/season_palette.gdshader"


func setup(sim: Simulation, window: DesktopWindow) -> void:
	_sim = sim
	_window = window
	_clip.size = Vector2(WorldLayout.VIEW_SIZE)
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_clip)
	_clip.add_child(_world)
	var shader: Shader = load(SEASON_SHADER) as Shader
	if shader == null:
		push_error("Missing season shader: %s" % SEASON_SHADER)
	_season_ground.shader = shader
	_season_trees.shader = shader
	_world.material = _season_ground
	_stars = _make_sky_sprite(_load_art(WorldLayout.STARS))
	_sun = _make_sky_sprite(_celestial(0))
	_moon = _make_sky_sprite(_celestial(1))
	add_child(_weather)
	_weather.setup(_clip)
	add_child(_tint)
	for index: int in WorldLayout.BACKDROP.size():
		var layer: StringName = WorldLayout.BACKDROP[index]
		_backdrop[layer] = _make_backdrop_pages(layer, -100 + index)
		if layer == &"trees":
			for trees: Sprite2D in _backdrop[layer]:
				trees.use_parent_material = false
				trees.material = _season_trees
	_sea = _make_sprite(
		WorldLayout.sea_frame_name(0), WorldLayout.SEA_Z, float(WorldLayout.SIDE_PAGES["east_"])
	)
	for state: int in WorldLayout.SEA_STATE_PREFIX.size():
		var frames: Array[Texture2D] = []
		for frame: int in WorldLayout.SEA_FRAMES:
			frames.append(_load_art(WorldLayout.sea_frame_name(frame, state)))
		_sea_sets.append(frames)
	_sea_frames = _sea_sets[WeatherLook.SEA_CALM]
	var east_x: float = float(WorldLayout.SIDE_PAGES["east_"])
	_flats = _make_sprite(WorldLayout.FLATS, WorldLayout.FLATS_Z, east_x)
	_life = _make_sprite(WorldLayout.life_frame_name(0), WorldLayout.LIFE_Z, east_x)
	_deer = _make_sprite(WorldLayout.deer_frame_name(0), WorldLayout.LIFE_Z + 1, east_x)
	for frame: int in WorldLayout.LIFE_FRAMES:
		_life_frames.append(_load_art(WorldLayout.life_frame_name(frame)))
	for frame: int in WorldLayout.DEER_FRAMES:
		_deer_frames.append(_load_art(WorldLayout.deer_frame_name(frame)))
	for layer: StringName in WorldLayout.STATIC_Z:
		_static_layers.append(_make_sprite(layer, WorldLayout.STATIC_Z[layer]))
	for prefix: String in WorldLayout.SIDE_PAGES:
		for layer: StringName in WorldLayout.SIDE_STATIC[prefix]:
			var side: Sprite2D = _make_sprite(
				StringName(prefix + layer), WorldLayout.STATIC_Z[layer],
				float(WorldLayout.SIDE_PAGES[prefix])
			)
			_static_layers.append(side)
	for building_id: StringName in WorldLayout.BUILDINGS:
		var z: int = WorldLayout.BUILDINGS[building_id]["z"]
		_buildings[building_id] = _make_piece(StringName("building_%s" % building_id), z)
		_sites[building_id] = _make_piece(StringName("site_%s" % building_id), z)
	for prop_id: StringName in SceneProps.ids():
		_props[prop_id] = _make_piece(prop_id, SceneProps.z_of(prop_id), SceneProps.at_x_of(prop_id))
	_flower_sprout = _make_sprite(&"flower_sprout", WorldLayout.FLOWER_Z)
	_flower_bloom = _make_sprite(&"flower_bloom", WorldLayout.FLOWER_Z)
	_fire_pit = _make_sprite(WorldLayout.fire_frame_name(0), WorldLayout.FIRE_PIT_Z)
	for frame: int in WorldLayout.FIRE_FRAMES:
		_fire_frames.append(_load_art(WorldLayout.fire_frame_name(frame)))
	_fire_glow = _make_sprite(WorldLayout.FIRE_GLOW, WorldLayout.FIRE_GLOW_Z)
	var additive: CanvasItemMaterial = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_fire_glow.material = additive
	_fire_glow.use_parent_material = false
	_ui.layout(float(WorldLayout.VIEW_SIZE.x))
	_ui.z_index = 1000
	_ui.pan_requested.connect(func(direction: int) -> void: pan_by(direction * WorldLayout.PAN_STEP))
	add_child(_ui)
	_apply_camera()
	on_world_changed()


## Only the opaque window shows the full diorama; on the desktop the sky and far hills would
## cover other apps, so strip and corner mode keep the near hills, tree line and ground.
func set_full_scene(full: bool) -> void:
	_full_scene = full
	for layer: StringName in _backdrop:
		var shown: bool = full or WorldLayout.DESKTOP_BACKDROP.has(layer)
		for sprite: Sprite2D in _backdrop[layer]:
			sprite.visible = shown
	if _sim != null:
		_weather.apply(_sim.world, _full_scene)
		update_light()


## Glides the camera by `amount` art pixels (negative is west).
func pan_by(amount: float) -> void:
	_camera.pan_by(amount)
	_apply_camera()


## Puts the camera's left edge at camp pixel `x` straight away.
func jump_camera(x: float) -> void:
	_camera.jump_to(x)
	_apply_camera()


func recenter() -> void:
	_camera.glide_to(0.0)
	_apply_camera()


## The whole-pixel left edge of the viewport, in camp pixels (0 is the camp page).
func camera_x() -> int:
	return _camera.pixel_x()


## Areas that must stay clickable in strip mode (the pan arrows), in viewport art pixels.
func clickable_regions() -> Array[Rect2i]:
	var regions: Array[Rect2i] = _ui.clickable_regions()
	if covers_sky():
		regions.append(Rect2i(Vector2i.ZERO, WorldLayout.VIEW_SIZE))
	return regions


## Whether rain or snow is falling across the whole viewport with no sky drawn behind it (strip and
## corner mode), so the viewport is drawn, and therefore clickable, while it lasts.
func covers_sky() -> bool:
	return _weather.covers_sky()


func on_world_changed() -> void:
	_refresh_season()
	_refresh_life()
	_refresh_props()
	_refresh_actors()
	_weather.apply(_sim.world, _full_scene)
	update_light()


## Re-tints the scene for the current time of day, season and weather. Cheap enough to call every
## frame.
func update_light() -> void:
	var hour: float = DayNight.hour_of_world(_sim.world, _sim.config)
	var lit: bool = _sim.world.has_fire()
	var season: int = _sim.config.season_at(_sim.world.tick)
	var tint: Color = DayNight.tint(hour, lit) * SeasonLook.tint(season) \
			* WeatherLook.tint(_sim.world.weather)
	_tint.color = tint
	_sea.modulate = SeasonLook.sea_tint(season) * WeatherLook.sea_tint(_sim.world.weather)
	_set_sea_state(WeatherLook.sea_state(_sim.world.weather))
	# The tint dims every piece, so the glow is boosted back to its own colour and only fades
	# in with the dark.
	var strength: float = DayNight.night_amount(hour) if lit else 0.0
	_fire_glow.visible = strength > 0.0
	_fire_glow.modulate = Color(
		1.0 / tint.r, 1.0 / tint.g, 1.0 / tint.b,
		strength * WorldLayout.FIRE_GLOW_FLICKER[_fire_frame]
	)
	_update_sky(hour, tint)


## The sun and the moon cross the sky and the stars come out, but only where the sky is drawn
## (the opaque window); on the desktop none of it exists. The moon and the stars are boosted back
## to their own colour like the glow; the sun takes the tint, so it reddens at dawn and dusk.
func _update_sky(hour: float, tint: Color) -> void:
	var sun_at: Vector2 = DayNight.sun_position(hour) if _full_scene else Vector2.INF
	var moon_at: Vector2 = DayNight.moon_position(hour) if _full_scene else Vector2.INF
	_place_body(_sun, sun_at)
	_place_body(_moon, moon_at)
	var stars: float = DayNight.star_alpha(hour) if _full_scene else 0.0
	_stars.visible = stars > 0.0
	var boost: Color = Color(1.0 / tint.r, 1.0 / tint.g, 1.0 / tint.b)
	_stars.modulate = Color(boost.r, boost.g, boost.b, stars)
	_moon.modulate = boost


## Puts a sky body's centre at `at` on whole pixels, or hides it if it is below the horizon.
func _place_body(body: Sprite2D, at: Vector2) -> void:
	body.visible = at.is_finite()
	if body.visible:
		body.position = (at - Vector2(WorldLayout.CELESTIAL_CELL) / 2.0).round()


## The fire flickers by swapping its flame frame on a slow clock. It does nothing at all while
## there is no fire or none of the light is on screen.
func _animate_fire(delta: float) -> void:
	if not _fire_pit.visible:
		return
	var left: float = float(_camera.pixel_x())
	if left > WorldLayout.FIRE_LIGHT_X.y or left + float(WorldLayout.VIEW_SIZE.x) < WorldLayout.FIRE_LIGHT_X.x:
		return
	_fire_clock += delta
	if _fire_clock < WorldLayout.FIRE_FRAME_SECONDS:
		return
	_fire_clock = 0.0
	set_fire_frame(_fire_frame + 1)


func set_fire_frame(frame: int) -> void:
	_fire_frame = posmod(frame, WorldLayout.FIRE_FRAMES)
	_fire_pit.texture = _fire_frames[_fire_frame]
	update_light()


## Swaps to the frames of a calmer or rougher sea, keeping the phase so the swell does not jump.
func _set_sea_state(state: int) -> void:
	if state == _sea_state:
		return
	_sea_state = state
	_sea_frames = _sea_sets[state]
	_sea.texture = _sea_frames[_sea_frame]


## The sea swaps its surf and swell phase on a slow clock. It does nothing while the view is
## hidden or none of the sea is on screen.
func _animate_sea(delta: float) -> void:
	if not visible or not _sea.visible:
		return
	if float(_camera.pixel_x()) + float(WorldLayout.VIEW_SIZE.x) <= WorldLayout.SEA_X.x:
		return
	_sea_clock += delta
	if _sea_clock < WorldLayout.SEA_FRAME_SECONDS * WeatherLook.swell_scale(_sim.world.weather):
		return
	_sea_clock = 0.0
	_sea_frame = posmod(_sea_frame + 1, WorldLayout.SEA_FRAMES)
	_sea.texture = _sea_frames[_sea_frame]


## The fish and birds swap frames on a slow clock, and do nothing while none of the river's far
## side is on screen.
func _animate_life(delta: float) -> void:
	if not visible:
		return
	var left: float = float(_camera.pixel_x())
	var right: float = left + float(WorldLayout.VIEW_SIZE.x)
	if right <= WorldLayout.LIFE_X.x or left >= WorldLayout.LIFE_X.y:
		return
	_life_clock += delta
	if _life_clock < WorldLayout.LIFE_FRAME_SECONDS:
		return
	_life_clock = 0.0
	_life_frame += 1
	_life.texture = _life_frames[posmod(_life_frame, WorldLayout.LIFE_FRAMES)]
	_deer.texture = _deer_frames[posmod(floori(float(_life_frame) / 2.0), WorldLayout.DEER_FRAMES)]


## The deer comes down to drink at dawn and dusk; the tide bares the flats and covers them again.
## Both are decided by the world's clock, so there is nothing to animate.
func _refresh_life() -> void:
	var hour: float = DayNight.hour_of_world(_sim.world, _sim.config)
	_deer.visible = RiverLife.deer_visible(hour)
	var alpha: float = TideLook.flats_alpha(_sim.config.tide_at(_sim.world.tick))
	_flats.visible = alpha > 0.0
	_flats.modulate.a = alpha


func _process(delta: float) -> void:
	if _camera.step(delta):
		_apply_camera()
	_animate_fire(delta)
	_animate_sea(delta)
	_animate_life(delta)


func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null:
		_handle_button(button)
		return
	var motion := event as InputEventMouseMotion
	if motion != null and _dragging:
		_camera.jump_to(_drag_camera_x - (motion.position.x - _drag_mouse_x))
		_apply_camera()


func _handle_button(button: InputEventMouseButton) -> void:
	match button.button_index:
		MOUSE_BUTTON_LEFT:
			if not button.pressed:
				var was_dragging: bool = _dragging
				_dragging = false
				if was_dragging and button.position.distance_to(_press_position) <= CLICK_SLOP:
					_report_click(button.position)
			elif _clip.get_global_rect().has_point(button.position):
				_dragging = true
				_press_position = button.position
				_drag_mouse_x = button.position.x
				_drag_camera_x = _camera.shown
		MOUSE_BUTTON_RIGHT:
			if button.pressed and _clip.get_global_rect().has_point(button.position):
				menu_requested.emit()
		MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT:
			if button.pressed:
				pan_by(WorldLayout.WHEEL_STEP)
		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT:
			if button.pressed:
				pan_by(-WorldLayout.WHEEL_STEP)


func _report_click(at: Vector2) -> void:
	var id: StringName = villager_at(at)
	if id != &"":
		villager_clicked.emit(id)


## The villager standing at a point of the window (art pixels), or &"" if none. When two overlap
## the one in front, whose feet are lower on screen, wins. Hidden (asleep or away) villagers
## cannot be clicked.
func villager_at(at: Vector2) -> StringName:
	var point: Vector2 = _world.to_local(at)
	var found: StringName = &""
	var front: float = -INF
	for id: StringName in _actors:
		var actor: VillagerActor = _actors[id]
		if actor.visible and actor.hit_rect().has_point(point) and actor.position.y > front:
			front = actor.position.y
			found = id
	return found


func _apply_camera() -> void:
	var pixel: int = _camera.pixel_x()
	_ui.update_state(
		_camera.can_go(-1), _camera.can_go(1), WorldLayout.PAGE_COUNT,
		_camera.page_index(float(WorldLayout.VIEW_SIZE.x)),
	)
	if pixel == _applied_pixel:
		return
	_applied_pixel = pixel
	_world.position.x = -float(pixel)
	if _window != null:
		_window.set_scroll(pixel - WorldLayout.WORLD_LEFT)


func _refresh_props() -> void:
	var world: WorldState = _sim.world
	if world.era_order != _art_era:
		_art_era = world.era_order
		_retexture_pieces()
	var site: BuildingState = world.constructing()
	for building_id: StringName in _buildings:
		(_buildings[building_id] as Sprite2D).visible = world.has_building(building_id)
		(_sites[building_id] as Sprite2D).visible = site != null and site.def_id == building_id
	for prop_id: StringName in _props:
		(_props[prop_id] as Sprite2D).visible = SceneProps.is_shown(prop_id, world)
	var planted: bool = not world.plants.is_empty()
	var bloomed: bool = planted and world.plants[0].flowered
	_flower_sprout.visible = planted and not bloomed
	_flower_bloom.visible = bloomed
	_fire_pit.visible = world.has_fire()
	var signature: String = _shape_signature()
	if signature != _signature:
		_signature = signature
		_rebuild_skyline()


## The season's palette on the scrolling world, and the few pieces it adds (snow, blossom,
## leaves). Only does anything when the season turns.
func _refresh_season() -> void:
	var season: int = _sim.config.season_at(_sim.world.tick)
	if season == _applied_season:
		return
	_applied_season = season
	for key: StringName in SeasonLook.params(season):
		_season_ground.set_shader_parameter(key, SeasonLook.params(season)[key])
	for key: StringName in SeasonLook.tree_params(season):
		_season_trees.set_shader_parameter(key, SeasonLook.tree_params(season)[key])
	_rebuild_season_overlays(season)


func _rebuild_season_overlays(season: int) -> void:
	for old: Sprite2D in _season_overlays:
		old.queue_free()
	_season_overlays.clear()
	for layer: StringName in SeasonOverlay.LAYERS:
		for sprite: Sprite2D in _backdrop.get(layer, []):
			var source: Image = sprite.texture.get_image() if sprite.texture != null else null
			if source == null or source.is_empty():
				continue
			var overlay: Image = SeasonOverlay.build(source, layer, season)
			if overlay == null:
				continue
			var piece: Sprite2D = Sprite2D.new()
			piece.centered = false
			piece.use_parent_material = true
			piece.position = sprite.position
			piece.z_index = sprite.z_index
			piece.texture = ImageTexture.create_from_image(overlay)
			_world.add_child(piece)
			_season_overlays.append(piece)


func _refresh_actors() -> void:
	var world: WorldState = _sim.world
	var cloth: bool = WorldLayout.wears_cloth(world)
	if cloth != _cloth:
		_cloth = cloth
		for existing: VillagerActor in _actors.values():
			existing.set_sheet(_sheet_for(existing.get_meta(&"look")))
	var present: Dictionary = {}
	for villager: VillagerState in world.villagers:
		present[villager.id] = true
	for id: StringName in _actors.keys():
		if not present.has(id):
			(_actors[id] as VillagerActor).queue_free()
			_actors.erase(id)
	for slot: int in world.villagers.size():
		var villager: VillagerState = world.villagers[slot]
		var actor: VillagerActor = _actors.get(villager.id)
		if actor == null:
			actor = _make_actor(villager)
		actor.apply_plan(_planner.plan(villager, world, _sim.config, slot))


func _make_actor(villager: VillagerState) -> VillagerActor:
	var look: StringName = villager.look if villager.look != &"" else villager.id
	var actor: VillagerActor = VillagerActor.new()
	actor.set_meta(&"look", look)
	_world.add_child(actor)
	actor.setup(villager.id, _sheet_for(look))
	_actors[villager.id] = actor
	return actor


func _sheet_for(look: StringName) -> Texture2D:
	return load(WorldLayout.villager_sheet_path(look, _cloth)) as Texture2D


## The camp's backdrop layer plus the same layer of the west and east pages (art/cave_pages.js).
## Returns the camp's sprite first.
func _make_backdrop_pages(layer: StringName, z: int) -> Array[Sprite2D]:
	var sprites: Array[Sprite2D] = [_make_sprite(layer, z)]
	for prefix: String in WorldLayout.SIDE_PAGES:
		sprites.append(_make_sprite(
			StringName(prefix + layer), z, float(WorldLayout.SIDE_PAGES[prefix])
		))
	return sprites


## `at_x` is the sprite's left edge in camp pixels (0 for the camp page's own pieces).
func _make_sprite(layer: StringName, z: int, at_x: float = 0.0) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.centered = false
	sprite.use_parent_material = true
	sprite.z_index = z
	sprite.position.x = at_x
	sprite.texture = _load_art(layer)
	_world.add_child(sprite)
	return sprite


func _load_art(layer: StringName) -> Texture2D:
	var path: String = "%s%s.png" % [WorldLayout.ASSET_DIR, layer]
	if not ResourceLoader.exists(path):
		push_error("Missing world art: %s" % path)
		return null
	return load(path) as Texture2D


## A piece that an age may redraw (a building, its site, a prop): its art is the newest the
## current age has, and it is swapped when the age turns.
func _make_piece(layer: StringName, z: int, at_x: float = 0.0) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.centered = false
	sprite.use_parent_material = true
	sprite.z_index = z
	sprite.position.x = at_x
	sprite.visible = false
	sprite.set_meta(&"layer", layer)
	sprite.texture = _load_piece(layer, WorldLayout.ERA_DIRS.size() - 1)
	_world.add_child(sprite)
	return sprite


func _load_piece(layer: StringName, era_order: int) -> Texture2D:
	var path: String = WorldLayout.piece_path(layer, era_order)
	if path.is_empty():
		push_error("Missing world art: %s" % layer)
		return null
	return load(path) as Texture2D


## A piece with no art yet in the current age (a Settled prop while still in the Cave Age) keeps
## the texture it has: it is not shown until its age.
func _retexture_pieces() -> void:
	for group: Dictionary in [_buildings, _sites, _props]:
		for key: StringName in group:
			var sprite: Sprite2D = group[key]
			var layer: StringName = sprite.get_meta(&"layer")
			if not WorldLayout.piece_path(layer, _art_era).is_empty():
				sprite.texture = _load_piece(layer, _art_era)


## A piece of the sky, in the clip but not in the scrolling world, so it stays put as you pan.
func _make_sky_sprite(texture: Texture2D) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.centered = false
	sprite.z_index = WorldLayout.SKY_Z
	sprite.texture = texture
	sprite.visible = false
	_clip.add_child(sprite)
	return sprite


## One cell of the sun and moon sheet: 0 is the sun, 1 the moon.
func _celestial(cell: int) -> Texture2D:
	var sheet: Texture2D = _load_art(WorldLayout.CELESTIAL)
	if sheet == null:
		return null
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(
		Vector2(WorldLayout.CELESTIAL_CELL.x * cell, 0), Vector2(WorldLayout.CELESTIAL_CELL)
	)
	return atlas


## Which solid pieces are showing, so the click region is only rebuilt when it changes.
func _shape_signature() -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append(str(_art_era))
	for building_id: StringName in _buildings:
		parts.append("b" if (_buildings[building_id] as Sprite2D).visible else "-")
		parts.append("s" if (_sites[building_id] as Sprite2D).visible else "-")
	for prop_id: StringName in _props:
		parts.append("o" if (_props[prop_id] as Sprite2D).visible else "-")
	parts.append("f" if _flower_sprout.visible else "-")
	parts.append("F" if _flower_bloom.visible else "-")
	parts.append("p" if _fire_pit.visible else "-")
	parts.append("d" if _deer.visible else "-")
	return "".join(parts)


## What the player can click across the whole world: land and props that are currently drawn,
## desktop-mode backdrop only. The window reads the part that is in view.
func _rebuild_skyline() -> void:
	var skyline: Skyline = Skyline.new(WorldLayout.WORLD_WIDTH, WorldLayout.VIEW_SIZE.y)
	for layer: StringName in WorldLayout.DESKTOP_BACKDROP:
		for sprite: Sprite2D in _backdrop[layer]:
			skyline.add(sprite.texture, _world_column(sprite))
	for sprite: Sprite2D in _static_layers:
		skyline.add(sprite.texture, _world_column(sprite))
	for building_id: StringName in _buildings:
		for sprite: Sprite2D in [_buildings[building_id], _sites[building_id]]:
			if sprite.visible:
				skyline.add(sprite.texture, _world_column(sprite))
	for sprite: Sprite2D in _props.values():
		if sprite.visible:
			skyline.add(sprite.texture, _world_column(sprite))
	for sprite: Sprite2D in [_flower_sprout, _flower_bloom, _fire_pit, _life, _deer]:
		if sprite.visible:
			skyline.add(sprite.texture, _world_column(sprite))
	_window.set_skyline(skyline.tops)


## A sprite's left edge as a column of the whole world (which starts at WORLD_LEFT).
func _world_column(sprite: Sprite2D) -> int:
	return int(sprite.position.x) - WorldLayout.WORLD_LEFT
