# Storm Split — Roblox Architecture

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
│   ├── TowerLook.luau       Tower models, shared by real towers and the placement ghost
│   └── ShopRules.luau       Which towers are for sale yet; placement and prompt distances
├── server/   → ServerScriptService.Server
│   ├── Main.server.luau     Entry point and wiring. Only file that knows every module.
│   ├── MapBuilder.luau      Builds the map at runtime from Track
│   ├── Enemies.luau         Spawning, movement, damage, splitting, live cap
│   ├── Towers.luau          Placement, stats, crossover rule, targeting, firing
│   ├── Waves.luau           Runs the 40-round table
│   ├── Economy.luau         The team's shared cash and lives
│   └── Shop.luau            The one validated RemoteFunction for build/sell; tower prompts
└── client/   → StarterPlayer.StarterPlayerScripts.Client
    ├── Hud.client.luau      Round / cash / lives / enemies label, Start button
    └── Shop.client.luau     Build button, placement ghost, sell panel (requests only)
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
| Enemies (create / move / damage / remove) | `Enemies` | Read `getLive()`, call `damage()` |
| A tower's tiers and stats | `Towers` | Call `upgrade()` after paying |
| Cash and lives | `Economy` | Call `trySpend()` / `earn()` / `lose()` |
| What a tower cost (for refunds) | `Shop` | — |
| Current round | `Waves` | Read the `Round` attribute |
| Saved progression *(phase 6)* | `Progression` | Snapshot at match start only |

**Server authoritative, always.** On Roblox the client is untrusted — exploiters can fire any
RemoteEvent with any arguments. The client *requests* ("upgrade the tower on pad 4, path 2");
the server checks the pad, the crossover rule and the cash, then acts. Never let the client
state a price, a damage number or a result.

---

## 5. Decisions already made in the code

**5.1 The live cap and spawn queue.** One Barge death cascades into 244 enemies. Nothing ever
spawns directly — everything goes through a queue that only drains while live enemies are under
`MaxConcurrentEnemies`. Split children get a priority queue so they are never stuck behind
fresh spawns. *Verified headlessly: 245 kills from one Barge, live count held exactly at the
cap, queue drained to zero.*

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
- **Range paths don't increase range.** The spreadsheet has no range-multiplier column, so
  the Scout's "Range" path only buffs damage and rate. Add a column when towers get tuned.
- **Fire rate ceiling.** Towers fire at most once per frame, so anything above ~60 shots/s is
  capped. Irrelevant until late upgrades.
- **Fortnite theming.** Husks, Loot Llamas and Storm Barges are Fortnite-flavoured names and
  should be replaced with an original theme. Internal keys (`HUSK`, `ZEP`…) can stay.

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
| **3** — upgrade paths | Shop calls `Towers.upgrade()`; model swaps at tiers 3 and 5 | Next. `canUpgrade()` done and tested |
| **4** — weapons and abilities | `Weapons` (Tools, server-validated hits), `Abilities` | |
| **5** — roster and rounds | Remaining towers' behaviours (Chiller slow, Quartermaster income) | Numbers already in `Config` |
| **6** — co-op, mastery, publish | `Progression` (DataStoreService), mastery effects, lobby | |

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
