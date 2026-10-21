--[[
	Hunter bodies (PLAN 10a T135, DECISIONS #364/#365/#370): Shared/HunterStats over the
	Hunter Stats sheet. The parity refusal on a bad seed is the exporter's (doctest in
	tools/export_constants.py validate_bodies).
]]
local Config = require(src.shared.Config)
local HunterStats = require(src.shared.HunterStats)

local SEEDS = { -- #364
	PISTOL = { 95, 17 }, -- Tracker
	RIFLE = { 110, 15 }, -- Big Game Hunter
	SHOTGUN = { 115, 15.5 }, -- Brush Beater
	MEDIC = { 100, 16.5 }, -- Field Medic
}

test("each hunter's Max HP and Walk speed are the #364 seeds", function()
	for key, want in SEEDS do
		local body = HunterStats.body(key)
		eq(body.maxHealth, want[1], `{key} Max HP`)
		eq(body.walkSpeed, want[2], `{key} Walk speed`)
	end
	for key in Config.Heroes do
		ok(SEEDS[key] ~= nil, `every hero has a body: {key}`)
	end
end)

test("no hunter picked (or an unknown key) is today's 100 HP / 16", function()
	for _, key in { nil :: any, "", "NOPE", 7 } do
		local body = HunterStats.body(key)
		eq(body.maxHealth, 100, `{tostring(key)} HP`)
		eq(body.walkSpeed, 16, `{tostring(key)} speed`)
	end
	eq(Config.Tuning.PlayerMaxHealth, 100)
	eq(Config.Tuning.PlayerWalkSpeed, 16)
end)

test("body parity: best / worst score <= Body parity max (1.15, #365)", function()
	eq(Config.Tuning.BodySpeedWeight, 1.5)
	eq(Config.Tuning.BodyParityMax, 1.15)
	local best, worst = -math.huge, math.huge
	for key in Config.Heroes do
		local s = HunterStats.score(HunterStats.body(key))
		best, worst = math.max(best, s), math.min(worst, s)
	end
	ok(best / worst <= Config.Tuning.BodyParityMax, `parity {best / worst}`)
	near(HunterStats.score(HunterStats.body("SHOTGUN")), 1.15 * (15.5 / 16) ^ 1.5, "Brush Beater score", 1e-12)
	near(HunterStats.score(HunterStats.body(nil)), 1, "the reference body scores 1")
end)

test("trained Health and Speed add % on the class base, capped at +10 % / +15 % (#370)", function()
	eq(Config.Tuning.TrainedHealthMax, 10)
	eq(Config.Tuning.TrainedSpeedMax, 15)
	local half = HunterStats.body("PISTOL", { healthPercent = 5, speedPercent = 7.5 })
	near(half.maxHealth, 95 * 1.05, "Tracker +5 % HP")
	near(half.walkSpeed, 17 * 1.075, "Tracker +7.5 % speed")
	local over = HunterStats.body("RIFLE", { healthPercent = 50, speedPercent = 100 })
	near(over.maxHealth, 110 * 1.1, "capped at +10 %")
	near(over.walkSpeed, 15 * 1.15, "capped at +15 %")
	local bad = HunterStats.body("MEDIC", { healthPercent = -20, speedPercent = 0 / 0 })
	eq(bad.maxHealth, 100, "negative = 0")
	eq(bad.walkSpeed, 16.5, "NaN = 0")
end)

test("a slow multiplies the class base, not 16 (#365)", function()
	near(HunterStats.slowed(HunterStats.body("RIFLE").walkSpeed, 30), 10.5, "Big Game Hunter 15 x 0.7")
	near(HunterStats.slowed(HunterStats.body("PISTOL").walkSpeed, 30), 11.9, "Tracker 17 x 0.7")
	ok(math.abs(HunterStats.slowed(HunterStats.body("PISTOL").walkSpeed, 30) - 16 * 0.7) > 0.5, "not 16-based")
	eq(HunterStats.slowed(15, 0), 15, "no slow")
	eq(HunterStats.slowed(15, 150), 0, "clamped to 100 %")
	eq(HunterStats.slowed(15, -10), 15, "never a speed-up")
end)

test("a hero pick keeps the share of HP; the HUD shows the hunter's own max", function()
	eq(HunterStats.carryHealth(100, 100, 115), 115, "full stays full")
	eq(HunterStats.carryHealth(50, 100, 110), 55, "half stays half")
	eq(HunterStats.carryHealth(0, 100, 95), 0, "zero stays zero")
	eq(HunterStats.carryHealth(10, 0, 95), 95, "no old max: full")
	eq(HunterStats.hpText(95, 95), "HP 95 / 95", "Tracker")
	eq(HunterStats.hpText(57.5, 115), "HP 58 / 115", "Brush Beater, HP rounded up")
	eq(HunterStats.hpText(-3, 0), "HP 0 / 1", "never negative or zero max")
end)
