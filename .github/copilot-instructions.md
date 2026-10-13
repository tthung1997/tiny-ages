# Screenhaven — Copilot Instructions

Screenhaven is a **2D desktop-companion game** built with **Godot 4.7** and
**GDScript** (standard build, not .NET): a tiny settlement that lives at the edge of
the screen. The Godot project is in **`game/`**; everything else in the repo is
docs, art sources and art tooling.

Read before designing anything:

- `docs/mvp-concept.md` — what the game is and, just as important, what it is **not**
  (no clicker loops, no timers, no FOMO, no LLM, no combat).
- `docs/engine-and-art.md` — engine/art decisions, style rules, open questions.

The MVP is a concept, not a spec. Do not invent systems, data models or progression
beyond what those docs say. When a request is ambiguous, ask. This file covers *how*
to write code here, not *what* to build.

## Non-negotiables

- **Godot 4 API only.** Godot 3 snippets are the most common failure mode:
  `yield` → `await`, `instance()` → `instantiate()`, `KinematicBody2D` →
  `CharacterBody2D`, `export` → `@export`, `onready` → `@onready`,
  `connect("sig", self, "_m")` → `sig.connect(_m)`, `emit_signal("sig")` →
  `sig.emit()`. `move_and_slide()` takes no arguments.
- **No C#.** No `.cs` files, no `[Export]` / `GetNode<T>()`.
- **Static typing everywhere** — `var speed: float = 0.0`,
  `func take(n: int) -> void:`. Use `:=` only when the type is unambiguous on the
  same line. Nested typed collections (`Array[Array[int]]`) are not supported.
- **Every reusable script gets a `class_name`.** Search for collisions first.
- Tabs, LF, lines ≤ 100 characters. `snake_case` files/functions/variables,
  `PascalCase` classes/nodes/enum names, `CONSTANT_CASE` constants and enum members,
  `_leading_underscore` for private members, signals in the past tense. Prefer
  `and`/`or`/`not`. `.editorconfig` enforces whitespace; Godot's official style guide
  covers the rest.

## Declaration order

```
@tool / @icon, @abstract, class_name, extends, ## doc comment
signals, enums, constants, static vars, @export vars, regular vars, @onready vars
_static_init, static methods
_init, _enter_tree, _ready, _process, _physics_process, other virtuals
remaining methods, inner classes
```

Enums come **before** constants; `@onready` comes **last** among variables.

## Engine idioms

| Don't | Do |
| --- | --- |
| `get_node("../../X")` | `@export var x: Node2D`, wired in the editor, or `%UniqueName` |
| Polling a flag in `_process` | A `signal`, connected with `.connect()` |
| Input checks in `_process` | `_input()` / `_unhandled_input()` |
| Deep inheritance | Composition — child nodes for discrete behaviours |
| Hardcoded tunables | `@export` vars or a custom `Resource` |
| `get_nodes_in_group()` every frame | Cache in `_ready()` |
| A `Timer` node for a one-off delay | `await get_tree().create_timer(0.5).timeout` |
| `queue_free()` then touching the node | Free last, or guard `is_instance_valid()` |
| `load()` in a hot path | `preload()` or `@export var scene: PackedScene` |
| A dictionary of magic numbers | A `Resource` subclass with typed `@export`s |

- **Calls go down, signals come up.** A child never reaches up the tree. Every
  scene should run standalone (F6).
- **Connect signals in code**, not in the editor. Disconnect capturing lambdas
  explicitly.
- `await` is a coroutine, not a thread; guard with `is_instance_valid(self)` after a
  long await.
- Use `is` / `is not` / `assert()` for type checks; `as` silently yields `null`.

## Architecture rules specific to Screenhaven

- **Simulation is separate from rendering.** The settlement sim (characters, needs,
  events, time) must run without drawing and be testable headless. Prefer
  `RefCounted` for sim objects; nodes only render and forward input.
- **Offline catch-up is timestamp-based.** Store a last-seen time; on launch advance
  the sim in coarse steps and summarise as journal entries, never resource dumps.
- **The game must be cheap when ignored.** No per-frame work that is not visible.
  Frame-rate caps and render pausing are decided in the window spike — do not
  hard-code them elsewhere.
- **Nothing is demanded of the player.** No timers that expire, no penalties for
  being away, no sound/flash notifications by default.
- **Data belongs in Resources** (events, buildings, traits, journal entries), not
  JSON loaders or dictionaries. Resources are shared by default — `.duplicate()` or
  *Local to Scene* when you need a per-instance copy.
- **No game autoloads without justification.** The only entry today is
  `_mcp_game_helper`, owned by the committed Godot AI plugin
  (`game/addons/godot_ai/`); leave it alone. No global event bus.

## Fail loudly

```gdscript
if not ResourceLoader.exists(path):
	push_error("Missing resource: %s" % path)
	return null
```

`push_error` for faults, `push_warning` for recoverable problems. Prefer guard
clauses. No `print()` in committed code.

## Godot 4.7 specifics

Docs: <https://docs.godotengine.org/en/4.7/>.

- Mouse/keyboard device IDs are `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD`,
  not `0`. Dispatch on event type.
- An override of a method with a typed return inherits that return type and needs an
  explicit `return`.
- `CanvasItem` line drawing no longer adds an antialiasing feather.
- Third-party content comes from the **Asset Store**; the Asset Library is gone.

## Project layout

```
docs/                 design notes and decisions
art/reference/        generated reference PNGs (1x) + previews
tools/art/            LibreSprite art-generation scripts (see its README)
game/                 the Godot project (open game/project.godot)
  scenes/             .tscn, mirroring scripts/   (ui/ for menus, HUD, overlays)
  scripts/sim/        the settlement simulation: headless, no nodes (see below)
  scripts/game/       `Game`: owns the sim, real-time clock, save/autosave, dev flags
  scripts/view/       the on-screen world: `WorldView`, villager actors, planner (see below)
  scripts/ui/         the panels and strip icons: presenters (pure, tested), `PanelHost`, `StripIcons`
  scripts/window/     desktop-window handling;  scripts/dev/  dev/spike scenes
  assets/             art/audio/fonts the game loads — only what is in use
  resources/sim/      authored sim content (.tres): config, events, buildings, plants
  tests/              test suites (test_*.gd) and shared fixtures
  tools/              one-off Godot CLI/editor scripts, not shipped code
  addons/godot_ai/    committed Godot AI (MCP) editor plugin — do not edit
```

### The simulation (`game/scripts/sim/`)

Plain `RefCounted` rules over plain `Resource` state, so it runs headless and is
reproducible from a seed. Never put node or scene-tree code in it; the view reads
`WorldState` and calls `Simulation`'s public methods and signals.

- `state/` — `WorldState` and the things it holds. Everything saved is an `@export` field.
- `data/` — authored definitions: `SimConfig` (all tunables, incl. the 20 min/day pace),
  `ContentLibrary`, `EraDef`, `EventDef`, `ChoiceDef`, `SimCondition`, `SimEffect`,
  `BuildingDef`, `PlantDef`. Content is data, never code: add new behaviour as a `Kind` on
  a condition or effect. **Append enum members at the end** — saved `.tres` files store the
  integer. Ages are linear and gated by hidden milestones plus a minimum time (`EraDef`,
  `ADVANCE_ERA`, forward only); gate content with `ERA_AT_LEAST` (see `docs/ages.md`).
- `systems/` — `VillagerSystem`, `ConstructionSystem`, `PlantSystem`, `EventSystem`,
  `EraSystem`, `EffectRunner`, driven by `Simulation._step()`. All randomness uses
  `Simulation.rng`. `EraSystem` opens the next age when its hidden gate is met (required
  achievements and a minimum time, on `EraDef`); the gate is never shown to the player.
  New worlds start without fire (`fire_found`); tests that are about something later use
  `SimFixture.new_sim()`, which starts lit (pass `lit = false` for the fire story).
- Time is ticks (`ticks_per_day`, default 24). `advance_ticks` is exact; offline catch-up
  is `advance_real_time(now)` and must equal ticking the same amount.
- Design rules baked in: decisions wait indefinitely and never penalise waiting; nothing
  fails or kills; open-ended with chapter milestones, no ending.
- Content seeds come from `tools/build_sim_content.gd` (a bootstrap — after running it,
  edit the `.tres` in the inspector; re-running overwrites them). `ContentLibrary.validate()`
  must stay empty; a test enforces it. Pacing numbers live in its tables: `UNLOCK_DAY`
  (milestones), `STORY_DAY` (the small story decisions between them), `AMBIENT_CHANCE`,
  `GATHER_RATE`; `SimConfig.comfortable_stock` stops villagers and buildings piling up stock.
  A story decision is `_story`/`_story_about` plus `_answer` choices (two answers, both
  harmless, a journal line each, a flag for later lines); a quiet moment is `_ambient`,
  `_ambient_about` (a trait) or `_remembered` (a flag). Costs are a `_has` requirement plus
  a `_spend` effect, so the panel shows "needs 8 wood".
- `tools/sim_timeline.gd` plays a bot through the sim and prints the journal with real-time
  offsets, every question asked, the longest wait between them and the stock: use it to
  judge pacing instead of guessing (`-- <seed> <days>`).

### The world view (`game/scripts/view/`)

The view only reads `WorldState`; it never changes it, and the sim never knows it exists.
`Game` calls `WorldView.on_world_changed()` after the sim advances.

- Every art piece (`game/assets/world/cave/*.png`) is a full 384×80 transparent sprite
  already at its final position, so placing it is `position = (0, 0)`. Draw order is z =
  the foot row (see `WorldLayout`). `WorldLayout` mirrors the slots in `tools/art/cave_strip.js`:
  change both together.
- **The world is wider than the viewport** (decision A8). Everything lives in "camp pixels":
  the camp page is x 0..384, the world runs from `WorldLayout.WORLD_LEFT` (−384) to
  `WORLD_RIGHT` (768), and the viewport shows one 384 px page. `WorldView` keeps a scrolling
  container inside a clipping `Control`; `ScrollCamera` (pure, tested) clamps, glides and
  rounds to whole pixels; `ScrollUi` and `PanArrow` are the edge arrows and page dots. The
  side pages have their own art (`west_*`, `east_*`, from `tools/art/cave_pages.js`; see
  `WorldLayout.SIDE_PAGES`). The camp's river blocks the whole ground at its east edge, so
  the east is water and villagers wander west only; arrivals come from the west.
- **Clickable region across the scroll**: `WorldView` builds a world-wide `Skyline` and the
  `DesktopWindow` reads the slice in view (`set_skyline`, `set_scroll`); the arrows and HUD
  are `set_extra_regions` so they stay clickable. Anything drawn must be inside that polygon
  on Windows (it clips drawing).
- `VillagerPlanner` (pure logic, tested) turns a villager's activity into a spot and pose;
  `VillagerActor` walks and animates; away or sleeping villagers are hidden. A plan's
  `focus_x` is where to face on arrival and can be negative (the world runs west of the camp):
  test `has_focus()`, never `>= 0`.
- `DayNight.tint(hour)` drives a `CanvasModulate` (darker nights while `WorldState.has_fire()` is false).
  The fire pit (`fire_pit_0..3`, flame frames, with the firelight in the cave mouth) is state-driven like a
  building and only shows once the fire is found; it flickers on a 0.2 s clock that sleeps unless the fire is lit
  and in view. `fire_glow.png` is an additive glow that fades in with the dark while there is
  fire. Before fire the group gathers in the cave mouth. Wood is cut at the west forest. Sky and far hills only show in the opaque
  window (decision A7); strip and corner mode keep near hills, trees and ground.
- Art regenerates with `python tools/art/bundle.py --run cave_strip cave_pages cave_villagers`,
  then `--import` and commit the `.import` files.
- Dev flags for `scenes/main.tscn` are listed in `scripts/game/game.gd` (`--new`, `--nosave`,
  `--days=N`, `--manual`, `--bot`, `--speed=`, `--cam=`, `--panel=`, `--shot=`). Always use
  `--nosave` (or `--save=`) in automated runs so the player's save is not touched. To check
  GUI input without touching the real mouse, push events with
  `get_viewport().push_input(event, true)` (local coordinates) from a temporary script (and
  remove it afterwards); the headless test runner has no running tree for it.

### The panels (`game/scripts/ui/`)

What the player is shown is built by pure presenters, so it is tested without nodes:
`DecisionPresenter` (title, text and choices; a choice is *listed* if only stock stops it,
*enabled* if nothing does; staged unlocks are never listed), `JournalPresenter`, `AwaySummary`,
`VillagerPresenter` (a clicked villager's name, traits, role and a thought that follows what they
are doing, whether there is fire, and whether food is low; a pure function of the world, so it
holds still between ticks).
`PanelHost` draws them above the strip and only reports the choice picked; `Game` applies it
with `Simulation.resolve_decision`. While a panel is open `DesktopWindow.set_panel_height`
grows the window upward and the click region takes in the panel. `StripIcons` is the bulb and
the journal book. The sim withdraws a decision the world has moved past
(`Simulation.withdraw_stale_decisions`), so the UI never asks a stale question.

**Skins, one per age** (`PanelSkin`, `UiTheme`): a skin is the age's material, colours, font and
where each piece sits in its atlas (`tools/art/ui_skin_<age>.js`). To add an age: draw the atlas,
add a factory to `PanelSkin.skins()`; `Game` swaps the skin on `era_advanced`, and an age without
one uses the Cave skin. The panel's art height is `PanelSkin.PANEL_HEIGHT` and must match the
atlas. The font (`assets/fonts/PixelifySans.ttf`, OFL, licence beside it) is set with no
antialiasing; sizes should stay at 12 (titles use the bold weight). Dev flags for looking at
panels: `--panel=decision|journal|away|villager`, `--manual`, `--fire`, `--flag=path_hunting`,
`--give=wood:6`,
`--hour=12`.

Keep a script and its scene at mirrored paths. Every PNG in `game/assets/` is
imported as a texture whether or not it is used — do not add art until it is in use.
`game/assets/preview/strip_v2.png` is a scaffold smoke test and is meant to be
replaced.

Settings that shape the code: base resolution **384×80** shown at 768×160 (2×) with
`canvas_items` stretch and **integer** scale mode, **Nearest** default texture
filter, **`gl_compatibility`** renderer. Art style rules (outline, palette, scale)
are in `docs/engine-and-art.md`; pixel art must stay integer-scaled.

## Files you must not hand-edit

- **`.uid` files** — Godot generates them; commit them; move them with their script.
- **`.import` sidecars** — generated; after adding art/audio/fonts run
  `--headless --path game --import` and commit what it writes.
- **`game/addons/godot_ai/`** and the `[autoload]` / `[editor_plugins]` entries in
  `game/project.godot` that it owns. The plugin updates itself; do not patch it.
- **The `[input]` section of `project.godot`** — write a `tools/setup_input.gd`
  script and let the engine serialise events.
- **Anything under `game/.godot/`** — generated and ignored.
- **`art/reference/*.png`** — generated by `tools/art/`; change the scripts instead.

## Writing `.tscn` / `.tres` by hand

Prefer building scenes in the editor (or via the Godot AI MCP tools). When hand-
authoring is unavoidable:

- Put `script = ExtResource(...)` **before** the exported properties it sets.
- `ExtResource`/`SubResource` ids must be unique and match references exactly.
- Omit `load_steps` and `uid`; never invent a `uid`. Write `format=3`.
- The first `[node]` is the root and takes no `parent=`.

## Commands

Resolve the engine from `$env:GODOT` or `godot_console`/`godot`/`godot4` on `PATH`.
Use a `_console` build — the plain Windows `.exe` prints nothing.

```powershell
pwsh -File game/tools/check.ps1                                  # validate
pwsh -File game/tools/run_game.ps1 [--nosave --days=12 --bot]    # run the game standalone
pwsh -File game/tools/run_spike.ps1 [--mode=...]                 # run the old window spike
& $env:GODOT --headless --path game --import                     # import new assets
& $env:GODOT --headless --path game --script res://tools/x.gd    # run a tool script
python tools/art/bundle.py --run                                 # regenerate reference art
```

Window behaviour (borderless, transparent, always-on-top, click-through) does **not** work
when the editor embeds the running game in its Game tab, so test it with
`run_game.ps1` or `run_spike.ps1` (or untick "Embed Game on Next Play"). `scenes/main.tscn` is the main scene;
the old spike is `scenes/dev/window_spike.tscn`. Both take a `--shot=<png>` launch arg that
saves the rendered viewport, alpha included, for automated visual checks.
On Windows, `DisplayServer.window_set_mouse_passthrough()` also clips drawing — anything
that must be visible has to be inside the passthrough polygon.

## Before you claim something works

Run `pwsh -File game/tools/check.ps1`. It parses every `.gd` file with
`--check-only`, boots the project, then runs every suite in `game/tests/` headlessly
(`tools/run_tests.gd`; suites extend `McpTestSuite`; run one with `-- <suite name>`). The
editor's `test_run` MCP tool cannot run them. **Do not** substitute
`--headless --path . --quit`: it only parses scripts reachable from the main scene
and exits 0 even when it prints a parse error.

New simulation behaviour needs a test, and a bug fix needs a test that fails without it.
Tests must be deterministic: seed the sim, and assert outcomes, not exact random rolls.

A clean check proves only that code parses and loads. It says nothing about behaviour
or feel — never claim a timing, window or visual change is right; describe what to
look for and let the human check it. Window behaviour (transparency, click-through,
always-on-top, multi-monitor/DPI) can only be verified on a real desktop.

## Things to avoid

- Inventing game systems or adding anything the MVP concept excludes.
- Adding addons or plugins unasked.
- `class_name` collisions — search before naming.
- Hardcoding absolute machine paths in committed files.
- Bundling a large refactor with a feature.
- Generating `.md` documentation unless asked.
