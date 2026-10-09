--[[
	The tie-break chain (PLAN Phase 8 batch 2 T102, DECISIONS #253): every queue, no result
	is ever a tie. Camp Clash: standing / fell later -> Fence -> Bones -> damage -> lower
	clear time -> seeded coin flip. Bone Rush: Bones -> survived longer -> Fence -> damage ->
	lower clear time -> seeded coin flip. `decidedBy` names the step between 1st and 2nd.
]]

local BattleRules = require(src.shared.BattleRules)

-- Camp Clash ----------------------------------------------------------------------

test("Camp Clash: each step decides alone", function()
	-- standing: side 1 stands with less of everything
	local r = BattleRules.teamResult({ { 2 } }, { [1] = 0, [2] = 99 }, { fence = { [1] = 1 }, damage = { [2] = 999 }, clearTime = { [1] = 999 }, seed = 1 })
	eq(r.winners[1], 1)
	eq(r.decidedBy, "standing")
	-- the rest at the clock: both standing, level on every earlier step
	local base = { modeKey = "TEAM", eliminationOrder = {}, bones = { [1] = 5, [2] = 5 }, seed = 1 }
	local function clock(extra)
		local input = table.clone(base)
		for k, v in extra do
			input[k] = v
		end
		return BattleRules.atClock(input)
	end
	r = clock({ fence = { [1] = 10, [2] = 11 }, bones = { [1] = 50, [2] = 5 }, damage = { [1] = 900, [2] = 0 }, clearTime = { [1] = 1, [2] = 900 } })
	eq(r.winners[1], 2, "more Fence beats more Bones, damage and a faster clear")
	eq(r.decidedBy, "fence")
	r = clock({ fence = { [1] = 10, [2] = 10 }, bones = { [1] = 6, [2] = 5 }, damage = { [1] = 0, [2] = 900 }, clearTime = { [1] = 900, [2] = 1 } })
	eq(r.winners[1], 1, "more Bones beats damage and clear time")
	eq(r.decidedBy, "bones")
	r = clock({ fence = { [1] = 10, [2] = 10 }, damage = { [1] = 300, [2] = 301 }, clearTime = { [1] = 1, [2] = 900 } })
	eq(r.winners[1], 2, "more damage beats a faster clear")
	eq(r.decidedBy, "damage")
	r = clock({ fence = { [1] = 10, [2] = 10 }, damage = { [1] = 300, [2] = 300 }, clearTime = { [1] = 400, [2] = 399.5 } })
	eq(r.winners[1], 2, "the lower total clear time")
	eq(r.decidedBy, "clearTime")
	r = clock({ fence = { [1] = 10, [2] = 10 }, damage = { [1] = 300, [2] = 300 }, clearTime = { [1] = 400, [2] = 400 }, seed = "match-1" })
	eq(#r.winners, 1)
	eq(r.decidedBy, "coinFlip")
	eq(r.tie, false)
end)

test("Camp Clash: sides that fell in the same step go down the chain from Fence", function()
	local r = BattleRules.teamResult({ { 1, 2, 3 } }, { [1] = 8, [2] = 8, [3] = 7 }, { damage = { [1] = 5, [2] = 6 }, seed = 3 })
	eq(r.winners[1], 2)
	eq(r.decidedBy, "damage")
	eq(table.concat(r.ranking, ","), "2,1,3")
	eq(table.concat(r.losers, ","), "1,3")
end)

test("atClock (Camp Clash): over at once, everyone standing ranked first, fallen sides after", function()
	local r = BattleRules.atClock({
		modeKey = "TEAM",
		eliminationOrder = { { 3 } },
		bones = { [1] = 10, [2] = 10, [3] = 500 },
		fence = { [1] = 4, [2] = 9, [3] = 0 },
		seed = 7,
	})
	eq(r.over, true)
	eq(table.concat(r.ranking, ","), "2,1,3", "Fence among the standing; the fallen camp last despite its Bones")
	eq(r.decidedBy, "fence")
	eq(r.tie, false)
	eq(BattleRules.teamResult({}, { [1] = 1, [2] = 2 }, { seed = 1 }).over, false, "without the clock two standing is not over")
end)

-- Bone Rush -----------------------------------------------------------------------

test("Bone Rush: each step decides alone", function()
	local function two(a, b, roundsDone: boolean?)
		a.id, b.id = "a", "b"
		return BattleRules.royaleResult({ a, b }, roundsDone ~= false, 11)
	end
	local r = two({ bones = 34, fence = 0, outAt = 1 }, { bones = 30, fence = 9, damage = 999, clearTime = 0 }) -- b: 30 + 10% = 33
	eq(r.ranking[1], "a", "Bones first")
	eq(r.decidedBy, "bones")
	r = two({ bones = 30, fence = 0, outAt = 3 }, { bones = 30, fence = 0, outAt = 4, damage = 0, clearTime = 999 })
	eq(r.ranking[1], "b", "survived longer")
	eq(r.decidedBy, "survived")
	r = two({ bones = 30, fence = 5, damage = 999, clearTime = 1 }, { bones = 30, fence = 6 })
	eq(r.ranking[1], "b", "more Fence")
	eq(r.decidedBy, "fence")
	r = two({ bones = 30, fence = 5, damage = 10, clearTime = 1 }, { bones = 30, fence = 5, damage = 11, clearTime = 900 })
	eq(r.ranking[1], "b", "more damage")
	eq(r.decidedBy, "damage")
	r = two({ bones = 30, fence = 5, damage = 10, clearTime = 300 }, { bones = 30, fence = 5, damage = 10, clearTime = 299 })
	eq(r.ranking[1], "b", "lower clear time")
	eq(r.decidedBy, "clearTime")
	r = two({ bones = 30, fence = 5, damage = 10, clearTime = 300 }, { bones = 30, fence = 5, damage = 10, clearTime = 300 })
	eq(#r.ranking, 2)
	eq(r.decidedBy, "coinFlip")
end)

test("atClock (Bone Rush): over at once; survivor bonus only for a lone survivor", function()
	local r = BattleRules.atClock({
		modeKey = "ROYALE",
		players = { { id = 1, bones = 20, fence = 3 }, { id = 2, bones = 20, fence = 8 }, { id = 3, bones = 25, fence = 0, outAt = 2 } },
		seed = 5,
	})
	eq(r.over, true)
	eq(r.survivor, nil, "two still standing: no bonus")
	eq(table.concat(r.ranking, ","), "3,2,1", "Bones, then Fence among the standing")
	eq(r.decidedBy, "bones")
end)

-- The coin flip ---------------------------------------------------------------------

test("the coin flip is seeded: same inputs + seed = same result; seeds differ", function()
	local seen = {}
	for seed = 1, 64 do
		local a = BattleRules.teamResult({ { 1, 2, 3 } }, { [1] = 1, [2] = 1, [3] = 1 }, { seed = seed })
		local b = BattleRules.teamResult({ { 1, 2, 3 } }, { [1] = 1, [2] = 1, [3] = 1 }, { seed = seed })
		eq(table.concat(a.ranking, ","), table.concat(b.ranking, ","), `seed {seed} reproducible`)
		eq(a.decidedBy, "coinFlip")
		seen[a.winners[1]] = true
		local players = { { id = "x", bones = 3, fence = 1 }, { id = "y", bones = 3, fence = 1 } }
		local c = BattleRules.royaleResult(players, true, `job-{seed}`)
		local d = BattleRules.royaleResult({ players[2], players[1] }, true, `job-{seed}`)
		eq(c.ranking[1], d.ranking[1], "the order given no longer matters")
	end
	ok(seen[1] and seen[2] and seen[3], "every side wins some flips")
end)

-- Fuzz ------------------------------------------------------------------------------

test("fuzz: 1,000 random results, never a tie, rankings follow the chain", function()
	math.randomseed(253)
	local function pick(n: number): number
		return math.random(0, n) -- small ranges, so ties are common
	end
	for case = 1, 1000 do
		local sides = math.random(2, 3)
		local bones, fence, damage, clear = {}, {}, {}, {}
		local order = {}
		for side = 1, sides do
			bones[side], fence[side], damage[side], clear[side] = pick(2), pick(1), pick(1), pick(1)
		end
		-- a random elimination: everyone falls in 1-2 steps, or some stand (clock)
		local clockEnd = math.random() < 0.5
		local list = {}
		for side = 1, sides do
			if not clockEnd or math.random() < 0.5 then
				table.insert(list, side)
			end
		end
		if #list > 0 then
			local cut = math.random(0, #list - 1)
			if cut > 0 then
				table.insert(order, { table.unpack(list, 1, cut) })
			end
			table.insert(order, { table.unpack(list, cut + 1) })
		end
		local r
		if clockEnd then
			r = BattleRules.atClock({ modeKey = "TEAM", eliminationOrder = order, bones = bones, fence = fence, damage = damage, clearTime = clear, seed = case })
		else
			r = BattleRules.teamResult(order, bones, { fence = fence, damage = damage, clearTime = clear, seed = case })
		end
		eq(r.over, true, `team case {case}`)
		eq(r.tie, false)
		eq(#r.winners, 1)
		eq(#r.ranking, sides)
		eq(#r.losers, sides - 1)
		ok(r.decidedBy ~= nil, "a deciding step is named")
		local seen = {}
		for _, side in r.ranking do
			ok(not seen[side], "each side once")
			seen[side] = true
		end

		local n = math.random(2, 10)
		local players = {}
		for i = 1, n do
			local out = if math.random() < 0.5 then math.random(1, 3) else nil
			table.insert(players, { id = i, bones = pick(2), fence = if out then 0 else pick(1), outAt = out, damage = pick(1), clearTime = pick(1) })
		end
		local royale = BattleRules.royaleResult(players, true, case)
		eq(royale.over, true)
		eq(#royale.ranking, n, `royale case {case}`)
		ok(royale.decidedBy ~= nil, "named")
		local byId = {}
		for _, p in players do
			byId[p.id] = p
		end
		for i = 1, n - 1 do
			local a, b = byId[royale.ranking[i]], byId[royale.ranking[i + 1]]
			local ka = { royale.bones[a.id], a.outAt or math.huge, a.fence, a.damage, -a.clearTime }
			local kb = { royale.bones[b.id], b.outAt or math.huge, b.fence, b.damage, -b.clearTime }
			local better = nil
			for k = 1, #ka do
				if ka[k] ~= kb[k] then
					better = ka[k] > kb[k]
					break
				end
			end
			ok(better ~= false, `royale case {case}: place {i} is not worse than place {i + 1}`)
		end
	end
end)

test("#261: a nil seed is an error in every result (T104 always passes matchId)", function()
	local function fails(f: () -> any, what: string)
		local okay, why = pcall(f)
		ok(not okay and tostring(why):find("match seed", 1, true) ~= nil, what)
	end
	fails(function()
		return BattleRules.teamResult({ { 1, 2 } }, { [1] = 1, [2] = 1 }, {})
	end, "teamResult, stats without a seed")
	fails(function()
		return (BattleRules.teamResult :: any)({ { 1, 2 } }, { [1] = 1, [2] = 1 })
	end, "teamResult, no stats")
	fails(function()
		return (BattleRules.royaleResult :: any)({ { id = 1, bones = 1, fence = 1 } }, true)
	end, "royaleResult")
	fails(function()
		return BattleRules.atClock({ modeKey = "TEAM", eliminationOrder = {}, bones = { [1] = 1, [2] = 1 } })
	end, "atClock (Camp Clash)")
	fails(function()
		return BattleRules.atClock({ modeKey = "ROYALE", players = {} })
	end, "atClock (Bone Rush)")
	eq(BattleRules.teamResult({ { 1, 2 } }, { [1] = 1, [2] = 1 }, { seed = "match-guid" }).over, true, "a string matchId is a seed")
end)
