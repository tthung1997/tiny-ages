extends McpTestSuite
## The rules for what a decision is (docs/gameplay.md P13): it is only asked while at least
## two answers can be picked, it has no "pass" answer, and the economy does not pile up stock.

const DAY: int = SimFixture.TICKS_PER_DAY
## How many decisions still have the old "do it or pass" shape. It only ever goes down; the
## stages that convert the Cave and Settled decisions lower it until it reaches zero.
const MAX_UNCONVERTED: int = 68
const WOOD_CEILING: int = 100
const FOOD_CEILING: int = 250


func suite_name() -> String:
	return "decision_rules"


func _test_event(second_needs_wood: int) -> EventDef:
	var event: EventDef = EventDef.new()
	event.id = &"test_fork"
	event.title = "A fork"
	event.chance_per_tick = 1.0
	var left: ChoiceDef = ChoiceDef.new()
	left.id = &"left"
	var right: ChoiceDef = ChoiceDef.new()
	right.id = &"right"
	var need: SimCondition = SimCondition.new()
	need.kind = SimCondition.Kind.RESOURCE_AT_LEAST
	need.key = &"wood"
	need.amount = second_needs_wood
	right.requires.append(need)
	event.choices.append(left)
	event.choices.append(right)
	return event


func _sim_with(event: EventDef) -> Simulation:
	var sim: Simulation = SimFixture.new_sim()
	sim.content.events.clear()
	sim.content.events.append(event)
	sim.world.resources[&"wood"] = 0
	return sim


func test_a_decision_with_one_answer_left_is_not_asked() -> void:
	var sim: Simulation = _sim_with(_test_event(10))
	sim.advance_ticks(DAY * 3)
	assert_eq(sim.world.pending.size(), 0, "One answer is not a decision")


func test_a_decision_is_asked_once_two_answers_are_open() -> void:
	var sim: Simulation = _sim_with(_test_event(10))
	sim.world.resources[&"wood"] = 10
	sim.advance_ticks(DAY * 3)
	assert_eq(sim.world.pending.size(), 1)


func test_an_event_can_still_ask_with_a_single_answer_while_unconverted() -> void:
	var event: EventDef = _test_event(10)
	event.min_choices = 1
	var sim: Simulation = _sim_with(event)
	sim.advance_ticks(DAY * 3)
	assert_eq(sim.world.pending.size(), 1)


func test_new_decisions_default_to_needing_two_answers() -> void:
	assert_eq(EventDef.new().min_choices, 2)


func test_a_decision_already_asked_waits_when_stock_drops() -> void:
	var sim: Simulation = _sim_with(_test_event(10))
	sim.world.resources[&"wood"] = 10
	sim.advance_ticks(DAY)
	sim.world.resources[&"wood"] = 0
	sim.advance_ticks(DAY)
	assert_eq(sim.world.pending.size(), 1, "Waiting is never punished or withdrawn")


## A pass is an answer that changes nothing but the journal.
func _is_pass(choice: ChoiceDef) -> bool:
	for effect: SimEffect in choice.effects:
		if effect.kind != SimEffect.Kind.JOURNAL:
			return false
	return true


func test_converted_decisions_have_no_pass_answer() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	var problems: PackedStringArray = []
	for event: EventDef in content.events:
		if not event.is_decision() or event.min_choices < 2:
			continue
		var real: int = 0
		for choice: ChoiceDef in event.choices:
			if not _is_pass(choice):
				real += 1
		if real < 2:
			problems.append("%s needs two answers that each do something" % event.id)
	assert_eq(problems.size(), 0, ", ".join(problems))


func test_the_unconverted_decisions_only_shrink() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	var unconverted: int = 0
	for event: EventDef in content.events:
		if event.is_decision() and event.min_choices < 2:
			unconverted += 1
	assert_true(
		unconverted <= MAX_UNCONVERTED,
		"%d decisions still allow one answer (limit %d)" % [unconverted, MAX_UNCONVERTED]
	)


func test_stock_does_not_pile_up_over_a_long_game() -> void:
	var sim: Simulation = SimFixture.new_sim(1, false)
	var bot: DecisionBot = DecisionBot.new()
	var most_wood: int = 0
	var most_food: int = 0
	for _tick: int in DAY * 700:
		sim.advance_ticks(1)
		bot.answer_all(sim)
		most_wood = maxi(most_wood, sim.world.resource_amount(&"wood"))
		most_food = maxi(most_food, sim.world.resource_amount(&"food"))
	assert_true(most_wood <= WOOD_CEILING, "Wood peaked at %d" % most_wood)
	assert_true(most_food <= FOOD_CEILING, "Food peaked at %d" % most_food)
