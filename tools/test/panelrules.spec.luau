--[[
	Which shop panel may be open in which match state (Shared/PanelRules). Guards the bug
	Jovan found: Unlocks & Mastery stayed on screen after pressing Play.
]]
local PanelRules = require(src.shared.PanelRules)

local MODES = { "list", "placing", "manage", "heroUpgrade", "heroPick", "mastery", "huntBoard", "profile" }
local STATES = { "Lobby", "Building", "Playing", "GameOver", "Victory" }

test("the home screen allows only hero select, mastery, the Hunt Board and the Profile screen", function()
	for _, mode in MODES do
		local expected = mode == "heroPick" or mode == "mastery" or mode == "huntBoard" or mode == "profile"
		eq(PanelRules.allowed(mode, "Lobby", true), expected, `{mode} in Lobby`)
	end
end)

test("hero upgrades need a match and a hero", function()
	eq(PanelRules.allowed("heroUpgrade", "Building", true), true, "Building with hero")
	eq(PanelRules.allowed("heroUpgrade", "Building", false), false, "Building without hero")
	for _, state in { "Lobby", "GameOver", "Victory" } do
		eq(PanelRules.allowed("heroUpgrade", state, true), false, `{state}`)
	end
end)

test("pressing Play closes every home-screen panel (the reported bug)", function()
	for _, mode in MODES do
		eq(PanelRules.keepOnStateChange(mode, "Building", true), false, `{mode} into Building`)
	end
end)

test("starting the round keeps match panels and closes before-round ones", function()
	eq(PanelRules.keepOnStateChange("placing", "Playing", true), true, "placing")
	eq(PanelRules.keepOnStateChange("manage", "Playing", true), true, "manage")
	eq(PanelRules.keepOnStateChange("heroUpgrade", "Playing", true), true, "heroUpgrade")
	eq(PanelRules.keepOnStateChange("mastery", "Playing", true), false, "mastery")
	eq(PanelRules.keepOnStateChange("heroPick", "Playing", true), false, "heroPick with a hero")
	eq(PanelRules.keepOnStateChange("heroPick", "Playing", false), true, "heroPick without a hero")
end)

test("the results screen and going home close everything", function()
	for _, state in { "GameOver", "Victory", "Lobby" } do
		for _, mode in MODES do
			eq(PanelRules.keepOnStateChange(mode, state, true), false, `{mode} into {state}`)
		end
	end
end)

test("the Hunt Board opens on the home screen only, hero or not (DECISIONS #70)", function()
	for _, state in STATES do
		for _, hasHero in { true, false } do
			eq(PanelRules.allowed("huntBoard", state, hasHero), state == "Lobby", `{state}, hero {hasHero}`)
		end
	end
	eq(PanelRules.allowed("huntBoard", nil, true), false, "before the state is known")
end)

test("the Hunt Board never survives a state change (no-trap rule)", function()
	for _, state in STATES do
		for _, hasHero in { true, false } do
			eq(PanelRules.keepOnStateChange("huntBoard", state, hasHero), false, `into {state}, hero {hasHero}`)
		end
	end
	eq(PanelRules.keepOnStateChange("huntBoard", nil, true), false, "into an unknown state")
end)

-- The tower panel's level line (PLAN round 3 T36b, DECISIONS #112).

test("the tower level line is hidden at level 1 and says the compounded damage after", function()
	local Config = require(src.shared.Config)
	local perLevel = Config.Tuning.TowerDamagePerLevel
	eq(perLevel, 0.1, "Tower damage per level is the seed this spec means")
	eq(PanelRules.towerLevelLine(1, perLevel), nil, "level 1: no line")
	eq(PanelRules.towerLevelLine(0, perLevel), nil, "no level yet: no line")
	eq(PanelRules.towerLevelLine(2, perLevel), "Tower level 2 · +10% damage", "level 2")
	eq(PanelRules.towerLevelLine(3, perLevel), "Tower level 3 · +21% damage", "level 3")
	eq(PanelRules.towerLevelLine(8, perLevel), "Tower level 8 · +95% damage", "level 8, the last round")
	eq(PanelRules.towerLevelLine(3, 0.25), "Tower level 3 · +56% damage", "the percent follows the lever")
end)

test("the hero panel's tier ladder shows all six tiers (PLAN T53)", function()
	eq(PanelRules.tierLadder(0, 6), "○○○○○○ 0/6", "nothing bought")
	eq(PanelRules.tierLadder(3, 6), "●●●○○○ 3/6", "three of six")
	eq(PanelRules.tierLadder(6, 6), "●●●●●● 6/6", "maxed")
	eq(PanelRules.tierLadder(9, 6), "●●●●●● 6/6", "never past the top")
	eq(PanelRules.tierLadder(2, 5), "●●○○○ 2/5", "a five-tier path keeps five")
end)

test("every hero path's ladder has six pips, one line each (no-trap: the panel doesn't grow)", function()
	local Config = require(src.shared.Config)
	for key, hero in Config.Heroes do
		for _, path in hero.paths do
			local ladder = PanelRules.tierLadder(0, #path.tiers)
			eq(#path.tiers, 6, `{key} {path.id} has six tiers`)
			ok(not string.find(ladder, "\n"), `{key} {path.id}: one line`)
		end
	end
end)

test("a tower that can be damaged keeps its Repair row at full HP (PLAYTEST F2)", function()
	eq(PanelRules.repairRow(100, 100, false), "full", "full HP: greyed row, same slot")
	eq(PanelRules.repairRow(100, 40, false), "needed", "bitten")
	eq(PanelRules.repairRow(100, 0, true), "needed", "trampled")
	eq(PanelRules.repairRow(0, 0, false), nil, "can't be damaged: never a row")
	-- Bitten and healed: the row is there either way, so the paths never move.
	eq(PanelRules.repairRow(100, 99, false) ~= nil, PanelRules.repairRow(100, 100, false) ~= nil, "same rows")
end)

test("the hunter's HP bar hides on the home screen and without a character (PLAYTEST F1)", function()
	eq(PanelRules.hpBarVisible("Lobby", true), false, "home screen after a match")
	eq(PanelRules.hpBarVisible("Playing", false), false, "no character")
	for _, state in { "Building", "Playing", "GameOver", "Victory" } do
		eq(PanelRules.hpBarVisible(state, true), true, state)
	end
end)

-- PLAN T83 (DECISIONS #233): the Inspect prompt and the four player-list columns ---------

test("T83 another camp's tower says Inspect; your own keeps the server's text", function()
	eq(PanelRules.towerPrompt(1, 2, "Upgrade"), "Inspect")
	eq(PanelRules.towerPrompt(2, 1, "Upgrade / Repair"), "Inspect")
	eq(PanelRules.towerPrompt(2, 2, "Upgrade / Repair"), "Upgrade / Repair", "own camp")
	eq(PanelRules.towerPrompt(1, 1, "Upgrade"), "Upgrade", "co-op: side 1")
	eq(PanelRules.towerPrompt(1, nil, "Upgrade"), "Upgrade", "no side published yet")
end)

test("T83 the player list is Bones, Level, Trophies, Title (no Mastery)", function()
	local Theme = require(src.shared.Theme)
	local columns = PanelRules.playerListColumns()
	eq(table.concat(columns, "|"), `{Theme.Bones}|{Theme.PlayerLevel}|Trophies|Title`)
	eq(#columns, 4, "Roblox shows four stats")
	eq(table.find(columns, "Mastery"), nil)
	local fs = require("@lune/fs")
	local board = fs.readFile("src/server/Scoreboard.luau")
	ok(board:find('"Mastery"', 1, true) == nil, "Server/Scoreboard no longer makes a Mastery column")
	local at = {}
	for i = 1, 4 do
		at[i] = board:find(`.Name = columns[{i}]`, 1, true)
		ok(at[i] ~= nil, `column {i} made from the list`)
	end
	ok(at[1] < at[2] and at[2] < at[3] and at[3] < at[4], "created in the list's order (Roblox shows them in that order)")
end)

-- PLAN T83: the in-match battle screens (spectator panels, labels, camps board) ---------

test("T83 a spectator (camp out) can't open build, hero, upgrade or mastery panels; Inspect stays", function()
	for _, m in { "list", "placing", "heroUpgrade", "heroPick", "mastery" } do
		eq(PanelRules.allowed(m, "Playing", true, true), false, `{m} while out`)
		eq(PanelRules.keepOnStateChange(m, "Playing", true, true), false, `{m} kept while out`)
	end
	eq(PanelRules.allowed("list", "Playing", true, false), true, "in the game: build")
	eq(PanelRules.allowed("list", "Playing", true), true, "co-op callers pass no out flag")
	eq(PanelRules.allowed("manage", "Playing", true, true), true, "the read-only tower panel")
	eq(PanelRules.allowed("closed", "Playing", true, true), true)
end)

test("T83 battle labels show only in a battle match, each on its own condition", function()
	local function hud(state, battle, out, overtime, camo)
		local h = PanelRules.battleHud(state, battle, out, overtime, camo)
		return `{h.camps}{h.spectate}{h.stampede}{h.camo}`
	end
	eq(hud("Playing", nil, true, 2, 3), "falsefalsefalsefalse", "co-op shows none")
	eq(hud("Lobby", "TEAM", true, 2, 3), "falsefalsefalsefalse", "home screen")
	eq(hud("Victory", "TEAM", true, 2, 3), "falsefalsefalsefalse", "results")
	eq(hud("Playing", "TEAM", false, nil, 0), "truefalsefalsefalse", "the board only")
	eq(hud("Playing", "ROYALE", true, nil, 0), "truetruefalsefalse", "spectating")
	eq(hud("Playing", "TEAM", false, 1, 0), "truefalsetruefalse", "Final Stampede")
	eq(hud("Building", "TEAM", false, 1, 0), "truefalsefalsefalse", "no Stampede while building")
	eq(hud("Playing", "TEAM", false, nil, 2.5), "truefalsefalsetrue", "Camo Cover")
	eq(hud("Playing", "TEAM", true, nil, 2.5), "truetruefalsefalse", "no Camo Cover for a spectator")
end)

test("T83 camps board: camps still in first, then most Bones, then side; yours marked", function()
	local rows = PanelRules.campRows({
		{ side = 1, camp = "Red Camp", fence = 10, bones = 5, out = false },
		{ side = 2, camp = "Blue Camp", fence = 0, bones = 50, out = true },
		{ side = 3, camp = "Green Camp", fence = 4, bones = 9, out = false },
		{ side = 4, camp = "Ann's Camp", fence = 7, bones = 9, out = false },
	}, 4)
	local order = {}
	for _, row in rows do
		table.insert(order, `{row.side}{if row.mine then "*" else ""}`)
	end
	eq(table.concat(order, ","), "3,4*,1,2")
	eq(PanelRules.campLine(rows[3]), "Red Camp · Fence 10 · 5 Bones")
	eq(PanelRules.campLine(rows[4]), "Blue Camp · out · 50 Bones")
	eq(PanelRules.campsHeader(rows), "3/4 camps left")
	eq(PanelRules.SPECTATE_LINE, "Your Fence is down — you're watching now.")
	eq(PanelRules.STAMPEDE_LINE, "Final Stampede! Dinos get tougher every round.")
	eq(PanelRules.CAMO_LINE, "Camo Cover: can't be hit")
end)

test("T83 Server/Battle publishes each camp's Bones and a Team per camp, and clears both", function()
	local fs = require("@lune/fs")
	local src = fs.readFile("src/server/Battle.luau")
	ok(src:find('Sides.attr("CampBones", side), sideBones(side)', 1, true) ~= nil, "live camp Bones")
	ok(src:find('{ "Camp", "Out", "Place", "CampBones" }', 1, true) ~= nil, "reset clears them")
	ok(src:find("team:Destroy()", 1, true) ~= nil, "reset removes the camp Teams")
	ok(src:find("BattleFlow.campColor(side)", 1, true) ~= nil, "Team colour = the camp colour")
end)
