# Storm Split — Verse Architecture

Companion to `Storm-Split-Design-Doc.pdf` (what the game is) and
`Storm-Split-Balance.xlsx` (what the numbers are). This file is **how the code is shaped**.

> **Read this first.** Every type sketch below is *design*, written in a Verse-flavored
> pseudocode. It is **not compilable Verse** and the syntax has not been verified against a
> compiler. Verse has very little public training data and every LLM — this one included —
> invents plausible-looking Verse APIs with total confidence. Treat every device name, method
> signature and type below as a claim to check against
> [dev.epicgames.com](https://dev.epicgames.com/documentation/fortnite/verse-api) before you
> rely on it. The *structure* here is sound; the *spelling* is not guaranteed.

---

## 1. Module layout

Twelve modules. The boundary rule: **one concern, one owner, one mutator.** If two modules can
write the same state you will spend Phase 3 debugging ghosts.

```
Storm_Split/
├── constants.verse      GENERATED from the spreadsheet. Never hand-edit.
├── types.verse          Shared structs and enums. Zero logic, zero imports.
│
├── track.verse          Nav points, spawn origin, exit volume, leak detection.
├── enemies.verse        Tier registry, spawning, the split chain, the live-NPC cap.
├── waves.verse          Round table, round start/end, spawn pacing.
│
├── economy.verse        THE ONLY MODULE THAT MUTATES CASH. Also owns lives.
├── towers.verse         Tower definitions, path/tier tables, per-instance state machine.
├── tower_pad.verse      Placement slots, interaction triggers, sell/upgrade entry points.
│
├── player.verse         Weapon tier state, weapon grants, the three abilities.
├── progression.verse    Persistable data: Storm Cores, mastery levels, unlocks.
│
├── ui.verse             HUD (cash, lives, round, cooldown) and the shop panel.
└── director.verse       Match lifecycle. Wires everything. The only module that knows all others.
```

**Dependency direction is strictly downward.** `types` and `constants` import nothing.
`director` imports everything. Nothing ever imports `director`. If you find yourself wanting a
back-reference, you want an event instead.

---

## 2. Core data structures

### types.verse

```
# An enemy tier in the splitting ladder.
enemy_tier := struct:
    Id          : string          # "HUSK", "BRUTE", "SHIELD", "ARMOR", "STORM", "LLAMA", "ZEP", "BARGE"
    Display     : string
    BaseHP      : float
    SpeedMult   : float
    SplitsInto  : string          # child tier Id, or "" for terminal
    SplitCount  : int
    Flying      : logic
    CashValue   : int             # from the spreadsheet's Effective HP column

# A single upgrade step on one of a tower's three paths.
tower_tier := struct:
    Cost        : int
    DamageMult  : float
    RateMult    : float
    TargetsMult : float
    SwapsSkin   : logic           # true only at tiers 3 and 5 — see §5

tower_path := struct:
    Id          : string          # "Range", "Rate", "Damage", "Pierce", ...
    Focus       : string
    Tiers       : []tower_tier    # exactly 5

tower_def := struct:
    Id          : string          # "SCOUT", "SNIPER", "GRENADIER", "CHILLER", "QUARTERMASTER"
    BaseCost    : int
    BaseDamage  : float
    BaseRate    : float
    BaseTargets : int
    Range       : float
    HitsAir     : logic
    IncomePerRound : int          # Quartermaster only; 0 for everything else
    Paths       : []tower_path    # exactly 3

# One round of the 40-round table.
round_entry := struct:
    Number   : int
    Counts   : [string]int        # tier Id -> how many spawn
    SpawnGap : float              # seconds between spawns
    HPMult   : float              # the compounding round ramp
```

### towers.verse — the instance

This is the most important class in the project. Get it right in Phase 3 and the rest is content.

```
tower_instance := class:
    var Def           : tower_def
    var PathTiers     : []int      # exactly 3 entries, current tier per path, starts [0,0,0]
    var Pad           : tower_pad
    var Npc           : ?agent     # the spawned NPC — a VIEW, never the source of truth
    var CashInvested  : int        # for sell refund

    # Derived, never stored:
    EffectiveDamage() : float      # BaseDamage * product of DamageMult across all owned tiers
    EffectiveRate()   : float
    EffectiveTargets(): float
    CanUpgrade(PathIndex : int) : logic    # enforces the crossover rule — see below
```

**The crossover rule, in one function.** This is the single piece of logic most likely to be
written wrong:

```
CanUpgrade(PathIndex) =
    Current  := PathTiers[PathIndex]
    if Current >= 5: return false

    Others   := every path index except PathIndex
    MaxOther := max tier among Others
    NonZero  := count of Others with tier > 0

    # At most two paths may be non-zero at all.
    if Current = 0 and NonZero >= 2: return false

    # Only one path may exceed tier 2.
    if Current >= 2 and MaxOther >= 3: return false

    return true
```

Mastery level 20 raises the `>= 3` cap to `>= 4` for one weapon only — but that applies to the
**player's weapon paths**, not towers. Towers keep the strict rule always.

### player.verse

```
player_state := class:
    var WeaponTiers   : []int      # 3 entries: Precision, Sustained, Ordnance
    var AbilityReady  : []float    # cooldown remaining per ability
    var Mastery       : []int      # 3 entries, loaded from persistence, read-only in-match
    var Cores         : int        # read-only in-match; awarded at match end
```

---

## 3. Who owns what

| State | Sole owner | Everyone else |
|---|---|---|
| Cash balance | `economy` | Calls `TryySpend(Amount)` which returns success/failure |
| Lives | `economy` | Calls `Leak(Count)` |
| Live enemy list | `enemies` | Subscribes to `EnemyDied` / `EnemyLeaked` |
| Current round | `waves` | Subscribes to `RoundStarted` / `RoundCleared` |
| A tower's tier state | its `tower_instance` | Goes through `tower_pad` |
| Saved progression | `progression` | Reads a snapshot at match start only |

**The one rule that prevents most bugs:** no module reads another module's mutable state
directly. It subscribes to an event or calls a method that returns a copy. Shared mutable state
across twelve modules is how a two-person project stalls.

---

## 4. Event flow

```
director: match start
   └─> progression.Load()            reads 8 ints from persistable storage
   └─> mastery applied to player_state
   └─> economy.Init(StartingCash, StartingLives)
   └─> waves.Begin()

waves: round N starts
   └─> emits RoundStarted(N)
   └─> enemies.SpawnRound(RoundTable[N])    respects SpawnGap and the live cap

enemy dies
   └─> enemies.OnDeath(Tier, Position)
         ├─> economy.Award(Tier.CashValue)
         └─> if Tier.SplitsInto != "":  enqueue SplitCount children at Position

enemy reaches exit
   └─> track emits Leaked(Tier)
   └─> economy.Leak(1)
         └─> if Lives <= 0:  director.EndMatch(Survived: false)

all enemies dead and spawn queue empty
   └─> waves emits RoundCleared(N)
   └─> economy.Award(RoundBonusBase + RoundBonusPerRound * N)
   └─> quartermasters pay IncomePerRound
   └─> waves.Begin(N+1)

director: match end
   └─> progression.AwardCores(HighestRound)
   └─> progression.Save()
```

---

## 5. Five decisions that will bite you

### 5.1 The NPC is a view, not the state

Store everything in `tower_instance`. The spawned NPC is disposable and can be destroyed and
recreated at any time without losing anything. Write it this way and the open question from the
design doc — whether Verse can mutate a live NPC's weapon and stats, or whether you must
despawn and respawn — stops mattering. Either implementation drops into the same seam.

### 5.2 The split chain can spawn 244 enemies in one frame

Walk the ladder: a Storm Barge dies into 4 Loot Zeppelins, each into 4 Drifter Llamas (16),
each into 2 Shielded (32), each into 2 Brute (64), each into 2 Husk (128). That is **244
descendants from one death**, and if your DPS is high they cascade almost simultaneously.

You must have a **spawn queue with a hard live-NPC cap** (`MaxConcurrentEnemies`, currently 130
in the spreadsheet). When a split would exceed the cap, the children wait in the queue and
spawn as slots free up. Without this, round 40 crashes the session.

This is not a polish item. Build the queue in Phase 3, the same day you build splitting.

### 5.3 Validate the split table at startup

A tier that splits into itself, or a cycle anywhere in the ladder, is an infinite loop. On
startup, walk every tier's chain and assert it terminates within 10 hops. Ten lines of code,
and it turns a hang into a readable error.

### 5.4 Constants are generated, never edited

`constants.verse` carries a header saying so. The moment someone hand-tweaks a number there,
the spreadsheet stops being the source of truth and you have two disagreeing copies of the
balance — which is the exact fight §08 of the design doc exists to prevent.

Regenerate with `tools/export_constants.py`.

### 5.5 One cash mutator

Four players sharing a wallet means every purchase is a race. Route every spend through a
single `economy.TrySpend()` that checks and deducts in one step. Do not let a module read the
balance, decide, and then deduct — two players clicking at once will both pass the check.

---

## 6. Build order, mapped to modules

Phases are from §07 of the design doc. Build modules in this order and every phase ends with
something playable.

| Phase | Modules | Deliberately absent |
|---|---|---|
| **1** — one tower, one enemy, one track | `types`, `track`, `enemies` (spawn only, no splitting), `waves` (hardcoded single round) | No economy, no UI, no upgrades. Hardcode the tower. |
| **2** — cash, pads, shop | `economy`, `tower_pad`, `ui` (shop + HUD) | Still one tower type, still no upgrade paths. |
| **3** — upgrades and splitting | `towers` (full instance + crossover), `enemies` (split chain + spawn queue) | The hardest phase. Everything after is content. |
| **4** — weapons and abilities | `player` | In-round track only. No mastery yet. |
| **5** — roster and rounds | `constants` fully populated from the spreadsheet | Mostly authoring, not engineering. |
| **6** — co-op, mastery, publish | `progression`, `director` (match lifecycle, end states) | Mastery balanced against numbers already settled. |

---

## 7. Week-one verification checklist

Before writing anything on top of these assumptions, confirm each in the editor. Every one of
them changes the code if it comes back false.

- [ ] How many NPCs can UEFN path simultaneously before frame time degrades? The spreadsheet
      assumes **130**. This is the single most load-bearing guess in the project.
- [ ] Can a spawned NPC's weapon, health and speed be changed at runtime, or is
      despawn/respawn required?
- [ ] Can an NPC Character Definition be swapped on a live NPC?
- [ ] Does an NPC spawned mid-round path correctly to nav points from an arbitrary position
      (needed for split children appearing mid-track)?
- [ ] What is the actual persistable-data size and write-frequency limit?
- [ ] Can Verse UMG render a shop panel with per-player state in co-op?
- [ ] Does team index reliably stop towers from targeting players?

Answer these first. Several of them can invalidate a design decision, and finding that out in
week one costs a day — finding it out in Phase 3 costs a rewrite.
