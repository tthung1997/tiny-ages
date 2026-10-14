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
signal villager_joined(villager: VillagerState)
signal achievement_earned(key: StringName, title: String)

var world: WorldState
var config: SimConfig
var content: ContentLibrary
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _villager_system: VillagerSystem = VillagerSystem.new()
var _construction_system: ConstructionSystem = ConstructionSystem.new()
var _plant_system: PlantSystem = PlantSystem.new()
var _event_system: EventSystem = EventSystem.new()
var _era_system: EraSystem = EraSystem.new()
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
	withdraw_stale_decisions()
	decision_resolved.emit(decision, choice)
	return true


## Whether the world has moved past a pending decision: its event's requirements no longer hold,
## ignoring stock and construction (an unaffordable choice just waits, greyed out) and "not yet"
## conditions such as a day or an age (they only ever turn true). The fire was lit another way,
## the tools were found another way... so the question no longer makes sense.
func is_decision_stale(decision: PendingDecision) -> bool:
	var event: EventDef = content.get_event(decision.event_id)
	if event == null:
		return true
	for condition: SimCondition in event.requires:
		var not_yet: bool = not condition.negate and (
			condition.kind == SimCondition.Kind.DAYS_AT_LEAST
			or condition.kind == SimCondition.Kind.ERA_AT_LEAST
		)
		var transient: bool = not_yet \
				or condition.kind == SimCondition.Kind.RESOURCE_AT_LEAST \
				or condition.kind == SimCondition.Kind.ITEM_AT_LEAST \
				or condition.kind == SimCondition.Kind.CONSTRUCTION_IDLE
		if not transient and not condition.is_met(world, config):
			return true
	return false


## Drops every pending decision the world has moved past.
func withdraw_stale_decisions() -> void:
	for decision: PendingDecision in world.pending.duplicate():
		if is_decision_stale(decision):
			world.pending.erase(decision)


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
	if def.completion_flag != &"":
		world.flags[def.completion_flag] = true
	if def.completion_achievement != &"":
		grant_achievement(def.completion_achievement, def.completion_achievement_title)
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
	world.era_started_tick = world.tick
	var line: String = next.intro_text
	if line.is_empty():
		line = "A new age began: %s." % next.display_name
	add_journal(line, &"settlement", &"", &"")
	era_advanced.emit(next)
	return true


## Whether the hidden entry gate of `era` is open: it is the next age, its required achievements
## are all earned and the settlement has spent long enough in the current one.
func era_gate_open(era: EraDef) -> bool:
	if era == null or era.order <= world.era_order:
		return false
	if world.tick - world.era_started_tick < era.min_ticks_in_previous_era:
		return false
	for key: StringName in era.required_achievements:
		if not world.has_achievement(key):
			return false
	return true


## A newcomer joins the group: an unused name from the content pool, random traits, and a look
## reused in turn. Uses the simulation's rng, so it stays reproducible.
func add_villager() -> VillagerState:
	var used: Dictionary = {}
	for existing: VillagerState in world.villagers:
		used[existing.id] = true
	var free: Array[String] = []
	for candidate: String in content.villager_names:
		if not used.has(StringName(candidate.to_lower())):
			free.append(candidate)
	var villager: VillagerState = VillagerState.new()
	if free.is_empty():
		villager.display_name = "Newcomer %d" % (world.villagers.size() + 1)
	else:
		villager.display_name = free[rng.randi_range(0, free.size() - 1)]
	villager.id = StringName(villager.display_name.to_lower().replace(" ", "_"))
	if not content.villager_looks.is_empty():
		var looks: Array[StringName] = content.villager_looks
		villager.look = looks[world.villagers.size() % looks.size()]
	var pool: Array[int] = SimRandom.shuffled_indices(rng, content.villager_traits.size())
	for pick: int in mini(content.traits_per_villager, pool.size()):
		villager.traits.append(content.villager_traits[pool[pick]])
	world.villagers.append(villager)
	add_journal("%s joined the group." % villager.display_name, &"settlement", &"", villager.id)
	villager_joined.emit(villager)
	return villager


func grant_achievement(key: StringName, title: String) -> void:
	if world.has_achievement(key):
		return
	world.achievements.append(key)
	world.achievement_titles[key] = title
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
	_era_system.step(self)
	withdraw_stale_decisions()
