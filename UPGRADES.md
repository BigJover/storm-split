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
| **Lookout** | range → support | Keen Eyes | Spyglass | *Flare Gun* | Watch Post | *Signal Tower* |
| **Trigger Happy** | attack speed | Quick Hands | Extended Mag | *Double Tap* | Bullet Hose | *Lead Rain* |
| **Hardliner** | anti-armour | Heavy Slugs | *Armor Breaker* | Hollow Points | *Railshot* | *Hide Buster* |

- Flare Gun: towers in its range +10% attack speed. Signal Tower: towers in range +20% damage and can hit armour.
- Double Tap: two shots per trigger pull. Lead Rain: fastest fire in the game.
- Armor Breaker: can damage armoured dinos (Ankylosaurus). Hollow Points: ×2 vs armoured. Railshot: bullet passes through 3 dinos. Hide Buster: ×4 vs armoured and bosses.

A/B/C picks at tiers 4 and 5 (PLAN 9c, DECISIONS #290; A = the path table's T4 / T5; names are working names until the Dino pass):

| Path | Tier | A | B | C |
|---|---|---|---|---|
| **Lookout** | 4 | Watch Post — Sees further, and shoots faster and harder | Signal Mirror — Towers in range fire 18% faster | Spotter's Call — Its target takes +15% from every tower |
| **Lookout** | 5 | Signal Tower — Towers in range hit harder and can hurt armour | Beacon Fire — Towers in range fire 35% faster | Alpha Spotter — Bosses in range take +40% from everything |
| **Trigger Happy** | 4 | Bullet Hose — Fires much faster and hits harder | Belt Feed — Never stops to reload: fires 45% faster | Long Burst — Fires faster from further away |
| **Trigger Happy** | 5 | Lead Rain — The fastest fire in the game | Bullet Storm — Lighter bullets go through 4 dinos | Shredder — Bullets punch through armour and strip it |
| **Hardliner** | 4 | Railshot — Each bullet goes through 3 dinos | Cracking Shot — Goes through 2 dinos and strips their armour | Heavy Slug — Goes through 2 dinos, shrinking each 3 sizes |
| **Hardliner** | 5 | Hide Buster — Hits armoured dinos and bosses 4 times as hard | Jolt Rounds — Hits jolt dinos still for a moment | Rail Lance — Each bullet goes through 6 dinos |

## Longshot Perch (Sniper) — global range, slow

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Deadeye** | line pierce | *Full Metal Jacket* | *Through-and-Through* | Ricochet | Tungsten Core | *Linebreaker* |
| **Spotter** | speed + mark | Steady Breath | Bolt Racking | *Marked Target* | Game Spotter | *Eye in the Sky* |
| **Big Bore** | boss killer | Large Calibre | *Bone Breaker* | *Concussion Round* | Punt Gun | *Extinction Round* |

- Full Metal Jacket: hits 2 in a line. Through-and-Through: hits 3, pierces armour. Linebreaker: hits 10, ×2 damage.
- Marked Target: its target takes +25% from every tower. Eye in the Sky: mark +60%, towers in range +15% attack speed.
- Bone Breaker: ×3 vs bosses. Concussion Round: stun on hit. Extinction Round: ×10 vs bosses, stuns bosses.

A/B/C picks at tiers 4 and 5 (PLAN 9c, DECISIONS #290; A = the path table's T4 / T5; names are working names until the Dino pass):

| Path | Tier | A | B | C |
|---|---|---|---|---|
| **Deadeye** | 4 | Tungsten Core — Shots go through more dinos, shrinking each 2 sizes | Wind Shear — Shots shove the whole line 3 studs back | Fast Bolt — Fires much faster through 5 dinos |
| **Deadeye** | 5 | Linebreaker — Each shot hits 10 dinos in a line, double damage | Piercing Gale — Fast shots through 8 dinos | Shatterline — Every dino in the line loses its armour |
| **Spotter** | 4 | Game Spotter — Fires faster, and its mark hits harder | Painted Target — Bosses in range take +25% too | Quick Spot — Fires much faster, marks more often |
| **Spotter** | 5 | Eye in the Sky — A bigger mark, and towers in range shoot faster | Spotter Network — Towers in range hit 15% harder | Kill Order — Every boss in range takes +40% |
| **Big Bore** | 4 | Punt Gun — Huge shots that stun and shrink a dino 3 sizes | Elephant Gun — Twice the damage against bosses | Knockdown Round — Knocks the hit dino 4 studs back |
| **Big Bore** | 5 | Extinction Round — 10 times damage to bosses, and stuns them | Bone Splitter — Each shot shrinks a dino 5 sizes | Hammer Shot — Stuns 1.2 s and knocks 6 studs back |

## Mortar Pit (Grenadier) — area damage, ground only

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Blast** | radius + burn | Bigger Bang | Shrapnel | *Napalm* | Firestorm | *Scorched Earth* |
| **Cluster** | bomblets | *Cluster Shell* | Rapid Loader | *Chain Reaction* | Carpet Shelling | *Meteor Shower* |
| **Concussive** | control / anti-armour | *Shockwave* | *Armor Crack* | *Stun Grenade* | Earthshaker | *Tectonic Slam* |

- Napalm: leaves a burning patch on the track. Scorched Earth: long burning stretch.
- Cluster Shell: each shell splits into 3 blasts. Chain Reaction: the bomblets burst again.
- Shockwave: knocks dinos back along the track. Armor Crack: damages armour, ×2 vs armoured. Stun Grenade: brief stun. Tectonic Slam: everything hit is stunned 1s.

A/B/C picks at tiers 4 and 5 (PLAN 9c, DECISIONS #290; A = the path table's T4 / T5; names are working names until the Dino pass):

| Path | Tier | A | B | C |
|---|---|---|---|---|
| **Blast** | 4 | Firestorm — Bigger blasts that leave dinos burning | Big Shell — Much bigger blasts | White Phosphorus — A short, very hot burning patch |
| **Blast** | 5 | Scorched Earth — Leaves a long burning stretch of track | Blast Furnace — Huge blasts that hit harder | Inferno Shell — Patches burn twice as hot |
| **Cluster** | 4 | Carpet Shelling — More bomblets and harder blasts | Fire Bomblets — Bomblets leave small fires | Wide Scatter — Bomblets spread over a wider area |
| **Cluster** | 5 | Meteor Shower — Even more bomblets rain down | Firecracker Rain — Bomblets burst a third time | Thumper Shells — Bomblets knock small dinos back |
| **Concussive** | 4 | Earthshaker — Hits much harder and knocks dinos further back | Aftershock — Stuns hit dinos for half a second | Armour Splitter — Hit dinos lose their armour |
| **Concussive** | 5 | Tectonic Slam — Stuns every dino it hits for a second | Seismic Charge — Throws dinos 10 studs back | Rockfall — A short stun that holds bosses too |

## Tranq Station (Chiller) — tranquilizer darts: slow and knockout ✅ phase 5 · unlock 100 Amber

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Sedate** | slow radius | Mild Dose | Heavy Dose | *Lingering Dose* | Sedative Cloud | *Deep Sleep* |
| **Knockout** | hard stops | *Knockout Dart* | Heavy Sedative | *Barbed Darts* | Quick Cycle | *Big Game Tranq* |
| **Weak Spot** | damage amp | *Exposed Hide* | *Find the Gap* | *Hunter's Call* | Vital Points | *Apex Predator* |

- Mild Dose → Sedative Cloud: a stronger slow each tier. Lingering Dose: the slow lingers after a dino leaves the zone. Deep Sleep: slows bosses too.
- Knockout Dart: knocks out every dino in range every few seconds. Barbed Darts: knockouts also deal damage. Big Game Tranq: a long knockout that holds bosses.
- Exposed Hide: sedated dinos take +25% damage. Find the Gap: +35%, and sedated dinos lose their armour. Hunter's Call: towers in range +10% attack speed. Apex Predator: +75%, towers in range +20% damage.

A/B/C picks at tiers 4 and 5 (PLAN 9d, DECISIONS #292–#295; A = the path table's T4 / T5; names are working names until the Dino pass). Sleeper Darts is the Raider option: in battles it also stings an enemy hunter who shoots a tower here from inside its range (slow 30 % for 2 s, once per 3 s per hunter, never through Camo Cover); in co-op it is a 72 % slow:

| Path | Tier | A | B | C |
|---|---|---|---|---|
| **Sedate** | 4 | Sedative Cloud — A much stronger slow over a wider area | Drowsy Trail — Dinos stay slowed 4 s after they leave | Sleeper Darts — Also slows raiders who shoot your towers |
| **Sedate** | 5 | Deep Sleep — Its slow works on bosses too | Fog Bank — A huge sleepy cloud slows a much wider ring | Long Nap — Dinos stay slowed 7 s after they leave |
| **Knockout** | 4 | Quick Cycle — Knockouts come sooner and hurt more | Long Sleep — Knockouts hold dinos 1.8 s instead of 1 | Knockout Ring — Knocks out dinos in a much wider ring |
| **Knockout** | 5 | Big Game Tranq — A long knockout that even holds bosses | Snooze Alarm — Knocks out every dino in range every 4 s | Sleep Wave — A giant knockout ring |
| **Weak Spot** | 4 | Vital Points — Sedated dinos take even more damage | Pack Instinct — Towers in range fire 20% faster | Big Game Weakness — Bosses in range take +40% from everything |
| **Weak Spot** | 5 | Apex Predator — Dinos take much more damage; towers in range hit harder | Feeding Frenzy — Towers in range fire 35% faster | Killing Ground — Bosses in range take +75% from everything |

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

A/B/C picks at tiers 4 and 5 (PLAN 9d, DECISIONS #292–#295; A = the path table's T4 / T5; names are working names until the Dino pass). Bounty cash: a dino taken down (sinks count, shrinks don't) inside its range pays this side the bounty; the strongest camp covering it pays, once:

| Path | Tier | A | B | C |
|---|---|---|---|---|
| **Yield** | 4 | War Chest — Pays a lot more cash every round | Savings Jar — Less income, but 3% interest on banked cash | Bounty Board — +8 cash for each dino taken down in its range |
| **Yield** | 5 | Amber Vault — Earns interest on your banked cash | Gold Reserve — Big interest: 8% on banked cash | Bounty Hall — +25 cash for each dino taken down in its range |
| **Airdrop** | 4 | Supply Chain — More chests land each round, worth more | Heavy Crates — Two crates a round, worth more each | Extra Drop — Four crates a round |
| **Airdrop** | 5 | Treasure Haul — The richest chests, and more of them | Supply Fleet — Five crates a round | Gold Crates — Four crates a round, worth 900 each |
| **Logistics** | 4 | Forward Camp — Towers in range shoot faster | Bulk Buyer — Upgrades in range cost 18% less | Scrap Dealer — Towers in range sell for 97% |
| **Logistics** | 5 | Base Camp — Towers in range cost less and sell for full price | Wholesale — Upgrades in range cost 32% less | Depot — Towers in range fire 20% faster, cost 15% less |

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

A/B/C picks at tiers 4 and 5 (PLAN 9d, DECISIONS #292–#295; A = the path table's T4 / T5; names are working names until the Dino pass). Biter slow (Bitter Tonic / Bitter Brew): a dino that bites a tower in range is slowed (not bosses); the strongest hospital's slow wins:

| Path | Tier | A | B | C |
|---|---|---|---|---|
| **Ward** | 4 | Night Shift — Heals towers and hunters even faster | Quick Stitch — Trampled towers stand up twice as fast | Big Tent — Heals towers in a wider ring |
| **Ward** | 5 | Miracle Ward — The fastest heals; trampled towers revive at full speed | Field Ward — Heals a huge ring of towers | Rapid Recovery — Trampled towers jump back up 4x as fast |
| **Rescue** | 4 | Pack Mules — Three med kits a round, and each heals more | Long Whistle — Kits reach hunters in a much wider ring | Kit Bags — Four med kits land each round |
| **Rescue** | 5 | Rescue Beacon — Bigger kits and reach; downed hunters return sooner | Pack Train — Five med kits a round, 50 each | Medevac — Downed hunters come back 3x as fast |
| **Tonic** | 4 | Bone Broth — Towers in range get much more health | Hot Coffee — Towers in range fire 18% faster | Bitter Tonic — Dinos that bite towers in range get slowed |
| **Tonic** | 5 | Last Stand — More health; once a round, saves a tower from trampling | Adrenaline — Towers in range fire 30% faster | Bitter Brew — Biters slowed 30% for 3 s; towers +45% HP |

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

A/B/C picks at tiers 4 and 5 (PLAN 9d, DECISIONS #292–#295; A = the path table's T4 / T5; names are working names until the Dino pass). Barbed Wire is the Raider option: in battles it also stings an enemy hunter who shoots a tower here from inside its range (10 damage x0.5, slow 20 % for 2 s, once per 3 s per hunter, never through Camo Cover); in co-op it is 32 % resistance:

| Path | Tier | A | B | C |
|---|---|---|---|---|
| **Plating** | 4 | Tempered Steel — Tougher armour, and biters take more damage back | Spiked Walls — Dinos that bite take 10 damage back | Barbed Wire — Stings and slows raiders who shoot towers here |
| **Plating** | 5 | Bulwark — The best armour; biting dinos get stunned (not bosses) | Iron Fortress — Towers in range take 55% less damage | Spike Fortress — Biters take 18 damage back |
| **Gunsmith** | 4 | Match Grade — Towers in range hit harder and shoot faster | Rapid Feed — Towers in range fire 20% faster | Heavy Loads — Towers in range hit 30% harder |
| **Gunsmith** | 5 | Master Gunsmith — Towers in range hit much harder and faster | Machine Shop — Towers in range fire 30% faster | Magnum Loads — Towers in range hit 40% harder |
| **Outfitter** | 4 | Steady Rests — Hunters in range shoot straighter | Loading Bench — Hunters in range reload 30% faster | Gun Braces — Hunters in range have 30% less recoil |
| **Outfitter** | 5 | Full Kit — Wider reach, and hunters in range fire faster | Gun Oil — Wider ring; hunters in it reload 20% faster | Steady Aim — Wider ring; hunters in it aim 20% tighter |

---

# The round-4 batch (TOWERS_NEXT.md, Jovan's picks 2026-10-02; DECISIONS #146–#152, #159)

Unlocks at 2× Amber, normal in-match prices (#147). Falcon Roost and Tar Pit **can't be
damaged**: no HP, dinos never target them, no repairs, Armory/Hospital don't affect them,
and they're "somewhat weaker" (#193). All four are sold since T68 (921cab2): in-match cost
Storm Coil 400, Falcon Roost 400, Tar Pit 450, Harpoon Ballista 500 (#194–#195). "Worth it"
(#193, #200): a damageable tower's best T5 costs ≤ 1.25 × M per eDPS in rounds 31–40, a
can't-be-damaged one between 1.25 × and 2 × M (M = 142, frozen); Tar Pit is judged as a
control tower (#198, #201–#203). Tier 4s are the Director's picks (#149), tier 5s Jovan's.

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

A/B/C picks at tiers 4 and 5 (PLAN 9e, DECISIONS #296–#297; A = the path table's T4 / T5; names are working names until the Dino pass). Storm Front: every 8 s the coil strikes every dino on its side's field for ×0.5 its damage (air too; armour only if it pierces; breaks 1). Chain effects (Supercell, Superconductor): the strike's slow and stun land on every dino in the chain; an arc's stun is capped at 0.3 s (Tuning Chain stun cap), the first dino keeps its full stun; never bosses. Thunderstrike: the strike's first dino breaks 2 sizes (arcs 1). Rod Strike is the Raider option: in battles it also stings an enemy hunter who shoots a tower here from inside its range (8 damage x0.5, slow 20 % for 1 s, once per 3 s per hunter, never through Camo Cover); in co-op it is a 15 % rate aura:

| Path | Tier | A | B | C |
|---|---|---|---|---|
| **Arc** | 4 | Jump Spark — Arcs can jump from one coil's range to another's | Branching Bolt — Every arc forks three ways | Chain Surge — Three more arcs on every strike |
| **Arc** | 5 | Power Grid — Strikes every dino near every coil; more coils, more power | Storm Front — Every 8 s a strike hits every dino on the field | Supercell — A 14-arc chain that slows every dino it hits |
| **Charge** | 4 | High Voltage — Hurts armoured dinos, and hits harder | Overcharge — Stuns its first target for 0.8 s | Static Storm — Struck dinos take +30% from the next strike |
| **Charge** | 5 | Judgement Bolt — A huge bolt shrinks the biggest dino 3 sizes | Superconductor — Every dino in the chain is stunned for a moment | Thunderstrike — Huge strikes that break 2 sizes |
| **Lightning Rod** | 4 | Storm Warning — Towers in range hit harder | Ground Wire — Strikes down a dino throw every 2 s | Rod Strike — Zaps raiders; towers in range fire 15% faster |
| **Lightning Rod** | 5 | Lightning Rodeo — Towers in range chain their shots to one more dino | Lightning Shield — Strikes down a throw at a tower every second | Thunder Drums — Towers in range fire 25% faster |

## Falcon Roost (FALCON) — birds of prey, can't be damaged ✅ round 4 (PLAN T65; sold from T68) · unlock 200 Amber

A tall perch with a falconer's hut. Two falcons fly to the first dino within 40 studs (one
no other bird is already after), dive, strike and come back: the hit lands after the
flight (Falcon speed 40 studs/s), and a bird can't go again until it's home. Hits air and
ground. No armour until Iron Talons. Rules: `Shared/Falcon`.

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Talons** | raw damage, pierces armour | Sharp Talons | Hooked Beak | *Power Dive* | *Iron Talons* | *Eagle of the Peak* |
| **Flock** | more birds | Second Pair | Quick Return | *Flock of Six* | *Wide Circle* | *Murmuration* |
| **Falconer** | support | Long Leash | Falcon Bells | *Hooded Scout* | *Lure* | *Hunting Party* |

- Power Dive: the first dive on a dino ×3, breaks 2. Iron Talons: pierces armour, breaks 3. Eagle of the Peak: one giant eagle replaces the flock, ×6 dives, stuns 0.5s (not bosses), breaks 3.
- Second Pair: 4 birds. Flock of Six: 6 birds. Wide Circle: radius 60. Murmuration (pending Jovan: or Sky Swarm): 12 small birds peck every dino in range (no more dives or flights; breaks 1).
- Long Leash: +10% range. Falcon Bells: a struck dino takes +10% for 2s. Hooded Scout: bosses in range marked +25%. Lure: struck dinos pulled 2 studs back (not bosses). Hunting Party: towers in range +15% attack speed while a bird dives.

A/B/C picks at tiers 4 and 5 (PLAN 9e, DECISIONS #296–#297; names are working names until the Dino pass). Raking Strike: a dive also hits the dino nearest the struck one (breaks 1). Strafing Run: a dive also hits the 2 dinos right behind the struck one on the track, each with the dive's breaks. Guard Falcons is the Raider option: in battles it also stings an enemy hunter who shoots a tower here from inside its range (6 damage x0.5, slow 20 % for 1 s, once per 3 s per hunter, never through Camo Cover); in co-op bosses in range take +40 %:

| Path | Tier | A | B | C |
|---|---|---|---|---|
| **Talons** | 4 | Iron Talons — Hurts armoured dinos; dives shrink a dino 3 sizes | Raking Strike — Each dive also slashes the dino beside it | Stoop Strike — The first dive on a dino hits 6x |
| **Talons** | 5 | Eagle of the Peak — One giant eagle dives, stuns and shrinks a dino 3 sizes | Harpy Strike — Dives break 4 sizes and hit bosses 2x | Hide Ripper — Talons shred armoured dinos |
| **Flock** | 4 | Wide Circle — The birds hunt much further out | Swift Wings — Birds fly back much faster | Second Flock — Seven bigger birds hunt at once |
| **Flock** | 5 | Murmuration — A swarm of small birds pecks every dino in range | Sky Hunters — Twelve birds hunt twice as far out | Strafing Run — Each dive cuts through 3 dinos in a line |
| **Falconer** | 4 | Lure — Struck dinos get pulled back (not bosses) | Loud Bells — Struck dinos take +25% from every tower | Guard Falcons — Birds dive at raiders; bosses take +40% |
| **Falconer** | 5 | Hunting Party — Towers in range shoot faster while a bird dives | Royal Hood — Bosses in range take +60% from everything | Bell Chorus — Struck dinos take +40% from every tower |

## Tar Pit (TARPIT) — on the track: slows and sinks, can't be damaged ✅ round 4 (PLAN T67; sold from T68) · unlock 250 Amber

Placed **on the track** (dinos walk through it, #152). Its pool is 12 studs of track centred
where it stands; a new pit's pool may not overlap another pit's pool at its current length
(touching is fine, #189). Ground dinos in the tar are slowed 25% (bosses too); a dino at its
last size that stays in it 1s **sinks** (#202) — a take-down that pays like a kill and counts as a
pop for the pit's owner (never bosses, never Pteranodons). No air. A dino in two pools (a
Tar Lake can make them touch) gets only the strongest pool — the one with the most cash in
it — so slow, damage, sinking and Eruption never stack (#189). Rules: `Shared/TarPit`.

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Deep Tar** | slow and sink | Thick Tar | Wide Pool | *Fast Sink* | *Clinging Tar* | *Tar Lake* |
| **Bubbling** | damage | Warm Tar | Simmer | *Boiling Pit* | *Tar Fire* | *Eruption* |
| **Dig Site** | cash and support | Pick and Shovel | Fossil Hunter | *Lucky Finds* | *Tar Tracks* | *Tar Totem* |

- Thick Tar: slow 35%. Wide Pool: 18 studs of track. Fast Sink: the smallest dinos sink in 0.5s (base pit 1s; #202, T68b). Clinging Tar: dinos walking out stay slowed 3s. Tar Lake: the pool covers three times as much track (54 studs).
- Warm Tar / Simmer: the tar deals damage per second to every dino in it (8, 22). Boiling Pit: burning tar (80/s); its ticks break 1 (#127). Tar Fire: dinos walk out burning — one tick of 2s of the tar's damage, kept as they shrink. Eruption: every 10s (#201, T68b; its tar burns 80/s, like Tar Fire) a geyser drops every dino in the pool 2 sizes outright, bosses included, Break resist ignored; each size pays (#150).
- Pick and Shovel / Fossil Hunter: +2 / +6 cash per sunk dino (#203, T68b). Lucky Finds: each sink also leaves a chest worth 10 where the dino went under (collected like an airdrop). Tar Tracks: after a dino walks out, the next 12 studs of track slow 15% for 3s. Tar Totem: towers in range +15% damage against slowed dinos (tar or tranq).

A/B/C picks at tiers 4 and 5 (PLAN 9e, DECISIONS #296–#297; names are working names until the Dino pass). La Brea: the smallest dinos sink at once (0.05 s). Pitch Coat: a dino in the pool loses its armour while in it and for Strip (s) after (9c's strip), so the tar's burn hurts it. Bog Boots is the Raider option: in battles it also slows an enemy hunter who shoots a tower near the pit (slow 30 % for 2 s, once per 3 s per hunter, never through Camo Cover; "near" = within Pool sting reach, 12 studs, of the nearest point of the pool at its current length, Tar Lake included; PLAN T120b, #321); in co-op it is a longer pool that slows 45 %. Bog Boots' Range x 1.5 multiplies with Tar Lake (×3 → 81 studs), fine by the pool-overlap rule (#189), playtest watch:

| Path | Tier | A | B | C |
|---|---|---|---|---|
| **Deep Tar** | 4 | Clinging Tar — Dinos stay slowed for a while after they leave | Thick Mire — Thicker tar: dinos wade much slower | Bog Boots — A longer pool that also slows raiders |
| **Deep Tar** | 5 | Tar Lake — The pool covers three times as much track | La Brea — Smallest dinos sink at once; the rest crawl | Black Glue — Dinos stay slowed 5 s after they climb out |
| **Bubbling** | 4 | Tar Fire — Dinos walk out of the tar still burning | Boiling Splash — A bigger pool of boiling tar | Pitch Coat — Sticky tar strips armour; dinos leave burning |
| **Bubbling** | 5 | Eruption — A geyser shrinks every dino in the pool 2 sizes | Ever-Burn — Dinos keep burning 2.75 s after they leave | Tar Inferno — The tar boils 50% hotter |
| **Dig Site** | 4 | Tar Tracks — Dinos leaving the tar leave a slowing trail | Bone Yard — Every sunk dino pays more cash | Fossil Finder — Bigger chests where dinos go under |
| **Dig Site** | 5 | Tar Totem — Towers in range hit slowed dinos harder | Preserved Specimens — Every sunk dino pays 36 cash | Amber Seep — Chests where dinos sink are worth 60 |

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

A/B/C picks at tiers 4 and 5 (PLAN 9e, DECISIONS #296–#297; names are working names until the Dino pass). Heartseeker (Targets biggest): bolts aim at the dino with the most HP in range instead of the furthest along. Bolts mark what they hit (Serrated Head), slow it (Anchor Line, bosses too) and leave a burning patch under the target (Fire Bolts, Firestorm Volley). Snag Line is the Raider option: in battles it also stings an enemy hunter who shoots a tower here from inside its range (12 damage x0.5, slow 30 % for 3 s, once per 3 s per hunter, never through Camo Cover); in co-op it holds dinos 1.75 s:

| Path | Tier | A | B | C |
|---|---|---|---|---|
| **Spearhead** | 4 | Great Harpoon — Pierces armour and shrinks a dino 3 sizes | Serrated Head — Hit dinos take +20% from every tower | Whale Lance — Bolts hit bosses 40% harder |
| **Spearhead** | 5 | Skewer — The bolt flies on through every dino in its line | Leviathan Bolt — Bolts break 4 sizes and hit bosses 3x | Heartseeker — Always aims for the biggest dino in range |
| **Reel** | 4 | Reel In — Drags the hit dino back along the track (not bosses) | Tether — Pinned dinos stay held 2 s | Snag Line — Harpoons raiders too; holds dinos 1.75 s |
| **Reel** | 5 | Tow Line — Every 15 seconds, pulls a boss back along the track | Anchor Line — Bolts slow bosses too: 30% for 2 s | Winch Haul — Drags hit dinos 7.5 studs back |
| **Volley** | 4 | Steam Crank — Fires twice as fast | Wide Volley — Five bolts per volley | Fire Bolts — Bolts set dinos on fire |
| **Volley** | 5 | Chain Harpoons — Chained bolt pairs hit every dino between them | Siege Battery — Six bolts per volley | Firestorm Volley — Faster volleys of burning bolts |


---

## Amber Resin Cannon (RESIN) — control: resin slows, entombs and fossilizes · built (PLAN 9g T123; sold from T124d) · unlock 500 Amber

A stubby cannon on a cart that lobs amber resin (2 damage, 1 glob a second, 18 studs, ground
only, 800 cash). Every glob slows the dino 20 % for 1 s (not bosses) and adds 1 resin; at
max(1, ⌈6 × Entomb hits x × its HP-left share⌉) resin the dino is **entombed** (a hard stop:
it can't move, bite or throw, and still takes damage) for Entomb (s) (0.8 s base) and glows
amber: the more HP is gone, the faster it sets. Bosses: at most once every 10 s per boss, for
half the time. A control tower (judged like the Tar Pit, #314): out of the damage medians.
Rules: `Shared/Resin`, `Shared/FourX`, `Shared/AutoFire`.

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Entomb** | control | Thick Resin | Quick Set | *Amber Tomb* | *Hardened Amber* | *Amber Age* |
| **Fossilize** | economy | Collector's Eye | Rare Find | *Fossil Record* | *Museum Piece* | *Fossil Fuel* |
| **Resin Shell** | support | Coat of Resin | Sticky Armour | *Amber Shield* | *Self-Sealing* | *Amber Fortress* |

- Thick Resin / Quick Set / Amber Tomb: faster, heavier globs and fewer hits to set (x0.85 / x0.7 / x0.5); Amber Tomb entombs for 2 s.
- Fossilize: a dino entombed at or below Fossil below % of its HP (10 / 12 / 20 %; not bosses) is a **fossil**: it turns to stone and crumbles, every size it had left pays as a take-down (pops to the cannon's owner), plus Sink cash per fossil (50 / 100 / 100 after T124b's payback tuning, seeds 4 / 10 / 16; scaled by the difficulty like Tar Pit sinks, #309). Fossil Record also sets faster (x0.7).
- Resin Shell: towers in range +15 % max HP; Sticky Armour adds 20 % damage resistance; Amber Shield **seals** a tower in range that would be Trampled: it stays at 1 HP and takes no damage for 3 s (once a round per cannon).

A/B/C picks at tiers 4 and 5 (PLAN 9g, DECISIONS #312–#320; names = DINO_REVIEW Round 19). Hardened Amber: an entombed dino takes +30 % from everything while it is stuck. Spreading Amber: an entomb also takes the nearest other dino within 6 studs. Sticky Bed: dinos within 6 studs of a stuck one walk 30 % slower. Amber Age: every 12 s every dino in range is entombed (bosses half). Living Amber: entombs last 2.5 s, a boss's the full 3 s. Time Capsule: an entombed dino is sent 12 studs back (never a boss). Museum Piece: fossils pay 50 % more cash (150 a fossil, over Fossil Record's 100). Dig Crew: a fossil drops a 25-cash chest. Bone Dust: a fossil (or any take-down by the cannon) marks dinos within 6 studs +15 % for 3 s. Fossil Fuel: fossils at 25 %; each fossil gives towers in range +5 % attack speed for the rest of the round (cap 30 %). Prize Fossils: fossils at 30 %; each counts as 2 take-downs for the owner's Bounties. Amber Heart: every 15th fossil this match entombs every dino on your side 1 s (bosses half). Self-Sealing: a sealed tower heals 30 % of its max HP when the seal breaks. Raider Glue is the Raider option: in battles an enemy hunter who shoots a tower in range is slowed 20 % for 2 s (generic Raider sting, ×0.5 rules, never through Camo Cover); its dino part (co-op too): a dino biting a tower in range is slowed 25 % for 2 s (not bosses). Sticky Thorns: biters take 5 damage and are slowed 15 % for 1.5 s. Amber Fortress: each tower in range can be sealed once every 20 s (instead of once a round per cannon). Resin Wall: once a round (fires itself: a boss or 6 dinos in range, else the round's last spawn; never on an empty track) an amber wall rises at the furthest point of the track in range and holds every dino reaching it 3 s (bosses 1.5 s). Amber Mirror: catches a throw at a tower in range every 1 s and bounces it back at the thrower for 60 (× the team's level).

| Path | Tier | A | B | C |
|---|---|---|---|---|
| **Entomb** | 4 | Hardened Amber — Stuck dinos take +30% from everything | Spreading Amber — The amber jumps to the next dino | Sticky Bed — Dinos walking past a stuck one slow 30% |
| **Entomb** | 5 | Amber Age — Every 12 s, everything in range is stuck | Living Amber — Traps a boss 3 s; others stay stuck longer | Time Capsule — Stuck dinos are sent 12 studs back |
| **Fossilize** | 4 | Museum Piece — Fossils pay 50% more cash | Dig Crew — A fossil drops a cash chest | Bone Dust — Fossils mark nearby dinos +15% |
| **Fossilize** | 5 | Fossil Fuel — Each fossil speeds up nearby towers | Prize Fossils — More fossils; each counts double for bounties | Amber Heart — Every 15th fossil freezes your whole side 1 s |
| **Resin Shell** | 4 | Self-Sealing — Sealed towers heal 30% when the shell breaks | Raider Glue — Raiders and biters near your towers slow down | Sticky Thorns — Biters get slowed and take 5 damage |
| **Resin Shell** | 5 | Amber Fortress — Nearby towers can't be knocked out (20 s each) | Resin Wall — Once a round, an amber wall holds every dino 3 s | Amber Mirror — Throws at your towers bounce back |


---

## Raptor Pen (RAPTOR) — tamed raptors: pack damage, one big hunter, support · built (PLAN 9g T124; sold from T124d) · unlock 500 Amber

A log pen (600 cash, 10 per bite, 2.3 bites a second; 22-stud hunting ground, 150 HP) that never shoots: its tamed **raptors**
(collar and stripe in the camp colour) sprint out along your own track, pounce, bite (seeds 850 cash / 10 / 1.5, moved by T124b/T124c's guaranteed exit, #326) and come back. A raptor has 60 HP (grows with tiers like towers),
runs home at 30 % HP and heals 15 HP/s in the pen (it leaves again at 80 %), and is gone 8 s
if bitten to 0. The dino it fights bites it instead of a tower; a big dino (3+ sizes left)
walking through it tramples it for a quarter of its HP. A pounce holds a non-boss 0.5 s.
Hunters can't hit raptors and raptors never touch hunters; they never leave your side's track.
At most 24 walkers a side. Rules: `Shared/Walker` (every walker), `Shared/Raptor`.

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Pack** | pack damage | Second Raptor | Quick Whistle | *Pack of Five* | *Hide Rippers* | *Raptor Swarm* |
| **Alpha** | one big hunter | Sharp Claws | Thick Hide | *Alpha Raptor* | *Sickle Claw* | *King of the Pack* |
| **Trainer** | support | Tracking Nose | Herding Call | *Pack Howl* | *Treat Bag* | *Raptor Charge* |

- Second Raptor: 2 raptors. Quick Whistle: bites x1.4, raptors 30 % faster and back 30 % sooner. Pack of Five: 5 raptors.
- Sharp Claws / Thick Hide / Alpha Raptor: one raptor, much harder bites (x1.9 / x3.6 / x7); Thick Hide: x1.6 HP and 25 % less damage taken; Alpha Raptor: one big alpha (x3 HP), breaks 2 and holds what it pounces 1 s.
- Tracking Nose: raptors go for the dino furthest along, +15 % range. Herding Call: bites slow 20 % for 1 s. Pack Howl: 2 raptors; towers in range attack 15 % faster while a raptor is fighting.

A/B/C picks at tiers 4 and 5 (PLAN 9g, DECISIONS #312–#320; names = DINO_REVIEW Round 19). Hide Rippers: raptors bite through armour. Flanking: no two raptors on one dino while another is free. Ambush: each raptor's first pounce after leaving the pen hits double. Raptor Swarm: once a round (fires itself: a boss or 6 dinos in range, else the round's last spawn; never on an empty track) 10 small raptors (40 % HP and bite) hunt anywhere on your track for 15 s, within the walker cap. Clever Girls: a raptor ignores one bite every 3 s and is never trampled by any dino, bosses too (#328). Sky Leap: raptors jump at flyers. Sickle Claw: the alpha bites much harder and breaks 3. Boss Hunter: x1.6 on bosses and its pounce holds a boss 0.5 s (once per boss). Scent Trail: its target is marked +15 %. King of the Pack: a giant alpha, x1.5 HP, takes half damage, breaks 4. Rex Tamer: a small tamed T. rex (x1.4 HP); every 15 s its roar stuns small dinos within 10 studs for 1 s. Hungry Alpha: each take-down by its raptors adds +10 % to their bites this round (up to +50 %). Treat Bag: raptors heal fully between rounds and come back twice as fast. Guard Raptors: each raptor is posted beside a tower in range (the most damaged first) and attacks a dino within 10 studs that bites or throws at that tower, then goes back to its post. Whistle Drill: raptors run 30 % faster; towers in range +20 % attack speed while a raptor fights. Raptor Charge: once a round (fires itself) every raptor charges your whole track from the exit end back at double speed, biting each dino it passes once and knocking small dinos 6 studs back (never a boss). Pack Bond: 3 raptors; your hunters in range deal +20 % to dinos (never to hunters or towers) while 3 or more raptors are out. Raider Hounds is the Raider option: in battles an enemy hunter who shoots a tower in range is stung for 10 (×0.5) and slowed 20 % for 1 s (generic Raider sting, never through Camo Cover; the raptors' run at the hunter is a look only); its dino part (co-op too): with no raider stung in the last 3 s the raptors go for the last dino that hurt a tower in range, bites x2, breaks 2.

| Path | Tier | A | B | C |
|---|---|---|---|---|
| **Pack** | 4 | Hide Rippers — Raptors bite through armour | Flanking — Each raptor picks a different dino | Ambush — Each raptor's first pounce hits double |
| **Pack** | 5 | Raptor Swarm — 10 small raptors flood the track once a round | Clever Girls — Raptors dodge bites and never get trampled | Sky Leap — Raptors jump at low flyers |
| **Alpha** | 4 | Sickle Claw — ×3 on its target, breaks 3 | Boss Hunter — Can hold a boss for a moment | Scent Trail — Its target is marked +15% |
| **Alpha** | 5 | King of the Pack — A giant raptor, half damage taken | Rex Tamer — A tamed T. rex whose roar stuns | Hungry Alpha — Stronger with every take-down |
| **Trainer** | 4 | Treat Bag — Raptors heal and return faster | Guard Raptors — A raptor guards each tower | Whistle Drill — Raptors run 30% faster |
| **Trainer** | 5 | Raptor Charge — Every raptor charges the track once a round | Pack Bond — Hunters nearby +20% with 3+ raptors out | Raider Hounds — Raptors chase raiders (or the dino that hurt a tower) |

---

## Bone Totem (TOTEM) — charged by Bones: a roar, buffs or cash · built (PLAN 9h T126) · sold from T126c · unlock 450 Amber

A carved pole crowned with a horned dino skull (600 cash, 24 studs, 200 HP, hits air) that never
shoots. Every pop (a dino losing a size) inside its range on your side, by anyone on your side,
adds 1 to its **charge**; at 3 it is **full**: the path's effect fires and the charge starts
again (the overflow is kept; the charge carries over between rounds and starts at 0 each match).
A glowing ring round its foot shows the charge. Pops made by any Bone Totem's roar, skulls or
spirit hunters never charge a totem. It only reads pops: Bones, the Bone Rush score, Ranked
results and Hunt Board counts are exactly what they'd be without it, and it never gives Amber.
On full, a Roar or Ancestors totem lets out the **Spirit Roar**: every dino in range takes 60
(× the team's level), breaking 2 sizes, armour only once it pierces. A control/cash tower on
two of its paths: Ancestors and Bone Pile are judged on their own lines (out of the damage
medians). Rules: `Shared/Totem`.

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Roar** | damage | Louder Roar | Quick Charge | *Thunder Roar* | *Echo Roar* | *Ancient Roar* |
| **Ancestors** | buffs | Old Bones | Shared Charge | *Spirit Guard* | *War Paint* | *Spirit Hunters* |
| **Bone Pile** | cash | Bone Collector | Trade Post | *Bone Market* | *Rare Bones* | *Camp Payday* |

- Louder Roar / Quick Charge / Thunder Roar: a harder roar (x1.6 / x2.2 / x4.2); Quick Charge fills at 80 %; Thunder Roar pierces armour and breaks 3.
- Old Bones: towers in range +20 % damage × how full the charge is. Shared Charge: a hunter's pops charge it double. Spirit Guard: when full, towers in range take no damage for 4 s.
- Bone Collector / Trade Post: 8 / 26 cash to your side for every pop in range (scaled by the difficulty like kill pay). Bone Market: a full charge no longer roars; it pays 120 cash instead.

A/B/C picks at tiers 4 and 5 (PLAN 9h, DECISIONS #312–#320; names = DINO_REVIEW Round 19). Echo Roar: the roar hits again 1 s later (x0.9 damage, T126's option-bar step). Fear: the roar knocks small dinos 8 studs back (never a boss). Shatter Roar: the roar strips armour for 4 s first (bosses half). Ancient Roar: the roar reaches every dino on your track (x0.8). Skull Storm: instead of the roar, 8 flying skulls each hit a different dino anywhere on your track for 0.6 × the roar (x1.76, T126's option-bar step), breaking 1. Finishing Roar: a boss in range dropping under 25 % of its HP gets one free roar (once per boss; no charge used). War Paint: your hunters in range deal +15 % to dinos (never to hunters or towers) for 6 s after a full charge. Bone Armour: towers in range +20 % max HP. Ancestor's Eye: towers in range +10 % range. Spirit Hunters: 3 ghost hunters fire 2 shots a second (8 damage each, × the team's level) at dinos in range for 6 s after a full charge. Totem Pole: Old Bones at 30 %, and its auras reach every tower on your side at half strength. Elder Wisdom: your hunters' abilities recharge 25 % faster in range (tempo, not damage). Rare Bones: a boss's pop fills half the charge. Bone Bank: at each round's end it pays 25 cash for each point of charge it holds. Bone Bonus: a full charge pays 168. Camp Payday: each full charge also pays 30 for every hunter in your camp. Bounty Wall: pops in range charge 25 % more, and each take-down in range counts +25 % for the owner's Bounties. Ancient Treasure: the first full charge of the match drops a 1,500-cash chest. No Raider option (#320).

| Path | Tier | A | B | C |
|---|---|---|---|---|
| **Roar** | 4 | Echo Roar — The roar hits twice | Fear — The roar scares small dinos 8 studs back | Shatter Roar — The roar strips armour for 4 s |
| **Roar** | 5 | Ancient Roar — The roar reaches your whole track | Skull Storm — 8 flying skulls hunt dinos | Finishing Roar — A free roar at a weak boss |
| **Ancestors** | 4 | War Paint — Hunters nearby +15% for 6 s when full | Bone Armour — Nearby towers get 20% more HP | Ancestor's Eye — Nearby towers see 10% further |
| **Ancestors** | 5 | Spirit Hunters — 3 ghost hunters fire for 6 s when full | Totem Pole — Buffs reach every tower, half strength | Elder Wisdom — Hero abilities nearby recharge 25% faster |
| **Bone Pile** | 4 | Rare Bones — Bosses fill half the charge | Bone Bank — Leftover charge pays at round end | Bone Bonus — Each full charge pays 40% more |
| **Bone Pile** | 5 | Camp Payday — Every hunter in your camp gets paid | Bounty Wall — Bones nearby charge 25% faster and count +25% for bounties | Ancient Treasure — One big treasure chest a match |

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
