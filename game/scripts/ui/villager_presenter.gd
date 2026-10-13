class_name VillagerPresenter
extends RefCounted
## Turns a villager into what the player is shown when they click them: a name, their traits, any
## profession and a thought (docs/gameplay.md P11). The thought follows what they are doing and
## what the camp is like (no fire yet, low on food, their traits), and is a pure function of the
## world, so it holds still between ticks and never touches the simulation's random numbers.
## Pure logic, no nodes.

const FOOD_LOW: int = 4
## A thought lasts this many ticks before another is picked.
const THOUGHT_TICKS: int = 3

const BY_ACTIVITY: Dictionary = {
	VillagerState.ACTIVITY_GATHER_WOOD: [
		"The wood at the forest's edge is good and dry.",
		"Thinking how much wood a winter takes.",
		"Chopping is easier with a rhythm.",
	],
	VillagerState.ACTIVITY_FORAGE: [
		"Looking for anything that grows by the river.",
		"Hoping the baskets come home full.",
		"There is always something to eat if you look long enough.",
	],
	VillagerState.ACTIVITY_SOCIALIZE: [
		"Telling anyone who will listen about the day.",
		"It is good to sit with the others.",
		"Trying to remember a story from long ago.",
	],
	VillagerState.ACTIVITY_BUILD: [
		"This will be better than what the group has now.",
		"Just a little more to do.",
		"Counting what is left to lash and lay.",
	],
	VillagerState.ACTIVITY_WANDER: [
		"Wondering what is beyond the trees.",
		"Following the river with no plan at all.",
		"Looking at the sky for no reason.",
	],
	VillagerState.ACTIVITY_REST: [
		"Resting by the fire.",
		"Watching the flames.",
		"Doing nothing, and enjoying it.",
	],
}
const BY_TRAIT: Dictionary = {
	VillagerState.TRAIT_CURIOUS: [
		"Keeps wondering what is over the next ridge.",
		"Has a question nobody can answer yet.",
	],
	VillagerState.TRAIT_SOCIAL: [
		"Hopes everyone will sit together tonight.",
		"Can hear a story starting somewhere.",
	],
	VillagerState.TRAIT_INDUSTRIOUS: [
		"Cannot sit still while there is work to do.",
		"Is already planning tomorrow's work.",
	],
	VillagerState.TRAIT_NATURE_LOVING: [
		"Is listening to the birds.",
		"Has noticed which flowers have opened.",
	],
}
const ASLEEP: Array[String] = [
	"Fast asleep.",
	"Asleep, and dreaming of something.",
]
const COLD: Array[String] = [
	"It is cold in the cave, and dark.",
	"Pulling the hide closer against the cold.",
	"Listening to the dark outside the cave mouth.",
	"Someone will have to find a way to keep warm.",
]
const LOW_FOOD: Array[String] = [
	"The food pile is getting small.",
	"Wondering when the next meal will be.",
]

var display_name: String = ""
var look: StringName = &""
## For example "Curious, social". Empty if they have none.
var traits_text: String = ""
## For example "Scout". Empty if they have none.
var role_text: String = ""
var thought: String = ""


static func present(
	villager: VillagerState, world: WorldState, config: SimConfig
) -> VillagerPresenter:
	var view: VillagerPresenter = VillagerPresenter.new()
	view.display_name = villager.display_name
	view.look = villager.look if villager.look != &"" else villager.id
	view.traits_text = traits_text_for(villager)
	view.role_text = String(villager.profession).replace("_", " ").capitalize()
	view.thought = thought_for(villager, world, config)
	return view


static func traits_text_for(villager: VillagerState) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for trait_name: StringName in villager.traits:
		parts.append(String(trait_name).replace("_", "-"))
	var text: String = ", ".join(parts)
	return text.left(1).to_upper() + text.substr(1)


static func thought_for(
	villager: VillagerState, world: WorldState, config: SimConfig
) -> String:
	if villager.is_away():
		return "Out in %s, far from the camp." % _place(villager.location)
	var asleep: bool = config.is_sleeping_hour(config.hour_of(world.tick))
	if asleep and villager.activity == VillagerState.ACTIVITY_REST:
		return _pick(ASLEEP, villager, world)
	return _pick(_pool(villager, world), villager, world)


## Everything this villager might be thinking right now; one is picked by `_pick`.
static func _pool(villager: VillagerState, world: WorldState) -> Array[String]:
	var pool: Array[String] = []
	var idle: bool = villager.activity == VillagerState.ACTIVITY_REST \
			or villager.activity == VillagerState.ACTIVITY_SOCIALIZE \
			or (villager.activity == VillagerState.ACTIVITY_BUILD and world.constructing() == null)
	if idle and not world.has_fire():
		pool.append_array(COLD)
	else:
		var fallback: Array = BY_ACTIVITY[VillagerState.ACTIVITY_REST]
		pool.append_array(_lines(BY_ACTIVITY.get(villager.activity, fallback)))
	for trait_name: StringName in villager.traits:
		pool.append_array(_lines(BY_TRAIT.get(trait_name, [])))
	if world.resource_amount(&"food") < FOOD_LOW:
		pool.append_array(LOW_FOOD)
	return pool


static func _pick(lines: Array[String], villager: VillagerState, world: WorldState) -> String:
	var seed_value: int = String(villager.id).hash() + floori(float(world.tick) / THOUGHT_TICKS)
	return lines[posmod(seed_value, lines.size())]


static func _lines(source: Array) -> Array[String]:
	var lines: Array[String] = []
	for line: Variant in source:
		lines.append(line as String)
	return lines


## "western_forest" -> "the western forest".
static func _place(location: StringName) -> String:
	return "the %s" % String(location).replace("_", " ")
