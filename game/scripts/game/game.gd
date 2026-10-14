class_name Game
extends Node2D
## The running game: owns the simulation, drives it from the real clock (so being away is
## offline catch-up), saves it, and hosts the world view and the desktop window.
##
## Right-click the strip for the menu (journal, stores, settings, quit); click the bulb (decision
##   waiting) or the book (journal) at the top right of the strip.
##   A/D or arrows pan the view - Home back to camp - drag, wheel or the edge arrows also pan
##   Esc closes the open panel, or saves and quits; Q saves and quits
## Dev keys (only with --dev): 1/2/3 mode - +/- scale - T on-top - P click-through - F fps cap -
##   L low-processor - N next screen - H hide HUD - [ ] time speed - B auto-answer decisions -
##   Y answer one
## Launch args (after `--`): --dev (the dev keys and the text overlay) --hud (just the overlay)
##   --mode= --scale= --fps= --screen= --no-ontop --no-passthrough
##   --no-lowproc  as in the window spike, plus: --new (ignore the save)
##   --nosave (never write the save or the settings, and ignore the saved settings)
##   --save=<path> --speed=<x real time> --era=<age id> (start in
##   that age, for looking at it) --days=<n> (play n game
##   days before showing; the bot answers decisions unless --manual) --bot (auto-answer
##   decisions) --manual --hour=<0-23> (then run on to that hour of the day, for looking at the
##   light) --cam=<camp x> (start with the viewport's left edge there: -384..384,
##   camp is 0) --panel=decision|journal|away|villager|menu|stores|settings (open that panel at
##   start) --shot=<png> (save
##   the rendered viewport after a moment, then quit)

const CONTENT_PATH: String = "res://resources/sim/content.tres"
const CONFIG_PATH: String = "res://resources/sim/sim_config.tres"
const SAVE_INTERVAL_SECONDS: float = 60.0
const CLOCK_INTERVAL_SECONDS: float = 1.0
const HUD_INTERVAL_SECONDS: float = 0.5
const HUD_REGION: Rect2i = Rect2i(0, 0, 300, 56)
const HUD_OFFSET: Vector2 = Vector2(3.0, 2.0)
const SPEEDS: Array[float] = [1.0, 60.0, 600.0, 3600.0]
const MAX_TICKS_PER_FRAME: int = 240
const KEY_PAN_STEP: float = 96.0
const SHOT_DELAY_SECONDS: float = 2.0
## Away for at least this long (and something happened) and the summary opens on launch.
const AWAY_SUMMARY_MIN_SECONDS: float = 300.0
const JOURNAL_PREVIEW_CHARS: int = 64

var sim: Simulation
## What happened while the player was away, from this launch's catch-up.
var last_catch_up: CatchUpReport = CatchUpReport.new()

var _bot: DecisionBot = DecisionBot.new()
var _bot_auto: bool = false
var _manual_days: bool = false
var _last_pending: int = -1
var _panel: PanelHost = PanelHost.new()
var _icons: StripIcons = StripIcons.new()
var _time_scale: float = 1.0
var _tick_budget: float = 0.0
var _clock_timer: float = 0.0
var _save_timer: float = 0.0
var _hud_timer: float = 0.0
var _save_path: String = SaveStore.DEFAULT_PATH
var _settings_path: String = UserSettings.DEFAULT_PATH
var _autosave: bool = true
var _dev: bool = false
var _shot_path: String = ""

@onready var _window: DesktopWindow = $DesktopWindow
@onready var _world_view: WorldView = $World
@onready var _hud: Label = $Hud/Label
@onready var _hud_layer: CanvasLayer = $Hud


func _ready() -> void:
	# The player's saved window settings go in first; launch flags, applied next, win. A run that
	# must not touch the player's files (--nosave) neither reads nor writes them.
	if not OS.get_cmdline_user_args().has("--nosave"):
		UserSettings.load_from(_settings_path).apply_to(_window)
	var options: Dictionary = _apply_cmdline()
	var config: SimConfig = load(CONFIG_PATH) as SimConfig
	var content: ContentLibrary = load(CONTENT_PATH) as ContentLibrary
	var now: float = Time.get_unix_time_from_system()
	var world: WorldState = null
	if not options.get("new", false):
		world = SaveStore.load_world(_save_path)
	if world == null:
		world = WorldFactory.create_new(content, config, _new_seed(), now)
	sim = Simulation.new(world, config, content)
	_apply_dev_world(options)
	last_catch_up = sim.advance_real_time(now)
	for _tick: int in int(options.get("days", 0)) * config.ticks_per_day:
		sim.advance_ticks(1)
		if not _manual_days:
			_bot.answer_all(sim)
	if options.has("hour"):
		for _tick: int in config.ticks_per_day:
			if config.hour_of(sim.world.tick) == options["hour"]:
				break
			sim.advance_ticks(1)
	_world_view.setup(sim, _window)
	if options.has("cam"):
		_world_view.jump_camera(options["cam"])
	_icons.update_pending(0)
	_hud_layer.add_child(_icons)
	_hud_layer.add_child(_panel)
	_panel.animated = true
	_panel.set_skin(PanelSkin.for_era(sim.world.era))
	sim.era_advanced.connect(func(era: EraDef) -> void: _panel.set_skin(PanelSkin.for_era(era.id)))
	_icons.bulb_pressed.connect(_open_decisions)
	_icons.journal_pressed.connect(_toggle_journal)
	_world_view.villager_clicked.connect(_on_villager_clicked)
	_world_view.menu_requested.connect(_on_menu_requested)
	_panel.choice_picked.connect(_on_choice_picked)
	_panel.action_picked.connect(_on_action)
	_panel.decisions_requested.connect(_open_decisions)
	_panel.closed.connect(_fit_window)
	_panel.height_changed.connect(_fit_window)
	_window.layout_changed.connect(_on_layout_changed)
	_hud.visible = options.get("hud", false)
	_refresh_pending()
	_update_hud_region()
	_open_startup_panel(options.get("panel", ""))
	_window.apply()
	if not _shot_path.is_empty():
		await get_tree().create_timer(SHOT_DELAY_SECONDS).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_shot_path)
		get_tree().quit()


func _process(delta: float) -> void:
	_advance_clock(delta)
	_refresh_pending()
	_world_view.update_light()
	_save_timer += delta
	if _autosave and _save_timer >= SAVE_INTERVAL_SECONDS:
		_save()
	_hud_timer -= delta
	if _hud_timer <= 0.0 and _hud.visible:
		_hud_timer = HUD_INTERVAL_SECONDS
		_hud.text = _hud_text()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save()


func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_A, KEY_LEFT:
			_world_view.pan_by(-KEY_PAN_STEP)
		KEY_D, KEY_RIGHT:
			_world_view.pan_by(KEY_PAN_STEP)
		KEY_HOME:
			_world_view.recenter()
		KEY_ESCAPE:
			if _panel.is_open():
				_panel.close_panel()
			else:
				_save()
				get_tree().quit()
		KEY_Q:
			_save()
			get_tree().quit()
		_:
			if _dev:
				_dev_key(key.keycode)


## The keys that only exist with --dev: window knobs, the overlay, time speed and the bot.
func _dev_key(keycode: Key) -> void:
	match keycode:
		KEY_1:
			_window.set_mode(DesktopWindow.Mode.STRIP)
		KEY_2:
			_window.set_mode(DesktopWindow.Mode.CORNER)
		KEY_3:
			_window.set_mode(DesktopWindow.Mode.WINDOW)
		KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
			_window.set_pixel_scale(_window.pixel_scale + 1)
		KEY_MINUS, KEY_KP_SUBTRACT:
			_window.set_pixel_scale(_window.pixel_scale - 1)
		KEY_T:
			_window.set_always_on_top(not _window.always_on_top)
		KEY_P:
			_window.set_click_through(not _window.click_through)
		KEY_F:
			_window.cycle_fps_cap()
		KEY_L:
			_window.set_low_processor(not _window.low_processor)
		KEY_N:
			_window.move_to_next_screen()
		KEY_H:
			_hud.visible = not _hud.visible
			_update_hud_region()
		KEY_BRACKETRIGHT:
			_change_speed(1)
		KEY_BRACKETLEFT:
			_change_speed(-1)
		KEY_B:
			_bot_auto = not _bot_auto
		KEY_Y:
			if _bot.answer_first(sim):
				_world_view.on_world_changed()


func _advance_clock(delta: float) -> void:
	var ticks_before: int = sim.world.tick
	if _time_scale <= 1.0:
		_clock_timer += delta
		if _clock_timer < CLOCK_INTERVAL_SECONDS:
			return
		_clock_timer = 0.0
		sim.advance_real_time(Time.get_unix_time_from_system())
	else:
		_tick_budget += delta * _time_scale / sim.config.seconds_per_tick()
		var whole: int = floori(_tick_budget)
		_tick_budget -= float(whole)
		sim.advance_ticks(mini(whole, MAX_TICKS_PER_FRAME))
		sim.world.last_seen_unix = Time.get_unix_time_from_system()
	if _bot_auto:
		_bot.answer_all(sim)
	if sim.world.tick != ticks_before:
		_world_view.on_world_changed()
		if _panel.mode() == &"villager":
			_panel.show_villager(sim, _panel.villager_id())


func _change_speed(step: int) -> void:
	var index: int = SPEEDS.find(_time_scale)
	index = clampi((index if index >= 0 else 0) + step, 0, SPEEDS.size() - 1)
	_time_scale = SPEEDS[index]


func _save() -> void:
	_save_timer = 0.0
	if _autosave and sim != null:
		SaveStore.save_world(sim.world, _save_path)


func _on_layout_changed(_content_size: Vector2i) -> void:
	var origin: Vector2 = Vector2(_window.art_origin())
	_world_view.position = origin
	_hud.position = origin + HUD_OFFSET
	_icons.position = origin
	_panel.position = Vector2(origin.x, 0.0)
	_world_view.set_full_scene(_window.mode == DesktopWindow.Mode.WINDOW)


func _update_hud_region() -> void:
	var regions: Array[Rect2i] = _world_view.clickable_regions()
	regions.append_array(_icons.clickable_regions())
	if _hud.visible:
		regions.append(HUD_REGION)
	_window.set_extra_regions(regions)


## Keeps the bulb, and the panel if it shows a decision, in step with what is pending.
func _refresh_pending() -> void:
	var waiting: int = sim.world.pending.size()
	if waiting == _last_pending:
		return
	_last_pending = waiting
	_icons.update_pending(waiting)
	_update_hud_region()
	if _panel.mode() == &"decision":
		_panel.show_decision(sim, 0)


func _open_decisions() -> void:
	if sim.world.pending.is_empty():
		return
	_panel.show_decision(sim, 0)
	_fit_window()


func _toggle_journal() -> void:
	if _panel.mode() == &"journal":
		_panel.close_panel()
		return
	_panel.show_journal(sim)
	_fit_window()


## Clicking a villager shows who they are; clicking the same one again puts the panel away.
func _on_villager_clicked(villager_id: StringName) -> void:
	if _panel.villager_id() == villager_id:
		_panel.close_panel()
		return
	_panel.show_villager(sim, villager_id)
	_fit_window()


## A right click on the strip opens the menu; another puts it away.
func _on_menu_requested() -> void:
	if _panel.mode() == &"menu":
		_panel.close_panel()
		return
	_panel.show_menu()
	_fit_window()


## A button in the menu, the stores panel or the settings panel.
func _on_action(action: StringName) -> void:
	match action:
		&"menu":
			_panel.show_menu()
		&"journal":
			_panel.show_journal(sim)
		&"stores":
			_panel.show_stores(sim)
		&"settings":
			_show_settings()
		&"quit":
			_save()
			get_tree().quit()
		&"screen:next":
			_window.move_to_next_screen()
		_:
			_change_setting(action)
	_fit_window()


func _show_settings() -> void:
	_panel.show_settings(UserSettings.from_window(_window), DisplayServer.get_screen_count())


## Applies a window setting picked in the panel, remembers it, and shows the panel again.
func _change_setting(action: StringName) -> void:
	var changed: UserSettings = UserSettings.from_window(_window).changed_by(action)
	changed.apply_live(_window)
	if _autosave:
		changed.save_to(_settings_path)
	_show_settings()


## The window gives the panel room above the viewport while it is open.
## --fire lights the fire; --era=settled enters that age; --build=hut,field completes buildings
## (their milestones too); --flag=path_hunting,cave_art sets world flags; --earn=a_village,
## fired_clay earns achievements; --give=wood:20,food:5 adds stock. For looking at things, not
## playing.
func _apply_dev_world(options: Dictionary) -> void:
	if options.get("fire", false) and not sim.world.has_fire():
		sim.world.flags[&"fire_found"] = true
		sim.world.achievements.append(&"fire")
	if options.has("era") and not sim.advance_era(StringName(options["era"])):
		push_warning("--era=%s is not a later age" % options["era"])
	for building_id: String in String(options.get("build", "")).split(",", false):
		var site: BuildingState = BuildingState.new()
		site.def_id = StringName(building_id)
		sim.world.buildings.append(site)
		sim.complete_building(site)
	for flag: String in String(options.get("flags", "")).split(",", false):
		sim.world.flags[StringName(flag)] = true
	for earned: String in String(options.get("earn", "")).split(",", false):
		if not sim.world.has_achievement(StringName(earned)):
			sim.world.achievements.append(StringName(earned))
	for part: String in String(options.get("give", "")).split(",", false):
		var pair: PackedStringArray = part.split(":")
		if pair.size() == 2:
			sim.world.add_resource(StringName(pair[0]), pair[1].to_int())


func _fit_window() -> void:
	_window.set_panel_height(_panel.current_height())
	_update_hud_region()


## The "while you were away" summary on launch, or a panel chosen by the dev flag --panel=
## (decision, journal, away, villager, menu, stores or settings) so each can be looked at without
## waiting for it to happen.
func _open_startup_panel(requested: String) -> void:
	match requested:
		"decision":
			_open_decisions()
		"journal":
			_toggle_journal()
		"away":
			_panel.show_away(_dev_away_summary())
			_fit_window()
		"villager":
			_panel.show_villager(sim, sim.world.villagers[0].id)
			_fit_window()
		"menu", "stores", "settings":
			_on_action(StringName(requested))
		_:
			var summary: AwaySummary = AwaySummary.present(
				last_catch_up, sim.world, AWAY_SUMMARY_MIN_SECONDS
			)
			if summary != null:
				_panel.show_away(summary)
				_fit_window()


## A made-up report from the latest journal entries, for looking at the panel.
func _dev_away_summary() -> AwaySummary:
	var report: CatchUpReport = CatchUpReport.new()
	report.elapsed_seconds = 8100.0
	for entry: JournalEntry in sim.world.journal.slice(-5):
		report.journal_entries.append(entry)
	return AwaySummary.present(report, sim.world, 0.0)


func _on_choice_picked(decision_id: StringName, choice_id: StringName) -> void:
	if not sim.resolve_decision(decision_id, choice_id):
		return
	_world_view.on_world_changed()
	_refresh_pending()
	if sim.world.pending.is_empty():
		_panel.close_panel()
	else:
		_panel.show_decision(sim, 0)


func _new_seed() -> int:
	return int(Time.get_unix_time_from_system()) ^ int(Time.get_ticks_usec())


func _hud_text() -> String:
	var world: WorldState = sim.world
	var config: SimConfig = sim.config
	var era: EraDef = sim.content.get_era(world.era)
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Day %d  %02d:00  %s   x%s%s" % [
		config.day_of(world.tick) + 1, config.hour_of(world.tick),
		era.display_name if era != null else "?", _time_scale_label(),
		"  BOT" if _bot_auto else "",
	])
	lines.append("wood %d  food %d   villagers %d   buildings %d" % [
		world.resource_amount(&"wood"), world.resource_amount(&"food"),
		world.villagers.size(), _count_built(world),
	])
	lines.append(_pending_line(world))
	if not world.journal.is_empty():
		lines.append("> %s" % world.journal[world.journal.size() - 1].text.left(JOURNAL_PREVIEW_CHARS))
	lines.append("[Y] answer  [B] bot  [ ] ] speed  [1/2/3] mode  [H] hud  [Esc] quit")
	return "\n".join(lines)


func _pending_line(world: WorldState) -> String:
	if world.pending.is_empty():
		return "No decisions waiting"
	var titles: PackedStringArray = PackedStringArray()
	for decision: PendingDecision in world.pending:
		var event: EventDef = sim.content.get_event(decision.event_id)
		titles.append(event.title if event != null else String(decision.event_id))
	return "Waiting: %s" % ", ".join(titles)


func _count_built(world: WorldState) -> int:
	var built: int = 0
	for building: BuildingState in world.buildings:
		if building.complete:
			built += 1
	return built


func _time_scale_label() -> String:
	return "1" if _time_scale <= 1.0 else "%d" % int(_time_scale)


## Dev flags. Window options go straight to the DesktopWindow; the rest is returned.
func _apply_cmdline() -> Dictionary:
	var options: Dictionary = {}
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="):
			var modes: Dictionary = {
				"strip": DesktopWindow.Mode.STRIP, "corner": DesktopWindow.Mode.CORNER,
				"window": DesktopWindow.Mode.WINDOW,
			}
			_window.mode = modes.get(arg.trim_prefix("--mode="), _window.mode)
		elif arg.begins_with("--scale="):
			_window.pixel_scale = clampi(
				arg.trim_prefix("--scale=").to_int(), DesktopWindow.MIN_SCALE, DesktopWindow.MAX_SCALE
			)
		elif arg.begins_with("--fps="):
			_window.fps_cap = maxi(arg.trim_prefix("--fps=").to_int(), 0)
		elif arg.begins_with("--screen="):
			get_window().current_screen = clampi(
				arg.trim_prefix("--screen=").to_int(), 0, DisplayServer.get_screen_count() - 1
			)
		elif arg == "--no-ontop":
			_window.always_on_top = false
		elif arg == "--no-passthrough":
			_window.click_through = false
		elif arg == "--no-lowproc":
			_window.low_processor = false
		elif arg == "--no-hud":
			options["hud"] = false
		elif arg == "--hud":
			options["hud"] = true
		elif arg == "--dev":
			_dev = true
			options["hud"] = true
		elif arg == "--new":
			options["new"] = true
		elif arg == "--nosave":
			_autosave = false
		elif arg.begins_with("--save="):
			_save_path = arg.trim_prefix("--save=")
		elif arg.begins_with("--speed="):
			_time_scale = maxf(arg.trim_prefix("--speed=").to_float(), 1.0)
		elif arg.begins_with("--days="):
			options["days"] = maxi(arg.trim_prefix("--days=").to_int(), 0)
		elif arg.begins_with("--hour="):
			options["hour"] = clampi(arg.trim_prefix("--hour=").to_int(), 0, 23)
		elif arg == "--bot":
			_bot_auto = true
		elif arg == "--manual":
			_manual_days = true
		elif arg == "--fire":
			options["fire"] = true
		elif arg.begins_with("--flag="):
			options["flags"] = arg.trim_prefix("--flag=")
		elif arg.begins_with("--era="):
			options["era"] = arg.trim_prefix("--era=")
		elif arg.begins_with("--build="):
			options["build"] = arg.trim_prefix("--build=")
		elif arg.begins_with("--earn="):
			options["earn"] = arg.trim_prefix("--earn=")
		elif arg.begins_with("--give="):
			options["give"] = arg.trim_prefix("--give=")
		elif arg.begins_with("--panel="):
			options["panel"] = arg.trim_prefix("--panel=")
		elif arg.begins_with("--cam="):
			options["cam"] = arg.trim_prefix("--cam=").to_float()
		elif arg.begins_with("--shot="):
			_shot_path = arg.trim_prefix("--shot=")
	return options
