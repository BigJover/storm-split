#!/usr/bin/env python3
"""
Dino Hunters — threat estimate (run by tools/test.sh; exits 1 if a target is missed).

Does a sensible defence survive Easy? From the Track geometry (src/shared/Track.luau)
and the spreadsheet (through the exporter, never Config.luau), this estimates how much
bite and projectile damage one tower takes per round on Easy, solo, at three spots:

  hugging   as close to a lane as placement allows (lane half-width + TowerRadius)
  mid-gap   halfway between two lanes (15 studs from each)
  corner    an inside corner, hugging both legs of a turn

Assumptions (deliberately pessimistic):
  - every dino of the round walks the whole track (nobody kills it), at Easy speed;
    it assumes no kills, so pierce-through (DECISIONS #126) doesn't change it;
  - this tower is the only thing in reach, so every attack that can reach it does;
  - attacks come round every `every` seconds while it's in reach (expected value);
  - projectiles always hit (towers can't dodge); a Boss species' projectiles deal
    x `Boss ranged vs towers x` to towers (Tuning, BOSS THROWS; DECISIONS #138, #154);
  - a dino is full size on its first lane and half size after (its damage halves).
Round pace (Tuning, DECISIONS #250; PLAN T101): spawn gaps x pace, dino HP x the pace factor,
walk speed unchanged. No dino is killed here, so per-round damage is the same paced or not;
the paced round is shorter, so the same damage lands in fewer seconds: the "len" column is
the paced Easy round length and "mid def/s" the defended mid-gap ranged damage per second
(report only; a tower's own heal per second is unchanged, its heal per round shrinks).
It prints per-round damage at each spot and, for each tower type at T0 max HP, the
rounds where one round's worst-case damage at the mid-gap spot would trample it.

Targets (PLAN.md T13, DECISIONS #42):
  - bites never reach a mid-gap tower;
  - rounds 11-30, mid-gap, the DEFENDED ranged damage per round (worst case x 0.5) stays
    under 50% of that tower's own T0 max HP, for every tower except the Longshot Perch;
  - the Longshot Perch, at its back-line spot (>= 25 studs from every lane), takes 0;
  - hugging and corner spots are reported with no target (they're meant to be at risk);
  - rounds 31-39, mid-gap, the DEFENDED damage of the BOSS throws alone (Boss species'
    projectiles, x the lever) stays under 50% of every tower's T0 max HP but the Perch's
    (DECISIONS #154). The other dinos' share and the totals stay report-only.

Boss rounds (PLAN.md round 2 T24, DECISIONS #44/#62/#154): rounds 31-40 are reported: boss /
other / total mid-gap defended damage per round against the weakest mid-gap tower, and the
total as a share of each tower type's T0 max HP, plain and with the Armory's top resist
applied. Totals stay a playtest item; round 40 (the T-Rex) is report-only.
"""

import contextlib
import io
import math
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

import export_constants  # noqa: E402

STEP = 0.5  # studs between samples along the path
# DECISIONS #42: a sensible Easy defence kills about half of a round's ranged dinos
# before they pass a mid-gap spot, so the target is judged on worst case x this.
DEFENDED = 0.5
RANGED_TARGET = 0.5  # share of the tower's own T0 max HP
RANGED_ROUNDS = range(11, 31)  # rounds 11-30
BACK_LINE_TOWER = "SNIPER"  # the Longshot Perch is judged at the back line instead
BACK_LINE = (-105.0, 0.0)  # >= 25 studs from every lane (checked below)
BOSS_ROUNDS = range(31, 41)  # reported (#44/#62)
BOSS_THROW_ROUNDS = range(31, 40)  # boss share judged (#154); 40 report-only
RESIST_TOWER = "ARMORY"  # its best resist tier is the "with Armory" column


def track():
    text = open(os.path.join(ROOT, "src", "shared", "Track.luau"), encoding="utf-8").read()
    points = [(float(x), float(z)) for x, _, z in re.findall(
        r"Vector3\.new\((-?[\d.]+),\s*(-?[\d.]+),\s*(-?[\d.]+)\)", text.split("LaneWidth")[0])]

    def number(name):
        return float(re.search(name + r"\s*=\s*([\d.]+)", text).group(1))

    return points, number("LaneWidth"), number("TowerRadius"), number("BaseEnemySpeed")


def samples(points):
    """(x, z, lane index) every STEP studs along the path."""
    out = []
    for i in range(1, len(points)):
        (ax, az), (bx, bz) = points[i - 1], points[i]
        length = math.hypot(bx - ax, bz - az)
        n = max(1, int(length / STEP))
        for k in range(n):
            f = k / n
            out.append((ax + (bx - ax) * f, az + (bz - az) * f, i - 1))
    return out


def exposure(path, spot, reach):
    """Studs walked within `reach` of `spot`, split into full-size (first lane) and later."""
    first = later = 0.0
    for x, z, lane in path:
        if math.hypot(x - spot[0], z - spot[1]) <= reach:
            if lane == 0:
                first += STEP
            else:
                later += STEP
    return first, later


def main():
    with contextlib.redirect_stdout(io.StringIO()):
        data = export_constants.read_data(export_constants.DEFAULT_XLSX)
    points, lane_width, tower_radius, base_speed = track()
    path = samples(points)
    easy = data["Difficulties"][data["DifficultyOrder"][0]]
    speed_scalar = data["Tuning"].get("GlobalSpeedScalar", 1)
    boss_vs_towers = data["Tuning"]["BossRangedVsTowersX"]  # DECISIONS #138, #154

    hug = lane_width / 2 + tower_radius
    # Lanes 2 and 3 run along z = -15 and z = 15 between x = -60 and 60.
    spots = {
        "hugging": (0.0, -15 + hug),
        "mid-gap": (0.0, 0.0),
        "corner": (60 - hug, -45 + hug),  # inside the first U-turn
        "back line": BACK_LINE,
    }
    gap = min(math.hypot(x - BACK_LINE[0], z - BACK_LINE[1]) for x, z, _ in path)
    assert gap >= 25, f"back-line spot is only {gap:.1f} studs from the track"

    enemies = data["Enemies"]
    # Per species and spot: damage one dino deals walking the track.
    per_dino = {}
    for key, e in enemies.items():
        speed = base_speed * speed_scalar * e["speedMult"] * easy["speedMult"]
        per_dino[key] = {}
        for name, spot in spots.items():
            out = {}
            for kind in ("melee", "ranged"):
                damage, every, reach = e[f"{kind}Damage"], e[f"{kind}Every"], e[f"{kind}Reach"]
                if damage <= 0 or every <= 0:
                    out[kind] = 0.0
                    continue
                first, later = exposure(path, spot, reach)
                seconds_full, seconds_half = first / speed, later / speed
                out[kind] = damage * easy["dinoDamageMult"] * (seconds_full + 0.5 * seconds_half) / every
                if kind == "ranged" and e["boss"]:
                    out[kind] *= boss_vs_towers  # every spot is a tower
            per_dino[key][name] = out

    towers = data["Towers"]
    # Towers that can't be damaged (DECISIONS #148: no HP, never a target) are left out.
    t0 = {t["display"]: t["maxHp"] for t in towers.values() if not t.get("untouchable")}
    mid_gap = {t["display"]: t["maxHp"] for key, t in towers.items() if key != BACK_LINE_TOWER and not t.get("untouchable")}
    untouchable = [t["display"] for t in towers.values() if t.get("untouchable")]
    print(f"threat (Easy, solo, every dino walks the whole track, worst case); hug = {hug} studs from the lane centre")
    print(f"  T0 max HP: " + ", ".join(f"{k} {v:g}" for k, v in t0.items())
          + (f"; can't be damaged (left out): {', '.join(untouchable)}" if untouchable else ""))
    print(f"  defended = worst case x {DEFENDED} (DECISIONS #42); boss throws vs towers x {boss_vs_towers:g} (DECISIONS #154)")
    pace = data["Tuning"]["RoundPace"]
    print(f"  Round pace {pace:g}: per-round damage unchanged (same counts, same walk); len = paced Easy round length (unpaced in brackets)")
    print(f"  {'round':>5} | {'bites hug':>9} {'mid':>6} {'corner':>7} | {'ranged hug':>10} {'mid':>6} {'corner':>7} {'mid def':>8} {'back':>5} | {'len':>9} {'mid def/s':>9}")
    findings = []
    trampled = {name: [] for name in t0}
    boss_rounds = []
    for index, round_ in enumerate(data["Rounds"], start=1):
        totals = {name: {"melee": 0.0, "ranged": 0.0} for name in spots}
        boss_mid = 0.0  # the Boss species' share of the mid-gap ranged damage
        for key, count in round_["counts"].items():
            n = count * easy["countMult"]
            if enemies[key]["boss"]:
                boss_mid += n * per_dino[key]["mid-gap"]["ranged"]
            for name in spots:
                for kind in ("melee", "ranged"):
                    totals[name][kind] += n * per_dino[key][name][kind]
        mid = totals["mid-gap"]
        paced = export_constants.paced_length(data, round_, easy)
        spawn_s, walk_s = export_constants.round_parts(data, round_, easy)
        unpaced = spawn_s + walk_s
        defended = mid["ranged"] * DEFENDED
        back = totals["back line"]["melee"] + totals["back line"]["ranged"]
        if index % 5 == 0 or index == 1 or index in (11, 21, 31):
            print(f"  {index:>5} | {totals['hugging']['melee']:>9.0f} {mid['melee']:>6.0f} {totals['corner']['melee']:>7.0f}"
                  f" | {totals['hugging']['ranged']:>10.0f} {mid['ranged']:>6.0f} {totals['corner']['ranged']:>7.0f} {defended:>8.1f} {back:>5.0f}"
                  f" | {paced:>4.0f} [{unpaced:>3.0f}] {defended / paced:>9.2f}")
        if mid["melee"] > 0:
            findings.append(f"round {index}: bites reach a mid-gap tower ({mid['melee']:.0f} damage)")
        if back > 0:
            findings.append(f"round {index}: the Longshot Perch's back line takes {back:.0f} damage")
        boss_def = boss_mid * DEFENDED
        if index in BOSS_ROUNDS:
            boss_rounds.append((index, defended, boss_def))
        if index in BOSS_THROW_ROUNDS:
            for name, hp in mid_gap.items():
                if boss_def >= RANGED_TARGET * hp:
                    findings.append(f"round {index}: mid-gap defended BOSS throw damage {boss_def:.1f} >= {RANGED_TARGET:.0%} of {name}'s {hp:g} HP (DECISIONS #154)")
        if index in RANGED_ROUNDS:
            for name, hp in mid_gap.items():
                if defended >= RANGED_TARGET * hp:
                    findings.append(f"round {index}: mid-gap defended ranged damage {defended:.1f} >= {RANGED_TARGET:.0%} of {name}'s {hp:g} HP")
        for name, hp in t0.items():
            if mid["melee"] + mid["ranged"] >= hp:
                trampled[name].append(index)
    print("  mid-gap tower trampled within one round (no repair), by type:")
    for name, rounds in trampled.items():
        print(f"    {name}: " + (f"from round {rounds[0]} ({len(rounds)} rounds)" if rounds else "never"))
    weakest = min(mid_gap, key=mid_gap.get)
    weakest_hp = mid_gap[weakest]
    resist = max((step.get("resistPercent", 0) for path in towers[RESIST_TOWER]["paths"] for step in path["tiers"]),
                 default=0)
    print(f"  boss rounds {BOSS_ROUNDS[0]}-{BOSS_ROUNDS[-1]}, mid-gap defended ranged damage per round as % of T0 max HP,"
          f" plain / with the {towers[RESIST_TOWER]['display']}'s top resist ({resist:g}%);"
          f" boss / other / total vs the {weakest} ({weakest_hp:g} HP, boss target < {RANGED_TARGET * weakest_hp:g});"
          f" rounds {BOSS_THROW_ROUNDS[0]}-{BOSS_THROW_ROUNDS[-1]} judge the boss share only (DECISIONS #154)")
    print(f"  {'round':>5} {'boss':>6} {'other':>6} {'total':>6} {'resisted':>8} | " + " ".join(f"{name.split()[0][:8]:>9}" for name in mid_gap))
    for index, defended, boss_def in boss_rounds:
        kept = defended * (1 - resist / 100)
        print(f"  {index:>5} {boss_def:>6.1f} {defended - boss_def:>6.1f} {defended:>6.1f} {kept:>8.1f} | "
              + " ".join(f"{f'{defended / hp:.0%}/{kept / hp:.0%}':>9}" for hp in mid_gap.values()))
    print(f"threat: {len(findings)} target miss(es)")
    for f in findings:
        print(f"  - {f}")
    sys.exit(1 if findings else 0)


if __name__ == "__main__":
    main()
