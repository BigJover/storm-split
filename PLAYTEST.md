# PLAYTEST — Studio playtest by the Tester (agent)

- **Date:** 2026-10-06
- **Commit tested:** `eccc704` (main). Studio was synced: `ReplicatedStorage.Shared.TarPit`, `PlayerLevel`, `HeroXp`, `PanelRules` and `Bounties` exist, and the byte lengths of `TarPit`, `Config`, `PlayerLevel`, `Server.Towers` and `Client.Profile` in Studio match the repo exactly.
- **How:** I drove Studio's MCP through `tools/studio/mcp.py`. The viewport was 707×620, so the home column's UIScale was about 0.83. Three solo matches: Easy (lost on round 3), Easy (played to round 32, then I sold the towers to lose), and Hard with no towers (lost on round 1). A fourth Easy match tested the base new towers. Play mode was stopped at the end and Studio is back in **Edit** mode. I changed nothing in Edit.
- **Screenshots:** `~/.claude/jobs/2a8d6f9c/tmp/tester/*.png` (named below).
- **Test conveniences I used (disclosed):**
  - The Studio keys K, J and L.
  - `character_navigation` to walk the hunter.
  - Client `execute_luau` that **hid the Roblox chat window and chat input bar** (TextChatService configs). This was needed because Studio's CoreGui chat window sat over the Hunt Board's Day 1 tile and blocked the virtual click.
  - Read-only server/client Luau that sampled attributes, enemy models and effect parts.
  - Nothing faked any game result. `SaveStatus` was `offline` the whole session, so no DataStore was touched.

## Summary

| # | Area | Result | Evidence |
|---|---|---|---|
| 1 | Boot: Play → home screen, no script errors | PASS | Console has only the expected `[Progression]` no-DataStore line and the `[LevelBoard]` this-server line. `boot.png` |
| 2 | Host picks mode/track/difficulty → PLAY → Building → Start → round 1 | PASS | State Lobby→Building→Playing. Round 1 has 14 HUSK; `Round 1 cleared` is logged. `building.png`, `round1.png` |
| 3 | Dinos spawn and walk; towers place and fire; rounds clear | PASS | 31 rounds cleared on Easy (match 2). Cash rises from take-downs. |
| 4 | Console errors across ~45 min of play | PASS | No error or warning from our scripts in any phase (only Studio/Assistant `VirtualInput` noise). |
| 5 | No-trap: G, P, H, M open and close with key and X in the Lobby | PASS | Each panel opens with its key and closes with the same key and its X. Every X `AbsolutePosition`/`AbsoluteSize` is inside the viewport. |
| 6 | No-trap: B and U in Playing open/close with key and X; G, P, H, M do nothing in Playing; G does nothing in Building | PASS | Probe after each key; X clicked by instance path. |
| 7 | Hunt Board: home button toggles it; H/M make it give way; PLAY while open closes it | PASS | Board→closed→open, then H/M panel replaces it, and PLAY → Building with the board closed. |
| 8 | Hunt Board content: 7 Haul tiles, 3 daily + 3 weekly, both countdowns, Amber in header | PASS | `Day1..Day7`, `D_*`×3, `W_*`×3, "New daily bounties in 4h 58m", "New in 5d 4h", "0 Amber". `huntboard.png` |
| 9 | Claim Haul (+5), no double pay; swap a daily | PASS | `Cores` 0→5, home line "5 Amber", second click pays nothing. Busy Day → Compy Sweep, and the swap buttons go away at 0 left. `huntboard-after-swap.png` |
| 10 | Hunt Board Day 1 tile click with Studio chat visible | NOT TESTABLE BY AGENT | Studio's CoreGui chat window covers the tile (`VirtualInput… hits CoreGUI`). Jovan: check whether a real client's chat window covers Day 1. |
| 11 | Bounty progress → toast → Claim → BAGGED; Gear Check | NOT RUN | Ran out of budget; Sharpen Up should have advanced from my upgrades but wasn't checked in the Lobby. |
| 12 | Dino bites on towers | PASS | Mortar, Armory, Coil and Hospital HP fell during rounds 7–31 with no L presses, and several were trampled (`KO`). |
| 13 | Hunter HP: hits and the Skull Toss throw | PASS (partial) | HP 100→95 once (round ~20), and in the Hard match HP 86 with "Pachycephalosaurus · Skull Toss −5". The +25 per round and 0-HP behaviour weren't checked. |
| 14 | Trample + repair (L twice) | PASS | Coil 262→150→0 `KO`. Panel title reads "Trampled — repair it", the other paths say "Repair it first", and the Repair row costs 12215. Clicking it gives "Repaired for 12215", the cash drops and HP is 262/262. |
| 15 | Armory resist (15%) | PASS | L on a Coil inside the Armory's range took 112.5 instead of 131.25 (exactly 15% less). |
| 16 | Field Hospital heal (3 HP/s) | PASS | Ballista in Hospital range went 131→147 in about 5 s. A Coil out of range didn't heal. |
| 17 | Field Medic hero, Supply Camp | NOT RUN | Out of budget. Supply Camp unlocked but not built. |
| 18 | Mastery screen (Tracker to 15) | PASS | Row "Mastery 10 perk · Sticky Dart (owned)…", "Mastery 15 perk · Spare Dart (owned)…". `TextFits=true`, 341×81 inside 376×93. The note shows "Progress isn't saving right now." because saving is offline, which is by design. |
| 19 | U shows "Tracking Dart perks: Sticky Dart · Spare Dart" | PASS | Read from the hero panel. |
| 20 | Hero XP row in round 1 | PASS | "Lv 1", "0 / 500 XP", "+N bonus on round clear" (wording per DECISIONS #157). On clear XP goes 0→107 (100 + 7 pending) and pending returns to 0. Labels have TextSize 8 and TextBounds height 14–16 px at UIScale ~0.83. |
| 21 | Level banners and tower level line | PASS | Banner "Hunter level 3 — your shots hit 25% harder" after round 9, and "Tower level 3 — towers hit 10% harder" after round 10. The tower panel shows "Tower level 2 · +10% damage" after round 5 and has no line in Building before round 1. |
| 22 | Lose a round: no XP banked, next match level 1 / XP 0 | PASS | After the round-3 loss: `HeroXp=0`, `HeroLevel=1`, and the next match starts at Lv 1, 0 XP. |
| 23 | Solo loss pays 0 Amber; back to Lobby; Hunt Board still opens | PASS | "Match over (round 3, lost): +0 Amber each". G opens the board afterwards. |
| 24 | Home: PLAY 240 px, Hunt Board on its own row | PASS | PLAY is 198×46 at UIScale ~0.83 (240 before scaling). Hunt Board and Profile sit in a `HuntRow` above the action row. |
| 25 | Unlock the four new towers (J + M) | PASS | Storm Coil 300, Falcon 200, Tar Pit 250, Ballista 300 Amber, all "owned". |
| 26 | Tar Pit only on the track | PASS | A Tar Pit aimed at grass isn't placed ("Must go on the track"). On lane 3 it places for 450. |
| 27 | Place Coil (400), Falcon (400), Ballista (500) | PASS | Costs match T68 (final). |
| 28 | Falcon Roost and Tar Pit can't be damaged and have no repair | PASS | Panel row reads "Can't be damaged: dinos ignore it, no repair". HP 0/0, and both stayed untouched for 31 rounds while their neighbours were trampled. |
| 29 | All four new towers to tier 5 | PASS | Skewer, Power Grid, Eruption and Eagle of the Peak bought; titles read `5·0·0` / `0·5·0`. |
| 30 | New towers attack | PASS | In 25 s of round 4 (base towers): 10 pale-blue long effect parts at the Coil (arcs), 14 brown short parts at the Falcon (dives), 10 brown long parts (harpoons), 6 black parts at the Tar Pit. |
| 31 | Storm Coil chains (enemy to enemy); Power Grid with 1 vs 3 coils | NOT TESTABLE BY AGENT | No per-hit log. Arcs were seen but chain links couldn't be told apart from first hits, and 3 coils weren't built. |
| 32 | Tar Pit slows and sinks | PASS | At a lane-1 Tar Pit, mean speed in the pool was HUSK 11.0 vs 13.0 outside and BRUTE 13.3 vs 15.5 outside. 19 dinos vanished inside the pool radius in 40 s, with no other tower nearby. |
| 33 | Pierce-through: one hit drops more than 1 size (Skewer, Linebreaker, Eruption) | NOT TESTABLE BY AGENT | No console logging per hit, so I paired models replaced on shrink. 40 s at rounds 19–20 with Skewer showed only 1-size drops (LLAMA ×8), which is inconclusive because kills aren't counted. I couldn't buy Linebreaker (see F3). |
| 34 | Boss notched bar | PASS | Round 31 Triceratops (`ZEP`, 4 sizes) has `Root.PoolBar` with Back, Fill and Notch1–3. |
| 35 | Boss throw on a tower deals half, on the hunter full | NOT TESTABLE BY AGENT | The boss died before it threw. There's no START_ROUND change allowed and no damage log. |
| 36 | Hard starts at 850 | PASS | Hard Building: cash 850, fence 20. |
| 37 | Chaos lever values | NOT RUN | — |
| 38 | Hero path to tier 6 | PASS | Gunslinger 6/6 "maxed · Hot Swap". The panel fits (rows at y 266–516 in a 620 px viewport). |
| 39 | Wildfire Drum patch 4 studs | NOT RUN | Needs Brush Beater. |
| 40 | Mastery 6–9 perks in play | NOT RUN | The mastery rows list them ("Long Arms III: pick up … from 6 studs away") but their effects weren't measured. |
| 41 | Result screen "+N player XP" | PASS | Hard loss: "GAME OVER / The fence fell on round 1 (Hard) / No Amber (solo pays on a clear) / +0 player XP". `result-screen.png` |
| 42 | Player level persists to the next match in the session | PASS | `PlayerXp` 230 after match 1 → 4206 after match 2; Profile shows "Player level 7, 456 / 800". |
| 43 | Profile: P/X; Leaderboard says "This server" with the note | PASS | "This server · The world board goes live when the game is published. · #1 · 7 · Jover_428". `leaderboard.png` |
| 44 | Profile: equip a colour | NOT RUN | The "Fern Name" chip was scrolled out of view and I didn't retry. |
| 45 | Leaver gets no player XP (2nd client) | NOT TESTABLE BY AGENT | The tools drive one client. |
| 46 | HP bar hidden on the home screen | **FAIL** | F1 |
| 47 | Tower panel rows don't move under the cursor | **FAIL** | F2 |
| 48 | Upgrade clicks on a tower panel during Playing | **FAIL (tooling-suspect)** | F3 |
| 49 | Small windows (800×450, phone), text readability, feel of rounds 10–12/20–22/30–32, Chaos aim | NOT TESTABLE BY AGENT | Can't resize the viewport; feel is for Jovan. |

**Counts:** PASS 35 · FAIL 3 · NOT TESTABLE BY AGENT 6 · NOT RUN 6.

## Failures

### F1. Hunter HP bar stays visible on the home screen after a match — minor
- **Repro:**
  1. Play and start any match.
  2. Lose, or let the match end, and return to the Lobby.
- **Seen:** `PlayerGui.StormSplitHud.Health.Visible == true` with `State == "Lobby"`. The green "HP 100 / 100" bar peeks out from behind the "Choose hero (H)" card at the bottom left (`lobby-after-loss.png`). On the very first boot it is hidden, because no character has spawned yet.
- **Console:** nothing.
- **Suspect:** `src/client/Hud.client.luau`. `watchHumanoid()` (around line 474) sets `hpFrame.Visible = true`, and the state handler (around lines 218–231) never hides it in the Lobby.

### F2. Tower panel rows shift while you aim at them — minor (UX)
- **Repro:**
  1. Build a Longshot Perch next to a lane in round 15+ so dinos bite it.
  2. Open its panel and try to click "Full Metal Jacket".
- **Seen:** the "Repair — N" row appears or disappears as the tower takes bites or the Hospital heals it. Every row below it moves 54 px, so a click aimed at one path landed on the next one. Twice I bought **Steady Breath / Bolt Racking** (Spotter) when I meant **Full Metal Jacket** (Deadeye). A real player who clicks during a bite could buy the wrong path.
- **Screenshot:** `longshot-panel.png` (rows without Repair; earlier reads had Repair at y 289 and the paths at 343 and below).
- **Suspect:** `src/client/Shop.client.luau`, the manage-mode `render()` around lines 1300–1330. The Repair row is inserted conditionally above the path rows. Possible fixes: give Repair a fixed slot, or put it below the paths.

### F3. Upgrade clicks on a tower panel did nothing during Playing — major if it's real, likely tooling
- **Repro (agent):**
  1. In Playing, walk next to a tower and press E; the panel opens.
  2. Use `user_mouse_input` to click an affordable path row at its fresh `AbsolutePosition` centre.
- **Seen:** no purchase and no message, in 7 attempts on the Longshot Perch (rounds 16–19). In the same match, the Repair row (on the second try), Sell rows and the X button all worked, and every upgrade click in **Building** worked (20+ purchases). The hunter is in first person with `MouseBehavior = LockCenter` during Playing, so the virtual mouse may be fighting the mouse lock.
- **Console:** nothing.
- **Action:** Jovan, please check by hand that upgrade rows respond to clicks mid-round. If they do, close this as tooling.

## Notes for the Director / Jovan (not failures)
- A CoreGui band at screen y ≈ 135–140 (GUI y ≈ 77–82) swallowed agent clicks: the Start button centre and the top half of the Profile "Leaderboard" tab. Clicking lower on the same buttons worked. It's probably Studio's Assistant or Rojo overlay, but worth a glance on a real client.
- Range rings are drawn for every tower all through Playing (`match2-round1.png`, `coil-area.png`). Check that this is intended.
- The hunter-level banner says "+25%" at every level (e.g. "Hunter level 8 — your shots hit 25% harder"). This is per level (`Tuning.HeroDamagePerLevel`), so it's correct, but players may read it as the total.
- The status line "+1000 cash (K)" slightly overlaps the Co-op card on the home screen at 707 px wide (`boot.png`). It's a Studio-only button.
- Feel items for Jovan: whether rounds 11/21/31 are walls on Easy, the size of PLAY at small windows, how readable the XP row is (14–16 px tall at UIScale 0.83), Chaos aim, and whether a level-3 hunter at round 9 feels like a reward.

# Run 2 — 2026-10-07 (Tester, agent)

- **Code tested:** main at `565f285`. Sync check (read-only, Edit): `script_grep` finds `hpBarVisible` (Client.Hud, Shared.PanelRules) and `BattleFlow` (Shared.BattleFlow, Client.Hud). Studio source byte sizes equal the repo for PanelRules 4207, BattleFlow 8738, Hud 26351, Shop 61357, Main 21551, Towers 60162, Enemies 21592.
- **Start state:** the previous Tester left Studio in Play; I stopped it first and `get_studio_state` showed Edit.
- **Screenshots/work files:** `~/.claude/jobs/2a8d6f9c/tmp/tester4/`.
- **Test conveniences (disclosed):** Studio keys K/J/L, `character_navigation`, keyboard/mouse input, read-only client/server `execute_luau`, and the Studio-only Lobby remote calls for Part 4. Anything else is noted where used.

(Results are written part by part below.)

## Part 1 — F1–F3 re-test

| # | Area | Result | Evidence |
|---|---|---|---|
| R2-1 | F1: HP bar hidden on the home screen after a match | PASS | Easy match lost on round 3 (towers sold). In the Lobby: `StormSplitHud.Health.Visible=false` while `LocalPlayer.Character` still exists and `State=Lobby`. `f1-lobby.png` |
| R2-2 | F2: tower panel rows stay put while bitten / repaired | PASS | Longshot Perch panel, Building. Full HP: rows Repair y235, Full Metal Jacket 289, Steady Breath 343, Large Calibre 397, Sell 451. After L (HP 40/80) the Repair row reads "Repair — 53" and every row keeps the same y. Clicking Repair → "Repaired for 53", rows again unchanged. After upgrades (MaxHP 80→92→104) rows shift only 3–6 px (two-line descriptions), not 54 px. |
| R2-3 | F2: Repair row greyed "Repair · full HP" when healthy | PASS | Text "Repair · full HP", grey background (R 0.27) vs blue path rows; red-ish when needed. `f2-full.png` |
| R2-4 | F3: upgrade clicks register mid-round | PASS | Playing, round 1, first person (MouseBehavior LockCenter), panel opened with E. Full Metal Jacket 2500→1696 (title 1·0·0), Steady Breath 1696→892 (1·1·0); K ×2 then Through-and-Through 2901→1051 (2·1·0). Every affordable click bought the right path (3/3). A click on Bolt Racking (1851) with 1051 cash correctly did nothing. |

Note (not a failure): in Building the hotbar buttons "Choose hero (H)" and "Unlocks & Mastery (M)" show through the translucent tower panel behind the HP/Repair rows (`f2-full.png`). Clicks went to the panel rows, so it's cosmetic.
Tooling note for future runs: `user_mouse_input` x/y are GUI `AbsolutePosition` coordinates (the tool adds the 58 px top-bar inset itself); world points use `Camera:WorldToScreenPoint`. Placement requires the hunter to stand near the spot ("Too far from you — walk closer").

## Part 2 — Run 1's NOT RUN items

Setup (disclosed): J ×15 for Amber (saving was already `offline`); unlocked Brush Beater, Field Medic, Supply Camp, Field Hospital, Storm Coil, Harpoon Ballista; Field Medic mastery 0→9 (25+30+35+41+48+57+67+80+94 Amber). **Scripted setup:** the hunter had no gun in hand in match 2 (the Lever-Action Carbine sat in the Backpack; the HUD shows no hotbar and VirtualInput refuses key `1` — "key is permanently bound to a CoreGUI core action"), so I equipped it once with client `Humanoid:EquipTool(backpackTool)` — what pressing 1 does. Without a gun, F does nothing (`useAbility` returns early).

| # | Area | Result | Evidence |
|---|---|---|---|
| R2-5 | Field Medic Triage Kit heal (with Patch Up, Triage 3) | PASS | Supply Camp L'd to 100/200; F → 150/200 (+50 = 40 × 1.25 Clean Bandages). Hunter was at 100/100, so the hunter half of the heal couldn't be seen. |
| R2-6 | Supply Camp round income | PASS | Easy, one Supply Camp (base). Cash watcher: +213 at the round-3 clear = round bonus 60+3 + 150 income. Round 2's clear gave +214 (212 + 2 take-downs). |
| R2-7 | Hero tier 6 purchase + effect (Field Medic **Rapid Response**) | PASS | Bought Triage Tent 1280, Second Wind 2560, Rapid Response 5120 (each "(-20%)", mastery discount). Panel "Triage · maxed · Rapid Response 6/6". `AbilityMaxCharges` 1→2, charges 2. Two F presses back to back healed the Camp 50→100→150, and charges went to 0 (cooldown ~55 s). |
| R2-8 | Bounty progress (Hunt Board G) | PASS (progress) | After match 2: "Gear Check · Use your ability 5 times · 3 / 5" (exactly my 3 Triage Kits) and "Deeper Trail · Reach round 25 · 4 / 25". Claim: see R2-10. |
| R2-9 | Profile (P) in the Lobby: equip a colour | PASS | After match 2 Player level 2 (PlayerXp 680). Name colour chips "None" / "Fern Name"; clicking Fern Name moves the highlight to it and the server sets `Equip_nameColour=NAME_FERN`. `profile-fern2.png`. The chips sit at the very bottom edge of the scroll area at first (half clipped) — I had to scroll to click them. |
| R2-10 | Bounty claim → BAGGED, no double pay | PASS | 4th and 5th Triage Kits in matches 3–4 → "Gear Check 5 / 5 · Claim". Claim: Amber 98→108 and the tile reads "BAGGED"; a second click on the same spot pays nothing (108). `bounty-claimed.png`. The in-match completion toast wasn't watched. |
| R2-11 | Chaos: towers ×0.6, hero ×1.5 (read-only) | PASS | Chaos match: `Difficulty=CHAOS`, `Lives=10`, cash 450. Server read-only: `TowerStats.damageScale(1, Difficulties.CHAOS)=0.6`, `HeroStats.damageScale(1, CHAOS)=1.5` (Easy: 1 / 1; level 3: 0.726 / 2.34). Main passes the chosen row to `Towers.setLevel(level, difficulty())` and the Hero `difficulty` hook. No damage was measured in play. |
| R2-12 | Mastery 6–9 small perks (Field Medic mastery 9) | PASS (Handyman I) · NOT TESTABLE (others) | **Handyman I:** Supply Camp (1000 spent) at 100/200 → "Repair — 143" = 0.3 × 1000 × 0.5 × 0.95 (150 without the perk). **Back in Action I:** died at t=5.1 s, back at 100 HP at t=8.1 s, consistent with 3 s × 0.9 + character load, not precise enough to call. **First Aid I** (+5 round heal) and **Long Arms I** (pick-up reach): not observed. The hunter was never hurt on Easy before a clear, and no chest was in reach. |

Note (not a failure): the Sell row's deduction for damage ("Sell for 550 (−150 for damage)") uses the repair price *without* Handyman (150, while Repair shows 143). The server (`Server/Shop.luau:281`) and the client agree, so it looks deliberate. Mention it only if the perk is meant to cover it.

## Part 3 — Probes

Method (read-only server Luau): **pierce** — every Heartbeat I tracked the dino models. A shrink rebuilds the model (`Enemies.dress`) at the same spot, so I paired a vanished model with a new same-species model within 4 studs and turned their root-part widths into sizes with `DinoLook.scale(size, sizes)`. **Coil** — a listener on `StormSplitMap.Effects` counts the arc-coloured (170,210,255) tracers created in the same frame (one per chain link, `fireChain`), and reads the radius of Power Grid's discs (`Effects.disc`, Size.Y / 2).

| # | Probe | Result | Evidence |
|---|---|---|---|
| R2-13 | Pierce-through: Longshot **Big Bore T2 (Bone Breaker)** drops 2 sizes per hit | PASS | Rounds 8–9 (Easy), with Bone Breaker Longshot 0·0·2 as the only attacking tower (mortars sold, hunter not firing): **5 of 5** shrinks were 2-size drops (SHIELD 3→1 ×4, LLAMA 3→1 ×1), none were 1-size. Round 7 with two 1-break Mortars added: 26 one-size drops and 1 two-size drop (SHIELD 3→1). Linebreaker and Skewer weren't built. |
| R2-14 | Power Grid range: 1 coil vs 3 coils | PASS | Coil 5·0·0 (Power Grid) alone: 4 grid pulses in 20 s (every 6 s), disc radius **14.0** (= range 14 × 1.0). After 2 more base coils: each pulse draws 3 discs, all radius **18.2** (= 14 × 1.3), and 3 grid strike tracers appeared. Damage ×0.75 / ×1.25 is from `StormCoil.grid(1)` / `grid(3)` (read-only), not measured. |
| R2-15 | Storm Coil chain target counts | PASS | Easy rounds 1–3 (sparse, one dino at a time): only 1-target strikes (25, 19 and 16 strikes), as expected with no second dino in reach. **Chaos round 1** (count ×2.5), coil 3·0·0 (Fork Lightning: arcs 6, forks 2, reach 15 from `TowerStats.compute`): in 15 s the strikes hit 1, 2 or 3 dinos (1×5, 2×6, 3×4), so arcs do hop from dino to dino. Per-hop damage falloff wasn't measured. |

Tooling notes: (1) tower prompts (E) only opened when the tower was on screen; the first-person camera faces −z, so I had to stand on the +z side of a tower. (2) Execute_luau output cut mid-character (e.g. `○` in hero tier ladders) hangs the MCP call; strip non-ASCII before truncating.

## Part 4 — Phase 7 solo battle with stand-ins

Setup (disclosed): from the client DataModel, `Remotes.Lobby:FireServer("standins", true)`, `("mode", "TEAM")`, `("sides", 2)`, then Easy on the home screen and `("play")`.
**Tooling trap (not a game bug):** my `("play")` call waited 4 s inside `execute_luau`, so it straddled Lobby→Building. Studio's Assistant then logged "The execute_luau changed camera type. Resetting from Custom back to Scriptable" and put the camera back into the home screen's Scriptable mode. `Home.client.luau` had already cleared `orbiting`, so the camera stayed frozen at the spawn point (−100, 4.7, 0) for the rest of that match, even after a respawn (`battle-cam.png`). Future runs: fire `("play")` without waiting in the same call.

| # | Area | Result | Evidence |
|---|---|---|---|
| R2-16 | Camp Clash starts with 2 sides | PASS | Console "Camp Clash on Easy: 2 sides, 1 player(s), 1 stand-in(s)". Attributes `Mode=TEAM`, `Sides=2`, `Camp=Red Camp`, `Camp2=Blue Camp`, `Lives/Lives2=40`, `Cash2=450`. Map has `BuildArea2`, `Lanes2`, `Spawn2`, `Exit2`, `Crossing1`. Zones: side 1 x −110…90, side 2 x 130…330 (offset 240). The stand-in built Hunting Blind, Longshot and Mortar on side 2. HUD reads "Red Camp · Round 1 · Easy · …". |
| R2-17 | Rounds advance together | PASS | "Round N over \| Camp Clash, 2 sides (2 alive) \| Fences 40 / 40" for rounds 1–5, one line per round for both sides. |
| R2-18 | Your towers hit only your side's dinos | PASS | 20 s tracer probe (round ~6): 20 tracers from my Longshot (global range) and Mortar all ended on side 1 (x < 100); 41 from the stand-in's towers all ended on side 2. No tracer crossed. |
| R2-19 | Mastery First Aid I (+5 round heal), found here | PASS | Field Medic mastery 9, hunter at 44 HP at the round-5 clear → 74 (+30 = 25 + 5). (Moves R2-12's First Aid to PASS.) |
| R2-20 | Building only on your side | PASS | Placing a Hunting Blind on the crossing strip (110, −30) and on Blue's side (136, −30) both show "That's another camp's zone. Build inside your own camp." and nothing is placed. On my side (−100…−88, −32) Mortars and a Longshot placed normally. |
| R2-21 | Enemy tower panel is read-only | PASS | E at Blue's Hunting Blind: panel "Hunting Blind · 0·0·0" with only "Blue Camp's tower" and "HP 100 / 100". No upgrade, repair or sell rows. `enemy-panel.png` (the "Upgrade" prompt label is known and queued) |
| R2-22 | Shoot an enemy tower (×0.35) and knock it out | PASS (×0.35) · PARTIAL (knock-out) | Field Medic carbine (damage 1, hunter level 1): 0.35 per hit on the Hunting Blind (100→99.65→99.30…). At hunter level 2: 0.4375 per hit (1.25 × 0.35) on Blue's Longshot. After one L (80→40), my shots took it 40→8.5. Then I died on Blue's side and respawned home without the gun, and when I came back it was already `KO=true` (probably dino bites). I never saw a hunter's shot finish a tower: at 0.35–0.44 per shot, 100 HP takes about 230–285 shots. **Scripted setup:** the gun was equipped with `EquipTool`, and the Studio L key was used (it knocked the Hunting Blind out with two presses). |
| R2-23 | Side out at Fence 0 shows "<Camp>'s Fence is down! They're out." | PASS | HUD banner "Blue Camp's Fence is down! They're out." and console lines for both camps across matches. `clash-result2.png` |
| R2-24 | Results appear; Camp Clash display name | PASS | "VICTORY · home in 58s" and the card "Camp Clash — Your camp wins the hunt! / Red Camp / Place 1 · 521 Bones". Console "Camp Clash over on round 10: …". Earlier matches: my undefended camp fell on round 2, giving "1. Blue Camp (0 Bones) \| 2. Red Camp (0 Bones)". Both camps fell in round 11, giving "1. Red Camp (628) \| 2. Blue Camp (0)", which follows the most-Bones rule for a shared fall. `clash-result2.png` |
| R2-25 | Console during Camp Clash | PASS | No script errors or warnings from our scripts across 3 Camp Clash matches (only Assistant VirtualInput / camera-reset lines). |

Notes (not failures): on Easy, both camps' fences went 40 → 0 inside round 11 of one Camp Clash, the round-11 wall (the open "leak cost" issue). The banner "Blue Camp's Fence is down! They're out." wraps "out." onto a second line in a box that's slightly too narrow at 707 px (`clash-result2.png`).
| R2-26 | Bone Rush (ROYALE, 4 sides): start, display name | PASS | `("mode","ROYALE")`, `("sides",4)`, `("play")` → "Bone Rush on Easy: 4 sides, 1 player(s), 3 stand-in(s)". `SideGrid=true`, camps "Jover_428's Camp" and "Stand-in 2/3/4's Camp", Lives/Cash 1–4 = 40/450. HUD "Jover_428's Camp · Round 6 · Easy · …". |
| R2-27 | Bone Rush end condition and placements | PASS | All three stand-ins fell in round 12 (fences 21→0), and the match ended at once with one camp standing: "VICTORY · home in …", card "Bone Rush — Top Hunter! Jover_428's Camp · Place 1 · 537 Bones", plus the three "Stand-in N's Camp's Fence is down! They're out." banners. Console: "Bone Rush over on round 12: 1. Jover_428's Camp (537) \| 2. Stand-in 4's Camp (0) \| 3. Stand-in 2's Camp (0) \| 4. Stand-in 3's Camp (0)". With all on 0 Bones, Stand-in 4 placed above 2 and 3, so it fell in a later elimination step. 2 above 3 fits a shared step (outAt equal, so fence then seat order decide). The console prints the falls but not the steps, so I can't confirm the 2/3 order exactly. `rush-result.png` |
| R2-28 | Console during Bone Rush | PASS | No errors or warnings from our scripts. |

## Run 2 summary

| # | Area | Result |
|---|---|---|
| R2-1…4 | F1, F2 (rows fixed + greyed Repair), F3 re-tests | PASS ×4 |
| R2-5…12 | Triage Kit, Supply Camp income, hero tier 6 (Rapid Response), bounty progress, Profile colour, bounty claim, Chaos ×0.6/×1.5, mastery perks | PASS ×8 (R2-12: Handyman I PASS; Long Arms I NOT TESTABLE; Back in Action I inconclusive) |
| R2-13…15 | Probes: pierce-through (Bone Breaker), Power Grid 1 vs 3 coils, coil chain counts | PASS ×3 |
| R2-16…28 | Camp Clash and Bone Rush with stand-ins | PASS ×12, plus R2-22 knock-out by a hunter's shots PARTIAL |
| R2-29 | Round counts as cleared when its last dino breaks the fence | **FAIL** (F4) |
| — | Wildfire Drum (Brush Beater tier 6); Linebreaker / Skewer pierce | NOT RUN (tier 6 was covered by Rapid Response; pierce was covered by Bone Breaker) |
| — | Long Arms I pick-up reach | NOT TESTABLE BY AGENT (no chest or med kit was in reach to measure) |

**Counts:** PASS 27 · FAIL 1 · PARTIAL 1 (R2-22 knock-out) · NOT TESTABLE 1 · NOT RUN 2.

## Run 2 failures

### F4. A round counts as "cleared" when its last dino breaks the fence — minor (major in one edge case)
- **Repro:**
  1. Solo Co-op on Easy with too little defence, so the fence runs out mid-round.
  2. Let the last dino of a round be the one that takes the fence to 0.
- **Seen (match 2):** the console printed `Round 4 cleared | Easy, 1 player(s) | lives 0 | cash 6489 …`, then `GAME OVER on round 4`. Matches that fell earlier in a round print no "cleared" line (e.g. Chaos: `GAME OVER on round 1` alone).
- **Why:** `Server/Waves.luau` (`Waves.run`, around lines 122–133) waits until `Enemies.remaining(side) == 0`, checking `isOver()` only *inside* the wait loop. When the last dino leaks and takes the fence to 0, `remaining` hits 0 and the loop ends before `isOver` is checked again. `onRoundEnd` then runs: Main pays the round bonus and Supply Camp income, heals hunters, sets `RoundsCleared`, banks hero XP (`Hero.roundCleared`), and logs "cleared". **Edge case:** on the last round of the table, the same path leaves the `for` loop and `return true`, so a run whose final leak breaks the fence would be scored as **VICTORY** with the clear payout. I reasoned this from the code; I didn't play round 40.
- **Console:** quoted above. No errors.
- **Suggested fix:** check `options.isOver()` after the wait loop, before `onRoundEnd`.
- **Screenshot:** none (console only).

## Studio state at the end
- Play mode stopped. `get_studio_state`: **Current Studio Mode: Edit**, DataModels: Edit. Nothing was changed in Edit, nothing was published, and `SaveStatus` stayed `offline` all session (J was used, so saving was off anyway).
- A full console scan at the end found no error or warning lines from our scripts, only Studio Assistant VirtualInput / camera-reset noise.
- Screenshots in `~/.claude/jobs/2a8d6f9c/tmp/tester4/`: `f1-lobby.png`, `f2-full.png`, `profile-fern2.png`, `bounty-claimed.png`, `battle-cam.png`, `enemy-panel.png`, `clash-result2.png`, `rush-result.png`.

# Run 3 — 2026-10-08 (Tester, agent) — PLAN T86 solo script

- **Code tested:** main at `207513e`. Sync check (read-only, Edit): `script_grep` finds "Amber Hoard" (Client.Hud, Shared.PanelRules, Shared.HomeLayout, Server.Progression), "RoundFlow" (Shared.RoundFlow, Server.Waves) and "Inspect" (Client.Shop, Shared.PanelRules).
- **Start state:** Studio in Edit mode.
- **Screenshots/work files:** `~/.claude/jobs/2a8d6f9c/tmp/tester5/`.
- **Test conveniences (disclosed):** Studio keys K/J/L (J pressed first in each session so nothing saves), `character_navigation`, keyboard/mouse input, read-only client/server `execute_luau`, and the Studio-only Lobby remote calls (`standins`, `mode`, `sides`, `ranked`, `ready`, `play`). Anything else is noted where used.

(Results are written step by step below.)

## Step 1 — Co-op regression (Easy, solo)

| # | Area | Result | Evidence |
|---|---|---|---|
| R3-1 | Boot, home screen, J | PASS | Console: only the expected `[Progression]` no-DataStore line and two `[LevelBoard]` this-server lines (level board, Trophy board). `SaveStatus=offline`. Home shows three mode cards (Co-op / Camp Clash / Bone Rush), track, 4 difficulties, Hunt Board, Profile, PLAY. `home.png` |
| R3-2 | Hero pick → PLAY → Building → placement → Start → rounds 1–3 | PASS | Tracker picked (H). Two Hunting Blinds placed for 200 each (450→50). Start → Playing. Console "Round 1/2/3 cleared \| Easy, 1 player(s) \| lives 40 …", peak enemies 13, script cost avg 0.22–0.24 ms. |
| R3-3 | F3: upgrade mid-round | PASS | Round 1, Playing, `MouseBehavior=LockCenter`, E on a Hunting Blind → panel; click "Keen Eyes · 460" → title `1·0·0`, cash 3050→2592 (−460 + take-downs). X closed the panel. |
| R3-4 | Loss: the losing round is not "cleared" | PASS | Sold both towers in round 4, round 5 leaked: fence 40→0 with 8 dinos still on the track. Console "Round 4 cleared …", then "GAME OVER on round 5", "Match over (round 5, lost): +0 Amber each" — no "Round 5 cleared". `RoundsCleared=0`, `HeroXp=0` after the match. `coop-result.png` |
| R3-5 | F4: last dino breaks the Fence = loss, no bonus/heal/XP | NOT TESTABLE BY AGENT in play (code + spec PASS) | Tried to engineer it in three more matches: Easy with no defence leaks exactly 38 in round 1 (fence 40→2, the last dino costs 3, so the round clears on 2), and round 2 breaks with 26–27 dinos left; Normal no defence breaks round 1 with 11 left. The exact case needs a fence that hits 0 on the last leak, which I can't set up without editing. Read-only check: `Server/Waves.run` now calls `Shared/RoundFlow.run`, which checks `isOver()` once more after `remaining()` reaches 0 and before `onRoundEnd`, and `tools/test/roundflow.spec.luau` exists. Every loss seen printed no "cleared" line for the losing round. |

## Step 2 — Home screen (battle cards, options, Ready, no-trap)

| # | Area | Result | Evidence |
|---|---|---|---|
| R3-6 | Camp Clash / Bone Rush cards | PASS | Cards "Camp Clash — Two or three camps, each defending its own side." and "Bone Rush — Every hunter for themselves. Most Bones wins." Picking Camp Clash shows BATTLE OPTIONS: Casual · Ranked · 2 camps · 3 camps · Fill with stand-ins. Default Casual + 2 camps; PLAY dark with "Camp Clash needs at least 2 hunters." `clash-home.png` |
| R3-7 | Ranked fixes Normal | PASS | Ranked → `Difficulty=NORMAL`, header "BATTLE OPTIONS · Ranked is always Normal."; clicking Easy afterwards keeps NORMAL. |
| R3-8 | Ready + Entry fee + Practice line | PASS | Ranked shows "Ready" and "Entry fee: 15 Amber · You have 100 Amber / Practice Hunt: session Amber only. Trophies won't change. / Ready: nobody yet (2 needed)". Ready → inline confirm "Pay 15 Amber to enter?" + X. Pay → `Ready=true`, button "Ready · (cancel)", "Ready: Jover_428 (1 of 1 needed)" (with stand-ins on). `ranked-home.png` |
| R3-9 | PLAY enables at the minimum | PASS | 3 camps + "Fill with stand-ins" → "needs at least 1 hunter"; after Ready, PLAY turns green (`BackgroundColor3` 0.27,0.71,0.43) and the line reads "You're the host: pick a mode…". |
| R3-10 | No-trap G/P/H/M in the Lobby (707×620) | PASS | Each opens with its key, closes with the same key, and closes with its X (Hunt Board/Profile X at 603,38; hero/unlocks X at 527,156 / 527,135, all in the viewport). `MouseBehavior=Default` after each close. |
| R3-11 | No-trap at a small window | NOT TESTABLE BY AGENT | The tools can't resize the viewport. NEEDS JOVAN. |

Note (cosmetic, Studio-only, known): the "+1000 cash (K)" button overlaps the Co-op card's left edge.
Note: while the "Pay 15 Amber to enter?" confirm is open, the other battle options (3 camps, stand-ins) stay clickable. Not a trap; the confirm stays.

## Step 3 + 6 — Camp Clash (Casual) with stand-ins, and losing my camp

Setup: Camp Clash, Casual, stand-ins on, picked by clicking the home buttons. **Deviation:** my "2 camps" click landed while the options row was re-laying out after Casual, so the match was **3 camps on Normal** (left over from the Ranked pick). Console "Camp Clash on Normal: 3 sides, 1 player(s), 2 stand-in(s)". I built two Hunting Blinds at my spawn (too far from the track), so Red Camp fell in round 1 — which covered step 6.

| # | Area | Result | Evidence |
|---|---|---|---|
| R3-12 | No Start button; timed build | PASS | Building HUD has no Start button (only "+1000 cash (K)"). `BuildEndsAt` was ~8.6 s away about 20 s after PLAY (≈30 s build); State went Building→Playing on its own. HUD "Red Camp · Build (B), choose a hero (H) · Normal · Cash 450 · Fence 30". |
| R3-13 | Camps board + status line | PASS | Board "3/3 camps left · Red Camp · Fence 30 · 0 Bones (bold, yours) · Blue Camp · Fence 30 · 0 Bones · Green Camp · …" with camp colours; after the fall "2/3 camps left … Red Camp · out · 0 Bones". |
| R3-14 | Side elimination line | PASS | Console "Round 1 over \| Camp Clash, 3 sides (3 alive) \| Fences 8 / 30 / 30 …" then "Red Camp's Fence is down! They're out." |
| R3-15 | Spectate banner after my Fence fell | PASS (cosmetic note) | HUD "Your Fence is down — you're watching now." `spectate.png`. The banner sits on top of the camps board's first row ("Blue Camp · Fence 30 · 53 Bones" is hidden behind it) — see note N1. |
| R3-16 | Out: can't build / pick hero / upgrade hero | PASS | B, H and U open nothing while out (probe: no panel visible). My two towers were removed when the camp fell. |
| R3-17 | Inspect while out → read-only panel | PASS | Prompts near Blue's towers read "Inspect / Hunting Blind", "Inspect / Mortar Pit". E → "Hunting Blind · 0·0·0 / Blue Camp's tower / HP 93/100", only an X button (no upgrade/repair/sell rows). `inspect.png` |
| R3-18 | No-trap on the Inspect panel | PASS | X (527,374, in the viewport) closes it; walking away closes it (PromptHidden). E/Q/B don't close it, the same as the co-op tower panel (by design). |
| R3-19 | Shoot a stand-in tower to Trampled + kill-feed line | PASS | Ranked 3-camp match (below), round 5. Stood at (230,−28) by Blue's Hunting Blind; **scripted setup:** one Studio L press (100→50) and the Revolver equipped with `EquipTool`. Then only my shots: 50 → 43.2 → 39.0 → … → 2.2 → **0, `KO=true`** in 54 s (~1.05 per Tracker shot at hunter Lv 1). Console "Jover_428 trampled Blue Camp's Hunting Blind". Inspect on it: "Hunting Blind · 0·0·0 / Blue Camp's tower / HP 0/100". The on-screen kill-feed line had faded by my screenshot (`trampled.png` shows the blackened tower). |
| R3-20 | Own shots don't damage own towers | PASS | ~24 Revolver shots (ammo cycled 12→5 with a reload) at my Longshot Perch 7 studs ahead, same geometry that hit Blue's blind: HP stayed 80/80. |
| R3-21 | Towers ignore the rival track | PASS | 20 s tracer probe, round 5, 3 camps: my 6 towers → 27 tracers, all ending on my side; the 6 stand-in towers → 74, all ending on their sides. None crossed. |
| R3-22 | Your chest only | NOT RUN | No Supply chests were spawned in my matches (no Quartermaster/airdrop). NEEDS JOVAN (2 clients). |
| R3-23 | Build refusal in the rival zone | PASS | Hunting Blind aimed at Blue's zone (132,−30) → "That's another camp's zone. Build inside your own camp." Nothing placed. |
| R3-24 | Build refusal on the crossing strip | PASS (string not captured separately) | Aimed at (112,−30) on the strip: nothing placed (tower count unchanged); the one refusal string I captured right after was the rival-zone string above, which Run 2 also saw for the strip. |

## Step 4 — Camp Clash, 3 camps, Ranked (Practice Hunt), stand-ins

Setup: home buttons Ranked · 3 camps · Fill with stand-ins · Ready → "Pay 15 Amber to enter?" → Pay, then PLAY. Console "Camp Clash on Normal: 3 sides, 1 player(s), 2 stand-in(s)". **Scripted help:** K for cash (many presses) to build 4 Hunting Blinds, 9 Mortar Pits, 2 Longshots and upgrade three Mortars to 2·0·0.

| # | Area | Result | Evidence |
|---|---|---|---|
| R3-25 | Stake leaves session Amber at PLAY | PASS | Amber 105 → **90** at PLAY (Building), `Ready=true`. |
| R3-26 | End + placements | PASS | All three fences fell in round 9 (Normal's round-8/9 spike took every camp 30→11→0). Console "Camp Clash over on round 9: 1. Red Camp (382 Bones) \| 2. Blue Camp (367 Bones) \| 2. Green Camp (378 Bones)" — the shared fall goes to the most Bones (Red, mine) and the other two share 2nd, as `BattleFlow.teamPlaces` documents ("sides that fell in one step share a place"). |
| R3-27 | Amber Hoard share comes back; Trophies unchanged | PASS (numbers) | Console "Battle settled (Practice Hunt): pot 15, sink 0". Amber 90 → **155** back in the Lobby (+65 = the 15 Hoard back + the win payout). `Trophies=0` before and after, `Arena=1`, `PracticeHunt=true`. |
| R3-28 | Results screen (title, placements, Amber Hoard line, Practice line, player XP) | NOT SEEN here | My polling call hung for ~2 min (an MCP call during upgrades), so the 30-s results screen came and went. Checked in Bone Rush below. PlayerXp 774 → 2654. |
| R3-29 | Casual Camp Clash payout (match 1, my camp out first) | PASS | 3rd place: Amber 100 → 105 (+5 loss pay), console "Battle settled (Casual): pot 0, sink 0", "Camp Clash over on round 10: 1. Blue Camp (447) \| 2. Green Camp (443) \| 3. Red Camp (0)". |

## Step 5 — Bone Rush, 10 seats (9 stand-ins), Ranked (Practice Hunt)

Setup: Bone Rush card → Ranked · "Seats: N" button cycled 3→10 · Fill with stand-ins · Ready → Pay 15, PLAY. Amber 155 → 140 at PLAY. **Scripted help:** K cash for 9 Mortar Pits (base).

| # | Area | Result | Evidence |
|---|---|---|---|
| R3-30 | Bone Rush home options | PASS | Options row "Casual · Ranked · Seats: 3 · Fill with stand-ins"; the Seats button steps 3→4→…→10. Same Ready/Entry fee/Practice lines as Camp Clash. |
| R3-31 | 10 seats: peak enemies vs cap, script cost | PASS (recorded) | Console per round: r4 peak 48/130 (avg 0.66 ms, worst 6.40), r8 84/130 (0.91 / 6.79), r9 104/130 (1.19 / 7.96), **r10 125/130** (avg 1.36 ms, worst **8.37 ms**). The cap was not hit. Fences went 30 → 11 for all ten in round 9 (the Normal round-9 spike). |
| R3-32 | Ranking by Bones (stand-ins score), end at ≤1 alive | PASS | My camp fell in round 10 ("Jover_428's Camp's Fence is down! They're out."); all nine stand-ins fell in round 11 and the match ended. "Bone Rush over on round 11: 1. Stand-in 6's Camp (559) \| 2. Stand-in 3's (511) \| 3. Stand-in 5's (511) \| … \| 10. Jover_428's Camp (441)". The same-step fall is ordered by Bones; the earlier fall (mine) is last. |
| R3-33 | Results screen | PASS (layout note N2) | "GAME OVER · home in 6s" and card "**Bone Rush — 10th Hunter**", 10 placement lines (mine highlighted), "+20 Amber", "**Amber Hoard 15 Amber · your share +15**", "**Practice Hunt: session Amber only. Trophies won't change.**", "+992 player XP", "Player level up! 5 → 6". `rush-res.png` |
| R3-34 | Survivor bonus | NOT SEEN | Nobody survived (all stand-ins fell in the same step), so no survivor bonus was paid. |

Note (by design, worth a look): in Practice with stand-ins, the only real hunter gets the whole Hoard back even in 10th place ("your share +15"), because `Stakes.settleBattle` splits the pot over **real present hunters in placement order** (stand-ins never take a share). So solo Ranked never costs Amber. Fine for testing; Jovan may want to know.

## Step 7 — Profile Trophies tab, player list

| # | Area | Result | Evidence |
|---|---|---|---|
| R3-35 | Profile → Trophies tab | PASS | Tabs Profile · Leaderboard · Trophies. Trophies: "Player level 6 · 646 / 750 XP to level 7 · **0 Trophies · Fern Gully**", arena ladder 0 Fern Gully (highlighted) / 300 Raptor Ridge / 600 Muddy Springs / 1000 Horn Canyon / 1500 Volcano Rim / 2000 Sky Cliffs / 3000 Misty Jungle / 4000 Rex Kingdom, then "This server · The world board goes live when the game is published. · #1 · 0 · Jover_428". `trophies.png`. X and P close it, `MouseBehavior=Default`. (Tabs sit at GUI y≈77, inside the known CoreGui click band; clicking at y 90 works.) |
| R3-36 | Player list columns | PASS | `leaderstats`: **Bones**=0, **Player level**=6, **Trophies**="0 · Fern Gully", **Title**="" (none equipped). |
| R3-37 | Trophies after Practice matches | PASS | `Trophies=0` after both Ranked Practice matches. |

## Step 5b — Bone Rush, 4 seats (3 stand-ins), Casual, Normal

Setup: Casual, Seats 4, stand-ins. **Scripted help:** K cash (~70 presses over the match) for 10 Mortar Pits, upgraded to 2–4 on path 1 and 0–2 on path 2.

| # | Area | Result | Evidence |
|---|---|---|---|
| R3-38 | Win as the last camp standing | PASS | Fences: r10 "10 / 30 / 30 / 30" (mine took the hit), then all three stand-ins fell together in round 11 and the match ended at once. Results "**VICTORY** · home in …", "**Bone Rush — Top Hunter!**", "1. Jover_428's Camp · 565 Bones \| 2. Stand-in 4's · 534 \| 3. Stand-in 2's · 530 \| 4. Stand-in 3's · 530", "+60 Amber", "+2109 player XP", "Player level up! 6 → 9". No Hoard/Practice lines (Casual), as expected. |
| R3-39 | Survivor bonus | NOT CONFIRMED | My 565 Bones may include it, but the card and console don't show it separately and I didn't log Bones before the end. |

## Co-op regression after the battles (fresh Play session, J first)

| # | Area | Result | Evidence |
|---|---|---|---|
| R3-40 | Co-op end to end, rounds 1–9 | PASS | Easy, Tracker. My first placements from the spawn were refused "Too close to the track" (correct: the co-op lane is at z −15), so round 1 leaked to Fence 2; then a Hunting Blind ×2 + Mortar Pit between the lanes cleared rounds 1–8 ("Round N cleared \| Easy, 1 player(s) \| lives 2 …", peak enemies 5–24, script cost avg 0.16–0.30 ms). Round 9 leaked: "GAME OVER on round 9", "Match over (round 9, lost): +0 Amber each", no "Round 9 cleared". Results: "GAME OVER / The fence fell on round 9 (Easy) / No Amber (solo pays on a clear) / +972 player XP / Player level up! 1 → 2". |
| R3-41 | Console across the whole run | PASS | Full scan: no errors or warnings from our scripts. Only Studio Assistant `VirtualInput … hits CoreGUI` lines and one "Infinite yield possible on 'Jover_428:WaitForChild("Humanoid")'" whose stack is the Assistant's `characterNavigation` tool (not ours). |

## Not testable here / NEEDS JOVAN

| # | Area | Result | Why |
|---|---|---|---|
| R3-42 | Final Stampede (overtime) | NOT TESTABLE BY AGENT | It needs a battle that reaches the end of the round table (round 40). Every battle ended by round 9–11 on Normal/Easy. |
| R3-43 | Mid-battle joiner → waiting banner | NEEDS JOVAN | Needs a second client. |
| R3-44 | Hunter vs hunter (×0.5, respawn on your camp, Camo Cover countdown), teammate upgrade, enemy-tower refusals for a real 2nd player, non-host Ready + stake, Ranked leaver → last-place Trophies, your chest only, 3-camp balance, raiding feel | NEEDS JOVAN | T86's Jovan script (Clients and Servers, 2 then 3 players). |
| R3-45 | Small window / phone no-trap | NEEDS JOVAN | Viewport can't be resized by the tools. |
| R3-46 | F4 exact case (last dino breaks the Fence) in play | NOT TESTABLE BY AGENT | See R3-5; the code path and spec are in place. |

## Run 3 summary

| Area | Result | Evidence |
|---|---|---|
| Sync to 207513e (Amber Hoard, RoundFlow, Inspect) | PASS | header |
| Co-op regression: rounds, placement, mid-round upgrade (F3), loss not "cleared" | PASS ×5 (R3-1…4, R3-40) | console |
| F4 exact last-dino case | NOT TESTABLE BY AGENT (code + spec in place) | R3-5 |
| Home: battle cards, Casual/Ranked, camps/seats, stand-ins, Ready + Entry fee + Practice line, PLAY at minimum | PASS ×5 (R3-6…9, R3-30) | `clash-home.png`, `ranked-home.png` |
| No-trap: G/P/H/M, Inspect panel, Profile Trophies tab | PASS ×3 (R3-10, R3-18, R3-35) | probes |
| Camp Clash: timed build/no Start, camps board, elimination line, spectate, out = no build/hero, Inspect read-only, refusals, tower to Trampled + kill line, own shots, rival track | PASS ×12 (R3-12…21, R3-23, R3-24) | `spectate.png`, `inspect.png`, `trampled.png` |
| Ranked Practice: stake out, Hoard back, Trophies unchanged, Practice line | PASS ×3 (R3-25…27) + results screen PASS in Bone Rush (R3-33) | `rush-res.png` |
| Bone Rush 10 seats: peak 125/130, worst 8.37 ms; ranking by Bones; results | PASS ×3 (R3-31…33) | console |
| Bone Rush 4 seats: Top Hunter win | PASS (R3-38) | console/HUD text |
| Casual payouts, placements with a shared fall | PASS ×2 (R3-26, R3-29) | console |
| Player list columns, Trophies after Practice | PASS ×2 (R3-36, R3-37) | leaderstats |
| Console errors | PASS (R3-41) | scan |
| Results banner overlap | **FAIL (minor)** F5 | `rush-res.png` |
| Spectate banner overlap | **FAIL (minor)** F6 | `spectate.png` |
| Survivor bonus | NOT CONFIRMED (R3-34, R3-39) | — |
| Your chest only, Final Stampede | NOT RUN / NOT TESTABLE (R3-22, R3-42) | — |
| Multi-client items, small window | NEEDS JOVAN (R3-43…45) | — |

**Counts:** PASS 41 · FAIL 2 (minor, cosmetic) · NOT TESTABLE BY AGENT 3 · NEEDS JOVAN 3 (+ chest) · NOT RUN 1 · NOT CONFIRMED 2. (R3-28 results screen in the Camp Clash Ranked match: missed, covered by R3-33.)

## Run 3 failures

### F5. A camp's "Fence is down! They're out." banner covers the results card's title and X — minor (cosmetic)
- **Repro:** Bone Rush, 10 seats with stand-ins; let the last camps fall in the final step. The results card appears while the elimination banner is still up.
- **Seen:** "Stand-in 4's Camp's Fence is down! They're out." (two lines, top right) sits over "Bone Rush — 10th Hunter" and the card's X (`rush-res.png`). The X stays visible and clickable at its edge, so it isn't a trap.
- **Console:** nothing.
- **Suspect:** `src/client/Hud.client.luau` — hide (or move below) the out banner when the results card shows.

### F6. The spectate banner hides the first row of the camps board — minor (cosmetic)
- **Repro:** Camp Clash, let your Fence fall.
- **Seen:** "Your Fence is down — you're watching now." is drawn across the camps board's first camp row ("Blue Camp · Fence 30 · 53 Bones" unreadable), at 707×620 (`spectate.png`, `inspect.png`). The board also wraps "· 53 / Bones" onto a second line at this width.
- **Console:** nothing.
- **Suspect:** `src/client/Hud.client.luau` (banner position vs the camps board).

## Notes for the Director / Jovan (not failures)
- N1. The results screen lasts **8 s** (`Tuning.ResultsTime = 8`). A 10-line Bone Rush card plus Hoard, Practice, XP and level lines is hard to read in 8 s; Run 2's "home in 58s" was likely a misread. Consider longer for battles.
- N2. "+20 Amber" on the results already includes the Hoard share (LastPayout = casual + share), so "+20 Amber" next to "Amber Hoard 15 · your share +15" reads like +35. Amber went 140 → 160.
- N3. Practice Hunt with stand-ins returns the whole Hoard to the only real hunter even in 10th place (`Stakes.settleBattle` splits over real hunters only). Solo Ranked can't lose Amber.
- N4. The Ready confirm "Pay 15 Amber to enter?" doesn't block the other battle options (3 camps / stand-ins stayed clickable). Harmless.
- N5. Tooling: the battle-options row re-lays out when Casual/Ranked changes, so a click sent right after (my "2 camps") can land on the old spot. CoreGui click bands also swallowed the Co-op card centre (GUI y 122) and the Sell row (GUI y 505) late in the session; clicking elsewhere on the button works. Probably Studio overlays — worth a glance on a real client.
- N6. Normal's round 8–9 spike takes every camp's Fence 30 → 11 in the same round (all 10 seats identical), so battles on Normal end around rounds 9–11 — the known leak-cost issue.

## Studio state at the end
- Play mode stopped. `get_studio_state`: **Current Studio Mode: Edit**, DataModels: Edit. Nothing changed in Edit, nothing published; `SaveStatus=offline` throughout (J pressed first in both Play sessions).

# Run 4 — 2026-10-08 (Tester, agent) — T86b re-check

- **Code tested:** Studio synced to c559cdc: `script_grep` "HUNT OPTIONS" → Shared.HomeLayout:82; "BattleResultsTime" → Shared.Config:134 (=15) and Shared.BattleFlow:103.
- **Start state:** Studio in Edit mode. Work files: `~/.claude/jobs/2a8d6f9c/tmp/tester6/`.
- **Conveniences (disclosed):** J first (no saves), K cash, home-screen clicks, read-only `execute_luau`.

| # | Item | Result | Evidence |
|---|---|---|---|
| R4-1 | Bone Rush Ranked (Practice), stand-ins: setup | NOTE | Home clicks Bone Rush · Ranked · Fill with stand-ins · Seats · Ready · Pay · PLAY. Deviation: my Seats click stepped 3→**2**, so this was 2 seats (me + 1 stand-in). No defence; my Fence fell in round 1/2 and that ended the match. |
| R4-2 | "HUNT OPTIONS" on home | PASS | Header "HUNT OPTIONS · Ranked is always Normal." `rhome.png` |
| R4-3 | Place line (Bone Rush) | PASS | Card title "Bone Rush — 2nd place". `rush2-res.png` |
| R4-4 | Amber line | PASS | "Amber +33 (30 payout + 3 Amber Hoard)"; no separate share line. Amber 85→118 (+33). Console "Battle settled (Practice Hunt): pot 15, sink 12" (stand-in's share to the sink, item 7). |
| R4-5 | Results time in battle ~15 s | PASS | ~1.5 s after the state flipped the status read "GAME OVER · home in 14s". |
| R4-6 | F5 (no banner/feed over results) | PASS (this case) | My "Fence is down! They're out." fired in the same step as the end; the HUD dump at results had no banner/feed label, title and X fully visible. Only the Studio-only "+1000 cash (K)" button clips the title's "B" (known Studio-only). |
| R4-7 | F6 spectate banner (Bone Rush, Casual Hard, 3 seats, no defence) | PASS | "Your Fence is down — you're watching now." at bottom-centre (GUI y 436, above HP bar); the camps board's first row "Stand-in 2's Camp · Fence 20 · 35 Bones" fully readable. `spect.png` |
| R4-8 | Camp-out banner placement (T86b item 2, 2nd sentence) | **FAIL (minor)** F7 | "Jover_428's Camp's Fence is down! They're out." shows top-**right** at GUI (408,64), over the level bar's "0 / 500 XP" text — not top-centre below the camps board (board ends at y≈340). `spect.png` |
| R4-9 | F5 exact repro (a camp-out fires in the final step) | PASS | Feed "Stand-in 2's Camp's Fence is down! They're out." arrived at the end; HUD dump at results: no banner/feed/spectate label, only status, card and HP bar. |
| R4-10 | Place line + Amber line, Casual | PASS | "Bone Rush — 3rd place"; "Amber +10" (no share). "home in 14s" ~1.5 s after the end. Console "Bone Rush over on round 10 …", "Battle settled (Casual): pot 0, sink 0". |
| R4-11 | Camp Clash Casual, 2 camps, stand-ins, no defence | PASS | "Camp Clash — 2nd place", "Amber +5", "home in 14s", no banner/feed over the card. `clash-res.png`. (A second, accidental Camp Clash on Easy — my Co-op card click hit Studio's CoreGui band — gave the same.) |
| R4-12 | Co-op round-trip, results 8 s | PASS | Easy, no defence: "GAME OVER on round 2", "Match over (round 2, lost): +0 Amber each"; status "home in 7s" ~1.5 s after, Lobby 2.3 s after a later poll. |
| R4-13 | Console | PASS | Scan for error/warn/infinite: none from our scripts (only Assistant VirtualInput CoreGUI lines). |

### F7. The camp-out banner sits top-right over the level bar, not top-centre below the camps board — minor (cosmetic)
- **Repro:** any battle, a camp's Fence falls. **Seen:** "X's Camp's Fence is down! They're out." at GUI (408,64), covering the "0 / 500 XP" text of the level bar (`spect.png`). T86b item 2 asked for top-centre, below the camps board's bottom edge. **Suspect:** `src/client/Hud.client.luau` (out-banner position).

**Run 4 summary:** F5 PASS, F6 (spectate) PASS, Nth place PASS (both modes), battle results ~15 s PASS, Amber line PASS, HUNT OPTIONS PASS, co-op 8 s PASS, console clean. 1 minor FAIL (F7, camp-out banner placement). Deviation: the Practice Bone Rush ran with 2 seats (Seats click went 3→2); the 3-seat Bone Rush was Casual Hard.

**Studio state at the end:** Play stopped; `get_studio_state` = Edit. Nothing edited or published; `SaveStatus=offline` throughout (J first).

# Run 5 — 2026-10-08 (Tester, agent) — Phase 8 batch 1 (T89, T90, T91b, T92, T93, F7)

- **Code tested:** Studio synced to b1a090c: `script_grep` "StudioOnly" → Shared.StudioOnly, Client.Home:267, Shared.HomeLayout:190; "standinshold" → Server.Main:291–292, Client.Home:280, Shared.StudioOnly:25, Server.Battle:119; "SaveStore" → Shared.SaveStore (ATTEMPTS 3, LOCK_WAITS 6, backoff).
- **Start state:** Studio in Edit mode. Work files: `~/.claude/jobs/2a8d6f9c/tmp/tester7/`.
- **Conveniences (disclosed):** J first in each Play session (no saves), K cash, home-screen clicks, keyboard/mouse input, `character_navigation`, read-only `execute_luau`, and the Studio-only Lobby remotes (`standins`, `mode`, `sides`, `startround`, `standinshold`, `play`). Anything else is noted where used.

(Results are written step by step below.)

## Step 1 — Boot, saves offline, Studio-only options (T89, T90)

| # | Item | Result | Evidence |
|---|---|---|---|
| R5-1 | Boot with no save errors (T90) | PASS | Play → console only the expected `[Progression] No data store…` and the two `[LevelBoard] Not published…` lines. `SaveStatus=offline`. |
| R5-2 | Studio-only host options visible in Studio (T89/T91b) | PASS | Home (Camp Clash, stand-ins) shows a bottom row "Start at round 1 · Stand-ins hold" under PLAY. `home5.png` |
| R5-3 | Gate exists (T89) | PASS (code) | `Shared.StudioOnly.allowed(isStudio, feature)` = `isStudio == true and FEATURES[feature]`; Server.Main gates `standins` (314), `startround` (316), `standinshold` (318) on `StudioOnly.allowed(RunService:IsStudio(), …)`. A live server can't be tested here. |

## Step 2 — T93 stand-in hunter (Camp Clash, 2 camps, Easy, stand-ins)

Setup (disclosed): Tracker, Revolver equipped with client `Humanoid:EquipTool` (key 1 is a CoreGui key for VirtualInput, as in Runs 2–3); K for cash; 4 Mortar Pits. Stood at (145, 3, 12) facing Blue's stand-in hunter at (146, 1.6, 0). A read-only server watcher logged every change of the dummy's billboard text.

| # | Item | Result | Evidence |
|---|---|---|---|
| R5-4 | Dummy spawns on the stand-in camp | PASS | Console "Stand-in hunter on Blue Camp (Studio only): 100 HP, never shoots"; model `StandInHunter2` at Blue's spawn; billboard "Blue Camp stand-in hunter / HP 100 / 100". |
| R5-5 | Hunter-vs-hunter damage ×0.5 | PASS | 8 single shots, ≥0.4 s apart, hunter Lv 2: billboard HP 75 → 68 (7 lost; expected 8 × 1.5 Tracker × 1.25 Lv 2 × 0.5 = 7.5; full damage would be 15). Earlier at Lv 1 the HP fell 1 per ~1.3 shots (0.75 per shot). |
| R5-6 | "Tranqed by <name>!" on its label and in Output | PASS | Billboard "Blue Camp stand-in hunter / Tranqed by Jover_428!" (body drops to y 0.7) twice; console `[DinoHunters] Blue Camp's stand-in hunter: Blue Camp stand-in hunter · Tranqed by Jover_428!`. |
| R5-7 | Respawn on its own camp after Respawn time | PASS | Down at 115.85 s → back at 118.86 s (3.0 s = `RespawnTime` 3) at (146, 1.6, 0), "HP 100 / 100". Second down 212.91 → back 215.93. |
| R5-8 | Camo Cover after respawn: can't be hit, countdown shown | PASS | Billboard "HP 100 / 100 / Camo Cover 3.0s" at 118.86; the Camo line was gone at 121.89 (3.03 s = `SpawnShield` 3). I fired the whole time; HP stayed 100 through the Camo window and started falling at 123.98. |

Tooling notes: `character_navigation` unequips the gun; clicks sent while the Build panel is in "Placing…" mode are placement attempts, not shots (cost me two attempts). In zsh, `$p` doesn't word-split (use `${=p}`). Placement works when the move and click are in one `user_mouse_input` call, during Building.

## Step 3 — T92 Tectonic Slam (Concussive T5), same match

| # | Item | Result | Evidence |
|---|---|---|---|
| R5-9 | Buy Concussive 1→5 on a Mortar Pit | PASS | K cash (60 presses, disclosed). Panel row clicked 5×: Shockwave 1265, Armor Crack 2909, Stun Grenade 6692, Earthshaker 15391, Tectonic Slam 35400 → row "Concussive · maxed · Tectonic Slam", Sell 43544. Tower attrs `Path3=5`, `Spent=62207`. Studio `Config` Tectonic Slam `damageMult = 34` (T92 value), stun 1 s, no boss stun. |
| R5-10 | It fires, no errors | PASS | 75-s read-only probe: 9 shell tracers from the T5 tower (few dinos come within its range at (−12, −2); the neighbouring base Mortar fired more). No script errors or warnings. Knockback/stun not isolated (no jumps/stops seen in the samples) — not measured. |

## Step 4 — T91b pacing (battle round time 120), Camp Clash 2 camps, Easy, rounds 7–10

Read-only server watcher: round start times vs when each side's dinos reached 0.

| # | Item | Result | Evidence |
|---|---|---|---|
| R5-11 | Next round waits for the previous to clear | PASS | r7: s2 clear 11.3 s, s1 14.7 → R8 at 20.0 (+5.3). r8: s1 96.0, s2 96.8 → R9 at 102.1 (+5.3). r9: s2 206.6, s1 217.7 → R10 at 222.3 (+4.6). Round 9 ran **115.6 s** before both cleared and round 10 still waited (with 60 s it would have started at 162 s on top of live dinos). Round 10's s1 cleared at 125 s after its start, then the match ended (Blue fell). No round started with dinos left on either side ("left s1=0 s2=0" at every start). |
| R5-12 | Battle round-over lines | PASS | Console "Round N over \| Camp Clash, 2 sides (2 alive) \| Fences 40 / 40 \| peak enemies 16–24/130 \| script cost avg 0.25–0.34 ms, worst ≤2.27 ms", one per round. Match: "Camp Clash over on round 10: 1. Red Camp (607 Bones) \| 2. Blue Camp (586 Bones)" (stand-in hold was off). |

## Step 5 — F7 camp-out banner (Camp Clash, 3 camps, Easy, Start at round 38, Stand-ins hold)

| # | Item | Result | Evidence |
|---|---|---|---|
| R5-13 | F7: camp-out banner top-centre below the camps board, not over the XP bar | PASS | My undefended camp fell in round 38. "Red Camp's Fence is down! They're out." in `CampOut` at GUI (93, 348) 520×30 — horizontally centred (centre x 353, same as the screen), directly below `CampsBoard` (12, 104, 212×236 → bottom y 340). The XP bar `HeroXp` is at y 56–80, untouched. The spectate banner sits lower and doesn't overlap. `f7b.png` |
| R5-14 | Studio options reach the server | PASS | `("sides",3)`, `("startround",38)`, `("standinshold",true)` → `BattleSides=3`, `StudioStartRound=38`, `StandInsHold=true`; home chip reads "Start at round 38". Match started at Round 38 (hunter Lv 8). |

## Step 6 — Final Stampede (same match)

| # | Item | Result | Evidence |
|---|---|---|---|
| R5-15 | Stand-ins hold keeps stand-in camps at Fence 1 | PASS | Round 38: "Fences out / 1 / 1" (Blue and Green 40 → 1 and held through rounds 38–44). |
| R5-16 | Round 40 → Final Stampede banner | PASS | Round 41 at +285 s: `Overtime=1`, HUD `FinalStampede` label "Final Stampede! Dinos get tougher every round." at GUI (93, 352), under the camps board, above the spectate banner. Status still reads "Round 41". `stampede.png` |
| R5-17 | HP step ×1.25 per repeat | PASS | Console "Final Stampede 1: round 40 again, dino HP x1.25", "2: … x1.56", "3: … x1.95", "4: … x2.44" (= 1.25ⁿ). Each repeat plays round 40 (peak 86/130 enemies, avg 0.77–0.80 ms, worst ≤2.55 ms). |
| R5-18 | Rounds 38–44 pacing with held camps | NOTE | Each round ran the full 120 s cap (held stand-in camps never clear: leaks keep coming). R39 at 44.8 s, R40 165.0, R41 285.2 (120.2 s apart). |
| R5-19 | Match ends when a camp falls in overtime → results | **NOT TESTABLE this way** (N7) | With my camp out and both stand-in camps held at 1, nobody can fall, so the match runs forever. `("standinshold", false)` mid-match is ignored (the Lobby remote returns unless `State == "Lobby"`, Server/Main:276), so I couldn't release them. I stopped Play to end it. |
| R5-20 | Retry: 2 camps, Start at round 40, hold, 5 base Mortars (K cash) | NOTE | My camp fell inside round 40 (5 base Mortars don't hold Easy round 40), so the match ended before overtime: "Camp Clash over on round 40: 1. Blue Camp (28 Bones) \| 2. Red Camp (88 Bones)" — the camp still standing is placed first despite fewer Bones, as designed. A second (accidental — my upgrade clicks landed on PLAY after the results) round-40 match: results card "GAME OVER · home in 14s / Camp Clash — 2nd place / 1. Blue Camp · 28 Bones / 2. Red Camp · 0 Bones / Amber +5 / +0 player XP". `r40res.png`. Surviving rounds 40+ alone needs a much bigger build than I can place in the 30-s build window with agent clicks, so the overtime-end step stays open (R5-19). |

## Step 7 — Saves offline across Play stop/start (T90)

| # | Item | Result | Evidence |
|---|---|---|---|
| R5-21 | Stop Play mid-match (BindToClose), restart, no save errors | PASS | Stopped Play during Final Stampede 4 (a live 3-camp battle): "Game Stopped", Studio back in Edit, no error/warning lines. Restarted Play: the same three boot lines only; `SaveStatus=offline`; Amber back to the session default (100), so nothing persisted. Two more stops (end of run) were clean too. |
| R5-22 | Join/leave save path in Studio | PASS (offline) | Only the `[Progression] No data store…` line per session; no `[SaveStore]` retry or error lines in any session. Live DataStore behaviour (retries, session lock, escrow refund) needs a published place → T95, NEEDS JOVAN. |

## Step 8 — Co-op regression (Easy, solo, 3 base Mortars)

| # | Item | Result | Evidence |
|---|---|---|---|
| R5-23 | Co-op rounds 1–3 | PASS | "Co-op on Easy with 1 player(s)"; "Round 1/2/3 cleared \| Easy, 1 player(s) \| lives 40 \| cash 2877/2959/3046 \| peak enemies 13 \| peak projectiles 0/80 \| script cost avg 0.17–0.21 ms". Start button (clicked low; the top is in the known CoreGui band). |
| R5-24 | Co-op pacing unchanged by B143 | PASS | Next round 5.2 s after each clear (r1 clear 30.8 → R2 36.0; 81.2 → 86.4; 135.6 → 140.9). |
| R5-25 | Studio "Start at round" back to 1 for co-op | PASS | After `("startround",1)` co-op started at Round 1. (Note: the option persists across matches in the session; it carried round 40 into my accidental second battle.) |

## Run 5 — console
| # | Item | Result | Evidence |
|---|---|---|---|
| R5-26 | Script errors across both Play sessions | PASS | Scan for error/warn/infinite/Stack: only 12 Studio Assistant `VirtualInput::SendMousePosition … hits CoreGUI` traces (TestAutomationUtils) and one Assistant "Humanoid is not a valid member" from my own execute_luau during a respawn. None from our scripts. |

## Not testable here / NEEDS JOVAN
| # | Item | Result | Why |
|---|---|---|---|
| R5-27 | T89 on a live server (K/J/L and Studio remotes refused) | NOT TESTABLE BY AGENT | Needs a published place; the gate and its use are confirmed in code (R5-3). |
| R5-28 | Real hunter vs hunter (2 clients), Camo Cover on a real respawn, "Tranqed by" for a real player | NEEDS JOVAN | Clients and Servers; the stand-in hunter covers the rules solo (R5-5…8). |
| R5-29 | Live saves, session lock, escrow refund on BindToClose | NEEDS JOVAN | T95 (published). |

## Notes for the Director / Jovan (not failures)
- **N7 (Studio test aid).** "Stand-ins hold" + a real camp that's already out = a battle that never ends (held camps can't fall; each round runs the 120-s cap forever), and the Lobby remote ignores `("standinshold", false)` outside the Lobby, so only stopping Play ends it. Reaching overtime *with my own camp alive* needs a round-40-proof build the agent can't place in the 30-s window, so "the match ends when a camp falls in overtime" (T91b accept) is still unverified. Options: let the hold apply only while a real camp is alive, or let the Studio host toggle the hold mid-match, or a Studio "my camp holds too" option.
- **N8.** With held stand-in camps, rounds 38–44 always ran the full 120 s (they never clear). Fine for the test aid; just slow (~2 min per repeat).
- **N9.** The status line still reads "Round 41/42…" during Final Stampede; the banner says Final Stampede. Consider "Final Stampede 1" in the status line.
- **N10 (tooling).** `character_navigation` unequips the gun; zsh needs `${=var}` to split args; clicks sent while "Placing…" is open are placements; results-screen clicks can land on PLAY and start a new match.

## Run 5 summary

| Area | Result | Evidence |
|---|---|---|
| Sync to b1a090c | PASS | header |
| F7 camp-out banner position | PASS (R5-13) | `f7b.png` |
| T93 stand-in hunter: ×0.5, Tranqed by line + Output, respawn 3 s, Camo Cover 3 s countdown + immune | PASS ×5 (R5-4…8) | watcher log, console |
| Final Stampede: start 38 + hold, banner, ×1.25 per repeat | PASS ×4 (R5-14…17) | `stampede.png`, console |
| Final Stampede: match ends when a camp falls → results | NOT TESTABLE BY AGENT (R5-19, N7); round-40 end + results PASS (R5-20) | `r40res.png` |
| T91b pacing: next round waits for clears; 115-s round not cut | PASS ×2 (R5-11, 12) | watcher log |
| T89 Studio-only options present + gate in code | PASS ×2 (R5-2, 3) | `home5.png`, grep |
| T90 saves offline, stop/start clean | PASS ×3 (R5-1, 21, 22) | console |
| T92 Tectonic Slam buy + fire | PASS ×2 (R5-9, 10) | panel, probe |
| Co-op regression | PASS ×3 (R5-23…25) | console |
| Console | PASS (R5-26) | scan |
| Live server / multi-client / published saves | NOT TESTABLE / NEEDS JOVAN (R5-27…29) | — |

**Counts:** PASS 23 · FAIL 0 · NOT TESTABLE BY AGENT 2 (R5-19, R5-27) · NEEDS JOVAN 2 (R5-28, R5-29) · NOT RUN 0 · notes 2 (R5-18, R5-20).

## Studio state at the end
- Play stopped. `get_studio_state`: **Current Studio Mode: Edit**, DataModels: Edit. Nothing changed in Edit, nothing published, `SaveStatus=offline` in both sessions (J pressed first in the second; the first never saved: offline). Screenshots in `~/.claude/jobs/2a8d6f9c/tmp/tester7/`: `home5.png`, `f7b.png`, `stampede.png`, `r40res.png` (+ working shots).
