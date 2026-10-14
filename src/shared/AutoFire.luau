--!strict
--[[
	Auto trigger (PLAN 9g common rule 4, DECISIONS #283 made generic, #316). Pure.
	Every "once per round played" tower effect (Resin Wall, Raptor Charge, Raptor Swarm,
	Bombing Run, Comet Tail, Extinction Event, Supervolcano, Obsidian Wall, Master
	Trapper) fires itself:
	  - the first moment a boss, or Tuning Wall min bunch dinos, are inside its area;
	  - else when that round's last dino has spawned (the caller aims it at the densest
	    bunch / its area then: `densest`);
	  - never on an empty track.
	Per tower, per side; `reset` each round played.
]]

local Config = require(script.Parent.Config)

local AutoFire = {}

export type State = { fired: boolean }

function AutoFire.new(): State
	return { fired = false }
end

-- A new round is played: ready again.
function AutoFire.reset(state: State)
	state.fired = false
end

-- Fire now? `bossInArea`, `inArea` (dinos inside its area now), `lastSpawned` (the
-- round's last dino is out), `onTrack` (dinos on its side's track). Marks it fired.
function AutoFire.check(state: State, bossInArea: boolean, inArea: number, lastSpawned: boolean, onTrack: number): boolean
	if state.fired or onTrack <= 0 then
		return false
	end
	if bossInArea or inArea >= Config.Tuning.WallMinBunch or lastSpawned then
		state.fired = true
		return true
	end
	return false
end

-- The densest bunch: the track distance (one of `distances`) with the most others within
-- Tuning Wall reach (studs) of it; ties: the furthest along. nil for none.
function AutoFire.densest(distances: { number }): number?
	local reach = Config.Tuning.WallReachStuds
	local best, bestCount = nil, -1
	for _, d in distances do
		local count = 0
		for _, other in distances do
			if math.abs(other - d) <= reach then
				count += 1
			end
		end
		if count > bestCount or (count == bestCount and best ~= nil and d > best) then
			best, bestCount = d, count
		end
	end
	return best
end

return AutoFire
