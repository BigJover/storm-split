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
│   ├── Track.luau           Level layout: waypoints, pads, sizes. Hand-authored.
│   └── Path.luau            Distance-along-path math
├── server/   → ServerScriptService.Server
│   ├── Main.server.luau     Entry point and wiring. Only file that knows every module.
│   ├── MapBuilder.luau      Builds the map at runtime from Track
│   ├── Enemies.luau         Spawning, movement, damage, splitting, live cap
│   ├── Towers.luau          Placement, stats, crossover rule, targeting, firing
│   ├── Waves.luau           Runs the 40-round table
│   └── Lives.luau           Phase 1 stand-in; folds into Economy in phase 2
└── client/   → StarterPlayer.StarterPlayerScripts.Client
    └── Hud.client.luau      Round / lives / enemies label
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
| Lives *(phase 2: and cash)* | `Lives` → `Economy` | Call `lose()` / `TrySpend()` |
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

**5.3 One cash mutator (phase 2).** Every spend goes through `Economy.TrySpend()`, which checks
and deducts in one step. Four players clicking at once must not all pass the same check.

**5.4 Towers never charge money.** `Towers.upgrade()` applies an upgrade and nothing else. The
caller pays first. Keeps money logic in exactly one place.

---

## 6. Known mismatches to reconcile

- **Walk time.** The spreadsheet's round-length formula assumes 14s of walk time. The real
  track is ~610 studs at 14 studs/s ≈ **44s**. Measure in Studio, then fix the spreadsheet.
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
| **2** — cash, pads, shop | `Economy` (replaces `Lives`), `Shop` (RemoteEvents + validation), shop UI, `ProximityPrompt` on pads | Next |
| **3** — upgrade paths | Shop calls `Towers.upgrade()`; model swaps at tiers 3 and 5 | `canUpgrade()` done and tested |
| **4** — weapons and abilities | `Weapons` (Tools, server-validated hits), `Abilities` | |
| **5** — roster and rounds | Remaining towers' behaviours (Chiller slow, Quartermaster income) | Numbers already in `Config` |
| **6** — co-op, mastery, publish | `Progression` (DataStoreService), mastery effects, lobby | |

---

## 9. Verify in Studio

- [ ] Phase 1 runs: map builds, towers fire, rounds advance, game ends around round 11 with
      the three hardcoded Scouts (expected — that's the first difficulty spike).
- [ ] Round summary lines appear in Output with peak enemies and script cost.
- [ ] Network stats during round 30+ with two clients (see §7).
- [ ] Mobile: enemy part count on a low-end device. Most Roblox players are on phones.
