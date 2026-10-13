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
## Game day each story decision becomes possible. They fill the stretches between the milestone
## unlocks above so something is waiting every few real hours (docs/gameplay.md P3, P10).
const STORY_DAY: Dictionary = {
	&"wolf": 4, &"hungry": 6, &"flint_edge": 24, &"frost": 32, &"prints": 42, &"feast": 60,
	&"hearth": 72, &"mammoth": 88, &"song": 115, &"wall": 126, &"ridge_smoke": 140,
	&"shelter": 172, &"river": 192, &"grain": 232, &"deer": 252, &"trader": 272, &"stars": 294,
	&"smoke": 316, &"tools_pile": 342,
}
## Chance per tick of a small journal line, and how long before the same one can repeat. About one
## line every quarter hour of real time across all of them.
const AMBIENT_CHANCE: float = 0.0045
const AMBIENT_COOLDOWN: int = 360
## Units a villager gathers per tick of work; the starting stock is a few units, so early choices
## wait a little (docs/simulation.md, pacing).
const GATHER_RATE: float = 0.06


func _init() -> void:
	for folder: String in ["events", "buildings", "plants", "eras"]:
		var path: String = ProjectSettings.globalize_path("%s/%s" % [ROOT, folder])
		DirAccess.make_dir_recursive_absolute(path)
	var config: SimConfig = SimConfig.new()
	config.gather_rate = GATHER_RATE
	_save(config, "%s/sim_config.tres" % ROOT)

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
	var lookout: BuildingDef = _building(&"lookout", "Lookout", {&"wood": 8}, 36)
	lookout.description = "A high place to watch the valleys for game, weather and what lies ahead."
	var rack: BuildingDef = _building(&"drying_rack", "Drying Rack", {&"wood": 10}, 30)
	rack.description = "Racks for drying meat and berries so they keep through the cold."
	rack.daily_output = _floats({&"food": 1.0})
	rack.completion_achievement = &"reliable_food"
	rack.completion_achievement_title = "Enough to Eat"
	var knapping: BuildingDef = _building(&"knapping_spot", "Knapping Spot", {&"wood": 12}, 40)
	knapping.description = "A flat stone and a pile of flint: a place to make better tools."
	knapping.daily_output = _floats({&"wood": 0.5})
	knapping.completion_achievement = &"stone_tools"
	knapping.completion_achievement_title = "Stone Tools"
	var hut: BuildingDef = _building(&"hut", "Hut", {&"wood": 14}, 40)
	hut.description = "A proper shelter, built where the group means to stay."
	var field: BuildingDef = _building(&"field", "Field", {&"wood": 12}, 36)
	field.description = "Ground cleared and sown, feeding the group season after season."
	field.daily_output = _floats({&"food": 3.0})
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
	var events: Array[EventDef] = [
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
	events.append_array(_story_decisions())
	events.append_array(_ambient_lines())
	return events


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
		_cond(SimCondition.Kind.RESOURCE_AT_LEAST, &"wood", 8),
	])
	event.chance_per_tick = 0.5
	event.cooldown_ticks = 24
	event.choices = _choices([
		_build_choice(&"build_lookout", "Lookout", &"lookout", 8),
		_build_choice(
			&"build_drying_rack", "Drying Rack", &"drying_rack", 10, UNLOCK_DAY[&"reliable_food"]
		),
		_build_choice(
			&"build_knapping_spot", "Knapping Spot", &"knapping_spot", 12,
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
		_cond(SimCondition.Kind.RESOURCE_AT_LEAST, &"wood", 12),
	])
	event.chance_per_tick = 0.5
	event.cooldown_ticks = 24
	event.choices = _choices([
		_build_choice(&"build_field", "Field", &"field", 12),
		_build_choice(&"build_hut", "Hut", &"hut", 14),
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


## The decisions that fill the Cave Age between its milestones. Each is a small, one-time question
## with two harmless answers: nothing fails, and the answer shows up in the journal and sometimes in
## a later line (a flag). Costs are shown on the choice and only gate it, never punish.
func _story_decisions() -> Array[EventDef]:
	return [
		_wolf_at_the_edge(), _hungry_mornings(), _flint_edge(), _first_hard_frost(),
		_strange_prints(), _prints_end(), _too_much_food(), _second_hearth(), _mammoth_neighbour(),
		_work_song(), _crowded_wall(), _living_story(), _smoke_on_the_ridge(), _ridge_empty(),
		_newcomers_shelter(), _rising_river(), _wild_grain(), _hurt_deer(), _trader(),
		_star_watching(), _smoke_in_the_cave(), _tools_pile(),
	]


func _wolf_at_the_edge() -> EventDef:
	var event: EventDef = _story(
		&"wolf_at_the_edge", "A wolf at the edge", &"nature", STORY_DAY[&"wolf"],
		"A thin grey wolf has begun appearing at dusk, sitting just outside the firelight. "
		+ "It watches the camp and never comes closer."
	)
	event.choices = _choices([
		_answer(
			&"feed_the_wolf", "Leave scraps at the edge of the light",
			"A bone was left at the edge of the light. By morning it was gone.",
			[_spend(&"food", 2), _eff(SimEffect.Kind.SET_FLAG, &"wolf_fed")],
			[_has(&"food", 2)],
		),
		_answer(
			&"drive_it_off", "Drive it off with a torch",
			"The group waved torches until the wolf slipped back into the dark.",
			[_eff(SimEffect.Kind.SET_FLAG, &"wolf_driven_off")],
		),
	])
	return event


## Scarcity told as a question (gameplay.md P2): it only appears when the food pile is low.
func _hungry_mornings() -> EventDef:
	var event: EventDef = _story(
		&"hungry_mornings", "Hungry mornings", &"settlement", STORY_DAY[&"hungry"],
		"The food pile is low and the mornings have gone quiet. Nobody has complained, but "
		+ "everyone has noticed.",
		0.03
	)
	event.once = false
	event.cooldown_ticks = 240
	event.requires.append(_cond(SimCondition.Kind.RESOURCE_AT_LEAST, &"food", 4, true))
	event.choices = _choices([
		_answer(
			&"forage_together", "Spend the day foraging together",
			"The whole group worked the river bank and came back with full baskets.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 6)],
		),
		_answer(
			&"set_snares", "Set snares in the long grass",
			"Snares went into the long grass, and by evening there was a rabbit.",
			[
				_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 4),
				_eff(SimEffect.Kind.SET_FLAG, &"snares"),
			],
		),
	])
	return event


func _flint_edge() -> EventDef:
	var event: EventDef = _story_about(
		&"flint_edge", "What the edge is for", &"character", STORY_DAY[&"flint_edge"],
		"{subject} keeps turning a sharp stone over in their hands. It could be an axe for "
		+ "the wood, or a scraper for the hides.",
		VillagerState.TRAIT_INDUSTRIOUS
	)
	event.requires.append(_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"stone_tools"))
	event.choices = _choices([
		_answer(
			&"make_axes", "Shape hand axes for the wood",
			"{subject} knapped a heavy wedge and felled a small tree before noon.",
			[
				_eff(SimEffect.Kind.ADD_RESOURCE, &"wood", 6),
				_eff(SimEffect.Kind.SET_FLAG, &"hand_axes"),
			],
		),
		_answer(
			&"make_scrapers", "Shape scrapers for the hides",
			"{subject} scraped a hide clean, and by evening it was soft enough to wear.",
			[_eff(SimEffect.Kind.SET_FLAG, &"hide_scrapers")],
		),
	])
	return event


func _first_hard_frost() -> EventDef:
	var event: EventDef = _story(
		&"first_hard_frost", "The first hard frost", &"nature", STORY_DAY[&"frost"],
		"The first hard frost has come. The river is edged with ice, and the wood pile is "
		+ "shrinking faster than it grows."
	)
	event.choices = _choices([
		_answer(
			&"keep_fire_high", "Keep the fire high all night",
			"The fire burned high until dawn, and nobody woke shivering.",
			[_spend(&"wood", 8), _eff(SimEffect.Kind.SET_FLAG, &"warm_winter")],
			[_has(&"wood", 8)],
		),
		_answer(
			&"huddle_close", "Ration the wood and huddle close",
			"They rationed the wood and slept in a heap, grumbling and warm enough.",
			[_eff(SimEffect.Kind.SET_FLAG, &"huddled")],
		),
	])
	return event


func _strange_prints() -> EventDef:
	var event: EventDef = _story_about(
		&"strange_prints", "Strange prints", &"exploration", STORY_DAY[&"prints"],
		"{subject} found a line of strange prints at the edge of the western forest, and "
		+ "wants to follow them.",
		VillagerState.TRAIT_CURIOUS
	)
	event.subject_requires.append(
		_cond(SimCondition.Kind.SUBJECT_HAS_TRAIT, VillagerState.TRAIT_CURIOUS)
	)
	event.choices = _choices([
		_answer(
			&"follow_the_prints", "Let them follow the prints",
			"{subject} set off into the western forest after the prints.",
			[
				_eff(SimEffect.Kind.SEND_AWAY, &"western_forest", 18),
				_eff(SimEffect.Kind.SCHEDULE_EVENT, &"prints_end", 18),
			],
		),
		_answer(
			&"stay_home", "Ask them to stay",
			"{subject} looked back at the forest a few times that evening.",
		),
	])
	return event


## Scheduled only: where the prints led.
func _prints_end() -> EventDef:
	var event: EventDef = _event(&"prints_end", "The prints end", &"exploration")
	event.needs_subject = true
	event.effects = _effs([
		_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 5),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} came home at dusk. The prints were a bear's, days old, but there were "
			+ "pine nuts beneath the tree where it had sat."
		),
	])
	return event


## A food sink for when the pile gets big: a choice about plenty instead of a number to watch.
func _too_much_food() -> EventDef:
	var event: EventDef = _story(
		&"too_much_food", "More than enough", &"settlement", STORY_DAY[&"feast"],
		"There is more food in the cave than the group can eat before it turns.", 0.03
	)
	event.once = true
	event.requires.append(_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"reliable_food"))
	event.requires.append(_cond(SimCondition.Kind.RESOURCE_AT_LEAST, &"food", 16))
	event.choices = _choices([
		_answer(
			&"hold_a_feast", "Hold a feast by the fire",
			"The fire was loud that night. Everyone ate until they laughed.",
			[_spend(&"food", 12)],
			[_has(&"food", 12)],
		),
		_answer(
			&"dry_the_rest", "Dry the rest for lean days",
			"The extra was split thin and hung to dry along the cave wall.",
		),
	])
	return event


func _second_hearth() -> EventDef:
	var event: EventDef = _story_about(
		&"second_hearth", "The warm spot", &"character", STORY_DAY[&"hearth"],
		"Two of the group both want the warm place by the fire, and {subject} has taken to "
		+ "sitting at the edge of the light, alone.",
		VillagerState.TRAIT_SOCIAL
	)
	event.choices = _choices([
		_answer(
			&"build_second_hearth", "Lay a second small fire",
			"A second ring of stones was laid, and the evenings got louder.",
			[_spend(&"wood", 6), _eff(SimEffect.Kind.SET_FLAG, &"second_hearth")],
			[_has(&"wood", 6)],
		),
		_answer(
			&"take_turns", "Take turns by the fire",
			"They agreed to take turns, mostly.",
		),
	])
	return event


func _work_song() -> EventDef:
	var event: EventDef = _story_about(
		&"work_song", "A rhythm to work to", &"character", STORY_DAY[&"song"],
		"{subject} has made up a rhythm to chop to, and keeps humming it. Others have begun "
		+ "to tap along.",
		VillagerState.TRAIT_SOCIAL
	)
	event.requires.append(_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"shared_stories"))
	event.choices = _choices([
		_answer(
			&"join_in", "Let everyone join in",
			"By evening the whole camp worked to {subject}'s rhythm, and nobody could stop "
			+ "humming it.",
			[_eff(SimEffect.Kind.SET_FLAG, &"work_song")],
		),
		_answer(
			&"keep_it_quiet", "Ask for quiet while they work",
			"{subject} kept the rhythm in their head, and tapped it on their knee.",
		),
	])
	return event


func _crowded_wall() -> EventDef:
	var event: EventDef = _story_about(
		&"crowded_wall", "The crowded wall", &"character", STORY_DAY[&"wall"],
		"The red hands on the cave wall are crowded now. {subject} wants to add something "
		+ "more than a hand.",
		VillagerState.TRAIT_CURIOUS
	)
	event.requires.append(_cond(SimCondition.Kind.FLAG_SET, &"cave_art"))
	event.choices = _choices([
		_answer(
			&"paint_the_herd", "Paint the herd and the hunters",
			"A line of deer ran across the cave wall that night, with small figures behind them.",
			[_eff(SimEffect.Kind.SET_FLAG, &"art_herd")],
		),
		_answer(
			&"paint_the_sky", "Paint the sun and the moon",
			"A pale moon and a ring of sun now hang over the hands on the cave wall.",
			[_eff(SimEffect.Kind.SET_FLAG, &"art_sky")],
		),
	])
	return event


func _mammoth_neighbour() -> EventDef:
	var event: EventDef = _story_about(
		&"mammoth_neighbour", "The neighbour", &"nature", STORY_DAY[&"mammoth"],
		"A woolly mammoth has been grazing at the edge of camp for days, ignoring everyone. "
		+ "{subject} has started talking to it.",
		VillagerState.TRAIT_NATURE_LOVING
	)
	event.choices = _choices([
		_answer(
			&"offer_greens", "Offer it a bundle of greens",
			"{subject} left greens at the edge of the grass. The mammoth considered them for "
			+ "most of the afternoon, and ate them.",
			[_spend(&"food", 3), _eff(SimEffect.Kind.SET_FLAG, &"mammoth_fed")],
			[_has(&"food", 3)],
		),
		_answer(
			&"keep_distance", "Keep a respectful distance",
			"Everyone kept a careful distance, and the mammoth kept its own.",
		),
	])
	return event


## Shared Stories told rather than painted: the crowded wall's moment, for the other route.
func _living_story() -> EventDef:
	var event: EventDef = _story(
		&"living_story", "The long story", &"character", STORY_DAY[&"wall"],
		"The story told by the fire has grown long. Everyone has added a piece, and they no "
		+ "longer agree on how it goes."
	)
	event.requires.append(_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"shared_stories"))
	event.requires.append(_cond(SimCondition.Kind.FLAG_SET, &"cave_art", 0, true))
	event.choices = _choices([
		_answer(
			&"one_telling", "Agree on one way to tell it",
			"They argued until it had one shape, and from then on it was told the same way "
			+ "every night.",
			[_eff(SimEffect.Kind.SET_FLAG, &"fixed_tale")],
		),
		_answer(
			&"let_it_change", "Let it change with every telling",
			"The story grew a new piece every night, and someone swore it had always had a "
			+ "giant bird in it.",
			[_eff(SimEffect.Kind.SET_FLAG, &"living_tale")],
		),
	])
	return event


## Foreshadows the strangers (A Bigger Group) without being part of it.
func _smoke_on_the_ridge() -> EventDef:
	var event: EventDef = _story_about(
		&"smoke_on_the_ridge", "Smoke on the ridge", &"exploration", STORY_DAY[&"ridge_smoke"],
		"A thin line of smoke has been rising from the far ridge, where nobody has lived.",
		VillagerState.TRAIT_CURIOUS
	)
	event.requires.append(_cond(SimCondition.Kind.HAS_BUILDING, &"lookout"))
	event.requires.append(_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"bigger_group", 0, true))
	event.choices = _choices([
		_answer(
			&"climb_up", "Send them up to look",
			"{subject} set off up the ridge to find out who was making the smoke.",
			[
				_eff(SimEffect.Kind.SEND_AWAY, &"western_ridge", 14),
				_eff(SimEffect.Kind.SCHEDULE_EVENT, &"ridge_empty", 14),
			],
		),
		_answer(
			&"keep_watching", "Keep watching from the lookout",
			"The smoke came and went. Someone was always at the lookout that week.",
		),
	])
	return event


## Scheduled only: what was found up on the ridge.
func _ridge_empty() -> EventDef:
	var event: EventDef = _event(&"ridge_empty", "The cold fire", &"exploration")
	event.needs_subject = true
	event.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"ridge_footprints"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} found a cold ring of stones and many footprints on the ridge, and came "
			+ "home thoughtful."
		),
	])
	return event


func _newcomers_shelter() -> EventDef:
	var event: EventDef = _story(
		&"newcomers_shelter", "Room for the newcomers", &"settlement", STORY_DAY[&"shelter"],
		"The two newcomers have been sleeping in the cave mouth, as close to the fire as they dare."
	)
	event.requires.append(_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"bigger_group"))
	event.choices = _choices([
		_answer(
			&"build_a_shelter", "Make them a shelter of hides and poles",
			"A shelter of hides and poles went up beside the cave, and the newcomers moved in.",
			[_spend(&"wood", 8), _eff(SimEffect.Kind.SET_FLAG, &"newcomer_shelter")],
			[_has(&"wood", 8)],
		),
		_answer(
			&"share_the_cave", "Make room for them in the cave",
			"The group shuffled along the wall and made room.",
		),
	])
	return event


func _rising_river() -> EventDef:
	var event: EventDef = _story(
		&"rising_river", "The river is rising", &"nature", STORY_DAY[&"river"],
		"Snowmelt has the river high, and it is creeping up the bank towards the cave mouth."
	)
	event.choices = _choices([
		_answer(
			&"move_up", "Carry the stores up to the ledge",
			"Everything went up to the ledge, and the river reached the old fire pit and "
			+ "no further.",
			[_spend(&"wood", 6)],
			[_has(&"wood", 6)],
		),
		_answer(
			&"trust_the_bank", "Trust the bank",
			"The river rose to the edge of the camp, thought about it, and went back.",
		),
	])
	return event


func _wild_grain() -> EventDef:
	var event: EventDef = _story(
		&"wild_grain", "Heavy grass", &"nature", STORY_DAY[&"grain"],
		"In the western meadow the wild grass is heavy with seed."
	)
	event.choices = _choices([
		_answer(
			&"gather_it_all", "Gather every seed head",
			"The group stripped the meadow, and the cave smelled of toasted grain for days.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 10)],
		),
		_answer(
			&"leave_some", "Gather half, and leave the rest to scatter",
			"They gathered half and shook the rest loose over the ground for next year.",
			[
				_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 5),
				_eff(SimEffect.Kind.SET_FLAG, &"left_seed"),
			],
		),
	])
	return event


func _hurt_deer() -> EventDef:
	var event: EventDef = _story(
		&"hurt_deer", "A limping deer", &"nature", STORY_DAY[&"deer"],
		"A young deer with a hurt leg has been limping near the camp, always at the edge of sight."
	)
	event.choices = _choices([
		_answer(
			&"tend_the_deer", "Tend its leg",
			"The deer let someone near. The leg was bound with reeds and moss, and by the new "
			+ "moon it was gone.",
			[_spend(&"food", 3), _eff(SimEffect.Kind.SET_FLAG, &"deer_tended")],
			[_has(&"food", 3)],
		),
		_answer(
			&"leave_it_be", "Let nature take its course",
			"The deer limped on out of sight, and nobody mentioned it.",
		),
	])
	return event


func _star_watching() -> EventDef:
	var event: EventDef = _story_about(
		&"star_watching", "Counting stars", &"character", STORY_DAY[&"stars"],
		"{subject} has taken to lying awake outside, counting the stars, and losing count.",
		VillagerState.TRAIT_CURIOUS
	)
	event.choices = _choices([
		_answer(
			&"name_the_shapes", "Stay up together and name the shapes",
			"They lay on the cold ground and named what they saw: the Hunter, the River, the "
			+ "Long Road.",
			[_eff(SimEffect.Kind.SET_FLAG, &"star_names")],
		),
		_answer(
			&"keep_it_theirs", "Let them keep the sky to themselves",
			"{subject} kept the stars private, and seemed happier for it.",
		),
	])
	return event


func _trader() -> EventDef:
	var event: EventDef = _story(
		&"trader", "A traveller with dark stone", &"exploration", STORY_DAY[&"trader"],
		"A traveller from beyond the ridge has come to the edge of the camp with a bag of dark, "
		+ "glassy stone, and a hungry look."
	)
	event.requires.append(_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"bigger_group"))
	event.choices = _choices([
		_answer(
			&"trade_food", "Trade food for the stone",
			"The dark stone took an edge sharper than flint, and the traveller left full.",
			[_spend(&"food", 8), _eff(SimEffect.Kind.SET_FLAG, &"glassy_stone")],
			[_has(&"food", 8)],
		),
		_answer(
			&"share_a_meal", "Share a meal and send them on",
			"The traveller ate by the fire, said a few words nobody understood, and went on.",
		),
	])
	return event


func _tools_pile() -> EventDef:
	var event: EventDef = _story_about(
		&"tools_pile", "The pile by the cave", &"character", STORY_DAY[&"tools_pile"],
		"The heap of blunt and broken stone tools by the cave mouth has grown tall. "
		+ "{subject} wants to do something about it.",
		VillagerState.TRAIT_INDUSTRIOUS
	)
	event.requires.append(_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"stone_tools"))
	event.choices = _choices([
		_answer(
			&"sort_it", "Sort the good stone from the rest",
			"{subject} sorted the pile by evening, and half of it turned out to be good for "
			+ "something.",
			[_eff(SimEffect.Kind.SET_FLAG, &"sorted_tools")],
		),
		_answer(
			&"bury_it", "Bury it in the river bank",
			"The heap went into the river bank, and the bank is a little higher there now.",
			[_eff(SimEffect.Kind.SET_FLAG, &"buried_tools")],
		),
	])
	return event


func _smoke_in_the_cave() -> EventDef:
	var event: EventDef = _story(
		&"smoke_in_the_cave", "Smoke in the cave", &"settlement", STORY_DAY[&"smoke"],
		"Years of fire have blackened the cave roof, and the smoke lingers every evening."
	)
	event.choices = _choices([
		_answer(
			&"dig_a_smoke_hole", "Open a gap in the roof above the fire",
			"A gap in the roof drew the smoke up, and the stars showed through it.",
			[_spend(&"wood", 8)],
			[_has(&"wood", 8)],
		),
		_answer(
			&"live_with_it", "Live with the smoke",
			"Everyone coughed a little less each year, or said so.",
		),
	])
	return event


## Small lines for the journal, with nothing asked of the player (gameplay.md P3): some about a
## villager with a trait, some about the world, some that remember an earlier answer.
func _ambient_lines() -> Array[EventDef]:
	var lines: Array[EventDef] = [
		_ambient(
			&"morning_mist", "Mist lay on the river until midday, and the camp was very quiet."
		),
		_ambient(
			&"heron", "A heron stood in the shallows all afternoon, as if it had business there."
		),
		_ambient(
			&"frost_glitter",
			"The grass glittered with frost this morning, and then it was gone.", 20
		),
		_ambient(&"geese", "A long line of geese went over, calling, bound somewhere warmer.", 30),
		_ambient(
			&"far_thunder",
			"Thunder grumbled far off, and everyone looked up and nobody was afraid."
		),
		_ambient(
			&"warm_wind",
			"A warm wind came up the valley, and for a day everyone sat outside.", 10
		),
		_ambient_about(
			&"watching_ants", VillagerState.TRAIT_CURIOUS,
			"{subject} lay in the grass all morning watching ants, and could not say why."
		),
		_ambient_about(
			&"shiny_pebble", VillagerState.TRAIT_CURIOUS,
			"{subject} found a pebble that flashed in the water, and keeps it in a pouch."
		),
		_ambient_about(
			&"humming", VillagerState.TRAIT_SOCIAL,
			"{subject} hummed while working, and before long someone hummed back."
		),
		_ambient_about(
			&"a_joke", VillagerState.TRAIT_SOCIAL,
			"{subject} told a joke by the fire. Nobody remembers the joke; everybody "
			+ "remembers the laughing."
		),
		_ambient_about(
			&"sharpened_everything", VillagerState.TRAIT_INDUSTRIOUS,
			"{subject} sharpened every tool in the camp before breakfast, and looked for more."
		),
		_ambient_about(
			&"woodpile", VillagerState.TRAIT_INDUSTRIOUS,
			"{subject} stacked the firewood into a neat wall, and seemed very pleased with it."
		),
		_ambient_about(
			&"crocuses", VillagerState.TRAIT_NATURE_LOVING,
			"{subject} came back from the meadow with crocuses, and set them in the cave mouth."
		),
		_ambient_about(
			&"bird_call", VillagerState.TRAIT_NATURE_LOVING,
			"{subject} followed a bird's call to the river and back, and could answer it."
		),
		_remembered(
			&"wolf_waits", &"wolf_fed",
			"The grey wolf was back at the edge of the light, and nobody minded."
		),
		_remembered(
			&"wolf_howl", &"wolf_driven_off",
			"Far off in the night, a lone wolf howled, and was not answered."
		),
		_remembered(
			&"song_again", &"work_song",
			"The work song drifted across the camp again, a little faster than before."
		),
		_remembered(
			&"herd_on_the_wall", &"art_herd",
			"Someone stood before the painted herd for a long time, and said nothing."
		),
		_remembered(
			&"moon_on_the_wall", &"art_sky",
			"At dusk the painted moon caught the firelight, and for a moment glowed from inside."
		),
		_remembered(
			&"two_fires", &"second_hearth",
			"Two fires burned in the camp that evening, and each had a story going."
		),
		_remembered(
			&"snare_rabbit", &"snares",
			"A rabbit was found in one of the snares, and the group ate well that night."
		),
		_remembered(
			&"mammoth_stays", &"mammoth_fed",
			"The mammoth was in the same place at dawn. It seems to have decided to stay."
		),
		_remembered(
			&"deer_returns", &"deer_tended",
			"A deer with a faint crooked step watched the camp from the meadow, then wasn't there."
		),
		_remembered(
			&"hunter_overhead", &"star_names",
			"Someone showed the Hunter to a sleepy neighbour, and it was exactly where they said."
		),
		_remembered(
			&"tale_told_again", &"living_tale",
			"The long story was told again tonight. It had a new river in it."
		),
		_remembered(
			&"hunters_home", &"path_hunting",
			"The hunters came back at dusk with a deer slung between two poles."
		),
		_remembered(
			&"one_that_got_away", &"path_hunting",
			"The hunters talked all evening about the one that got away."
		),
		_remembered(
			&"baskets_full", &"path_foraging",
			"The baskets came back heavy with roots and berries from along the river."
		),
	]
	return lines


## A story decision: needs the fire and the day, is asked once, and is not about anyone.
func _story(
	event_id: StringName, title: String, category: StringName, day: int, body: String,
	chance: float = 0.02
) -> EventDef:
	var event: EventDef = _event(event_id, title, category)
	event.body = body
	event.requires = _conds([
		_cond(SimCondition.Kind.FLAG_SET, &"fire_found"),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", day),
	])
	event.chance_per_tick = chance
	event.once = true
	return event


## A story decision about one villager at home; anyone can be it, a trait makes a villager likelier.
func _story_about(
	event_id: StringName, title: String, category: StringName, day: int, body: String,
	favoured: StringName
) -> EventDef:
	var event: EventDef = _story(event_id, title, category, day, body)
	event.needs_subject = true
	event.subject_requires = _conds([_cond(SimCondition.Kind.SUBJECT_AT_HOME)])
	event.trait_weights[favoured] = 3.0
	return event


## One answer to a story decision. The journal line is always written; `effects` come first.
func _answer(
	choice_id: StringName, label: String, line: String, effects: Array[SimEffect] = [],
	needs: Array[SimCondition] = []
) -> ChoiceDef:
	var choice: ChoiceDef = _choice(choice_id, label)
	choice.requires = needs
	var all: Array[SimEffect] = []
	all.append_array(effects)
	all.append(_eff(SimEffect.Kind.JOURNAL, &"", 0, line))
	choice.effects = all
	return choice


func _has(resource: StringName, amount: int) -> SimCondition:
	return _cond(SimCondition.Kind.RESOURCE_AT_LEAST, resource, amount)


func _spend(resource: StringName, amount: int) -> SimEffect:
	return _eff(SimEffect.Kind.ADD_RESOURCE, resource, -amount)


func _ambient(event_id: StringName, line: String, from_day: int = 0) -> EventDef:
	var event: EventDef = _event(event_id, "A quiet moment", &"nature")
	event.requires = _conds([_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", from_day)])
	event.chance_per_tick = AMBIENT_CHANCE
	event.cooldown_ticks = AMBIENT_COOLDOWN
	event.effects = _effs([_eff(SimEffect.Kind.JOURNAL, &"", 0, line)])
	return event


func _ambient_about(event_id: StringName, trait_name: StringName, line: String) -> EventDef:
	var event: EventDef = _ambient(event_id, line)
	event.category = &"character"
	event.needs_subject = true
	event.subject_requires = _conds([
		_cond(SimCondition.Kind.SUBJECT_HAS_TRAIT, trait_name),
		_cond(SimCondition.Kind.SUBJECT_AT_HOME),
		_cond(SimCondition.Kind.SUBJECT_AWAKE),
	])
	return event


## A line that only happens once an earlier answer set `flag`.
func _remembered(event_id: StringName, flag: StringName, line: String) -> EventDef:
	var event: EventDef = _ambient(event_id, line)
	event.requires.append(_cond(SimCondition.Kind.FLAG_SET, flag))
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
