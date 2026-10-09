--[[
	BattleLoop: a battle's round driver, pure (PLAN Phase 8 batch 2 T103, DECISIONS #251).
	Server/Battle drives it with the real clock, spawner and checks; specs drive it with a
	fake clock (tools/test/battleloop.spec.luau).

	Rounds: the queue's played list (Shared/Pace: casual every 3rd, Ranked every 2nd, both
	ending at the last row), from `first` (already snapped by Pace.firstRound); past the last
	row, Camp Clash goes on round by round into Final Stampede (BattleFlow.hasOvertime) and
	Bone Rush ends. As a played round starts, the rounds skipped right before it are paid
	once (paySkipped(from, to): Pace.skippedIncome per side, the caller's), then the round
	starts. Lockstep as before: the next round is due when every living side has cleared
	this one and the break has passed, or Tuning BattleRoundTime after it started
	(BattleFlow.roundDue).

	  run(steps)  -> (result, round): what `tick` or `finish` returned, and the round then
	    steps.tick()        every `poll` seconds: leavers, eliminations, the verdict; a
	                        non-nil return ends the loop with it
	    steps.cleared(r)    living side -> cleared round r?
	    steps.startRound(r) / steps.endRound(r) / steps.paySkipped(from, to)
	    steps.finish()      the last row is done and the mode has no overtime: the verdict
	    steps.now() / steps.wait(s)   os.clock / task.wait in the game, a fake clock in specs
]]

local Config = require(script.Parent.Config)
local BattleFlow = require(script.Parent.BattleFlow)
local Pace = require(script.Parent.Pace)

local BattleLoop = {}

export type Steps = {
	modeKey: string,
	competitive: boolean?,
	first: number,
	poll: number,
	now: () -> number,
	wait: (number) -> (),
	tick: () -> any?,
	cleared: (number) -> { [number]: boolean },
	startRound: (number) -> (),
	endRound: (number) -> (),
	paySkipped: (number, number) -> (),
	finish: () -> any,
}

function BattleLoop.run(steps: Steps): (any, number)
	local last = #Config.Rounds
	local round = steps.first
	local startedAt = 0
	local clearedAt: number? = nil

	local function begin(r: number)
		round = r
		local from, to = Pace.skippedBefore(r, steps.modeKey, steps.competitive)
		if from <= to then
			steps.paySkipped(from, to)
		end
		steps.startRound(r)
		startedAt = steps.now()
		clearedAt = nil
	end

	begin(round)
	while true do
		steps.wait(steps.poll)
		local result = steps.tick()
		if result ~= nil then
			return result, round
		end
		local due
		due, clearedAt = BattleFlow.roundDue(steps.cleared(round), steps.now() - startedAt, clearedAt)
		if due then
			steps.endRound(round)
			if not BattleFlow.hasOvertime(steps.modeKey) and round >= last then
				return steps.finish(), round
			end
			begin(Pace.nextRound(round, steps.modeKey, steps.competitive))
		end
	end
end

return table.freeze(BattleLoop)
