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
| **Spotter** | speed + mark | Steady Breath | Bolt Racking | *Marked Target* | Tactical Spotter | *Eye in the Sky* |
| **Siege** | boss killer | Large Calibre | *Anti-Materiel* | *Concussion Round* | Siege Gun | *Extinction Round* |

- Full Metal Jacket: hits 2 in a line. Through-and-Through: hits 3, pierces armour. Linebreaker: hits 10, ×2 damage.
- Marked Target: its target takes +25% from every tower. Eye in the Sky: mark +60%, towers in range +15% attack speed.
- Anti-Materiel: ×3 vs bosses. Concussion Round: stun on hit. Extinction Round: ×10 vs bosses, stuns bosses.

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
| **Sedate** | slow radius | Mild Dose | Heavy Dose | *Lingering Dose* | Sedative Cloud | *Hibernation* |
| **Knockout** | hard stops | *Knockout Dart* | Heavy Sedative | *Barbed Darts* | Quick Cycle | *Big Game Tranq* |
| **Weak Spot** | damage amp | *Exposed Hide* | *Find the Gap* | *Hunter's Call* | Vital Points | *Apex Predator* |

- Mild Dose → Sedative Cloud: a stronger slow each tier. Lingering Dose: the slow lingers after a dino leaves the zone. Hibernation: slows bosses too.
- Knockout Dart: knocks out every dino in range every few seconds. Barbed Darts: knockouts also deal damage. Big Game Tranq: a long knockout that holds bosses.
- Exposed Hide: sedated dinos take +25% damage. Find the Gap: +35%, and sedated dinos lose their armour. Hunter's Call: towers in range +10% attack speed. Apex Predator: +75%, towers in range +20% damage.

## Supply Camp (Quartermaster) — economy, no attack ✅ phase 5 · unlock 150 Amber

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Yield** | income | Supply Crate | Bigger Budget | Trade Route | War Chest | *Amber Vault* |
| **Airdrop** | loot chests | *Air Drop* | Double Drop | *Care Package* | Supply Chain | *Treasure Haul* |
| **Logistics** | discounts | *Bulk Order* | Field Engineer | *Recycler* | *Forward Base* | *Command Center* |

- Amber Vault: interest on banked cash. Air Drop: chests land that players run over to collect.
- Supply Camp upgrades cost less than other towers' (each tier ×1.6, not ×2.3: 1,600 / 2,560 / 4,096 / 6,554 / 10,486) so every tier repays itself in about 8–10 rounds, like the base camp (round 2, #56/#73).
- Yield: round income ×2.1 / ×3.85 / ×6.6 / ×11.1 / ×17.9 of the base 150; Amber Vault adds 5% interest (up to 500 a round).
- Airdrop: 1 / 2 / 2 / 3 / 4 chests a round worth 200 / 260 / 515 / 615 / 790 cash each.
- Bulk Order: towers in range −5% upgrade cost. Recycler: towers in range sell for 90%. Forward Base: towers in range +10% attack speed. Command Center: −20% costs, full refunds.

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

## Mechanics and when they're built

| Mechanic | Used by | Status |
|---|---|---|
| Upgrade names in the tower panel | all | ✅ phase 3 |
| Range multiplier | Lookout, Sedate | ✅ phase 3 |
| **Armored** and **Boss** dino flags; armour blocks damage without pierce | dinos | ✅ phase 3b |
| Armour pierce, bonus vs armoured, bonus vs bosses | Hardliner, Deadeye, Siege, Concussive, Signal Tower | ✅ phase 3b |
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

When a mechanic lands, its numbers get a column on `Tower Upgrades` and the stat-only
multipliers get rebalanced around it — expect a tuning pass per mechanic.

**Phase 3b rules (2026-09-28):** no tower damages an armoured dino (Ankylosaurus) until it
has an armour-piercing upgrade (Armor Breaker, Through-and-Through, Armor Crack), stands in a
Signal Tower's aura, or the dino is sedated by a Find the Gap Tranq Station; towers ignore
dinos they can't hurt. Bosses ignore stun unless the
hit says "stuns bosses", and are never knocked back. Auras don't stack — the strongest wins.
Ability numbers are seeds on `Tower Upgrades` (columns N–AD) and `Tuning` (ABILITIES).
