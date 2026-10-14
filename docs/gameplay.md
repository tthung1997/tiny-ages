# Gameplay basics

Decided with the project owner. Everything numeric below is a target to tune, not a promise. The
simulation's current content (wood and food, three fixed villagers, the first slice's achievements) is
placeholder and does not yet follow these decisions; see "What this changes".

## Decisions

- **P1 The player's job is direction, not management.** Choices set where the group settles, what it
  learns and who it becomes. The player never manages resources or assigns work.
- **P2 Resources are context, not a number to watch.**
  - A choice shows what it needs. If the group cannot afford it yet, it reads as "we'll start when we
    have enough"; it waits and nothing fails.
  - Scarcity is told as story ("food is running low" in the journal) and can make a choice appear
    (hunt or forage). Exact stock lives in a details panel, never on the strip.
  - Resources can also be hidden inputs to milestones (enough stone to learn knapping).
- **P3 Two rhythms of activity.** Something small every 10-20 real minutes (a speech bubble, a journal
  line, a visitor or an animal) and something meaningful every few hours (a decision). Away or not,
  there is always something to see when the player glances at the strip.
- **P4 Start with three villagers whose traits are random** (seeded, so a run is reproducible). Their
  names are not fixed; their traits shape which events they take part in and how those play out.
- **P5 The settlement can grow.** Villagers can arrive; later ages may add births and departures.
  Population is the clearest progress signal on a tiny strip.
- **P6 Fire is found, not given.** The first age starts without fire: the cave is cold and dark at
  night. Finding and keeping fire is the first major milestone, reached in roughly the first hour.
- **P7 Achievements drive the ages.** One system: an achievement records something that happened,
  and some are major milestones. Unearned ones are hidden.
- **P8 Ages are gated by hidden requirements.** An age needs a set of milestones **and** a minimum
  time. The player is told neither in advance.
  - Milestones are real turning points between ages (fire, stone tools, farming, pottery, copper and
    bronze...), not every event.
  - A requirement can be met in more than one way, so choices shape the route (see `ages.md` G1).
  - The minimum time stops luck from rushing an age. It is measured in real time and is a few real
    days for the Cave Age (to tune).
  - Reaching an age is announced by a story beat; the player never sees a checklist.
- **P9 Time while the game is closed counts fully.** The world keeps living on the real clock, so
  closed or asleep is the same as running in the background: offline catch-up replays it. This is safe
  because decisions are the bottleneck: at most 3 queue up and then the world waits for the player, so
  being away can only run down the minimum-time clock and never skip content. Players who answer
  decisions often still progress faster, up to that floor. Rejected: counting only open time (stingy
  to casual players, mostly rewards leaving the game running) and a per-day cap on catch-up (a rule
  that makes progress harder to predict).
- **P10 Content budget.** About 25-30 questions for the five-day Cave Age (the buildings and milestones plus about 20 small story decisions; roughly 4-6 per workday), plus ambient lines and trait-driven variants
  (one authored event plays differently per villager). Visible consequences matter most: choices
  change buildings, props and clothing, so there is a reason to look.
- **P11 Light interaction.** Clicking a villager shows their name, traits and current thought.
- **P12 The strip shows almost nothing, always.** Permanently on screen there are only the bulb (when
  a decision waits) and the journal book (with an unread dot). Everything else is on demand: a
  **right click on the strip** opens a short menu with the journal, **Stores** (where the
  settlement is, the exact wood and food, and who is in the group: the numbers P2 keeps off the
  strip), **Settings** (window mode, size, always on top, move to the next screen; remembered in
  its own file, separate from the save) and Quit. No counters, clocks or speed controls: time of
  day reads from the light, and time never pauses. The text overlay (day, stock, speed, the last
  journal line) and the dev keys (mode, speed, bot) are developer tools behind `--dev` (or `--hud`
  for the overlay alone), so they cannot block the desktop or tempt the player to watch numbers.

## Safeguards for the gate

- **Fire cannot stall.** Both fire routes have a "not now" choice, and passing on either schedules the embers, which light the fire anyway (a little later). Tested for every seed.
- **Every age's requirements must be reachable.** `test_sim_gate.gd` plays from a cold start as a player who accepts everything and as one who passes on each question twice before accepting, and both must reach the next age. A player who refuses a milestone's decisions forever cannot progress; the decisions keep coming back.
- The gate is data (`EraDef.required_achievements`, `min_ticks_in_previous_era`, `turn_event`), and `ContentLibrary.validate()` rejects a gate that requires an achievement nothing grants.

## What this changes (still to do)

- **Done in the sim**: random seeded traits; no fire at the start, with the two fire routes and the embers fallback; achievements as the hidden gate with a minimum time; the age-turn event asks *how* to settle (field or herds), not whether; all six Cave → Settled milestones, each with more than one route; about 20 small story decisions and 25 ambient lines between the milestones; resource needs shown on choices; a leaner economy that hovers instead of piling up.
- **Still to do in the sim**: more trait-driven variants of one event; the answers do little beyond the journal and a flag, so later content should read those flags and change what is seen. The Settled Age's fill (24 story decisions, 23 ambient lines) is in; stores in the Settled Age still pile up past what the sinks use, which wants a look when the age is played.
- **View**: built: no fire glow or fire-pit piece until the fire is found, and a cave-mouth place to gather until then; clicking a villager shows their name, traits and thought (`ages.md` V9). Still to do: speech bubbles.
- **Open**: how many resources exist per age; whether the player can ever see a hint that something is still undiscovered. The Cave → Settled milestones are listed in `ages.md`.
