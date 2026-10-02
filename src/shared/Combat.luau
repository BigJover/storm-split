--[[
	Combat rules for the dinos fighting back (VISION.md Step 2, DECISIONS #4, #8,
	#10, #12). Pure, so server and client agree and specs can run headlessly;
	Server/Health and Server/Towers apply them.

	  attackDamage  a dino's attack scales with its size (a half-shrunk dino hits
	                half as hard) and the difficulty's Dino damage x
	  combineResist damage resistance doesn't stack: the strongest source wins,
	                capped at Tuning Max resist
	  towerMaxHp    base Max HP, +Tower HP per tier x base for every tier bought
	                on any path, then any aura's +% max HP
	  repairCost    Repair cost x cash put into the tower x share of HP missing,
	                less a Logistics discount, rounded to the nearest whole
	  pickTarget    the nearest standing target within reach, measured sideways
	                (ignoring height); towers and players alike (DECISIONS #6)
	  landingHits   every standing target within a projectile's impact radius
	                of where it lands, measured sideways (DECISIONS #5)
	  mergeMark     a new mark on a dino that may already carry one: a weaker
	                mark never weakens a stronger one (DECISIONS #97)
	  nearestWithin the few nearest points within reach of a point (the Split
	                Dart perk's extra marks)
]]

local Config = require(script.Parent.Config)

local Combat = {}

-- Damage one attack deals: `base` is the value at the dino's largest size.
function Combat.attackDamage(base: number, size: number, sizes: number, difficultyMult: number): number
	return base * size / math.max(1, sizes) * difficultyMult
end

-- The resistance that applies (percent, 0..MaxResist) from every active source.
function Combat.combineResist(percents: { number }): number
	local best = 0
	for _, percent in percents do
		best = math.max(best, percent)
	end
	return math.min(best, Config.Tuning.MaxResist)
end

-- Damage left after resistance.
function Combat.afterResist(amount: number, resistPercent: number): number
	return amount * (1 - math.clamp(resistPercent, 0, 100) / 100)
end

-- What a hit did to a standing tower, from its HP after the damage: "saved"
-- (a Field Hospital's Last Stand holds it at 1 HP), "trampled", "hit" or
-- "none" (nothing got through).
function Combat.hitOutcome(hpAfter: number, dealt: number, saved: boolean): string
	if hpAfter <= 0 then
		return if saved then "saved" else "trampled"
	end
	return if dealt > 0 then "hit" else "none"
end

-- A med kit is taken only by a living hunter who's missing HP, so a full-HP
-- hunter leaves it for a hurt teammate (DECISIONS #45).
function Combat.takesMedKit(health: number, maxHealth: number): boolean
	return health > 0 and health < maxHealth
end

-- A tower's max HP with these tiers bought and this aura bonus (percent).
function Combat.towerMaxHp(def, pathTiers: { number }, auraHpPercent: number?): number
	local tiers = 0
	for _, tier in pathTiers do
		tiers += tier
	end
	local base = def.maxHp or 0
	return base * (1 + Config.Tuning.TowerHPPerTier * tiers) * (1 + (auraHpPercent or 0) / 100)
end

-- What topping a damaged tower back up to full costs.
function Combat.repairCost(spent: number, hp: number, maxHp: number, discountPercent: number?): number
	if maxHp <= 0 or hp >= maxHp then
		return 0
	end
	local missing = 1 - math.max(0, hp) / maxHp
	local cost = Config.Tuning.RepairCost * spent * missing * (1 - (discountPercent or 0) / 100)
	return math.floor(cost + 0.5)
end

export type Target = {
	position: Vector3,
	standing: boolean, -- false: a trampled tower or a dead / out-of-match player
	ref: any, -- the tower or player
}

-- The nearest standing target within `reach` (horizontal studs) of `point`,
-- or nil. Ties go to the earlier candidate.
function Combat.pickTarget(point: Vector3, candidates: { Target }, reach: number): Target?
	local best, bestGap = nil, math.huge
	for _, candidate in candidates do
		if candidate.standing then
			local offset = candidate.position - point
			local gap = Vector2.new(offset.X, offset.Z).Magnitude
			if gap <= reach and gap < bestGap then
				best, bestGap = candidate, gap
			end
		end
	end
	return best
end

-- Everything a landing projectile hurts: each standing target within
-- `radius` (horizontal studs, inclusive) of `point`.
function Combat.landingHits(point: Vector3, radius: number, candidates: { Target }): { Target }
	local hits = {}
	for _, candidate in candidates do
		if candidate.standing then
			local offset = candidate.position - point
			if Vector2.new(offset.X, offset.Z).Magnitude <= radius then
				table.insert(hits, candidate)
			end
		end
	end
	return hits
end

-- A new mark landing on a dino (Server/Enemies.mark is the only caller). `percent`
-- and `remaining` describe the mark it carries now (remaining <= 0 = none), and the
-- result is the mark it carries afterwards. An equal or stronger mark replaces it. A
-- weaker one never weakens it: the stronger percent stays, and its time is only ever
-- extended, never cut short (the Split Dart perk marks a second dino at reduced
-- strength, DECISIONS #97).
function Combat.mergeMark(percent: number, remaining: number, newPercent: number, newSeconds: number): (number, number)
	if remaining <= 0 or newPercent >= percent then
		return newPercent, newSeconds
	end
	return percent, math.max(remaining, newSeconds)
end

-- The indexes of the `count` nearest `positions` within `reach` studs of `point`
-- (inclusive), nearest first; ties go to the earlier one. Fewer if fewer are in reach.
function Combat.nearestWithin(point: Vector3, positions: { Vector3 }, reach: number, count: number): { number }
	local inReach = {}
	for index, position in positions do
		local gap = (position - point).Magnitude
		if gap <= reach then
			table.insert(inReach, { index = index, gap = gap })
		end
	end
	table.sort(inReach, function(a, b)
		return a.gap < b.gap or (a.gap == b.gap and a.index < b.index)
	end)
	local nearest = {}
	for i = 1, math.min(#inReach, math.max(0, math.floor(count))) do
		nearest[i] = inReach[i].index
	end
	return nearest
end

return Combat
