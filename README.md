# Two Worlds

A whimsical GBA-style pixel RPG set in 1963 Malaysia, built in **Godot 4**.
Spirit kids Reno and Lumi sneak out of Kampung Akar to see a human train.
The first target is the 20 to 30 minute prologue, *The Great Escape*.

All art in this build is **generated placeholder art**. The handover images are mood boards, not sprites.

![Root Square](docs/screenshots/root-square.png)

## Run it

1. Install [Godot 4.4 or newer](https://godotengine.org/download) (the standard build, not .NET).
2. In the Godot Project Manager, click **Import**, pick this folder's `project.godot`, then **Import & Edit**.
3. Press **F5** (or the ▶ Play button at the top right).

### Controls

| Action | Keyboard | Gamepad | Touch |
|---|---|---|---|
| Move | Arrows or WASD | D-pad or left stick | On-screen D-pad |
| Confirm / talk | Z, Enter, Space | A | A |
| Cancel | X, Backspace | B | B |
| Menu (Journal, Items, Party, System) | Esc or M | Start | M |
| Swap Reno and Lumi | C or Tab | Y | S |
| Show the touch pad on desktop | F2 | | |

The touch pad shows itself on touch screens. On desktop, press F2 and click its buttons with the mouse.

### What to try

1. **New Game** starts in Reno's Home (KA-02) with the dream and wake-up scene (P00). Reno gets his railway token.
2. Leave through the door at the bottom into Root Square (KA-01).
3. Lumi waits by the plaza. Face her and press Z: scene P01 plays, with a three-way flavour choice, and she joins.
4. Walk around: Lumi follows on the exact path Reno walked. Press C to swap leaders.
5. Take the north path to Elder's Hollow (KA-05) for Nenek Rimba's warning (P02).
6. Take the east path to Root Market (KA-04). Bobo (P03) starts the parcel errand.
7. Press Esc to open the Journal, Items and Party menu.
8. Take the south path to the Training Glade (KA-06). It opens once you've heard Nenek and spoken to Bobo.
9. Walk into the Leafling for the tutorial battle (P04). Press A as the ring closes: on your attacks for a stronger hit, and on the Leafling's Seed Toss to dodge.
10. Bring the parcel back to Bobo for the lantern and two Dewdrop Candies.
11. With the lantern, take the glade's south exit into the Whispering Roots (KA-08):
    - **Leaf Leap** (PZ-001): with Reno leading, face a gold-edged gap and press A. Walk into a gap and you climb back out where you were.
    - **Echo Sight** (PZ-002): with Lumi leading (press C), check the humming stone to reveal stepping stones.
    - **Gate Key** (PZ-003): after the echo, check the mossy stone across the pond.
    - **Root Bridge** (PZ-004): Lumi traces the old bridge at the post, then Reno pulls the roots.
12. Cross the bridge to the Forbidden Gate (KA-07) and face the **Thornkeeper** (P06). It braces with Thorn Guard, then shakes the ground (hits both heroes), and below 30% HP Lumi teaches **Spirit Cyclone**: the Team command uses both heroes' turns and 4 MP each, with three timed presses.
13. Open the gate with the key (PZ-005) and walk through to **Sungai Melor** (P07). The prologue ends, the game autosaves, and the end screen carries on into Chapter 1.

**Chapter 1, part A (Sungai Melor).** Humans can't see or hear Reno and Lumi, so everything you hear from them is overheard.

14. A woman walks straight past you (C00). Talk to villagers: they never turn to look.
15. Enter the kopitiam (west door). Walk in to overhear the train rumour, then talk to **Old Kettle** on the back shelf (C01). Talk again to browse his Dewdrop stall.
16. Next door, the sundry shop is now open. Sort Encik Lim's spilled coins into piles of exactly 50 cents (PZ-101, C02). Too much in a pile just tips it back; you can also tip the whole jar out and start again.
17. Back at the kopitiam, Old Kettle pays you (3 Dewdrops, 2 Kaya Toast) and tells you the bus trick.
18. Take the east road to the bus stop. At the bus door, pick who to follow on (PZ-102). Only the man with two big baskets keeps the door open long enough.
19. Ride the bus on the luggage rack (C03) to Bandar Senja Station. The game autosaves on arrival.
20. Optional: the north lane leads to the jetty, where a fisherman has dropped a postcard (C01-S01). It gets posted in part B.

**Chapter 1, part B (Bandar Senja).**

21. Post the postcard with **Mr Slot**, the post box in the forecourt.
22. In the Station Hall, overhear Pak Darus about his three lost parcels, then talk to **the Clockkeeper** above the ticket window (C04). He also has a Dewdrop stall.
23. **Goods Shed** (west of the forecourt, PZ-103): as Reno, face a crate and press A to Root Grip it one tile toward you. Clear the aisle to Parcel A. The lever by the door resets the crates. Optional: as Lumi, read the 1951 tag on the dead-letter shelf (C01-S02).
24. **Shophouse Row** (east, PZ-105): as Lumi, Memory Touch the smudged note on the board, then find the shop sign that matches the fragments (Parcel C).
25. **Place:** put each parcel on Pak Darus's desk while he looks away. A small glow shows when it's safe. If he's looking, Lumi tells you to wait. There's no timer and no fail state.
26. **Rail Yard** (east door of the hall, PZ-104): set the three signal levers (Lumi's Echo Sight on the old marker shows the route) and shove the handcar to open the moth siding. Then fight the **Paper Moth Monarch** (BOSS-101). Below half HP it calls Ticket Moths, and you pick your target.
27. The win gives Parcel B, the Moth-Wing Charm (Lumi SPD +2) and the team skill **Guardian Bloom**. Return the last parcel, and the Clockkeeper stamps your Veil tickets. Platform 2 opens; the train itself is part C.

**Chapter 1, part C (the Veil train).**

28. Board at Platform 2 (C08). The game autosaves on the platform. Inside the Veil train there's no autosave until the Guard's Van door.
29. Passengers have lost their destinations, and they can dimly see you. Beat the Memory Moths for glowing slips, then offer each slip to the passenger it fits (PZ-107). The chalk slip goes to the teacher, the baby's laugh to the grandmother, and the soft cloth to the man with the batik. A wrong slip just floats back.
30. **Roof** (PZ-106): Leaf Leap two gaps as Reno. Lumi then learns **Gentle Float** and can cross the 4-tile gap, with Reno holding her scarf. Missing a jump puts you back on the last safe tile.
31. Optional (PZ-108, C01-S03): in the Luggage Van, the lantern reveals a Veil keyhole. Beat the Lost Luggage for the Brass Lantern Hook (Lumi MAG +3).
32. **The Forgotten Conductor** (BOSS-102):
    - **Phase 1:** Ticket Punch, plus Where Are You Going?, which fogs a hero's skills.
    - **Phase 2:** the tunnel, which adds Last Call.
    - **Phase 3:** Final Stop, announced a full round ahead, so guard.
    - At 15% HP the fight ends in the story scene. You don't need to land a final blow.
33. **The Veil Halt** (C11), then dawn at Platform 2 and the **Chapter 1 complete** screen.

New battle rules: Slow (SPD x0.7), Shielded (damage x0.7), Memory Fog (Skill sealed for a turn), telegraphed attacks (the Dust Bundle announces Roll Over a turn early), and immunities.

**Chapter 2, part A (the river).** Design: `docs/chapter-02/CHAPTER_02_PRODUCTION.md` (a working proposal).

34. From the Chapter 1 screen, press A, then take the new south road out of the station forecourt to **Senja River Landing** (RV-01). It's night and the river is running backwards. Two fishermen are overheard, and the Kingfisher sisters Kilat and Kilau ask you to find the three verses of the Tide Song (C2-01).
35. Go east into the **Mangrove Walk** (RV-02). Blow the Conductor's Whistle at the first carved post to learn **Tide Call**. Each post switches the tide: low tide shows the mud paths, and high tide floats logs across the deep channel (PZ-201). If the tide rises under you, you're put back on dry land.
36. On the island, **Pak Lumpur** sings the first verse (C2-02). Watch for a Driftnet Tangle (Snare: Slow) and two Silt Wisps (Mud Splash: Soaked).
37. East again to **Kampung Air** (RV-03), the spirit-side stilt village. Talk to **Old Pole** as Lumi (press C) to hear the second verse with Memory Touch. Lumi learns **Ripple Echo** (6 MP, hits every enemy). Mak Siput's stall sells River Rice Cakes and Lotus Tea.

New battle rules: Soaked (DEF x0.7 against physical hits, 2 turns) and the first area skill.

**Chapter 2, part B (the jetty and the crossing).**

38. From Kampung Air's east end, cross to **the Sunken Jetty** (RV-04). The boardwalk is broken, and at low tide the far deck is out of reach (PZ-202). At low tide, Root Grip two crates out of the mud into the gap. Then blow the whistle at the marker: at high tide the crates float and the deck is level. The rope by the entrance resets the crates.
39. In the flooded bell house, fight the **Barnacle Bell** (BOSS-201):
    - **Clang** hits both heroes.
    - **Toll** is announced a round ahead.
    - Below half HP it calls Rust Crabs.
    - Winning gives the third verse and the Soggy Bell Clapper (Reno DEF +3). A skiff by the back wall takes you back to Kampung Air.
40. Back at the landing, talk to the Kingfishers. Lumi sings the **Tide Song** while Reno blows the whistle on the beat (PZ-203), and the **Veil boat** rises at the end of the pier. The game autosaves before you board.
41. **The Undertow** (BOSS-202) waits at the Drowned Crossing:
    - Phase 1 uses Slow and Soaked.
    - Phase 2 adds Flotsam Storm.
    - Phase 3 brings Whirlpool, announced a round ahead.
    - At 15% HP the story takes over.
42. **Nenek Arus** reveals that part of her name was cut from the Book of Names. The trail leads to Bandar Kencana. Then morning on the river and the **Chapter 2 complete** screen.

Optional, **Things the River Kept** (C02-S01): overhear the fisherman at the landing. Then find the toy boat (Mangrove Walk), the bicycle bell (Kampung Air) and the wedding ring (jetty mud). Slip each one into his tackle box while he's looking at the water.

**Chapter 3: The Town That Forgot Its Name.** Design: `docs/chapter-03/CHAPTER_03_PRODUCTION.md`.

43. From the Chapter 2 screen, press A. At the landing, ride the **paper barge** from the end of the pier to **Bandar Kencana** (BK-01). The townsfolk can't remember the town's name.
44. In **Kedai Radio**, a voice in an old radio needs a valve. The spare is in the photo studio's desk. Fit it, and **Elias** joins: the first companion, with Spark Coil and Static Burst.
45. **Photographs** (PZ-301): with Lumi leading, Memory Touch each faded photo and pick the right caption. The town remembers, and a crack opens at the west end of the wharf.
46. **Kencana-in-the-Veil** (BK-04): read each radio mast's plaque and let Elias Tune the right band (PZ-302). KEN, CA, NA.
47. **The Blank Clerk** (BOSS-301) in the Hall of Records:
    - Stamp and Redline in phase 1.
    - Erase and Ink Blots from 60%.
    - Redact, announced a round ahead, from 30%.
48. The name comes back, and the Clerk's ledger points to **Bukit Getah Estate**.

Party rules from Chapter 3: up to three heroes fight; anyone else waits in reserve and still earns XP. Companions join at the party's level and travel along without walking the map.

**Chapter 4: The Rubber Grove at Midnight.** Design: `docs/chapter-04/CHAPTER_04_PRODUCTION.md`.

49. From the Chapter 3 screen, press A. The **estate lorry** on the wharf takes you up to **Bukit Getah** at night.
50. In **the Rubber Grove** (PZ-401), three frightened trees block the lanes. With Reno leading, use **Forest Whisper** and pick what each tree needs to hear. Reno also learns Root Uppercut. Grove Shades can **Poison** (6% of max HP after each action).
51. In the **Smokehouse Clearing** (PZ-402), talk gently with **Titis**, the grove's little keeper. A harsh answer only makes her hide again.
52. Her fear pulls loose as **the Fear-Shadow** (BOSS-401):
    - Loom and Dread in phase 1.
    - From 60% it adds Bitter Rain and splits off Grove Shades.
    - From 30% it uses Nightfall, announced a round ahead.
53. At dawn the tappers find every cup full. Titis says the ink-fingered stranger went looking for a forgetting-flower in **Hutan Seribu Bunga**.

**Chapter 5: A Thousand Flowers, One Promise.** Design: `docs/chapter-05/CHAPTER_05_PRODUCTION.md`.

54. From the Chapter 4 screen, press A. Take the new east path from the estate road into **Hutan Seribu Bunga**.
55. Reno pulls **Maris** free of the dead vines. She's the healer: Bloom Heal heals everyone, plus Thorn Lash, and in the field she can **Regrow** vine bridges. With four in the party, **Menu > Party** marks reserves (R). Press A to move someone to the front. The first three fight.
56. In **the Thousand Flowers**, Regrow the bridges (PZ-501) and let Lumi read three memory blossoms (PZ-502): the Promise, a crying Oathkeeper in 1951, and the stranger planting forgetting seeds.
57. **The Forgetting Bloom** (BOSS-501):
    - Petal Storm and Forget-Me in phase 1.
    - Thorn Sprites from 60%.
    - Wilt, announced a round ahead, from 30%.
58. A carnival ticket stub points to **Pasar Malam Impian**.

### Saving

- The game autosaves after every map change and after each battle win.
- Menu → System: save to slots 1 to 3, load any slot, change the timing windows (Normal, Relaxed, Very relaxed), turn diagonal movement off, or quit to the title.
- Title → Continue lists your saves.
- **Export** copies a slot to the `exports` folder in Godot's user data folder (the menu shows the full path). **Import** reads `import.json` from that user data folder into slot 3, only if it's a valid save.
- Every save has a checksum. A damaged or hand-edited file is refused and nothing is overwritten.

### Battle basics

Each round, everyone acts once, fastest first. Commands are Attack, Skill (costs MP), Guard (halves damage until your next turn and gives 2 MP) and Item. Timed presses within 80 ms of the cue are Perfect (1.5x), within 180 ms Good (1.2x). Dodging an enemy cue Perfectly avoids the hit; Good halves it. Losing restarts the battle from just before it began. HP and MP refill after each prologue battle.

## Run the tests

From this folder, with `godot` meaning your Godot 4.4+ executable:

```
godot --headless --import
godot --headless --script res://tests/run_tests.gd
```

The first command only needs running once after cloning. The tests check every map, spawn and door, the game state save format, input mode ownership, the follow trail, and a scripted walk through both maps. It exits with code 0 when everything passes.

## How it's built

| Piece | Where | What it does |
|---|---|---|
| Pixel-perfect screen | `project.godot` | 240x160 world, scaled up by whole numbers only, nearest-neighbour filtering |
| `GameState` | `autoload/game_state.gd` | The one versioned game state: map, position, party, stats, wallet, items, quests, flags. Validates and migrates saves. |
| `InputManager` | `autoload/input_manager.gd` | Keyboard, gamepad and touch share named actions. One mode owns input at a time and each press is consumed once, so closing a message can't also trigger something behind it. |
| `Assets` | `autoload/assets.gd`, `content/asset_manifest.json` | Asset IDs with status. Missing files get a generated placeholder, so real art drops in by setting `path`. |
| Maps | `content/maps/*.json`, `scripts/exploration/map_data.gd` | Placeholder ASCII maps with spawns, two-way doors, NPCs and signs. Checked at boot and in tests. |
| Exploration | `scripts/exploration/` | Movement with collision, camera clamped to the map, Lumi following safe prior positions, swapping, doors with fades. |
| Dialogue | `content/dialogue/*.json`, `scripts/ui/dialogue_box.gd` | Scenes as lists of steps: lines with name and portrait, up to three choices, and story steps (flags, items, party joins). NPCs pick a scene by story flags. |
| Quests | `content/quests.json`, `autoload/quests.gd` | Quests move locked → active → completed → rewarded when story flags change. Each reward is granted once. |
| Combat | `scripts/battle/combat.gd`, `scripts/battle/battle.gd`, `content/enemies.json`, `content/skills.json` | Rules (turn order, tokens, damage, timing windows) kept separate from the battle screen so they can be tested. |
| Saves | `autoload/saves.gd` | Three slots plus autosave, written to a temporary file and then swapped in, with a checksum and full validation on load. |
| Menu | `scripts/ui/pause_menu.gd` | Journal, Items (money shown as 1963 dollars and cents) and Party tabs. |

Content files are marked `PLACEHOLDER` or `WORKING_PROPOSAL`, following the handover's status rules.

## Adding real art later

Put a PNG under `assets/` and set its `path` in `content/asset_manifest.json`:

- Characters: one row of 32x40 frames in the order down, left, right, up, feet near the bottom.
- Tiles: one row of 16x16 tiles in the index order from `content/tiles.json`.

## Roadmap

1. ✅ Foundation: screen, input, game state, asset manifest, boot and title
2. ✅ Exploration (first pass): Root Square and Reno's Home, follow, swap, doors
3. ✅ Dialogue and quests: P00 to P03, journal, items and party menu
4. ✅ Combat and the Leafling tutorial
5. ✅ Field abilities and Whispering Roots puzzles
6. ✅ Inventory and saving
7. ✅ The rest of the prologue: Thornkeeper, Spirit Cyclone, the gate and Sungai Melor
8. Chapter 1: The Last Train to Bandar Senja (design approved in `docs/chapter-01/`)
   - ✅ Part A: Sungai Melor, Old Kettle, the Coin Jar, the bus (plus level growth, MP items, Dewdrop stalls)
   - ✅ Part B: Bandar Senja, the Clockkeeper's parcels, Paper Moth Monarch, Guardian Bloom
   - ✅ Part C: the Veil train, Gentle Float, the Forgotten Conductor, the Veil Halt
9. Chapter 2: Whispers Along the River (design proposal in `docs/chapter-02/`)
   - ✅ Part A: the river landing, Tide Call and the mangroves, Kampung Air, Soaked, Ripple Echo
   - ✅ Part B: the Sunken Jetty, the Barnacle Bell, the Tide Song, the Undertow, Nenek Arus, Things the River Kept
10. ✅ Chapter 3: The Town That Forgot Its Name (Elias joins, three-hero battles)
11. ✅ Chapter 4: The Rubber Grove at Midnight (Forest Whisper, mediation, Poison)
12. ✅ Chapter 5: A Thousand Flowers, One Promise (Maris joins, healing, formation)
13. Chapters 6 to 10 and the epilogue
