#!/usr/bin/env python3
"""
Dino Hunters — value model (PLAN T18, DECISIONS #54/#59). A report: exits 0 unless it crashes.

The sheet's `Resulting DPS` can't tell a tower's paths apart (the multipliers track
1.9^tier), so this credits each tower tier with what the game really does against the
real wave mix. Reads the spreadsheet through the exporter (read_data), never Config.luau,
and never writes anything.

Reference wave mix: Easy, solo, by band (rounds 1-10, 11-20, 21-30, 31-40): each band's
share of effective HP (count x Effective HP x round HP x) that is plain ground, armoured,
flying and boss (the classes don't overlap on today's sheet).

Effective DPS of one path at one tier (the tower's stats are combined exactly like
Shared/TowerStats.compute, whose field lists are read from the Luau file):
  per shot   damage x (1 + Mark%) x (1 + Brittle%) x (hits + bomblets), where
             hits = Line hits if > 1 (the line ignores splash, as Server/Towers does), else
             Targets (the splash cap, a stand-in for how many it really catches), and
             bomblets = sum over generations g of (Bomblets x BombletDamage)^g, each blast
             catching one dino
  direct     rate x Shots x per shot x (plain + armoured x [pierces/strips] x Armoured x
             + flying x [hits air] + boss x Boss x)
  burn       Burn DPS x uptime min(1, rate x Shots x Burn seconds) x hits, ground only
             (armoured only if it pierces)
  freeze     Freeze damage / Freeze every x Targets (dinos in range stand-in)
  overkill   (PLAN T47, DECISIONS #128) direct damage only, per species and round in the
             band: a hit of damage D lands min(D, b x share), share = that species' size HP
             at the round's HP x (Easy), b = Shared/SizeBreaks' breaks for the tier at the
             round's tower level vs the species' Break resist (line or single target: the
             tier's Size breaks; splash and bomblets: 1). D is the hit as it lands: damage x
             mark x brittle x Armoured/Boss x, at the round's tower level (levels matter
             for overkill, so only the factor uses them). Each species-round is weighted by
             its share of the band's EHP. "before" = the old zero-waste number.
  aura       aura towers are credited with what their aura (rate %, damage %, pierces
             armour, Lightning Rodeo's arc) adds to 3 neighbour T2 Hunting Blinds, one on
             each Blind path (a stated assumption). Stun, knockback and slow are not DPS:
             not credited.
  chain      (Storm Coil, PLAN T64) a strike = the first hit plus, for hop k = 1..Arcs,
             Arc forks dinos at Coil arc falloff^k, each breaking 1 (assumed: the dinos
             are close enough for every arc). Static Shock: x (1 + Static %) on every hit
             (assumed: a strike reaches the dinos the last one did). Judgement Bolt: + a
             x Judgement Bolt x hit every Judgement Bolt every s, breaking Judgement Bolt
             breaks (pierce-through, the tower level bonus too). Power Grid: + one grid
             strike every Power Grid every s at x Shared/StormCoil.grid(GRID_COILS)
             damage on as many dinos as a full strike reaches (assumed). Jump Spark and
             Grounding Spike are not DPS: not credited.
Levels scale every tower alike, so they're left out of the tower tables (except inside the
overkill factor). Heroes break 1 and hit small: their lines are left as they were.

Flags (DECISIONS #59), damage paths only:
  dead tier      marginal cash per marginal eDPS > 2x the median of all damage paths at
                 that tier, in the band it's typically bought (T1-2: 11-20, T3: 21-30,
                 T4-5: 31-40)
  dominant path  cost per eDPS < 0.5x the median at every tier in every band
Support and control paths (Lookout, Sedate, Knockout, Weak Spot, Armory, Field Hospital,
Supply Camp) get their own value line instead and are left out of the medians. Knockout's
line is the share of time dinos in range are stopped; Weak Spot's credits its Brittle % and
auras on the 3 neighbour Blinds as well as its own darts. A single control tier on a damage
path (Concussion Round's stun) is noted and never flagged (DECISIONS #74).
Economy payback is in rounds of Easy income.

Usage:
    python3 tools/value.py           the value report (<= ~120 lines)
    python3 tools/value.py --full    every band's cost per eDPS, every tower
    python3 tools/value.py --overkill  eDPS before (zero-waste) -> after (overkill counted),
                                     every damage path's T4-T5 in every band (PLAN T47/T48)
    python3 tools/value.py --breaks1   Z / B1 (every break forced to 1) / S per raw-damage tier
                                     and the three break bars (PLAN T48 final, #160, #164-#166);
                                     exits 1 if a bar fails (tools/test.sh runs it)
    python3 tools/value.py --pacing  the pacing model (PLAN T19): the Balance Check's
                                     affordability per difficulty x 1/4/10 hunters (asserts
                                     it reproduces the sheet's Easy-solo column exactly),
                                     trampled-tower repair price vs income, Amber pace,
                                     and whether each bounty fits a match (PLAN T25)
"""

import contextlib
import io
import math
import os
import re
import statistics
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

import export_constants  # noqa: E402

BANDS = [(1, 10), (11, 20), (21, 30), (31, 40)]
BOUGHT_BAND = {1: 1, 2: 1, 3: 2, 4: 3, 5: 3}  # tier -> index into BANDS
# Support and control paths: judged on their own effect, not DPS (DECISIONS #59). #74 added the
# Tranq Station's Knockout (hard stops) and Weak Spot (damage amp for every tower in range).
SUPPORT_PATHS = {("SCOUT", "Lookout"), ("CHILLER", "Sedate"), ("CHILLER", "Knockout"), ("CHILLER", "Weak Spot"),
                 ("COIL", "Lightning Rod")}  # PLAN T64: Charged Air, Storm Warning, Lightning Rodeo
# Single tiers that buy control on a damage path (#74): still in the table and the medians,
# never flagged dead. Longshot Perch Big Bore T3 = Concussion Round (a stun on hit).
CONTROL_TIERS = {("SNIPER", "Big Bore", 3)}
# Boss specialists (#164): raw T5s whose job is a boss multiplier. `--breaks1` reports them on
# their own line and exempts them from bar 3 (the T5 median). Extinction Round = Big Bore T5.
BOSS_SPECIALIST = {("SNIPER", "Big Bore", 5)}
SUPPORT_TOWERS = {"QUARTERMASTER", "HOSPITAL", "ARMORY"}
# Towers on the sheet whose behaviour isn't built yet (the round-4 batch, PLAN T63-T67):
# left out of every table and median until their task models them. Each task removes its key.
PENDING_TOWERS = {"FALCON", "TARPIT", "BALLISTA"}
# Power Grid is credited as if this many Storm Coils stand (x1.0 damage, range x1.15; a
# stated assumption: the plain co-op case). One coil alone is x0.75, six x2.0 (#151).
GRID_COILS = 2
NEIGHBOUR_TOWER, NEIGHBOUR_TIER, NEIGHBOURS = "SCOUT", 2, 3
DEAD_X, DOMINANT_X = 2.0, 0.5


def load():
    with contextlib.redirect_stdout(io.StringIO()):
        data = export_constants.read_data(export_constants.DEFAULT_XLSX)
    TUNING.update(data["Tuning"])
    return data


# ---------------------------------------------------------------- tower stats

def _luau_list(text, name):
    body = re.search(r"local " + name + r" = \{(.*?)\}", text, re.S).group(1)
    return re.findall(r'"(\w+)"', body)


_TS = open(os.path.join(ROOT, "src", "shared", "TowerStats.luau"), encoding="utf-8").read()
MULTIPLIERS, HIGHEST, FLAGS = (_luau_list(_TS, n) for n in ("MULTIPLIERS", "HIGHEST", "FLAGS"))


def tower_stats(t, tiers):
    """Shared/TowerStats.compute: `tiers` is the tier bought on each path (0 = none)."""
    mult = {f: 1 for f in MULTIPLIERS}
    high = {"shots": 1, "lineHits": 1, "sizeBreaks": 1}
    flag = {}
    freeze_every = 0
    for path, tier in zip(t["paths"], tiers):
        if tier > 0:
            step = path["tiers"][tier - 1]
            for f in MULTIPLIERS:
                mult[f] *= step.get(f, 1)
            for f in HIGHEST:
                high[f] = max(high.get(f, 0), step.get(f, 0))
            for f in FLAGS:
                flag[f] = flag.get(f, False) or step.get(f) is True
            every = step.get("freezeEvery", 0)
            if every > 0 and (freeze_every == 0 or every < freeze_every):
                freeze_every = every
    return {
        "damage": t["baseDamage"] * mult["damageMult"],
        "rate": t["baseRate"] * mult["rateMult"],
        "targets": max(1, math.floor(t["baseTargets"] * mult["targetsMult"] + 0.5)),
        "shots": max(1, math.floor(high["shots"])),
        "lineHits": max(1, math.floor(high["lineHits"])),
        "sizeBreaks": max(1, math.floor(high["sizeBreaks"])),
        "hitsAir": t["hitsAir"],
        "pierces": flag.get("piercesArmor", False) or flag.get("stripsArmor", False),
        "armoredMult": mult["armoredMult"], "bossMult": mult["bossMult"],
        "markPercent": high.get("markPercent", 0), "brittlePercent": high.get("brittlePercent", 0),
        "burnDps": high.get("burnDps", 0), "burnSeconds": high.get("burnSeconds", 0),
        "bomblets": math.floor(high.get("bomblets", 0)), "bombletGenerations": math.floor(high.get("bombletGenerations", 0)),
        "freezeEvery": freeze_every, "freezeDamage": high.get("freezeDamage", 0),
        "freezeSeconds": high.get("freezeSeconds", 0), "freezeHoldsBosses": flag.get("freezeHoldsBosses", False),
        "stripsArmor": flag.get("stripsArmor", False), "stunSeconds": high.get("stunSeconds", 0),
        "auraRatePercent": high.get("auraRatePercent", 0), "auraDamagePercent": high.get("auraDamagePercent", 0),
        "auraPiercesArmor": flag.get("auraPiercesArmor", False),
        "slowPercent": max(t["slowPercent"], high.get("slowPercent", 0)), "slowLinger": high.get("slowLinger", 0),
        "slowsBosses": flag.get("slowsBosses", False),
        "incomeMult": mult["incomeMult"], "interestPercent": high.get("interestPercent", 0),
        "interestCap": high.get("interestCap", 0), "chests": math.floor(high.get("chests", 0)),
        "chestCash": high.get("chestCash", 0), "discountPercent": high.get("discountPercent", 0),
        "sellRefund": high.get("sellRefund", 0), "resistPercent": max(t["resistPercent"], high.get("resistPercent", 0)),
        "thornsDamage": high.get("thornsDamage", 0), "healPerSecond": t["healPerSecond"] * mult["healMult"],
        "revives": flag.get("revives", False), "medKits": math.floor(high.get("medKits", 0)),
        "medKitHeal": high.get("medKitHeal", 0), "auraHpPercent": high.get("auraHpPercent", 0),
        "rangeMult": mult["rangeMult"], "hunterRatePercent": high.get("hunterRatePercent", 0),
        "hunterReloadMult": mult["hunterReloadMult"],
        # Storm Coil (Shared/TowerStats: Tuning's arcs and reach unless a tier sets them)
        "chains": t.get("chains", False),
        "arcs": (math.floor(high.get("arcs", 0)) or int(TUNING["CoilArcs"])) if t.get("chains") else 0,
        "arcForks": max(1, math.floor(high.get("arcForks", 0))) if t.get("chains") else 0,
        "staticPercent": high.get("staticPercent", 0) if t.get("chains") else 0,
        "judgementBolt": bool(t.get("chains") and flag.get("judgementBolt", False)),
        "powerGrid": bool(t.get("chains") and flag.get("powerGrid", False)),
        "groundingEvery": high.get("groundingEvery", 0), "auraArcPercent": high.get("auraArcPercent", 0),
    }


TUNING = {}  # set by load(): Tuning levers tower_stats needs (the chain's defaults)


def grid_mult(tuning, n):
    """Shared/StormCoil.grid: Power Grid's (range x, damage x) for n standing Storm Coils."""
    coils = min(max(1, math.floor(n)), max(1, int(tuning["PowerGridCoilCap"])))
    return (1 + tuning["PowerGridRangePerCoil"] * (coils - 1),
            tuning["PowerGridDamageBase"] + tuning["PowerGridDamagePerCoil"] * coils)


def chain_pieces(s, tuning):
    """A chain strike's arcs as (dinos, share of the hit): hop k = Arc forks dinos at
    falloff^k (the first hit is the shot's own)."""
    if not s.get("chains"):
        return []
    f = tuning["CoilArcFalloff"]
    return [(s["arcForks"], f ** k) for k in range(1, s["arcs"] + 1)]


def path_stats(t, path_index, tier):
    tiers = [0] * len(t["paths"])
    if tier:
        tiers[path_index] = tier
    return tower_stats(t, tiers)


def cumulative_cost(t, path_index, tier):
    return t["baseCost"] + sum(s["cost"] for s in t["paths"][path_index]["tiers"][:tier])


# ---------------------------------------------------------------- wave mix

def round_level(tuning, r):
    """The team (tower) level in play during round r: 1 + rounds cleared before it / RoundsPerLevel."""
    return 1 + (r - 1) // max(1, int(tuning.get("RoundsPerLevel", 5)))


def band_mix(data):
    """Per band: share of Easy-solo EHP that is plain / armoured / flying / boss, and the total.
    `parts` lists every species-round of the band for the overkill factor: (EHP weight, kind,
    size HP that round, Break resist, tower level that round)."""
    enemies = data["Enemies"]
    tuning = data["Tuning"]
    out = []
    for lo, hi in BANDS:
        share = {"plain": 0.0, "armoured": 0.0, "flying": 0.0, "boss": 0.0}
        parts = []
        for r, rd in enumerate(data["Rounds"][lo - 1:hi], start=lo):
            for key, n in rd["counts"].items():
                e = enemies[key]
                ehp = n * e["effectiveHp"] * rd["hpMult"]
                kind = "boss" if e["boss"] else "flying" if e["flying"] else "armoured" if e["armored"] else "plain"
                share[kind] += ehp
                parts.append((ehp, kind, e["hp"] * rd["hpMult"] / max(1, e["sizes"]), e["breakResist"], round_level(tuning, r)))
        total = sum(share.values())
        out.append({**{k: v / total for k, v in share.items()}, "total": total,
                    "parts": [(w / total, kind, hp, resist, lv) for w, kind, hp, resist, lv in parts]})
    return out


def size_breaks(tuning, base, level, resist):
    """Shared/SizeBreaks.breaks for a tower (heroes never get the level bonus)."""
    b = max(1, math.floor(base))
    if b >= 2:
        step = tuning.get("BreakLevelStep", 3)
        if step > 0:
            b += (max(1, level) - 1) // step
    b -= max(0, math.floor(resist))
    return min(max(1, math.floor(tuning.get("MaxSizeBreaks", 4))), max(1, b))


def overkill_factor(damage, breaks, share):
    """The fraction of one hit's damage that does work: min(D, b x share) / D (DECISIONS #128).

    >>> overkill_factor(50, 1, 100)    # D <= share: all of it
    1.0
    >>> overkill_factor(300, 1, 100)   # D = 3 x share, b = 1: a third
    0.3333333333333333
    >>> overkill_factor(300, 3, 100)   # b = 3: all of it again
    1.0
    >>> overkill_factor(300, 2, 100)
    0.6666666666666666
    """
    if damage <= 0 or share <= 0:
        return 1.0
    return min(1.0, breaks * share / damage)


# ---------------------------------------------------------------- effective DPS

def edps(s, mix, tuning, buff=None, overkill=True, breaks1=False):
    """One tower's effective DPS against a band's mix (`buff`: an aura it stands in).
    `overkill` False = the old zero-waste number (every point of damage counted);
    `breaks1` True = overkill counted with every Size breaks forced to 1 (today's game, B1)."""
    buff = buff or {}
    rate = s["rate"] * (1 + buff.get("rate", 0) / 100)
    if s["damage"] <= 0 or rate <= 0:
        direct = 0.0
        hits = s["targets"]
    else:
        hits = s["lineHits"] if s["lineHits"] > 1 else s["targets"]
        share = tuning.get("BombletDamage", 0)
        bomb = sum((s["bomblets"] * share) ** g for g in range(1, s["bombletGenerations"] + 1)) if s["bomblets"] else 0
        bomb += sum(n * x for n, x in chain_pieces(s, tuning)) + buff.get("arc", 0) / 100  # PLAN T64
        damage = s["damage"] * (1 + buff.get("damage", 0) / 100) * (1 + buff.get("brittle", 0) / 100)
        damage *= 1 + s.get("staticPercent", 0) / 100
        per_shot = damage * (1 + s["markPercent"] / 100) * (1 + s["brittlePercent"] / 100) * (hits + bomb)
        pierces = s["pierces"] or buff.get("pierces", False)
        weight = (mix["plain"] + mix["armoured"] * (s["armoredMult"] if pierces else 0)
                  + mix["flying"] * (1 if s["hitsAir"] else 0) + mix["boss"] * s["bossMult"])
        direct = rate * s["shots"] * per_shot * weight
        if overkill and direct > 0:
            direct = rate * s["shots"] * honest_hits(s, mix, tuning, damage, hits, pierces, breaks1, buff.get("arc", 0))
        direct += coil_extras(s, mix, tuning, damage, pierces, overkill, breaks1)
    burn = 0.0
    if s["burnDps"] > 0 and rate > 0:
        uptime = min(1.0, rate * s["shots"] * s["burnSeconds"])
        ground = mix["plain"] + mix["boss"] + (mix["armoured"] if s["pierces"] else 0)
        burn = s["burnDps"] * uptime * hits * ground
    freeze = 0.0
    if s["freezeDamage"] > 0 and s["freezeEvery"] > 0:
        weight = mix["plain"] + mix["flying"] + mix["boss"] + (mix["armoured"] if s["pierces"] else 0)
        freeze = s["freezeDamage"] / s["freezeEvery"] * s["targets"] * weight
    return direct + burn + freeze


def coil_extras(s, mix, tuning, damage, pierces, overkill=True, breaks1=False):
    """Judgement Bolt and Power Grid per second (the chain paragraph in the docstring)."""
    if not s.get("chains") or not (s["judgementBolt"] or s["powerGrid"]):
        return 0.0
    hit = damage * (1 + s["markPercent"] / 100) * (1 + s["brittlePercent"] / 100)
    level_x = 1 + tuning.get("TowerDamagePerLevel", 0)
    reached = 1 + sum(n for n, _ in chain_pieces(s, tuning))
    pieces = []  # (per second, x of the hit, base breaks)
    if s["judgementBolt"]:
        pieces.append((1 / tuning["JudgementBoltEvery"], tuning["JudgementBoltX"], 1 if breaks1 else tuning["JudgementBoltBreaks"]))
    if s["powerGrid"]:
        pieces.append((reached / tuning["PowerGridEvery"], grid_mult(tuning, GRID_COILS)[1], 1))
    total = 0.0
    if not overkill:
        weight = (mix["plain"] + mix["armoured"] * (s["armoredMult"] if pierces else 0)
                  + mix["flying"] * (1 if s["hitsAir"] else 0) + mix["boss"] * s["bossMult"])
        return sum(per * hit * x for per, x, _ in pieces) * weight
    for w, kind, size_hp, resist, level in mix["parts"]:
        m = {"plain": 1, "armoured": s["armoredMult"] if pierces else 0,
             "flying": 1 if s["hitsAir"] else 0, "boss": s["bossMult"]}[kind]
        if m <= 0:
            continue
        for per, x, base in pieces:
            landed = hit * x * m * level_x ** (level - 1)
            total += w * m * per * hit * x * overkill_factor(landed, size_breaks(tuning, base, level, resist), size_hp)
    return total


def honest_hits(s, mix, tuning, damage, hits, pierces, breaks1=False, arc=0):
    """Damage one shot does with overkill counted, summed over the band's species-rounds
    (the overkill paragraph in the module docstring). `breaks1`: every break forced to 1."""
    hit = damage * (1 + s["markPercent"] / 100) * (1 + s["brittlePercent"] / 100)
    splash = s["lineHits"] <= 1 and s["targets"] > 1
    base = 1 if splash or breaks1 else s["sizeBreaks"]
    level_x = 1 + tuning.get("TowerDamagePerLevel", 0)
    bomb_share = tuning.get("BombletDamage", 0)
    blasts = [(s["bomblets"] ** g, bomb_share ** g) for g in range(1, s["bombletGenerations"] + 1)] if s["bomblets"] else []
    blasts += chain_pieces(s, tuning) + ([(1, arc / 100)] if arc else [])  # Storm Coil arcs, Lightning Rodeo (T64)
    total = 0.0
    for w, kind, size_hp, resist, level in mix["parts"]:
        m = {"plain": 1, "armoured": s["armoredMult"] if pierces else 0,
             "flying": 1 if s["hitsAir"] else 0, "boss": s["bossMult"]}[kind]
        if m <= 0:
            continue
        landed = hit * m * level_x ** (level - 1)  # what the hit is as it lands, at the level in play
        b = size_breaks(tuning, base, level, resist)
        part = hits * hit * overkill_factor(landed, b, size_hp)
        for count, x in blasts:
            part += count * hit * x * overkill_factor(landed * x, 1, size_hp)
        total += w * m * part
    return total


def aura_credit(data, s, mix, brittle=False):
    """What this tower's aura adds to 3 neighbour T2 Hunting Blinds, one per Blind path.

    `brittle` (support paths only, #74): the neighbours' shots also get the tower's Brittle %,
    assuming the dinos they shoot are the sedated ones in its range."""
    buff = {"rate": s["auraRatePercent"], "damage": s["auraDamagePercent"], "pierces": s["auraPiercesArmor"],
            "brittle": s["brittlePercent"] if brittle else 0, "arc": s.get("auraArcPercent", 0)}
    if not (buff["rate"] or buff["damage"] or buff["pierces"] or buff["brittle"] or buff["arc"]):
        return 0.0
    blind = data["Towers"][NEIGHBOUR_TOWER]
    tuning = data["Tuning"]
    gain = 0.0
    for i in range(min(NEIGHBOURS, len(blind["paths"]))):
        n = path_stats(blind, i, NEIGHBOUR_TIER)
        gain += edps(n, mix, tuning, buff) - edps(n, mix, tuning)
    return gain


def modelled(data):
    """TowerOrder less the towers whose behaviour isn't built yet (PENDING_TOWERS)."""
    return [key for key in data["TowerOrder"] if key not in PENDING_TOWERS]


def is_support(key, path):
    return key in SUPPORT_TOWERS or (key, path["id"]) in SUPPORT_PATHS


def value_table(data, mixes):
    """rows[(key, path index, tier)] = {cost, edps[band], ...} for every damage tower path."""
    rows = {}
    tuning = data["Tuning"]
    for key in modelled(data):
        t = data["Towers"][key]
        if key in SUPPORT_TOWERS:
            continue
        for pi, path in enumerate(t["paths"]):
            for tier in range(0, len(path["tiers"]) + 1):
                s = path_stats(t, pi, tier)
                own = [edps(s, m, tuning) for m in mixes]
                zero_waste = [edps(s, m, tuning, overkill=False) for m in mixes]
                aura = [aura_credit(data, s, m, brittle=is_support(key, path)) for m in mixes]
                rows[(key, pi, tier)] = {
                    "cost": cumulative_cost(t, pi, tier),
                    "step": path["tiers"][tier - 1]["cost"] if tier else t["baseCost"],
                    "edps": [a + b for a, b in zip(own, aura)],
                    "aura": aura,
                    "before": [a + b for a, b in zip(zero_waste, aura)],
                    "breaks": s["sizeBreaks"],
                    "support": is_support(key, path),
                }
    return rows


def ratio(cash, dps):
    return cash / dps if dps > 1e-9 else math.inf


def judge(data, rows):
    """Adds cost/eDPS, marginal cash/eDPS and the #59 flags to each damage-path row."""
    for (key, pi, tier), r in rows.items():
        r["cpd"] = [ratio(r["cost"], e) for e in r["edps"]]
        if tier:
            prev = rows[(key, pi, tier - 1)]["edps"]
            r["marginal"] = [ratio(r["step"], e - p) if e - p > 1e-9 else math.inf for e, p in zip(r["edps"], prev)]
    medians = {}
    for tier in range(1, 6):
        # #79: control and support paths stay out of the medians (they aren't judged on DPS).
        damage = [r for (k, p, t), r in rows.items() if t == tier and not r["support"]]
        b = BOUGHT_BAND[tier]
        medians[tier] = {
            "marginal": statistics.median(r["marginal"][b] for r in damage),
            "cpd": [statistics.median(r["cpd"][i] for r in damage) for i in range(len(BANDS))],
        }
    findings = []
    for (key, pi, tier), r in rows.items():
        if not tier or r["support"]:
            continue
        b = BOUGHT_BAND[tier]
        r["vsMedian"] = r["marginal"][b] / medians[tier]["marginal"]
        r["control"] = (key, data["Towers"][key]["paths"][pi]["id"], tier) in CONTROL_TIERS
        r["dead"] = r["vsMedian"] > DEAD_X and not r["control"]
    for key in modelled(data):
        t = data["Towers"][key]
        if key in SUPPORT_TOWERS:
            continue
        for pi, path in enumerate(t["paths"]):
            if is_support(key, path):
                continue
            dominant = all(rows[(key, pi, tier)]["cpd"][i] < DOMINANT_X * medians[tier]["cpd"][i]
                           for tier in range(1, len(path["tiers"]) + 1) for i in range(len(BANDS)))
            for tier in range(1, len(path["tiers"]) + 1):
                r = rows[(key, pi, tier)]
                if r["dead"]:
                    lo, hi = BANDS[BOUGHT_BAND[tier]]
                    findings.append(
                        f"DEAD tier: {t['display']} {path['id']} T{tier} {path['tiers'][tier - 1]['name']}: "
                        f"marginal {fmt(r['marginal'][BOUGHT_BAND[tier]])} cash/eDPS = {r['vsMedian']:.1f}x the T{tier} median "
                        f"({fmt(medians[tier]['marginal'])}) in rounds {lo}-{hi}")
            if dominant:
                findings.append(f"DOMINANT path: {t['display']} {path['id']}: cost/eDPS < {DOMINANT_X}x the median at every tier in every band")
    return medians, findings


def fmt(x):
    if x == math.inf:
        return "inf"
    if x >= 1000:
        return f"{x:,.0f}"
    if x >= 10:
        return f"{x:.0f}"
    return f"{x:.2f}" if x < 1 else f"{x:.1f}"


# ---------------------------------------------------------------- support, economy, heroes

def support_lines(data, mixes):
    out = []
    late = mixes[3]
    for key in modelled(data):
        t = data["Towers"][key]
        for pi, path in enumerate(t["paths"]):
            if not is_support(key, path) or key == "QUARTERMASTER":
                continue
            bits = []
            for tier in range(1, len(path["tiers"]) + 1):
                s = path_stats(t, pi, tier)
                if path["id"] == "Lookout":
                    bit = f"range x{s['rangeMult']:.2f}"
                    if s["auraRatePercent"] or s["auraDamagePercent"]:
                        bit += f" aura +{s['auraRatePercent']:g}%r/+{s['auraDamagePercent']:g}%d{'/AP' if s['auraPiercesArmor'] else ''} (+{aura_credit(data, s, late):.1f})"
                elif key == "CHILLER" and path["id"] == "Knockout":
                    stopped = s["freezeSeconds"] / s["freezeEvery"] if s["freezeEvery"] else 0
                    bit = f"knockout {s['freezeSeconds']:g}s every {s['freezeEvery']:g}s = stopped {stopped:.0%}" + (" holds bosses" if s["freezeHoldsBosses"] else "")
                elif key == "CHILLER" and path["id"] == "Weak Spot":
                    bit = f"brittle +{s['brittlePercent']:g}%" + (" strips armour" if s["stripsArmor"] else "")
                    if s["auraRatePercent"] or s["auraDamagePercent"]:
                        bit += f" aura +{s['auraRatePercent']:g}%r/+{s['auraDamagePercent']:g}%d"
                    bit += f" (+{aura_credit(data, s, late, brittle=True):.1f}, darts {edps(s, late, data['Tuning']):.1f})"
                elif key == "CHILLER":
                    bit = f"slow {s['slowPercent']:g}%"
                    if s["slowLinger"]:
                        bit += f" +{s['slowLinger']:g}s"
                    if s["slowsBosses"]:
                        bit += " bosses"
                elif key == "ARMORY" and path["id"] == "Gunsmith":
                    bit = f"+{s['auraRatePercent']:g}%r/+{s['auraDamagePercent']:g}%d{'/AP' if s['auraPiercesArmor'] else ''} (+{aura_credit(data, s, late):.1f})"
                elif key == "ARMORY" and path["id"] == "Plating":
                    bit = f"resist {s['resistPercent']:g}%" + (f" thorns {s['thornsDamage']:g}" if s["thornsDamage"] else "")
                elif key == "ARMORY":
                    bit = f"range x{s['rangeMult']:.1f} reload x{s['hunterReloadMult']:.2f}" + (f" +{s['hunterRatePercent']:g}%rate" if s["hunterRatePercent"] else "")
                elif key == "COIL":
                    bit = f"range x{s['rangeMult']:.1f}"
                    if s["auraRatePercent"] or s["auraDamagePercent"] or s["auraArcPercent"]:
                        bit += f" aura +{s['auraRatePercent']:g}%r/+{s['auraDamagePercent']:g}%d" + (f"/arc {s['auraArcPercent']:g}%" if s["auraArcPercent"] else "")
                        bit += f" (+{aura_credit(data, s, late):.1f}, own {edps(s, late, data['Tuning']):.1f})"
                    if s["groundingEvery"]:
                        bit += f" grounds a throw every {s['groundingEvery']:g}s"
                elif path["id"] == "Ward":
                    bit = f"heal {s['healPerSecond']:g}/s" + (" revives" if s["revives"] else "")
                elif path["id"] == "Rescue":
                    bit = f"range x{s['rangeMult']:.1f}" + (f" kits {s['medKits']}x{s['medKitHeal']:g}" if s["medKits"] else "")
                else:
                    bit = f"+{s['auraHpPercent']:g}% HP" + (f" +{s['auraRatePercent']:g}%r (+{aura_credit(data, s, late):.1f})" if s["auraRatePercent"] else "")
                bits.append(f"T{tier} {bit}")
            out.append(f"  {t['display'][:14]:<14} {path['id'][:10]:<10} " + "; ".join(bits))
    return out


def economy_lines(data):
    """Supply Camp payback in rounds of Easy income (every chest collected; interest at its cap)."""
    t = data["Towers"]["QUARTERMASTER"]
    income = t["incomePerRound"]
    out = [f"  base camp: {t['baseCost']:,.0f} for {income:g}/round = {t['baseCost'] / income:.1f} rounds"]
    findings = []
    for pi, path in enumerate(t["paths"]):
        prev = path_stats(t, pi, 0)
        cells = []
        for tier in range(1, len(path["tiers"]) + 1):
            s = path_stats(t, pi, tier)
            cost = path["tiers"][tier - 1]["cost"]
            if path["id"] == "Logistics":
                gain = s["discountPercent"] - prev["discountPercent"]
                need = cost / (gain / 100) if gain > 0 else math.inf
                extra = f" refund {s['sellRefund']:g}" if s["sellRefund"] > prev["sellRefund"] else ""
                extra += f" aura +{s['auraRatePercent']:g}%r" if s["auraRatePercent"] > prev["auraRatePercent"] else ""
                cells.append(f"T{tier} {s['discountPercent']:g}%: spend {fmt(need)}{extra}")
            else:
                def per_round(x):
                    return income * x["incomeMult"] + x["interestCap"] * (x["interestPercent"] > 0) + x["chests"] * x["chestCash"]
                gain = per_round(s) - per_round(prev)
                rounds = cost / gain if gain > 0 else math.inf
                cells.append(f"T{tier} {fmt(cost)}/+{gain:g} = {fmt(rounds)}r")
                if rounds > 10:
                    findings.append(f"ECONOMY: Supply Camp {path['id']} T{tier} {path['tiers'][tier - 1]['name']} repays in {fmt(rounds)} rounds (#55 bar: 5-10)")
            prev = s
        out.append(f"  {path['id']:<9} " + "; ".join(cells))
    return out, findings


def top_tier(h, path_index):
    """A hero path's highest tier: 6 since PLAN T53 (DECISIONS #133)."""
    return len(h["paths"][path_index]["tiers"])


def hero_dps(h, path_index, tier):
    """(peak, sustained) per-trigger-held DPS. Peak is the exporter guard's formula; sustained
    also pays for reloads (belt-fed never reloads). Burn, marks and bounces aren't counted."""
    if tier == 0:
        step = None
    else:
        step = h["paths"][path_index]["tiers"][tier - 1]

    def g(field, default):
        return step[field] if step and step[field] else default

    guns = max(1, g("guns", 1))
    shots = max(1, g("shotsPerTrigger", 1))
    burst = max(1, g("burstCount", 1)) if g("fireMode", h["fireMode"]) == "burst" else 1
    rate = h["rate"] * g("rateMult", 1)
    peak = h["damage"] * g("damageMult", 1) * rate * g("spinUp", 1) * guns * h["pellets"] * shots * max(1, g("pierce", 1))
    if step and step["beltFed"]:
        return peak, peak
    rounds_per_second = rate * guns * burst
    magazine = max(1, math.floor(h["magazine"] * g("magazineMult", 1) * guns + 0.5))
    reload = h["reload"] * g("reloadMult", 1)
    if step and step["staggeredReload"] and guns >= 2:
        # Hot Swap (Shared/GunRules): one gun reloads while the other fires its share,
        # so firing only stalls if that reload outlasts the share.
        share = (magazine // guns) / rounds_per_second
        return peak, peak * share / max(share, reload)
    empty = magazine / rounds_per_second
    return peak, peak * empty / (empty + reload)


def hero_lines(data, rows, mixes):
    tuning = data["Tuning"]
    per = int(tuning.get("RoundsPerLevel", 5))
    hero_x, tower_x = tuning.get("HeroDamagePerLevel", 0), tuning.get("TowerDamagePerLevel", 0)
    # Hero XP (DECISIONS #101): a hunter's level sits between the round level (the
    # FLOOR: no pops, and what towers use) and the floor + the lead cap (the CEILING).
    lead = int(tuning.get("HeroLevelLeadCap", 0))
    rounds = data["Rounds"]

    def required(r):
        rd = rounds[r - 1]
        length = round(sum(rd["counts"].values()) * rd["spawnGap"] + 14)
        return round(rd["effectiveHp"] / length, 1) if length else 0

    # (round level, round, band): the level IN PLAY during that round (DECISIONS #109),
    # computed the way Shared/HeroXp and the exporter's guard do: 1 + rounds cleared
    # before it / RoundsPerLevel. Clearing the round is what gives the next level.
    checkpoints = [(1 + (rd - 1) // max(1, per), rd, b) for rd, b in ((1, 0), (20, 1), (len(rounds), 3))]
    # The last checkpoint must be the same pair of levels the exporter's guard compares.
    assert (checkpoints[-1][0], checkpoints[-1][0] + lead) == export_constants.guard_levels(data), \
        f"value.py's last checkpoint (tower L{checkpoints[-1][0]}, hero L{checkpoints[-1][0] + lead}) is not the exporter guard's {export_constants.guard_levels(data)}"
    t5 = {}
    for (key, pi, tier), r in rows.items():
        if tier == 5 and not r["support"]:
            t5[(key, pi)] = r["edps"]
    out = [f"  round level (round), towers at it: " + ", ".join(f"L{lv} (r{rd}) Required DPS {required(rd):g}, T5 towers {fmt(min(e[b] for e in t5.values()))}-{fmt(max(e[b] for e in t5.values()))} x{(1 + tower_x) ** (lv - 1):.2f}"
                                        for lv, rd, b in checkpoints)]
    out.append(f"  hunters: each checkpoint at the FLOOR (the round level, a hunter with no take-downs) and in [brackets] at the CEILING"
               f" (floor + {lead}, the most hero XP allows); towers stay on the round level")
    findings = []
    lead_only = []  # T5 tower paths a hunter passes only at the ceiling: listed, not a finding
    for key in data["HeroOrder"]:
        h = data["Heroes"][key]
        base, _ = hero_dps(h, 0, 0)
        best = max(range(len(h["paths"])), key=lambda i: hero_dps(h, i, top_tier(h, i))[0])
        top = top_tier(h, best)
        peak, sustained = hero_dps(h, best, top)
        cash = sum(s["cost"] for s in h["paths"][best]["tiers"])
        cells = []
        for lv, rd, b in checkpoints:
            hs, ts = (1 + hero_x) ** (lv - 1), (1 + tower_x) ** (lv - 1)
            cs = (1 + hero_x) ** (lv + lead - 1)
            best_tower = max(e[b] for e in t5.values()) * ts
            cells.append(f"L{lv} {peak * hs:.0f}/{sustained * hs:.0f} [L{lv + lead} {peak * cs:.0f}/{sustained * cs:.0f}]")
            # The rule (DECISIONS #58, #101): the highest hero level in play against the
            # best tower at the round level.
            if peak * cs > best_tower:
                findings.append(f"HERO: {h['display']} {h['paths'][best]['id']} T{top} at L{lv + lead} (ceiling, {peak * cs:.0f}) out-damages every T5 tower path's eDPS at round level {lv} ({best_tower:.0f})")
            for (tower_key, pi), e in t5.items():
                if peak * hs <= e[b] * ts < peak * cs:
                    tower = data["Towers"][tower_key]
                    lead_only.append(f"{h['display']} L{lv + lead} {peak * cs:.0f} > {tower['display']} {tower['paths'][pi]['id']} T5 {e[b] * ts:.0f} (round level {lv})")
        out.append(f"  {h['display'][:15]:<15} base {base:5.1f}  best {h['paths'][best]['id'][:10]:<10} T{top} {' '.join(cells)}"
                   f"  cash/DPS {cash / max(1e-9, peak - base):.0f}")
    if lead_only:
        out.append("  only at the ceiling does a hunter's peak pass these T5 tower paths (for the Director; not a finding, the rule is the best tower):")
        out += [f"    {line}" for line in lead_only]
    else:
        out.append("  the ceiling level passes no T5 tower path that the floor level doesn't")
    return out, findings


# ---------------------------------------------------------------- report

def value_report(data, full=False):
    mixes = band_mix(data)
    rows = value_table(data, mixes)
    medians, findings = judge(data, rows)
    print("value model (Easy, solo; eDPS against each band's real EHP mix; levels left out)")
    print("  band mix (share of EHP): " + "; ".join(
        f"r{lo}-{hi} armour {m['armoured']:.0%} air {m['flying']:.0%} boss {m['boss']:.0%}" for (lo, hi), m in zip(BANDS, mixes)))
    print("  eDPS per band r1-10/11-20/21-30/31-40 | cost/eDPS and marginal cash/eDPS in the band the tier is bought"
          " (T1-2: 11-20, T3: 21-30, T4-5: 31-40) | x med = marginal vs the tier's median")
    for key in modelled(data):
        if key in SUPPORT_TOWERS:
            continue
        t = data["Towers"][key]
        for pi, path in enumerate(t["paths"]):
            label = f"{t['display'][:14]} {path['id']}" + (" (support: not judged)" if is_support(key, path) else "")
            print(f"  {label}")
            for tier in range(0 if pi == 0 else 1, len(path["tiers"]) + 1):
                r = rows[(key, pi, tier)]
                b = BOUGHT_BAND.get(tier, 0)
                name = "base" if tier == 0 else path["tiers"][tier - 1]["name"]
                line = (f"    T{tier} {name[:16]:<16} {fmt(r['cost']):>7}  eDPS " + "/".join(fmt(e) for e in r["edps"])
                        + f"  c/e {fmt(r['cpd'][b])}")
                if full:
                    line += " [" + "/".join(fmt(c) for c in r["cpd"]) + "]"
                if tier:
                    line += f"  marg {fmt(r['marginal'][b])}"
                    if not r["support"]:
                        line += f" ({r['vsMedian']:.1f}x med){'  DEAD' if r['dead'] else ''}"
                        if r["control"]:
                            line += f"  stun {path_stats(t, pi, tier)['stunSeconds']:g} s on hit: control, not flagged"
                if any(r["aura"]):
                    line += f"  ({'brittle + aura on Blinds' if r['support'] and path_stats(t, pi, tier)['brittlePercent'] else 'aura'} {fmt(r['aura'][b])})"
                print(line)
    print("  medians (damage paths) marginal cash/eDPS: " + ", ".join(f"T{t} {fmt(m['marginal'])}" for t, m in medians.items()))
    print("support and control (own effect, not DPS; aura credit in rounds 31-40 on 3 T2 Blinds in brackets; Weak Spot's adds its Brittle on them):")
    for line in support_lines(data, mixes):
        print(line)
    print("economy payback (Easy rounds of extra income; chests all collected; interest at its cap):")
    lines, econ = economy_lines(data)
    for line in lines:
        print(line)
    print("heroes (best path at its top tier (T6), peak/sustained DPS levelled; cash/DPS = that path's upgrade cash per DPS gained):")
    lines, heroes = hero_lines(data, rows, mixes)
    for line in lines:
        print(line)
    findings += econ + heroes
    print(f"Findings ({len(findings)}):")
    for f in findings:
        print(f"  - {f}")


def overkill_report(data):
    """PLAN T47: every damage path's T4-T5 eDPS per band, before (zero-waste) -> after."""
    mixes = band_mix(data)
    rows = value_table(data, mixes)
    print("overkill (PLAN T47, DECISIONS #128): eDPS before (zero-waste) -> after (overkill counted), Easy solo,"
          " levels left out of the numbers; breaks = the tier's Size breaks")
    print("  " + " " * 38 + "  ".join(f"r{lo}-{hi}".center(19) for lo, hi in BANDS))
    for key in modelled(data):
        if key in SUPPORT_TOWERS:
            continue
        t = data["Towers"][key]
        for pi, path in enumerate(t["paths"]):
            for tier in (4, 5):
                r = rows[(key, pi, tier)]
                cells = "  ".join(f"{fmt(a):>7}->{fmt(b):>7} {pct(a, b):>4}" if a > 1e-9 else f"{'-':>19}"
                                  for a, b in zip(r["before"], r["edps"]))
                label = f"{t['display'][:14]} {path['id'][:12]} T{tier} b{r['breaks']}"
                print(f"  {label:<38}{cells}{'  (support)' if r['support'] else ''}")


BREAKS_BANDS = (2, 3)  # PLAN T48: rounds 21-30 and 31-40 ...
BREAKS_T1_BANDS = (1,)  # ... and 11-20 for a tier 1
S_OVER_B1, S_OVER_Z = 1.10, 1.15  # DECISIONS #160: bars 1 and 2
RECOVER_Z = 0.95  # #165: where Z/B1 < S_OVER_B1, bar 1 asks S >= 0.95 x Z instead


def raw_tiers(data):
    """The raw-damage tiers (DECISIONS #127, #165): every tier on a break path whose own
    Size breaks cell is above 1, as (key, path index, tier)."""
    out = []
    for key in modelled(data):
        t = data["Towers"][key]
        for pi, path in enumerate(t["paths"]):
            if (t["display"], path["id"]) in export_constants.BREAK_PATHS:
                out += [(key, pi, i) for i, step in enumerate(path["tiers"], start=1) if step["sizeBreaks"] > 1]
    return out


def break_bars(z, b1, sv, gate_median, median):
    """PLAN T48 (final), DECISIONS #160/#164/#165: which bars a tier-band fails, and which
    branch of bar 1 ran ("B1" where overkill matters, Z/B1 >= 1.10; "Z" where it doesn't).
    >>> break_bars(146, 109, 144, False, 0)
    ([], 'B1')
    >>> break_bars(131, 122, 131, False, 0)
    ([], 'Z')
    >>> break_bars(131, 122, 124, False, 0)
    (['bar 1 (S/Z)'], 'Z')
    >>> break_bars(146, 109, 115, False, 0)
    (['bar 1 (S/B1)'], 'B1')
    >>> break_bars(100, 50, 120, True, 130)
    (['bar 2 (S/Z)', 'bar 3 (T5 median)'], 'B1')
    """
    bad = []
    if z >= S_OVER_B1 * b1:
        branch = "B1"
        if sv < S_OVER_B1 * b1:
            bad.append("bar 1 (S/B1)")
    else:
        branch = "Z"
        if sv < RECOVER_Z * z:
            bad.append("bar 1 (S/Z)")
    if sv > S_OVER_Z * z:
        bad.append("bar 2 (S/Z)")
    if gate_median and sv < median:
        bad.append("bar 3 (T5 median)")
    return bad, branch


def breaks_report(data):
    """PLAN T48 (final), DECISIONS #160/#164-#166: per raw tier and band, Z (old zero-waste),
    B1 (honest, every break 1), S (honest, the sheet's breaks), and the bars. Bar 3 gates the
    general raw T5s only; a boss specialist's T5 is printed, not gated. Returns the failures."""
    mixes = band_mix(data)
    rows = value_table(data, mixes)
    tuning = data["Tuning"]
    medians = [statistics.median(r["edps"][i] for (k, p, t), r in rows.items() if t == 5 and not r["support"])
               for i in range(len(BANDS))]
    print("breaks (PLAN T48 final, DECISIONS #160, #164-#166): Z = zero-waste, B1 = every break 1,"
          f" S = the sheet's breaks; bar 1 S >= {S_OVER_B1}x B1 where Z/B1 >= {S_OVER_B1} [branch B1],"
          f" else S >= {RECOVER_Z}x Z [branch Z]; bar 2 S <= {S_OVER_Z}x Z;"
          " bar 3 general raw T5 S >= the band's damage-path T5 median")
    print("  T5 median: " + ", ".join(f"r{BANDS[i][0]}-{BANDS[i][1]} {fmt(medians[i])}" for i in BREAKS_BANDS))
    failures, specialists = [], []
    for key, pi, tier in raw_tiers(data):
        t = data["Towers"][key]
        path = t["paths"][pi]
        r = rows[(key, pi, tier)]
        s = path_stats(t, pi, tier)
        label = f"{t['display'][:14]} {path['id']} T{tier} {path['tiers'][tier - 1]['name']} b{r['breaks']}"
        specialist = (key, path["id"], tier) in BOSS_SPECIALIST
        for i in (BREAKS_T1_BANDS if tier == 1 else BREAKS_BANDS):
            z, b1, sv = r["before"][i], edps(s, mixes[i], tuning, breaks1=True) + r["aura"][i], r["edps"][i]
            bad, branch = break_bars(z, b1, sv, tier == 5 and not specialist, medians[i])
            lo, hi = BANDS[i]
            print(f"  {label:<46} r{lo}-{hi}  Z {fmt(z):>5}  B1 {fmt(b1):>5}  S {fmt(sv):>5}"
                  f"  S/B1 {sv / b1:.2f}  S/Z {sv / z:.2f}  bar1:{branch}{'  FAIL ' + ', '.join(bad) if bad else ''}")
            failures += [f"{label} r{lo}-{hi}: {b}" for b in bad]
            if specialist:
                specialists.append(f"{label} r{lo}-{hi} S {fmt(sv)} S/B1 {sv / b1:.2f} S/Z {sv / z:.2f}"
                                   f" (median {fmt(medians[i])})")
    for line in specialists:
        print(f"  boss specialist (report, #164): {line}")
    print(f"Break bars: {'all met' if not failures else str(len(failures)) + ' failed'}")
    return failures


def pct(before, after):
    return f"{(after / before - 1) * 100:+.0f}%" if before > 1e-9 else ""


# ---------------------------------------------------------------- pacing (PLAN T19)

PLAYER_COUNTS = (1, 4, 10)
AFFORD_ROUNDS = range(11, 40)  # DECISIONS #72: the minimum over rounds 11-39 (round 40 is the finale)
# DECISIONS #72 bars (they replace #55's): (difficulty, players) -> ((rounds, minimum affordability), ...)
BARS = {
    ("EASY", 1): ((range(11, 33), 1.0), (range(33, 40), 0.85)),
    ("NORMAL", 1): ((AFFORD_ROUNDS, 0.75),),
    ("HARD", 1): ((AFFORD_ROUNDS, 0.65),),  # #136 (was 0.55 under #72)
    ("CHAOS", 4): ((AFFORD_ROUNDS, 0.40),),
}
HARDER_ROUNDS = range(1, 16)  # #136: Hard solo stays below Normal solo in these rounds
MAX_STEP = 1.6  # #72: no round's Required DPS above this x the round before (Easy solo, from round 2)
# #77: the one named exception, with its own bar so the step can't creep back up.
STEP_EXCEPTIONS = {11: (2.1, "first armour and air wave")}


def step_bar(r):
    """(bar, name) for the Required DPS step into round r; name is None for the usual bar."""
    return STEP_EXCEPTIONS.get(r, (MAX_STEP, None))
FINALE_ROUNDS = range(31, 41)
FINALE_EHP_BEFORE = 323127  # Easy solo EHP of rounds 31-40 before T21 reshaped the Rounds counts (#57)
FINALE_EHP_TOLERANCE = 0.12  # #72: the finale's total EHP stays within +/-12% of that
TYPICAL_TIER = ((15, 2), (25, 3), (35, 4))  # (round, tier a tower usually has by then)
WALK_SECONDS = 14  # the Rounds sheet's round length = enemies x spawn gap + 14


def xround(x, digits=0):
    """Excel ROUND (half away from zero), so the sheet's numbers come out exactly."""
    f = 10 ** digits
    return math.copysign(math.floor(abs(x) * f + 0.5) / f, x)


def promotion(data):
    """Server/Waves: each ground, non-boss species promotes to the next one in EnemyOrder."""
    out, previous = {}, None
    for key in data["EnemyOrder"]:
        e = data["Enemies"].get(key)
        if e and not e["flying"] and not e["boss"]:
            if previous:
                out[previous] = key
            previous = key
    return out


def pacing_rounds(data, wb_cost_per_dps, difficulty, players):
    """The Balance Check's columns for one difficulty and player count, round by round.

    Scaling as Server/Waves and Main do it: counts x (difficulty count x) x (1 + ExtraEnemies
    per extra player), rounded per species, never below 1; HP x (difficulty HP x) x (1 + ExtraHP
    per extra player); a promoted spawn has the next ground species' EHP. Density, not length:
    the spawn gap shrinks by the count factor, so the spawn phase stays enemies x gap and only
    the 14 s walk shortens with speed x. Cash x scales kill income and the round bonus; every
    extra player adds StartingCashPerExtraPlayer to the shared pot, on top of the difficulty's
    Starting cash (DECISIONS #136). Heroes' DPS isn't counted.
    Easy solo is exactly the Balance Check sheet (asserted by the caller)."""
    tuning, enemies = data["Tuning"], data["Enemies"]
    d = data["Difficulties"][difficulty]
    extra = players - 1
    count_x = d["countMult"] * (1 + tuning["ExtraEnemiesPerPlayer"] * extra)
    hp_x = d["hpMult"] * (1 + tuning["ExtraHPPerPlayer"] * extra)
    p, promote = d["promoteChance"], promotion(data)
    cumulative = d["startingCash"] + tuning["StartingCashPerExtraPlayer"] * extra  # per difficulty (#136)
    growth = tuning["TierCostGrowth"] / tuning["TierDamageGrowth"]
    out = []
    for index, rd in enumerate(data["Rounds"], start=1):
        ehp = enemies_n = 0.0
        for key, n in rd["counts"].items():
            spawns = n if count_x == 1 else max(1, math.floor(n * count_x + 0.5))
            each = enemies[key]["effectiveHp"]
            if p and key in promote:
                each = (1 - p) * each + p * enemies[promote[key]]["effectiveHp"]
            ehp += spawns * each
            enemies_n += n
        total = xround(ehp * rd["hpMult"] * hp_x)
        length = xround(enemies_n * rd["spawnGap"] + WALK_SECONDS / d["speedMult"])
        required = xround(total / length, 1) if length else 0
        income = (xround(total * tuning["CashPerEffectiveHP"]) + xround(tuning["RoundBonusBase"] + tuning["RoundBonusPerRound"] * index)) * d["cashMult"]
        cumulative += income
        ref_tier = min(5, index / tuning["RoundsPerTier"])
        cost_per_dps = xround(wb_cost_per_dps * growth ** ref_tier, 1)
        needed = xround(required * cost_per_dps / tuning["ExpectedEfficiency"])
        in_towers = xround(cumulative * tuning["AssumedSpendOnTowers"])
        out.append({"ehp": total, "required": required, "length": length, "income": income, "cumulative": cumulative,
                    "needed": needed, "afford": in_towers / needed if needed else 0})
    return out


def ranges(rounds):
    """[11, 12, 13, 31] -> '11-13, 31'"""
    out, start = [], None
    for i, r in enumerate(rounds):
        if start is None:
            start = r
        if i + 1 == len(rounds) or rounds[i + 1] != r + 1:
            out.append(f"{start}" if start == r else f"{start}-{r}")
            start = None
    return ", ".join(out) or "none"


def pacing_report(data):
    with contextlib.redirect_stdout(io.StringIO()):
        wb = export_constants.recalculated(export_constants.DEFAULT_XLSX)
    cost_per_dps = wb["Towers"]["C13"].value
    sheet = wb["Balance Check"]
    order = data["DifficultyOrder"]
    table = {(d, n): pacing_rounds(data, cost_per_dps, d, n) for d in order for n in PLAYER_COUNTS}

    # The model must reproduce the Balance Check sheet (Easy, solo) exactly.
    easy = table[(order[0], 1)]
    for i, row in enumerate(easy):
        r = 5 + i
        assert int(sheet.cell(r, 1).value) == i + 1, f"Balance Check row {r} isn't round {i + 1}"
        for col, field in ((2, "required"), (5, "needed"), (6, "cumulative"), (8, "afford")):
            want = sheet.cell(r, col).value
            assert abs(row[field] - want) < 1e-9, f"round {i + 1} {field}: model {row[field]} vs Balance Check {want}"

    findings = []
    print("pacing model (affordability = the Balance Check's cash in towers / cash needed; reproduces its Easy-solo column exactly)")
    print("  (a) affordability, minimum over rounds 11-39, and the TIGHT (< 1.0) rounds in 11-40; bars from DECISIONS #72")
    print(f"  {'difficulty':<10} {'hunters':>7} {'min 11-39':>9} {'at':>3} {'bar':>8}  TIGHT rounds")
    for d in order:
        for n in PLAYER_COUNTS:
            rows = table[(d, n)]
            low = min(AFFORD_ROUNDS, key=lambda r: rows[r - 1]["afford"])
            value = rows[low - 1]["afford"]
            bars = BARS.get((d, n), ())
            missed = []
            for span, bar in bars:
                worst = min(span, key=lambda r: rows[r - 1]["afford"])
                if rows[worst - 1]["afford"] < bar:
                    missed.append(f"AFFORD: {data['Difficulties'][d]['display']} with {n} hunter(s): minimum {rows[worst - 1]['afford']:.2f} at round {worst} < bar {bar:g} (rounds {span[0]}-{span[-1]})")
            findings.extend(missed)
            verdict = "" if not bars else (" MISS" if missed else " ok")
            shown = "/".join(f"{bar:g}" for _, bar in bars) or "-"
            tight = [r for r in range(11, 41) if rows[r - 1]["afford"] < 1]
            print(f"  {data['Difficulties'][d]['display']:<10} {n:>7} {value:>9.2f} {low:>3} {shown:>8}{verdict:<5} {ranges(tight)}")
            if (d, n) == (order[0], 1):
                for r in range(2, 41):
                    bar, name = step_bar(r)
                    if rows[r - 1]["required"] > bar * rows[r - 2]["required"]:
                        findings.append(f"CLIFF: Easy solo round {r} Required DPS {rows[r - 1]['required']:g} > {bar:g}x round {r - 1} ({rows[r - 2]['required']:g})"
                                        + (f" (named exception: {name}, DECISIONS #77)" if name else ""))
    # #136: Hard's bigger opening pot must not make it easier than Normal early on.
    hard, normal = table[("HARD", 1)], table[("NORMAL", 1)]
    gaps = [(r, normal[r - 1]["afford"] - hard[r - 1]["afford"]) for r in HARDER_ROUNDS]
    closest = min(gaps, key=lambda g: g[1])
    print(f"  Hard solo below Normal solo every round {HARDER_ROUNDS[0]}-{HARDER_ROUNDS[-1]} (#136): smallest gap {closest[1]:.2f} at round {closest[0]}")
    for r, gap in gaps:
        if gap <= 0:
            findings.append(f"HARDER: Hard solo affordability {hard[r - 1]['afford']:.2f} >= Normal {normal[r - 1]['afford']:.2f} at round {r} (DECISIONS #136)")
    cols = [(d, 1) for d in order] + [(order[0], 4), (order[-1], 4), (order[-1], 10)]
    print("  per round (solo unless marked): " + " ".join(f"{data['Difficulties'][d]['display'][:6]}{'' if n == 1 else f'x{n}'}" for d, n in cols))
    for r in range(11, 41):
        print(f"    r{r:<3} " + " ".join(f"{table[c][r - 1]['afford']:>{max(6, len(data['Difficulties'][c[0]]['display'][:6]) + (0 if c[1] == 1 else len(str(c[1])) + 1))}.2f}" for c in cols))

    steps = [(easy[r - 1]["required"] / easy[r - 2]["required"], r) for r in range(2, 41) if r not in STEP_EXCEPTIONS]
    step, at = max(steps)
    print(f"  Easy solo Required DPS: biggest step from round 2 on x{step:.2f} at round {at} ({easy[at - 2]['required']:g} -> {easy[at - 1]['required']:g}; bar x{MAX_STEP:g})")
    for r, (bar, name) in sorted(STEP_EXCEPTIONS.items()):
        print(f"    named exception, round {r} ({name}, DECISIONS #77): x{easy[r - 1]['required'] / easy[r - 2]['required']:.2f} ({easy[r - 2]['required']:g} -> {easy[r - 1]['required']:g}; bar x{bar:g})")
    finale = sum(easy[r - 1]["ehp"] for r in FINALE_ROUNDS)
    change = finale / FINALE_EHP_BEFORE - 1
    print(f"  Easy solo finale EHP (rounds {FINALE_ROUNDS[0]}-{FINALE_ROUNDS[-1]}): {finale:,.0f} vs {FINALE_EHP_BEFORE:,} before T21 ({change:+.1%}; bar +/-{FINALE_EHP_TOLERANCE:.0%})")
    if abs(change) > FINALE_EHP_TOLERANCE:
        findings.append(f"FINALE: rounds {FINALE_ROUNDS[0]}-{FINALE_ROUNDS[-1]} EHP {finale:,.0f} is {change:+.1%} from {FINALE_EHP_BEFORE:,} (bar +/-{FINALE_EHP_TOLERANCE:.0%})")
    print("  (b) repair price of a fully trampled tower (Repair cost x spent; Easy solo income that round)")
    tuning = data["Tuning"]
    for r, tier in TYPICAL_TIER:
        income = easy[r - 1]["income"]
        cells = []
        for key in data["TowerOrder"]:
            t = data["Towers"][key]
            if t.get("untouchable"):
                continue  # no HP, never repaired (DECISIONS #148)
            price = xround(tuning["RepairCost"] * cumulative_cost(t, 0, tier))
            cells.append(f"{t['display'].split()[0]} {fmt(price)} ({price / income:.2f})")
        print(f"    r{r} T{tier}, income {fmt(income)}: " + ", ".join(cells))

    print("  (c) Amber (Payouts: a clear pays the difficulty's Clear reward to every hunter; a loss pays "
          f"{tuning['MultiplayerLossPayout']:g} in co-op, 0 solo)")
    unlock = sum(t["unlockCost"] for t in data["Towers"].values()) + sum(h["unlockCost"] for h in data["Heroes"].values())
    waves = open(os.path.join(ROOT, "src", "server", "Waves.luau"), encoding="utf-8").read()
    intermission = float(re.search(r"INTERMISSION\s*=\s*([\d.]+)", waves).group(1))
    for d in order:
        dd = data["Difficulties"][d]
        rounds_s = sum(row["length"] for row in table[(d, 1)])
        clear_s = rounds_s + intermission * len(data["Rounds"]) + tuning.get("ResultsTime", 0)
        clears = unlock / dd["clearReward"] if dd["clearReward"] else math.inf
        print(f"    {dd['display']:<7} clear {dd['clearReward']:g} Amber, {rounds_s / 60:.1f} min of rounds ({clear_s / 60:.1f} with breaks):"
              f" unlock all ({unlock:g}) = {clears:.1f} clears = {clears * clear_s / 3600:.1f} h; {dd['clearReward'] * 3600 / clear_s:.0f} Amber/h")
    mastery = data["Mastery"]
    total = sum(m["coreCost"] for m in mastery)
    easy_clear = data["Difficulties"][order[0]]["clearReward"]
    print(f"    mastery 1-{len(mastery)}: {total:g} Amber per hero = {total / easy_clear:.1f} Easy clears; cost per level (* = gives a reward):")
    cells = [f"{i}:{m['coreCost']:g}{'*' if m['unlock'] else ''}" for i, m in enumerate(mastery, start=1)]
    for i in range(0, len(cells), 10):
        print("      " + " ".join(cells[i:i + 10]))
    dead = [i for i, m in enumerate(mastery, start=1) if not m["unlock"]]
    if dead:
        findings.append(f"MASTERY: levels {ranges(dead)} give no reward ({sum(mastery[i - 1]['coreCost'] for i in dead):g} of {total:g} Amber; DECISIONS #61: ask Jovan)")
    bounty_report(data, easy, unlock, findings)

    print(f"Findings ({len(findings)}):")
    for f in findings:
        print(f"  - {f}")


# ---------------------------------------------------------------- Chaos skill (PLAN T50 final)

CHAOS_AIM = {"average": 0.5, "skilled": 0.9}
# DECISIONS #167: (label, aim, rounds, test, bar); exit 1 if any is broken.
CHAOS_BARS = (
    ("towers only, lowest over 11-39", None, range(11, 40), "<=", 0.35),
    ("skilled aim, lowest through round 30", "skilled", range(1, 31), ">=", 0.85),
    ("skilled aim, lowest over 31-40", "skilled", range(31, 41), ">=", 0.40),
)
CHAOS_REPORT_ROUNDS = range(1, 20)  # average aim before round 20: report only (#167)


def chaos_report(data):
    """Chaos solo: the cash-to-required ratio with towers only (affordability x Tower damage x)
    and with the hunter's gun added (best hero's top-tier peak (T6, PLAN T53) at the round level x Hero damage x x
    aim, over Required DPS). Returns the broken gated bars."""
    with contextlib.redirect_stdout(io.StringIO()):
        wb = export_constants.recalculated(export_constants.DEFAULT_XLSX)
    key = data["DifficultyOrder"][-1]
    d = data["Difficulties"][key]
    rows = pacing_rounds(data, wb["Towers"]["C13"].value, key, 1)
    tuning = data["Tuning"]
    per, hero_x = int(tuning.get("RoundsPerLevel", 5)), tuning.get("HeroDamagePerLevel", 0)
    peak = max(hero_dps(h, i, top_tier(h, i))[0] for h in data["Heroes"].values() for i in range(len(h["paths"])))

    def ratio(r, aim):
        row = rows[r - 1]
        towers = d["towerDamageMult"] * row["afford"]
        if aim is None:
            return towers
        level = 1 + (r - 1) // max(1, per)
        return towers + CHAOS_AIM[aim] * d["heroDamageMult"] * peak * (1 + hero_x) ** (level - 1) / row["required"]

    def lowest(rounds, aim):
        at = min(rounds, key=lambda r: ratio(r, aim))
        return ratio(at, aim), at

    print(f"Chaos skill report ({d['display']} solo; Tower damage x {d['towerDamageMult']:g}, Hero damage x {d['heroDamageMult']:g})")
    print(f"  ratio = cash-to-required with towers x Tower damage x, plus aim x the best hero's top-tier (T6) peak ({peak:.1f} DPS at level 1)"
          f" at the round level x Hero damage x / Required DPS")
    print("  the hero model is an UPPER BOUND (DECISIONS #168): real hunters reach T6 later, so Chaos is at least this hard")
    broken = []
    for label, aim, rounds, test, bar in CHAOS_BARS:
        value, at = lowest(rounds, aim)
        ok = value <= bar if test == "<=" else value >= bar
        print(f"  {label:<38} {value:.2f} (round {at})  bar {test} {bar:g}  {'ok' if ok else 'MISS'}")
        if not ok:
            broken.append(f"CHAOS: {label} {value:.2f} at round {at}, bar {test} {bar:g}")
    avg, avg_at = lowest(CHAOS_REPORT_ROUNDS, "average")
    sk, sk_at = lowest(CHAOS_REPORT_ROUNDS, "skilled")
    print(f"  report only: average aim, lowest over {CHAOS_REPORT_ROUNDS[0]}-{CHAOS_REPORT_ROUNDS[-1]} {avg:.2f} (round {avg_at});"
          f" skilled {sk:.2f} (round {sk_at}); skilled minus average {sk - avg:+.2f}")
    print("  per round (towers / average / skilled): " + "  ".join(
        f"r{r} {ratio(r, None):.2f}/{ratio(r, 'average'):.2f}/{ratio(r, 'skilled'):.2f}" for r in (1, 11, 20, 30, 31, 35, 40)))
    print(f"Chaos bars broken ({len(broken)}):")
    for b in broken:
        print(f"  - {b}")
    return broken


# A daily bounty must fit one solo Easy match reaching this round; a weekly must fit this
# many such matches or clears (DECISIONS #66, PLAN round 2 T25).
BOUNTY_MATCH_ROUND = 25
BOUNTY_WEEK_MATCHES = 5


def bounty_report(data, easy, unlock, findings):
    """(d) of the pacing report: can each bounty be done, and the most Amber a week of
    log-ins and bounties adds. `easy` is pacing_rounds for Easy solo.

    One match = solo Easy to round BOUNTY_MATCH_ROUND; a clear = all the rounds. What one
    match can hold: pops = the Rounds sheet's counts; ability uses = round seconds / the
    best free hero's cooldown; builds = cash earned / the cheapest free tower; upgrades =
    the n that cash covers at two tier-1 upgrades per cheapest free tower. Repairs of
    trampled towers aren't modelled (how often a tower falls depends on where it stands)."""
    tuning, rounds = data["Tuning"], data["Rounds"]
    free_towers = [t for t in data["Towers"].values() if t["unlockCost"] == 0]
    free_heroes = [h for h in data["Heroes"].values() if h["unlockCost"] == 0]
    tower = min(t["baseCost"] for t in free_towers)
    upgrade = min(p["tiers"][0]["cost"] for t in free_towers for p in t["paths"] if p["tiers"])
    cooldown = min(h["abilityCooldown"] for h in free_heroes)

    def capacity(b, upto):
        """How much of bounty b one match to round `upto` can do; None = not modelled."""
        played = rounds[:upto]
        cash = easy[upto - 1]["cumulative"]
        event = b["event"]
        if event == "pop":
            return sum(rd["counts"].get(b["target"], 0) for rd in played)
        if event == "popTotal":
            return sum(sum(rd["counts"].values()) for rd in played)
        if event == "reachRound":
            return (1 if upto >= b["round"] else 0) if b["round"] else upto
        if event == "clear":
            return 1 if upto >= len(rounds) else 0
        if event == "ability":
            return math.floor(sum(row["length"] for row in easy[:upto]) / cooldown)
        if event == "build":
            return math.floor(cash / tower)
        if event == "upgrade":
            n = 0
            while math.ceil((n + 1) / 2) * tower + (n + 1) * upgrade <= cash:
                n += 1
            return n
        return None

    print(f"  (d) bounties: a daily must fit one solo Easy match to round {BOUNTY_MATCH_ROUND}, a weekly {BOUNTY_WEEK_MATCHES} such matches or clears (DECISIONS #66)")
    cells, unmodelled = [], []
    for key in data["BountyOrder"]:
        b = data["Bounties"][key]
        match, clear = capacity(b, BOUNTY_MATCH_ROUND), capacity(b, len(rounds))
        if match is None:
            unmodelled.append(f"{b['title']} {b['count']:g}")
            continue
        daily = b["pool"] == "daily"
        # A reach-round bounty with no Target counts the round itself, so more matches don't add up.
        once = b["event"] == "reachRound" and not b["round"]
        room = match if daily else (max(match, clear) if once else BOUNTY_WEEK_MATCHES * max(match, clear))
        mark = ""
        if b["count"] > room:
            if daily and b["count"] <= clear:
                mark = " (needs a full clear)"
                findings.append(f"BOUNTY: {key} ({b['title']}, daily) needs a full clear, not a match to round {BOUNTY_MATCH_ROUND} (PLAN's final pool; ask the Director)")
            else:
                mark = " MISS"
                findings.append(f"BOUNTY: {key} ({b['title']}) asks {b['count']:g}, the model allows {room:g}")
        cells.append(f"{key[:1].lower()} {b['title']} {b['count']:g}/{room:g}{mark}")
    for i in range(0, len(cells), 6):
        print("    " + ", ".join(cells[i:i + 6]))
    if unmodelled:
        print(f"    not modelled (needs a trampled tower; see threat.py's hugging column): {', '.join(unmodelled)}")
        findings.append(f"BOUNTY: {', '.join(unmodelled)} can't be checked: no model of how often a tower is trampled (playtest)")

    order, difficulties = data["DifficultyOrder"], data["Difficulties"]
    easy_clear = difficulties[order[0]]["clearReward"]
    haul = sum(day["amber"] for day in data["DailyHaul"])
    best = {}
    for pool, lever in (("daily", "DailyBounties"), ("weekly", "WeeklyBounties")):
        slots = export_constants.active_slots(tuning[lever])
        best[pool] = sum(
            sum(sorted((b["amber"] for b in data["Bounties"].values() if b["pool"] == pool and b["slot"] == slot), reverse=True)[:slots.count(slot)])
            for slot in export_constants.BOUNTY_SLOTS)
    days = len(data["DailyHaul"])
    week = haul * 7 / days + 7 * best["daily"] + best["weekly"]
    print(f"    the most a week adds: Daily Haul {haul * 7 / days:g} + dailies 7 x {best['daily']:g} + weeklies {best['weekly']:g} = {week:g} Amber"
          f" = {week / easy_clear:.1f} Easy clears; alone it unlocks everything ({unlock:g}) in {unlock / week:.1f} weeks")
    print(f"    log-in only (no play): {haul * 7 / days:g} Amber a week = {haul * 7 / days / easy_clear:g} Easy clears")


def main():
    args = sys.argv[1:]
    data = load()
    if "--pacing" in args:
        pacing_report(data)
    elif "--overkill" in args:
        overkill_report(data)
    elif "--chaos" in args:
        sys.exit(1 if chaos_report(data) else 0)
    elif "--breaks1" in args:
        sys.exit(1 if breaks_report(data) else 0)
    else:
        value_report(data, "--full" in args)


if __name__ == "__main__":
    main()
