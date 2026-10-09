--[[
	Shared/BattleLoop (PLAN Phase 8 batch 2 T103, DECISIONS #251, #258): the battle round
	driver on a fake clock. Played rounds only, skipped rounds paid once as the next played
	round starts, Battle round time (60 s) still forces a round, Final Stampede only in Camp
	Clash. Plus the T103 wiring the server can't run headless (read from the source).
]]
local fs = require("@lune/fs")
local Config = require(src.shared.Config)
local BattleLoop = require(src.shared.BattleLoop)
local Pace = require(src.shared.Pace)

local T = Config.Tuning
local LAST = #Config.Rounds

-- A fake battle. `clearAfter` = seconds a round takes to clear (nil = never clears);
-- `stopAfter` = rounds started before tick() ends it (a camp falls), nil = never.
local function play(modeKey: string, competitive: boolean, opts: { first: number?, clearAfter: number?, stopAfter: number?, sides: number? }?)
	local o = opts or {}
	local clock = 0
	local started: { number } = {}
	local startedAt: { [number]: number } = {}
	local ended: { number } = {}
	local paid: { { number } } = {}
	local events: { string } = {}
	local roundStart = 0
	local current = 0
	local result, round = BattleLoop.run({
		modeKey = modeKey,
		competitive = competitive,
		first = Pace.firstRound(modeKey, competitive, o.first),
		poll = 0.25,
		now = function()
			return clock
		end,
		wait = function(s)
			clock += s
		end,
		tick = function()
			if o.stopAfter and #started >= o.stopAfter and clock - roundStart > 1 then
				return "fell"
			end
			return nil
		end,
		cleared = function(r)
			eq(r, current, "cleared() asks about the current round")
			local done = o.clearAfter ~= nil and clock - roundStart >= o.clearAfter
			local out = {}
			for side = 1, o.sides or 2 do
				out[side] = done
			end
			return out
		end,
		startRound = function(r)
			table.insert(started, r)
			table.insert(events, `start {r}`)
			startedAt[r] = clock
			roundStart = clock
			current = r
		end,
		endRound = function(r)
			table.insert(ended, r)
		end,
		paySkipped = function(from, to)
			table.insert(paid, { from, to })
			table.insert(events, `pay {from}-{to}`)
		end,
		finish = function()
			return "rounds done"
		end,
	})
	return { result = result, round = round, started = started, startedAt = startedAt, ended = ended, paid = paid, events = events }
end

local function join(list: { number }): string
	return table.concat(list, ",")
end

test("Bone Rush casual: plays 1, 4 ... 40 and ends at 40; each skipped pair paid once, before its round", function()
	local m = play("ROYALE", false, { clearAfter = 20 })
	eq(m.result, "rounds done")
	eq(m.round, LAST)
	eq(join(m.started), join(Pace.playedRounds("ROYALE", false)), "the casual list")
	eq(join(m.ended), join(m.started), "every started round ended")
	eq(#m.paid, 13, "13 gaps (2-3 ... 38-39)")
	local seen = {}
	for _, gap in m.paid do
		for r = gap[1], gap[2] do
			ok(not seen[r], `round {r} paid once`)
			seen[r] = true
			ok(not Pace.isPlayed(r, "ROYALE", false), `round {r} is skipped`)
		end
	end
	for r = 1, LAST do
		eq(seen[r] == true, not Pace.isPlayed(r, "ROYALE", false), `round {r}`)
	end
	-- Paid as the round starts: "pay 2-3" right before "start 4".
	local at = table.find(m.events, "start 4")
	eq(m.events[(at :: number) - 1], "pay 2-3", "paid at the start of round 4")
	eq(m.events[1], "start 1", "round 1: nothing skipped before it")
end)

test("Ranked: 2, 4 ... 40; round 1 paid at round 2's start; Camp Clash goes on into Final Stampede", function()
	local m = play("TEAM", true, { clearAfter = 10, stopAfter = 23 })
	eq(m.result, "fell")
	eq(m.events[1], "pay 1-1", "round 1 skipped, paid first")
	eq(m.events[2], "start 2")
	local want = Pace.playedRounds("TEAM", true)
	table.insert(want, LAST + 1)
	table.insert(want, LAST + 2)
	table.insert(want, LAST + 3)
	eq(join(m.started), join(want), "20 played rounds, then Final Stampede 1-3")
	eq(#m.paid, 20, "rounds 1, 3 ... 39: nothing paid in Final Stampede")
end)

test("lockstep: a round that never clears is forced at Battle round time (60 s); a cleared one waits the break", function()
	eq(T.BattleRoundTime, 60, "B143 (#251)")
	local stuck = play("ROYALE", false, { stopAfter = 4 })
	for i = 2, #stuck.started do
		local gap = stuck.startedAt[stuck.started[i]] - stuck.startedAt[stuck.started[i - 1]]
		ok(gap >= 60 and gap < 60.5, `forced after 60 s (took {gap})`)
	end
	local quick = play("ROYALE", false, { clearAfter = 12, stopAfter = 4 })
	local gap = quick.startedAt[quick.started[2]] - quick.startedAt[quick.started[1]]
	ok(gap >= 12 + T.BattleRoundBreak and gap < 12 + T.BattleRoundBreak + 0.6, `cleared at 12 s + the {T.BattleRoundBreak} s break (took {gap})`)
end)

test("Studio 'Start at round 37' (casual): 37 then 40, the 38-39 supplies paid once; 38 snaps to 40", function()
	local m = play("TEAM", false, { first = 37, clearAfter = 5, stopAfter = 3 })
	eq(join({ m.started[1], m.started[2], m.started[3] }), "37,40,41")
	eq(m.events[1], "pay 35-36", "the gap before 37 (the list's own step)")
	ok(table.find(m.events, "pay 38-39") ~= nil, "38-39 at 40's start")
	eq(play("ROYALE", false, { first = 38, clearAfter = 5 }).started[1], 40)
end)

test("co-op is paced too but never skips: crowd 1, every round, nothing paid (#258)", function()
	eq(Pace.crowd("COOP"), 1)
	for r = 1, LAST do
		eq(Pace.isPlayed(r, "COOP"), true)
		local from, to = Pace.skippedBefore(r, "COOP")
		ok(from > to, `co-op round {r}: nothing skipped`)
	end
	eq(Pace.firstRound("COOP", false, 23), 23, "co-op Start at round N unchanged")
	-- Round 1, Easy solo: the sheet's gap, fewer dinos, each tougher; the spawn phase shrinks.
	local rd, easy = Config.Rounds[1], Config.Difficulties.EASY
	local plan = Pace.plan(1, easy.countMult, easy.promoteChance, easy)
	local before, after = 0, 0
	for key, n in rd.counts do
		before += math.max(1, math.floor(n * easy.countMult + 0.5))
		after += plan.counts[key] or 0
	end
	ok(after < before, `round 1: {after} dinos instead of {before}`)
	local gap = rd.spawnGap / easy.countMult
	ok(after * gap < before * gap * 0.5, "round 1's spawn phase is under half the unpaced one at the same gap")
	ok(plan.hpX > 1, "each round-1 dino is tougher than unpaced")
end)

local function read(path: string): string
	return fs.readFile(path)
end

test("wiring: Waves paces every round by Pace.plan at the sheet's gap; kill cash and leaks carry the factors", function()
	local waves = read("src/server/Waves.luau")
	ok(waves:find("local gap = round.spawnGap / math.max(countMult * (options.crowd or 1), 0.01)", 1, true) ~= nil, "gap not paced; / crowd (#258)")
	ok(waves:find("Pace.plan(options.index, countMult, scale.promoteChance, { speedMult = options.speedMult }, options.crowd)", 1, true) ~= nil, "plan per round")
	ok(waves:find("local count = plan.counts[key]", 1, true) ~= nil, "the plan's counts")
	ok(waves:find("* plan.hpX", 1, true) ~= nil, "the plan's HP")
	ok(waves:find("Enemies.enqueue(options.side, spawnKey, hpMult, plan.cashX, plan.leakX)", 1, true) ~= nil, "cash and leak factors")
	ok(read("src/server/Main.server.luau"):find("enemy.share * enemy.cashX * Config.Tuning.CashPerEffectiveHP", 1, true) ~= nil, "kill cash x cashX")
	ok(read("src/server/Main.server.luau"):find("speedMult = chosen.speedMult, -- the pace factor's walk", 1, true) ~= nil, "co-op passes the speed")
	ok(read("src/server/Enemies.luau"):find("enemy.size / enemy.sizes * enemy.leakX", 1, true) ~= nil, "leak cost x leakX")
	local battle = read("src/server/Battle.luau")
	ok(battle:find("crowd = Pace.crowd(modeKey)", 1, true) ~= nil, "battles: Battle crowd x")
	ok(battle:find("BattleLoop.run(", 1, true) ~= nil, "battles: the round driver")
	ok(battle:find("Pace.firstRound(modeKey, ctx.competitive, ctx.startRound)", 1, true) ~= nil, "battles: the first played round")
	ok(battle:find("Pace.skippedIncome(from, to, hunterCount(side), chosen, density)", 1, true) ~= nil, "battles: skipped income")
end)

test("Ability tempo (#259): cooldowns / 2, hospital heal x 2, wired in Hero and Towers", function()
	eq(Pace.abilityCooldown(35), 17.5)
	eq(Pace.healRate(3), 6)
	ok(read("src/server/Hero.luau"):find("Pace.abilityCooldown(s.stats.abilityCooldown", 1, true) ~= nil, "Hero")
	local towers = read("src/server/Towers.luau")
	ok(towers:find("heal = math.max(heal, Pace.healRate(s.healPerSecond))", 1, true) ~= nil, "Field Hospital heal")
end)

test("the supplies feed line (T103): '+N supplies for rounds X–Y', one round named alone", function()
	local BattleFlow = require(src.shared.BattleFlow)
	eq(BattleFlow.suppliesLine(1234.9, 2, 3), "+1234 supplies for rounds 2–3")
	eq(BattleFlow.suppliesLine(77, 1, 1), "+77 supplies for round 1")
end)
