class_name PanelHost
extends Control
## The panel that opens above the strip: the decision to answer, the journal, or the summary of
## time away. It only shows what the presenters give it and reports what the player picked; the
## game applies it. While it is open the window grows upward by HEIGHT (DesktopWindow). Its look
## comes from a PanelSkin (a stretched hide in the Cave Age) and, in the running game, it unrolls
## upward when it opens and rolls up when it closes.

signal choice_picked(decision_id: StringName, choice_id: StringName)
signal decisions_requested
signal closed
## The open panel switched to content with a different height (the window must follow).
signal height_changed

const WIDTH: int = 384
## The tallest panel, which most content uses. A kind of content with less to show has its own
## shorter height in HEIGHTS.
const HEIGHT: int = PanelSkin.PANEL_HEIGHT
## Panel height by kind of content. A villager's thought is a few short lines, so it gets a short
## panel; the decision, journal and away panels fill a full one.
const HEIGHTS: Dictionary = {&"villager": 112}
const TEXT_WIDTH: float = 352.0
const DAY_WIDTH: float = 34.0
## The unroll is stepped, to match the pixel art.
const UNROLL_STEPS: int = 6
const UNROLL_SECONDS: float = 0.2
const NEED_ICON_SIZE: Vector2 = Vector2(10, 10)
const PORTRAIT_SIZE: Vector2 = Vector2(28, 30)

## True in the running game: the panel unrolls and rolls up. Off by default so it is instant.
var animated: bool = false

var _skin: PanelSkin
var _clip: Control = Control.new()
var _card: PanelContainer = PanelContainer.new()
var _title: Label = Label.new()
var _close: TextureButton = TextureButton.new()
var _scroll: ScrollContainer = ScrollContainer.new()
var _content: VBoxContainer = VBoxContainer.new()
var _footer_label: Label = Label.new()
var _secondary: Button = Button.new()
var _primary: Button = Button.new()
var _mode: StringName = &""
var _height: int = HEIGHT
var _villager_id: StringName = &""
var _open: bool = false
var _reveal: int = 0
var _tween: Tween


func _init() -> void:
	size = Vector2(WIDTH, _height)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_clip)
	_card.size = Vector2(WIDTH, _height)
	_card.custom_minimum_size = Vector2(WIDTH, _height)
	_clip.add_child(_card)
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 2)
	_card.add_child(root)
	var header: HBoxContainer = HBoxContainer.new()
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.clip_text = true
	_close.ignore_texture_size = false
	_close.pressed.connect(close_panel)
	header.add_child(_title)
	header.add_child(_close)
	root.add_child(header)
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 3)
	_scroll.add_child(_content)
	root.add_child(_scroll)
	var footer: HBoxContainer = HBoxContainer.new()
	_footer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_footer_label)
	footer.add_child(_secondary)
	footer.add_child(_primary)
	root.add_child(footer)
	set_skin(PanelSkin.cave())
	_set_reveal(_height)


## The height the panel has for a kind of content.
static func height_for(content_mode: StringName) -> int:
	return int(HEIGHTS.get(content_mode, HEIGHT))


## How much room the open panel needs above the strip, 0 when it is closed.
func current_height() -> int:
	return _height if _open else 0


## Dresses the panel in an age's material. Safe to call while it is showing.
func set_skin(skin: PanelSkin) -> void:
	_skin = skin
	_card.theme = UiTheme.make(skin)
	_card.add_theme_stylebox_override("panel", UiTheme.panel_box(skin, _height))
	_title.add_theme_font_override("font", skin.title_font())
	_title.add_theme_color_override("font_color", skin.title_color)
	_footer_label.add_theme_color_override("font_color", skin.muted)
	_close.texture_normal = skin.piece(skin.close_regions[&"normal"])
	_close.texture_hover = skin.piece(skin.close_regions[&"hover"])
	_close.texture_pressed = skin.piece(skin.close_regions[&"hover"])
	_close.custom_minimum_size = skin.close_regions[&"normal"].size


func skin() -> PanelSkin:
	return _skin


func is_open() -> bool:
	return _open


## Which kind of content is showing: &"decision", &"journal", &"away", &"villager" or &"" when
## closed.
func mode() -> StringName:
	return _mode if _open else &""


func close_panel() -> void:
	if not _open:
		return
	_open = false
	_mode = &""
	if _use_animation():
		_animate_to(0, _finish_close)
	else:
		_finish_close()


## Shows the pending decision at `index` (wrapping). Closes if nothing is pending.
func show_decision(sim: Simulation, index: int = 0) -> void:
	var pending: Array[PendingDecision] = sim.world.pending
	if pending.is_empty():
		close_panel()
		return
	index = posmod(index, pending.size())
	var view: DecisionPresenter = DecisionPresenter.present(pending[index], sim)
	_begin(&"decision", view.title)
	_content.add_child(_text(view.body))
	for choice: DecisionPresenter.ChoiceView in view.choices:
		_content.add_child(_choice_row(view.decision_id, choice))
	_footer_label.text = "" if pending.size() < 2 else "%d of %d waiting" % [index + 1, pending.size()]
	if pending.size() > 1:
		_show_button(_primary, "Next >", func() -> void: show_decision(sim, index + 1))


func show_journal(sim: Simulation) -> void:
	_begin(&"journal", "Journal")
	for entry: Dictionary in JournalPresenter.entries(sim.world):
		_content.add_child(_journal_row(entry["day"], entry["text"]))
	_footer_label.text = ""


## Shows one villager: their picture, traits and what they are thinking. "Next" walks through
## the group.
func show_villager(sim: Simulation, villager_id: StringName) -> void:
	var villager: VillagerState = sim.world.find_villager(villager_id)
	if villager == null:
		close_panel()
		return
	var view: VillagerPresenter = VillagerPresenter.present(villager, sim.world, sim.config)
	_villager_id = villager_id
	_begin(&"villager", view.display_name)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_portrait(view.look, WorldLayout.wears_cloth(sim.world)))
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	var width: float = TEXT_WIDTH - PORTRAIT_SIZE.x - 8.0
	if not view.byline().is_empty():
		column.add_child(_text(view.byline(), true, width))
	column.add_child(_text(view.thought, false, width))
	row.add_child(column)
	_content.add_child(row)
	var group: Array[VillagerState] = sim.world.villagers
	var index: int = group.find(villager)
	if group.size() > 1:
		_footer_label.text = "%d of %d" % [index + 1, group.size()]
		var next: VillagerState = group[(index + 1) % group.size()]
		_show_button(_primary, "Next >", func() -> void: show_villager(sim, next.id))
	else:
		_footer_label.text = ""


## Whose panel is showing, or &"" if it is not the villager panel.
func villager_id() -> StringName:
	return _villager_id if mode() == &"villager" else &""


func show_away(summary: AwaySummary) -> void:
	_begin(&"away", "While you were away (%s)" % summary.duration_text)
	if summary.time_was_skipped:
		_content.add_child(_text("A very long time passed.", true))
	if summary.more_count > 0:
		_content.add_child(_text("... and %d earlier events." % summary.more_count, true))
	for line: String in summary.lines:
		_content.add_child(_text("- " + line))
	if summary.decisions_waiting > 0:
		var word: String = "decision is" if summary.decisions_waiting == 1 else "decisions are"
		_content.add_child(_text("%d %s waiting for you." % [summary.decisions_waiting, word]))
		_show_button(_secondary, "See it", func() -> void: decisions_requested.emit())
	_show_button(_primary, "Got it", close_panel)
	_footer_label.text = ""


func _begin(new_mode: StringName, title_text: String) -> void:
	_mode = new_mode
	_title.text = title_text
	for child: Node in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_secondary.visible = false
	_primary.visible = false
	_scroll.scroll_vertical = 0
	var was_visible: bool = visible
	var was_open: bool = _open
	var resized: bool = _apply_height(height_for(new_mode))
	var already_open: bool = _open and _reveal == _height
	_open = true
	visible = true
	if resized and was_open:
		height_changed.emit()
	if already_open:
		return
	if _use_animation():
		if not was_visible:
			_set_reveal(0)
		_animate_to(_height, Callable())
	else:
		_set_reveal(_height)


## Gives the panel and its art a new height. True if it changed.
func _apply_height(height: int) -> bool:
	if height == _height:
		return false
	_height = height
	size = Vector2(WIDTH, height)
	_card.custom_minimum_size = Vector2(WIDTH, height)
	_card.size = Vector2(WIDTH, height)
	_card.add_theme_stylebox_override("panel", UiTheme.panel_box(_skin, height))
	_set_reveal(mini(_reveal, height))
	return true


func _use_animation() -> bool:
	return animated and is_inside_tree()


func _finish_close() -> void:
	visible = false
	_set_reveal(_height)
	closed.emit()


## The panel rolls out from its bottom edge: the card stays put while the window onto it grows.
func _set_reveal(height: int) -> void:
	_reveal = height
	_clip.position = Vector2(0.0, float(_height - height))
	_clip.size = Vector2(float(WIDTH), float(height))
	_card.position = Vector2(0.0, float(height - _height))


func _animate_to(target: int, done: Callable) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var from: int = _reveal
	var step: int = maxi(_height / UNROLL_STEPS, 1)
	_tween = create_tween()
	_tween.tween_method(
		func(t: float) -> void: _set_reveal(clampi(roundi(lerpf(from, target, t) / step) * step, 0, _height)),
		0.0, 1.0, UNROLL_SECONDS,
	)
	if done.is_valid():
		_tween.tween_callback(done)


## One row per choice: the button, and on its right what it costs, as icons.
func _choice_row(decision_id: StringName, choice: DecisionPresenter.ChoiceView) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	var button: Button = Button.new()
	button.text = choice.label
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(120, 0)
	button.disabled = not choice.enabled
	button.pressed.connect(func() -> void: choice_picked.emit(decision_id, choice.id))
	row.add_child(button)
	if not choice.needs.is_empty():
		row.add_child(_needs_row(choice.needs))
	return row


func _needs_row(needs: Array[DecisionPresenter.NeedView]) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for need: DecisionPresenter.NeedView in needs:
		var icon: Texture2D = _skin.icon_for(need.key)
		var text: String = "%d" % need.amount if need.met else "%d (have %d)" % [need.amount, need.have]
		if icon != null:
			var picture: TextureRect = TextureRect.new()
			picture.texture = icon
			picture.custom_minimum_size = NEED_ICON_SIZE
			picture.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			picture.modulate = Color.WHITE if need.met else Color(1, 1, 1, 0.55)
			row.add_child(picture)
		else:
			text = "%s %s" % [text, String(need.key).replace("_", " ")]
		var label: Label = Label.new()
		label.text = text
		label.add_theme_color_override("font_color", _skin.ink if need.met else _skin.muted)
		row.add_child(label)
	return row


func _journal_row(day: int, text: String) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var day_label: Label = Label.new()
	day_label.text = "Day %d" % day
	day_label.custom_minimum_size = Vector2(DAY_WIDTH, 0)
	day_label.add_theme_color_override("font_color", _skin.day_color)
	row.add_child(day_label)
	var body: Label = _text(text)
	body.custom_minimum_size = Vector2(TEXT_WIDTH - DAY_WIDTH - 4.0, 0)
	row.add_child(body)
	return row


## Reconnects the button each time, so an old action never survives into new content.
func _show_button(button: Button, text: String, action: Callable) -> void:
	for connection: Dictionary in button.pressed.get_connections():
		button.pressed.disconnect(connection["callable"])
	button.text = text
	button.visible = true
	button.pressed.connect(action)


func _text(text: String, muted: bool = false, width: float = TEXT_WIDTH) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(width, 0)
	if muted:
		label.add_theme_color_override("font_color", _skin.muted)
	return label


## The villager's idle frame from their sheet, at the size they are on screen.
func _portrait(look: StringName, cloth: bool) -> TextureRect:
	var path: String = WorldLayout.villager_sheet_path(look, cloth)
	var picture: TextureRect = TextureRect.new()
	var sheet: Texture2D = load(path) as Texture2D
	if sheet != null:
		var cell: AtlasTexture = AtlasTexture.new()
		cell.atlas = sheet
		cell.region = Rect2(Vector2.ZERO, Vector2(WorldLayout.CELL_SIZE))
		picture.texture = cell
	picture.custom_minimum_size = PORTRAIT_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	picture.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	return picture
