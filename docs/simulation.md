# Simulation core

Status: **first slice built and tested**, headless, no UI. Code is in `game/scripts/sim/`, authored content in `game/resources/sim/`, tests in `game/tests/`. Conventions for working on it are in `.github/copilot-instructions.md`.

## Decisions

| Decision | Choice | Notes |
|---|---|---|
| Ending | **None.** Open-ended, with chapter milestones (Camp → Hamlet → Village) as soft endings | Milestones are not built yet. |
| Pace | **1 game day = 20 real minutes**, one tunable constant (`SimConfig.real_seconds_per_game_day`) | A tick is one game hour (50 real seconds). Decision frequency comes from accumulated resources, not the clock, so a long coding session is never punished. |
| Villager autonomy | **Coarse**: each villager has an activity (rest, gather, forage, build, socialize, wander, away, and hunt once the group has chosen to hunt); the sim does no path-finding, the view animates it | Traits only bias choices. |
| Persistence | The whole world is one `Resource` saved to `user://`, with a last-seen timestamp | Loading runs script references in the file; only load saves this game wrote. |
| Events | Authored data (`EventDef` + conditions + effects), never code | Anything that can happen is an event template; the sim only decides when. |
| Failure | **Nothing can go wrong.** Decisions wait forever; being away is never punished; there is no hunger, death or timer | Directly from the MVP concept. |

## How it works

- `Simulation.advance_ticks(n)` steps the world exactly; `advance_real_time(now)` turns wall-clock time into ticks, which is also offline catch-up. Catching up for N ticks is guaranteed identical to ticking N times (tested). Catch-up is capped (`max_catch_up_ticks`, default one game year) so a months-long absence cannot stall start-up.
- Each tick: villagers work or sleep → construction progresses → plants grow → scheduled events fire (dropped if their `requires` no longer hold) → at most one new event is rolled from the eligible templates → the era gate is checked.
- An event with choices opens a **pending decision**; it waits until the player resolves it. Choices can require resources, buildings or flags, and a decision never opens if none of its choices are available. The same decision never stacks up, and there is a cap (`max_pending_decisions`) and a cooldown between openings. If the world moves past a pending decision (the fire was lit another way), the sim **withdraws** it; waiting for resources or a later day never does.
- **Consequences** are scheduled events (`SCHEDULE_EVENT`) or flags that later events require, so choices ripple forward ("Theo found a seed → you planted it → it flowered → a rare butterfly came").
- All randomness uses one seeded RNG saved with the world, so a seed plus actions reproduces a world exactly.

## The first slice (content)

Re-themed as the **Cave Age** (see [ages](ages.md)), with the turn into the **Settled Age**.

- 2 eras (Cave, Settled), 3 starting villagers drawn at random per world from pools of 24 names, 4 traits and 3 looks (always at least one curious one), 5 buildings and 64 events, 1 plant. Of the events, 17 are the milestones, the fire story, the exploration chain and weather; 22 are the small story decisions that fill the Cave Age (see `ages.md`, "between the milestones"); 25 are one-line journal moments.
- Cave Age buildings: Lookout, Drying Rack, Knapping Spot. Settled Age buildings: Field, Hut (they only appear once settled).
- **The world starts without fire.** A curious villager may find a burning tree, or an industrious one may strike a spark; passing on either lights the fire anyway via embers. Nothing can be built until there is fire.
- The chain: fire → build the Lookout → a curious villager asks to scout the western forest → they return with a seed → you plant it → it flowers → a rare butterfly visits.
- **The Settled Age is gated** (`EraSystem`, `EraDef`): it needs all six milestones (Fire, Stone Tools, Enough to Eat, Shared Stories, A Bigger Group, Unexpected Garden; each has more than one route, see `ages.md`) plus **8640 ticks (5 real days)** in the Cave Age. The player is shown none of this. When the gate opens, the age-turn event asks *how* to settle (by the field, or where the herds winter), and either answer advances the era.
- Era-gated content uses `ERA_AT_LEAST` conditions on the era's `order`; `ADVANCE_ERA` moves forward only.
- Names and numbers are placeholders from the MVP doc's examples. It plays end to end for every tested seed, for players who accept everything and for players who pass on things first.

## Pacing findings (bot answering every decision immediately)

Measured with `tools/sim_timeline.gd` at 20 real minutes per day:

- Fire is found at about **18 real minutes**, and after that the first decisions follow.
- With the milestones **staged** (one table, `UNLOCK_DAY` in `tools/build_sim_content.gd`: Stone Tools from game day 18, Enough to Eat 54, Shared Stories 108, A Bigger Group 162, the seed chain 216; 72 game days per real day), a bot that answers instantly earns them at roughly **6.5 h**, **18 h**, **36 h**, **56 h** and **73 h** of real time, then the Settled Age opens at 5 days. The buildings that would grant a milestone early are staged too.
- The spread is right and the gaps are now filled: the small story decisions and journal moments (`ages.md`, "between the milestones") leave a bot that answers at once with about **29 questions** across the five days, never more than about **9 real hours** apart, and a journal line roughly every 20 real minutes. `tools/sim_timeline.gd` prints the questions, the longest wait and the stock every 30 days.
- **The economy** was far too generous (thousands of wood by day 400). It is now leaner: `gather_rate` 0.06, building costs 8-14 wood, building output about a tenth of before, and a **comfortable stock** (`SimConfig.comfortable_stock`, 40): once a store reaches it villagers rarely gather that resource and buildings stop adding to it. Stock now hovers and ends the age at roughly 100-200 of each, with several choices that spend it (frost, shelter, river, feast, the traveller). A test keeps it under 300.
- The earlier slice-only findings (kept for the record): by day 30 the old stockpile was hundreds of wood and food with nothing to spend on, because there were no resource sinks and only three buildings.

The target from the pacing discussion is roughly one decision per 1-2 hours of working, about 4-6 on a normal workday.

## Not built yet

- Settlement stages and the "A Beginning" milestone; seasons, weather and day/night as sim state.
- Relationships and friendship events; more traits and skills; the 15–25 event templates from the MVP.
- Wildlife, visitors, expeditions to other places; the settlement/wilderness balance.
- The view and the play-loop UI (the bulb, decision, journal and "while you were away" panels) are built on top of the sim without it knowing; see `ages.md` (V1-V7).

## Open questions

- How long should the first arc really take, and how many decisions per workday feels right? (Playtest with the timeline tool, then tune `SimConfig` and costs.)
- Should the player be able to see or influence villager activity, or is it purely ambient?
- What is the first milestone's trigger (building count, population, a specific building)?
