--[[
	Shared/HeroXp: hero XP and levels (PLAN round 3 T34, DECISIONS #100-#103). A cleared
	round banks Round XP plus a little pop XP; the level stays between the old
	every-5-rounds curve and one level above it. Server/Hero banks with these functions,
	so a match is replayed here by calling `bank` once per cleared round.
]]

local Config = require(src.shared.Config)
local HeroXp = require(src.shared.HeroXp)

local T = Config.Tuning
local LAST = #Config.Rounds

-- XP after clearing rounds 1..rounds with the same pops every round.
local function after(rounds: number, ownPops: number, teamPops: number): number
	local xp = 0
	for round = 1, rounds do
		xp = HeroXp.bank(xp, ownPops, teamPops, round)
	end
	return xp
end

test("the levers are the seeds this spec means", function()
	eq(T.XPPerLevel, 500, "XP per level")
	eq(T.RoundsPerLevel, 5, "Rounds per level")
	eq(T.XPPerPop, 0.25, "XP per pop")
	eq(T.PopXPCapPerRound, 15, "Pop XP cap per round")
	eq(T.TeamPopShare, 0.25, "Team pop share")
	eq(T.HeroLevelLeadCap, 1, "Hero level lead cap")
	eq(LAST, 40, "rounds")
end)

test("Round XP is XP per level / Rounds per level (100)", function()
	eq(HeroXp.roundXp(), 100)
	eq(HeroXp.roundXp() * T.RoundsPerLevel, T.XPPerLevel, "five clears = one level")
end)

test("the round level is the old every-5-rounds curve", function()
	eq(HeroXp.roundLevel(0), 1, "start")
	eq(HeroXp.roundLevel(4), 1, "after 4")
	eq(HeroXp.roundLevel(5), 2, "after 5")
	eq(HeroXp.roundLevel(39), 8, "after 39")
	eq(HeroXp.roundLevel(40), 9, "after 40")
end)

test("no pops: the level is exactly the old curve after every round 0..40", function()
	for rounds = 0, LAST do
		local xp = after(rounds, 0, 0)
		eq(xp, rounds * 100, `XP after {rounds}`)
		eq(xp, HeroXp.floorXp(rounds), `floor after {rounds}`)
		eq(HeroXp.level(xp, rounds), 1 + math.floor(rounds / 5), `level after {rounds}`)
	end
end)

test("capped pops every round: level 3 after 9, 5 after 18, 9 after 35", function()
	eq(after(1, 400, 400), 115, "one capped round banks 115")
	eq(HeroXp.level(after(8, 400, 400), 8), 2, "after 8")
	eq(HeroXp.level(after(9, 400, 400), 9), 3, "after 9")
	eq(HeroXp.level(after(17, 400, 400), 17), 4, "after 17")
	eq(HeroXp.level(after(18, 400, 400), 18), 5, "after 18")
	eq(HeroXp.level(after(34, 400, 400), 34), 8, "after 34")
	eq(HeroXp.level(after(35, 400, 400), 35), 9, "after 35")
end)

test("capped pops every round: never more than the lead cap above the round level", function()
	local ahead = 0
	for rounds = 0, LAST do
		local level = HeroXp.level(after(rounds, 400, 400), rounds)
		local floorLevel = HeroXp.roundLevel(rounds)
		ok(level >= floorLevel, `below the floor after {rounds}`)
		ok(level <= floorLevel + T.HeroLevelLeadCap, `past the lead cap after {rounds}: {level} vs {floorLevel}`)
		if level > floorLevel then
			ahead += 1
		end
	end
	ok(ahead > 0, "pop XP never put the hunter ahead at all")
end)

test("pop XP: own pops, a share of teammates', rounded down and capped", function()
	eq(HeroXp.popXp(0, 0), 0, "no pops")
	eq(HeroXp.popXp(3, 3), 0, "3 own pops = 0.75, rounds down")
	eq(HeroXp.popXp(4, 4), 1, "4 own pops")
	eq(HeroXp.popXp(7, 7), 1, "7 own pops = 1.75, rounds down")
	eq(HeroXp.popXp(4, 20), 2, "4 own + 16 teammates' at a quarter share")
	eq(HeroXp.popXp(0, 16), 1, "teammates only")
	eq(HeroXp.popXp(0, 15), 0, "teammates only, rounds down")
	eq(HeroXp.popXp(60, 60), 15, "exactly the cap")
	eq(HeroXp.popXp(1000, 1000), 15, "past the cap")
	eq(HeroXp.popXp(0, 400), 15, "a Medic with no pops in a busy lobby still caps")
end)

test("pop XP survives odd input", function()
	eq(HeroXp.popXp(5, 2), 1, "team below own counts no teammates")
	eq(HeroXp.popXp(-5, -5), 0, "negative pops")
	eq(HeroXp.popXp(4.9, 4.9), 1, "fractional pops round down first")
end)

test("a joiner at round 23 starts on the floor: 2,300 XP, level 5", function()
	eq(HeroXp.floorXp(23), 2300)
	eq(HeroXp.level(HeroXp.floorXp(23), 23), 5)
	eq(HeroXp.floorXp(0), 0, "a fresh match")
	eq(HeroXp.bank(0, 0, 0, 23), 2300, "banking never leaves a hunter below the floor")
end)

test("a huge pending value can't pass the ceiling", function()
	local xp = HeroXp.bank(0, 1e9, 1e9, 1)
	eq(xp, 115, "a billion pops bank the cap, no more")
	-- Even XP that should never exist is held under round level + lead cap + 1.
	for _, rounds in { 1, 9, 23, 40 } do
		local held = HeroXp.bank(1e9, 1e9, 1e9, rounds)
		local top = HeroXp.roundLevel(rounds) + T.HeroLevelLeadCap
		ok(held < top * T.XPPerLevel, `XP {held} reaches level {top + 1} after {rounds}`)
		eq(1 + math.floor(held / T.XPPerLevel), top, `raw level after {rounds}`)
		eq(HeroXp.level(held, rounds), top, `level after {rounds}`)
	end
end)

test("the level is clamped both ways whatever the XP", function()
	eq(HeroXp.level(0, 23), 5, "no XP at round 23 still has the round level")
	eq(HeroXp.level(1e9, 0), 1 + T.HeroLevelLeadCap, "absurd XP before round 1")
	eq(HeroXp.level(499, 0), 1, "one short of level 2")
	eq(HeroXp.level(500, 0), 2, "level 2 on the dot")
	eq(HeroXp.level(-50, 0), 1, "negative XP")
end)

test("XP never falls and a level never drops as rounds are cleared", function()
	for _, pops in { 0, 7, 30, 400 } do
		local xp, level = 0, 1
		for round = 1, LAST do
			local nextXp = HeroXp.bank(xp, pops, pops, round)
			local nextLevel = HeroXp.level(nextXp, round)
			ok(nextXp >= xp + HeroXp.roundXp(), `round {round} with {pops} pops banked less than Round XP`)
			ok(nextLevel >= level, `level fell at round {round} with {pops} pops`)
			xp, level = nextXp, nextLevel
		end
	end
end)

test("the same inputs always give the same answer (no clock, no player)", function()
	for _ = 1, 3 do
		eq(HeroXp.bank(1234, 37, 100, 12), 1347)
		eq(HeroXp.level(1347, 12), 3)
		eq(HeroXp.popXp(37, 100), 13)
	end
end)

-- The HUD's XP bar (PLAN round 3 T35).

local function progress(xp: number, roundsCleared: number): string
	local shown, needed, level = HeroXp.progress(xp, roundsCleared)
	return `Lv {level} {shown}/{needed}`
end

test("the XP bar: XP into the level, XP a level takes, the level", function()
	eq(progress(0, 0), "Lv 1 0/500", "a fresh match")
	eq(progress(240, 2), "Lv 1 240/500", "part way")
	eq(progress(2300, 23), "Lv 5 300/500", "a joiner at round 23")
	eq(progress(1035, 9), "Lv 3 35/500", "capped pops after round 9")
end)

test("the XP bar: the level-up edge", function()
	eq(progress(499, 4), "Lv 1 499/500", "one short")
	eq(progress(500, 5), "Lv 2 0/500", "on the dot")
	eq(progress(501, 5), "Lv 2 1/500", "one over")
end)

test("the XP bar: the clamp edges never show a negative or overfull bar", function()
	eq(progress(1e9, 0), "Lv 2 499/500", "absurd XP: the lead cap, one short of full")
	eq(progress(999, 0), "Lv 2 499/500", "the most XP bank allows before round 5")
	eq(progress(0, 23), "Lv 5 0/500", "XP below the floor: the round level, empty")
	for rounds = 0, LAST do
		for _, pops in { 0, 400 } do
			local xp = after(rounds, pops, pops)
			local shown, needed, level = HeroXp.progress(xp, rounds)
			ok(shown >= 0 and shown < needed, `bar {shown}/{needed} after {rounds}`)
			eq(level, HeroXp.level(xp, rounds), `level after {rounds}`)
			eq((level - 1) * needed + shown, xp, `the bar accounts for every XP after {rounds}`)
		end
	end
end)

test("the XP bar: pending pop XP is shown beside it, not counted in it", function()
	local before = progress(240, 2)
	local pending = HeroXp.popXp(48, 48)
	eq(pending, 12, "48 take-downs this round")
	eq(progress(240, 2), before, "the bar doesn't move while the round is on")
	eq(progress(HeroXp.bank(240, 48, 48, 3), 3), "Lv 1 352/500", "the clear banks 100 + 12")
end)

-- What the balance tools assume (PLAN round 3 T36, DECISIONS #101).

test("the last round is fought at round level 8, and no hunter is above level 9 in play", function()
	-- tools/export_constants.py compares the best hero at this level with the best
	-- tower at the round level; tools/value.py prints heroes at the floor and floor + 1.
	local lastRoundLevel = HeroXp.roundLevel(LAST - 1)
	eq(lastRoundLevel, 8, "round level during the last round")
	local highest = 0
	for round = 1, LAST do
		local cleared = round - 1 -- what a hunter has while round `round` is fought
		for _, xp in { after(cleared, 0, 0), after(cleared, 400, 400), 1e9 } do
			local level = HeroXp.level(xp, cleared)
			ok(level <= HeroXp.roundLevel(cleared) + T.HeroLevelLeadCap, `round {round}: level {level}`)
			highest = math.max(highest, level)
		end
	end
	eq(highest, lastRoundLevel + T.HeroLevelLeadCap, "highest hero level in play")
	eq(HeroXp.level(after(LAST - 1, 400, 400), LAST - 1), 9, "capped take-downs reach it honestly")
end)
