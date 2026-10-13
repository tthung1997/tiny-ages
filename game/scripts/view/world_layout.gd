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
## The stump at the forest's edge (west page), where wood is cut.
const CHOP_X: float = -66.0
## The fire pit is state-driven like a building: it appears once the fire is found. It is drawn
## with the firelight inside the cave mouth (tools/art/cave_strip.js), in FIRE_FRAMES flame frames
## named fire_pit_0.. that swap every FIRE_FRAME_SECONDS while it is in view.
const FIRE_PIT: StringName = &"fire_pit"
const FIRE_PIT_Z: int = 70
const FIRE_FRAMES: int = 4
const FIRE_FRAME_SECONDS: float = 0.2
## How bright the glow is on each flame frame, so it breathes with the fire.
const FIRE_GLOW_FLICKER: Array[float] = [1.0, 0.9, 0.96, 0.84]
## The camp x range the fire lights; the animation sleeps while none of it is on screen.
const FIRE_LIGHT_X: Vector2 = Vector2(20.0, 120.0)
## The fire's glow is drawn over everything in the world (villagers included) but under the HUD.
const FIRE_GLOW: StringName = &"fire_glow"
const FIRE_GLOW_Z: int = 90
## The sky bodies: stars, then a sheet of the sun (cell 0) and the moon (cell 1). They sit in front
## of the sky and behind the far hills (z -100 and -99), and do not scroll with the world.
const STARS: StringName = &"stars"
const CELESTIAL: StringName = &"celestial"
const CELESTIAL_CELL: Vector2i = Vector2i(16, 16)
const SKY_Z: int = -100

## Where the group gathers while there is no fire: the cave mouth.
const COLD_X: float = 40.0
const COLD_SPOTS: Array[Vector2] = [Vector2(32, 78), Vector2(46, 79), Vector2(56, 78)]
## Hunters go to the far end of the west forest, beyond where anyone wanders, and stand watch
## facing further west.
const HUNT_X: float = -400.0
const HUNT_SPOTS: Array[Vector2] = [Vector2(-318, 77), Vector2(-296, 79), Vector2(-338, 78)]
const FIRE_SPOTS: Array[Vector2] = [Vector2(88, 78), Vector2(96, 79), Vector2(60, 79)]
const SOCIAL_SPOTS: Array[Vector2] = [Vector2(62, 78), Vector2(84, 79), Vector2(98, 78)]
const WOOD_SPOTS: Array[Vector2] = [Vector2(-82, 78), Vector2(-74, 79), Vector2(-54, 78)]
const FORAGE_SPOTS: Array[Vector2] = [Vector2(188, 77), Vector2(206, 78), Vector2(176, 78)]
## The forest to the west is walkable; the camp's river stops the east at about x = 298.
const WANDER_X: Vector2 = Vector2(-150.0, 290.0)
const WANDER_Y: Vector2 = Vector2(75.0, 79.0)


static func fire_frame_name(frame: int) -> StringName:
	return StringName("%s_%d" % [FIRE_PIT, posmod(frame, FIRE_FRAMES)])


static func spot(spots: Array[Vector2], index: int) -> Vector2:
	return spots[posmod(index, spots.size())]


## Where a villager stands to work on a building site.
static func build_spot(building_id: StringName, index: int) -> Vector2:
	var slot: Dictionary = BUILDINGS.get(building_id, {})
	var center_x: float = float(slot.get("cx", 150))
	var foot: float = float(slot.get("foot", 70))
	return Vector2(center_x - 10.0 - float(posmod(index, 3)) * 7.0, minf(foot + 3.0, 79.0))
