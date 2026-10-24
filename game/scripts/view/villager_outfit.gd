class_name VillagerOutfit
extends RefCounted
## What the villagers wear (docs/ages.md B8, "Clothes, one look per age"): an outfit for the turn of
## each age and a finer one at a milestone of its own. Pure and derived from the world, so there
## is nothing to save, and the outfit only follows what has been earned (the age gate stays hidden).

const FUR: StringName = &"fur"
const FIELD: StringName = &"field"
const WOVEN: StringName = &"woven"
const TOWN: StringName = &"town"
const BRONZE: StringName = &"bronze"

## Every outfit, simplest first: each falls back to the one before it if its art is missing.
const ORDER: Array[StringName] = [FUR, FIELD, WOVEN, TOWN, BRONZE]

const SETTLED_ERA: int = 1
const BRONZE_ERA: int = 2
const WOVEN_ACHIEVEMENT: StringName = &"woven_cloth"
const BRONZE_ACHIEVEMENT: StringName = &"first_casting"

## Where each outfit's sheets live, `<look>.png` inside. The woven tunic keeps its original path.
const DIRS: Dictionary = {
	FUR: "res://assets/world/cave/villagers/",
	FIELD: "res://assets/world/settled/villagers/field/",
	WOVEN: "res://assets/world/settled/villagers/",
	TOWN: "res://assets/world/bronze/villagers/town/",
	BRONZE: "res://assets/world/bronze/villagers/fittings/",
}


## The finest outfit the world has earned: bronze fittings once the first casting is earned in the
## Bronze Age, town clothes from the turn of that age, woven tunics once the cloth is woven in the
## Settled Age or later, field clothes from the turn of the Settled Age, else furs.
static func for_world(world: WorldState) -> StringName:
	if world.era_order >= BRONZE_ERA:
		if world.has_achievement(BRONZE_ACHIEVEMENT):
			return BRONZE
		return TOWN
	if world.era_order >= SETTLED_ERA:
		if world.has_achievement(WOVEN_ACHIEVEMENT):
			return WOVEN
		return FIELD
	return FUR


## The sheet for `look` in `outfit`: `res://.../<look>.png`, or "" if there is no art.
static func sheet_path(outfit: StringName, look: StringName) -> String:
	var dir: String = DIRS.get(outfit, "")
	if dir.is_empty():
		return ""
	var path: String = "%s%s.png" % [dir, look]
	return path if ResourceLoader.exists(path) else ""
