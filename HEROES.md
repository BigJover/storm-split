# Storm Split — Hero Design

The player character is the hero (design doc §02, `VISION.md`). User-approved 2026-09-29;
**more heroes will be added later** — the data and code are shaped so a new hero is new rows
on the spreadsheet plus any new fire mechanic.

## Rules

- **Picking a hero is free.** Pick in the build phase; switch freely (full refund of any
  upgrades) until Start, then it's locked. A player who joins mid-match picks once.
- **Only upgrades cost cash** (the team's shared pot). Each hero has three paths of five
  tiers, with the same crossover rule as towers: two paths at most, only one past tier 2.
- Upgrades are about **how the gun handles and fires** — reload, magazine, recoil, fire
  mode, special rounds — not raw damage.
- Every hero has its **ability from the start** (F), on a cooldown. One path per hero
  makes it stronger or faster.

## Gun mechanics

| Mechanic | What it means |
|---|---|
| Magazine + reload | Each shot uses a round; empty = automatic reload; R reloads early |
| Recoil | Each shot widens your spread; it settles when you stop. Applied by the server |
| Fire modes | Semi (one per click), auto (hold), burst (N per click) |
| Dual guns | Two guns alternate: double fire rate and magazine |
| Pellets / slug | Shotguns fire a cone of pellets; a slug is one accurate shot |
| Pierce | A shot keeps going through N enemies |
| Ricochet | A hit bounces to nearby enemies |
| Special rounds | Burn, armour-piercing, splash, knockback, marking, bonus vs marked |
| Scope | Right-click zoom in first person |
| Spin-up | Fire rate climbs the longer you hold the trigger |

## Heroes

Tiers in *italics* change how the gun fires.

### Pistol — Precision · ability **Mark** (target takes +% damage from everything)

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Gunslinger** | handling | Quick Draw | Hair Trigger | *Dual Pistols* | Fan the Hammer | *Akimbo Storm* |
| **Marksman** | accuracy | Match Barrel | Steady Hands | *Scope* | Hollow Tips | *Deadshot* |
| **Trick Shot** | utility | Speed Loader | Extended Mag | *Ricochet* | Quick Mark | *Chain Shot* |

Dual Pistols: a second gun, alternating fire. Akimbo Storm: both full-auto. Scope: zoom and
reach. Hollow Tips: pierces armour. Deadshot: triple damage to marked enemies. Ricochet:
bounces to a second enemy. Quick Mark: shorter Mark cooldown. Chain Shot: bounces 4 times.

### Assault Rifle — Sustained · ability **Overdrive** (your fire rate up, nearby towers faster)

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Tactical** | control | Foregrip | Compensator | *Burst Fire* | Trigger Discipline | *Precision Burst* |
| **Heavy** | sustain | Drum Mag | Fast Hands | *Belt Fed* | Bipod | *Spin-Up* |
| **Special Ammo** | rounds | Tracer Rounds | *Incendiary* | *AP Rounds* | Hot Load | *Explosive Tips* |

Burst Fire: 3-round bursts, tight grouping. Belt Fed: no reloading during Overdrive. Bipod:
much less recoil while standing still. Spin-Up: fire rate climbs while you hold. Tracer
Rounds: hits briefly mark. Incendiary: burning ground. AP Rounds: pierce armour. Explosive
Tips: small splash.

### Shotgun — Ordnance · ability **Airburst** (delayed strike on the track: damage + stun)

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Slug** | reach | *Slug Rounds* | Rifled Barrel | *Sabot* | Long Barrel | *Railslug* |
| **Buckshot** | crowds | Tight Choke | Extra Pellets | *Dragon's Breath* | Auto-Loader | *Street Sweeper* |
| **Breacher** | burst | Speed Shells | Extended Tube | *Double Barrel* | Kickback | *Frag Shells* |

Slug Rounds: one accurate shot through 2 enemies. Rifled Barrel: slugs reach air. Sabot:
pierces armour. Railslug: through 6. Dragon's Breath: pellets set enemies on fire — they burn down one layer (bosses just take
the burn) — and leave burning ground for the enemies behind. Street Sweeper:
full-auto drum. Double Barrel: two blasts per trigger. Kickback: knocks enemies back. Frag
Shells: explode on impact.

## Where the numbers live

Spreadsheet `Heroes` (base gun and ability per hero) and `Hero Upgrades` (one row per tier;
effect columns cumulative per tier, like `Tower Upgrades`). Upgrade costs come from
`Tuning` → HERO.
