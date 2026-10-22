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
- **A/B/C picks (Phase 9, ✅ built and released):** tiers 4 and 5 of every path are an
  in-game pick of three options (A = the path table's tier; B/C in each hero's option table;
  the tier-5 pick is free of the tier-4 one); tier 6 stays one capstone that works after any
  tier 5. Options change handling and fire modes, never raw gun damage; no Raider options for
  heroes (#301). Picks last one match. DECISIONS #278, #298–#302.
- Upgrades are about **how the gun handles and fires** — reload, magazine, recoil, fire
  mode, special rounds — not raw damage.
- Every hero has its **ability from the start** (F), on a cooldown. One path per hero
  makes it stronger or faster.

## Mastery (saved between matches)

Amber (`VISION.md` for how it's earned) buys up to 20 mastery levels per owned hero: -5% to -20% hero
upgrade costs (levels 1-4), ability cooldown -15% (5) and -30% (15), a free first upgrade
each match (10), and at 20 a gold gun and a crossover cap of 3 for this hero. Never gun damage: perks change abilities only.

**Small perks (Jovan, 2026-10-02: "small perks"; DECISIONS #135, PLAN T51).** The levels in
between give four non-damage lines, three steps each (Mastery sheet; final names, Dino
round 13, DECISIONS #175): **Long Arms** I–III (6/11/16) picks up chests and med kits from 2/4/6 studs
away; **First Aid** I–III (7/12/17) heals 5/10/15 more HP when a round is cleared;
**Back in Action** I–III (8/13/18) respawns 10/20/30% sooner; **Handyman** I–III (9/14/19)
makes repairs 5/10/15% cheaper. They follow the hero being played.

**Ability perks (Jovan, 2026-10-02; DECISIONS #97–#99, #114–#115).** Mastery 10 and 15 also
give each hero an ability perk: the stronger one at 15, both small ("a somewhat fair
advantage", safe for the PvP modes). A hero with mastery 15 has both.

| Hero | Mastery 10 | Mastery 15 |
|---|---|---|
| Tracker | **Sticky Dart**: Tracking Dart lasts 2s longer (8 → 10) | **Spare Dart**: also marks the nearest dino within 10 studs at 40% strength |
| Big Game Hunter | **Hunting Horn**: Rally Cry reaches 6 studs further (25 → 31) | **Long Rally**: Rally Cry lasts 3.5s longer (10 → 13.5) |
| Brush Beater | **Wide Flare**: Flare Strike reaches 2.5 studs further (10 → 12.5) | **Smoulder**: leaves burning ground for 3s (12% of the strike's damage each second) |
| Field Medic | **Far Reach**: Triage Kit reaches 5 studs further (20 → 25) | **Stocked Kit**: Triage Kit heals 14 more HP (40 → 54) |

- Numbers: the `Mastery Perks` sheet, one row per hero and level. A perk adds to the hero's
  base ability value, before path upgrades multiply it (Stocked Kit + Clean Bandages = 54 ×
  1.25).
- The exporter refuses a sheet where a hero's mastery-15 perk isn't worth more than the
  mastery-10 one, where any perk is worth more than 40% of one cast (`Tuning` → MASTERY
  PERKS), or where a perk adds stun time. No perk column raises gun damage. Heroes stay
  level with each other: at mastery 10 and at 15+ (both perks summed) the strongest hero's
  perk worth is at most 1.15× the weakest's (`Perk parity band`, DECISIONS #235).
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
  rounds from this alone), plus a small **take-down bonus**: 0.25 XP per take-down (your gun, your
  towers, your fire) and a quarter of that for each teammate's take-down, rounded down, at most
  **15 a round**. A Field Medic who takes down nothing still gets the bonus from the team.
- The bonus is **pending** during the round and is banked only when the round is cleared. A
  lost round, or leaving mid-round, drops it; a leaver's take-downs also leave the team count.
- A hunter is never below the **round level** (1 + rounds cleared ÷ 5, the old curve) and
  never more than **one level above** it. With the bonus capped every round: level 3 after
  round 9, level 5 after 18, level 9 after 35. Late joiners start on the round level.
- **Towers stay on the round level** for the whole team (a level every 5 rounds cleared).
- On screen: "Lv N", an XP bar and "+{N} bonus on round clear" on its own line (#157); a banner for your own
  level ("Hunter level N — your shots hit 25% harder") and for the towers' ("Tower level N —
  towers hit 10% harder"); the tower panel shows "Tower level N · +X% damage".
- Rules: `Shared/HeroXp` (pure). The balance models print heroes at the round level and one
  above it; the exporter's hero-vs-tower guard uses the highest level in play.

**Player level (round 4, DECISIONS #118–#124, #177).** Separate from the hunter level and
saved: at match end, won or lost, each hunter present banks the hero XP of the rounds they
cleared plus a clear bonus (Easy 500 / Normal 1,000 / Hard 1,500 / Chaos 2,000) into an
**overall player level** with no cap (level n → n+1 costs 500 + 50(n−1), at most 10,000).
In solo, take-downs count ×2 toward it (up to 30 a round); co-op and the in-match hunter
level are unchanged. Rewards are cosmetics and titles only (`Shared/PlayerLevel`,
`Shared/Cosmetics`); the Profile screen (P) and the level leaderboard show it off.

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
| **Trick Shot** | utility | Speed Loader | Extended Mag | *Ricochet* | Quick Dart | *Chain Shot* | *Bounce Back* |

Dual Pistols: a second gun, alternating fire. Akimbo Frenzy: both full-auto. Scope: zoom and
reach. Hollow Tips: pierces armour. Deadshot: triple damage to marked dinos. Ricochet:
bounces to a second dino. Quick Dart: shorter Tracking Dart cooldown. Chain Shot: bounces 4 times.
Tier 6 (final names, DECISIONS #133, #174–#175): Hot Swap: the two guns reload one at a time, so firing
never stops; reload x0.8. Heart Shot: scoped shots have no spread and shrink a dino 2 sizes. Bounce
Back: each ricochet take-down puts a round back in the cylinder.

A/B/C picks at tiers 4 and 5 (PLAN 9f, DECISIONS #298–#302; A = the path table's T4 / T5; final names after the Dino passes; every T6 works after any T5). Twin Burst: each click is 3 rounds, alternating the two guns (Hot Swap still staggers). Hunter's Mark: hits mark dinos (+35% from everything).

| Path | Tier | A | B | C |
|---|---|---|---|---|
| **Gunslinger** | 4 | Fan the Hammer — Fires faster and reloads quicker | Deep Cylinders — Both guns hold 50% more and fire 15% faster | Crossdraw — Reload 35% faster, fire 15% faster |
| **Gunslinger** | 5 | Akimbo Frenzy — Both guns go full-auto | Twin Burst — Each click fires a 3-round burst, 30% faster | Steady Pair — Half the kick, tighter aim, 10% faster |
| **Marksman** | 4 | Hollow Tips — Shots pierce armour | Quick Cock — Fire 20% faster, scope and all | Breath Control — Half the kick; the scope reaches 35% further |
| **Marksman** | 5 | Deadshot — Triple damage to marked dinos | Quick Scope — Fire 70% faster with 30% less kick | Hunter's Mark — Hits mark dinos: +35% from everything |
| **Trick Shot** | 4 | Quick Dart — Your Tracking Dart is ready again sooner | Bank Shot — Ricochets bounce twice | Quick Fingers — Reload 30% faster, fire a bit faster |
| **Trick Shot** | 5 | Chain Shot — Shots bounce 4 times | Pinball — 3 bounces, a bigger cylinder, faster shots | Dart Storm — 3 bounces, faster shots, Tracking Dart sooner |

### Big Game Hunter (hunting rifle) — Sustained · ability **Rally Cry** (your fire rate up, nearby towers faster)

| Path | Focus | T1 | T2 | T3 | T4 | T5 | T6 |
|---|---|---|---|---|---|---|---|
| **Stalker** | control | Foregrip | Compensator | *Burst Fire* | Trigger Discipline | *Precision Burst* | *Big Five* |
| **Heavy** | sustain | Drum Mag | Fast Hands | *Belt Fed* | Bipod | *Spin-Up* | *Endless Belt* |
| **Special Ammo** | rounds | Tracer Rounds | *Incendiary* | *AP Rounds* | Hot Load | *Explosive Tips* | *Dynamite Rounds* |

Burst Fire: 3-round bursts, tight grouping. Belt Fed: no reloading during Rally Cry. Bipod:
much less recoil while standing still. Spin-Up: fire rate climbs while you hold. Tracer
Rounds: hits briefly mark. Incendiary: burning ground. AP Rounds: pierce armour. Explosive
Tips: small splash. Tier 6: Big Five: bursts of 5; recoil resets between bursts. Endless
Belt: once fully spun up (2 s of holding), no reloading. Dynamite Rounds: the blast grows to
6 m and pierces armour.

A/B/C picks at tiers 4 and 5 (PLAN 9f, DECISIONS #298–#302; A = the path table's T4 / T5; final names after the Dino passes; every T6 works after any T5: every Heavy T5 spins up, every Special Ammo T5 has a blast). Marking Burst / Bright Tracers: hits mark dinos. War Drum: Rally Cry twice as often.

| Path | Tier | A | B | C |
|---|---|---|---|---|
| **Stalker** | 4 | Trigger Discipline — Less kick and longer reach | Snap Bursts — Bursts come 20% faster | Quick Mag — Reload 25% faster |
| **Stalker** | 5 | Precision Burst — 4-round bursts with a much tighter grouping | Marking Burst — 4-round bursts that mark: +25% from everything | Rapid Volley — Bursts 35% faster, half the kick, bigger mag |
| **Heavy** | 4 | Bipod — Much less kick while you stand still | Steady Sling — 35% less kick, moving or not | Quick Belt — Belt changes 30% faster; 20% less kick |
| **Heavy** | 5 | Spin-Up — Fire rate climbs while you hold the trigger | Hot Barrel — 50% faster at once, spins up to +60% more | War Drum — Rally Cry twice as often; spins up to +130% |
| **Special Ammo** | 4 | Hot Load — Hits harder and reaches further | Phosphor Rounds — Fires burn 10% hotter and 50% longer | Bright Tracers — Hits mark dinos: +30% from everything |
| **Special Ammo** | 5 | Explosive Tips — Shots burst with a small splash | Fire Tips — Small blasts; dinos burn 25% longer | Flat Tips — Small blasts; rounds fly 25% further |

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
Shells: explode on impact. Tier 6: Thunder Slug: slugs shrink a dino 2 sizes; no spread while
standing still. Wildfire Drum: Dragon's Breath's burning ground 4 studs wide (from 3); holds
+50% shells. Quad Barrel: four blasts per trigger (from two); reload 1.25x longer.

A/B/C picks at tiers 4 and 5 (PLAN 9f, DECISIONS #298–#302; A = the path table's T4 / T5; final names after the Dino passes; every T6 works after any T5). Twin Slug: two slugs per pump, each through 4, both from one round (a pump spends 1 round; Double Barrel spends 2; T120b, #323). Slam Fire: full-auto, both barrels each pull (four with Quad Barrel). Bird Shot: blasts hit flying dinos.

| Path | Tier | A | B | C |
|---|---|---|---|---|
| **Slug** | 4 | Long Barrel — Tighter, longer slugs that go through 3 dinos | Quick Pump — Pump 25% faster | Side Saddle — Holds 50% more slugs, loads 20% faster |
| **Slug** | 5 | Railslug — Slugs go through 6 dinos | Express Slug — Slugs through 6, 60% faster, bigger tube | Twin Slug — Two slugs per pump, each through 4 |
| **Buckshot** | 4 | Auto-Loader — Fires faster and reloads quicker | Hot Shells — Fires burn more than twice as hot | Shell Belt — Pump 50% faster; holds 50% more |
| **Buckshot** | 5 | Thicket Sweeper — A full-auto drum | Flame Choke — Dragon's Breath bursts for 90% of a shot | Pump Storm — Pump 50% faster, bigger tube |
| **Point Blank** | 4 | Kickback — Blasts knock dinos back | Quick Breech — Reload 35% faster, fire 20% faster | Bird Shot — Blasts hit flying dinos; fire 15% faster |
| **Point Blank** | 5 | Frag Shells — Shells explode on impact | Breech Loader — 45% faster, bigger tube, quick reload | Slam Fire — Hold to keep both barrels firing, 70% faster |

### Field Medic (lever-action carbine) — Support · ability **Triage Kit** (heals you and every hunter within 20 studs by 40 HP)

DECISIONS #13, #14 (names per #25). The carbine deals less damage per second than the
Tracker's revolver: the Medic is support. The heal is flat and doesn't grow with hero levels.

| Path | Focus | T1 | T2 | T3 | T4 | T5 | T6 |
|---|---|---|---|---|---|---|---|
| **Triage** | ability | Clean Bandages | Belt Pouch | *Patch Up* | Triage Tent | *Second Wind* | *Rapid Response* |
| **Lever Action** | handling | Oiled Lever | Loading Gate | *Rapid Cycle* | Smooth Action | *Runaway Lever* | *Bottomless Tube* |
| **Muzzle** | protective rounds | Tranq Tips | Double Dose | *Jaw Lock* | Long Dose | *Lullaby Rounds* | *Lights Out* |

Clean Bandages: heals 25% more. Belt Pouch: shorter Triage Kit cooldown. Patch Up: also
heals standing towers in the radius by the same amount. Triage Tent: 1.5x radius. Second
Wind: everything healed takes 30% less damage for 8s (resistance doesn't stack: the
strongest source wins, DECISIONS #12). Oiled Lever: faster cycling. Loading Gate: bigger
magazine, faster reload. Rapid Cycle: 2-round bursts. Smooth Action: half the recoil. Runaway
Lever: full auto. Tranq Tips: hits slow dinos 20% for 1s. Double Dose: 30% for 1.5s. Jaw
Lock: a hit dino can't bite or shoot for 2s (a dark strap across its snout). Long Dose:
locked 3s. Lullaby Rounds: the lock spreads to dinos within 6 studs. Bosses ignore the slow
and are locked for half as long. Tier 6: Rapid Response: the Triage Kit holds 2 charges.
Bottomless Tube: magazine +50%, reload x0.5. Lights Out: Jaw Lock lasts at least 4 s and
spreads within 9 studs; bosses still half.

A/B/C picks at tiers 4 and 5 (PLAN 9f, DECISIONS #298–#302; A = the path table's T4 / T5; final names after the Dino passes; every T6 works after any T5). Mending Salve (**Heal regen**, #302): everything the Triage Kit heals (hunters and, with Patch Up, standing towers) regains 2 HP/s for 8 s; flat, no hero levels; doesn't stack (the strongest wins, a recast refreshes it); own team only. Triple Cycle: 3-round bursts.

| Path | Tier | A | B | C |
|---|---|---|---|---|
| **Triage** | 4 | Triage Tent — Your Triage Kit heals a wider area | Thick Gauze — Triage Kit heals 55% more | Quick Kit — Triage Kit is ready a third sooner |
| **Triage** | 5 | Second Wind — Everyone you heal takes less damage for a while | Mending Salve — Everything healed regains 2 HP/s for 8 s | Field Surgeon — Triage Kit is ready 22% sooner |
| **Lever Action** | 4 | Smooth Action — Half the kick | Long Tube — Holds 80% more rounds | Snap Lever — Cycles 14% faster |
| **Lever Action** | 5 | Runaway Lever — Goes full auto | Triple Cycle — 3-round bursts, cycling 33% faster | Steady Lever — 10% faster, half the kick, tighter aim |
| **Muzzle** | 4 | Long Dose — Jaw Lock keeps a dino's jaws shut for longer | Quick Dose — Fire 12% faster; jaws locked 2.6 s | Strap Toss — Lock jumps 2 studs; hits slow dinos 40% |
| **Muzzle** | 5 | Lullaby Rounds — Jaw Lock spreads to nearby dinos | Heavy Lids — Locked jaws stay shut 4.2 s | Drowsy Cloud — Lock spreads 4 studs; hits slow 40% for 2 s |

## Bodies and kit (Phase 10, Jovan 2026-10-20)

Each hunter has its **own body** and **its own melee (V) and grenade (C)**. Bodies are held to a
parity bar (HP/100 × (speed/16)^1.5, best ÷ worst ≤ 1.15, DECISIONS #365); slows multiply the
hunter's own speed. Kit damage grows with the hunter level like the gun; there are no kit
upgrade tiers: the kit grows through the **trained stats** (reach +20 %, grenade range +30 %,
speed +15 %, health +10 %, account-wide, trained in the Hunters' Outpost).

| Hunter | Max HP | Walk speed | Melee (V) | Grenade (C) |
|---|---|---|---|---|
| Tracker | 95 | 17 | **Hunting Knife** — 2 dmg, 0.4 s swing, 6 studs | **Stink Bomb** — 8 dmg, 10-stud cloud for 6 s; dinos in it take +20 % damage |
| Big Game Hunter | 110 | 15 | **Stock Swing** — 5 dmg, 1 s swing, 7 studs | **Safari Grenade** — 20 dmg, 12-stud blast |
| Brush Beater | 115 | 15.5 | **Brush Machete** — 2.5 dmg, 0.75 s, 7 studs, a 120° sweep hitting up to 3 | **Cherry Bomb** — 12 dmg, 9-stud blast, slows dinos 50 % for 1.5 s |
| Field Medic | 100 | 16.5 | **Splint Stick** — 1.5 dmg, 0.6 s, 6 studs, slows dinos 30 % for 1.5 s (dinos only, #401) | **Dozy Cloud** — 5 dmg, 10-stud cloud for 5 s; slows dinos 40 %, hunters 30 % for 2 s |

Grenades: 1 charge, 20 s recharge, thrown on a fixed arc along your view, 40 studs base range.
Rules (#366–#369, #400–#402): melee is checked by the server like a shot; the server owns the
grenade. Against hunters: ×0.5, never a stun or knockback, a slow of at most 30 % for 2 s; no
friendly fire. Kit raids rival towers under the gun's raid rules. Kit deals no damage to flyers
or armoured dinos, but its slows and the Stink Bomb land on armoured ground dinos. Gun + melee +
grenade together never out-damage the best tower (`value.py`; the kit peaks at 27 %).

## Where the numbers live

Spreadsheet `Heroes` (base gun and ability per hero) and `Hero Upgrades` (one row per tier;
effect columns cumulative per tier, like `Tower Upgrades`). Upgrade costs come from
`Tuning` → HERO. Bodies: `Hunter Stats`; melee and grenades: `Hunter Kit`; trained-stat caps:
`Tuning` (`Trained … max`).
