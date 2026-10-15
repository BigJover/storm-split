--!strict
--[[
	Spotter Blimp (PLAN 9h T125 / T125b, DECISIONS #334-#336). Pure.
	Its mooring mast is placed like any tower; the blimp flies its side's track from the spawn
	end to the exit end and back (a lap) at Tuning Blimp speed x Blimp speed x, 30 studs up.
	Everything it does is centred on the track point below it (its range is a circle there),
	or, with Targets biggest (Tracking Beam), on a point that follows the side's biggest dino
	at Blimp speed. It can't be damaged (#148).
	  - Lap drops: Lap chests (one crate a lap instead of the round's Chests), Med kits (that
	    many a lap), Lap repairs (that many Trampled towers within range of its path, a lap).
	  - Paratroopers: once per round played, PARA_DELAY s in, walkers drop below it and stay
	    until the round ends. Airlift: the side's first Trampled tower each round is lifted
	    and set back down repaired after AIRLIFT_S s.
	  - Blinding Glare: dinos under the light miss Throw miss % of their throws (a missed
	    throw lands short). Sky Hook: every Hook every s, the smallest non-boss dino in range
	    with at most Hook max sizes left is lifted off the track (a take-down).
	  - Spotter's Map: own-side hunters see own-side dinos through walls; never a player,
	    never another side's dinos (#319).
	The server (Towers) moves it, aims through it and lands every effect (rule 4).
]]

local Config = require(script.Parent.Config)
local Walker = require(script.Parent.Walker)

local Blimp = {}

Blimp.HEIGHT = 30 -- studs above the track it flies (a look and the gun's muzzle)
Blimp.PARA_DELAY = 10 -- s into a round played the Paratroopers drop (PLAN 9h mechanics 2)
Blimp.AIRLIFT_S = 3 -- s an Airlift holds the tower before it is set down repaired (PLAN 9h)
Blimp.MISS_SHORT = 0.5 -- a missed throw lands this share of the way to its target (Blinding Glare)

type Stats = {
	blimpSpeedMult: number,
	lapChests: boolean,
	lapRepairs: number,
	crateHealPercent: number,
	chests: number,
	chestCash: number,
	medKits: number,
	medKitHeal: number,
	airlift: boolean,
	throwMissPercent: number,
	hookEvery: number,
}

-- Studs a second it flies.
function Blimp.speed(stats: Stats): number
	return Config.Tuning.BlimpSpeedStudsS * stats.blimpSpeedMult
end

-- Seconds a lap takes (spawn end to exit end and back).
function Blimp.lapSeconds(length: number, speed: number): number
	return if speed > 0 then 2 * length / speed else math.huge
end

-- One frame of flight: `at` (studs along the side's track) moving `dir` (+1 toward the exit
-- end, -1 back). Returns the new (at, dir, lap done): a lap is done when it is back at the
-- spawn end.
function Blimp.advance(at: number, dir: number, speed: number, dt: number, length: number): (number, number, boolean)
	if length <= 0 then
		return 0, 1, false
	end
	local lap = false
	local step = speed * dt
	-- Whole laps in one frame never happen at real frame times; a long step just bounces.
	while step > 0 do
		if dir > 0 then
			local room = length - at
			if step < room then
				return at + step, dir, lap
			end
			step -= room
			at, dir = length, -1
		else
			if step < at then
				return at - step, dir, lap
			end
			step -= at
			at, dir = 0, 1
			lap = true
		end
	end
	return at, dir, lap
end

-- Tracking Beam: the light's point moves from `current` toward `target` at `speed`.
function Blimp.follow(current: number, target: number, speed: number, dt: number): number
	local gap = target - current
	local step = speed * dt
	if math.abs(gap) <= step then
		return target
	end
	return current + (if gap > 0 then step else -step)
end

-- Is a point under the blimp's circle (flat distance from the point below it)?
function Blimp.under(point: Vector3, centre: Vector3, range: number): boolean
	local offset = point - centre
	return Vector2.new(offset.X, offset.Z).Magnitude <= range
end

export type Dino = { hp: number, at: number, boss: boolean, sizesLeft: number, inRange: boolean }

-- Targets biggest: the side's dino with the most HP (ties: furthest along), or nil.
function Blimp.biggest(dinos: { Dino }): number?
	local best: number? = nil
	for i, d in dinos do
		local b = if best then dinos[best] else nil
		if not b or d.hp > b.hp or (d.hp == b.hp and d.at > b.at) then
			best = i
		end
	end
	return best
end

-- Sky Hook's pick: the smallest non-boss dino in range with at most Hook max sizes left
-- (fewest sizes; ties furthest along), or nil.
function Blimp.hookPick(dinos: { Dino }): number?
	local cap = Config.Tuning.HookMaxSizes
	local best: number? = nil
	for i, d in dinos do
		if d.inRange and not d.boss and d.sizesLeft <= cap then
			local b = if best then dinos[best] else nil
			if not b or d.sizesLeft < b.sizesLeft or (d.sizesLeft == b.sizesLeft and d.at > b.at) then
				best = i
			end
		end
	end
	return best
end

-- What one finished lap drops below it.
function Blimp.lapDrops(stats: Stats): { crates: number, kits: number, repairs: number }
	return {
		crates = if stats.lapChests and stats.chestCash > 0 then 1 else 0,
		kits = if stats.medKitHeal > 0 then stats.medKits else 0,
		repairs = stats.lapRepairs,
	}
end

-- Crates it drops at a round's start (Supply Camp's Air Drop timing): Chests, unless it drops
-- one every lap instead (Lap chests).
function Blimp.roundCrates(stats: Stats): number
	if stats.lapChests or stats.chestCash <= 0 then
		return 0
	end
	return stats.chests
end

-- Spare Parts: HP a crate gives the tower nearest where it lands.
function Blimp.crateHeal(stats: Stats, maxHp: number): number
	return maxHp * stats.crateHealPercent / 100
end

-- Rebuild Kits: of the Trampled towers' flat distances to the blimp's path, the ones it fixes
-- this lap (within `range`, nearest first, at most `n`). Returns their indices.
function Blimp.repairs(distances: { number }, range: number, n: number): { number }
	local within = {}
	for i, d in distances do
		if d <= range then
			table.insert(within, i)
		end
	end
	table.sort(within, function(a, b)
		return distances[a] < distances[b]
	end)
	local out = {}
	for i = 1, math.min(n, #within) do
		table.insert(out, within[i])
	end
	return out
end

-- Paratroopers drop now? (`elapsed` s into the round played; once a round).
function Blimp.paraDue(paratroopers: number, elapsed: number, dropped: boolean): boolean
	return paratroopers > 0 and not dropped and elapsed >= Blimp.PARA_DELAY
end

-- A paratrooper (the 9g walker in fight mode, Tuning SPOTTER BLIMP stats): hunts ground dinos
-- within Paratrooper reach of where it lands, never runs home, and is gone when downed.
function Blimp.paraParams(): Walker.Params
	local t = Config.Tuning
	return {
		maxHp = t.ParatrooperHP,
		speed = t.ParatrooperSpeed,
		reach = t.RaptorReach,
		range = t.ParatrooperReach,
		leash = t.LeashX,
		retreatShare = 0,
		respawn = math.huge,
		homeHeal = 0,
		rate = t.ParatrooperRate,
		hold = 0,
		bossHold = 0,
		firstDiveX = 1,
		flanking = false,
		targetsFirst = false,
		hitsAir = false,
		resist = 0,
		dodge = false,
		dodgeEvery = t.DodgeEveryS,
		trampleSize = t.TrampleSize,
		trampleShare = t.TrampleShare,
		smallSize = t.SmallSize,
	}
end

-- A paratrooper's shot (before the team's level).
function Blimp.paraDamage(): number
	return Config.Tuning.ParatrooperDamage
end

-- Airlift takes this Trampled tower? (the side's first each round, per blimp).
function Blimp.airlifts(stats: Stats, usedThisRound: boolean): boolean
	return stats.airlift and not usedThisRound
end

-- Blinding Glare: does this throw miss? `roll` in [0, 1).
function Blimp.misses(percent: number, roll: number): boolean
	return percent > 0 and roll < percent / 100
end

-- Where a missed throw lands: short of its target.
function Blimp.shortOf(from: Vector3, to: Vector3): Vector3
	return from + (to - from) * Blimp.MISS_SHORT
end

-- Sky Hook: is its timer up? Returns (new timer, fire).
function Blimp.hookTick(timer: number, dt: number, every: number): (number, boolean)
	if every <= 0 then
		return 0, false
	end
	timer += dt
	if timer >= every then
		return timer - every, true
	end
	return timer, false
end

-- Spotter's Map (client): outline this model? Only a dino (never a player) on the viewer's
-- own side, while a standing blimp of that side has Dino outlines (#319).
function Blimp.outlined(isDino: boolean, dinoSide: number?, viewerSide: number, outlinesOn: boolean): boolean
	return outlinesOn and isDino and dinoSide == viewerSide
end

-- The replicated attribute that says a side's dinos are outlined (Towers sets it).
function Blimp.outlineAttribute(side: number): string
	return `DinoOutlines{side}`
end

return Blimp
