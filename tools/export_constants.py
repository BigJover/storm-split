#!/usr/bin/env python3
"""
Storm Split — constants exporter (Roblox / Luau).

Reads Storm-Split-Balance.xlsx and writes src/shared/Config.luau, the ONLY place
gameplay numbers live in code. Rojo syncs it into ReplicatedStorage.Shared.Config.

Run after every balance change. Never hand-edit Config.luau.

Usage:
    python3 tools/export_constants.py [path/to/Storm-Split-Balance.xlsx]

Requires: openpyxl   (pip3 install openpyxl)

Note: the spreadsheet must have been saved by Excel, Numbers, or LibreOffice
at least once after editing so formula results are cached. openpyxl reads
cached values; it does not calculate formulas itself.
"""

import os
import re
import sys

try:
    from openpyxl import load_workbook
except ImportError:
    sys.exit("openpyxl is required:  pip3 install openpyxl")

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DEFAULT_XLSX = os.path.join(ROOT, "Storm-Split-Balance.xlsx")
OUT_FILE = os.path.join(ROOT, "src", "shared", "Config.luau")

TIER_KEYS = ["HUSK", "BRUTE", "SHIELD", "ARMOR", "STORM", "LLAMA", "ZEP", "BARGE"]
ROUND_COLS = list(zip(range(2, 10), TIER_KEYS))  # columns B..I


# ---------------------------------------------------------------- readers

def ident(name):
    """'Starting cash' -> 'StartingCash'"""
    return "".join(p[:1].upper() + p[1:] for p in re.split(r"[^A-Za-z0-9]+", str(name)) if p)


def v(ws, r, c):
    return ws.cell(row=r, column=c).value


def num(x, default=0):
    if x is None or x == "" or x == "n/a":
        return default
    return x


def yes(x):
    return str(x).strip().lower() == "yes"


# Tower Upgrades ability columns (N onwards): (key, column, kind, default)
ABILITY_COLUMNS = [
    ("piercesArmor", 14, "bool", False),
    ("armoredMult", 15, "num", 1),
    ("bossMult", 16, "num", 1),
    ("shots", 17, "num", 1),
    ("lineHits", 18, "num", 1),
    ("splashMult", 19, "num", 1),
    ("markPercent", 20, "num", 0),
    ("stunSeconds", 21, "num", 0),
    ("stunsBosses", 22, "bool", False),
    ("knockback", 23, "num", 0),
    ("burnDps", 24, "num", 0),
    ("burnSeconds", 25, "num", 0),
    ("bomblets", 26, "num", 0),
    ("bombletGenerations", 27, "num", 0),
    ("auraRatePercent", 28, "num", 0),
    ("auraDamagePercent", 29, "num", 0),
    ("auraPiercesArmor", 30, "bool", False),
    # Chiller
    ("slowPercent", 31, "num", 0),
    ("slowLinger", 32, "num", 0),
    ("slowsBosses", 33, "bool", False),
    ("freezeEvery", 34, "num", 0),
    ("freezeSeconds", 35, "num", 0),
    ("freezeDamage", 36, "num", 0),
    ("freezeHoldsBosses", 37, "bool", False),
    ("brittlePercent", 38, "num", 0),
    ("stripsArmor", 39, "bool", False),
    # Quartermaster
    ("incomeMult", 40, "num", 1),
    ("interestPercent", 41, "num", 0),
    ("interestCap", 42, "num", 0),
    ("chests", 43, "num", 0),
    ("chestCash", 44, "num", 0),
    ("discountPercent", 45, "num", 0),
    ("sellRefund", 46, "num", 0),
    # Armory (Step 2)
    ("resistPercent", 47, "num", 0),
    ("thornsDamage", 48, "num", 0),
    ("stunBitersSeconds", 49, "num", 0),
    ("hunterRecoilMult", 50, "num", 1),
    ("hunterReloadMult", 51, "num", 1),
    ("hunterSpreadMult", 52, "num", 1),
    ("hunterRatePercent", 53, "num", 0),
    # Field Hospital (Step 2)
    ("healMult", 54, "num", 1),
    ("revives", 55, "bool", False),
    ("reviveSpeed", 56, "num", 0),
    ("medKits", 57, "num", 0),
    ("medKitHeal", 58, "num", 0),
    ("rescueRespawnMult", 59, "num", 0),
    ("auraHpPercent", 60, "num", 0),
    ("lastStand", 61, "bool", False),
    # Pierce-through (DECISIONS #126, #127): sizes one hit may drop; blank = 1
    ("sizeBreaks", 62, "num", 1),
]

# Paths allowed a Size breaks above 1 (DECISIONS #127, #134). A new one is a
# Director call: add it here and to PLAN's design table together.
BREAK_PATHS = {
    ("Longshot Perch", "Deadeye"), ("Longshot Perch", "Big Bore"), ("Hunting Blind", "Hardliner"),
}
HERO_BREAK_PATHS = {("Tracker", "Marksman"), ("Brush Beater", "Slug")}


def read_tuning(ws):
    out = {}
    for r in range(5, 200):
        name, val = v(ws, r, 1), v(ws, r, 2)
        if name and isinstance(val, (int, float)):
            out[ident(name)] = val
    return out


def read_towers(ws):
    towers, order = {}, []
    # Tower rows run from 5 down to the "Cost per DPS" line; a blank row in
    # between is a slot kept free (the Field Hospital's row 10 until T15).
    for r in range(5, 40):
        name = v(ws, r, 1)
        if name and str(name).startswith("Cost per DPS"):
            break
        if not name:
            continue
        # Internal key (Key column) stays fixed while the display name can change.
        key = str(v(ws, r, 15) or name).strip().upper()
        towers[key] = {
            "display": str(name),
            "role": v(ws, r, 2) or "",
            "baseCost": num(v(ws, r, 3)),
            "baseDamage": num(v(ws, r, 4)),
            "baseRate": num(v(ws, r, 5)),
            "baseTargets": num(v(ws, r, 6)),
            "range": num(v(ws, r, 8)),
            "hitsAir": str(v(ws, r, 9)).strip().lower() == "yes",
            "incomePerRound": num(v(ws, r, 10)),
            "splashRadius": num(v(ws, r, 12)),
            "slowPercent": num(v(ws, r, 13)),
            "unlockCost": num(v(ws, r, 14)),
            "maxHp": num(v(ws, r, 16)),
            "healPerSecond": num(v(ws, r, 17)),
            "resistPercent": num(v(ws, r, 18)),
            "paths": [],
        }
        order.append(key)
    return towers, order


def attach_paths(ws, towers):
    by_display = {t["display"]: k for k, t in towers.items()}
    index = {}
    r = 5
    while True:
        tower = v(ws, r, 1)
        if not tower:
            break
        key = by_display.get(str(tower).strip())
        if key is None:
            sys.exit(f"Tower Upgrades row {r}: unknown tower '{tower}' (not on the Towers sheet)")
        pid = str(v(ws, r, 2))
        if (key, pid) not in index:
            path = {"id": pid, "focus": v(ws, r, 3) or "", "tiers": []}
            index[(key, pid)] = path
            towers[key]["paths"].append(path)
        tier = int(v(ws, r, 4))
        index[(key, pid)]["tiers"].append({
            "name": str(v(ws, r, 13) or ""),
            "cost": num(v(ws, r, 5)),
            "damageMult": num(v(ws, r, 7), 1),
            "rateMult": num(v(ws, r, 8), 1),
            "targetsMult": num(v(ws, r, 9), 1),
            "rangeMult": num(v(ws, r, 12), 1),
            "swapsModel": tier in (3, 5),
            **{
                key: (yes(v(ws, r, col)) if kind == "bool" else num(v(ws, r, col), default))
                for key, col, kind, default in ABILITY_COLUMNS
            },
        })
        r += 1


HERO_BASE_COLUMNS = [
    # (key, column, kind)
    ("display", 2, "text"), ("role", 3, "text"), ("ability", 4, "text"),
    ("damage", 5, "num"), ("rate", 6, "num"), ("fireMode", 7, "text"), ("magazine", 8, "num"),
    ("reload", 9, "num"), ("pellets", 10, "num"), ("spread", 11, "num"), ("recoilPerShot", 12, "num"),
    ("recoilMax", 13, "num"), ("recoilRecovery", 14, "num"), ("range", 15, "num"),
    ("piercesArmor", 16, "bool"), ("hitsAir", 17, "bool"), ("splashRadius", 18, "num"),
    ("abilityPower", 19, "num"), ("abilitySeconds", 20, "num"), ("abilityRadius", 21, "num"),
    ("abilityCooldown", 22, "num"),
    ("unlockCost", 24, "num"),
    ("weapon", 25, "text"),
    ("abilityKind", 26, "text"),
]

# Hero Upgrades effect columns, cumulative per tier: (key, column, kind, default when blank).
# "mult" multiplies the hero's base; "set" overrides it when present.
HERO_UPGRADE_COLUMNS = [
    ("rateMult", 7, "mult", 1), ("magazineMult", 8, "mult", 1), ("reloadMult", 9, "mult", 1),
    ("spreadMult", 10, "mult", 1), ("recoilMult", 11, "mult", 1), ("rangeMult", 12, "mult", 1),
    ("damageMult", 13, "mult", 1), ("fireMode", 14, "text", ""), ("burstCount", 15, "num", 0),
    ("guns", 16, "num", 0), ("pellets", 17, "num", 0), ("shotsPerTrigger", 18, "num", 0),
    ("pierce", 19, "num", 0), ("bounces", 20, "num", 0), ("piercesArmor", 21, "bool", False),
    ("hitsAir", 22, "bool", False), ("burnDps", 23, "num", 0), ("burnSeconds", 24, "num", 0),
    ("splashRadius", 25, "num", 0), ("knockback", 26, "num", 0), ("markPercent", 27, "num", 0),
    ("markedDamageMult", 28, "mult", 1), ("abilityCooldownMult", 29, "mult", 1),
    ("beltFed", 30, "bool", False), ("stillRecoilMult", 31, "mult", 1), ("spinUp", 32, "mult", 1),
    ("scope", 33, "bool", False),
    ("igniteSeconds", 34, "num", 0),
    ("igniteShare", 35, "num", 0),
    # Field Medic (PLAN T16): the Triage Kit heal, Second Wind guard, Muzzle rounds.
    ("healMult", 36, "mult", 1), ("healRadiusMult", 37, "mult", 1), ("healRepairsTowers", 38, "bool", False),
    ("guardPercent", 39, "num", 0), ("guardSeconds", 40, "num", 0),
    ("slowPercent", 41, "num", 0), ("slowSeconds", 42, "num", 0),
    ("jawLockSeconds", 43, "num", 0), ("jawLockSpread", 44, "num", 0),
    # Pierce-through (DECISIONS #134): blank = 1
    ("sizeBreaks", 45, "num", 1),
    # Hero tier 6 (PLAN T52, DECISIONS #132-#134): handling and fire-mode mechanics.
    ("burnPatchReach", 46, "num", 0),  # blank = Tuning Burn patch min reach (3)
    ("staggeredReload", 47, "bool", False),  # Hot Swap: dual guns reload one at a time
    ("ricochetReload", 48, "num", 0),  # Trick Reload: rounds back per ricochet take-down
    ("burstRecoilReset", 49, "bool", False),  # Five-Round Burst
    ("spunUpBelt", 50, "bool", False),  # Endless Belt: no rounds used while fully spun up
    ("stillSpreadMult", 51, "mult", 1),  # Thunder Slug: spread while standing still
    ("scopedSpreadMult", 52, "mult", 1),  # Heart Shot: spread while scoped
    ("abilityCharges", 53, "num", 0),  # Rapid Response; blank = 1 charge
]

# Every hero path has this many tiers (DECISIONS #133: "the same amount of upgrades on
# each path").
HERO_TIERS = 6

ABILITY_KINDS = ("MARK", "OVERDRIVE", "AIRBURST", "HEAL")

FIRE_MODES = ("semi", "auto", "burst")


def read_heroes(ws):
    heroes, order = {}, []
    r = 5
    while v(ws, r, 1):
        key = str(v(ws, r, 1)).strip().upper()
        hero = {"paths": []}
        for field, col, kind in HERO_BASE_COLUMNS:
            raw = v(ws, r, col)
            hero[field] = yes(raw) if kind == "bool" else (str(raw or "").strip() if kind == "text" else num(raw))
        hero["fireMode"] = hero["fireMode"].lower()
        heroes[key] = hero
        order.append(key)
        r += 1
    return heroes, order


def attach_hero_paths(ws, heroes):
    by_display = {h["display"]: h for h in heroes.values()}
    index = {}
    r = 5
    while v(ws, r, 1):
        hero = by_display.get(str(v(ws, r, 1)).strip())
        if hero is None:
            sys.exit(f"Hero Upgrades row {r}: unknown hero '{v(ws, r, 1)}' (not on the Heroes sheet)")
        pid = str(v(ws, r, 2))
        if (hero["display"], pid) not in index:
            path = {"id": pid, "focus": v(ws, r, 3) or "", "tiers": []}
            index[(hero["display"], pid)] = path
            hero["paths"].append(path)
        tier = num(v(ws, r, 4))
        if tier != len(index[(hero["display"], pid)]["tiers"]) + 1:
            sys.exit(f"Hero Upgrades row {r}: {hero['display']} {pid} Tier {tier} is out of order (a path's rows run 1, 2, 3... top to bottom)")
        step = {"name": str(v(ws, r, 5) or ""), "cost": num(v(ws, r, 6))}
        for field, col, kind, default in HERO_UPGRADE_COLUMNS:
            raw = v(ws, r, col)
            if kind == "bool":
                step[field] = yes(raw)
            elif kind == "text":
                step[field] = str(raw or "").strip().lower()
            else:
                step[field] = num(raw, default)
        index[(hero["display"], pid)]["tiers"].append(step)
        r += 1


# Mastery small perks (PLAN T51, DECISIONS #135): the only columns allowed after the
# fixed ones (A-I), found by header: (Config field, header, kind). "add" columns are
# blank = 0 and may only rise with the level; "x" columns are blank = 1, in (0, 1], and
# may only fall. None touches damage, fire rate, reload, recoil, spread, max HP or move
# speed (tools/audit.py checks the headers and fields too).
MASTERY_FIXED_COLUMNS = 9
MASTERY_SMALL_PERKS = [
    ("pickupReachAdd", "Pick-up reach +", "add"),
    ("healPerRoundAdd", "Heal per round +", "add"),
    ("respawnMult", "Respawn x", "x"),
    ("repairCostMult", "Repair cost x", "x"),
]
# The first level a small perk may change at (levels 1-5 stay blank / 1).
MASTERY_SMALL_PERK_FIRST = 6


def read_mastery(ws):
    columns = {}
    for c in range(MASTERY_FIXED_COLUMNS + 1, ws.max_column + 1):
        head = v(ws, 4, c)
        if head is None:
            continue
        head = str(head).strip()
        if head not in [h for _, h, _ in MASTERY_SMALL_PERKS]:
            sys.exit(f"Mastery row 4: column '{head}' is not a small perk this game knows"
                     f" ({', '.join(h for _, h, _ in MASTERY_SMALL_PERKS)}; PLAN T51)")
        columns[head] = c
    for _, head, _ in MASTERY_SMALL_PERKS:
        if head not in columns:
            sys.exit(f"Mastery row 4: no '{head}' column (small perks are found by header, PLAN T51)")
    out = []
    for r in range(5, 25):
        lvl = v(ws, r, 1)
        if lvl is None:
            break
        row = {
            "coreCost": num(v(ws, r, 2)),
            "unlock": v(ws, r, 5) or "",
            "upgradeDiscountPercent": num(v(ws, r, 6)),
            "abilityCooldownMult": num(v(ws, r, 7), 1),
            "freeFirstUpgrade": yes(v(ws, r, 8)),
            "crossoverCap": int(num(v(ws, r, 9), 2)),
        }
        for field, head, kind in MASTERY_SMALL_PERKS:
            row[field] = num(v(ws, r, columns[head]), 0 if kind == "add" else 1)
        out.append(row)
    return out


def validate_small_perks(data, problems):
    """PLAN T51: each small perk column is monotone in the level, neutral before
    MASTERY_SMALL_PERK_FIRST, and every level where one changes says so in its
    'Unlock at this level' text with that number (x columns as a % off)."""
    mastery = data["Mastery"]
    for field, head, kind in MASTERY_SMALL_PERKS:
        previous = 0 if kind == "add" else 1
        for i, row in enumerate(mastery, start=1):
            value = row[field]
            if not isinstance(value, (int, float)):
                problems.append(f"Mastery level {i}: '{head}' must be a number")
                continue
            if kind == "add" and (value < 0 or value < previous):
                problems.append(f"Mastery level {i}: '{head}' {value:g} must be 0 or more and never below level {i - 1}'s {previous:g}")
            if kind == "x" and (not 0 < value <= 1 or value > previous):
                problems.append(f"Mastery level {i}: '{head}' {value:g} must be in (0, 1] and never above level {i - 1}'s {previous:g}")
            if i < MASTERY_SMALL_PERK_FIRST and value != (0 if kind == "add" else 1):
                problems.append(f"Mastery level {i}: '{head}' must be blank{'' if kind == 'add' else ' or 1'} below level {MASTERY_SMALL_PERK_FIRST}")
            if value != previous:
                shown = value if kind == "add" else round((1 - value) * 100, 6)
                numbers = [float(n) for n in re.findall(r"\d+(?:\.\d+)?", str(row["unlock"]))]
                if not any(abs(n - shown) < 1e-6 for n in numbers):
                    problems.append(f"Mastery level {i}: '{head}' changes to {value:g}, but its 'Unlock at this level' text doesn't say {shown:g}")
            previous = value


# Mastery Perks effect columns, found by header text: (Config field, header, kind).
# Blank = 0. There is no gun-damage column, on purpose (DECISIONS #99).
PERK_COLUMNS = [
    ("abilitySecondsAdd", "Ability seconds +"),
    ("abilityRadiusAdd", "Ability radius +"),
    ("abilityPowerAdd", "Ability power +"),
    ("markExtra", "Extra marks"),
    ("markExtraPowerMult", "Extra mark power x"),
    ("markExtraReach", "Extra mark reach"),
    ("strikeBurnPercent", "Strike burn % per s"),
    ("strikeBurnSeconds", "Strike burn (s)"),
]
PERK_HEADER_ROW = 4
# The mastery levels every hero must have a perk at (PLAN round 3 T32).
# To remove the perks (DECISIONS #107, which restates #97's reversal): delete rows
# 5-12 of Mastery Perks and set PERK_LEVELS = (); Config.MasteryPerks is then empty
# and HeroStats merges nothing. Blanking the effect cells instead fails the export
# (every hero needs both perks, level 15 worth more than level 10). To weaken them,
# lower the cells but keep 15 > 10.
PERK_LEVELS = (10, 15)


def read_mastery_perks(ws):
    """Mastery Perks: one row per (hero key, mastery level), columns found by header.

    Returns {heroKey: [perk, ...]} sorted by level, each perk with `level`, `name`,
    `text` and every PERK_COLUMNS field (zeros included)."""
    columns = {}
    for c in range(1, ws.max_column + 1):
        head = v(ws, PERK_HEADER_ROW, c)
        if head is not None:
            columns[str(head).strip()] = c
    wanted = ["Hero key", "Mastery level", "Name", "Text"] + [head for _, head in PERK_COLUMNS]
    for head in wanted:
        if head not in columns:
            sys.exit(f"Mastery Perks row {PERK_HEADER_ROW}: no '{head}' column (columns are found by header)")
    perks = {}
    r = PERK_HEADER_ROW + 1
    while v(ws, r, columns["Hero key"]):
        key = str(v(ws, r, columns["Hero key"])).strip().upper()
        perk = {
            "level": num(v(ws, r, columns["Mastery level"])),
            "name": str(v(ws, r, columns["Name"]) or "").strip(),
            "text": str(v(ws, r, columns["Text"]) or "").strip(),
        }
        for field, head in PERK_COLUMNS:
            perk[field] = num(v(ws, r, columns[head]))
        perks.setdefault(key, []).append(perk)
        r += 1
    for rows in perks.values():
        rows.sort(key=lambda p: p["level"] if isinstance(p["level"], (int, float)) else 0)
    return perks


def read_enemies(ws):
    enemies = {}
    r = 5
    while True:
        key = v(ws, r, 1)
        if not key or str(key).startswith("EFFECTIVE"):
            break
        splits = v(ws, r, 6)
        enemies[str(key)] = {
            "display": v(ws, r, 2) or "",
            "hp": num(v(ws, r, 4)),
            "speedMult": num(v(ws, r, 5), 1),
            "splitsInto": "" if splits in (None, "—", "-") else str(splits),
            "splitCount": int(num(v(ws, r, 7))),
            "effectiveHp": num(v(ws, r, 8)),
            "cashValue": num(v(ws, r, 9)),
            "flying": str(v(ws, r, 10)).strip().lower() == "yes",
            "armored": yes(v(ws, r, 12)),
            "boss": yes(v(ws, r, 13)),
            "sizes": max(1, int(num(v(ws, r, 14), 1))),
            # Step 2: the bite (values at the largest size, on Easy)
            "meleeName": str(v(ws, r, 15) or ""),
            "meleeDamage": num(v(ws, r, 16)),
            "meleeEvery": num(v(ws, r, 17)),
            "meleeReach": num(v(ws, r, 18)),
            # Step 2: the ranged attack (a projectile; values at the largest size, on Easy)
            "rangedName": str(v(ws, r, 19) or ""),
            "rangedDamage": num(v(ws, r, 20)),
            "rangedEvery": num(v(ws, r, 21)),
            "rangedReach": num(v(ws, r, 22)),
            "projectileSpeed": num(v(ws, r, 23)),
            "impactRadius": num(v(ws, r, 24)),
            # Pierce-through (DECISIONS #126): sizes taken off every hit's breaks
            "breakResist": num(v(ws, r, 25)),
        }
        r += 1
    return enemies


def read_rounds(ws):
    out = []
    for i in range(40):
        r = 5 + i
        counts = {}
        for col, key in ROUND_COLS:
            n = int(num(v(ws, r, col)))
            if n:
                counts[key] = n
        out.append({
            "counts": counts,
            "hpMult": num(v(ws, r, 11), 1),
            "spawnGap": num(v(ws, r, 12), 1),
            "effectiveHp": num(v(ws, r, 13)),
        })
    return out


def read_daily_haul(ws):
    """Daily Haul: one row per calendar day (Day, Amber, Note)."""
    out = []
    r = 5
    while v(ws, r, 1) is not None:
        if v(ws, r, 1) != len(out) + 1:
            sys.exit(f"Daily Haul row {r}: Day must be {len(out) + 1} (days run 1, 2, 3, ...)")
        out.append({"amber": num(v(ws, r, 2))})
        r += 1
    return out


BOUNTY_POOLS = ["daily", "weekly"]
BOUNTY_SLOTS = ["easy", "medium", "hard"]  # the order active slots fill in (Shared/Bounties)
# Event -> what its Target column may hold
BOUNTY_EVENTS = {
    "pop": "species", "popTotal": "none", "clear": "difficulty", "reachRound": "round",
    "ability": "none", "build": "none", "upgrade": "none", "repair": "none",
}


def read_bounties(ws):
    """Bounties: Id, Pool, Slot, Event, Target, Count, Amber, Title, Text.

    Target is a species key (pop), a difficulty key (clear: that one or harder) or a
    round (reachRound: reach that round Count times; blank = reach round Count). The
    round goes out as `round`, so `target` is always a string."""
    bounties, order = {}, []
    r = 5
    while v(ws, r, 1):
        key = str(v(ws, r, 1)).strip()
        event, target = str(v(ws, r, 4) or "").strip(), v(ws, r, 5)
        is_round = event == "reachRound" and isinstance(target, (int, float)) and not isinstance(target, bool)
        if key in bounties:
            sys.exit(f"Bounties row {r}: Id '{key}' is used twice")
        order.append(key)
        bounties[key] = {
            "title": str(v(ws, r, 8) or "").strip(),
            "text": str(v(ws, r, 9) or "").strip(),
            "pool": str(v(ws, r, 2) or "").strip().lower(),
            "slot": str(v(ws, r, 3) or "").strip().lower(),
            "event": event,
            "target": "" if target is None or is_round else str(target).strip().upper(),
            "round": target if is_round else 0,
            "count": num(v(ws, r, 6)),
            "amber": num(v(ws, r, 7)),
        }
        r += 1
    return bounties, order


# ---------------------------------------------------------------- validation

def active_slots(count):
    """The slots of `count` active bounties: easy, medium, hard, easy, ... (Shared/Bounties)."""
    return [BOUNTY_SLOTS[i % len(BOUNTY_SLOTS)] for i in range(max(0, int(count)))]


def validate_rewards(data, problems, notes):
    """Daily Haul and Bounties (PLAN round 2 T25). "Log-ins never beat playing" is
    checked here, not left to today's seeds (DECISIONS #71)."""
    tuning, difficulties = data["Tuning"], data["Difficulties"]

    def whole(x, low=0, high=None):
        return (isinstance(x, (int, float)) and not isinstance(x, bool) and float(x).is_integer()
                and x >= low and (high is None or x <= high))

    levers = {
        "DailyBounties": (1, None), "WeeklyBounties": (1, None), "DailySwaps": (0, None),
        "WeeklySwaps": (0, None), "HaulResetsAfterMissedDays": (0, None),
        "DailyResetHourUTC": (0, 23), "WeeklyResetDay": (1, 7),
    }
    for key, (low, high) in levers.items():
        if key not in tuning:
            problems.append(f"Tuning is missing '{key}' (REWARDS; Shared/Bounties reads it by name)")
        elif not whole(tuning[key], low, high):
            problems.append(f"Tuning {key}: must be a whole number {low}{'+' if high is None else f'-{high}'}")
    if "EASY" not in difficulties or "CHAOS" not in difficulties:
        problems.append("Rewards are checked against the Easy and Chaos clear rewards: the Difficulty sheet needs both rows")
        return
    easy, chaos = difficulties["EASY"]["clearReward"], difficulties["CHAOS"]["clearReward"]

    haul = data["DailyHaul"]
    if not haul:
        problems.append("Daily Haul: needs at least one day")
    for i, day in enumerate(haul, start=1):
        if not whole(day["amber"], 1):
            problems.append(f"Daily Haul day {i}: Amber must be a whole number above 0")
        elif day["amber"] >= easy:
            problems.append(f"Daily Haul day {i}: {day['amber']:g} Amber is not below the Easy clear reward ({easy:g}); log-ins must never beat playing")
    week = sum(day["amber"] for day in haul if isinstance(day["amber"], (int, float)))
    if week > 2 * easy:
        problems.append(f"Daily Haul: the whole calendar pays {week:g} Amber, more than two Easy clears ({2 * easy:g})")

    bounties = data["Bounties"]
    free_air = [x["display"] for block in ("Towers", "Heroes") for x in data[block].values()
                if x["unlockCost"] == 0 and x["hitsAir"]]
    for key, b in bounties.items():
        where = f"Bounty {key}"
        if not re.match(r"^[A-Z][A-Z0-9_]*$", key):
            problems.append(f"{where}: Id must be CAPITALS_AND_UNDERSCORES (it is saved in profiles)")
        if b["pool"] not in BOUNTY_POOLS:
            problems.append(f"{where}: Pool must be one of {', '.join(BOUNTY_POOLS)}")
        if b["slot"] not in BOUNTY_SLOTS:
            problems.append(f"{where}: Slot must be one of {', '.join(BOUNTY_SLOTS)}")
        if not b["title"] or not b["text"]:
            problems.append(f"{where}: needs a Title and a Text")
        if not whole(b["count"], 1):
            problems.append(f"{where}: Count must be a whole number above 0")
        if not whole(b["amber"], 1):
            problems.append(f"{where}: Amber must be a whole number above 0")
        kind = BOUNTY_EVENTS.get(b["event"])
        target = b["target"]
        if kind is None:
            problems.append(f"{where}: Event must be one of {', '.join(BOUNTY_EVENTS)}")
        elif kind == "species":
            enemy = data["Enemies"].get(target)
            if not enemy:
                problems.append(f"{where}: Target '{target}' is no key on the Enemies sheet")
            elif enemy["flying"] and not free_air:
                problems.append(f"{where}: {enemy['display']} flies, and no free tower or hero has Hits air (DECISIONS #66: bounties only ask for what the free roster can do)")
        elif kind == "difficulty":
            if target and target not in difficulties:
                problems.append(f"{where}: Target '{target}' is no difficulty (blank = any)")
        elif kind == "round":
            if target:
                problems.append(f"{where}: Target must be a round number or blank, not '{target}'")
            reach = b["round"] or b["count"]
            if not whole(reach, 1, len(data["Rounds"])):
                problems.append(f"{where}: round {reach} isn't one of the {len(data['Rounds'])} rounds")
        elif target:
            problems.append(f"{where}: a '{b['event']}' bounty takes no Target")

    def amber(b):
        return b["amber"] if isinstance(b["amber"], (int, float)) else 0

    best = {}  # pool -> the most one set can pay
    for pool, lever in zip(BOUNTY_POOLS, ("DailyBounties", "WeeklyBounties")):
        slots = active_slots(tuning.get(lever, 0) if whole(tuning.get(lever), 0) else 0)
        total = 0
        for slot in BOUNTY_SLOTS:
            rows = sorted((amber(b) for b in bounties.values() if b["pool"] == pool and b["slot"] == slot), reverse=True)
            used = slots.count(slot)
            if used and len(rows) < used + 2:
                problems.append(f"Bounties: {pool} {slot} has {len(rows)} entries; it needs {used + 2} ({used} on the board + 2, so a swap always has a choice)")
            total += sum(rows[:used])
        best[pool] = total
    if best["daily"] >= easy:
        problems.append(f"Bounties: a day's set can pay {best['daily']:g} Amber, not below the Easy clear reward ({easy:g})")
    for key, b in bounties.items():
        if b["pool"] == "weekly" and amber(b) >= chaos:
            problems.append(f"Bounty {key}: {b['amber']:g} Amber is not below the Chaos clear reward ({chaos:g})")
    if best["weekly"] > chaos:
        problems.append(f"Bounties: a week's set can pay {best['weekly']:g} Amber, more than the Chaos clear reward ({chaos:g})")
    notes.append(f"rewards: Daily Haul {week:g} Amber over {len(haul)} days (bar {2 * easy:g}); daily bounties up to {best['daily']:g} (< {easy:g}),"
                 f" weekly up to {best['weekly']:g} (<= {chaos:g}); {sum(1 for b in bounties.values() if b['pool'] == 'daily')} daily + "
                 f"{sum(1 for b in bounties.values() if b['pool'] == 'weekly')} weekly in the pools")


def perk_worth(hero, perk):
    """Worth % of one perk (DECISIONS #99): 100 x (seconds added / base + radius added /
    base + power added / base + extra marks x extra-mark strength) + burn % per second
    x burn seconds. None when a perk adds to a base of 0 (reported by the caller)."""
    share = 0.0
    for add, base in (("abilitySecondsAdd", "abilitySeconds"), ("abilityRadiusAdd", "abilityRadius"),
                      ("abilityPowerAdd", "abilityPower")):
        if perk[add]:
            if not hero[base]:
                return None
            share += perk[add] / hero[base]
    share += perk["markExtra"] * perk["markExtraPowerMult"]
    return round(100 * share + perk["strikeBurnPercent"] * perk["strikeBurnSeconds"], 6)


def validate_perks(data, problems, notes):
    """Mastery Perks (PLAN round 3 T32). "Level 15 is objectively stronger" and
    "PvP-safe" are rules here, not opinions (DECISIONS #99)."""
    tuning, heroes, perks = data["Tuning"], data["Heroes"], data["MasteryPerks"]
    cap = tuning.get("MasteryPerkWorthCap")
    if not isinstance(cap, (int, float)) or cap <= 0:
        problems.append("Tuning is missing 'Mastery perk worth cap' (MASTERY PERKS; the exporter checks every perk against it)")
        cap = None
    shown = []
    for key, rows in perks.items():
        hero = heroes.get(key)
        if hero is None:
            problems.append(f"Mastery Perks: hero key '{key}' is not on the Heroes sheet")
            continue
        kind = hero["abilityKind"].upper()
        seen, worth = set(), {}
        for perk in rows:
            level = perk["level"]
            where = f"Mastery Perks {key} level {level}"
            if (not isinstance(level, (int, float)) or isinstance(level, bool) or not float(level).is_integer()
                    or not 1 <= level <= len(data["Mastery"])):
                problems.append(f"{where}: Mastery level must be a whole number 1-{len(data['Mastery'])}")
                continue
            if level in seen:
                problems.append(f"{where}: this hero has two perks at that level")
            seen.add(level)
            if not perk["name"] or not perk["text"]:
                problems.append(f"{where}: needs a Name and a Text")
            bad = [head for field, head in PERK_COLUMNS
                   if not isinstance(perk[field], (int, float)) or isinstance(perk[field], bool) or perk[field] < 0]
            if bad:
                problems.append(f"{where}: {', '.join(bad)} must be a number >= 0")
                continue
            if kind == "AIRBURST" and perk["abilitySecondsAdd"]:
                problems.append(f"{where}: 'Ability seconds +' on an AIRBURST hero would add stun time (no perk adds stun, DECISIONS #99)")
            if kind != "HEAL" and perk["abilityPowerAdd"]:
                problems.append(f"{where}: 'Ability power +' is only for a HEAL hero (no perk raises damage or a damage bonus, DECISIONS #99)")
            marks = (perk["markExtra"], perk["markExtraPowerMult"], perk["markExtraReach"])
            if kind != "MARK" and any(marks):
                problems.append(f"{where}: the Extra mark columns are only for a MARK hero")
            elif any(marks) and not (all(marks) and float(perk["markExtra"]).is_integer()):
                problems.append(f"{where}: Extra marks (a whole number), Extra mark power x and Extra mark reach go together")
            burn = (perk["strikeBurnPercent"], perk["strikeBurnSeconds"])
            if kind != "AIRBURST" and any(burn):
                problems.append(f"{where}: the Strike burn columns are only for an AIRBURST hero")
            elif any(burn) and not all(burn):
                problems.append(f"{where}: Strike burn % per s and Strike burn (s) go together")
            w = perk_worth(hero, perk)
            if w is None:
                problems.append(f"{where}: adds to an ability value that is 0 on the Heroes sheet, so its worth can't be measured")
                continue
            worth[level] = w
            if cap is not None and w > cap:
                problems.append(f"{where}: worth {w:g}% is above the Mastery perk worth cap ({cap:g}%)")
        low, high = PERK_LEVELS
        if low in worth and high in worth:
            if worth[high] <= worth[low]:
                problems.append(f"Mastery Perks {key}: level {high} (worth {worth[high]:g}%) must be worth more than level {low} ({worth[low]:g}%)")
            shown.append(f"{hero['display']} {worth[low]:g} / {worth[high]:g}")
    for key, hero in heroes.items():
        have = {p["level"] for p in perks.get(key, [])}
        for level in PERK_LEVELS:
            if level not in have:
                problems.append(f"Mastery Perks: {hero['display']} ({key}) has no level-{level} perk")
    if shown:
        limit = f", cap {cap:g}" if cap is not None else ""
        notes.append(f"mastery perks worth % (level {PERK_LEVELS[0]} / {PERK_LEVELS[1]}{limit}): " + ", ".join(shown))


XP_LEVERS = ["XPPerLevel", "XPPerPop", "PopXPCapPerRound", "TeamPopShare", "HeroLevelLeadCap"]


def validate_xp(data, problems, notes):
    """Hero XP levers (PLAN round 3 T32, DECISIONS #100-#101)."""
    tuning = data["Tuning"]
    missing = [k for k in XP_LEVERS if k not in tuning]
    for key in missing:
        problems.append(f"Tuning is missing '{key}' (HERO XP; the game reads it by name)")
    negative = [k for k in XP_LEVERS if k in tuning and tuning[k] < 0]
    for key in negative:
        problems.append(f"Tuning {key}: must not be negative")
    per_level, rounds_per_level = tuning.get("XPPerLevel", 0), tuning.get("RoundsPerLevel", 0)
    if missing or negative or rounds_per_level <= 0:
        return
    if per_level <= 0 or per_level % rounds_per_level != 0:
        problems.append(f"Tuning XPPerLevel ({per_level:g}) must be a whole multiple of RoundsPerLevel ({rounds_per_level:g}), so a cleared round banks a whole Round XP")
        return
    # A hunter at the pop-XP cap every round: the lead cap must be a safety net, not the rule.
    per_round = per_level / rounds_per_level + tuning["PopXPCapPerRound"]
    lead_cap, worst, worst_round = tuning["HeroLevelLeadCap"], 0, 0
    for r in range(1, len(data["Rounds"]) + 1):
        lead = (1 + int(r * per_round // per_level)) - (1 + r // int(rounds_per_level))
        if lead > worst:
            worst, worst_round = lead, r
    if worst > lead_cap:
        problems.append(f"Hero XP: a hunter at the pop-XP cap every round is {worst} levels above the round level after round {worst_round}, more than HeroLevelLeadCap ({lead_cap:g})")
    notes.append(f"hero XP: {per_level / rounds_per_level:g} a cleared round + up to {tuning['PopXPCapPerRound']:g} pop XP; at the cap a hunter leads the round level by at most {worst} (lead cap {lead_cap:g})")



def guard_levels(data):
    """(tower level, highest hero level) in play during the last round: what the
    hero-vs-tower guard compares. tools/value.py asserts its last checkpoint matches."""
    tuning = data["Tuning"]
    round_level = 1 + (len(data["Rounds"]) - 1) // max(1, int(tuning.get("RoundsPerLevel", 5)))
    return round_level, round_level + int(tuning.get("HeroLevelLeadCap", 0))


def validate(data):
    problems = []
    enemies = data["Enemies"]

    for key in enemies:
        seen, cur, depth = set(), key, 0
        while cur:
            if cur in seen:
                problems.append(f"Split cycle starting at {key}")
                break
            seen.add(cur)
            nxt = enemies.get(cur, {}).get("splitsInto", "")
            if nxt and nxt not in enemies:
                problems.append(f"{cur} splits into unknown tier '{nxt}'")
                break
            cur, depth = nxt, depth + 1
            if depth > 10:
                problems.append(f"Split chain from {key} exceeds depth 10")
                break

    def descendants(k, d=0):
        e = enemies.get(k)
        if d > 12 or not e or not e["splitsInto"]:
            return 0
        n = e["splitCount"]
        return n + n * descendants(e["splitsInto"], d + 1)

    worst = max((descendants(k), k) for k in enemies)
    cap = data["Tuning"].get("MaxConcurrentEnemies", 0)
    notes = [
        f"worst-case split cascade: {worst[0]} enemies from one {worst[1]} (live cap {cap})"
        if worst[0] > 0
        else f"no splitting: dinos shrink in place (live cap {cap})"
    ]

    for i, rd in enumerate(data["Rounds"], start=1):
        for k in rd["counts"]:
            if k not in enemies:
                problems.append(f"Round {i} references unknown tier '{k}'")

    for key, e in enemies.items():
        if e["meleeDamage"] > 0 and (e["meleeEvery"] <= 0 or e["meleeReach"] <= 0):
            problems.append(f"{key} bites (Melee damage > 0) but needs Melee every and Melee reach above 0")
        if not isinstance(e["breakResist"], (int, float)) or e["breakResist"] < 0 or e["breakResist"] != int(e["breakResist"]):
            problems.append(f"{key}: Break resist must be a whole number >= 0")
        if e["meleeDamage"] > 0 and not e["meleeName"]:
            problems.append(f"{key} bites but its Melee name is empty")
        if e["rangedDamage"] > 0 and (min(e["rangedEvery"], e["rangedReach"], e["projectileSpeed"], e["impactRadius"]) <= 0 or not e["rangedName"]):
            problems.append(f"{key} has a ranged attack but needs a name, Ranged every, reach, Projectile speed and Impact radius above 0")
    for key, d in data["Difficulties"].items():
        if d["dinoDamageMult"] <= 0:
            problems.append(f"Difficulty {key} needs a Dino damage x above 0")

    for key, t in data["Towers"].items():
        if not isinstance(t["maxHp"], (int, float)) or t["maxHp"] <= 0:
            problems.append(f"{key} needs a Max HP above 0 (Towers column P)")
        for p in t["paths"]:
            for i, step in enumerate(p["tiers"], start=1):
                if not isinstance(step["cost"], (int, float)) or step["cost"] <= 0:
                    problems.append(
                        f"{key} {p['id']} tier {i} has no upgrade cost. If the spreadsheet was saved by a "
                        "script, open it in Numbers and Export To Excel so formulas are recalculated."
                    )
                if not step["name"].strip():
                    problems.append(f"{key} {p['id']} tier {i} has no Name (Tower Upgrades, column M)")
                if not isinstance(step["rangeMult"], (int, float)) or step["rangeMult"] <= 0:
                    problems.append(f"{key} {p['id']} tier {i}: Range x must be a positive number")
                for field, _, kind, _ in ABILITY_COLUMNS:
                    if kind == "num" and (not isinstance(step[field], (int, float)) or step[field] < 0):
                        problems.append(f"{key} {p['id']} tier {i}: {field} must be a number >= 0")
                for field in ("shots", "lineHits", "sizeBreaks"):
                    if step[field] < 1 or step[field] != int(step[field]):
                        problems.append(f"{key} {p['id']} tier {i}: {field} must be a whole number >= 1")
                if step["sizeBreaks"] > 1 and (t["display"], p["id"]) not in BREAK_PATHS:
                    problems.append(f"{key} {p['id']} tier {i}: Size breaks above 1 on a path not in the design table (DECISIONS #127; a Director call)")

    for key, h in data["Heroes"].items():
        name = h["display"]
        if h["fireMode"] not in FIRE_MODES:
            problems.append(f"Hero {name}: Fire mode must be one of {', '.join(FIRE_MODES)}")
        for field in ("damage", "rate", "magazine", "reload", "pellets", "range", "abilityCooldown"):
            if not isinstance(h[field], (int, float)) or h[field] <= 0:
                problems.append(f"Hero {name}: {field} must be > 0")
        if len(h["paths"]) != 3:
            problems.append(f"Hero {name}: needs exactly 3 upgrade paths on Hero Upgrades (has {len(h['paths'])})")
        for p in h["paths"]:
            if len(p["tiers"]) != HERO_TIERS:
                problems.append(f"Hero {name} {p['id']}: needs {HERO_TIERS} tiers on Hero Upgrades (has {len(p['tiers'])}; DECISIONS #133)")
            for i, step in enumerate(p["tiers"], start=1):
                where = f"Hero {name} {p['id']} tier {i}"
                if step["abilityCharges"] != int(step["abilityCharges"]):
                    problems.append(f"{where}: Ability charges must be a whole number")
                if (step["stillSpreadMult"] > 1) or (step["scopedSpreadMult"] > 1):
                    problems.append(f"{where}: Still spread x and Scoped spread x may only tighten (0-1)")
                if not step["name"].strip():
                    problems.append(f"{where}: needs a Name")
                if not isinstance(step["cost"], (int, float)) or step["cost"] <= 0:
                    problems.append(f"{where}: has no cost")
                if step["fireMode"] and step["fireMode"] not in FIRE_MODES:
                    problems.append(f"{where}: Fire mode must be one of {', '.join(FIRE_MODES)}")
                if step["fireMode"] == "burst" and step["burstCount"] < 2:
                    problems.append(f"{where}: burst fire needs a Burst count of 2+")
                for field, _, kind, _ in HERO_UPGRADE_COLUMNS:
                    if kind in ("num", "mult") and (not isinstance(step[field], (int, float)) or step[field] < 0):
                        problems.append(f"{where}: {field} must be a number >= 0")
                for field in ("guardPercent", "slowPercent"):
                    if step[field] > 100:
                        problems.append(f"{where}: {field} must be 0-100")
                if (step["guardPercent"] > 0) != (step["guardSeconds"] > 0):
                    problems.append(f"{where}: Guard % and Guard (s) go together")
                if (step["slowPercent"] > 0) != (step["slowSeconds"] > 0):
                    problems.append(f"{where}: Slow on hit % and Slow on hit (s) go together")
                if step["jawLockSpread"] > 0 and step["jawLockSeconds"] <= 0:
                    problems.append(f"{where}: Jaw lock spread needs Jaw lock (s)")
                if step["sizeBreaks"] < 1 or step["sizeBreaks"] != int(step["sizeBreaks"]):
                    problems.append(f"{where}: Size breaks must be a whole number >= 1")
                if step["sizeBreaks"] > 1 and (name, p["id"]) not in HERO_BREAK_PATHS:
                    problems.append(f"{where}: Size breaks above 1 on a path not in the design table (DECISIONS #134; a Director call)")

    # Tuning levers the game code reads by name. A renamed or overwritten row would
    # otherwise only show up as nil in Studio.
    needed = [
        "StartingCash", "CashPerEffectiveHP", "RoundBonusBase", "RoundBonusPerRound",
        "SellRefund", "MaxConcurrentEnemies", "GlobalSpeedScalar", "LinePierceReach", "MarkDuration",
        "BombletDamage", "BombletSpread", "ExtraEnemiesPerPlayer", "ExtraHPPerPlayer",
        "StartingCashPerExtraPlayer", "WeaponAimAssist", "OverdriveFireRateX", "AirburstDelay",
        "AirburstReach", "SpinUpTime", "RicochetReach", "StillSpeed", "HeroUpgradeBaseCost",
        "HeroUpgradeCostGrowth", "ChestLifetime", "ChestSpread", "RoundsPerLevel",
        "HeroDamagePerLevel", "TowerDamagePerLevel", "MultiplayerLossPayout", "RespawnTime", "ResultsTime",
        "PlayerMaxHealth", "HealPerRound", "SpawnProtection", "MaxResist", "MaxProjectiles",
        "TowerHPPerTier", "RepairCost", "BurnPatchMinReach", "BossJawLockX",
        "BreakLevelStep", "MaxSizeBreaks",
    ]
    for key in needed:
        if key not in data["Tuning"]:
            problems.append(f"Tuning is missing '{key}' (the game reads it by name)")
    tuning = data["Tuning"]
    if tuning.get("BreakLevelStep", 1) <= 0:
        problems.append("Tuning Break level step must be above 0")
    if tuning.get("MaxSizeBreaks", 1) < 1:
        problems.append("Tuning Max size breaks must be 1 or more (1 turns pierce-through off)")

    for i, lvl in enumerate(data["Mastery"], start=1):
        if not isinstance(lvl["coreCost"], (int, float)) or lvl["coreCost"] <= 0:
            problems.append(f"Mastery level {i}: needs a Core cost")
        if not 2 <= lvl["crossoverCap"] <= 5:
            problems.append(f"Mastery level {i}: Crossover cap must be 2-5")
    for key, h in data["Heroes"].items():
        if h["abilityKind"].upper() not in ABILITY_KINDS:
            problems.append(f"Hero {h['display']}: Ability kind must be one of {', '.join(ABILITY_KINDS)}")
    if not any(t["unlockCost"] == 0 for t in data["Towers"].values()):
        problems.append("At least one tower must be free (Unlock cost 0)")
    if not any(h["unlockCost"] == 0 for h in data["Heroes"].values()):
        problems.append("At least one hero must be free (Unlock cost 0)")

    if "EASY" not in data["Difficulties"]:
        problems.append("Difficulty sheet needs an 'Easy' row (the baseline)")
    for key, d in data["Difficulties"].items():
        for field in ("hpMult", "countMult", "speedMult", "cashMult", "startingLives", "startingCash"):
            if not isinstance(d[field], (int, float)) or d[field] <= 0:
                problems.append(f"Difficulty {d['display']}: {field} must be > 0")
        if not isinstance(d["promoteChance"], (int, float)) or not 0 <= d["promoteChance"] <= 1:
            problems.append(f"Difficulty {d['display']}: Promote chance must be between 0 and 1")
    easy = data["Difficulties"].get("EASY")
    if easy and easy["startingCash"] != data["Tuning"]["StartingCash"]:
        problems.append(
            f"Difficulty Easy Starting cash ({easy['startingCash']}) must equal Tuning Starting cash "
            f"({data['Tuning']['StartingCash']}), the documented default (DECISIONS #136)"
        )
    notes.append("difficulties: " + ", ".join(d["display"] for d in data["Difficulties"].values()))
    notes.append("starting cash: " + ", ".join(f"{d['display']} {d['startingCash']}" for d in data["Difficulties"].values()))

    best_tower = 0.0
    best_by_tower = {}  # display -> that tower kind's best maxed path, unlevelled
    for t in data["Towers"].values():
        base = t["baseDamage"] * t["baseRate"] * t["baseTargets"]
        for p in t["paths"]:
            if p["focus"] == "economy" or not p["tiers"]:
                continue
            top = p["tiers"][-1]
            dps = base * top["damageMult"] * top["rateMult"] * top["targetsMult"]
            best_tower = max(best_tower, dps)
            best_by_tower[t["display"]] = max(best_by_tower.get(t["display"], 0.0), dps)
    def hero_peak_dps(h):
        best = 0.0
        for p in h["paths"]:
            if not p["tiers"]:
                continue
            t = p["tiers"][-1]
            guns = max(1, t["guns"] or 1)
            pellets = h["pellets"]  # damage per shot is conserved across pellet counts
            shots = max(1, t["shotsPerTrigger"] or 1)
            dps = h["damage"] * t["damageMult"] * h["rate"] * t["rateMult"] * t["spinUp"] * guns * pellets * shots
            best = max(best, dps * max(1, t["pierce"] or 1))
        return best
    # Compare in the last round (PLAN round 3 T36, DECISIONS #101). Towers fight it at
    # the round level (1 + rounds cleared before it / RoundsPerLevel); hero XP can put a
    # hunter HeroLevelLeadCap levels above that, so the hero side uses the highest hero
    # level in play. tools/test/heroxp.spec.luau holds Shared/HeroXp to the same clamp.
    tuning = data["Tuning"]
    round_level, hero_level = guard_levels(data)
    hero_x = 1 + tuning.get("HeroDamagePerLevel", 0)
    tower_scale = (1 + tuning.get("TowerDamagePerLevel", 0)) ** (round_level - 1)
    hero_peak = max(hero_peak_dps(h) for h in data["Heroes"].values())
    best_weapon = hero_peak * hero_x ** (hero_level - 1)
    floor_weapon = hero_peak * hero_x ** (round_level - 1)
    best_tower_leveled = best_tower * tower_scale
    notes.append(f"last round: max hero DPS {best_weapon:.0f} at hero level {hero_level} (round level {round_level} + lead cap; {floor_weapon:.0f} at the round level)"
                 f" vs max tower DPS {best_tower_leveled:.0f} at tower level {round_level}")
    if best_tower_leveled and best_weapon > best_tower_leveled:
        problems.append(f"A maxed hero at the highest hero level in play (level {hero_level}: {best_weapon:.0f} DPS) out-damages the best maxed tower"
                        f" (tower level {round_level}: {best_tower_leveled:.0f}). The game becomes a horde shooter.")
    # The guard runs per difficulty (PLAN T50 final): Chaos softens towers and hardens the gun.
    for key in data.get("DifficultyOrder", []):
        d = data["Difficulties"][key]
        if d["towerDamageMult"] <= 0 or d["heroDamageMult"] <= 0:
            problems.append(f"Difficulty {d['display']}: Tower damage x and Hero damage x must be above 0")
            continue
        if d["towerDamageMult"] == 1 and d["heroDamageMult"] == 1:
            continue
        hero_d, tower_d = best_weapon * d["heroDamageMult"], best_tower_leveled * d["towerDamageMult"]
        notes.append(f"  {d['display']}: hero {best_weapon:.0f} x {d['heroDamageMult']:g} = {hero_d:.0f} vs best tower {best_tower_leveled:.0f} x {d['towerDamageMult']:g} = {tower_d:.0f}")
        if tower_d and hero_d >= tower_d:
            problems.append(f"Difficulty {d['display']}: a maxed hero at level {hero_level} ({hero_d:.0f} DPS with Hero damage x) out-damages the best maxed tower"
                            f" ({tower_d:.0f} with Tower damage x).")
    # Not a failure (the rule is the BEST tower, DECISIONS #58): tower kinds whose best
    # maxed path the hero only passes because of the lead level.
    lead_only = [f"{name} ({dps * tower_scale:.0f})" for name, dps in best_by_tower.items()
                 if dps > 0 and floor_weapon <= dps * tower_scale < best_weapon]
    if lead_only:
        notes.append(f"  only at the lead level does that hero ({best_weapon:.0f}) pass a maxed: " + ", ".join(lead_only))

    validate_rewards(data, problems, notes)
    validate_perks(data, problems, notes)
    validate_small_perks(data, problems)
    validate_xp(data, problems, notes)

    return problems, notes


# ---------------------------------------------------------------- Luau emitter

LUAU_IDENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
LUAU_RESERVED = {
    "and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if",
    "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until",
    "while", "continue", "export", "type",
}


def lua_key(k):
    if isinstance(k, str) and LUAU_IDENT.match(k) and k not in LUAU_RESERVED:
        return k
    return "[" + lua_value(k, 0) + "]"


def lua_value(x, depth):
    pad, inner = "\t" * depth, "\t" * (depth + 1)
    if isinstance(x, bool):
        return "true" if x else "false"
    if isinstance(x, (int, float)):
        if isinstance(x, float):
            if x.is_integer():
                return str(int(x))
            return repr(round(x, 4))
        return str(x)
    if isinstance(x, str):
        esc = x.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
        return f'"{esc}"'
    if isinstance(x, list):
        if not x:
            return "{}"
        body = ",\n".join(inner + lua_value(i, depth + 1) for i in x)
        return "{\n" + body + ",\n" + pad + "}"
    if isinstance(x, dict):
        if not x:
            return "{}"
        body = ",\n".join(f"{inner}{lua_key(k)} = {lua_value(val, depth + 1)}" for k, val in x.items())
        return "{\n" + body + ",\n" + pad + "}"
    if x is None:
        return "nil"
    raise TypeError(f"Cannot serialize {type(x)}")


def emit(data, source_name):
    header = (
        "--[[\n"
        "\tGENERATED FILE. DO NOT EDIT.\n"
        f"\tSource: {source_name}\n"
        "\tRegenerate: python3 tools/export_constants.py\n"
        "\n"
        "\tEvery gameplay number lives here. If you want to change one, change\n"
        "\tthe spreadsheet and re-export, or the spreadsheet stops being the\n"
        "\tsource of truth.\n"
        "]]\n\n"
    )
    return header + "return table.freeze(" + lua_value(data, 0) + ")\n"


# ---------------------------------------------------------------- main

def read_difficulty(ws):
    levels, order = {}, []
    r = 5
    while v(ws, r, 1):
        name = str(v(ws, r, 1)).strip()
        key = name.upper()
        levels[key] = {
            "display": name,
            "hpMult": num(v(ws, r, 2), 1),
            "countMult": num(v(ws, r, 3), 1),
            "speedMult": num(v(ws, r, 4), 1),
            "promoteChance": num(v(ws, r, 5), 0),
            "cashMult": num(v(ws, r, 6), 1),
            "startingLives": num(v(ws, r, 7)),
            "clearReward": num(v(ws, r, 9)),
            "dinoDamageMult": num(v(ws, r, 10), 1),
            "startingCash": num(v(ws, r, 11)),
            # Chaos = gun skill (PLAN T50 final, DECISIONS #167): every tower's damage and
            # every hunter's damage scale by these on top of the level curve.
            "towerDamageMult": num(v(ws, r, 12), 1),
            "heroDamageMult": num(v(ws, r, 13), 1),
        }
        order.append(key)
        r += 1
    return levels, order


def recalculated(xlsx):
    """The workbook with every formula replaced by its value, computed by pycel.

    pycel follows Excel's arithmetic. Checked 2026-09-28 on a copy with stored
    results removed: all 1100 formulas match the original Excel values; Numbers
    differs on 54 cells (Sniper costs where 350 x 2.3^n sits on an exact .5,
    which Numbers rounds up). The file's stored results are never used.
    """
    try:
        from pycel import ExcelCompiler
    except ImportError:
        sys.exit(
            "Formula results are missing from the spreadsheet and pycel isn't installed.\n"
            "Run: pip3 install pycel   (or open the file in Numbers and Export To Excel)"
        )
    import warnings
    warnings.filterwarnings("ignore")

    wb = load_workbook(xlsx)
    compiler = ExcelCompiler(filename=xlsx)
    count = 0
    for ws in wb:
        for row in ws.iter_rows():
            for cell in row:
                formula = getattr(cell.value, "text", cell.value)
                if isinstance(formula, str) and formula.startswith("="):
                    value = compiler.evaluate(f"{ws.title}!{cell.coordinate}")
                    if isinstance(value, str) and value.startswith("#"):
                        sys.exit(f"Formula error {value} in {ws.title}!{cell.coordinate}: {formula}")
                    cell.value = value
                    count += 1
    print(f"Recalculated {count} formulas")
    return wb


def read_data(xlsx):
    """Everything Config.luau is written from, as Python data (tools/audit.py uses it)."""
    # Always recalculate: results stored in the file depend on which app saved it
    # (Numbers and Excel round a few exact-.5 costs differently), so one
    # calculator gives the same Config every time.
    wb = recalculated(xlsx)

    towers, tower_order = read_towers(wb["Towers"])
    attach_paths(wb["Tower Upgrades"], towers)
    heroes, hero_order = read_heroes(wb["Heroes"])
    attach_hero_paths(wb["Hero Upgrades"], heroes)
    difficulties, difficulty_order = read_difficulty(wb["Difficulty"])
    for name in ("Daily Haul", "Bounties"):
        if name not in wb.sheetnames:
            sys.exit(f"The spreadsheet has no '{name}' sheet (PLAN round 2 T25)")
    if "Mastery Perks" not in wb.sheetnames:
        sys.exit("The spreadsheet has no 'Mastery Perks' sheet (PLAN round 3 T32)")
    bounties, bounty_order = read_bounties(wb["Bounties"])

    data = {
        "Tuning": read_tuning(wb["Tuning"]),
        "Towers": towers,
        "TowerOrder": tower_order,
        "Heroes": heroes,
        "HeroOrder": hero_order,
        "Mastery": read_mastery(wb["Mastery"]),
        "MasteryPerks": read_mastery_perks(wb["Mastery Perks"]),
        "Enemies": read_enemies(wb["Enemies"]),
        "EnemyOrder": [k for k in TIER_KEYS],
        "Rounds": read_rounds(wb["Rounds"]),
        "Difficulties": difficulties,
        "DifficultyOrder": difficulty_order,
        "DailyHaul": read_daily_haul(wb["Daily Haul"]),
        "Bounties": bounties,
        "BountyOrder": bounty_order,
    }
    return data


def main():
    xlsx = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_XLSX
    if not os.path.exists(xlsx):
        sys.exit(f"Spreadsheet not found: {xlsx}")

    data = read_data(xlsx)
    towers, heroes = data["Towers"], data["Heroes"]
    problems, notes = validate(data)

    os.makedirs(os.path.dirname(OUT_FILE), exist_ok=True)
    with open(OUT_FILE, "w") as f:
        f.write(emit(data, os.path.basename(xlsx)))

    print(f"Read   {xlsx}")
    print(f"Wrote  {os.path.relpath(OUT_FILE, ROOT)}")
    print(f"  {len(towers)} towers, {len(heroes)} heroes, {len(data['Enemies'])} enemy tiers, {len(data['Rounds'])} rounds")
    for n in notes:
        print(f"  {n}")
    if problems:
        print("\nVALIDATION PROBLEMS:")
        for p in problems:
            print(f"  ! {p}")
        sys.exit(1)
    print("Validation clean.")


if __name__ == "__main__":
    main()
