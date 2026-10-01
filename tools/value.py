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
  aura       aura towers are credited with what their aura (rate %, damage %, pierces
             armour) adds to 3 neighbour T2 Hunting Blinds, one on each Blind path
             (a stated assumption). Stun, knockback and slow are not DPS: not credited.
Levels scale every tower alike, so they're left out of the tower tables.

Flags (DECISIONS #59), damage paths only:
  dead tier      marginal cash per marginal eDPS > 2x the median of all damage paths at
                 that tier, in the band it's typically bought (T1-2: 11-20, T3: 21-30,
                 T4-5: 31-40)
  dominant path  cost per eDPS < 0.5x the median at every tier in every band
Support and control paths (Lookout, Sedate, Armory, Field Hospital, Supply Camp) get their
own value line instead. Economy payback is in rounds of Easy income.

Usage:
    python3 tools/value.py           the value report (<= ~120 lines)
    python3 tools/value.py --full    every band's cost per eDPS, every tower
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
SUPPORT_PATHS = {("SCOUT", "Lookout"), ("CHILLER", "Sedate")}
SUPPORT_TOWERS = {"QUARTERMASTER", "HOSPITAL", "ARMORY"}
NEIGHBOUR_TOWER, NEIGHBOUR_TIER, NEIGHBOURS = "SCOUT", 2, 3
DEAD_X, DOMINANT_X = 2.0, 0.5


def load():
    with contextlib.redirect_stdout(io.StringIO()):
        return export_constants.read_data(export_constants.DEFAULT_XLSX)


# ---------------------------------------------------------------- tower stats

def _luau_list(text, name):
    body = re.search(r"local " + name + r" = \{(.*?)\}", text, re.S).group(1)
    return re.findall(r'"(\w+)"', body)


_TS = open(os.path.join(ROOT, "src", "shared", "TowerStats.luau"), encoding="utf-8").read()
MULTIPLIERS, HIGHEST, FLAGS = (_luau_list(_TS, n) for n in ("MULTIPLIERS", "HIGHEST", "FLAGS"))


def tower_stats(t, tiers):
    """Shared/TowerStats.compute: `tiers` is the tier bought on each path (0 = none)."""
    mult = {f: 1 for f in MULTIPLIERS}
    high = {"shots": 1, "lineHits": 1}
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
        "hitsAir": t["hitsAir"],
        "pierces": flag.get("piercesArmor", False) or flag.get("stripsArmor", False),
        "armoredMult": mult["armoredMult"], "bossMult": mult["bossMult"],
        "markPercent": high.get("markPercent", 0), "brittlePercent": high.get("brittlePercent", 0),
        "burnDps": high.get("burnDps", 0), "burnSeconds": high.get("burnSeconds", 0),
        "bomblets": math.floor(high.get("bomblets", 0)), "bombletGenerations": math.floor(high.get("bombletGenerations", 0)),
        "freezeEvery": freeze_every, "freezeDamage": high.get("freezeDamage", 0),
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
    }


def path_stats(t, path_index, tier):
    tiers = [0] * len(t["paths"])
    if tier:
        tiers[path_index] = tier
    return tower_stats(t, tiers)


def cumulative_cost(t, path_index, tier):
    return t["baseCost"] + sum(s["cost"] for s in t["paths"][path_index]["tiers"][:tier])


# ---------------------------------------------------------------- wave mix

def band_mix(data):
    """Per band: share of Easy-solo EHP that is plain / armoured / flying / boss, and the total."""
    enemies = data["Enemies"]
    out = []
    for lo, hi in BANDS:
        share = {"plain": 0.0, "armoured": 0.0, "flying": 0.0, "boss": 0.0}
        for rd in data["Rounds"][lo - 1:hi]:
            for key, n in rd["counts"].items():
                e = enemies[key]
                ehp = n * e["effectiveHp"] * rd["hpMult"]
                kind = "boss" if e["boss"] else "flying" if e["flying"] else "armoured" if e["armored"] else "plain"
                share[kind] += ehp
        total = sum(share.values())
        out.append({**{k: v / total for k, v in share.items()}, "total": total})
    return out


# ---------------------------------------------------------------- effective DPS

def edps(s, mix, tuning, buff=None):
    """One tower's effective DPS against a band's mix (`buff`: an aura it stands in)."""
    buff = buff or {}
    rate = s["rate"] * (1 + buff.get("rate", 0) / 100)
    if s["damage"] <= 0 or rate <= 0:
        direct = 0.0
        hits = s["targets"]
    else:
        hits = s["lineHits"] if s["lineHits"] > 1 else s["targets"]
        share = tuning.get("BombletDamage", 0)
        bomb = sum((s["bomblets"] * share) ** g for g in range(1, s["bombletGenerations"] + 1)) if s["bomblets"] else 0
        damage = s["damage"] * (1 + buff.get("damage", 0) / 100)
        per_shot = damage * (1 + s["markPercent"] / 100) * (1 + s["brittlePercent"] / 100) * (hits + bomb)
        pierces = s["pierces"] or buff.get("pierces", False)
        weight = (mix["plain"] + mix["armoured"] * (s["armoredMult"] if pierces else 0)
                  + mix["flying"] * (1 if s["hitsAir"] else 0) + mix["boss"] * s["bossMult"])
        direct = rate * s["shots"] * per_shot * weight
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


def aura_credit(data, s, mix):
    """What this tower's aura adds to 3 neighbour T2 Hunting Blinds, one per Blind path."""
    buff = {"rate": s["auraRatePercent"], "damage": s["auraDamagePercent"], "pierces": s["auraPiercesArmor"]}
    if not (buff["rate"] or buff["damage"] or buff["pierces"]):
        return 0.0
    blind = data["Towers"][NEIGHBOUR_TOWER]
    tuning = data["Tuning"]
    gain = 0.0
    for i in range(min(NEIGHBOURS, len(blind["paths"]))):
        n = path_stats(blind, i, NEIGHBOUR_TIER)
        gain += edps(n, mix, tuning, buff) - edps(n, mix, tuning)
    return gain


def is_support(key, path):
    return key in SUPPORT_TOWERS or (key, path["id"]) in SUPPORT_PATHS


def value_table(data, mixes):
    """rows[(key, path index, tier)] = {cost, edps[band], ...} for every damage tower path."""
    rows = {}
    tuning = data["Tuning"]
    for key in data["TowerOrder"]:
        t = data["Towers"][key]
        if key in SUPPORT_TOWERS:
            continue
        for pi, path in enumerate(t["paths"]):
            for tier in range(0, len(path["tiers"]) + 1):
                s = path_stats(t, pi, tier)
                own = [edps(s, m, tuning) for m in mixes]
                aura = [aura_credit(data, s, m) for m in mixes]
                rows[(key, pi, tier)] = {
                    "cost": cumulative_cost(t, pi, tier),
                    "step": path["tiers"][tier - 1]["cost"] if tier else t["baseCost"],
                    "edps": [a + b for a, b in zip(own, aura)],
                    "aura": aura,
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
        r["dead"] = r["vsMedian"] > DEAD_X
    for key in data["TowerOrder"]:
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
    for key in data["TowerOrder"]:
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
    empty = magazine / rounds_per_second
    return peak, peak * empty / (empty + h["reload"] * g("reloadMult", 1))


def hero_lines(data, rows, mixes):
    tuning = data["Tuning"]
    per = int(tuning.get("RoundsPerLevel", 5))
    hero_x, tower_x = tuning.get("HeroDamagePerLevel", 0), tuning.get("TowerDamagePerLevel", 0)
    rounds = data["Rounds"]

    def required(r):
        rd = rounds[r - 1]
        length = round(sum(rd["counts"].values()) * rd["spawnGap"] + 14)
        return round(rd["effectiveHp"] / length, 1) if length else 0

    checkpoints = [(1, 1, 0), (5, 20, 1), (9, 40, 3)]  # (level, first round at it, band)
    t5 = {}
    for (key, pi, tier), r in rows.items():
        if tier == 5 and not r["support"]:
            t5[(key, pi)] = r["edps"]
    out = [f"  level (round): " + ", ".join(f"L{lv} (r{rd}) Required DPS {required(rd):g}, T5 towers {fmt(min(e[b] for e in t5.values()))}-{fmt(max(e[b] for e in t5.values()))} x{(1 + tower_x) ** (lv - 1):.2f}"
                                        for lv, rd, b in checkpoints)]
    findings = []
    for key in data["HeroOrder"]:
        h = data["Heroes"][key]
        base, _ = hero_dps(h, 0, 0)
        best = max(range(len(h["paths"])), key=lambda i: hero_dps(h, i, 5)[0])
        peak, sustained = hero_dps(h, best, 5)
        cash = sum(s["cost"] for s in h["paths"][best]["tiers"])
        cells = []
        for lv, rd, b in checkpoints:
            hs, ts = (1 + hero_x) ** (lv - 1), (1 + tower_x) ** (lv - 1)
            best_tower = max(e[b] for e in t5.values()) * ts
            cells.append(f"L{lv} {peak * hs:.0f}/{sustained * hs:.0f}")
            if peak * hs > best_tower:
                findings.append(f"HERO: {h['display']} {h['paths'][best]['id']} T5 at L{lv} ({peak * hs:.0f}) out-damages every T5 tower path's eDPS ({best_tower:.0f})")
        out.append(f"  {h['display'][:15]:<15} base {base:5.1f}  best {h['paths'][best]['id'][:10]:<10} T5 {' '.join(cells)}"
                   f"  cash/DPS {cash / max(1e-9, peak - base):.0f}")
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
    for key in data["TowerOrder"]:
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
                if any(r["aura"]):
                    line += f"  (aura {fmt(r['aura'][b])})"
                print(line)
    print("  medians (damage paths) marginal cash/eDPS: " + ", ".join(f"T{t} {fmt(m['marginal'])}" for t, m in medians.items()))
    print("support and control (own effect, not DPS; aura credit in rounds 31-40 on 3 T2 Blinds in brackets):")
    for line in support_lines(data, mixes):
        print(line)
    print("economy payback (Easy rounds of extra income; chests all collected; interest at its cap):")
    lines, econ = economy_lines(data)
    for line in lines:
        print(line)
    print("heroes (best path T5, peak/sustained DPS levelled; cash/DPS = that path's upgrade cash per DPS gained):")
    lines, heroes = hero_lines(data, rows, mixes)
    for line in lines:
        print(line)
    findings += econ + heroes
    print(f"Findings ({len(findings)}):")
    for f in findings:
        print(f"  - {f}")


def main():
    full = "--full" in sys.argv[1:]
    data = load()
    value_report(data, full)


if __name__ == "__main__":
    main()
