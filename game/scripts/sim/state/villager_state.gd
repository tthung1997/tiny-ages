class_name VillagerState
extends Resource
## One villager's persistent state. Pure data; behaviour lives in the simulation systems.

const ACTIVITY_REST: StringName = &"rest"
const ACTIVITY_GATHER_WOOD: StringName = &"gather_wood"
const ACTIVITY_FORAGE: StringName = &"forage"
const ACTIVITY_BUILD: StringName = &"build"
const ACTIVITY_SOCIALIZE: StringName = &"socialize"
const ACTIVITY_WANDER: StringName = &"wander"
const ACTIVITY_AWAY: StringName = &"away"

const LOCATION_CAMP: StringName = &"camp"

const TRAIT_CURIOUS: StringName = &"curious"
const TRAIT_SOCIAL: StringName = &"social"
const TRAIT_INDUSTRIOUS: StringName = &"industrious"
const TRAIT_NATURE_LOVING: StringName = &"nature_loving"

@export var id: StringName = &""
@export var display_name: String = ""
@export var traits: Array[StringName] = []
@export var profession: StringName = &""
@export var activity: StringName = ACTIVITY_REST
@export var activity_ticks_left: int = 0
@export var location: StringName = LOCATION_CAMP
## Tick at which an away villager comes home.
@export var away_until_tick: int = 0


func has_trait(trait_name: StringName) -> bool:
	return traits.has(trait_name)


func is_away() -> bool:
	return activity == ACTIVITY_AWAY
