extends McpTestSuite
## The Cave Age milestones beyond fire: every one has more than one way to happen, newcomers can
## join, and the gate asks for all six.

const DAY: int = SimFixture.TICKS_PER_DAY


func suite_name() -> String:
	return "sim_milestones"


func _fire(sim: Simulation, event_id: StringName) -> PendingDecision:
	sim.fire_event(sim.content.get_event(event_id), sim.world.villagers[0])
	return SimFixture.pending_for(sim, event_id)


func test_the_gate_asks_for_all_six_milestones() -> void:
	var needed: Array[StringName] = SimFixture.load_content().get_era(&"settled").required_achievements
	for milestone: StringName in [
		&"fire", &"stone_tools", &"reliable_food", &"shared_stories", &"bigger_group",
		&"unexpected_garden",
	]:
		assert_true(needed.has(milestone), "%s should gate the Settled Age" % milestone)
	assert_eq(needed.size(), 6)


func test_stone_tools_can_come_from_a_lucky_stone_instead_of_a_building() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var decision: PendingDecision = _fire(sim, &"cracking_nuts")
	assert_true(sim.resolve_decision(decision.id, &"keep_the_stone"))
	assert_true(sim.world.has_achievement(&"stone_tools"))
	assert_false(sim.world.has_building(&"knapping_spot"))


func test_tossing_the_stone_aside_earns_nothing_yet() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var decision: PendingDecision = _fire(sim, &"cracking_nuts")
	assert_true(sim.resolve_decision(decision.id, &"toss_it"))
	assert_false(sim.world.has_achievement(&"stone_tools"))


func test_hunting_makes_food_reliable_at_once() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.achievements.append(&"stone_tools")
	var decision: PendingDecision = _fire(sim, &"herds_nearby")
	assert_true(sim.resolve_decision(decision.id, &"hunt"))
	assert_true(sim.world.has_achievement(&"reliable_food"))
	assert_true(sim.world.has_flag(&"path_hunting"))


func test_foraging_needs_the_drying_rack_to_make_food_reliable() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.achievements.append(&"stone_tools")
	var decision: PendingDecision = _fire(sim, &"herds_nearby")
	assert_true(sim.resolve_decision(decision.id, &"forage"))
	assert_false(sim.world.has_achievement(&"reliable_food"))
	assert_true(sim.world.has_flag(&"path_foraging"))
	var rack: BuildingState = BuildingState.new()
	rack.def_id = &"drying_rack"
	sim.world.buildings.append(rack)
	sim.complete_building(rack)
	assert_true(sim.world.has_achievement(&"reliable_food"))


func test_the_hunt_waits_for_stone_tools_and_stops_once_chosen() -> void:
	var sim: Simulation = SimFixture.new_sim(3)
	SimFixture.jump_to_day(sim, 54)
	SimFixture.advance_until_asked(sim, &"herds_nearby", DAY * 30)
	assert_eq(sim.world.event_counts.get(&"herds_nearby", 0), 0, "No spears without stone tools")
	sim.world.achievements.append(&"stone_tools")
	var asked: int = SimFixture.advance_until_asked(sim, &"herds_nearby", DAY * 10)
	assert_gt(asked, 0, "Once there are tools the herds come near")


func test_shared_stories_have_two_routes() -> void:
	for route: Array in [[&"stories_by_the_fire", &"tell_it"], [&"ochre_on_the_riverbank", &"paint_the_wall"]]:
		var sim: Simulation = SimFixture.new_sim()
		var decision: PendingDecision = _fire(sim, route[0])
		assert_true(sim.resolve_decision(decision.id, route[1]))
		assert_true(sim.world.has_achievement(&"shared_stories"), "%s" % route[0])


func test_passing_on_a_story_earns_nothing() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var decision: PendingDecision = _fire(sim, &"stories_by_the_fire")
	assert_true(sim.resolve_decision(decision.id, &"let_it_pass"))
	assert_false(sim.world.has_achievement(&"shared_stories"))


func test_milestone_events_can_happen_to_anyone_in_any_group() -> void:
	for rng_seed: int in 60:
		var sim: Simulation = SimFixture.new_sim(rng_seed)
		SimFixture.jump_to_day(sim, 108)
		SimFixture.set_traits(sim, [
			[VillagerState.TRAIT_CURIOUS, VillagerState.TRAIT_INDUSTRIOUS],
			[VillagerState.TRAIT_CURIOUS, VillagerState.TRAIT_INDUSTRIOUS],
			[VillagerState.TRAIT_CURIOUS, VillagerState.TRAIT_INDUSTRIOUS],
		])
		var asked: int = SimFixture.advance_until_asked(sim, &"stories_by_the_fire", DAY * 40)
		assert_gt(asked, 0, "seed %d: nobody social, but the story still happens" % rng_seed)


func test_strangers_only_appear_once_there_is_a_lookout() -> void:
	var sim: Simulation = SimFixture.new_sim(2)
	SimFixture.jump_to_day(sim, 162)
	SimFixture.advance_until_asked(sim, &"strangers_on_the_ridge", DAY * 30)
	assert_eq(sim.world.event_counts.get(&"strangers_on_the_ridge", 0), 0)
	var lookout: BuildingState = BuildingState.new()
	lookout.def_id = &"lookout"
	sim.world.buildings.append(lookout)
	sim.complete_building(lookout)
	var asked: int = SimFixture.advance_until_asked(sim, &"strangers_on_the_ridge", DAY * 30)
	assert_gt(asked, 0)


func test_welcoming_strangers_grows_the_group() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var joined: Array[String] = []
	sim.villager_joined.connect(func(villager: VillagerState) -> void: joined.append(villager.id))
	var decision: PendingDecision = _fire(sim, &"strangers_on_the_ridge")
	assert_true(sim.resolve_decision(decision.id, &"welcome_them"))
	assert_eq(sim.world.villagers.size(), 5)
	assert_eq(joined.size(), 2)
	assert_true(sim.world.has_achievement(&"bigger_group"))
	assert_gt(SimFixture.journal_index(sim.world, "joined the group"), -1)


func test_keeping_watch_does_not_grow_the_group() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var decision: PendingDecision = _fire(sim, &"strangers_on_the_ridge")
	assert_true(sim.resolve_decision(decision.id, &"keep_watch"))
	assert_eq(sim.world.villagers.size(), 3)
	assert_false(sim.world.has_achievement(&"bigger_group"))


func test_newcomers_are_unique_even_past_the_name_pool() -> void:
	var sim: Simulation = SimFixture.new_sim(9)
	for _newcomer: int in 40:
		sim.add_villager()
	var ids: Dictionary = {}
	for villager: VillagerState in sim.world.villagers:
		ids[villager.id] = true
		assert_eq(villager.traits.size(), 2)
		assert_true(villager.look != &"", "%s has a look" % villager.id)
	assert_eq(ids.size(), sim.world.villagers.size(), "Every villager id is unique")


func test_newcomers_are_reproducible_from_the_seed() -> void:
	var first: Simulation = SimFixture.new_sim(4)
	var second: Simulation = SimFixture.new_sim(4)
	first.add_villager()
	second.add_villager()
	assert_eq(first.world.villagers[3].id, second.world.villagers[3].id)
	assert_eq(first.world.villagers[3].traits, second.world.villagers[3].traits)


func test_the_milestones_are_staged_over_the_age() -> void:
	var unlock: Dictionary = {
		&"stone_tools": 18, &"reliable_food": 54, &"shared_stories": 108,
		&"bigger_group": 162, &"unexpected_garden": 216,
	}
	for rng_seed: int in [1, 2, 3]:
		var sim: Simulation = SimFixture.new_sim(rng_seed, false)
		var earned: Dictionary = {}
		sim.achievement_earned.connect(
			func(key: StringName, _title: String) -> void: earned[key] = sim.world.tick
		)
		var bot: DecisionBot = DecisionBot.new()
		for _tick: int in DAY * 330:
			sim.advance_ticks(1)
			bot.answer_all(sim)
		for key: StringName in unlock:
			assert_true(earned.has(key), "seed %d: %s was earned" % [rng_seed, key])
			if earned.has(key):
				var day: int = sim.config.day_of(earned[key])
				assert_true(
					day >= unlock[key], "seed %d: %s on day %d, before day %d" % [
						rng_seed, key, day, unlock[key],
					]
				)
		var fire_day: int = sim.config.day_of(earned.get(&"fire", 0))
		assert_true(fire_day <= 6, "seed %d: fire is the opening, found on day %d" % [rng_seed, fire_day])
		assert_gt(
			earned[&"unexpected_garden"] - earned[&"stone_tools"], DAY * 150,
			"seed %d: the milestones cover most of the age" % rng_seed
		)


func test_the_achievement_condition_reads_earned_achievements() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var condition: SimCondition = SimCondition.new()
	condition.kind = SimCondition.Kind.ACHIEVEMENT_EARNED
	condition.key = &"stone_tools"
	assert_false(condition.is_met(sim.world, sim.config))
	sim.world.achievements.append(&"stone_tools")
	assert_true(condition.is_met(sim.world, sim.config))
