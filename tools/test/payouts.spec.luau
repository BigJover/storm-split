--[[
	Casual Amber payouts (VISION.md "Amber economy", DECISIONS #19) and the unlock ladder
	(DIRECTION.md). Towers and heroes are looked up by key, never by display name alone.
]]

local Config = require(src.shared.Config)
local Payouts = require(src.shared.Payouts)

local CLEAR = { EASY = 50, NORMAL = 100, HARD = 150, CHAOS = 200 }

test("the difficulties are the four this spec means", function()
	local n = 0
	for key in Config.Difficulties do
		ok(CLEAR[key] ~= nil, `unexpected difficulty {key}`)
		n += 1
	end
	eq(n, 4, "difficulties")
end)

test("a solo clear pays the difficulty's reward", function()
	for key, reward in CLEAR do
		eq(Payouts.casualPayout(true, 1, key), reward, `solo clear {key}`)
	end
end)

test("a multiplayer clear pays the same reward to each", function()
	for key, reward in CLEAR do
		eq(Payouts.casualPayout(true, 2, key), reward, `2-player clear {key}`)
		eq(Payouts.casualPayout(true, 10, key), reward, `10-player clear {key}`)
	end
end)

test("a solo loss pays nothing", function()
	for key in CLEAR do
		eq(Payouts.casualPayout(false, 1, key), 0, `solo loss {key}`)
	end
	eq(Payouts.casualPayout(false, 0, "EASY"), 0, "nobody left")
end)

test("a multiplayer loss pays MultiplayerLossPayout (5)", function()
	eq(Config.Tuning.MultiplayerLossPayout, 5, "Tuning")
	for key in CLEAR do
		eq(Payouts.casualPayout(false, 2, key), 5, `2-player loss {key}`)
		eq(Payouts.casualPayout(false, 10, key), 5, `10-player loss {key}`)
	end
	eq(Payouts.casualPayout(false, 2, "NOPE"), 5, "loss, unknown difficulty")
end)

test("an unknown difficulty on a clear pays nothing", function()
	eq(Payouts.casualPayout(true, 1, "NOPE"), 0)
	eq(Payouts.casualPayout(true, 3, nil), 0)
end)

test("the unlock ladder equals DIRECTION.md", function()
	local towers = { SCOUT = 0, SNIPER = 0, GRENADIER = 0, CHILLER = 100, QUARTERMASTER = 150 }
	local heroes = { PISTOL = 0, RIFLE = 75, SHOTGUN = 75 }
	local names = {
		SCOUT = "Hunting Blind",
		SNIPER = "Longshot Perch",
		GRENADIER = "Mortar Pit",
		CHILLER = "Tranq Station",
		QUARTERMASTER = "Supply Camp",
		PISTOL = "Tracker",
		RIFLE = "Big Game Hunter",
		SHOTGUN = "Brush Beater",
	}
	for key, cost in towers do
		eq(Config.Towers[key].display, names[key], `Towers.{key} name`)
		eq(Config.Towers[key].unlockCost, cost, `Towers.{key} unlock`)
	end
	for key, cost in heroes do
		eq(Config.Heroes[key].display, names[key], `Heroes.{key} name`)
		eq(Config.Heroes[key].unlockCost, cost, `Heroes.{key} unlock`)
	end
end)
