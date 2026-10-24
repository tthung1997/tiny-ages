class_name VillagerPlanner
extends RefCounted
## Turns a villager's simulated activity into somewhere to stand and something to do. Pure
## logic with no nodes, so it is testable headless. The only randomness is where an aimless
## wanderer heads; it is view-side and never touches the simulation.

## Two villagers who stay put never stand closer than this, so each can be told apart and clicked.
const MIN_GAP: float = 8.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Moves a villager who would stand on top of an earlier one to the west of them (west is always
## open ground), until nobody stays put within `MIN_GAP` of another. Wanderers keep their own
## random targets. Deterministic, so a villager does not shuffle between refreshes.
static func spread(plans: Array[VillagerPlan]) -> void:
	var placed: Array[VillagerPlan] = []
	for plan: VillagerPlan in plans:
		if not plan.visible or plan.wander:
			continue
		var moved: bool = true
		while moved:
			moved = false
			for other: VillagerPlan in placed:
				if absf(other.target.x - plan.target.x) < MIN_GAP:
					plan.target.x = other.target.x - MIN_GAP
					moved = true
		placed.append(plan)


## `slot` is the villager's index, used to spread people over the available spots.
func plan(
	villager: VillagerState, world: WorldState, config: SimConfig, slot: int
) -> VillagerPlan:
	var result: VillagerPlan = VillagerPlan.new()
	if villager.is_away():
		result.visible = false
		result.hidden_reason = VillagerPlan.HIDDEN_AWAY
		return result
	var asleep: bool = config.is_sleeping_hour(config.hour_of(world.tick))
	if villager.activity == VillagerState.ACTIVITY_REST and asleep:
		result.visible = false
		result.hidden_reason = VillagerPlan.HIDDEN_ASLEEP
		return result
	match villager.activity:
		VillagerState.ACTIVITY_GATHER_WOOD:
			if not _plan_smith(result, villager, world, slot):
				result.target = WorldLayout.spot(WorldLayout.WOOD_SPOTS, slot)
				result.pose = &"chop"
				result.focus_x = WorldLayout.CHOP_X
		VillagerState.ACTIVITY_FORAGE:
			_plan_forage(result, world, config, slot)
		VillagerState.ACTIVITY_HUNT:
			result.target = WorldLayout.spot(WorldLayout.HUNT_SPOTS, slot)
			result.pose = &"spear"
			result.focus_x = WorldLayout.HUNT_X
		VillagerState.ACTIVITY_SOCIALIZE:
			if not _plan_trader(result, villager, world, config, slot):
				if world.has_fire():
					result.target = WorldLayout.spot(WorldLayout.SOCIAL_SPOTS, slot)
					result.focus_x = WorldLayout.FIRE_X
				else:
					_plan_cold_camp(result, slot)
		VillagerState.ACTIVITY_BUILD:
			_plan_build(result, world, slot)
		VillagerState.ACTIVITY_WANDER:
			if _plan_trader(result, villager, world, config, slot):
				return result
			result.wander = true
			var range_x: Vector2 = WorldLayout.wander_range(world)
			result.target = Vector2(
				_rng.randf_range(range_x.x, range_x.y),
				_rng.randf_range(WorldLayout.WANDER_Y.x, WorldLayout.WANDER_Y.y),
			)
		_:
			_plan_hearth(result, world, slot)
	return result


## A Smith with a Smithy to work at hammers in front of it instead of cutting wood in the forest
## (in the sim it is still wood for the hearth; the view only shows where it is spent).
func _plan_smith(
	result: VillagerPlan, villager: VillagerState, world: WorldState, slot: int
) -> bool:
	if villager.profession != &"smith" or not world.has_building(&"smithy"):
		return false
	result.target = WorldLayout.spot(WorldLayout.SMITHY_SPOTS, slot)
	result.pose = &"hammer"
	result.focus_x = float(WorldLayout.BUILDINGS[&"smithy"]["cx"])
	return true


## A Trader walks the road: to the market once there is one, and to the Trading Post, on
## alternate days, instead of wandering at random.
func _plan_trader(
	result: VillagerPlan, villager: VillagerState, world: WorldState, config: SimConfig, slot: int
) -> bool:
	if villager.profession != &"trader":
		return false
	var market: bool = world.has_flag(&"market_day")
	var post: bool = world.has_building(&"trading_post")
	if not market and not post:
		return false
	if market and (not post or posmod(config.day_of(world.tick) + slot, 2) == 0):
		result.target = WorldLayout.spot(WorldLayout.MARKET_SPOTS, slot)
		result.focus_x = WorldLayout.MARKET_X
	else:
		result.target = WorldLayout.spot(WorldLayout.POST_SPOTS, slot)
		result.focus_x = float(WorldLayout.BUILDINGS[&"trading_post"]["cx"])
	return true


## Foragers spread over the places the group forages: the pines, and once the world has them the
## near bank (fishing), the far bank's reeds (past a crossing) and the flats at low tide. Which
## one a villager is at changes by the day, so nobody stays in one place for ever. The sim does not
## know: it is all `forage`, and the food comes in the same.
func _plan_forage(result: VillagerPlan, world: WorldState, config: SimConfig, slot: int) -> void:
	var places: Array[StringName] = [&"pines"]
	var crossed: bool = WorldLayout.crossing_open(world)
	if _has_any_flag(world, WorldLayout.FISH_FLAGS):
		places.append(&"bank")
	if crossed and _has_any_flag(world, WorldLayout.REED_FLAGS):
		places.append(&"reeds")
	var turn: int = slot + config.day_of(world.tick)
	var place: StringName = places[posmod(turn, places.size())]
	if crossed and config.is_low_tide(world.tick) and posmod(turn, 2) == 0:
		place = &"flats"
	match place:
		&"bank":
			result.target = WorldLayout.spot(WorldLayout.FISH_SPOTS, slot)
			result.pose = &"spear"
			result.focus_x = WorldLayout.FISH_FOCUS_X
		&"reeds":
			result.target = WorldLayout.spot(WorldLayout.REED_SPOTS, slot)
			result.pose = &"chop"
			result.focus_x = WorldLayout.REED_FOCUS_X
		&"flats":
			result.target = WorldLayout.spot(WorldLayout.FLATS_SPOTS, slot)
			result.focus_x = WorldLayout.FLATS_FOCUS_X
		_:
			result.target = WorldLayout.spot(WorldLayout.FORAGE_SPOTS, slot)
			result.focus_x = WorldLayout.PINE_X - 6.0


func _has_any_flag(world: WorldState, flags: Array[StringName]) -> bool:
	for flag: StringName in flags:
		if world.has_flag(flag):
			return true
	return false


## Idle villagers sit round the fire, or in the cave mouth while there is none.
func _plan_hearth(result: VillagerPlan, world: WorldState, slot: int) -> void:
	if world.has_fire():
		result.target = WorldLayout.spot(WorldLayout.FIRE_SPOTS, slot)
		result.focus_x = WorldLayout.FIRE_X
	else:
		_plan_cold_camp(result, slot)


func _plan_cold_camp(result: VillagerPlan, slot: int) -> void:
	result.target = WorldLayout.spot(WorldLayout.COLD_SPOTS, slot)
	result.focus_x = WorldLayout.COLD_X


func _plan_build(result: VillagerPlan, world: WorldState, slot: int) -> void:
	var site: BuildingState = world.constructing()
	if site == null:
		_plan_hearth(result, world, slot)
		return
	result.target = WorldLayout.build_spot(site.def_id, slot)
	result.pose = &"hammer"
	var slot_data: Dictionary = WorldLayout.BUILDINGS.get(site.def_id, {})
	result.focus_x = float(slot_data.get("cx", result.target.x + 10.0))
