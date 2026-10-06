# Dino Hunters — Tower Upgrade Design

The agreed vision for every tower's three paths (user-approved 2026-09-28). Every path is a
**specialisation** — attack speed, anti-armour, support, crowd control, economy — not a
generic "+damage / +range" track, and every tier has its **own name**, BTD6-style. Names are
original (the design doc: "your own upgrade names").

Tiers in *italics* grant a new **ability**; the rest are named stat steps. Numbers live in
the spreadsheet (`Tower Upgrades`: Name column, plus one column per mechanic as each is
built). Change a name there, not in code.

**Status key:** ✅ built · 🔜 next · ⏳ later phase

---

## Hunting Blind (Scout) — cheap single-target

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Lookout** | range → support | Keen Eyes | Long Barrel | *Flare Gun* | Watch Post | *Signal Tower* |
| **Trigger Happy** | attack speed | Quick Hands | Extended Mag | *Double Tap* | Bullet Hose | *Lead Rain* |
| **Hardliner** | anti-armour | Heavy Slugs | *Armor Breaker* | Hollow Points | *Railshot* | *Hide Buster* |

- Flare Gun: towers in its range +10% attack speed. Signal Tower: towers in range +20% damage and can hit armour.
- Double Tap: two shots per trigger pull. Lead Rain: fastest fire in the game.
- Armor Breaker: can damage armoured dinos (Ankylosaurus). Hollow Points: ×2 vs armoured. Railshot: bullet passes through 3 dinos. Hide Buster: ×4 vs armoured and bosses.

## Longshot Perch (Sniper) — global range, slow

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Deadeye** | line pierce | *Full Metal Jacket* | *Through-and-Through* | Ricochet | Tungsten Core | *Linebreaker* |
| **Spotter** | speed + mark | Steady Breath | Bolt Racking | *Marked Target* | Game Spotter | *Eye in the Sky* |
| **Big Bore** | boss killer | Large Calibre | *Bone Breaker* | *Concussion Round* | Punt Gun | *Extinction Round* |

- Full Metal Jacket: hits 2 in a line. Through-and-Through: hits 3, pierces armour. Linebreaker: hits 10, ×2 damage.
- Marked Target: its target takes +25% from every tower. Eye in the Sky: mark +60%, towers in range +15% attack speed.
- Bone Breaker: ×3 vs bosses. Concussion Round: stun on hit. Extinction Round: ×10 vs bosses, stuns bosses.

## Mortar Pit (Grenadier) — area damage, ground only

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Blast** | radius + burn | Bigger Bang | Shrapnel | *Napalm* | Firestorm | *Scorched Earth* |
| **Cluster** | bomblets | *Cluster Shell* | Rapid Loader | *Chain Reaction* | Carpet Shelling | *Meteor Shower* |
| **Concussive** | control / anti-armour | *Shockwave* | *Armor Crack* | *Stun Grenade* | Earthshaker | *Tectonic Slam* |

- Napalm: leaves a burning patch on the track. Scorched Earth: long burning stretch.
- Cluster Shell: each shell splits into 3 blasts. Chain Reaction: the bomblets split again.
- Shockwave: knocks dinos back along the track. Armor Crack: damages armour, ×2 vs armoured. Stun Grenade: brief stun. Tectonic Slam: everything hit is stunned 1s.

## Tranq Station (Chiller) — tranquilizer darts: slow and knockout ✅ phase 5 · unlock 100 Amber

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Sedate** | slow radius | Mild Dose | Heavy Dose | *Lingering Dose* | Sedative Cloud | *Deep Sleep* |
| **Knockout** | hard stops | *Knockout Dart* | Heavy Sedative | *Barbed Darts* | Quick Cycle | *Big Game Tranq* |
| **Weak Spot** | damage amp | *Exposed Hide* | *Find the Gap* | *Hunter's Call* | Vital Points | *Apex Predator* |

- Mild Dose → Sedative Cloud: a stronger slow each tier. Lingering Dose: the slow lingers after a dino leaves the zone. Deep Sleep: slows bosses too.
- Knockout Dart: knocks out every dino in range every few seconds. Barbed Darts: knockouts also deal damage. Big Game Tranq: a long knockout that holds bosses.
- Exposed Hide: sedated dinos take +25% damage. Find the Gap: +35%, and sedated dinos lose their armour. Hunter's Call: towers in range +10% attack speed. Apex Predator: +75%, towers in range +20% damage.

## Supply Camp (Quartermaster) — economy, no attack ✅ phase 5 · unlock 150 Amber

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Yield** | income | Supply Crate | Bigger Budget | Trade Route | War Chest | *Amber Vault* |
| **Airdrop** | loot chests | *Air Drop* | Double Drop | *Chopper Drop* | Supply Chain | *Treasure Haul* |
| **Logistics** | discounts | *Bulk Order* | Field Engineer | *Recycler* | *Forward Camp* | *Base Camp* |

- Amber Vault: interest on banked cash. Air Drop: chests land that players run over to collect.
- Supply Camp upgrades cost less than other towers' (each tier ×1.6, not ×2.3: 1,600 / 2,560 / 4,096 / 6,554 / 10,486) so every tier repays itself in about 8–10 rounds, like the base camp (round 2, #56/#73).
- Yield: round income ×2.1 / ×3.85 / ×6.6 / ×11.1 / ×17.9 of the base 150; Amber Vault adds 5% interest (up to 500 a round).
- Airdrop: 1 / 2 / 2 / 3 / 4 chests a round worth 200 / 260 / 515 / 615 / 790 cash each.
- Bulk Order: towers in range −5% upgrade cost. Recycler: towers in range sell for 90%. Forward Camp: towers in range +10% attack speed. Base Camp: −20% costs, full refunds.

## Field Hospital (HOSPITAL) — heals towers and hunters, no attack ✅ Step 2 · unlock 100 Amber

Never shoots. Heals standing towers and hunters in its range (itself included) 3 HP/s.
Hospitals don't stack: the strongest one covering a tower or hunter heals it.

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Ward** | heal speed | Clean Linens | Extra Cots | *Stitch-Up* | Night Shift | *Miracle Ward* |
| **Rescue** | hunters | Stretcher Team | Signal Whistle | *Med Kits* | Pack Mules | *Rescue Beacon* |
| **Tonic** | tougher towers | Camp Rations | Iron Tonic | *Smelling Salts* | Bone Broth | *Last Stand* |

- Clean Linens heal ×1.5 · Extra Cots ×2. Stitch-Up: ×2.5, and trampled towers in range climb back at half the heal rate; they stand up again at full HP. Night Shift: ×3. Miracle Ward: ×4.5, revives at full speed.
- Stretcher Team: range ×1.2. Signal Whistle: ×1.4. Med Kits: 2 white kits with a green "+" land nearby each round (like the Supply Camp's chests); the first hurt hunter to run over one heals 30 (a hunter at full HP leaves it for a teammate). Pack Mules: 3 kits, 40. Rescue Beacon: range ×1.8, kits heal 50, and downed hunters come back beside the hospital in half the respawn time.
- Camp Rations: towers in range +10% max HP · Iron Tonic +20%. Smelling Salts: towers in range also +10% attack speed. Bone Broth: +35% HP. Last Stand: +50% HP, and once per round a tower in range that would be trampled stays at 1 HP.

## Armory (ARMORY) — damage resistance, no attack ✅ Step 2 · unlock 150 Amber

Never shoots. Towers and hunters in its range (itself included) take 15% less damage.
Resistance doesn't stack: the strongest source wins, capped at 60% (Tuning).

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Plating** | resistance | Hide Padding | Iron Plates | *Thorn Plating* | Tempered Steel | *Bulwark* |
| **Gunsmith** | support | Oiled Actions | Hand Loads | *Piercing Rounds* | Match Grade | *Master Gunsmith* |
| **Outfitter** | hunters | Wide Rack | Recoil Pads | *Ammo Crate* | Steady Rests | *Full Kit* |

- Hide Padding 20% · Iron Plates 25%. Thorn Plating: dinos that bite anything in range take 3 damage back (pierces armour, grows with tower levels, the kill counts for the Armory's builder). Tempered Steel: 35%, thorns 5. Bulwark: 45%, and biters are stunned 0.5s (not bosses).
- Oiled Actions: towers in range +5% attack speed. Hand Loads: +10% damage. Piercing Rounds: towers in range pierce armour. Match Grade: +20% damage, +10% speed. Master Gunsmith: +30% damage, +15% speed.
- Wide Rack: range ×1.3. Recoil Pads: hunters in range have 25% less recoil. Ammo Crate: reload ×0.65. Steady Rests: spread ×0.7. Full Kit: range ×1.5, hunters in range fire 20% faster.

---

# The round-4 batch (TOWERS_NEXT.md, Jovan's picks 2026-10-02; DECISIONS #146–#152, #159)

Unlocks at 2× Amber, normal in-match prices (#147). Falcon Roost and Tar Pit **can't be
damaged**: no HP, dinos never target them, no repairs, Armory/Hospital don't affect them,
and they're "somewhat weaker" (≤ 0.8× the median eDPS per cash, #148). Not sold until PLAN
T68. Tier 4s are the Director's picks (#149), tier 5s Jovan's.

## Storm Coil (COIL) — chain lightning: crowds and air ✅ round 4 (PLAN T64; sold from T68) · unlock 300 Amber

A copper coil on a tripod. Each strike hits the first dino in range and **arcs** to the
nearest other dino within arc reach (10 studs), 4 arcs, each 80% of the last. Arcs stay in
the coil's own range (Jump Spark lifts that). Hits air; can't hurt armour until High
Voltage; breaks 1 size per hit. Short own range (14). Rules: `Shared/StormCoil`.

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Arc** | more arcs, reach | Copper Wire | Long Arc | *Fork Lightning* | *Jump Spark* | *Power Grid* |
| **Charge** | power, armour, stun | Battery Pack | Static Shock | *Thunderclap* | *High Voltage* | *Judgement Bolt* |
| **Lightning Rod** | support, defence | Tall Mast | Charged Air | *Grounding Spike* | *Storm Warning* | *Lightning Rodeo* |

- Copper Wire: +2 arcs. Long Arc: arc reach 15. Fork Lightning: each arc may fork in two (each hop reaches the two nearest new dinos, so the chain runs two wide). Jump Spark: arcs jump between Storm Coils' ranges. Power Grid: every 6s one grid strike through every dino in every Storm Coil's range; n = standing Storm Coils (up to 6): range × (1 + 0.15(n−1)), damage × (0.5 + 0.25n) — one coil ×0.75, two ×1, six ×2 (#151).
- Battery Pack: +30% damage. Static Shock: a struck dino takes +10% from the next strike. Thunderclap: the first target is stunned 0.4s (not bosses). High Voltage: pierces armour, +40% damage. Judgement Bolt: every 10s one bolt on the biggest dino in range, ×8, breaks 3 sizes, stuns bosses 0.5s.
- Tall Mast: range ×1.2. Charged Air: towers in range +10% attack speed. Grounding Spike: every 4s strikes down one dino throw aimed at a tower in range. Storm Warning: towers in range +15% damage. Lightning Rodeo: towers in range chain their own shots once (one more dino at 50%).

## Falcon Roost (FALCON) — birds of prey, can't be damaged ✅ round 4 (PLAN T65; sold from T68) · unlock 200 Amber

A tall perch with a falconer's hut. Two falcons fly to the first dino within 40 studs (one
no other bird is already after), dive, strike and come back: the hit lands after the
flight (Falcon speed 40 studs/s), and a bird can't go again until it's home. Hits air and
ground. No armour until Iron Talons. Rules: `Shared/Falcon`.

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Talons** | raw damage, pierce-through | Sharp Talons | Hooked Beak | *Power Dive* | *Iron Talons* | *Eagle of the Peak* |
| **Flock** | more birds | Second Pair | Quick Return | *Flock of Six* | *Wide Circle* | *Murmuration* |
| **Falconer** | support | Long Leash | Falcon Bells | *Hooded Scout* | *Lure* | *Hunting Party* |

- Power Dive: the first dive on a dino ×3, breaks 2. Iron Talons: pierces armour, breaks 3. Eagle of the Peak: one giant eagle replaces the flock, ×6 dives, stuns 0.5s (not bosses), breaks 3.
- Second Pair: 4 birds. Flock of Six: 6 birds. Wide Circle: radius 60. Murmuration (pending Jovan: or Sky Swarm): 12 small birds peck every dino in range (no more dives or flights; breaks 1).
- Long Leash: +10% range. Falcon Bells: a struck dino takes +10% for 2s. Hooded Scout: bosses in range marked +25%. Lure: struck dinos pulled 2 studs back (not bosses). Hunting Party: towers in range +15% attack speed while a bird dives.

## Tar Pit (TARPIT) — on the track: slows and sinks, can't be damaged ✅ round 4 (PLAN T67; sold from T68) · unlock 250 Amber

Placed **on the track** (dinos walk through it, #152). Its pool is 12 studs of track centred
where it stands; a new pit's pool may not overlap another pit's pool at its current length
(touching is fine, #189). Ground dinos in the tar are slowed 25% (bosses too); a dino at its
last size that stays in it 3s **sinks** — a take-down that pays like a kill and counts as a
pop for the pit's owner (never bosses, never Pteranodons). No air. A dino in two pools (a
Tar Lake can make them touch) gets only the strongest pool — the one with the most cash in
it — so slow, damage, sinking and Eruption never stack (#189). Rules: `Shared/TarPit`.

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Deep Tar** | slow and sink | Thick Tar | Wide Pool | *Fast Sink* | *Clinging Tar* | *Tar Lake* |
| **Bubbling** | damage | Warm Tar | Simmer | *Boiling Pit* | *Tar Fire* | *Eruption* |
| **Dig Site** | cash and support | Pick and Shovel | Fossil Hunter | *Lucky Finds* | *Tar Tracks* | *Tar Totem* |

- Thick Tar: slow 35%. Wide Pool: 18 studs of track. Fast Sink: last-size dinos sink in 1.5s. Clinging Tar: dinos walking out stay slowed 3s. Tar Lake: the pool covers three times as much track (54 studs).
- Warm Tar / Simmer: the tar deals damage per second to every dino in it (8, 22). Boiling Pit: burning tar (80/s); its ticks break 1 (#127). Tar Fire: dinos walk out burning — one tick of 2s of the tar's damage, kept as they shrink. Eruption: every 10s a geyser drops every dino in the pool 2 sizes outright, bosses included, Break resist ignored; each size pays (#150).
- Pick and Shovel / Fossil Hunter: +10 / +25 cash per sunk dino. Lucky Finds: each sink also leaves a chest worth 40 where the dino went under (collected like an airdrop). Tar Tracks: after a dino walks out, the next 12 studs of track slow 15% for 3s. Tar Totem: towers in range +15% damage against slowed dinos (tar or tranq).

## Harpoon Ballista (BALLISTA) — the heaviest single hit, pierce-through ✅ round 4 (PLAN T66; sold from T68) · unlock 300 Amber

A heavy crossbow on a turntable: slow (one bolt every 2.5s), very heavy bolts (12, the
heaviest single hit). Ground and air. A volley's bolts spread over the dinos in range,
furthest along first. Rules: `Shared/Ballista`.

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Spearhead** | raw damage, breaks | Steel Head | Saw Tip | *Crusher Bolt* | *Great Harpoon* | *Skewer* |
| **Reel** | control | Rope Line | Winch | *Pin Down* | *Reel In* | *Tow Line* |
| **Volley** | more bolts | Twin Bolts | Fast Crank | *Spread Volley* | *Steam Crank* | *Chain Harpoons* |

- Crusher Bolt: breaks 2. Great Harpoon: pierces armour, breaks 3. Skewer: the bolt flies on through every dino in its line out to the tower's range (within Bolt width 3 studs), each breaks 3.
- Pin Down: the hit dino is held 1s (not bosses). Reel In: drags the hit dino 6 studs back (not bosses). Tow Line: every 15s pulls the boss furthest along in range 10 studs back (the only knockback that moves a boss; waits while no boss is in range).
- Twin Bolts: 2 bolts. Spread Volley: 3 bolts. Steam Crank: fires twice as fast. Chain Harpoons: 4 bolts in 2 linked pairs; each pair lands on the k-th dino from the front and from the back of the crowd in range, and its chain hits every other dino within Bolt width of the line between them (breaks 1).

---

## Mechanics and when they're built

| Mechanic | Used by | Status |
|---|---|---|
| Upgrade names in the tower panel | all | ✅ phase 3 |
| Range multiplier | Lookout, Sedate | ✅ phase 3 |
| **Armored** and **Boss** dino flags; armour blocks damage without pierce | dinos | ✅ phase 3b |
| Armour pierce, bonus vs armoured, bonus vs bosses | Hardliner, Deadeye, Big Bore, Concussive, Signal Tower | ✅ phase 3b |
| Multi-shot per trigger | Double Tap, Lead Rain | ✅ phase 3b |
| Line pierce (hits N in a line) | Railshot, Deadeye | ✅ phase 3b |
| Mark (target takes +X% from all towers) | Marked Target, Eye in the Sky | ✅ phase 3b |
| Stun, knockback | Concussion Round, Extinction Round, Shockwave, Stun Grenade, Tectonic Slam | ✅ phase 3b |
| Burn patch on the track | Napalm, Scorched Earth | ✅ phase 3b |
| Cluster bomblets | Cluster Shell, Chain Reaction | ✅ phase 3b |
| Support auras (buff nearby towers) | Flare Gun, Signal Tower, Eye in the Sky | ✅ phase 3b |
| Slow, knockout pulses, damage-taken amp, armour strip | Tranq Station | ✅ phase 5 |
| Round income, interest, airdrop chests, upgrade discounts, better refunds | Supply Camp | ✅ phase 5 |
| Damage resistance aura, thorns, biter stun, hunter handling buffs | Armory | ✅ Step 2 |
| Healing aura, tower revive, med kits, rescue respawn, max-HP aura, Last Stand | Field Hospital | ✅ Step 2 |
| Can't be damaged (no HP, never a target, no repair, no Armory/Hospital aura) | Falcon Roost, Tar Pit | ✅ round 4 (PLAN T63) |
| On-track placement (pits never overlap) | Tar Pit | ✅ round 4 (PLAN T63) |
| Chain lightning, Power Grid, Judgement Bolt, Grounding Spike, Lightning Rodeo | Storm Coil | ✅ round 4 (PLAN T64) |
| Birds with travel time, Power Dive, Eagle of the Peak, Murmuration, Hooded Scout, Lure, Hunting Party | Falcon Roost | ✅ round 4 (PLAN T65) |
| Spread volleys, Skewer, Pin Down, Reel In, Tow Line (boss pull), Chain Harpoons | Harpoon Ballista | ✅ round 4 (PLAN T66) |
| Tar pool on the track (strongest pool only), sinking, Clinging Tar, tar damage, Tar Fire, Eruption (size drop), Dig Site cash and chests, Tar Tracks, Tar Totem | Tar Pit | ✅ round 4 (PLAN T67) |

When a mechanic lands, its numbers get a column on `Tower Upgrades` and the stat-only
multipliers get rebalanced around it — expect a tuning pass per mechanic.

**Phase 3b rules (2026-09-28):** no tower damages an armoured dino (Ankylosaurus) until it
has an armour-piercing upgrade (Armor Breaker, Through-and-Through, Armor Crack), stands in a
Signal Tower's aura, or the dino is sedated by a Find the Gap Tranq Station; towers ignore
dinos they can't hurt. Bosses ignore stun unless the
hit says "stuns bosses", and are never knocked back. Auras don't stack — the strongest wins.
Ability numbers are seeds on `Tower Upgrades` (columns N–AD) and `Tuning` (ABILITIES).
