--[[
	Which shop panel may be open in which match state (Shared/PanelRules). Guards the bug
	Jovan found: Unlocks & Mastery stayed on screen after pressing Play.
]]
local PanelRules = require(src.shared.PanelRules)

local MODES = { "list", "placing", "manage", "heroUpgrade", "heroPick", "mastery" }

test("the home screen allows only hero select and mastery", function()
	for _, mode in MODES do
		local expected = mode == "heroPick" or mode == "mastery"
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
