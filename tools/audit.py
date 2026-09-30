#!/usr/bin/env python3
"""
Dino Hunters — Config <-> design-doc audit.

Catches drift between the approved docs, the spreadsheet and the code. Reads the
spreadsheet through the exporter (export_constants.read_data), never by parsing
Config.luau, and prints a findings list:

  1. names    every tier name in the UPGRADES.md / HEROES.md path tables equals the
              spreadsheet Name, keyed by (tower or hero, path, tier) and scoped to
              Towers vs Heroes (tier names repeat across the two)
  2. unlocks  unlock costs equal the DIRECTION.md ladder, extended by DECISIONS
              #13/#15/#16 once those rows exist
  3. dead     every Config field that is non-zero (true, non-empty) somewhere is
              referenced by name in some src/**/*.luau other than Config.luau, so no
              mechanic is silently unbuilt. Exempt, and listed as notes: Tuning levers
              that only sheet formulas read ("sheet-only", DECISIONS #28), and the
              DEAD_ALLOWED entries below
  4. species  every species in VISION.md's table exists with that display name

Usage:
    python3 tools/audit.py            report; exits 0 whatever it finds
    python3 tools/audit.py --strict   exits 1 if there are findings

tools/test.sh runs it after the specs.
"""

import contextlib
import glob
import io
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

import export_constants  # noqa: E402

# Rows the DIRECTION.md ladder doesn't list yet, from DECISIONS.md. Checked only
# once the key exists in Config. (kind, key): (display, cost, source)
LADDER_EXTENSIONS = {
    ("hero", "MEDIC"): ("Field Medic", 75, "DECISIONS #13"),
    ("tower", "HOSPITAL"): ("Field Hospital", 100, "DECISIONS #15"),
    ("tower", "ARMORY"): ("Armory", 150, "DECISIONS #16"),
}


# Config fields no code reads, on purpose (DECISIONS #28). One reason each; nothing
# else belongs here. (block, field): reason
DEAD_ALLOWED = {
    ("Tuning", "StartingLives"): "superseded by Difficulty -> Starting lives",
    ("Enemies", "cashValue"): "display column; the code pays maxHp x CashPerEffectiveHP, the same value unrounded",
}


def read(name):
    with open(os.path.join(ROOT, name), encoding="utf-8") as f:
        return f.read()


def cells(line):
    return [c.strip() for c in line.strip().strip("|").split("|")]


def plain(text):
    """A table cell without markdown emphasis."""
    return text.replace("**", "").replace("*", "").strip()


# ---------------------------------------------------------------- 1. names

def doc_path_tables(text, heading_level):
    """{section display name: [(path id, [tier names]), ...]} from a design doc.

    A section starts at a heading of `heading_level` ('##' or '###') whose title is
    '<Display> (<note>) — ...'; its path rows are table rows whose first cell is bold.
    """
    sections = {}
    current = None
    heading = re.compile(r"^" + re.escape(heading_level) + r" (.+?) \(")
    for line in text.splitlines():
        if line.startswith("#"):
            m = heading.match(line)
            current = m.group(1).strip() if m else None
            if current:
                sections[current] = []
        elif current and line.startswith("|"):
            row = cells(line)
            if len(row) >= 3 and row[0].startswith("**"):
                sections[current].append((plain(row[0]), [plain(c) for c in row[2:]]))
    return {k: v for k, v in sections.items() if v}


def check_names(findings, block, items, doc_name, heading_level, compared):
    sections = doc_path_tables(read(doc_name), heading_level)
    by_display = {item["display"]: key for key, item in items.items()}
    for display, rows in sections.items():
        key = by_display.get(display)
        if key is None:
            findings.append(f"{doc_name} section '{display}' has no {block} with that display name")
            continue
        paths = items[key]["paths"]
        if len(rows) != len(paths):
            findings.append(f"{block}.{key}: {doc_name} lists {len(rows)} paths, the sheet has {len(paths)}")
        for p, (doc_id, doc_tiers) in enumerate(rows, start=1):
            if p > len(paths):
                break
            path = paths[p - 1]
            where = f"{block}.{key} path {p}"
            if doc_id != path["id"]:
                findings.append(f"{where}: {doc_name} path '{doc_id}', sheet '{path['id']}'")
            tiers = path["tiers"]
            if len(doc_tiers) != len(tiers):
                findings.append(f"{where} ({path['id']}): {doc_name} has {len(doc_tiers)} tiers, the sheet {len(tiers)}")
            for t, (doc_tier, tier) in enumerate(zip(doc_tiers, tiers), start=1):
                compared.append(1)
                if doc_tier != tier.get("name"):
                    findings.append(f"{where} ({path['id']}) T{t}: {doc_name} '{doc_tier}', sheet '{tier.get('name')}'")
    documented = set(sections)
    for key, item in items.items():
        if item["display"] not in documented:
            findings.append(f"{block}.{key} ({item['display']}) has no path table in {doc_name}")


# ---------------------------------------------------------------- 2. unlocks

def direction_ladder():
    """[(display, cost)] from the DIRECTION.md '- Unlocks:' bullet."""
    lines = read("DIRECTION.md").splitlines()
    for i, line in enumerate(lines):
        if line.startswith("- Unlocks:"):
            text = line[len("- Unlocks:"):]
            for more in lines[i + 1:]:
                if not more.startswith("  "):
                    break
                text += " " + more.strip()
            break
    else:
        return None
    ladder = []
    for part in text.strip().rstrip(".").split(";"):
        part = part.strip()
        if part.endswith(" free"):
            for name in re.split(r"\s*[+/]\s*", part[: -len(" free")]):
                ladder.append((name.strip(), 0))
        else:
            for item in part.split(","):
                m = re.match(r"^(.+?)\s+(\d+)$", item.strip())
                if m:
                    ladder.append((m.group(1).strip(), int(m.group(2))))
                else:
                    ladder.append((item.strip(), None))
    return ladder


def check_unlocks(findings, data):
    ladder = direction_ladder()
    if ladder is None:
        findings.append("DIRECTION.md has no '- Unlocks:' bullet")
        return
    kinds = {"tower": ("Towers", data["Towers"]), "hero": ("Heroes", data["Heroes"])}
    expected = {}  # (kind, key) -> (cost, source)
    for display, cost in ladder:
        matches = [(kind, key) for kind, (_, items) in kinds.items()
                   for key, item in items.items() if item["display"] == display]
        if cost is None:
            findings.append(f"DIRECTION.md ladder entry '{display}' has no cost")
        elif not matches:
            findings.append(f"DIRECTION.md ladder names '{display}', which is no tower or hero in the sheet")
        elif len(matches) > 1:
            findings.append(f"DIRECTION.md ladder name '{display}' is both a tower and a hero")
        else:
            expected[matches[0]] = (cost, "DIRECTION.md")
    for (kind, key), (display, cost, source) in LADDER_EXTENSIONS.items():
        items = kinds[kind][1]
        if key in items:
            expected[(kind, key)] = (cost, source)
            if items[key]["display"] != display:
                findings.append(f"{kinds[kind][0]}.{key} is '{items[key]['display']}', {source} says '{display}'")
    for kind, (block, items) in kinds.items():
        for key, item in items.items():
            want = expected.get((kind, key))
            if want is None:
                findings.append(f"{block}.{key} ({item['display']}) is on no unlock ladder")
            elif item.get("unlockCost") != want[0]:
                findings.append(f"{block}.{key} ({item['display']}) unlock {item.get('unlockCost')}, {want[1]} says {want[0]}")


# ---------------------------------------------------------------- 3. dead columns

def live(value):
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return value != 0
    if isinstance(value, str):
        return value != ""
    return value is not None


def config_fields(data):
    """{(block, field): [where it's non-zero]} for every leaf field in Config."""
    fields = {}

    def note(block, row, where):
        for field, value in row.items():
            if isinstance(value, (dict, list)):
                continue
            entry = fields.setdefault((block, field), [])
            if live(value):
                entry.append(where)

    note("Tuning", data["Tuning"], "Tuning")
    for block in ("Towers", "Heroes"):
        for key, item in data[block].items():
            note(block, item, key)
            for p, path in enumerate(item["paths"], start=1):
                note(f"{block} paths", path, f"{key} path {p}")
                for t, tier in enumerate(path["tiers"], start=1):
                    note(f"{block} tiers", tier, f"{key} path {p} T{t}")
    for key, enemy in data["Enemies"].items():
        note("Enemies", enemy, key)
    for key, difficulty in data["Difficulties"].items():
        note("Difficulties", difficulty, key)
    for i, row in enumerate(data["Mastery"], start=1):
        note("Mastery", row, f"level {i}")
    for i, row in enumerate(data["Rounds"], start=1):
        note("Rounds", row, f"round {i}")
        fields.setdefault(("Rounds", "counts"), []).append(f"round {i}")
    return fields


def tuning_formula_uses():
    """{Tuning field: how many workbook formulas read its cell}. A Tuning lever that
    only feeds sheet formulas (cost curves, round HP) shows up as a dead column; this
    tells those apart for whoever decides what to do with them."""
    from openpyxl import load_workbook
    wb = load_workbook(export_constants.DEFAULT_XLSX)
    ws = wb["Tuning"]
    rows = {}
    for r in range(5, 200):
        name, value = ws.cell(row=r, column=1).value, ws.cell(row=r, column=2).value
        if name and isinstance(value, (int, float)):
            rows[export_constants.ident(name)] = r
    formulas = []  # (sheet title, formula text)
    for sheet in wb:
        for row in sheet.iter_rows():
            for cell in row:
                text = getattr(cell.value, "text", cell.value)
                if isinstance(text, str) and text.startswith("="):
                    formulas.append((sheet.title, text))
    uses = {}
    for field, r in rows.items():
        other = re.compile(r"Tuning'?!\$?B\$?" + str(r) + r"(?!\d)")
        local = re.compile(r"(?<![A-Za-z$!])\$?B\$?" + str(r) + r"(?!\d)")
        uses[field] = sum(1 for title, text in formulas
                          if other.search(text) or (title == "Tuning" and local.search(text)))
    return uses


def check_dead(findings, data, notes):
    tuning_uses = tuning_formula_uses()
    config = os.path.join(ROOT, "src", "shared", "Config.luau")
    code = ""
    for path in glob.glob(os.path.join(ROOT, "src", "**", "*.luau"), recursive=True):
        if os.path.abspath(path) != config:
            with open(path, encoding="utf-8") as f:
                code += f.read() + "\n"
    for (block, field), where in sorted(config_fields(data).items()):
        if where and not re.search(r"\b" + re.escape(field) + r"\b", code):
            uses = tuning_uses.get(field, 0) if block == "Tuning" else 0
            if (block, field) in DEAD_ALLOWED:
                notes.append(f"allowed: {block}.{field} ({DEAD_ALLOWED[(block, field)]})")
            elif uses:
                notes.append(f"sheet-only: {block}.{field} (sheet formulas read it {uses}x)")
            else:
                shown = ", ".join(where[:3]) + (f" (+{len(where) - 3} more)" if len(where) > 3 else "")
                finding = f"{block}.{field} is set ({shown}) but no src file reads it"
                if block == "Tuning":
                    finding += "; no sheet formula reads it either"
                findings.append(finding)
    for (block, field) in DEAD_ALLOWED:
        if (block, field) not in config_fields(data):
            findings.append(f"DEAD_ALLOWED lists {block}.{field}, which Config no longer has")


# ---------------------------------------------------------------- 4. species

def check_species(findings, data):
    enemies = data["Enemies"]
    order = data["EnemyOrder"]
    by_display = {enemy["display"]: key for key, enemy in enemies.items()}
    rows = []
    in_table = False
    for line in read("VISION.md").splitlines():
        if line.startswith("| Tier | Species"):
            in_table = True
        elif in_table and line.startswith("|"):
            row = cells(line)
            if not set(row[0]) <= set("-"):
                rows.append((row[0], plain(row[1])))
        elif in_table:
            break
    if not rows:
        findings.append("VISION.md has no '| Tier | Species |' table")
        return
    listed = set()
    for tier, name in rows:
        key = by_display.get(name)
        if key is None:
            findings.append(f"VISION.md species '{name}' (tier {tier}) is no enemy display name in the sheet")
            continue
        listed.add(key)
        enemy = enemies[key]
        if tier.isdigit() and (int(tier) > len(order) or order[int(tier) - 1] != key):
            findings.append(f"VISION.md puts {name} at tier {tier}; the sheet has it as Enemies.{key} (#{order.index(key) + 1})")
        elif tier == "air" and not enemy.get("flying"):
            findings.append(f"VISION.md says {name} flies; Enemies.{key} isn't flying")
        elif tier == "boss" and not enemy.get("boss"):
            findings.append(f"VISION.md says {name} is a boss; Enemies.{key} isn't")
    for key, enemy in enemies.items():
        if key not in listed:
            findings.append(f"Enemies.{key} ({enemy['display']}) isn't in VISION.md's species table")


# ---------------------------------------------------------------- main

def main():
    strict = "--strict" in sys.argv[1:]
    with contextlib.redirect_stdout(io.StringIO()):
        data = export_constants.read_data(export_constants.DEFAULT_XLSX)

    compared = []
    checks = [
        ("names", lambda f, n: (check_names(f, "Towers", data["Towers"], "UPGRADES.md", "##", compared),
                             check_names(f, "Heroes", data["Heroes"], "HEROES.md", "###", compared))),
        ("unlocks", lambda f, n: check_unlocks(f, data)),
        ("dead columns", lambda f, n: check_dead(f, data, n)),
        ("species", lambda f, n: check_species(f, data)),
    ]
    total = 0
    for name, run in checks:
        findings, notes = [], []
        run(findings, notes)
        total += len(findings)
        counted = f" ({len(compared)} tier names compared)" if name == "names" else ""
        print(f"{'ok  ' if not findings else 'FIND'} audit {name}: {len(findings)} finding(s){counted}")
        for note in notes:
            print(f"       ok {note}")
        for finding in findings:
            print(f"       - {finding}")
    print(f"audit: {total} finding(s)")
    sys.exit(1 if strict and total else 0)


if __name__ == "__main__":
    main()
