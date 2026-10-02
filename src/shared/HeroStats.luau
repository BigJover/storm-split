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

	Gear: an Outfitter Armory the hunter stands near (Server/Towers.hunterGearAt,
	published as the Gear* player attributes so the client fire loop agrees)
	scales recoil, reload and spread, and adds a fire-rate percent. Never damage.

	Mastery perks (Config.MasteryPerks, DECISIONS #97-#99): a hunter whose saved
	mastery with the hero is at or above a perk's level has it, so level 15 has the
	level-10 perk too. A perk's seconds / radius / power are added to the hero's
	BASE ability values, before any path multiplier; its other fields come out as
	markExtra*, strikeBurn*. No mastery (nil or 0) = the stats without perks. The
	server passes Progression.masteryLevel and the client its Mastery_{heroKey}
	attribute, so both compute the same numbers. Perks never touch the gun.
]]

local Config = require(script.Parent.Config)

local HeroStats = {}

export type Stats = {
	damage: number, -- per pellet
	shotDamage: number, -- the whole shot (every pellet)
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
	sizeBreaks: number,
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
	igniteShare: number,
	abilityPower: number,
	abilitySeconds: number,
	abilityRadius: number,
	abilityCooldown: number,
	-- Field Medic (HEAL): the Triage Kit heal and what rides on it, and the
	-- Muzzle rounds' on-hit slow and Jaw Lock.
	heal: number, -- HP per Triage Kit (flat: hero levels don't scale it)
	healRadius: number,
	healRepairsTowers: boolean,
	guardPercent: number, -- Second Wind: damage resistance on everything healed
	guardSeconds: number,
	slowPercent: number,
	slowSeconds: number,
	jawLockSeconds: number, -- a hit dino can't bite or shoot
	jawLockSpread: number, -- the lock also reaches dinos this close to the hit one
	-- Mastery perks (0 without the perk).
	markExtra: number, -- MARK: how many other dinos near the target are marked too
	markExtraPowerMult: number, -- ... at this share of abilityPower
	markExtraReach: number, -- ... within this many studs of the target
	strikeBurnPercent: number, -- AIRBURST: burning ground, % of the strike's damage per second
	strikeBurnSeconds: number,
}

export type Perk = {
	level: number,
	name: string,
	text: string,
	abilitySecondsAdd: number,
	abilityRadiusAdd: number,
	abilityPowerAdd: number,
	markExtra: number,
	markExtraPowerMult: number,
	markExtraReach: number,
	strikeBurnPercent: number,
	strikeBurnSeconds: number,
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
	"healMult",
	"healRadiusMult",
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
	"igniteShare",
	"guardPercent",
	"guardSeconds",
	"slowPercent",
	"slowSeconds",
	"jawLockSeconds",
	"jawLockSpread",
	"sizeBreaks",
}
local FLAGS = { "piercesArmor", "hitsAir", "beltFed", "scope", "healRepairsTowers" }

export type Gear = { recoilMult: number, reloadMult: number, spreadMult: number, ratePercent: number }

HeroStats.NO_GEAR = table.freeze({ recoilMult = 1, reloadMult = 1, spreadMult = 1, ratePercent = 0 }) :: Gear

-- The gear a player's Gear* attributes describe (set by Server/Hero).
function HeroStats.gearOf(player: Player): Gear
	local function attribute(name: string, default: number): number
		local value = player:GetAttribute(name)
		return if typeof(value) == "number" then value else default
	end
	return {
		recoilMult = attribute("GearRecoil", 1),
		reloadMult = attribute("GearReload", 1),
		spreadMult = attribute("GearSpread", 1),
		ratePercent = attribute("GearRate", 0),
	}
end

-- Every mastery perk of a hero, lowest level first (empty for an unknown hero).
function HeroStats.perksOf(heroKey: string): { Perk }
	return (Config.MasteryPerks :: any)[heroKey] or {}
end

-- The perks a hunter with this mastery level has: every perk at or below it.
function HeroStats.perksAt(heroKey: string, masteryLevel: number?): { Perk }
	local level = masteryLevel or 0
	local owned = {}
	for _, perk in HeroStats.perksOf(heroKey) do
		if perk.level <= level then
			table.insert(owned, perk)
		end
	end
	return owned
end

-- Does a hunter with this mastery level have this perk?
function HeroStats.hasPerk(perk: Perk, masteryLevel: number?): boolean
	return perk.level <= (masteryLevel or 0)
end

function HeroStats.compute(heroKey: string, tiers: { number }, gear: Gear?, masteryLevel: number?): Stats?
	local g = gear or HeroStats.NO_GEAR
	local hero = Config.Heroes[heroKey]
	if not hero then
		return nil
	end

	-- Mastery perks first: they change the hero's base ability values, which the
	-- path multipliers below then scale. Added amounts add up; for the rest the
	-- highest wins, like the path amounts.
	local abilityPower, abilitySeconds, abilityRadius = hero.abilityPower, hero.abilitySeconds, hero.abilityRadius
	local markExtra, markExtraPowerMult, markExtraReach = 0, 0, 0
	local strikeBurnPercent, strikeBurnSeconds = 0, 0
	for _, perk in HeroStats.perksAt(heroKey, masteryLevel) do
		abilityPower += perk.abilityPowerAdd
		abilitySeconds += perk.abilitySecondsAdd
		abilityRadius += perk.abilityRadiusAdd
		markExtra += perk.markExtra
		markExtraPowerMult = math.max(markExtraPowerMult, perk.markExtraPowerMult)
		markExtraReach = math.max(markExtraReach, perk.markExtraReach)
		strikeBurnPercent = math.max(strikeBurnPercent, perk.strikeBurnPercent)
		strikeBurnSeconds = math.max(strikeBurnSeconds, perk.strikeBurnSeconds)
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
		shotDamage = hero.damage * hero.pellets * mult.damageMult,
		rate = hero.rate * mult.rateMult * (1 + g.ratePercent / 100),
		fireMode = fireMode,
		burstCount = math.max(1, math.floor(burstCount)),
		guns = math.max(1, math.floor(high.guns or 1)),
		magazine = math.max(1, math.floor(hero.magazine * mult.magazineMult * math.max(1, high.guns or 1) + 0.5)),
		reload = hero.reload * mult.reloadMult * g.reloadMult,
		pellets = pellets,
		shotsPerTrigger = math.max(1, math.floor(high.shotsPerTrigger or 1)),
		spread = hero.spread * mult.spreadMult * g.spreadMult,
		recoilPerShot = hero.recoilPerShot * mult.recoilMult * g.recoilMult,
		recoilMax = hero.recoilMax * mult.recoilMult * g.recoilMult,
		recoilRecovery = hero.recoilRecovery,
		stillRecoilMult = mult.stillRecoilMult,
		range = hero.range * mult.rangeMult,
		pierce = math.max(1, math.floor(high.pierce or 1)),
		bounces = math.floor(high.bounces or 0),
		sizeBreaks = math.max(1, math.floor(high.sizeBreaks or 1)), -- pierce-through base (Shared/SizeBreaks)
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
		igniteShare = high.igniteShare or 0,
		abilityPower = abilityPower,
		abilitySeconds = abilitySeconds,
		abilityRadius = abilityRadius,
		abilityCooldown = hero.abilityCooldown * mult.abilityCooldownMult,
		heal = abilityPower * mult.healMult,
		healRadius = abilityRadius * mult.healRadiusMult,
		healRepairsTowers = flag.healRepairsTowers == true,
		guardPercent = high.guardPercent or 0,
		guardSeconds = high.guardSeconds or 0,
		slowPercent = high.slowPercent or 0,
		slowSeconds = high.slowSeconds or 0,
		jawLockSeconds = high.jawLockSeconds or 0,
		jawLockSpread = high.jawLockSpread or 0,
		markExtra = math.floor(markExtra),
		markExtraPowerMult = markExtraPowerMult,
		markExtraReach = markExtraReach,
		strikeBurnPercent = strikeBurnPercent,
		strikeBurnSeconds = strikeBurnSeconds,
	}
end

return HeroStats
