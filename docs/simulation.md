# Simulation core

Status: **first slice built and tested**, headless, no UI. Code is in `game/scripts/sim/`, authored content in `game/resources/sim/`, tests in `game/tests/`. Conventions for working on it are in `.github/copilot-instructions.md`.

## Decisions

| Decision | Choice | Notes |
|---|---|---|
| Ending | **None.** Open-ended, with chapter milestones (Camp → Hamlet → Village) as soft endings | Milestones are not built yet. |
| Pace | **1 game day = 20 real minutes**, one tunable constant (`SimConfig.real_seconds_per_game_day`) | A tick is one game hour (50 real seconds). Decision frequency comes from accumulated resources, not the clock, so a long coding session is never punished. |
| Villager autonomy | **Coarse**: each villager has an activity (rest, gather, forage, build, socialize, wander, away); the sim does no path-finding, the view animates it | Traits only bias choices. |
| Persistence | The whole world is one `Resource` saved to `user://`, with a last-seen timestamp | Loading runs script references in the file; only load saves this game wrote. |
| Events | Authored data (`EventDef` + conditions + effects), never code | Anything that can happen is an event template; the sim only decides when. |
| Failure | **Nothing can go wrong.** Decisions wait forever; being away is never punished; there is no hunger, death or timer | Directly from the MVP concept. |

## How it works

- `Simulation.advance_ticks(n)` steps the world exactly; `advance_real_time(now)` turns wall-clock time into ticks, which is also offline catch-up. Catching up for N ticks is guaranteed identical to ticking N times (tested). Catch-up is capped (`max_catch_up_ticks`, default one game year) so a months-long absence cannot stall start-up.
- Each tick: villagers work or sleep → construction progresses → plants grow → scheduled events fire → at most one new event is rolled from the eligible templates.
- An event with choices opens a **pending decision**; it waits until the player resolves it. Choices can require resources, buildings or flags, and a decision never opens if none of its choices are available. The same decision never stacks up, and there is a cap (`max_pending_decisions`) and a cooldown between openings.
- **Consequences** are scheduled events (`SCHEDULE_EVENT`) or flags that later events require, so choices ripple forward ("Theo found a seed → you planted it → it flowered → a rare butterfly came").
- All randomness uses one seeded RNG saved with the world, so a seed plus actions reproduces a world exactly.

## The first slice (content)

3 villagers (Mira: industrious/social; Theo: curious/nature-loving; Wren: social/nature-loving), 3 buildings (Farm, Explorer's Hut, Workshop), 6 events (building opportunity, a curious explorer, the explorer returns, the seed in the jar, a rare butterfly, heavy rain) and 1 plant. Names and numbers are placeholders from the MVP doc's examples. It plays the doc's chain end to end for every tested seed.

## Pacing findings (bot answering every decision immediately)

Measured with `tools/sim_timeline.gd` at 20 real minutes per day:

- The first building decision opens about **4 real minutes** in.
- The whole chain, from the first decision to the rare butterfly, takes about **3 real hours** (day ~10).
- Around **5 decisions in the first 1.5–2 real hours**, then nothing but rain.
- By day 30 the stockpile is ~340 wood and ~470 food with **nothing to spend on**: there are no resource sinks and only three buildings.

So the slice proves the loop works, but the economy is far too generous and content runs out in an afternoon. Both are expected for a slice and are tuning/content work, not design changes: lower `gather_rate`, raise building costs, add buildings and events. The target from the pacing discussion is roughly one decision per 1–2 hours of working, about 4–6 on a normal workday.

## Not built yet

- Settlement stages and the "A Beginning" milestone; seasons, weather and day/night as sim state.
- Relationships and friendship events; more traits and skills; the 15–25 event templates from the MVP.
- Wildlife, visitors, expeditions to other places; the settlement/wilderness balance.
- Any view: the sim has no UI. The next step is to render villagers, the decision bulb and the "while you were away" summary from `WorldState`.

## Open questions

- How long should the first arc really take, and how many decisions per workday feels right? (Playtest with the timeline tool, then tune `SimConfig` and costs.)
- Should the player be able to see or influence villager activity, or is it purely ambient?
- What is the first milestone's trigger (building count, population, a specific building)?
