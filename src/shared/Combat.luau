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

return Combat
