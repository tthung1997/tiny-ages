extends McpTestSuite

const TURN: StringName = &"room_on_the_page"
const MEDIEVAL: Array[StringName] = [
	&"water_in_trust", &"guild_bench", &"charter_kept", &"common_book",
	&"fair_on_the_road", &"round_of_towns",
]
const MILESTONES: Array[StringName] = [
	&"first_impression", &"common_measure", &"wayfinder_sheet", &"open_demonstration",
	&"fair_of_pages", &"notebook_of_questions",
]


func suite_name() -> String:
	return "sim_renaissance"


func _start(era: StringName) -> Simulation:
	var sim: Simulation = SimFixture.new_sim()
	sim.advance_era(era)
	return sim


func test_both_turn_answers_work_without_medieval_flags_or_buildings() -> void:
	for answer: StringName in [&"share_pages", &"share_patterns"]:
		var sim: Simulation = _start(&"medieval")
		var era_steps: EraSystem = EraSystem.new()
		sim.world.achievements.append_array(MEDIEVAL.slice(0, -1))
		sim.world.tick = sim.world.era_started_tick + 8640
		era_steps.step(sim)
		assert_true(SimFixture.pending_for(sim, TURN) == null, "The sixth milestone matters")
		sim.world.achievements.append(&"round_of_towns")
		sim.world.tick -= 1
		era_steps.step(sim)
		assert_true(SimFixture.pending_for(sim, TURN) == null, "Five real days must pass")
		sim.world.tick += 1
		era_steps.step(sim)
		var turn: PendingDecision = SimFixture.pending_for(sim, TURN)
		assert_true(turn != null, "A legacy save without knowledge_shared can still turn")
		if turn == null:
			continue
		assert_eq(sim.world.era, &"medieval")
		assert_true(sim.resolve_decision(turn.id, answer))
		assert_eq(sim.world.era, &"renaissance")
		assert_eq(sim.world.era_started_tick, sim.world.tick)
		assert_true(sim.world.has_achievement(&"round_of_towns"))
		assert_eq(sim.world.has_flag(&"path_pages"), answer == &"share_pages")
		assert_eq(sim.world.has_flag(&"path_patterns"), answer == &"share_patterns")


func test_common_roads_can_wait_and_leave_the_age_open_ended() -> void:
	var sim: Simulation = _start(&"renaissance")
	var days: Array[int] = [60, 108, 162, 216, 270, 324]
	assert_false(WorldLayout.crossing_open(sim.world))
	for i: int in MILESTONES.size():
		var milestone: StringName = MILESTONES[i]
		var road: EventDef = sim.content.get_event(StringName("renaissance_%s_common" % milestone))
		sim.world.tick = sim.world.era_started_tick + days[i] * SimFixture.TICKS_PER_DAY - 1
		assert_false(SimCondition.all_met(road.requires, sim.world, sim.config, null))
		sim.world.tick += 1
		assert_true(SimCondition.all_met(road.requires, sim.world, sim.config, null))
		sim.fire_event(road, null)
		sim.advance_ticks(3 * SimFixture.TICKS_PER_DAY)
		var decision: PendingDecision = SimFixture.pending_for(sim, road.id)
		assert_true(decision != null, "%s can wait" % milestone)
		if decision == null:
			return
		assert_true(sim.resolve_decision(decision.id, road.choices[1].id))
		assert_true(sim.world.has_achievement(milestone))
	assert_true(sim.world.has_flag(&"observations_shared"))
	sim.world.tick = sim.world.era_started_tick + 8640
	EraSystem.new().step(sim)
	assert_eq(sim.world.era, &"renaissance")
	assert_true(sim.content.next_era(sim.world.era_order) == null)


func test_both_answers_on_every_road_and_early_route_flags() -> void:
	var early_days: Array[int] = [24, 72, 126, 180, 234, 288]
	var early_flags: Array[StringName] = [
		&"path_pages", &"path_circuit", &"path_patterns", &"guild_ribbon",
		&"path_commons", &"margin_drawings",
	]
	for i: int in MILESTONES.size():
		var milestone: StringName = MILESTONES[i]
		for suffix: StringName in [early_flags[i], &"common"]:
			for choice_index: int in 2:
				var sim: Simulation = _start(&"renaissance")
				sim.world.achievements.append_array(MILESTONES.slice(0, i))
				var id: StringName = StringName("renaissance_%s_%s" % [milestone, suffix])
				var road: EventDef = sim.content.get_event(id)
				var day: int = 324 if suffix == &"common" else early_days[i]
				sim.world.tick = sim.world.era_started_tick + day * SimFixture.TICKS_PER_DAY
				if suffix != &"common":
					assert_false(SimCondition.all_met(road.requires, sim.world, sim.config, null))
					sim.world.flags[suffix] = true
				assert_true(SimCondition.all_met(road.requires, sim.world, sim.config, null))
				sim.fire_event(road, null)
				var decision: PendingDecision = SimFixture.pending_for(sim, id)
				assert_true(decision != null, String(id))
				if decision == null:
					continue
				assert_true(sim.resolve_decision(decision.id, road.choices[choice_index].id))
				assert_true(sim.world.has_achievement(milestone))
				assert_false(SimCondition.all_met(road.requires, sim.world, sim.config, null))
				if milestone == &"notebook_of_questions":
					assert_true(sim.world.has_flag(&"observations_shared"))


func test_medieval_gate_is_the_same_online_and_away() -> void:
	var away: Simulation = _start(&"medieval")
	var present: Simulation = _start(&"medieval")
	for sim: Simulation in [away, present]:
		sim.world.tick = 8639
		sim.world.achievements.append_array(MEDIEVAL)
	var span: int = SimFixture.TICKS_PER_DAY
	var until: float = SimFixture.START_UNIX + away.config.seconds_per_tick() * float(span)
	away.advance_real_time(until)
	present.advance_ticks(span)
	assert_true(SimFixture.pending_for(away, TURN) != null)
	assert_eq(SimFixture.snapshot(away.world), SimFixture.snapshot(present.world))
