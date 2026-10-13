class_name WorldView
extends Node2D
## Draws the settlement from the simulation: the backdrop, always-present props, buildings and
## their construction sites as the world says, the strange flower, villagers walking and
## working, and the light through the day. It only reads WorldState; it never changes it.
## Call `on_world_changed()` after the simulation advances.

var _sim: Simulation
var _window: DesktopWindow
var _planner: VillagerPlanner = VillagerPlanner.new()
var _full_scene: bool = true
var _backdrop: Dictionary = {}
var _static_layers: Array[Sprite2D] = []
var _buildings: Dictionary = {}
var _sites: Dictionary = {}
var _flower_sprout: Sprite2D
var _flower_bloom: Sprite2D
var _actors: Dictionary = {}
var _tint: CanvasModulate = CanvasModulate.new()
var _signature: String = ""


func setup(sim: Simulation, window: DesktopWindow) -> void:
	_sim = sim
	_window = window
	add_child(_tint)
	for index: int in WorldLayout.BACKDROP.size():
		var layer: StringName = WorldLayout.BACKDROP[index]
		_backdrop[layer] = _make_sprite(layer, -100 + index)
	for layer: StringName in WorldLayout.STATIC_Z:
		_static_layers.append(_make_sprite(layer, WorldLayout.STATIC_Z[layer]))
	for building_id: StringName in WorldLayout.BUILDINGS:
		var z: int = WorldLayout.BUILDINGS[building_id]["z"]
		_buildings[building_id] = _make_sprite(StringName("building_%s" % building_id), z)
		_sites[building_id] = _make_sprite(StringName("site_%s" % building_id), z)
	_flower_sprout = _make_sprite(&"flower_sprout", WorldLayout.FLOWER_Z)
	_flower_bloom = _make_sprite(&"flower_bloom", WorldLayout.FLOWER_Z)
	on_world_changed()


## Only the opaque window shows the full diorama; on the desktop the sky and far hills would
## cover other apps, so strip and corner mode keep the near hills, tree line and ground.
func set_full_scene(full: bool) -> void:
	_full_scene = full
	for layer: StringName in _backdrop:
		(_backdrop[layer] as Sprite2D).visible = full or WorldLayout.DESKTOP_BACKDROP.has(layer)


func on_world_changed() -> void:
	_refresh_props()
	_refresh_actors()
	update_light()


## Re-tints the scene for the current time of day. Cheap enough to call every frame.
func update_light() -> void:
	_tint.color = DayNight.tint(DayNight.hour_of_world(_sim.world, _sim.config))


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
		_window.set_silhouettes(_solid_textures())


func _refresh_actors() -> void:
	var world: WorldState = _sim.world
	for slot: int in world.villagers.size():
		var villager: VillagerState = world.villagers[slot]
		var actor: VillagerActor = _actors.get(villager.id)
		if actor == null:
			actor = _make_actor(villager)
		actor.apply_plan(_planner.plan(villager, world, _sim.config, slot))


func _make_actor(villager: VillagerState) -> VillagerActor:
	var path: String = "%s%s.png" % [WorldLayout.VILLAGER_DIR, villager.id]
	if not ResourceLoader.exists(path):
		path = "%smira.png" % WorldLayout.VILLAGER_DIR
	var actor: VillagerActor = VillagerActor.new()
	add_child(actor)
	actor.setup(villager.id, load(path) as Texture2D)
	_actors[villager.id] = actor
	return actor


func _make_sprite(layer: StringName, z: int) -> Sprite2D:
	var path: String = "%s%s.png" % [WorldLayout.ASSET_DIR, layer]
	var sprite: Sprite2D = Sprite2D.new()
	sprite.centered = false
	sprite.z_index = z
	if ResourceLoader.exists(path):
		sprite.texture = load(path) as Texture2D
	else:
		push_error("Missing world art: %s" % path)
	add_child(sprite)
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


## What the player can click: land and props that are currently drawn, desktop-mode backdrop only.
func _solid_textures() -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for layer: StringName in WorldLayout.DESKTOP_BACKDROP:
		textures.append((_backdrop[layer] as Sprite2D).texture)
	for sprite: Sprite2D in _static_layers:
		textures.append(sprite.texture)
	for building_id: StringName in _buildings:
		for sprite: Sprite2D in [_buildings[building_id], _sites[building_id]]:
			if sprite.visible:
				textures.append(sprite.texture)
	for sprite: Sprite2D in [_flower_sprout, _flower_bloom]:
		if sprite.visible:
			textures.append(sprite.texture)
	return textures
