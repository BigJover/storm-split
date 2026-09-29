# Storm Split — Tower Upgrade Design

The agreed vision for every tower's three paths (user-approved 2026-09-28). Every path is a
**specialisation** — attack speed, anti-armour, support, crowd control, economy — not a
generic "+damage / +range" track, and every tier has its **own name**, BTD6-style. Names are
original (the design doc: "your own upgrade names").

Tiers in *italics* grant a new **ability**; the rest are named stat steps. Numbers live in
the spreadsheet (`Tower Upgrades`: Name column, plus one column per mechanic as each is
built). Change a name there, not in code.

**Status key:** ✅ built · 🔜 next · ⏳ later phase

---

## Scout — cheap single-target

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Lookout** | range → support | Keen Eyes | Long Barrel | *Flare Gun* | Watch Post | *Signal Tower* |
| **Trigger Happy** | attack speed | Quick Hands | Extended Mag | *Double Tap* | Bullet Hose | *Stormgunner* |
| **Hardliner** | anti-armour | Heavy Slugs | *Armor Breaker* | Hollow Points | *Railshot* | *Tank Buster* |

- Flare Gun: towers in its range +10% attack speed. Signal Tower: towers in range +20% damage and can hit armour.
- Double Tap: two shots per trigger pull. Stormgunner: fastest fire in the game.
- Armor Breaker: can damage Armored Husks. Hollow Points: ×2 vs armoured. Railshot: bullet passes through 3 enemies. Tank Buster: ×4 vs armoured and bosses.

## Sniper — global range, slow

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Deadeye** | line pierce | *Full Metal Jacket* | *Through-and-Through* | Ricochet | Tungsten Core | *Linebreaker* |
| **Spotter** | speed + mark | Steady Breath | Bolt Racking | *Marked Target* | Tactical Spotter | *Eye in the Sky* |
| **Siege** | boss killer | Large Calibre | *Anti-Materiel* | *Concussion Round* | Siege Gun | *Skybreaker* |

- Full Metal Jacket: hits 2 in a line. Through-and-Through: hits 3, pierces armour. Linebreaker: hits 10, ×2 damage.
- Marked Target: its target takes +25% from every tower. Eye in the Sky: mark +60%, towers in range +15% attack speed.
- Anti-Materiel: ×3 vs bosses. Concussion Round: stun on hit. Skybreaker: ×10 vs bosses, stuns bosses.

## Grenadier — area damage, ground only

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Blast** | radius + burn | Bigger Bang | Shrapnel | *Napalm* | Firestorm | *Scorched Earth* |
| **Cluster** | bomblets | *Cluster Shell* | Rapid Loader | *Chain Reaction* | Carpet Shelling | *Storm of Steel* |
| **Concussive** | control / anti-armour | *Shockwave* | *Armor Crack* | *Stun Grenade* | Earthshaker | *Tectonic Slam* |

- Napalm: leaves a burning patch on the track. Scorched Earth: long burning stretch.
- Cluster Shell: each shell splits into 3 blasts. Chain Reaction: the bomblets split again.
- Shockwave: knocks enemies back along the track. Armor Crack: damages armour, ×2 vs armoured. Stun Grenade: brief stun. Tectonic Slam: everything hit is stunned 1s.

## Chiller — support / crowd control ⏳ phase 5

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Field** | slow radius | Cold Snap | Frostbite | *Permafrost* | Glacier Zone | *Absolute Zero* |
| **Freeze** | hard stops | *Flash Freeze* | Deep Freeze | *Ice Shards* | Cryo Pulse | *Stasis* |
| **Brittle** | damage amp | *Brittle* | *Shatter* | *Cold Front* | Frozen Core | *Winter's Edge* |

- Permafrost: slow lingers after leaving the zone. Absolute Zero: slows bosses too.
- Flash Freeze: periodic hard stop. Ice Shards: freezes also deal damage. Stasis: long freeze that holds bosses.
- Brittle: chilled enemies take +25% damage. Shatter: +35% and strips armour. Cold Front: towers in range +10% attack speed. Winter's Edge: +75%, towers in range +20% damage.

## Quartermaster — economy, no attack ⏳ phase 5

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Yield** | income | Supply Crate | Bigger Budget | Trade Route | War Chest | *Storm Bank* |
| **Airdrop** | loot chests | *Air Drop* | Double Drop | *Care Package* | Supply Chain | *Treasure Barge* |
| **Logistics** | discounts | *Bulk Order* | Field Engineer | *Recycler* | *Forward Base* | *Command Center* |

- Storm Bank: interest on banked cash. Air Drop: chests land that players run over to collect.
- Bulk Order: towers in range −5% upgrade cost. Recycler: towers in range sell for 90%. Forward Base: towers in range +10% attack speed. Command Center: −20% costs, full refunds.

---

## Mechanics and when they're built

| Mechanic | Used by | Status |
|---|---|---|
| Upgrade names in the tower panel | all | ✅ phase 3 |
| Range multiplier | Lookout, Field | ✅ phase 3 |
| **Armored** and **Boss** enemy flags; armour blocks damage without pierce | enemies | 🔜 phase 3b |
| Armour pierce, bonus vs armoured, bonus vs bosses | Hardliner, Deadeye, Siege, Concussive, Signal Tower | 🔜 phase 3b |
| Multi-shot per trigger | Double Tap, Stormgunner | 🔜 phase 3b |
| Line pierce (hits N in a line) | Railshot, Deadeye | 🔜 phase 3b |
| Mark (target takes +X% from all towers) | Marked Target, Eye in the Sky | 🔜 phase 3b |
| Stun, knockback | Concussion Round, Skybreaker, Shockwave, Stun Grenade, Tectonic Slam | 🔜 phase 3b |
| Burn patch on the track | Napalm, Scorched Earth | 🔜 phase 3b |
| Cluster bomblets | Cluster Shell, Chain Reaction | 🔜 phase 3b |
| Support auras (buff nearby towers) | Flare Gun, Signal Tower, Eye in the Sky | 🔜 phase 3b |
| Slow, freeze, damage-taken amp | Chiller | ⏳ phase 5 |
| Round income, chests, discounts, refunds | Quartermaster | ⏳ phase 5 |

When a mechanic lands, its numbers get a column on `Tower Upgrades` and the stat-only
multipliers get rebalanced around it — expect a tuning pass per mechanic.
