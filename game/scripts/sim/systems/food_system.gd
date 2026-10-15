class_name FoodSystem
extends RefCounted
## The group eats. Each tick every villager eats the same small share. The stock never goes below
## zero and nothing else happens to anyone: a shortage is only felt in what the villagers choose
## to do (VillagerSystem), in the gauge on the strip and in the decisions it brings
## (docs/gameplay.md P13).


func step(sim: Simulation) -> void:
	var amount: float = ration_per_tick(sim.world.villagers.size(), sim.config)
	if amount > 0.0:
		sim.world.add_resource_fraction(&"food", -amount)


## What a group of `villagers` eats in one tick.
static func ration_per_tick(villagers: int, config: SimConfig) -> float:
	return config.food_per_villager_per_day / float(config.ticks_per_day) \
			* float(maxi(villagers, 0))
