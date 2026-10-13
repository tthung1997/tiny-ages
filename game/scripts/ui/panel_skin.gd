class_name PanelSkin
extends RefCounted
## How the panels look in one age: the material (a hide in the Cave Age, later clay, papyrus...),
## its colours and font, and where each piece sits in the age's atlas. Art comes from the
## tools/art/ui_skin_<age>.js script, so adding an age's skin is: draw the atlas, add a factory
## here and register it in `skins()`. Unknown ages fall back to the Cave skin.

const ASSET_DIR: String = "res://assets/ui/"
const FONT_PATH: String = "res://assets/fonts/PixelifySans.ttf"
const FONT_SIZE: int = 12
## Tighter than the font's own line spacing, which is airy at this size.
const LINE_SPACING: int = -4
## The panel's art height, and the y of the row of small pieces under it in the atlas.
const PANEL_HEIGHT: int = 160
const ITEM_ROW: int = PANEL_HEIGHT + 4
## The OpenType tag of the weight axis ("wght") and the weight used for titles.
const WEIGHT_TAG: int = 0x77676874
const TITLE_WEIGHT: int = 700
## Corner size of the stitched button 9-patch.
const BUTTON_MARGIN: int = 4

var era_id: StringName = &""
var atlas_path: String = ""
var ink: Color = Color("2b2d42")
var muted: Color = Color("5a4630")
var title_color: Color = Color("7d3e22")
var day_color: Color = Color("8a4a2a")
var button_text: Color = Color("2b2d42")
var button_text_disabled: Color = Color("6a5a40")
var scroll_track: Color = Color("b48c58")
var scroll_grabber: Color = Color("6a4326")
## Padding between the panel's art edge and its content (left, top, right, bottom).
var content_margins: Rect2 = Rect2(14, 11, 14, 10)
var panel_region: Rect2 = Rect2(0, 0, 384, PANEL_HEIGHT)
var button_regions: Dictionary = {}
var close_regions: Dictionary = {}
var icon_regions: Dictionary = {}

var _atlas: Texture2D
var _font: Font
var _title_font: Font


## The registered factories: era id -> Callable returning a PanelSkin.
static func skins() -> Dictionary:
	return {&"cave": cave}


static func for_era(era: StringName) -> PanelSkin:
	var factories: Dictionary = skins()
	if factories.has(era):
		return (factories[era] as Callable).call()
	return cave()


static func cave() -> PanelSkin:
	var skin: PanelSkin = PanelSkin.new()
	skin.era_id = &"cave"
	skin.atlas_path = ASSET_DIR + "skin_hide.png"
	skin.button_regions = {
		&"normal": Rect2(0, ITEM_ROW, 16, 16), &"hover": Rect2(16, ITEM_ROW, 16, 16),
		&"pressed": Rect2(32, ITEM_ROW, 16, 16), &"disabled": Rect2(48, ITEM_ROW, 16, 16),
	}
	skin.close_regions = {
		&"normal": Rect2(64, ITEM_ROW, 14, 14), &"hover": Rect2(78, ITEM_ROW, 14, 14),
	}
	skin.icon_regions = {
		&"wood": Rect2(96, ITEM_ROW, 10, 10), &"food": Rect2(106, ITEM_ROW, 10, 10),
	}
	return skin


func atlas() -> Texture2D:
	if _atlas == null:
		_atlas = load(atlas_path) as Texture2D
	return _atlas


## A piece of the atlas as a texture.
func piece(region: Rect2) -> AtlasTexture:
	var texture: AtlasTexture = AtlasTexture.new()
	texture.atlas = atlas()
	texture.region = region
	return texture


## The icon for a resource or item, or null if the skin has none (the panel then writes its name).
func icon_for(key: StringName) -> Texture2D:
	if not icon_regions.has(key):
		return null
	return piece(icon_regions[key])


func font() -> Font:
	if _font == null:
		_font = _load_font()
	return _font


## The same face in bold, for titles.
func title_font() -> Font:
	if _title_font == null:
		var bold: FontVariation = FontVariation.new()
		bold.base_font = font()
		bold.variation_opentype = {WEIGHT_TAG: TITLE_WEIGHT}
		_title_font = bold
	return _title_font


func _load_font() -> Font:
	var face: FontFile = load(FONT_PATH) as FontFile
	if face == null:
		return ThemeDB.fallback_font
	# Crisp pixel text: no smoothing, no sub-pixel placement.
	face.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	face.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	face.hinting = TextServer.HINTING_NONE
	return face
