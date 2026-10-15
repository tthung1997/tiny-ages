class_name WeatherLayer
extends Node
## Draws the weather over the scene from one sheet of art (assets/world/weather.png, drawn by
## tools/art/weather.js): falling rain or snow and heat shimmer over the screen, storm clouds in
## the sky, and the pieces that stand in the world (cracked ground, flood water, the tornado's
## funnel). It only reads WorldState through WeatherLook.
##
## Cheap when ignored: a piece that is not showing costs nothing, and the animation clock only runs
## while some animated piece is on screen; otherwise this node does not process at all. There are
## no flashes. Sheet rows (each 80 px high) are mirrored in tools/art/weather.js.

const SHEET: String = "res://assets/world/weather.png"
const ROW_HEIGHT: int = 80
const ROW_RAIN: int = 0
const ROW_SNOW: int = 3
const ROW_SHIMMER: int = 6
const ROW_CRACKS_CAMP: int = 8
const ROW_CRACKS_WEST: int = 9
const ROW_FLOOD_CAMP: int = 10
const ROW_FLOOD_EAST: int = 12
const ROW_TORNADO: int = 14
const ROW_CLOUDS: int = 17
const ROW_WRECK: int = 19
const WRECK_CELL: Vector2i = Vector2i(28, 14)
const WRECK_VARIANTS: int = 2
## How long each frame stays up, in seconds.
const FALL_SECONDS: float = 0.14
const SHIMMER_SECONDS: float = 0.6
const WATER_SECONDS: float = 0.7
const FUNNEL_SECONDS: float = 0.25
const CLOUD_SECONDS: float = 1.2
## Camp x ranges (camp pixels) of the world pieces, so they sleep while off screen.
const CAMP_PAGE: Vector2 = Vector2(0.0, 384.0)
const WEST_PAGE: Vector2 = Vector2(-384.0, 0.0)
const EAST_PAGE: Vector2 = Vector2(384.0, 768.0)
const FALL_Z: int = 95
const SHIMMER_Z: int = 94
const CLOUDS_Z: int = -100
const WATER_Z: int = 5
const GROUND_Z: int = -90
const FUNNEL_Z: int = 85
const SHIMMER_ALPHA: float = 0.5
const FALL_ALPHA: float = 0.85
const MASK_SHADER: String = "res://assets/world/precipitation_mask.gdshader"

var _sheet: Texture2D
var _mask: ShaderMaterial = ShaderMaterial.new()
var _tops_image: Image = Image.create_empty(
	WorldLayout.VIEW_SIZE.x, 1, false, Image.FORMAT_R8
)
var _tops_texture: ImageTexture
var _fall: Sprite2D = Sprite2D.new()
var _shimmer: Sprite2D = Sprite2D.new()
var _clouds: Sprite2D = Sprite2D.new()
var _cracks_camp: Sprite2D = Sprite2D.new()
var _cracks_west: Sprite2D = Sprite2D.new()
var _flood_camp: Sprite2D = Sprite2D.new()
var _flood_east: Sprite2D = Sprite2D.new()
var _funnel: Sprite2D = Sprite2D.new()
var _frames: Dictionary = {}
var _clock: float = 0.0
var _left: float = 0.0
var _weather: StringName = &""
var _full_scene: bool = true
var _shown: Dictionary = {}


## `world_root` is the scrolling world (pieces stand in it); `screen_root` is the clip, which does
## not scroll (rain, shimmer and clouds stay put as you pan).
func setup(world_root: Node2D, screen_root: Control) -> void:
	_sheet = load(SHEET) as Texture2D
	if _sheet == null:
		push_error("Missing weather art: %s" % SHEET)
		return
	_place(_fall, screen_root, FALL_Z, Vector2.ZERO)
	_mask.shader = load(MASK_SHADER) as Shader
	_tops_image.fill(Color(1.0, 0.0, 0.0))
	_tops_texture = ImageTexture.create_from_image(_tops_image)
	_mask.set_shader_parameter("tops", _tops_texture)
	_fall.material = _mask
	_place(_shimmer, screen_root, SHIMMER_Z, Vector2.ZERO)
	_place(_clouds, screen_root, CLOUDS_Z, Vector2.ZERO)
	_place(_cracks_camp, world_root, GROUND_Z, Vector2(CAMP_PAGE.x, 0.0))
	_place(_cracks_west, world_root, GROUND_Z, Vector2(WEST_PAGE.x, 0.0))
	_place(_flood_camp, world_root, WATER_Z, Vector2(CAMP_PAGE.x, 0.0))
	_place(_flood_east, world_root, WATER_Z, Vector2(EAST_PAGE.x, 0.0))
	_place(_funnel, world_root, FUNNEL_Z, Vector2(CAMP_PAGE.x, 0.0))
	_shimmer.modulate.a = SHIMMER_ALPHA
	_fall.modulate.a = FALL_ALPHA
	_cracks_camp.texture = _row(ROW_CRACKS_CAMP)
	_cracks_west.texture = _row(ROW_CRACKS_WEST)
	set_process(false)


## The wreckage drawn at the foot of a broken building (a small piece of the sheet).
func wreck_texture(variant: int) -> Texture2D:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = _sheet
	atlas.region = Rect2(
		Vector2(posmod(variant, WRECK_VARIANTS) * 32, ROW_WRECK * ROW_HEIGHT), Vector2(WRECK_CELL)
	)
	return atlas


## Shows what the weather in `world` calls for. Call whenever the world changes.
func apply(world: WorldState, full_scene: bool) -> void:
	if _sheet == null:
		return
	_weather = world.weather
	_full_scene = full_scene
	_mask.set_shader_parameter("masked", not full_scene)
	var fall: StringName = WeatherLook.fall(_weather)
	_shown[&"fall"] = fall != &""
	_shown[&"shimmer"] = WeatherLook.shows(_weather, &"shimmer")
	_shown[&"cracks"] = WeatherLook.shows(_weather, &"cracks")
	_shown[&"water"] = WeatherLook.shows(_weather, &"water")
	_shown[&"funnel"] = WeatherLook.shows(_weather, &"funnel")
	_shown[&"clouds"] = WeatherLook.shows(_weather, &"clouds") and full_scene
	_fall.visible = _shown[&"fall"]
	_shimmer.visible = _shown[&"shimmer"]
	_cracks_camp.visible = _shown[&"cracks"]
	_cracks_west.visible = _shown[&"cracks"]
	_flood_camp.visible = _shown[&"water"]
	_flood_east.visible = _shown[&"water"]
	_funnel.visible = _shown[&"funnel"]
	_clouds.visible = _shown[&"clouds"]
	_frames.clear()
	_show_frames()
	_update_sleep()


## Tells the layer where the land is for each column of the viewport (the y of its highest
## pixel), so that on the desktop, with no sky, rain and snow fall over the land and not in the
## empty air above it.
func set_land(tops: PackedInt32Array) -> void:
	if _tops_texture == null:
		return
	for x: int in mini(tops.size(), _tops_image.get_width()):
		_tops_image.set_pixel(x, 0, Color(float(clampi(tops[x], 0, 255)) / 255.0, 0.0, 0.0))
	_tops_texture.update(_tops_image)


## Tells the layer where the camera is (its left edge in camp pixels), so pieces off screen sleep.
func set_view(left: float) -> void:
	_left = left
	_update_sleep()


## Whether anything animated is on screen, and so whether the clock needs to run.
func is_animating() -> bool:
	return _any_animated_in_view()


func _process(delta: float) -> void:
	_clock = fmod(_clock + delta, 3600.0)
	_show_frames()


func _update_sleep() -> void:
	set_process(_any_animated_in_view())


func _any_animated_in_view() -> bool:
	if _sheet == null:
		return false
	if _shown.get(&"fall", false) or _shown.get(&"shimmer", false) or _shown.get(&"clouds", false):
		return true
	var right: float = _left + float(WorldLayout.VIEW_SIZE.x)
	if _shown.get(&"water", false):
		return _overlaps(CAMP_PAGE, right) or _overlaps(EAST_PAGE, right)
	if _shown.get(&"funnel", false):
		return _overlaps(CAMP_PAGE, right)
	return false


func _overlaps(page: Vector2, right: float) -> bool:
	return _left < page.y and right > page.x


func _show_frames() -> void:
	var fall: StringName = WeatherLook.fall(_weather)
	if fall != &"":
		var rows: int = ROW_SNOW if fall == WeatherLook.SNOW else ROW_RAIN
		_set_frame(_fall, &"fall", rows, 3, FALL_SECONDS)
	_set_frame(_shimmer, &"shimmer", ROW_SHIMMER, 2, SHIMMER_SECONDS)
	_set_frame(_flood_camp, &"flood_camp", ROW_FLOOD_CAMP, 2, WATER_SECONDS)
	_set_frame(_flood_east, &"flood_east", ROW_FLOOD_EAST, 2, WATER_SECONDS)
	_set_frame(_funnel, &"funnel", ROW_TORNADO, 3, FUNNEL_SECONDS)
	_set_frame(_clouds, &"clouds", ROW_CLOUDS, 2, CLOUD_SECONDS)


## Puts frame `int(clock / seconds) % count` of the rows starting at `first_row` on a sprite, only
## touching the sprite when the frame changes.
func _set_frame(sprite: Sprite2D, key: StringName, first_row: int, count: int, seconds: float) -> void:
	if not sprite.visible:
		return
	var frame: int = int(_clock / seconds) % count
	var token: int = first_row * 10 + frame
	if _frames.get(key, -1) == token:
		return
	_frames[key] = token
	sprite.texture = _row(first_row + frame)


func _row(row: int) -> Texture2D:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = _sheet
	atlas.region = Rect2(Vector2(0, row * ROW_HEIGHT), Vector2(WorldLayout.VIEW_SIZE))
	return atlas


func _place(sprite: Sprite2D, parent: Node, z: int, at: Vector2) -> void:
	sprite.centered = false
	sprite.z_index = z
	sprite.position = at
	sprite.visible = false
	parent.add_child(sprite)
