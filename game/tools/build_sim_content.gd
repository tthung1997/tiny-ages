extends SceneTree
## Bootstrap for the simulation's first-slice content (Cave Age, with the turn into the Settled
## Age). Writes the config and content library under res://resources/sim/. Run once with:
##   & $env:GODOT --headless --path game --script res://tools/build_sim_content.gd
## The generated .tres files are ordinary resources: after this, edit them in the Godot
## inspector. Re-running overwrites them, so treat this script as a seed, not the source of truth.

const ROOT: String = "res://resources/sim"
const CAVE: int = 0
const SETTLED: int = 1
## Decisions already written as a real choice between two directions (docs/gameplay.md P13).
## Every other decision still has a "do it or pass" shape and keeps asking with one answer;
## each stage of the conversion moves ids here, and the list ends as every decision.
const CONVERTED_DECISIONS: Array[StringName] = [
	&"fire_from_storm", &"fire_from_sparks", &"cracking_nuts", &"herds_nearby",
	&"stories_by_the_fire", &"ochre_on_the_riverbank", &"strangers_on_the_ridge",
	&"strangers_at_the_edge", &"building_opportunity", &"curious_explorer", &"restless_explorer",
	&"explorer_returns", &"seed_in_pouch", &"seeds_of_a_new_life", &"wolf_at_the_edge",
	&"hungry_mornings", &"flint_edge", &"first_hard_frost", &"strange_prints", &"too_much_food",
	&"second_hearth", &"mammoth_neighbour", &"work_song", &"crowded_wall", &"living_story",
	&"smoke_on_the_ridge", &"newcomers_shelter", &"rising_river", &"wild_grain", &"hurt_deer",
	&"trader", &"star_watching", &"smoke_in_the_cave", &"tools_pile", &"cold_floors",
	&"lost_flint", &"night_noises", &"the_ford", &"bright_feather", &"bats_in_the_back",
	&"bee_tree", &"fish_run", &"hollow_log", &"first_snow", &"echo_in_the_cave", &"sky_stone",
	&"warm_pool",
]
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
	&"floors": 11, &"lost_flint": 80, &"night_noises": 98, &"ford": 152, &"feather": 182,
	&"bats": 204, &"honey": 227, &"fish_run": 246, &"drum": 265, &"first_snow": 285,
	&"echo": 307, &"sky_stone": 331, &"warm_pool": 350,
}
## Days into the Settled Age (not since the start) before each of its milestones can happen. The
## age is paced like the Cave Age: five hidden milestones spread over about the same five real
## days (docs/ages.md). `reeds` is the third, late route to woven cloth, open to every group.
const SETTLED_DAY: Dictionary = {
	&"first_roof": 18,
	&"first_harvest": 54,
	&"fired_clay": 108,
	&"woven_cloth": 162,
	&"reeds": 198,
	&"a_village": 216,
	&"green_stone": 252,
}
## Days into the Settled Age when each small story decision becomes possible, filling the stretches
## between the milestones above (the same idea as STORY_DAY). Paired entries (`furrows`/`pasture`,
## `scarecrow`/`dog`) are the farmers' and the herders' version of one beat.
const SETTLED_STORY_DAY: Dictionary = {
	&"cave": 2, &"ground": 8, &"furrows": 14, &"pasture": 14, &"roof": 38, &"well": 46,
	&"scarecrow": 58, &"dog": 58, &"store": 70, &"quarrel": 82, &"festival": 92, &"voice": 100,
	&"kiln": 118, &"wet": 130, &"fowl": 142, &"dye": 172, &"loom": 184, &"flood": 196,
	&"neighbours": 208, &"salt": 226, &"count": 238, &"beads": 262, &"wall": 286,
	&"looking_back": 312,
}
## Chance per tick of a small journal line, and how long before the same one can repeat. About one
## line every quarter hour of real time across all of them.
const AMBIENT_CHANCE: float = 0.0045
## The Settled Age adds its own lines to the Cave Age's, which keep happening, so each is rarer.
const SETTLED_AMBIENT_CHANCE: float = 0.002
const AMBIENT_COOLDOWN: int = 360
## Units a villager gathers per tick of work; the starting stock is a few units, so early choices
## wait a little (docs/simulation.md, pacing).
const GATHER_RATE: float = 0.06
## Days later that a Lookout milestone still happens for a group that never built one. The Lookout
## makes the strangers and the scout come sooner; nothing depends on having it (docs/gameplay.md P13).
const NO_LOOKOUT_DELAY: int = 30


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
	_mark_unconverted(library.events)
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


func _mark_unconverted(events: Array[EventDef]) -> void:
	for event: EventDef in events:
		if event.is_decision() and not CONVERTED_DECISIONS.has(event.id):
			event.min_choices = 1


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
	hut.completion_achievement = &"first_roof"
	hut.completion_achievement_title = "A Roof of Your Own"
	var field: BuildingDef = _building(&"field", "Field", {&"wood": 12}, 36)
	field.description = "Ground cleared and sown, feeding the group season after season."
	field.daily_output = _floats({&"food": 3.0})
	field.completion_achievement = &"first_harvest"
	field.completion_achievement_title = "The First Harvest"
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
		_hammerstone_splits(),
		_herds_nearby(),
		_baskets_keep(),
		_stories_by_the_fire(),
		_ochre_on_the_riverbank(),
		_strangers_on_the_ridge(),
		_strangers_at_the_edge(),
		_strangers_come(),
		_building_opportunity(),
		_settled_building_opportunity(),
		_curious_explorer(),
		_restless_explorer(),
		_explorer_returns(),
		_seed_in_pouch(),
		_seeds_of_a_new_life(),
		_rare_butterfly(),
		_heavy_rain(),
		_cold_night(),
	]
	events.append_array(_settled_milestones())
	events.append_array(_story_decisions())
	events.append_array(_settled_stories())
	events.append_array(_ambient_lines())
	events.append_array(_settled_ambient_lines())
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
	var avoid: ChoiceDef = _choice(&"wait_for_embers", "Wait for it to burn down, then take the embers")
	avoid.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"embers_waited"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"The group watched the burning tree from a distance until it was ash and embers."
		),
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
	var brush: ChoiceDef = _choice(&"tend_the_spark", "Shelter it and tend it until morning")
	brush.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"embers_waited"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} cupped the spark in the moss all night, and by dawn it was a bed of embers."
		),
		_eff(SimEffect.Kind.SCHEDULE_EVENT, &"embers_remain", 72),
	])
	event.choices = _choices([blow, brush])
	return event


## Scheduled only: the slower road to fire for a group that waited instead of carrying it home.
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
	var toss: ChoiceDef = _choice(&"keep_cracking", "Keep cracking nuts with it")
	toss.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"nut_hammer"),
		_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 3),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} kept cracking nuts with the split stone, and the others queued up to try it."
		),
		_eff(SimEffect.Kind.SCHEDULE_EVENT, &"hammerstone_splits", 96),
	])
	event.choices = _choices([keep, toss])
	return event


## Scheduled only: the stone that was kept for cracking nuts breaks, and the group learns the
## same thing the other way round.
func _hammerstone_splits() -> EventDef:
	var event: EventDef = _event(&"hammerstone_splits", "The hammerstone breaks", &"character")
	event.needs_subject = true
	event.requires = _conds([
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"stone_tools", 0, true),
	])
	event.effects = _effs([
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"The old nut stone finally split clean across, and the edge it left was sharper than "
			+ "anything the group owned. By evening everyone was making edges."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"stone_tools", 0, "Stone Tools"),
	])
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
		_eff(SimEffect.Kind.SCHEDULE_EVENT, &"baskets_keep", 96),
	])
	event.choices = _choices([hunt, forage])
	return event


## Scheduled only: the foragers' road to Reliable Food, a little slower than the hunters'. The
## Drying Rack still gets there first.
func _baskets_keep() -> EventDef:
	var event: EventDef = _event(&"baskets_keep", "Baskets that keep", &"settlement")
	event.requires = _conds([
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"reliable_food", 0, true),
	])
	event.effects = _effs([
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"The baskets hung from the cave roof stayed full through the lean weeks, and nobody "
			+ "woke hungry."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"reliable_food", 0, "Enough to Eat"),
	])
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
		_eff(SimEffect.Kind.SET_FLAG, &"tales_told"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} told the story of the day, and soon everyone was adding to it. By the end they told it the same way each night."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"shared_stories", 0, "Shared Stories"),
	])
	var pass_on: ChoiceDef = _choice(&"sing_it", "Let them sing it instead")
	pass_on.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"songs_sung"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} sang the story of the day, and one by one the others found the tune. By the end they sang it the same way each night."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"shared_stories", 0, "Shared Stories"),
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
	var wash: ChoiceDef = _choice(&"paint_faces", "Let them paint faces and hands instead")
	wash.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"body_paint"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} painted a red line down a friend's cheek, and by dark the whole camp wore it."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"shared_stories", 0, "Shared Stories"),
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
	event.choices = _strangers_choices()
	return event


## The same strangers for a group with no Lookout: nobody sees them coming, so they are noticed a
## month later at the edge of the firelight. The Lookout is only ever a faster road.
func _strangers_at_the_edge() -> EventDef:
	var event: EventDef = _event(&"strangers_at_the_edge", "Strangers at the edge", &"exploration")
	event.body = "Two strangers have been seen at dusk, just beyond the firelight, watching the " \
			+ "smoke of the cave fire. They have kept their distance for two days."
	event.requires = _conds([
		_cond(SimCondition.Kind.HAS_BUILDING, &"lookout", 0, true),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"bigger_group", 0, true),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", UNLOCK_DAY[&"bigger_group"] + NO_LOOKOUT_DELAY),
	])
	event.chance_per_tick = 0.02
	event.cooldown_ticks = 72
	event.choices = _strangers_choices()
	return event


func _strangers_choices() -> Array[ChoiceDef]:
	var welcome: ChoiceDef = _choice(&"welcome_them", "Welcome them to the fire")
	welcome.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"strangers_welcomed"),
		_eff(SimEffect.Kind.ADD_VILLAGER, &"", 2),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"The two strangers came down from the ridge, and the group grew."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"bigger_group", 0, "A Bigger Group"),
	])
	var court: ChoiceDef = _choice(&"leave_food", "Leave food at the edge of the light")
	court.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"strangers_courted"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"A bundle of food was left at the edge of the light, and the strangers watched it "
			+ "for a long time."
		),
		_eff(SimEffect.Kind.SCHEDULE_EVENT, &"strangers_come", 72),
	])
	return _choices([welcome, court])


## Scheduled only: the cautious road to A Bigger Group, where the strangers decide for themselves.
func _strangers_come() -> EventDef:
	var event: EventDef = _event(&"strangers_come", "The strangers come in", &"exploration")
	event.requires = _conds([
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"bigger_group", 0, true),
	])
	event.effects = _effs([
		_eff(SimEffect.Kind.ADD_VILLAGER, &"", 2),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"The bundle was gone one morning, and that evening the two strangers walked in on "
			+ "their own and sat down at the edge of the fire."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"bigger_group", 0, "A Bigger Group"),
	])
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
		_build_choice(&"build_hut", "Hut", &"hut", 14, 0, SETTLED_DAY[&"first_roof"]),
		_build_choice(&"build_field", "Field", &"field", 12, 0, SETTLED_DAY[&"first_harvest"]),
	])
	return event


## The Settled Age's six hidden milestones, each with more than one route (docs/ages.md). A group
## that herds and a group that farms reach some by different roads, and one late route is open to
## everyone so no group is locked out. The last one looks outward, to what the next age is built
## on. Nothing here is shown to the player.
func _settled_milestones() -> Array[EventDef]:
	return [
		_thatched_roof(), _first_calves(), _clay_hardens(), _shaped_bowls(), _flax_in_the_field(),
		_wool_on_the_thorns(), _plaited_reeds(), _families_on_the_road(), _the_long_table(),
		_green_stone_found(), _green_stone_traded(),
	]


## Every Settled milestone event: Settled Age, far enough into it, and not yet earned.
func _settled_milestone(
	event_id: StringName, title: String, category: StringName, favoured: StringName,
	era_day: int, milestone: StringName
) -> EventDef:
	var event: EventDef = _milestone_event(event_id, title, category, favoured)
	event.requires = _conds([
		_cond(SimCondition.Kind.ERA_AT_LEAST, &"", SETTLED),
		_cond(SimCondition.Kind.ERA_DAYS_AT_LEAST, &"", era_day),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, milestone, 0, true),
	])
	return event


func _earn(milestone: StringName, title: String) -> SimEffect:
	return _eff(SimEffect.Kind.ACHIEVEMENT, milestone, 0, title)


## A Roof of Your Own, second route (the first is building the Hut).
func _thatched_roof() -> EventDef:
	var event: EventDef = _settled_milestone(
		&"thatched_roof", "Rain through the hides", &"character",
		VillagerState.TRAIT_INDUSTRIOUS, SETTLED_DAY[&"first_roof"], &"first_roof"
	)
	event.body = "{subject} is tired of rain dripping through the hides. Bundles of river " \
			+ "reed, bound tight over the poles, might shed it."
	event.choices = _choices([
		_answer(
			&"thatch_it", "Bind reeds into a thatch",
			"{subject} lashed reed bundles over the poles, and that night the rain ran off "
			+ "the roof as if it had never been a problem.",
			[_earn(&"first_roof", "A Roof of Your Own")],
		),
		_answer(
			&"make_do", "Make do with the hides",
			"The hides dripped all night, and everyone moved their bedding to the dry side.",
		),
	])
	return event


## The First Harvest, the herders' route (the farmers' is building the Field).
func _first_calves() -> EventDef:
	var event: EventDef = _event(&"first_calves", "Calves in the spring", &"nature")
	event.body = "The herd that winters by the camp has calves this spring: small, unsteady " \
			+ "things, and their mothers watch the camp with suspicion."
	event.requires = _conds([
		_cond(SimCondition.Kind.ERA_AT_LEAST, &"", SETTLED),
		_cond(SimCondition.Kind.ERA_DAYS_AT_LEAST, &"", SETTLED_DAY[&"first_harvest"]),
		_cond(SimCondition.Kind.FLAG_SET, &"path_herding"),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"first_harvest", 0, true),
	])
	event.chance_per_tick = 0.03
	event.cooldown_ticks = 48
	event.choices = _choices([
		_answer(
			&"tend_the_calves", "Keep them close and tend the herd",
			"The group kept watch through the long nights of calving. By midsummer there was "
			+ "milk, and nobody had lost an animal.",
			[
				_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 4),
				_earn(&"first_harvest", "The First Calves"),
			],
		),
		_answer(
			&"let_them_roam", "Let the herd keep to itself",
			"The herd kept to itself, and the calves were hardly seen again that spring.",
		),
	])
	return event


## Fired Clay, first route.
func _clay_hardens() -> EventDef:
	var event: EventDef = _settled_milestone(
		&"clay_hardens", "Clay by the fire", &"character", VillagerState.TRAIT_CURIOUS,
		SETTLED_DAY[&"fired_clay"], &"fired_clay"
	)
	event.body = "{subject} left a basket smeared with river clay too close to the fire. The " \
			+ "basket burned away, but the clay did not melt. It stood there hard and red, and " \
			+ "rang when it was tapped."
	event.choices = _choices([
		_answer(
			&"fire_a_pot", "Shape some clay and fire it on purpose",
			"{subject} shaped a squat little pot and buried it in hot ashes. Next morning it "
			+ "held water, and everyone had to hold it.",
			[_earn(&"fired_clay", "Fired Clay")],
		),
		_answer(
			&"leave_the_shell", "Leave it where it stands",
			"The red shell of clay stayed by the fire, and was mostly used as a seat.",
		),
	])
	return event


## Fired Clay, second route.
func _shaped_bowls() -> EventDef:
	var event: EventDef = _settled_milestone(
		&"shaped_bowls", "Bowls in the sun", &"character", VillagerState.TRAIT_INDUSTRIOUS,
		SETTLED_DAY[&"fired_clay"], &"fired_clay"
	)
	event.body = "{subject} has been shaping the soft clay of the riverbank into bowls and " \
			+ "setting them out in the sun. They crack, one after another."
	event.choices = _choices([
		_answer(
			&"bake_them", "Bake the bowls in the hot ashes",
			"{subject} buried the bowls in glowing ash overnight. In the morning they rang "
			+ "when they were tapped, and none of them leaked.",
			[_earn(&"fired_clay", "Fired Clay")],
		),
		_answer(
			&"keep_drying", "Keep drying them in the sun",
			"The bowls dried in the sun again, and again some of them cracked.",
		),
	])
	return event


## Woven Cloth, the farmers' route.
func _flax_in_the_field() -> EventDef:
	var event: EventDef = _settled_milestone(
		&"flax_in_the_field", "Something in the field", &"nature",
		VillagerState.TRAIT_NATURE_LOVING, SETTLED_DAY[&"woven_cloth"], &"woven_cloth"
	)
	event.requires.append(_cond(SimCondition.Kind.FLAG_SET, &"path_agriculture"))
	event.body = "Among the sown seeds, {subject} noticed a tall plant with pale blue flowers. " \
			+ "When the stems rot in the river, they peel into long, strong fibres."
	event.choices = _choices([
		_answer(
			&"twist_the_fibres", "Twist the fibres into thread",
			"{subject} twisted the fibres into thread, and the thread into a first rough strip "
			+ "of cloth. It was crooked, and everyone wanted a piece.",
			[_earn(&"woven_cloth", "Woven Cloth")],
		),
		_answer(
			&"leave_it_standing", "Leave it standing",
			"The blue flowers were left to go to seed, and the bees were pleased.",
		),
	])
	return event


## Woven Cloth, the herders' route.
func _wool_on_the_thorns() -> EventDef:
	var event: EventDef = _settled_milestone(
		&"wool_on_the_thorns", "Wool on the thorns", &"nature",
		VillagerState.TRAIT_NATURE_LOVING, SETTLED_DAY[&"woven_cloth"], &"woven_cloth"
	)
	event.requires.append(_cond(SimCondition.Kind.FLAG_SET, &"path_herding"))
	event.body = "Tufts of wool hang from every thorn bush along the herd's path. {subject} " \
			+ "has been gathering them in the hem of a tunic."
	event.choices = _choices([
		_answer(
			&"spin_the_wool", "Spin it into thread",
			"{subject} spun the wool on a stick weighted with a stone, and by the new moon "
			+ "there was cloth that kept the wind out.",
			[_earn(&"woven_cloth", "Woven Cloth")],
		),
		_answer(
			&"stuff_the_bedding", "Stuff it into the bedding",
			"The wool went into the bedding, and for a while nobody was cold at night.",
		),
	])
	return event


## Woven Cloth, the late route open to every group.
func _plaited_reeds() -> EventDef:
	var event: EventDef = _settled_milestone(
		&"plaited_reeds", "Mats of reed", &"character", VillagerState.TRAIT_SOCIAL,
		SETTLED_DAY[&"reeds"], &"woven_cloth"
	)
	event.body = "{subject} has been plaiting river reeds into mats, over and under, over and " \
			+ "under. The mat has begun to look like something softer than a mat."
	event.choices = _choices([
		_answer(
			&"show_the_others", "Show the others how it is done",
			"{subject} showed the others the over-and-under, and soon the whole camp was "
			+ "weaving, badly and happily.",
			[_earn(&"woven_cloth", "Woven Cloth")],
		),
		_answer(
			&"keep_it_a_mat", "Keep it a mat",
			"The mat was put down by the door, where it was walked on.",
		),
	])
	return event


## Word from the Hills, first route. The green stone is copper ore; the flag is what the next age
## will read.
func _green_stone_found() -> EventDef:
	var event: EventDef = _settled_milestone(
		&"green_stone_found", "A green stone", &"exploration", VillagerState.TRAIT_CURIOUS,
		SETTLED_DAY[&"green_stone"], &"green_stone"
	)
	event.body = "{subject} brought back a stone from a stream in the hills, streaked bright " \
			+ "green. It sat in the cook fire all night, and in the morning there was a bead of " \
			+ "something red and gold in the ashes."
	event.choices = _choices([
		_answer(
			&"follow_the_stream", "Follow the stream to where it came from",
			"{subject} followed the stream up into the hills and found a cliff streaked green "
			+ "from top to bottom, and came back with a heavy bag.",
			[
				_eff(SimEffect.Kind.SET_FLAG, &"green_stone"),
				_earn(&"green_stone", "Word from the Hills"),
			],
		),
		_answer(
			&"keep_the_bead", "Keep the bead, and ask no more",
			"{subject} strung the bead on a cord, and wears it where the others can see.",
		),
	])
	return event


## Word from the Hills, second route: a traveller brings the same stone.
func _green_stone_traded() -> EventDef:
	var event: EventDef = _event(
		&"green_stone_traded", "A traveller with green beads", &"exploration"
	)
	event.body = "A traveller has come over the hills with a string of bright green stones. " \
			+ "They want grain, and will not say where the stones are from."
	event.requires = _conds([
		_cond(SimCondition.Kind.ERA_AT_LEAST, &"", SETTLED),
		_cond(SimCondition.Kind.ERA_DAYS_AT_LEAST, &"", SETTLED_DAY[&"green_stone"]),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"first_harvest"),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"green_stone", 0, true),
	])
	event.chance_per_tick = 0.02
	event.cooldown_ticks = 72
	event.choices = _choices([
		_answer(
			&"trade_for_stones", "Trade food for a pouch of the stones",
			"The traveller left with a sack of grain, and the group had a pouch of green stones "
			+ "and a rumour of the hills they came from.",
			[
				_spend(&"food", 8), _eff(SimEffect.Kind.SET_FLAG, &"green_stone"),
				_earn(&"green_stone", "Word from the Hills"),
			],
			[_has(&"food", 8)],
		),
		_answer(
			&"send_them_on", "Wish them well and send them on",
			"The traveller was wished well and went on, and the green beads went with them.",
		),
	])
	return event


## A Village, first route: a roof to offer, and travellers who need one.
func _families_on_the_road() -> EventDef:
	var event: EventDef = _event(&"families_on_the_road", "Families on the road", &"exploration")
	event.body = "Two families have stopped at the edge of the fields. They have walked a " \
			+ "long way, and they look at the roofs the way hungry people look at bread."
	event.requires = _conds([
		_cond(SimCondition.Kind.ERA_AT_LEAST, &"", SETTLED),
		_cond(SimCondition.Kind.ERA_DAYS_AT_LEAST, &"", SETTLED_DAY[&"a_village"]),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"first_roof"),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"a_village", 0, true),
	])
	event.chance_per_tick = 0.02
	event.cooldown_ticks = 72
	event.choices = _choices([
		_answer(
			&"make_room", "Make room for them",
			"The two families came in out of the road, and the camp became a village.",
			[_eff(SimEffect.Kind.ADD_VILLAGER, &"", 2), _earn(&"a_village", "A Village")],
		),
		_answer(
			&"point_the_way", "Point them to the next valley",
			"The group pointed the way to the next valley, and gave them bread for it.",
		),
	])
	return event


## A Village, second route: the harvest, shared.
func _the_long_table() -> EventDef:
	var event: EventDef = _settled_milestone(
		&"the_long_table", "The long table", &"character", VillagerState.TRAIT_SOCIAL,
		SETTLED_DAY[&"a_village"], &"a_village"
	)
	event.requires.append(_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"first_harvest"))
	event.body = "{subject} wants to put every board and bench in the camp end to end, and " \
			+ "invite everyone to eat at the same table. It will take a good deal of food."
	event.choices = _choices([
		_answer(
			&"lay_the_table", "Lay the long table for everyone",
			"The boards were laid end to end in the dusk. Nobody could say how many people "
			+ "sat down, but it was more than lived there.",
			[_spend(&"food", 10), _earn(&"a_village", "A Village")],
			[_has(&"food", 10)],
		),
		_answer(
			&"eat_as_usual", "Eat together, as usual",
			"The group ate together as usual, with a little more talk than most nights.",
		),
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
	event.choices = _scout_choices()
	return event


## The same restless villager for a group with no Lookout, a month later (NO_LOOKOUT_DELAY).
func _restless_explorer() -> EventDef:
	var event: EventDef = _curious_explorer()
	event.id = &"restless_explorer"
	event.body = "{subject} keeps wandering to the edge of the western forest to stare at the " \
			+ "ridge beyond it."
	event.requires = _conds([
		_cond(SimCondition.Kind.HAS_BUILDING, &"lookout", 0, true),
		_cond(SimCondition.Kind.FLAG_SET, &"western_forest_explored", 0, true),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", UNLOCK_DAY[&"seed_chain"] + NO_LOOKOUT_DELAY),
	])
	return event


func _scout_choices() -> Array[ChoiceDef]:
	var go: ChoiceDef = _choice(&"encourage", "Let them scout alone")
	go.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"scouted_alone"),
		_eff(SimEffect.Kind.SET_PROFESSION, &"scout"),
		_eff(SimEffect.Kind.SEND_AWAY, &"western_forest", 36),
		_eff(SimEffect.Kind.SCHEDULE_EVENT, &"explorer_returns", 36),
		_eff(SimEffect.Kind.JOURNAL, &"", 0, "{subject} set off to scout the western forest."),
	])
	var together: ChoiceDef = _choice(&"walk_together", "Walk out there together")
	together.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"scouted_together"),
		_eff(SimEffect.Kind.SEND_AWAY, &"western_forest", 60),
		_eff(SimEffect.Kind.SCHEDULE_EVENT, &"explorer_returns", 60),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"The group walked out to the western forest together, slowly, and {subject} led "
			+ "the way back."
		),
	])
	return _choices([go, together])


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
	var seed_needed: Array[SimCondition] = [
		_cond(SimCondition.Kind.ITEM_AT_LEAST, &"strange_seed", 1)
	]
	var plant: ChoiceDef = _choice(&"plant_it", "Plant it in the sun at the cave mouth")
	plant.requires = _conds(seed_needed)
	plant.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"seed_in_sun"),
		_eff(SimEffect.Kind.PLANT, &"strange_seed"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} pressed the strange seed into the sunny soil by the cave mouth."
		),
	])
	var shade: ChoiceDef = 	_choice(&"plant_in_shade", "Plant it in the shade of the overhang")
	shade.requires = _conds(seed_needed)
	shade.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"seed_in_shade"),
		_eff(SimEffect.Kind.PLANT, &"strange_seed"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} pressed the strange seed into the cool soil under the overhang."
		),
	])
	event.choices = _choices([plant, shade])
	return event


func _seed_in_pouch() -> EventDef:
	var event: EventDef = _event(&"seed_in_pouch", "The seed in the pouch", &"exploration")
	event.body = "The strange seed in its hide pouch looks ready to be planted."
	event.requires = _conds([_cond(SimCondition.Kind.ITEM_AT_LEAST, &"strange_seed", 1)])
	event.chance_per_tick = 0.01
	event.cooldown_ticks = 96
	var plant: ChoiceDef = _choice(&"plant_it", "Plant it in the sun at the cave mouth")
	plant.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"seed_in_sun"),
		_eff(SimEffect.Kind.PLANT, &"strange_seed"),
		_eff(SimEffect.Kind.JOURNAL, &"", 0, "The strange seed was planted in the sun at last."),
	])
	var shade: ChoiceDef = 	_choice(&"plant_in_shade", "Plant it in the shade of the overhang")
	shade.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"seed_in_shade"),
		_eff(SimEffect.Kind.PLANT, &"strange_seed"),
		_eff(SimEffect.Kind.JOURNAL, &"", 0, "The strange seed was planted in the shade at last."),
	])
	event.choices = _choices([plant, shade])
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
		_star_watching(), _smoke_in_the_cave(), _tools_pile(), _cold_floors(), _lost_flint(),
		_night_noises(), _the_ford(), _bright_feather(), _bats_in_the_back(), _bee_tree(),
		_fish_run(), _hollow_log(), _first_snow(), _echo_in_the_cave(), _sky_stone(), _warm_pool(),
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
			&"read_the_prints", "Wait for daylight and read the prints together",
			"The group pressed ash over the prints at dawn and read them together: a bear, "
			+ "and an old one.",
			[_set_flag(&"prints_read")],
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
			[_spend(&"food", 12), _set_flag(&"feast_held")],
			[_has(&"food", 12)],
		),
		_answer(
			&"dry_the_rest", "Dry the rest for lean days",
			"The extra was split thin and hung to dry along the cave wall.",
			[_set_flag(&"food_dried")],
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
			[_set_flag(&"fire_turns")],
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
			[_set_flag(&"work_quiet")],
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
			[_set_flag(&"mammoth_distant")],
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
			[_set_flag(&"ridge_watched")],
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
			[_set_flag(&"shared_cave")],
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
			[_spend(&"wood", 6), _set_flag(&"stores_on_ledge")],
			[_has(&"wood", 6)],
		),
		_answer(
			&"trust_the_bank", "Trust the bank",
			"The river rose to the edge of the camp, thought about it, and went back.",
			[_set_flag(&"trusted_bank")],
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
			[_set_flag(&"deer_left")],
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
			[_set_flag(&"stars_private")],
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
			[_set_flag(&"meal_shared")],
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


## Ten small forks added so a workday is never without a question (docs/gameplay.md P10): they
## sit in the longest stretches between the others. Each answer does something and sets a flag
## that a quiet line remembers later.
func _cold_floors() -> EventDef:
	var event: EventDef = _story(
		&"cold_floors", "The cold floor", &"settlement", STORY_DAY[&"floors"],
		"The cave floor is bare rock, and the nights have been cold underneath."
	)
	event.choices = _choices([
		_answer(
			&"hang_hides", "Spread the spare hides over the floor",
			"The hides went down in rows, and the cave smelled of animals and was a good deal warmer.",
			[_set_flag(&"hide_floor")],
		),
		_answer(
			&"cut_reeds", "Cut reeds from the river for bedding",
			"Armfuls of reeds were carried up from the river, and everyone slept on a rustling bed.",
			[_set_flag(&"reed_beds")],
		),
	])
	return event


func _lost_flint() -> EventDef:
	var event: EventDef = _story(
		&"lost_flint", "The missing flint", &"character", STORY_DAY[&"lost_flint"],
		"The best flint in the cave has gone missing, and two of the group are each sure the "
		+ "other has it."
	)
	event.choices = _choices([
		_answer(
			&"wrestle_it_out", "Let them settle it with a wrestle by the fire",
			"They wrestled in the firelight until both were laughing, and the flint turned up in "
			+ "a boot.",
			[_set_flag(&"wrestled")],
		),
		_answer(
			&"search_together", "Turn the whole cave over, everyone together",
			"The whole group searched the cave, and found the flint, and a good many other lost "
			+ "things.",
			[_set_flag(&"searched_together")],
		),
	])
	return event


func _night_noises() -> EventDef:
	var event: EventDef = _story(
		&"night_noises", "Scratching in the night", &"nature", STORY_DAY[&"night_noises"],
		"Something has been scratching at the cave wall after dark, always just out of sight."
	)
	event.choices = _choices([
		_answer(
			&"keep_a_torch", "Keep a torch burning at the cave mouth",
			"A torch burned at the cave mouth all night, and the scratching stopped.",
			[_spend(&"wood", 3), _set_flag(&"torch_at_mouth")],
			[_has(&"wood", 3)],
		),
		_answer(
			&"sleep_deeper", "Move the beds deeper into the cave",
			"The beds were moved to the back of the cave, where the sound could not reach.",
			[_set_flag(&"deep_sleepers")],
		),
	])
	return event


func _the_ford() -> EventDef:
	var event: EventDef = _story(
		&"the_ford", "The hard crossing", &"settlement", STORY_DAY[&"ford"],
		"The river is easiest to cross at one place, and everyone has begun to slip there."
	)
	event.choices = _choices([
		_answer(
			&"lay_stepping_stones", "Lay a line of flat stones across it",
			"A line of flat stones was laid across the shallows, each one carried from the bank.",
			[_set_flag(&"stepping_stones")],
		),
		_answer(
			&"fell_a_log", "Fell a tree to lie across it",
			"A tree came down across the river with a crack, and by dusk everyone had walked over it.",
			[_spend(&"wood", 6), _set_flag(&"log_bridge")],
			[_has(&"wood", 6)],
		),
	])
	return event


func _bright_feather() -> EventDef:
	var event: EventDef = _story_about(
		&"bright_feather", "A bright feather", &"character", STORY_DAY[&"feather"],
		"{subject} found a long blue feather by the river, and has been carrying it about all day.",
		VillagerState.TRAIT_NATURE_LOVING
	)
	event.choices = _choices([
		_answer(
			&"wear_the_feather", "Let them keep it, tied in their hair",
			"{subject} tied the feather into their hair, and walked about as if nobody noticed.",
			[_set_flag(&"feather_worn")],
		),
		_answer(
			&"share_the_feather", "Pin it up in the cave for everyone",
			"The feather was pinned above the fire, where everyone could see it.",
			[_set_flag(&"feather_shared")],
		),
	])
	return event


func _bats_in_the_back() -> EventDef:
	var event: EventDef = _story(
		&"bats_in_the_back", "Bats in the back", &"nature", STORY_DAY[&"bats"],
		"Bats have moved into the back of the cave, and hang from the roof all day in a "
		+ "twitching row."
	)
	event.choices = _choices([
		_answer(
			&"smoke_them_out", "Smoke them out with a green fire",
			"A green fire at the back of the cave sent the bats out in a long dark stream.",
			[_spend(&"wood", 3), _set_flag(&"bats_smoked")],
			[_has(&"wood", 3)],
		),
		_answer(
			&"keep_the_bats", "Leave them, and be glad of the quiet midges",
			"The bats stayed, and the cave stopped being full of midges at dusk.",
			[_set_flag(&"bats_kept")],
		),
	])
	return event


func _bee_tree() -> EventDef:
	var event: EventDef = _story(
		&"bee_tree", "The bee tree", &"nature", STORY_DAY[&"honey"],
		"A hollow tree in the western wood hums with bees, and the comb inside is heavy with honey."
	)
	event.choices = _choices([
		_answer(
			&"take_the_comb", "Take the whole comb, and put up with the stings",
			"They took the whole comb, and sticky, swollen, everyone ate until they ached.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 6), _set_flag(&"honey_taken")],
		),
		_answer(
			&"take_a_little", "Take a little and leave the hive standing",
			"They took one small piece of comb and left the tree humming, and the bees stayed.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 3), _set_flag(&"honey_shared")],
		),
	])
	return event


func _fish_run() -> EventDef:
	var event: EventDef = _story(
		&"fish_run", "The run of fish", &"nature", STORY_DAY[&"fish_run"],
		"The river is full of fish, thick in the shallows, all heading the same way."
	)
	event.choices = _choices([
		_answer(
			&"wade_in", "Wade in with spears and bare hands",
			"Half the camp ended up in the river, and came out soaked, laughing, and carrying fish.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 5), _set_flag(&"fish_by_hand")],
		),
		_answer(
			&"weave_a_trap", "Weave a trap across the narrow channel",
			"A trap of woven willow went across the channel, and by morning it was heavy with fish.",
			[
				_spend(&"wood", 4),
				_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 9),
				_set_flag(&"fish_trap"),
			],
			[_has(&"wood", 4)],
		),
	])
	return event


func _hollow_log() -> EventDef:
	var event: EventDef = _story_about(
		&"hollow_log", "A hollow log", &"character", STORY_DAY[&"drum"],
		"{subject} found a hollow log, and found it made a sound when struck.",
		VillagerState.TRAIT_SOCIAL
	)
	event.choices = _choices([
		_answer(
			&"beat_a_drum", "Stretch a hide over the end, and beat it",
			"{subject} stretched a hide across the log, and the whole valley heard the first drum.",
			[_set_flag(&"log_drum")],
		),
		_answer(
			&"carve_a_flute", "Carve a bone into a pipe instead",
			"{subject} bored holes in a bird bone, and by dusk it was a small clear voice.",
			[_set_flag(&"bone_pipe")],
		),
	])
	return event


func _first_snow() -> EventDef:
	var event: EventDef = _story(
		&"first_snow", "The first snow", &"nature", STORY_DAY[&"first_snow"],
		"Snow fell in the night, and the whole valley is white and silent."
	)
	event.choices = _choices([
		_answer(
			&"build_a_snow_figure", "Build something in the snow at the cave mouth",
			"A snow figure with a stick for an arm stood at the cave mouth, and nobody would "
			+ "say who had made it.",
			[_set_flag(&"snow_figure")],
		),
		_answer(
			&"read_the_tracks", "Walk out and read what has crossed the snow",
			"They followed the tracks of a hare, a fox, and one that nobody could name.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 3), _set_flag(&"snow_tracks")],
		),
	])
	return event


func _echo_in_the_cave() -> EventDef:
	var event: EventDef = _story(
		&"echo_in_the_cave", "The cave answers", &"character", STORY_DAY[&"echo"],
		"Someone shouted into the deep back of the cave, and it shouted back, a moment later."
	)
	event.choices = _choices([
		_answer(
			&"shout_questions", "Shout questions into it, all together",
			"The whole group shouted questions into the dark, and the cave answered every one "
			+ "with the last word.",
			[_set_flag(&"echo_games")],
		),
		_answer(
			&"whisper_and_listen", "Whisper, and listen to what comes back",
			"They whispered into the cave, one at a time, and held their breath for the reply.",
			[_set_flag(&"echo_whispers")],
		),
	])
	return event


func _sky_stone() -> EventDef:
	var event: EventDef = _story(
		&"sky_stone", "A stone from the sky", &"nature", STORY_DAY[&"sky_stone"],
		"A streak of light crossed the sky in the night, and in the morning there is a heavy "
		+ "black stone in the meadow, still warm."
	)
	event.choices = _choices([
		_answer(
			&"keep_the_sky_stone", "Carry it back and keep it by the fire",
			"Four of them carried the black stone to the cave, and it sat by the fire like a guest.",
			[_set_flag(&"sky_stone_kept")],
		),
		_answer(
			&"mark_the_sky_stone", "Leave it where it fell, and ring it with white stones",
			"They ringed the black stone with white pebbles, and left it to the sky.",
			[_set_flag(&"sky_stone_marked")],
		),
	])
	return event


func _warm_pool() -> EventDef:
	var event: EventDef = _story(
		&"warm_pool", "The warm pool", &"nature", STORY_DAY[&"warm_pool"],
		"A pool up the valley steams in the cold, and the water is warm to the hand."
	)
	event.choices = _choices([
		_answer(
			&"bathe_in_it", "Go and bathe in it on the coldest days",
			"They walked up the valley in the frost and sat in the warm pool up to their chins.",
			[_set_flag(&"warm_pool_used")],
		),
		_answer(
			&"carry_the_warmth", "Fill hide bags and carry the warmth home",
			"Hide bags of warm water were carried home, and everyone slept with one at their feet.",
			[_set_flag(&"warm_bags")],
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
			[_spend(&"wood", 8), _set_flag(&"smoke_hole")],
			[_has(&"wood", 8)],
		),
		_answer(
			&"live_with_it", "Live with the smoke",
			"Everyone coughed a little less each year, or said so.",
			[_set_flag(&"smoky_cave")],
		),
	])
	return event


## Small lines for the journal, with nothing asked of the player (gameplay.md P3): some about a
## villager with a trait, some about the world, some that remember an earlier answer.
## Small story decisions that fill the Settled Age between its milestones (docs/ages.md). Like the
## Cave Age's, each has two harmless answers and a journal line, and an answer may set a flag that
## later lines and the next age can read. Costs are bigger than the Cave Age's: by now the stores
## are fuller, and these are what they are for.
func _settled_stories() -> Array[EventDef]:
	return [
		_what_the_cave_is_for(), _marking_the_ground(), _first_furrows(), _pasture_gate(),
		_mending_the_roof(), _the_well(), _the_scarecrow(), _the_herd_dog(), _a_dry_store(),
		_the_quarrel(), _harvest_festival(), _the_oldest_voice(), _the_kiln_pit(), _a_wet_summer(),
		_wild_fowl(), _dyed_cloth(), _the_loom_frame(), _the_flood(), _smoke_in_the_next_valley(),
		_pots_for_salt(), _winter_count(), _green_beads(), _the_low_wall(), _looking_back(),
	]


## A Settled Age story decision: needs the age and the day into it, is asked once, is not about
## anyone.
func _settled_story(
	event_id: StringName, title: String, category: StringName, era_day: int, body: String,
	chance: float = 0.02
) -> EventDef:
	var event: EventDef = _event(event_id, title, category)
	event.body = body
	event.requires = _conds([
		_cond(SimCondition.Kind.ERA_AT_LEAST, &"", SETTLED),
		_cond(SimCondition.Kind.ERA_DAYS_AT_LEAST, &"", era_day),
	])
	event.chance_per_tick = chance
	event.once = true
	return event


func _settled_story_about(
	event_id: StringName, title: String, category: StringName, era_day: int, body: String,
	favoured: StringName
) -> EventDef:
	var event: EventDef = _settled_story(event_id, title, category, era_day, body)
	event.needs_subject = true
	event.subject_requires = _conds([_cond(SimCondition.Kind.SUBJECT_AT_HOME)])
	event.trait_weights[favoured] = 3.0
	return event


func _flag_set(flag: StringName) -> SimCondition:
	return _cond(SimCondition.Kind.FLAG_SET, flag)


func _earned(milestone: StringName) -> SimCondition:
	return _cond(SimCondition.Kind.ACHIEVEMENT_EARNED, milestone)


func _set_flag(flag: StringName) -> SimEffect:
	return _eff(SimEffect.Kind.SET_FLAG, flag)


func _what_the_cave_is_for() -> EventDef:
	var event: EventDef = _settled_story(
		&"what_the_cave_is_for", "What the cave is for", &"settlement", SETTLED_STORY_DAY[&"cave"],
		"The cave is still there, dry and deep, and the group has begun to wonder what it is now for."
	)
	event.choices = _choices([
		_answer(
			&"cave_for_stores", "Make it the winter store",
			"Baskets and jars were carried up to the cave, where the cool dark kept them all winter.",
			[_set_flag(&"cave_store")],
		),
		_answer(
			&"cave_for_elders", "Keep it for sleeping and for the old stories",
			"The cave stayed a place to sleep and to tell the old stories, and the huts filled "
			+ "with the young.",
			[_set_flag(&"cave_kept")],
		),
	])
	return event


func _marking_the_ground() -> EventDef:
	var event: EventDef = _settled_story(
		&"marking_the_ground", "Whose ground", &"settlement", SETTLED_STORY_DAY[&"ground"],
		"Everyone has begun to say \"my plot\" and \"your plot\", and nobody can say where one ends."
	)
	event.choices = _choices([
		_answer(
			&"set_boundary_stones", "Set a stone at every corner",
			"A stone went into every corner, and for a week people walked the lines to look at them.",
			[_spend(&"wood", 4), _set_flag(&"boundary_stones")],
			[_has(&"wood", 4)],
		),
		_answer(
			&"leave_it_open", "Leave the ground open and sort it out as it comes",
			"The ground stayed open, and every dispute was settled over a meal.",
			[_set_flag(&"open_ground")],
		),
	])
	return event


func _first_furrows() -> EventDef:
	var event: EventDef = _settled_story(
		&"first_furrows", "The digging sticks", &"settlement", SETTLED_STORY_DAY[&"furrows"],
		"The seed is sown, but the ground fights back, and another digging stick has snapped."
	)
	event.requires.append(_flag_set(&"path_agriculture"))
	event.choices = _choices([
		_answer(
			&"drag_a_branch", "Drag a forked branch through the soil together",
			"Six people dragged a forked branch across the field, and the furrow ran almost straight.",
			[_set_flag(&"forked_plough")],
		),
		_answer(
			&"dig_by_hand", "Keep digging by hand",
			"The digging went on by hand, slowly, and everyone's back knew about it.",
		),
	])
	return event


func _pasture_gate() -> EventDef:
	var event: EventDef = _settled_story(
		&"pasture_gate", "Into the sown ground", &"settlement", SETTLED_STORY_DAY[&"pasture"],
		"The herd keeps wandering into the small sown plot, and the plot keeps losing."
	)
	event.requires.append(_flag_set(&"path_herding"))
	event.choices = _choices([
		_answer(
			&"build_a_gate", "Weave a hurdle gate",
			"A hurdle of woven withies went up across the gap, and the herd stood and looked at it.",
			[_spend(&"wood", 6), _set_flag(&"hurdle_gate")],
			[_has(&"wood", 6)],
		),
		_answer(
			&"post_a_watcher", "Post someone to watch the plot",
			"Someone sat by the plot all day, and had a very good view of the herd.",
			[_set_flag(&"herd_watch")],
		),
	])
	return event


func _mending_the_roof() -> EventDef:
	var event: EventDef = _settled_story(
		&"mending_the_roof", "Rain through the thatch", &"settlement", SETTLED_STORY_DAY[&"roof"],
		"Rain has found the thatch again, and the dark patch on the ceiling grows every night."
	)
	event.requires.append(_earned(&"first_roof"))
	event.choices = _choices([
		_answer(
			&"patch_it_now", "Patch it while the weather holds",
			"Fresh reed went over the worn thatch, and the next storm drummed on it harmlessly.",
			[_spend(&"wood", 6), _set_flag(&"tight_roofs")],
			[_has(&"wood", 6)],
		),
		_answer(
			&"wait_for_dry", "Wait for dry weather",
			"They waited for dry weather, and put a pot under the drip in the meantime.",
		),
	])
	return event


func _the_well() -> EventDef:
	var event: EventDef = _settled_story(
		&"the_well", "A place to fetch water", &"settlement", SETTLED_STORY_DAY[&"well"],
		"Carrying water from the river twice a day is starting to feel like a way of life."
	)
	event.choices = _choices([
		_answer(
			&"dig_a_well", "Dig a well, and line it with stones",
			"The well went down past the roots of the old tree, and the water that came up tasted of stone.",
			[_spend(&"wood", 8), _set_flag(&"well_dug")],
			[_has(&"wood", 8)],
		),
		_answer(
			&"keep_carrying", "Keep carrying water from the river",
			"They kept carrying water from the river, and everybody grew a good pair of shoulders.",
		),
	])
	return event


func _the_scarecrow() -> EventDef:
	var event: EventDef = _settled_story(
		&"the_scarecrow", "Birds in the field", &"nature", SETTLED_STORY_DAY[&"scarecrow"],
		"The birds have found the field, and they are very pleased with it."
	)
	event.requires.append(_flag_set(&"path_agriculture"))
	event.choices = _choices([
		_answer(
			&"dress_a_scarecrow", "Dress a scarecrow in an old hide tunic",
			"A scarecrow went up in an old tunic. The birds were wary for two days, then sat on its head.",
			[_set_flag(&"scarecrow")],
		),
		_answer(
			&"take_turns", "Take turns chasing them off",
			"They took turns chasing the birds, and by evening everyone was hoarse.",
		),
	])
	return event


func _the_herd_dog() -> EventDef:
	var event: EventDef = _settled_story(
		&"the_herd_dog", "A dog at the fold", &"nature", SETTLED_STORY_DAY[&"dog"],
		"A half-tame dog has taken to following the herd, keeping the stragglers from straying."
	)
	event.requires.append(_flag_set(&"path_herding"))
	event.choices = _choices([
		_answer(
			&"feed_the_dog", "Feed it, and let it stay",
			"The dog was fed, and it stayed, and by the end of the week it had opinions about the herd.",
			[_spend(&"food", 2), _set_flag(&"herd_dog")],
			[_has(&"food", 2)],
		),
		_answer(
			&"shoo_it_off", "Leave it to its own business",
			"The dog was left to its own business, and went on doing it, at a distance, with the herd.",
		),
	])
	return event


func _a_dry_store() -> EventDef:
	var event: EventDef = _settled_story(
		&"a_dry_store", "Damp grain", &"settlement", SETTLED_STORY_DAY[&"store"],
		"The grain in the baskets is going damp at the bottom, and something has been at the rest."
	)
	event.requires.append(_earned(&"first_harvest"))
	event.choices = _choices([
		_answer(
			&"dig_a_store_pit", "Line a pit with clay",
			"A pit lined with clay and capped with a flat stone kept the grain dry and the mice hungry.",
			[_spend(&"wood", 6), _set_flag(&"store_pit")],
			[_has(&"wood", 6)],
		),
		_answer(
			&"hang_the_baskets", "Hang the baskets from the rafters",
			"The baskets were hung from the rafters, out of reach of everything but the swallows.",
		),
	])
	return event


func _the_quarrel() -> EventDef:
	var event: EventDef = _settled_story_about(
		&"the_quarrel", "Over the fence", &"character", SETTLED_STORY_DAY[&"quarrel"],
		"{subject} and a neighbour are not speaking, over a handspan of ground that both of them "
		+ "are sure is theirs.",
		VillagerState.TRAIT_SOCIAL
	)
	event.choices = _choices([
		_answer(
			&"talk_it_through", "Sit them down by the fire together",
			"{subject} and the neighbour were sat by the fire, and by the third pot they were laughing.",
			[_set_flag(&"peacemaking")],
		),
		_answer(
			&"let_it_cool", "Let it cool by itself",
			"It cooled by itself, slowly, and the handspan of ground was never mentioned again.",
		),
	])
	return event


func _harvest_festival() -> EventDef:
	var event: EventDef = _settled_story(
		&"harvest_festival", "More than enough", &"settlement", SETTLED_STORY_DAY[&"festival"],
		"The stores are full for the first time, and nobody can remember a year like it."
	)
	event.requires.append(_earned(&"first_harvest"))
	event.choices = _choices([
		_answer(
			&"hold_the_festival", "Hold a harvest festival",
			"A festival ran from noon to the small hours. There was a lot of dancing and a little singing.",
			[_spend(&"food", 20), _set_flag(&"festival")],
			[_has(&"food", 20)],
		),
		_answer(
			&"lay_it_by", "Lay it by for the lean months",
			"Everything was laid by for the lean months, and the lean months were noticeably less lean.",
		),
	])
	return event


func _the_oldest_voice() -> EventDef:
	var event: EventDef = _settled_story_about(
		&"the_oldest_voice", "Before the huts", &"character", SETTLED_STORY_DAY[&"voice"],
		"{subject} has noticed that the youngest cannot remember the cave, or the cold, or the "
		+ "first fire. They think the camp was always like this.",
		VillagerState.TRAIT_SOCIAL
	)
	event.choices = _choices([
		_answer(
			&"tell_the_whole_story", "Tell it all, from the cold to the first fire",
			"{subject} told it all, from the cold to the first fire, and the youngest listened "
			+ "with their mouths open.",
			[_set_flag(&"cave_tale")],
		),
		_answer(
			&"keep_it_short", "Tell them a short version, and let the rest come later",
			"{subject} told a short version, and said there would be more when they were older.",
		),
	])
	return event


func _the_kiln_pit() -> EventDef:
	var event: EventDef = _settled_story(
		&"the_kiln_pit", "A pit for the pots", &"settlement", SETTLED_STORY_DAY[&"kiln"],
		"Baking pots in hot ashes loses one in three. A proper pit, with a roof and a draught, "
		+ "might lose far fewer."
	)
	event.requires.append(_earned(&"fired_clay"))
	event.choices = _choices([
		_answer(
			&"build_a_kiln", "Build a kiln pit",
			"The kiln pit was lit for the first time at dusk, and nothing came out of it cracked.",
			[_spend(&"wood", 15), _set_flag(&"kiln")],
			[_has(&"wood", 15)],
		),
		_answer(
			&"bake_in_ashes", "Keep baking in the ashes",
			"They went on baking in the ashes, and made a few more pots to cover the cracked ones.",
		),
	])
	return event


func _a_wet_summer() -> EventDef:
	var event: EventDef = _settled_story(
		&"a_wet_summer", "Nine days of rain", &"nature", SETTLED_STORY_DAY[&"wet"],
		"The rain has not stopped for nine days, and the low ground by the river has become a pond."
	)
	event.choices = _choices([
		_answer(
			&"dig_a_ditch", "Dig a ditch to carry the water away",
			"A ditch carried the water off to the river, and the pond sulked and shrank.",
			[_spend(&"wood", 8), _set_flag(&"ditch")],
			[_has(&"wood", 8)],
		),
		_answer(
			&"wait_it_out", "Wait for the rain to stop",
			"The rain stopped on the eleventh day, and the pond took a week to leave.",
		),
	])
	return event


func _wild_fowl() -> EventDef:
	var event: EventDef = _settled_story(
		&"wild_fowl", "Small brown birds", &"nature", SETTLED_STORY_DAY[&"fowl"],
		"A flock of small brown fowl has begun nesting by the huts, as if it had been invited."
	)
	event.choices = _choices([
		_answer(
			&"tempt_them_with_grain", "Scatter a little grain for them",
			"A little grain was scattered each dawn, and by the new moon the birds came when called.",
			[_spend(&"food", 3), _set_flag(&"hens")],
			[_has(&"food", 3)],
		),
		_answer(
			&"let_them_be", "Let them be",
			"The birds were let be, and carried on arguing on the roofs.",
		),
	])
	return event


func _dyed_cloth() -> EventDef:
	var event: EventDef = _settled_story(
		&"dyed_cloth", "A colour for the cloth", &"character", SETTLED_STORY_DAY[&"dye"],
		"The cloth is soft and strong and exactly the colour of a sheep, and someone has started to mind."
	)
	event.requires.append(_earned(&"woven_cloth"))
	event.choices = _choices([
		_answer(
			&"dye_with_berries", "Boil it with berries and bark",
			"The cloth came out of the pot a deep red, and its owner wore it all week.",
			[_spend(&"food", 6), _set_flag(&"dyed_cloth")],
			[_has(&"food", 6)],
		),
		_answer(
			&"keep_it_plain", "Keep it plain",
			"The cloth was kept plain, and was said to be none the worse for it.",
		),
	])
	return event


func _the_loom_frame() -> EventDef:
	var event: EventDef = _settled_story_about(
		&"the_loom_frame", "Two posts and some thread", &"character",
		SETTLED_STORY_DAY[&"loom"],
		"{subject} has propped a frame between two posts and wound thread from end to end. It "
		+ "might weave faster than hands alone.",
		VillagerState.TRAIT_INDUSTRIOUS
	)
	event.requires.append(_earned(&"woven_cloth"))
	event.choices = _choices([
		_answer(
			&"build_a_loom", "Build the loom properly",
			"The loom went up by the door, and the first cloth off it was the widest anyone had seen.",
			[_spend(&"wood", 8), _set_flag(&"loom")],
			[_has(&"wood", 8)],
		),
		_answer(
			&"keep_the_spindle", "Stay with the spindle",
			"They stayed with the spindle, and the frame leaned against a wall and was used for drying.",
		),
	])
	return event


func _the_flood() -> EventDef:
	var event: EventDef = _settled_story(
		&"the_flood", "The river is rising", &"nature", SETTLED_STORY_DAY[&"flood"],
		"The river has risen to the edge of the fields, and the low plots are under a finger of water."
	)
	event.choices = _choices([
		_answer(
			&"build_a_bank", "Raise a bank of earth and stone",
			"A bank of earth and stone went up along the river, and the water stopped at its foot.",
			[_spend(&"wood", 20), _set_flag(&"river_bank")],
			[_has(&"wood", 20)],
		),
		_answer(
			&"move_what_you_can", "Move what you can to higher ground",
			"They moved what they could to higher ground, and the river went down on its own.",
		),
	])
	return event


func _smoke_in_the_next_valley() -> EventDef:
	var event: EventDef = _settled_story(
		&"smoke_in_the_next_valley", "Smoke beyond the ridge", &"exploration",
		SETTLED_STORY_DAY[&"neighbours"],
		"A thin column of smoke rises beyond the ridge, where there was never smoke before."
	)
	event.choices = _choices([
		_answer(
			&"send_a_gift", "Send a gift of grain over the ridge",
			"A sack of grain went over the ridge. A string of shells came back, and a message "
			+ "nobody could read.",
			[_spend(&"food", 12), _set_flag(&"good_neighbours")],
			[_has(&"food", 12)],
		),
		_answer(
			&"watch_and_wait", "Watch, and wait to be visited",
			"They watched the smoke for three days, and the smoke, presumably, watched them.",
		),
	])
	return event


func _pots_for_salt() -> EventDef:
	var event: EventDef = _settled_story(
		&"pots_for_salt", "Salt", &"exploration", SETTLED_STORY_DAY[&"salt"],
		"A trader from the coast has offered a bag of grey salt for a load of fired pots."
	)
	event.requires.append(_earned(&"fired_clay"))
	event.choices = _choices([
		_answer(
			&"trade_pots_for_salt", "Trade a load of pots for the salt",
			"The pots went off on a donkey, and the salt made the winter meat last until spring.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 6), _set_flag(&"salt")],
		),
		_answer(
			&"keep_the_pots", "Keep the pots",
			"The pots were kept, and the trader went away with a polite face and no pots.",
		),
	])
	return event


func _winter_count() -> EventDef:
	var event: EventDef = _settled_story(
		&"winter_count", "Before winter", &"settlement", SETTLED_STORY_DAY[&"count"],
		"The leaves are turning. Somebody has counted the stores twice, and got two different answers."
	)
	event.choices = _choices([
		_answer(
			&"lay_in_more", "Lay in more firewood and set it dry",
			"Firewood was stacked along every wall, and the winter looked at it and thought better of it.",
			[_spend(&"wood", 15), _set_flag(&"winter_ready")],
			[_has(&"wood", 15)],
		),
		_answer(
			&"trust_the_stores", "Trust the stores",
			"The stores were trusted, and held, and nobody said anything about the counting.",
		),
	])
	return event


func _green_beads() -> EventDef:
	var event: EventDef = _settled_story_about(
		&"green_beads", "What the stone does", &"exploration", SETTLED_STORY_DAY[&"beads"],
		"{subject} has been turning the green stone over for days. It is soft enough to scratch, "
		+ "and it does something strange in a hot fire.",
		VillagerState.TRAIT_CURIOUS
	)
	event.requires.append(_earned(&"green_stone"))
	event.choices = _choices([
		_answer(
			&"shape_beads", "Shape it into beads for everyone",
			"{subject} shaped a bead for everyone in the camp, and wearing one became a way of belonging.",
			[_set_flag(&"green_beads")],
		),
		_answer(
			&"try_the_fire", "Put more in the fire, and see what it does",
			"{subject} put more of the green stone in the fire, and at the bottom of the ash there was "
			+ "a bright dribble of metal.",
			[_set_flag(&"copper_tried")],
		),
	])
	return event


func _the_low_wall() -> EventDef:
	var event: EventDef = _settled_story(
		&"the_low_wall", "How far the village goes", &"settlement", SETTLED_STORY_DAY[&"wall"],
		"The village has grown past the edge of anyone's idea of it. Someone has asked where, "
		+ "exactly, it stops."
	)
	event.choices = _choices([
		_answer(
			&"build_a_low_wall", "Raise a low wall of fieldstones",
			"A low wall of fieldstones went up round the village, and everyone sat on it at least once.",
			[_spend(&"wood", 25), _set_flag(&"low_wall")],
			[_has(&"wood", 25)],
		),
		_answer(
			&"keep_it_open", "Leave it open",
			"The village was left open, and the paths went out from it like the spokes of a wheel.",
			[_set_flag(&"open_village")],
		),
	])
	return event


func _looking_back() -> EventDef:
	var event: EventDef = _settled_story_about(
		&"looking_back", "Up at the cave", &"character", SETTLED_STORY_DAY[&"looking_back"],
		"{subject} climbed up to the cave this evening, and sat in the mouth of it for a long while, "
		+ "looking down at the roofs.",
		VillagerState.TRAIT_NATURE_LOVING
	)
	event.choices = _choices([
		_answer(
			&"light_the_cave", "Light a fire in the cave, once every year",
			"A small fire was lit in the cave, and it was agreed that it would be lit again next year.",
			[_set_flag(&"cave_remembered")],
		),
		_answer(
			&"let_it_be", "Let the cave be",
			"The cave was let be, dark and dry, and there were bats in it by spring.",
		),
	])
	return event


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
		_remembered(
			&"fire_banked", &"embers_waited",
			"Someone banked the fire for the night with ash, the way you do with something "
			+ "that was waited for."
		),
		_remembered(
			&"nut_stone_again", &"nut_hammer",
			"The round river stone was cracking nuts again, and still as good as ever."
		),
		_remembered(
			&"tale_by_the_fire", &"tales_told",
			"The story was told again by the fire, everyone in their usual place."
		),
		_remembered(
			&"fire_song", &"songs_sung",
			"Someone started the fire-song, and the whole cave knew the words."
		),
		_remembered(
			&"red_cheek", &"body_paint",
			"A red handprint dried on someone's cheek, and nobody wiped it off."
		),
		_remembered(
			&"newcomer_laughs", &"strangers_welcomed",
			"One of the newcomers laughed by the fire, and the others turned round in surprise."
		),
		_remembered(
			&"food_at_dusk", &"strangers_courted",
			"A bundle of food was set out at dusk again, though the strangers had long since come in."
		),
		_remembered(
			&"scout_boots", &"scouted_alone",
			"The scout's boots stood by the cave mouth, still muddy from the forest."
		),
		_remembered(
			&"walk_to_the_forest", &"scouted_together",
			"Someone told the story of the day the whole camp walked to the western forest."
		),
		_remembered(
			&"sunny_seed", &"seed_in_sun",
			"Someone checked the strange seed in the sun at the cave mouth, for the third time today."
		),
		_remembered(
			&"shady_seed", &"seed_in_shade",
			"Someone crouched under the overhang to look at the strange seed, and said nothing."
		),
		_remembered(
			&"private_sky", &"stars_private",
			"Someone lay awake outside, and nobody asked what they were looking at."
		),
		_remembered(
			&"bear_in_ash", &"prints_read",
			"A bear's paw was drawn in the ash by the fire, to show how big they get."
		),
		_remembered(
			&"feast_song", &"feast_held",
			"Someone was still humming the feast song while scraping out the bowls."
		),
		_remembered(
			&"dried_food", &"food_dried",
			"Dried meat hung along the cave wall, and the whole cave smelled of smoke and berries."
		),
		_remembered(
			&"seat_by_the_fire", &"fire_turns",
			"The best seat by the fire went to someone new tonight, as agreed."
		),
		_remembered(
			&"mammoth_far_edge", &"mammoth_distant",
			"The mammoth watched the camp from the far edge of the grass, and the camp watched back."
		),
		_remembered(
			&"knee_rhythm", &"work_quiet",
			"Someone tapped a rhythm on their knee while they worked, and it was nobody's but theirs."
		),
		_remembered(
			&"ridge_in_the_rain", &"ridge_watched",
			"Someone at the lookout was looking at the ridge again, even in the rain."
		),
		_remembered(
			&"warm_and_crowded", &"shared_cave",
			"It was crowded in the cave tonight, and warm, and nobody minded."
		),
		_remembered(
			&"bank_held", &"trusted_bank",
			"The river was high again. Everyone looked at the bank, and the bank held."
		),
		_remembered(
			&"ledge_stores", &"stores_on_ledge",
			"The stores on the ledge were dry and in easy reach, and everyone was quietly pleased."
		),
		_remembered(
			&"limp_on_the_far_bank", &"deer_left",
			"A deer was seen on the far bank, favouring one leg, and then it was not."
		),
		_remembered(
			&"traveller_word", &"meal_shared",
			"Someone used a word the traveller had said, and was understood by nobody."
		),
		_remembered(
			&"red_eyes", &"smoky_cave",
			"Everyone's eyes were red from the smoke, and everyone laughed about it."
		),
		_remembered(
			&"stars_through_the_roof", &"smoke_hole",
			"The stars showed through the gap in the roof, and the smoke went up to meet them."
		),
		_remembered(
			&"hide_floor_warm", &"hide_floor",
			"Bare feet came down warm on the hide floor, and someone said how good it felt."
		),
		_remembered(
			&"reeds_rustle", &"reed_beds",
			"The reed beds rustled all night, and someone swore they could hear the river in them."
		),
		_remembered(
			&"wrestle_again", &"wrestled",
			"Two of the group wrestled by the fire again, for nothing at all, and both won."
		),
		_remembered(
			&"lost_things", &"searched_together",
			"Somebody turned up another thing that had been lost since the big search."
		),
		_remembered(
			&"torch_at_the_mouth", &"torch_at_mouth",
			"The torch at the cave mouth burned low, and someone got up to trim it."
		),
		_remembered(
			&"back_of_the_cave", &"deep_sleepers",
			"It was very quiet at the back of the cave, and everyone slept late."
		),
		_remembered(
			&"stones_in_the_river", &"stepping_stones",
			"Someone crossed the stepping stones with a full basket, not looking down once."
		),
		_remembered(
			&"log_bridge_creaks", &"log_bridge",
			"The log over the river creaked under three people at once, and held."
		),
		_remembered(
			&"feather_in_hair", &"feather_worn",
			"The blue feather in someone's hair caught the light, and they stood a little taller."
		),
		_remembered(
			&"feather_over_the_fire", &"feather_shared",
			"The blue feather above the fire turned in the warm air, and everyone looked up."
		),
		_remembered(
			&"bats_leave_dusk", &"bats_kept",
			"The bats went out at dusk in a long stream, and the midges did not come."
		),
		_remembered(
			&"smoked_cave", &"bats_smoked",
			"The back of the cave smelled of green smoke for days, and was quiet."
		),
		_remembered(
			&"honey_again", &"honey_taken",
			"Someone was still picking wax out of their hair, and refused to regret it."
		),
		_remembered(
			&"bees_still_there", &"honey_shared",
			"The bee tree hummed on in the western wood, and someone nodded to it passing."
		),
		_remembered(
			&"wet_and_laughing", &"fish_by_hand",
			"Someone was still telling the story of the day everyone went into the river."
		),
		_remembered(
			&"trap_in_the_channel", &"fish_trap",
			"The willow trap in the channel was checked at dawn, and was not empty."
		),
		_remembered(
			&"drum_in_the_valley", &"log_drum",
			"The drum sounded across the valley at dusk, and something answered far off."
		),
		_remembered(
			&"pipe_at_night", &"bone_pipe",
			"A thin pipe tune drifted over the camp, and everyone pretended not to listen."
		),
		_remembered(
			&"snow_figure_stands", &"snow_figure",
			"The snow figure at the cave mouth was still standing, a little lopsided."
		),
		_remembered(
			&"unknown_tracks", &"snow_tracks",
			"Someone drew the unnamed track in the dirt, and nobody could say what made it."
		),
		_remembered(
			&"echo_game", &"echo_games",
			"Someone shouted a nonsense word into the back of the cave, and the cave shouted it back."
		),
		_remembered(
			&"echo_whisper", &"echo_whispers",
			"A whisper came out of the back of the cave, and everyone looked round to see whose."
		),
		_remembered(
			&"stone_by_the_fire", &"sky_stone_kept",
			"The black stone by the fire was warm to the touch long after the fire had burned low."
		),
		_remembered(
			&"ring_of_white", &"sky_stone_marked",
			"Someone walked out to the ring of white stones in the meadow, and stood a while."
		),
		_remembered(
			&"steam_up_the_valley", &"warm_pool_used",
			"A column of steam stood over the pool up the valley, and somebody was already walking to it."
		),
		_remembered(
			&"warm_feet", &"warm_bags",
			"Everyone slept with a bag of warm water at their feet, and not one was cold."
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


## The Settled Age's one-line moments. They carry the age's feel (roofs, fields and herds, pots and
## cloth), several only for the group's path or an earlier answer, and each is a little rarer than
## the Cave Age's because those keep happening too.
func _settled_ambient_lines() -> Array[EventDef]:
	var roofs: Array[SimCondition] = [_earned(&"first_roof")]
	var farmers: Array[SimCondition] = [_flag_set(&"path_agriculture")]
	var herders: Array[SimCondition] = [_flag_set(&"path_herding")]
	return [
		_settled_ambient(
			&"smoke_from_roofs",
			"On still mornings the smoke stood straight up from every roof, each in its own thread.",
			roofs
		),
		_settled_ambient(
			&"swallows",
			"The swallows came back to the eaves, as if the roofs had been built for them.", roofs
		),
		_settled_ambient(
			&"dogs_at_dusk", "The dogs barked at dusk, and somebody answered from the next roof."
		),
		_settled_ambient(
			&"harvest_moon",
			"The moon came up huge and orange over the fields, and work went on by its light."
		),
		_settled_ambient(
			&"worn_path",
			"A path has worn itself between the huts and the river, deep enough to hold the rain."
		),
		_settled_ambient(
			&"smell_of_bread",
			"The smell of flat bread on hot stones drifted over the camp, and people found reasons "
			+ "to pass by.",
			[_earned(&"first_harvest")]
		),
		_settled_ambient(
			&"pots_ring",
			"Someone tapped a pot to hear it ring, and then every pot in the camp had to be tapped.",
			[_earned(&"fired_clay")]
		),
		_settled_ambient(
			&"spindle_turns",
			"A spindle turned in the shade, and the thread grew longer than anyone had noticed.",
			[_earned(&"woven_cloth")]
		),
		_settled_ambient(
			&"rain_on_the_field",
			"Rain came soft and steady all day, and everyone stood in a doorway to watch it fall "
			+ "on the field.",
			farmers
		),
		_settled_ambient(
			&"bleating_at_night",
			"Bleating came across the fold all night. Nobody minded; it meant the herd was there.",
			herders
		),
		_settled_ambient_about(
			&"counting_roofs", VillagerState.TRAIT_CURIOUS,
			"{subject} counted the roofs twice and got two different answers, and counted them "
			+ "a third time."
		),
		_settled_ambient_about(
			&"everyones_business", VillagerState.TRAIT_SOCIAL,
			"{subject} knew everyone's business by noon, and shared it generously."
		),
		_settled_ambient_about(
			&"same_fence", VillagerState.TRAIT_INDUSTRIOUS,
			"{subject} mended the same fence three times in a week, and was not satisfied."
		),
		_settled_ambient_about(
			&"flower_corner", VillagerState.TRAIT_NATURE_LOVING,
			"{subject} sowed one corner of the field with flowers, and nobody had the heart to say "
			+ "anything."
		),
		_settled_ambient_about(
			&"with_the_herd", VillagerState.TRAIT_NATURE_LOVING,
			"{subject} sat with the herd until dark, and said that they were good company.",
			herders
		),
		_settled_remembered(
			&"stores_in_the_cave", &"cave_store",
			"Someone went up to the cave for the winter store, and came back sneezing from the dust."
		),
		_settled_remembered(
			&"well_water", &"well_dug",
			"The water from the new well tasted of stone, and everyone agreed it was better."
		),
		_settled_remembered(
			&"scarecrow_hat", &"scarecrow",
			"The scarecrow was wearing a different hat this morning, and nobody owned up."
		),
		_settled_remembered(
			&"festival_tune", &"festival",
			"Someone began humming the festival tune, and was joined within a bar."
		),
		_settled_remembered(
			&"kiln_night", &"kiln",
			"The kiln was lit, and for a night the whole camp smelled of hot clay."
		),
		_settled_remembered(
			&"red_tunic", &"dyed_cloth",
			"A red tunic crossed the field, and everyone stopped to watch it go."
		),
		_settled_remembered(
			&"wall_at_dusk", &"low_wall",
			"Someone leaned on the low wall at dusk and looked toward the hills for a long time."
		),
		_settled_remembered(
			&"beads_clicking", &"green_beads",
			"Green beads clicked softly as people walked, a small sound the whole camp shared."
		),
	]


## A Settled Age line: only in the age, rarer than a Cave Age line, and only when every one of
## `needs` holds.
func _settled_ambient(
	event_id: StringName, line: String, needs: Array[SimCondition] = []
) -> EventDef:
	var event: EventDef = _ambient(event_id, line)
	event.requires = _conds([_cond(SimCondition.Kind.ERA_AT_LEAST, &"", SETTLED)])
	event.requires.append_array(needs)
	event.chance_per_tick = SETTLED_AMBIENT_CHANCE
	return event


func _settled_ambient_about(
	event_id: StringName, trait_name: StringName, line: String, needs: Array[SimCondition] = []
) -> EventDef:
	var event: EventDef = _settled_ambient(event_id, line, needs)
	event.category = &"character"
	event.needs_subject = true
	event.subject_requires = _conds([
		_cond(SimCondition.Kind.SUBJECT_HAS_TRAIT, trait_name),
		_cond(SimCondition.Kind.SUBJECT_AT_HOME),
		_cond(SimCondition.Kind.SUBJECT_AWAKE),
	])
	return event


func _settled_remembered(event_id: StringName, flag: StringName, line: String) -> EventDef:
	return _settled_ambient(event_id, line, [_flag_set(flag)])


func _build_choice(
	choice_id: StringName, label: String, building: StringName, wood: int, from_day: int = 0,
	from_era_day: int = 0
) -> ChoiceDef:
	var choice: ChoiceDef = _choice(choice_id, label)
	choice.requires = _conds([
		_cond(SimCondition.Kind.HAS_BUILDING, building, 0, true),
		_cond(SimCondition.Kind.RESOURCE_AT_LEAST, &"wood", wood),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", from_day),
	])
	if from_era_day > 0:
		choice.requires.append(_cond(SimCondition.Kind.ERA_DAYS_AT_LEAST, &"", from_era_day))
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
