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
