--[[
	Shared/PlayerLevel: the overall player level (PLAN round 4 T55, DECISIONS #118-#121,
	#124). The curve's totals, an unbounded monotone level, one match's player XP and the
	reward ladder.
]]

local Config = require(src.shared.Config)
local PlayerLevel = require(src.shared.PlayerLevel)

local T = Config.Tuning
local ROUNDS = #Config.Rounds

test("the levers are the seeds this spec means", function()
	eq(T.PlayerXPBase, 500, "Player XP base")
	eq(T.PlayerXPStep, 50, "Player XP step")
	eq(T.PlayerXPPerLevelMax, 10000, "Player XP per level max")
	eq(T.SoloTakeDownXPX, 2, "Solo take-down XP x")
	eq(Config.Difficulties.EASY.clearXp, 500, "Easy Clear XP")
	eq(Config.Difficulties.NORMAL.clearXp, 1000, "Normal Clear XP")
	eq(Config.Difficulties.HARD.clearXp, 1500, "Hard Clear XP")
	eq(Config.Difficulties.CHAOS.clearXp, 2000, "Chaos Clear XP")
	eq(T.XPPerLevel / T.RoundsPerLevel, 100, "round XP")
	eq(T.PopXPCapPerRound, 15, "take-down XP cap a round")
	eq(ROUNDS, 40, "rounds")
end)

test("level totals: L10 6,300, L50 83,300, L100 292,050, L150 625,800, L200 1,082,750", function()
	eq(PlayerLevel.xpFor(1), 0, "L1")
	eq(PlayerLevel.xpFor(2), 500, "L2")
	eq(PlayerLevel.xpFor(10), 6300, "L10")
	eq(PlayerLevel.xpFor(50), 83300, "L50")
	eq(PlayerLevel.xpFor(100), 292050, "L100")
	eq(PlayerLevel.xpFor(150), 625800, "L150")
	eq(PlayerLevel.xpFor(200), 1082750, "L200")
end)

test("each level costs 500 + 50(n-1), capped at 10,000 from level 191", function()
	eq(PlayerLevel.cost(1), 500, "1 -> 2")
	eq(PlayerLevel.cost(2), 550, "2 -> 3")
	eq(PlayerLevel.cost(190), 9950, "190 -> 191, the last below the cap")
	eq(PlayerLevel.cost(191), 10000, "191 -> 192, the first at the cap")
	eq(PlayerLevel.cost(5000), 10000, "far past: still the cap")
	for level = 1, 400 do
		eq(PlayerLevel.xpFor(level + 1) - PlayerLevel.xpFor(level), PlayerLevel.cost(level), `step at {level}`)
	end
end)

test("level(xp) is the inverse of xpFor at every boundary, and monotone", function()
	local last = 1
	for level = 1, 400 do
		local at = PlayerLevel.xpFor(level)
		eq(PlayerLevel.level(at), level, `exactly at L{level}`)
		if level > 1 then
			eq(PlayerLevel.level(at - 1), level - 1, `one short of L{level}`)
		end
		ok(PlayerLevel.level(at) >= last, `monotone at {level}`)
		last = PlayerLevel.level(at)
	end
	for xp = 0, 30000, 37 do
		local now = PlayerLevel.level(xp)
		ok(now >= PlayerLevel.level(math.max(0, xp - 37)), `monotone at {xp} XP`)
	end
end)

test("there's no top level: level 10,000 computes, and more XP keeps raising it", function()
	local total = PlayerLevel.xpFor(10000)
	eq(total, PlayerLevel.xpFor(200) + (10000 - 200) * 10000, "past 200 every level is 10,000")
	eq(PlayerLevel.level(total), 10000, "level 10,000")
	eq(PlayerLevel.level(total - 1), 9999, "one XP short")
	ok(PlayerLevel.level(total * 10) > 10000, "and beyond")
end)

test("garbage XP is level 1 with nothing in it", function()
	for _, bad in { -50 :: any, 0 / 0, math.huge, "9000", nil } do
		eq(PlayerLevel.level(bad), 1, `level of {bad}`)
		local into, needed, level = PlayerLevel.progress(bad)
		eq(into, 0, "into")
		eq(needed, 500, "needed")
		eq(level, 1, "level")
	end
end)

test("progress shows XP into the level and what the level takes", function()
	local into, needed, level = PlayerLevel.progress(6300 + 120)
	eq(level, 10, "level")
	eq(into, 120, "into")
	eq(needed, 950, "L10 -> 11 costs 500 + 50 x 9")
end)

-- 40 cleared rounds with take-downs at the cap: 4,000 round XP + 600 take-down XP.
local ROUND_XP = ROUNDS * 100
local TAKEDOWN_XP = ROUNDS * 15

test("a solo Easy clear with capped take-downs = 5,700; co-op 5,100", function()
	eq(PlayerLevel.matchXp(ROUND_XP, TAKEDOWN_XP, true, true, "EASY"), 5700, "solo")
	eq(PlayerLevel.matchXp(ROUND_XP, TAKEDOWN_XP, false, true, "EASY"), 5100, "co-op")
end)

test("solo doubles only the take-down part", function()
	eq(PlayerLevel.matchXp(300, 0, true, false, "EASY"), 300, "no take-downs: solo = co-op")
	eq(PlayerLevel.matchXp(0, 40, true, false, "EASY"), 80, "take-downs x2")
	eq(PlayerLevel.matchXp(0, 40, false, false, "EASY"), 40, "co-op x1")
end)

test("a lost match gets no clear XP; a harder clear gets more", function()
	eq(PlayerLevel.matchXp(1200, 150, false, false, "CHAOS"), 1350, "lost: banked XP only")
	eq(PlayerLevel.matchXp(0, 0, false, false, "EASY"), 0, "lost round 1: nothing")
	local last = -1
	for _, key in Config.DifficultyOrder do
		local xp = PlayerLevel.matchXp(ROUND_XP, TAKEDOWN_XP, false, true, key)
		ok(xp > last, `{key} clear beats the easier one`)
		last = xp
	end
	eq(PlayerLevel.matchXp(100, 0, false, true, "NOT_A_DIFFICULTY"), 100, "unknown difficulty: no clear XP")
end)

test("bad tallies count as 0, never negative", function()
	eq(PlayerLevel.matchXp(-500, -20, true, false, "EASY"), 0, "negative")
	eq(PlayerLevel.matchXp(0 / 0, math.huge, true, true, "EASY"), 500, "NaN / inf: only the clear")
end)

test("the reward ladder: commons to 99, rares every 10 to 100, legendaries at 150 and 200, titles every 50 past 200", function()
	eq(PlayerLevel.rewardAt(1), "none", "level 1")
	eq(PlayerLevel.rewardAt(2), "common", "level 2")
	eq(PlayerLevel.rewardAt(10), "rare", "level 10")
	eq(PlayerLevel.rewardAt(37), "common", "level 37")
	eq(PlayerLevel.rewardAt(99), "common", "level 99")
	eq(PlayerLevel.rewardAt(100), "rare", "level 100")
	eq(PlayerLevel.rewardAt(120), "none", "level 120")
	eq(PlayerLevel.rewardAt(150), "legendary", "level 150")
	eq(PlayerLevel.rewardAt(200), "legendary", "level 200")
	eq(PlayerLevel.rewardAt(225), "none", "level 225")
	eq(PlayerLevel.rewardAt(250), "title", "level 250")
	eq(PlayerLevel.rewardAt(10000), "title", "level 10,000")
	local commons, rares = 0, 0
	for level = 1, 100 do
		local r = PlayerLevel.rewardAt(level)
		if r == "common" then
			commons += 1
		elseif r == "rare" then
			rares += 1
		end
	end
	eq(commons, 89, "89 commons (DECISIONS #121)")
	eq(rares, 10, "10 rares")
end)
