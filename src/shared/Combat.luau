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
	  mergeMark     a new mark on a dino that may already carry one: the stronger
	                mark wins outright, an equal one keeps the longer time
	                (DECISIONS #106)
	  nearestWithin the few nearest points within reach of a point (the Split
	                Dart perk's extra marks)
	  burnPatchReach a burning ground patch reaches its splash radius, never less
	                than Tuning Burn patch min reach (DECISIONS #32, #37, #132)
	  throwDamage   what a landing throw deals to one target: a Boss species'
	                throw on a tower x Tuning Boss ranged vs towers x; hunters
	                take it in full (they can dodge; DECISIONS #138, #154)
	  canBeHit      can dinos target or hurt this tower at all: never one that
	                can't be damaged (Towers column Untouchable, DECISIONS #148), nor
	                a trampled one
	  towerDealt    the HP a hit takes off a tower: 0 if it can't be damaged, else
	                the damage after resistance, never more than the HP it has
]]

local Config = require(script.Parent.Config)

local Combat = {}

-- Damage one attack deals: `base` is the value at the dino's largest size.
function Combat.attackDamage(base: number, size: number, sizes: number, difficultyMult: number): number
	return base * size / math.max(1, sizes) * difficultyMult
end

-- What a landing throw deals to one target (DECISIONS #138, #154).
function Combat.throwDamage(damage: number, boss: boolean, onTower: boolean): number
	if boss and onTower then
		return damage * Config.Tuning.BossRangedVsTowersX
	end
	return damage
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

-- Can a dino pick this tower as a target, or hurt it? A tower that can't be damaged
-- (Falcon Roost, Tar Pit; DECISIONS #148) never; a trampled one not until repaired.
function Combat.canBeHit(def, knockedOut: boolean): boolean
	return not def.untouchable and not knockedOut
end

-- The HP a hit takes off a standing tower with `hp` left.
function Combat.towerDealt(def, hp: number, amount: number, resistPercent: number): number
	if def.untouchable or amount <= 0 then
		return 0
	end
	return math.min(hp, Combat.afterResist(amount, resistPercent))
end

-- A tower's max HP with these tiers bought and this aura bonus (percent). A tower
-- that can't be damaged has none (no HP bar, no repair, no Hospital Tonic).
function Combat.towerMaxHp(def, pathTiers: { number }, auraHpPercent: number?): number
	if def.untouchable then
		return 0
	end
	local tiers = 0
	for _, tier in pathTiers do
		tiers += tier
	end
	local base = def.maxHp or 0
	return base * (1 + Config.Tuning.TowerHPPerTier * tiers) * (1 + (auraHpPercent or 0) / 100)
end

-- What topping a damaged tower back up to full costs. `perkMult`: the repairing
-- hunter's Handyman mastery perk (Shared/SmallPerks repairCostMult; 1 = none).
function Combat.repairCost(spent: number, hp: number, maxHp: number, discountPercent: number?, perkMult: number?): number
	if maxHp <= 0 or hp >= maxHp then
		return 0
	end
	local missing = 1 - math.max(0, hp) / maxHp
	local cost = Config.Tuning.RepairCost * spent * missing * (1 - (discountPercent or 0) / 100) * (perkMult or 1)
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
-- result is the mark it carries afterwards. The stronger mark wins outright
-- (DECISIONS #106, the same rule as resistance: nothing stacks). While a mark is
-- running, a weaker new mark changes nothing, neither the strength nor the time (it
-- can't cut a Tracking Dart short, and it can't hold one up either); an equal one
-- keeps the strength and the longer of the two times; a stronger one replaces both.
function Combat.mergeMark(percent: number, remaining: number, newPercent: number, newSeconds: number): (number, number)
	if remaining <= 0 or newPercent > percent then
		return newPercent, newSeconds
	end
	if newPercent < percent then
		return percent, remaining
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

-- Whether a hit can hurt a dino at all: it pierces armour, the dino isn't armoured, or
-- its armour is open right now, through a Tranq chill that strips it (`chillStripped`)
-- or a Strips-armour hit (PLAN 9c, #290) that left it bare until `strippedUntil`.
function Combat.canHurt(armored: boolean, piercesArmor: boolean, chillStripped: boolean, strippedUntil: number, now: number): boolean
	return piercesArmor or not armored or chillStripped or now < strippedUntil
end

-- Heal regen (PLAN 9f, #302; Mending Salve): everything a Triage Kit heals regains `hps`
-- HP a second for `seconds`. Flat (no hero levels); doesn't stack: the strongest HP/s
-- wins and a recast refreshes the time (it never cuts a longer one short).
export type Regen = { hps: number, untilTime: number }

function Combat.regenAfter(old: Regen?, now: number, hps: number, seconds: number): Regen?
	local active = old ~= nil and now < old.untilTime
	if hps <= 0 or seconds <= 0 then
		return if active then old else nil
	end
	if active and old then
		return { hps = math.max(old.hps, hps), untilTime = math.max(old.untilTime, now + seconds) }
	end
	return { hps = hps, untilTime = now + seconds }
end

-- The HP a regen gives over the `dt` seconds up to `now` (0 once it has run out).
function Combat.regenHeal(r: Regen?, now: number, dt: number): number
	if not r or dt <= 0 then
		return 0
	end
	local active = math.max(0, math.min(dt, r.untilTime - (now - dt)))
	return r.hps * active
end

-- Fire Bomblets cap (#306): how many of each generation's bomblets light a fire, first
-- generation first, at most `cap` (Tuning Bomblet fires per shell) per shell. Generation g
-- throws bomblets^g; the bomblets past the cap still hit, they just don't burn.
function Combat.bombletFires(bomblets: number, generations: number, cap: number): { number }
	local fires = {}
	local left = math.max(0, cap)
	for g = 1, generations do
		local n = math.min(left, bomblets ^ g)
		fires[g] = n
		left -= n
	end
	return fires
end

-- How long a Strips-armour hit leaves this dino bare (#307): bosses half the time, by the
-- same Tuning factor as Jaw Lock (Boss jaw lock x), so a boss is bare 1.5 s of Strip's 3.
function Combat.stripSeconds(seconds: number, isBoss: boolean): number
	return if isBoss then seconds * Config.Tuning.BossJawLockX else seconds
end

-- A Strips-armour hit (PLAN 9c): the dino stays bare for `seconds` (Tuning Strip (s))
-- from now; a later strip only ever extends it, never cuts it short.
function Combat.stripUntil(strippedUntil: number, now: number, seconds: number): number
	if seconds <= 0 then
		return strippedUntil
	end
	return math.max(strippedUntil, now + seconds)
end

-- How far a burning ground patch reaches either side of where it lands: the splash,
-- or a tier's own Burn patch reach (Wildfire Drum, DECISIONS #132), never below the
-- Tuning floor.
function Combat.burnPatchReach(splashRadius: number, patchReach: number?): number
	return math.max(splashRadius, patchReach or 0, Config.Tuning.BurnPatchMinReach)
end

return Combat
