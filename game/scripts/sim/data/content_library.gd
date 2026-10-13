class_name ContentLibrary
extends Resource
## All authored simulation content: events, buildings, plants and the starting setup.

@export var events: Array[EventDef] = []
@export var buildings: Array[BuildingDef] = []
@export var plants: Array[PlantDef] = []
@export_group("Starting world")
## Templates; copied into each new world.
@export var starting_villagers: Array[VillagerState] = []
@export var starting_resources: Dictionary[StringName, int] = {}

var _event_index: Dictionary = {}
var _building_index: Dictionary = {}
var _plant_index: Dictionary = {}


func get_event(event_id: StringName) -> EventDef:
	if _event_index.size() != events.size():
		_event_index = _index_by_id(events)
	return _event_index.get(event_id)


func get_building(building_id: StringName) -> BuildingDef:
	if _building_index.size() != buildings.size():
		_building_index = _index_by_id(buildings)
	return _building_index.get(building_id)


func get_plant(plant_id: StringName) -> PlantDef:
	if _plant_index.size() != plants.size():
		_plant_index = _index_by_id(plants)
	return _plant_index.get(plant_id)


func plant_for_seed(seed_item: StringName) -> PlantDef:
	for plant: PlantDef in plants:
		if plant.seed_item == seed_item:
			return plant
	return null


## Returns a list of authoring problems; empty means the content is consistent.
func validate() -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	_check_unique_ids(events, "event", problems)
	_check_unique_ids(buildings, "building", problems)
	_check_unique_ids(plants, "plant", problems)
	for event: EventDef in events:
		var where: String = "event '%s'" % event.id
		if event.chance_per_tick <= 0.0 and not _is_scheduled_target(event.id):
			problems.append("%s never fires: zero chance and nothing schedules it" % where)
		if not event.is_decision() and event.effects.is_empty():
			problems.append("%s has no choices and no effects" % where)
		_check_conditions(event.requires, where, problems)
		_check_conditions(event.subject_requires, where, problems)
		_check_effects(event.effects, where, problems)
		var choice_ids: Dictionary = {}
		for choice: ChoiceDef in event.choices:
			if choice.id == &"" or choice_ids.has(choice.id):
				problems.append("%s has a missing or duplicate choice id '%s'" % [where, choice.id])
			choice_ids[choice.id] = true
			_check_conditions(choice.requires, "%s choice '%s'" % [where, choice.id], problems)
			_check_effects(choice.effects, "%s choice '%s'" % [where, choice.id], problems)
	for building: BuildingDef in buildings:
		if building.work_required <= 0:
			problems.append("building '%s' needs work_required > 0" % building.id)
	for plant: PlantDef in plants:
		if plant.seed_item == &"":
			problems.append("plant '%s' has no seed_item" % plant.id)
	for villager: VillagerState in starting_villagers:
		if villager.id == &"" or villager.display_name.is_empty():
			problems.append("a starting villager is missing an id or name")
	return problems


func _is_scheduled_target(event_id: StringName) -> bool:
	for event: EventDef in events:
		if _effects_schedule(event.effects, event_id):
			return true
		for choice: ChoiceDef in event.choices:
			if _effects_schedule(choice.effects, event_id):
				return true
	return false


func _effects_schedule(effects: Array[SimEffect], event_id: StringName) -> bool:
	for effect: SimEffect in effects:
		if effect.kind == SimEffect.Kind.SCHEDULE_EVENT and effect.key == event_id:
			return true
	return false


func _check_conditions(
	conditions: Array[SimCondition], where: String, problems: PackedStringArray
) -> void:
	for condition: SimCondition in conditions:
		if condition.kind == SimCondition.Kind.HAS_BUILDING and get_building(condition.key) == null:
			problems.append("%s requires unknown building '%s'" % [where, condition.key])


func _check_effects(
	effects: Array[SimEffect], where: String, problems: PackedStringArray
) -> void:
	for effect: SimEffect in effects:
		match effect.kind:
			SimEffect.Kind.START_BUILD:
				if get_building(effect.key) == null:
					problems.append("%s starts unknown building '%s'" % [where, effect.key])
			SimEffect.Kind.SCHEDULE_EVENT:
				if get_event(effect.key) == null:
					problems.append("%s schedules unknown event '%s'" % [where, effect.key])
				if effect.amount <= 0:
					problems.append("%s schedules '%s' with no delay" % [where, effect.key])
			SimEffect.Kind.PLANT:
				if plant_for_seed(effect.key) == null:
					problems.append("%s plants item '%s' that grows nothing" % [where, effect.key])
			SimEffect.Kind.JOURNAL, SimEffect.Kind.ACHIEVEMENT:
				if effect.text.is_empty():
					problems.append("%s has a %s effect without text" % [where, effect.kind])
			SimEffect.Kind.SEND_AWAY:
				if effect.amount <= 0 or effect.key == &"":
					problems.append("%s sends a villager away without a place or duration" % where)


func _check_unique_ids(items: Array, label: String, problems: PackedStringArray) -> void:
	var seen: Dictionary = {}
	for item: Resource in items:
		var item_id: StringName = item.get("id")
		if item_id == &"" or seen.has(item_id):
			problems.append("%s has a missing or duplicate id '%s'" % [label, item_id])
		seen[item_id] = true


func _index_by_id(items: Array) -> Dictionary:
	var index: Dictionary = {}
	for item: Resource in items:
		index[item.get("id")] = item
	return index
