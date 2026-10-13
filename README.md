# Screenhaven

A personal project exploring a small world that lives on your screen.

## Project notes

- [MVP concept](docs/mvp-concept.md) — the initial idea and scope notes.
- [Engine and art direction](docs/engine-and-art.md) — Godot + LibreSprite decisions, style rules, pipeline.
- [Art tools](tools/art/README.md) — scripts that generate the reference art (`art/reference/`).

## Godot project

The game lives in [`game/`](game/) (Godot **4.7**, standard build, GDScript).

1. Install [Godot 4.7](https://godotengine.org/download) (standard, not .NET).
2. In Godot choose **Import** and select `game/project.godot`, then press **F5**.
3. The [Godot AI](game/addons/godot_ai/README.md) editor plugin (MCP server for AI
   tooling) is committed and enabled, so it starts with the project — connect your
   MCP client from the **Godot AI** dock.

For command-line tooling, point `$env:GODOT` at a **console** build (or put
`godot_console` on `PATH`), then validate with `pwsh -File game/tools/check.ps1`.
Conventions are in [`.github/copilot-instructions.md`](.github/copilot-instructions.md).

This repository is a private workspace for the project. It currently contains the concept, the art/engine direction, the art-generation scripts and an empty Godot scaffold (it shows the reference strip as a smoke test); no game code yet.
