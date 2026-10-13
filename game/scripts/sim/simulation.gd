class_name Simulation
extends RefCounted
## Runs the settlement. Owns the rules and one seeded rng; the WorldState it drives is plain
## data. No rendering, no scene tree: the view only reads the world and calls the public
## methods, so everything here runs headless and is reproducible from a seed.
##
## Time passes in ticks. `advance_ticks` is exact and deterministic; `advance_real_time` turns
## wall-clock time into ticks, which is also how offline catch-up works.

signal journal_added(entry: JournalEntry)
signal decision_opened(decision: PendingDecision)
signal decision_resolved(decision: PendingDecision, choice: ChoiceDef)
signal building_started(building: BuildingState)
signal building_completed(building: BuildingState)
signal era_advanced(era: EraDef)
signal achievement_earned(key: StringName, title: String)

var world: WorldState
var config: SimConfig
var content: ContentLibrary
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _villager_system: VillagerSystem = VillagerSystem.new()
var _construction_system: ConstructionSystem = ConstructionSystem.new()
var _plant_system: PlantSystem = PlantSystem.new()
var _event_system: EventSystem = EventSystem.new()
var _effects: EffectRunner = EffectRunner.new()


func _init(p_world: WorldState, p_config: SimConfig, p_content: ContentLibrary) -> void:
	world = p_world
	config = p_config
	content = p_content
	rng.seed = world.rng_seed
	if world.rng_state != 0:
		rng.state = world.rng_state


## Advances the world by exactly `count` ticks.
func advance_ticks(count: int) -> void:
	for _step_index: int in count:
		_step()
	world.rng_state = rng.state


## Advances by real elapsed time. After being away this is the catch-up: the same ticks that
## would have happened, simulated in one go, capped at SimConfig.max_catch_up_ticks.
func advance_real_time(now_unix: float) -> CatchUpReport:
	var report: CatchUpReport = CatchUpReport.new()
	if world.last_seen_unix <= 0.0:
		world.last_seen_unix = now_unix
	report.elapsed_seconds = maxf(now_unix - world.last_seen_unix, 0.0)
	world.last_seen_unix = now_unix
	var exact: float = report.elapsed_seconds / config.seconds_per_tick() + world.tick_fraction
	var ticks: int = floori(exact)
	world.tick_fraction = exact - float(ticks)
	if ticks > config.max_catch_up_ticks:
		report.ticks_dropped = ticks - config.max_catch_up_ticks
		ticks = config.max_catch_up_ticks
	report.ticks_simulated = ticks
	var journal_before: int = world.journal.size()
	var decisions_before: Array[PendingDecision] = world.pending.duplicate()
	advance_ticks(ticks)
	report.journal_entries.assign(world.journal.slice(journal_before))
	for decision: PendingDecision in world.pending:
		if not decisions_before.has(decision):
			report.decisions_opened.append(decision)
	return report


## Fires an event now: applies its effects and, if it has choices, opens a decision.
func fire_event(event: EventDef, subject: VillagerState) -> void:
	world.event_counts[event.id] = world.event_counts.get(event.id, 0) + 1
	world.event_last_tick[event.id] = world.tick
	for effect: SimEffect in event.effects:
		_effects.apply(effect, self, subject, event)
	if not event.is_decision():
		return
	var decision: PendingDecision = PendingDecision.new()
	decision.id = world.new_id("decision_")
	decision.event_id = event.id
	decision.subject_id = subject.id if subject != null else &""
	decision.opened_tick = world.tick
	world.pending.append(decision)
	world.last_decision_tick = world.tick
	decision_opened.emit(decision)


func choice_available(choice: ChoiceDef, subject: VillagerState) -> bool:
	return SimCondition.all_met(choice.requires, world, config, subject)


## Applies the player's choice. Returns false, changing nothing, if the decision or choice is
## unknown or the choice's requirements no longer hold.
func resolve_decision(decision_id: StringName, choice_id: StringName) -> bool:
	var decision: PendingDecision = world.find_pending(decision_id)
	if decision == null:
		return false
	var event: EventDef = content.get_event(decision.event_id)
	if event == null:
		push_error("Decision references unknown event '%s'" % decision.event_id)
		return false
	var choice: ChoiceDef = event.get_choice(choice_id)
	var subject: VillagerState = world.find_villager(decision.subject_id)
	if choice == null or not choice_available(choice, subject):
		return false
	world.pending.erase(decision)
	for effect: SimEffect in choice.effects:
		_effects.apply(effect, self, subject, event)
	decision_resolved.emit(decision, choice)
	return true


## Spends the building's cost and starts construction. False if it cannot start right now.
func start_building(def_id: StringName) -> bool:
	var def: BuildingDef = content.get_building(def_id)
	if def == null or world.constructing() != null:
		return false
	for key: StringName in def.cost:
		if world.resource_amount(key) < def.cost[key]:
			return false
	for key: StringName in def.cost:
		world.add_resource(key, -def.cost[key])
	var site: BuildingState = BuildingState.new()
	site.id = world.new_id("building_")
	site.def_id = def_id
	site.started_tick = world.tick
	world.buildings.append(site)
	add_journal("Construction of the %s began." % def.display_name, &"settlement", &"", &"")
	building_started.emit(site)
	return true


func complete_building(site: BuildingState) -> void:
	site.complete = true
	site.completed_tick = world.tick
	var def: BuildingDef = content.get_building(site.def_id)
	add_journal("The %s was completed." % def.display_name, &"settlement", &"", &"")
	building_completed.emit(site)


## Plants one `seed_item` from the inventory. False if there is none or it grows nothing.
func plant_seed(seed_item: StringName) -> bool:
	var def: PlantDef = content.plant_for_seed(seed_item)
	if def == null or world.item_count(seed_item) < 1:
		return false
	world.add_item(seed_item, -1)
	var plant: PlantState = PlantState.new()
	plant.id = world.new_id("plant_")
	plant.def_id = def.id
	plant.planted_tick = world.tick
	world.plants.append(plant)
	return true


## Moves the settlement into a later era. False if the era is unknown or not later than the
## current one: ages only move forward.
func advance_era(era_id: StringName) -> bool:
	var next: EraDef = content.get_era(era_id)
	if next == null or next.order <= world.era_order:
		return false
	world.era = next.id
	world.era_order = next.order
	var line: String = next.intro_text
	if line.is_empty():
		line = "A new age began: %s." % next.display_name
	add_journal(line, &"settlement", &"", &"")
	era_advanced.emit(next)
	return true


func grant_achievement(key: StringName, title: String) -> void:
	if world.has_achievement(key):
		return
	world.achievements.append(key)
	add_journal("Achievement: %s" % title, &"settlement", &"", &"")
	achievement_earned.emit(key, title)


func add_journal(
	text: String, kind: StringName, event_id: StringName, subject_id: StringName
) -> void:
	var entry: JournalEntry = JournalEntry.new()
	entry.tick = world.tick
	entry.day = config.day_of(world.tick)
	entry.text = text
	entry.kind = kind
	entry.event_id = event_id
	entry.subject_id = subject_id
	world.journal.append(entry)
	journal_added.emit(entry)


func _step() -> void:
	world.tick += 1
	_villager_system.step(self)
	_construction_system.step(self)
	_plant_system.step(self)
	_event_system.step(self)
