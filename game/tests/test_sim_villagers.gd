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
	var mira_ticks: int = 0
	var wren_ticks: int = 0
	for _tick: int in SimFixture.TICKS_PER_DAY * 20:
		sim.advance_ticks(1)
		sim.world.pending.clear()
		if sim.world.find_villager(&"mira").activity == VillagerState.ACTIVITY_GATHER_WOOD:
			mira_ticks += 1
		if sim.world.find_villager(&"wren").activity == VillagerState.ACTIVITY_GATHER_WOOD:
			wren_ticks += 1
	assert_gt(mira_ticks, wren_ticks, "Industrious Mira should gather wood more than Wren")


func test_away_villager_comes_home_on_time() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var theo: VillagerState = sim.world.find_villager(&"theo")
	theo.activity = VillagerState.ACTIVITY_AWAY
	theo.location = &"forest_east"
	theo.away_until_tick = sim.world.tick + 5
	sim.advance_ticks(4)
	assert_true(theo.is_away(), "Still away one tick early")
	sim.advance_ticks(1)
	assert_false(theo.is_away())
	assert_eq(theo.location, VillagerState.LOCATION_CAMP)


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
