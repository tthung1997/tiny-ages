class_name DesktopWindow
extends Node
## Applies Screenhaven's desktop display modes to the main window: a borderless
## transparent strip along the bottom of a screen, a corner window, or a normal window.
##
## The art's alpha silhouette doubles as the clickable region, so clicks on transparent
## pixels fall through to whatever application is underneath.

signal layout_changed(content_size: Vector2i)

enum Mode { STRIP, CORNER, WINDOW }

const ART_SIZE: Vector2i = Vector2i(384, 80)
const MIN_SCALE: int = 1
const MAX_SCALE: int = 4
const FPS_CAPS: Array[int] = [0, 60, 30, 15, 5]
const ALPHA_CLICKABLE: float = 0.5

## Textures whose non-transparent pixels are clickable and visible in strip/corner mode (alpha
## above ALPHA_CLICKABLE). Empty keeps the whole window clickable.
@export var silhouettes: Array[Texture2D] = []

## Extra clickable area in art pixels (for example a HUD). The passthrough polygon also clips
## drawing on Windows, so anything that must be visible has to sit inside it.
var extra_clickable: Rect2i = Rect2i()

var mode: Mode = Mode.STRIP
var pixel_scale: int = 2
var always_on_top: bool = true
var click_through: bool = true
var fps_cap: int = 30
var low_processor: bool = true

var _skyline: PackedInt32Array = PackedInt32Array()
var _content_size: Vector2i = ART_SIZE
var _apply_serial: int = 0


func _ready() -> void:
	_build_skyline()


## Logical (art) pixels between the left edge of the window and the art.
func art_origin() -> Vector2i:
	return Vector2i((_content_size.x - ART_SIZE.x) / 2, 0)


func content_size() -> Vector2i:
	return _content_size


func apply() -> void:
	_apply_serial += 1
	var serial: int = _apply_serial
	var window: Window = get_window()
	var floating: bool = mode != Mode.WINDOW
	window.mode = Window.MODE_WINDOWED
	window.borderless = floating
	window.transparent = floating
	window.unresizable = floating
	window.always_on_top = always_on_top
	get_viewport().transparent_bg = floating
	Engine.max_fps = fps_cap
	OS.low_processor_usage_mode = low_processor
	_place_window()
	# Flag changes are applied asynchronously on some platforms, so settle geometry again.
	await get_tree().process_frame
	if serial != _apply_serial or not is_inside_tree():
		return
	_place_window()
	_update_click_through()


func set_mode(value: Mode) -> void:
	mode = value
	apply()


func set_pixel_scale(value: int) -> void:
	pixel_scale = clampi(value, MIN_SCALE, MAX_SCALE)
	apply()


func set_always_on_top(value: bool) -> void:
	always_on_top = value
	get_window().always_on_top = value


func set_click_through(value: bool) -> void:
	click_through = value
	_update_click_through()


func set_extra_clickable(rect: Rect2i) -> void:
	extra_clickable = rect
	_update_click_through()


## Replaces the textures whose opaque pixels are clickable (and visible in strip mode).
func set_silhouettes(textures: Array[Texture2D]) -> void:
	silhouettes = textures
	_build_skyline()
	_update_click_through()


func set_low_processor(value: bool) -> void:
	low_processor = value
	OS.low_processor_usage_mode = value


func cycle_fps_cap() -> void:
	var index: int = FPS_CAPS.find(fps_cap)
	fps_cap = FPS_CAPS[(index + 1) % FPS_CAPS.size()]
	Engine.max_fps = fps_cap


func move_to_next_screen() -> void:
	var window: Window = get_window()
	window.current_screen = (window.current_screen + 1) % DisplayServer.get_screen_count()
	apply()


func _place_window() -> void:
	var window: Window = get_window()
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(window.current_screen)
	var window_size: Vector2i = ART_SIZE * pixel_scale
	var content: Vector2i = ART_SIZE
	var window_pos: Vector2i = usable.position
	match mode:
		Mode.STRIP:
			window_size = Vector2i(usable.size.x, ART_SIZE.y * pixel_scale)
			content = Vector2i(window_size.x / pixel_scale, ART_SIZE.y)
			window_pos = Vector2i(usable.position.x, usable.end.y - window_size.y)
		Mode.CORNER:
			window_pos = usable.end - window_size
		Mode.WINDOW:
			window_pos = usable.position + (usable.size - window_size) / 2
	_content_size = content
	window.content_scale_size = content
	window.size = window_size
	window.position = window_pos
	layout_changed.emit(content)


func _build_skyline() -> void:
	_skyline = PackedInt32Array()
	if silhouettes.is_empty():
		return
	_skyline.resize(ART_SIZE.x)
	_skyline.fill(ART_SIZE.y)
	for texture: Texture2D in silhouettes:
		if texture == null:
			continue
		var image: Image = texture.get_image()
		if image == null:
			push_warning("DesktopWindow: a silhouette has no image data; ignoring it.")
			continue
		for x: int in mini(image.get_width(), ART_SIZE.x):
			for y: int in _skyline[x]:
				if image.get_pixel(x, y).a > ALPHA_CLICKABLE:
					_skyline[x] = y
					break


## Mouse passthrough accepts one polygon, so the clickable area is the art's skyline:
## everything at or below the highest opaque pixel of each column.
func _update_click_through() -> void:
	if not click_through or mode == Mode.WINDOW or _skyline.is_empty():
		DisplayServer.window_set_mouse_passthrough(PackedVector2Array())
		return
	var origin: Vector2i = art_origin() * pixel_scale
	var region: PackedVector2Array = PackedVector2Array()
	var count: int = _skyline.size()
	var run_start: int = 0
	for x: int in range(1, count + 1):
		if x < count and _top_at(x) == _top_at(run_start):
			continue
		var top_y: float = origin.y + _top_at(run_start) * pixel_scale
		region.append(Vector2(origin.x + run_start * pixel_scale, top_y))
		region.append(Vector2(origin.x + x * pixel_scale, top_y))
		run_start = x
	var bottom: float = origin.y + ART_SIZE.y * pixel_scale
	region.append(Vector2(origin.x + count * pixel_scale, bottom))
	region.append(Vector2(origin.x, bottom))
	DisplayServer.window_set_mouse_passthrough(region)


func _top_at(x: int) -> int:
	var top: int = _skyline[x]
	if extra_clickable.has_area() and x >= extra_clickable.position.x \
			and x < extra_clickable.end.x:
		top = mini(top, extra_clickable.position.y)
	return top
