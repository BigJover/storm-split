--[[
	Waves: runs the 40-round table from Config.Rounds.

	Spawns each round weakest-tier first at the round's spawn gap, waits for
	every enemy (including queued split children) to be dealt with, then
	moves on. Main pays the round-end bonus from onRoundEnd.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Enemies = require(script.Parent.Enemies)

local Waves = {}

local INTERMISSION = 5 -- seconds between rounds

export type RunOptions = {
	startRound: number?,
	isOver: () -> boolean,
	onRoundStart: ((number) -> ())?,
	onRoundEnd: ((number) -> ())?,
}

-- Returns true if every round was cleared.
function Waves.run(options: RunOptions): boolean
	local first = options.startRound or 1

	for index = first, #Config.Rounds do
		if options.isOver() then
			return false
		end

		local round = Config.Rounds[index]
		ReplicatedStorage:SetAttribute("Round", index)
		if options.onRoundStart then
			options.onRoundStart(index)
		end

		for _, key in Config.EnemyOrder do
			local count = round.counts[key]
			if count then
				for _ = 1, count do
					if options.isOver() then
						return false
					end
					Enemies.enqueue(key, round.hpMult)
					task.wait(round.spawnGap)
				end
			end
		end

		while Enemies.remaining() > 0 do
			if options.isOver() then
				return false
			end
			task.wait(0.25)
		end

		if options.onRoundEnd then
			options.onRoundEnd(index)
		end
		task.wait(INTERMISSION)
	end

	return true
end

return Waves
