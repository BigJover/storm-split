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

	THE CLOCK (T104, #252): with `cap` (Pace.matchCap; nil in co-op, which never comes here),
	the match ends at once when now - clockStart reaches it, checked after each tick (so a
	fall in the same check still counts) and before the lockstep: steps.atClock() is the
	result (BattleRules.atClock ranks everyone standing).

	CLEAR TIME (#253 step 5): steps.clearTime (side -> seconds), when given, gets each played
	round's seconds from its start to the side's first "cleared"; a side that hadn't cleared
	when the round ended (forced at Battle round time) or the clock ran out adds the whole
	elapsed round. Final Stampede rounds count like any other.

	  run(steps)  -> (result, round): what `tick`, `finish` or `atClock` returned, and the round then
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
	cap: number?, -- seconds from clockStart (Pace.matchCap)
	clockStart: number?, -- steps.now() when Building started
	atClock: (() -> any)?,
	clearTime: { [number]: number }?,
}

function BattleLoop.run(steps: Steps): (any, number)
	local last = #Config.Rounds
	local round = steps.first
	local startedAt = 0
	local clearedAt: number? = nil
	local clearedThis: { [number]: boolean } = {}
	local clearTime = steps.clearTime

	-- Every side in `cleared` that hasn't cleared this round adds the round so far.
	local function chargeUncleared(cleared: { [number]: boolean })
		if clearTime then
			for side in cleared do
				if not clearedThis[side] then
					clearTime[side] = (clearTime[side] or 0) + (steps.now() - startedAt)
					clearedThis[side] = true
				end
			end
		end
	end

	local function begin(r: number)
		round = r
		local from, to = Pace.skippedBefore(r, steps.modeKey, steps.competitive)
		if from <= to then
			steps.paySkipped(from, to)
		end
		steps.startRound(r)
		startedAt = steps.now()
		clearedAt = nil
		clearedThis = {}
	end

	begin(round)
	while true do
		steps.wait(steps.poll)
		local result = steps.tick()
		if result ~= nil then
			return result, round
		end
		local cleared = steps.cleared(round)
		if steps.cap and steps.atClock and steps.now() - (steps.clockStart or 0) >= steps.cap then
			chargeUncleared(cleared)
			return steps.atClock(), round
		end
		if clearTime then
			for side, done in cleared do
				if done and not clearedThis[side] then
					clearedThis[side] = true
					clearTime[side] = (clearTime[side] or 0) + (steps.now() - startedAt)
				end
			end
		end
		local due
		due, clearedAt = BattleFlow.roundDue(cleared, steps.now() - startedAt, clearedAt)
		if due then
			chargeUncleared(cleared)
			steps.endRound(round)
			if not BattleFlow.hasOvertime(steps.modeKey) and round >= last then
				return steps.finish(), round
			end
			begin(Pace.nextRound(round, steps.modeKey, steps.competitive))
		end
	end
end

return table.freeze(BattleLoop)
