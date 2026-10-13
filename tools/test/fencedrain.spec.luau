--[[
	The battle Fence drain (PLAN T103c, DECISIONS #267, PLAYTEST N13): Shared/BattleRules
	drain / flush / drainAll and the server wiring. A leak adds its cost to the side's pending
	loss, which comes off the Fence at most Tuning BattleFenceDrain per second; an out side's
	pending is dropped; everything pending lands before any match-end ranking. Co-op unchanged.
]]

local Config = require(src.shared.Config)
local BattleRules = require(src.shared.BattleRules)
local fs = require("@lune/fs")

local RATE = Config.Tuning.BattleFenceDrain
local DT = 1 / 60

test("the seed this spec means", function()
	eq(RATE, 4, "Battle Fence drain (#267)")
end)

-- Step every side at DT until its Fence is 0; returns side -> fall time and total loss.
local function run(pending: { [number]: number }, fences: { [number]: number })
	local fell, lost, out = {}, {}, {}
	local t = 0
	while next(pending) ~= nil and t < 60 do
		t += DT
		for side, loss in BattleRules.drainAll(pending, fences, out, RATE, DT) do
			fences[side] -= loss
			lost[side] = (lost[side] or 0) + loss
			if fences[side] <= 1e-9 and not fell[side] then
				fell[side] = t
				out[side] = true
			end
		end
	end
	return fell, lost
end

test("two sides, 60 pending each at t=0, Fence 40 and 10: fall at 10 s and 2.5 s (more Fence = later)", function()
	local fell = run({ [1] = 60, [2] = 60 }, { [1] = 40, [2] = 10 })
	ok(math.abs(fell[1] - 10) <= DT + 1e-6, `Fence 40 falls at {fell[1]}`)
	ok(math.abs(fell[2] - 2.5) <= DT + 1e-6, `Fence 10 falls at {fell[2]}`)
	ok(fell[1] > fell[2], "the camp with more Fence falls later")
end)

test("total loss = the sum of the leaks, exactly; at most rate x dt per step", function()
	local pending, fence, lost = 0, 100, 0
	local leaks = { 7, 3, 12, 1, 9 }
	for i, cost in leaks do
		pending += cost -- a leak every 0.5 s while it drains
		for _ = 1, 30 do
			local loss
			loss, pending = BattleRules.drain(pending, fence, RATE, DT)
			ok(loss <= RATE * DT + 1e-12, `leak {i}: step loss {loss}`)
			fence -= loss
			lost += loss
		end
	end
	while pending > 0 do
		local loss
		loss, pending = BattleRules.drain(pending, fence, RATE, DT)
		fence -= loss
		lost += loss
	end
	ok(math.abs(lost - 32) < 1e-9, `lost {lost} = 32`)
	ok(math.abs(fence - 68) < 1e-9, `Fence {fence}`)
	local loss, left = BattleRules.drain(5, 40, RATE, 0.25)
	eq(loss, 1, "4/s x 0.25 s")
	eq(left, 4, "the rest waits")
	loss, left = BattleRules.drain(0.5, 40, RATE, 1)
	eq(loss, 0.5, "never more than pending")
	eq(left, 0)
	loss, left = BattleRules.drain(9, 0, RATE, 1)
	eq(loss, 0, "a fallen side takes nothing")
	eq(left, 0)
end)

test("an out side's pending is dropped; the others keep draining", function()
	local pending = { [1] = 30, [2] = 30 }
	local losses = BattleRules.drainAll(pending, { [1] = 40, [2] = 40 }, { [2] = true }, RATE, 1)
	eq(losses[1], 4)
	eq(losses[2], nil, "out: no loss")
	eq(pending[2], nil, "out: pending cleared")
	eq(pending[1], 26)
end)

test("flush: everything pending lands at once (never past 0)", function()
	local pending = { [1] = 25, [2] = 60, [3] = 3 }
	local losses = BattleRules.drainAll(pending, { [1] = 30, [2] = 10, [3] = 20 }, {}, RATE, nil)
	eq(losses[1], 25)
	eq(losses[2], 10, "capped at the Fence left")
	eq(losses[3], 3)
	eq(next(pending), nil, "nothing pending after a flush")
	eq(select(1, BattleRules.flush(0, 10)), 0)
end)

test("clock flush: the ranking sees the Fence after the loss", function()
	-- Side 1 on 30 with 25 pending, side 2 on 20: on the shown Fence side 1 wins; the true
	-- Fence (5) puts side 2 first.
	local fences = { [1] = 30, [2] = 20 }
	local pending = { [1] = 25 }
	local function clock()
		return BattleRules.atClock({ modeKey = "TEAM", eliminationOrder = {}, bones = { [1] = 5, [2] = 5 }, fence = table.clone(fences), seed = 1 })
	end
	eq(clock().winners[1], 1, "before the flush (what the fix prevents)")
	for side, loss in BattleRules.drainAll(pending, fences, {}, RATE, nil) do
		fences[side] -= loss
	end
	local r = clock()
	eq(r.winners[1], 2, "after the flush")
	eq(r.decidedBy, "fence")
	-- Bone Rush the same way (Fence is step 3 there).
	local function royale()
		return BattleRules.atClock({ modeKey = "ROYALE", players = { { id = 1, bones = 5, fence = fences[1] }, { id = 2, bones = 5, fence = fences[2] } }, seed = 1 })
	end
	eq(royale().ranking[1], 2)
end)

test("server: battles queue leaks and drain; every match-end ranking flushes; co-op path unchanged", function()
	local battle = fs.readFile("src/server/Battle.luau")
	local main = fs.readFile("src/server/Main.server.luau")
	ok(main:find("if Battle.active() then\n\t\t\tBattle.queueLeak(enemy.side, Enemies.leakCost(enemy))", 1, true) ~= nil, "battle leaks go to pending")
	ok(main:find("Economy.loseFor(enemy.side, Battle.leakCost(enemy.side, Enemies.leakCost(enemy)))", 1, true) ~= nil, "co-op leak line unchanged")
	ok(battle:find("BattleRules.drainAll(pendingLeak, fences, out, Config.Tuning.BattleFenceDrain, dt)", 1, true) ~= nil, "the drain reads the Tuning row")
	ok(battle:find("Economy.loseFor(side, Battle.leakCost(side, loss))", 1, true) ~= nil, "Stand-ins hold still caps the loss")
	ok(battle:find("RunService.Heartbeat:Connect(function(dt)\n\t\tif not finished then\n\t\t\tdrainFences(out, dt)", 1, true) ~= nil, "drained every Heartbeat")
	ok(battle:find("pendingLeak[side] = nil -- an out side's pending loss is dropped", 1, true) ~= nil, "out drops pending")
	ok(battle:find("local result = judge(roundsDone)\n\t\tif result and flushFences() then\n\t\t\tresult = judge(roundsDone)", 1, true) ~= nil, "last camp / round 40 / Final Stampede: flushed and re-judged")
	ok(battle:find("atClock = true\n\t\tflushFences()\n\t\tlocal bones, fence, damage, clear, seats = standings()", 1, true) ~= nil, "the clock flushes before ranking")
	ok(battle:find("drainConn:Disconnect()", 1, true) ~= nil, "the drain stops with the match")
end)
