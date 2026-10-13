extends SceneTree
## Bootstrap for the simulation's first-slice content (Cave Age, with the turn into the Settled
## Age). Writes the config and content library under res://resources/sim/. Run once with:
##   & $env:GODOT --headless --path game --script res://tools/build_sim_content.gd
## The generated .tres files are ordinary resources: after this, edit them in the Godot
## inspector. Re-running overwrites them, so treat this script as a seed, not the source of truth.

const ROOT: String = "res://resources/sim"
const CAVE: int = 0
const SETTLED: int = 1
## Game days (72 per real day, see SimConfig) before each Cave Age milestone can happen, so the
## five-day age is spread out instead of finished in an afternoon. Fire is not staged: it is the
## opening. This is one table so the pace can be retuned in one place.
const UNLOCK_DAY: Dictionary = {
	&"stone_tools": 18,
	&"reliable_food": 54,
	&"shared_stories": 108,
	&"bigger_group": 162,
	&"seed_chain": 216,
}


func _init() -> void:
	for folder: String in ["events", "buildings", "plants", "eras"]:
		var path: String = ProjectSettings.globalize_path("%s/%s" % [ROOT, folder])
		DirAccess.make_dir_recursive_absolute(path)
	_save(SimConfig.new(), "%s/sim_config.tres" % ROOT)

	var library: ContentLibrary = ContentLibrary.new()
	library.eras.assign(_eras())
	library.buildings.assign(_buildings())
	library.plants.assign(_plants())
	library.events.assign(_events())
	_set_starting_group(library)
	library.starting_resources = _ints({&"wood": 2, &"food": 4})
	for era: EraDef in library.eras:
		_save(era, "%s/eras/%s.tres" % [ROOT, era.id])
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


func _eras() -> Array[EraDef]:
	var cave: EraDef = _era(&"cave", "Cave Age", CAVE)
	cave.description = "Hunter-gatherers sheltering in a cave, living by fire and flint."
	var settled: EraDef = _era(&"settled", "Settled Age", SETTLED)
	settled.description = "Farming and herding: people stay in one place and shape the land."
	settled.intro_text = "The group stayed by the field, and a new way of living began."
	# The hidden gate (docs/ages.md): every milestone, then a minimum of about five real days
	# (8640 ticks at 50 real seconds each). The player is never shown any of this.
	var milestones: Array[StringName] = [
		&"fire", &"stone_tools", &"reliable_food", &"shared_stories", &"bigger_group",
		&"unexpected_garden",
	]
	settled.required_achievements = milestones
	settled.min_ticks_in_previous_era = 8640
	settled.turn_event = &"seeds_of_a_new_life"
	return [cave, settled]


func _set_starting_group(library: ContentLibrary) -> void:
	library.villager_names.assign([
		"Mira", "Theo", "Wren", "Ash", "Bram", "Cora", "Dov", "Elm", "Fenn", "Gale", "Hale",
		"Ivo", "Juno", "Kest", "Lark", "Moss", "Nia", "Orin", "Pike", "Rue", "Sage", "Tarn",
		"Una", "Vale",
	])
	library.villager_traits.assign([
		VillagerState.TRAIT_CURIOUS, VillagerState.TRAIT_SOCIAL,
		VillagerState.TRAIT_INDUSTRIOUS, VillagerState.TRAIT_NATURE_LOVING,
	])
	library.villager_looks.assign([&"mira", &"theo", &"wren"])
	library.starting_villager_count = 3
	library.traits_per_villager = 2
	library.guaranteed_traits.assign([VillagerState.TRAIT_CURIOUS])


func _buildings() -> Array[BuildingDef]:
	var lookout: BuildingDef = _building(&"lookout", "Lookout", {&"wood": 6}, 36)
	lookout.description = "A high place to watch the valleys for game, weather and what lies ahead."
	var rack: BuildingDef = _building(&"drying_rack", "Drying Rack", {&"wood": 6}, 30)
	rack.description = "Racks for drying meat and berries so they keep through the cold."
	rack.daily_output = _floats({&"food": 6.0})
	rack.completion_achievement = &"reliable_food"
	rack.completion_achievement_title = "Enough to Eat"
	var knapping: BuildingDef = _building(&"knapping_spot", "Knapping Spot", {&"wood": 8}, 40)
	knapping.description = "A flat stone and a pile of flint: a place to make better tools."
	knapping.daily_output = _floats({&"wood": 4.0})
	knapping.completion_achievement = &"stone_tools"
	knapping.completion_achievement_title = "Stone Tools"
	var hut: BuildingDef = _building(&"hut", "Hut", {&"wood": 10}, 40)
	hut.description = "A proper shelter, built where the group means to stay."
	var field: BuildingDef = _building(&"field", "Field", {&"wood": 8}, 36)
	field.description = "Ground cleared and sown, feeding the group season after season."
	field.daily_output = _floats({&"food": 10.0})
	return [lookout, rack, knapping, hut, field]


func _plants() -> Array[PlantDef]:
	var flower: PlantDef = PlantDef.new()
	flower.id = &"strange_flower"
	flower.display_name = "Strange flower"
	flower.seed_item = &"strange_seed"
	flower.ticks_to_flower = 72
	flower.flower_text = "The strange seed flowered by the cave mouth."
	flower.flower_flag = &"strange_flower_bloomed"
	flower.flower_achievement = &"unexpected_garden"
	flower.flower_achievement_title = "Unexpected Garden"
	return [flower]


func _events() -> Array[EventDef]:
	return [
		_fire_from_storm(),
		_fire_from_sparks(),
		_embers_remain(),
		_cracking_nuts(),
		_herds_nearby(),
		_stories_by_the_fire(),
		_ochre_on_the_riverbank(),
		_strangers_on_the_ridge(),
		_building_opportunity(),
		_settled_building_opportunity(),
		_curious_explorer(),
		_explorer_returns(),
		_seed_in_pouch(),
		_seeds_of_a_new_life(),
		_rare_butterfly(),
		_heavy_rain(),
		_cold_night(),
	]


## The first milestone. The Cave Age starts cold and dark; fire is found by one of two routes,
## and a player who passes on either still gets it (the embers), only a little later.
func _fire_from_storm() -> EventDef:
	var event: EventDef = _event(&"fire_from_storm", "A burning tree", &"nature")
	event.body = "A storm rolled over the valley in the night. On the ridge a lone tree is " \
			+ "burning, and even from here its glow is warm."
	event.requires = _conds([
		_cond(SimCondition.Kind.FLAG_SET, &"fire_found", 0, true),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", 1),
	])
	event.needs_subject = true
	event.subject_requires = _conds([
		_cond(SimCondition.Kind.SUBJECT_HAS_TRAIT, VillagerState.TRAIT_CURIOUS),
		_cond(SimCondition.Kind.SUBJECT_AT_HOME),
	])
	event.chance_per_tick = 0.04
	event.cooldown_ticks = 24
	var carry: ChoiceDef = _choice(&"carry_fire", "Carry a burning branch back to the cave")
	carry.effects = _effs(_fire_found_effects(
		"{subject} carried a burning branch back through the rain, and the cave was warm for the first time."
	))
	var avoid: ChoiceDef = _choice(&"stay_away", "Keep well away from it")
	avoid.effects = _effs([
		_eff(SimEffect.Kind.JOURNAL, &"", 0, "The group kept away from the burning tree."),
		_eff(SimEffect.Kind.SCHEDULE_EVENT, &"embers_remain", 48),
	])
	event.choices = _choices([carry, avoid])
	return event


func _fire_from_sparks() -> EventDef:
	var event: EventDef = _event(&"fire_from_sparks", "Sparks", &"settlement")
	event.body = "{subject} was knocking two stones together when a spark caught in a nest " \
			+ "of dry moss."
	event.requires = _conds([
		_cond(SimCondition.Kind.FLAG_SET, &"fire_found", 0, true),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", 1),
	])
	event.needs_subject = true
	event.subject_requires = _conds([
		_cond(SimCondition.Kind.SUBJECT_HAS_TRAIT, VillagerState.TRAIT_INDUSTRIOUS),
		_cond(SimCondition.Kind.SUBJECT_AT_HOME),
	])
	event.chance_per_tick = 0.03
	event.cooldown_ticks = 24
	var blow: ChoiceDef = _choice(&"blow_on_it", "Blow on the spark, gently")
	blow.effects = _effs(_fire_found_effects(
		"{subject} blew on the spark until the moss glowed, and the first fire of the camp was lit."
	))
	var brush: ChoiceDef = _choice(&"let_it_die", "Brush it away")
	brush.effects = _effs([
		_eff(SimEffect.Kind.JOURNAL, &"", 0, "{subject} brushed the spark away before it could grow."),
		_eff(SimEffect.Kind.SCHEDULE_EVENT, &"embers_remain", 72),
	])
	event.choices = _choices([blow, brush])
	return event


## Scheduled only: the fallback that guarantees fire for a player who passed on both routes.
func _embers_remain() -> EventDef:
	var event: EventDef = _event(&"embers_remain", "Embers", &"nature")
	event.requires = _conds([_cond(SimCondition.Kind.FLAG_SET, &"fire_found", 0, true)])
	event.effects = _effs(_fire_found_effects(
		"In the grey morning the group went back for the last glowing embers, and carried the first fire home."
	))
	return event


func _fire_found_effects(text: String) -> Array[SimEffect]:
	return [
		_eff(SimEffect.Kind.SET_FLAG, &"fire_found"),
		_eff(SimEffect.Kind.JOURNAL, &"", 0, text),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"fire", 0, "Fire"),
	]


## Milestone events pick anyone at home as the subject; a matching trait only makes the person
## likelier, so no random group can be locked out of a milestone.
func _milestone_event(
	event_id: StringName, title: String, category: StringName, favoured: StringName
) -> EventDef:
	var event: EventDef = _event(event_id, title, category)
	event.needs_subject = true
	event.subject_requires = _conds([_cond(SimCondition.Kind.SUBJECT_AT_HOME)])
	event.trait_weights[favoured] = 3.0
	event.chance_per_tick = 0.03
	event.cooldown_ticks = 48
	return event


## Stone Tools, second route (the first is building the Knapping Spot).
func _cracking_nuts() -> EventDef:
	var event: EventDef = _milestone_event(
		&"cracking_nuts", "A sharp stone", &"character", VillagerState.TRAIT_NATURE_LOVING
	)
	event.body = "{subject} was cracking nuts with a river stone when it split, leaving an " \
			+ "edge sharper than anything the group owns."
	event.requires = _conds([
		_cond(SimCondition.Kind.FLAG_SET, &"fire_found"),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"stone_tools", 0, true),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", UNLOCK_DAY[&"stone_tools"]),
	])
	var keep: ChoiceDef = _choice(&"keep_the_stone", "Keep it, and try making more")
	keep.effects = _effs([
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} struck the split stone against another, and by evening everyone was making sharp edges."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"stone_tools", 0, "Stone Tools"),
	])
	var toss: ChoiceDef = _choice(&"toss_it", "Toss it aside")
	toss.effects = _effs([
		_eff(SimEffect.Kind.JOURNAL, &"", 0, "{subject} tossed the split stone onto the pile."),
	])
	event.choices = _choices([keep, toss])
	return event


## Reliable Food, the first route (the second is building the Drying Rack). Either the group
## hunts, which counts at once, or it forages and the Drying Rack makes the food last.
func _herds_nearby() -> EventDef:
	var event: EventDef = _event(&"herds_nearby", "The herds are close", &"exploration")
	event.body = "A herd has wandered into the valley below the cave. Food has been uncertain " \
			+ "for days, and this might be the chance to change that."
	event.requires = _conds([
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"stone_tools"),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"reliable_food", 0, true),
		_cond(SimCondition.Kind.FLAG_SET, &"path_foraging", 0, true),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", UNLOCK_DAY[&"reliable_food"]),
	])
	event.chance_per_tick = 0.03
	event.cooldown_ticks = 48
	var hunt: ChoiceDef = _choice(&"hunt", "Make spears and hunt together")
	hunt.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"path_hunting"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"The group carved spears and brought down a deer together. There was meat for everyone."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"reliable_food", 0, "Enough to Eat"),
	])
	var forage: ChoiceDef = _choice(&"forage", "Weave baskets and gather instead")
	forage.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"path_foraging"),
		_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 6),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"The group wove reed baskets and spent the day gathering along the river."
		),
	])
	event.choices = _choices([hunt, forage])
	return event


## Shared Stories, first route.
func _stories_by_the_fire() -> EventDef:
	var event: EventDef = _milestone_event(
		&"stories_by_the_fire", "A story by the fire", &"character", VillagerState.TRAIT_SOCIAL
	)
	event.body = "{subject} has started telling the others about the day, and for once nobody " \
			+ "is eager to sleep."
	event.requires = _conds([
		_cond(SimCondition.Kind.FLAG_SET, &"fire_found"),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"shared_stories", 0, true),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", UNLOCK_DAY[&"shared_stories"]),
	])
	var tell: ChoiceDef = _choice(&"tell_it", "Gather everyone to listen")
	tell.effects = _effs([
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} told the story of the day, and soon everyone was adding to it. By the end they told it the same way each night."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"shared_stories", 0, "Shared Stories"),
	])
	var pass_on: ChoiceDef = _choice(&"let_it_pass", "Let the fire burn down")
	pass_on.effects = _effs([
		_eff(SimEffect.Kind.JOURNAL, &"", 0, "The fire burned down and everyone drifted to sleep."),
	])
	event.choices = _choices([tell, pass_on])
	return event


## Shared Stories, second route.
func _ochre_on_the_riverbank() -> EventDef:
	var event: EventDef = _milestone_event(
		&"ochre_on_the_riverbank", "Red earth", &"nature", VillagerState.TRAIT_NATURE_LOVING
	)
	event.body = "{subject} came back from the riverbank with hands stained deep red, and a " \
			+ "lump of the earth that did it."
	event.requires = _conds([
		_cond(SimCondition.Kind.FLAG_SET, &"fire_found"),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"shared_stories", 0, true),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", UNLOCK_DAY[&"shared_stories"]),
	])
	var paint: ChoiceDef = _choice(&"paint_the_wall", "Let them mark the cave wall")
	paint.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"cave_art"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} pressed a red hand to the cave wall, and one by one the others added theirs."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"shared_stories", 0, "Shared Stories"),
	])
	var wash: ChoiceDef = _choice(&"wash_it_off", "Wash it off in the river")
	wash.effects = _effs([
		_eff(SimEffect.Kind.JOURNAL, &"", 0, "{subject} washed the red earth off in the river."),
	])
	event.choices = _choices([paint, wash])
	return event


## A Bigger Group. The lookout is how the strangers are seen at all.
func _strangers_on_the_ridge() -> EventDef:
	var event: EventDef = _event(&"strangers_on_the_ridge", "Strangers on the ridge", &"exploration")
	event.body = "From the lookout, two strangers can be seen on the ridge, watching the smoke " \
			+ "of the cave fire. They have kept their distance for two days."
	event.requires = _conds([
		_cond(SimCondition.Kind.HAS_BUILDING, &"lookout"),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"bigger_group", 0, true),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", UNLOCK_DAY[&"bigger_group"]),
	])
	event.chance_per_tick = 0.02
	event.cooldown_ticks = 72
	var welcome: ChoiceDef = _choice(&"welcome_them", "Welcome them to the fire")
	welcome.effects = _effs([
		_eff(SimEffect.Kind.ADD_VILLAGER, &"", 2),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"The two strangers came down from the ridge, and the group grew."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"bigger_group", 0, "A Bigger Group"),
	])
	var watch: ChoiceDef = _choice(&"keep_watch", "Keep watching from a distance")
	watch.effects = _effs([
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"The group watched the strangers, and the strangers watched back."
		),
	])
	event.choices = _choices([welcome, watch])
	return event


func _building_opportunity() -> EventDef:
	var event: EventDef = _event(&"building_opportunity", "Ready to build", &"settlement")
	event.body = "The group has gathered enough to improve the camp."
	event.requires = _conds([
		_cond(SimCondition.Kind.FLAG_SET, &"fire_found"),
		_cond(SimCondition.Kind.CONSTRUCTION_IDLE),
		_cond(SimCondition.Kind.RESOURCE_AT_LEAST, &"wood", 6),
	])
	event.chance_per_tick = 0.5
	event.cooldown_ticks = 24
	event.choices = _choices([
		_build_choice(&"build_lookout", "Lookout", &"lookout", 6),
		_build_choice(
			&"build_drying_rack", "Drying Rack", &"drying_rack", 6, UNLOCK_DAY[&"reliable_food"]
		),
		_build_choice(
			&"build_knapping_spot", "Knapping Spot", &"knapping_spot", 8,
			UNLOCK_DAY[&"stone_tools"]
		),
	])
	return event


func _settled_building_opportunity() -> EventDef:
	var event: EventDef = _event(
		&"settled_building_opportunity", "Building a settlement", &"settlement"
	)
	event.body = "Staying in one place means building for it."
	event.requires = _conds([
		_cond(SimCondition.Kind.ERA_AT_LEAST, &"", SETTLED),
		_cond(SimCondition.Kind.CONSTRUCTION_IDLE),
		_cond(SimCondition.Kind.RESOURCE_AT_LEAST, &"wood", 8),
	])
	event.chance_per_tick = 0.5
	event.cooldown_ticks = 24
	event.choices = _choices([
		_build_choice(&"build_field", "Field", &"field", 8),
		_build_choice(&"build_hut", "Hut", &"hut", 10),
	])
	return event


func _curious_explorer() -> EventDef:
	var event: EventDef = _event(&"curious_explorer", "A curious scout", &"exploration")
	event.body = "{subject} keeps climbing the lookout to stare at the ridge beyond the western forest."
	event.requires = _conds([
		_cond(SimCondition.Kind.HAS_BUILDING, &"lookout"),
		_cond(SimCondition.Kind.FLAG_SET, &"western_forest_explored", 0, true),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", UNLOCK_DAY[&"seed_chain"]),
	])
	event.needs_subject = true
	event.subject_requires = _conds([
		_cond(SimCondition.Kind.SUBJECT_HAS_TRAIT, VillagerState.TRAIT_CURIOUS),
		_cond(SimCondition.Kind.SUBJECT_AT_HOME),
	])
	event.chance_per_tick = 0.06
	event.cooldown_ticks = 72
	var go: ChoiceDef = _choice(&"encourage", "Encourage them to scout")
	go.effects = _effs([
		_eff(SimEffect.Kind.SET_PROFESSION, &"scout"),
		_eff(SimEffect.Kind.SEND_AWAY, &"western_forest", 36),
		_eff(SimEffect.Kind.SCHEDULE_EVENT, &"explorer_returns", 36),
		_eff(SimEffect.Kind.JOURNAL, &"", 0, "{subject} set off to scout the western forest."),
	])
	event.choices = _choices([go, _choice(&"remain", "Ask them to stay")])
	return event


func _explorer_returns() -> EventDef:
	var event: EventDef = _event(&"explorer_returns", "A scout returns", &"exploration")
	event.body = "{subject} is back from the forest, carrying something unfamiliar."
	event.needs_subject = true
	event.effects = _effs([
		_eff(SimEffect.Kind.ADD_ITEM, &"strange_seed", 1),
		_eff(SimEffect.Kind.SET_FLAG, &"western_forest_explored"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} returned from the western forest carrying the seed of an unfamiliar plant."
		),
	])
	var plant: ChoiceDef = _choice(&"plant_it", "Plant it")
	plant.requires = _conds([_cond(SimCondition.Kind.ITEM_AT_LEAST, &"strange_seed", 1)])
	plant.effects = _effs([
		_eff(SimEffect.Kind.PLANT, &"strange_seed"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} pressed the strange seed into the soil by the cave mouth."
		),
	])
	var keep: ChoiceDef = _choice(&"keep_it", "Keep it safe")
	keep.effects = _effs([
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"The strange seed was wrapped in a hide pouch for safekeeping."
		),
	])
	event.choices = _choices([plant, keep])
	return event


func _seed_in_pouch() -> EventDef:
	var event: EventDef = _event(&"seed_in_pouch", "The seed in the pouch", &"exploration")
	event.body = "The strange seed in its hide pouch looks ready to be planted."
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


## The turn from the Cave Age to the Settled Age. Fired by the era's hidden gate (not rolled), so
## the player is never asked *whether* to settle, only how.
func _seeds_of_a_new_life() -> EventDef:
	var event: EventDef = _event(&"seeds_of_a_new_life", "Seeds of a new life", &"settlement")
	event.body = "The plant by the cave has gone to seed: enough to sow a whole field. The " \
			+ "herds still move through the valley, and the group has learned enough to stay."
	var settle: ChoiceDef = _choice(&"settle_field", "Sow the seeds and settle by the field")
	settle.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"path_agriculture"),
		_eff(SimEffect.Kind.ADVANCE_ERA, &"settled"),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"the_first_field", 0, "The First Field"),
	])
	var herds: ChoiceDef = _choice(&"settle_herds", "Settle where the herds winter, and sow a small plot")
	herds.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"path_herding"),
		_eff(SimEffect.Kind.ADVANCE_ERA, &"settled"),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"a_place_to_stay", 0, "A Place to Stay"),
	])
	event.choices = _choices([settle, herds])
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
		_eff(SimEffect.Kind.JOURNAL, &"", 0, "It rained heavily and everyone crowded in the cave."),
	])
	return event


func _cold_night() -> EventDef:
	var event: EventDef = _event(&"cold_night", "A cold night", &"nature")
	event.requires = _conds([
		_cond(SimCondition.Kind.FLAG_SET, &"fire_found"),
		_cond(SimCondition.Kind.ERA_AT_LEAST, &"", SETTLED, true),
	])
	event.chance_per_tick = 0.005
	event.cooldown_ticks = 120
	event.effects = _effs([
		_eff(SimEffect.Kind.JOURNAL, &"", 0, "A cold night. Everyone drew close around the fire."),
	])
	return event


func _build_choice(
	choice_id: StringName, label: String, building: StringName, wood: int, from_day: int = 0
) -> ChoiceDef:
	var choice: ChoiceDef = _choice(choice_id, label)
	choice.requires = _conds([
		_cond(SimCondition.Kind.HAS_BUILDING, building, 0, true),
		_cond(SimCondition.Kind.RESOURCE_AT_LEAST, &"wood", wood),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", from_day),
	])
	choice.effects = _effs([_eff(SimEffect.Kind.START_BUILD, building)])
	return choice


func _era(era_id: StringName, display_name: String, order: int) -> EraDef:
	var era: EraDef = EraDef.new()
	era.id = era_id
	era.display_name = display_name
	era.order = order
	return era


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
