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

The slice's chain (a curious villager scouts, brings back a wild seed, the player plants it, it flowers) is the **origin of farming**, and it is the last milestone before the Cave Age can turn into the Settled Age (see the gate below). When the whole gate is met, the group is asked *how* to settle (by the field, or where the herds winter); both answers advance the age.

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

- **Order**: Fire first; the rest are **staged over the age** so it is not finished in an afternoon: Stone Tools from game day 18 (about 6 real hours), Enough to Eat from 54 (18 h), Shared Stories from 108 (1.5 days), A Bigger Group from 162 (2.25 days) and the seed chain from 216 (3 days). Stone tools come before hunting. The numbers are one table in `tools/build_sim_content.gd`.
- **Minimum time**: about 5 real days (to tune). Time while the game is closed counts.
- **Choices that shape it**: milestone 3 can be met by hunting or gathering (different look); whether the flower is planted is the player's call; the age-turn beat can be a *how* choice (how to settle), not a *whether*.
- **Safeguards**: if a milestone is still missing after the minimum time, a fallback chain makes it eligible; declined decisions come back; a test proves every milestone is reachable, including for a player who keeps declining.

## Cave Age: between the milestones

The milestones are far apart (hours to days), so each stretch has its own small decisions and a stream of one-line journal moments. None of it is required, nothing fails, every answer is harmless, and an answer only shows up in the journal and sometimes in a later line. Which game day each opens is one table (`STORY_DAY` in `tools/build_sim_content.gd`); 72 game days is a real day.

| From day | Decision (two answers each) | What the answers do |
|---|---|---|
| 4 | **A wolf at the edge** | Leave scraps (2 food) or drive it off; the wolf is remembered in later lines |
| 6 | **Hungry mornings** (only when food is low) | Forage together or set snares; food and a flag |
| 24 | **What the edge is for** (needs Stone Tools) | Hand axes (wood) or hide scrapers |
| 32 | **The first hard frost** | Keep the fire high all night (8 wood) or huddle close |
| 42 | **Strange prints** (a curious villager) | Follow them (away 18 ticks, comes back with pine nuts) or stay |
| 60 | **More than enough** (needs Enough to Eat and a full store) | Hold a feast (12 food) or dry the rest |
| 72 | **The warm spot** | A second small fire (6 wood) or take turns |
| 88 | **The neighbour** (the mammoth at the camp's edge) | Offer greens (3 food) or keep a distance |
| 115 | **A rhythm to work to** (needs Shared Stories) | Let everyone join in or ask for quiet |
| 126 | **The crowded wall** (cave art route) or **The long story** (storytelling route) | Paint the herd or the sky; or fix the story or let it change |
| 140 | **Smoke on the ridge** (needs the Lookout; before the strangers) | Send a scout (finds a cold fire ring) or keep watching |
| 172 | **Room for the newcomers** (needs A Bigger Group) | A shelter (8 wood) or share the cave |
| 192 | **The river is rising** | Carry the stores up (6 wood) or trust the bank |
| 232 | **Heavy grass** | Gather every seed head (10 food) or half, leaving the rest to scatter |
| 252 | **A limping deer** | Tend it (3 food) or let nature take its course |
| 272 | **A traveller with dark stone** | Trade food (8) for the stone or share a meal |
| 294 | **Counting stars** (a curious villager) | Name the shapes together or let them keep the sky |
| 316 | **Smoke in the cave** | Open a gap in the roof (8 wood) or live with it |
| 342 | **The pile by the cave** (an industrious villager) | Sort the good stone or bury it |

- **Ambient lines**: about 25 one-line moments (mist, a heron, geese, thunder; a curious villager watching ants; a social one humming; an industrious one stacking wood; a nature-loving one bringing back crocuses; plus lines that remember an earlier answer). Each repeats at most every 5 real hours (360 ticks). A line about a villager is never told while they are asleep (`SUBJECT_AWAKE`).
- **Pace** (bot answering at once, `tools/sim_timeline.gd`): about 29 questions across the 5 days including the buildings and milestones, never more than about 9 real hours apart, and a journal line roughly every 20 real minutes. That is about 4-6 questions per workday for a player who is at the desk for a third of the time.
- **Resources stay context** (P2): a choice shows what it needs and only waits for it. Villagers stop gathering a resource once the store reaches `comfortable_stock` (40), and buildings stop adding to a full store, so stock hovers around that instead of piling up; building costs are 8-14 wood.

## What is built in the sim

- `EraDef` (id, name, `order`, intro text, and the hidden gate: `required_achievements`, `min_ticks_in_previous_era`, `turn_event`) in `ContentLibrary.eras`; the world stores the current `era`, `era_order` and `era_started_tick`.
- `EraSystem` opens the next age when its gate is met: it fires the turn event (or advances at once). `SimCondition.ERA_AT_LEAST` gates events and choices; `SimEffect.ADVANCE_ERA` moves forward only and writes the era's intro to the journal. Buildings can grant a milestone on completion (`BuildingDef.completion_achievement`).
- Built: all six milestones, each with at least two routes or a way to pass and be asked again. Fire (burning tree for a curious villager, sparks for an industrious one, embers if both are passed). Stone Tools (Knapping Spot, or a lucky split stone). Enough to Eat (the hunt, or foraging plus the Drying Rack). Shared Stories (a story by the fire, or red earth for the cave wall). A Bigger Group (strangers seen from the Lookout; two newcomers join). Unexpected Garden (the seed chain).
- Milestone events let *anyone* at home be the subject; a matching trait only makes someone likelier (`EventDef.trait_weights`), so no random group can be locked out.
- Newcomers get a random unused name and traits (`Simulation.add_villager`), and reuse the three villager looks until more art exists.
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

- **V1** Bigger panels (decisions, journal, "while you were away") expand the strip **upward temporarily** while open, then shrink back. The strip itself stays 80 px tall. The click region grows with the panel. **Built** (see V7).
- **V2** Villagers act out their simulated activity (chop near the pine, hammer at the building site, gather at the fire) and are hidden while asleep or away.
- **V3** The scene is tinted by the hour of the day; buildings appear as built, with a site stage while under construction.
- **V4** The game autosaves every 60 seconds and on quit; launching after time away runs the offline catch-up.
- **V5** The world is three pages wide (engine-and-art A8). The strip shows one page, starting on the camp, and the player pans with an arrow on each edge (shown only when there is more that way), click-drag, the wheel, or A/D / arrow keys; Home returns to camp. No automatic camera moves. Small dots show which page is in view.
- **V6** The side pages (art: `tools/art/cave_pages.js`). **West**: a pine forest rising to a snowy ridge, the hunting grounds; it is walkable, and newcomers and returning scouts arrive along the forest path from beyond its west end. **East**: the camp's river, a far bank of reeds that villagers cannot reach, then a bay that runs off the right edge. There is no sea in the Cave Age (groups lived by fresh water: rivers, lakes, herds coming to drink, flint and red earth in the riverbed), but the bay is where a sea or coast page can attach in a later age. The camp's river already crosses the whole ground at the camp's east edge, so the east is water, not a ford; the ridge is in the west. Villagers wander west into the forest (to x = −150) and stop at the camp's river (x ≈ 290).
- **V6b** Before fire the camp is cold and dark (P6): there is **no fire pit**, no firelight in the cave mouth and no glow (the `fire_pit` piece appears when `fire_found` is set), the group sits in the cave mouth, and **nights are darker** (`DayNight.tint(hour, lit)`; days are unchanged). Once there is fire, a dithered warm **glow** (`fire_glow`, drawn additively over the world, villagers included) fades in with the dark round the pit and in the cave mouth. The fire **flickers**: four flame frames (`fire_pit_0..3`) swap every 0.2 s and the glow dips and brightens with them; the clock only runs while there is fire and some of its light is on screen. **Wood is cut at the stump at the west forest's edge** (x = −66), not at the camp. Scouts go to **the western forest** (the east is water), and the lookout watches the ridge beyond it.
- **Next for the world**: hunts at the forest's far end; an off-screen indicator for events out of view; a night variant of the art.
- **V7** The play-loop UI (milestone 2). A **bulb** floats at the top right of the viewport while a decision waits (a count when several do) and a **journal book** is always there; both stay put while the world scrolls and stay clickable in strip mode. Clicking the bulb opens the decision in a **panel above the strip** (the window grows upward by the panel's height; the art does not move; the click region takes in the panel). Each choice shows what it needs ("needs 6 wood") and is greyed out with "(have 2)" while unaffordable (P2); choices still locked by a hidden stage are not listed, so nothing hidden is hinted at. Several waiting decisions page with Next. A decision the world has moved past (the fire was lit another way) is withdrawn by the sim. The journal is newest first. On launch, if the player was away at least 5 minutes and something happened, a "While you were away" panel lists the latest events and what is waiting. Esc closes the panel. The font is Pixelify Sans (OFL, in `game/assets/fonts/` with its licence).
- **V9** **Clicking a villager** (gameplay.md P11) opens the same panel with their picture, name, traits, any role (Scout) and a one-line thought. A click is a press and release within 3 px (a longer drag pans the world); the villager in front wins when two overlap; villagers who are asleep or away are hidden and cannot be clicked, but "Next >" walks through the whole group ("1 of 3") including them ("Fast asleep.", "Out in the western forest, far from the camp."). Clicking the same villager again, or Esc, closes it. The thought is picked from short authored lines by what they are doing, their traits, whether there is fire yet ("It is cold in the cave, and dark.") and whether the food is low ("The food pile is getting small."), so scarcity is told as a thought, not a number (P2). It changes every few game hours and holds still in between. Nothing here changes the simulation.
- **V8** **Panel skins, one per age.** The panels are dressed by a `PanelSkin` (material, colours, font, where each piece sits in the age's atlas), so the UI itself shows progress: the Cave Age skin is a **stretched hide** with torn sides, a **bone rail** top and bottom lashed with sinew, an ochre handprint, stitched-leather buttons, a bone close button and a brown scrollbar. Later ages get their own (clay, papyrus...); an age with no skin yet uses the Cave one. Costs are drawn as resource icons (a log, a haunch of meat) with the amount, and "(have N)" in muted ink while short. The panel unrolls upward in 6 steps when it opens and rolls up when it closes. Text is Pixelify Sans at 12 px with tight line spacing.
