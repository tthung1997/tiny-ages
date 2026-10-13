class_name VillagerSystem
extends RefCounted
## Gives villagers their autonomous day: sleep at night, otherwise drift between work and
## leisure, gathering as they go. Traits only bias what they choose.

const WEIGHT_GATHER: float = 3.0
const WEIGHT_FORAGE: float = 3.0
const WEIGHT_SOCIALIZE: float = 1.0
const WEIGHT_WANDER: float = 1.0
const WEIGHT_BUILD: float = 6.0
## A group that chose to hunt sometimes goes out hunting; a hunt brings back more than foraging.
const WEIGHT_HUNT: float = 2.0
const HUNT_YIELD: float = 2.0
const TRAIT_BIAS: float = 2.0
## Multiplies the wish to gather a resource the group already has plenty of.
const PLENTY_WEIGHT: float = 0.1
## Chance per tick that an idle villager joins a building site that appears.
const BUILD_DRIFT_CHANCE: float = 0.5


func step(sim: Simulation) -> void:
	var world: WorldState = sim.world
	var config: SimConfig = sim.config
	var sleeping: bool = config.is_sleeping_hour(config.hour_of(world.tick))
	var building_underway: bool = world.constructing() != null
	for villager: VillagerState in world.villagers:
		if villager.is_away():
			if world.tick < villager.away_until_tick:
				continue
			_return_home(villager)
		if sleeping:
			villager.activity = VillagerState.ACTIVITY_REST
			villager.activity_ticks_left = 0
			continue
		villager.activity_ticks_left -= 1
		var building_unwanted: bool = villager.activity == VillagerState.ACTIVITY_BUILD \
				and not building_underway
		var drifts_to_build: bool = building_underway \
				and villager.activity != VillagerState.ACTIVITY_BUILD \
				and sim.rng.randf() < BUILD_DRIFT_CHANCE
		if villager.activity_ticks_left <= 0 or villager.activity == VillagerState.ACTIVITY_REST \
				or building_unwanted or drifts_to_build:
			_choose_activity(sim, villager, building_underway)
		_work(sim, villager)


func _return_home(villager: VillagerState) -> void:
	villager.activity = VillagerState.ACTIVITY_REST
	villager.activity_ticks_left = 0
	villager.location = VillagerState.LOCATION_CAMP
	villager.away_until_tick = 0


func _choose_activity(sim: Simulation, villager: VillagerState, building_underway: bool) -> void:
	var activities: Array[StringName] = []
	var weights: Array[float] = []
	activities.append(VillagerState.ACTIVITY_GATHER_WOOD)
	weights.append(
		WEIGHT_GATHER * _bias(villager, VillagerState.TRAIT_INDUSTRIOUS) * _plenty(sim, &"wood")
	)
	activities.append(VillagerState.ACTIVITY_FORAGE)
	weights.append(
		WEIGHT_FORAGE * _bias(villager, VillagerState.TRAIT_NATURE_LOVING) * _plenty(sim, &"food")
	)
	activities.append(VillagerState.ACTIVITY_SOCIALIZE)
	weights.append(WEIGHT_SOCIALIZE * _bias(villager, VillagerState.TRAIT_SOCIAL))
	activities.append(VillagerState.ACTIVITY_WANDER)
	weights.append(WEIGHT_WANDER * _bias(villager, VillagerState.TRAIT_CURIOUS))
	if sim.world.has_flag(&"path_hunting"):
		activities.append(VillagerState.ACTIVITY_HUNT)
		weights.append(
			WEIGHT_HUNT * _bias(villager, VillagerState.TRAIT_CURIOUS) * _plenty(sim, &"food")
		)
	if building_underway:
		activities.append(VillagerState.ACTIVITY_BUILD)
		weights.append(WEIGHT_BUILD * _bias(villager, VillagerState.TRAIT_INDUSTRIOUS))
	var picked: int = SimRandom.pick_weighted(sim.rng, weights)
	villager.activity = activities[maxi(picked, 0)]
	villager.activity_ticks_left = sim.rng.randi_range(
		sim.config.min_activity_ticks, sim.config.max_activity_ticks
	)


func _bias(villager: VillagerState, trait_name: StringName) -> float:
	return TRAIT_BIAS if villager.has_trait(trait_name) else 1.0


## How keen the group is to gather a resource: full while it is short, much less once the stores
## are comfortable, so stock hovers instead of piling up for ever.
func _plenty(sim: Simulation, resource: StringName) -> float:
	if sim.world.resource_amount(resource) >= sim.config.comfortable_stock:
		return PLENTY_WEIGHT
	return 1.0


func _work(sim: Simulation, villager: VillagerState) -> void:
	var config: SimConfig = sim.config
	var rate: float = config.gather_rate
	if villager.has_trait(VillagerState.TRAIT_INDUSTRIOUS):
		rate *= config.industrious_multiplier
	match villager.activity:
		VillagerState.ACTIVITY_GATHER_WOOD:
			sim.world.add_resource_fraction(&"wood", rate)
		VillagerState.ACTIVITY_FORAGE:
			sim.world.add_resource_fraction(&"food", rate)
		VillagerState.ACTIVITY_HUNT:
			sim.world.add_resource_fraction(&"food", rate * HUNT_YIELD)
