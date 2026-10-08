# Setup — Mac

About 15 minutes. Everything runs on your Mac; the Windows PC isn't needed.

## 1. Install the tools

**Roblox Studio** — download from create.roblox.com and sign in.

**Rokit** (tool manager) — in Terminal:

```bash
curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
```

Open a new Terminal window afterwards so `rokit` is on your PATH.

**Rojo** — from this folder:

```bash
cd ~/Fortnite
rokit init
rokit add rojo-rbx/rojo
rojo plugin install
```

That pins Rojo's version in `rokit.toml` (commit it, so any other machine gets the same version)
and installs the Rojo plugin into Studio.

**openpyxl** and **pycel** — only needed when you re-export balance numbers:

```bash
pip3 install openpyxl pycel
```

## 2. Create the place

1. Studio → **New** → **Baseplate**.
2. **File → Save to File As…** → `~/Fortnite/storm-split.rbxl`.
   It's gitignored — the map is built by code at runtime, so the place file holds nothing
   you need to version.

## 3. Sync and play

```bash
cd ~/Fortnite
rojo serve
```

In Studio: **Plugins** tab → **Rojo** → **Connect**. The scripts appear under
ReplicatedStorage, ServerScriptService and StarterPlayerScripts.

If you can't find the Rojo button: on the Mac it is also in the **menu bar at the very top of
the screen → Plugins → Rojo 7.7.0 → Connect**. The first time it connects, Rojo shows a
prompt about syncing into the place: click **Accept**. Nothing syncs until you do.

Press **Play**. You should see:

- The **home screen** over a slowly circling view of the map: pick Co-op, the track and a
  difficulty, then **PLAY** (the first player in the server is the host and chooses)
- A purple serpentine track on a green build area, with a green spawn and red exit
- A status bar at the top with your cash (450) and lives, and a green **Start round 1** button
- **Build (B)** bottom-right: pick a tower, move the see-through ghost (green = fits, red =
  on the track, overlapping or too far), click to place, **Q** to cancel
- Walk up to a built tower and press **E** to upgrade or sell it
- **Choose hero (H)** (under Start): pick a hero for free, switch until Start. **Upgrades (U)**
  (bottom right): your hero's upgrade paths. Equip with **1**: click to shoot, **R** reload,
  **F** ability, right-click zooms if you have a scope.
- **Camera:** always first person, so PvP is even. Placing a tower pulls back to third person
  until you place or cancel. Open menus free the mouse without leaving first person.
- Press **Start** and enemies spawn; kills and cleared rounds add cash
- One line per cleared round in **Output** (**Window → Output**):
  `Round 3 cleared | lives 40 | cash 212 | peak enemies 14 | script cost avg … ms`

Leave `rojo serve` running. Edits to any `.luau` file sync into Studio instantly.

## Testing with several players (on one Mac)

Studio can pretend to be a real server with 2 or 3 players, each in their own window. This
is how you test things one player can't: shooting another hunter, teammates, Ready for
Ranked.

1. `rojo serve` running and Rojo connected (above). Stop any normal Play first.
2. Studio → **Test** tab → in the **Clients and Servers** box, set the player count
   (**2** or **3**) → **Start**.
3. Studio opens **one server window** plus **one window per player** (Player1, Player2, …).
   Give it 20–30 seconds; each player window loads on its own.
   - The **server window** has no player in it. It shows the map from above and runs the
     game. Leave it alone.
   - **Player1** joined first, so Player1 is the **host**: only Player1 picks the mode,
     track, difficulty and presses PLAY. The others see the choices live.
   - Click into a window to control that player. Each window has its own mouse and keys.
4. **Test keys are per player.** Press **J** in *each* player window you want to test with:
   J gives that player +100 Amber and turns saving **off for that player only** (the
   others still save, if the place is published). **K** (+1000 cash) and **L** (knock half
   the HP off the tower nearest you) also work from any player window.
5. **Where the messages are:** every window has its own **Output** (**Window → Output** in
   that window). The game's own lines (`Round 3 cleared …`, `Battle settled …`,
   `[Progression] …`) are in the **server** window's Output. A player window's Output shows
   only that player's screen code. When something goes wrong, check the server window first.
6. **To finish:** in any window, **Test** tab → **Cleanup** (the red stop button). Studio
   closes every server and player window together. Don't close the windows one by one.

The 20-minute script to run this way is in `RECAP.md` → "Your 20-minute script (Studio →
Test → Clients and Servers)".

## Publish checklist (about 15 minutes)

Saving Amber, unlocks, mastery and Trophies, Ranked with real Entry fees, and both world
leaderboards only work in a place **published to Roblox**. Until then the game plays fine
but keeps progress for the session only, and Ranked is a free **Practice Hunt**.

**Publish (privately):**
1. Studio → **File → Publish to Roblox** → **Create new experience**. Give it a name. It is
   **private** (only you can join) until you change that, so publishing is safe.
2. **Home → Game Settings → Security** → turn on **Enable Studio Access to API Services** →
   **Save**. This lets Studio playtests reach the saves too.
3. **Game Settings → Places** (or the experience page on create.roblox.com) → **Max
   Players** = **10** → **Save**.
4. **Keep it private** until the published smoke test (PLAN T95) passes. Don't make it public
   or share it yet.

**The saved-data names (never rename these).** The game stores data under these names; a
renamed one starts everyone over from nothing. They are fixed in the code; just never type
a new name into one:

| Data store name | What it holds | Where in the code |
|---|---|---|
| `StormSplitProgress_v1` | each player's save: Amber, unlocks, mastery, player XP, Hunt Board, Trophies, an open Ranked Entry fee | `src/server/Progression.luau` (`STORE_NAME`) |
| `DinoHuntersPlayerXp_v1` | the world level leaderboard | `src/shared/LevelBoard.luau` (`STORE`), used by `src/server/LevelBoard.luau` |
| `DinoHuntersTrophies_v1` | the world Trophy board | `src/shared/TrophyBoard.luau` (`STORE`), used by `src/server/TrophyBoard.luau` |

**What "SaveStatus" means.** Every player has a `SaveStatus` (Explorer → Players → your
name → Attributes):
- `saved`: their save loaded, and changes are being written.
- `offline`: their save couldn't be loaded (not published, Studio API access off, Roblox
  having trouble, or J was pressed). They play on a **session-only** copy. Their real save
  is **never written over** by it. The Mastery screen says "Progress isn't saving right
  now." and Ranked is not allowed for them.

**What to check after publishing** (each line is part of PLAN T95):
1. Join the published game from the Roblox app (not Studio). `SaveStatus` should be
   `saved` and the Mastery screen should *not* say "Progress isn't saving".
2. Earn some Amber, leave, rejoin: the Amber is still there.
3. With a second account: Ranked takes the Entry fee, the winner gets the Amber Hoard, and
   Trophies change and stay after rejoining.
4. Shut the server down in the middle of a Ranked match (create.roblox.com → **Creations**
   → the experience's **⋯** menu → **Shut Down All Servers**): on the next join the Entry
   fee is back.
5. Both leaderboards say "World", not "This server", after a minute or two.
6. Watch the server's Output (**Developer Console**, F9 in the Roblox app → **Server**) for
   `[Progression]` warnings.

**If a publish breaks something: roll back.** create.roblox.com → the experience → the
place → **Version History** → pick the last good version → **Restore**. Saved player data is
not rolled back by this, only the place.

**Studio test keys never work in the published game:** K (+1000 cash), J (+100 Amber, no
saving), L (damage the nearest tower) and "Fill with stand-ins" only exist when the server
runs in Studio (the server checks).

## 4. Connect Claude to Studio (MCP)

1. Update Studio to the latest version.
2. Studio → **Assistant** → settings → **Manage MCP Servers** → turn on the
   **Enable Studio as MCP server** switch. If Claude says it can't reach Studio, this switch
   is the first thing to check (it can turn itself off after a Studio update).
3. Use **Quick connect** and pick Claude, or copy the config it shows into the Claude desktop
   app's MCP settings.
4. Restart the Claude desktop app. Studio must stay open with the place loaded.

Test it by asking Claude: *"Start a playtest in Studio, let it run 60 seconds, and read me the
Output."*

## 5. Git

```bash
cd ~/Fortnite
git init
git add -A
git commit -m "Storm Split phase 1: track, enemies, towers, waves"
```

Then create an empty repo on GitHub and push to it. On another machine, clone it, run step 1, and
`rojo serve` the same code.

## Changing balance numbers

1. Edit blue cells in `Storm-Split-Balance.xlsx` and save it as `.xlsx`. With **Numbers**:
   open the `.xlsx`, edit, press Enter, then **File → Export To → Excel…** over
   `~/Fortnite/Storm-Split-Balance.xlsx` (untick "Include a summary worksheet"). Cmd+S only
   saves a `.numbers` copy, which the exporter can't read.

   The exporter always recalculates every formula itself (pycel, Excel's arithmetic), so
   it doesn't matter which app last saved the file, and a file edited by a script needs no
   Numbers step. Numbers would round a few exact-.5 Sniper costs up by 1; the export uses
   Excel's result.
2. `python3 tools/export_constants.py`
3. `Config.luau` regenerates and Rojo syncs it. Stop and restart the playtest to pick it up.

The exporter validates as it goes and exits with an error if something would break the game
(split cycles, unknown enemy tiers, a weapon out-damaging towers).
