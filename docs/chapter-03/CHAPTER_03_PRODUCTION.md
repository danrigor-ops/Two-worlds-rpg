# Chapter 3 Production — The Town That Forgot Its Name

> **Status: WORKING PROPOSAL (28 November 2026).** Dennis asked for all remaining chapters and treats every design doc as a guide that can change freely. This expands the handover line "Supernatural counterpart loses identity; photos and memory clues; gadgets. Recruits Elias." Stats, coordinates and prices are prototype data.

## 1. Objective and completion
Nenek Arus said the ink that cut her name smelled of Bandar Kencana, a trading town of printers and paper merchants downriver. Reno and Lumi ride a paper barge there and find a town that is forgetting its own name: humans say "Bandar... um" and shrug, shop signs read BANDAR ______, and the town's spirit counterpart, Kencana-in-the-Veil, is full of spirits who can't remember who they are.

The duo meet **Elias**, a Wayfarer spirit who lives in valve radios. He joins as the first companion: gadgets in battle, and **Tune** in the field (tuning old broadcasts out of radio masts). Old photographs (Lumi's Memory Touch) wake the human town's memory and open a crack into the Veil town. Three masts broadcast the three syllables of the name. In the Hall of Records, **the Blank Clerk**, an ink spirit left behind to keep the page blank, is defeated. The name comes back.

The Clerk's ledger is stamped with a rubber-leaf crest: **Bukit Getah Estate**. That's Chapter 4.

Completion: `chapter_03_completed`, `chapter_04_unlocked`, `bukit_getah_route_unlocked`.

### Canon guardrails
- Humans still can't see spirits. Every human line is overheard.
- Elias is an original spirit (Wayfarer kin) and **not human**: he looks like a lanky boy with an aerial for a cowlick. He can't be seen by humans either.
- The culprit stays unseen. The Clerk is a servant made of ink, not the Keeper.
- Printing, trading and radio repair are portrayed through jobs, not ethnic "types".

## 2. Maps
| ID | Name | Tiles | Function |
|---|---|---|---|
| BK-01 | Kencana Wharf | 40x30 | Arrival by paper barge; overheard humans; doors to the radio shop and photo studio; the Veil crack (west) |
| BK-02 | Kedai Radio | 20x15 | Elias in a broken valve radio |
| BK-03 | Photo Studio | 20x15 | The glass valve; PZ-301 photographs |
| BK-04 | Kencana-in-the-Veil | 40x30 | Nameless spirits, Mak Kertas's stall, PZ-302 radio masts |
| BK-05 | Hall of Records | 24x18 | BOSS-301 the Blank Clerk |

## 3. Quests
| ID | Name | Start | Completion | Reward |
|---|---|---|---|---|
| C03-001 | A Town Without a Name | `ch03_started` | `ch03_elias_joined` | 3 DP |
| C03-002 | Pictures of a Name | `ch03_elias_joined` | `ch03_photos_restored` | Coconut Jelly x2 |
| C03-003 | Voices in the Static | `ch03_photos_restored` | `ch03_masts_done` | 4 DP |
| C03-004 | The Blank Clerk | `ch03_masts_done` | `ch03_clerk_defeated` | Crystal Earpiece (battle) |

## 4. Party and new systems
- **Three active heroes.** The first three in party order fight. Later recruits sit in reserve, earn full XP and can be moved to the front from the Party menu (from Chapter 5, when there are four).
- **Companions don't walk the map.** Reno and Lumi lead and follow as before; Elias travels in Reno's satchel (he's small when he wants to be).
- **New members join at the party's level** (the average XP of the others).
- **Elias:** Spark Coil (4 MP, magical 1.4x) and Static Burst (7 MP, magical 0.8x, all enemies). Field: **Tune** at radio masts.

## 5. Main scenes
- **C3-00 Paper Barge (RV-01).** A barge stacked with paper bales leaves the landing every morning. The duo ride on top.
- **C3-01 Kencana Wharf.** Printer *(overheard)*: "Proofs for the... for the Bandar... what's this town called again?" Trader: "Ha! Long week." Lumi smells the same ink as at Nenek Arus's pool.
- **C3-02 Elias.** In Kedai Radio, a broken radio on a high shelf crackles "...valve... anybody... valve". Elias's own valve has cracked; there's a spare in the photo studio's drawer. Fitted, he pops out of the speaker grille: "Thank you! I've been stuck on the shipping forecast for a month." He joins.
- **C3-03 Photographs (PZ-301).** Three faded photographs with blank captions. Lumi's Memory Touch shows each scene; choose the right caption. All three: the photographer *(overheard)*: "Kencana. Bandar Kencana! How did I forget?" A crack in the Veil opens at the west end of the wharf.
- **C3-04 Kencana-in-the-Veil.** A violet twin of the town where spirits have lost their names ("I'm... the one who sells the... the paper things?"). Mak Kertas still runs her stall.
- **C3-05 Voices in the Static (PZ-302).** Three radio masts. Each plaque gives a clue; Elias tunes the right frequency and an old broadcast plays one syllable: KEN, CA, NA.
- **C3-06 The Blank Clerk (BOSS-301).** In the Hall of Records, an ink spirit keeps the town's page wiped clean. "Blank is tidy. Blank is safe."
- **C3-07 The Name Comes Back (BK-01).** The signs fill in. Humans laugh at themselves. Elias reads the Clerk's ledger: the stamp is a rubber leaf, *Bukit Getah Estate*. Reno: "Rubber trees! Do they have trains?" Chapter 3 complete.

## 6. Puzzles
| ID | Map | Description | Flag |
|---|---|---|---|
| PZ-301 | BK-03 | Three photos; Memory Touch (Lumi leads) shows the scene, then pick the caption. A wrong caption just says "not that one". | `ch03_photos_restored` |
| PZ-302 | BK-04 | Three masts; read the plaque, pick the frequency. Wrong frequencies play static. | `ch03_masts_done` |

## 7. Battles
| ID | Name | Lv | HP | ATK | DEF | MAG | RES | SPD | XP | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| EN-301 | Ink Blot | 8 | 90 | 10 | 10 | 22 | 16 | 14 | 26 | Smudge: magical 1.0x + Memory Fog |
| EN-302 | Typeset Beetle | 9 | 120 | 24 | 22 | 6 | 10 | 8 | 30 | Press: physical 1.4x, telegraphed |
| BOSS-301 | The Blank Clerk | 10 | 720 | 22 | 18 | 26 | 20 | 12 | 140 | Immune Slow and Fog. Phase 1: Stamp, Redline (all). ≤60%: Erase (Fog) and calls Ink Blots. ≤30%: Redact (telegraphed, magical 1.8x all) |

## 8. Items
River Rice Cake and Lotus Tea carry over. New: Coconut Jelly (70 HP, 5 DP), Chrysanthemum Tea (+25 MP, 5 DP), Glass Valve (key), the Clerk's Ledger (key, Chapter 4 hook), Crystal Earpiece (charm: Elias RES +3, SPD +2).

## 9. Decision log
- One PR per chapter from here (design and build together), merged when the headless tests pass.
- Companions are battle and story members; only Reno and Lumi walk the map.
