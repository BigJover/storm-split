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

Press **Play**. You should see:

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

**Testing with several players:** Studio → **Test** tab → **Clients and Servers** → set the
number of players → **Start**. Studio opens one server window and one window per player.
Each extra player adds enemies and starting cash (`VISION.md`).

## Saving progress and 10-player servers

Storm Cores, unlocks and mastery save with Roblox's DataStore, which only exists for a
place **published to Roblox**. Until then the game runs on session-only progress and the
Mastery screen (M) says so.

1. Studio → **File → Publish to Roblox** → create a new experience (it's private until you
   make it public).
2. **Home → Game Settings → Security** → turn on **Enable Studio Access to API Services**,
   so playtests in Studio save too.
3. **Game Settings → Places** (or on create.roblox.com) → set **Max Players** to **10**.

Studio test keys (never in a published game): **K** = +1000 cash, **J** = +100 Storm Cores
and every hero and tower owned. J switches that session to "not saving" so test progress never
reaches your real save.

## 4. Connect Claude to Studio (MCP)

1. Update Studio to the latest version.
2. Studio → **Assistant** → settings → **MCP Servers** → turn on
   **Enable Studio as MCP server**.
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
