# Chapter 2 Production — Whispers Along the River

> **Status: WORKING PROPOSAL (written 28 November 2026).** Dennis said "Yes" to continuing into Chapter 2 and treats every design doc as a guide that can change freely. This doc expands the handover's one-line outline ("Reverse tides and submerged crossing; river guardian Nenek Arus") into a buildable chapter. Story, structure and rules are proposals, and stats, prices, sizes and coordinates are prototype data to tune in playtests. Format follows `docs/chapter-01/CHAPTER_01_PRODUCTION.md`.

## 1. Objective and completion
The Conductor said "The rails forget. The river remembers." Reno and Lumi follow the Conductor's Whistle down to the river below Bandar Senja. At night the river has started running backwards. Fishermen pull up nets full of things lost decades ago. The old Veil ferry crossing, which once carried spirits between the river villages, has sunk under the water and keeps dragging in anything that floats past.

The river guardian, **Nenek Arus**, is fading. She can't remember the Tide Song that tells the river which way to flow. The duo gather the song's three verses from the river's small spirits, learn to call the tide with the Conductor's Whistle, ride a Veil boat down to the Drowned Crossing and calm **the Undertow**: a knot of lost things the severed crossing has pulled together.

Restored, Nenek Arus explains why. A page of her name was **cut** from the Book of Names, cleanly, by someone who knew exactly what they were doing. The cut left a mark: ink, and the faint stamp of a town crest from Bandar Kencana. This is the first real sign that someone is severing crossings on purpose, and it leads into Chapter 3 ("The Town That Forgot Its Name").

Completion: `chapter_02_completed` after scene C2-09, with `bandar_kencana_route_unlocked` and `chapter_03_unlocked`. Safe autosave.

Pacing target: **40–60 minutes** main path, plus about 10 minutes optional (not playtested). Expected party level: enter Lv5–6, about Lv7 before the boss, leave at about Lv8.

### Canon guardrails
- Humans still can't see spirits (CONFIRMED_USER). River humans are overheard only. The Veil boat is invisible to them, apart from "a strange ripple".
- Nenek Arus and every river spirit here are **original** Two Worlds spirits. None is a named Malaysian folklore being, and there's no religious claim or ritual depicted. The Tide Song is an invented in-world song.
- The Book of Names hint stays partial. A page of a name was cut, which caused fading and forgetting, not death. The culprit is not named. The Keeper of Silence is not shown. "Someone with ink on their hands" is enough.
- Lumi's thread advances lightly. Nenek Arus says Lumi's humming sounds like "an echo of someone who sang to this river once". Seri is **not** named, and nothing about 1951 is explained.
- Fishing life, river trade and kampung houses on stilts are portrayed through jobs and daily goals, never through ethnic "types" or accents (same rule as Chapter 1).

## 2. Maps
16x16 tiles. Sizes are design anchors.

| ID | Name | Tiles | Function | Return |
|---|---|---|---|---|
| RV-01 | Senja River Landing | 40x30 | Reached from Bandar Senja's south road. Fishermen overheard, the reversed river, Kingfisher sisters | Yes |
| RV-02 | Mangrove Walk | 48x30 | Tide puzzle (PZ-201): low tide shows mud paths, high tide floats logs; first verse | Yes |
| RV-03 | Kampung Air (spirit side) | 40x30 | Stilt village of river spirits; Old Pole the jetty post; stall; second verse | Yes |
| RV-04 | The Sunken Jetty | 44x28 | Tide plus Root Grip puzzle (PZ-202), mid-boss Barnacle Bell; third verse | Yes |
| RV-05 | The Drowned Crossing | 36x24 | Veil boat arrival, underwater-feeling Veil space, boss arena | No (boss lock) |
| RV-06 | Nenek Arus's Pool | 32x24 | Ending, Book of Names clue, route to Bandar Kencana | Story exit |

## 3. Quests
| ID | Name | Start | Completion | Reward |
|---|---|---|---|---|
| C02-001 | The River Runs Backwards | `chapter_02_unlocked` (on first arriving at RV-01) | Meet Nenek Arus's messenger, the Kingfisher sisters | 2 Dewdrops |
| C02-002 | The Tide Song | `ch02_song_quest_started` | Three verses: Mangrove (PZ-201), Kampung Air (Old Pole), Sunken Jetty (Barnacle Bell) | Tide Call learned |
| C02-003 | The Drowned Crossing | `ch02_tide_song_complete` | Whistle up the Veil boat at RV-01, ride to RV-05, calm the Undertow | 100 XP (battle) |
| C02-004 | A Name Cut Out | `ch02_undertow_calmed` | Talk to Nenek Arus at her pool | Chapter 3 unlock, autosave |
| C02-S01 | Things the River Kept | RV-01 fisherman | Return three lost objects (a spoon, a toy boat, a wedding ring) using Place while nobody is looking | 3 Dewdrops, Memory Album entry |

## 4. Field abilities
| Ability | Owner | Status in Ch 2 | Used for |
|---|---|---|---|
| Leaf Leap / Root Grip | Reno | From before | Mangrove roots, jetty crates |
| Echo Sight / Memory Touch | Lumi | From before | Old Pole's memory, hidden verse |
| Gentle Float | Lumi | From Ch 1 | Wide channels at high tide |
| **Tide Call** | Both (key item: Conductor's Whistle) | **New**, learned after the first verse | At a tide marker, blow the whistle to switch the map between high and low tide |

**Tide Call.** River maps have two states. Low tide shows mud paths and sandbars, and high tide covers them but floats logs and reed rafts you can step on. A tide marker (a carved post) toggles the state. It's deterministic, with no timer and no fail state. Sinking into deep water just returns you to the last safe tile.

## 5. Main scenes
Dialogue is selected main-path copy in the prologue's style. Lines marked *(overheard)* are humans talking among themselves.

### C2-01 — The River Runs Backwards (RV-01)
Night. The river flows uphill, past the jetty, the wrong way.
Fisherman *(overheard, to his friend)*: "Third night running. Nets come up full of old things. A spoon from my grandmother's house!"
Friend: "The tide tables must be printed wrong."
Reno: "The water's going the wrong way! Is it lost?"
Lumi: "Rivers don't get lost."
Two kingfisher spirits land on the rail, Kilat and Kilau (original sisters, they finish each other's sentences).
Kilat: "You're the train kids—" Kilau: "—with the Conductor's whistle!" Kilat: "Nenek Arus needs—" Kilau: "—help. She's forgetting the Tide Song."
Objective: *Find the three verses of the Tide Song.*

### C2-02 — Mangrove Walk (RV-02, PZ-201, first verse)
Mud paths at low tide, floating logs at high tide. A mudskipper spirit, Pak Lumpur, has the first verse but keeps losing his place. When the duo reach his island he sings it.
After the verse, Lumi hums it and the whistle answers. **Tide Call learned.**
Reno: "We can boss the river around now?"
Lumi: "We can *ask* the river nicely."

### C2-03 — Old Pole (RV-03, second verse)
Kampung Air on the spirit side, a stilt village of small river spirits. Old Pole, the oldest jetty post, remembers the verse but only as a feeling. Lumi uses Memory Touch and hears it sung by many voices at a festival long ago. Lumi's humming makes Old Pole cry a little: "You sound like an echo of someone who sang to this river once."
Lumi doesn't answer. Reno changes the subject loudly, on purpose.

### C2-04 — The Sunken Jetty (RV-04, PZ-202, BOSS-201, third verse)
A tide-plus-crates puzzle: low tide to reach the crates, Root Grip to line them up, high tide to float across on them. In the jetty's flooded bell house, the **Barnacle Bell** (mid-boss) clangs over the third verse because it's afraid of the quiet.
After the battle: "If I stop ringing, I'll forget I was ever a bell." Lumi: "Then we'll remember for you." The verse is given freely.

### C2-05 — The Tide Song (RV-01)
All three verses. At the landing, Lumi sings and Reno blows the whistle on the beat (an off-battle timing moment with no fail state, reusing the cue ring). A Veil boat rises out of the water: a long, quiet boat with a lantern at each end and nobody rowing.

### C2-06 — The Drowned Crossing (RV-05)
The boat sinks gently and the air stays dry. The old ferry crossing lies under the river, and lost things circle it: nets, sandals, a bicycle wheel, letters. In the middle, everything knots into the **Undertow**.
Undertow: "Keep. Everything. Nothing floats away if I keep it all."
Reno: "That's a lot of sandals."

### C2-07 — Calming the Undertow (BOSS-202)
A story-threshold boss like the Conductor. At 15%, Lumi sings the whole Tide Song and the knot loosens. The lost things drift back up toward the people who lost them.

### C2-08 — Nenek Arus (RV-06)
A pool where the river begins to turn the right way again. Nenek Arus, an old river spirit made of reflections, is pale and fading.
Nenek Arus: "Thank you, little ones. My river remembers its way again. But I still don't feel whole."
She shows a page-shaped hole in her reflection, its edge as straight as a ruler.
Nenek Arus: "Someone cut part of my name from the Book. Neatly. With ink on their fingers. Names don't fall out by themselves."
Lumi: "Who would do that?"
Nenek Arus: "Someone who wants the worlds to stop touching. Follow the ink. It smelled of a town that trades in paper: Bandar Kencana."
She gives Lumi a river pearl that hums the Tide Song (`item_tide_pearl`).

### C2-09 — Morning on the River (RV-01)
Dawn. The river runs the right way. A fisherman finds his grandmother's spoon on the jetty rail and laughs out loud.
Fisherman *(overheard)*: "Who put this here? ...Never mind. Never mind!"
Reno: "Bandar Kencana. Do they have trains?"
Lumi: "Reno."
Reno: "Boats? Buses? A flying kettle?"
"Chapter 2 Complete" card. Set the completion flags and autosave.

## 6. Puzzles
| ID | Map | Mandatory | Description | Recovery | Flag |
|---|---|---|---|---|---|
| PZ-201 | RV-02 | Yes | Mangrove tides: cross to Pak Lumpur's island by switching the tide. Low tide shows a mud path to the first marker; high tide floats logs across the deep channel; low again shows the last stretch. | Deep water returns you to a safe tile | `pz201_mangrove_crossed` |
| PZ-202 | RV-04 | Yes | Sunken jetty: at low tide, Root Grip two crates into the channel line; at high tide they float as stepping stones to the bell house. | Reset rope by the entrance | `pz202_jetty_crossed` |
| PZ-203 | RV-01 | Yes | Tide Song: three whistle beats with Lumi's singing. No fail state; misses just replay. | Replay | `pz203_song_sung` |

## 7. Battles
Formulas are unchanged from Chapter 1. Original creatures only. River areas on the spirit side have visible encounters; the human landing has none.

### 7.1 New combat content
- **Status: Soaked** (DEF −30% for 2 turns), from water attacks. Guarding still halves damage.
- **New skill: Ripple Echo** (Lumi, 6 MP, magical 0.9x on all enemies). It's the first area skill, learned at RV-03 after Old Pole's verse.
- Guardian Bloom and Spirit Cyclone are unchanged.

### 7.2 Regular enemies
| ID | Name | Where | Lv | HP | ATK | DEF | MAG | RES | SPD | XP | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| EN-201 | Driftnet Tangle | RV-02, RV-04 | 6 | 80 | 16 | 12 | 6 | 10 | 7 | 18 | Snare: physical 1.0x + Slow |
| EN-202 | Silt Wisp | RV-02, RV-04 | 6 | 58 | 8 | 9 | 17 | 14 | 16 | 17 | Mud Splash: magical 0.9x + Soaked |
| EN-203 | Rust Crab | RV-04 | 7 | 96 | 18 | 18 | 4 | 8 | 6 | 22 | Pinch: physical 1.3x, telegraphed |

### 7.3 Bosses
**BOSS-201 Barnacle Bell** (mid-boss, RV-04): Lv7 HP320 ATK15 DEF16 MAG18 RES12 SPD8; XP60. Clang (magical 0.8x, all heroes), Toll (telegraphed, magical 1.5x all). Below 50% it summons one Rust Crab at a time (0 XP). Immune to Slow. Reward: third verse, Soggy Bell Clapper (charm: Reno DEF +3).

**BOSS-202 The Undertow** (chapter boss, RV-05): Lv8 HP520 ATK19 DEF15 MAG21 RES17 SPD10; XP100. Immune to Slow and Soaked. Non-lethal story threshold at 15%.
| Phase | HP | Moves |
|---|---|---|
| 1 "Keep" | >60% | Grasping Net (physical 1.1x + Slow), Pull Under (magical 1.0x + Soaked) |
| 2 "Hoard" | ≤60% | Adds Flotsam Storm (physical 0.8x, all) |
| 3 "Whirlpool" | ≤30% | Whirlpool (telegraphed, magical 1.7x, all); guard and Shielded matter |

## 8. Items and shops
| ID | Name | Type | Effect | Price | Source |
|---|---|---|---|---|---|
| item_river_rice_cake | River Rice Cake | Consumable | Heal 45 HP | 3 DP | Kampung Air stall |
| item_lotus_tea | Lotus Tea | Consumable | +18 MP | 3 DP | Kampung Air stall |
| item_tide_verse_1/2/3 | Tide Song verses | Key | Quest | Not sold | C2-02/03/04 |
| item_tide_pearl | Tide Pearl | Key | Chapter 3 hook | Not sold | C2-08 |
| equip_bell_clapper | Soggy Bell Clapper | Charm | Reno DEF +3 | Not sold | BOSS-201 |

## 9. Required flags
`chapter_02_unlocked` (set at the end of Chapter 1), `ch02_started`, `ch02_song_quest_started`, `ch02_verse_1`, `ch02_verse_2`, `ch02_verse_3`, `ch02_tide_call_learned`, `ch02_tide_song_complete`, `ch02_boat_called`, `ch02_undertow_calmed`, `ch02_name_cut_learned`, `bandar_kencana_route_unlocked`, `chapter_02_completed`, `chapter_03_unlocked`. Optional: `ch02_lost_things_returned`, plus the puzzle flags.

Autosave points: arrival at RV-01, after the Barnacle Bell, before boarding the Veil boat, and after C2-09.

## 10. Build plan in Godot
- **Part A:** RV-01 to RV-03, Tide Call (a per-map tide flag driving tile overrides, with water as a "deep" tile that returns you to safety), PZ-201, Kingfishers, Pak Lumpur, Old Pole, the Kampung Air stall, Soaked, Ripple Echo, and EN-201 and EN-202.
- **Part B:** RV-04 to RV-06, PZ-202, the Barnacle Bell, the Tide Song moment, the Veil boat, the Undertow, the ending, the optional lost things, and the Chapter 2 complete screen.

## 11. Open questions (defaults chosen, Dennis can change any)
1. Nenek Arus's look: an old woman made of water reflections, with reeds in her hair. Default: yes.
2. The culprit hint: "ink on their fingers" plus Bandar Kencana. Default: yes; the Keeper isn't seen.
3. Lumi's echo line from Old Pole: keep it, with Seri unnamed. Default: yes.
4. Whether the night river scenes need a day/night palette. Default: a simple tint for now.

## 12. Decision log
- **Part A build (28 Nov 2026): Tide Call is learned at the first tide marker in RV-02, not after Pak Lumpur's verse.** PZ-201 needs the tide to reach Pak Lumpur, so the Kingfisher sisters teach the whistle tune in C2-01 and the first marker teaches the ability. Pak Lumpur still sings verse 1, and Reno and Lumi's "boss the river / ask nicely" lines move to the first marker. C02-002's reward becomes 3 Dewdrops.
- Water in RV-02 stays solid rather than a "deep" tile you fall into: you simply can't walk into it, and if the tide rises under you, you're moved to the nearest dry tile.
- Tide markers sit in the mangrove wall, so you can only reach them from dry ground.
- The C02-S01 lost-things side quest moves to part B with RV-01's morning scene.
- **Part B build (28 Nov 2026):**
  - **PZ-202.** A crate on flooded ground becomes a floating stepping stone. At low tide, the deck edge is a pillar too high to climb. At high tide, it's level with the crates.
  - **The bell house** has a skiff exit back to Kampung Air, so you can't get stuck on the far side after a reload.
  - **PZ-203 (the Tide Song)** is three "blow on the beat" prompts in dialogue. It has no fail state and doesn't use the cue ring yet.
  - **C02-S01's lost things** are a toy boat, a bicycle bell and a wedding ring. The grandmother's spoon stays for the C2-09 morning scene. You return them with the Chapter 1 Place rule: the tackle box, while the fisherman looks at the water.
  - **The Veil boat** stays at the pier until the Undertow is calmed, so loading the pre-boarding autosave still lets you board.
