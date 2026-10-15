class_name WeatherLook
extends RefCounted
## What the weather looks like, and how the season and weather read in words and on the strip's
## glyph. Pure and headless: the view asks, nothing here draws (docs/gameplay.md P14).
##
## Each weather lists what it shows: `fall` (what falls from the sky), `dim` (how much it darkens
## the light), `tint` (a colour cast), and the pieces `clouds`, `water`, `shimmer`, `cracks` and
## `funnel`. The sim never reads any of this.

const RAIN: StringName = &"rain"
const SNOW: StringName = &"snow"

const LOOKS: Dictionary = {
	&"rain": {"fall": &"rain", "dim": 0.9},
	&"storm": {"fall": &"rain", "dim": 0.74, "clouds": true},
	&"flood": {"fall": &"rain", "dim": 0.88, "water": true},
	&"drought": {"tint": Color(1.0, 0.92, 0.78), "shimmer": true, "cracks": true},
	&"snow": {"fall": &"snow", "dim": 0.94},
	&"tornado": {"dim": 0.7, "clouds": true, "funnel": true},
	&"debris": {"dim": 0.96},
}
## How each weather reads in a line ("Late spring, rain").
const NAMES: Dictionary = {
	&"rain": "rain", &"storm": "a storm", &"flood": "flood", &"drought": "drought",
	&"snow": "snow", &"tornado": "a tornado", &"debris": "wreckage",
}
## Cells of the strip glyph sheet (tools/art/ui_weather.js): the four seasons, then the weather.
const SEASON_GLYPHS: Array[int] = [0, 1, 2, 3]
const WEATHER_GLYPHS: Dictionary = {
	&"rain": 4, &"snow": 5, &"storm": 6, &"drought": 7, &"flood": 8, &"tornado": 9, &"debris": 10,
}
const GLYPH_COUNT: int = 11


## What falls from the sky under `weather`: RAIN, SNOW or &"" for nothing.
static func fall(weather: StringName) -> StringName:
	return LOOKS.get(weather, {}).get("fall", &"")


## Whether `weather` shows the piece `what` (&"clouds", &"water", &"shimmer", &"cracks" or
## &"funnel").
static func shows(weather: StringName, what: StringName) -> bool:
	return LOOKS.get(weather, {}).get(what, false)


## The colour the light is multiplied by under `weather`: white for a clear sky.
static func tint(weather: StringName) -> Color:
	var look: Dictionary = LOOKS.get(weather, {})
	var dim: float = look.get("dim", 1.0)
	var cast: Color = look.get("tint", Color.WHITE)
	return Color(cast.r * dim, cast.g * dim, cast.b * dim)


## The strip glyph for the world now: the weather while there is some, else the season.
static func glyph_cell(world: WorldState, config: SimConfig) -> int:
	if WEATHER_GLYPHS.has(world.weather):
		return WEATHER_GLYPHS[world.weather]
	return SEASON_GLYPHS[config.season_at(world.tick)]


## "Late spring" or "Late spring, rain": for the stores panel and the glyph's tooltip.
static func describe(world: WorldState, config: SimConfig) -> String:
	var season: int = config.season_at(world.tick)
	var text: String = Season.describe(
		season, config.day_of_season(world.tick), config.days_per_season
	)
	if NAMES.has(world.weather):
		text += ", %s" % NAMES[world.weather]
	return text
