--[[
	Shared/SmallPerks: the mastery small perks (PLAN T51, DECISIONS #135) at
	levels 5 / 6 / 11 / 16 / 19, the player lookup, and the pick-up reach rule.
]]

local Config = require(src.shared.Config)
local SmallPerks = require(src.shared.SmallPerks)

local function perks(level)
	local p = SmallPerks.at(level)
	return { p.pickupReach, p.healPerRound, p.respawnMult, p.repairCostMult }
end

local function same(actual, expected, what)
	for i = 1, 4 do
		near(actual[i], expected[i], `{what} [{i}]`, 1e-9)
	end
end

test("each line at levels 5 / 6 / 11 / 16 / 19 (reach, heal, respawn x, repair x)", function()
	same(perks(0), { 0, 0, 1, 1 }, "level 0")
	same(perks(5), { 0, 0, 1, 1 }, "level 5: none yet")
	same(perks(6), { 2, 0, 1, 1 }, "level 6: Long Arms I")
	same(perks(9), { 2, 5, 0.9, 0.95 }, "level 9: all four at step I")
	same(perks(11), { 4, 5, 0.9, 0.95 }, "level 11: Long Arms II")
	same(perks(16), { 6, 10, 0.8, 0.9 }, "level 16: Long Arms III")
	same(perks(19), { 6, 15, 0.7, 0.85 }, "level 19: all four at step III")
	same(perks(20), { 6, 15, 0.7, 0.85 }, "level 20 keeps them")
	same(perks(99), { 0, 0, 1, 1 }, "unknown level: none")
end)

test("the lines only grow with the level, and no level 1-5 has one", function()
	local previous = perks(0)
	for level = 1, #Config.Mastery do
		local now = perks(level)
		ok(now[1] >= previous[1] and now[2] >= previous[2], `level {level} adds never fall`)
		ok(now[3] <= previous[3] and now[4] <= previous[4], `level {level} x never rise`)
		if level <= 5 then
			same(now, { 0, 0, 1, 1 }, `level {level}`)
		end
		previous = now
	end
end)

test("every level that changes a line says so on the mastery screen", function()
	local previous = perks(0)
	for level = 1, #Config.Mastery do
		local now = perks(level)
		local changed = false
		for i = 1, 4 do
			changed = changed or now[i] ~= previous[i]
		end
		if changed then
			ok((Config.Mastery[level].unlock or "") ~= "", `level {level} has a line`)
		end
		previous = now
	end
	eq(Config.Mastery[6].unlock, "Long Arms I: pick up chests and med kits from 2 studs away")
	eq(Config.Mastery[19].unlock, "Handyman III: repairs cost 15% less")
end)

test("ofPlayer reads the hero being played and its mastery", function()
	local attrs = {}
	local fake = {
		GetAttribute = function(_, name)
			return attrs[name]
		end,
	}
	same(perks(0), (function()
		local p = SmallPerks.ofPlayer(fake :: any)
		return { p.pickupReach, p.healPerRound, p.respawnMult, p.repairCostMult }
	end)(), "no hero")
	attrs.Hero = "RIFLE"
	attrs.Mastery_RIFLE = 13
	attrs.Mastery_PISTOL = 19
	local p = SmallPerks.ofPlayer(fake :: any)
	same({ p.pickupReach, p.healPerRound, p.respawnMult, p.repairCostMult }, perks(13), "the played hero's level, not another's")
end)

test("pick-up reach: gap on the ground plane, reach 0 = touching only", function()
	local size = Vector3.new(2, 2, 2)
	local centre = Vector3.new(0, 1, 0)
	near(SmallPerks.gap(Vector3.new(4, 3, 0), 1, centre, size), 2, "3 studs from the face less a 1-stud half width", 1e-9)
	eq(SmallPerks.gap(Vector3.new(0.5, 3, 0), 1, centre, size), 0, "standing on it")
	near(SmallPerks.gap(Vector3.new(4, 3, 4), 1, centre, size), math.sqrt(18) - 1, "corner", 1e-9)
	ok(SmallPerks.inReach(2, 2), "at the reach")
	ok(not SmallPerks.inReach(2.01, 2), "past the reach")
	ok(not SmallPerks.inReach(0, 0), "no perk: Touched only")
end)

test("Handyman: the repair price takes the repairing hunter's perk, after the camp discount", function()
	local Combat = require(src.shared.Combat)
	local base = Combat.repairCost(1000, 0, 100, 10)
	eq(Combat.repairCost(1000, 0, 100, 10, 1), base, "x1 = no perk")
	local mult = SmallPerks.at(19).repairCostMult
	eq(Combat.repairCost(1000, 0, 100, 10, mult), math.floor(Config.Tuning.RepairCost * 1000 * 0.9 * mult + 0.5), "level 19")
	ok(Combat.repairCost(1000, 0, 100, 10, mult) < base, "cheaper")
	eq(Combat.repairCost(1000, 100, 100, 10, mult), 0, "full HP: free")
end)
