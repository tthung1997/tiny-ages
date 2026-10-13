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
			result.focus_x = WorldLayout.PINE_X
		VillagerState.ACTIVITY_FORAGE:
			result.target = WorldLayout.spot(WorldLayout.FORAGE_SPOTS, slot)
			result.focus_x = WorldLayout.PINE_X - 6.0
		VillagerState.ACTIVITY_SOCIALIZE:
			result.target = WorldLayout.spot(WorldLayout.SOCIAL_SPOTS, slot)
			result.focus_x = WorldLayout.FIRE_X
		VillagerState.ACTIVITY_BUILD:
			_plan_build(result, world, slot)
		VillagerState.ACTIVITY_WANDER:
			result.wander = true
			result.target = Vector2(
				_rng.randf_range(WorldLayout.WANDER_X.x, WorldLayout.WANDER_X.y),
				_rng.randf_range(WorldLayout.WANDER_Y.x, WorldLayout.WANDER_Y.y),
			)
		_:
			result.target = WorldLayout.spot(WorldLayout.FIRE_SPOTS, slot)
			result.focus_x = WorldLayout.FIRE_X
	return result


func _plan_build(result: VillagerPlan, world: WorldState, slot: int) -> void:
	var site: BuildingState = world.constructing()
	if site == null:
		result.target = WorldLayout.spot(WorldLayout.FIRE_SPOTS, slot)
		result.focus_x = WorldLayout.FIRE_X
		return
	result.target = WorldLayout.build_spot(site.def_id, slot)
	result.pose = &"hammer"
	var slot_data: Dictionary = WorldLayout.BUILDINGS.get(site.def_id, {})
	result.focus_x = float(slot_data.get("cx", result.target.x + 10.0))
