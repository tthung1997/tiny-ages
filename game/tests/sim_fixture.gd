class_name SimFixture
extends RefCounted
## Shared helpers for simulation tests: build a seeded sim from the real content and step it.

const CONTENT_PATH: String = "res://resources/sim/content.tres"
const CONFIG_PATH: String = "res://resources/sim/sim_config.tres"
const START_UNIX: float = 1_700_000_000.0
const TICKS_PER_DAY: int = 24


static func load_content() -> ContentLibrary:
	return load(CONTENT_PATH) as ContentLibrary


static func load_config() -> SimConfig:
	return load(CONFIG_PATH) as SimConfig


static func new_sim(rng_seed: int = 1) -> Simulation:
	var config: SimConfig = load_config()
	var content: ContentLibrary = load_content()
	var world: WorldState = WorldFactory.create_new(content, config, rng_seed, START_UNIX)
	return Simulation.new(world, config, content)


## Steps one tick at a time until `predicate` is true. Returns ticks used, or -1 on timeout.
static func advance_until(sim: Simulation, predicate: Callable, max_ticks: int) -> int:
	for used: int in max_ticks:
		sim.advance_ticks(1)
		if predicate.call():
			return used + 1
	return -1


static func pending_for(sim: Simulation, event_id: StringName) -> PendingDecision:
	for decision: PendingDecision in sim.world.pending:
		if decision.event_id == event_id:
			return decision
	return null


static func advance_until_pending(sim: Simulation, event_id: StringName, max_ticks: int) -> int:
	return advance_until(
		sim, func() -> bool: return pending_for(sim, event_id) != null, max_ticks
	)


static func advance_until_flag(sim: Simulation, flag: StringName, max_ticks: int) -> int:
	return advance_until(sim, func() -> bool: return sim.world.has_flag(flag), max_ticks)


static func advance_until_built(sim: Simulation, building_id: StringName, max_ticks: int) -> int:
	return advance_until(
		sim, func() -> bool: return sim.world.has_building(building_id), max_ticks
	)


static func journal_index(world: WorldState, fragment: String) -> int:
	for index: int in world.journal.size():
		if world.journal[index].text.contains(fragment):
			return index
	return -1


## A comparable summary of a world, for asserting two worlds are in the same state.
static func snapshot(world: WorldState) -> Dictionary:
	var villagers: Array = []
	for villager: VillagerState in world.villagers:
		villagers.append([
			villager.id, villager.activity, villager.location, villager.profession,
			villager.activity_ticks_left, villager.away_until_tick,
		])
	var journal: Array = []
	for entry: JournalEntry in world.journal:
		journal.append("%d %s" % [entry.tick, entry.text])
	var pending: Array = []
	for decision: PendingDecision in world.pending:
		pending.append([decision.id, decision.event_id, decision.subject_id])
	return {
		"tick": world.tick,
		"fraction": world.tick_fraction,
		"resources": world.resources.duplicate(),
		"resource_fraction": world.resource_fraction.duplicate(),
		"inventory": world.inventory.duplicate(),
		"flags": world.flags.duplicate(),
		"villagers": villagers,
		"journal": journal,
		"pending": pending,
		"achievements": world.achievements.duplicate(),
		"buildings": world.buildings.size(),
		"plants": world.plants.size(),
		"rng_state": world.rng_state,
	}
