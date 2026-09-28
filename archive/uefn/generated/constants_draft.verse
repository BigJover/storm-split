# ============================================================
# GENERATED FILE — DO NOT EDIT
# Source: Storm-Split-Balance.xlsx
# Regenerate: python3 tools/export_constants.py
#
# WARNING: This is a DRAFT. The Verse syntax below has NOT been
# verified against a compiler. Check every construct against
# dev.epicgames.com before relying on it. See ARCHITECTURE.md.
# ============================================================

StormSplitConstants<public> := module:

    # --- Tuning levers ---
    StartingCash<public>:int = 650
    StartingLives<public>:int = 40
    CashPerEffectiveHp<public>:float = 0.43
    RoundBonusBase<public>:int = 60
    RoundBonusPerRound<public>:int = 1
    TierCostGrowth<public>:float = 2.3
    TierDamageGrowth<public>:float = 1.9
    SellRefund<public>:float = 0.7
    GlobalHpScalar<public>:int = 1
    RoundHpRamp<public>:float = 1.052
    MaxConcurrentEnemies<public>:int = 130
    GlobalSpeedScalar<public>:int = 1
    WeaponTier1Cost<public>:int = 300
    WeaponCostGrowth<public>:float = 2.35
    WeaponDamageGrowth<public>:float = 1.35
    CorePayoutBase<public>:int = 5
    CorePayoutPerRound<public>:float = 1.5
    MasteryCostBase<public>:int = 25
    MasteryCostGrowth<public>:float = 1.18
    AssumedSpendOnTowers<public>:float = 0.75
    ExpectedEfficiency<public>:float = 0.6
    RoundsPerTier<public>:int = 8

    # --- Enemy ladder ---
    # Id, BaseHP, SpeedMult, SplitsInto, SplitCount, CashValue, Flying
    # HUSK    HP=1      speed=1     splits=-       x0  EHP=1       cash=0      flying=False
    # BRUTE   HP=1      speed=1.2   splits=HUSK    x2  EHP=3       cash=1      flying=False
    # SHIELD  HP=2      speed=1     splits=BRUTE   x2  EHP=8       cash=3      flying=False
    # ARMOR   HP=3      speed=0.8   splits=SHIELD  x2  EHP=19      cash=8      flying=False
    # STORM   HP=4      speed=1.4   splits=ARMOR   x3  EHP=61      cash=26     flying=False
    # LLAMA   HP=4      speed=0.9   splits=SHIELD  x2  EHP=20      cash=9      flying=True
    # ZEP     HP=200    speed=0.5   splits=LLAMA   x4  EHP=280     cash=120    flying=True
    # BARGE   HP=700    speed=0.4   splits=ZEP     x4  EHP=1820    cash=783    flying=True

    # --- Round table (40 rounds) ---
    # R1  gap=1.19  hp=1      n=24   EHP=38      | HUSK:17 BRUTE:7
    # R2  gap=1.17  hp=1.052  n=28   EHP=46      | HUSK:20 BRUTE:8
    # R3  gap=1.16  hp=1.107  n=32   EHP=55      | HUSK:23 BRUTE:9
    # R4  gap=1.14  hp=1.164  n=36   EHP=65      | HUSK:26 BRUTE:10
    # R5  gap=1.13  hp=1.225  n=40   EHP=76      | HUSK:29 BRUTE:11
    # R6  gap=1.12  hp=1.288  n=44   EHP=88      | HUSK:32 BRUTE:12
    # R7  gap=1.1   hp=1.355  n=48   EHP=100     | HUSK:35 BRUTE:13
    # R8  gap=1.09  hp=1.426  n=52   EHP=117     | HUSK:37 BRUTE:15
    # R9  gap=1.07  hp=1.5    n=56   EHP=132     | HUSK:40 BRUTE:16
    # R10 gap=1.06  hp=1.578  n=60   EHP=148     | HUSK:43 BRUTE:17
    # R11 gap=1.05  hp=1.66   n=64   EHP=742     | HUSK:19 BRUTE:16 SHIELD:16 ARMOR:8 LLAMA:5
    # R12 gap=1.03  hp=1.747  n=67   EHP=802     | HUSK:20 BRUTE:17 SHIELD:17 ARMOR:8 LLAMA:5
    # R13 gap=1.02  hp=1.837  n=73   EHP=939     | HUSK:22 BRUTE:18 SHIELD:18 ARMOR:9 LLAMA:6
    # R14 gap=1     hp=1.933  n=76   EHP=1011    | HUSK:23 BRUTE:19 SHIELD:19 ARMOR:9 LLAMA:6
    # R15 gap=0.99  hp=2.033  n=80   EHP=1126    | HUSK:24 BRUTE:20 SHIELD:20 ARMOR:10 LLAMA:6
    # R16 gap=0.98  hp=2.139  n=84   EHP=1253    | HUSK:25 BRUTE:21 SHIELD:21 ARMOR:10 LLAMA:7
    # R17 gap=0.96  hp=2.25   n=88   EHP=1388    | HUSK:26 BRUTE:22 SHIELD:22 ARMOR:11 LLAMA:7
    # R18 gap=0.95  hp=2.367  n=92   EHP=1491    | HUSK:28 BRUTE:23 SHIELD:23 ARMOR:11 LLAMA:7
    # R19 gap=0.93  hp=2.49   n=97   EHP=1696    | HUSK:29 BRUTE:24 SHIELD:24 ARMOR:12 LLAMA:8
    # R20 gap=0.92  hp=2.62   n=100  EHP=1816    | HUSK:30 BRUTE:25 SHIELD:25 ARMOR:12 LLAMA:8
    # R21 gap=0.91  hp=2.756  n=104  EHP=4330    | HUSK:17 BRUTE:21 SHIELD:25 ARMOR:21 STORM:12 LLAMA:8
    # R22 gap=0.89  hp=2.9    n=109  EHP=4878    | HUSK:17 BRUTE:22 SHIELD:26 ARMOR:22 STORM:13 LLAMA:9
    # R23 gap=0.88  hp=3.05   n=111  EHP=5158    | HUSK:18 BRUTE:22 SHIELD:27 ARMOR:22 STORM:13 LLAMA:9
    # R24 gap=0.86  hp=3.209  n=116  EHP=5722    | HUSK:19 BRUTE:23 SHIELD:28 ARMOR:23 STORM:14 LLAMA:9
    # R25 gap=0.85  hp=3.376  n=120  EHP=6188    | HUSK:19 BRUTE:24 SHIELD:29 ARMOR:24 STORM:14 LLAMA:10
    # R26 gap=0.84  hp=3.551  n=125  EHP=6836    | HUSK:20 BRUTE:25 SHIELD:30 ARMOR:25 STORM:15 LLAMA:10
    # R27 gap=0.82  hp=3.736  n=128  EHP=7304    | HUSK:20 BRUTE:26 SHIELD:31 ARMOR:26 STORM:15 LLAMA:10
    # R28 gap=0.81  hp=3.93   n=130  EHP=7927    | HUSK:21 BRUTE:26 SHIELD:31 ARMOR:26 STORM:16 LLAMA:10
    # R29 gap=0.79  hp=4.135  n=130  EHP=8340    | HUSK:21 BRUTE:26 SHIELD:31 ARMOR:26 STORM:16 LLAMA:10
    # R30 gap=0.78  hp=4.35   n=130  EHP=8774    | HUSK:21 BRUTE:26 SHIELD:31 ARMOR:26 STORM:16 LLAMA:10
    # R31 gap=0.77  hp=4.576  n=130  EHP=24418   | BRUTE:16 SHIELD:26 ARMOR:31 STORM:31 LLAMA:18 ZEP:8
    # R32 gap=0.75  hp=4.814  n=130  EHP=25688   | BRUTE:16 SHIELD:26 ARMOR:31 STORM:31 LLAMA:18 ZEP:8
    # R33 gap=0.74  hp=5.064  n=130  EHP=27022   | BRUTE:16 SHIELD:26 ARMOR:31 STORM:31 LLAMA:18 ZEP:8
    # R34 gap=0.72  hp=5.327  n=130  EHP=28425   | BRUTE:16 SHIELD:26 ARMOR:31 STORM:31 LLAMA:18 ZEP:8
    # R35 gap=0.71  hp=5.604  n=130  EHP=29903   | BRUTE:16 SHIELD:26 ARMOR:31 STORM:31 LLAMA:18 ZEP:8
    # R36 gap=0.7   hp=5.896  n=130  EHP=31461   | BRUTE:16 SHIELD:26 ARMOR:31 STORM:31 LLAMA:18 ZEP:8
    # R37 gap=0.68  hp=6.202  n=130  EHP=33094   | BRUTE:16 SHIELD:26 ARMOR:31 STORM:31 LLAMA:18 ZEP:8
    # R38 gap=0.67  hp=6.525  n=130  EHP=34817   | BRUTE:16 SHIELD:26 ARMOR:31 STORM:31 LLAMA:18 ZEP:8
    # R39 gap=0.65  hp=6.864  n=130  EHP=36626   | BRUTE:16 SHIELD:26 ARMOR:31 STORM:31 LLAMA:18 ZEP:8
    # R40 gap=0.64  hp=7.221  n=131  EHP=51673   | BRUTE:16 SHIELD:26 ARMOR:31 STORM:31 LLAMA:18 ZEP:8 BARGE:1

    # Full structured data is in generated/constants.json.
    # Translate it into real Verse arrays once the syntax is confirmed.
