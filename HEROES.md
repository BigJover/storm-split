# Dino Hunters — Hero Design

The player character is the hero (design doc §02, `VISION.md`). User-approved 2026-09-29;
**more heroes will be added later** — the data and code are shaped so a new hero is new rows
on the spreadsheet plus any new fire mechanic.

## Rules

- **Everyone starts as the Tracker.** Other heroes are unlocked with Amber (Big Game Hunter
  75, Brush Beater 75; `Heroes` sheet). **Picking a hero you own is free.** Pick in the build phase; switch freely (full refund of any
  upgrades) until Start, then it's locked. A player who joins mid-match picks once.
- **Only upgrades cost cash** (the team's shared pot). Each hero has three paths of five
  tiers, with the same crossover rule as towers: two paths at most, only one past tier 2.
- Upgrades are about **how the gun handles and fires** — reload, magazine, recoil, fire
  mode, special rounds — not raw damage.
- Every hero has its **ability from the start** (F), on a cooldown. One path per hero
  makes it stronger or faster.

## Mastery (saved between matches)

Storm Cores (`VISION.md` for how they're earned) buy up to 20 mastery levels per owned hero: -5% to -20% hero
upgrade costs (levels 1-4), ability cooldown -15% (5) and -30% (15), a free first upgrade
each match (10), and at 20 a gold gun and a crossover cap of 3 for this hero. Never damage.
Planned later: a second ability variant (10) and a secondary ability effect (15).

## Hero levels

Enemy HP grows ~5% a round (x7 by round 40) while hero upgrades don't add much damage, so
heroes **level up**: each level multiplies all hero damage — rounds, splash, fire, Airburst —
by +25%, compounding. Towers ride the same levels at +10% a level (they already scale with
upgrades), so both stay useful. A banner announces each level. Numbers: `Tuning` → HERO
LEVELS.

- **Now:** everyone levels up together every 5 rounds cleared.
- **Planned (user-approved 2026-09-29):** hero **XP from your own pops** drives your level
  instead, BTD6-style, with perks at some levels. Levels are already stored per player
  (`HeroLevel`), so only the trigger changes.

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

### Tracker (revolver) — Precision · ability **Tracking Dart** (target takes +% damage from everything)

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Gunslinger** | handling | Quick Draw | Hair Trigger | *Dual Pistols* | Fan the Hammer | *Akimbo Frenzy* |
| **Marksman** | accuracy | Match Barrel | Steady Hands | *Scope* | Hollow Tips | *Deadshot* |
| **Trick Shot** | utility | Speed Loader | Extended Mag | *Ricochet* | Quick Mark | *Chain Shot* |

Dual Pistols: a second gun, alternating fire. Akimbo Frenzy: both full-auto. Scope: zoom and
reach. Hollow Tips: pierces armour. Deadshot: triple damage to marked enemies. Ricochet:
bounces to a second enemy. Quick Mark: shorter Mark cooldown. Chain Shot: bounces 4 times.

### Big Game Hunter (hunting rifle) — Sustained · ability **Rally Cry** (your fire rate up, nearby towers faster)

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Tactical** | control | Foregrip | Compensator | *Burst Fire* | Trigger Discipline | *Precision Burst* |
| **Heavy** | sustain | Drum Mag | Fast Hands | *Belt Fed* | Bipod | *Spin-Up* |
| **Special Ammo** | rounds | Tracer Rounds | *Incendiary* | *AP Rounds* | Hot Load | *Explosive Tips* |

Burst Fire: 3-round bursts, tight grouping. Belt Fed: no reloading during Overdrive. Bipod:
much less recoil while standing still. Spin-Up: fire rate climbs while you hold. Tracer
Rounds: hits briefly mark. Incendiary: burning ground. AP Rounds: pierce armour. Explosive
Tips: small splash.

### Brush Beater (shotgun) — Ordnance · ability **Flare Strike** (delayed strike on the track: damage + stun)

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Slug** | reach | *Slug Rounds* | Rifled Barrel | *Sabot* | Long Barrel | *Railslug* |
| **Buckshot** | crowds | Tight Choke | Extra Pellets | *Dragon's Breath* | Auto-Loader | *Street Sweeper* |
| **Breacher** | burst | Speed Shells | Extended Tube | *Double Barrel* | Kickback | *Frag Shells* |

Slug Rounds: one accurate shot through 2 enemies. Rifled Barrel: slugs reach air. Sabot:
pierces armour. Railslug: through 6. Dragon's Breath: pellets set enemies on fire — after a moment they take one burn tick worth
35% of the shot. The fire passes to split children, so a Brute shot down to Husks sees the
Husks burn out on the tick in early rounds. Also leaves burning ground behind. Street Sweeper:
full-auto drum. Double Barrel: two blasts per trigger. Kickback: knocks enemies back. Frag
Shells: explode on impact.

## Where the numbers live

Spreadsheet `Heroes` (base gun and ability per hero) and `Hero Upgrades` (one row per tier;
effect columns cumulative per tier, like `Tower Upgrades`). Upgrade costs come from
`Tuning` → HERO.
