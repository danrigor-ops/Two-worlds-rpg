# Chapter 1 Production — The Last Train to Bandar Senja

> **Status: CONFIRMED_USER (approved by Dennis on 27 November 2026), revision 2.** Dennis decided that **humans cannot see Reno and Lumi**, then approved the rest of this design and its recommendations, including the dreaming-passengers rule. He treats it as a guide that can change freely. Approval covers the story, structure, scenes and rules. Stats, prices, map sizes and coordinates are still prototype data to tune in playtests (01 rule), and items marked `PLACEHOLDER` stay stand-ins until researched or replaced.
>
> Shape follows `05_PROLOGUE_PRODUCTION.md`. Formulas follow `04_GAMEPLAY_SYSTEMS.md`. Canon follows `01_CANON_AND_DECISIONS.md`. Machine-readable companions live in `docs/chapter-01/data/`.

## 1. Objective and completion
Reno finally gets his train ride, and it goes very wrong. The duo arrive in Sungai Melor and discover that humans can't see or hear them at all. A kopitiam kettle spirit teaches them how to get by unseen, and they stow away on the bus to the rail town of Bandar Senja. There the station's own spirit, the Clockkeeper, offers them Veil-stamped tickets for the evening train if they secretly return three parcels the human stationmaster has lost. The evening train slips into a Veil Crossing. Aboard, the Forgotten Conductor is "punching" travellers' tickets and taking their destinations and Veil-touched memories. Reno and Lumi recover them, calm the Conductor, glimpse that Lumi's own past is missing, and unlock the river route that leads into Chapter 2.

Completion: `chapter_01_completed` set after scene C11, with `river_route_unlocked` and `chapter_02_unlocked`. Safe autosave on completion.

Pacing target: **60–80 minutes** main path, plus 15–20 minutes optional (not playtested). Expected party level: enter Lv2–3, reach Lv5 before the boss, leave at Lv6 (section 7.2).

### The visibility rule (CONFIRMED_USER: humans cannot see the spirits)
- In the Human World, humans cannot see or hear Reno, Lumi or other spirits. They can notice the **effects**: a parcel that "appears" on a desk, a door that swings, coins that sort themselves. Humans explain these away ("the fan must be broken").
- Reno and Lumi can see and hear humans, so they learn about the world by **overhearing**. Human dialogue is written as people talking to each other or to themselves, never to the duo.
- Spirits can carry and place small human objects. Doing so to help is fine; taking from humans is not something the heroes do. This is a tone rule, not a mechanic the player can break.
- **Inside the Veil (approved):** humans caught inside a Veil Crossing are half-dreaming and can see spirits dimly, as in a dream. This lets the train passengers in C09 speak to the duo. Afterwards they remember only "a strange dream about two children".
- Consequence for the economy: human shops and human money (`humanCents`) are out of reach in Chapter 1. Shopping uses **Dewdrops** at spirit stalls. Human money stays in the save schema for later chapters.

### Canon guardrails applied in this chapter
- Sungai Melor is a **riverside settlement with no railway station**. The bus is the only way out. Bandar Senja is the separate rail town (01 audit correction).
- The Veil train is supernatural. No real railway company, livery, logo, timetable or real station is depicted.
- Lumi learns her early past is **missing**, not who she "was". She is not Seri, and Seri is not named. The 1951 truth stays reserved for Chapter 9.
- All spirits introduced here (Old Kettle, the Clockkeeper, Mr Slot, the Forgotten Conductor, every enemy) are **original**. None is a named Malaysian folklore being, and none makes a religious claim.
- The Book of Names is hinted at (the Conductor's name has been removed), but it does not alter physical records or bring anyone back.

## 2. Maps, grid sizes, and proposed IDs
16x16 tiles, 240x160 logical view (15x10 tiles visible). Sizes are design anchors only, to validate against painted maps and collision. Every map has the prologue's layer set: ground, decor, blocking collision, overhead, triggers, spawns.

| ID | Name | Tiles | Function | Return allowed |
|---|---|---|---|---|
| SM-01 | Sungai Melor Entrance | 40x30 | Prologue arrival point, chapter hub start | Yes |
| SM-02 | Jetty and Market Lane | 48x32 | Market stalls, river jetty, dropped postcard (optional) | Yes |
| SM-03 | Kopitiam | 20x15 | Old Kettle (spirit guide and stall), overheard bus talk | Yes |
| SM-04 | Sundry Shop | 16x12 | Coin Jar kindness puzzle | Yes |
| SM-05 | Village Road Bus Stop | 32x20 | Boarding puzzle | Until bus boarded |
| TR-01 | Country Bus (interior) | 24x10 | Cutscene map on the luggage rack, overheard passengers | No |
| BS-01 | Bandar Senja Station Forecourt | 40x30 | Town hub, Mr Slot the post box | Yes |
| BS-02 | Station Hall and Ticket Office | 32x24 | Human stationmaster (overheard), the Clockkeeper and spirit stall | Yes |
| BS-03 | Goods Shed | 36x28 | Crate puzzle, Parcel A, 1951 shelf | Yes |
| BS-04 | Shophouse Row | 48x28 | Smudged label clue chain, Parcel C | Yes |
| BS-05 | Rail Yard | 44x32 | Signal lever puzzle, moth encounters, mid-boss, Parcel B | Yes |
| BS-06 | Platform 2 (evening) | 40x20 | Boarding; later the dawn ending | Yes |
| VT-01 | Veil Train: Third-Class Carriage | 40x12 | First Veil encounters, dreaming passengers | Yes, within train |
| VT-02 | Veil Train: Dining Car | 40x12 | Destination-matching puzzle | Yes, within train |
| VT-03 | Veil Train: Carriage Roof | 48x12 | Gentle Float tutorial, gap crossing | Yes, within train |
| VT-04 | Veil Train: Luggage Van | 40x12 | Lantern keyhole (optional), Lost Luggage | Yes, within train |
| VT-05 | Veil Train: Guard's Van | 30x14 | Forgotten Conductor boss arena | No (boss lock) |
| VT-06 | The Veil Halt | 36x24 | Ghost platform, memory release, Lumi beat, river route | No (story exit) |

Notes:
- SM-01 already exists as the prologue's end map (size TBD there). 40x30 is a suggestion for the prologue team, not a requirement.
- Inside the train, carriages connect through end doors with two-way safe spawns. Backtracking is allowed until the Guard's Van door locks.
- After C11, Bandar Senja maps are revisitable. The train maps (VT-*) are not, apart from a Memory Album replay.

## 3. Main quests and prerequisites
| ID | Name | Prerequisite | Completion | Reward |
|---|---|---|---|---|
| C01-001 | Unseen | `prologue_completed` | Learn the visibility rule from Old Kettle and secretly sort the Coin Jar | 3 Dewdrops, 2 Kaya Toast, Old Kettle's bus tip |
| C01-002 | The Bus to Bandar Senja | `ch01_kettle_tip_heard` | Board the bus unseen (SM-05 puzzle), ride TR-01, arrive at BS-01 | Autosave |
| C01-003 | The Stationmaster's Parcels | `ch01_arrived_bandar_senja` | Parcels A, B and C all secretly returned to the stationmaster's desk | 2 Veil-Stamped Tickets (key), 2 Moonleaf Bun |
| C01-004 | The Paper Moth Monarch | Parcel B trail started (in C01-003) | Mid-boss defeated | Parcel B, Blank Punched Ticket, Moth-Wing Charm, Guardian Bloom learned |
| C01-005 | The Last Train | `ch01_tickets_obtained` | Board at Platform 2, Veil transition scene | Autosave before departure |
| C01-006 | Tickets, Please | `ch01_veil_train_entered` | Three mandatory passengers' destinations returned | Route to Guard's Van opens |
| C01-007 | The Forgotten Conductor | `ch01_guards_van_unlocked` | Boss reaches story threshold | Conductor's Whistle (key), 80 XP |
| C01-008 | The Veil Halt | `ch01_conductor_calmed` | Memory release, Lumi scene, river route marker | Chapter 2 unlock, autosave |

Rules carried over from the prologue:
- C01-003's three parcels can be done in any order. Each sets its own flag. Only the return of all three completes the quest.
- C01-004 is mandatory because Parcel B is inside the moth nest.
- Nothing in the main path costs money, so there is no farming, random-drop or shopping gate. The bus and train cost nothing because the duo are unseen. The Clockkeeper's tickets are about safety in the Veil, not fares.

### Optional side quests
| ID | Name | Where | Completion | Reward |
|---|---|---|---|---|
| C01-S01 | A Postcard Home | Picked up in SM-02, posted at BS-01 | A fisherman dropped his postcard on the jetty. Carry it to Bandar Senja and post it. | 2 Dewdrops from Mr Slot, Memory Album entry |
| C01-S02 | The Dead-Letter Shelf | BS-03 | Memory Touch on the 1951 parcel tag | Memory Album entry "A Railway Badge" |
| C01-S03 | Unclaimed Luggage | VT-04 | Lantern reveals the Veil keyhole, Lost Luggage battle | Brass Lantern Hook (Tool) |
| C01-S04 | Two Extra Passengers | VT-01, VT-02 | Return two optional destinations | Folklore Journal entries, 1 Firefly Tea each |

Optional content never blocks the chapter exit, and unique rewards can't repeat.

## 4. Field abilities and interactions in this chapter
| Ability | Owner | Status in Ch 1 | Used for |
|---|---|---|---|
| Leaf Leap | Reno | From prologue | Roof gaps, yard ditches, hopping onto the bus |
| Root Grip | Reno | From prologue | Pull goods-shed crates one tile |
| Echo Sight | Lumi | From prologue | Ghost handcar path in the rail yard |
| Memory Touch | Lumi | **First mandatory use** (tutorial in BS-04) | Smudged labels, passengers' tickets, the 1951 tag |
| Gentle Float | Lumi | **New**, unlocked in VT-03 | Gaps too wide for Leaf Leap; Reno holds her scarf for a comic tow |
| Place | Both | **New interaction** | Put a carried human object down at a marked spot when no human is looking (see below) |

Field abilities cost no combat MP (04 rule).

**Place (unseen delivery).** Some human NPCs have a simple facing loop (look at paperwork, turn to the window, look back). A marked drop spot glows only while the human faces away. Pressing interact then places the object. There is **no fail state and no timer**: if the human is facing the spot, the prompt is just greyed out and Lumi says "Wait until he looks away." The human's reaction line plays afterwards. This mechanic is the chapter's running gag.

## 5. Main scenes and core dialogue
Dialogue is selected main-path copy, in the prologue's punchy style. Full NPC variants remain to author. Lines marked *(overheard)* are humans talking among themselves; they cannot hear the duo.

### C00 — Morning in Sungai Melor (SM-01)
Continues from P07. The bus has gone. A woman with a basket walks straight towards Reno and he has to leap aside.
Reno: "Excuse me! Good morning! Hello!"
The woman walks on without a glance.
Reno: "Rude."
Lumi: "Reno. She didn't see you."
Reno: "I'm *very* visible. I'm wearing a red scarf."
A man cycles past and rings his bell at nothing in particular. Reno waves both arms. Nothing.
Lumi: "They can't see us. Or hear us."
Reno: "...So I could make the funniest face in the world and nobody would know?"
Lumi: "That's your first thought?"
Objective: *Find out how to get to Bandar Senja.*

### C01 — Old Kettle (SM-03)
In the kopitiam, a battered tin kettle on the back shelf opens one eye.
Old Kettle: "Forest kids, eh? Don't bother waving. They can't see you. They never could."
Lumi: "You're a spirit too."
Old Kettle: "I'm a kettle with opinions. Thirty years on this shelf. I know every bus, every customer and every rumour in Sungai Melor."
Reno: "We need to get to Bandar Senja. For a train."
Old Kettle: "The bus will take you, if you can get on it. But first, do me a favour. Something knocked Encik Lim's change jar over last night. A cold wind, out of nowhere. That's been happening a lot lately."
Lumi: "A cold wind?"
Old Kettle: "Veil wind. Sort his coins before he opens up, and I'll tell you the trick for the bus."
*(Overheard, kopitiam owner to a regular)*: "The evening train from Bandar Senja always runs late. My cousin says people fall asleep on it and wake up not knowing where they are."

### C02 — The Coin Jar (SM-04, PZ-101)
The coins are spilled across the floor of the closed sundry shop. The player sorts them into piles of fifty cents.
Reno: "How many is fifty?"
Lumi: "It's written on them."
Reno: "This one says ten. So five of these makes... a lot!"
Lumi: "It makes fifty, Reno."
On solve, Encik Lim (`PLACEHOLDER` name) unlocks the shop and stops dead.
Encik Lim *(to himself)*: "Sorted? All of it? ...I must have done it in my sleep."
Reno: "You're welcome!"
Lumi: "He can't hear you."
Reno: "I'm saying it for *me*."
Back at the kopitiam, Old Kettle gives 3 Dewdrops and two pieces of Kaya Toast "that fell off a plate".
Old Kettle: "The bus trick: wait for someone with a big load. The door stays open longest for people carrying baskets. And ride up top, on the luggage rack. Nobody sits there."

### C03 — The Bus (SM-05 to TR-01)
Boarding puzzle at the bus stop: passengers queue and the door opens briefly for each. The player times nothing; instead they pick which passenger to follow. Following the man with two baskets of rambutans works; following anyone else, the door closes first and Lumi suggests the right one. Reno Leaf Leaps onto the rack inside.
Reno, on the luggage rack, nose against the window: "It's even better than I imagined."
Lumi: "You're lying on a sack of onions."
Reno: "*Even better.*"
*(Overheard, two passengers)*: "My brother at the station says three parcels have gone missing this week." "Missing? From the station?" "And the goods shed is full of moths."
Lumi hears a faint train whistle that no human reacts to.
Lumi: "Did you hear that?"
Reno: "The bus going *brrrrrm*? Yes! It's the best sound in the world!"
Lumi: "...Never mind."
Fade to arrival at BS-01, then autosave.

### C04 — The Clockkeeper (BS-02)
The human stationmaster, Pak Darus (`PLACEHOLDER` name), is buried in paperwork.
Pak Darus *(to the ticket clerk)*: "Three parcels gone. One somewhere in the goods shed, one in the yard, and one sent to the wrong shop with a label nobody can read. If they're not on my desk by tonight, head office will have my cap."
A ticking voice comes from the big station clock above the ticket window.
The Clockkeeper: "Tick. You two. Yes, you. The ones he can't see."
Reno: "The clock is talking!"
The Clockkeeper: "The clock has been talking since 1931. Nobody listens. Tick. You want the evening train?"
Reno: "More than anything!"
The Clockkeeper: "Then you need one of my tickets. Stamped for the Veil. The evening train hasn't been running straight for weeks. Board it without a stamp, and you may not get off where you meant to."
Lumi: "And what do you want in return?"
The Clockkeeper: "Pak Darus is a good man. He winds me every Monday. Find his parcels and put them on his desk. Quietly."
Reno: "Secret parcel heroes! Deal!"
Lumi: "We once lost a bridge."
Reno: "And then we *found* it!"
Objective: *Return three parcels to the stationmaster's desk (0/3).* Each return uses Place on the desk while Pak Darus faces the window.
Pak Darus, after the first: "...Was that there a minute ago?"
After the second: "I'm not going to question it."
After the third: "Ticket clerk! Did you— never mind. Never mind."

### C05 — Parcel A, the Goods Shed (BS-03, PZ-103)
Crates block the parcel shelf. Dust Bundles roll around the aisles.
Reno: "Root Grip! I'll just pull every crate at once."
Lumi: "One crate at a time. And not onto my foot."
Optional C01-S02: on a high "dead letters" shelf is a parcel tagged 1951. Its emblem matches Reno's railway token. Memory Touch plays a faint echo: footsteps on a platform, and a woman's voice saying "Mind the gap, little one." Reno goes quiet for once.
Reno: "That's my token's picture."
Lumi: "Someone in 1951 had the same one."
Reno: "...Maybe it's a very popular token."
Lumi does not answer.

### C06 — Parcel C, the Smudged Label (BS-04, PZ-105)
Memory Touch tutorial. Lumi touches the label and sees fragments: a colour, a shape on a signboard, part of a word. The player matches the fragments to the signboards along Shophouse Row (fictional shops: a tailor, a bicycle repairer, a photo studio, a goldsmith). The parcel was left at the bicycle repairer's by mistake, so the duo take it back to the station.
Lumi: "Things remember where they were meant to go."
Reno: "Does my satchel remember where my lunch went?"
Lumi: "Your satchel remembers you ate it."
Reno pokes a bicycle wheel and it spins. The repairer looks up.
Repairer *(to himself)*: "Wind's strange today."
Reno: "Is that one tame?"
Lumi: "It's a bicycle. And he can't hear you ask."

### C07 — Parcel B and the Paper Moth Monarch (BS-05, PZ-104, BOSS-101)
Ticket Moths flutter out of the rail yard carrying scraps of paper. Echo Sight shows the ghost path of the last handcar to a siding. The player sets three signal levers to route the handcar there. The moth nest is wrapped around Parcel B and stuffed with chewed tickets.
Paper Moth Monarch: "*Mine.* All the little papers that say *where*... *mine.*"
Reno: "It's eating tickets! That's the worst crime I can think of!"
Lumi: "Why would a moth want destinations?"
After the win, the Monarch drops a punched ticket with no destination printed on it, just a neat hole. Lumi pockets it (`item_blank_punched_ticket`).
Lumi: "Someone is collecting where people are going."
Reno: "Then they'd better not touch *our* tickets."
Guardian Bloom tutorial pop-up after the battle (section 7.3).

### C08 — The Evening Train (BS-02 to BS-06)
The Clockkeeper stamps two tickets with a violet tick mark.
The Clockkeeper: "Carriage three. Keep these on you. And if the train runs late, don't blame me. That one always does."
Platform 2 at dusk. The train pulls in. Reno freezes.
Reno: "Lumi. Lumi. It's *real*."
Lumi: "You're crying."
Reno: "It's steam. In my eyes."
They slip aboard behind a porter. A fog rolls across the platform. The lamps turn from yellow to blue-violet, and the station clock runs backwards for one tick. Autosave before departure; save is then locked until VT-01 loads.

### C09 — Tickets, Please (VT-01 to VT-04)
Passengers sit staring forward, each holding a ticket with a neat hole where the destination should be. Memory Moths drift between seats carrying faint glowing slips. Inside the Veil, the passengers can dimly see the duo.
Passenger (mandatory 1, a schoolteacher going to a new posting): "Are you... a dream? I'm going... I was going... somewhere with a blackboard?"
Reno: "She can see us!"
Lumi: "Only a little. Like when you're half asleep."
Lumi: "They haven't lost their luggage. They've lost where they were going."
Reno: "That's so much worse!"
In the Dining Car (PZ-107) the player matches recovered slips to passengers by clue. On the roof (VT-03), Gentle Float is unlocked.
Lumi: "I think I can float across."
Reno: "And me?"
Lumi: "Hold my scarf."
Reno: "This is the best day of my life."
Lumi: "We're on the roof of a ghost train."
Reno: "Best. Day."
All three mandatory destinations returned: the Guard's Van door unlocks with the sound of a whistle.

### C10 — The Forgotten Conductor (VT-05, BOSS-102)
A tall, thin figure in a faded uniform with a lantern for a face. His cap badge has been rubbed blank. He reaches for their tickets and recoils from the Clockkeeper's violet stamp.
Conductor: "Stamped. Stamped tickets. Then I cannot take your *where*. Tickets, please. Where are you going?"
Reno: "Bandar— no, wait, we're already— somewhere fun!"
Lumi: "Don't tell him!"
Conductor: "Everyone is going somewhere. I am going nowhere. I had a name once. It was on a list. Now there is no list. So I keep everyone's *where*... so I am not alone with my nowhere."
Lumi: "Someone took your name?"
Conductor: "Tickets. Please."
Battle starts. At the story threshold (section 7.5), Lumi uses the blank punched ticket from C07 with Memory Touch and shows the Conductor one thing that is still his: seeing passengers off at a small platform at dawn.
Conductor: "...I used to carry them *home*."
Reno: "You still can! You just took a wrong turn. I do that constantly."

### C11 — The Veil Halt (VT-06)
The train stops at a ghost platform under violet sky. The Conductor opens his lantern and hundreds of small lights drift back into the carriages. The passengers sleep, smiling.
Among the lights, one doesn't go to any passenger. It drifts to Lumi. She hears the lullaby from Reno's dream (P00) and the voice from Whispering Roots (P05): "Remember the way home."
Lumi: "That one's mine."
Reno: "You lost a memory too?"
Lumi: "I don't think I *lost* it. I think I never had it. There's nothing before... before I woke up in Kampung Akar."
Conductor, reading an old ledger: "Your name is here, little echo. But nothing is written before it. As if you began in the middle of a sentence."
Reno: "Then you get to write the rest. That's the fun part."
Lumi, after a beat: "...That's annoyingly wise."
The Conductor gives Reno his whistle (`item_conductors_whistle`) and points down the platform to steps that lead into mist and the sound of water.
Conductor: "The rails forget. The river remembers. If someone is taking names, the river spirits will know who. I will keep this halt until mine is written again."
Hard cut to dawn at BS-06. The train is an ordinary train again. Passengers wake up yawning.
Schoolteacher *(to the woman beside her)*: "I had the strangest dream. Two children on the roof of the train."
Pak Darus checks his watch.
Pak Darus *(to himself)*: "Late again. But everyone's here. Strange."
Above the platform, the Clockkeeper ticks once, pleased.
Reno: "Lumi, can we ride another one?"
Lumi: "Can we have breakfast first?"
Reno: "...After breakfast."
Chapter title card, "Chapter 1 Complete". Set `river_route_unlocked`, `chapter_01_completed`, `chapter_02_unlocked`. Safe autosave.

## 6. Puzzles
All mandatory puzzles have hints, safe recovery, no timers and persistent solved flags (05 rule).

| ID | Map | Mandatory | Description | Reset / recovery | Flag |
|---|---|---|---|---|---|
| PZ-101 | SM-04 | Yes | Coin Jar: sort 1, 5, 10, 20 and 50 cent coins into piles that each total 50 cents, before the shop opens (story framing only, no real timer). Lumi hints after two wrong piles. | Re-pour jar button; no penalty | `pz101_coin_jar_solved` |
| PZ-102 | SM-05 | Yes | Bus boarding: choose which queuing passenger to follow through the door. Only the one with the big load keeps it open long enough. | Bus waits; wrong choice just replays the queue with a hint | `pz102_bus_boarded` |
| PZ-103 | BS-03 | Yes | Crate aisle: Root Grip pulls crates one tile toward Reno. Clear a path to the parcel shelf. | Reset lever by the door | `pz103_crates_solved` |
| PZ-104 | BS-05 | Yes | Three signal levers route a handcar to the moth siding. Echo Sight shows the ghost handcar's last route as a hint. | Levers can be re-thrown; handcar returns if wrong | `pz104_signals_solved` |
| PZ-105 | BS-04 | Yes | Smudged label: Memory Touch shows three fragments (colour, shape, partial word). Match to one of four signboards. Wrong shop gives a funny line and no penalty. | Fragments stay in the Journal | `pz105_label_solved` |
| PZ-106 | VT-03 | Yes | Roof gaps: two Leaf Leap gaps, then one Gentle Float gap. Wind pushes back to the last safe tile on a miss. No falling off the train. | Safe tile on miss | `pz106_roof_crossed` |
| PZ-107 | VT-02 | Yes | Destination matching: three glowing slips, each with a clue (a smell, a sound, an object), matched to the passenger whose belongings fit. | Slips return to inventory if wrong | `pz107_destinations_matched` |
| PZ-108 | VT-04 | No | Lantern keyhole: the prologue lantern reveals a Veil keyhole on a trunk, which opens to Lost Luggage. | Re-inspect | `pz108_lantern_keyhole_found` |

The three parcel returns use the Place interaction (section 4) and are not separate puzzles.

## 7. Battles

### 7.1 Formula reminder (from 04, unchanged)
Physical base = max(1, 2\*ATK − DEF). Magical base = max(1, 2\*MAG − RES). Then skill multiplier, then element, then timing (Perfect 1.5x, Good 1.2x, none 1.0x), then guard/shield, then one final integer rounding; floor 1. No random variance in Chapter 1, same as the prologue.

### 7.2 Hero level growth (adopted as the starting point)
04 gives Lv1 stats and the XP curve 10\*(L−1)^2 but no growth. This flat per-level gain is adopted as the starting point and will be replaced if real growth profiles are designed.

| Hero | +HP | +MP | +ATK | +DEF | +MAG | +RES | +SPD |
|---|---|---|---|---|---|---|---|
| Reno | 6 | 2 | 2 | 1 | 1 | 1 | 1 |
| Lumi | 4 | 3 | 1 | 1 | 2 | 1 | 1 |

| Level (XP) | Reno HP/MP/ATK/DEF/MAG/RES/SPD | Lumi HP/MP/ATK/DEF/MAG/RES/SPD |
|---|---|---|
| Lv3 (40) | 54/18/18/11/8/10/14 | 40/30/9/9/20/14/12 |
| Lv4 (90) | 60/20/20/12/9/11/15 | 44/33/10/10/22/15/13 |
| Lv5 (160) | 66/22/22/13/10/12/16 | 48/36/11/11/24/16/14 |
| Lv6 (250) | 72/24/24/14/11/13/17 | 52/39/12/12/26/17/15 |

### 7.3 New combat content
- **Status introduced: Memory Fog** (04 definition: command seal, 1 turn). Seals the Skill command of one hero for their next action. Attack, Guard and Item stay usable, so the fight can never softlock.
- **Status introduced: Slow** (SPD −30% for 3 turns, 04 definition), from Signal Flicker only.
- **Dual tech: Guardian Bloom** (04 lists it as a "later defensive dual-tech proposal"). Reno + Lumi, 5 MP each, consumes both action tokens, applies Shielded (−30% damage, 2 turns) to both heroes and heals each for 15% of their own max HP. Two timing cues; mistiming reduces the heal to 10% but Shielded always applies. Learned after BOSS-101.
- Spirit Cyclone stays as specified in 04. Its multiplier is not specified there; this doc assumes **2.0x physical on one target** for sanity checks (`PLACEHOLDER`).

### 7.4 Regular enemies (visible encounters only)
All are original creatures invented for this game.

| ID | Name | Where | Lv | HP | ATK | DEF | MAG | RES | SPD | XP | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| EN-101 | Ticket Moth | BS-05 | 3 | 40 | 8 | 6 | 10 | 8 | 13 | 8 | Paper Nibble: magical 1.0x, dodge cue |
| EN-102 | Dust Bundle | BS-03 | 3 | 56 | 12 | 10 | 3 | 6 | 5 | 9 | Roll Over: physical 1.2x, telegraphed one turn, guard or dodge |
| EN-103 | Signal Flicker | BS-05 | 4 | 44 | 6 | 7 | 13 | 12 | 14 | 11 | Red Light: Slow on one hero. Green Light: an ally acts first next round |
| EN-104 | Fog Porter | VT-01, VT-04 | 5 | 72 | 15 | 12 | 6 | 9 | 8 | 16 | Heavy Trunk: physical 1.3x |
| EN-105 | Memory Moth | VT-01 to VT-03 | 5 | 50 | 7 | 8 | 15 | 13 | 15 | 14 | Forget-Me Dust: magical 0.6x + Memory Fog. Releases a light when defeated (flavour) |
| EN-106 | Lost Luggage | VT-04 (optional) | 6 | 90 | 14 | 16 | 4 | 8 | 4 | 30 | Snap Shut: physical 1.4x, telegraphed. Can't escape. Guaranteed drop: Brass Lantern Hook |

Sanity check, Reno Lv4 Attack on Fog Porter: 2\*20 − 12 = 28 (Good 33, Perfect 42), so 2–3 hits for 72 HP. Fog Porter Heavy Trunk on Lumi Lv4: (2\*15 − 10) \* 1.3 = 26 against 44 HP, so two unguarded hits put her in danger. That is intended as the chapter's first real pressure.

XP budget (main path, both heroes get full XP): about 5 Bandar Senja fights (~45) + Monarch (40) + about 4 train fights (~60) = ~145, plus ~35 from the prologue = ~180, which is Lv5 before the boss. The boss's 80 XP takes the party to Lv6 (260).

Human areas (SM-*) have no encounters. Veil creatures only appear where the Veil is thin: the goods shed, the rail yard and the train.

### 7.5 Bosses
Both bosses follow the Thornkeeper pattern: fixed rewards, defeat returns to a pre-boss snapshot, phases by HP threshold, no Escape.

**BOSS-101 Paper Moth Monarch** (mid-boss, BS-05)
Lv4 HP200 ATK9 DEF8 MAG14 RES11 SPD12; XP40. Fixed reward: Parcel B, Blank Punched Ticket, Moth-Wing Charm, Guardian Bloom unlocked.
- Phase >50%: Paper Storm (magical 0.7x, both heroes, one dodge cue each) and Nibble (magical 1.0x, single).
- Phase ≤50%: Summons one Ticket Moth (EN-101) whenever none are present (max one at a time). Moths summoned this way give 0 XP to prevent farming.
- Immune: Slow.
- Check at party Lv3: Reno Attack 2\*18 − 8 = 28; Lumi Echo Spark at 1.0x, 2\*20 − 11 = 29. About 57 per round with no timing bonus, so ~4 rounds. Paper Storm on Lumi Lv3: (2\*14 − 14) \* 0.7 = 9.8, rounded to 10, out of 40 HP.

**BOSS-102 The Forgotten Conductor** (chapter boss, VT-05)
Lv6 HP420 ATK17 DEF14 MAG19 RES16 SPD11; XP80. Fixed reward: Conductor's Whistle (key item), 80 XP. Immune: Slow, Memory Fog. Non-lethal: the battle ends in a cutscene, not a kill.

| Phase | HP | Moves |
|---|---|---|
| 1 "Tickets, Please" | >60% | Ticket Punch: physical 1.2x single, dodge cue. Where Are You Going?: Memory Fog on one hero, no damage, telegraphed by the Conductor raising his punch. |
| 2 "Tunnel" | ≤60% | The carriage goes dark for one round: next attack can't be guarded but has a longer dodge window (accessibility-safe). Adds Last Call: magical 0.8x on both heroes. |
| 3 "Final Stop" | ≤30% | Final Stop: announced one full round ahead ("Next stop... *nowhere*"). Magical 1.6x on both heroes. Guard halves it; Guardian Bloom's Shielded and Guard stack per 04's order. |
| Story threshold | ≤15% | Battle ends. Lumi's "Show Him His Ticket" scene (C10). The party does not need to land a final blow. |

Sanity checks at party Lv5:
- Reno Attack: 2\*22 − 14 = 30 (Good 36, Perfect 45). Lumi Echo Spark at 1.0x: 2\*24 − 16 = 32. About 62 per round, ~75 with Good timing. Reaching the 15% threshold takes 357 damage, so 5–6 rounds, or 4–5 with a Spirit Cyclone.
- Ticket Punch on Lumi: (2\*17 − 11) \* 1.2 = 27.6, rounded to 28, of 48 HP.
- Last Call on Reno: (2\*19 − 12) \* 0.8 = 20.8, rounded to 21, of 66 HP. On Lumi: (2\*19 − 16) \* 0.8 = 17.6, rounded to 18.
- Final Stop on Lumi unguarded: (2\*19 − 16) \* 1.6 = 35.2, rounded to 35, of 48 HP. With Guard: 18. With Guard and Shielded: 22 \* 1.6 \* 0.5 \* 0.7 = 12.3, rounded to 12.
- So the boss can knock Lumi out if the player ignores the telegraph and doesn't heal, but a guard-aware player at Lv5 with two healing items survives. To test in playtests, not proven.

## 8. Items, equipment and shops
Because humans can't see the duo, Chapter 1 shopping happens at **spirit stalls priced in Dewdrops** (DP). Starting DP after the prologue is 8 (5 starting + 3 from the Thornkeeper). Chapter 1 gives 3 (C01-001) + 2 optional (C01-S01). Prices are provisional.

| ID | Name | Type | Effect | Price | Source |
|---|---|---|---|---|---|
| item_kaya_toast | Kaya Toast | Consumable | Heal 20 HP | Not sold in Ch 1 | Old Kettle gift (C01-001) |
| item_moonleaf_bun | Moonleaf Bun | Consumable | Heal 20 HP | 1 DP | Spirit stalls; C01-003 reward |
| item_starfruit_dumpling | Starfruit Dumpling | Consumable | Heal 35 HP | 2 DP | Clockkeeper's stall only |
| item_firefly_tea | Firefly Tea | Consumable | +12 MP | 2 DP | Spirit stalls; C01-S04 reward |
| item_dewdrop_candy | Dewdrop Candy | Consumable | From prologue; effect not yet defined in 05 (proposed: heal 10 HP and 4 MP) | 1 DP | Both stalls |
| item_veil_ticket | Veil-Stamped Ticket ×2 | Key | Boarding; protects the holder's destination from the Conductor | Not sold | C01-003 |
| item_parcel_a / item_parcel_b / item_parcel_c | Stationmaster's Parcel A/B/C | Key | Quest | Not sold | C01-003 |
| item_postcard | Postcard Home | Key | Side quest | Not sold | C01-S01 |
| item_blank_punched_ticket | Blank Punched Ticket | Key | Story item used in C10 | Not sold | BOSS-101 |
| item_conductors_whistle | Conductor's Whistle | Key | Chapter 2 hook (proposed: calls a Veil boat at the river crossing) | Not sold | BOSS-102 |
| equip_moth_wing_charm | Moth-Wing Charm | Charm | SPD +2 | Not sold | BOSS-101 |
| equip_brass_lantern_hook | Brass Lantern Hook | Tool | MAG +3 | Not sold | C01-S03 |

Shops: Old Kettle's shelf stall in SM-03 (Moonleaf Bun, Firefly Tea, Dewdrop Candy) and the Clockkeeper's stall in BS-02 (all four buyable consumables). The 04 human-priced items (Kaya Toast 15 cents and so on) stay in the data for later chapters. Nothing in the main path requires buying.

## 9. Required flags
`ch01_started`, `ch01_visibility_learned`, `ch01_coin_jar_solved`, `ch01_kettle_tip_heard`, `ch01_bus_boarded`, `ch01_arrived_bandar_senja`, `ch01_parcels_quest_started`, `ch01_parcel_a_found`, `ch01_parcel_b_found`, `ch01_parcel_c_found`, `ch01_parcel_a_returned`, `ch01_parcel_b_returned`, `ch01_parcel_c_returned`, `ch01_parcels_returned`, `ch01_moth_monarch_defeated`, `ch01_guardian_bloom_learned`, `ch01_tickets_obtained`, `ch01_veil_train_entered`, `ch01_gentle_float_unlocked`, `ch01_passenger_1_restored`, `ch01_passenger_2_restored`, `ch01_passenger_3_restored`, `ch01_guards_van_unlocked`, `ch01_conductor_calmed`, `ch01_lumi_origin_glimpsed`, `river_route_unlocked`, `chapter_01_completed`, `chapter_02_unlocked`.

Optional: `ch01_postcard_posted`, `ch01_dead_letter_tag_read`, `ch01_lost_luggage_defeated`, `ch01_extra_passenger_1_restored`, `ch01_extra_passenger_2_restored`, plus each puzzle's `pz1xx_*` flag from section 6.

Autosave points: arrival at BS-01, before boarding at BS-06, after C11. No autosave inside VT-01 to VT-05 between scenes C08 and C11 except at the Guard's Van door (pre-boss snapshot).

## 10. Secondary content
- Memory Album: "A Postcard Home" (C01-S01), "A Railway Badge" (C01-S02), "The Evening Train" (C08), "The Veil Halt" (C11).
- Folklore Journal: one entry per enemy, plus Old Kettle, the Clockkeeper, Mr Slot and the Forgotten Conductor. All written as in-world notes by Lumi, clearly about invented Two Worlds spirits.
- Ambient humans: kopitiam regulars, bus passengers, porters, shopkeepers and train passengers. Each is written around a job or a personal goal (going to a new teaching post, visiting a grandchild, taking fabric to a tailor), never around ethnicity or accent. Since they can't hear the duo, every line is overheard conversation or self-talk.
- Ambient spirits: small object spirits in human places (Old Kettle, the Clockkeeper, Mr Slot) give the duo someone to talk to in the Human World. This is a reusable pattern for later chapters.

## 11. Sensitivity and research checklist
- **Communities.** 1963 Sungai Melor and Bandar Senja are mixed communities. No humour from accents, broken English, food stereotypes or ethnic "types". Humour comes from Reno misunderstanding human objects and from humans explaining away spirit help, never from the humans themselves.
- **Religion.** No depiction of real religious practice, prayer, places of worship or religious objects as plot devices. Object spirits are a Two Worlds invention, not a claim about real belief (01, 02).
- **Folklore.** No enemy, boss or helper spirit is presented as a real Malaysian folklore being. Folklore Journal text is in-world fiction.
- **Language.** English dialogue with light Malay honorifics and common words (Pak, Mak Cik, Encik, kopitiam). To review with a native speaker before lock.
- **Research to do before art lock:** 1963 country bus body style and luggage racks; whether the regional train would be steam or diesel in 1963 (the Veil train may stay steam as a supernatural echo either way); station and goods-shed architecture; period signage style (fictional names only); coin denominations in circulation in 1963 for the Coin Jar (believed to be 1, 5, 10, 20 and 50 cents; verify).
- **Real places.** Bandar Senja, Sungai Melor and the train's destination are fictional. The train's printed destination stays blank or uses a fictional name (`PLACEHOLDER`: "Tanjung Lampu").

## 12. Decisions
Dennis answered on 27 November 2026: "Humans cannot see, follow your recommendations, this is a guide and we can freely change accordingly." After revision 2 he replied "Follow recommendation and proceed", approving the design.

| # | Question | Decision | Source |
|---|---|---|---|
| 1 | Can humans see Reno and Lumi? | **No.** Rule in section 1. Bus fare, ticket buying and stationmaster dialogue were rewritten around it. | CONFIRMED_USER |
| 1a | Can dreaming humans inside the Veil see them dimly? | Yes, as written in section 1. | CONFIRMED_USER |
| 2 | How much of Lumi's origin to reveal | As written: nothing exists before Kampung Akar, plus the lullaby and "Remember the way home" callbacks. Seri is not named. | Approved |
| 3 | Reno's token on the 1951 parcel tag | Keep it optional (C01-S02). | Approved |
| 4 | The Conductor's fate | Calmed; stays at the Veil Halt as a recurring friendly NPC with his name still missing. | Approved |
| 5 | Guardian Bloom in Chapter 1 | Yes, learned after BOSS-101. | Approved |
| 6 | Gentle Float unlock | Chapter 1, on the train roof. | Approved |
| 7 | Placeholder names | Kept as working names: Pak Darus, Encik Lim, Tanjung Lampu. New in revision 2: Old Kettle, the Clockkeeper, Mr Slot. The kopitiam owner is now unnamed. | Approved |
| 8 | Length | 60–80 minutes main path. | Approved |
| 9 | Hero growth table | Adopted as the starting point (7.2). | Approved |
| 10 | Engine and data format | The doc stays engine-neutral; JSON follows the handover's `data/` naming so the Godot build can import it. | Approved |

## 13. Content that still needs authoring
Painted maps and collision, interaction coordinates, spawn geometry, the stationmaster's facing loop timings for Place, full NPC ambient lines and expressions, passenger scripts beyond the three mandatory ones, battle animation timing, sound cue timeline (bus engine, train whistle, Veil transition, clock tick), cutscene skip transactions, sprite and portrait atlas paths for all new NPCs, spirits and enemies. None of this exists yet.
