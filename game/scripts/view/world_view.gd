class_name WorldView
extends Node2D
## Draws the settlement from the simulation: the backdrop, always-present props, buildings and
## their construction sites as the world says, the strange flower, villagers walking and
## working, and the light through the day. It only reads WorldState; it never changes it.
## Call `on_world_changed()` after the simulation advances.
##
## The world is wider than the viewport (see WorldLayout): a scrolling container sits inside a
## The world is three pages wide (see the header): pages west and east of the camp have their own
## art, drawn by tools/art/cave_pages.js.

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
var _flower_sprout: Sprite2D
var _flower_bloom: Sprite2D
var _actors: Dictionary = {}
var _tint: CanvasModulate = CanvasModulate.new()
var _signature: String = ""
var _dragging: bool = false
var _drag_mouse_x: float = 0.0
var _drag_camera_x: float = 0.0
var _applied_pixel: int = -999999


func setup(sim: Simulation, window: DesktopWindow) -> void:
	_sim = sim
	_window = window
	_clip.size = Vector2(WorldLayout.VIEW_SIZE)
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_clip)
	_clip.add_child(_world)
	add_child(_tint)
	for index: int in WorldLayout.BACKDROP.size():
		var layer: StringName = WorldLayout.BACKDROP[index]
		_backdrop[layer] = _make_backdrop_pages(layer, -100 + index)
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
		_buildings[building_id] = _make_sprite(StringName("building_%s" % building_id), z)
		_sites[building_id] = _make_sprite(StringName("site_%s" % building_id), z)
	_flower_sprout = _make_sprite(&"flower_sprout", WorldLayout.FLOWER_Z)
	_flower_bloom = _make_sprite(&"flower_bloom", WorldLayout.FLOWER_Z)
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
	return _ui.clickable_regions()


func on_world_changed() -> void:
	_refresh_props()
	_refresh_actors()
	update_light()


## Re-tints the scene for the current time of day. Cheap enough to call every frame.
func update_light() -> void:
	_tint.color = DayNight.tint(DayNight.hour_of_world(_sim.world, _sim.config))


func _process(delta: float) -> void:
	if _camera.step(delta):
		_apply_camera()


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
				_dragging = false
			elif _clip.get_global_rect().has_point(button.position):
				_dragging = true
				_drag_mouse_x = button.position.x
				_drag_camera_x = _camera.shown
		MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT:
			if button.pressed:
				pan_by(WorldLayout.WHEEL_STEP)
		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT:
			if button.pressed:
				pan_by(-WorldLayout.WHEEL_STEP)


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
	var site: BuildingState = world.constructing()
	for building_id: StringName in _buildings:
		(_buildings[building_id] as Sprite2D).visible = world.has_building(building_id)
		(_sites[building_id] as Sprite2D).visible = site != null and site.def_id == building_id
	var planted: bool = not world.plants.is_empty()
	var bloomed: bool = planted and world.plants[0].flowered
	_flower_sprout.visible = planted and not bloomed
	_flower_bloom.visible = bloomed
	var signature: String = _shape_signature()
	if signature != _signature:
		_signature = signature
		_rebuild_skyline()


func _refresh_actors() -> void:
	var world: WorldState = _sim.world
	for slot: int in world.villagers.size():
		var villager: VillagerState = world.villagers[slot]
		var actor: VillagerActor = _actors.get(villager.id)
		if actor == null:
			actor = _make_actor(villager)
		actor.apply_plan(_planner.plan(villager, world, _sim.config, slot))


func _make_actor(villager: VillagerState) -> VillagerActor:
	var look: StringName = villager.look if villager.look != &"" else villager.id
	var path: String = "%s%s.png" % [WorldLayout.VILLAGER_DIR, look]
	if not ResourceLoader.exists(path):
		path = "%smira.png" % WorldLayout.VILLAGER_DIR
	var actor: VillagerActor = VillagerActor.new()
	_world.add_child(actor)
	actor.setup(villager.id, load(path) as Texture2D)
	_actors[villager.id] = actor
	return actor


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
	var path: String = "%s%s.png" % [WorldLayout.ASSET_DIR, layer]
	var sprite: Sprite2D = Sprite2D.new()
	sprite.centered = false
	sprite.z_index = z
	sprite.position.x = at_x
	if ResourceLoader.exists(path):
		sprite.texture = load(path) as Texture2D
	else:
		push_error("Missing world art: %s" % path)
	_world.add_child(sprite)
	return sprite


## Which solid pieces are showing, so the click region is only rebuilt when it changes.
func _shape_signature() -> String:
	var parts: PackedStringArray = PackedStringArray()
	for building_id: StringName in _buildings:
		parts.append("b" if (_buildings[building_id] as Sprite2D).visible else "-")
		parts.append("s" if (_sites[building_id] as Sprite2D).visible else "-")
	parts.append("f" if _flower_sprout.visible else "-")
	parts.append("F" if _flower_bloom.visible else "-")
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
	for sprite: Sprite2D in [_flower_sprout, _flower_bloom]:
		if sprite.visible:
			skyline.add(sprite.texture, _world_column(sprite))
	_window.set_skyline(skyline.tops)


## A sprite's left edge as a column of the whole world (which starts at WORLD_LEFT).
func _world_column(sprite: Sprite2D) -> int:
	return int(sprite.position.x) - WorldLayout.WORLD_LEFT
