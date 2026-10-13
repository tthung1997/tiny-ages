class_name SimCondition
extends Resource
## One yes/no test about the world, used to gate events and choices. Authored as data so
## designers can compose requirements in the inspector.

enum Kind {
	## Append new kinds at the end: saved .tres content stores the integer value.
	HAS_BUILDING, ## `key` is a completed building id.
	FLAG_SET, ## `key` is a world flag.
	RESOURCE_AT_LEAST, ## `key` resource holds at least `amount`.
	ITEM_AT_LEAST, ## `key` item holds at least `amount`.
	CONSTRUCTION_IDLE, ## Nothing is currently being built.
	DAYS_AT_LEAST, ## The settlement is at least `amount` days old.
	SUBJECT_HAS_TRAIT, ## The event's subject villager has trait `key`.
	SUBJECT_AT_HOME, ## The event's subject villager is not away.
	ERA_AT_LEAST, ## The settlement's era `order` is at least `amount`.
	ACHIEVEMENT_EARNED, ## Achievement `key` has been earned.
}

@export var kind: Kind = Kind.FLAG_SET
@export var key: StringName = &""
@export var amount: int = 0
## Invert the result.
@export var negate: bool = false


func is_met(world: WorldState, config: SimConfig, subject: VillagerState = null) -> bool:
	var subject_kind: bool = kind == Kind.SUBJECT_HAS_TRAIT or kind == Kind.SUBJECT_AT_HOME
	if subject_kind and subject == null:
		return false
	var result: bool = false
	match kind:
		Kind.HAS_BUILDING:
			result = world.has_building(key)
		Kind.FLAG_SET:
			result = world.has_flag(key)
		Kind.RESOURCE_AT_LEAST:
			result = world.resource_amount(key) >= amount
		Kind.ITEM_AT_LEAST:
			result = world.item_count(key) >= amount
		Kind.CONSTRUCTION_IDLE:
			result = world.constructing() == null
		Kind.DAYS_AT_LEAST:
			result = config.day_of(world.tick) >= amount
		Kind.SUBJECT_HAS_TRAIT:
			result = subject.has_trait(key)
		Kind.SUBJECT_AT_HOME:
			result = not subject.is_away()
		Kind.ERA_AT_LEAST:
			result = world.era_order >= amount
		Kind.ACHIEVEMENT_EARNED:
			result = world.has_achievement(key)
	return result != negate


static func all_met(
	conditions: Array[SimCondition],
	world: WorldState,
	config: SimConfig,
	subject: VillagerState = null,
) -> bool:
	for condition: SimCondition in conditions:
		if not condition.is_met(world, config, subject):
			return false
	return true
