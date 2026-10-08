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
