class_name FoodSystem
extends RefCounted
## The group eats. Each tick the settlement uses a little food, more per head as the group grows
## past `SimConfig.crowding_from`. The stock never goes below zero and nothing else happens to
## anyone: a shortage is only felt in what the villagers choose to do (VillagerSystem), in the
## gauge on the strip and in the decisions it brings (docs/gameplay.md P13).


func step(sim: Simulation) -> void:
	var amount: float = ration_per_tick(sim.world.villagers.size(), sim.config)
	if amount > 0.0:
		sim.world.add_resource_fraction(&"food", -amount)


## What a group of `villagers` eats in one tick.
static func ration_per_tick(villagers: int, config: SimConfig) -> float:
	if villagers <= 0:
		return 0.0
	var extra: int = maxi(villagers - config.crowding_from, 0)
	var crowding: float = 1.0 + config.crowding_per_villager * float(extra)
	return config.food_per_villager_per_day / float(config.ticks_per_day) \
			* float(villagers) * crowding
