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
- Walk up to a built tower and press **E** to sell it
- Press **Start** and enemies spawn; kills and cleared rounds add cash
- One line per cleared round in **Output** (**Window → Output**):
  `Round 3 cleared | lives 40 | cash 212 | peak enemies 14 | script cost avg … ms`

Leave `rojo serve` running. Edits to any `.luau` file sync into Studio instantly.

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

   If the file was changed by a script instead (no stored formula results), the exporter
   recalculates every formula itself with pycel — no Numbers step needed. pycel matches
   Numbers exactly, including rounding exact .5 results up.
2. `python3 tools/export_constants.py`
3. `Config.luau` regenerates and Rojo syncs it. Stop and restart the playtest to pick it up.

The exporter validates as it goes and exits with an error if something would break the game
(split cycles, unknown enemy tiers, a weapon out-damaging towers).
