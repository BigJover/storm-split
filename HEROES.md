# Dino Hunters — Hero Design

The player character is the hero (design doc §02, `VISION.md`). User-approved 2026-09-29;
**more heroes will be added later** — the data and code are shaped so a new hero is new rows
on the spreadsheet plus any new fire mechanic.

## Rules

- **Everyone starts as the Tracker.** Other heroes are unlocked with Amber (Big Game Hunter
  75, Brush Beater 75, Field Medic 75; `Heroes` sheet). **Picking a hero you own is free.** Pick in the build phase; switch freely (full refund of any
  upgrades) until Start, then it's locked. A player who joins mid-match picks once.
- **Only upgrades cost cash** (the team's shared pot). Each hero has three paths of **six
  tiers** (DECISIONS #133), with the same crossover rule as towers: two paths at most, only
  one past tier 2; tier 6 needs tier 5 on the same path. Max build 6/2/0 (6/3/0 at mastery 20).
- Upgrades are about **how the gun handles and fires** — reload, magazine, recoil, fire
  mode, special rounds — not raw damage.
- Every hero has its **ability from the start** (F), on a cooldown. One path per hero
  makes it stronger or faster.

## Mastery (saved between matches)

Amber (`VISION.md` for how it's earned) buys up to 20 mastery levels per owned hero: -5% to -20% hero
upgrade costs (levels 1-4), ability cooldown -15% (5) and -30% (15), a free first upgrade
each match (10), and at 20 a gold gun and a crossover cap of 3 for this hero. Never gun damage: perks change abilities only.

**Small perks (Jovan, 2026-10-02: "small perks"; DECISIONS #135, PLAN T51).** The levels in
between give four non-damage lines, three steps each (Mastery sheet; working names until the
Dino agent's T54): **Long Arms** I–III (6/11/16) picks up chests and med kits from 2/4/6 studs
away; **Field Dressing** I–III (7/12/17) heals 5/10/15 more HP when a round is cleared;
**Quick Recovery** I–III (8/13/18) respawns 10/20/30% sooner; **Handyman** I–III (9/14/19)
makes repairs 5/10/15% cheaper. They follow the hero being played.

**Ability perks (Jovan, 2026-10-02; DECISIONS #97–#99, #114–#115).** Mastery 10 and 15 also
give each hero an ability perk: the stronger one at 15, both small ("a somewhat fair
advantage", safe for the PvP modes). A hero with mastery 15 has both.

| Hero | Mastery 10 | Mastery 15 |
|---|---|---|
| Tracker | **Sticky Dart**: Tracking Dart lasts 2s longer (8 → 10) | **Spare Dart**: also marks the nearest dino within 10 studs at 40% strength |
| Big Game Hunter | **Hunting Horn**: Rally Cry reaches 5 studs further (25 → 30) | **Long Rally**: Rally Cry lasts 3s longer (10 → 13) |
| Brush Beater | **Wide Flare**: Flare Strike reaches 1.5 studs further (10 → 11.5) | **Smoulder**: leaves burning ground for 3s (12% of the strike's damage each second) |
| Field Medic | **Far Reach**: Triage Kit reaches 4 studs further (20 → 24) | **Stocked Kit**: Triage Kit heals 10 more HP (40 → 50) |

- Numbers: the `Mastery Perks` sheet, one row per hero and level. A perk adds to the hero's
  base ability value, before path upgrades multiply it (Stocked Kit + Clean Bandages = 50 ×
  1.25).
- The exporter refuses a sheet where a hero's mastery-15 perk isn't worth more than the
  mastery-10 one, where any perk is worth more than 40% of one cast (`Tuning` → MASTERY
  PERKS), or where a perk adds stun time. No perk column raises gun damage.
- Perks act on dinos and allies only: nothing stuns, slows or marks another hunter.
- Marks don't stack (DECISIONS #106): the stronger mark wins; a weaker one changes neither
  its strength nor its time; an equal one keeps the longer time.
- Levels 6–9, 11–14 and 16–19 still give nothing (DECISIONS #61, Jovan's call).

## Hero levels

Dino HP grows ~5% a round (x7 by round 40) while hero upgrades don't add much damage, so
heroes **level up**: each level multiplies all hero damage — rounds, splash, fire, Flare Strike —
by +25%, compounding. Towers level too, at +10% a level (they already scale with
upgrades), so both stay useful. Numbers: `Tuning` → HERO LEVELS and HERO XP.

**Hero XP (Jovan, 2026-10-02; DECISIONS #100–#103, #111).** Each hunter has their own level,
driven by XP. XP lasts for one match and is never saved.

- **Clearing a round** banks 100 XP for every hunter (500 XP a level, so a level every 5
  rounds from this alone), plus a small **take-down bonus**: 0.25 XP per pop (your gun, your
  towers, your fire) and a quarter of that for each teammate's pop, rounded down, at most
  **15 a round**. A Field Medic who takes down nothing still gets the bonus from the team.
- The bonus is **pending** during the round and is banked only when the round is cleared. A
  lost round, or leaving mid-round, drops it; a leaver's take-downs also leave the team count.
- A hunter is never below the **round level** (1 + rounds cleared ÷ 5, the old curve) and
  never more than **one level above** it. With the bonus capped every round: level 3 after
  round 9, level 5 after 18, level 9 after 35. Late joiners start on the round level.
- **Towers stay on the round level** for the whole team (a level every 5 rounds cleared).
- On screen: "Lv N", an XP bar and "+N on round clear" on the HUD; a banner for your own
  level ("Hunter level N — your shots hit 25% harder") and for the towers' ("Tower level N —
  towers hit 10% harder"); the tower panel shows "Tower level N · +X% damage".
- Rules: `Shared/HeroXp` (pure). The balance models print heroes at the round level and one
  above it; the exporter's hero-vs-tower guard uses the highest level in play.

## Gun mechanics

| Mechanic | What it means |
|---|---|
| Magazine + reload | Each shot uses a round; empty = automatic reload; R reloads early |
| Recoil | Each shot widens your spread; it settles when you stop. Applied by the server |
| Fire modes | Semi (one per click), auto (hold), burst (N per click) |
| Dual guns | Two guns alternate: double fire rate and magazine |
| Pellets / slug | Shotguns fire a cone of pellets; a slug is one accurate shot |
| Pierce | A shot keeps going through N dinos |
| Ricochet | A hit bounces to nearby dinos |
| Special rounds | Burn, armour-piercing, splash, knockback, marking, bonus vs marked |
| Scope | Right-click zoom in first person |
| Spin-up | Fire rate climbs the longer you hold the trigger |

## Heroes

Tiers in *italics* change how the gun fires.

### Tracker (revolver) — Precision · ability **Tracking Dart** (target takes +% damage from everything)

| Path | Focus | T1 | T2 | T3 | T4 | T5 | T6 |
|---|---|---|---|---|---|---|---|
| **Gunslinger** | handling | Quick Draw | Hair Trigger | *Dual Pistols* | Fan the Hammer | *Akimbo Frenzy* | *Hot Swap* |
| **Marksman** | accuracy | Match Barrel | Steady Hands | *Scope* | Hollow Tips | *Deadshot* | *Heart Shot* |
| **Trick Shot** | utility | Speed Loader | Extended Mag | *Ricochet* | Quick Dart | *Chain Shot* | *Trick Reload* |

Dual Pistols: a second gun, alternating fire. Akimbo Frenzy: both full-auto. Scope: zoom and
reach. Hollow Tips: pierces armour. Deadshot: triple damage to marked dinos. Ricochet:
bounces to a second dino. Quick Dart: shorter Tracking Dart cooldown. Chain Shot: bounces 4 times.
Tier 6 (working names, DECISIONS #133): Hot Swap: the two guns reload one at a time, so firing
never stops; reload x0.8. Heart Shot: scoped shots have no spread and break 2 sizes. Trick
Reload: each ricochet take-down puts a round back in the cylinder.

### Big Game Hunter (hunting rifle) — Sustained · ability **Rally Cry** (your fire rate up, nearby towers faster)

| Path | Focus | T1 | T2 | T3 | T4 | T5 | T6 |
|---|---|---|---|---|---|---|---|
| **Stalker** | control | Foregrip | Compensator | *Burst Fire* | Trigger Discipline | *Precision Burst* | *Five-Round Burst* |
| **Heavy** | sustain | Drum Mag | Fast Hands | *Belt Fed* | Bipod | *Spin-Up* | *Endless Belt* |
| **Special Ammo** | rounds | Tracer Rounds | *Incendiary* | *AP Rounds* | Hot Load | *Explosive Tips* | *Powder Tips* |

Burst Fire: 3-round bursts, tight grouping. Belt Fed: no reloading during Rally Cry. Bipod:
much less recoil while standing still. Spin-Up: fire rate climbs while you hold. Tracer
Rounds: hits briefly mark. Incendiary: burning ground. AP Rounds: pierce armour. Explosive
Tips: small splash. Tier 6: Five-Round Burst: bursts of 5 with Precision Burst's grouping;
recoil resets between bursts. Endless Belt: no reloading while fully spun up. Powder Tips:
Explosive Tips' splash 1.5x wider; the splash pierces armour.

### Brush Beater (shotgun) — Close range · ability **Flare Strike** (delayed strike on the track: damage + stun)

| Path | Focus | T1 | T2 | T3 | T4 | T5 | T6 |
|---|---|---|---|---|---|---|---|
| **Slug** | reach | *Slug Rounds* | Rifled Barrel | *Sabot* | Long Barrel | *Railslug* | *Thunder Slug* |
| **Buckshot** | crowds | Tight Choke | Extra Pellets | *Dragon's Breath* | Auto-Loader | *Thicket Sweeper* | *Wildfire Drum* |
| **Point Blank** | burst | Speed Shells | Extended Tube | *Double Barrel* | Kickback | *Frag Shells* | *Quad Barrel* |

Slug Rounds: one accurate shot through 2 dinos. Rifled Barrel: slugs reach air. Sabot:
pierces armour. Railslug: through 6. Dragon's Breath: pellets set dinos on fire — after a moment they take one burn tick worth
35% of the shot. The fire stays lit as a dino shrinks, so a dino shot down a size still
takes the tick, which often finishes off small ones in early rounds. Also leaves burning
ground behind. Thicket Sweeper:
full-auto drum. Double Barrel: two blasts per trigger. Kickback: knocks dinos back. Frag
Shells: explode on impact. Tier 6: Thunder Slug: slugs break 2 sizes; no spread while
standing still. Wildfire Drum: Dragon's Breath's burning ground 4 studs wide (from 3); the
drum holds +50% shells. Quad Barrel: four blasts per trigger (from two); reload 1.25x longer.

### Field Medic (lever-action carbine) — Support · ability **Triage Kit** (heals you and every hunter within 20 studs by 40 HP)

DECISIONS #13, #14 (names per #25). The carbine deals less damage per second than the
Tracker's revolver: the Medic is support. The heal is flat and doesn't grow with hero levels.

| Path | Focus | T1 | T2 | T3 | T4 | T5 | T6 |
|---|---|---|---|---|---|---|---|
| **Triage** | ability | Clean Bandages | Belt Pouch | *Patch Up* | Triage Tent | *Second Wind* | *Rapid Response* |
| **Lever Action** | handling | Oiled Lever | Loading Gate | *Rapid Cycle* | Smooth Action | *Runaway Lever* | *Tube Feed* |
| **Muzzle** | protective rounds | Tranq Tips | Double Dose | *Jaw Lock* | Long Dose | *Lullaby Rounds* | *Nightcap* |

Clean Bandages: heals 25% more. Belt Pouch: shorter Triage Kit cooldown. Patch Up: also
heals standing towers in the radius by the same amount. Triage Tent: 1.5x radius. Second
Wind: everything healed takes 30% less damage for 8s (resistance doesn't stack: the
strongest source wins, DECISIONS #12). Oiled Lever: faster cycling. Loading Gate: bigger
magazine, faster reload. Rapid Cycle: 2-round bursts. Smooth Action: half the recoil. Runaway
Lever: full auto. Tranq Tips: hits slow dinos 20% for 1s. Double Dose: 30% for 1.5s. Jaw
Lock: a hit dino can't bite or shoot for 2s (a dark strap across its snout). Long Dose:
locked 3s. Lullaby Rounds: the lock spreads to dinos within 6 studs. Bosses ignore the slow
and are locked for half as long. Tier 6: Rapid Response: the Triage Kit holds 2 charges.
Tube Feed: magazine +50%, reload x0.5. Nightcap: Jaw Lock lasts 4s and spreads within 9
studs; bosses still half.

## Where the numbers live

Spreadsheet `Heroes` (base gun and ability per hero) and `Hero Upgrades` (one row per tier;
effect columns cumulative per tier, like `Tower Upgrades`). Upgrade costs come from
`Tuning` → HERO.
