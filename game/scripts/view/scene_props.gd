class_name SceneProps
extends RefCounted
## Pieces of the world that show because of what the settlement has chosen or earned, not because
## a building of that name stands: the sown plot and the pen the age turn leaves behind, and later
## whatever an answer or a milestone puts on the ground. Pure and headless: the view asks which
## are shown and draws them (docs/ages.md V10).
##
## Each prop is a full-width art piece named like the others; `name` is what hover says (the
## tooltip names the thing and nothing more); `at_x` is the left edge of its
## sprite in camp pixels (-384 is the west page), `z` is its draw order, and `kind` and `key` say
## what the world must hold. Mirrors tools/art/settled_camp.js: change both together. The camp's
## big static pieces (cliff, pine, mammoth) are drawn at z 10, so a prop meant to stand behind them
## (the low wall) uses z 9.

enum Kind {
	## Append new kinds at the end.
	FLAG, ## `key` is a world flag.
	ACHIEVEMENT, ## `key` is an earned achievement.
	BUILDING, ## `key` is a completed building id.
}

const PROPS: Dictionary = {
	&"west_plot_farm": {
		"name": "Sown plot", "at_x": -384.0, "z": 55,
		"kind": Kind.FLAG, "key": &"path_agriculture",
	},
	&"west_plot_patch": {
		"name": "Garden patch", "at_x": -384.0, "z": 55,
		"kind": Kind.FLAG, "key": &"path_herding",
	},
	&"west_pen": {
		"name": "Goat pen", "at_x": -384.0, "z": 77,
		"kind": Kind.FLAG, "key": &"path_herding",
	},
	&"pots": {
		"name": "Clay pots", "at_x": 0.0, "z": 79,
		"kind": Kind.ACHIEVEMENT, "key": &"fired_clay",
	},
	&"cloth_line": {
		"name": "Drying cloth", "at_x": 0.0, "z": 67,
		"kind": Kind.ACHIEVEMENT, "key": &"woven_cloth",
	},
	&"cloth_dyed": {
		"name": "Dyed cloth", "at_x": 0.0, "z": 68,
		"kind": Kind.FLAG, "key": &"dyed_cloth",
	},
	&"loom": {
		"name": "Loom", "at_x": 0.0, "z": 77,
		"kind": Kind.FLAG, "key": &"loom",
	},
	&"low_wall": {
		"name": "Low wall", "at_x": 0.0, "z": 9,
		"kind": Kind.FLAG, "key": &"low_wall",
	},
	&"green_stones": {
		"name": "Green stones", "at_x": 0.0, "z": 79,
		"kind": Kind.FLAG, "key": &"green_stone",
	},
	&"hens": {
		"name": "Hens", "at_x": 0.0, "z": 79,
		"kind": Kind.FLAG, "key": &"hens",
	},
	&"west_kiln": {
		"name": "Kiln", "at_x": -384.0, "z": 78,
		"kind": Kind.FLAG, "key": &"kiln",
	},
	&"west_well": {
		"name": "Well", "at_x": -384.0, "z": 77,
		"kind": Kind.FLAG, "key": &"well_dug",
	},
	&"west_scarecrow": {
		"name": "Scarecrow", "at_x": -384.0, "z": 76,
		"kind": Kind.FLAG, "key": &"scarecrow",
	},
	&"west_roof_a": {
		"name": "Village roof", "at_x": -384.0, "z": 72,
		"kind": Kind.ACHIEVEMENT, "key": &"a_village",
	},
	&"west_roof_b": {
		"name": "Village roof", "at_x": -384.0, "z": 71,
		"kind": Kind.ACHIEVEMENT, "key": &"a_village",
	},
	# The river (docs/ages.md V13): the crossing runs over the camp page and the east page, so it
	# is two pieces; the rest sits on the near bank and in the shallows (camp page), or on the
	# flats (east page). Mirrors tools/art/cave_river.js and settled_camp.js.
	&"crossing_stones": {
		"name": "Stepping stones", "at_x": 0.0, "z": 70,
		"kind": Kind.FLAG, "key": &"stepping_stones",
	},
	&"east_crossing_stones": {
		"name": "Stepping stones", "at_x": 384.0, "z": 70,
		"kind": Kind.FLAG, "key": &"stepping_stones",
	},
	&"crossing_log": {
		"name": "Log bridge", "at_x": 0.0, "z": 70,
		"kind": Kind.FLAG, "key": &"log_bridge",
	},
	&"east_crossing_log": {
		"name": "Log bridge", "at_x": 384.0, "z": 70,
		"kind": Kind.FLAG, "key": &"log_bridge",
	},
	&"river_trap": {
		"name": "Willow fish trap", "at_x": 0.0, "z": 72,
		"kind": Kind.FLAG, "key": &"fish_trap",
	},
	&"reed_bundles": {
		"name": "Reed bundles", "at_x": 0.0, "z": 74,
		"kind": Kind.FLAG, "key": &"reed_beds",
	},
	&"clay_pits": {
		"name": "Clay pits", "at_x": 0.0, "z": 67,
		"kind": Kind.ACHIEVEMENT, "key": &"fired_clay",
	},
	&"flax_thread": {
		"name": "Flax soaking", "at_x": 0.0, "z": 72,
		"kind": Kind.FLAG, "key": &"flax_thread",
	},
	&"flax_beaten": {
		"name": "Beaten flax", "at_x": 0.0, "z": 78,
		"kind": Kind.FLAG, "key": &"flax_beaten",
	},
	&"river_bank": {
		"name": "Flood bank", "at_x": 0.0, "z": 60,
		"kind": Kind.FLAG, "key": &"river_bank",
	},
	&"boat_dugout": {
		"name": "Dugout canoe", "at_x": 0.0, "z": 71,
		"kind": Kind.FLAG, "key": &"dugout_canoe",
	},
	&"boat_raft": {
		"name": "Reed raft", "at_x": 0.0, "z": 71,
		"kind": Kind.FLAG, "key": &"reed_raft",
	},
	&"east_tide_weir": {
		"name": "Stone weir", "at_x": 384.0, "z": 77,
		"kind": Kind.FLAG, "key": &"tide_weir",
	},
}


static func ids() -> Array[StringName]:
	var found: Array[StringName] = []
	for id: StringName in PROPS:
		found.append(id)
	return found


static func z_of(id: StringName) -> int:
	return int(PROPS[id]["z"])


static func at_x_of(id: StringName) -> float:
	return float(PROPS[id]["at_x"])


## What the player sees on hover; every prop must have one (a test enforces it).
static func name_of(id: StringName) -> String:
	if not PROPS.has(id):
		return ""
	return String(PROPS[id].get("name", ""))


static func is_shown(id: StringName, world: WorldState) -> bool:
	if not PROPS.has(id):
		return false
	return holds(PROPS[id]["kind"], PROPS[id]["key"], world)


## Whether the world holds what a prop of this `kind` and `key` waits for.
static func holds(kind: Kind, key: StringName, world: WorldState) -> bool:
	match kind:
		Kind.FLAG:
			return world.has_flag(key)
		Kind.ACHIEVEMENT:
			return world.has_achievement(key)
		Kind.BUILDING:
			return world.has_building(key)
	return false


## Every prop the world currently shows.
static func shown(world: WorldState) -> Array[StringName]:
	var found: Array[StringName] = []
	for id: StringName in PROPS:
		if is_shown(id, world):
			found.append(id)
	return found
