# The next tower batch — PROPOSAL

> **PROPOSAL — not to be built until Jovan picks.** Director, 2026-10-02 (DECISIONS #140).
> Jovan: "we need more towers, the next batch needs to be 2x the cost but worth it (some
> that dont take damage) (lightning chaining abilities reaching all dinos on the field at
> once)… ask for more input on highest tier towers but come with some ideas".
> Tower and tier names are **working names**: the Dino agent (🦖) does the dino-flavoured
> naming once Jovan has picked. Numbers are rough seeds; the spreadsheet and the models
> settle them when a tower is built.

Same format as `UPGRADES.md`: three named paths × five tiers; tiers in *italics* grant a new
ability. For each tower's **tier 4 and tier 5** there are several options (A, B, C…) — pick
one per slot, mix, or say "none of these".

## Price: what "2× the cost" means here

| | Today's batch | This batch |
|---|---|---|
| Amber unlock | 75–150 (Tranq 100, Supply 150, Hospital 100, Armory 150) | **200–300** |
| In-match price | Blind 200 … Armory 600, Supply 1,000 | about **2× the nearest existing tower** |

All four together: 1,050 Amber (today's whole unlock list is 725). **Worth it** means each
does something no current tower can: hit every dino at once, never need a repair, sink dinos
outright, or drop several sizes in one shot (pierce-through, PLAN round 4).

| Tower | Role | Amber | Cash | Takes damage? |
|---|---|---|---|---|
| Storm Coil | chain lightning, crowds and air | 300 | 1,100 (2× Mortar Pit) | yes |
| Falcon Roost | birds of prey, roams a huge radius | 200 | 700 (2× Longshot Perch) | **no** |
| Tar Pit | zone control: slows and sinks small dinos | 250 | 800 (2× Tranq Station) | **no** |
| Harpoon Ballista | the heaviest single hit; pierce-through | 300 | 1,100 | yes |

---

## Storm Coil — chain lightning (the "reach every dino" tower)

A copper coil on a tripod. Each strike hits one dino and **arcs** to the nearest other dino
within 10 studs, up to 4 arcs, each arc 80% of the last. Hits air. Can't hurt armour until
the Charge path. Breaks 1 size per hit (area damage never pierces through).
**Why 2×:** one strike hits five dinos with no line-up and no ground-only limit, and its top
tier can reach the whole field. **Weakness:** falloff per arc, normal HP, short own range (14).

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Chain** | more arcs, reach | Copper Coil (+2 arcs) | Long Arc (arc reach 15) | *Fork Lightning* (each arc may fork in two) | *see options* | *see options* |
| **Charge** | power, armour, stun | Capacitor (+30% damage) | Static Build-up (a struck dino takes +10% from the next strike) | *Thunderclap* (first target stunned 0.4s) | *see options* | *see options* |
| **Storm** | support, defence | Lightning Rod (range ×1.2) | Conductor (towers in range +10% attack speed) | *Grounding Spike* (every 4s strikes down one dino projectile aimed at a tower in range) | *see options* | *see options* |

**Chain T4:** A *Live Wire* — no falloff along the chain. B *Jumper* — arcs can jump from one
Storm Coil's range to another's.
**Chain T5 (the one Jovan asked for — all dinos on the field):**
- A **Storm Front** — every 8s a strike that chains to **every dino on the field** at 50%
  damage (1 size each). Simple, readable, the headline.
- B **Supercell** — the chain never ends while there's a dino within reach: it keeps
  arcing (no limit) and slows 20% for 1s. Reaches the whole field when dinos are bunched.
- C **Power Grid** — all Storm Coils on the map link into one net; a strike from any coil
  runs through every dino between them.
- D **Ball Lightning** — a slow orb rolls down the whole track every 10s, striking
  everything it passes.

**Charge T4:** A *High Voltage* — pierces armour, +40% damage. B *Overload* — every 5th strike
deals ×3 to its first target.
**Charge T5:**
- A **Judgement Bolt** — every 10s one huge bolt on the biggest dino: ×8 damage, **breaks 3
  sizes** (pierce-through), stuns bosses 0.5s.
- B **Superconductor** — every dino in the chain is stunned 0.3s (bosses 0.15s).
- C **Thunderhead** — a storm cloud parks over the toughest dino in range and strikes it
  every second until it dies.

**Storm T4:** A *Ion Field* — dinos in range take +15% from every tower. B *Storm Warning* —
towers in range +15% damage.
**Storm T5:**
- A **Eye of the Storm** — every 3s, a small strike (10% damage) on **every dino on the
  map**: a second way to "reach all dinos", as chip damage plus support.
- B **Lightning Rodeo** — towers in range chain their own shots once (each shot arcs to one
  more dino at 50%).
- C **Lightning Shield** — Grounding Spike catches every projectile aimed at towers in
  range, every 1s.

---

## Falcon Roost — can't be damaged

A tall perch with a falconer's hut. Two falcons fly to any dino within 40 studs, dive,
strike and come back (about 1.5s a round trip). Hits air and ground. **The roost and birds
can't be damaged**: dinos ignore it, it never gets trampled and never needs a repair.
**Why 2×:** zero upkeep all game, a huge radius, hits air. **Weakness:** travel time, low
damage per dive, no armour until Talons T4.

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Talons** | raw damage, pierce-through | Sharp Talons | Hooked Beak | *Stoop Dive* (first dive on a dino ×3, **breaks 2 sizes**) | *see options* | *see options* |
| **Flock** | more birds | Second Pair (4 birds) | Quick Return | *Cast of Six* | *see options* | *see options* |
| **Falconer** | support | Jesses (+10% range) | Bells (a struck dino takes +10% for 2s) | *Hooded Scout* (bosses in range marked +25%) | *see options* | *see options* |

**Talons T4:** A *Iron Talons* — pierce armour, breaks 3. B *Raking Strike* — each dive
also hits one dino next to the target.
**Talons T5:**
- A **Harpy Strike** — dives break 4 sizes and deal ×2 to bosses.
- B **Carry Off** — every 5s a falcon grabs the smallest dino in range (any species, not a
  boss, at its last size) and carries it off the track: an instant take-down.
- C **Eagle of the Peak** — the flock is replaced by one giant eagle: slow, huge dives
  (×6), stuns what it hits 0.5s.

**Flock T4:** A *Wide Circle* — radius 60. B *Pack Hunting* — birds focus one dino together
for +30%.
**Flock T5:**
- A **Murmuration** — a swarm of 12 small birds pecks every dino in range continuously.
- B **Sky Hunters** — the birds hunt anywhere on the map (global range).
- C **Mixed Mews** — falcons for air, hawks for ground; each ×1.5 on its own kind.

**Falconer T4:** A *Lure* — dinos struck are pulled 2 studs back (not bosses). B *Spotter's
Eye* — hunters in range see every dino's outline through walls.
**Falconer T5:**
- A **Master Falconer** — hunters in range deal +15% and their shots mark for 1s.
- B **Sentinel Birds** — the birds catch one projectile aimed at a tower or hunter in range
  every 3s.
- C **Hunting Party** — towers in range +15% attack speed while any bird is diving.

---

## Tar Pit — can't be damaged

Dug **beside the track** (the one tower that must touch it — a placement-rule exception),
it floods a 12-stud stretch with tar. Dinos wading through are slowed 25%, and a dino at its
**last size** that stays in the tar for 3s **sinks** (a take-down; not bosses, not
Pteranodons). **Can't be damaged:** it's a hole in the ground. **Why 2×:** works on every dino
that passes, all game, no repairs, and it gets better the more dinos there are.
**Weakness:** no damage on its own until Bubbling, no air, one stretch of track.

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Deep Tar** | slow and sink | Thick Tar (35%) | Wide Pool (18 studs) | *Sucking Mire* (last-size dinos sink in 1.5s) | *see options* | *see options* |
| **Bubbling** | damage | Warm Tar (small damage per second) | Simmer | *Boiling Pit* (burning tar; burn ticks break 1) | *see options* | *see options* |
| **Bone Yard** | cash and support | Pick and Shovel (+cash per sink) | Fossil Hunter (+cash) | *Amber Seep* (each sink drops a small chest, like Air Drop) | *see options* | *see options* |

**Deep Tar T4:** A *Deeper Pit* — dinos at their last **two** sizes sink. B *Clinging Tar* —
dinos leaving stay slowed 3s.
**Deep Tar T5:**
- A **La Brea** — any non-boss dino at its last size sinks on contact; bosses slowed 40%.
- B **Tar Lake** — the pool covers three times as much track.
- C **Fossil Trap** — each sunk dino leaves a fossil that stops the next dino for 1s.

**Bubbling T4:** A *Pitch Fire* — dinos leave the pit burning (passes down as they shrink,
like Dragon's Breath). B *Fumes* — dinos in the pit can't bite or shoot.
**Bubbling T5:**
- A **Eruption** — every 8s a geyser of burning tar hits everything in the pool and
  **breaks 2 sizes**.
- B **Ever-Burn** — burning lasts 4s after leaving and spreads to dinos they touch.
- C **Asphalt** — a press of the panel button hardens the pool: everything in it is frozen
  1.5s (cooldown 20s).

**Bone Yard T4:** A *Museum Grant* — round income +200. B *Sticky Trail* — dinos leaving
leave tar footprints that slow the ones behind 15%.
**Bone Yard T5:**
- A **Dig Site** — each round pays cash per dino sunk this round.
- B **Preserved Specimens** — sunk dinos pay double cash.
- C **Tar Totem** — towers in range +15% damage against slowed dinos.

---

## Harpoon Ballista — raw damage and pierce-through

A heavy crossbow on a turntable. Slow (one bolt every 2.5s), very heavy bolts that pin.
Ground and air. **Why 2×:** the biggest single hit in the game with pierce-through built into
its main path (one bolt can drop a dino 2–4 sizes, PLAN round 4); pins dinos in place.
**Weakness:** slowest fire, normal HP, wastes shots on Compys.

| Path | Focus | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| **Barbed** | raw damage, breaks | Steel Head | Barbed Tip | *Bone Splitter* (**breaks 2**) | *see options* | *see options* |
| **Chain Line** | control | Rope Line | Winch | *Pin Down* (hit dino held 1s, not bosses) | *see options* | *see options* |
| **Volley** | more bolts | Twin Bow | Fast Crank | *Spread Volley* (3 bolts) | *see options* | *see options* |

**Barbed T4:** A *Whale Iron* — pierces armour, **breaks 3**. B *Serrated* — the hit dino
takes +20% from everything for 3s.
**Barbed T5:**
- A **Leviathan Bolt** — **breaks 4**, ×3 vs bosses.
- B **Skewer** — the bolt passes through every dino in a line; each breaks 2.
- C **Heartseeker** — always targets the biggest dino on the map (global), breaks 3.

**Chain Line T4:** A *Reel In* — drags the hit dino 6 studs back. B *Tether* — pins last 2s.
**Chain Line T5:**
- A **Anchor Line** — tethers a dino to the ground 3s; bosses slowed 50%.
- B **Tow Line** — every 15s pulls a boss 10 studs back.
- C **Clothesline** — a rope strung between two Ballistas trips every dino that crosses it.

**Volley T4:** A *Auto-Crank* — fires twice as fast. B *Fire Bolts* — bolts set dinos alight.
**Volley T5:**
- A **Siege Battery** — 6 bolts per volley.
- B **Rain of Spears** — every 5s spears rain on a 10-stud circle of track.
- C **Chain Harpoons** — pairs of bolts linked by chain hit everything between them.

---

## What Jovan needs to pick

1. **Which towers** (all four, or which ones). Are three enough for one batch?
2. **For each tower, one option per tier-4 and tier-5 slot** (or "none of these").
3. **Storm Coil:** Storm Front (A, every 8s, the whole field) is the plain reading of
   "reaching all dinos on the field at once". Is chip damage on the whole map (Storm T5 A)
   a second one you want, or one is enough?
4. **"Can't be damaged":** Falcon Roost and Tar Pit. Should they be weaker in raw numbers to
   pay for it (proposed), or fully priced by the 2× cost alone?
5. **Tar Pit touches the track** (an exception to the placement rule). OK?
6. **Price:** 200–300 Amber and about 2× in-match cash. Right reading of "2x the cost"?
