extends McpTestSuite

const TURN: StringName = &"two_reports_one_question"
const RENAISSANCE: Array[StringName] = [
	&"first_impression", &"common_measure", &"wayfinder_sheet", &"open_demonstration",
	&"fair_of_pages", &"notebook_of_questions",
]
const MILESTONES: Array[StringName] = [
	&"two_reports", &"rule_that_agrees", &"method_in_other_hands", &"a_fair_trial",
	&"correction_in_the_open", &"pattern_that_travels",
]
const EARLY_DAYS: Array[int] = [24, 72, 126, 180, 234, 288]
const COMMON_DAYS: Array[int] = [60, 108, 162, 216, 270, 324]


func suite_name() -> String:
	return "sim_enlightenment"


func _start(era: StringName) -> Simulation:
	var sim: Simulation = SimFixture.new_sim()
	sim.advance_era(era)
	return sim


func _road(sim: Simulation, milestone: StringName, suffix: StringName) -> EventDef:
	return sim.content.get_event(StringName("enlightenment_%s_%s" % [milestone, suffix]))


func test_either_turn_answer_works_on_the_exact_gate_in_a_legacy_save() -> void:
	for answer: StringName in [&"repeat_here", &"ask_neighbours"]:
		var sim: Simulation = _start(&"renaissance")
		var era_steps: EraSystem = EraSystem.new()
		sim.world.tick = sim.world.era_started_tick + 8640
		sim.world.achievements.append_array(RENAISSANCE.slice(0, -1))
		era_steps.step(sim)
		assert_true(SimFixture.pending_for(sim, TURN) == null, "All six are needed")
		sim.world.achievements.append(&"notebook_of_questions")
		sim.world.tick -= 1
		era_steps.step(sim)
		assert_true(SimFixture.pending_for(sim, TURN) == null, "Five real days are needed")
		sim.world.tick += 1
		era_steps.step(sim)
		var decision: PendingDecision = SimFixture.pending_for(sim, TURN)
		assert_true(decision != null, "The observations_shared flag is not a gate")
		if decision == null:
			continue
		assert_eq(sim.world.era, &"renaissance", "The world waits for an answer")
		assert_true(sim.resolve_decision(decision.id, answer))
		assert_eq(sim.world.era, &"enlightenment")
		assert_eq(sim.world.era_started_tick, sim.world.tick)
		assert_eq(sim.world.has_flag(&"repeat_here"), answer == &"repeat_here")
		assert_eq(sim.world.has_flag(&"ask_neighbours"), answer == &"ask_neighbours")


func test_common_roads_wait_and_hand_off_without_any_optional_content() -> void:
	var sim: Simulation = _start(&"enlightenment")
	for i: int in MILESTONES.size():
		var road: EventDef = _road(sim, MILESTONES[i], &"common")
		sim.world.tick = sim.world.era_started_tick + COMMON_DAYS[i] * SimFixture.TICKS_PER_DAY - 1
		assert_false(SimCondition.all_met(road.requires, sim.world, sim.config, null))
		sim.world.tick += 1
		assert_true(SimCondition.all_met(road.requires, sim.world, sim.config, null))
		sim.fire_event(road, null)
		sim.advance_ticks(3 * SimFixture.TICKS_PER_DAY)
		var decision: PendingDecision = SimFixture.pending_for(sim, road.id)
		assert_true(decision != null, "%s does not expire" % road.id)
		if decision == null:
			return
		assert_true(sim.resolve_decision(decision.id, road.choices[0].id))
		assert_true(sim.world.has_achievement(MILESTONES[i]))
		assert_eq(sim.world.has_flag(&"methods_shared"), i == MILESTONES.size() - 1)
	assert_true(sim.world.buildings.is_empty())
	assert_false(WorldLayout.crossing_open(sim.world))
	sim.world.tick = sim.world.era_started_tick + 8640
	EraSystem.new().step(sim)
	assert_eq(sim.world.era, &"enlightenment")
	assert_true(sim.content.next_era(sim.world.era_order) == null)


func test_both_answers_on_each_road_earn_the_milestone() -> void:
	var flags: Array[Array] = [
		[&"repeat_here", &"ask_neighbours"], [&"path_pages"], [&"guild_ribbon"],
		[&"margin_drawings"], [&"path_patterns"], [&"path_circuit"],
	]
	for i: int in MILESTONES.size():
		var suffixes: Array[StringName] = [&"common"]
		suffixes.append_array(flags[i])
		for suffix: StringName in suffixes:
			for choice_index: int in 2:
				var sim: Simulation = _start(&"enlightenment")
				var road: EventDef = _road(sim, MILESTONES[i], suffix)
				var common: bool = suffix == &"common"
				var day: int = COMMON_DAYS[i] if common else EARLY_DAYS[i]
				sim.world.tick = sim.world.era_started_tick + day * SimFixture.TICKS_PER_DAY
				if not common:
					sim.world.flags[suffix] = true
				if i > 0:
					assert_false(SimCondition.all_met(road.requires, sim.world, sim.config, null))
				sim.world.achievements.append_array(MILESTONES.slice(0, i))
				if not common:
					sim.world.flags.erase(suffix)
					assert_false(SimCondition.all_met(road.requires, sim.world, sim.config, null))
					sim.world.flags[suffix] = true
				assert_true(SimCondition.all_met(road.requires, sim.world, sim.config, null))
				sim.fire_event(road, null)
				var decision: PendingDecision = SimFixture.pending_for(sim, road.id)
				assert_true(decision != null, String(road.id))
				if decision == null:
					continue
				assert_true(sim.resolve_decision(decision.id, road.choices[choice_index].id))
				assert_true(sim.world.has_achievement(MILESTONES[i]))
				assert_false(SimCondition.all_met(road.requires, sim.world, sim.config, null))
				assert_eq(sim.world.has_flag(&"methods_shared"), i == MILESTONES.size() - 1)


func test_time_away_opens_the_same_turn_without_answering_it() -> void:
	var away: Simulation = _start(&"renaissance")
	var present: Simulation = _start(&"renaissance")
	for sim: Simulation in [away, present]:
		sim.world.tick = 8639
		sim.world.achievements.append_array(RENAISSANCE)
	var span: int = SimFixture.TICKS_PER_DAY
	away.advance_real_time(SimFixture.START_UNIX + away.config.seconds_per_tick() * float(span))
	present.advance_ticks(span)
	assert_true(SimFixture.pending_for(away, TURN) != null)
	assert_eq(away.world.era, &"renaissance")
	assert_eq(SimFixture.snapshot(away.world), SimFixture.snapshot(present.world))
