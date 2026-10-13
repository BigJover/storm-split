--[[
	Upgrades.check: the crossover rule (UPGRADES.md). At most two of three paths open, and
	only one of them past the cap (2, or 3 with hero mastery level 20).
]]

local Config = require(src.shared.Config)
local Upgrades = require(src.shared.Upgrades)

local MAX = 5

-- { tiers, path, secondaryCap, expected }
local CASES = {
	-- Fresh tower: any path may open.
	{ { 0, 0, 0 }, 1, nil, "ok" },
	{ { 0, 0, 0 }, 3, nil, "ok" },
	-- Maxed path, and a path index that doesn't exist.
	{ { 5, 0, 0 }, 1, nil, "maxed" },
	{ { 5, 2, 0 }, 1, nil, "maxed" },
	{ { 0, 0, 0 }, 4, nil, "maxed" },
	-- A third path never opens, whatever the tiers.
	{ { 1, 1, 0 }, 3, nil, "third path" },
	{ { 0, 2, 2 }, 1, nil, "third path" },
	{ { 5, 2, 0 }, 3, nil, "third path" },
	{ { 3, 3, 0 }, 3, 3, "third path" },
	-- Two open paths may keep going up to the cap.
	{ { 1, 1, 0 }, 1, nil, "ok" },
	{ { 2, 1, 0 }, 2, nil, "ok" },
	{ { 4, 1, 0 }, 2, nil, "ok" },
	{ { 4, 1, 0 }, 1, nil, "ok" },
	-- Tier 2/2 edges: either path may be the one that goes past 2...
	{ { 2, 2, 0 }, 1, nil, "ok" },
	{ { 2, 2, 0 }, 2, nil, "ok" },
	{ { 0, 2, 2 }, 3, nil, "ok" },
	-- ...but once one has, the other stops at 2.
	{ { 3, 2, 0 }, 2, nil, "crossover" },
	{ { 2, 3, 0 }, 1, nil, "crossover" },
	{ { 5, 2, 0 }, 2, nil, "crossover" },
	{ { 3, 2, 0 }, 1, nil, "ok" },
	-- Cap 3 (mastery level 20): the same rule one tier higher.
	{ { 2, 3, 0 }, 1, 3, "ok" },
	{ { 3, 3, 0 }, 1, 3, "ok" },
	{ { 3, 3, 0 }, 2, 3, "ok" },
	{ { 4, 3, 0 }, 2, 3, "crossover" },
	{ { 3, 4, 0 }, 1, 3, "crossover" },
	{ { 5, 3, 0 }, 2, 3, "crossover" },
	{ { 4, 2, 0 }, 2, 3, "ok" },
}

for _, case in CASES do
	local tiers, path, cap, expected = case[1], case[2], case[3], case[4]
	local name = `tiers {table.concat(tiers, "/")} path {path} cap {cap or 2}`
	test(name, function()
		eq(Upgrades.check(tiers, path, MAX, cap), expected, name)
	end)
end

-- A/B/C (PLAN T111, DECISIONS #275-#278): Config's shape, as the exporter writes it. Tier
-- 4 has A and B, tier 5 has A and C, so a hero path composes 2 x 2 tier-5 and tier-6 rows.
local function fakePath(hero: boolean)
	local path = { tiers = { "t1", "t2", "t3" }, t4 = { A = "4A", B = "4B" }, t5 = { AA = "5AA", AC = "5AC", BA = "5BA", BC = "5BC" } } :: any
	if hero then
		path.t6 = { AA = "6AA", AC = "6AC", BA = "6BA", BC = "6BC" }
	end
	return path
end
local TOWER = { paths = { fakePath(false), fakePath(false) } }
local HERO = { paths = { fakePath(true) } }

test("stepFor returns the next tier's row with its pick, nil when maxed", function()
	eq(Upgrades.stepFor(TOWER, { 0, 0 }, { "", "" }, 1, nil), "t1")
	eq(Upgrades.stepFor(TOWER, { 2, 0 }, { "", "" }, 1, nil), "t3")
	eq(Upgrades.stepFor(TOWER, { 3, 0 }, { "", "" }, 1, "B"), "4B")
	eq(Upgrades.stepFor(TOWER, { 4, 0 }, { "B", "" }, 1, "C"), "5BC")
	eq(Upgrades.stepFor(TOWER, { 4, 0 }, { "A", "" }, 1, "A"), "5AA")
	local row, why = Upgrades.stepFor(TOWER, { 5, 0 }, { "BC", "" }, 1, nil)
	eq(row, nil)
	eq(why, "maxed")
	eq(select(2, Upgrades.stepFor(TOWER, { 0, 0 }, { "", "" }, 3, nil)), "unknown path")
end)

-- Hero paths have six tiers (PLAN T53, DECISIONS #133); towers keep five. The crossover
-- rule is unchanged: max build 6/2/0, or 6/3/0 at mastery level 20.
local HERO_MAX = 6
local HERO_CASES = {
	{ { 5, 2, 0 }, 1, nil, "ok" }, -- 6/2/0
	{ { 6, 2, 0 }, 1, nil, "maxed" },
	{ { 6, 2, 0 }, 2, nil, "crossover" },
	{ { 6, 2, 0 }, 3, nil, "third path" },
	{ { 5, 3, 0 }, 1, 3, "ok" }, -- 6/3/0 at mastery 20
	{ { 6, 3, 0 }, 1, 3, "maxed" },
	{ { 6, 3, 0 }, 2, 3, "crossover" },
	{ { 3, 2, 0 }, 2, nil, "crossover" }, -- 3/3/0 refused without mastery 20
	{ { 2, 3, 0 }, 1, nil, "crossover" },
	{ { 3, 3, 0 }, 1, nil, "crossover" },
}
for _, case in HERO_CASES do
	local tiers, path, cap, expected = case[1], case[2], case[3], case[4]
	local name = `hero tiers {table.concat(tiers, "/")} path {path} cap {cap or 2}`
	test(name, function()
		eq(Upgrades.check(tiers, path, HERO_MAX, cap), expected, name)
	end)
end

-- Buy greedily on path 1, then path 2, then path 3: the build the rule allows.
local function maxBuild(maxTier: number, cap: number?): string
	local tiers = { 0, 0, 0 }
	for path = 1, 3 do
		while Upgrades.check(tiers, path, maxTier, cap) == "ok" do
			tiers[path] += 1
		end
	end
	return table.concat(tiers, "/")
end

test("hero max builds: 6/2/0, and 6/3/0 at mastery 20", function()
	eq(maxBuild(HERO_MAX, nil), "6/2/0", "cap 2")
	eq(maxBuild(HERO_MAX, 3), "6/3/0", "cap 3")
	eq(maxBuild(MAX, nil), "5/2/0", "towers keep 5/2/0")
end)

test("tier 6 needs tier 5 on the same path: the only way to 6 is the step from 5", function()
	eq(Upgrades.stepFor(HERO, { 4 }, { "A" }, 1, "A"), "5AA", "from 4 the next is 5, never 6")
	eq(Upgrades.stepFor(HERO, { 5 }, { "AA" }, 1, nil), "6AA", "from 5 the next is 6")
	eq(select(2, Upgrades.stepFor(HERO, { 6 }, { "AA" }, 1, nil)), "maxed", "6 is the top")
	-- A path that went past the cap elsewhere can't reach 6 either: it stops at the cap.
	eq(Upgrades.check({ 2, 5, 0 }, 1, HERO_MAX, nil), "crossover", "2/5/0: path 1 stays at 2")
end)

test("T111 refusals: an option only at tiers 4 and 5, and only one that exists", function()
	local function why(tiers, picks, option): string
		return select(2, Upgrades.stepFor(TOWER, tiers, picks, 1, option))
	end
	eq(why({ 3, 0 }, { "", "" }, nil), "pick an option", "tier 4 without an option")
	eq(why({ 4, 0 }, { "A", "" }, nil), "pick an option", "tier 5 without an option")
	eq(why({ 0, 0 }, { "", "" }, "A"), "no option here", "tier 1 with an option")
	eq(why({ 2, 0 }, { "", "" }, "A"), "no option here", "tier 3 with an option")
	eq(select(2, Upgrades.stepFor(HERO, { 5 }, { "AA" }, 1, "A")), "no option here", "hero tier 6 with an option")
	eq(why({ 3, 0 }, { "", "" }, "D"), "unknown option", "a letter past C")
	eq(why({ 3, 0 }, { "", "" }, "a"), "unknown option", "lower case")
	eq(why({ 3, 0 }, { "", "" }, 1), "unknown option", "not a string")
	eq(why({ 3, 0 }, { "", "" }, ""), "unknown option", "empty")
	eq(why({ 3, 0 }, { "", "" }, "C"), "no such option", "tier 4 has no C row")
	eq(why({ 4, 0 }, { "A", "" }, "B"), "no such option", "tier 5 has no B row")
	eq(why({ 3, 0 }, { "", "" }, "A"), "ok")
end)

test("T111: the tier-5 pick is independent of the tier-4 pick; tier 6 works after every tier 5", function()
	for _, o4 in { "A", "B" } do
		eq(Upgrades.stepFor(TOWER, { 3 }, { "" }, 1, o4), "4" .. o4)
		for _, o5 in { "A", "C" } do
			eq(Upgrades.stepFor(TOWER, { 4 }, { o4 }, 1, o5), `5{o4}{o5}`, `{o4} then {o5}`)
			eq(Upgrades.stepFor(HERO, { 5 }, { o4 .. o5 }, 1, nil), `6{o4}{o5}`, `tier 6 after {o4}{o5}`)
		end
	end
end)

test("T111: options lists the letters on offer; pickAfter adds letters only at tiers 4 and 5", function()
	local path = fakePath(false)
	eq(table.concat(Upgrades.options(path, 4, ""), ","), "A,B")
	eq(table.concat(Upgrades.options(path, 5, "B"), ","), "A,C")
	eq(#Upgrades.options(path, 3, ""), 0, "no options at tier 3")
	eq(#Upgrades.options(HERO.paths[1], 6, "BC"), 0, "no options at hero tier 6")
	eq(Upgrades.pickAfter("", 3, nil), "")
	eq(Upgrades.pickAfter("", 4, "B"), "B")
	eq(Upgrades.pickAfter("B", 5, "C"), "BC")
	eq(Upgrades.pickAfter("BC", 6, nil), "BC")
end)

test("T111: row reads the composed build for the picks; tierCount is 5 for towers, 6 for heroes", function()
	local path = fakePath(true)
	eq(Upgrades.row(path, 0, ""), nil)
	eq(Upgrades.row(path, 3, ""), "t3")
	eq(Upgrades.row(path, 4, "B"), "4B")
	eq(Upgrades.row(path, 5, "BC"), "5BC")
	eq(Upgrades.row(path, 6, "BC"), "6BC")
	eq(Upgrades.row(path, 5, "B"), nil, "a tier-5 row needs both letters")
	eq(Upgrades.row(path, 4, nil), "4A", "no picks = option A (scripted builds, #287)")
	eq(Upgrades.row(path, 7, "AA"), nil)
	eq(Upgrades.tierCount(fakePath(false)), 5)
	eq(Upgrades.tierCount(path), 6)
	eq(table.concat(Upgrades.line(path, "BC"), ","), "t1,t2,t3,4B,5BC,6BC")
end)

test("T111: every real path offers option A at tiers 4 and 5; the starters A, B and C (9c)", function()
	local withBC = { SCOUT = true, SNIPER = true, GRENADIER = true }
	for g, group in { Config.Towers, Config.Heroes } do
		for key, def in group :: any do
			local want = if g == 1 and withBC[key] then "A,B,C" else "A"
			for _, path in def.paths do
				eq(table.concat(Upgrades.options(path, 4, ""), ","), want, `{key} {path.id} tier 4`)
				for _, o4 in { "A", "B", "C" } do
					if path.t4[o4] then
						eq(table.concat(Upgrades.options(path, 5, o4), ","), want, `{key} {path.id} tier 5 after {o4}`)
					end
				end
			end
		end
	end
end)
