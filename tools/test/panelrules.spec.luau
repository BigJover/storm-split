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
