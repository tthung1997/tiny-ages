# Art tools

Scripts that generate Screenhaven's reference art from code, using LibreSprite. See [engine and art direction](../../docs/engine-and-art.md) for the style rules these implement.

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
| `cave_pages.js` | The two side pages of the Cave Age world: west (forest and ridge) and east (the river, a far bank, an open bay). Writes `west_*` / `east_*` layers to `game/assets/world/cave/` and previews `art/reference/cave_west.png`, `cave_east.png`. All curves are functions of world x, so the hills, sky and tree line meet the camp page's edges without a seam. Run after `cave_strip`, then `--import` |
| `cave_villagers.js` | Per-villager sheets (idle, walk×4, chop×3, hammer×2, spear; 11 cells, facing right) → `game/assets/world/cave/villagers/*.png`; needs `--import` afterwards. If the sheet width changes, delete `art/reference/cave_villagers.png` first so the bundler recreates the canvas |
| `ui_icons.js` | The strip's icons in one 52×20 sheet (idea bulb ×2 frames, journal book) → `game/assets/ui/icons.png` and `art/reference/ui_icons.png`; frame positions are mirrored in `scripts/ui/strip_icons.gd` |
| `ui_skin_hide.js` | The Cave Age panel skin as one 384×192 atlas → `game/assets/ui/skin_hide.png`: the 384×160 hide panel (torn sides, lashed bone rails, ochre handprint), four stitched-leather button states, the bone close button and the wood and food icons. Regions are mirrored in `scripts/ui/panel_skin.gd`; keep the panel height equal to `PanelSkin.PANEL_HEIGHT` |
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
