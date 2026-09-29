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
]


def read_tuning(ws):
    out = {}
    for r in range(5, 200):
        name, val = v(ws, r, 1), v(ws, r, 2)
        if name and isinstance(val, (int, float)):
            out[ident(name)] = val
    return out


def read_towers(ws):
    towers, order = {}, []
    r = 5
    while True:
        name = v(ws, r, 1)
        if not name or str(name).startswith("Cost per DPS"):
            break
        key = str(name).upper()
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
            "paths": [],
        }
        order.append(key)
        r += 1
    return towers, order


def attach_paths(ws, towers):
    index = {}
    r = 5
    while True:
        tower = v(ws, r, 1)
        if not tower:
            break
        key = str(tower).upper()
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
]

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


def read_mastery(ws):
    out = []
    for r in range(5, 25):
        lvl = v(ws, r, 1)
        if lvl is None:
            break
        out.append({"coreCost": num(v(ws, r, 2)), "unlock": v(ws, r, 5) or ""})
    return out


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


# ---------------------------------------------------------------- validation

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
    notes = [f"worst-case split cascade: {worst[0]} enemies from one {worst[1]} (live cap {cap}; the spawn queue absorbs the overflow)"]

    for i, rd in enumerate(data["Rounds"], start=1):
        for k in rd["counts"]:
            if k not in enemies:
                problems.append(f"Round {i} references unknown tier '{k}'")

    for key, t in data["Towers"].items():
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
                for field in ("shots", "lineHits"):
                    if step[field] < 1 or step[field] != int(step[field]):
                        problems.append(f"{key} {p['id']} tier {i}: {field} must be a whole number >= 1")

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
            for i, step in enumerate(p["tiers"], start=1):
                where = f"Hero {name} {p['id']} tier {i}"
                if not step["name"].strip():
                    problems.append(f"{where}: needs a Name")
                if not isinstance(step["cost"], (int, float)) or step["cost"] <= 0:
                    problems.append(f"{where}: has no cost")
                if step["fireMode"] and step["fireMode"] not in FIRE_MODES:
                    problems.append(f"{where}: Fire mode must be one of {', '.join(FIRE_MODES)}")
                if step["fireMode"] == "burst" and step["burstCount"] < 2:
                    problems.append(f"{where}: burst fire needs a Burst count of 2+")

    # Tuning levers the game code reads by name. A renamed or overwritten row would
    # otherwise only show up as nil in Studio.
    needed = [
        "StartingCash", "StartingLives", "CashPerEffectiveHP", "RoundBonusBase", "RoundBonusPerRound",
        "SellRefund", "MaxConcurrentEnemies", "GlobalSpeedScalar", "LinePierceReach", "MarkDuration",
        "BombletDamage", "BombletSpread", "ExtraEnemiesPerPlayer", "ExtraHPPerPlayer",
        "StartingCashPerExtraPlayer", "WeaponAimAssist", "OverdriveFireRateX", "AirburstDelay",
        "AirburstReach", "SpinUpTime", "RicochetReach", "StillSpeed", "HeroUpgradeBaseCost",
        "HeroUpgradeCostGrowth",
    ]
    for key in needed:
        if key not in data["Tuning"]:
            problems.append(f"Tuning is missing '{key}' (the game reads it by name)")

    if "EASY" not in data["Difficulties"]:
        problems.append("Difficulty sheet needs an 'Easy' row (the baseline)")
    for key, d in data["Difficulties"].items():
        for field in ("hpMult", "countMult", "speedMult", "cashMult", "startingLives"):
            if not isinstance(d[field], (int, float)) or d[field] <= 0:
                problems.append(f"Difficulty {d['display']}: {field} must be > 0")
        if not isinstance(d["promoteChance"], (int, float)) or not 0 <= d["promoteChance"] <= 1:
            problems.append(f"Difficulty {d['display']}: Promote chance must be between 0 and 1")
    notes.append("difficulties: " + ", ".join(d["display"] for d in data["Difficulties"].values()))

    best_tower = 0.0
    for t in data["Towers"].values():
        base = t["baseDamage"] * t["baseRate"] * t["baseTargets"]
        for p in t["paths"]:
            if p["focus"] == "economy" or not p["tiers"]:
                continue
            top = p["tiers"][-1]
            best_tower = max(best_tower, base * top["damageMult"] * top["rateMult"] * top["targetsMult"])
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
    best_weapon = max(hero_peak_dps(h) for h in data["Heroes"].values())
    notes.append(f"max hero DPS {best_weapon:.0f} vs max tower DPS {best_tower:.0f}")
    if best_tower and best_weapon > best_tower:
        problems.append("A maxed hero out-damages the best maxed tower. The game becomes a horde shooter.")

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


def main():
    xlsx = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_XLSX
    if not os.path.exists(xlsx):
        sys.exit(f"Spreadsheet not found: {xlsx}")

    # Always recalculate: results stored in the file depend on which app saved it
    # (Numbers and Excel round a few exact-.5 costs differently), so one
    # calculator gives the same Config every time.
    wb = recalculated(xlsx)

    towers, tower_order = read_towers(wb["Towers"])
    attach_paths(wb["Tower Upgrades"], towers)
    heroes, hero_order = read_heroes(wb["Heroes"])
    attach_hero_paths(wb["Hero Upgrades"], heroes)
    difficulties, difficulty_order = read_difficulty(wb["Difficulty"])

    data = {
        "Tuning": read_tuning(wb["Tuning"]),
        "Towers": towers,
        "TowerOrder": tower_order,
        "Heroes": heroes,
        "HeroOrder": hero_order,
        "Mastery": read_mastery(wb["Mastery"]),
        "Enemies": read_enemies(wb["Enemies"]),
        "EnemyOrder": [k for k in TIER_KEYS],
        "Rounds": read_rounds(wb["Rounds"]),
        "Difficulties": difficulties,
        "DifficultyOrder": difficulty_order,
    }

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
