--[[
	A tower's stats right now: its Config row (base) plus the tiers bought on
	each path. Pure, so it can be tested headlessly and shared later.

	Combining a tower's paths (the ability columns are cumulative per tier):
	  x columns        multiply (MULTIPLIERS)
	  amounts          the highest wins (HIGHEST)
	  yes/no flags     OR (FLAGS)
	  freezeEvery      the shortest pulse interval any path gives
]]

local TowerStats = {}

export type Stats = {
	damage: number,
	rate: number,
	targets: number,
	range: number,
	splashRadius: number,
	shots: number,
	lineHits: number,
	piercesArmor: boolean,
	armoredMult: number,
	bossMult: number,
	markPercent: number,
	stunSeconds: number,
	stunsBosses: boolean,
	knockback: number,
	burnDps: number,
	burnSeconds: number,
	bomblets: number,
	bombletGenerations: number,
	auraRatePercent: number,
	auraDamagePercent: number,
	auraPiercesArmor: boolean,
	slowPercent: number,
	slowLinger: number,
	slowsBosses: boolean,
	freezeEvery: number,
	freezeSeconds: number,
	freezeDamage: number,
	freezeHoldsBosses: boolean,
	brittlePercent: number,
	stripsArmor: boolean,
	incomeMult: number,
	interestPercent: number,
	interestCap: number,
	chests: number,
	chestCash: number,
	discountPercent: number,
	sellRefund: number,
	-- Armory (Step 2): resistance and thorns for everything in range, buffs for hunters in range
	resistPercent: number,
	thornsDamage: number,
	stunBitersSeconds: number,
	hunterRecoilMult: number,
	hunterReloadMult: number,
	hunterSpreadMult: number,
	hunterRatePercent: number,
	-- Field Hospital (Step 2)
	healPerSecond: number, -- to standing towers and hunters in range
	revives: boolean, -- also raises trampled towers in range
	reviveSpeed: number, -- x heal rate while reviving
	medKits: number, -- heal kits dropped each round
	medKitHeal: number,
	rescueRespawnMult: number, -- 0 = no Rescue Beacon; else x respawn time, at the hospital
	auraHpPercent: number, -- towers in range get +% max HP
	lastStand: boolean, -- once a round, a tower in range that would be trampled stays at 1 HP
	sizeBreaks: number, -- pierce-through base: sizes one direct hit may drop (Shared/SizeBreaks)
}

local MULTIPLIERS = {
	"damageMult",
	"rateMult",
	"targetsMult",
	"rangeMult",
	"armoredMult",
	"bossMult",
	"splashMult",
	"incomeMult",
	"hunterRecoilMult",
	"hunterReloadMult",
	"hunterSpreadMult",
	"healMult",
}
local HIGHEST = {
	"shots",
	"lineHits",
	"markPercent",
	"stunSeconds",
	"knockback",
	"burnDps",
	"burnSeconds",
	"bomblets",
	"bombletGenerations",
	"auraRatePercent",
	"auraDamagePercent",
	"slowPercent",
	"slowLinger",
	"freezeSeconds",
	"freezeDamage",
	"brittlePercent",
	"interestPercent",
	"interestCap",
	"chests",
	"chestCash",
	"discountPercent",
	"sellRefund",
	"resistPercent",
	"thornsDamage",
	"stunBitersSeconds",
	"hunterRatePercent",
	"reviveSpeed",
	"medKits",
	"medKitHeal",
	"rescueRespawnMult",
	"auraHpPercent",
	"sizeBreaks",
}
local FLAGS = { "piercesArmor", "stunsBosses", "auraPiercesArmor", "slowsBosses", "freezeHoldsBosses", "stripsArmor", "revives", "lastStand" }

function TowerStats.compute(def, pathTiers: { number }): Stats
	local mult: { [string]: number } = {}
	for _, field in MULTIPLIERS do
		mult[field] = 1
	end
	local high: { [string]: number } = { shots = 1, lineHits = 1 }
	local flag: { [string]: boolean } = {}
	local freezeEvery = 0 -- shortest pulse interval any path gives

	for pathIndex, tier in pathTiers do
		if tier > 0 then
			local step = def.paths[pathIndex].tiers[tier]
			for _, field in MULTIPLIERS do
				mult[field] *= step[field] or 1
			end
			for _, field in HIGHEST do
				high[field] = math.max(high[field] or 0, step[field] or 0)
			end
			for _, field in FLAGS do
				flag[field] = flag[field] or step[field] == true
			end
			local every = step.freezeEvery or 0
			if every > 0 and (freezeEvery == 0 or every < freezeEvery) then
				freezeEvery = every
			end
		end
	end

	return {
		damage = def.baseDamage * mult.damageMult,
		rate = def.baseRate * mult.rateMult,
		targets = math.max(1, math.floor(def.baseTargets * mult.targetsMult + 0.5)),
		range = def.range * mult.rangeMult,
		splashRadius = (def.splashRadius or 0) * mult.splashMult,
		shots = math.max(1, math.floor(high.shots)),
		lineHits = math.max(1, math.floor(high.lineHits)),
		piercesArmor = flag.piercesArmor == true,
		armoredMult = mult.armoredMult,
		bossMult = mult.bossMult,
		markPercent = high.markPercent or 0,
		stunSeconds = high.stunSeconds or 0,
		stunsBosses = flag.stunsBosses == true,
		knockback = high.knockback or 0,
		burnDps = high.burnDps or 0,
		burnSeconds = high.burnSeconds or 0,
		bomblets = math.floor(high.bomblets or 0),
		bombletGenerations = math.floor(high.bombletGenerations or 0),
		auraRatePercent = high.auraRatePercent or 0,
		auraDamagePercent = high.auraDamagePercent or 0,
		auraPiercesArmor = flag.auraPiercesArmor == true,
		slowPercent = math.max(def.slowPercent or 0, high.slowPercent or 0),
		slowLinger = high.slowLinger or 0,
		slowsBosses = flag.slowsBosses == true,
		freezeEvery = freezeEvery,
		freezeSeconds = high.freezeSeconds or 0,
		freezeDamage = high.freezeDamage or 0,
		freezeHoldsBosses = flag.freezeHoldsBosses == true,
		brittlePercent = high.brittlePercent or 0,
		stripsArmor = flag.stripsArmor == true,
		incomeMult = mult.incomeMult,
		interestPercent = high.interestPercent or 0,
		interestCap = high.interestCap or 0,
		chests = math.floor(high.chests or 0),
		chestCash = high.chestCash or 0,
		discountPercent = high.discountPercent or 0,
		sellRefund = high.sellRefund or 0,
		resistPercent = math.max(def.resistPercent or 0, high.resistPercent or 0),
		thornsDamage = high.thornsDamage or 0,
		stunBitersSeconds = high.stunBitersSeconds or 0,
		hunterRecoilMult = mult.hunterRecoilMult,
		hunterReloadMult = mult.hunterReloadMult,
		hunterSpreadMult = mult.hunterSpreadMult,
		hunterRatePercent = high.hunterRatePercent or 0,
		healPerSecond = (def.healPerSecond or 0) * mult.healMult,
		revives = flag.revives == true,
		reviveSpeed = high.reviveSpeed or 0,
		medKits = math.floor(high.medKits or 0),
		medKitHeal = high.medKitHeal or 0,
		rescueRespawnMult = high.rescueRespawnMult or 0,
		auraHpPercent = high.auraHpPercent or 0,
		lastStand = flag.lastStand == true,
		sizeBreaks = math.max(1, math.floor(high.sizeBreaks or 1)),
	}
end

-- The field lists, for specs and tools that check the combine rule.
TowerStats.MULTIPLIERS = MULTIPLIERS
TowerStats.HIGHEST = HIGHEST
TowerStats.FLAGS = FLAGS

return TowerStats
