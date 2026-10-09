--[[
	The match clock (PLAN Phase 8 batch 2 T104, DECISIONS #252, #253, #261): casual 900 s /
	Ranked 1800 s from Building, none in co-op; at the cap the match ends at once and the
	tie-break chain ranks everyone standing; a clock end places and settles exactly like a
	normal end (no tie path); the clear-time counter; the HUD clock, warning banner and
	"Decided by" line; the Studio short clock is refused live; the wiring (read from the source).
]]
local fs = require("@lune/fs")
local Config = require(src.shared.Config)
local BattleLoop = require(src.shared.BattleLoop)
local BattleFlow = require(src.shared.BattleFlow)
local BattleRules = require(src.shared.BattleRules)
local Pace = require(src.shared.Pace)
local PanelRules = require(src.shared.PanelRules)
local Stakes = require(src.shared.Stakes)
local StudioOnly = require(src.shared.StudioOnly)

local T = Config.Tuning

test("the cap is picked by queue; co-op has none", function()
	eq(Pace.matchCap("TEAM", false), 900)
	eq(Pace.matchCap("ROYALE", false), 900)
	eq(Pace.matchCap("TEAM", true), 1800)
	eq(Pace.matchCap("ROYALE", true), 1800)
	eq(Pace.matchCap("COOP", false), nil)
	eq(Pace.matchCap("COOP", true), nil)
end)

-- A fake battle on a fake clock: every round clears after `clearAfter` s (side 2 after
-- `slowSide2`), the clock started `building` s before round 1.
local function run(modeKey: string, competitive: boolean, cap: number?, opts: { clearAfter: number?, slowSide2: number?, building: number?, stopAt: number? }?)
	local o = opts or {}
	local clock = o.building or T.BattleBuildTime
	local roundStart = 0
	local clearTime = {}
	local ended = {}
	local result, round = BattleLoop.run({
		modeKey = modeKey,
		competitive = competitive,
		first = Pace.firstRound(modeKey, competitive),
		poll = 0.25,
		now = function()
			return clock
		end,
		wait = function(s)
			clock += s
		end,
		tick = function()
			if o.stopAt and clock >= o.stopAt then
				return "fell"
			end
			return nil
		end,
		cleared = function()
			local after = clock - roundStart
			return { [1] = after >= (o.clearAfter or 10), [2] = after >= (o.slowSide2 or o.clearAfter or 10) }
		end,
		startRound = function()
			roundStart = clock
		end,
		endRound = function(r)
			table.insert(ended, r)
		end,
		paySkipped = function() end,
		finish = function()
			return "rounds done"
		end,
		cap = cap,
		clockStart = 0,
		atClock = function()
			return "clock"
		end,
		clearTime = clearTime,
	})
	return result, round, clock, clearTime, ended
end

test("at the cap the match ends at once (casual 900 s), counted from Building", function()
	-- Camp Clash casual, nobody falls: Final Stampede until the clock.
	local result, round, clock = run("TEAM", false, 900, { clearAfter = 30 })
	eq(result, "clock")
	ok(clock >= 900 and clock < 900.3, `ended at {clock} s`)
	ok(round > #Config.Rounds, `in Final Stampede (round {round})`)
	local r2, _, c2 = run("TEAM", true, 1800, { clearAfter = 30 })
	eq(r2, "clock")
	ok(c2 >= 1800 and c2 < 1800.3, `Ranked: {c2} s`)
	-- A fall in the same check as the cap is a normal end (tick runs first).
	eq((run("TEAM", false, 900, { clearAfter = 30, stopAt = 900 })), "fell")
	-- Bone Rush ends at round 40 well before its clock (the backstop).
	local r3, round3, c3 = run("ROYALE", false, 900, { clearAfter = 30 })
	eq(r3, "rounds done")
	eq(round3, #Config.Rounds)
	ok(c3 < 900, `round 40 done at {c3} s`)
	-- No cap: no clock end (co-op never comes here; a battle without one would run on).
	eq((run("TEAM", false, nil, { clearAfter = 30, stopAt = 5000 })), "fell")
end)

test("clear time: each round's seconds to the first clear; an uncleared round counts whole", function()
	local _, _, _, clear, ended = run("ROYALE", false, nil, { clearAfter = 10, slowSide2 = 25 })
	local n = #ended
	eq(n, 14, "the casual list")
	near(clear[1], 10 * n, "side 1: 10 s a round", 0.3 * n)
	near(clear[2], 25 * n, "side 2: 25 s a round", 0.3 * n)
	-- Side 2 never clears: every round is forced at Battle round time and counts whole.
	local _, _, _, stuck = run("ROYALE", false, nil, { clearAfter = 10, slowSide2 = 1e9 })
	near(stuck[2], T.BattleRoundTime * 14, "forced rounds count whole", 0.3 * 14)
	-- At the clock the round in progress counts what has passed.
	local _, _, clock, part = run("TEAM", false, 100, { clearAfter = 10, slowSide2 = 1e9, building = 30 })
	near(part[2], clock - 30, "side 2: every second since round 1", 0.01)
end)

test("a clock end places and settles exactly like a normal end: no tie path (Camp Clash)", function()
	-- Clock: 3 camps standing, camp 4 fell; level Bones, Fence decides among the standing.
	local clockResult = BattleRules.atClock({
		modeKey = "TEAM",
		eliminationOrder = { { 4 } },
		bones = { [1] = 10, [2] = 10, [3] = 10, [4] = 99 },
		fence = { [1] = 3, [2] = 9, [3] = 6, [4] = 0 },
		seed = "match-1",
	})
	eq(clockResult.over, true)
	eq(clockResult.tie, false)
	eq(#clockResult.winners, 1)
	eq(clockResult.decidedBy, "fence")
	local places = BattleFlow.teamPlaces({ { 4 } }, clockResult, 4)
	eq(places[2], 1, "most Fence")
	eq(places[3], 2, "standing camps keep their chain order")
	eq(places[1], 3)
	eq(places[4], 4, "the fallen camp after everyone standing")
	-- The same order reached by falls (1 at a step, 3 after, 2 last standing).
	local order = { { 4 }, { 1 }, { 3 } }
	local normal = BattleRules.teamResult(order, { [1] = 10, [2] = 10, [3] = 10, [4] = 99 }, { seed = "match-1" })
	local normalPlaces = BattleFlow.teamPlaces(order, normal, 4)
	for side = 1, 4 do
		eq(places[side], normalPlaces[side], `side {side}: same place either way`)
	end
	-- Settle both: Ranked stakes, Trophies and payouts identical, one winning side only.
	local function seats(p)
		local list = {}
		for side = 1, 4 do
			table.insert(list, { id = `hunter{side}`, place = p[side], present = true, stake = T.CompetitiveBuyIn })
		end
		return list
	end
	for _, ranked in { true, false } do
		local a, potA, leftA = Stakes.settleBattle("TEAM", 4, seats(places), ranked, false)
		local b, potB, leftB = Stakes.settleBattle("TEAM", 4, seats(normalPlaces), ranked, false)
		eq(potA, potB)
		eq(leftA, leftB)
		local winners = 0
		for side = 1, 4 do
			local x, y = a[`hunter{side}`], b[`hunter{side}`]
			eq(x.payout, y.payout, `ranked {ranked} side {side} payout`)
			eq(x.share, y.share, `ranked {ranked} side {side} share`)
			eq(x.trophies, y.trophies, `ranked {ranked} side {side} trophies`)
			if ranked and x.share > 0 then
				winners += 1
			end
		end
		if ranked then
			eq(winners, 1, "the pot goes to one camp: no tie split")
		end
	end
end)

test("a clock end in Bone Rush ranks every seat by the chain, unique places", function()
	local r = BattleRules.atClock({
		modeKey = "ROYALE",
		players = {
			{ id = 1, bones = 40, fence = 2, damage = 10, clearTime = 5 },
			{ id = 2, bones = 40, fence = 2, damage = 10, clearTime = 5 },
			{ id = 3, bones = 12, fence = 0, outAt = 1 },
		},
		seed = "match-2",
	})
	eq(r.over, true)
	eq(r.decidedBy, "coinFlip", "level on every step: the seeded flip")
	local places = BattleFlow.royalePlaces(r.ranking)
	local seen = {}
	for _, p in places do
		ok(not seen[p], "unique place")
		seen[p] = true
	end
	eq(places[3], 3)
end)

test("HUD: clock text, the warning banner in the last minute, never over a result", function()
	eq(T.ClockWarning, 60)
	eq(PanelRules.clockText(900), "15:00")
	eq(PanelRules.clockText(59.2), "1:00")
	eq(PanelRules.clockText(5), "0:05")
	eq(PanelRules.clockText(-3), "0:00")
	local function hud(state, left)
		return PanelRules.battleHud(state, "TEAM", false, nil, 0, left)
	end
	eq(hud("Playing", 61).clock, true)
	eq(hud("Playing", 61).clockWarning, false)
	eq(hud("Playing", 60).clockWarning, true)
	eq(hud("Playing", 1).clockWarning, true)
	eq(hud("Playing", 0).clockWarning, false, "at the cap the match is over")
	eq(hud("Building", 890).clock, true, "counts from Building")
	for _, state in { "Victory", "GameOver", "Lobby" } do
		eq(hud(state, 30).clock, false, `{state}: no clock`)
		eq(hud(state, 30).clockWarning, false, `{state}: no banner (no-trap rule)`)
	end
	eq(PanelRules.battleHud("Playing", nil, false, nil, 0, 30).clock, false, "co-op: no clock")
	eq(hud("Playing", nil).clock, false, "no cap: no clock")
end)

test("results: the 'Decided by' line names the step; 'Time's up!' at the clock", function()
	eq(PanelRules.decidedLine("fence", true), "Time's up! Decided by Fence left")
	eq(PanelRules.decidedLine("bones"), "Decided by Bones")
	eq(PanelRules.decidedLine("standing"), "Last camp standing")
	eq(PanelRules.decidedLine("survived"), "Decided by who lasted longer")
	eq(PanelRules.decidedLine("damage"), "Decided by damage dealt to dinos")
	eq(PanelRules.decidedLine("clearTime"), "Decided by faster round clears")
	eq(PanelRules.decidedLine("coinFlip"), "Decided by a coin flip (seeded by the match)")
	eq(PanelRules.decidedLine(nil, true), "Time's up!")
	eq(PanelRules.decidedLine(nil), nil)
	local out = PanelRules.battleResults({
		mode = "TEAM",
		place = 1,
		mySide = 1,
		camps = {},
		practice = false,
		decidedBy = "fence",
		atClock = true,
	})
	eq(out.lines[1], "Time's up! Decided by Fence left", "first line of the results")
end)

test("Studio short clock: shorter caps in Studio only; live always the real cap", function()
	eq(StudioOnly.matchCap(true, 120, 900), 120)
	eq(StudioOnly.matchCap(false, 120, 900), 900, "refused live")
	eq(StudioOnly.matchCap(true, 2000, 900), 900, "never longer")
	eq(StudioOnly.matchCap(true, "x", 1800), 1800)
	eq(StudioOnly.matchCap(true, 0, 900), 900)
	eq(StudioOnly.matchCap(true, 120, nil), nil, "co-op: no clock at all")
end)

local function read(path: string): string
	return fs.readFile(path)
end

test("wiring: matchId always the seed; per-side damage and clear time feed the chain; clock from Building", function()
	local main = read("src/server/Main.server.luau")
	ok(main:find("local matchId: string = HttpService:GenerateGUID(false)", 1, true) ~= nil, "every battle has an id")
	ok(main:find("matchId = matchId, -- always: the tie-break seed (#261)", 1, true) ~= nil, "passed to Battle")
	ok(main:find('action == "clockcap" and typeof(key) == "number" and StudioOnly.allowed(RunService:IsStudio(), "clockCap")', 1, true) ~= nil, "short clock gated")
	local battle = read("src/server/Battle.luau")
	ok(battle:find("seed = ctx.matchId })", 1, true) ~= nil, "teamResult / atClock seeded")
	ok(battle:find("BattleRules.royaleResult(seats, roundsDone, ctx.matchId)", 1, true) ~= nil, "royaleResult seeded")
	ok(battle:find("damage[side] = Enemies.damageDealt(side)", 1, true) ~= nil, "damage per side")
	ok(battle:find("clearTime = clearTime,", 1, true) ~= nil, "clear time from the loop")
	local cap = battle:find("local clockStart = os.clock()", 1, true)
	local building = battle:find('ReplicatedStorage:SetAttribute("State", "Building")', 1, true)
	ok(cap ~= nil and building ~= nil and cap < building, "the clock starts with Building")
	ok(battle:find('ReplicatedStorage:SetAttribute("BattleDecidedBy", result.decidedBy)', 1, true) ~= nil, "results name the step")
	local enemies = read("src/server/Enemies.luau")
	ok(enemies:find("tally(enemy.side, enemy.hp - hp)", 1, true) ~= nil, "HP taken off, never overkill")
	local _, n = string.gsub(enemies, "tally%(enemy%.side", "")
	eq(n, 3, "damage, sink and Eruption all count")
end)
