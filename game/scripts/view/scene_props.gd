class_name SceneProps
extends RefCounted
## Pieces of the world that show because of what the settlement has chosen or earned, not because
## a building of that name stands: the sown plot and the pen the age turn leaves behind, and later
## whatever an answer or a milestone puts on the ground. Pure and headless: the view asks which
## are shown and draws them (docs/ages.md V10).
##
## Each prop is a full-width art piece named like the others; `at_x` is the left edge of its
## sprite in camp pixels (-384 is the west page), `z` is its draw order, and `kind` and `key` say
## what the world must hold. Mirrors tools/art/settled_camp.js: change both together.

enum Kind {
	## Append new kinds at the end.
	FLAG, ## `key` is a world flag.
	ACHIEVEMENT, ## `key` is an earned achievement.
	BUILDING, ## `key` is a completed building id.
}

const PROPS: Dictionary = {
	&"west_plot_farm": {"at_x": -384.0, "z": 55, "kind": Kind.FLAG, "key": &"path_agriculture"},
	&"west_plot_patch": {"at_x": -384.0, "z": 55, "kind": Kind.FLAG, "key": &"path_herding"},
	&"west_pen": {"at_x": -384.0, "z": 77, "kind": Kind.FLAG, "key": &"path_herding"},
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
