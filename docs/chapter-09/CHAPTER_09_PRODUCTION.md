# Chapter 9 Production: The Keeper of Forgotten Years

> **Status: WORKING PROPOSAL (28 November 2026).** This expands the handover line "The Archive, the truth about 1951, a first confrontation." Stats and coordinates are prototype data.

## 1. Objective and completion
The railway tear closes into a door, and the Ticket to Nowhere opens it onto **the Archive Between Worlds**, where every forgotten thing is filed. The catalogue spirit **Index** says the Keeper has come here every night for twelve years to file things away.

**The truth about 1951 (canon for this build):**
- Every twelve years, on a Lantern Moon, the Oathkeepers opened a crossing so the worlds could visit.
- In 1951 the youngest Oathkeeper led it for the first time. A train arrived as it opened, the gap began to tear, and he froze.
- **Maya**, a railway worker, and **Seri**, a guardian spirit, held the gap open with their hands until everyone was across.
- The last one across was a tiny spirit child. Maya pressed her railway token into his hand. **That child is Reno.**
- Seri's light broke into echoes, and one followed the child. **That echo is Lumi.**
- The gap closed with Maya and Seri on the other side.
- The young Oathkeeper wrote down Maya's last words and hid them: *"Tell them to keep the doors open. Don't let this make anyone afraid."* He became the Keeper of Silence.

At his desk, the party confront the Keeper and show him Maya's page. He breaks off the fight at 40% HP. He can't stop: "If I stop now, everything I've done was for nothing." He flees to **the First Crossing** to unmake the Promise.

Completion flags: `chapter_09_completed`, `chapter_10_unlocked`.

## 2. Maps
| ID | Name | Tiles | Function |
|---|---|---|---|
| AR-01 | The Archive Between Worlds | 32x26 | Entered by the railway tear in LM-01 (one-way back). Index. PZ-901: three catalogue gates |
| AR-02 | The Reading Room of 1951 | 30x20 | PZ-902: three memory pages that only Lumi can read, then the hidden fourth page |
| AR-03 | The Keeper's Desk | 30x22 | BOSS-901. A golden door appears afterwards (the Chapter 10 entry) |

## 3. Puzzles
- **PZ-901 Catalogue gates.** Each gate is a callback to the journey:
  1. The Oath Stone Rubbing from Chapter 7 opens the first.
  2. Index asks "whose Promise is it?" The answer, "Everyone who keeps it", is the Chapter 5 memory.
  3. The Ticket to Nowhere from Chapter 8 opens the third.
- **PZ-902 Pages written in light.** Lumi must lead to read them. Reading all three reveals Maya's hidden page.

## 4. Quests
| ID | Name | Start | Completion | Reward |
|---|---|---|---|---|
| C09-001 | The Catalogue | `ch09_started` | `ch09_gates_open` | 10 DP |
| C09-002 | The Truth About 1951 | `ch09_gates_open` | `ch09_truth_known` | Cloud Honey x3 |
| C09-003 | The Keeper of Forgotten Years | `ch09_truth_known` | `ch09_keeper_confronted` | Oathkeeper's Pin |

## 5. Battles
| ID | Name | Lv | HP | Notes |
|---|---|---|---|---|
| EN-901 | Erased Page | 21 | 230 | Blank Out (Fog), Paper Cut |
| EN-902 | Ink Wraith | 21 | 280 | Smudge (Poison), Blot |
| BOSS-901 | The Keeper of Silence (first) | 22 | 2600 | Immune to Slow, Fog and Poison. Grey Rain (all), Quiet Hand, Silence Ink (Fog). From 75% he calls an Erased Page. From 55%, Forget Everything (telegraphed, all). **Ends at 40%** |

## 6. Items
- Oathkeeper's Pin: Reno ATK +3, SPD +2.
- Maya's Page (key item; used in Chapter 10).
