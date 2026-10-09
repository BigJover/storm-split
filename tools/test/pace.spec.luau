--[[
	Shared/Pace (PLAN Phase 8 batch 2 T100, DECISIONS #250-#254): round pace, the battle
	round lists, skipped-round income, late-join catch-up cash and the match clock caps.
]]

local Config = require(src.shared.Config)
local Pace = require(src.shared.Pace)
local BattleFlow = require(src.shared.BattleFlow)

local T = Config.Tuning
local LAST = #Config.Rounds
local D = Config.Difficulties

test("the seeds this spec means", function()
	eq(T.RoundPace, 0.4, "Round pace (#250)")
	eq(T.TrackWalkSeconds, 14, "Track walk seconds")
	eq(T.CasualRoundStep, 3, "Casual round step (#251)")
	eq(T.RankedRoundStep, 2, "Ranked round step (#251)")
	eq(T.CasualMatchCap, 900, "Casual match cap (#252)")
	eq(T.RankedMatchCap, 1800, "Ranked match cap (#252)")
	eq(T.ClockWarning, 60, "Clock warning (#252)")
	eq(T.LateJoinCashX, 1.1, "Late join cash x (#254)")
	eq(T.StartingCashPerExtraPlayer, 200, "the catch-up floor")
	eq(LAST, 40, "rounds")
	eq(#Config.DifficultyOrder, 4, "difficulties")
end)

-- The unpaced length, computed here on its own: the Rounds sheet's enemies x gap + 14 / speed.
local function unpaced(round: number, difficulty): number
	local rd = Config.Rounds[round]
	local enemies = 0
	for _, n in rd.counts do
		enemies += n
	end
	return enemies * rd.spawnGap + 14 / difficulty.speedMult
end

test("Required DPS is unchanged by pace: every round x every difficulty (1e-9)", function()
	for _, key in Config.DifficultyOrder do
		local d = D[key]
		for round = 1, LAST do
			local ehp = Config.Rounds[round].effectiveHp * d.hpMult -- any unpaced EHP will do
			local paced = Pace.roundLength(round, d)
			local before = ehp / unpaced(round, d)
			local after = ehp * Pace.hpX(round, d) / paced
			near(after, before, `{key} round {round}`, 1e-9)
			ok(paced < unpaced(round, d), `{key} round {round} is shorter`)
			ok(Pace.hpX(round, d) > 0 and Pace.hpX(round, d) < 1, `{key} round {round} hpX in (0, 1)`)
		end
	end
end)

test("paced length = pace x spawn phase + walk; spawn gap x pace; past the table the last row", function()
	local n = D.NORMAL
	local rd = Config.Rounds[20]
	local enemies = 0
	for _, c in rd.counts do
		enemies += c
	end
	near(Pace.roundLength(20, n), 0.4 * enemies * rd.spawnGap + 14 / n.speedMult, "round 20 Normal", 1e-9)
	near(Pace.roundLength(20, n), 55.7, "the 56 s PLAN quotes", 0.05)
	for round = 1, LAST do
		near(Pace.spawnGap(round), Config.Rounds[round].spawnGap * 0.4, `gap {round}`, 1e-12)
	end
	eq(Pace.hpX(LAST + 3, n), Pace.hpX(LAST, n), "Final Stampede repeats the last row")
	eq(Pace.spawnGap(LAST + 1), Pace.spawnGap(LAST))
end)

test("Battle round time covers the longest paced Normal and Chaos round (#251)", function()
	for _, key in { "NORMAL", "CHAOS" } do
		local longest = 0
		for round = 1, LAST do
			longest = math.max(longest, Pace.roundLength(round, D[key]))
		end
		ok(T.BattleRoundTime >= longest, `{key}: {longest} s`)
	end
end)

local function list(from: number, to: number, by: number): { number }
	local out = {}
	for r = from, to, by do
		table.insert(out, r)
	end
	return out
end

test("round lists: casual 1, 4 ... 40 (14), Ranked 2, 4 ... 40 (20), co-op all 40 (#251)", function()
	for _, mode in { "TEAM", "ROYALE" } do
		local casual = Pace.playedRounds(mode, false)
		eq(#casual, 14, `{mode} casual count`)
		eq(table.concat(casual, ","), table.concat(list(1, 40, 3), ","), `{mode} casual`)
		local ranked = Pace.playedRounds(mode, true)
		eq(#ranked, 20, `{mode} ranked count`)
		eq(table.concat(ranked, ","), table.concat(list(2, 40, 2), ","), `{mode} ranked`)
		eq(casual[#casual], 40, "casual ends at 40")
		eq(ranked[#ranked], 40, "ranked ends at 40")
	end
	eq(table.concat(Pace.playedRounds("COOP"), ","), table.concat(list(1, 40, 1), ","), "co-op")
	eq(#Pace.playedRounds("COOP", true), 40, "co-op ignores competitive")
end)

test("isPlayed agrees with the lists", function()
	for _, case in { { "COOP", false }, { "TEAM", false }, { "TEAM", true }, { "ROYALE", false }, { "ROYALE", true } } do
		local mode, competitive = case[1], case[2]
		local inList = {}
		for _, r in Pace.playedRounds(mode, competitive) do
			inList[r] = true
		end
		for r = 1, LAST do
			eq(Pace.isPlayed(r, mode, competitive), inList[r] == true, `{mode} {competitive} round {r}`)
		end
		eq(Pace.isPlayed(0, mode, competitive), false)
		eq(Pace.isPlayed(LAST + 1, mode, competitive), false, "overtime isn't a table round")
	end
end)

test("expectedIncome: value.py's numbers, and the side scale is BattleFlow.sideScale's", function()
	near(Pace.expectedIncome(1, 1, D.EASY), 77, "Easy solo round 1 (value.py 77)", 0.5)
	near(Pace.expectedIncome(20, 1, D.EASY), 1560, "Easy solo round 20 (value.py 1560)", 0.5)
	near(Pace.expectedIncome(20, 4, D.NORMAL), 6082.2, "Normal x4 round 20 (value.py 6082.2)", 0.5)
	eq(Pace.expectedIncome(0, 1, D.EASY), 0, "no round 0")
	eq(Pace.expectedIncome(LAST + 1, 1, D.EASY), 0, "Final Stampede has no table income")
	-- The same scale BattleFlow gives a side: count x and HP x from its own hunters; promotion
	-- as Server/Waves builds it (each ground, non-boss species -> the next in EnemyOrder).
	local promo, previous = {}, nil
	for _, key in Config.EnemyOrder do
		local def = Config.Enemies[key]
		if not def.flying and not def.boss then
			if previous then
				promo[previous] = key
			end
			previous = key
		end
	end
	for _, hunters in { 1, 3, 5 } do
		local scale = BattleFlow.sideScale(D.HARD, hunters)
		local rd = Config.Rounds[25]
		local p, ehp = scale.promoteChance, 0
		for key, n in rd.counts do
			local each = Config.Enemies[key].effectiveHp
			local up = promo[key]
			if up and p > 0 then
				each = (1 - p) * each + p * Config.Enemies[up].effectiveHp
			end
			ehp += math.max(1, math.floor(n * scale.countMult * 0.6 + 0.5)) * each
		end
		local want = (ehp * rd.hpMult * scale.hpMult * T.CashPerEffectiveHP + T.RoundBonusBase + T.RoundBonusPerRound * 25) * D.HARD.cashMult
		near(Pace.expectedIncome(25, hunters, D.HARD, 0.6), want, `Hard {hunters} hunters, density 0.6`, 1e-6)
	end
end)

test("skipped + played income = co-op's cumulative income to round 40 (#251)", function()
	for _, key in Config.DifficultyOrder do
		for _, hunters in { 1, 2, 5 } do
			for _, density in { 1, 0.6 } do
				local coop = Pace.skippedIncome(1, LAST, hunters, D[key], density)
				local direct = 0
				for r = 1, LAST do
					direct += Pace.expectedIncome(r, hunters, D[key], density)
				end
				near(coop, direct, "skippedIncome sums expectedIncome", 1e-6)
				for _, competitive in { false, true } do
					local paid, previous = 0, 0
					for _, r in Pace.playedRounds("TEAM", competitive) do
						paid += Pace.skippedIncome(previous + 1, r - 1, hunters, D[key], density) -- at the round's start
						paid += Pace.expectedIncome(r, hunters, D[key], density) -- earned in it
						previous = r
					end
					near(paid, coop, `{key} {hunters} hunters density {density} competitive {competitive}`, 1e-6)
				end
			end
		end
	end
	eq(Pace.skippedIncome(5, 4, 1, D.EASY), 0, "nothing skipped")
end)

test("catchUpCash: the floor at round 1, monotonic, 1.1 x one more hunter's income (#254)", function()
	for _, key in Config.DifficultyOrder do
		for _, hunters in { 0, 1, 2, 4, 9 } do
			eq(Pace.catchUpCash(1, hunters, D[key]), T.StartingCashPerExtraPlayer, `{key} {hunters}: round 1 = the floor only`)
			local last = 0
			for r = 1, LAST do
				local cash = Pace.catchUpCash(r, hunters, D[key])
				ok(cash >= last, `{key} {hunters} hunters: round {r} not below round {r - 1}`)
				ok(cash >= T.StartingCashPerExtraPlayer, "never below the floor")
				last = cash
			end
		end
	end
	local n = D.NORMAL
	local marginal = Pace.skippedIncome(1, 29, 3, n) - Pace.skippedIncome(1, 29, 2, n)
	near(Pace.catchUpCash(30, 2, n), 1.1 * marginal, "joining a camp of 2 at round 30", 1e-6)
	ok(Pace.catchUpCash(30, 2, n) > 10 * T.StartingCashPerExtraPlayer, "well above the old flat 200 by round 30")
	near(Pace.catchUpCash(30, 0, n, 0.6), 1.1 * Pace.skippedIncome(1, 29, 1, n, 0.6), "a new camp (Bone Rush plot): its whole income", 1e-6)
end)

test("matchCap: casual 900, Ranked 1800, none in co-op (#252)", function()
	eq(Pace.matchCap("COOP"), nil)
	eq(Pace.matchCap("COOP", true), nil)
	for _, mode in { "TEAM", "ROYALE" } do
		eq(Pace.matchCap(mode, false), 900, `{mode} casual`)
		eq(Pace.matchCap(mode), 900, `{mode} default casual`)
		eq(Pace.matchCap(mode, true), 1800, `{mode} ranked`)
	end
end)

test("clockWarning: the last 60 s before the cap, not at or after it, never without a cap", function()
	eq(Pace.clockWarning(839.9, 900), false)
	eq(Pace.clockWarning(840, 900), true)
	eq(Pace.clockWarning(899.9, 900), true)
	eq(Pace.clockWarning(900, 900), false, "at the cap the match is over")
	eq(Pace.clockWarning(1740, 1800), true)
	eq(Pace.clockWarning(1739, 1800), false)
	eq(Pace.clockWarning(5000, nil), false, "co-op")
end)
