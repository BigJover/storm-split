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
            "cost": num(v(ws, r, 5)),
            "damageMult": num(v(ws, r, 7), 1),
            "rateMult": num(v(ws, r, 8), 1),
            "targetsMult": num(v(ws, r, 9), 1),
            "swapsModel": tier in (3, 5),
        })
        r += 1


def read_weapons(ws):
    weapons, order = {}, []
    r = 5
    while True:
        wtype = v(ws, r, 1)
        if not wtype or str(wtype).startswith("CROSSOVER"):
            break
        key = str(wtype).upper()
        if key not in weapons:
            weapons[key] = {"display": str(wtype), "ability": "", "tiers": []}
            order.append(key)
        ability = v(ws, r, 2)
        if ability and "locked" not in str(ability):
            weapons[key]["ability"] = str(ability)
        weapons[key]["tiers"].append({
            "name": v(ws, r, 4) or "",
            "cost": num(v(ws, r, 5)),
            "damage": num(v(ws, r, 7)),
            "rate": num(v(ws, r, 8)),
            "targets": num(v(ws, r, 9)),
            "cooldown": num(v(ws, r, 11)),
        })
        r += 1
    return weapons, order


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

    best_tower = 0.0
    for t in data["Towers"].values():
        base = t["baseDamage"] * t["baseRate"] * t["baseTargets"]
        for p in t["paths"]:
            if p["focus"] == "economy" or not p["tiers"]:
                continue
            top = p["tiers"][-1]
            best_tower = max(best_tower, base * top["damageMult"] * top["rateMult"] * top["targetsMult"])
    best_weapon = max(
        (w["tiers"][-1]["damage"] * w["tiers"][-1]["rate"] * w["tiers"][-1]["targets"])
        for w in data["Weapons"].values()
    )
    notes.append(f"max weapon DPS {best_weapon:.0f} vs max tower DPS {best_tower:.0f}")
    if best_tower and best_weapon > best_tower:
        problems.append("A maxed weapon out-damages the best maxed tower. The game becomes a horde shooter.")

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

def main():
    xlsx = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_XLSX
    if not os.path.exists(xlsx):
        sys.exit(f"Spreadsheet not found: {xlsx}")

    wb = load_workbook(xlsx, data_only=True)
    if wb["Rounds"].cell(row=5, column=13).value is None:
        sys.exit(
            "Formula results are missing from the spreadsheet. Open it in Excel, Numbers\n"
            "or LibreOffice, save it once, then re-run this script."
        )

    towers, tower_order = read_towers(wb["Towers"])
    attach_paths(wb["Tower Upgrades"], towers)
    weapons, weapon_order = read_weapons(wb["Weapons"])

    data = {
        "Tuning": read_tuning(wb["Tuning"]),
        "Towers": towers,
        "TowerOrder": tower_order,
        "Weapons": weapons,
        "WeaponOrder": weapon_order,
        "Mastery": read_mastery(wb["Mastery"]),
        "Enemies": read_enemies(wb["Enemies"]),
        "EnemyOrder": [k for k in TIER_KEYS],
        "Rounds": read_rounds(wb["Rounds"]),
    }

    problems, notes = validate(data)

    os.makedirs(os.path.dirname(OUT_FILE), exist_ok=True)
    with open(OUT_FILE, "w") as f:
        f.write(emit(data, os.path.basename(xlsx)))

    print(f"Read   {xlsx}")
    print(f"Wrote  {os.path.relpath(OUT_FILE, ROOT)}")
    print(f"  {len(towers)} towers, {len(weapons)} weapon types, {len(data['Enemies'])} enemy tiers, {len(data['Rounds'])} rounds")
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
