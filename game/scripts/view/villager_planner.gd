class_name VillagerPlanner
extends RefCounted
## Turns a villager's simulated activity into somewhere to stand and something to do. Pure
## logic with no nodes, so it is testable headless. The only randomness is where an aimless
## wanderer heads; it is view-side and never touches the simulation.

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


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
			result.target = WorldLayout.spot(WorldLayout.WOOD_SPOTS, slot)
			result.pose = &"chop"
			result.focus_x = WorldLayout.CHOP_X
		VillagerState.ACTIVITY_FORAGE:
			result.target = WorldLayout.spot(WorldLayout.FORAGE_SPOTS, slot)
			result.focus_x = WorldLayout.PINE_X - 6.0
		VillagerState.ACTIVITY_HUNT:
			result.target = WorldLayout.spot(WorldLayout.HUNT_SPOTS, slot)
			result.pose = &"spear"
			result.focus_x = WorldLayout.HUNT_X
		VillagerState.ACTIVITY_SOCIALIZE:
			if world.has_fire():
				result.target = WorldLayout.spot(WorldLayout.SOCIAL_SPOTS, slot)
				result.focus_x = WorldLayout.FIRE_X
			else:
				_plan_cold_camp(result, slot)
		VillagerState.ACTIVITY_BUILD:
			_plan_build(result, world, slot)
		VillagerState.ACTIVITY_WANDER:
			result.wander = true
			result.target = Vector2(
				_rng.randf_range(WorldLayout.WANDER_X.x, WorldLayout.WANDER_X.y),
				_rng.randf_range(WorldLayout.WANDER_Y.x, WorldLayout.WANDER_Y.y),
			)
		_:
			_plan_hearth(result, world, slot)
	return result


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
