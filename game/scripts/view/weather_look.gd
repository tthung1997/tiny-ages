class_name WeatherLook
extends RefCounted
## What the weather looks like, and how the season and weather read in words and on the strip's
## glyph. Pure and headless: the view asks, nothing here draws (docs/gameplay.md P14).
##
## Only rain and snow are animated, and a storm and a flood reuse the rain (a storm a little darker).
## Every other weather (a drought, a tornado, wreckage) shows up only as its events, journal lines
## and decisions. Each entry lists what falls (`fall`) and how much it darkens the light (`dim`).
## The sim never reads any of this.

const RAIN: StringName = &"rain"
const SNOW: StringName = &"snow"

const LOOKS: Dictionary = {
	&"rain": {"fall": &"rain", "dim": 0.9},
	&"storm": {"fall": &"rain", "dim": 0.8},
	&"flood": {"fall": &"rain", "dim": 0.88},
	&"snow": {"fall": &"snow", "dim": 0.94},
}
## Cells of the strip glyph sheet (tools/art/ui_seasons.js): the four seasons.
const GLYPH_COUNT: int = 4
## How a weather that falls reads in a line.
const NAMES: Dictionary = {
	&"rain": "rain", &"storm": "a storm", &"flood": "a flood", &"snow": "snow",
}


## What falls from the sky under `weather`: RAIN, SNOW or &"" for nothing.
static func fall(weather: StringName) -> StringName:
	return LOOKS.get(weather, {}).get("fall", &"")


## The colour the light is multiplied by under `weather`: white for any that is not drawn.
static func tint(weather: StringName) -> Color:
	var dim: float = LOOKS.get(weather, {}).get("dim", 1.0)
	return Color(dim, dim, dim)


## The strip glyph for the world now: the season (a sprout, a sun, a leaf, a snowflake).
static func glyph_cell(world: WorldState, config: SimConfig) -> int:
	return config.season_at(world.tick)


## "Late spring" or "Late spring, rain": for the stores panel and the glyph's tooltip. Only what
## falls from the sky is named (rain, a storm, a flood, snow), since that is what is seen.
static func describe(world: WorldState, config: SimConfig) -> String:
	var season: int = config.season_at(world.tick)
	var text: String = Season.describe(
		season, config.day_of_season(world.tick), config.days_per_season
	)
	if LOOKS.has(world.weather):
		text += ", %s" % NAMES[world.weather]
	return text
