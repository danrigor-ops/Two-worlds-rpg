# Chapter 8 Production: The Night the Worlds Touched

> **Status: WORKING PROPOSAL (28 November 2026).** This expands the handover line "Three party-pair missions, full roster." Stats and coordinates are prototype data.

## 1. Objective and completion
Galen's Oathkeeper road, the Lantern Path, folds three nights into three steps and brings the party back to **Bandar Senja** on the night of the Lantern Moon. Three tears have opened between the worlds, and the party **splits up**:

| Mission | Team | Map | Ability gates | Boss |
|---|---|---|---|---|
| A. The River Tear | Lumi, Maris, Elias | LM-02 | Maris Regrows a bridge over spilled spirit water. Lumi's Echo Sight finds the knot | Riptide Wraith |
| B. The Market Tear | Reno, Taro, Galen | LM-03 | Taro's Decoy (a paper cat even humans can see tonight) leads a human watchman away. Galen breaks a silent stone | Lantern Glutton |
| C. The Railway Tear | Reno and Lumi | LM-04 | Opens once A and B are sealed. It shows 1951 | Echo of 1951 |

The railway tear replays the 1951 crossing. A railway worker carries Reno's token and a guardian spirit made of light pulls people back from the gap. Lumi recognises the spirit without knowing why.

Afterwards **the man in the grey coat** appears. He names Maya and Seri, the two who held the crossing and didn't come back, and gives himself the name **the Keeper of Silence**. He tells the duo the whole truth is in the **Archive**, then leaves a 1951 ticket behind.

Completion flags: `chapter_08_completed`, `chapter_09_unlocked`, `ch08_archive_revealed`.

### Canon guardrails
- Humans still can't see spirits. Tonight they *notice* things:
  - signal lamps turn green on their own;
  - a girl sees a door in the moon;
  - the watchman follows an illusion cat, because Taro's illusions are visible to humans on this one night.
- Maya and Seri are seen only as figures in an echo. The full truth is held back for Chapter 9.

## 2. New system: mission parties
`GameState.set_mission(ids)` and `clear_mission()` split and regroup the party. In dialogue they're triggered with the event `mission:a,b,c` (or `mission:` to regroup).

While a mission is active:
- only the team fights (`active_party()`);
- only the team's Reno and/or Lumi walk the map (`walking_party()`), and the leader moves onto the team;
- the Party menu marks everyone else "(away)" and locks formation.

The mission is saved. Older saves migrate to an empty mission, and a mission member who isn't in the party fails validation.

## 3. Maps
| ID | Name | Tiles | Function |
|---|---|---|---|
| LM-01 | Bandar Senja, Lantern Moon | 34x26 | Hub. Entered by the Lantern Path from EH-04. Three tear NPCs, overheard humans |
| LM-02 | The River Tear | 30x20 | Mission A |
| LM-03 | The Market Tear | 30x20 | Mission B |
| LM-04 | The Railway Tear | 30x22 | Mission C |

## 4. Quests
| ID | Name | Start | Completion | Reward |
|---|---|---|---|---|
| C08-001 | The River Tear | `ch08_started` | `ch08_river_sealed` | 8 DP |
| C08-002 | The Market Tear | `ch08_started` | `ch08_market_sealed` | Cloud Honey x2 |
| C08-003 | The Railway Tear | `ch08_two_sealed` | `ch08_echo_beaten` | Lantern Moon Charm |

## 5. Battles
| ID | Name | Lv | HP | Notes |
|---|---|---|---|---|
| EN-801 | Tear Sprite | 19 | 200 | Rift Spark (magical), Snag (Slow) |
| BOSS-801 | Riptide Wraith | 19 | 1300 | Magical. Undertow (Soaked), Cold Wave (all). From 50% a Tear Sprite appears, plus Flood Bell (telegraphed) |
| BOSS-802 | Lantern Glutton | 19 | 1400 | Physical (Galen's counter shines). From 50% a sprite appears, plus Swallow the Moon (telegraphed) |
| BOSS-803 | Echo of 1951 | 20 | 1000 | Two-hero fight. Lost Platform (Fog) from 60%. The Crossing Fails (telegraphed, all) from 30% |

## 6. Items
- Lantern Moon Charm: Lumi MAG +3, RES +2.
- Ticket to Nowhere (key item; leads into Chapter 9).
