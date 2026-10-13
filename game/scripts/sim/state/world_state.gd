class_name WorldState
extends Resource
## Everything that must survive a save and load. Pure data plus small accessors; the rules
## live in Simulation and its systems. Saved as a single resource (see SaveStore).

const SAVE_VERSION: int = 1

@export var save_version: int = SAVE_VERSION

@export_group("Time")
@export var tick: int = 0
## Fraction of a tick carried over between real-time updates.
@export var tick_fraction: float = 0.0
## Unix time of the last real-time update; drives offline catch-up.
@export var last_seen_unix: float = 0.0

@export_group("Randomness")
@export var rng_seed: int = 0
@export var rng_state: int = 0

@export_group("Era")
## Id of the current era and its `order`, kept together so conditions need no content lookup.
@export var era: StringName = &""
@export var era_order: int = 0
## Tick the current era began; the entry gate of the next era measures from here.
@export var era_started_tick: int = 0

@export_group("Stocks")
@export var resources: Dictionary[StringName, int] = {}
## Sub-unit production not yet converted into whole resources.
@export var resource_fraction: Dictionary[StringName, float] = {}
@export var inventory: Dictionary[StringName, int] = {}
@export var flags: Dictionary[StringName, bool] = {}

@export_group("Entities")
@export var villagers: Array[VillagerState] = []
@export var buildings: Array[BuildingState] = []
@export var plants: Array[PlantState] = []

@export_group("Story")
@export var scheduled: Array[ScheduledEvent] = []
@export var pending: Array[PendingDecision] = []
@export var journal: Array[JournalEntry] = []
@export var achievements: Array[StringName] = []
@export var event_counts: Dictionary[StringName, int] = {}
@export var event_last_tick: Dictionary[StringName, int] = {}
@export var last_decision_tick: int = -1000

@export var next_id: int = 1


func find_villager(villager_id: StringName) -> VillagerState:
	for villager: VillagerState in villagers:
		if villager.id == villager_id:
			return villager
	return null


func find_pending(decision_id: StringName) -> PendingDecision:
	for decision: PendingDecision in pending:
		if decision.id == decision_id:
			return decision
	return null


func resource_amount(key: StringName) -> int:
	return resources.get(key, 0)


## Adds to a resource, never dropping below zero.
func add_resource(key: StringName, amount: int) -> void:
	resources[key] = maxi(resource_amount(key) + amount, 0)


## Adds a fractional amount, banking the remainder until it makes a whole unit.
func add_resource_fraction(key: StringName, amount: float) -> void:
	var total: float = resource_fraction.get(key, 0.0) + amount
	var whole: int = floori(total)
	resource_fraction[key] = total - float(whole)
	if whole != 0:
		add_resource(key, whole)


func item_count(key: StringName) -> int:
	return inventory.get(key, 0)


func add_item(key: StringName, amount: int) -> void:
	inventory[key] = maxi(item_count(key) + amount, 0)


func has_flag(key: StringName) -> bool:
	return flags.get(key, false)


## Whether the settlement has fire. Fire is found, not given (docs/gameplay.md P6).
func has_fire() -> bool:
	return has_flag(&"fire_found")


func has_building(def_id: StringName) -> bool:
	for building: BuildingState in buildings:
		if building.complete and building.def_id == def_id:
			return true
	return false


## The building currently under construction, or null.
func constructing() -> BuildingState:
	for building: BuildingState in buildings:
		if not building.complete:
			return building
	return null


func has_achievement(key: StringName) -> bool:
	return achievements.has(key)


func new_id(prefix: String) -> StringName:
	var made: StringName = StringName("%s%d" % [prefix, next_id])
	next_id += 1
	return made
