# Chapter 7 Production: The Guardian of the Eastern Mountains

> **Status: WORKING PROPOSAL (28 November 2026).** This expands the handover line "Borneo-inspired highlands. Recruits Galen." Stats and coordinates are prototype data.

> **Cultural research flag.** The handover asks for region-specific research before the highlands are final. This build keeps everything **fictional and generic**:
> - an invented range, *Banjaran Awan* (the Cloud Range);
> - mossy cloud forest, pitcher plants and vegetable terraces;
> - an original boulder spirit.
>
> It uses no named community, longhouse, motif, ritual or folklore being. Before final art and writing, check the setting with people from the region and replace placeholders as they advise.

## 1. Objective and completion
The Ringmaster's one-way ticket points east. The travelling carnival packs up and crosses the sea on a ferry of lantern light, and drops the party at the foot of the Cloud Range. The ink-fingered man has been here:
- a mist that won't move hides the trail;
- "silent stones" that eat sound block the Guardian's Gate.

**Galen** guards the gate. He is an ancient boulder spirit in a fern cloak and a former companion of the Oathkeepers. He mistakes the party for the stranger's allies and tests them in a trial fight. Afterwards he joins, and tells them the stranger was the youngest Oathkeeper, who stopped speaking after the 1951 crossing failure.

At the summit, the party drive off **the Hush**, a silence the stranger left wrapped around the Oath Stone. The stone then plays back the stranger's message. On the night of the **Lantern Moon** the worlds will touch, as they did in 1951, and afterwards he will close every door between them.

Completion flags: `chapter_07_completed`, `chapter_08_unlocked`, `ch07_lantern_moon_warned`.

## 2. Maps
| ID | Name | Tiles | Function |
|---|---|---|---|
| EH-01 | Banjaran Awan Foothills | 36x26 | Arrival by caravan (from PM-01). Overheard farmer and road surveyor. Ridge trader. Mist bank 1 |
| EH-02 | The Moss Forest | 34x24 | Mist banks 2 and 3 (PZ-701), pitcher plants |
| EH-03 | The Guardian's Gate | 30x26 | Galen's trial, then three silent stones (PZ-702) |
| EH-04 | The Oath Stone | 30x22 | BOSS-701 the Hush |

## 3. Quests
| ID | Name | Start | Completion | Reward |
|---|---|---|---|---|
| C07-001 | Above the Clouds | `ch07_started` | `ch07_mist_cleared` | 6 DP |
| C07-002 | The Guardian's Trial | `ch07_mist_cleared` | `ch07_galen_joined` | Cloud Honey x2 |
| C07-003 | The Oath Stone | `ch07_galen_joined` | `ch07_hush_beaten` | Moss Mantle |

## 4. New content
- **Galen (tank):**
  - Boulder Smash: 6 MP, physical 1.7x.
  - Stone Rain: 9 MP, physical 0.9x, hits all.
  - Two new passives in characters.json:
    - `draws_fire`: on even rounds, single-target enemy attacks aim at him.
    - `counter`: after a physical attack on him, he hits back for 0.6x.
  - Field ability: he breaks silent stones.
- **Mist banks:** solid until Reno (as leader) uses Spirit Cyclone on them.
- **Battle menu fix:** Skill is greyed out when the unit can't afford any of its skills.

## 5. Battles
| ID | Name | Lv | HP | ATK | DEF | MAG | RES | SPD | XP | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| EN-701 | Mist Wisp | 17 | 160 | 16 | 20 | 38 | 30 | 20 | 56 | Cold Mist: magical + Slow |
| EN-702 | Stone Silencer | 17 | 240 | 40 | 34 | 10 | 18 | 9 | 60 | Shush Slam, Brace (guard) |
| TRIAL | Galen | 17 | 1000 | 38 | 32 | 12 | 26 | 10 | 150 | Yields at 50% |
| BOSS-701 | The Hush | 18 | 1700 | 36 | 26 | 40 | 28 | 16 | 300 | Immune to Slow and Fog. Hush (Fog), Stone Drop, Echo Ache (all). From 60% it wakes a Stone Silencer; from 30%, Great Silence (telegraphed, magical 2.0x, hits all) |

## 6. Items
- Moss Mantle: Galen DEF +3, RES +2.
- Cloud Honey: restores 160 HP, 12 DP.
- Oath Stone Rubbing (key item).
