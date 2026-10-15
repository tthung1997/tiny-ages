class_name TideLook
extends RefCounted
## What the tide looks like on the east beach. Pure and headless: the simulation's `tide_at` gives
## a level (0 lowest, 1 highest) and this says how much wet sand the sea has left showing. Nothing
## here is saved or animated on a clock; the flats just fade with the level.

## Above this level the sea covers the flats; below LOW_LEVEL they show in full.
const HIGH_LEVEL: float = 0.55
const LOW_LEVEL: float = 0.15


## How visible the flats are, from 0 (the sea covers them) to 1 (fully bare).
static func flats_alpha(level: float) -> float:
	return clampf((HIGH_LEVEL - level) / (HIGH_LEVEL - LOW_LEVEL), 0.0, 1.0)
