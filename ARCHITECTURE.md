# Dino Hunters — Roblox Architecture

Companion to `Storm-Split-Design-Doc.pdf` (what the game is) and `Storm-Split-Balance.xlsx`
(what the numbers are). This file is **how the code is shaped**.

The design doc was written for Fortnite. Its game design still holds; its §06 (UEFN mapping)
and the Fortnite-specific parts of §09 do not. The old UEFN architecture is in `archive/uefn/`.

---

## 1. Stack

| Piece | Job |
|---|---|
| **Roblox Studio** (native on Mac) | Runs and playtests the game |
| **Rojo** | Code lives as `.luau` files in this folder, synced live into Studio. This is what makes git work. |
| **Studio MCP server** | Lets Claude start playtests, run code in Studio and read the Output window — the write → run → read errors loop |
| **`tools/export_constants.py`** | Spreadsheet → `src/shared/Config.luau` |

---

## 2. Layout

```
default.project.json         Rojo mapping (below)
src/
├── shared/   → ReplicatedStorage.Shared
│   ├── Config.luau          GENERATED from the spreadsheet. Never hand-edit.
│   ├── Track.luau           Level layout: waypoints, build area, sizes. Hand-authored.
│   ├── Path.luau            Distance-along-path math
│   ├── Placement.luau       Where a tower may stand (off track, no overlap) — client ghost + server
│   ├── TowerLook.luau       Tower models, shared by real towers and the placement ghost;
│   │                        upgrade visuals (ring size, tier label, crown/glow swaps)
│   ├── Upgrades.luau        The crossover rule, shared so the client greys out what the server refuses
│   ├── HeroStats.luau       A hero's gun right now (base + upgrades), shared by server and client HUD
│   ├── TowerStats.luau      A tower's stats right now (base + upgrades); pure, used by Towers
│   ├── Pricing.luau         Upgrade discounts and sell refunds; pure, used by Shop
│   ├── Payouts.luau         Casual Amber payout at match end; pure, used by Progression
│   ├── Combat.luau          Dino attack scaling, resistance cap, tower max HP, repair cost; pure
│   ├── ShopRules.luau       Which towers are for sale yet; placement and prompt distances
│   └── Modes.luau           Game modes and tracks the home screen offers (availability, display)
├── server/   → ServerScriptService.Server
│   ├── Main.server.luau     Entry point, wiring, and the match loop: Lobby → Building → Playing
│   │                        → GameOver/Victory → reset → Lobby. Spawns characters.
│   ├── MapBuilder.luau      Builds the map at runtime from Track
│   ├── Enemies.luau         Spawning, movement, damage, splitting, live cap; armour, stun,
│   │                        knockback, marks
│   ├── Towers.luau          Placement, stats, abilities (multi-shot, pierce, bomblets,
│   │                        burn, auras), targeting, firing
│   ├── Waves.luau           Runs the 40-round table
│   ├── Economy.luau         The team's shared cash and lives
│   ├── Scoreboard.luau      Per-player pops on the Roblox leaderboard (leaderstats)
│   ├── Hero.luau            The player as hero: free pick, upgrade paths, magazine/reload, recoil,
│   │                        fire modes, pellets/pierce/ricochet, abilities — all validated here
│   ├── Hazards.luau         Burning patches on the track (towers and hero rounds)
│   ├── Airdrops.luau        Quartermaster chests players run over to collect
│   ├── DinoAttacks.luau     Dino bites: per-dino timers, nearest standing tower or hunter in reach (reads enemies only)
│   ├── Health.luau          The only mutator of player HP: setUp (max HP, spawn force field), damage (resist), heal
│   ├── Progression.luau     Saved per player: Storm Cores, hero mastery, highest round (DataStore)
│   ├── Effects.luau         Tracers, blasts, burn discs (visual only)
│   └── Shop.luau            The one validated RemoteFunction for build/sell; tower prompts
├── starter/StarterCharacterScripts → StarterPlayer.StarterCharacterScripts
│   └── Health.server.luau   Empty on purpose: replaces Roblox's health regeneration
└── client/   → StarterPlayer.StarterPlayerScripts.Client
    ├── Home.client.luau     Home screen (Lobby): mode, track, difficulty, Play (host only)
    ├── Hud.client.luau      Status bar, Start button, level-up banner, result screen
    ├── Shop.client.luau     Build, hero select and hero upgrade screens; placement ghost; tower panel
    └── Hero.client.luau     Trigger (semi/auto/burst), reload, ammo, scope, camera, crosshair (requests only)
```

Dependencies point one way: `shared` imports nothing from `server` or `client`. `Main` imports
everything; nothing imports `Main`.

---

## 3. The core model — why this is simpler than the Fortnite version was

**Enemies are data, not NPCs.** Each enemy is a table holding one number that matters: its
distance along the path. Every frame the server adds `speed × dt` to it and samples a world
position from `Path`. The visible part is anchored, has no physics, no Humanoid and no
pathfinding.

This dissolves most of the problems the UEFN plan was built around:

- **No NPC pathing limit.** The UEFN plan's biggest unknown was how many NPCs could path at
  once. Here nothing paths.
- **Splitting is trivial.** A child spawns at its parent's distance. No navmesh re-entry.
- **Towers are math.** "In range" is a distance check; "first" targeting is the enemy with the
  largest path distance. No AI.
- **Upgrades never touch a live NPC.** A tower is a table of state; its model is a view.

---

## 4. Who owns what

| State | Sole owner | Everyone else |
|---|---|---|
| Enemies (create / move / damage / remove; stun, disarm, chill) | `Enemies` | Read `getLive()` and `isStunned` / `isDisarmed` / `slowFraction`, call `damage()` |
| Dino attack timers | `DinoAttacks` | — (it hurts towers and players only through `Towers.damage` / `Health.damage`) |
| A tower's tiers and stats | `Towers` | Call `upgrade()` after paying |
| A tower's HP and trampled state | `Towers` | Call `damage()` / `heal()` / `repair()` (after paying); dinos pick from `targets()`; clients read the body's `HP` / `MaxHP` / `KO` attributes |
| Cash and lives | `Economy` | Call `trySpend()` / `earn()` / `lose()` |
| Player HP (the Humanoid's Health / MaxHealth) | `Health` | Call `damage()` / `heal()` / `healAll()`; clients read the Humanoid |
| What a tower cost (for refunds) | `Shop` | — |
| Who built a tower | `Towers` (`tower.owner`) | Shop reads it: only the builder sells |
| Pops per player | `Scoreboard` | Towers report kills through the `onPop` hook |
| Match state (`State`), mode, track, difficulty, host | `Main` | Clients read the attributes; the host changes mode/track/difficulty through the `Lobby` remote, in the Lobby only |
| A player's hero, upgrades, ammo, recoil, cooldown, Overdrive | `Hero` | Clients read `Hero`, `HeroPath1-3`, `Ammo`, `Magazine`, `ReloadUntil`, `AbilityReadyAt` player attributes; Towers ask `Hero.towerRateBoost` |
| Burning patches | `Hazards` | Towers and Hero call `Hazards.burn()` |
| Current round | `Waves` | Read the `Round` attribute |
| Saved progression: Cores, owned heroes/towers, mastery, highest round | `Progression` | Hero asks `ownsHero` and reads mastery; Shop asks `ownsTower` (placing only); buying only outside a match |

**Server authoritative, always.** On Roblox the client is untrusted — exploiters can fire any
RemoteEvent with any arguments. The client *requests* ("upgrade the tower on pad 4, path 2");
the server checks the pad, the crossover rule and the cash, then acts. Never let the client
state a price, a damage number or a result.

---

## 5. Decisions already made in the code

**5.1 The live cap and spawn queue.** Nothing ever spawns directly — everything goes through a
queue that only drains while live enemies are under `MaxConcurrentEnemies`. (Before the
dinosaur reskin, enemies split into children and one Barge cascaded into 244; dinos now
**shrink in place** instead — same species, smaller size, HP shared across sizes — so a
round's live count is just its spawns.)

**5.2 Leaks cost effective HP, not one life.** The design doc said one life per leak. That makes
leaking a boss *cheaper* than killing it, since its children never spawn. `Enemies.leakCost()`
charges the enemy's effective HP instead — what BTD6 does. A leaked Armored Husk now costs 19
lives, so `StartingLives = 40` is probably too low. Tune it in the spreadsheet.

**5.3 One cash mutator.** Every spend goes through `Economy.trySpend()`, which checks
and deducts in one step. Four players clicking at once must not all pass the same check.

**5.4 Towers never charge money.** `Towers.upgrade()` applies an upgrade and nothing else. The
caller pays first. Keeps money logic in exactly one place.

---

## 6. Known mismatches to reconcile

- **Walk time.** The round-length formula's 14s is really *clear time after the last spawn*:
  measured in Studio at 13.8–14.3s for rounds 2–10 with no leaks. A leaking enemy walks the
  full ~610 studs at 14 studs/s ≈ 44s. Re-measure once players buy their own towers.
- **Range paths.** Resolved in phase 3: `Range x` column on Tower Upgrades (Scout Range and
  Chiller Field: 1.15 → 2.0x). The Scout Range path still also has its old damage/rate boosts,
  so it is now the strongest Scout path — trim in the spreadsheet after playtesting.
- **Fire rate ceiling.** Towers fire at most once per frame, so anything above ~60 shots/s is
  capped. Irrelevant until late upgrades.
- **Theme.** Resolved 2026-09-29: Dino Hunters (`VISION.md`). Internal keys (`HUSK`,
  `SCOUT`, `PISTOL`…) stay; display names live in the spreadsheet and `Shared/Theme`.

---

## 7. What's likely to break first: replication

The server moves every enemy part every frame, and Roblox replicates each of those moves to
every client. CPU cost is tiny — the headless run averaged well under a millisecond — but
**network replication is the probable first limit**, not the 130 cap.

The standard fix for large tower defense games: the server simulates distances only and
replicates spawn/death events; each client moves its own copies locally. Don't build that
until you've measured a problem. Watch Studio's network stats during a late round with a
second test client.

---

## 8. Phase plan

| Phase | Modules | Status |
|---|---|---|
| **1** — track, enemies, towers, lives | `Track`, `Path`, `MapBuilder`, `Enemies`, `Towers`, `Waves`, `Lives`, `Hud` | **Written and verified headlessly.** Includes splitting and the cap, which the UEFN plan had deferred to phase 3. |
| **2** — cash, placement, shop | `Economy` (replaces `Lives`), `Shop` (RemoteFunction + validation), free placement anywhere off the track with a ghost preview (pads dropped 2026-09-28 at the user's request), sell via tower prompts, build phase + Start button | **Done, confirmed in Studio.** Sells Scout, Sniper, Grenadier; Chiller and Quartermaster wait for phase 5. |
| **3** — upgrade paths | Shop calls `Towers.upgrade()`; model swaps at tiers 3 and 5; range multipliers; tier names | **Done, confirmed in Studio** |
| **3b** — tower abilities | Armored/Boss enemy flags, then the Scout, Sniper and Grenadier mechanics in `UPGRADES.md` (multi-shot, pierce, mark, stun, knockback, burn, cluster, auras) | **Written, statically checked**, not yet playtested |
| **3c** — difficulty and scale | Difficulty levels (Easy = baseline, Normal, Hard, Chaos) and per-player scaling from the spreadsheet; tower owners; pops leaderboard; owner-only selling. See `VISION.md` | **Written, statically checked**, not yet playtested |
| **4** — the hero | Free hero pick (Pistol, Assault Rifle, Shotgun); three named upgrade paths each about handling, not damage (`HEROES.md`); magazines, recoil, fire modes, pellets/slugs, pierce, ricochet, special rounds; first-person gunplay; abilities Mark / Overdrive / Airburst | **Done, confirmed in Studio** (redesign 2026-09-29) |
| **5** — roster and rounds | Chiller (chill: slow, brittle, armour strip; freeze pulses) and Quartermaster (round income, interest, airdrop chests, Logistics discounts/refunds) per `UPGRADES.md` | **Written 2026-09-29, statically checked**, not yet playtested |
| **5b** — levels | Heroes +25% and towers +10% damage per level, a level every 5 rounds cleared (`HEROES.md`). Next step, planned: hero XP from pops drives each player's level | **Done, confirmed in Studio** |
| **6** — progression | `Progression`: DataStore save (Cores, owned heroes/towers, mastery per hero, highest round; failed loads never overwrite). Casual payouts (clear reward per difficulty; multiplayer loss 5; solo loss 0). Core unlocks: Pistol + Scout/Sniper/Grenadier free; Rifle/Shotgun 75, Chiller 100, Quartermaster 150; place only what you own, upgrade anyone's. Mastery screen (M). Deferred: level 10/15 ability variants; competitive buy-ins/pots (phase 7) | **Written 2026-09-29, statically checked**, not yet playtested; saving needs the place published |
| **6b** — home screen | Match loop in `Main` (Lobby → match → results → reset → Lobby), no characters until Play, host picks mode (Co-op; Team Battle / Battle Royale shown as coming soon), track and difficulty; result screen with Cores earned. A separate lobby place with matchmaking comes with phase 7 | **Done, confirmed in Studio** |
| **7** — battle modes | Team battle (sides, tower HP, per-team cash) and battle royale (most pops) — `VISION.md` | |

---

## 9. Verify in Studio

- [x] Phase 1 runs: map builds, towers fire, rounds advance, game ends around round 11 with
      the three hardcoded Scouts (confirmed 2026-09-28).
- [x] Round summary lines appear in Output with peak enemies and script cost.
- [x] Phase 2 economy: buying, selling (70%), kill and round income (confirmed with pads).
- [x] Phase 2 placement (confirmed 2026-09-28): ghost is green off-track and red on the track / overlapping / too far;
      the server refuses the same spots.
- [ ] Network stats during round 30+ with two clients (see §7).
- [ ] Mobile: enemy part count on a low-end device. Most Roblox players are on phones.
