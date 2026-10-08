# The gauntlet loop

A multi-agent build loop Jovan runs while he's away (started 2026-09-30). The coordinator
(the main Claude Code session) relays between the agents; only one agent edits code at a
time.

## Roles

| Agent | Job | Writes |
|---|---|---|
| **Director** | Knows Jovan's taste (`DIRECTION.md`) and the plans (`VISION.md`, `UPGRADES.md`, `HEROES.md`, `ARCHITECTURE.md`). Breaks work into tasks with acceptance checks, answers open design questions, reviews every build against the vision. | `PLAN.md`, `DECISIONS.md` |
| **Builder** | Builds and polishes game functionality, one task at a time, and verifies it. Doesn't make design calls; asks the Director through the coordinator. | code, spreadsheet, docs |
| **Dino agent** | Guards the dinosaur vision: names, looks, attack flavour, wording. Reviews each build and proposes theme fixes. | review notes (fixes go through the Director to the Builder) |
| **Tester** (added 2026-10-01, Jovan's request) | Playtests in Roblox Studio through Studio's built-in MCP server, using `tools/studio/mcp.py` (`tools` / `call <tool> '<json>'`), following the playtest script in `PLAN.md`. Reports each step as pass, fail or not testable, with console output and screenshots. Doesn't judge feel or balance; doesn't fix anything. Bugs go to the Director, who queues fixes for the Builder. | `PLAYTEST.md`, screenshots in `playtest/` |

## Cycle

1. Director writes or updates `PLAN.md`: the next tasks, each with acceptance checks.
2. Builder takes the next task, builds it, verifies it (below), commits and pushes.
3. Dino agent reviews the change for the theme; Director reviews it for the vision.
   Fixes go back to step 2.
4. Repeat until the scope is done, then the Director writes the recap for Jovan.

## Current scope (Jovan, 2026-09-30)

Step 2 of the Dino Hunters plan (`VISION.md`: dinos bite and shoot, health, repair, Field
Medic, Field Hospital, Armory), then a wide polish pass — including that Amber is paid out
correctly and every tower and every upgrade path works as described. **Stop before phase 7**
and write the recap.

**Status (2026-10-01):** scope done (T1–T16c). The recap is `RECAP.md`.

## Round 2 scope (Jovan, 2026-10-01)

1. **Balance pass** across the whole game — towers, upgrade paths, heroes, levels, dino attacks,
   difficulty, cash and Amber pacing — using the tools (threat model, Balance Check sheet,
   specs). Jovan hasn't sent playtest numbers yet; prefer changes the models can justify, and
   flag anything that needs a playtest to settle.
2. **New feature: daily log-in rewards plus daily and weekly challenges**, to boost player
   retention. Rewards in Amber (and anything else that fits), balanced against the clear
   rewards so logging in never beats playing.

Stop before phase 7 again and write a round-2 recap (append to `RECAP.md`).

**Status (2026-10-01):** round 2 built (T18–T29b) and the recap is written (`RECAP.md`,
"Round 2"). 214 headless specs, `audit.py --strict` 0, `threat.py` 0; **not playtested**.
**Still open: T31, the Tester's Studio playtest** (`PLAN.md`). It waits for Jovan to turn on
Studio's "Enable Studio as MCP server". Phase 7 is not started.

## Round 3 scope (Jovan, 2026-10-02)

Jovan read the round-2 recap ("it looks really good to me") and asked for the two leftovers
of Phase 6:

1. **Mastery ability perks** at levels 10 and 15 for every hunter: the stronger one at 15,
   both modest and PvP-safe ("a somewhat fair advantage").
2. **Hero XP:** pops give a small amount of XP that is only banked when the round is
   cleared; levels stay close to the old every-5-rounds curve.

Saving and publishing are deferred ("we can deal with that later when it is published").
Plan: `PLAN.md` "Round 3" (T32–T39); design calls `DECISIONS.md` #97–#103. T31 (the Studio
playtest) is still open. Stop before phase 7 again and append a round-3 recap to `RECAP.md`.

**Status (2026-10-02):** round 3 built (T32–T37, T39; T36c is a one-string follow-up) and the
recap is written (`RECAP.md`, "Round 3"; design calls #97–#117). 245 headless specs,
`audit.py --strict` 0, `threat.py` 0; **not playtested**. **Still open: T31 + T38, the
Tester's Studio playtest.** It waits for Jovan to restart Studio, turn on "Enable Studio as
MCP server" and reconnect Rojo (disconnected since 2026-10-01 afternoon: Studio holds
pre-round-2 code until then). Phase 7 is not started.

## Round 4 scope (Jovan, 2026-10-02)

Jovan answered the open questions (his words: `DIRECTION.md` "Round-4 answers"). Round 4
turns them into work: the renames (Pops → **Bones**), Linebreaker ×2 over tier 4, a bigger
PLAY button and three small UI fixes, more starting cash on Hard, softer round-31 boss
throws; then **one health pool per dino with pierce-through** for the raw-damage towers
(models updated so they stay honest), Chaos as a gun-skill mode, a **sixth tier on every
hero path**, **small mastery perks** on the empty levels, and a saved **overall player
level** with cosmetics, titles and a level leaderboard (works unpublished). The next tower
batch is a proposal only (`TOWERS_NEXT.md`): nothing is built until Jovan picks.
Plan: `PLAN.md` "Round 4" (T40–T61); design calls `DECISIONS.md` #118–#142. T31 + T38 (the
Studio playtest) stay open. Stop before phase 7 again and append a round-4 recap to
`RECAP.md`.

**Status (2026-10-06):** round 4 built (T40–T68b; T69 Dino review done) and the recap is
written (`RECAP.md`, "Round 4"; design calls #118–#206). 406 headless specs, `audit.py
--strict` 0, `threat.py` 0, `value.py` bars met (findings = the four accepted); **not
playtested**. Jovan picked all four `TOWERS_NEXT.md` towers; they're built and on sale.
**Still open: T31 + T38 + T60 + T70, the Tester's Studio playtest** — Studio's MCP still
reports no Studio; Jovan must restart Studio, turn on "Enable Studio as MCP server" and
reconnect Rojo. Phase 7 is not started.

## Phase 7 scope (Jovan, 2026-10-06)

"Make sure everything is play tested and phase 7 is fully done." Phase 7 is the battle
modes: Team Battle (2–3 sides, raiding with guns), Battle Royale (most Bones), competitive
buy-ins and pots (escrow, Practice when unpublished), and ranked Trophies with arenas. Plan:
`PLAN.md` "Phase 7" (T71–T86, six Builder batches); design calls `DECISIONS.md` #208–#226
(ask-Jovan list #226, with defaults applied). The rounds 1–4 Studio playtest runs separately
and is blocked on Jovan reconnecting Rojo. Every phase-7 batch ends with a Tester step: solo
through the MCP with Studio-only stand-in sides (#221). Hunter-vs-hunter and non-host steps
go to Jovan's Clients and Servers script (T86). Saved stakes and Trophies, the cross-server
board, and 10-player load need a published place.

**Status (2026-10-08):** built (T71–T84b, T86b) and playtested solo in Studio (PLAYTEST
Runs 1–3; Run 4 re-checks T86b). The rounds 1–4 playtest is closed. Left for Jovan: the
Clients and Servers script and the after-publishing list (`RECAP.md` "Phase 7").

## Phase 8 scope (Director proposal, 2026-10-08)

Jovan: "begin phase 8 when all loose ends on phase 7 are done". Recommended: **Ready to
publish** (`PLAN.md` "Phase 8", DECISIONS #238): batch 1 (docs + publish checklist,
Studio-only gating, DataStore hardening, battle pacing report, Concussive T5 buff, stand-in
hunter for solo PvP tests) needs nothing from Jovan; the private publish, the lobby place and
the 4×-Amber towers wait on his answers.

## Rules

- **Verify every step:** `tools/check.sh` clean; `python3 tools/export_constants.py` clean;
  diff `src/shared/Config.luau` after any spreadsheet change and account for every changed
  line; headless tests where they exist. Studio playtests aren't available to the agents
  unless the Studio MCP is connected — say "statically checked, not playtested" honestly.
- **Numbers in the spreadsheet** (`Storm-Split-Balance.xlsx`, edited with openpyxl; the
  exporter recalculates formulas). Before writing a cell, assert it's empty or is the one
  you mean to change.
- **Commit and push each verified step** (Jovan's choice). Use
  `/Library/Developer/CommandLineTools/usr/bin/git` (the Xcode licence blocks `/usr/bin/git`).
  Never commit `ideas/`. Commit messages end with the Co-Authored-By line used in history.
- **Studio testing (Tester only):** needs Jovan to switch on Studio's Assistant Settings →
  Manage MCP Servers → "Enable Studio as MCP server"; if no Studio is listed, say "Studio
  testing unavailable" and stop. The Tester never edits game code, the spreadsheet or the
  place outside play mode, never publishes or saves the place, never wipes or writes
  DataStores (turn saving off with the Studio key J before any claim or unlock), and always
  stops play mode when done. Only what was run in Studio may be called playtested.
- **Log every design call** in `DECISIONS.md`: what was decided, why (which preference), and
  how to reverse it.
- Keep `CLAUDE.md` status, `ARCHITECTURE.md` phase table and the design docs current.
