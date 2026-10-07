--[[
	The capped spawn queue per side (PLAN phase 7 T75, ARCHITECTURE §5.1): Shared/SpawnQueue.
	One side (co-op) must spawn exactly what the old single queue did; many sides share
	the cap, each up to its even share, taking turns.
]]

local SpawnQueue = require(src.shared.SpawnQueue)
local Sides = require(src.shared.Sides)

-- The pre-T75 rule (4b2a3bc's Enemies.step): pop first-in while live < cap.
local function oldDrain(queue: { any }, live: number, cap: number): { any }
	local out = {}
	while live < cap and #queue > 0 do
		table.insert(out, table.remove(queue, 1))
		live += 1
	end
	return out
end

-- Drain one frame the way Enemies.step does now.
local function drain(q, liveBySide: { number }, cap: number): { { any } }
	local out = {}
	local total = 0
	for _, n in liveBySide do
		total += n
	end
	while true do
		local item, side = SpawnQueue.take(q, total, liveBySide, cap)
		if not item or not side then
			break
		end
		liveBySide[side] += 1
		total += 1
		table.insert(out, { item, side })
	end
	return out
end

test("one side spawns exactly what the old queue did, frame by frame", function()
	local seed = 7
	local rng = {}
	function rng:NextInteger(lo: number, hi: number): number -- a small LCG (no Random headless)
		seed = (seed * 1103515245 + 12345) % 2147483648
		return lo + seed % (hi - lo + 1)
	end
	for run = 1, 200 do
		local cap = rng:NextInteger(1, 140)
		local q = SpawnQueue.new(1)
		local old: { any } = {}
		local live = { 0 }
		local oldLive = 0
		local nextItem = 0
		for frame = 1, 60 do
			for _ = 1, rng:NextInteger(0, 12) do -- the wave runner queues some
				nextItem += 1
				SpawnQueue.push(q, 1, nextItem)
				table.insert(old, nextItem)
			end
			local kills = rng:NextInteger(0, live[1])
			live[1] -= kills -- towers take some down
			oldLive -= kills
			local now = drain(q, live, cap)
			local before = oldDrain(old, oldLive, cap)
			oldLive += #before
			eq(#now, #before, `run {run} frame {frame}: spawned`)
			for i, pair in now do
				eq(pair[1], before[i], `run {run} frame {frame}: item {i}`)
				eq(pair[2], 1, "side")
			end
			eq(SpawnQueue.size(q), #old, `run {run} frame {frame}: still queued`)
			eq(live[1], oldLive, `run {run} frame {frame}: live`)
		end
	end
end)

test("many sides share the cap: each up to its share, taking turns", function()
	local q = SpawnQueue.new(3)
	for i = 1, 50 do
		for side = 1, 3 do
			SpawnQueue.push(q, side, `{side}-{i}`)
		end
	end
	eq(SpawnQueue.size(q), 150)
	eq(SpawnQueue.size(q, 2), 50)
	local live = { 0, 0, 0 }
	local out = drain(q, live, 130)
	local share = Sides.sideCap(130, 3)
	eq(#out, share * 3, "every side filled its share")
	for side = 1, 3 do
		eq(live[side], share, `side {side} at its share`)
	end
	eq(out[1][2], 1, "turns: side 1")
	eq(out[2][2], 2, "turns: side 2")
	eq(out[3][2], 3, "turns: side 3")
	eq(out[4][1], "1-2", "each side first-in first-out")
end)

test("one side's backlog never holds back another side", function()
	local q = SpawnQueue.new(2)
	for i = 1, 100 do
		SpawnQueue.push(q, 1, i)
	end
	local live = { 0, 0 }
	drain(q, live, 130)
	eq(live[1], 65, "side 1 stops at its share")
	SpawnQueue.push(q, 2, "late")
	local out = drain(q, live, 130)
	eq(#out, 1, "side 2's dino still spawns")
	eq(out[1][2], 2)
	eq(SpawnQueue.size(q, 1), 35, "side 1 waits")
end)

test("the total never passes the cap", function()
	local q = SpawnQueue.new(10)
	for side = 1, 10 do
		for i = 1, 30 do
			SpawnQueue.push(q, side, i)
		end
	end
	local live = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
	drain(q, live, 130)
	local total = 0
	for _, n in live do
		total += n
		ok(n <= Sides.sideCap(130, 10), "per side")
	end
	ok(total <= 130, `total {total}`)
	eq(select("#", SpawnQueue.take(q, 130, live, 130)), 2)
	eq((SpawnQueue.take(q, 130, live, 130)), nil, "full: nothing")
end)

test("an unknown side is refused", function()
	local q = SpawnQueue.new(2)
	eq(SpawnQueue.push(q, 3, "x"), false)
	eq(SpawnQueue.push(q, 0, "x"), false)
	eq(SpawnQueue.size(q), 0)
	eq(SpawnQueue.size(q, 3), 0)
end)

test("a cap smaller than the side count still holds", function()
	local q = SpawnQueue.new(10)
	for side = 1, 10 do
		SpawnQueue.push(q, side, side)
	end
	local live = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
	eq(#drain(q, live, 5), 5, "only 5 spawn")
	eq(SpawnQueue.size(q), 5, "the rest wait")
end)
