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
- **Log every design call** in `DECISIONS.md`: what was decided, why (which preference), and
  how to reverse it.
- Keep `CLAUDE.md` status, `ARCHITECTURE.md` phase table and the design docs current.
