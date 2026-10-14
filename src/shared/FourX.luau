--!strict
--[[
	Shared rules of the seven 4x towers (PLAN 9g common rule 4, DECISIONS #316). Pure.

	  hardStop      entomb, walls, nets, holds: a dino can't move, bite or throw, and still
	                takes damage. On a boss the length is x Tuning Boss hard stop x unless
	                the option says otherwise (`full`). Hard stops don't stack: the longer
	                remaining wins (Enemies.stun keeps the later end).
	  isSmall       "small dinos" = not a boss, at its last Tuning Small size sizes
	  markNear      Take-down mark %: a take-down by this tower (or its walkers) marks the
	                dinos within Tuning Take-down mark radius (Mark duration 3 s; marks
	                don't stack, the stronger wins)
]]

local Config = require(script.Parent.Config)

local FourX = {}

function FourX.hardStop(seconds: number, boss: boolean, full: boolean?): number
	if seconds <= 0 then
		return 0
	end
	return if boss and not full then seconds * Config.Tuning.BossHardStopX else seconds
end

function FourX.isSmall(size: number, boss: boolean): boolean
	return not boss and size <= Config.Tuning.SmallSize
end

-- How long a take-down mark lasts: Tuning Mark duration (3 s).
function FourX.takeDownMarkSeconds(): number
	return Config.Tuning.MarkDuration
end

-- Which of `points` (dino positions) a take-down at `at` marks.
function FourX.markNear(at: Vector3, points: { Vector3 }): { number }
	local radius = Config.Tuning.TakeDownMarkRadius
	local out = {}
	for i, p in points do
		local offset = p - at
		if Vector2.new(offset.X, offset.Z).Magnitude <= radius then
			table.insert(out, i)
		end
	end
	return out
end

return FourX
