class_name StripIcons
extends Control
## The icons floating at the top right of the viewport, left to right: the idea bulb (only while
## a decision waits, with a count when several do), the journal book and the menu gear. The
## bulb comes and goes at the left end, so the book and gear never move. They stay put while
## the world scrolls. Everything here is in viewport art pixels.

signal bulb_pressed
signal journal_pressed
signal menu_pressed

const SHEET_PATH: String = "res://assets/ui/icons.png"
const BULB_FRAME: Vector2i = Vector2i(18, 20)
const JOURNAL_REGION: Rect2i = Rect2i(36, 0, 16, 20)
const GEAR_REGION: Rect2i = Rect2i(52, 0, 16, 20)
const BULB_POSITION: Vector2 = Vector2(331.0, 3.0)
const JOURNAL_POSITION: Vector2 = Vector2(349.0, 3.0)
const GEAR_POSITION: Vector2 = Vector2(366.0, 3.0)
const GEAR_QUIET: Color = Color(1.0, 1.0, 1.0, 0.7)
const BLINK_SECONDS: float = 0.5

var _sheet: Texture2D
var _bulb: TextureButton = TextureButton.new()
var _journal: TextureButton = TextureButton.new()
var _gear: TextureButton = TextureButton.new()
var _badge: Label = Label.new()
var _time: float = 0.0
var _frames: Array[AtlasTexture] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(WorldLayout.VIEW_SIZE)
	_sheet = load(SHEET_PATH) as Texture2D
	for frame: int in 2:
		_frames.append(_atlas(Rect2i(Vector2i(frame * BULB_FRAME.x, 0), BULB_FRAME)))
	_bulb.texture_normal = _frames[0]
	_bulb.position = BULB_POSITION
	_bulb.visible = false
	_bulb.pressed.connect(func() -> void: bulb_pressed.emit())
	_badge.add_theme_font_size_override("font_size", 7)
	_badge.add_theme_color_override("font_color", UiTheme.PAPER_LIGHT)
	_badge.add_theme_color_override("font_outline_color", UiTheme.INK)
	_badge.add_theme_constant_override("outline_size", 3)
	_badge.position = Vector2(8.0, 10.0)
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bulb.add_child(_badge)
	_journal.texture_normal = _atlas(JOURNAL_REGION)
	_journal.position = JOURNAL_POSITION
	_journal.pressed.connect(func() -> void: journal_pressed.emit())
	add_child(_journal)
	_gear.texture_normal = _atlas(GEAR_REGION)
	_gear.position = GEAR_POSITION
	_gear.self_modulate = GEAR_QUIET
	_gear.mouse_entered.connect(func() -> void: _gear.self_modulate = Color.WHITE)
	_gear.mouse_exited.connect(func() -> void: _gear.self_modulate = GEAR_QUIET)
	_gear.pressed.connect(func() -> void: menu_pressed.emit())
	add_child(_gear)
	add_child(_bulb)


## `waiting` is how many decisions are pending.
func update_pending(waiting: int) -> void:
	_bulb.visible = waiting > 0
	_badge.text = str(waiting) if waiting > 1 else ""


func has_bulb() -> bool:
	return _bulb.visible


## The count shown on the bulb ("" for a single decision).
func badge_text() -> String:
	return _badge.text


## The areas that must stay clickable in strip mode, in viewport art pixels.
func clickable_regions() -> Array[Rect2i]:
	var regions: Array[Rect2i] = [
		Rect2i(Vector2i(_journal.position), JOURNAL_REGION.size),
		Rect2i(Vector2i(_gear.position), GEAR_REGION.size),
	]
	if _bulb.visible:
		regions.append(Rect2i(Vector2i(_bulb.position), BULB_FRAME))
	return regions


func _process(delta: float) -> void:
	if not _bulb.visible:
		return
	_time += delta
	_bulb.texture_normal = _frames[int(_time / BLINK_SECONDS) % 2]
	_bulb.position.y = BULB_POSITION.y + (1.0 if fmod(_time, 1.4) > 0.7 else 0.0)


func _atlas(region: Rect2i) -> AtlasTexture:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = _sheet
	atlas.region = Rect2(region)
	return atlas
