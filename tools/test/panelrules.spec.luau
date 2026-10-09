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
	eq(PanelRules.battleHud("Playing", "TEAM", false, nil, 0).feed, true, "the feed in a battle")
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

-- PLAN T83: the battle results screen ---------------------------------------------------

local function camps3()
	return {
		{ side = 2, camp = "Blue Camp", place = 1, bones = 12 },
		{ side = 1, camp = "Red Camp", place = 2, bones = 30 },
		{ side = 3, camp = "Green Camp", place = 2, bones = 8 },
	}
end

test("T83 results open only for a battle's end, until the X", function()
	eq(PanelRules.resultsOpen("Victory", "TEAM", false), true)
	eq(PanelRules.resultsOpen("GameOver", "ROYALE", false), true)
	eq(PanelRules.resultsOpen("Victory", "TEAM", true), false, "X pressed")
	eq(PanelRules.resultsOpen("Victory", nil, false), false, "co-op keeps its own label")
	for _, state in { "Lobby", "Building", "Playing" } do
		eq(PanelRules.resultsOpen(state, "TEAM", false), false, `closes on {state}`)
	end
end)

test("T83 results: winner titles, placements in order, Ranked Hoard + Trophies + new arena", function()
	local r = PanelRules.battleResults({
		mode = "TEAM", place = 1, mySide = 2, camps = camps3(),
		payout = 80, share = 30, pot = 60, trophies = 30, trophiesNow = 330, newArena = "Raptor Ridge",
		practice = false, xp = 120,
	})
	eq(r.title, "Camp Clash — Your camp wins the hunt!")
	eq(r.won, true)
	eq(r.placements[1].text, "1. Blue Camp · 12 Bones")
	eq(r.placements[1].mine, true)
	eq(r.placements[2].text, "2. Red Camp · 30 Bones", "a shared place: by side")
	eq(r.placements[3].text, "2. Green Camp · 8 Bones")
	eq(table.concat(r.lines, "|"), "Amber +80 (50 payout + 30 Amber Hoard)|+30 Trophies · Raptor Ridge|New arena: Raptor Ridge!|+120 player XP")
	eq(PanelRules.battleResults({ mode = "ROYALE", place = 1, mySide = 1, camps = {}, practice = false }).title, "Bone Rush — Top Hunter!")
end)

test("T83 results: losers' titles, a Trophy loss, Practice Hunt changes no Trophies, casual has no Hoard", function()
	local loss = PanelRules.battleResults({ mode = "ROYALE", place = 3, mySide = 3, camps = {}, payout = 10, share = 0, trophies = -20, trophiesNow = 300, practice = false })
	eq(loss.title, "Bone Rush — 3rd place", "every mode: Nth place (T86b, Dino 17)")
	eq(loss.won, false)
	eq(table.concat(loss.lines, "|"), "Amber +10|−20 Trophies · Raptor Ridge")
	eq(PanelRules.battleResults({ mode = "TEAM", place = 2, mySide = 2, camps = {}, practice = false }).title, "Camp Clash — 2nd place")
	local practice = PanelRules.battleResults({ mode = "TEAM", place = 1, mySide = 1, camps = {}, payout = 80, share = 30, pot = 60, newArena = "Raptor Ridge", practice = true })
	eq(table.concat(practice.lines, "|"), "Amber +80 (50 payout + 30 Amber Hoard)|Practice Hunt: session Amber only. Trophies won't change.")
	local casual = PanelRules.battleResults({ mode = "TEAM", place = 2, mySide = 2, camps = {}, payout = 5, practice = false })
	eq(table.concat(casual.lines, "|"), "Amber +5", "no Hoard, no Trophies")
	eq(PanelRules.ordinal(11) .. PanelRules.ordinal(22) .. PanelRules.ordinal(13) .. PanelRules.ordinal(101), "11th22nd13th101st")
end)

test("T86b F5: no banner or feed line over a results screen", function()
	for _, state in { "Victory", "GameOver" } do
		eq(PanelRules.bannersShown(state), false, state)
		local h = PanelRules.battleHud(state, "ROYALE", true, 3, 2)
		eq(`{h.spectate}{h.stampede}{h.camo}{h.feed}`, "falsefalsefalsefalse", `{state}: spectate, Stampede, Camo, feed`)
	end
	for _, state in { "Lobby", "Building", "Playing" } do
		eq(PanelRules.bannersShown(state), true, state)
	end
	eq(PanelRules.battleHud("Lobby", "TEAM", false, nil, 0).feed, false, "home: no feed")
	eq(PanelRules.battleHud("Playing", nil, false, nil, 0).feed, false, "co-op: no battle feed")
end)

test("T86b F6: the top-centre banners sit below the camps board", function()
	eq(PanelRules.bannerTop(116, nil, 8), 116, "no board: under the XP rows")
	eq(PanelRules.bannerTop(116, 354, 8), 362, "below the board's bottom edge")
	eq(PanelRules.bannerTop(116, 60, 8), 116, "never above the XP rows")
	local hud = require("@lune/fs").readFile("src/client/Hud.client.luau")
	ok(hud:find('battleLabel("Spectate", 1, Color3.fromRGB(255, 120, 140), gui)', 1, true) ~= nil, "spectate out of the top banners")
	ok(hud:find("spectateBanner.Position = UDim2.new(0.5, 0, 1, -96)", 1, true) ~= nil, "spectate bottom centre")
	ok(hud:find("feedList.Visible = show.feed", 1, true) ~= nil, "the feed follows the rule")
end)

test("Run 4 F7: the camp-out line is a top-centre banner below the camps board, not a feed line", function()
	local BattleFlow = require(src.shared.BattleFlow)
	eq(PanelRules.feedSlot(BattleFlow.outLine("Jover_428's Camp")), "banner", "camp-out → banner")
	eq(PanelRules.feedSlot(BattleFlow.outLine("Red Camp")), "banner", "any camp")
	eq(PanelRules.feedSlot(BattleFlow.tranqLine("Rex")), "feed", "tranq stays in the feed")
	eq(PanelRules.feedSlot("Red Camp's Spotter was Trampled!"), "feed", "raid lines stay in the feed")
	eq(PanelRules.feedSlot(BattleFlow.outLine("")), "feed", "no camp name: not a camp-out line")
	local hud = require("@lune/fs").readFile("src/client/Hud.client.luau")
	ok(hud:find('PanelRules.feedSlot(text) == "banner"', 1, true) ~= nil, "the HUD routes by the rule")
	ok(hud:find("outBanners.Parent = battleBanners", 1, true) ~= nil, "camp-out lines live in the top-centre stack")
	ok(hud:find("outBanners.Visible = show.feed", 1, true) ~= nil, "and hide over the results (F5)")
end)

test("T86b place line: '{display} — {ordinal} place' below 1st in every mode", function()
	for _, mode in { "TEAM", "ROYALE" } do
		local display = if mode == "TEAM" then "Camp Clash" else "Bone Rush"
		for _, place in { 2, 3, 4, 10 } do
			eq(PanelRules.battleResults({ mode = mode, place = place, mySide = 1, camps = {}, practice = false }).title, `{display} — {PanelRules.ordinal(place)} place`)
		end
	end
	eq(PanelRules.battleResults({ mode = "TEAM", place = 1, mySide = 1, camps = {}, practice = false }).title, "Camp Clash — Your camp wins the hunt!")
	eq(PanelRules.battleResults({ mode = "ROYALE", place = 1, mySide = 1, camps = {}, practice = false }).title, "Bone Rush — Top Hunter!")
end)

test("T86b Amber line: the total with its breakdown when there's a share; never a separate +share", function()
	eq(PanelRules.amberLine(20, 15), "Amber +20 (5 payout + 15 Amber Hoard)")
	eq(PanelRules.amberLine(92, 32), "Amber +92 (60 payout + 32 Amber Hoard)")
	eq(PanelRules.amberLine(5, 0), "Amber +5", "a zero share: no breakdown")
	eq(PanelRules.amberLine(60, nil), "Amber +60", "casual")
	eq(PanelRules.amberLine(nil, 10), nil, "nothing paid out")
	local r = PanelRules.battleResults({ mode = "ROYALE", place = 1, mySide = 1, camps = {}, payout = 20, share = 15, practice = false })
	local plus = 0
	for _, line in r.lines do
		for _ in string.gmatch(line, "%+") do
			plus += 1
		end
	end
	eq(plus, 2, "one total line, one '+' inside its breakdown")
end)

test("T103 round label: the real round of 40, then Final Stampede N (never 'Round 41 / 40')", function()
	eq(PanelRules.roundLabel(1, 40), "Round 1 / 40")
	eq(PanelRules.roundLabel(22, 40), "Round 22 / 40")
	eq(PanelRules.roundLabel(40, 40), "Round 40 / 40")
	eq(PanelRules.roundLabel(41, 40), "Final Stampede 1")
	eq(PanelRules.roundLabel(43, 40), "Final Stampede 3")
end)
