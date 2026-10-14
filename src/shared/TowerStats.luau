--[[
	A tower's stats right now: its Config row (base) plus the tiers bought on
	each path. Pure, so it can be tested headlessly and shared later.

	Combining a tower's paths (the ability columns are cumulative per tier):
	  x columns        multiply (MULTIPLIERS)
	  amounts          the highest wins (HIGHEST)
	  yes/no flags     OR (FLAGS)
	  freezeEvery      the shortest pulse interval any path gives
	  sinkSeconds      the shortest any path gives (Tuning Tar sink seconds when none)
]]

local Config = require(script.Parent.Config)
local Upgrades = require(script.Parent.Upgrades)

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
	-- Fire Bomblets (PLAN 9c): a path's own burn rides its own bomblets, so only a path
	-- that throws bomblets and burns lights them (a Blast burn never reaches Cluster's).
	bombletBurnDps: number,
	bombletBurnSeconds: number,
	-- Strips armour on a hit (PLAN 9c, #290): the dino it hits loses its armour for
	-- Tuning Strip (s). A chilling tower (Tranq Station) strips through its chill instead.
	stripsOnHit: boolean,
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
	-- Storm Coil (PLAN T64; rules in Shared/StormCoil). 0 / false on a tower that doesn't chain.
	arcs: number, -- arcs after the first hit (Tuning Coil arcs unless a tier raises it)
	arcReach: number, -- studs from one chained dino to the next
	arcForks: number, -- dinos each hop of the chain reaches (Fork Lightning: 2)
	arcJumps: boolean, -- Jump Spark: arcs may reach into any Storm Coil's range
	powerGrid: boolean, -- Power Grid: takes part in the shared grid strike
	staticPercent: number, -- Static Shock: a struck dino takes +% from this coil's next strike
	judgementBolt: boolean, -- Judgement Bolt
	groundingEvery: number, -- Grounding Spike: strikes down a throw at a tower in range every N s
	auraArcPercent: number, -- Lightning Rodeo: towers in range arc each shot once at this %
	-- Falcon Roost (PLAN T65; rules in Shared/Falcon). 0 / false on a tower without birds.
	birds: number, -- birds in the flock (the Towers row's, raised by tiers; 1 with the eagle)
	firstDiveX: number, -- Power Dive: the first dive on each dino x this (1 = off)
	eagle: boolean, -- Eagle of the Peak: one eagle, dives x Tuning Eagle dive x
	murmuration: boolean, -- Murmuration: pecks every dino in range instead of diving
	bossMarkPercent: number, -- Hooded Scout: bosses in range are marked +%
	diveAuraRatePercent: number, -- Hunting Party: towers in range +% attack speed while a bird dives
	-- Harpoon Ballista (PLAN T66; rules in Shared/Ballista). false on a tower without harpoons.
	skewer: boolean, -- Skewer: each bolt passes through every dino on its line (the tier's breaks each)
	towLine: boolean, -- Tow Line: every Tuning Tow Line every s, pulls a boss in range back
	chainHarpoons: boolean, -- Chain Harpoons: bolt pairs hit every dino on the chain between them
	-- Tar Pit (PLAN T67; rules in Shared/TarPit). 0 / false on a tower that isn't on the track.
	sinkSeconds: number, -- s a last-size dino stays in the pool before it sinks
	sinkCash: number, -- Pick and Shovel / Fossil Hunter: cash per sunk dino
	sinkChestCash: number, -- Lucky Finds: each sink drops a chest worth this
	eruption: boolean, -- Eruption: every Tuning Eruption every s, every dino in the pool drops sizes
	tracksSlowPercent: number, -- Tar Tracks: the track past the pool slows this % after a dino leaves
	auraSlowedPercent: number, -- Tar Totem: towers in range +% damage against slowed dinos
	-- Raider sting (PLAN 9d, #294; rules in Shared/RaiderSting): battles only. An enemy hunter who
	-- damages a tower on this side inside this tower's range is stung. 0 = no sting.
	raiderSlowPercent: number,
	raiderSlowSeconds: number,
	raiderDamage: number, -- before the PvP hunter lever (x0.5)
	-- Bounty cash (PLAN 9d, #294): cash to this side for each of its dinos taken down in range.
	bountyCash: number,
	-- Biter slow (PLAN 9d, #294): a dino that bites a tower in range is slowed (not bosses).
	biterSlowPercent: number,
	biterSlowSeconds: number,
	-- PLAN 9e (#297). Field strike (Storm Front; a coil only): every fieldStrikeEvery s, every dino
	-- on its side's field takes fieldStrikeX x its damage. 0 = none.
	fieldStrikeEvery: number,
	fieldStrikeX: number,
	-- Chain effects (Supercell, Superconductor; a coil only): the strike's slow and stun land on
	-- every dino in the chain (an arc's stun capped at Tuning Chain stun cap (s)).
	chainEffects: boolean,
	-- Targets biggest (Heartseeker): aims at the biggest dino in range, not the furthest along.
	targetsBiggest: boolean,
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
	"arcs",
	"arcReach",
	"arcForks",
	"staticPercent",
	"groundingEvery",
	"auraArcPercent",
	"birds",
	"firstDiveX",
	"bossMarkPercent",
	"diveAuraRatePercent",
	"sinkCash",
	"sinkChestCash",
	"tracksSlowPercent",
	"auraSlowedPercent",
	"raiderSlowPercent",
	"raiderSlowSeconds",
	"raiderDamage",
	"bountyCash",
	"biterSlowPercent",
	"biterSlowSeconds",
	"fieldStrikeEvery",
	"fieldStrikeX",
}
local FLAGS = {
	"piercesArmor",
	"stunsBosses",
	"auraPiercesArmor",
	"slowsBosses",
	"freezeHoldsBosses",
	"stripsArmor",
	"revives",
	"lastStand",
	"arcJumps",
	"powerGrid",
	"judgementBolt",
	"eagle",
	"murmuration",
	"skewer",
	"towLine",
	"chainHarpoons",
	"eruption",
	"chainEffects",
	"targetsBiggest",
}

-- `pathPicks` is each path's A/B/C letters ("", "B", "BA"; Shared/Upgrades); nil means
-- option A everywhere (scripted builds, #287).
function TowerStats.compute(def, pathTiers: { number }, pathPicks: { string }?): Stats
	local mult: { [string]: number } = {}
	for _, field in MULTIPLIERS do
		mult[field] = 1
	end
	local high: { [string]: number } = { shots = 1, lineHits = 1 }
	local flag: { [string]: boolean } = {}
	local freezeEvery = 0 -- shortest pulse interval any path gives
	local sinkSeconds = 0 -- shortest sink time any path gives
	local bombletBurnDps, bombletBurnSeconds = 0, 0

	for pathIndex, tier in pathTiers do
		if tier > 0 then
			local step = Upgrades.row(def.paths[pathIndex], tier, if pathPicks then pathPicks[pathIndex] or "" else nil)
			assert(step, "no Config row for this tier and pick")
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
			if (step.bomblets or 0) > 0 and (step.burnDps or 0) > 0 then
				bombletBurnDps = math.max(bombletBurnDps, step.burnDps)
				bombletBurnSeconds = math.max(bombletBurnSeconds, step.burnSeconds or 0)
			end
			local sink = step.sinkSeconds or 0
			if sink > 0 and (sinkSeconds == 0 or sink < sinkSeconds) then
				sinkSeconds = sink
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
		bombletBurnDps = bombletBurnDps,
		bombletBurnSeconds = bombletBurnSeconds,
		stripsOnHit = flag.stripsArmor == true and (high.slowPercent or 0) <= 0 and (def.slowPercent or 0) <= 0 and freezeEvery <= 0,
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
		arcs = if def.chains then math.floor(if (high.arcs or 0) > 0 then high.arcs else Config.Tuning.CoilArcs) else 0,
		arcReach = if def.chains then (if (high.arcReach or 0) > 0 then high.arcReach else Config.Tuning.CoilArcReach) else 0,
		arcForks = if def.chains then math.max(1, math.floor(high.arcForks or 0)) else 0,
		arcJumps = def.chains == true and flag.arcJumps == true,
		powerGrid = def.chains == true and flag.powerGrid == true,
		staticPercent = if def.chains then high.staticPercent or 0 else 0,
		judgementBolt = def.chains == true and flag.judgementBolt == true,
		groundingEvery = high.groundingEvery or 0,
		auraArcPercent = high.auraArcPercent or 0,
		birds = if (def.birds or 0) <= 0 then 0 elseif flag.eagle then 1 else math.floor(math.max(def.birds, high.birds or 0)),
		firstDiveX = if (def.birds or 0) > 0 then math.max(1, high.firstDiveX or 0) else 1,
		eagle = (def.birds or 0) > 0 and flag.eagle == true,
		murmuration = (def.birds or 0) > 0 and flag.murmuration == true,
		bossMarkPercent = high.bossMarkPercent or 0,
		diveAuraRatePercent = if (def.birds or 0) > 0 then high.diveAuraRatePercent or 0 else 0,
		skewer = def.harpoons == true and flag.skewer == true,
		towLine = def.harpoons == true and flag.towLine == true,
		chainHarpoons = def.harpoons == true and flag.chainHarpoons == true,
		sinkSeconds = if def.onTrack then (if sinkSeconds > 0 then sinkSeconds else Config.Tuning.TarSinkSeconds) else 0,
		sinkCash = if def.onTrack then high.sinkCash or 0 else 0,
		sinkChestCash = if def.onTrack then high.sinkChestCash or 0 else 0,
		eruption = def.onTrack == true and flag.eruption == true,
		tracksSlowPercent = if def.onTrack then high.tracksSlowPercent or 0 else 0,
		auraSlowedPercent = high.auraSlowedPercent or 0,
		raiderSlowPercent = high.raiderSlowPercent or 0,
		raiderSlowSeconds = high.raiderSlowSeconds or 0,
		raiderDamage = high.raiderDamage or 0,
		bountyCash = high.bountyCash or 0,
		biterSlowPercent = high.biterSlowPercent or 0,
		biterSlowSeconds = high.biterSlowSeconds or 0,
		fieldStrikeEvery = if def.chains then high.fieldStrikeEvery or 0 else 0,
		fieldStrikeX = if def.chains then high.fieldStrikeX or 0 else 0,
		chainEffects = def.chains == true and flag.chainEffects == true,
		targetsBiggest = flag.targetsBiggest == true,
	}
end

-- The field lists, for specs and tools that check the combine rule.
TowerStats.MULTIPLIERS = MULTIPLIERS
TowerStats.HIGHEST = HIGHEST
TowerStats.FLAGS = FLAGS

-- Every tower's damage multiplier: the team's level (1 + TowerDamagePerLevel per level
-- past 1) times the difficulty's Tower damage x (Chaos = gun skill, PLAN T50 final).
function TowerStats.damageScale(level: number, difficulty: { towerDamageMult: number }?): number
	local levelScale = (1 + Config.Tuning.TowerDamagePerLevel) ^ math.max(0, level - 1)
	return levelScale * (if difficulty then difficulty.towerDamageMult else 1)
end

return TowerStats
