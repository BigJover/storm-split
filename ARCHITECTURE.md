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
| **Studio MCP server** | Lets Claude start playtests, run code in Studio and read the Output window — the write → run → read errors loop. Built into Studio (switch on Assistant Settings → Manage MCP Servers → "Enable Studio as MCP server"); `tools/studio/mcp.py` is the command-line way in (`tools`, `call <tool> '<json>'`), used by the Tester (`GAUNTLET.md`) |
| **`tools/export_constants.py`** | Spreadsheet → `src/shared/Config.luau` |
| **`tools/value.py`** | Tower value and pacing model; `--battle` prints how long a battle camp lasts per mode on Normal (typical and "competent" 1.5× builds; T91, #245). A report: it never edits the sheet |

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
│   ├── HeroStats.luau       A hero's gun and ability right now (base + mastery perks + upgrades), shared by
│   │                        server and client; which mastery perks a mastery level has (`Config.MasteryPerks`)
│   ├── GunRules.luau        Hero tier-6 gun rules: spread cone (still/scoped), Hot Swap reloads, Trick Reload,
│   │                        Five-Round Burst recoil reset, Endless Belt, ability charges; pure, server + client
│   ├── HeroXp.luau          Hero XP and levels in a match: round XP, take-down bonus and its cap, floor and
│   │                        ceiling, leavers, the HUD bar's numbers; pure
│   ├── TowerStats.luau      A tower's stats right now (base + upgrades); pure, used by Towers
│   ├── Pricing.luau         Upgrade discounts and sell refunds; pure, used by Shop
│   ├── Payouts.luau         Casual Amber payout at match end; pure, used by Progression
│   ├── Combat.luau          Dino attack scaling, resistance cap, tower max HP, repair cost, how marks merge
│   │                        (the stronger wins), nearest dinos to a point; pure
│   ├── SizeBreaks.luau      One health pool per dino with size thresholds; pierce-through breaks per hit; the boss pool bar's fill and notches
│   │                        (tier base + level bonus − species resist, capped); pure, used by Enemies
│   ├── SmallPerks.luau      Mastery small perks (levels 6-19): pick-up reach, round heal, respawn x, repair x
│   ├── ShopRules.luau       Which towers are for sale yet; placement and prompt distances
│   ├── Modes.luau           Game modes and tracks the home screen offers (availability, display); sides per mode
│   ├── BattleRules.luau     Battle modes: who may damage whom (every source family: hunter shots, towers,
│   │                        hazards, abilities, dinos; own side's dinos only), PvP damage x levers, Camo Cover,
│   │                        own-side support; lockstep rounds, side out, overtime HP,
│   │                        Team and Royale results (survivor bonus, tie-breaks); pure
│   ├── Matchmaking.luau     Side assignment in one server: sizes within 1, snake draft by Trophies; pure
│   ├── BattleFlow.luau      Battle match flow: seating (+ Studio stand-ins), camp names and feed lines,
│   │                        round rows + Final Stampede, side scale/cash, placements; pure
│   ├── Sides.luau           Map sides: per-side track copy, build zone, crossing strips, hunter spawn, per-side
│   │                        density and cap share; co-op = side 1 = today's map; pure, server + client
│   ├── Ledger.luau          Each side's cash and Fence as plain data (earn, trySpend, lose); pure, only Economy holds one
│   ├── SpawnQueue.luau      The capped spawn queue, one FIFO per side, sides take turns under the shared cap; pure,
│   │                        Enemies holds the only one
│   ├── Stakes.luau          Competitive buy-in: who may stake (offline, Practice), escrow/refund, pot,
│   │                        Team and Royale splits, casual battle payouts, settle; pure, for Progression
│   ├── Trophies.luau        Ranked Trophies: delta per mode/placement, arena floors, first-reach arenas; pure
│   ├── StudioOnly.luau      Studio-only test features (K/J/L, stand-ins, stand-in hunters, Start at round N,
│   │                        Stand-ins hold, stand-in towers pierce armour): the one gate the server asks
│   │                        with RunService:IsStudio(); refused in a live server; a grep spec catches new
│   │                        Studio keys that skip it; pure (T89, T91b, T93)
│   ├── SaveStore.luau       How Progression reads/writes its DataStore: every request an UpdateAsync with
│   │                        retries + backoff and the session lock checked against what's stored; the store
│   │                        is passed in, so tools/test/savestore.spec fakes throttles/conflicts; pure (T90)
│   ├── StandInHunter.luau   The Studio stand-in hunter's rules (100 HP, never shoots, damage via
│   │                        BattleRules.pvpDamage, respawn + Camo Cover; never saved/paid/ranked); pure (T93)
│   ├── RoundFlow.luau       The co-op round loop Waves.run drives: a round whose last dino breaks the Fence
│   │                        is a loss, never a clear (PLAYTEST F4); pure
│   ├── PanelRules.luau      Which panel may be open in which match state, and what a state change closes;
│   │                        the tower panel's "Tower level" line
│   ├── Bounties.luau        Daily Haul and bounty rules: roll, reset, progress, claim, swap, sanitise a save; pure
│   ├── Profile.luau         The saved profile as plain data and pure rules (load, save, Hunt Board paths);
│   │                        only Server/Progression holds profiles and calls it
│   ├── PlayerLevel.luau     The saved player level: curve, one match's player XP, reward tier; pure
│   ├── Cosmetics.luau       The player level's rewards: cosmetics and titles by level, equip checks; pure
│   ├── LevelBoard.luau      Level leaderboard rules: rows, own row, This-server fallback, write budget; pure
│   ├── TrophyBoard.luau     The Trophy board on LevelBoard's rules (live rows: Trophies can drop), arena badge; pure
│   ├── ProfileScreen.luau   What the Profile screen (P) and its Leaderboard tab draw; pure
│   ├── HomeLayout.luau      The home screen's bottom rows (Hunt Board row; hero · Unlocks · PLAY)
│   ├── HitNotice.luau       The private "what hit you" line beside your HP bar; pure
│   ├── StormCoil.luau       Storm Coil rules: chain hops, Power Grid scaling, Judgement Bolt, Rodeo; pure
│   ├── Falcon.luau          Falcon Roost rules: birds with travel time, dives, Eagle, Murmuration; pure
│   ├── Ballista.luau        Harpoon Ballista rules: volleys, Skewer lines, Tow Line, Chain Harpoons; pure
│   ├── TarPit.luau          Tar Pit rules: pool on the track, strongest pool, sinking, Eruption; pure
│   ├── DinoLook.luau        Blocky dino models per species and size (visual)
│   ├── Theme.luau           Title, currency and display names (Dino Hunters theme)
│   └── HuntBoard.luau       What the Hunt Board screen draws: tiles, cards, button states, text, fit-to-window
├── server/   → ServerScriptService.Server
│   ├── Main.server.luau     Entry point, wiring, and the match loop: Lobby → Building → Playing
│   │                        → GameOver/Victory → reset → Lobby. Spawns characters.
│   ├── MapBuilder.luau      Builds the map at runtime from Track
│   ├── Enemies.luau         Spawning, movement, damage, splitting, live cap; armour, stun,
│   │                        knockback, marks
│   ├── Towers.luau          Placement, stats, abilities (multi-shot, pierce, bomblets,
│   │                        burn, auras), targeting, firing
│   ├── Waves.luau           Runs the 40-round table (co-op); spawnRound() spawns one side's round
│   ├── Battle.luau          Runs a Camp Clash / Bone Rush match: sides, build phase, lockstep rounds,
│   │                        per-side pay and drops, elimination, results, the kill feed (T77)
│   ├── StandInHunters.luau  Studio only: a dummy hunter on each stand-in camp's plot for solo PvP tests (T93)
│   ├── Economy.luau         Each side's shared cash and lives (co-op: one side)
│   ├── Scoreboard.luau      Per-player pops on the Roblox leaderboard (leaderstats)
│   ├── Hero.luau            The player as hero: free pick, upgrade paths, magazine/reload, recoil,
│   │                        fire modes, pellets/pierce/ricochet, abilities — all validated here
│   ├── Hazards.luau         Burning patches on the track (towers and hero rounds)
│   ├── Airdrops.luau        Quartermaster chests players run over to collect
│   ├── DinoAttacks.luau     Dino bites and projectiles: per-dino timers, nearest standing tower or hunter in reach,
│   │                        projectiles as data (capped), landing hits (reads enemies only)
│   ├── Health.luau          The only mutator of player HP: setUp (max HP, spawn force field), damage (resist), heal
│   ├── Progression.luau     Saved per player: Amber, unlocks, hero mastery, highest round, and the Hunt Board
│   │                        (Daily Haul + bounties) (DataStore). Answers getRewards / claim / swap requests;
│   │                        `bountyEvent` is the one way in for match events
│   ├── Effects.luau         Tracers, blasts, burn discs (visual only)
│   ├── LevelBoard.luau      The level leaderboard: OrderedDataStore top 50, cache, budgeted writes
│   ├── TrophyBoard.luau     The Trophy leaderboard: LevelBoard.start on its own store, remote and cache
│   ├── Wardrobe.luau        The only adder/remover of worn cosmetics on characters (hat, sprint trail)
│   └── Shop.luau            The one validated RemoteFunction for build/sell; tower prompts
├── starter/StarterCharacterScripts → StarterPlayer.StarterCharacterScripts
│   └── Health.server.luau   Empty on purpose: replaces Roblox's health regeneration
└── client/   → StarterPlayer.StarterPlayerScripts.Client
    ├── Home.client.luau     Home screen (Lobby): mode cards (Co-op, Camp Clash, Bone Rush), track, difficulty,
    │                        Hunt Options (Casual/Ranked, camps, stand-ins), Play (host); Ready + Entry fee (every player)
    ├── Hud.client.luau      Status bar, Start button, hunter level + XP bar, level-up banner, result screen;
    │                        battles: camps board, kill feed, spectate / Final Stampede / Camo Cover banners, results card
    ├── Shop.client.luau     Build, hero select and hero upgrade screens; placement ghost; tower panel
    ├── HuntBoard.client.luau  Hunt Board (G, home screen): Daily Haul and bounties; claim and swap requests
    ├── Profile.client.luau  Profile screen (P, Lobby): player level, rewards, equip rows, Leaderboard tab
    ├── Looks.client.luau    Animated cosmetic sets on guns (visual only)
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
| Enemies (create / move / damage / remove; stun, disarm, chill, tar) | `Enemies` | Read `getLive()` and `isStunned` / `isDisarmed` / `slowFraction` / `isSlowed`, call `damage()`; a Tar Pit tars (`tar()`), sinks (`sink()`) and erupts (`dropSizes()`) through it, never by touching a dino |
| Dino attack timers and projectiles in flight (and the Storm Coil's Grounding Spike timers, which strike throws down) | `DinoAttacks` | — (it hurts towers and players only through `Towers.damage` / `Health.damage`; towers that can't be damaged are never in `Towers.targets()`) |
| A tower's tiers and stats | `Towers` | Call `upgrade()` after paying |
| A tower's HP and trampled state | `Towers` | Call `damage()` / `heal()` / `repair()` (after paying); dinos pick from `targets()`; clients read the body's `HP` / `MaxHP` / `KO` attributes |
| Cash and lives (the Fence), one pot per side (co-op = side 1; arithmetic in the pure `Shared/Ledger`) | `Economy` | Call `trySpendFor(side)` / `earnFor(side)` / `loseFor(side)` (the side-less `trySpend()` / `earn()` / `lose()` are side 1); clients read their side's `Cash` / `Lives` attributes (`Shared/Sides.attr`: side 1 `Cash`, side n `Cash<n>`) |
| Player HP (the Humanoid's Health / MaxHealth) | `Health` | Call `damage()` / `heal()` / `healAll()`; an enemy hunter's shot goes through `pvpHit()` (Hero, after `Shared/BattleRules.pvpDamage`, which is 0 under Camo Cover: `camoCover()`); clients read the Humanoid |
| What a tower cost (for refunds) | `Shop` | — |
| Who built a tower, and its side | `Towers` (`tower.owner`, `tower.side`) | Shop reads them: only the builder sells; upgrades, repairs and sells only on your own side (`Sides.manageRefusal`); builds only in your zone with your side's cash |
| Pops per player | `Scoreboard` | Towers report kills through the `onPop` hook |
| A hunter's XP, pending pops and hero level (per match, never saved) | `Hero` (rules in the pure `Shared/HeroXp`) | Main calls `Hero.addPop()` on every credited pop, `Hero.roundCleared(index, solo)` when a round is cleared (solo = one hunter present then: that round's take-downs count ×2 toward player XP, DECISIONS #177) and `Hero.startMatch()` at Start; clients read the `HeroLevel`, `HeroXp`, `HeroXpPending` player attributes |
| Tower level (the round level) and rounds cleared | `Main` | Main calls `Towers.setLevel(HeroXp.roundLevel(...))`; clients read the `Level` and `RoundsCleared` attributes on ReplicatedStorage |
| Match state (`State`), mode, track, difficulty, host | `Main` | Clients read the attributes; the host changes mode/track/difficulty through the `Lobby` remote, in the Lobby only |
| A battle's sides: each hunter's `Side`, camp names, who is out, placements | `Battle` (rules in the pure `Shared/BattleFlow` / `Shared/BattleRules`) | Clients read `Side` / `Out` / `BattlePlace` / `BattleBones` player attributes and `Camp<n>` / `Out<n>` / `Place<n>` / `BattleMode` / `Overtime` on ReplicatedStorage (`Shared/Sides.attr`); Shop and Hero refuse a hunter whose side is out |
| A player's hero, upgrades, ammo, recoil, cooldown, Overdrive | `Hero` | Clients read `Hero`, `HeroPath1-3`, `Ammo`, `Magazine`, `ReloadUntil`, `AbilityReadyAt` player attributes; Towers ask `Hero.towerRateBoost` |
| Burning patches | `Hazards` | Towers and Hero call `Hazards.burn()` |
| Current round | `Waves` | Read the `Round` attribute |
| Saved progression: Cores, owned heroes/towers, mastery, highest round, player XP and equipped cosmetics (`Shared/PlayerLevel`, `Shared/Cosmetics`; read/written only through `Shared/SaveStore` under a session lock `{session, at}` in the record: a server loads a save only if it's free, its own or stale (`Profile.LOCK_STALE` 600 s), writes only while it holds it, refreshes every 120 s, releases on leave/BindToClose (T90); Main reports each hunter's match XP through `addPlayerXp` at match end; XP for a save still loading is held and added once it loads, dropped if it fails) | `Progression` | Hero asks `ownsHero` and reads mastery; Shop asks `ownsTower` (placing only); buying only outside a match; equipping through `ProgressRequest` ("equip", slot, id), checked against the level, any time; everyone reads the `Equip_<slot>` and `PlayerXp` player attributes |
| The level leaderboard (OrderedDataStore of player XP, its 60 s cache) | `LevelBoard` (rules and the tick in the pure `Shared/LevelBoard`) | Reads the `PlayerXp` / `SaveStatus` attributes Progression publishes; clients ask the `LevelBoard` remote (answered from the cache, never a store request); unpublished, Studio or failing → "This server". `Scoreboard` shows each hunter's player level and title on the player list |
| Cosmetics worn on the character (hunting hat, sprint trail) | `Wardrobe` | Reads `Equip_hat` / `Equip_trail`; the gun look and tracers are `Hero`'s (`Hero.lookChanged` via Progression's hook), the crosshair and hit-marker `Hero.client`'s, a set's animation `Looks.client`'s, the tower flag `Towers`' (at placing). Looks only: no collision, hit or touch, no mass |
| Ranked state on the profile: `trophies`, `bestArena`, the Entry-fee `escrow` `{matchId, amount}` (taken at Building and saved at once; settled and cleared in one save; refunded on BindToClose or on a load that finds it unsettled); Practice Hunt Amber when unpublished | `Progression` (rules in the pure `Shared/Stakes`, `Shared/Trophies`, `Shared/Profile`) | `Battle` reports the result; the `Lobby` remote's `ready` is checked by `Stakes.canStake`; a Ranked leaver's forfeit and last-place Trophies land in one save; `TrophyBoard` reads the published Trophies; stand-ins and mid-battle joiners never touch it |
| The Trophy leaderboard (OrderedDataStore, live rows) | `TrophyBoard` (rules in the pure `Shared/TrophyBoard`, on `LevelBoard`'s pattern) | Clients ask its remote; unpublished → "This server" |
| Hunt Board state: Daily Haul day, active bounties, progress, swaps (the profile's `rewards` field) | `Progression` (rules in the pure `Shared/Bounties` and `Shared/Profile`) | Main, Shop and Hero report match events through `Progression.bountyEvent()`; the client asks with `getRewards` / claim / swap on `ProgressRequest` and reads `RewardsClaimable` / `RewardsVersion`; claims and swaps only in the Lobby |
| Which client panel is open | `Shop.client` (allowed states in `Shared/PanelRules`) | `Home.client`, `HuntBoard.client` and `Profile.client` ask through the `OpenPanel` attribute; `HuntBoard.client` shows its board while `HuntBoardOpen` is set, `Profile.client` the Profile screen while `ProfileOpen` is set |

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
Phase 7 (T75): `Enemies.enqueue(side, key, hpMult)` queues per side (`Shared/SpawnQueue`); the
cap stays shared, each side up to its even share, and every dino carries its `side`. Co-op is
one side, so the queue behaves exactly as before.

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
| **5b** — levels | Heroes +25% and towers +10% damage per level, a level every 5 rounds cleared (`HEROES.md`). Since round 3 each hunter's level comes from hero XP; towers keep this curve | **Done, confirmed in Studio** |
| **6** — progression | `Progression`: DataStore save (Cores, owned heroes/towers, mastery per hero, highest round; failed loads never overwrite). Casual payouts (clear reward per difficulty; multiplayer loss 5; solo loss 0). Core unlocks: Pistol + Scout/Sniper/Grenadier free; Rifle/Shotgun 75, Chiller 100, Quartermaster 150; place only what you own, upgrade anyone's. Mastery screen (M). Deferred: level 10/15 ability variants; competitive buy-ins/pots (phase 7) | **Written 2026-09-29, statically checked**, not yet playtested; saving needs the place published |
| **6b** — home screen | Match loop in `Main` (Lobby → match → results → reset → Lobby), no characters until Play, host picks mode (Co-op; Team Battle / Battle Royale shown as coming soon), track and difficulty; result screen with Cores earned. A separate lobby place with matchmaking: phase 8, after publishing (#240) | **Done, confirmed in Studio** |
| **Step 2** — the dinos fight back | `Combat` (pure rules), `Health` (player HP), `DinoAttacks` (bites and projectiles), tower HP / Trampled / repair / auras in `Towers`, Field Medic (`Hero`), Field Hospital and Armory towers, med kits (`Airdrops`), Rescue Beacon respawn (`Main`). The polish pass adds `tools/test.sh` (Lune specs), `audit.py`, `threat.py` | **Written 2026-10-01, statically checked + 130 headless specs**, not yet playtested (`RECAP.md`) |
| **Round 2** — balance pass, Daily Haul and Bounties | Balance: `tools/value.py` (value and pacing models), Supply Camp tiers, Rounds counts for rounds 7–12, 17–20 and 31–39 (spreadsheet only). Hunt Board: `Daily Haul` and `Bounties` sheets with exporter checks, `Shared/Bounties`, `Shared/Profile`, rewards in `Progression`, `Shared/HuntBoard` + `HuntBoard.client`, `PanelRules` mode `huntBoard`. `tools/studio/mcp.py` talks to Studio's MCP server for the Tester | **Written 2026-10-01, statically checked + 214 headless specs**, not yet playtested (`RECAP.md`, "Round 2"); Studio playtest T31 open |
| **Round 3** — mastery ability perks, hero XP | `Mastery Perks` sheet (one row per hero and mastery level) and Tuning HERO XP / MASTERY PERKS levers, with exporter rules (level 15 worth more than level 10, worth cap, no extra stun) and audit checks; perks merged by `HeroStats.compute(…, masteryLevel)`; Spare Dart and Smoulder in `Hero`; `Combat.mergeMark`; `Shared/HeroXp`, per-hunter XP and level in `Hero`, towers on the round level; HUD XP bar and banners; `value.py` and the hero-vs-tower guard use the level in play (`PLAN.md` round 3, `DECISIONS.md` #97–#117) | **Written 2026-10-02, statically checked + headless tests** (245 specs), not yet playtested |
| **Round 4** — Jovan's answers (`DIRECTION.md` 2026-10-02) | Renames (Bones, Fence, Big Bore); Linebreaker ×2; per-difficulty `Starting cash` (Hard 850); home-screen rows (`HomeLayout`); softer boss throws; one health pool + pierce-through (`SizeBreaks`) and the boss notched bar; Chaos = gun skill (towers ×0.6, hero ×1.5); mastery small perks (`SmallPerks`); hero tier 6 (`GunRules`); saved player level (`PlayerLevel`), cosmetics and titles (`Cosmetics`, `Wardrobe`, `Looks.client`), Profile screen (`ProfileScreen`, `Profile.client`), level leaderboard (`LevelBoard`, This-server fallback); four new towers (`StormCoil`, `Falcon`, `Ballista`, `TarPit`; can't-be-damaged and on-track placement in `Combat`/`Placement`); `value.py` worth bars and Tar Pit control line (`PLAN.md` round 4, `DECISIONS.md` #118–#206) | **Written 2026-10-02 → 10-06, statically checked + 406 headless specs**, not yet playtested (`RECAP.md`, "Round 4"); Studio playtests T31/T38/T60/T70 open |
| **7** — battle modes | Camp Clash (team battle) and Bone Rush (battle royale): `Sides` (track copies, zones, crossing strip), per-side `Economy` (`Ledger`) and spawn queue (`SpawnQueue`), `BattleRules` (damage permission per source, PvP levers, Camo Cover, lockstep, results), `BattleFlow` + `Server/Battle` (seating, Studio stand-ins, elimination, Final Stampede), `Matchmaking` (one server, snake draft by Trophies), `Stakes` (Entry fee, escrow, Amber Hoard, Practice Hunt) and `Trophies` (arenas) applied by `Progression`, `TrophyBoard` (shared + server), `RoundFlow` (F4), home/HUD/results/Profile Trophies screens, value.py perk-parity bar (`PLAN.md` phase 7, `DECISIONS.md` #208–#243) | **Written 2026-10-06 → 10-08, 587 headless specs, playtested solo in Studio** (PLAYTEST Runs 2–3 with stand-in camps; Run 4 re-checks T86b). Multi-client steps: Jovan's script (`RECAP.md` "Phase 7"); real stakes, saved Trophies, world boards: need publishing |
| **8** — ready to publish | Batch 1 (done): publish checklist + multi-client guide (`SETUP.md`); `StudioOnly` gate for every Studio cheat; `SaveStore` + session lock with a fake-store spec; `value.py --battle`; `Tuning!B143` battle rounds 60 → 120 s; Tectonic Slam ×34; Studio stand-in hunter (`StandInHunter`, `Server/StandInHunters`), Start at round N, Stand-ins hold. Waiting on Jovan: private publish + published smoke (T94–T95), lobby place with TeleportService + MemoryStore by Trophies (T96), the 4×-Amber towers (T97), battle length (T98) (`PLAN.md` "Phase 8", #238–#248) | **Batch 1 built 2026-10-08, 619 headless specs, playtested in Studio** (Run 5: 23 pass, 0 fail; N7 test aid open). Live saves, the lock and cross-server boards need the place published |

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
