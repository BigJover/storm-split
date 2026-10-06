--[[
	Falcon Roost rules (PLAN T65, UPGRADES.md "Falcon Roost"). Pure, so specs run
	headlessly; Server/Towers applies them.

	  pick         a bird dives on the dino furthest along the track in range that no
	              other bird of this roost is already flying at; if every one is taken,
	              the furthest along (ties: the earlier in the list)
	  flight       seconds one way: distance / Falcon speed (the travel time; the bird
	              is back after twice that, and can't fly again until then)
	  free         birds at the roost: the flock less those still out
	  diveDamage   one dive: the roost's damage, x Power Dive's first-dive x on a dino this
	              roost hasn't dived on before, x Tuning Eagle dive x with the eagle
	  diveRate     dives a second the flock can keep up: the lower of the roost's rate
	              and birds / round trip (the model's cap; the game gets it by waiting)
	  huntingParty the strongest Hunting Party covering a point while one of its birds is
	              out (auras don't stack), never the roost's own
]]

local Config = require(script.Parent.Config)

local Falcon = {}

-- `distances`: each candidate's distance along the track; `claimed[i]`: a bird is already
-- flying at candidate i. Returns an index, or nil for an empty list.
function Falcon.pick(distances: { number }, claimed: { [number]: boolean }?): number?
	local best, bestFree = nil, nil
	for i, d in distances do
		if best == nil or d > distances[best] then
			best = i
		end
		if not (claimed and claimed[i]) and (bestFree == nil or d > distances[bestFree]) then
			bestFree = i
		end
	end
	return bestFree or best
end

function Falcon.flight(distance: number): number
	return math.max(0, distance) / Config.Tuning.FalconSpeed
end

function Falcon.free(birds: number, out: number): number
	return math.max(0, birds - out)
end

function Falcon.diveDamage(damage: number, firstDive: boolean, firstDiveX: number, eagle: boolean): number
	local x = if firstDive then math.max(1, firstDiveX) else 1
	return damage * x * (if eagle then Config.Tuning.EagleDiveX else 1)
end

function Falcon.diveRate(rate: number, birds: number, distance: number): number
	if birds <= 0 or distance <= 0 then
		return rate
	end
	return math.min(rate, birds / (2 * Falcon.flight(distance)))
end

export type Party = { center: Vector3, radius: number, percent: number, diving: boolean, source: any }

function Falcon.huntingParty(point: Vector3, parties: { Party }, self: any?): number
	local best = 0
	for _, party in parties do
		local offset = point - party.center
		if party.diving and party.source ~= self and Vector2.new(offset.X, offset.Z).Magnitude <= party.radius then
			best = math.max(best, party.percent)
		end
	end
	return best
end

return Falcon
