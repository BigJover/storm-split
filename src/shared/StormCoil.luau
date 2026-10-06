--[[
	Storm Coil rules (PLAN T64, DECISIONS #151, UPGRADES.md "Storm Coil"). Pure, so
	specs run headlessly; Server/Towers applies them (and Server/DinoAttacks the
	Grounding Spike).

	  chain       a strike hits its first dino, then arcs hop by hop: each hop reaches
	              the nearest dinos not yet hit within arc reach of the dinos the last
	              hop reached, up to `forks` of them (Fork Lightning: 2, so the chain
	              runs two wide), for `arcs` hops. Hop k deals falloff^k of the strike.
	              Ties go to the earlier dino in the list.
	  grid        Power Grid: n standing Storm Coils, counted up to the cap: range
	              x (1 + per-coil range x (n - 1)), damage x (base + per-coil damage x n)
	  covered     is a point inside any of these circles (flat, ignoring height)
	  biggest     Judgement Bolt's target: the dino with the most HP left
	  groundingPick  Grounding Spike: the throw aimed at a tower that lands soonest,
	              among those landing within the coil's range
]]

local Config = require(script.Parent.Config)

local StormCoil = {}

export type Link = {
	index: number, -- into the points list
	from: number?, -- the dino it arced from (nil for the first hit)
	x: number, -- share of the strike's damage
	hop: number, -- 0 for the first hit
}

-- `skip`: indices that can't be reached (already hit by something else).
function StormCoil.chain(
	points: { Vector3 },
	first: number,
	arcs: number,
	reach: number,
	forks: number,
	falloff: number,
	skip: { [number]: boolean }?
): { Link }
	local links: { Link } = { { index = first, from = nil, x = 1, hop = 0 } }
	local hit: { [number]: boolean } = { [first] = true }
	if skip then
		for i in skip do
			hit[i] = true
		end
	end
	local front = { first }
	for hop = 1, math.max(0, math.floor(arcs)) do
		local reached = {}
		for _ = 1, math.max(1, math.floor(forks)) do
			local best, bestFrom, bestGap = nil, nil, math.huge
			for _, f in front do
				local from = points[f]
				for i, p in points do
					if not hit[i] then
						local gap = (p - from).Magnitude
						if gap <= reach and gap < bestGap then
							best, bestFrom, bestGap = i, f, gap
						end
					end
				end
			end
			if not best then
				break
			end
			hit[best] = true
			table.insert(reached, best)
			table.insert(links, { index = best, from = bestFrom, x = falloff ^ hop, hop = hop })
		end
		if #reached == 0 then
			break
		end
		front = reached
	end
	return links
end

-- Power Grid's range and damage multipliers for n standing Storm Coils.
function StormCoil.grid(n: number): (number, number)
	local t = Config.Tuning
	local coils = math.clamp(math.floor(n), 1, math.max(1, t.PowerGridCoilCap))
	return 1 + t.PowerGridRangePerCoil * (coils - 1), t.PowerGridDamageBase + t.PowerGridDamagePerCoil * coils
end

export type Area = { center: Vector3, radius: number }

function StormCoil.covered(point: Vector3, areas: { Area }): boolean
	for _, area in areas do
		local offset = point - area.center
		if Vector2.new(offset.X, offset.Z).Magnitude <= area.radius then
			return true
		end
	end
	return false
end

-- The index of the largest HP left, or nil for an empty list.
function StormCoil.biggest(hps: { number }): number?
	local best, bestHp = nil, -math.huge
	for i, hp in hps do
		if hp > bestHp then
			best, bestHp = i, hp
		end
	end
	return best
end

export type Throw = { to: Vector3, left: number, atTower: boolean }

function StormCoil.groundingPick(throws: { Throw }, center: Vector3, range: number): number?
	local best, soonest = nil, math.huge
	for i, throw in throws do
		if throw.atTower and throw.left < soonest and StormCoil.covered(throw.to, { { center = center, radius = range } }) then
			best, soonest = i, throw.left
		end
	end
	return best
end

return StormCoil
