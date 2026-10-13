extends McpTestSuite
## Villagers live on their own: sleep, work, bias by trait, and come home from trips.


func suite_name() -> String:
	return "sim_villagers"


func test_villagers_sleep_at_night() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.tick = sim.config.tick_for_hour(23) - 1
	sim.advance_ticks(1)
	for villager: VillagerState in sim.world.villagers:
		assert_eq(villager.activity, VillagerState.ACTIVITY_REST)


func test_villagers_gather_resources_by_day() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.advance_ticks(SimFixture.TICKS_PER_DAY * 2)
	var gathered: int = sim.world.resource_amount(&"wood") + sim.world.resource_amount(&"food")
	assert_gt(gathered, 6, "Two days of work should yield more than the starting stock")


func test_industrious_villagers_gather_wood_more_often() -> void:
	var sim: Simulation = SimFixture.new_sim(7)
	SimFixture.set_traits(sim, [
		[VillagerState.TRAIT_INDUSTRIOUS, VillagerState.TRAIT_SOCIAL],
		[VillagerState.TRAIT_SOCIAL, VillagerState.TRAIT_NATURE_LOVING],
		[VillagerState.TRAIT_SOCIAL, VillagerState.TRAIT_NATURE_LOVING],
	])
	var worker: VillagerState = sim.world.villagers[0]
	var other: VillagerState = sim.world.villagers[1]
	var worker_ticks: int = 0
	var other_ticks: int = 0
	for _tick: int in SimFixture.TICKS_PER_DAY * 20:
		sim.advance_ticks(1)
		sim.world.pending.clear()
		if worker.activity == VillagerState.ACTIVITY_GATHER_WOOD:
			worker_ticks += 1
		if other.activity == VillagerState.ACTIVITY_GATHER_WOOD:
			other_ticks += 1
	assert_gt(worker_ticks, other_ticks, "An industrious villager should gather wood more often")


func test_away_villager_comes_home_on_time() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var scout: VillagerState = sim.world.villagers[0]
	scout.activity = VillagerState.ACTIVITY_AWAY
	scout.location = &"eastern_valley"
	scout.away_until_tick = sim.world.tick + 5
	sim.advance_ticks(4)
	assert_true(scout.is_away(), "Still away one tick early")
	sim.advance_ticks(1)
	assert_false(scout.is_away())
	assert_eq(scout.location, VillagerState.LOCATION_CAMP)


func test_same_seed_gives_the_same_world() -> void:
	var first: Simulation = SimFixture.new_sim(42)
	var second: Simulation = SimFixture.new_sim(42)
	first.advance_ticks(SimFixture.TICKS_PER_DAY * 5)
	second.advance_ticks(SimFixture.TICKS_PER_DAY * 5)
	assert_eq(SimFixture.snapshot(first.world), SimFixture.snapshot(second.world))


func test_different_seeds_diverge() -> void:
	var first: Simulation = SimFixture.new_sim(1)
	var second: Simulation = SimFixture.new_sim(2)
	first.advance_ticks(SimFixture.TICKS_PER_DAY * 5)
	second.advance_ticks(SimFixture.TICKS_PER_DAY * 5)
	assert_ne(SimFixture.snapshot(first.world), SimFixture.snapshot(second.world))
