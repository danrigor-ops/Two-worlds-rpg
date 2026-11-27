# Chapter 4 Production — The Rubber Grove at Midnight

> **Status: WORKING PROPOSAL (28 November 2026).** Expands the handover line "Frightened displaced spirit, shadowy estate and mediation." Dennis treats designs as a changeable guide. Stats and coordinates are prototype data.

## 1. Objective and completion
The Blank Clerk's ledger was stamped **Bukit Getah Estate**. The party (Reno, Lumi, Elias) ride a lorry up the hill road. At night the estate's rubber grove is full of shadows: lanterns go out, paths close, the trees whisper in fright. The grove's guardian, **Titis**, a small spirit of the first drop of morning sap, has been displaced: someone with ink on their fingers cut her name, and her fear has grown into a separate thing, **the Fear-Shadow**, that walls the grove off.

Reno learns **Forest Whisper** (talk to frightened trees) and **Root Uppercut**. In the smokehouse clearing the party *mediates* with Titis instead of fighting her: patient answers, no wrong-answer punishment. Calmed, her Fear-Shadow pulls loose and the party fights it.

Titis tells them the ink-fingered stranger asked the way to **Hutan Seribu Bunga**, the forest of a thousand flowers, "looking for a flower that helps people forget". Chapter 5.

Completion: `chapter_04_completed`, `chapter_05_unlocked`, `seribu_bunga_route_unlocked`.

### Canon guardrails
- Humans can't see spirits. Tappers are overheard, talking about their work (tapping before dawn, cups, latex, the smokehouse), never as ethnic types.
- Titis is an original spirit, not a named folklore being. Mediation, not exorcism. No ritual is depicted.
- The culprit stays unseen.

## 2. Maps
| ID | Name | Tiles | Function |
|---|---|---|---|
| GT-01 | Estate Road | 40x30 | Lorry from Bandar Kencana; tappers overheard; night until the end |
| GT-02 | The Rubber Grove | 48x30 | PZ-401: three frightened trees block the lanes; Forest Whisper |
| GT-03 | Smokehouse Clearing (spirit side) | 30x20 | PZ-402 mediation with Titis; BOSS-401 the Fear-Shadow |

## 3. Quests
| ID | Name | Start | Completion | Reward |
|---|---|---|---|---|
| C04-001 | Lanterns Going Out | `ch04_started` | `pz401_grove_calm` | 4 DP |
| C04-002 | Something Small and Scared | `pz401_grove_calm` | `ch04_titis_calmed` | Coconut Jelly x2 |
| C04-003 | The Fear-Shadow | `ch04_titis_calmed` | `ch04_shadow_beaten` | Sap-Drop Charm (battle) |

## 4. New content
- **Forest Whisper** (Reno leads): at a frightened tree, pick what to say. The right words (based on what the tree is afraid of) calm it and the lane opens.
- **Root Uppercut** (Reno, 5 MP, physical 1.6x).
- **Status: Poison** (6% max HP after each of the unit's own actions, 3 turns), from the handover's status list.
- **Mediation (PZ-402):** three questions from Titis. A wrong answer just makes her hide again; try again.

## 5. Battles
| ID | Name | Lv | HP | ATK | DEF | MAG | RES | SPD | XP | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| EN-401 | Latex Lurker | 11 | 150 | 26 | 20 | 10 | 16 | 9 | 36 | Sticky Grab: physical 1.1x + Slow |
| EN-402 | Grove Shade | 11 | 110 | 14 | 14 | 28 | 22 | 17 | 34 | Bitter Sap: magical 0.9x + Poison |
| BOSS-401 | The Fear-Shadow | 12 | 950 | 28 | 22 | 30 | 22 | 13 | 180 | Immune Slow/Fog/Poison. Loom, Dread (Fog); ≤60% Bitter Rain (all) + Grove Shades; ≤30% Nightfall (telegraphed, magical 1.9x all) |

## 6. Items
Sap-Drop Charm (charm: Lumi MAG +3, from the boss). No new stall: the estate is a working place at night.

## 7. Decision log
- The Fear-Shadow is a separate being, so the party never fights Titis herself.
