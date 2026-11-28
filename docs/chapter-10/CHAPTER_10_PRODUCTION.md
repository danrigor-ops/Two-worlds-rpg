# Chapter 10 Production: Where Two Worlds Meet

> **Status: WORKING PROPOSAL (28 November 2026).** This expands the handover lines "Multi-phase Keeper confrontation, Promise renewed" and "the Promise is rebuilt as voluntary coexistence". Stats and coordinates are prototype data.

## 1. Objective and completion
A golden door at the Keeper's desk opens onto **the First Crossing**: a bridge of lanterns over nothing, where a human and a spirit first promised to keep the way open. The Keeper is putting the lanterns out.

1. **Bridge of Lanterns (PZ-1001).** Four Promise lanterns light "for anyone who remembers why they keep the Promise". Each companion relights one with a short, personal reason that calls back to their chapter: Elias, Maris, Taro and Galen. With all four lit, the wall of silence falls.
2. **The Keeper (BOSS-1001).** He is fighting to close every door. He breaks at 30%.
3. **The Great Silence (BOSS-1002).** Twelve years of forgetting stand up on their own, a threat to both worlds. Reno's token and Lumi's light answer two faint voices ("Together"), and the duo learn the team skill **Promise Renewed**.
4. **The Promise renewed.**
   - Echoes of Maya and Seri appear, smiling, keeping the door on their side, and ask the duo to visit every Lantern Moon.
   - The Keeper remembers Maya's words and chooses to help.
   - Galen restates the Promise as **voluntary coexistence**: anyone who wants to cross may cross, and anyone who wants to stay may stay.
   - Everyone puts a hand on the last lantern.

Completion flags: `chapter_10_completed`, `epilogue_unlocked`.

## 2. Maps
| ID | Name | Tiles | Function |
|---|---|---|---|
| FC-01 | The Bridge of Lanterns | 32x24 | Entered by the golden door in AR-03. Four lanterns (PZ-1001), a silence wall, Silence Shards |
| FC-02 | The Heart of the Crossing | 30x24 | BOSS-1001 then BOSS-1002 |

## 3. Quests
| ID | Name | Start | Completion | Reward |
|---|---|---|---|---|
| C10-001 | The Bridge of Lanterns | `ch10_started` | `ch10_bridge_open` | 12 DP |
| C10-002 | Where Two Worlds Meet | `ch10_bridge_open` | `ch10_silence_beaten` | The Renewed Promise |

## 4. New content
**Promise Renewed** is a team skill for Reno and Lumi:
- 6 MP each;
- four timed cues;
- 3.2x damage;
- learned between the two final fights (`requires_flag: ch10_promise_learned`).

## 5. Battles
| ID | Name | Lv | HP | Notes |
|---|---|---|---|---|
| EN-1001 | Silence Shard | 23 | 260 | Mute (Fog), Shard Rain (all) |
| BOSS-1001 | The Keeper of Silence (final) | 24 | 3000 | Immune to Slow, Fog and Poison. From 70% he calls an Erased Page. From 45%, Close Every Door (telegraphed, 2.2x, all). **Ends at 30%** |
| BOSS-1002 | The Great Silence | 25 | 3200 | Immune to Slow, Fog, Poison and Soaked. Engulf (all), Crushing Quiet. From 66% it sheds Silence Shards. From 33%, The End of All Sound (telegraphed, 2.4x, all) |
