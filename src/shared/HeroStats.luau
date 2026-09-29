--[[
	A hero's gun right now: base (Config.Heroes) plus upgrades (its paths).
	Shared so the client's HUD, crosshair and fire loop use exactly the numbers
	the server enforces.

	Combining a hero's paths (the crossover rule allows two):
	  x columns        multiply
	  amounts          the highest wins (pierce, bounces, burn, splash, ...)
	  yes/no flags     OR
	  fire mode, burst count, pellets   from the most-upgraded path that sets them

	Damage is per shot: the hero's base damage x base pellets is split across
	however many pellets the gun now fires (HEROES.md). A slug concentrates it,
	extra pellets spread it.
]]

local Config = require(script.Parent.Config)

local HeroStats = {}

export type Stats = {
	damage: number, -- per pellet
	rate: number, -- trigger pulls per second (per gun)
	fireMode: string, -- "semi" | "auto" | "burst"
	burstCount: number,
	guns: number,
	magazine: number,
	reload: number,
	pellets: number,
	shotsPerTrigger: number,
	spread: number, -- degrees, cone half-angle at rest
	recoilPerShot: number,
	recoilMax: number,
	recoilRecovery: number,
	stillRecoilMult: number,
	range: number,
	pierce: number, -- enemies one pellet passes through
	bounces: number,
	piercesArmor: boolean,
	hitsAir: boolean,
	burnDps: number,
	burnSeconds: number,
	splashRadius: number,
	knockback: number,
	markPercent: number,
	markedDamageMult: number,
	beltFed: boolean,
	spinUp: number,
	scope: boolean,
	igniteSeconds: number,
	abilityPower: number,
	abilitySeconds: number,
	abilityRadius: number,
	abilityCooldown: number,
}

local MULTIPLY = {
	"rateMult",
	"magazineMult",
	"reloadMult",
	"spreadMult",
	"recoilMult",
	"rangeMult",
	"damageMult",
	"markedDamageMult",
	"abilityCooldownMult",
	"stillRecoilMult",
	"spinUp",
}
local HIGHEST = {
	"guns",
	"shotsPerTrigger",
	"pierce",
	"bounces",
	"burnDps",
	"burnSeconds",
	"splashRadius",
	"knockback",
	"markPercent",
	"igniteSeconds",
}
local FLAGS = { "piercesArmor", "hitsAir", "beltFed", "scope" }

function HeroStats.compute(heroKey: string, tiers: { number }): Stats?
	local hero = Config.Heroes[heroKey]
	if not hero then
		return nil
	end

	local mult: { [string]: number } = {}
	for _, field in MULTIPLY do
		mult[field] = 1
	end
	local high: { [string]: number } = {}
	local flag: { [string]: boolean } = {}
	local fireMode, burstCount, pellets = hero.fireMode, 0, hero.pellets
	local fireModeSet, pelletsSet = false, false

	-- Most-upgraded path first, so its overrides win; ties go to the earlier
	-- path, so server and client always agree.
	local order = {}
	for pathIndex in hero.paths do
		table.insert(order, pathIndex)
	end
	table.sort(order, function(a, b)
		local ta, tb = tiers[a] or 0, tiers[b] or 0
		return ta > tb or (ta == tb and a < b)
	end)

	for _, pathIndex in order do
		local tier = tiers[pathIndex] or 0
		if tier > 0 then
			local step = hero.paths[pathIndex].tiers[tier]
			for _, field in MULTIPLY do
				mult[field] *= step[field] or 1
			end
			for _, field in HIGHEST do
				high[field] = math.max(high[field] or 0, step[field] or 0)
			end
			for _, field in FLAGS do
				flag[field] = flag[field] or step[field] == true
			end
			if not fireModeSet and step.fireMode ~= "" then
				fireMode, burstCount, fireModeSet = step.fireMode, step.burstCount, true
			end
			if not pelletsSet and (step.pellets or 0) > 0 then
				pellets, pelletsSet = step.pellets, true
			end
		end
	end

	pellets = math.max(1, math.floor(pellets))
	return {
		damage = hero.damage * hero.pellets / pellets * mult.damageMult,
		rate = hero.rate * mult.rateMult,
		fireMode = fireMode,
		burstCount = math.max(1, math.floor(burstCount)),
		guns = math.max(1, math.floor(high.guns or 1)),
		magazine = math.max(1, math.floor(hero.magazine * mult.magazineMult * math.max(1, high.guns or 1) + 0.5)),
		reload = hero.reload * mult.reloadMult,
		pellets = pellets,
		shotsPerTrigger = math.max(1, math.floor(high.shotsPerTrigger or 1)),
		spread = hero.spread * mult.spreadMult,
		recoilPerShot = hero.recoilPerShot * mult.recoilMult,
		recoilMax = hero.recoilMax * mult.recoilMult,
		recoilRecovery = hero.recoilRecovery,
		stillRecoilMult = mult.stillRecoilMult,
		range = hero.range * mult.rangeMult,
		pierce = math.max(1, math.floor(high.pierce or 1)),
		bounces = math.floor(high.bounces or 0),
		piercesArmor = hero.piercesArmor or flag.piercesArmor == true,
		hitsAir = hero.hitsAir or flag.hitsAir == true,
		burnDps = high.burnDps or 0,
		burnSeconds = high.burnSeconds or 0,
		splashRadius = math.max(hero.splashRadius, high.splashRadius or 0),
		knockback = high.knockback or 0,
		markPercent = high.markPercent or 0,
		markedDamageMult = mult.markedDamageMult,
		beltFed = flag.beltFed == true,
		spinUp = mult.spinUp,
		scope = flag.scope == true,
		igniteSeconds = high.igniteSeconds or 0,
		abilityPower = hero.abilityPower,
		abilitySeconds = hero.abilitySeconds,
		abilityRadius = hero.abilityRadius,
		abilityCooldown = hero.abilityCooldown * mult.abilityCooldownMult,
	}
end

return HeroStats
