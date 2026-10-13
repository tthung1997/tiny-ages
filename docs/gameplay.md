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
- **P10 Content budget.** About 20 decisions per age, plus ambient lines and trait-driven variants
  (one authored event plays differently per villager). Visible consequences matter most: choices
  change buildings, props and clothing, so there is a reason to look.
- **P11 Light interaction.** Clicking a villager shows their name, traits and current thought.

## Safeguards for the gate

- Every age's requirements must be reachable. A test runs a bot that accepts everything **and** one
  that keeps declining, and both must eventually reach the next age (declined decisions come back).
- A milestone must never depend on a single lucky event; if a requirement is not met after the
  minimum time, a fallback chain makes it eligible.

## What this changes (still to do)

- **Sim**: random seeded traits at world creation; start without fire (a Fire milestone chain and a
  cave-mouth fallback where villagers gather until the fire exists); achievements as the gate, with a
  hidden `min_age_ticks` on `EraDef` and milestone lists instead of the single `seeds_of_a_new_life`
  trigger; resource needs shown on choices.
- **View**: no fire glow or fire-pit piece until the fire is found; speech bubbles and a villager
  detail popup.
- **Open**: how many resources exist per age; whether the player can ever see a hint that something is still undiscovered. The Cave → Settled milestones are listed in `ages.md`.
