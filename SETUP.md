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

That pins Rojo's version in `rokit.toml` (commit it, so your friend gets the same version)
and installs the Rojo plugin into Studio.

**openpyxl** — only needed when you re-export balance numbers:

```bash
pip3 install openpyxl
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

- A purple serpentine track with a green spawn and red exit
- Nine gold pads, three with blue Scout towers and range rings
- Enemies spawning after ~3 seconds, tracers from the towers
- A status bar at the top: round, lives, enemies alive
- One line per cleared round in **Output**:
  `Round 3 cleared | lives 40 | peak enemies 14 | script cost avg … ms`

**The game ending around round 11 is expected.** Three Scouts with no economy can't handle the
first difficulty spike, which is when armored enemies and flyers arrive. Phase 2 adds the shop.

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

Then create an empty repo on GitHub and push to it. Your friend clones it, runs step 1, and
`rojo serve`s the same code.

## Changing balance numbers

1. Edit blue cells in `Storm-Split-Balance.xlsx` and **save** (openpyxl reads the values
   your spreadsheet app last calculated).
2. `python3 tools/export_constants.py`
3. `Config.luau` regenerates and Rojo syncs it. Stop and restart the playtest to pick it up.

The exporter validates as it goes and exits with an error if something would break the game
(split cycles, unknown enemy tiers, a weapon out-damaging towers).
