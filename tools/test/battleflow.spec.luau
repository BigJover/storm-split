--[[
	Battle match flow (PLAN phase 7 T77, DECISIONS #210, #213, #214, #221, #229-#231):
	Shared/BattleFlow (seating, stand-ins, camp names and lines, round rows and the Final
	Stampede, side scale and cash, placements, results titles), BattleRules.canSupport
	(drops, heals and auras stay on their own side) and SpawnQueue.clear (a side out).
]]

local Config = require(src.shared.Config)
local BattleFlow = require(src.shared.BattleFlow)
local BattleRules = require(src.shared.BattleRules)
local Modes = require(src.shared.Modes)
local Placement = require(src.shared.Placement)
local Sides = require(src.shared.Sides)
local SpawnQueue = require(src.shared.SpawnQueue)

local T = Config.Tuning
local LAST = #Config.Rounds

-- Names (T74 / #229 / #230) ------------------------------------------------------

test("mode display names are Camp Clash and Bone Rush (#230); keys unchanged", function()
	eq(Modes.Modes.TEAM.display, "Camp Clash")
	eq(Modes.Modes.ROYALE.display, "Bone Rush")
	eq(Modes.Modes.TEAM.blurb, "Two or three camps, each defending its own side.")
	ok(Modes.Modes.ROYALE.blurb:find("Every hunter for themselves. Most ", 1, true) == 1, "Royale blurb")
	eq(Modes.ModeOrder[2], "TEAM")
	eq(Modes.ModeOrder[3], "ROYALE")
end)

test("camp names: Red / Blue / Green Camp; Bone Rush '<Name>'s Camp'", function()
	eq(BattleFlow.campName("TEAM", 1), "Red Camp")
	eq(BattleFlow.campName("TEAM", 2), "Blue Camp")
	eq(BattleFlow.campName("TEAM", 3), "Green Camp")
	eq(BattleFlow.campName("ROYALE", 4, "Jovan"), "Jovan's Camp")
	eq(BattleFlow.campName("ROYALE", 4), "Stand-in 4's Camp", "a stand-in seat")
end)

test("feed lines are exactly the Round 16 strings", function()
	eq(BattleFlow.outLine("Red Camp"), "Red Camp's Fence is down! They're out.")
	eq(BattleFlow.tranqLine("Jovan"), "Tranqed by Jovan!")
	eq(BattleFlow.raidLine("Jovan", "Blue Camp", "Scout Post"), "Jovan trampled Blue Camp's Scout Post")
end)

test("results titles for the winner only (T74)", function()
	eq(BattleFlow.resultTitle("TEAM", 1), "Camp Clash — Your camp wins the hunt!")
	eq(BattleFlow.resultTitle("ROYALE", 1), "Bone Rush — Top Hunter!")
	eq(BattleFlow.resultTitle("TEAM", 2), nil)
	eq(BattleFlow.resultTitle("ROYALE", 3), nil)
	eq(BattleFlow.resultTitle("ROYALE", nil), nil)
	eq(BattleFlow.resultTitle("COOP", 1), nil, "co-op has its own results")
end)

-- Seating ---------------------------------------------------------------------------

test("without stand-ins the lobby rules hold (Modes.sideCount)", function()
	local s, why = BattleFlow.seat("TEAM", { "a" }, 2, false)
	eq(s, nil)
	eq(why, "tooFew")
	s = BattleFlow.seat("TEAM", { "a", "b", "c", "d" }, 2, false)
	eq(s and s.sides, 2)
	eq(s and #s.teams[1], 2)
	eq(s and next(s.standIn), nil, "no stand-ins")
	s = BattleFlow.seat("ROYALE", { "a", "b", "c" }, nil, false)
	eq(s and s.sides, 3, "a seat each")
	eq(BattleFlow.seat("COOP", { "a" }), nil, "co-op never seats sides")
end)

test("stand-ins: one tester fills every empty side (Studio, #221)", function()
	local s = BattleFlow.seat("TEAM", { "me" }, 2, true)
	eq(s and s.sides, 2)
	eq(s and s.sideOf.me, 1)
	eq(s and s.standIn[2], true, "side 2 is a stand-in")
	eq(s and s.standIn[1], nil, "my side isn't")
	s = BattleFlow.seat("TEAM", { "me", "you" }, 3, true)
	eq(s and s.sides, 3)
	eq(s and s.standIn[3], true)
	eq(s and s.standIn[2], nil)
	s = BattleFlow.seat("ROYALE", { "me" }, 3, true)
	eq(s and s.sides, 3, "Bone Rush with 2 stand-ins")
	eq(s and s.standIn[2] and s.standIn[3], true)
	s = BattleFlow.seat("ROYALE", { "me" }, 10, true)
	eq(s and s.sides, 10, "the 10-seat load test")
	s = BattleFlow.seat("ROYALE", { "me" }, nil, true)
	eq(s and s.sides, 2, "at least two seats")
	eq(BattleFlow.seat("TEAM", { "me" }, 4, true), nil, "Camp Clash is 2 or 3")
	eq(BattleFlow.seat("TEAM", {}, 2, true), nil, "nobody to play")
end)

test("stand-ins: owner ids are negative, never a real UserId", function()
	for side = 1, 10 do
		ok(BattleFlow.standInOwnerId(side) < 0, `side {side}`)
	end
	eq(BattleFlow.standInName(3), "Stand-in 3")
end)

test("stand-in towers: free, damageable, off-track; spots pass Placement in their own zone", function()
	local keys = BattleFlow.standInTowers()
	ok(#keys >= 1, "some towers")
	for _, key in keys do
		local def = Config.Towers[key]
		eq(def.unlockCost or 0, 0, `{key} free`)
		eq(def.untouchable, false, `{key} can be raided`)
	end
	for _, sides in { 2, 3, 10 } do
		local layout = Sides.new(sides, sides > 3)
		for side = 1, sides do
			local spots = BattleFlow.standInSpots(layout, side, #keys)
			eq(#spots, #keys, `{sides} sides: side {side} has a spot per tower`)
			for i, spot in spots do
				local others = table.clone(spots)
				table.remove(others, i)
				ok(Placement.check(spot, others, false, Sides.zone(layout, side)), `{sides}/{side}: spot {i} fits`)
				eq(Sides.sideAt(layout, spot), side, `{sides}/{side}: spot {i} in its own zone`)
			end
		end
	end
end)

-- Rounds ------------------------------------------------------------------------------

test("round rows: the table, then the Final Stampede repeats the last row with more HP", function()
	local index, mult, repeats = BattleFlow.roundRow(1)
	eq(index, 1)
	eq(mult, 1)
	eq(repeats, 0)
	index, mult, repeats = BattleFlow.roundRow(LAST)
	eq(index, LAST)
	eq(mult, 1)
	eq(repeats, 0)
	index, mult, repeats = BattleFlow.roundRow(LAST + 1)
	eq(index, LAST)
	near(mult, T.OvertimeHPStep)
	eq(repeats, 1)
	index, mult, repeats = BattleFlow.roundRow(LAST + 3)
	eq(index, LAST)
	near(mult, T.OvertimeHPStep ^ 3)
	eq(repeats, 3)
	eq(BattleFlow.hasOvertime("TEAM"), true)
	eq(BattleFlow.hasOvertime("ROYALE"), false, "Bone Rush ends at the last round")
end)

test("a side scales by its own hunters (the CO-OP levers); a stand-in is one-hunter scale", function()
	local d = { countMult = 1.2, hpMult = 1.5, promoteChance = 0.1, startingCash = 450 }
	local one = BattleFlow.sideScale(d, 1)
	eq(one.countMult, 1.2)
	eq(one.hpMult, 1.5)
	eq(one.promoteChance, 0.1)
	local zero = BattleFlow.sideScale(d, 0)
	eq(zero.countMult, one.countMult, "stand-in")
	local three = BattleFlow.sideScale(d, 3)
	near(three.countMult, 1.2 * (1 + T.ExtraEnemiesPerPlayer * 2))
	near(three.hpMult, 1.5 * (1 + T.ExtraHPPerPlayer * 2))
	eq(BattleFlow.startingCash(d, 1), 450)
	eq(BattleFlow.startingCash(d, 0), 450, "stand-in")
	eq(BattleFlow.startingCash(d, 3), 450 + T.StartingCashPerExtraPlayer * 2)
end)

test("lockstep: a living side that hasn't cleared holds the round until the timer", function()
	eq(BattleRules.nextRoundDue({ [1] = true, [2] = false }, 0), false)
	eq(BattleRules.nextRoundDue({ [1] = true, [2] = true }, 0), true)
	eq(BattleRules.nextRoundDue({ [1] = true, [2] = false }, T.BattleRoundTime), true)
	eq(BattleRules.nextRoundDue({ [1] = true }, 1), true, "an out side isn't waited for")
end)

-- Placements ---------------------------------------------------------------------------

test("Camp Clash places: the winner 1st, then the latest fall", function()
	local order = { { 3 }, { 2 } }
	local result = BattleRules.teamResult(order, { [1] = 5, [2] = 9, [3] = 1 })
	eq(result.over, true)
	local p = BattleFlow.teamPlaces(order, result, 3)
	eq(p[1], 1)
	eq(p[2], 2)
	eq(p[3], 3)
end)

test("Camp Clash places: a simultaneous fall decided by Bones, a full tie shares 1st", function()
	local order = { { 1, 2 } }
	local result = BattleRules.teamResult(order, { [1] = 7, [2] = 3 })
	local p = BattleFlow.teamPlaces(order, result, 2)
	eq(p[1], 1)
	eq(p[2], 2)
	result = BattleRules.teamResult(order, { [1] = 4, [2] = 4 })
	p = BattleFlow.teamPlaces(order, result, 2)
	eq(p[1], 1)
	eq(p[2], 1)
	order = { { 2, 3 } }
	result = BattleRules.teamResult(order, { [1] = 0, [2] = 1, [3] = 1 })
	p = BattleFlow.teamPlaces(order, result, 3)
	eq(p[1], 1, "the one standing")
	eq(p[2], 2, "fell together")
	eq(p[3], 2, "fell together")
end)

test("Bone Rush places follow the ranking (Bones, then survival, then Fence)", function()
	local result = BattleRules.royaleResult({
		{ id = 1, bones = 10, fence = 0, outAt = 1 },
		{ id = 2, bones = 30, fence = 5 },
		{ id = 3, bones = 20, fence = 0, outAt = 2 },
	}, false)
	eq(result.over, true, "one left alive")
	local p = BattleFlow.royalePlaces(result.ranking)
	eq(p[2], 1)
	eq(p[3], 2)
	eq(p[1], 3)
	eq(result.bones[2], math.floor(30 * (1 + T.SurvivorBonus)), "survivor bonus")
end)

-- Own side only (#231) -------------------------------------------------------------------

test("canSupport: drops, heals and auras reach only their own side", function()
	eq(BattleRules.canSupport(1, 1), true, "co-op / own side")
	eq(BattleRules.canSupport(2, 2), true)
	eq(BattleRules.canSupport(1, 2), false, "an enemy can't take my chest")
	eq(BattleRules.canSupport(3, 1), false)
end)

test("SpawnQueue.clear: an out side's queue empties, the others keep theirs", function()
	local q = SpawnQueue.new(3)
	for side = 1, 3 do
		for i = 1, 4 do
			SpawnQueue.push(q, side, i)
		end
	end
	SpawnQueue.clear(q, 2)
	eq(SpawnQueue.size(q, 2), 0)
	eq(SpawnQueue.size(q, 1), 4)
	eq(SpawnQueue.size(q, 3), 4)
	eq(SpawnQueue.size(q), 8)
	SpawnQueue.clear(q, 9) -- unknown side: nothing happens
	eq(SpawnQueue.size(q), 8)
end)
