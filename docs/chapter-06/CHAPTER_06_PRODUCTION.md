# Chapter 6 Production — The Midnight Carnival

> **Status: WORKING PROPOSAL (28 November 2026).** Expands the handover line "Illusions, impossible attractions, unreliable performer. Recruits Taro." Stats and coordinates are prototype data.

## 1. Objective and completion
The ticket stub says **Pasar Malam Impian**, a travelling midnight carnival that only appears to people who want to forget something. Tonight its lights glow through the trees south of the Old Forest Trail.

It's a spirit carnival hiding inside an ordinary human pasar malam: humans at the edges see satay smoke and toy stalls, spirits see impossible rides. The party meet **Taro**, a paper-lantern trickster and the carnival's star performer, who lies for a living and at first sends them the wrong way. In the **Hall of Mirrors** Lumi's Echo Sight shows which mirrors are really doorways. Taro, caught out and a bit ashamed, joins: speed and illusions in battle, **Decoy** in the field. With a decoy distracting the ticket-taker, the party ride the **Ghost Train** (Reno's dream) to the Big Top, where **the Ringmaster of Maybe** has been hiding the stranger's trail behind illusions.

The Ringmaster admits the ink-fingered man bought a one-way ticket "east, over the sea, to the mountain where the Oathkeepers swore their oath". Chapter 7.

Completion: `chapter_06_completed`, `chapter_07_unlocked`, `eastern_route_unlocked`.

### Canon guardrails
- Humans can't see spirits; the human pasar malam is overheard only (hawkers, families, a toy-seller).
- Taro is an original Wayfarer spirit (a paper lantern that learned to juggle). Not a fox spirit or any named folklore being.
- The Ringmaster is a carnival spirit who helped the stranger out of pity, not a villain.

## 2. Maps
| ID | Name | Tiles | Function |
|---|---|---|---|
| PM-01 | Pasar Malam Impian | 40x30 | Entry from SB-01's south path; stalls; Taro's show; doors to the Hall of Mirrors and the Ghost Train |
| PM-02 | Hall of Mirrors | 30x20 | PZ-601: false mirrors, Echo Sight reveals them |
| PM-03 | Ghost Train Platform | 30x16 | PZ-602: the ticket-taker watches the lever; Taro's Decoy (or good timing) |
| PM-04 | The Big Top | 30x22 | BOSS-601 the Ringmaster of Maybe |

## 3. Quests
| ID | Name | Start | Completion | Reward |
|---|---|---|---|---|
| C06-001 | Admit One | `ch06_started` | `ch06_taro_joined` | 5 DP |
| C06-002 | The Last Ride | `ch06_taro_joined` | `ch06_ride_taken` | Coconut Jelly x3 |
| C06-003 | The Ringmaster of Maybe | `ch06_ride_taken` | `ch06_ringmaster_beaten` | Juggler's Ribbon (battle) |

## 4. New content
- **Taro** (speed/illusion): Trick Shot (5 MP, physical 1.5x), Dazzle (7 MP, magical 0.9x all). Field: **Decoy**.
- **False walls:** mirror tiles that look solid but aren't. Echo Sight (Lumi leads, at the echo marker) shows them.
- **Watched switches:** the ride lever can only be pulled while the ticket-taker looks away, or after a Decoy.

## 5. Battles
| ID | Name | Lv | HP | ATK | DEF | MAG | RES | SPD | XP | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| EN-601 | Funhouse Double | 15 | 190 | 34 | 24 | 14 | 20 | 16 | 50 | Copycat: physical 1.2x |
| EN-602 | Balloon Imp | 15 | 140 | 14 | 18 | 34 | 26 | 19 | 48 | Pop!: magical 1.0x + Fog |
| BOSS-601 | The Ringmaster of Maybe | 16 | 1250 | 34 | 24 | 36 | 24 | 18 | 260 | Immune Slow/Fog. Cane Twirl, Now You Don't (Fog); ≤60% calls Funhouse Doubles; ≤30% Grand Finale (telegraphed, magical 2.0x all) |

## 6. Items
Juggler's Ribbon (charm: Taro SPD +3, ATK +2, from the boss). Toffee Apple (120 HP, 8 DP) and Sugarcane Juice (+35 MP, 8 DP) at the carnival stall.
