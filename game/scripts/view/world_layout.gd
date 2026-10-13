class_name WorldLayout
extends RefCounted
## Where things are in the Cave Age scene, in art pixels (384x80, ground line at y=56). Mirrors
## the slots in tools/art/cave_strip.js: change both together.

const ASSET_DIR: String = "res://assets/world/cave/"
const VILLAGER_DIR: String = "res://assets/world/cave/villagers/"

## What the viewport shows at once: one "page", the camp. Everything below is in camp pixels
## (the camp page's top-left is 0, 0); the world extends one page west and one page east.
const VIEW_SIZE: Vector2i = Vector2i(384, 80)
const WORLD_LEFT: int = -384
const WORLD_RIGHT: int = 768
const WORLD_WIDTH: int = WORLD_RIGHT - WORLD_LEFT
## Pages the world is made of, for the position dots.
const PAGE_COUNT: int = WORLD_WIDTH / 384
## How far an arrow press, and one wheel notch, pan.
const PAN_STEP: float = 288.0
const WHEEL_STEP: float = 48.0
## The pages beside the camp: asset-name prefix -> the camp x of the page's left edge, and the
## static prop layers each has (drawn by tools/art/cave_pages.js).
const SIDE_PAGES: Dictionary = {"west_": -384, "east_": 384}
const SIDE_STATIC: Dictionary = {
	"west_": [&"static_back", &"static_mid"], "east_": [&"static_mid"],
}

## Villager sheet cells are 28x30; the feet are at (14, 28) inside a cell.
const CELL_SIZE: Vector2i = Vector2i(28, 30)
const FOOT_OFFSET: Vector2 = Vector2(-14.0, -28.0)

const BACKDROP: Array[StringName] = [&"sky", &"far_hills", &"near_hills", &"trees", &"ground"]
## Backdrop layers that stay in strip and corner mode; the others only show in the opaque window.
const DESKTOP_BACKDROP: Array[StringName] = [&"near_hills", &"trees", &"ground"]
const STATIC_Z: Dictionary = {&"static_back": 10, &"static_mid": 70}

## State-driven buildings: art slot and draw order (z is the foot row, so villagers walk
## behind or in front correctly).
const BUILDINGS: Dictionary = {
	&"lookout": {"cx": 300, "foot": 66, "z": 66},
	&"drying_rack": {"cx": 132, "foot": 70, "z": 70},
	&"knapping_spot": {"cx": 160, "foot": 79, "z": 78},
	&"hut": {"cx": 268, "foot": 71, "z": 71},
	&"field": {"cx": 228, "foot": 78, "z": 55},
}
const FLOWER_Z: int = 73

const CAVE_DOOR: Vector2 = Vector2(40.0, 78.0)
## Newcomers and returning scouts arrive along the forest path from beyond the west end: the
## east is water.
const WEST_EDGE: Vector2 = Vector2(-394.0, 77.0)
const FIRE_X: float = 72.0
const PINE_X: float = 204.0

const FIRE_SPOTS: Array[Vector2] = [Vector2(88, 78), Vector2(96, 79), Vector2(60, 79)]
const SOCIAL_SPOTS: Array[Vector2] = [Vector2(62, 78), Vector2(84, 79), Vector2(98, 78)]
const WOOD_SPOTS: Array[Vector2] = [Vector2(192, 74), Vector2(214, 75), Vector2(222, 77)]
const FORAGE_SPOTS: Array[Vector2] = [Vector2(188, 77), Vector2(206, 78), Vector2(176, 78)]
## The forest to the west is walkable; the camp's river stops the east at about x = 298.
const WANDER_X: Vector2 = Vector2(-150.0, 290.0)
const WANDER_Y: Vector2 = Vector2(75.0, 79.0)


static func spot(spots: Array[Vector2], index: int) -> Vector2:
	return spots[posmod(index, spots.size())]


## Where a villager stands to work on a building site.
static func build_spot(building_id: StringName, index: int) -> Vector2:
	var slot: Dictionary = BUILDINGS.get(building_id, {})
	var center_x: float = float(slot.get("cx", 150))
	var foot: float = float(slot.get("foot", 70))
	return Vector2(center_x - 10.0 - float(posmod(index, 3)) * 7.0, minf(foot + 3.0, 79.0))
