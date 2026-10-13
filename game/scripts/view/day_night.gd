class_name DayNight
extends RefCounted
## The light over the settlement through the day: a smooth tint keyed by the hour.

const HOURS: Array[float] = [0.0, 5.0, 6.5, 8.0, 17.0, 19.0, 21.0, 24.0]
const COLORS: Array[Color] = [
	Color(0.42, 0.48, 0.74),
	Color(0.42, 0.48, 0.74),
	Color(1.0, 0.84, 0.76),
	Color(1.0, 1.0, 1.0),
	Color(1.0, 1.0, 1.0),
	Color(1.0, 0.8, 0.66),
	Color(0.5, 0.52, 0.78),
	Color(0.42, 0.48, 0.74),
]


## The tint for an hour of the day in [0, 24).
static func tint(hour: float) -> Color:
	var clamped: float = clampf(hour, 0.0, 24.0)
	for index: int in range(1, HOURS.size()):
		if clamped <= HOURS[index]:
			var span: float = HOURS[index] - HOURS[index - 1]
			var amount: float = (clamped - HOURS[index - 1]) / span if span > 0.0 else 1.0
			return COLORS[index - 1].lerp(COLORS[index], amount)
	return COLORS[COLORS.size() - 1]


## Hour of day as a float, including the fraction of the current tick.
static func hour_of_world(world: WorldState, config: SimConfig) -> float:
	var into_day: float = float(posmod(world.tick, config.ticks_per_day)) + world.tick_fraction
	return into_day * 24.0 / float(config.ticks_per_day)
