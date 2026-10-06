--[[
	Falcon Roost (PLAN T65, UPGRADES.md): which dino a bird dives on, the travel time and
	the flock's dive cap, a dive's damage (Power Dive, Eagle of the Peak), Hunting Party's
	cover, and the sheet's tiers.
]]

local Combat = require(src.shared.Combat)
local Config = require(src.shared.Config)
local Falcon = require(src.shared.Falcon)
local TowerStats = require(src.shared.TowerStats)

local ROOST = Config.Towers.FALCON
local T = Config.Tuning

local function at(pathIndex: number, tier: number)
	local tiers = { 0, 0, 0 }
	tiers[pathIndex] = tier
	return TowerStats.compute(ROOST, tiers)
end

test("the Tuning levers are the seeds", function()
	eq(T.FalconSpeed, 40)
	eq(T.EagleDiveX, 6)
	eq(T.FalconBellsMark, 2)
end)

test("the tower: 400 cash, 200 Amber, 3 x 1.33/s, 40 studs, air, can't be damaged, two birds (#191)", function()
	eq(ROOST.display, "Falcon Roost")
	eq(ROOST.baseCost, 400)
	eq(ROOST.unlockCost, 200)
	eq(ROOST.baseDamage, 3)
	eq(ROOST.baseRate, 1.33)
	eq(ROOST.range, 40)
	eq(ROOST.hitsAir, true)
	eq(ROOST.untouchable, true)
	eq(ROOST.chains, false)
	eq(ROOST.birds, 2)
	eq(Combat.canBeHit(ROOST, false), false, "never a dino's target")
	for key, def in Config.Towers do
		eq(def.birds > 0, key == "FALCON", `{key} has birds`)
	end
	local base = TowerStats.compute(ROOST, { 0, 0, 0 })
	eq(base.birds, 2, "two birds at tier 0")
	eq(base.firstDiveX, 1, "no Power Dive yet")
	eq(base.sizeBreaks, 1, "breaks 1")
	eq(base.piercesArmor, false, "no armour until Iron Talons")
	local blind = TowerStats.compute(Config.Towers.SCOUT, { 5, 2, 0 })
	eq(blind.birds, 0, "a tower without birds")
	eq(blind.firstDiveX, 1, "x1")
end)

test("pick: the first dino in range no other bird is after", function()
	eq(Falcon.pick({ 10, 50, 30 }), 2, "furthest along")
	eq(Falcon.pick({ 10, 50, 30 }, { [2] = true }), 3, "the furthest is taken: the next one")
	eq(Falcon.pick({ 10, 50, 30 }, { [1] = true, [2] = true, [3] = true }), 2, "all taken: the furthest")
	eq(Falcon.pick({ 40, 40 }), 1, "a tie: the earlier")
	eq(Falcon.pick({}), nil, "nothing in range")
end)

test("travel time: out and back at Falcon speed; the flock caps the dives", function()
	near(Falcon.flight(40), 1, "40 studs at 40/s")
	near(Falcon.flight(10), 0.25)
	eq(Falcon.flight(-3), 0, "never negative")
	eq(Falcon.free(2, 0), 2)
	eq(Falcon.free(2, 2), 0, "both out: the roost waits")
	eq(Falcon.free(2, 5), 0)
	-- two birds, 40 studs out: a round trip is 2s, so at most 1 dive a second (rate 1.33)
	near(Falcon.diveRate(1.33, 2, 40), 1, "the cap binds far out")
	near(Falcon.diveRate(1.33, 2, 10), 1.33, "close in, the rate binds")
	near(Falcon.diveRate(1.33, 1, 40), 0.5, "the eagle alone")
end)

test("a dive: Power Dive's first dive, the eagle's x6", function()
	near(Falcon.diveDamage(10, false, 3, false), 10, "not the first dive")
	near(Falcon.diveDamage(10, true, 3, false), 30, "the first dive on a dino x3")
	near(Falcon.diveDamage(10, true, 1, false), 10, "no Power Dive")
	near(Falcon.diveDamage(10, false, 3, true), 60, "an eagle dive x6")
	near(Falcon.diveDamage(10, true, 3, true), 180, "the eagle's first dive")
end)

test("Hunting Party: the strongest diving roost covering the point, never itself", function()
	local roost = {}
	local parties = {
		{ center = Vector3.new(0, 0, 0), radius = 40, percent = 15, diving = true, source = roost },
		{ center = Vector3.new(100, 0, 0), radius = 40, percent = 25, diving = true, source = {} },
	}
	eq(Falcon.huntingParty(Vector3.new(30, 5, 0), parties), 15, "in range, a bird out")
	eq(Falcon.huntingParty(Vector3.new(30, 5, 0), parties, roost), 0, "not the roost itself")
	eq(Falcon.huntingParty(Vector3.new(50, 0, 0), parties), 0, "out of range")
	eq(Falcon.huntingParty(Vector3.new(70, 0, 0), parties), 25, "the other one")
	parties[1].diving = false
	eq(Falcon.huntingParty(Vector3.new(30, 0, 0), parties), 0, "no bird out: nothing")
end)

test("Talons: raw damage, Power Dive breaks 2, Iron Talons pierces and breaks 3, the eagle", function()
	local names = { "Sharp Talons", "Hooked Beak", "Power Dive", "Iron Talons", "Eagle of the Peak" }
	local breaks = { 1, 1, 2, 3, 3 }
	local first = { 1, 1, 3, 3, 3 }
	for tier = 1, 5 do
		local s = at(1, tier)
		eq(ROOST.paths[1].tiers[tier].name, names[tier])
		eq(s.sizeBreaks, breaks[tier], `T{tier} breaks`)
		eq(s.firstDiveX, first[tier], `T{tier} first dive`)
		eq(s.piercesArmor, tier >= 4, `T{tier} pierces`)
		eq(s.eagle, tier == 5, `T{tier} eagle`)
		eq(s.birds, if tier == 5 then 1 else 2, `T{tier} birds`)
		ok(tier == 1 or s.damage > at(1, tier - 1).damage or tier == 5, `T{tier} more damage`)
	end
	local eagle = at(1, 5)
	eq(eagle.stunSeconds, 0.5, "the eagle stuns 0.5s")
	eq(eagle.stunsBosses, false, "not bosses")
	-- the eagle replaces the flock, whatever Flock tier is bought alongside
	eq(TowerStats.compute(ROOST, { 5, 2, 0 }).birds, 1, "Eagle + Quick Return: one eagle")
	eq(TowerStats.compute(ROOST, { 2, 5, 0 }).birds, 12, "Murmuration + Hooked Beak: the swarm")
end)

test("Flock: more birds, Wide Circle 60 studs, Murmuration", function()
	local birds = { 4, 4, 6, 6, 12 }
	for tier = 1, 5 do
		local s = at(2, tier)
		eq(s.birds, birds[tier], `T{tier} birds`)
		eq(s.murmuration, tier == 5, `T{tier} murmuration`)
		ok(s.rate * s.damage > at(2, tier - 1).rate * at(2, tier - 1).damage or tier >= 4, `T{tier} more output`)
	end
	near(at(2, 4).range, 60, "Wide Circle: radius 60")
	near(at(2, 3).range, 40)
end)

test("Falconer: range, Falcon Bells, Hooded Scout, Lure, Hunting Party", function()
	near(at(3, 1).range, 44, "Long Leash +10%")
	eq(at(3, 1).markPercent, 0)
	eq(at(3, 2).markPercent, 10, "Falcon Bells +10%")
	eq(at(3, 2).bossMarkPercent, 0)
	eq(at(3, 3).bossMarkPercent, 25, "Hooded Scout: bosses +25%")
	eq(at(3, 3).knockback, 0)
	eq(at(3, 4).knockback, 2, "Lure: 2 studs (Enemies never moves bosses)")
	eq(at(3, 4).diveAuraRatePercent, 0)
	eq(at(3, 5).diveAuraRatePercent, 15, "Hunting Party +15% while a bird dives")
	eq(at(3, 5).auraRatePercent, 0, "no standing rate aura")
end)
