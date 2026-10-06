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

# Run 2 — 2026-10-06 (Tester, agent) — BLOCKED: Studio holds stale code

- **Target:** main at `1cf3d2a` (includes `e9b0d00`, the F1–F3 fixes).
- **Sync check (read-only, Edit mode):** the fixed code isn't in Studio, so none of the Run 2 tests were run.
  - No script in the Studio DataModel contains `hpBarVisible` or `repairRow`. I scanned every `LuaSourceContainer.Source` with `execute_luau`, and `script_grep` found nothing either.
  - In the repo, `src/client/Hud.client.luau:476` uses `PanelRules.hpBarVisible`, and `src/client/Shop.client.luau:1350` uses `PanelRules.repairRow`.
  - The sizes don't match. `StarterPlayerScripts.Client.Hud` is 21547 bytes in Studio and 22237 in the repo. `ReplicatedStorage.Shared.PanelRules` is 3362 bytes in Studio and 4207 in the repo.
  - `rojo serve` (7.7.0, pid 14590) is running on this Mac, so Studio's Rojo plugin is probably disconnected or was never reconnected after the restart.
- **Action for Jovan / Director:** in Studio, open the Rojo plugin and press **Connect**, and check that the `PanelRules` size matches the repo. Then re-run Run 2: F1–F3 re-test, bounty claim, Field Medic, Supply Camp, Chaos, hero tier 6, mastery 6–9, Profile colour, and the probes.
- **Studio state:** I never entered Play. Studio was in **Edit** mode before and after, and nothing was changed.

| # | Area | Result | Evidence |
|---|---|---|---|
| R2-0 | Studio has e9b0d00 | **FAIL (blocker, environment)** | `hpBarVisible`/`repairRow` are absent, and the Hud and PanelRules byte sizes differ from the repo |
| R2-1…R2-n | All Run 2 items | NOT RUN | Blocked by R2-0 |
