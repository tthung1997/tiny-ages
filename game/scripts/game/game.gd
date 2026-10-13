class_name Game
extends Node2D
## The running game: owns the simulation, drives it from the real clock (so being away is
## offline catch-up), saves it, and hosts the world view and the desktop window.
##
## Keys (dev): 1/2/3 mode - +/- scale - T on-top - P click-through - F fps cap - L low-processor
##   N next screen - H hide HUD - [ ] time speed - B auto-answer decisions - Y answer one
##   A/D or arrows pan the view - Home back to camp - drag, wheel or the edge arrows also pan
##   Esc/Q save and quit
## Launch args (after `--`): --mode= --scale= --fps= --screen= --no-ontop --no-passthrough
##   --no-lowproc --no-hud  as in the window spike, plus: --new (ignore the save)
##   --nosave (never write the save) --save=<path> --speed=<x real time> --days=<n> (play n game
##   days with the bot before showing) --bot (auto-answer decisions) --cam=<camp x> (start with
##   the viewport's left edge there: -384..384, camp is 0) --shot=<png> (save the
##   rendered viewport after a moment, then quit)

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
const JOURNAL_PREVIEW_CHARS: int = 64

var sim: Simulation
## What happened while the player was away, from this launch's catch-up.
var last_catch_up: CatchUpReport = CatchUpReport.new()

var _bot: DecisionBot = DecisionBot.new()
var _bot_auto: bool = false
var _time_scale: float = 1.0
var _tick_budget: float = 0.0
var _clock_timer: float = 0.0
var _save_timer: float = 0.0
var _hud_timer: float = 0.0
var _save_path: String = SaveStore.DEFAULT_PATH
var _autosave: bool = true
var _shot_path: String = ""

@onready var _window: DesktopWindow = $DesktopWindow
@onready var _world_view: WorldView = $World
@onready var _hud: Label = $Hud/Label


func _ready() -> void:
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
	last_catch_up = sim.advance_real_time(now)
	for _tick: int in int(options.get("days", 0)) * config.ticks_per_day:
		sim.advance_ticks(1)
		_bot.answer_all(sim)
	_world_view.setup(sim, _window)
	if options.has("cam"):
		_world_view.jump_camera(options["cam"])
	_window.layout_changed.connect(_on_layout_changed)
	_hud.visible = options.get("hud", true)
	_update_hud_region()
	_window.apply()
	if not _shot_path.is_empty():
		await get_tree().create_timer(SHOT_DELAY_SECONDS).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_shot_path)
		get_tree().quit()


func _process(delta: float) -> void:
	_advance_clock(delta)
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
		KEY_A, KEY_LEFT:
			_world_view.pan_by(-KEY_PAN_STEP)
		KEY_D, KEY_RIGHT:
			_world_view.pan_by(KEY_PAN_STEP)
		KEY_HOME:
			_world_view.recenter()
		KEY_B:
			_bot_auto = not _bot_auto
		KEY_Y:
			if _bot.answer_first(sim):
				_world_view.on_world_changed()
		KEY_ESCAPE, KEY_Q:
			_save()
			get_tree().quit()


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


func _change_speed(step: int) -> void:
	var index: int = SPEEDS.find(_time_scale)
	index = clampi((index if index >= 0 else 0) + step, 0, SPEEDS.size() - 1)
	_time_scale = SPEEDS[index]


func _save() -> void:
	_save_timer = 0.0
	if _autosave and sim != null:
		SaveStore.save_world(sim.world, _save_path)


func _on_layout_changed(_content_size: Vector2i) -> void:
	_world_view.position = Vector2(_window.art_origin())
	_hud.position = Vector2(_window.art_origin()) + HUD_OFFSET
	_world_view.set_full_scene(_window.mode == DesktopWindow.Mode.WINDOW)


func _update_hud_region() -> void:
	var regions: Array[Rect2i] = _world_view.clickable_regions()
	if _hud.visible:
		regions.append(HUD_REGION)
	_window.set_extra_regions(regions)


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
		elif arg == "--bot":
			_bot_auto = true
		elif arg.begins_with("--cam="):
			options["cam"] = arg.trim_prefix("--cam=").to_float()
		elif arg.begins_with("--shot="):
			_shot_path = arg.trim_prefix("--shot=")
	return options
