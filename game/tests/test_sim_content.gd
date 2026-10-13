extends McpTestSuite
## Authored content is consistent, and new worlds start the way the design says.


func suite_name() -> String:
	return "sim_content"


func test_content_validates() -> void:
	var problems: PackedStringArray = SimFixture.load_content().validate()
	assert_eq(problems.size(), 0, "Content problems: %s" % "; ".join(problems))


func test_validation_catches_broken_references() -> void:
	var content: ContentLibrary = SimFixture.load_content().duplicate(true)
	var broken: SimEffect = SimEffect.new()
	broken.kind = SimEffect.Kind.START_BUILD
	broken.key = &"does_not_exist"
	content.events[0].effects.append(broken)
	assert_gt(content.validate().size(), 0)


func test_starting_villagers_have_two_traits_each() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	assert_eq(content.starting_villagers.size(), 3)
	for villager: VillagerState in content.starting_villagers:
		assert_eq(villager.traits.size(), 2, "%s should have two traits" % villager.display_name)


func test_new_world_starts_at_dawn_with_a_founding_entry() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var config: SimConfig = sim.config
	assert_eq(config.hour_of(sim.world.tick), config.wake_hour)
	assert_eq(sim.world.journal.size(), 1)
	assert_eq(sim.world.resource_amount(&"wood"), 2)
	assert_eq(sim.world.villagers.size(), 3)


func test_worlds_do_not_share_villagers_with_the_content() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	var sim: Simulation = SimFixture.new_sim()
	sim.world.villagers[0].profession = &"changed"
	assert_eq(content.starting_villagers[0].profession, &"")
