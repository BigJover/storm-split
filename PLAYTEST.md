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

# Run 6 — 2026-10-08 (Tester, agent) — R5-19 re-test (c2ec04d)

- **Code tested:** Studio synced to c2ec04d: `script_grep` "standinshold" → Server.Main:251 handler no longer Lobby-only ("also works mid-match", line 83), Shared.StudioOnly:42 `heldLoss(... realAlive)`, Server.Battle:121.
- **Conveniences (disclosed):** J, read-only `execute_luau`, Studio Lobby remotes (`mode` TEAM, `sides`, `standins`, `startround` 38, `standinshold`, `play`). No towers placed.

| # | Item | Result | Evidence |
|---|---|---|---|
| R6-1 | Auto-release: 3 camps, stand-ins, Start 38, hold on; my camp falls | PASS | Round 38: Red (mine) out, then Blue and Green (held) fell — "Camp Clash over on round 38: 1. Blue Camp (35 Bones) \| 1. Green Camp (35 Bones) \| 3. Red Camp (0 Bones)". State → Victory, results card "GAME OVER · home in 14s / Camp Clash — 3rd place / ...". Before c2ec04d this ran forever (N7). |
| R6-2 | `("standinshold", false)` mid-match | PASS | 2 camps, Start 38: fired 4 s into round 38 → `StandInsHold=false` (was ignored in Run 5). Match ended round 38 (my camp fell): "1. Blue Camp (30 Bones) \| 2. Red Camp (0 Bones)", results card shown. |
| R6-3 | Same, reached in Final Stampede | NOT TESTABLE BY AGENT | Still needs my camp alive through round 40 (R5-20); both releases verified pre-overtime only. The end check is the same per-leak/side-out path, so overtime should behave the same. |

Console: no script errors or warnings in either match. Studio left in Edit mode.

# Run 7 — 2026-10-12 (Tester, agent) — Phase 8 batch 2 (T103–T106b: pace, clock, tie-break, joiners)

- **Code tested:** Studio synced to 856065f: `script_grep` "for skipped round" → Shared.BattleFlow:12 ("+N cash for skipped rounds X–Y"); "Time left" → Client.Hud:360 (`Time left {clockText}`).
- **Start state:** Studio in Edit mode. Work files: `~/.claude/jobs/2a8d6f9c/tmp/tester8/`.
- **Conveniences (disclosed):** J first in each Play session (no saves), K cash, home-screen clicks, keyboard/mouse input, read-only `execute_luau` (probes/watchers labelled), Studio-only Lobby remotes (`standins`, `mode`, `sides`, `startround`, `standinshold`, `clockcap`, `latestandin`, `play`, `ready`). Anything else is noted where used.

(Results are written step by step below.)

## Step 1 — Paced co-op (Normal, solo, Tracker, 3 base Mortar Pits)
Setup (disclosed): J; K ×3 for the Mortars (so the Cash attribute isn't a pure kill-cash trace from Building; round-to-round deltas are). Expected numbers from a read-only `require(Shared.Pace)` in the Server context (pure module).

| # | Item | Result | Evidence |
|---|---|---|---|
| R7-1 | HUD round counter "Round N / 40" | PASS | Status "Round 1 / 40 · Normal · Cash 1800 · Fence 30 · Dinos 6". `coop.png` |
| R7-2 | Fewer, tougher dinos | PASS | `Pace.plan` Normal r1 = HUSK 9 + BRUTE 4 (unpaced 22 + 9 = 31), hpX 1.38; r2 10+4, r3 12+5, r4 14+5. Console peaks: r1 13, r2 14, r3 16, r4 17 (= the paced counts, not 31+). |
| R7-3 | A few rounds clear normally | PASS | "Round 1/2/3/4 cleared \| Normal, 1 player(s) \| lives 30 \| cash 1886/1973/2074/2180 \| peak enemies 13/14/16/17 \| script cost avg 0.20–0.23 ms"; no leaks, next round started by itself. |
| R7-4 | Kill cash per round unchanged | PASS | Cash per round +86 / +87 / +101 / +106 vs `Pace.expectedIncome` (unpaced income, 1 hunter) 83 / 89 / 98 / 106 (within promotion noise). |
| R7-5 | Ability cooldowns faster | PASS (code) / not measured live | `Tuning.AbilityTempo = 2`; `Pace.abilityCooldown(45) = 22.5`; Server.Hero:263 applies it to every ability cooldown. I couldn't land a Tracking Dart with agent input ("No dino there to dart": F/button + mouse on the dino's screen point didn't register a hit), so the live 22.5 s wasn't timed. |

Tooling note: `execute_luau` gets its own `require` cache, so server modules with state (Enemies.getLive) read empty; probes count `workspace.StormSplitMap.Enemies` models instead.

## Step 2 — Casual Camp Clash pacing, late stand-in, short clock (2 camps, Easy, stand-ins)
Setup (disclosed): K cash, `character_navigation` to (−45, 3, 0) (Red's spawn at x −100 is ~40 studs from the lanes; my first two tries with Mortars near the spawn were out of range and Red fell in round 1, then round 13), 6 base Mortar Pits. A client watcher printed round/state changes and new feed/results texts to Output (`[W]` lines). Third match: `("clockcap",150)`.

| # | Item | Result | Evidence |
|---|---|---|---|
| R7-6 | Played rounds 1, 4, 7, 10, 13 … | PASS | Console "Round 1 over … Round 4 over … Round 7 over … Round 10 over" (no 2, 3, 5 …); `Pace.playedRounds("TEAM", casual)` = 1,4,7…40. Status "Round 7 / 40". |
| R7-7 | Skipped-round cash line | PASS | Feed "+168 cash for skipped rounds 2–3" at R4, "+201 … 5–6" at R7, "+307 … 8–9" at R10; `Pace.skippedIncome` = 169 / 201 / 308 (floor vs round). |
| R7-8 | Clock shows "Time left m:ss" (casual 15:00) | PASS | Status "… Fence 40 · Time left 14:55" in Building (no Studio cap); "Time left 13:38" at R7. `late1.png` |
| R7-9 | Studio short clock | PASS | `("clockcap",150)` → status "Time left 1:36" at R4; match ended ~150 s after Building. |
| R7-10 | "One minute left on the clock!" | PASS | `ClockWarning` visible between 60.97 s (hidden) and 56.8 s left (polled every 4 s); TextLabel, Active=false, GUI (93, 352) 520×30, below the camps board. `clockwarn.png` |
| R7-11 | "Time's up!" + tie-break "Decided by …" (non-trivial decider) | PASS | Both camps standing at the clock, Fence 40 / 40 → Bones decided: console "Camp Clash over on round 10 at the clock, decided by bones: 1. Red Camp (71 Bones) \| 2. Blue Camp (67 Bones)"; card "Camp Clash — Your camp wins the hunt! / 1. Red Camp · 71 Bones / 2. Blue Camp · 67 Bones / Time's up! Decided by Bones / Amber +50". `clockres.png` |
| R7-12 | "Last camp standing" (a camp falls) | PASS | Earlier match: card "Camp Clash — 2nd place / Last camp standing"; console "… over on round 1, decided by standing". |
| R7-13 | Casual late stand-in (Camp Clash) → fewest-hunter camp, toast | PASS | `("latestandin")` in R7: console "Late join (stand-in): Joined Blue Camp at round 7: +1174 cash to catch up", same toast on my HUD (`late1.png`). Blue (stand-in camp, 0 real hunters) < Red (me, 1). Clock match, R4: "+821". Both = `Pace.catchUpCash(joinRound(true, r), 0, Easy)` (1174 / 821). See N11. |
| R7-14 | Same-step fall → tie-break past "standing" | PASS | Start at round 22, no hold, 4 base Mortars: both camps lost Fence 40 → 0 within ~1.5 s of round 25 starting (left-over round-22 dinos reaching the exit together; same seeded dinos on both sides; server probe: no stall, dinos walking z −50 → −20 → 10 → 40 rows). Console "Camp Clash over on round 25, decided by bones: 1. Red Camp (39 Bones) \| 2. Blue Camp (31 Bones)"; card "Decided by Bones". Reproduced 3× with identical Bones (seeded). |
| R7-15 | Final Stampede running until the clock, then "Time's up!" | NOT TESTABLE BY AGENT | Needs my camp alive past round 40 (held stand-in camps auto-release when no real camp stands, R6-1). Try: Start at round 40 + hold + 200-s clock + 7 base Mortars + K cash → Red fell in round 40 (50 s). Same wall as R5-20. Banner stacking checked instead: `FinalStampede` (order 2) and `ClockWarning` (order 1) share the `battleBanners` list (Hud:1016–1018), so both visible would stack, not overlap. |
| R7-16 | Studio "Start at round N" pays skipped rounds before it | NOTE | Start at round 40: "+34141 cash for skipped rounds 38–39"; Start at 22: "+3503 … 20–21" (only the step before the first played round; rounds 1..N−3 aren't paid — fine for a test aid). |
| R7-17 | Casual Camp Clash late join closed after round 30 | PASS | Start at round 31: `("latestandin")` in round 31 (Playing) → console "Late stand-in refused: closed". (In Building before round 31 it was accepted: "Joined Blue Camp at round 31: +450 cash" — the joiner arrives before any round is played, so only start cash; see N12.) |

## Step 3 — Casual Bone Rush (4 seats + 2 spare plots, Easy, stand-ins, no defence)

| # | Item | Result | Evidence |
|---|---|---|---|
| R7-18 | Spare plots exist | PASS | `Sides=6` with 4 seats (Bone Rush spare plots 2). |
| R7-19 | Late stand-in → spare plot, Bones = lowest standing, toast | PASS | Round 4: "Late join (stand-in): Joined the hunt at round 4: +782 cash and 0 Bones to catch up" (toast on my HUD, `brlate.png`); plot 5 opened at Fence 40. Lowest standing Bones at that moment = my plot (still up, Fence 17, 0 Bones) → 0. Second one after I was out: plot 6, "0 Bones" again — lowest standing was plot 5 (0 Bones; its dinos start next round). Floor rule correct but trivial both times; a non-trivial floor below. |
| R7-20 | Third late stand-in with no spare plot | PASS | "Late stand-in refused: full". |
| R7-21 | Bone Rush played rounds 1, 4, 7, 10 | PASS | Console "Round 1 over \| Bone Rush, 4 sides …", "Round 4 over \| Bone Rush, 6 sides (5 alive)", "Round 7 over …"; state Round=10 next. |
| R7-22 | Non-trivial Bones floor | PASS | Start at round 28, my plot out: standing Bones 23 / 22 / 23 → "Late join (stand-in): Joined the hunt at round 28: +21359 cash and 22 Bones to catch up"; plot 5 `CampBones5=22`, Fence 40. |
| R7-23 | Bone Rush late join closed after round 30 | PASS | Start at round 31, Playing: "Late stand-in refused: closed". (In the round-28 match a round-31 try got "refused: over": the match had ended at round 31's start.) |
| R7-24 | Bone Rush result line | PASS | "Bone Rush over on round 31, decided by bones: 1. Stand-in 5's Camp (26 Bones) \| 2. Stand-in 2's Camp (23) \| 3. Stand-in 4's Camp (23) \| 4. Stand-in 3's Camp (22) \| 5. Jover_428's Camp (0)". See N13 (the late joiner won). |

## Step 4 — Live-cap probe: Bone Rush, 10 seats (9 stand-ins), Start at round 37
**Probe (read-only, Server context):** every 0.5 s, the number of dino models in `workspace.StormSplitMap.Enemies` (Enemies.luau:232 destroys a model the moment its dino dies, so models = live dinos), plus Fences. My plot undefended (no towers) — a weak player is a normal case; the 9 stand-in plots have their base towers.

| # | Item | Result | Evidence |
|---|---|---|---|
| R7-25 | Peak live dinos stay under 130 | **FAIL (major)** F8 | Easy: 10 → 54 → 103 → **130** at ~57 s into round 37, flat at 130 until ~73 s. Normal: 20 → 93 → **130** at 46 s, flat at 130 for ~23 s (to 69.5 s), then the plots fell. `MaxConcurrentEnemies` = 130 is a hard cap (SpawnQueue), so spawns were being queued. |
| R7-26 | Same-step fall, deepest tie-break | PASS (rules) | All 9 stand-in plots lost Fence 30/40 → 0 together (left-over dinos from the capped round); Easy: "Bone Rush over on round 37, decided by damage: 1. Stand-in 8's Camp (19 Bones) \| 2. Stand-in 10's Camp (19) …"; Normal: "… decided by coinFlip: 1. Stand-in 2's Camp (17 Bones) \| 2. Stand-in 9's Camp (17) …". Identical stand-ins → identical Bones/survival/Fence/damage/clear time → coin flip, as designed. |

### F8. Bone Rush at max seats saturates the 130 live-dino cap — major (pacing/perf target)
- **Repro:** Studio, Bone Rush, Casual, Seats 10, Fill with stand-ins, Start at round 37 (Easy or Normal), don't build on your plot. Probe the `Enemies` folder's child count during round 37.
- **Seen:** 130 live dinos (the cap) from ~46 s (Normal) / ~57 s (Easy) to the end of the round; ~20 s pinned at the cap. T103b's accept was "value.py peaks at max players Bone Rush ≤ 122". The model seems to assume every side kills its dinos; an undefended or weak plot keeps its share alive for the whole walk.
- **Console:** no errors; the match ended in round 37 before a "Round 37 over … peak enemies N/130" line could print (all plots fell in one step).
- **Severity:** major — the cap queues spawns (no crash), but the busiest battle runs at the ceiling the live cap was meant to stay under; spawn timing on every plot is then distorted.
- **Suspected:** `tools/value.py` live-cap model and `Config` Tuning `BattleCrowdX` (0.7) / Bone Rush round counts (Director's call per #250/#264, report-only).
| R7-27 | Bone Rush ends at round 40 | PARTIAL | Start at round 40, 4 seats: "Bone Rush over on round 40, decided by damage: 1. Stand-in 2's Camp (18 Bones) \| 2. Stand-in 3's Camp (18) \| 3. Stand-in 4's Camp (18) \| 4. Jover_428's Camp (0)" — but every plot fell inside round 40, so "ends at 40 with plots still standing" wasn't isolated (needs a plot that survives round 40). |

## Step 5 — Ranked (Practice Hunt): seats lock, round step, clock
Setup: Camp Clash, 2 camps, stand-ins, "Ranked" home button, `("ready", true)` (Amber 115 → 100 at PLAY), `("play")`.

| # | Item | Result | Evidence |
|---|---|---|---|
| R7-28 | Late stand-in refused in Ranked | PASS | `("latestandin")` in Building and again in Playing → "Late stand-in refused: ranked" ×2; Sides stayed 2. |
| R7-29 | Ranked rounds 2, 4 … and 30:00 clock | PASS | Status "Red Camp · Round 2 / 40 · Normal · Cash 532 · Fence 30 · Dinos 13 · Time left 29:19" (`ranked.png`). Settled "Battle settled (Practice Hunt): pot 15, sink 15" after Red fell in round 2 ("decided by standing"). Single-round wording "+N cash for skipped round X" confirmed in code (BattleFlow:124); the toast itself was gone before I read it. |

## Step 6 — No-trap and console
| # | Item | Result | Evidence |
|---|---|---|---|
| R7-30 | New HUD elements don't trap input | PASS | `ClockWarning` / `FinalStampede` are TextLabels, Active=false (probe); `battleLabel` sets `Active = false` (Hud:952); toasts and results lines are TextLabels; the only `Active = true` in client code are the Hunt Board and Profile boards (older, intended). Clicks/keys kept working through every banner. |
| R7-31 | Console errors | PASS | Last Play session scanned (error/warn/infinite/Stack): only Studio Assistant `VirtualInput … hits CoreGUI` traces and an Assistant camera-reset note. Spot reads of Output in the co-op and Camp Clash sessions showed no script errors either. |

## Not testable here / NEEDS JOVAN
| # | Item | Result | Why |
|---|---|---|---|
| R7-32 | A real second client joining late (Camp Clash, Bone Rush, Ranked waiting banner) | NEEDS JOVAN | Clients and Servers; the stand-in path (R7-13, 19, 22, 28) covers the rules. |
| R7-33 | Full-length 15:00 casual / 30:00 Ranked match for feel | NEEDS JOVAN | Agent can't hold a camp past ~round 25. |
| R7-34 | Ranked stakes/Trophies at a clock end (published) | NEEDS JOVAN | T95. |

## Notes for the Director / Jovan (not failures)
- **N11.** A late stand-in into a stand-in camp counts that camp as 0 hunters, so it gets the own-plot catch-up (1-hunter start cash + whole income: +1174 at round 7 vs +308 for a camp with 1 hunter). Real camps always have ≥1 hunter, so this is Studio-only.
- **N12.** A late joiner in Building after a Studio "Start at round 31" is accepted (+450, start cash only), then refused once round 31 plays. Live this can't happen (round 31 is never the first). Fine.
- **N13 (balance watch).** A leak now costs species EHP × leakX (~3×), so 2–4 left-over dinos take a full 40 Fence in about a second. In 5 of my battles every camp/plot that fell went down at the start of the next played round, all in the same step (left-overs from the 60-s round reaching the exit together), so ties past "standing" are common (Bones, damage, even a coin flip among 9 stand-ins). In one Bone Rush the late joiner (seated at round 28 with fresh Fence and no left-overs) won when the 3 original stand-ins fell together at round 31.
- **N14 (cosmetic, existing feed).** The two-line late-join toast sits top-right over the XP bar's "400 / 500 XP" text for a few seconds (`late1.png`).
- **Tooling.** `execute_luau` has its own `require` cache (stateful server modules read empty); count `workspace.StormSplitMap.Enemies` instead. Long `execute_luau` calls run in the background lose their reply when other calls interleave: print to Output and read it with `get_console_output`. Red's spawn (−100, 0) is ~40 studs from its lanes; Mortars at (−48, 0), (−20…−56, −30) cover them.

## Run 7 summary

| Area | Result | Evidence |
|---|---|---|
| Sync to 856065f | PASS | header |
| Paced co-op: "Round N / 40", fewer/tougher dinos, rounds clear, kill cash | PASS ×4 (R7-1…4) | console, `coop.png` |
| Ability tempo ×2 | PASS (code; not timed live) (R7-5) | Pace 22.5 s |
| Casual Camp Clash: rounds 1,4,7…, "+N cash for skipped rounds X–Y" | PASS ×2 (R7-6, 7) | `[W]` log |
| Match clock: "Time left m:ss", Studio short clock, "One minute left…", "Time's up! Decided by Bones" | PASS ×4 (R7-8…11) | `clockwarn.png`, `clockres.png` |
| Decided-by: standing, Bones (same-step), damage, coin flip | PASS ×3 (R7-12, 14, 26) | console |
| Final Stampede until the clock | NOT TESTABLE BY AGENT (R7-15) | — |
| Late stand-in: Camp Clash fewest-hunter camp + toast; closed after 30 | PASS ×2 (R7-13, 17) | `late1.png` |
| Bone Rush rounds 1,4,7…; late stand-in: spare plot, Bones floor, full, closed after 30 | PASS ×6 (R7-18…23) | `brlate.png` |
| Bone Rush result / end at 40 | PASS (R7-24) / PARTIAL (R7-27) | console |
| Live cap < 130 (probe) | **FAIL (major) F8** (R7-25) | probe log |
| Ranked: seats lock, rounds 2,4…, 30:00 | PASS ×2 (R7-28, 29) | `ranked.png` |
| No-trap, console | PASS ×2 (R7-30, 31) | probe, scan |
| Multi-client / full-length / published | NEEDS JOVAN ×3 (R7-32…34) | — |

**Counts:** PASS 27 · FAIL 1 (F8, major) · NOT TESTABLE BY AGENT 1 (R7-15) · PARTIAL 1 (R7-27) · NEEDS JOVAN 3 · NOT RUN 0 · notes 1 (R7-16).

## Studio state at the end
- Play stopped. `get_studio_state`: **Current Studio Mode: Edit**, DataModels: Edit. Nothing edited in Edit, nothing published, `SaveStatus=offline` in every session (J first). Remote disclosure: one `("difficulty","NORMAL")` was fired by mistake while a match was running — the handler ignores it outside the Lobby (State ≠ Lobby), so it had no effect; Normal for the probe was picked with the home button. Screenshots in `~/.claude/jobs/2a8d6f9c/tmp/tester8/`: `coop.png`, `late1.png`, `clockwarn.png`, `clockres.png`, `brlate.png`, `ranked.png`.

# Run 7b — 2026-10-12 (Tester, agent) — re-check F8, N13, #268, N14 after T103c + T105b

- **Code tested:** Studio synced to 3664152: `script_grep` "BattleFenceDrain" → Shared.Config:148 (`BattleFenceDrain = 4`), Server.Battle:155 (`drainAll`); "peak by side" → Server.Battle:500; Hud:763 `feedList.Position = UDim2.new(1, -16, 0, 88)`.
- **Start state:** Edit mode. Work files `~/.claude/jobs/2a8d6f9c/tmp/tester9/`. Conveniences as Run 7 (J first, Studio-only Lobby remotes `mode/sides/standins/startround/difficulty/standinshold/latestandin/play`, read-only Server probe `side.lua`: every 0.5 s dino models in `Enemies` by `Side` attribute, each model's first-seen time per side, Fence (`Lives*`) changes at 0.1 s).

| # | Item | Result | Evidence |
|---|---|---|---|
| R7b-1 | F8: Bone Rush, Seats 10 (9 stand-ins), Easy, Start at round 37, my plot (side 1) undefended — own side ≤ share 13 | PASS | Probe (2 runs, identical): side 1 spawns every ~1.6 s (29.2 … 48.9) until 13 live, then nothing until 65.6 (after its first leak). Per-side peaks 13 ×10; total ≤ 130 (130 reached at ~62 s with every side at 13). |
| R7b-2 | F8: other sides not delayed by mine | PASS | Sides 2–10 spawn times identical to each other (max diff 0.00 s, 36 spawns each) and kept the paced gap while side 1 was held (50.5, 52.1, 53.6 … 61.8); they waited only at their own 13 (61.8 → 80.0). Samples: 44 s `10/6/6/…` total 64, 53 s `13/10/…` 103, 57 s `13/12/…` 121, 62–80 s `13/13/…` 130. (Side 2's extra entries vs side 1 are split pieces from the stand-ins' hits.) |
| R7b-3 | F8: "Round N over" per-side peaks | PASS (see N15) | "Round 37 over \| Bone Rush, 10 sides (9 alive) \| Fences out / 2.9 / … \| peak enemies 130/130 (peak by side out/13/13/13/13/13/13/13/13/13, share 13)"; match-end line also prints: "Round 40 at the match end \| peak enemies 117/130 (peak by side out/…/out, share 13)". |
| R7b-4 | N13: battle leak drain ≤ 4/s | PASS | Max Fence loss in any 1 s window = 4.01 on every side (0.1 s sampling); stand-in Fence 14.06 → 0 in steps of ~0.4–0.47 per 0.1 s; 40 → 0 over 10 s (80.0 → 90.0, all 9 together). My plot: first below full 65.6, out at 83.2. HUD Fence drains, no jumps. |
| R7b-5 | N13: result uses final applied Fence (clock flush) | PASS | Bone Rush 4 seats, Hard, Start 28, `("clockcap",76)`: stand-ins draining at 9.80 when the clock hit → all three jumped 9.80 → 0.00 at 75.7 s (state Victory = pending flushed), then "Bone Rush over on round 28 at the clock, decided by damage: 1. Stand-in 4's Camp (17 Bones) \| 2. Stand-in 2's … \| 4. Jover_428's Camp (0 Bones)". |
| R7b-6 | N13: co-op leaks unchanged | PASS | Co-op Normal solo round 1, no towers (started with the `StartGame` remote, the Start button's own remote — my click landed on CoreGUI): Fence 30 → 27 → 19 → 16 → 8 → 5 → 0, one instant step per leak (~0.45 s apart), GameOver. No drain in co-op. |
| R7b-7 | #268: late stand-in Fence = best standing | PASS | Bone Rush 4 seats, Hard (full 20), Start 28, my plot out; fired `("latestandin")` when standing Fences were 18.3/18.3/18.3 → plot 5 at 18.2 0.3 s later (the others had drained on to 17.1); unused spare plot 6 stayed 20. Console "Joined the hunt at round 28: +50087 cash and 16 Bones". (First try fired at full Fence 20 → 20, trivial.) |
| R7b-8 | N14: feed no longer over XP text | PASS | `late7b.png`: toast "Joined the hunt at round 28 …" sits below the "200 / 500 XP" row. Probe (viewport 707×620): HeroXp.Numbers y 59–76, BattleFeed starts y 88 — no overlap. |
| R7b-9 | Console | PASS | Scanned all sessions for error/warn/attempt/infinite: only "Stack Begin/End" pairs from Studio Assistant VirtualInput (as Run 7) and the Assistant camera-reset note; no script errors. |

- **N15 (minor, log).** A side that's out by round end shows `out` in "peak by side", so the undefended side under test (which did peak at 13) loses its peak in the very log meant to show it. Printing the peak with an "(out)" mark would keep it.
- **End state:** Play stopped, Studio in Edit mode. Nothing published, no saves touched (J each session).

## Run 7b summary
F8 PASS (own side capped at 13, others undelayed, total ≤ 130, per-side peaks logged), N13 PASS (≤ 4/s drain, clock flush before ranking, co-op instant leaks unchanged), #268 PASS, N14 PASS, console clean. New: N15 (minor log wording).

# Run 8 — 2026-10-13 (Tester, agent) — Phase 9b: the A/B/C pick panel, option A only

- **Code tested:** Studio synced to cd749d2: `script_grep` "OptionPick" → Client.Shop:52 (`require(Shared:WaitForChild("OptionPick"))`); "pick one" → Client.Shop:1337 / 1365 / 1511 / 1569.
- **Start state:** Edit mode. Work files `~/.claude/jobs/2a8d6f9c/tmp/tester10/`.
- **Conveniences (disclosed):** J first every session (`SaveStatus=offline`), K cash, L (trample), keyboard/mouse input (B/E/U/H/M, clicks), `character_navigation`, read-only `execute_luau` (panel/label/attribute probes; pure `TowerStats.compute` / `HeroStats.compute` / `OptionPick.layout` calls), `StartGame` remote (the Start button's own remote; my click on it hit CoreGUI, as in Run 7b), Studio Lobby remotes `mode` TEAM / `standins` / `sides` 2. **Also:** unlocked Big Game Hunter for 75 Amber in the M panel (offline session, nothing saved) to test the hero switch-refund. Old values compared against `git show fad6140:src/shared/Config.luau` (pre-T110).

| # | Item | Result | Evidence |
|---|---|---|---|
| R8-1 | Co-op, Hunting Blind Lookout to tier 3 → tier-4 row | PASS | Row "Lookout 4: pick one · 5597 / A Watch Post" (Hardliner: "… / A Railshot"; Trigger Happy: "… / A Bullet Hose"). |
| R8-2 | Tap the row → card(s) with letter, name, blurb | PASS | One card "A · Watch Post / Sees further, and shoots faster and harder", pre-chosen (only card); header "Hunting Blind · Lookout 4: pick one", Back + X. `pick_need.png` |
| R8-3 | Confirm text: can't afford | PASS | "Need 5,597 cash for A", disabled; clicking it bought nothing (battle T5: "Need 12,873 cash for A"). |
| R8-4 | Confirm text: "Tap a card" | NOT TESTABLE (option A only) | With one card it's pre-chosen (`OptionPick.initial`); reachable only with B/C. |
| R8-5 | Cash changes keep the pick open, text updates | PASS | K ×2 with the pick open: 4299 → 5299 (still "Need …") → 6299 "Buy A — 5,597", pick stayed. |
| R8-6 | Buy A works | PASS | "Buy A — 5,597" → Path1=4, Picks1=A, Spent 4151 → 9748, toast "Watch Post!", back to the tower panel. |
| R8-7 | Tower label "4A", then "4A · 5A" | PASS | World label `4A`, panel title "Hunting Blind · 4 · 0 · 0 · 4A"; after 5A (12,873): label `4A · 5A`, title "5 · 0 · 0 · 4A · 5A", row "Lookout · maxed · Signal Tower". |
| R8-8 | Back and X work and stay visible | PASS | Back → tower panel, same rows; X on an open pick (battle, Playing) closes the panel. Both at the header (y 360) on screen in every pick opened. |
| R8-9 | Closes on trampling (L) | PASS | Pick open on T5: L once (HP drop) kept it; L again (HP 0) → panel "Trampled · repair it", rows "Repair it first". |
| R8-10 | Closes on selecting another tower | PASS (via prompt) / PARTIAL | With the pick open on tower 2, moving toward tower 1 hides tower 2's prompt and the panel closes; E on tower 1 opens its normal panel. A direct E-switch with both prompts live wasn't reproducible by agent input (OnePerButton). |
| R8-11 | Closes on a state change | NOTE (N16) | Pick open in Building, `StartGame` → State Playing: the pick stayed open (buy then worked mid-round). Code reads "state change" as a panel-mode/path change. |
| R8-12 | Crossover still blocks | PASS | 5A on Lookout, Trigger Happy 1–2 bought, then "Trigger Happy · tier 2 / locked · only one path past tier 2"; "Hardliner · tier 0 / locked · only two paths per tower". |
| R8-13 | Sell refund as before | PASS | 0.7 × Spent every time: 2905 (4151), 6823 (9748), 15834 (22621), 16897 (24139); selling the 5A tower: cash 1236 → 18133. |
| R8-14 | Stats after A = pre-change | PASS | Range ring 70 at 4A, 80 at 5A (= 20 × 1.75 / × 2 old rows, ring = diameter). `TowerStats.compute(SCOUT,{4,0,0},{"A"})` dmg 2.86, rate 5.25, range 35; `(5,"AA")` 3.71 / 6.03 / 40 = old cumulative T4/T5 (×2.86/1.75/1.75, ×3.71/2.01/2). |
| R8-15 | Hero U panel: T4 pick, 5A, T6 | PASS | Tracker Gunslinger 3 → "Gunslinger 4: pick one · 1600 / … 3/6 · A Fan the Hammer"; pick "Gunslinger 4 · pick one · Cash 16733", card "A · Fan the Hammer / Fires faster and reloads quicker", "Buy A — 1,600" → HeroPath1=4, HeroPicks1=A; T5 card "A · Akimbo Frenzy / Both guns go full-auto" "Buy A — 3,200"; T6 "Hot Swap · 6400" is a plain row (no pick) → "Gunslinger · maxed · Hot Swap". `hero_pick.png` |
| R8-16 | Hero stats after A = pre-change | PASS | `HeroStats.compute(PISTOL,{6,0,0},…,{"AA"})`: rate 8, reload 0.672, magazine 36, guns 2, staggeredReload = base 4 / 1.2 / 12 × old Hot Swap row (2, 0.56, 1.5). |
| R8-17 | Hero switch-refund before Start | PASS | Spent 12,600 on Tracker (cash 5533) → switch to Big Game Hunter → cash 18133, HeroPath1=0, HeroPicks1 cleared. |
| R8-18 | Small window | NOT TESTABLE BY AGENT | No viewport resize in the MCP tools (fixed 707×620). Read-only `OptionPick.layout`: 320×240 n1 → width 342, scale 0.84; 360×640 n3 → stacked, list 204. |
| R8-19 | Co-op rounds with picked towers | PASS | 4A Railshot bought mid-round 1; "Round 1 cleared … lives 40", "Round 2 cleared … lives 40". |
| R8-20 | Camp Clash (stand-ins) upgrade per side | PASS | My Blind (Side 1) → 4A in Building, 5A mid-round: Picks1=AA on my tower only; Blue's stand-in towers 0·0·0, no picks. "Round 1 over \| Camp Clash … Fences 40 / 40", "Round 4 over … 40 / 40". (First try: Blind at Red's spawn, out of lane range, Red fell in round 1 — placement, not the pick; same as Run 7's note.) Path 2 to 4A/5A ("Bullet Hose", "Lead Rain") in that first match also bought fine. |
| R8-21 | Console | PASS | Only Studio Assistant VirtualInput "hits CoreGUI" Stack traces and one error from my own probe (wrong child name); no game script errors. |
| R8-22 | Pick header readable | **FAIL (minor)** F9 | See below. |

### F9. The pick header's title runs under the Back button — minor (cosmetic)
- **Repro:** any tower or hero path at tier 3 → tap the "… 4: pick one" row (viewport 707×620).
- **Seen:** "Hunting Blind · Lookout 4: pick on" (the "e" under Back); hero: "Gunslinger 4 · pick one · Cash 167" (cash cut). Longer tower/path names (e.g. "Harpoon Ballista · Trigger Happy …") will lose more. `pick_need.png`, `hero_pick.png`
- **Suspected:** `src/client/Shop.client.luau` header (Title size vs Back/X, ~L244–280): title needs to end left of Back (or TextScaled/truncate with "…"), or drop "Cash N" from the hero pick title.

- **N16 (Director call).** #279 says "every state change closes the pick"; the build keeps it open across Building → Playing (only path/tower/panel changes and trampling close it). Harmless (the buy is still valid), but not what the wording suggests.
- **N17 (cosmetic).** The pick panel sits lower (header y 360) than the tower panel (y 135); its right edge goes under the "Upgrades (U)" button by a few px, and the message line sits beside the HP bar. `pick_need.png`
- **N18.** Row prices are ungrouped ("5597", "12873") while the confirm shows "5,597" — same as the rest of the panel (Sell "2905"), so only a consistency note.

## Run 8 summary
**Counts:** PASS 18 (R8-1–3, 5–10*, 12–17, 19–21; *R8-10 via prompt, direct switch partial) · FAIL 1 (F9 minor) · NOT TESTABLE 2 (R8-4 "Tap a card" until B/C; R8-18 small window) · NOTE 1 (R8-11 → N16). Studio left in **Edit mode** (Play stopped, `get_studio_state`: Edit); nothing edited in Edit, nothing published, saves offline every session. Screenshots: `pick_need.png`, `hero_pick.png`, `hsel.png` in tester10.

# Run 9 — 2026-10-14 (Tester, agent) — Phase 9c–9f: B/C options on 11 towers + 4 heroes

- **Code tested:** Studio synced to 168ee78: `script_grep` "Heal regen" → Shared.HeroStats:75, Shared.Combat:182, Server.Hero:141/1066; "Alpha Spotter" → Shared.Config:932/1214/1496; "standinpick" → Shared.StudioOnly:20/69, Server.Main:84/281/283.
- **Start state:** Edit mode. Work files `~/.claude/jobs/2a8d6f9c/tmp/tester11/` (helpers copied from tester10).
- **Conveniences (disclosed):** J first every session (`SaveStatus=offline`); J ×21 (+100 Amber each) then unlocked all 3 heroes and 8 towers in the M panel (one accidental Big Game Hunter mastery 1 buy, offline, harmless); K cash; E/B/U/H/M keys + clicks; `character_navigation`; read-only `execute_luau` probes (panel text, tower attributes, dino state; labelled "probe"). The camera always looks −Z, so I stand +5 Z of a tower to get its prompt.
- **Session 1:** Co-op, Easy, solo, round 1 Building. 14 towers placed: Blind (−45,3), Perch (−30,0), Mortar ×2 (−15,0 / −1,1), Tranq (14,0), Supply (29,0), Hospital (44,3), Armory (−45,−30), Coil ×2 (−31,−30 / −16,−30), Falcon (−1,−30), Ballista (15,−30), Tar Pit ×2 on the track (29,−16 / 29,−44).

| # | Item | Result | Evidence |
|---|---|---|---|
| R9-1 | Tier-4 pick with three real cards, "Tap a card" | PASS | Blind Lookout 3 → row "Lookout 4: pick one · 5597 / one of: A Watch Post / B Signal Mirror / C Spotter's Call"; pick: cards "A · Watch Post / Sees further, and shoots faster and harder", "B · Signal Mirror / Towers in range fire 18% faster", "C · Spotter's Call / Its target takes +15% from every tower"; Confirm "Tap a card · 5,597" disabled. `pick3.png` |
| R9-2 | Pick B → "Buy B — 5,597" → bought | PASS | Confirm "Buy B — 5,597" enabled; bought → title "Hunting Blind · 4 · 0 · 0 · 4B", world label `4B`, toast "Signal Mirror!", cash 9799 → 4202. |
| R9-3 | Tier-5 pick independent of tier 4; label "4B · 5C" | PASS | After 4B the tier-5 cards are A Signal Tower / B Beacon Fire / C Alpha Spotter ("Bosses in range take +40% from everything"); bought C (12,873) → title "5 · 0 · 0 · 4B · 5C", label `4B · 5C`, row "Lookout · maxed · Alpha Spotter". |
| R9-4 | F9 re-check (header) | PASS | Long title now ends "Hunting Blind · Lookout 4: pick…" left of Back (ellipsis, no overlap). `pick3.png` |
| R9-5 | B/C bought on every tower (UI: row → card → Buy) | PASS | Perch Spotter 4C Quick Spot → 5B Spotter Network; Mortar ①Cluster 4B Fire Bomblets → 5B Firecracker Rain, ②Concussive 4C Armour Splitter → 5C Rockfall; Tranq Sedate 4C Sleeper Darts → 5B Fog Bank; Supply Yield 4C Bounty Board → 5B Gold Reserve; Hospital Tonic 4C Bitter Tonic → 5B Adrenaline; Armory Outfitter 4B Loading Bench → 5C Steady Aim; Coil ①Arc 4C Chain Surge → 5B Storm Front, ②Charge 4C Static Storm → 5B Superconductor; Falcon ①Talons 4B Raking Strike → 5C Hide Ripper, ②Flock 4C Second Flock → 5C Strafing Run; Ballista Spearhead 4B Serrated Head → 5C Heartseeker; Tar Pit ①Deep Tar 4C Bog Boots → 5B La Brea, ②Bubbling 4C Pitch Coat → 5B Ever-Burn. Every toast = option name, every title ends "4X · 5Y". (Disclosed slip: one extra Concussive 1 on Mortar ① while re-approaching it.) "Need 35,400 cash for B" shown when short (Mortar 5B), buy after K. |
| R9-6 | Composed stats match the cards (probe: pure `TowerStats.compute`, tier-3 build vs bought build) | PASS | Blind 4B·5C: auraRate 10→18 %, bossMark 0→40 %; Perch: mark 25→45, aura dmg 0→15; Mortar① bombletGenerations 2→3, bomblet burn 2 dps 2 s; Mortar② stripsOnHit, stunsBosses, stun 0.5; Tranq raider slow 30 %/2 s; Supply bountyCash 8 (4C kept under 5B); Hospital biterSlow 25 %/2 s; Armory hunterReload ×0.65→0.455, spread ×0.8; Coil① fieldStrike every 8 s ×0.5; Coil② chainEffects, pierces; Falcon① targets 1→2 (Raking); Falcon② lineHits 1→3 (Strafing); Ballista targetsBiggest; Tar① sink 0.5→0.05 s (La Brea), raider slow 30 %; Tar② stripsArmor (Pitch Coat). |
| R9-7 | Crossover rule | PASS | Blind 5·2·0: "Trigger Happy · tier 2 / locked · only one path past tier 2", "Hardliner · tier 0 / locked · only two paths per tower". |
| R9-8 | Selling refunds 0.7 × Spent | PASS | Blind 5·2 "Sell for 16897" (= 0.7 × 24139); Falcon② 4C·5C Spent 45242 → "Sell for 31669", cash 322285 → 353963 (+31669 + a kill). |
| R9-9 | Hero path through B at T4/T5, then T6 — Field Medic (Heal regen) | PASS (cards/buys) · first-person NOT TESTABLE BY AGENT | Picked Field Medic (H) mid-match; U → "Triage 4 · pick one · Cash …" cards A Triage Tent / B Thick Gauze ("heals 55% more") / C Quick Kit, "Tap a card · 1,600" → B; T5 cards A Second Wind / **B Mending Salve "Everything healed regains 2 HP/s for 8 s"** / C Field Surgeon → B (3,200); T6 plain row "Rapid Response · 6400 / Triage · 5/6 · the ability holds 2 charges" → "Triage · maxed · Rapid Response 6/6"; HeroPath1=6, HeroPicks1=BB, AbilityMaxCharges=2. Probe (pure `HeroStats.compute("MEDIC",{6,0,0},…,{"BB"})` vs tier 3): heal 50→77.5, healRegen 0→2, healRegenSeconds 0→8, abilityCharges 1→2. **Not testable:** the gun sits in the Backpack and can't be equipped by agent input ("1" is CoreGUI-bound, no hotbar shown), and `useAbility` needs it equipped, so F does nothing — the regen tick itself (tower 102.5/205 after L, unchanged after F) wasn't seen (see N19). |
| R9-10 | Mortar Firecracker Rain (4B Fire Bomblets → 5B): ≤ 6 fires per shell | PASS | Second Cluster 4B·5B Mortar at (−61,−30) near spawn. Probe (Effects folder, burn-coloured discs grouped per shell): every shell = **6** discs r 3.0 (bomblet fires) + 1 r 6.0 (the shell's own burn); pure `Combat.bombletFires(6,3,6)` = 6,0,0 (first generation first); Tuning `BombletFiresPerShell` = 6. |
| R9-11 | Supply Camp Bounty cash | PASS | Supply Yield 4C·5C (Bounty Hall, 25) at (−72,−30). Probe (cash delta at each dino removal): Ankylosaurus taken down in range +99/+100, out of range (−26,−45) +75 → +25 bounty, once (Easy). The 4C·5B camp at (29,0) never saw a take-down (everything dies near spawn). |
| R9-12 | Storm Coil Storm Front (field strike) | PASS | Probe: field-strike tracers every ~8 s (9.8, 17.8, 33.8 s; 13, 21, 37 s) at x −66…−79, z −45 — 35–50 studs from the coil at (−31,−30), outside its range. |
| R9-13 | Ballista Heartseeker (targets biggest) | PARTIAL | Probe: 31+ harpoons in 35 s; every one with a living target ended on an Ankylosaurus or a Triceratops (boss) — the biggest kinds on the field — but no sample had a mixed bunch inside 60 studs, so "biggest over a closer small one" wasn't isolated. Compute: targetsBiggest false→true. |
| R9-14 | Strip time: armoured 3 s, bosses 1.5 s | PASS (pure probe) | `Combat.stripSeconds(Tuning.StripS=3, false)` = 3, `(3, true)` = 1.5. Live strip state is server-private (not on the dino model), so a stripped Ankylosaurus taking damage from a non-piercing tower can't be read by a probe. |
| R9-15 | Rockfall boss stun, Superconductor never a boss, Bitter Tonic biter slow, Falcon Raking/Strafing, Tar La Brea/Pitch Coat, Tranq Fog Bank, Armory Loading Bench (in play) | NOT TESTABLE BY AGENT (live) · compute PASS (R9-6) | On Easy the Perch (global) + field strikes kill every dino within ~45 studs of the spawn, so these towers never engaged, and stun/slow/strip/sink state isn't exposed on dino models. Build stats match the cards (R9-6). |
| R9-16 | Live Rockfall / Superconductor on bosses (after selling Perch, Falcon①, Coil① and the spawn-side three so dinos walk) | INCONCLUSIVE (note) | Rounds 36–40 probe (boss positions every 0.1 s): 28 Triceratops/T-Rex seen, **no** boss stalled ≥ 0.25 s; all died on lane z −45 at x −10…30 (Coil② Superconductor, Ballista, Tar②) — consistent with "Superconductor never stuns a boss", but the Rockfall Mortar (−1,1) never reached a boss. Co-op Easy cleared round 40 ("VICTORY — all rounds cleared"). |
| R9-17 | Tracker: Gunslinger 4C → 5B → T6 | PASS (cards/buys/stats) | Battle Building: cards B Deep Cylinders / C Crossdraw ("Reload 35% faster, fire 15% faster") → C; T5 B Twin Burst ("Each click fires a 3-round burst, 30% faster") → B; T6 "Hot Swap · 6400 … the guns reload one at a time" → "Gunslinger · maxed · Hot Swap 6/6"; HeroPicks1=CB. Pure compute vs T3: burstCount 1→3, fireMode semi→burst, staggeredReload →true, reload 1.02→0.53 (guns 2 from T3). |
| R9-18 | Big Game Hunter: Stalker 4B → 5C → T6 | PASS (cards/buys/stats) | Cards B Snap Bursts / C Quick Mag → B; T5 B Marking Burst / C Rapid Volley ("Bursts 35% faster, half the kick, bigger mag") → C; T6 "Big Five · 6400 · 5-round burst · recoil resets between bursts" → maxed. Compute: burstCount 3→5, burstRecoilReset true, recoil ×0.5, mag 30→45. |
| R9-19 | Raider sting rules (probe: pure `TowerPerks.sting`, Armory 4C Barbed Wire + Tranq 4C Sleeper Darts as sources) | PASS | Enemy hunter: dmg 10 × 0.5 = **5.00**, slow 30 % for 2 s; under Camo Cover: none; 1 s later: none; 3.1 s later: stung again (cooldown 3 s); same side (co-op/teammate): none. Tranq 4C still slows dinos 72 % (compute). |
| R9-20 | `standinpick` mid-battle | PASS with F10 | Camp Clash, 2 camps, stand-ins, Easy, start round 1: `("standinpick","Tranq Station Sedate C")` / `("…","Armory Plating C")` → Output "standinpick Tranq Station Sedate C: 1 stand-in tower(s) set" (and Armory); the stand-in towers' world labels read `4C`. |
| R9-21 | Raider sting live: shoot a `standinpick` tower, get stung (×0.5 + slow), none through Camo Cover | NOT TESTABLE BY AGENT | Stings only come from a **hunter's gun hit** (`Towers.damage` with a Player source); L's hit has source "studio". The hero gun can't be equipped by agent input (see N19), so I can't shoot. Rules covered by R9-19. |
| R9-22 | First-person hero effects (Twin Burst 3 per click, Big Five, Mending Salve regen tick, Bird Shot, Slam Fire) | NOT TESTABLE BY AGENT | Same cause (N19). Stats via compute (R9-9/17/18). |
| R9-23 | Hero switch before Start keeps the refund | NOT RE-RUN | The battle Building timer ran out mid-test; R8-17 passed and no code path changed for it. |

### F10. `standinpick` sets the stand-in tower's build but not its Path/Picks attributes — minor (Studio-only test tool)
- **Repro:** Camp Clash with stand-ins → mid-battle Lobby `("standinpick","Tranq Station Sedate C")` → walk to the Blue camp's Tranq Station, E (Inspect).
- **Seen:** world label `4C`, but Inspect panel title "Tranq Station · 0 · 0 · 0", and Body attributes `Path1=0`, `Picks1=""` (same for the Armory). A Tester can't confirm the pick from the panel, and anything reading the attributes (Inspect, label refresh on next render) disagrees with the server's build.
- **Suspected:** `src/server/Towers.luau` `setPicksForStandIn` (~L713) calls `Towers.upgrade` directly; the `Path{i}`/`Picks{i}` attributes are only published by `src/server/Shop.luau` (~L75) on a player purchase — publish them here too.

- **N19 (blocks agent tests).** The hero gun sits in the Backpack and the agent can't equip it: VirtualInput refuses "1" ("permanently bound to a CoreGUI core action") and clicks on the hotbar hit CoreGUI; F/`useAbility` and shooting need it equipped. A Studio-only "equip the hero gun" key (like K/J/L) would let the Tester do the hero first-person and Raider-sting steps; otherwise these need Jovan.
- **N20 (cosmetic).** In co-op Building the tower panel (lower half) overlaps the "Choose hero (H)" / "Unlocks & Mastery (M)" HUD buttons. `pick3.png`
- **N21 (setup note).** The tower panel's Sell row can sit below the list's visible area (y ≈ 505 with 3 path rows + HP + Repair) and isn't clickable until the list is scrolled; normal scroll UI, noted because it looks clickable.

_Run 9 was cut off by a usage limit after R9-23; the coordinator stopped Play (Studio back in Edit mode). Counts as recorded: 17 PASS (incl. cards/buys/stats), 1 PARTIAL, 1 INCONCLUSIVE, 2 NOT TESTABLE, 1 NOT RE-RUN; F10 minor; notes N19–N21._

# Run 10 — 2026-10-15 (Tester, agent) — Phase 9g–9j: the seven new towers

- **Code tested:** Studio synced to 9223192 (F11 fix): `script_grep` "PLAYTEST F11" → 4 `do -- block-scoped locals …` blocks in Server.Towers (L1396/2010/3072/3530); probe of the Edit-mode source: 142 top-level `local` lines (was 222). "firenow RANGER" → Server.Towers:1686.
- **Start state:** Edit mode. Work files `~/.claude/jobs/2a8d6f9c/tmp/tester13/` (helpers copied from tester12).
- **Conveniences (disclosed):** J first every session (`SaveStatus=offline`), J for Amber + M-panel unlocks (offline, nothing saved), K cash, L, keyboard/mouse, `character_navigation`, read-only `execute_luau` probes (labelled "probe"), Studio Lobby remotes (`standins`, `startround`, `standinshold`, `clockcap`, `latestandin`, `standinpick`, `firenow <TOWER>`).

| # | Item | Result | Evidence |
|---|---|---|---|
| R10-1 | Play starts (server boots) — F11 re-check | PASS (F11 fixed in 9223192) | Play → `ReplicatedStorage.Remotes` exists, State=Lobby, home screen (Dino Hunters / Co-op · Camp Clash · Bone Rush / PLAY) shows; client ScreenGuis Shop/Hud/Hero/Home enabled; console: only the usual `[Progression] No data store…` / `[LevelBoard]` notes, **no** "Out of local registers", no Infinite yield. `boot.png` |
| R10-2 | Unlock the seven (M panel) | PASS | J ×40 → 4000 Amber (offline); M → Amber Resin Cannon / Raptor Pen / Bone Totem / Spotter Blimp / Meteor Beacon / Volcano Vent / Ranger Station each "· unlock · N amber" → "· owned" (total 3550: 4000 → 450). |
| R10-3 | Place each (Build list, walk closer, click) | PASS | All seven placed in co-op Building: Resin (−45,−30) 800, Raptor (−20,−30) 600, Totem (5,−30) 600, Ranger (25,−30) 600, Vent (−50,−37, 9 studs from lane 1) 600, Meteor (0,0) 600, Blimp mast (30,0) 600. Placing too far gives "Too far from you — walk closer". Ranger placement opens "Posts · Ranger Station / Posts go on the track" at once. A raptor walker appears at the pen and a ranger walks to a default post on lane 3 (24,−15). |
| (setup) | First co-op match accidentally at round 10 | note | `StudioStartRound` was 10 (a stray helper click on the home "Start at round" button during the M-panel unlocks); co-op Normal from round 10 with seven tier-0 towers → GAME OVER in round 10, no errors. Restarted with Lobby `("startround",1)`. Start button click lands on CoreGUI at this viewport, so rounds are started with the button's own `StartGame` remote (as R7b-6). |
| R10-4 | Each tower to tier 3 + a T4 and T5 card (UI: E on the tower → path row ×3 → "pick one" → card → Buy) | PASS | Titles/toasts: Resin "5·0·0 · 4B·5A" Amber Age!; Raptor "4C·5A" Raptor Swarm!; Totem "4A·5B" Skull Storm!; Blimp "4B·5B" Bombing Run!; Meteor "4A·5A" Extinction Event!; Vent "4C·5A" Supervolcano!; Ranger "4B·5A" Ranger Troop!. Row reads "<path> · maxed · <T5 name>". K cash used. |
| R10-5 | Composed stats match the cards (probe: `TowerStats.compute` bought vs tier 3) | PASS | Resin entombSpread 0→1 (Spreading Amber), entombAllEvery 0→12 (Amber Age "every 12 s"); Raptor firstDiveX 1→2 (Ambush), swarm →true; Totem roarEchoes 0→1 (Echo Roar), skulls 0→8 (Skull Storm); Blimp bomblets 0→3 + 1 generation (Rocket Pods), bombingRun →true; Meteor sizeBreaks 2→3, bossMult 1→2 (Planet Killer), extinction →true; Vent hitsAir →true (Ember Rain), supervolcano →true; Ranger heavyRanger →true (Heavy Rifle), walkers 3→5 (Ranger Troop). `walkers` aid: 5 raptors at the pen (105 HP), 5 rangers at posts 206/104/192. |
| R10-6 | Co-op Normal with all seven at T5 (cards as R10-4) — matches 2 and 3 | NOTE (N22), not a bug | Rounds 1–7 / 7–9 cleared (Output each round: lives 30, peak enemies 2–3, script cost avg 0.47–0.79 ms, worst ≤ 7.7 ms; Studio Heartbeat avg 16.7 ms, max 19 ms, 10 walkers out). Then Lives **30 → 0 in one step** → `GAME OVER on round 8` (match 2) / `round 10` (matches 3 and 4). Probe (Lives changed + enemies removed at the exit) in match 4, round 10: `lives 30->0` the instant an **ARMOR** dino reached the exit (−79,45), two more ARMOR behind it. My build had no armour-piercing option (only Thunder Roar pierces), so armoured dinos walked through untouched — a build gap, not a bug; but see N22. No script errors. |
| R10-7 | Co-op Normal to round 20+ with one of each (match 5: start round 12, all T5 with armour-piercing cards: Resin 4A·5B, Raptor 4A·5A, Totem 4C·5A, Blimp 4A·5A, Meteor 4B·5A, Vent 4A·5A, Ranger 4A·5B) | PASS | Rounds 12 → 21 cleared, Lives 30 throughout; Output round 20: peak enemies 9, script cost avg 0.60 ms worst 4.47 ms; round 21: peak 11. Probe per ~55 s window: Studio Heartbeat avg 16.7 ms, max 19–21 ms; max 18 walkers out (8 between raptor trips). Compute diffs matched every card (e.g. Raptor/Vent/Meteor/Ranger/Blimp piercesArmor →true, Totem roarWholeTrack + stripsArmor, Resin entombAmpPercent 0→30 + bossEntombSeconds 3, Blimp shots 2→4 + blimpSpeedMult 1.5, Ranger legend →true). |
| R10-8 | `walkers` aid at the peak (round 21) | PASS | Output lists every walker: Raptor Swarm `RAPTOR swarm#30 walker 1…10` (42 HP), the pen's 5 raptors (105 HP), Ranger Station's 3 rangers at posts 206/104/192 (Legend 421/525 HP). |
| R10-9 | `firenow` per tower (Studio aid) | PASS | Output: `firenow RAPTOR: Raptor Swarm`, `TOTEM: full charge`, `METEOR: Extinction Event`, `VENT: eruption, Supervolcano`, `RANGER: Tracking Dart` (the Legend's dart); `RESIN:` and `BLIMP:` empty — correct, Living Amber and Gunship have no timed effect. |
| R10-10 | Ranger posts: Move posts → set 3 posts by clicking the track | PASS | E on the station → "Move posts · 3 on the track" (sits below the list's visible area until scrolled, as N21) → title "Posts · Ranger Station", rows "Post 1 of 3 · click the track to place it" / "Post 2 of 3 · placed · tap to move" / … / "Done (Q)". Probe: `Placing=true`, MouseBehavior Default (cursor free), camera 12 studs back (third person). Hint reads "Click or tap the track for post 1 · Q to stop" over the track, "Posts go on the track" off it. Three clicks → `Posts` 206,104,192 → **89.8, 120.3, 84.6**; after the 3rd the panel returns to the tower panel, `Placing=false`, camera 0.5 (first person). `walkers`: rangers walk to 89/120 and one at 88 → post 84. A click under the "Choose hero (H)" HUD button doesn't set a post (the button eats it) — see N23. |
| R10-11 | Posts mode closes when the cabin is Trampled; Repair; Move posts hidden while Trampled | PASS | In posts mode, L ×2 at the cabin → HP 0 → posts rows gone, back to the tower panel "HP 0 / 350 · Repair 20359 · Trackers/Wardens — Repair it first", no Move posts row; Repair → "Repaired for 20359", Move posts back. |
| R10-12 | Posts mode "closes on taking damage" (#350 / T131 step 5) | NOT TESTED | T131 isn't in the synced build (git: 9223192 follows the Run-10 design commit; no T131 commit), and nothing hit the hunter in 30 s of posts mode (probe: Humanoid.Health unchanged). |
| R10-13 | Gun comes back after posts | NOT TESTABLE BY AGENT | No hero chosen in this co-op (the hero gun can't be used by the agent, N19); `Placing` returns false correctly. |
| R10-14 | Who can be damaged (L = Studio tower hit) | PASS | Ranger cabin: 332 → 156 → 0 (Trampled), Repair works. Volcano Vent: already Trampled by dinos during rounds 20–23 (HP 0, KO true), Repair → 350/350. Spotter Blimp mast: L → HP attribute stays 0, KO false (no HP, untouchable). Falcon / Tar Pit not placed this run (unchanged since Run 9). |
| R10-15 | Walker cap per side (probe): Raptor Swarm + 2 Raptor Packs + Ranger Troop on one side | PASS (cap) · cap message NOT BUILT | Added 2 Raptor Pens (Pack 3 · Pack of Five) and a 2nd Ranger Station (Riflemen 4C Flare Rounds · 5A Ranger Troop). `firenow RAPTOR` → "Raptor Swarm", `walkers`: pen 5 + 5 + 5 raptors, Legend station 3 + Troop 5 rangers = 23, swarm got **1** (10 asked) → **24 = WalkerCapPerSide**. No errors. The "N of M — side's walker cap" panel line is T131 step 5 (not built yet), so there is no cap message to see. |

### F11. Server.Towers no longer compiles: more than 200 top-level locals — critical — **FIXED in 9223192**
- Run 10 first attempt (59f2d54): Play → `Server.Towers:3697: Out of local registers … exceeded limit 200`, no Remotes, nothing reachable. 9223192 moved the per-tower sections into `do` blocks and added `tools/compile.luau`; re-checked R10-1 above: boots cleanly.

- **N22 (Director call).** One armoured dino reaching the exit on Normal round 10 costs the whole 30-life Fence (`Enemies.leakCost` = ⌈effectiveHp × size share × leakX⌉; round 10 effectiveHp 385). With seven non-piercing 4× towers (all T5) the match ends on the first ARMOR leak with no warning; worth checking against the "Fence drains" feel (R7b-6 saw 30 → 27 for small leaks).
- **N23 (minor, UX).** In co-op (no hero chosen) the "Choose hero (H)" HUD button sits mid-screen and covers part of the track in posts mode; a click there opens nothing for the posts and doesn't set a post. Clicking beside it works.

_Run 10 was cut off by the weekly usage limit after R10-15; the coordinator stopped Play (Studio back in Edit mode). Boot fix confirmed; all seven towers placed, upgraded with B/C cards, composed stats match, Studio aids work, walker cap holds. Open: N22 (leak cost on Normal), N23, T131 not yet built._

# Run 10b — 2026-10-20 (Tester, agent) — T131 re-check (N22, N23, R10-12, R10-15)

- **Code tested:** Studio synced to c9f9c4f: `script_grep` "coopLeak" → Pace.coopLeak (Pace:108/112, `CoOpLeakCapShare = 0.25` Config:254) and Main:142 non-battle onLeak.
- **Conveniences (disclosed):** same as Run 10 (J offline/Amber, K cash, L, navigation, read-only probes, Studio Lobby remotes). Work files `~/.claude/jobs/2a8d6f9c/tmp/tester14/`.

| # | Item | Result | Evidence |
|---|---|---|---|
| R10b-1 | Play starts (server boots) | PASS | Play → Remotes exist, State=Lobby; console only the usual `[Progression]` / `[LevelBoard]` notes. |
| R10b-2 | N23 while placing (Build → Hunting Blind row) | PASS | Probe: Building, before: ChooseHero / Mastery visible; placing (`Placing=true`): both hidden; Q: both back. |
| R10b-3 | N22 co-op Normal, non-boss armoured leak capped at 8 (start round 10; 4 Mortar Pits + 2 Hunting Blinds, no pierce) | PASS | Leak probe, round 10: `LLAMA` leak 30→22, then `ARMOR` leaks 22→14 and 14→6 (each exactly 8 = ⌈30×0.25⌉; Run 10 saw 30→0 on one ARMOR). Heartbeat 16.7/19 ms. |
| R10b-4 | N22 boss leak still in full | PARTIAL — gameplay NOT REACHED; probe PASS | First boss (Triceratops ZEP ×1) is round 31 behind 26 ARMOR + 16 BRUTE + …; with a defence that lets it through, the 8-per-leak non-bosses end the Fence first, so a live boss leak wasn't reachable. Read-only probe of `Pace.coopLeak` in Play: (48,no,30)=8, (5,no,30)=5, **(48,yes,30)=48**, (48,no,40)=10, (1,no,10)=1 — all match the T131 spec; Main:142 passes `enemy.def.boss == true`. |
| R10b-5 | Battles unchanged (Camp Clash, 2 camps, Easy, stand-ins, start round 10, my side undefended) | PASS | Probe of `Lives` every 0.1 s: leaks drain gradually, e.g. 18.66 → 10.33 in 2.08 s (= 4.0/s), plateaus at whole numbers between leak batches (22, 19); a 30→22-style cap does not apply. Stand-in side `Lives2` 40 untouched. |
| (setup) | Co-op Easy, start round 1: 3 Raptor Pens + Ranger Station (M-panel unlocks with J Amber, offline) | note | Pen 1 Pack 5·0·0 4C·5A (Raptor Swarm), pens 2–3 Pack 3 (Pack of Five), Ranger Riflemen 4C·5A (Ranger Troop); K cash. Harness artifact (not a game bug): an `execute_luau` call that waited across the Lobby→match switch made Studio's Assistant reset the camera to Scriptable ("The execute_luau changed camera type…"), freezing the view; fixed by stop/restart Play and not waiting inside that call. |
| R10b-6 | R10-15 walker-cap line | PASS | Round 1–2, `walkers` probe: 20–24 out (Ranger 5, Raptor 15+); E on the Swarm pen → row **"9 of 15 out · side's walker cap 24"** (disabled row, under Pack/Alpha/Trainer; scroll to see); Pack-3 pens and the Troop station (all out) show no line; no toast. `capline.png` |
| R10b-7 | N23 posts mode + R10-12 camera | PASS | E on station → scroll → Move posts → "Posts · Ranger Station": ChooseHero hidden (`Placing=true`), camera 12.0 studs back, MouseBehavior Default (= placing). (Mastery is hidden in Playing anyway — see R10b-8.) |
| R10b-8 | R10-12 posts mode closes on taking damage | PASS | In posts mode, walked onto lane 1 ahead of HUSKs: first bite 100→98 at 5.6 s → `Placing` true→false the same tick, panel closed, ChooseHero back; further bites (→86) changed nothing else. |
| R10b-9 | N23 posts mode in Building (both buttons), back on Done (Q) | PASS | New co-op (Play restarted; J Amber offline, Ranger unlocked), Building: before both visible; E → Move posts → posts mode: ChooseHero **and** Unlocks & Mastery hidden; Q → both back, `Placing=false`. `postsB.png` |
| R10b-10 | Quick co-op round regression | PASS | Co-op Easy with 3 pens + station: rounds 1 → 8 auto-advance, Fence 40 throughout, no stalls. |
| R10b-11 | Console | PASS | No game script errors in any match; only `[Progression]`/`[LevelBoard]` notes and Studio Assistant messages (navigation "Infinite yield … Humanoid" during respawn, camera-type resets — tool-side). |

- **Studio state at the end:** Play stopped; Studio in Edit mode. Nothing published, no saves touched.

# Run 11 — 2026-10-21 (Tester, agent) — Phase 10a + 10b (Big Amber, hunter bodies, melee V, grenade C)

- **Code tested:** Studio synced to 8f63f9e: `script_grep` "Dozy Cloud" → Config:183990 + Shared.Grenade:3; "formatAmber" → Theme:27, Hud:385, Shop:1748, Home:172/449, PanelRules:275. **T137b (#400–#402: kit raids towers, effects on armoured ground dinos) is NOT in this build** (git tip 8f63f9e) — its steps are recorded against T137 as built.
- **Start state:** Edit mode. Work files `~/.claude/jobs/2a8d6f9c/tmp/tester15/` (helpers copied from tester14).
- **Conveniences (disclosed):** J first (`SaveStatus=offline`), J for Amber (offline, nothing saved), K cash, L, V/C, keyboard/mouse, `character_navigation`, read-only `execute_luau` probes (labelled "probe"), Studio Lobby remotes as Run 10.

| # | Item | Result | Evidence |
|---|---|---|---|
| R11-1 | Play starts (server boots) | PASS | Play → State=Lobby, home screen; console only the usual `[Progression]` / `[LevelBoard]` notes. |
| R11-2 | J's Amber grant ×1000 | PASS | J → `Cores` 0→100000 → 200000 (+100K each, `SaveStatus=offline`); home "200K Amber · Hero: none yet (H)", Hunt Board header "200K Amber". J has no toast (by design, Hud:579 comment "+100K Amber"). |
| R11-3 | K/M/B on home, Hunt Board, Unlocks, Ranked fee | PASS | Home difficulty buttons "clear: 50K / 100K / 150K / 200K amber"; Ranked line "Entry fee: 15K Amber · You have 100K Amber"; Hunt Board Haul days +5K/+5K/+10K/+10K/+15K/+15K/+40K, bounties +10K/+15K/+20K/+40K; Unlocks title "200K Amber", rows "Big Game Hunter · unlock · 75K amber", "Tranq Station 100K", "Storm Coil 300K", "Falcon Roost 200K", "Amber Resin Cannon · unlock · 500K amber", "Raptor Pen 500K" (4× tower 500K ✓), mastery "25K amber". `home.png` |
| R11-4 | Unlock 3 hunters (M) | PASS | Three "unlocked!" messages; Amber 400K → 250K → 175K (75K each). Setup note: one helper click landed on the home "Start at round" button behind the panel (→ round 30, as in Run 10); reset with Lobby `("startround",1)`. |
| R11-5 | Hunter bodies: max HP / walk speed per hunter (probe of the client Humanoid after each pick, co-op Building) | PASS | Tracker 95/95 ws 17.00; Big Game Hunter 110/110 ws 15.00; Brush Beater 115/115 ws 15.50; Field Medic 100/100 ws 16.50 (= Config HunterStats; switching hero mid-Building re-applies at once). |
| R11-6 | N19 workaround: gun equipped by a client `Humanoid:EquipTool(Backpack tool)` (setup aid, disclosed — not read-only) | PASS (aid works) | Server sees `Lever-Action Carbine` on the character; HUD kit buttons appear only with the gun out: "Splint Stick (V)" / "Dozy Cloud (C)". |
| (setup) | Undefended co-op Easy round 1 = GAME OVER in ~1 min | note | Lives 40 → 0 on round 1 with no towers (twice); not a bug. Tests run in short matches. A camera aid (client RenderStepped pointing the camera at the nearest dino within 25 studs; camera only) stands in for mouse aim; observers are read-only `_G` loggers (HeroKit hit marker, MeleeReadyAt/GrenadeFullAt, Effects parts, dino speed every 0.5 s). Server `require` of `Server.Enemies` from execute_luau gets a fresh module copy (live=0), so dino HP isn't readable — damage is judged by hit markers, take-downs and cash. |
| R11-7 | Medic melee (V, Splint Stick) | PASS | Standing on lane 2, V every 0.7 s: `MeleeReadyAt` +0.56–0.58 s per swing (swing time 0.6), white swing flash; in reach → `HeroKit hit false/true`; HUSK taken down in one hit (+cash 450→456); out of reach → no marker. BRUTE speed after a hit 16.8 → 11.8 (= −30 %, Splint slow), back to 15–17 after ~1.5 s. |
| R11-8 | Medic grenade (C, Dozy Cloud) | PASS | Ball → bursts at (16,0,−16) as a 20-stud disc (Splash 10), 2 HUSKs gone + hit marker; cloud stays ~5 s: HUSKs walking through it 14.9 → 8.4 (≈ −40 %); `GrenadeFullAt` +19.97; HUD "Dozy Cloud 18s" → "8s" → "(C)". |

_Run 11 stalled after R11-8 (agent stream watchdog); the coordinator stopped Play. The remaining 10b items (other hunters' melee/grenades, PvP in a battle, co-op regression) move to Run 12 after T137b + 10c. Note: the EquipTool workaround now equips the hero gun (N19 solved for agents)._
