--[[
	Upgrades.check: the crossover rule (UPGRADES.md). At most two of three paths open, and
	only one of them past the cap (2, or 3 with hero mastery level 20).
]]

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

test("nextStep returns the next tier's row, nil when maxed", function()
	local def = { paths = { { tiers = { "t1", "t2" } }, { tiers = { "u1" } } } }
	eq(Upgrades.nextStep(def, { 0, 0 }, 1), "t1")
	eq(Upgrades.nextStep(def, { 1, 0 }, 1), "t2")
	eq(Upgrades.nextStep(def, { 2, 0 }, 1), nil)
	eq(Upgrades.nextStep(def, { 0, 1 }, 2), nil)
	eq(Upgrades.nextStep(def, { 0, 0 }, 3), nil)
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
	local def = { paths = { { tiers = { "t1", "t2", "t3", "t4", "t5", "t6" } } } }
	eq(Upgrades.nextStep(def, { 4 }, 1), "t5", "from 4 the next is 5, never 6")
	eq(Upgrades.nextStep(def, { 5 }, 1), "t6", "from 5 the next is 6")
	eq(Upgrades.nextStep(def, { 6 }, 1), nil, "6 is the top")
	-- A path that went past the cap elsewhere can't reach 6 either: it stops at the cap.
	eq(Upgrades.check({ 2, 5, 0 }, 1, HERO_MAX, nil), "crossover", "2/5/0: path 1 stays at 2")
end)
