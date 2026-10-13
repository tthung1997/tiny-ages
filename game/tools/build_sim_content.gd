extends SceneTree
## Bootstrap for the simulation's first-slice content. Writes the config and content library
## under res://resources/sim/. Run once with:
##   & $env:GODOT --headless --path game --script res://tools/build_sim_content.gd
## The generated .tres files are ordinary resources: after this, edit them in the Godot
## inspector. Re-running overwrites them, so treat this script as a seed, not the source of truth.

const ROOT: String = "res://resources/sim"


func _init() -> void:
	for folder: String in ["events", "buildings", "plants"]:
		var path: String = ProjectSettings.globalize_path("%s/%s" % [ROOT, folder])
		DirAccess.make_dir_recursive_absolute(path)
	_save(SimConfig.new(), "%s/sim_config.tres" % ROOT)

	var library: ContentLibrary = ContentLibrary.new()
	library.buildings.assign(_buildings())
	library.plants.assign(_plants())
	library.events.assign(_events())
	library.starting_villagers.assign(_villagers())
	library.starting_resources = _ints({&"wood": 2, &"food": 4})
	for building: BuildingDef in library.buildings:
		_save(building, "%s/buildings/%s.tres" % [ROOT, building.id])
	for plant: PlantDef in library.plants:
		_save(plant, "%s/plants/%s.tres" % [ROOT, plant.id])
	for event: EventDef in library.events:
		_save(event, "%s/events/%s.tres" % [ROOT, event.id])
	_save(library, "%s/content.tres" % ROOT)

	var problems: PackedStringArray = library.validate()
	for problem: String in problems:
		push_error("Content problem: %s" % problem)
	print("Wrote simulation content (%d problems)." % problems.size())
	quit(1 if not problems.is_empty() else 0)


func _villagers() -> Array[VillagerState]:
	var theo_traits: Array[StringName] = [
		VillagerState.TRAIT_CURIOUS, VillagerState.TRAIT_NATURE_LOVING,
	]
	return [
		_villager(&"mira", "Mira", [VillagerState.TRAIT_INDUSTRIOUS, VillagerState.TRAIT_SOCIAL]),
		_villager(&"theo", "Theo", theo_traits),
		_villager(&"wren", "Wren", [VillagerState.TRAIT_SOCIAL, VillagerState.TRAIT_NATURE_LOVING]),
	]


func _buildings() -> Array[BuildingDef]:
	var farm: BuildingDef = _building(&"farm", "Farm", {&"wood": 6}, 30)
	farm.description = "Fields that feed the settlement."
	farm.daily_output = _floats({&"food": 6.0})
	var hut: BuildingDef = _building(&"explorers_hut", "Explorer's Hut", {&"wood": 6}, 36)
	hut.description = "A base for those who want to see what lies beyond the camp."
	var workshop: BuildingDef = _building(&"workshop", "Workshop", {&"wood": 8}, 40)
	workshop.description = "A place to make things that last."
	workshop.daily_output = _floats({&"wood": 4.0})
	return [farm, hut, workshop]


func _plants() -> Array[PlantDef]:
	var flower: PlantDef = PlantDef.new()
	flower.id = &"strange_flower"
	flower.display_name = "Strange flower"
	flower.seed_item = &"strange_seed"
	flower.ticks_to_flower = 72
	flower.flower_text = "The strange seed flowered beside the camp."
	flower.flower_flag = &"strange_flower_bloomed"
	flower.flower_achievement = &"unexpected_garden"
	flower.flower_achievement_title = "Unexpected Garden"
	return [flower]


func _events() -> Array[EventDef]:
	return [
		_building_opportunity(),
		_curious_explorer(),
		_explorer_returns(),
		_seed_in_jar(),
		_rare_butterfly(),
		_heavy_rain(),
	]


func _building_opportunity() -> EventDef:
	var event: EventDef = _event(&"building_opportunity", "Ready to build", &"settlement")
	event.body = "The settlement has gathered enough to build something new."
	event.requires = _conds([
		_cond(SimCondition.Kind.CONSTRUCTION_IDLE),
		_cond(SimCondition.Kind.RESOURCE_AT_LEAST, &"wood", 6),
	])
	event.chance_per_tick = 0.5
	event.cooldown_ticks = 24
	event.choices = _choices([
		_build_choice(&"build_explorers_hut", "Explorer's Hut", &"explorers_hut", 6),
		_build_choice(&"build_farm", "Farm", &"farm", 6),
		_build_choice(&"build_workshop", "Workshop", &"workshop", 8),
	])
	return event


func _curious_explorer() -> EventDef:
	var event: EventDef = _event(&"curious_explorer", "A curious explorer", &"exploration")
	event.body = "{subject} is curious about the forest to the east and asks to explore it."
	event.requires = _conds([
		_cond(SimCondition.Kind.HAS_BUILDING, &"explorers_hut"),
		_cond(SimCondition.Kind.FLAG_SET, &"forest_east_explored", 0, true),
	])
	event.needs_subject = true
	event.subject_requires = _conds([
		_cond(SimCondition.Kind.SUBJECT_HAS_TRAIT, VillagerState.TRAIT_CURIOUS),
		_cond(SimCondition.Kind.SUBJECT_AT_HOME),
	])
	event.chance_per_tick = 0.06
	event.cooldown_ticks = 72
	var go: ChoiceDef = _choice(&"encourage", "Encourage exploration")
	go.effects = _effs([
		_eff(SimEffect.Kind.SET_PROFESSION, &"explorer"),
		_eff(SimEffect.Kind.SEND_AWAY, &"forest_east", 36),
		_eff(SimEffect.Kind.SCHEDULE_EVENT, &"explorer_returns", 36),
		_eff(SimEffect.Kind.JOURNAL, &"", 0, "{subject} set off to explore the eastern forest."),
	])
	event.choices = _choices([go, _choice(&"remain", "Ask them to remain")])
	return event


func _explorer_returns() -> EventDef:
	var event: EventDef = _event(&"explorer_returns", "An explorer returns", &"exploration")
	event.body = "{subject} is back from the forest, carrying something unfamiliar."
	event.needs_subject = true
	event.effects = _effs([
		_eff(SimEffect.Kind.ADD_ITEM, &"strange_seed", 1),
		_eff(SimEffect.Kind.SET_FLAG, &"forest_east_explored"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} returned from the eastern forest carrying an unfamiliar seed."
		),
	])
	var plant: ChoiceDef = _choice(&"plant_it", "Plant it")
	plant.requires = _conds([_cond(SimCondition.Kind.ITEM_AT_LEAST, &"strange_seed", 1)])
	plant.effects = _effs([
		_eff(SimEffect.Kind.PLANT, &"strange_seed"),
		_eff(SimEffect.Kind.JOURNAL, &"", 0, "{subject} planted the strange seed beside the camp."),
	])
	var keep: ChoiceDef = _choice(&"keep_it", "Keep it safe")
	keep.effects = _effs([
		_eff(SimEffect.Kind.JOURNAL, &"", 0, "The strange seed was put in a jar for safekeeping."),
	])
	event.choices = _choices([plant, keep])
	return event


func _seed_in_jar() -> EventDef:
	var event: EventDef = _event(&"seed_in_jar", "The seed in the jar", &"exploration")
	event.body = "The strange seed in its jar looks ready to be planted."
	event.requires = _conds([_cond(SimCondition.Kind.ITEM_AT_LEAST, &"strange_seed", 1)])
	event.chance_per_tick = 0.01
	event.cooldown_ticks = 96
	var plant: ChoiceDef = _choice(&"plant_it", "Plant it")
	plant.effects = _effs([
		_eff(SimEffect.Kind.PLANT, &"strange_seed"),
		_eff(SimEffect.Kind.JOURNAL, &"", 0, "The strange seed was planted at last."),
	])
	event.choices = _choices([plant, _choice(&"wait", "Wait a while longer")])
	return event


func _rare_butterfly() -> EventDef:
	var event: EventDef = _event(&"rare_butterfly", "A rare visitor", &"nature")
	event.requires = _conds([
		_cond(SimCondition.Kind.FLAG_SET, &"strange_flower_bloomed"),
		_cond(SimCondition.Kind.FLAG_SET, &"butterfly_seen", 0, true),
	])
	event.chance_per_tick = 0.02
	event.once = true
	event.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"butterfly_seen"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"A butterfly nobody had seen before landed on the strange flower."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"rare_visitor", 0, "A Rare Visitor"),
	])
	return event


func _heavy_rain() -> EventDef:
	var event: EventDef = _event(&"heavy_rain", "Heavy rain", &"nature")
	event.chance_per_tick = 0.004
	event.cooldown_ticks = 120
	event.effects = _effs([
		_eff(SimEffect.Kind.JOURNAL, &"", 0, "It rained heavily for most of the afternoon."),
	])
	return event


func _build_choice(
	choice_id: StringName, label: String, building: StringName, wood: int
) -> ChoiceDef:
	var choice: ChoiceDef = _choice(choice_id, label)
	choice.requires = _conds([
		_cond(SimCondition.Kind.HAS_BUILDING, building, 0, true),
		_cond(SimCondition.Kind.RESOURCE_AT_LEAST, &"wood", wood),
	])
	choice.effects = _effs([_eff(SimEffect.Kind.START_BUILD, building)])
	return choice


func _villager(
	villager_id: StringName, display_name: String, traits: Array[StringName]
) -> VillagerState:
	var villager: VillagerState = VillagerState.new()
	villager.id = villager_id
	villager.display_name = display_name
	villager.traits = traits
	return villager


func _building(
	building_id: StringName, display_name: String, cost: Dictionary, work_required: int
) -> BuildingDef:
	var building: BuildingDef = BuildingDef.new()
	building.id = building_id
	building.display_name = display_name
	building.cost = _ints(cost)
	building.work_required = work_required
	return building


func _event(event_id: StringName, title: String, category: StringName) -> EventDef:
	var event: EventDef = EventDef.new()
	event.id = event_id
	event.title = title
	event.category = category
	return event


func _choice(choice_id: StringName, label: String) -> ChoiceDef:
	var choice: ChoiceDef = ChoiceDef.new()
	choice.id = choice_id
	choice.label = label
	return choice


func _cond(
	kind: SimCondition.Kind, key: StringName = &"", amount: int = 0, negate: bool = false
) -> SimCondition:
	var condition: SimCondition = SimCondition.new()
	condition.kind = kind
	condition.key = key
	condition.amount = amount
	condition.negate = negate
	return condition


func _eff(
	kind: SimEffect.Kind, key: StringName = &"", amount: int = 0, text: String = ""
) -> SimEffect:
	var effect: SimEffect = SimEffect.new()
	effect.kind = kind
	effect.key = key
	effect.amount = amount
	effect.text = text
	return effect


func _conds(items: Array[SimCondition]) -> Array[SimCondition]:
	return items


func _effs(items: Array[SimEffect]) -> Array[SimEffect]:
	return items


func _choices(items: Array[ChoiceDef]) -> Array[ChoiceDef]:
	return items


func _ints(pairs: Dictionary) -> Dictionary[StringName, int]:
	var typed: Dictionary[StringName, int] = {}
	for key: StringName in pairs:
		typed[key] = int(pairs[key])
	return typed


func _floats(pairs: Dictionary) -> Dictionary[StringName, float]:
	var typed: Dictionary[StringName, float] = {}
	for key: StringName in pairs:
		typed[key] = float(pairs[key])
	return typed


func _save(resource: Resource, path: String) -> void:
	var error: Error = ResourceSaver.save(resource, path, ResourceSaver.FLAG_CHANGE_PATH)
	if error != OK:
		push_error("Could not save %s (error %d)" % [path, error])
