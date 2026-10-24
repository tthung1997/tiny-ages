class_name SceneProps
extends RefCounted
## Pieces of the world that show because of what the settlement has chosen or earned, not because
## a building of that name stands: the sown plot and the pen the age turn leaves behind, and later
## whatever an answer or a milestone puts on the ground. Pure and headless: the view asks which
## are shown and draws them (docs/ages.md V10, B10).
##
## Each prop is a full-width art piece named like the others; `name` is what hover says (the
## tooltip names the thing and nothing more); `at_x` is the left edge of its
## sprite in camp pixels (-384 is the west page), `z` is its draw order, and `kind` and `key` say
## what the world must hold. Mirrors tools/art/settled_camp.js: change both together. The camp's
## big static pieces (cliff, pine, mammoth) are drawn at z 10, so a prop meant to stand behind them
## uses a lower z.
##
## Keeping the world tidy (docs/ages.md B10). A prop belongs to a `place` (`WorldLayout.PLACES`: a
## yard, the river bank, the west village), and its art must sit inside it. Three optional fields:
## `alt_of` (an alternative to another prop, which is never shown with it, so they may share
## ground), `overlays` (drawn on top of another prop on purpose), `behind` (a backdrop that stands
## behind the others, a wall, so they may cover it) and, so an age can simplify what
## the last one built, `replaced_by` (hidden while that prop is shown), `from_era` (shown only from
## that era order on) and `until_era` (hidden once the world's era order reaches it).
## `test_scene_props.gd` checks every one of them. `at_y` is how far the sprite is lifted onto its
## lane (see `WorldLayout.BUILDINGS`), and the art's own rows are shifted with it.

enum Kind {
	## Append new kinds at the end.
	FLAG, ## `key` is a world flag.
	ACHIEVEMENT, ## `key` is an earned achievement.
	BUILDING, ## `key` is a completed building id.
}

const PROPS: Dictionary = {
	# The village at the forest's edge (west page): the Settled Age's houses, plot, pen, kiln, well
	# and the crafts around them.
	&"west_plot_farm": {
		"name": "Sown plot", "at_x": -384.0, "at_y": -4, "z": 55, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"path_agriculture", "replaced_by": &"farmstead_farm",
	},
	&"west_plot_patch": {
		"name": "Garden patch", "at_x": -384.0, "at_y": -4, "z": 55, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"path_herding", "alt_of": &"west_plot_farm",
		"replaced_by": &"farmstead_herd",
	},
	&"west_pen": {
		"name": "Goat pen", "at_x": -384.0, "at_y": -10, "z": 67, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"path_herding", "replaced_by": &"farmstead_herd",
	},
	# The clay pots stand in front of the cave mouth, where the fire is: the art was drawn in the
	# west village, so the sprite sits 166 px to the east of its page.
	&"pots": {
		"name": "Clay pots", "at_x": -166.0, "at_y": -5, "z": 74, "place": &"cave_mouth",
		"kind": Kind.ACHIEVEMENT, "key": &"fired_clay", "replaced_by": &"potters_yard",
	},
	&"cloth_line": {
		"name": "Drying cloth", "at_x": -384.0, "at_y": -5, "z": 70, "place": &"west_village",
		"kind": Kind.ACHIEVEMENT, "key": &"woven_cloth", "replaced_by": &"weavers_row",
	},
	&"cloth_dyed": {
		"name": "Dyed cloth", "at_x": -384.0, "at_y": -5, "z": 71, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"dyed_cloth", "overlays": &"cloth_line",
		"replaced_by": &"weavers_row_dyed",
	},
	&"loom": {
		"name": "Loom", "at_x": -384.0, "at_y": -5, "z": 74, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"loom", "replaced_by": &"weavers_row",
	},
	# The wall runs along the back lane behind the village, from the forest's edge to the cave's
	# flank (`tools/art/settled_camp.js`), so it joins two things.
	&"low_wall": {
		"name": "Low wall", "at_x": -384.0, "z": 63, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"low_wall", "behind": true, "replaced_by": &"town_wall",
	},
	&"hens": {
		"name": "Hens", "at_x": -384.0, "at_y": -5, "z": 74, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"hens", "replaced_by": &"farmstead_farm",
	},
	&"west_kiln": {
		"name": "Kiln", "at_x": -384.0, "at_y": -12, "z": 67, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"kiln", "replaced_by": &"potters_yard",
	},
	&"west_well": {
		"name": "Well", "at_x": -384.0, "at_y": -5, "z": 74, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"well_dug",
	},
	&"west_scarecrow": {
		"name": "Scarecrow", "at_x": -384.0, "at_y": -4, "z": 73, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"scarecrow", "overlays": &"west_plot_farm",
		"replaced_by": &"farmstead_farm",
	},
	&"west_roof_a": {
		"name": "Village roof", "at_x": -384.0, "at_y": -6, "z": 67, "place": &"west_village",
		"kind": Kind.ACHIEVEMENT, "key": &"a_village",
	},
	&"west_roof_b": {
		"name": "Village roof", "at_x": -384.0, "at_y": -5, "z": 67, "place": &"west_village",
		"kind": Kind.ACHIEVEMENT, "key": &"a_village",
	},
	# The Bronze Age tidies what the Settled Age scattered: one piece for each yard, and a town
	# wall for the low one (docs/ages.md B10). Each hides the pieces it replaces.
	&"potters_yard": {
		"name": "Potter's yard", "at_x": -384.0, "at_y": -12, "z": 67, "place": &"west_village",
		"kind": Kind.ACHIEVEMENT, "key": &"fired_clay", "from_era": 2,
	},
	&"weavers_row": {
		"name": "Weaver's row", "at_x": -384.0, "at_y": -12, "z": 67, "place": &"west_village",
		"kind": Kind.ACHIEVEMENT, "key": &"woven_cloth", "from_era": 2,
	},
	&"weavers_row_dyed": {
		"name": "Dyed cloth", "at_x": -384.0, "at_y": -12, "z": 68, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"dyed_cloth", "from_era": 2, "overlays": &"weavers_row",
	},
	&"town_wall": {
		"name": "Town wall", "at_x": -384.0, "z": 63, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"town_wall", "behind": true, "from_era": 2,
	},
	&"flax_beaten": {
		"name": "Beaten flax", "at_x": -384.0, "at_y": -5, "z": 74, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"flax_beaten", "alt_of": &"flax_thread",
		"replaced_by": &"weavers_row",
	},
	# The yard in front of the cave, beside the knapping spot.
	&"green_stones": {
		"name": "Green stones", "at_x": 0.0, "at_y": -4, "z": 75, "place": &"cave_yard",
		"kind": Kind.FLAG, "key": &"green_stone", "until_era": 2,
	},
	&"clay_pits": {
		"name": "Clay pits", "at_x": 0.0, "at_y": -4, "z": 74, "place": &"cave_yard",
		"kind": Kind.ACHIEVEMENT, "key": &"fired_clay", "replaced_by": &"potters_yard",
	},
	# The river (docs/ages.md V13): the crossing runs over the camp page and the east page, so it
	# is two pieces; the rest sits on the near bank and in the shallows (camp page), or on the
	# flats (east page). Mirrors tools/art/cave_river.js and settled_camp.js.
	&"crossing_stones": {
		"name": "Stepping stones", "at_x": 0.0, "z": 70, "place": &"river_bank",
		"kind": Kind.FLAG, "key": &"stepping_stones", "replaced_by": &"crossing_planks",
	},
	&"east_crossing_stones": {
		"name": "Stepping stones", "at_x": 384.0, "z": 70, "place": &"east_shore",
		"kind": Kind.FLAG, "key": &"stepping_stones", "replaced_by": &"east_crossing_planks",
	},
	&"crossing_log": {
		"name": "Log bridge", "at_x": 0.0, "z": 70, "place": &"river_bank",
		"kind": Kind.FLAG, "key": &"log_bridge", "alt_of": &"crossing_stones",
		"replaced_by": &"crossing_planks",
	},
	&"east_crossing_log": {
		"name": "Log bridge", "at_x": 384.0, "z": 70, "place": &"east_shore",
		"kind": Kind.FLAG, "key": &"log_bridge", "alt_of": &"east_crossing_stones",
		"replaced_by": &"east_crossing_planks",
	},
	&"river_trap": {
		"name": "Willow fish trap", "at_x": 0.0, "z": 72, "place": &"river_bank",
		"kind": Kind.FLAG, "key": &"fish_trap", "replaced_by": &"quay_boats",
	},
	&"reed_bundles": {
		"name": "Reed bundles", "at_x": 0.0, "z": 74, "place": &"river_bank",
		"kind": Kind.FLAG, "key": &"reed_beds",
	},
	&"flax_thread": {
		"name": "Flax soaking", "at_x": 0.0, "z": 72, "place": &"river_bank",
		"kind": Kind.FLAG, "key": &"flax_thread", "replaced_by": &"quay_boats",
	},
	&"river_bank": {
		"name": "Flood bank", "at_x": 0.0, "z": 60, "place": &"river_bank",
		"kind": Kind.FLAG, "key": &"river_bank", "behind": true,
	},
	&"boat_dugout": {
		"name": "Dugout canoe", "at_x": 0.0, "z": 71, "place": &"river_bank",
		"kind": Kind.FLAG, "key": &"dugout_canoe", "replaced_by": &"quay_boats",
	},
	&"boat_raft": {
		"name": "Reed raft", "at_x": 0.0, "z": 71, "place": &"river_bank",
		"kind": Kind.FLAG, "key": &"reed_raft", "alt_of": &"boat_dugout", "replaced_by": &"quay_boats",
	},
	&"east_tide_weir": {
		"name": "Stone weir", "at_x": 384.0, "z": 77, "place": &"east_shore",
		"kind": Kind.FLAG, "key": &"tide_weir",
	},
	# The coast's work, on the spit (the east page was the emptiest): what the group does with the
	# sea once it has had it, each shown by the flag that says it was done.
	&"east_salt_pans": {
		"name": "Salt pans", "at_x": 384.0, "z": 74, "place": &"east_shore",
		"kind": Kind.FLAG, "key": &"salt",
	},
	&"east_shell_heap": {
		"name": "Shell heap", "at_x": 384.0, "z": 76, "place": &"east_shore",
		"kind": Kind.FLAG, "key": &"shellfish_gathered",
	},
	&"east_driftwood_stack": {
		"name": "Driftwood stack", "at_x": 384.0, "z": 74, "place": &"east_shore",
		"kind": Kind.FLAG, "key": &"driftwood_gathered",
	},
	&"east_tide_baskets": {
		"name": "Tide baskets", "at_x": 384.0, "z": 76, "place": &"east_shore",
		"kind": Kind.FLAG, "key": &"tide_baskets",
	},
	&"east_sail": {
		"name": "Trading ship", "at_x": 384.0, "z": 60, "place": &"east_shore",
		"kind": Kind.FLAG, "key": &"far_shore",
	},
	# What the Bronze Age's roads put on the ground (docs/ages.md): a market, a cart, donkeys, a
	# hard road, and the boats tied up at the quay in place of the ones afloat in the shallows.
	&"crossing_planks": {
		"name": "Plank bridge", "at_x": 0.0, "z": 70, "place": &"river_bank",
		"kind": Kind.FLAG, "key": &"road_laid", "from_era": 2,
	},
	&"east_crossing_planks": {
		"name": "Plank bridge", "at_x": 384.0, "z": 70, "place": &"east_shore",
		"kind": Kind.FLAG, "key": &"road_laid", "from_era": 2,
	},
	&"market_stalls": {
		"name": "Market stalls", "at_x": -384.0, "at_y": -3, "z": 67, "place": &"west_market",
		"kind": Kind.FLAG, "key": &"market_day", "from_era": 2,
	},
	# The other two roads to a town share the market's spot: only one was ever taken.
	&"council_ring": {
		"name": "Council ring", "at_x": -384.0, "at_y": -3, "z": 67, "place": &"west_market",
		"kind": Kind.FLAG, "key": &"council", "from_era": 2, "alt_of": &"market_stalls",
	},
	&"tally_post": {
		"name": "Tally post", "at_x": -384.0, "at_y": -3, "z": 67, "place": &"west_market",
		"kind": Kind.FLAG, "key": &"tally", "from_era": 2, "alt_of": &"market_stalls",
	},
	# One tidy farmstead for each way of life (the plot, scarecrow and hens; the patch and the pen).
	&"farmstead_farm": {
		"name": "Farmstead", "at_x": -384.0, "at_y": -12, "z": 67, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"path_agriculture", "from_era": 2,
	},
	&"farmstead_herd": {
		"name": "Sheepfold", "at_x": -384.0, "at_y": -12, "z": 67, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"path_herding", "from_era": 2,
	},
	&"cart": {
		"name": "Cart", "at_x": -384.0, "at_y": -2, "z": 77, "place": &"west_market",
		"kind": Kind.FLAG, "key": &"cart", "from_era": 2,
	},
	&"donkeys": {
		"name": "Donkeys", "at_x": -384.0, "at_y": -2, "z": 77, "place": &"west_market",
		"kind": Kind.FLAG, "key": &"donkeys", "from_era": 2,
	},
	&"road_camp": {
		"name": "Road", "at_x": 0.0, "z": 54, "place": &"cave_yard",
		"kind": Kind.FLAG, "key": &"road_laid", "from_era": 2, "behind": true,
	},
	&"quay_boats": {
		"name": "Boats at the quay", "at_x": 0.0, "z": 73, "place": &"river_bank",
		"kind": Kind.BUILDING, "key": &"quay", "from_era": 2,
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


## How far a prop's sprite is lifted onto its lane (negative is up; the art keeps its rows, and the
## sprite moves). 0 for a piece drawn where it stands.
static func at_y_of(id: StringName) -> float:
	return float(PROPS[id].get("at_y", 0))


## The place a prop belongs to (`WorldLayout.PLACES`), or "" for an unknown prop.
static func place_of(id: StringName) -> StringName:
	if not PROPS.has(id):
		return &""
	return PROPS[id].get("place", &"")


## What the player sees on hover; every prop must have one (a test enforces it).
static func name_of(id: StringName) -> String:
	if not PROPS.has(id):
		return ""
	return String(PROPS[id].get("name", ""))


## Whether the world shows a prop: it holds what the prop waits for, the age has not outgrown it
## (`until_era`), and nothing that replaces it is shown (`replaced_by`).
static func is_shown(id: StringName, world: WorldState) -> bool:
	return is_shown_in(PROPS, id, world)


## `is_shown` over any table of props (so the rules can be tested without a real one).
static func is_shown_in(props: Dictionary, id: StringName, world: WorldState) -> bool:
	if not props.has(id):
		return false
	var prop: Dictionary = props[id]
	if prop.has("from_era") and world.era_order < int(prop["from_era"]):
		return false
	if prop.has("until_era") and world.era_order >= int(prop["until_era"]):
		return false
	if prop.has("replaced_by") and is_shown_in(props, prop["replaced_by"], world):
		return false
	return holds(prop["kind"], prop["key"], world)


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
