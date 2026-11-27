# Chapter 5 Production — A Thousand Flowers, One Promise

> **Status: WORKING PROPOSAL (28 November 2026).** Expands the handover line "Floral sanctuary, memory fragments and restorative plants. Recruits Maris." Stats and coordinates are prototype data.

## 1. Objective and completion
Titis said the ink-fingered stranger went to **Hutan Seribu Bunga**, the ancient forest of a thousand flowers, for a flower that helps people forget. The party walks the old trail east of Bukit Getah and finds the sanctuary wilting from the centre out.

They free **Maris**, a sanctuary-keeper spirit tangled in dead vines, who joins as the healer: Bloom Heal and Thorn Lash in battle, **Regrow** in the field (grow vine bridges over the stream). Three **memory blossoms** hold fragments the sanctuary kept (Lumi's Memory Touch): the Great Promise being planted, a young Oathkeeper crying here long ago, and the stranger planting forgetting-flower seeds last week. At the heart, the seeds have grown into **the Forgetting Bloom**.

After the battle the sanctuary breathes again. Among the roots: a ticket stub for **Pasar Malam Impian**, the travelling midnight carnival. Chapter 6.

Completion: `chapter_05_completed`, `chapter_06_unlocked`, `carnival_route_unlocked`.

### Canon guardrails
- Maris is an original spirit (Forest Kin), not a named folklore being.
- The 1951 thread stays partial. The memory shows "a young Oathkeeper" crying after a crossing failure; he is not named as the Keeper of Silence, and the player isn't told it's the same person (strongly hinted).
- The forgetting flower is invented ("Lupa-bloom"), not a real plant or medicine.

## 2. Maps
| ID | Name | Tiles | Function |
|---|---|---|---|
| SB-01 | Old Forest Trail | 40x30 | From Bukit Getah's east path; Maris in dead vines |
| SB-02 | The Thousand Flowers | 48x30 | PZ-501 Regrow bridges; three memory blossoms (PZ-502) |
| SB-03 | Heart of the Sanctuary | 30x24 | BOSS-501 the Forgetting Bloom |

## 3. Quests
| ID | Name | Start | Completion | Reward |
|---|---|---|---|---|
| C05-001 | The Wilting Trail | `ch05_started` | `ch05_maris_joined` | 4 DP |
| C05-002 | What the Flowers Kept | `ch05_maris_joined` | `ch05_memories_seen` | Chrysanthemum Tea x2 |
| C05-003 | The Forgetting Bloom | `ch05_memories_seen` | `ch05_bloom_beaten` | Petal Brooch (battle) |

## 4. New content
- **Maris** (healer): Bloom Heal (6 MP, heals everyone MAG x1.4, no cue), Thorn Lash (4 MP, magical 1.3x). Field: **Regrow**.
- **Formation:** with four members, the Party menu marks reserves (R); A moves someone to the front. The first three fight.
- **Healing skills** are a new skill kind (`heal`).

## 5. Battles
| ID | Name | Lv | HP | ATK | DEF | MAG | RES | SPD | XP | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| EN-501 | Thorn Sprite | 13 | 160 | 30 | 22 | 12 | 18 | 15 | 42 | Prickle: physical 1.2x + Poison |
| EN-502 | Pollen Puff | 13 | 130 | 12 | 16 | 30 | 24 | 11 | 40 | Drowsy Pollen: magical 0.7x all |
| BOSS-501 | The Forgetting Bloom | 14 | 1200 | 30 | 24 | 34 | 26 | 14 | 220 | Immune Slow/Poison. Petal Storm (all), Forget-Me (Fog); ≤60% calls Thorn Sprites; ≤30% Wilt (telegraphed, magical 2.0x all) |

## 6. Items
Petal Brooch (charm: Maris MAG +2, RES +2, from the boss). The carnival ticket stub (key, Chapter 6 hook).
