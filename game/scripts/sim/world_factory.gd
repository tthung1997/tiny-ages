class_name WorldFactory
extends RefCounted
## Builds a brand-new world from authored content.


static func create_new(
	content: ContentLibrary, config: SimConfig, rng_seed: int, now_unix: float
) -> WorldState:
	var world: WorldState = WorldState.new()
	world.rng_seed = rng_seed
	world.last_seen_unix = now_unix
	world.tick = config.tick_for_hour(config.wake_hour)
	for template: VillagerState in content.starting_villagers:
		world.villagers.append(template.duplicate(true))
	for key: StringName in content.starting_resources:
		world.resources[key] = content.starting_resources[key]
	var founded: JournalEntry = JournalEntry.new()
	founded.tick = world.tick
	founded.day = config.day_of(world.tick)
	founded.text = "The settlement was founded."
	founded.kind = &"settlement"
	world.journal.append(founded)
	return world
