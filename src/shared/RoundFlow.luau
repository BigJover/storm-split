--[[
	RoundFlow: the co-op round loop's rule, pure (PLAYTEST Run 2 F4). Server/Waves.run
	drives it with the real spawner, enemy count and task.wait; specs drive it with fakes.

	A round is cleared only when every dino is dealt with AND the match isn't over. The
	last dino of a round can be the one that breaks the Fence: the count reaches 0 and the
	match is lost in the same step, and that round is a loss — no onRoundEnd (no round
	bonus, heal or hero XP) and, on the last round of the table, no victory. So `isOver`
	is checked once more after the count reaches 0, before the round is called cleared.

	  run(steps)  true if every round from `first` to `last` was cleared, false as soon as
	              the match is over (between rounds, while spawning, while waiting, or in
	              the step the round's last dino is dealt with)
]]

local RoundFlow = {}

export type Steps = {
	first: number,
	last: number,
	isOver: () -> boolean,
	spawn: (number) -> boolean, -- starts the round and spawns it (yields); false = stopped part-way
	remaining: () -> number, -- dinos left on this side's track (queued ones included)
	onRoundEnd: ((number) -> ())?,
	wait: (number) -> (), -- task.wait in the game, a fake clock in specs
	poll: number, -- seconds between remaining() checks
	intermission: number, -- seconds between rounds
}

function RoundFlow.run(steps: Steps): boolean
	for index = steps.first, steps.last do
		if steps.isOver() then
			return false
		end
		if not steps.spawn(index) then
			return false
		end
		while steps.remaining() > 0 do
			if steps.isOver() then
				return false
			end
			steps.wait(steps.poll)
		end
		-- F4: the leak that took the last dino off the track may have broken the Fence.
		if steps.isOver() then
			return false
		end
		if steps.onRoundEnd then
			steps.onRoundEnd(index)
		end
		steps.wait(steps.intermission)
	end
	return true
end

return table.freeze(RoundFlow)
