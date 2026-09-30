--[[
	Casual Amber payouts at the end of a match (VISION.md "Amber economy"). Pure, so it
	can be tested without a DataStore; Server/Progression pays what this says.

	  clear             the difficulty's Clear reward, solo or not (unknown
	                    difficulty: nothing)
	  multiplayer loss  Tuning MultiplayerLossPayout each
	  solo loss         nothing

	`players` is how many took part in the match and are still in the server
	(DECISIONS #19), not how many save profiles loaded.
]]

local Config = require(script.Parent.Config)

local Payouts = {}

function Payouts.casualPayout(cleared: boolean, players: number, difficultyKey: string?): number
	if cleared then
		local difficulty = if difficultyKey then Config.Difficulties[difficultyKey] else nil
		return if difficulty then difficulty.clearReward else 0
	elseif players >= 2 then
		return Config.Tuning.MultiplayerLossPayout
	end
	return 0
end

return Payouts
