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
| `night.js` | Palette-shifted night variant → `strip_v2_night.png` |
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
