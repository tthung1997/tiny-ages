# Ages (eras)

Status: **direction agreed; the sim supports eras and the slice is re-themed.** This extends the MVP concept's progression (Camp → Hamlet → Village, the Knowledge axes and the Wild ↔ Developed axis) with a long-term arc: the game starts in the Cave Age and the settlement progresses through later ages gradually. Art for the Cave Age is not drawn yet; the on-screen art is still the earlier cottage-era placeholder set.

## Decisions

| # | Decision | Why |
|---|---|---|
| G1 | The game **starts in the Cave Age** (hunter-gatherers living in caves) | Player's vision for the game. |
| G2 | **Ages are linear, but the player's choices decide how they get there and what the age looks like.** Not branching into different ages per player | The MVP's "knowledge" axes (Agriculture / Craft / Exploration) drive the transition, so one player's Settled Age is farmland, another's is herding or craft. Linear ages keep the art and content scope bounded. |
| G3 | **Sequencing: decide the structure now, draw art one age at a time.** Age 1 art first; later ages are content packs | Art cost multiplies per age; the sim and content only need the era *structure* up front. |
| G4 | **Change is gradual and cumulative**: new buildings and props appear and older ones stay (the cave remains as storage), so the world accumulates history instead of being replaced | Matches "the player's desktop physically becomes more populated"; also cheaper than swapping whole scenes. |
| G5 | An **age** is a content/art pack and tech level; a **chapter** is settlement size within it (the MVP's Camp → Hamlet → Village milestones) | Keeps two different ideas apart. |

## Candidate ages (for reference)

| Age | Life | Visible change |
|---|---|---|
| 1. Cave | Hunter-gatherers, fire, hides, flint tools | Caves, fire pits, lean-tos, furs, big game |
| 2. Settled | Farming, herding, pottery, weaving | Huts, fields, pens, storage (reuses much of the current farm/tent art) |
| 3. Bronze | Metal, trade, walls, first towns | Mud-brick, workshops, roads |
| 4+ | Iron, classical, medieval | Out of scope for now |

Recommended MVP scope: Age 1 in full, Age 2 as the first transition, Age 3 as a horizon only. Not yet confirmed.

## How the first slice fits

The slice's chain (a curious villager scouts, brings back a wild seed, the player plants it, it flowers) is the **origin of farming**, and it is the moment the Cave Age can turn into the Settled Age. It is built that way: once the plant has flowered, the group is asked whether to settle by the field or keep following the herds. The choice is the player's; declining just asks again later.

## Cave → Settled: the gate

Agreed. The player is never shown this list or the minimum time (see `gameplay.md` P8). All six
milestones must be earned, and the minimum time must have passed. Milestones are achievements.

| # | Milestone | Real-world turning point | Ways it can happen | On screen | Unlocks |
|---|---|---|---|---|---|
| 1 | **Fire** | Controlled fire | A curious villager finds a tree burning after a storm, or sparks fly while knapping | Fire pit lit, warm night glow, villagers gather at it | Everything below |
| 2 | **Stone tools** | Knapping | An industrious villager works at a flint spot, or a tool is found while cracking nuts | Knapping spot, tools in hands | Hunting, building |
| 3 | **Reliable food** | Organised hunting or foraging | *Hunt*: spears and a shared hunt. *Gather*: baskets and drying | Spears or baskets, drying rack, hides | Furs, growth |
| 4 | **Shared stories** | Language, art, ritual | Social villagers talk by the fire, or someone paints the cave wall | Ochre handprints on the cave wall | Trait events |
| 5 | **A bigger group** | Bands joining | Wanderers arrive once the camp is secure (at least 2 newcomers) | More villagers | Settling |
| 6 | **Seeds of a new life** | Origin of farming | A scout brings back a seed, someone plants it, it flowers (the existing chain) | The strange flower by the cave | The Settled Age |

- **Order**: Fire first; the rest in most orders. Stone tools come before hunting, and the seed chain needs a scout who has travelled.
- **Minimum time**: about 5 real days (to tune). Time while the game is closed counts.
- **Choices that shape it**: milestone 3 can be met by hunting or gathering (different look); whether the flower is planted is the player's call; the age-turn beat can be a *how* choice (how to settle), not a *whether*.
- **Safeguards**: if a milestone is still missing after the minimum time, a fallback chain makes it eligible; declined decisions come back; a test proves every milestone is reachable, including for a player who keeps declining.

## What is built in the sim

- `EraDef` (id, name, `order`, intro text) in `ContentLibrary.eras`; the world stores the current `era` and `era_order`.
- `SimCondition.ERA_AT_LEAST` gates events and choices; `SimEffect.ADVANCE_ERA` moves forward only and writes the era's intro to the journal.
- Cave and Settled ages exist, with era-gated buildings (Field, Hut) and cave-only flavour events.

## Open questions

- How many ages does the MVP actually cover?
- Which choices shape an age (Agriculture vs Craft vs Exploration?) and how visibly?
- Real-time length of an age at 20 minutes per game day (Cave: about 5 real days minimum, to tune).
- What does the cave look like in the strip (a rock face along the back layer?), and do later ages hide or keep it?

## Cave Age art sketch

`art/reference/cave_strip.png` (layers in `art/reference/layers/cave_*.png`, generated by `tools/art/cave_strip.js`) is a first look at Age 1 in the strip, in the same style and layer structure as the day strip.

![Cave Age strip](../art/reference/previews/cave_strip_x3.png)

- **Cave**: a rock cliff with a dark cave mouth and warm firelight inside, ochre handprints on the wall, and a fire pit in the trampled earth in front. It is a big landmark at the left of the strip (about 54 px tall).
- **Slice buildings**: Lookout (rock outcrop with a platform and ladder, a scout standing on top), Drying Rack (hanging meat and a hide), Knapping Spot (flat stone with flint chips), a hide shelter (a stitched hide cone over pole tips; it stands in for the later Hut), and the strange flower (violet blossoms) by the cave mouth.
- **People**: fur tunics with ragged hems, a bone necklace and bare legs; stone-headed tools; a gatherer with a basket and a hunter with a spear. Same 16 px villager, so all existing poses and hair work.
- **World**: colder sky, a snowy far range, conifer tree line, a woolly mammoth in the back lane, drier grass.

Still rough: the cliff reads a little like a boulder, the far mountains look like a pale band rather than peaks, fur is hinted at rather than textured, and only some tool poses exist (hammer, spear, axe). Nothing here is final.

## What this changes (still to do)

- **Art**: finish Age 1 (animation, more props, night variant, more tool poses); building and prop art keyed by era so later ages can add to the scene.
- **On-screen view**: built (milestone 1) with the Cave Age art split into pieces: backdrop layers, static props, and per-building art with a construction-site stage each. Later ages add their own pieces; `WorldLayout` is where an age's slots live.

## On-screen view decisions

- **V1** Bigger panels (decisions, journal, "while you were away") expand the strip **upward temporarily** while open, then shrink back. The strip itself stays 80 px tall. The click region must grow with the panel. Not built yet (milestone 2).
- **V2** Villagers act out their simulated activity (chop near the pine, hammer at the building site, gather at the fire) and are hidden while asleep or away.
- **V3** The scene is tinted by the hour of the day; buildings appear as built, with a site stage while under construction.
- **V4** The game autosaves every 60 seconds and on quit; launching after time away runs the offline catch-up.
