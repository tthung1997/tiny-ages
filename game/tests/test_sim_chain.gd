extends McpTestSuite
## The first vertical slice, end to end, from the MVP concept: build the Explorer's Hut, Theo
## wants to explore, he returns with a seed, it is planted, it flowers, a rare butterfly comes.
## Each step is a consequence of the previous player choice. Run across several seeds so the
## chain does not depend on one lucky roll.

const SEEDS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8]
const DAY: int = SimFixture.TICKS_PER_DAY


func suite_name() -> String:
	return "sim_chain"


func test_the_exploration_chain_plays_out_for_every_seed() -> void:
	for rng_seed: int in SEEDS:
		_run_chain(rng_seed)


func test_the_chain_is_reproducible_from_a_seed() -> void:
	var first: Simulation = SimFixture.new_sim(11)
	var second: Simulation = SimFixture.new_sim(11)
	_play_through_hut_and_exploration(first)
	_play_through_hut_and_exploration(second)
	assert_eq(SimFixture.snapshot(first.world), SimFixture.snapshot(second.world))


func test_ignoring_the_explorer_just_delays_the_chain() -> void:
	var sim: Simulation = SimFixture.new_sim(2)
	_build_hut(sim)
	assert_gt(SimFixture.advance_until_pending(sim, &"curious_explorer", DAY * 10), 0)
	var decision: PendingDecision = SimFixture.pending_for(sim, &"curious_explorer")
	assert_true(sim.resolve_decision(decision.id, &"remain"))
	assert_false(sim.world.find_villager(&"theo").is_away())
	var again: int = SimFixture.advance_until_pending(sim, &"curious_explorer", DAY * 15)
	assert_gt(again, 0, "Asking them to stay should not end the story; they ask again later")


func _run_chain(rng_seed: int) -> void:
	var sim: Simulation = SimFixture.new_sim(rng_seed)
	var label: String = "seed %d" % rng_seed
	_build_hut(sim)
	assert_true(sim.world.has_building(&"explorers_hut"), "%s: hut built" % label)

	var asked: int = SimFixture.advance_until_pending(sim, &"curious_explorer", DAY * 10)
	assert_gt(asked, 0, "%s: Theo asks to explore" % label)
	if asked < 0:
		return
	var ask: PendingDecision = SimFixture.pending_for(sim, &"curious_explorer")
	assert_eq(ask.subject_id, &"theo", "%s: the curious villager is the one who asks" % label)
	assert_true(sim.resolve_decision(ask.id, &"encourage"))
	var theo: VillagerState = sim.world.find_villager(&"theo")
	assert_true(theo.is_away(), "%s: Theo leaves" % label)
	assert_eq(theo.profession, &"explorer")

	var returned: int = SimFixture.advance_until_pending(sim, &"explorer_returns", DAY * 3)
	assert_gt(returned, 0, "%s: Theo returns" % label)
	if returned < 0:
		return
	assert_false(theo.is_away())
	assert_eq(sim.world.item_count(&"strange_seed"), 1, "%s: with a seed" % label)
	assert_true(sim.world.has_flag(&"forest_east_explored"))
	var found: PendingDecision = SimFixture.pending_for(sim, &"explorer_returns")
	assert_true(sim.resolve_decision(found.id, &"plant_it"))
	assert_eq(sim.world.plants.size(), 1, "%s: the seed is planted" % label)
	assert_eq(sim.world.item_count(&"strange_seed"), 0)

	var bloomed: int = SimFixture.advance_until_flag(sim, &"strange_flower_bloomed", DAY * 4)
	assert_gt(bloomed, 0, "%s: it flowers" % label)
	assert_true(sim.world.has_achievement(&"unexpected_garden"))

	var visited: int = SimFixture.advance_until_flag(sim, &"butterfly_seen", DAY * 30)
	assert_gt(visited, 0, "%s: a rare butterfly visits" % label)
	assert_true(sim.world.has_achievement(&"rare_visitor"))
	_assert_journal_tells_the_story(sim.world, label)


func _assert_journal_tells_the_story(world: WorldState, label: String) -> void:
	var beats: Array[String] = [
		"Construction of the Explorer's Hut began",
		"The Explorer's Hut was completed",
		"Theo set off to explore",
		"Theo returned from the eastern forest",
		"Theo planted the strange seed",
		"The strange seed flowered",
		"A butterfly nobody had seen before",
		"Achievement: A Rare Visitor",
	]
	var previous: int = -1
	for beat: String in beats:
		var index: int = SimFixture.journal_index(world, beat)
		assert_gt(index, previous, "%s: journal has '%s' after the previous beat" % [label, beat])
		previous = index


## Waits for the building decision, picks the Explorer's Hut, and waits for it to be built.
func _build_hut(sim: Simulation) -> void:
	var opened: int = SimFixture.advance_until_pending(sim, &"building_opportunity", DAY * 5)
	assert_gt(opened, 0, "A building decision opens in the first days")
	if opened < 0:
		return
	var decision: PendingDecision = SimFixture.pending_for(sim, &"building_opportunity")
	assert_true(sim.resolve_decision(decision.id, &"build_explorers_hut"))
	var built: int = SimFixture.advance_until_built(sim, &"explorers_hut", DAY * 6)
	assert_gt(built, 0, "The hut gets built")


func _play_through_hut_and_exploration(sim: Simulation) -> void:
	_build_hut(sim)
	SimFixture.advance_until_pending(sim, &"curious_explorer", DAY * 10)
	var ask: PendingDecision = SimFixture.pending_for(sim, &"curious_explorer")
	if ask == null:
		return
	sim.resolve_decision(ask.id, &"encourage")
	SimFixture.advance_until_pending(sim, &"explorer_returns", DAY * 3)
	var found: PendingDecision = SimFixture.pending_for(sim, &"explorer_returns")
	if found != null:
		sim.resolve_decision(found.id, &"keep_it")
	sim.advance_ticks(DAY * 5)
