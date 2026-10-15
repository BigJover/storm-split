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

import math
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
    # Storm Coil (PLAN T64, DECISIONS #151): the chain, its tier 5s and the Lightning Rod
    ("arcs", 63, "num", 0),  # arcs after the first hit; blank = Tuning Coil arcs
    ("arcReach", 64, "num", 0),  # studs between chained dinos; blank = Tuning Coil arc reach
    ("arcForks", 65, "num", 0),  # Fork Lightning: dinos each hop reaches; blank = 1
    ("arcJumps", 66, "bool", False),  # Jump Spark: arcs may use any Storm Coil's range
    ("powerGrid", 67, "bool", False),  # Power Grid: the shared grid strike
    ("staticPercent", 68, "num", 0),  # Static Shock: a struck dino takes +% from the next strike
    ("judgementBolt", 69, "bool", False),  # Judgement Bolt (Tuning JUDGEMENT levers)
    ("groundingEvery", 70, "num", 0),  # Grounding Spike: strikes down a throw every N s
    ("auraArcPercent", 71, "num", 0),  # Lightning Rodeo: towers in range arc each shot once at %
    # Falcon Roost (PLAN T65): the flock, its dives and the Falconer
    ("birds", 72, "num", 0),  # birds in the flock; blank = the Towers row's Birds
    ("firstDiveX", 73, "num", 1),  # Power Dive: the first dive on each dino x this
    ("eagle", 74, "bool", False),  # Eagle of the Peak: one eagle, Tuning Eagle dive x
    ("murmuration", 75, "bool", False),  # Murmuration: pecks every dino in range, no dives
    ("bossMarkPercent", 76, "num", 0),  # Hooded Scout: bosses in range marked +%
    ("diveAuraRatePercent", 77, "num", 0),  # Hunting Party: towers in range +% rate while a bird dives
    # Harpoon Ballista (PLAN T66): the bolt's line, the boss pull and the linked pairs
    ("skewer", 78, "bool", False),  # Skewer: each bolt passes through every dino on its line
    ("towLine", 79, "bool", False),  # Tow Line: pulls a boss back every Tuning Tow Line every s
    ("chainHarpoons", 80, "bool", False),  # Chain Harpoons: bolt pairs hit everything between them
    # Tar Pit (PLAN T67): sinking, the Dig Site's pay, Eruption, Tar Tracks and Tar Totem
    ("sinkSeconds", 81, "num", 0),  # Fast Sink: s a last-size dino stays before it sinks; blank = Tuning
    ("sinkCash", 82, "num", 0),  # Pick and Shovel / Fossil Hunter: cash per sunk dino
    ("sinkChestCash", 83, "num", 0),  # Lucky Finds: each sink drops a chest worth this
    ("eruption", 84, "bool", False),  # Eruption: Tuning Eruption every / Eruption sizes
    ("tracksSlowPercent", 85, "num", 0),  # Tar Tracks: footprints past the pool slow this %
    ("auraSlowedPercent", 86, "num", 0),  # Tar Totem: towers in range +% damage vs slowed dinos
    # PLAN 9d (#294), after Option / Blurb / PvP effect (CI-CK). Raider sting: battles only, an
    # enemy hunter who damages a tower on this side inside this tower's range (Shared/RaiderSting).
    ("raiderSlowPercent", 90, "num", 0),  # CL: the sting's slow (<= RAIDER_SLOW_MAX)
    ("raiderSlowSeconds", 91, "num", 0),  # CM: how long (<= RAIDER_SLOW_SECONDS_MAX)
    ("raiderDamage", 92, "num", 0),  # CN: the sting's damage, before the PvP hunter lever (x0.5)
    ("bountyCash", 93, "num", 0),  # CO: Supply Camp: cash per dino taken down in range (strongest camp pays)
    # Biter slow (PLAN 9d, #294): a dino that bites a tower in range is slowed (not bosses).
    ("biterSlowPercent", 94, "num", 0),  # CP
    ("biterSlowSeconds", 95, "num", 0),  # CQ
    # PLAN 9e (#297). Field strike (Storm Front): every N s the coil strikes every dino on its
    # side's field for x its damage (air too; armour only if it pierces; breaks 1).
    ("fieldStrikeEvery", 96, "num", 0),  # CR: 0 = no field strike
    ("fieldStrikeX", 97, "num", 0),  # CS
    # Chain effects (Supercell, Superconductor): the strike's slow and stun land on every dino in
    # the chain; an arc's stun is capped at Tuning Chain stun cap (s).
    ("chainEffects", 98, "bool", False),  # CT
    # Targets biggest (Heartseeker): aims at the biggest dino in range, not the furthest along.
    ("targetsBiggest", 99, "bool", False),  # CU
    # PLAN 9g (T123): the Amber Resin Cannon (Shared/Resin). Entomb: resin builds up on each hit
    # until the dino is entombed (a hard stop); Fossilize: a dino entombed low on HP is taken down
    # whole; Resin Shell: towers in range are sealed instead of Trampled. Kinds in RESIN_KINDS.
    ("entombSeconds", 100, "num", 0),  # CV: s an entomb holds (blank = Tuning Entomb base)
    ("entombHitsMult", 101, "num", 1),  # CW: x the resin hits to entomb
    ("entombAmpPercent", 102, "num", 0),  # CX: an entombed dino takes +% from everything
    ("entombSpread", 103, "num", 0),  # CY: the entomb also takes the n nearest dinos in Spread reach
    ("entombSlowPercent", 104, "num", 0),  # CZ: dinos near an entombed one are slowed this %
    ("entombAllEvery", 105, "num", 0),  # DA: every N s everything in range is entombed (0 = off)
    ("bossEntombSeconds", 106, "num", 0),  # DB: a boss's entomb: this long, full (no Boss hard stop x)
    ("sendBack", 107, "num", 0),  # DC: an entombed non-boss is sent this many studs back
    ("fossilBelowPercent", 108, "num", 0),  # DD: entombed at or below this % of its HP: a fossil
    ("fossilRatePercent", 109, "num", 0),  # DE: each fossil: towers in range +% rate this round
    ("bountyFossilsX", 110, "num", 0),  # DF: a fossil counts this many take-downs for Bounties
    ("heartEvery", 111, "num", 0),  # DG: every N-th fossil this match entombs the whole side 1 s
    ("sealSeconds", 112, "num", 0),  # DH: a tower in range that would be Trampled is sealed at 1 HP
    ("sealEvery", 113, "num", 0),  # DI: ... once per N s per tower instead of once a round
    ("sealHealPercent", 114, "num", 0),  # DJ: a sealed tower heals this % of max HP when it breaks
    ("reflectDamage", 115, "num", 0),  # DK: a throw caught by Grounding hits its thrower for this
    ("wallSeconds", 116, "num", 0),  # DL: once a round (AutoFire) a track wall holds dinos this long
    ("takeDownMarkPercent", 117, "num", 0),  # DM: a take-down marks dinos within Take-down mark radius
    # PLAN 9g (T124): walkers (Shared/Walker; Raptor Pen raptors, later Paratroopers and rangers)
    # and the Raptor Pen's own rules. A tower with walkers has Towers column Z (Walkers) > 0.
    ("walkers", 118, "num", 0),  # DN: walkers this build has (blank = the Towers row's)
    ("walkerHpMult", 119, "num", 1),  # DO
    ("walkerSpeedMult", 120, "num", 1),  # DP
    ("walkerResistPercent", 121, "num", 0),  # DQ
    ("walkerRespawnMult", 122, "num", 1),  # DR
    ("holdSeconds", 123, "num", 0),  # DS: a pounce holds a non-boss this long (blank = Tuning Pounce hold)
    ("bossHoldSeconds", 124, "num", 0),  # DT: ... a boss this long, once per boss
    ("flanking", 125, "bool", False),  # DU
    ("targetsFirst", 126, "bool", False),  # DV
    ("hitsAir", 127, "bool", False),  # DW: generic, the tower can hit flyers
    ("healsBetweenRounds", 128, "bool", False),  # DX
    ("dodge", 129, "bool", False),  # DY
    ("alpha", 130, "bool", False),  # DZ: one big raptor (look)
    ("swarm", 131, "bool", False),  # EA: Raptor Swarm, once a round (AutoFire)
    ("charge", 132, "bool", False),  # EB: Raptor Charge, once a round (AutoFire)
    ("guard", 133, "bool", False),  # EC: Guard Raptors
    ("stunRoarEvery", 134, "num", 0),  # ED: Rex Tamer's roar every N s (0 = none)
    ("takeDownStackPercent", 135, "num", 0),  # EE: Hungry Alpha
    ("avengerX", 136, "num", 0),  # EF: Raider Hounds: bites x this on the dino that hurt a tower
    ("hunterDamagePercent", 137, "num", 0),  # EG: own side's hunters in range +% to dinos only
    # PLAN 9h (T126): the Bone Totem (Shared/Totem). Pops (a dino losing a size) in its range charge
    # it; full = the path's effect. Kinds in TOWER_STEP_KINDS; KEY_ONLY keeps them on the totem.
    ("chargeMult", 138, "num", 1),  # EH: x every pop's charge (Bounty Wall)
    ("hunterChargeX", 139, "num", 0),  # EI: a hunter's pop charges x this (Shared Charge; blank = 1)
    ("bossChargePercent", 140, "num", 0),  # EJ: a boss's pop adds this % of a full charge (Rare Bones)
    ("bountyChargeX", 141, "num", 0),  # EK: take-downs in range count x this for the owner's Bounties
    ("chargeNeededMult", 142, "num", 1),  # EL: x Tuning Totem charge to be full
    ("roarEchoes", 143, "num", 0),  # EM: Echo Roar: the roar again 1 s later
    ("roarWholeTrack", 144, "bool", False),  # EN: Ancient Roar: every dino on its side
    ("skulls", 145, "num", 0),  # EO: Skull Storm: skulls instead of the roar
    ("fullGuardSeconds", 146, "num", 0),  # EP: Spirit Guard: towers in range take no damage this long
    ("spiritHunters", 147, "bool", False),  # EQ: Spirit Hunters: ghost hunters when full (Tuning)
    ("fullCash", 148, "num", 0),  # ER: Bone Market: a full charge pays this instead of a roar
    ("paydayCash", 149, "num", 0),  # ES: Camp Payday: + this per hunter on the side, per full
    ("treasure", 150, "bool", False),  # ET: Ancient Treasure: the first full of the match drops a chest
    ("chargeAuraDamagePercent", 151, "num", 0),  # EU: Old Bones: towers in range + % x charge share
    ("hunterCooldownMult", 152, "num", 1),  # EV: Elder Wisdom: own hunters in range, ability cooldown x
    ("sideAuraHalf", 153, "bool", False),  # EW: Totem Pole: its auras reach the whole side at half
    ("boneCash", 154, "num", 0),  # EX: cash to the side per pop in range
    ("bankCashPerCharge", 155, "num", 0),  # EY: Bone Bank: at round end, x the charge held
    ("finishingRoar", 156, "bool", False),  # EZ: a free roar at a boss in range under Finisher %
    ("auraRangePercent", 157, "num", 0),  # FA: towers in range +% range (Ancestor's Eye; the Blimp's Night Hunt)
    # PLAN 9h (T125b, #334-#336): the Spotter Blimp (Shared/Blimp). KEY_ONLY keeps them on the blimp.
    ("blimpSpeedMult", 158, "num", 1),  # FB: x Tuning Blimp speed (Gunship)
    ("lapChests", 159, "bool", False),  # FC: Cargo Run: one crate every lap instead of the round's Chests
    ("lapRepairs", 160, "num", 0),  # FD: Rebuild Kits: each lap repairs up to this many Trampled towers in reach
    ("crateHealPercent", 161, "num", 0),  # FE: Spare Parts: a crate heals the nearest tower this % of max HP
    ("paratroopers", 162, "num", 0),  # FF: Paratroopers: walkers dropped once a round played (Tuning stats)
    ("airlift", 163, "bool", False),  # FG: Airlift: the side's first Trampled tower each round is repaired
    ("throwMissPercent", 164, "num", 0),  # FH: Blinding Glare: dinos under the light miss this % of throws
    ("auraReachX", 165, "num", 0),  # FI: Lighthouse: its aura damage reaches Range x this (blank = 1)
    ("dinoOutlines", 166, "bool", False),  # FJ: Spotter's Map: own-side hunters see own-side dinos (#319)
    ("bombingRun", 167, "bool", False),  # FK: Bombing Run: once a round played (AutoFire), Field strike x the gun
    ("hookEvery", 168, "num", 0),  # FL: Sky Hook: every N s lifts the smallest small dino in range
    # PLAN 9i (T127, #337): the Meteor Beacon (Shared/Meteor). KEY_ONLY keeps them on the beacon.
    ("meteors", 169, "num", 0),  # FM: each strike is this many small meteors on the densest points (blank = 1 big)
    ("scatter", 170, "bool", False),  # FN: Scatter Field: the points are the densest of equal track segments
    ("meteorEvery", 171, "num", 0),  # FO: Endless Rain: one more small meteor every N s
    ("starfallEvery", 172, "num", 0),  # FP: Starfall: every N s Starfall meteors replace the strike
    ("craterSeconds", 173, "num", 0),  # FQ: s a crater lasts (blank = Tuning Crater (s))
    ("craterAmpPercent", 174, "num", 0),  # FR: Scorch Marks: a dino crossing a crater takes +% for 3 s
    ("biteMissPercent", 175, "num", 0),  # FS: Ash Cloud: dinos in a crater miss this % of bites
    ("craterFreezeSeconds", 176, "num", 0),  # FT: New Ice Age: a dino entering a crater is hard-stopped once
    ("fireLine", 177, "bool", False),  # FU: Fire Line: close craters join into one burning strip
    ("burnStreak", 178, "bool", False),  # FV: Cinder Trail: each small meteor leaves a burning strip
    ("extinction", 179, "bool", False),  # FW: Extinction Event, once per round played (AutoFire)
    ("sideSlowPercent", 180, "num", 0),  # FX: Impact Winter: after each meteor every dino on the side slowed
    ("sideSlowSeconds", 181, "num", 0),  # FY
    ("biggestBreaks", 182, "num", 0),  # FZ: Dino Killer: the biggest dino a meteor hits breaks this many more
    # PLAN 9i (T128, #339): the Volcano Vent (Shared/Vent). KEY_ONLY keeps them on the vent.
    ("flowSeconds", 183, "num", 0),  # GA: s the lava stays down (blank = Tuning Flow (s))
    ("flowLengthMult", 184, "num", 1),  # GB: x Tuning Flow length
    ("burnBreaks", 185, "bool", False),  # GC: Lava Lake: lava ticks break 1 (Tar Pit's Boiling Pit rule)
    ("geyserEvery", 186, "num", 0),  # GD: Geyser: a burst on the stretch every N s between eruptions
    ("extraVents", 187, "num", 0),  # GE: Ring of Fire: small vents erupting in turn between the main eruptions
    ("lavaBombs", 188, "bool", False),  # GF: Lava Bombs: each eruption throws Tuning Lava bombs at the biggest dinos
    ("bossErupt", 189, "bool", False),  # GG: Pressure Valve: erupts at once when a boss enters range, once per boss
    ("sideThrowMissPercent", 190, "num", 0),  # GH: Ash Blanket: each eruption, the side's dinos miss this % of throws
    ("supervolcano", 191, "bool", False),  # GI: Supervolcano, once per round played (AutoFire)
    ("crust", 192, "bool", False),  # GJ: Obsidian: the flow's stretch is crust after the lava
    ("crustDps", 193, "num", 0),  # GK: Jagged Crust: the crust cuts dinos on it (x the team's level)
    ("mazeStuds", 194, "num", 0),  # GL: Glass Maze: a dino crossing the crust walks this much further
    ("freezeFlowSeconds", 195, "num", 0),  # GM: Frozen Fire: when the flow ends its dinos are hard-stopped
    ("throwResistPercent", 196, "num", 0),  # GN: Obsidian Armour: towers in range take this % less from throws
]

# Columns only a tower that chains (Towers column Chains) can use.
CHAIN_ONLY = ("arcs", "arcReach", "arcForks", "arcJumps", "powerGrid", "staticPercent", "judgementBolt",
              "fieldStrikeEvery", "fieldStrikeX", "chainEffects")  # the last three: PLAN 9e
# Columns only a tower with birds (Towers column Birds) can use.
BIRD_ONLY = ("birds", "eagle", "murmuration", "diveAuraRatePercent")
# Columns only a tower with harpoons (Towers column Harpoons) can use.
HARPOON_ONLY = ("skewer", "towLine", "chainHarpoons")
# Columns only a tower placed on the track (Towers column On track: the Tar Pit) can use.
TAR_ONLY = ("sinkSeconds", "eruption", "tracksSlowPercent", "auraSlowedPercent")
# Sink cash and its chest: a Tar Pit's sinks (on the track) or a Resin Cannon's fossils (PLAN 9g).
SINK_CASH = ("sinkCash", "sinkChestCash")
# Columns only a Resin tower (Towers column Resin) can use (PLAN 9g, T123).
RESIN_ONLY = ("entombSeconds", "entombHitsMult", "entombAmpPercent", "entombSpread", "entombSlowPercent",
              "entombAllEvery", "bossEntombSeconds", "sendBack", "fossilBelowPercent", "fossilRatePercent",
              "bountyFossilsX", "heartEvery", "sealSeconds", "sealEvery", "sealHealPercent", "wallSeconds")
# Columns only a tower with walkers (Towers column Walkers) can use (PLAN 9g, T124).
WALKER_ONLY = ("walkers", "walkerHpMult", "walkerSpeedMult", "walkerResistPercent", "walkerRespawnMult",
               "holdSeconds", "bossHoldSeconds", "flanking", "targetsFirst", "healsBetweenRounds", "dodge",
               "alpha", "swarm", "charge", "guard", "stunRoarEvery", "takeDownStackPercent", "avengerX")
WALKER_ONE = ("walkerHpMult", "walkerSpeedMult", "walkerRespawnMult")  # blank = 1
# Columns only one 4x tower uses (PLAN 9h): tower key -> (its columns, the ones whose blank is 1).
KEY_ONLY = {
    "TOTEM": (("chargeMult", "hunterChargeX", "bossChargePercent", "bountyChargeX", "chargeNeededMult", "roarEchoes",
               "roarWholeTrack", "skulls", "fullGuardSeconds", "spiritHunters", "fullCash", "paydayCash", "treasure",
               "chargeAuraDamagePercent", "hunterCooldownMult", "sideAuraHalf", "boneCash", "bankCashPerCharge",
               "finishingRoar"), ("chargeMult", "chargeNeededMult", "hunterCooldownMult")),
    "BLIMP": (("blimpSpeedMult", "lapChests", "lapRepairs", "crateHealPercent", "paratroopers", "airlift",
               "throwMissPercent", "auraReachX", "dinoOutlines", "bombingRun", "hookEvery"), ("blimpSpeedMult",)),
    "METEOR": (("meteors", "scatter", "meteorEvery", "starfallEvery", "craterSeconds", "craterAmpPercent",
                "biteMissPercent", "craterFreezeSeconds", "fireLine", "burnStreak", "extinction", "sideSlowPercent",
                "sideSlowSeconds", "biggestBreaks"), ()),
    "VENT": (("flowSeconds", "flowLengthMult", "burnBreaks", "geyserEvery", "extraVents", "lavaBombs", "bossErupt",
              "sideThrowMissPercent", "supervolcano", "crust", "crustDps", "mazeStuds", "freezeFlowSeconds",
              "throwResistPercent"), ("flowLengthMult",)),
}
# A KEY_ONLY column a later 4x tower reuses (PLAN 9i "Reused"): field -> the other keys allowed.
KEY_SHARED = {"throwMissPercent": ("METEOR", "VENT"), "bombingRun": ("METEOR",)}
# Resin columns another 4x tower reuses (PLAN 9i): the Volcano Vent's Obsidian Wall is the Resin Wall.
RESIN_SHARED = {"wallSeconds": ("VENT",)}

# Paths allowed a Size breaks above 1 (DECISIONS #127, #134). A new one is a
# Director call: add it here and to PLAN's design table together.
BREAK_PATHS = {
    ("Longshot Perch", "Deadeye"), ("Longshot Perch", "Big Bore"), ("Hunting Blind", "Hardliner"),
    ("Falcon Roost", "Talons"),  # PLAN T65: Power Dive 2, Iron Talons 3, Eagle of the Peak 3
    ("Harpoon Ballista", "Spearhead"),  # PLAN T66: Crusher Bolt 2, Great Harpoon 3, Skewer 3
    ("Storm Coil", "Charge"),  # PLAN 9e (#297): Thunderstrike 2 (the strike's first dino; arcs break 1)
    ("Raptor Pen", "Alpha"),  # PLAN 9g: Alpha Raptor 2, Sickle Claw 3, King of the Pack 4
    ("Raptor Pen", "Trainer"),  # PLAN 9g: Raider Hounds 2
    ("Spotter Blimp", "Door Gun"),  # PLAN T125b (#336): Heavy Mount 2
    ("Meteor Beacon", "Impact"),  # PLAN 9i (#337, #338): Ground Zero 2, Planet Killer 3; bar 3 reported
    ("Bone Totem", "Roar"),  # PLAN 9h: Thunder Roar 3 (the Spirit Roar breaks Tuning Roar breaks 2 below it)
}
HERO_BREAK_PATHS = {("Tracker", "Marksman"), ("Brush Beater", "Slug")}


def read_tuning(ws):
    out = {}
    for r in range(5, 400):
        name, val = v(ws, r, 1), v(ws, r, 2)
        if name and isinstance(val, (int, float)):
            out[ident(name)] = val
    return out


def read_towers(ws):
    towers, order = {}, []
    # Tower rows run from 5 down; a blank row in between is a slot kept free (the
    # Field Hospital's row 10 until T15). The "Cost per DPS" line (row 13, which
    # value.py reads) is skipped: towers added after it (PLAN T63) are appended below.
    for r in range(5, 40):
        name = v(ws, r, 1)
        if name and str(name).startswith("Cost per DPS"):
            continue
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
            # Can't be damaged (DECISIONS #148): no HP, never a dino's target, no repair,
            # no Armory/Hospital aura. On track: placed on the track, not off it (#152).
            "untouchable": yes(v(ws, r, 20)),
            "onTrack": yes(v(ws, r, 21)),
            # Chain lightning: each strike arcs from dino to dino (Storm Coil, PLAN T64).
            "chains": yes(v(ws, r, 22)),
            # Birds: the flock a roost flies out (Falcon Roost, PLAN T65); 0 = no birds.
            "birds": num(v(ws, r, 23)),
            # Harpoons: heavy bolts with Skewer / Tow Line / Chain Harpoons (Ballista, PLAN T66).
            "harpoons": yes(v(ws, r, 24)),
            # Resin: its hits build up resin and entomb (Amber Resin Cannon, PLAN 9g T123).
            "resin": yes(v(ws, r, 25)),
            # Walkers: NPC units on the track (Raptor Pen raptors, PLAN 9g T124); 0 = none.
            "walkers": num(v(ws, r, 26)),
            # Near track: a tower that must stand within this many studs of the track (the Volcano
            # Vent, PLAN 9i T128; Shared/Placement.checkNear); 0 = none.
            "nearTrack": num(v(ws, r, 27)),
            "paths": [],
        }
        order.append(key)
    return towers, order


# ---------------------------------------------------------------- A/B/C options
# (PLAN Phase 9 "The A/B/C system", DECISIONS #275-#278.) Tiers 1-3 rows are cumulative.
# A tier-4 or tier-5 row is one option (`Option` A/B/C) and holds only ITS OWN STEP; a
# hero tier-6 row (no option) holds only its own step too. Each effect column declares how
# a step combines with the build below it (the column registry):
#   mult  cumulative x step (blank = 1)          add   cumulative + step (blank = 0)
#   max   the higher of the two (blank = keep)   flag  on if either is on (blank = keep)
#   set   the step's value replaces it (blank = keep)
# The exporter precomposes every build into cumulative rows, so runtime keeps reading one
# row: path.tiers[1..3], path.t4[o4] (3 per path), path.t5[o4 .. o5] (9 per path) and, for
# heroes, path.t6[o4 .. o5] (9 per path). Picks: the T5 letter is independent of the T4
# letter (#276). Rows are grouped by (tower/hero, path, tier, option), never by row order,
# so new option rows are appended at the bottom of the sheet.

OPTIONS = ("A", "B", "C")
TOWER_OPTION_COLUMN, TOWER_BLURB_COLUMN = 87, 88  # Tower Upgrades CI, CJ
HERO_OPTION_COLUMN, HERO_BLURB_COLUMN = 54, 55  # Hero Upgrades BB, BC
# A Raider option (DECISIONS #284) touches enemy hunters in battles: "yes" in Tower Upgrades
# `PvP effect` (CK), on a tier-4/5 option row only, at most one per tower. Written into that
# option's rows as pvpEffect = true (absent otherwise); value.py --options holds its dino part
# to the Raider floor (PLAN T113).
TOWER_PVP_COLUMN = 89
BLURB_MAX = 60  # the pick card's line (#275)
# Composed numbers are rounded here, so a step written as a ratio (1.6 / 1.3) composes
# back to exactly 1.6; the snapshot spec (tools/test/optiona.spec.luau) holds option A to it.
COMPOSE_DIGITS = 6

# Shared/TowerStats combines PATHS by: x columns multiply, amounts take the highest, flags
# OR, freezeEvery / sinkSeconds the shortest. Within a path the steps combine the same way,
# except freezeEvery / sinkSeconds, which a step sets.
TOWER_STEP_KINDS = {
    "damageMult": "mult", "rateMult": "mult", "targetsMult": "mult", "rangeMult": "mult",
    "armoredMult": "mult", "bossMult": "mult", "splashMult": "mult", "incomeMult": "mult",
    "hunterRecoilMult": "mult", "hunterReloadMult": "mult", "hunterSpreadMult": "mult", "healMult": "mult",
    "freezeEvery": "set", "sinkSeconds": "set",
    # PLAN 9e: intervals, so a step sets them (Ground Wire's 2 s beats Grounding Spike's 4 s)
    "groundingEvery": "set", "fieldStrikeEvery": "set",
    # PLAN 9g (#316): timers where the shorter wins; a blank (0) is "off", never the minimum
    "entombAllEvery": "minpos", "heartEvery": "minpos", "sealEvery": "minpos", "stunRoarEvery": "minpos",
    "entombHitsMult": "mult", "walkerHpMult": "mult", "walkerSpeedMult": "mult", "walkerRespawnMult": "mult",
    # PLAN 9h (T126): the Bone Totem
    "chargeMult": "mult", "chargeNeededMult": "mult", "hunterCooldownMult": "mult",
    # PLAN 9h (T125b): the Spotter Blimp
    "blimpSpeedMult": "mult", "hookEvery": "minpos",
    # PLAN 9i (T127): the Meteor Beacon
    "meteorEvery": "minpos", "starfallEvery": "minpos",
    # PLAN 9i (T128): the Volcano Vent
    "flowLengthMult": "mult", "geyserEvery": "minpos",
}
for _key, _col, _kind, _default in ABILITY_COLUMNS:
    TOWER_STEP_KINDS.setdefault(_key, "flag" if _kind == "bool" else "max")

# Shared/HeroStats: x columns multiply, amounts the highest, flags OR; Fire mode (with its
# Burst count) and Pellets override, so a step sets them.
HERO_STEP_KINDS = {"fireMode": "set", "burstCount": "set", "pellets": "set"}


def _hero_kinds():
    for key, _col, kind, _default in HERO_UPGRADE_COLUMNS:
        HERO_STEP_KINDS.setdefault(key, {"mult": "mult", "bool": "flag", "text": "set"}.get(kind, "max"))


def compose_value(kind, below, step):
    """One column of a build: the cumulative value `below` plus this step.

    >>> compose_value("mult", 1.3, 1.6 / 1.3), compose_value("add", 2, 1), compose_value("max", 3, 2)
    (1.6, 3, 3)
    >>> compose_value("flag", False, True), compose_value("set", "auto", "burst"), compose_value("set", "auto", None)
    (True, 'burst', 'auto')
    >>> compose_value("minpos", 0, 12), compose_value("minpos", 20, 12), compose_value("minpos", 12, 20), compose_value("minpos", 12, 0)
    (12, 12, 12, 12)
    """
    if step is None:
        return below
    if kind == "mult":
        return round(below * step, COMPOSE_DIGITS)
    if kind == "add":
        return round(below + step, COMPOSE_DIGITS)
    if kind == "max":
        return max(below, step)
    if kind == "flag":
        return below or step
    if kind == "set":
        return step
    if kind == "minpos":  # PLAN 9g: the smaller non-blank value wins
        return step if not below or (step and step < below) else below
    raise ValueError(f"unknown step kind {kind}")


def step_value(kind, below, full):
    """The step that takes cumulative `below` to cumulative `full` (None = blank), or
    raises ValueError when this kind can't express it. Used once to turn the old
    cumulative tier-4/5 (and hero tier-6) rows into steps (option A).

    >>> step_value("mult", 1.3, 1.6), step_value("max", 3, 3), step_value("set", "auto", "burst")
    (1.230769230769, None, 'burst')
    """
    if full == below:
        return None
    if kind == "mult" and below:
        step = round(full / below, 12)
    elif kind == "add":
        step = round(full - below, 12)
    elif kind == "max" and full > below:
        step = full
    elif kind == "flag" and full and not below:
        step = full
    elif kind == "set":
        step = full
    else:
        raise ValueError(f"{kind}: {below!r} -> {full!r}")
    if compose_value(kind, below, step) != full:
        raise ValueError(f"{kind}: {below!r} -> {full!r} doesn't compose back")
    return step


def compose_row(kinds, below, step, tier, option):
    """A cumulative row: `below` (the build under it) plus the option row `step`. The
    composed row keeps the step's own name, cost and Blurb."""
    row = {field: compose_value(kind, below[field], step["steps"][field]) for field, kind in kinds.items()}
    row.update(step["own"])
    if option:
        row["option"] = option
    return row


def _option_key(ws, r, tier, entity, pid, option_col, blurb_col):
    raw = v(ws, r, option_col)
    option = str(raw).strip().upper() if raw is not None and str(raw).strip() else ""
    blurb = str(v(ws, r, blurb_col) or "").strip()
    where = f"{ws.title} row {r} ({entity} {pid} T{tier})"
    if tier in (4, 5):
        if option not in OPTIONS:
            sys.exit(f"{where}: Option must be A, B or C at tiers 4 and 5 (DECISIONS #275)")
        if len(blurb) > BLURB_MAX:
            sys.exit(f"{where}: Blurb is {len(blurb)} characters (max {BLURB_MAX})")
    elif option or blurb:
        sys.exit(f"{where}: Option and Blurb are only for tier-4/5 option rows (blank at tiers 1-3 and hero tier 6)")
    return option, blurb


def _ordered(row, order):
    """The row's fields in the sheet's column order (so Config keeps its old layout)."""
    return {**{k: row[k] for k in order if k in row}, **{k: x for k, x in row.items() if k not in order}}


def _build_path(path, kinds, rows, max_tier, where, extra=None, order=()):
    """Turn the (tier, option) -> parsed row map into path.tiers[1..3], t4, t5 (and t6).

    The T5 pick is independent of the T4 pick (#276) and T6 is composed on every T5 (#278):
    >>> K = {"damageMult": "mult", "shots": "max"}
    >>> def r(cost, full=None, **steps):
    ...     return {"full": full or {}, "steps": {k: steps.get(k) for k in K}, "own": {"name": "", "cost": cost}}
    >>> rows = {(t, ""): r(t, {"damageMult": 1.0 + t / 10, "shots": 1}) for t in (1, 2, 3)}
    >>> rows.update({(4, "A"): r(40, damageMult=2), (4, "B"): r(40, shots=3),
    ...              (5, "A"): r(50, damageMult=1.5), (5, "C"): r(50, shots=5), (6, ""): r(60, damageMult=2)})
    >>> p = {"tiers": []}; _build_path(p, K, rows, 6, "demo")
    >>> sorted(p["t5"]), sorted(p["t6"])
    (['AA', 'AC', 'BA', 'BC'], ['AA', 'AC', 'BA', 'BC'])
    >>> [(p["t6"][k]["damageMult"], p["t6"][k]["shots"]) for k in ("AA", "AC", "BA", "BC")]
    [(7.8, 1), (5.2, 5), (3.9, 3), (2.6, 5)]
    >>> rows[(5, "C")]["own"]["cost"] = 55; _build_path({"tiers": []}, K, rows, 6, "demo")
    Traceback (most recent call last):
    SystemExit: demo T5: every option at a tier costs the same (#277); found [50, 55]
    """
    for tier in (4, 5):
        costs = sorted({rows[(tier, o)]["own"]["cost"] for o in OPTIONS if (tier, o) in rows})
        if len(costs) > 1:
            sys.exit(f"{where} T{tier}: every option at a tier costs the same (#277); found {costs}")
    for tier in (1, 2, 3):
        if (tier, "") not in rows:
            sys.exit(f"{where}: no tier {tier} row")
        row = {field: rows[(tier, "")]["full"][field] for field in kinds}
        row.update(rows[(tier, "")]["own"])
        if extra:
            row.update(extra(tier))
        path["tiers"].append(_ordered(row, order))
    for tier in (4, 5):
        if (tier, "A") not in rows:
            sys.exit(f"{where}: no tier {tier} option A row (every slot keeps today's upgrade as A, #281)")
    path["t4"], path["t5"] = {}, {}
    for o4 in OPTIONS:
        if (4, o4) not in rows:
            continue
        row = compose_row(kinds, path["tiers"][2], rows[(4, o4)], 4, o4)
        if extra:
            row.update(extra(4))
        path["t4"][o4] = _ordered(row, order)
    for o4, below in path["t4"].items():
        for o5 in OPTIONS:
            if (5, o5) in rows:
                row = compose_row(kinds, below, rows[(5, o5)], 5, o5)
                if extra:
                    row.update(extra(5))
                path["t5"][o4 + o5] = _ordered(row, order)
    if max_tier == 6:
        if (6, "") not in rows:
            sys.exit(f"{where}: no tier 6 row")
        path["t6"] = {key: _ordered(compose_row(kinds, below, rows[(6, "")], 6, ""), order)
                      for key, below in path["t5"].items()}
    extra_tiers = sorted(t for t, _ in rows if t > max_tier or t < 1)
    if extra_tiers:
        sys.exit(f"{where}: tier {extra_tiers[0]} is out of range 1-{max_tier}")


def line(path, picks="AA"):
    """A path's rows from tier 1 up, for one pair of picks (option A by default):
    tiers 1-3, then t4[picks[0]], t5[picks[:2]] and, for heroes, t6[picks[:2]]."""
    out = list(path["tiers"]) + [path["t4"][picks[0]], path["t5"][picks[:2]]]
    if "t6" in path:
        out.append(path["t6"][picks[:2]])
    return out


def all_rows(path):
    """(label, row) for every cumulative row of a path: '1'..'3', '4A', '5AB', '6AB'..."""
    for i, row in enumerate(path["tiers"], start=1):
        yield str(i), row
    for key, row in path["t4"].items():
        yield "4" + key, row
    for key, row in path["t5"].items():
        yield "5" + key, row
    for key, row in path.get("t6", {}).items():
        yield "6" + key, row


def option_rows(path):
    """(label, row) once per row WRITTEN on the sheet: '1'..'3', then '4A', '4B'.., '5A'..
    (each T5 option shown on its A-after build), and hero '6'. Names, letters and Blurbs
    are the written row's; the effect numbers are a composed build's."""
    for i, row in enumerate(path["tiers"], start=1):
        yield str(i), row
    for key, row in path["t4"].items():
        yield "4" + key, row
    for key, row in path["t5"].items():
        if key[0] == "A":
            yield "5" + key[1], row
    if "t6" in path:
        yield "6", path["t6"]["AA"]


def top_rows(path):
    """Every maxed build of a path (each T5 pick pair; heroes: each T6)."""
    return list(path.get("t6", path["t5"]).values())


def tier_count(path):
    return len(path["tiers"]) + 2 + (1 if "t6" in path else 0)


TOWER_ROW_ORDER = ["name", "cost", "damageMult", "rateMult", "targetsMult", "rangeMult", "swapsModel",
                   *[key for key, _c, _k, _d in ABILITY_COLUMNS], "option", "blurb"]


def read_tower_row(ws, r):
    """One Tower Upgrades row as written: its effect columns (cumulative at tiers 1-3, a
    step at tiers 4-5) and its own name and cost."""
    full = {
        "damageMult": num(v(ws, r, 7), 1),
        "rateMult": num(v(ws, r, 8), 1),
        "targetsMult": num(v(ws, r, 9), 1),
        "rangeMult": num(v(ws, r, 12), 1),
        **{
            key: (yes(v(ws, r, col)) if kind == "bool" else num(v(ws, r, col), default))
            for key, col, kind, default in ABILITY_COLUMNS
        },
    }
    steps = {
        "damageMult": v(ws, r, 7), "rateMult": v(ws, r, 8), "targetsMult": v(ws, r, 9), "rangeMult": v(ws, r, 12),
        **{key: v(ws, r, col) for key, col, _kind, _default in ABILITY_COLUMNS},
    }
    for key, _col, kind, _default in ABILITY_COLUMNS:
        if kind == "bool":
            steps[key] = True if yes(steps[key]) else None
    steps = {k: (None if s is None or s == "" or s == "n/a" else s) for k, s in steps.items()}
    return {"full": full, "steps": steps, "own": {"name": str(v(ws, r, 13) or ""), "cost": num(v(ws, r, 5))}}


def attach_paths(ws, towers):
    by_display = {t["display"]: k for k, t in towers.items()}
    grouped = {}  # (key, pid) -> {(tier, option): row}
    r = 5
    while True:
        tower = v(ws, r, 1)
        if not tower:
            break
        key = by_display.get(str(tower).strip())
        if key is None:
            sys.exit(f"Tower Upgrades row {r}: unknown tower '{tower}' (not on the Towers sheet)")
        pid = str(v(ws, r, 2))
        tier = int(v(ws, r, 4))
        option, blurb = _option_key(ws, r, tier, towers[key]["display"], pid, TOWER_OPTION_COLUMN, TOWER_BLURB_COLUMN)
        if (key, pid) not in grouped:
            grouped[(key, pid)] = {}
            towers[key]["paths"].append({"id": pid, "focus": v(ws, r, 3) or "", "tiers": []})
        if (tier, option) in grouped[(key, pid)]:
            sys.exit(f"Tower Upgrades row {r}: {towers[key]['display']} {pid} T{tier}{option} appears twice")
        row = read_tower_row(ws, r)
        if option:
            row["own"]["blurb"] = blurb
        if yes(v(ws, r, TOWER_PVP_COLUMN)):
            if not option:
                sys.exit(f"Tower Upgrades row {r}: PvP effect is only for tier-4/5 option rows (DECISIONS #284)")
            row["own"]["pvpEffect"] = True
        grouped[(key, pid)][(tier, option)] = row
        r += 1
    for (key, pid), rows in grouped.items():
        path = next(p for p in towers[key]["paths"] if p["id"] == pid)
        _build_path(path, TOWER_STEP_KINDS, rows, 5, f"Tower Upgrades {towers[key]['display']} {pid}",
                    extra=lambda tier: {"swapsModel": tier in (3, 5)}, order=TOWER_ROW_ORDER)


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
    ("ricochetReload", 48, "num", 0),  # Bounce Back: rounds back per ricochet take-down
    ("burstRecoilReset", 49, "bool", False),  # Big Five
    ("spunUpBelt", 50, "bool", False),  # Endless Belt: no rounds used while fully spun up
    ("stillSpreadMult", 51, "mult", 1),  # Thunder Slug: spread while standing still
    ("scopedSpreadMult", 52, "mult", 1),  # Heart Shot: spread while scoped
    ("abilityCharges", 53, "num", 0),  # Rapid Response; blank = 1 charge
    # Heal regen (PLAN 9f, DECISIONS #302): after Option / Blurb (BB, BC). Mending Salve.
    ("healRegen", 56, "num", 0),  # Heal regen HP/s: everything the Triage Kit heals regains this
    ("healRegenSeconds", 57, "num", 0),  # Heal regen (s)
    # Twin Slug (PLAN T120b, DECISIONS #323): every shot of a trigger comes from one round.
    ("oneRoundPerTrigger", 58, "bool", False),
]

# Every hero path has this many tiers (DECISIONS #133: "the same amount of upgrades on
# each path").
HERO_TIERS = 6
_hero_kinds()  # the hero column registry (A/B/C steps), now that the columns exist

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


def read_hero_row(ws, r):
    """One Hero Upgrades row as written (cumulative at tiers 1-3, a step at 4-6)."""
    full, steps = {}, {}
    for field, col, kind, default in HERO_UPGRADE_COLUMNS:
        raw = v(ws, r, col)
        if kind == "bool":
            full[field] = yes(raw)
            steps[field] = True if yes(raw) else None
        elif kind == "text":
            full[field] = str(raw or "").strip().lower()
            steps[field] = full[field] or None
        else:
            full[field] = num(raw, default)
            steps[field] = None if raw is None or raw == "" or raw == "n/a" else raw
    return {"full": full, "steps": steps, "own": {"name": str(v(ws, r, 5) or ""), "cost": num(v(ws, r, 6))}}


HERO_ROW_ORDER = ["name", "cost", *[field for field, _c, _k, _d in HERO_UPGRADE_COLUMNS], "option", "blurb"]


def attach_hero_paths(ws, heroes):
    by_display = {h["display"]: h for h in heroes.values()}
    grouped = {}  # (display, pid) -> {(tier, option): row}
    r = 5
    while v(ws, r, 1):
        hero = by_display.get(str(v(ws, r, 1)).strip())
        if hero is None:
            sys.exit(f"Hero Upgrades row {r}: unknown hero '{v(ws, r, 1)}' (not on the Heroes sheet)")
        pid = str(v(ws, r, 2))
        tier = int(num(v(ws, r, 4)))
        option, blurb = _option_key(ws, r, tier, hero["display"], pid, HERO_OPTION_COLUMN, HERO_BLURB_COLUMN)
        if (hero["display"], pid) not in grouped:
            grouped[(hero["display"], pid)] = {}
            hero["paths"].append({"id": pid, "focus": v(ws, r, 3) or "", "tiers": []})
        if (tier, option) in grouped[(hero["display"], pid)]:
            sys.exit(f"Hero Upgrades row {r}: {hero['display']} {pid} T{tier}{option} appears twice")
        row = read_hero_row(ws, r)
        if option:
            row["own"]["blurb"] = blurb
        grouped[(hero["display"], pid)][(tier, option)] = row
        r += 1
    for (display, pid), rows in grouped.items():
        path = next(p for p in by_display[display]["paths"] if p["id"] == pid)
        _build_path(path, HERO_STEP_KINDS, rows, HERO_TIERS, f"Hero Upgrades {display} {pid}", order=HERO_ROW_ORDER)


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


# Cosmetics (PLAN round 4 T57, DECISIONS #121): Kind column text -> (Config kind, the
# rarity it must have). Commons are the six simple colours; rares the hat, gun pattern,
# hit-marker and trail; legendaries the animated sets; titles their own rarity.
COSMETIC_KINDS = {
    "Name colour": ("nameColour", "common"),
    "Gun tint": ("gunTint", "common"),
    "Tracer colour": ("tracer", "common"),
    "Crosshair colour": ("crosshair", "common"),
    "Tower flag": ("towerFlag", "common"),
    "Leaderboard banner": ("banner", "common"),
    "Hunting hat": ("hat", "rare"),
    "Gun pattern": ("gunFinish", "rare"),
    "Hit-marker": ("hitMarker", "rare"),
    "Sprint trail": ("trail", "rare"),
    "Animated set": ("set", "legendary"),
    "Title": ("title", "title"),
}
# Pattern values a kind may use (blank = none); other kinds leave it blank.
COSMETIC_PATTERNS = {
    "hat": {"Brim", "Cap", "Crest"},
    "hitMarker": {"Cross", "Plus", "Diamond", "Star"},
    "set": {"Pulse", "Cycle"},
}
# Roblox materials a cosmetic may use. No Neon: a glowing gun is mastery 20's gold look.
COSMETIC_MATERIALS = {
    "Plastic", "SmoothPlastic", "Wood", "WoodPlanks", "Marble", "Slate", "Granite", "Metal",
    "DiamondPlate", "Fabric", "Sand", "Pebble", "Brick", "Cobblestone", "Concrete", "Ice",
    "Foil", "Glass", "Grass",
}
MASTERY_GOLD = (250, 200, 60)  # Server/Hero's gold gun; no cosmetic may come near it
GOLD_DISTANCE = 80  # RGB distance below which a colour counts as gold
COSMETIC_TOP = 200  # the last level with listed rewards; past it only the repeat title
COSMETIC_HEADER_ROW = 4


def read_cosmetics(ws):
    """Cosmetics: Id, Level, Kind, Name, Rarity, Colour, Material, Pattern, Repeat every.

    Returns a list in sheet order. `kind` is the Config kind (COSMETIC_KINDS); unknown
    kind text goes out as "" and fails validation. Colour goes out as {r, g, b} ({} when
    blank); `every` is 0 except on the past-200 title row."""
    columns = {}
    for c in range(1, ws.max_column + 1):
        head = v(ws, COSMETIC_HEADER_ROW, c)
        if head is not None:
            columns[str(head).strip()] = c
    wanted = ["Id", "Level", "Kind", "Name", "Rarity", "Colour", "Material", "Pattern", "Repeat every"]
    for head in wanted:
        if head not in columns:
            sys.exit(f"Cosmetics row {COSMETIC_HEADER_ROW}: no '{head}' column (columns are found by header)")
    out = []
    r = COSMETIC_HEADER_ROW + 1
    while v(ws, r, columns["Id"]):
        cell = lambda head: v(ws, r, columns[head])
        kind_text = str(cell("Kind") or "").strip()
        colour_text = str(cell("Colour") or "").strip()
        colour = []
        m = re.fullmatch(r"#?([0-9A-Fa-f]{6})", colour_text)
        if m:
            colour = [int(m.group(1)[i:i + 2], 16) for i in (0, 2, 4)]
        elif colour_text:
            sys.exit(f"Cosmetics row {r}: Colour '{colour_text}' must be #RRGGBB")
        out.append({
            "id": str(cell("Id")).strip(),
            "level": num(cell("Level")),
            "kind": COSMETIC_KINDS.get(kind_text, ("", ""))[0],
            "name": str(cell("Name") or "").strip(),
            "rarity": str(cell("Rarity") or "").strip().lower(),
            "colour": colour,
            "material": str(cell("Material") or "").strip(),
            "pattern": str(cell("Pattern") or "").strip(),
            "every": num(cell("Repeat every")),
        })
        r += 1
    return out


def validate_cosmetics(data, problems, notes):
    """The reward ladder (DECISIONS #121, PLAN T57): one cosmetic per listed level (a title
    may sit beside it), commons only at non-multiples of 10 below 100, a rare + a title every
    10 to 100, a legendary + a title at 150 and 200, nothing else up to 200, one repeating
    title past 200, and no gold anywhere (mastery 20's)."""
    items = data["Cosmetics"]
    rarity_of = {key: rarity for key, rarity in COSMETIC_KINDS.values()}
    ids, names, by_level, repeats = set(), set(), {}, []
    taken = {d["display"].lower() for block in ("Heroes", "Towers") for d in data[block].values()}
    for item in items:
        where = f"Cosmetics {item['id']}"
        if not re.fullmatch(r"[A-Z0-9_]+", item["id"]):
            problems.append(f"{where}: Id must be capitals, digits and _")
        if item["id"] in ids:
            problems.append(f"{where}: Id is used twice")
        ids.add(item["id"])
        if not item["name"]:
            problems.append(f"{where}: needs a Name")
        if item["name"].lower() in names:
            problems.append(f"{where}: Name '{item['name']}' is used twice")
        names.add(item["name"].lower())
        if item["name"].lower() in taken:
            problems.append(f"{where}: Name '{item['name']}' is already a hero's or tower's name")
        if "gold" in item["name"].lower():
            problems.append(f"{where}: no gold cosmetics (gold is mastery 20's alone)")
        kind = item["kind"]
        if not kind:
            problems.append(f"{where}: Kind must be one of {', '.join(COSMETIC_KINDS)}")
            continue
        if item["rarity"] != rarity_of[kind]:
            problems.append(f"{where}: a {kind} is {rarity_of[kind]}, not '{item['rarity']}'")
        level = item["level"]
        if not isinstance(level, (int, float)) or level != int(level) or level < 2:
            problems.append(f"{where}: Level must be a whole number, 2 or more")
            continue
        colour = item["colour"]
        if kind == "title":
            if colour or item["material"] or item["pattern"]:
                problems.append(f"{where}: a title has no Colour, Material or Pattern")
        elif len(colour) != 3:
            problems.append(f"{where}: needs a Colour (#RRGGBB)")
        elif sum((a - b) ** 2 for a, b in zip(colour, MASTERY_GOLD)) ** 0.5 < GOLD_DISTANCE:
            problems.append(f"{where}: Colour is too close to mastery 20's gold")
        if item["material"] and item["material"] not in COSMETIC_MATERIALS:
            problems.append(f"{where}: Material '{item['material']}' isn't allowed ({', '.join(sorted(COSMETIC_MATERIALS))})")
        allowed = COSMETIC_PATTERNS.get(kind, set())
        if item["pattern"] and item["pattern"] not in allowed:
            problems.append(f"{where}: Pattern '{item['pattern']}' isn't one for a {kind} ({', '.join(sorted(allowed)) or 'leave it blank'})")
        if kind in ("hat", "set") and not item["pattern"]:
            problems.append(f"{where}: a {kind} needs a Pattern ({', '.join(sorted(allowed))})")
        every = item["every"]
        if every:
            repeats.append(item)
            if kind != "title" or level <= COSMETIC_TOP or every <= 0 or every != int(every):
                problems.append(f"{where}: only a title past level {COSMETIC_TOP} may repeat, every whole number of levels")
            elif (level - COSMETIC_TOP) % every:
                problems.append(f"{where}: Level {level:g} must be {COSMETIC_TOP} + a multiple of Repeat every ({every:g})")
            if "{n}" not in item["name"]:
                problems.append(f"{where}: a repeating title needs {{n}} (the level) in its Name, so each one differs")
            continue
        if level > COSMETIC_TOP:
            problems.append(f"{where}: only the repeating title goes past level {COSMETIC_TOP}")
            continue
        by_level.setdefault(int(level), []).append(item)
    if len(repeats) != 1:
        problems.append(f"Cosmetics: exactly one title past level {COSMETIC_TOP} must repeat (Repeat every); found {len(repeats)}")
    counts = {}
    for level in range(2, COSMETIC_TOP + 1):
        here = by_level.get(level, [])
        titles = [i for i in here if i["kind"] == "title"]
        cosmetics = [i for i in here if i["kind"] != "title"]
        if level < 100 and level % 10:
            want, want_title = "common", False
        elif level <= 100 and level % 10 == 0:
            want, want_title = "rare", True
        elif level in (150, 200):
            want, want_title = "legendary", True
        else:
            want, want_title = None, False
        got = [i["rarity"] for i in cosmetics]
        if want is None and here:
            problems.append(f"Cosmetics level {level}: no rewards between 101-149 and 151-199 (DECISIONS #121)")
        elif want and got != [want]:
            problems.append(f"Cosmetics level {level}: needs exactly one {want} cosmetic (has {', '.join(got) or 'none'})")
        if want_title != (len(titles) == 1) or len(titles) > 1:
            problems.append(f"Cosmetics level {level}: needs {'one title' if want_title else 'no title'} (has {len(titles)})")
        for i in here:
            counts[i["rarity"]] = counts.get(i["rarity"], 0) + 1
    if repeats:
        r = repeats[0]
        notes.append(f"cosmetics: {counts.get('common', 0)} common, {counts.get('rare', 0)} rare, {counts.get('legendary', 0)} legendary, {counts.get('title', 0)} titles to level {COSMETIC_TOP}; then a title every {r['every']:g} from {r['level']:g}")


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


def perk_parity(worth, band):
    """Hero-vs-hero perk parity (PLAN T84, DECISIONS #220, #235): at mastery 10 (the level-10
    perk) and at mastery 15+ (level 10 + level 15 summed; 20 adds no ability perk), the max
    / min of the heroes' #99 worth % must be at most 1 + band. `worth` is {hero name:
    {level: worth %}}. Returns (problems, ratios) with ratios {label: max / min}.

    >>> perk_parity({"A": {10: 25, 15: 40}, "B": {10: 24, 15: 35}}, 0.15)[0]
    []
    >>> problems, ratios = perk_parity({"A": {10: 25, 15: 40}, "B": {10: 20, 15: 30}}, 0.15)
    >>> problems
    ['Mastery Perks: parity at mastery 10 is 1.25 (A 25% / B 20%), above 1 + Perk parity band (1.15; buff the weaker perk, DECISIONS #220, #235)', 'Mastery Perks: parity at mastery 15+ is 1.30 (A 65% / B 50%), above 1 + Perk parity band (1.15; buff the weaker perk, DECISIONS #220, #235)']
    >>> round(ratios["mastery 15+"], 2)
    1.3
    >>> perk_parity({"A": {10: 0, 15: 40}, "B": {10: 20, 15: 20}}, 0.15)[0]
    ['Mastery Perks: parity at mastery 10 has a hero worth 0%, so the max / min is unbounded (DECISIONS #235)']
    """
    low, high = PERK_LEVELS
    problems, ratios = [], {}
    for label, total in ((f"mastery {low}", lambda w: w[low]), (f"mastery {high}+", lambda w: w[low] + w[high])):
        sums = {name: total(w) for name, w in worth.items() if low in w and high in w}
        if len(sums) < 2:
            continue
        top, bottom = max(sums, key=sums.get), min(sums, key=sums.get)
        if sums[bottom] <= 0:
            problems.append(f"Mastery Perks: parity at {label} has a hero worth 0%, so the max / min is unbounded (DECISIONS #235)")
            continue
        ratios[label] = sums[top] / sums[bottom]
        if ratios[label] > 1 + band + 1e-9:
            problems.append(f"Mastery Perks: parity at {label} is {ratios[label]:.2f} ({top} {sums[top]:g}% / {bottom} {sums[bottom]:g}%),"
                            f" above 1 + Perk parity band ({1 + band:g}; buff the weaker perk, DECISIONS #220, #235)")
    return problems, ratios


def validate_perks(data, problems, notes):
    """Mastery Perks (PLAN round 3 T32). "Level 15 is objectively stronger" and
    "PvP-safe" are rules here, not opinions (DECISIONS #99)."""
    tuning, heroes, perks = data["Tuning"], data["Heroes"], data["MasteryPerks"]
    cap = tuning.get("MasteryPerkWorthCap")
    if not isinstance(cap, (int, float)) or cap <= 0:
        problems.append("Tuning is missing 'Mastery perk worth cap' (MASTERY PERKS; the exporter checks every perk against it)")
        cap = None
    shown, by_hero = [], {}
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
            by_hero[hero["display"]] = worth
    for key, hero in heroes.items():
        have = {p["level"] for p in perks.get(key, [])}
        for level in PERK_LEVELS:
            if level not in have:
                problems.append(f"Mastery Perks: {hero['display']} ({key}) has no level-{level} perk")
    if shown:
        limit = f", cap {cap:g}" if cap is not None else ""
        notes.append(f"mastery perks worth % (level {PERK_LEVELS[0]} / {PERK_LEVELS[1]}{limit}): " + ", ".join(shown))
    band = tuning.get("PerkParityBand")
    if not isinstance(band, (int, float)) or band < 0:
        problems.append("Tuning is missing 'Perk parity band' (PVP; the exporter checks hero-vs-hero perk parity against it)")
    elif by_hero:
        parity_problems, ratios = perk_parity(by_hero, band)
        problems += parity_problems
        notes.append(f"perk parity max / min (bar {1 + band:g}): " + ", ".join(f"{label} {r:.2f}" for label, r in ratios.items()))


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



ARENA_HEADER_ROW = 4


def read_arenas(ws):
    """Arenas (PLAN phase 7 T73, DECISIONS #218): Key, Name, Floor, Reward, found by
    header. A list in sheet order, lowest arena first; Reward "" = none."""
    columns = {}
    for c in range(1, ws.max_column + 1):
        head = v(ws, ARENA_HEADER_ROW, c)
        if head is not None:
            columns[str(head).strip()] = c
    for head in ("Key", "Name", "Floor", "Reward"):
        if head not in columns:
            sys.exit(f"Arenas row {ARENA_HEADER_ROW}: no '{head}' column (columns are found by header)")
    out, seen = [], set()
    r = ARENA_HEADER_ROW + 1
    while v(ws, r, columns["Key"]):
        key = str(v(ws, r, columns["Key"])).strip()
        if key in seen:
            sys.exit(f"Arenas row {r}: Key '{key}' is used twice")
        seen.add(key)
        out.append({
            "key": key,
            "display": str(v(ws, r, columns["Name"]) or "").strip(),
            "floor": num(v(ws, r, columns["Floor"])),
            "reward": str(v(ws, r, columns["Reward"]) or "").strip(),
        })
        r += 1
    return out


# BATTLE MODES levers (PLAN phase 7 T73, DECISIONS #208-#226); the game reads each by name.
BATTLE_LEVERS = [
    "BattleBuildTime", "BattleRoundTime", "BattleSideDensity", "PvPTowerDamage", "PvPHunterDamage",
    "SpawnShield", "OvertimeHPStep", "SurvivorBonus", "RaidBones", "TeamMinPlayers", "RoyaleMinPlayers",
    "BattleMaxPlayers", "CompetitiveBuyIn", "TeamWinPayout", "TeamLossPayout", "Royale1stPayout",
    "Royale2ndPayout", "Royale3rdPayout", "RoyaleRestPayout", "RoyalePot1st", "RoyalePot2nd", "RoyalePot3rd",
    "TeamWinTrophies", "TeamLossTrophies", "Royale1stTrophies", "RoyaleLastTrophies",
    "CompetitiveEdgeMax", "PerkParityBand", "BattleRoundBreak", "BattleResultsTime",
]
BUY_IN_RANGE = (10, 20)  # VISION.md "Amber economy": a 10-20 buy-in


def pvp_lever_problem(key, value):
    """Why a PvP damage lever is out of range, or None (DECISIONS #211, #212, #228).
    PvP tower damage stays in (0, 1]: raiding towers is the battle modes' point, so it
    can't be switched off. PvP hunter damage may be 0 (hunter vs hunter off, #228).

    >>> pvp_lever_problem("PvPHunterDamage", 0) is None
    True
    >>> pvp_lever_problem("PvPHunterDamage", 0.5) is None
    True
    >>> pvp_lever_problem("PvPHunterDamage", 1) is None
    True
    >>> pvp_lever_problem("PvPHunterDamage", -0.1)
    'Tuning PvPHunterDamage (-0.1) must be in [0, 1] (0 = hunter vs hunter off; DECISIONS #212, #228)'
    >>> pvp_lever_problem("PvPHunterDamage", 1.5) is None
    False
    >>> pvp_lever_problem("PvPTowerDamage", 0)
    'Tuning PvPTowerDamage (0) must be in (0, 1] (DECISIONS #211, #228)'
    >>> pvp_lever_problem("PvPTowerDamage", 0.35) is None
    True
    >>> pvp_lever_problem("PvPTowerDamage", 1.2) is None
    False
    """
    if key == "PvPHunterDamage":
        if not (0 <= value <= 1):
            return f"Tuning {key} ({value:g}) must be in [0, 1] (0 = hunter vs hunter off; DECISIONS #212, #228)"
        return None
    if not (0 < value <= 1):
        return f"Tuning {key} ({value:g}) must be in (0, 1] (DECISIONS #211, #228)"
    return None


def validate_battle(data, problems, notes):
    """Battle modes, stakes and Trophies (PLAN phase 7 T73). Mirrors Shared/Stakes'
    arithmetic for the competitive-beats-casual check (DECISIONS #215)."""
    tuning = data["Tuning"]
    missing = [k for k in BATTLE_LEVERS if k not in tuning]
    for key in missing:
        problems.append(f"Tuning is missing '{key}' (BATTLE MODES; the game reads it by name)")
    if missing:
        return
    t = tuning
    low, high = BUY_IN_RANGE
    buy_in = t["CompetitiveBuyIn"]
    if not (low <= buy_in <= high) or buy_in != int(buy_in):
        problems.append(f"Tuning Competitive buy-in ({buy_in:g}) must be a whole number from {low} to {high} (VISION.md)")
    splits = [t["RoyalePot1st"], t["RoyalePot2nd"], t["RoyalePot3rd"]]
    if sum(splits) != 100 or any(s < 0 for s in splits):
        problems.append(f"Tuning Royale pot 1st/2nd/3rd ({'/'.join(f'{s:g}' for s in splits)}) must be >= 0 and add to 100")
    if not (splits[0] >= splits[1] >= splits[2]):
        problems.append("Tuning Royale pot shares must not grow with a worse placement")
    for key in ("PvPTowerDamage", "PvPHunterDamage"):
        problem = pvp_lever_problem(key, t[key])
        if problem:
            problems.append(problem)
    for key in ("BattleBuildTime", "BattleRoundTime", "BattleSideDensity", "OvertimeHPStep", "BattleResultsTime"):
        if t[key] <= 0:
            problems.append(f"Tuning {key} must be above 0")
    if t["OvertimeHPStep"] <= 1:
        problems.append("Tuning Overtime HP step must be above 1, so overtime ends")
    for key in ("SpawnShield", "SurvivorBonus", "RaidBones", "TeamWinPayout", "TeamLossPayout",
                "Royale1stPayout", "Royale2ndPayout", "Royale3rdPayout", "RoyaleRestPayout",
                "CompetitiveEdgeMax", "PerkParityBand", "BattleRoundBreak"):
        if t[key] < 0:
            problems.append(f"Tuning {key} must not be negative")
    if not (t["Royale1stPayout"] >= t["Royale2ndPayout"] >= t["Royale3rdPayout"] >= t["RoyaleRestPayout"]):
        problems.append("Tuning casual Royale payouts must not grow with a worse placement")
    if t["TeamWinPayout"] < t["TeamLossPayout"]:
        problems.append("Tuning Team win payout must be at least Team loss payout")
    if not (2 <= t["TeamMinPlayers"] <= t["BattleMaxPlayers"]) or not (3 <= t["RoyaleMinPlayers"] <= t["BattleMaxPlayers"]):
        problems.append("Tuning Team/Royale min players must be at least 2/3 and at most Battle max players (DECISIONS #217)")
    if t["TeamWinTrophies"] <= 0 or t["Royale1stTrophies"] <= 0:
        problems.append("Tuning Team win / Royale 1st trophies must be above 0")
    if t["TeamLossTrophies"] >= 0 or t["RoyaleLastTrophies"] >= 0:
        problems.append("Tuning Team loss / Royale last trophies must be below 0 (a loss loses Trophies)")
    for key in ("TeamWinTrophies", "TeamLossTrophies", "Royale1stTrophies", "RoyaleLastTrophies",
                "TeamMinPlayers", "RoyaleMinPlayers", "BattleMaxPlayers", "RaidBones"):
        if t[key] != int(t[key]):
            problems.append(f"Tuning {key} must be a whole number")

    # Competitive always pays more than casual (VISION.md; DECISIONS #215): the winner at
    # the minimum lobby gets the casual payout plus a pot share that is above 0.
    team_pot = int(buy_in) * int(t["TeamMinPlayers"])
    team_share = team_pot // max(1, (int(t["TeamMinPlayers"]) + 1) // 2)  # the larger of two sides wins
    royale_pot = int(buy_in) * int(t["RoyaleMinPlayers"])
    royale_share = royale_pot * int(splits[0]) // 100
    for mode, casual, share in (("Team", t["TeamWinPayout"], team_share), ("Royale", t["Royale1stPayout"], royale_share)):
        if casual + share <= casual:
            problems.append(f"Competitive {mode} winner at the minimum lobby gets {casual + share:g}, not more than casual {casual:g} (DECISIONS #215)")
    notes.append(f"competitive: buy-in {buy_in:g}; min-lobby winner Team {t['TeamWinPayout'] + team_share:g} vs casual {t['TeamWinPayout']:g},"
                 f" Royale {t['Royale1stPayout'] + royale_share:g} vs casual {t['Royale1stPayout']:g}")

    arenas = data["Arenas"]
    floors = [a["floor"] for a in arenas]
    if not arenas or floors[0] != 0:
        problems.append("Arenas: the first arena's Floor must be 0 (everyone starts at 0 Trophies)")
    for prev, cur in zip(arenas, arenas[1:]):
        if not cur["floor"] > prev["floor"]:
            problems.append(f"Arenas {cur['key']}: Floor {cur['floor']:g} must be above {prev['key']}'s {prev['floor']:g} (floors ascend)")
    for a in arenas:
        if a["floor"] != int(a["floor"]):
            problems.append(f"Arenas {a['key']}: Floor must be a whole number")
        if not a["display"]:
            problems.append(f"Arenas {a['key']}: Name is blank")
    cosmetic_ids = {c["id"] for c in data["Cosmetics"]}
    for a in arenas:
        if a["reward"] and a["reward"] not in cosmetic_ids:
            problems.append(f"Arenas {a['key']}: Reward '{a['reward']}' is not a Cosmetics Id (an arena unlocks a cosmetic or title only)")
    notes.append("arenas: " + ", ".join(f"{a['display']} {a['floor']:g}" for a in arenas))


PACE_LEVERS = [
    "RoundPace", "TrackWalkSeconds", "CasualRoundStep", "RankedRoundStep", "CasualMatchCap", "RankedMatchCap",
    "ClockWarning", "LateJoinCashX", "LateJoinLastRound", "BoneRushSparePlots", "CoOpLengthMax",
    "BattleCrowdX", "AbilityTempo", "BattleFenceDrain",
]
CASUAL_CAP_MAX, RANKED_CAP_MAX = 900, 1800  # DIRECTION 2026-10-09: casual <= 15 min, Ranked <= 30 min (#249, #252)


def round_parts(data, rd, difficulty):
    """(S, W) of one round (DECISIONS #250): S = enemies x spawn gap (the spawn phase, which
    count scaling and density don't change: the gap shrinks by the same factor), W = Track
    walk seconds / the difficulty's speed. Shared/Pace computes the same."""
    s = sum(rd["counts"].values()) * rd["spawnGap"]
    return s, data["Tuning"]["TrackWalkSeconds"] / difficulty["speedMult"]


def paced_length(data, rd, difficulty):
    """A round's length at Round pace: pace x S + W (unrounded)."""
    s, w = round_parts(data, rd, difficulty)
    return data["Tuning"]["RoundPace"] * s + w


def pace_hp_x(data, rd, difficulty):
    """Dino HP x for a round: (pace x S + W) / (S + W), so EHP / length is unchanged."""
    s, w = round_parts(data, rd, difficulty)
    return (data["Tuning"]["RoundPace"] * s + w) / (s + w) if s + w > 0 else 1.0


def paced_counts(data, rd, count_x, crowd=1.0):
    """Shared/Pace.plan's counts (DECISIONS #258): species -> spawns in play. Unpaced =
    max(1, round half up(n x count x)); paced = max(1, round half up(n x count x x Round pace
    x crowd)), bosses keep the unpaced count. The spawn gap is the sheet's / count x (unchanged)."""
    pace, out = data["Tuning"]["RoundPace"], {}
    for key, n in rd["counts"].items():
        if n > 0:
            boss = data["Enemies"][key]["boss"]
            out[key] = max(1, math.floor(n * count_x * (1 if boss else pace * crowd) + 0.5))
    return out


def pace_plan_x(data, rd, difficulty, count_x, crowd=1.0, promote=None):
    """Shared/Pace.plan's (hpX, ratio) for one round (DECISIONS #258): ratio = unpaced round
    EHP / paced round EHP (expected EHP per spawn; `promote` = species -> its promotion, with
    the difficulty's promoteChance), hpX = pace_hp_x x ratio."""
    p, enemies = difficulty.get("promoteChance", 0), data["Enemies"]
    paced = paced_counts(data, rd, count_x, crowd)
    before = after = 0.0
    for key, n in rd["counts"].items():
        if n > 0:
            each = enemies[key]["effectiveHp"]
            up = (promote or {}).get(key)
            if up and p:
                each = (1 - p) * each + p * enemies[up]["effectiveHp"]
            before += max(1, math.floor(n * count_x + 0.5)) * each
            after += paced[key] * each
    ratio = before / after if after else 1.0
    return pace_hp_x(data, rd, difficulty) * ratio, ratio


def played_rounds(last, step):
    """The rounds a battle plays (#251): first = last - step x floor((last - 1) / step), then every step-th."""
    step = int(step)
    first = last - step * ((last - 1) // step)
    return list(range(first, last + 1, step))


def validate_pace(data, problems, notes):
    """Match length levers (PLAN Phase 8 batch 2 T101, DECISIONS #250-#254)."""
    t = data["Tuning"]
    missing = [k for k in PACE_LEVERS if k not in t]
    for key in missing:
        problems.append(f"Tuning is missing '{key}' (MATCH LENGTH; the game and the models read it by name)")
    if missing:
        return
    last = len(data["Rounds"])
    if not 0 < t["RoundPace"] <= 1:
        problems.append(f"Tuning Round pace ({t['RoundPace']:g}) must be above 0 and at most 1 (DECISIONS #250)")
    if t["TrackWalkSeconds"] <= 0:
        problems.append("Tuning Track walk seconds must be above 0")
    for key in ("CasualRoundStep", "RankedRoundStep"):
        step = t[key]
        if step < 1 or step != int(step):
            problems.append(f"Tuning {key} ({step:g}) must be a whole number >= 1 (DECISIONS #251)")
        elif played_rounds(last, step)[-1] != last:
            problems.append(f"Tuning {key}: the round list must end at round {last}")
    if not 0 < t["CasualMatchCap"] <= CASUAL_CAP_MAX:
        problems.append(f"Tuning Casual match cap ({t['CasualMatchCap']:g}) must be above 0 and at most {CASUAL_CAP_MAX} s (DECISIONS #252)")
    if not 0 < t["RankedMatchCap"] <= RANKED_CAP_MAX:
        problems.append(f"Tuning Ranked match cap ({t['RankedMatchCap']:g}) must be above 0 and at most {RANKED_CAP_MAX} s (DECISIONS #252)")
    if not 0 < t["ClockWarning"] < min(t["CasualMatchCap"], t["RankedMatchCap"]):
        problems.append(f"Tuning Clock warning ({t['ClockWarning']:g}) must be above 0 and below both match caps")
    if t["LateJoinCashX"] < 0:
        problems.append("Tuning Late join cash x must not be negative")
    if not 1 <= t["LateJoinLastRound"] < last or t["LateJoinLastRound"] != int(t["LateJoinLastRound"]):
        problems.append(f"Tuning Late join last round ({t['LateJoinLastRound']:g}) must be a whole round from 1 to below {last} (DECISIONS #254)")
    spare = t["BoneRushSparePlots"]
    if spare < 0 or spare != int(spare):
        problems.append(f"Tuning Bone Rush spare plots ({spare:g}) must be a whole number >= 0")
    if t["CoOpLengthMax"] <= 0:
        problems.append("Tuning Co-op length max must be above 0")
    if not 0 < t["BattleCrowdX"] <= 1:
        problems.append(f"Tuning Battle crowd x ({t['BattleCrowdX']:g}) must be above 0 and at most 1 (DECISIONS #258)")
    if not 1 <= t["BattleFenceDrain"] <= 40:
        problems.append(f"Tuning Battle Fence drain ({t['BattleFenceDrain']:g}) must be from 1 to 40 Fence per second (DECISIONS #267)")
    if 0 < t["RoundPace"] <= 1 and not 1 <= t["AbilityTempo"] <= 1 / t["RoundPace"] + 1e-9:
        problems.append(f"Tuning Ability tempo ({t['AbilityTempo']:g}) must be from 1 to 1 / Round pace ({1 / t['RoundPace']:g}) (DECISIONS #259)")
    for key in ("NORMAL", "CHAOS"):
        d = data["Difficulties"].get(key)
        if not d:
            problems.append(f"Difficulty {key} is missing (Battle round time is checked against it)")
            continue
        longest, at = max((paced_length(data, rd, d), i) for i, rd in enumerate(data["Rounds"], start=1))
        if t["BattleRoundTime"] < longest:
            problems.append(f"Tuning Battle round time ({t['BattleRoundTime']:g}) must be >= the longest paced {d['display']} round"
                            f" ({longest:.1f} s, round {at}; DECISIONS #251)")
        else:
            notes.append(f"pace: longest paced {d['display']} round {longest:.1f} s (round {at}) <= Battle round time {t['BattleRoundTime']:g}")


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
        if t["birds"] and (t["birds"] != int(t["birds"]) or t["birds"] < 1 or t["chains"]):
            problems.append(f"{key}: Birds must be a whole number >= 1, on a tower that doesn't chain")
        if t["harpoons"] and (t["chains"] or t["birds"]):
            problems.append(f"{key}: Harpoons can't go on a tower that chains or has birds")
        if t["untouchable"]:
            if t["maxHp"] != 0:
                problems.append(f"{key} can't be damaged (Towers column T), so its Max HP must be blank or 0")
        elif not isinstance(t["maxHp"], (int, float)) or t["maxHp"] <= 0:
            problems.append(f"{key} needs a Max HP above 0 (Towers column P)")
        for p in t["paths"]:
            for i, step in all_rows(p):
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
                for field in CHAIN_ONLY:  # Field strike x: a Bombing Run's too (the Blimp, T125b)
                    if step[field] and not t["chains"] and not (field == "fieldStrikeX" and step["bombingRun"]):
                        problems.append(f"{key} {p['id']} tier {i}: {field} needs a tower that chains (Towers column V)")
                # The Blimp's Bombing Run fires Field strike x once a round (AutoFire), no timer (T125b).
                if bool(step["fieldStrikeEvery"]) != bool(step["fieldStrikeX"]) and not (step["bombingRun"] and not step["fieldStrikeEvery"]):
                    problems.append(f"{key} {p['id']} tier {i}: Field strike every (s) and Field strike x go together (PLAN 9e)")
                if step["arcForks"] and step["arcForks"] != int(step["arcForks"]) or step["arcs"] != int(step["arcs"]):
                    problems.append(f"{key} {p['id']} tier {i}: Arcs and Arc forks must be whole numbers")
                for field in BIRD_ONLY:  # Dive aura rate %: a Raptor Pen's raptors too (PLAN 9g)
                    if step[field] and not (t["birds"] or (field == "diveAuraRatePercent" and t["walkers"])):
                        problems.append(f"{key} {p['id']} tier {i}: {field} needs a tower with birds (Towers column W)")
                for field in HARPOON_ONLY:
                    if step[field] and not t["harpoons"]:
                        problems.append(f"{key} {p['id']} tier {i}: {field} needs a tower with harpoons (Towers column X)")
                for field in TAR_ONLY:
                    if step[field] and not t["onTrack"]:
                        problems.append(f"{key} {p['id']} tier {i}: {field} needs a tower placed on the track (Towers column U)")
                for field in SINK_CASH:
                    if step[field] and not (t["onTrack"] or t["resin"]):
                        problems.append(f"{key} {p['id']} tier {i}: {field} needs a Tar Pit or a Resin tower (Towers column U or Y)")
                for field in WALKER_ONLY:
                    if step[field] not in (False, 1 if field in WALKER_ONE else 0) and not t["walkers"]:
                        problems.append(f"{key} {p['id']} tier {i}: {field} needs a tower with walkers (Towers column Z)")
                for field in RESIN_ONLY:
                    if step[field] != (1 if field == "entombHitsMult" else 0) and not t["resin"] and key not in RESIN_SHARED.get(field, ()):
                        problems.append(f"{key} {p['id']} tier {i}: {field} needs a Resin tower (Towers column Y)")
                for owner, (fields, ones) in KEY_ONLY.items():
                    for field in fields:
                        if step[field] not in (False, 1 if field in ones else 0) and key != owner and key not in KEY_SHARED.get(field, ()):
                            problems.append(f"{key} {p['id']} tier {i}: {field} is the {owner} tower's own column (PLAN 9h)")
                if step["tracksSlowPercent"] > 100 or (t["onTrack"] and step["slowPercent"] > 100):
                    problems.append(f"{key} {p['id']} tier {i}: Slow % and Tracks slow % must be 0-100")
                if step["birds"] != int(step["birds"]):
                    problems.append(f"{key} {p['id']} tier {i}: Birds must be a whole number")
                if step["firstDiveX"] != 1 and not (t["birds"] or t["walkers"]):
                    problems.append(f"{key} {p['id']} tier {i}: First dive x needs a tower with birds or walkers (Towers column W / Z)")
                if step["firstDiveX"] < 1:
                    problems.append(f"{key} {p['id']} tier {i}: First dive x must be 1 or more (blank = 1)")
                if step["auraArcPercent"] > 100:
                    problems.append(f"{key} {p['id']} tier {i}: Aura arc % must be 0-100")
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
            if tier_count(p) != HERO_TIERS:
                problems.append(f"Hero {name} {p['id']}: needs {HERO_TIERS} tiers on Hero Upgrades (has {tier_count(p)}; DECISIONS #133)")
            for i, step in all_rows(p):
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
        "CoilArcs", "CoilArcReach", "CoilArcFalloff", "PowerGridRangePerCoil", "PowerGridDamageBase",
        "PowerGridDamagePerCoil", "PowerGridCoilCap", "PowerGridEvery", "JudgementBoltEvery",
        "JudgementBoltX", "JudgementBoltBreaks", "JudgementBoltStun",
        "FalconSpeed", "EagleDiveX", "FalconBellsMark", "TowLineEvery", "TowLinePull", "BoltWidth",
        "EruptionEvery", "EruptionSizes", "TarSinkSeconds", "TarTracksLength", "TarTracksSeconds",
        "PlayerXPBase", "PlayerXPStep", "PlayerXPPerLevelMax", "SoloTakeDownXPX",
    ]
    for key in needed:
        if key not in data["Tuning"]:
            problems.append(f"Tuning is missing '{key}' (the game reads it by name)")
    tuning = data["Tuning"]
    if tuning.get("BreakLevelStep", 1) <= 0:
        problems.append("Tuning Break level step must be above 0")
    if not 0 < tuning.get("CoilArcFalloff", 0.8) <= 1:
        problems.append("Tuning Coil arc falloff must be above 0 and at most 1")
    if tuning.get("PowerGridEvery", 1) <= 0 or tuning.get("JudgementBoltEvery", 1) <= 0:
        problems.append("Tuning Power Grid every and Judgement Bolt every must be above 0")
    if min(tuning.get("FalconSpeed", 1), tuning.get("EagleDiveX", 1), tuning.get("FalconBellsMark", 1)) <= 0:
        problems.append("Tuning Falcon speed, Eagle dive x and Falcon Bells mark must be above 0")
    if min(tuning.get("TowLineEvery", 1), tuning.get("TowLinePull", 1), tuning.get("BoltWidth", 1)) <= 0:
        problems.append("Tuning Tow Line every, Tow Line pull and Bolt width must be above 0")
    if min(tuning.get("EruptionEvery", 1), tuning.get("TarSinkSeconds", 1), tuning.get("TarTracksLength", 1), tuning.get("TarTracksSeconds", 1)) <= 0:
        problems.append("Tuning Eruption every, Tar sink seconds, Tar Tracks length and Tar Tracks seconds must be above 0")
    if tuning.get("EruptionSizes", 1) < 1 or tuning.get("EruptionSizes", 1) != int(tuning.get("EruptionSizes", 1)):
        problems.append("Tuning Eruption sizes must be a whole number >= 1")
    if tuning.get("PowerGridCoilCap", 1) < 1:
        problems.append("Tuning Power Grid coil cap must be 1 or more")
    if tuning.get("MaxSizeBreaks", 1) < 1:
        problems.append("Tuning Max size breaks must be 1 or more (1 turns pierce-through off)")
    # Player level (PLAN T55, DECISIONS #120, #124): every level costs something, costs
    # never fall, and the per-level cap is reachable from the base.
    if tuning.get("PlayerXPBase", 1) <= 0:
        problems.append("Tuning Player XP base must be above 0")
    if tuning.get("PlayerXPStep", 0) < 0:
        problems.append("Tuning Player XP step can't be negative (levels never get cheaper)")
    if tuning.get("PlayerXPPerLevelMax", 1) < tuning.get("PlayerXPBase", 1):
        problems.append("Tuning Player XP per level max must be at least Player XP base")
    if tuning.get("SoloTakeDownXPX", 1) < 0:
        problems.append("Tuning Solo take-down XP x can't be negative (1 = off)")

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
    # Clear XP rises with difficulty (PLAN T55): a harder clear never earns less.
    previous = None
    for key in data.get("DifficultyOrder", []):
        d = data["Difficulties"][key]
        xp = d["clearXp"]
        if not isinstance(xp, (int, float)) or xp < 0:
            problems.append(f"Difficulty {d['display']}: Clear XP must be a number, 0 or more")
        elif previous is not None and xp <= previous[1]:
            problems.append(f"Difficulty {d['display']}: Clear XP ({xp}) must be above {previous[0]}'s ({previous[1]})")
        else:
            previous = (d["display"], xp)
    notes.append("clear XP: " + ", ".join(f"{d['display']} {d['clearXp']}" for d in data["Difficulties"].values()))
    notes.append("difficulties: " + ", ".join(d["display"] for d in data["Difficulties"].values()))
    notes.append("starting cash: " + ", ".join(f"{d['display']} {d['startingCash']}" for d in data["Difficulties"].values()))

    best_tower = 0.0
    best_by_tower = {}  # display -> that tower kind's best maxed path, unlevelled
    for t in data["Towers"].values():
        base = t["baseDamage"] * t["baseRate"] * t["baseTargets"]
        for p in t["paths"]:
            if p["focus"] == "economy":
                continue
            for top in top_rows(p):  # every T5 pick pair
                dps = base * top["damageMult"] * top["rateMult"] * top["targetsMult"]
                best_tower = max(best_tower, dps)
                best_by_tower[t["display"]] = max(best_by_tower.get(t["display"], 0.0), dps)
    def hero_peak_dps(h):
        best = 0.0
        for t in (row for p in h["paths"] for row in top_rows(p)):  # every T6 after each T5 pick pair
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
    validate_cosmetics(data, problems, notes)
    validate_battle(data, problems, notes)
    validate_pace(data, problems, notes)
    validate_options(data, problems, notes)

    return problems, notes


RAIDER_COLUMNS = ("raiderSlowPercent", "raiderSlowSeconds", "raiderDamage")
RAIDER_SLOW_MAX, RAIDER_SLOW_SECONDS_MAX = 30, 3  # DECISIONS #284 rule 3: slows <= 30 %, <= 3 s


def raider_problems(towers):
    """At most one Raider option (`PvP effect`) per tower (DECISIONS #284 rule 5); the Raider
    sting columns only on a build whose T4 or T5 pick is that Raider option, and its slow
    within #284's limits (PLAN 9d, #294).

    >>> t = {"paths": [{"id": "P", "t4": {"A": {}, "B": {"pvpEffect": True}}, "t5": {"AA": {}, "BC": {"pvpEffect": True}}}]}
    >>> raider_problems({"X": {"display": "Demo", **t}})
    ['Tower Upgrades Demo: 2 Raider options (P 4B, P 5C); at most one per tower (DECISIONS #284)']
    >>> raider_problems({"X": {"display": "Demo", "paths": [{"id": "P", "t4": {"B": {"pvpEffect": True}}, "t5": {}}]}})
    []
    >>> sting = {"pvpEffect": True, "raiderSlowPercent": 35, "raiderSlowSeconds": 2}
    >>> raider_problems({"X": {"display": "Demo", "paths": [{"id": "P", "t4": {"C": sting}, "t5": {"CA": {**sting, "pvpEffect": None}}}]}})
    ['Tower Upgrades Demo P 4C: Raider slow 35 % is over 30 % (DECISIONS #284)', 'Tower Upgrades Demo P 5CA: Raider slow 35 % is over 30 % (DECISIONS #284)']
    >>> raider_problems({"X": {"display": "Demo", "paths": [{"id": "P", "t4": {"B": {"raiderDamage": 5}}, "t5": {}}]}})
    ['Tower Upgrades Demo P 4B: Raider sting columns on a build without a Raider option (PvP effect, DECISIONS #284)']
    """
    out = []
    for t in towers.values():
        found = []
        for path in t["paths"]:
            found += [f"{path['id']} 4{o}" for o, row in path["t4"].items() if row.get("pvpEffect")]
            found += sorted({f"{path['id']} 5{k[1]}" for k, row in path["t5"].items() if row.get("pvpEffect")})
        if len(found) > 1:
            out.append(f"Tower Upgrades {t['display']}: {len(found)} Raider options ({', '.join(found)}); at most one per tower (DECISIONS #284)")
        for path in t["paths"]:
            builds = [(str(i), row, False) for i, row in enumerate(path.get("tiers", []), start=1)]
            builds += [(f"4{o}", row, bool(row.get("pvpEffect"))) for o, row in path["t4"].items()]
            builds += [(f"5{k}", row, bool(row.get("pvpEffect") or path["t4"].get(k[0], {}).get("pvpEffect")))
                       for k, row in path["t5"].items()]
            for label, row, raider in builds:
                where = f"Tower Upgrades {t['display']} {path['id']} {label}"
                if any(row.get(f, 0) for f in RAIDER_COLUMNS) and not raider:
                    out.append(f"{where}: Raider sting columns on a build without a Raider option (PvP effect, DECISIONS #284)")
                if row.get("raiderSlowPercent", 0) > RAIDER_SLOW_MAX:
                    out.append(f"{where}: Raider slow {fmt_num(row['raiderSlowPercent'])} % is over {RAIDER_SLOW_MAX} % (DECISIONS #284)")
                if row.get("raiderSlowSeconds", 0) > RAIDER_SLOW_SECONDS_MAX:
                    out.append(f"{where}: Raider slow {fmt_num(row['raiderSlowSeconds'])} s is over {RAIDER_SLOW_SECONDS_MAX} s (DECISIONS #284)")
    return out


def fmt_num(x):
    return f"{x:g}"


def validate_options(data, problems, notes):
    """The A/B/C option bars (PLAN T113, DECISIONS #280, #284), enforced on every slot that has
    B or C, and one Raider option per tower: tools/value.py --options computes them (imported
    here, as it imports this module)."""
    import value  # noqa: E402 (tools/ is on the path: this file's own folder)
    enforced = value.option_problems(data)
    problems += enforced
    slots = sum(1 for t in [*data["Towers"].values(), *data["Heroes"].values()] for p in t["paths"]
                for counts in ([len(p["t4"])], [len({k[1] for k in p["t5"] if k[0] == o4}) for o4 in p["t4"]]) for n in counts if n > 1)
    notes.append(f"A/B/C option bars (value.py --options): {slots} slot(s) with a choice, {len(enforced)} problem(s)")


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
            # Player XP for clearing the track (PLAN T55, DECISIONS #119): added at match
            # end on a clear only, toward the saved player level (Shared/PlayerLevel).
            "clearXp": num(v(ws, r, 14), 0),
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
    if "Cosmetics" not in wb.sheetnames:
        sys.exit("The spreadsheet has no 'Cosmetics' sheet (PLAN round 4 T57)")
    if "Arenas" not in wb.sheetnames:
        sys.exit("The spreadsheet has no 'Arenas' sheet (PLAN phase 7 T73)")

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
        "Cosmetics": read_cosmetics(wb["Cosmetics"]),
        "Arenas": read_arenas(wb["Arenas"]),
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
