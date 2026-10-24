# Art tools

Scripts that generate Tiny Ages' reference art from code, using LibreSprite. See [engine and art direction](../../docs/engine-and-art.md) for the style rules these implement.

## Requirements

- LibreSprite 1.1-dev (tested) — set `LIBRESPRITE_EXE` if it is not on `PATH`.
- Python 3 (bundler uses only the standard library; `preview.py` needs Pillow).

## Run

```powershell
$env:LIBRESPRITE_EXE = "S:\LibreSprite\libresprite.exe"
python tools/art/bundle.py --run      # strip -> villager sheet -> workshop stages -> night
python tools/art/preview.py           # optional upscaled previews in art/reference/previews/
```

Run one script: `python tools/art/bundle.py --run strip`. `night` reads the day strip, so run `strip` first.

Without `--run`, `bundle.py` only writes `tools/art/dist/<name>.bundle.js` (git-ignored); paste one into the libresprite MCP `run_script` tool or run it from LibreSprite's Scripts menu.

## Layout

| File | Purpose |
|---|---|
| `lib.js` | Pixel buffer, outline, palettes, `vil()` villager, props, workshop stages |
| `strip.js` | Day strip scene, drawn as layers → `art/reference/strip_v2.png` (composite) and `art/reference/layers/strip_*.png` |
| `cave_strip.js` | Cave Age strip sketch (cliff and cave, furs, stone tools, mammoth, slice buildings) → `art/reference/cave_strip.png` and `layers/cave_*.png` |
| `cave_strip.js` also | exports the game's 384×80 layers (backdrop, static props, per-building and site pieces, flower stages) to `game/assets/world/cave/` |
| `cave_pages.js` | The two side pages of the Cave Age world: west (forest and ridge) and east (the river, a spit that runs into a beach, the sea). Writes `west_*` / `east_*` layers to `game/assets/world/cave/` and previews `art/reference/cave_west.png`, `cave_east.png`. All curves are functions of world x, so the hills, sky and tree line meet the camp page's edges without a seam. Run after `cave_strip`, then `--import` |
| `cave_river.js` | The river's Cave Age pieces → `game/assets/world/cave/`: `crossing_stones` / `crossing_log` (camp page) and `east_crossing_stones` / `east_crossing_log` (the same span on the east page, since it crosses the seam), `river_trap`, `reed_bundles`. The span runs x 302–476 over three gravel bars; mirrored in `world_layout.gd` (`CROSSING_X`) and `scene_props.gd`. Needs `--import` afterwards. Preview `art/reference/cave_river.png` |
| `cave_pages.js` also | Writes the east page's river life: `east_life_0..2` (fish rising, birds on the two tallest reed clumps), `east_deer_0..1` (a doe at the bank, head down and up) and `east_tide_flats_<step>_<frame>` (the wet flats low tide leaves: 3 steps of how far out, 3 foam frames each); no random numbers, so the older art does not change. Frame counts are mirrored in `world_layout.gd` (`LIFE_FRAMES`, `DEER_FRAMES`) |
| `cave_villagers.js` | Per-villager sheets (idle, walk×4, chop×3, hammer×2, spear; 11 cells, facing right) → `game/assets/world/cave/villagers/*.png`; needs `--import` afterwards. If the sheet width changes, delete `art/reference/cave_villagers.png` first so the bundler recreates the canvas |
| `ui_icons.js` | The strip's icons in one 110×20 sheet (idea bulb ×2 frames, journal book, menu gear, the wood and food icons, the two trend arrows and three pip rows of the stock gauge) → `game/assets/ui/icons.png` and `art/reference/ui_icons.png`; positions are mirrored in `scripts/ui/strip_icons.gd`. If the sheet width changes, delete `art/reference/ui_icons.png` first so the bundler recreates the canvas |
| `ui_achievements.js` | The achievement icons: 22 round medals (20×20 each) in one 440×20 sheet, one per achievement in the order of `AchievementPresenter.ICON_ORDER` and a plain rosette last for any without its own → `game/assets/ui/achievements.png` and `art/reference/ui_achievements.png`; needs `--import` afterwards. A new achievement needs a cell appended here (before the rosette) and in `ICON_ORDER`, and `GENERIC_ICON` and the sheet width grow with it; delete `art/reference/ui_achievements.png` first so the bundler recreates the canvas at the new width (a test checks every grantable achievement has one) |
| `game_icon.js` + `make_icon.py` | The game icon, a campfire under stars with a small villager: a 32×32 sprite → `art/reference/game_icon.png`; then `python tools/art/make_icon.py` scales it (nearest) into `game/icon.png` (256 px, the project icon) and `game/icon.ico` (16–256 px, `application/windows_native_icon`, used when exporting) |
| `ui_skin_hide.js` | The Cave Age panel skin as one 384×192 atlas → `game/assets/ui/skin_hide.png`: the 384×160 hide panel (torn sides, lashed bone rails, ochre handprint), four stitched-leather button states, the bone close button and the wood and food icons. Regions are mirrored in `scripts/ui/panel_skin.gd`; keep the panel height equal to `PanelSkin.PANEL_HEIGHT` |
| `ui_skin_clay.js` | The Settled Age panel skin, same 384×192 atlas layout → `game/assets/ui/skin_clay.png`: a timber frame (pegged beams, side posts) round a plastered clay wall with straw flecks, a woven zig-zag and a wheat ear, four fired-clay tile button states, a wooden-peg close button, and planks and a loaf as the wood and food icons. Regions are shared with the hide skin in `scripts/ui/panel_skin.gd` |
| `ui_skin_bronze.js` | The Bronze Age panel skin, same 384×192 atlas layout → `game/assets/ui/skin_bronze.png`: a hammered-bronze frame (rivets, a verdigris fleck) round a sun-baked mud-brick wall, a Greek key under the title and an oxhide ingot, four bronze-plate button states, a bronze rivet close button, and a log with a plank and a haunch as the wood and food icons. Regions are shared with the other skins in `scripts/ui/panel_skin.gd` |
| `settled_camp.js` | The Settled Age's first world pieces → `game/assets/world/settled/`: `building_hut` / `site_hut` (a thatched roundhouse), `building_field` / `site_field` (ripe wheat) at the old camp slots, and, for the west page, `west_plot_farm`, `west_plot_patch` and `west_pen` (a fenced pen with three goats), plus what answers and milestones put on the ground: `pots`, `cloth_line`, `cloth_dyed`, `loom`, `low_wall`, `green_stones`, `hens`, `west_kiln`, `west_well`, `west_scarecrow`, `west_roof_a`, `west_roof_b` (`SceneProps` decides when each shows), and the river's Settled pieces: `clay_pits`, `flax_thread`, `flax_beaten`, `river_bank`, `boat_dugout`, `boat_raft` (camp page) and `east_tide_weir` (east page); `low_wall` is a dry-stone wall with timber posts along the back lane (page-local x 59..383, a gate near x 205..229), and the east page's coast props `east_salt_pans`, `east_shell_heap`, `east_driftwood_stack`, `east_tide_baskets`, each placed in ground the east art leaves free. Slots are mirrored in `world_layout.gd` (`BUILDINGS`) and `scene_props.gd`; needs `--import` afterwards. Previews `art/reference/settled_camp.png` |
| `bronze_camp.js` | The Bronze Age's world pieces → `game/assets/world/bronze/`, drawn in mud-brick, copper and dark timber: `building_smithy` / `site_smithy` (workshop, clay furnace and chimney, anvil stone, ingots under a bronze-red sign) and `building_trading_post` / `site_trading_post` (a timber stall under a striped awning with a balance) as new camp slots; `building_hut` / `site_hut` (the Hut's slot redrawn as a mud-brick house), `boat_dugout` (now a planked boat) and `boat_raft` (now a reed ship under a sail), which upgrade the Settled slots in place under the same names; `west_roof_a` / `west_roof_b` (mud-brick houses), and three tidy pieces that each replace several Settled props: `potters_yard` (kiln, shelf of pots, tray, clay heap), `weavers_row` (loom, cloth line, flax) with `weavers_row_dyed` (only the dyed cloth, an unoutlined overlay that sits exactly inside the line's outline), and `town_wall` (a crenellated mud-brick wall along the back lane, x 59..383, with buttresses, an end pier, a corner tower and a gate tower over an open arch, replacing `low_wall`); and `east_sail` (a trading ship over the open sea, east page); later additions: `road_camp` (a flat packed-earth backdrop strip), `building_quay` / `site_quay` (a timber pier into the river) and `quay_boats` (a planked boat and a reed boat tied up, replacing the free-floating boats), `building_lookout` / `site_lookout` (the Lookout's slot redrawn as a mud-brick gate tower), `crossing_planks` / `east_crossing_planks` (a plank bridge on the Cave crossing's span, one drawing cut at the page seam), and on the west page `market_stalls`, `cart` and `donkeys`. Slots are mirrored in `world_layout.gd` and `scene_props.gd`; needs `--import` afterwards. Previews `art/reference/bronze_camp.png`, `bronze_west.png`, `bronze_east.png` |
| `weather.js` | Rain and snow as one 384×480 sheet of 80 px rows (no outline, transparent light and shade) → `game/assets/world/weather.png`: rain ×3 and snow ×3, each a falling loop. Rows are mirrored in `scripts/view/weather_layer.gd`; needs `--import` afterwards |
| `ui_seasons.js` | The strip's season glyphs: 4 cells of 12×12 (spring sprout, summer sun, autumn leaf, winter snowflake) in one 48×12 sheet → `game/assets/ui/season_glyphs.png`; cells are the `Season` order |
| `settled_villagers.js` | The same three villagers in woven tunics (palettes `clothMira`, `clothTheo`, `clothWren`, `cloth: true` in `vil`) → `game/assets/world/settled/villagers/<id>.png`, 308×30, 11 cells like the Cave sheets; the game swaps to them once `woven_cloth` is earned. Also draws the field clothes (palettes `fieldMira`…, `outfit: 'field'`: hemp tunic, rope belt, rolled sleeves, bare feet) → `settled/villagers/field/<id>.png`, worn from the turn of the age. Needs `--import` afterwards |
| `bronze_villagers.js` | The Bronze Age outfits, same sheet layout (`townMira`…, `outfit: 'town'`: long belted tunic with a red hem, hooded cloak, boots; `outfit: 'fittings'`: the same plus a bronze pin, buckle and arm rings) → `game/assets/world/bronze/villagers/town/<id>.png` and `.../fittings/<id>.png`, worn from the turn of the age and once `first_casting` is earned. `VillagerOutfit` picks the sheet. Needs `--import` afterwards |
| `role_overlays.js` | The role overlays: one transparent 308×30 PNG per profession (`smith`, `trader`, `forager`, `scout`), the same eleven 28×30 cells as the villager sheets, holding only what the role adds (smith: dark leather apron, bronze hammer at the belt, brick-red headband; trader: leather pack under a bright rolled blanket, belt pouch; forager: woven back-basket of greens on a strap; scout: teal scarf with tails streaming behind, small pack) so the game can draw one over any look and outfit → `game/assets/world/roles/<profession>.png`. Placement rules (torso x 10–15, body raised 1 px in walk cells 2 and 4) are in the script header. `role_preview.py` (run by `bundle.py` after it) composites the four over real bodies, three looks and outfits, into `art/reference/role_overlays.png`; needs `--import` afterwards |
| `cave_celestial.js`, `cave_stars.js` | The sun and moon (one 32×16 sheet, two 16×16 cells) and the night sky's stars (384×56) → `game/assets/world/cave/celestial.png`, `stars.png`; the game moves them by the hour |
| `night.js` | Palette-shifted night variant → `strip_v2_night.png` (the old prototype; the game tints the scene instead) |
| `villager_sheet.js` | Walk/work frames, role overlays, hair variants |
| `villager_walk.js` | Transparent 4-frame walk cycle used by the Godot spike |
| `workshop_stages.js` | Site → frame → half-built → complete |
| `bundle.py` | Prepends `app.open()` header + `lib.js`, creates missing blank canvases, optionally runs the bundle |
| `preview.py` | Nearest-neighbour previews |

## Adding a script

1. Create `tools/art/<name>.js` starting with `// @open art/reference/<file>.png` and `// @canvas <W>x<H>` (`// @nolib` to skip `lib.js`).
2. Use `SPR` (the opened sprite) to write pixels: `SPR.layer(0).cel(0).image.putImageData(buf.d); SPR.save();`.
3. Add the name to `SCENES` in `bundle.py` and run `bundle.py --run <name>`.

Scripts are deterministic (seeded RNG): re-running reproduces identical pixels. LibreSprite gotchas are listed in the design doc.
