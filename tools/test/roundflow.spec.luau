--[[
	PLAYTEST Run 2 F4: a round whose last dino breaks the Fence is a loss, not a clear.
	Shared/RoundFlow (the co-op round loop Server/Waves.run drives) and
	BattleFlow.clearedSides (which battle sides get the round's pay, heal and hero XP).
]]

local RoundFlow = require(src.shared.RoundFlow)
local BattleFlow = require(src.shared.BattleFlow)

-- A fake match: `dinos` per round; each wait() takes one dino off the track. `breakAt`
-- = { round, left }: when that round is down to `left` dinos, the next one off the track
-- leaks and breaks the Fence (the match is over in the same step the count hits 0).
local function play(rounds: number, dinos: number, breakAt: { number }?)
	local over = false
	local left = 0
	local current = 0
	local ended: { number } = {}
	local won = RoundFlow.run({
		first = 1,
		last = rounds,
		isOver = function()
			return over
		end,
		spawn = function(index)
			current = index
			left = dinos
			return true
		end,
		remaining = function()
			return left
		end,
		onRoundEnd = function(index)
			table.insert(ended, index)
		end,
		wait = function(_seconds)
			if left > 0 then
				if breakAt and breakAt[1] == current and left == breakAt[2] + 1 then
					over = true
				end
				left -= 1
			end
		end,
		poll = 0.25,
		intermission = 5,
	})
	return won, ended
end

test("every round cleared: each one ends, and the run is won", function()
	local won, ended = play(3, 4)
	eq(won, true)
	eq(#ended, 3)
end)

test("F4: the last dino of round 2 breaks the Fence -> no round end for round 2, a loss", function()
	local won, ended = play(3, 4, { 2, 0 })
	eq(won, false)
	eq(#ended, 1, "only round 1 cleared")
	eq(ended[1], 1)
end)

test("F4 edge: the last dino of the LAST round breaks the Fence -> no victory, no clear", function()
	local won, ended = play(3, 4, { 3, 0 })
	eq(won, false, "not a victory")
	eq(#ended, 2, "rounds 1-2 cleared, round 3 not")
end)

test("the Fence breaking mid-round (dinos still out) is a loss too", function()
	local won, ended = play(3, 4, { 1, 2 })
	eq(won, false)
	eq(#ended, 0)
end)

test("battle: a side whose Fence is 0 didn't clear, even before it's marked out (F4)", function()
	local fences = { 10, 0, 5 }
	local cleared = BattleFlow.clearedSides(3, {}, function(side)
		return fences[side]
	end)
	eq(#cleared, 2)
	eq(cleared[1], 1)
	eq(cleared[2], 3)
end)

test("battle: an out side never clears", function()
	local cleared = BattleFlow.clearedSides(2, { [1] = true }, function()
		return 20
	end)
	eq(#cleared, 1)
	eq(cleared[1], 2)
end)
