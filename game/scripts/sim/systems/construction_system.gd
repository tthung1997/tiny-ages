class_name ConstructionSystem
extends RefCounted
## Advances the building under construction and collects output from finished buildings.


func step(sim: Simulation) -> void:
	var world: WorldState = sim.world
	var config: SimConfig = sim.config
	var site: BuildingState = world.constructing()
	if site != null:
		var builders: int = _count_builders(world)
		site.progress += float(builders) * config.build_rate_per_builder
		var def: BuildingDef = sim.content.get_building(site.def_id)
		if def == null:
			push_error("Unknown building '%s' under construction" % site.def_id)
		elif site.progress >= float(def.work_required):
			sim.complete_building(site)
	for building: BuildingState in world.buildings:
		if not building.complete:
			continue
		var built: BuildingDef = sim.content.get_building(building.def_id)
		if built == null:
			continue
		for key: StringName in built.daily_output:
			world.add_resource_fraction(key, built.daily_output[key] / float(config.ticks_per_day))


func _count_builders(world: WorldState) -> int:
	var count: int = 0
	for villager: VillagerState in world.villagers:
		if villager.activity == VillagerState.ACTIVITY_BUILD:
			count += 1
	return count
