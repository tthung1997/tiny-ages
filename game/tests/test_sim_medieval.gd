extends McpTestSuite

const TURN: StringName = &"what_we_keep_together"
const CLASSICAL: Array[StringName] = [
	&"paved_streets", &"water_from_afar", &"written_law", &"the_square",
	&"lamp_and_stage", &"wider_world",
]
const MILESTONES: Array[StringName] = [
	&"water_in_trust", &"guild_bench", &"charter_kept", &"common_book", &"fair_on_the_road",
	&"round_of_towns",
]


func suite_name() -> String:
	return "sim_medieval"


func _start(era: StringName) -> Simulation:
	var sim: Simulation = SimFixture.new_sim()
	sim.advance_era(era)
	return sim


func test_turn_preserves_classical_history_without_requiring_optional_flags() -> void:
	for choice_id: StringName in [&"name_the_commons", &"share_the_circuit"]:
		var sim: Simulation = _start(&"classical")
		var era_steps: EraSystem = EraSystem.new()
		sim.world.achievements.append_array(CLASSICAL.slice(0, -1))
		sim.world.tick = sim.world.era_started_tick + 8640
		era_steps.step(sim)
		assert_true(SimFixture.pending_for(sim, TURN) == null, "All six milestones are required")
		sim.world.achievements.append(&"wider_world")
		sim.world.tick -= 1
		era_steps.step(sim)
		assert_true(SimFixture.pending_for(sim, TURN) == null, "The turn waits five real days")
		sim.world.tick += 1
		var classical_story: EventDef = sim.content.get_event(&"a_book_for_the_journey")
		sim.fire_event(classical_story, null)
		era_steps.step(sim)
		var turn: PendingDecision = SimFixture.pending_for(sim, TURN)
		assert_true(turn != null, "The turn opens with no towns_connected flag")
		if turn == null:
			continue
		assert_eq(sim.world.era, &"classical", "Opening the question does not turn the age")
		assert_true(sim.resolve_decision(turn.id, choice_id))
		assert_eq(sim.world.era, &"medieval")
		assert_eq(sim.world.era_started_tick, sim.world.tick)
		assert_true(sim.world.achievements.has(&"wider_world"))
		assert_true(SimFixture.pending_for(sim, classical_story.id) == null)
		assert_eq(sim.world.has_flag(&"path_commons"), choice_id == &"name_the_commons")
		assert_eq(sim.world.has_flag(&"path_circuit"), choice_id == &"share_the_circuit")


func test_both_answers_to_every_road_earn_their_milestone() -> void:
	for event: EventDef in SimFixture.load_content().events:
		if not String(event.id).begins_with("medieval_") or not event.is_decision():
			continue
		for choice: ChoiceDef in event.choices:
			var milestone: StringName = &""
			for effect: SimEffect in choice.effects:
				if effect.kind == SimEffect.Kind.ACHIEVEMENT:
					milestone = effect.key
			if milestone == &"":
				continue # An optional story, not a milestone road.
			assert_true(MILESTONES.has(milestone))
			var sim: Simulation = _start(&"medieval")
			for key: StringName in MILESTONES:
				if key != milestone:
					sim.world.achievements.append(key)
			sim.world.tick = sim.world.era_started_tick + 324 * SimFixture.TICKS_PER_DAY
			for condition: SimCondition in event.requires:
				if condition.kind == SimCondition.Kind.FLAG_SET:
					sim.world.flags[condition.key] = true
			assert_true(SimCondition.all_met(event.requires, sim.world, sim.config, null))
			sim.fire_event(event, null)
			var decision: PendingDecision = SimFixture.pending_for(sim, event.id)
			assert_true(decision != null, String(event.id))
			if decision == null:
				continue
			assert_true(sim.resolve_decision(decision.id, choice.id))
			assert_true(sim.world.has_achievement(milestone), String(choice.id))
			if milestone == &"round_of_towns":
				assert_true(sim.world.has_flag(&"knowledge_shared"))


func test_common_roads_wait_without_a_crossing_or_any_inherited_answers() -> void:
	var sim: Simulation = _start(&"medieval")
	var days: Array[int] = [60, 108, 162, 216, 270, 324]
	for index: int in MILESTONES.size():
		var key: StringName = MILESTONES[index]
		var road: EventDef = sim.content.get_event(StringName("medieval_%s_common" % key))
		sim.world.tick = sim.world.era_started_tick + days[index] * SimFixture.TICKS_PER_DAY - 1
		assert_false(SimCondition.all_met(road.requires, sim.world, sim.config, null))
		sim.world.tick += 1
		assert_true(SimCondition.all_met(road.requires, sim.world, sim.config, null), String(key))
		sim.fire_event(road, null)
		sim.advance_ticks(SimFixture.TICKS_PER_DAY * 3)
		var decision: PendingDecision = SimFixture.pending_for(sim, road.id)
		assert_true(decision != null, "%s can wait" % key)
		if decision == null:
			return
		assert_true(sim.resolve_decision(decision.id, road.choices[1].id))
	assert_true(sim.world.has_flag(&"knowledge_shared"))
	assert_eq(sim.world.era, &"medieval")


func test_classical_gate_is_the_same_online_and_away() -> void:
	var away: Simulation = _start(&"classical")
	var present: Simulation = _start(&"classical")
	for sim: Simulation in [away, present]:
		sim.world.tick = 8639
		sim.world.achievements.append_array(CLASSICAL)
	var span: int = SimFixture.TICKS_PER_DAY
	var until: float = SimFixture.START_UNIX + away.config.seconds_per_tick() * float(span)
	away.advance_real_time(until)
	present.advance_ticks(span)
	assert_true(SimFixture.pending_for(away, TURN) != null)
	assert_eq(SimFixture.snapshot(away.world), SimFixture.snapshot(present.world))
