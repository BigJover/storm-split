--[[
	Battle modes (PLAN phase 7 T71, DECISIONS #209-#214, #217, #219, #225): Modes sides,
	Shared/BattleRules and Shared/Matchmaking. Co-op stays one side.
]]

local Config = require(src.shared.Config)
local Modes = require(src.shared.Modes)
local BattleRules = require(src.shared.BattleRules)
local Matchmaking = require(src.shared.Matchmaking)

local T = Config.Tuning
local LAST = #Config.Rounds

-- Modes: sides --------------------------------------------------------------

test("the seeds this spec means", function()
	eq(T.TeamMinPlayers, 2, "TeamMinPlayers")
	eq(T.RoyaleMinPlayers, 3, "RoyaleMinPlayers")
	eq(T.BattleMaxPlayers, 10, "BattleMaxPlayers")
	eq(T.BattleRoundTime, 60, "BattleRoundTime (T101, #251: was 120 before Round pace)")
	eq(T.OvertimeHPStep, 1.25, "OvertimeHPStep")
	eq(T.SurvivorBonus, 0.1, "SurvivorBonus")
	eq(LAST, 40, "rounds")
end)

test("co-op is one side for any player count", function()
	for n = 1, 10 do
		eq(Modes.sideCount("COOP", n), 1, `co-op {n}`)
	end
	eq(Modes.minPlayers("COOP"), 1)
	eq(Modes.Modes.COOP.available, true, "co-op available")
end)

test("battle modes are on the home screen from T82", function()
	eq(Modes.Modes.TEAM.available, true)
	eq(Modes.Modes.ROYALE.available, true)
	eq(Modes.Modes.TEAM.display, "Camp Clash", "#230")
	eq(Modes.Modes.ROYALE.display, "Bone Rush", "#230")
end)

test("Team: 2 or 3 sides, the host's pick; 3 needs 3 players; 1v1 allowed", function()
	eq(Modes.sideCount("TEAM", 2), 2, "default 2")
	eq(Modes.sideCount("TEAM", 2, 2), 2, "1v1")
	eq(Modes.sideCount("TEAM", 3, 3), 3, "3 sides of 1")
	eq(Modes.sideCount("TEAM", 7, 3), 3, "7 on 3")
	eq(Modes.sideCount("TEAM", 10, 2), 2, "10 on 2")
	local none, why = Modes.sideCount("TEAM", 2, 3)
	eq(none, nil)
	eq(why, "emptySide", "3 sides with 2 players")
	none, why = Modes.sideCount("TEAM", 1, 2)
	eq(why, "tooFew", "1 player")
	none, why = Modes.sideCount("TEAM", 6, 4)
	eq(why, "badSides", "4 sides")
	none, why = Modes.sideCount("TEAM", 11, 2)
	eq(why, "tooMany", "11 players")
	eq(Modes.minPlayers("TEAM", true), 2, "competitive Team min")
end)

test("Royale: one side per player, 2-10 casual, 3+ competitive", function()
	for n = 2, 10 do
		eq(Modes.sideCount("ROYALE", n), n, `royale {n}`)
	end
	local none, why = Modes.sideCount("ROYALE", 1)
	eq(none, nil)
	eq(why, "tooFew")
	none, why = Modes.sideCount("ROYALE", 11)
	eq(why, "tooMany")
	none, why = Modes.sideCount("ROYALE", 2, nil, true)
	eq(why, "tooFew", "competitive royale needs 3")
	eq(Modes.sideCount("ROYALE", 3, nil, true), 3)
	eq(Modes.minPlayers("ROYALE"), 2)
	eq(Modes.minPlayers("ROYALE", true), 3)
	local _, unknown = Modes.sideCount("NOPE", 4)
	eq(unknown, "unknownMode")
end)

-- canDamage -------------------------------------------------------------------

local SCOUT = Config.Towers.SCOUT
local FALCON = Config.Towers.FALCON
local TARPIT = Config.Towers.TARPIT

test("no friendly fire: a hunter never hurts their own side", function()
	eq(BattleRules.canDamage(1, 1, "hunter"), false, "own hunter")
	eq(BattleRules.canDamage(1, 1, "tower", { tower = SCOUT }), false, "own tower")
	eq(BattleRules.canDamage(2, 2, "tower"), false, "own tower, no def")
end)

test("a hunter hits enemy hunters and enemy towers, and only their own side's dinos (#228)", function()
	eq(BattleRules.canDamage(1, 2, "hunter"), true, "enemy hunter")
	eq(BattleRules.canDamage(1, 2, "tower", { tower = SCOUT }), true, "enemy tower")
	eq(BattleRules.canDamage(1, 1, "dino"), true, "own dino")
	eq(BattleRules.canDamage(1, 3, "dino"), false, "another side's dino: no Bone-stealing")
	eq(BattleRules.canDamage(2, 1, "dino", { attacker = "hunter" }), false, "explicit hunter")
end)

test("Falcon Roost and Tar Pit are immune to everyone", function()
	ok(FALCON.untouchable and TARPIT.untouchable, "the sheet flags them")
	for _, def in { FALCON, TARPIT } do
		eq(BattleRules.canDamage(1, 2, "tower", { tower = def }), false, "enemy hunter")
		eq(BattleRules.canDamage(0, 2, "tower", { attacker = "dino", tower = def }), false, "dino")
	end
end)

test("towers shoot dinos only: never hunters, never towers", function()
	eq(BattleRules.canDamage(1, 2, "hunter", { attacker = "tower" }), false, "enemy hunter")
	eq(BattleRules.canDamage(1, 1, "hunter", { attacker = "tower" }), false, "own hunter")
	eq(BattleRules.canDamage(1, 2, "tower", { attacker = "tower", tower = SCOUT }), false, "enemy tower")
	eq(BattleRules.canDamage(1, 1, "dino", { attacker = "tower" }), true, "dino")
end)

test("dinos bite anyone in reach, invaders included", function()
	eq(BattleRules.canDamage(1, 1, "hunter", { attacker = "dino" }), true, "own side's hunter")
	eq(BattleRules.canDamage(1, 2, "hunter", { attacker = "dino" }), true, "invader")
	eq(BattleRules.canDamage(1, 1, "tower", { attacker = "dino", tower = SCOUT }), true, "tower")
	eq(BattleRules.canDamage(1, 1, "dino", { attacker = "dino" }), false, "dino on dino")
end)

test("a spectator (side out) deals no damage", function()
	for _, kind in { "hunter", "tower", "dino" } do
		eq(BattleRules.canDamage(1, 2, kind :: any, { attackerOut = true, tower = SCOUT }), false, kind)
	end
end)

test("co-op (one side): hunters still can't hurt each other or towers", function()
	eq(BattleRules.canDamage(1, 1, "hunter"), false)
	eq(BattleRules.canDamage(1, 1, "tower", { tower = SCOUT }), false)
	eq(BattleRules.canDamage(1, 1, "dino"), true)
end)

-- lockstep, elimination, overtime --------------------------------------------

test("lockstep: next round once every live side cleared, or after Battle round time", function()
	eq(BattleRules.nextRoundDue({ [1] = true, [2] = false }, 10), false, "one side still fighting")
	eq(BattleRules.nextRoundDue({ [1] = true, [2] = true }, 10), true, "all cleared")
	eq(BattleRules.nextRoundDue({ [1] = false, [2] = false }, T.BattleRoundTime - 0.1), false, "just before the timer")
	eq(BattleRules.nextRoundDue({ [1] = false, [2] = false }, T.BattleRoundTime), true, "the timer")
	ok(T.BattleRoundTime >= 55.7, "at least the longest paced Normal round (55.7 s, #251; the exporter checks Normal and Chaos)")
	eq(BattleRules.nextRoundDue({ [3] = true }, 0), true, "one live side cleared")
end)

test("a side is out at Fence 0", function()
	eq(BattleRules.sideOut(1), false)
	eq(BattleRules.sideOut(0), true)
	eq(BattleRules.sideOut(-5), true)
end)

test("overtime: repeats after the last round; HP x 1.25 per repeat, compounding", function()
	eq(BattleRules.overtimeRepeat(LAST), 0, "the last round is not overtime")
	eq(BattleRules.overtimeRepeat(1), 0)
	eq(BattleRules.overtimeRepeat(LAST + 1), 1)
	eq(BattleRules.overtimeRepeat(LAST + 3), 3)
	eq(BattleRules.overtimeHpMult(0), 1)
	near(BattleRules.overtimeHpMult(1), 1.25)
	near(BattleRules.overtimeHpMult(2), 1.5625)
	near(BattleRules.overtimeHpMult(3), 1.953125)
end)

-- Team result -------------------------------------------------------------------

test("Team: not over while two sides stand", function()
	local r = BattleRules.teamResult({}, { [1] = 5, [2] = 9 })
	eq(r.over, false)
	r = BattleRules.teamResult({ { 2 } }, { [1] = 0, [2] = 0, [3] = 0 })
	eq(r.over, false, "3 sides, one out")
end)

test("Team: the last side standing wins", function()
	local r = BattleRules.teamResult({ { 2 } }, { [1] = 0, [2] = 50 })
	eq(r.over, true)
	eq(#r.winners, 1)
	eq(r.winners[1], 1, "side 1 stands, even with fewer Bones")
	eq(r.losers[1], 2)
	eq(r.tie, false)
	r = BattleRules.teamResult({ { 3 }, { 1 } }, { [1] = 10, [2] = 1, [3] = 99 })
	eq(r.winners[1], 2, "3 sides")
	eq(#r.losers, 2)
end)

test("Team: a simultaneous fall goes to more Bones", function()
	local r = BattleRules.teamResult({ { 1, 2 } }, { [1] = 30, [2] = 31 })
	eq(r.over, true)
	eq(#r.winners, 1)
	eq(r.winners[1], 2)
	eq(r.tie, false)
	-- only the sides of the last step count: side 3 fell earlier with more Bones
	r = BattleRules.teamResult({ { 3 }, { 2, 1 } }, { [1] = 8, [2] = 7, [3] = 100 })
	eq(r.winners[1], 1)
	eq(#r.losers, 2)
end)

test("Team: a simultaneous fall with equal Bones is a tie", function()
	local r = BattleRules.teamResult({ { 1, 2 } }, { [1] = 30, [2] = 30 })
	eq(r.over, true)
	eq(r.tie, true)
	eq(#r.winners, 2)
	eq(r.winners[1], 1)
	eq(r.winners[2], 2)
	eq(#r.losers, 0)
	r = BattleRules.teamResult({ { 1 }, { 2, 3 } }, { [1] = 0, [2] = 4, [3] = 4 })
	eq(r.tie, true, "3 sides, last two tie")
	eq(#r.losers, 1)
	eq(r.losers[1], 1)
end)

-- Royale result -------------------------------------------------------------------

test("Royale: not over while two are alive and rounds remain", function()
	local r = BattleRules.royaleResult({
		{ id = "a", bones = 10, fence = 5 },
		{ id = "b", bones = 20, fence = 5 },
		{ id = "c", bones = 30, fence = 0, outAt = 1 },
	}, false)
	eq(r.over, false)
	eq(r.survivor, nil)
end)

test("Royale: ends at one alive; the survivor gets +10% Bones (rounded down)", function()
	local r = BattleRules.royaleResult({
		{ id = "a", bones = 105, fence = 3 },
		{ id = "b", bones = 110, fence = 0, outAt = 2 },
		{ id = "c", bones = 50, fence = 0, outAt = 1 },
	}, false)
	eq(r.over, true)
	eq(r.survivor, "a")
	eq(r.bones.a, 115, "105 x 1.1 = 115.5 -> 115")
	eq(r.bones.b, 110, "out: frozen")
	eq(r.ranking[1], "a", "the bonus lifts the survivor past b")
	eq(r.ranking[2], "b")
	eq(r.ranking[3], "c")
end)

test("Royale: most Bones wins even over the survivor", function()
	local r = BattleRules.royaleResult({
		{ id = "a", bones = 10, fence = 9 },
		{ id = "b", bones = 200, fence = 0, outAt = 1 },
	}, false)
	eq(r.over, true)
	eq(r.ranking[1], "b")
	eq(r.bones.a, 11)
end)

test("Royale: ends at the last round with several alive; no survivor bonus", function()
	local r = BattleRules.royaleResult({
		{ id = "a", bones = 40, fence = 3 },
		{ id = "b", bones = 50, fence = 3 },
	}, true)
	eq(r.over, true)
	eq(r.survivor, nil)
	eq(r.bones.a, 40)
	eq(r.bones.b, 50)
	eq(r.ranking[1], "b")
end)

test("Royale: nobody alive (the last fall together): over, no bonus", function()
	local r = BattleRules.royaleResult({
		{ id = "a", bones = 40, fence = 0, outAt = 5 },
		{ id = "b", bones = 40, fence = 0, outAt = 5 },
	}, false)
	eq(r.over, true)
	eq(r.survivor, nil)
	eq(r.ranking[1], "a", "full tie keeps the order given")
end)

test("Royale ties: survived longer, then more Fence", function()
	local r = BattleRules.royaleResult({
		{ id = "early", bones = 30, fence = 0, outAt = 1 },
		{ id = "late", bones = 30, fence = 0, outAt = 4 },
		{ id = "aliveLow", bones = 30, fence = 2 },
		{ id = "aliveHigh", bones = 30, fence = 9 },
	}, true)
	eq(r.ranking[1], "aliveHigh")
	eq(r.ranking[2], "aliveLow")
	eq(r.ranking[3], "late")
	eq(r.ranking[4], "early")
end)

-- Matchmaking ---------------------------------------------------------------------

local function sizes(teams)
	local out = {}
	for i, t in teams do
		out[i] = #t
	end
	return out
end

test("7 players on 3 sides: 3/2/2", function()
	local teams = Matchmaking.assign({ 1, 2, 3, 4, 5, 6, 7 }, 3)
	local s = sizes(teams)
	eq(s[1], 3)
	eq(s[2], 2)
	eq(s[3], 2)
	teams = Matchmaking.assign({ 1, 2, 3, 4, 5, 6, 7 }, 3, { [1] = 5, [2] = 9 })
	s = sizes(teams)
	eq(s[1] + s[2] + s[3], 7)
	ok(math.max(s[1], s[2], s[3]) - math.min(s[1], s[2], s[3]) <= 1, "snake sizes")
end)

test("sizes differ by at most 1 for every count", function()
	for sides = 1, 3 do
		for n = sides, 10 do
			local ids = {}
			for i = 1, n do
				ids[i] = i
			end
			for _, tr in { false, true } do
				local trophies = if tr then {} else nil
				if trophies then
					for i = 1, n do
						trophies[i] = (i * 37) % 11
					end
				end
				local teams, sideOf = Matchmaking.assign(ids, sides, trophies)
				local s = sizes(teams)
				local lo, hi, total = math.huge, 0, 0
				for _, k in s do
					lo, hi, total = math.min(lo, k), math.max(hi, k), total + k
				end
				ok(hi - lo <= 1, `{n} on {sides}`)
				eq(total, n, "everyone placed")
				for side, team in teams do
					for _, id in team do
						eq(sideOf[id], side, "sideOf agrees")
					end
				end
			end
		end
	end
end)

test("snake draft by Trophies: 1,2,3,3,2,1", function()
	local trophies = { a = 600, b = 500, c = 400, d = 300, e = 200, f = 100 }
	local teams, sideOf = Matchmaking.assign({ "f", "e", "d", "c", "b", "a" }, 3, trophies)
	eq(sideOf.a, 1)
	eq(sideOf.b, 2)
	eq(sideOf.c, 3)
	eq(sideOf.d, 3)
	eq(sideOf.e, 2)
	eq(sideOf.f, 1)
	eq(teams[1][1], "a", "draft order within a side")
	eq(teams[1][2], "f")
end)

test("snake draft 1v1 and 2v2", function()
	local _, sideOf = Matchmaking.assign({ "x", "y", "z", "w" }, 2, { x = 10, y = 40, z = 30, w = 20 })
	-- ranked y, z, w, x -> 1, 2, 2, 1
	eq(sideOf.y, 1)
	eq(sideOf.z, 2)
	eq(sideOf.w, 2)
	eq(sideOf.x, 1)
end)

test("deterministic; equal Trophies keep the order given", function()
	local ids = { "p", "q", "r", "s" }
	local tr = { p = 100, q = 100, r = 100, s = 100 }
	local _, a = Matchmaking.assign(ids, 2, tr)
	local _, b = Matchmaking.assign(ids, 2, tr)
	for _, id in ids do
		eq(a[id], b[id], id)
	end
	eq(a.p, 1)
	eq(a.q, 2)
	eq(a.r, 2)
	eq(a.s, 1)
	-- no Trophies: round-robin in the order given
	local _, rr = Matchmaking.assign(ids, 2)
	eq(rr.p, 1)
	eq(rr.q, 2)
	eq(rr.r, 1)
	eq(rr.s, 2)
end)

test("Royale: one player per side", function()
	local teams = Matchmaking.assign({ "a", "b", "c", "d" }, 4)
	for side = 1, 4 do
		eq(#teams[side], 1, `side {side}`)
	end
end)
