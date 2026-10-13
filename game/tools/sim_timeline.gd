extends SceneTree
## Plays the simulation with a simple bot and prints the world journal, to eyeball pacing:
##   & $env:GODOT --headless --path game --script res://tools/sim_timeline.gd -- [seed] [days]
## The bot answers every decision immediately with the first choice it can take, preferring
## the Explorer's Hut. Real-time columns use the configured pace (SimConfig).

const BOT_PREFERENCE: Array[StringName] = [
	&"build_explorers_hut", &"encourage", &"plant_it", &"build_farm", &"build_workshop",
]


func _init() -> void:
	var rng_seed: int = 1
	var days: int = 30
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		rng_seed = args[0].to_int()
	if args.size() > 1:
		days = args[1].to_int()
	var config: SimConfig = load("res://resources/sim/sim_config.tres") as SimConfig
	var content: ContentLibrary = load("res://resources/sim/content.tres") as ContentLibrary
	var world: WorldState = WorldFactory.create_new(content, config, rng_seed, 0.0)
	var sim: Simulation = Simulation.new(world, config, content)
	var start_tick: int = world.tick
	for _tick: int in days * config.ticks_per_day:
		sim.advance_ticks(1)
		_answer_decisions(sim)
	print("Seed %d, %d days at %.0f real minutes per day" % [
		rng_seed, days, config.real_seconds_per_game_day / 60.0,
	])
	for entry: JournalEntry in world.journal:
		var real_minutes: float = float(entry.tick - start_tick) * config.seconds_per_tick() / 60.0
		print("  day %2d %02d:00  (+%5.0f real min)  %s" % [
			entry.day + 1, config.hour_of(entry.tick), real_minutes, entry.text,
		])
	print("Stock: wood %d, food %d. Achievements: %s" % [
		world.resource_amount(&"wood"), world.resource_amount(&"food"), world.achievements,
	])
	quit()


func _answer_decisions(sim: Simulation) -> void:
	for decision: PendingDecision in sim.world.pending.duplicate():
		var event: EventDef = sim.content.get_event(decision.event_id)
		var subject: VillagerState = sim.world.find_villager(decision.subject_id)
		var picked: StringName = &""
		for wanted: StringName in BOT_PREFERENCE:
			var choice: ChoiceDef = event.get_choice(wanted)
			if choice != null and sim.choice_available(choice, subject):
				picked = wanted
				break
		if picked == &"":
			for choice: ChoiceDef in event.choices:
				if sim.choice_available(choice, subject):
					picked = choice.id
					break
		if picked != &"":
			sim.resolve_decision(decision.id, picked)
