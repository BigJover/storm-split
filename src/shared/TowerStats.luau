--[[
	A tower's stats right now: its Config row (base) plus the tiers bought on
	each path. Pure, so it can be tested headlessly and shared later.

	Combining a tower's paths (the ability columns are cumulative per tier):
	  x columns        multiply (MULTIPLIERS)
	  amounts          the highest wins (HIGHEST)
	  yes/no flags     OR (FLAGS)
	  freezeEvery      the shortest pulse interval any path gives
	  sinkSeconds      the shortest any path gives (Tuning Tar sink seconds when none)
	  timers           (MIN_POSITIVE, PLAN 9g #316) the shortest non-zero any path gives
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
	-- Amber Resin Cannon (PLAN 9g T123; rules in Shared/Resin). 0 on a tower without resin
	-- (Towers column Resin), except the shared Take-down mark %.
	entombSeconds: number, -- s an entomb holds (Tuning Entomb base when the build sets none)
	entombHitsMult: number, -- x the resin hits to entomb
	entombAmpPercent: number, -- an entombed dino takes +% from everything
	entombSpread: number, -- the entomb also takes the n nearest dinos within Spread reach
	entombSlowPercent: number, -- Sticky Bed: dinos near an entombed one slowed this %
	entombAllEvery: number, -- Amber Age: every N s everything in range is entombed (0 = off)
	bossEntombSeconds: number, -- Living Amber: a boss's entomb lasts this, full (0 = Entomb x Boss hard stop x)
	sendBack: number, -- Time Capsule: an entombed non-boss goes this many studs back
	fossilBelowPercent: number, -- entombed at or below this % of its HP: a fossil (not bosses)
	fossilRatePercent: number, -- Fossil Fuel: each fossil, towers in range +% rate this round
	bountyFossilsX: number, -- Prize Fossils: a fossil counts this many take-downs for Bounties
	heartEvery: number, -- Amber Heart: every N-th fossil this match entombs the whole side 1 s
	sealSeconds: number, -- Amber Shield: a tower in range that would be Trampled is sealed at 1 HP
	sealEvery: number, -- Amber Fortress: per tower, once per N s (0 = once a round per cannon)
	sealHealPercent: number, -- Self-Sealing: heals this % of max HP when the seal breaks
	reflectDamage: number, -- Amber Mirror: a throw its Grounding catches hits the thrower for this
	wallSeconds: number, -- Resin Wall: once a round (AutoFire) a track wall holds dinos this long
	takeDownMarkPercent: number, -- 4x common rule: a take-down marks dinos near it +% (Bone Dust)
	-- Walkers (PLAN 9g T124; rules in Shared/Walker): 0 / false / 1 on a tower without walkers
	-- (Towers column Walkers), except the generic Hits air and Hunter damage %.
	hitsAir: boolean, -- the tower can hit flyers (its Towers row, or a Hits air tier: Sky Leap)
	walkers: number, -- walkers this build has (the Towers row's unless a tier raises it)
	walkerHpMult: number,
	walkerSpeedMult: number,
	walkerResistPercent: number,
	walkerRespawnMult: number,
	holdSeconds: number, -- a pounce holds a non-boss (Tuning Pounce hold when the build sets none)
	bossHoldSeconds: number, -- ... a boss, once per boss (0 = never)
	flanking: boolean,
	targetsFirst: boolean,
	healsBetweenRounds: boolean,
	dodge: boolean,
	alpha: boolean, -- Alpha Raptor: one big raptor
	swarm: boolean, -- Raptor Swarm
	charge: boolean, -- Raptor Charge
	guard: boolean, -- Guard Raptors
	stunRoarEvery: number, -- Rex Tamer: roars every N s (0 = none)
	takeDownStackPercent: number, -- Hungry Alpha
	avengerX: number, -- Raider Hounds (0 = off)
	hunterDamagePercent: number, -- own side's hunters in range +% to dinos only (Pack Bond, War Paint, #319)
	-- Bone Totem (PLAN 9h T126; rules in Shared/Totem). Only the TOTEM's rows set these (the
	-- exporter's KEY_ONLY), except the shared Aura range %.
	chargeMult: number, -- x every pop's charge (Bounty Wall)
	hunterChargeX: number, -- a hunter's pop charges x this (1 = like any pop; Shared Charge 2)
	bossChargePercent: number, -- a boss's pop adds this % of a full charge instead (Rare Bones)
	bountyChargeX: number, -- take-downs in range count x this for the owner's Bounties (Bounty Wall)
	chargeNeededMult: number, -- x Tuning Totem charge to be full
	roarEchoes: number, -- Echo Roar: the roar again 1 s later
	roarWholeTrack: boolean, -- Ancient Roar: every dino on its side
	skulls: number, -- Skull Storm: this many skulls instead of the roar
	fullGuardSeconds: number, -- Spirit Guard: towers in range take no damage this long when full
	spiritHunters: boolean, -- Spirit Hunters: ghost hunters when full
	fullCash: number, -- Bone Market: a full charge pays this to the side instead of a roar
	paydayCash: number, -- Camp Payday: + this per hunter on the side, per full charge
	treasure: boolean, -- Ancient Treasure: the first full of the match drops a Treasure cash chest
	chargeAuraDamagePercent: number, -- Old Bones: towers in range + this % x the charge share
	hunterCooldownMult: number, -- Elder Wisdom: own hunters in range, ability cooldown x this
	sideAuraHalf: boolean, -- Totem Pole: its auras reach every tower on the side at half strength
	boneCash: number, -- cash to the side per pop in range
	bankCashPerCharge: number, -- Bone Bank: at each round end, x the charge held
	finishingRoar: boolean, -- Finishing Roar: a free roar at a weak boss in range, once per boss
	auraRangePercent: number, -- towers in range +% range (Ancestor's Eye; the Spotter Blimp's Night Hunt)
	-- Spotter Blimp (PLAN 9h T125b; rules in Shared/Blimp). Only the BLIMP's rows set these (KEY_ONLY).
	blimpSpeedMult: number, -- x Tuning Blimp speed (Gunship)
	lapChests: boolean, -- Cargo Run: one crate every lap instead of the round's Chests
	lapRepairs: number, -- Rebuild Kits: each lap repairs up to this many Trampled towers in reach
	crateHealPercent: number, -- Spare Parts: a crate heals the nearest tower this % of max HP
	paratroopers: number, -- Paratroopers: walkers dropped once a round played
	airlift: boolean, -- Airlift: the side's first Trampled tower each round is repaired
	throwMissPercent: number, -- Blinding Glare: dinos under the light miss this % of their throws
	auraReachX: number, -- Lighthouse: its aura damage reaches Range x this (1 = Range)
	dinoOutlines: boolean, -- Spotter's Map: own-side hunters see own-side dinos through walls (#319)
	bombingRun: boolean, -- Bombing Run: once a round played, Field strike x the gun on the whole side
	hookEvery: number, -- Sky Hook: every N s (0 = none)
	-- Meteor Beacon (PLAN 9i T127; rules in Shared/Meteor). Only the METEOR's rows set these (KEY_ONLY).
	meteors: number, -- each strike is this many small meteors (0/1 = one big meteor)
	scatter: boolean, -- Scatter Field: the n points are the densest of n equal track segments
	meteorEvery: number, -- Endless Rain: one more small meteor every N s (0 = none)
	starfallEvery: number, -- Starfall: every N s Starfall meteors replace the strike (0 = none)
	craterSeconds: number, -- s a crater lasts (0 = Tuning Crater (s); Shared/Meteor)
	craterAmpPercent: number, -- Scorch Marks: a dino crossing a crater takes +% for 3 s
	biteMissPercent: number, -- Ash Cloud: dinos in a crater miss this % of their bites
	craterFreezeSeconds: number, -- New Ice Age: a dino entering a crater is hard-stopped this long, once
	fireLine: boolean, -- Fire Line: craters close along the track join into one burning strip
	burnStreak: boolean, -- Cinder Trail: each small meteor leaves a burning strip
	extinction: boolean, -- Extinction Event: once per round played (AutoFire)
	sideSlowPercent: number, -- Impact Winter: after each meteor every dino on the side is slowed
	sideSlowSeconds: number,
	biggestBreaks: number, -- Dino Killer: the biggest dino a meteor hits breaks this many sizes more
	-- Volcano Vent (PLAN 9i T128; rules in Shared/Vent). Only the VENT's rows set these (KEY_ONLY).
	flowSeconds: number, -- s the lava stays down (0 = Tuning Flow (s))
	flowLengthMult: number, -- x Tuning Flow length
	burnBreaks: boolean, -- Lava Lake: lava ticks break 1
	geyserEvery: number, -- Geyser: a burst every N s between eruptions (0 = none)
	extraVents: number, -- Ring of Fire: small vents erupting in turn
	lavaBombs: boolean, -- Lava Bombs
	bossErupt: boolean, -- Pressure Valve: erupts at once when a boss enters range, once per boss
	sideThrowMissPercent: number, -- Ash Blanket: after each eruption the side's dinos miss this % of throws
	supervolcano: boolean, -- Supervolcano: once per round played (AutoFire)
	crust: boolean, -- Obsidian: crust after each flow
	crustDps: number, -- Jagged Crust: the crust's cut a second (x the team's level)
	mazeStuds: number, -- Glass Maze: a dino crossing the crust walks this much further
	freezeFlowSeconds: number, -- Frozen Fire: when the flow ends its dinos are hard-stopped this long
	throwResistPercent: number, -- Obsidian Armour: towers in range take this % less from throws
	-- Ranger Station (PLAN 9j T129; rules in Shared/Ranger). Only the RANGER's rows set these (KEY_ONLY).
	walkerRegen: number, -- Medic Bag: HP/s a ranger heals at its post
	heavyRanger: boolean, -- Heavy Rifle: the first ranger shoots x Heavy x, breaks 3
	legend: boolean, -- Legend Ranger: one ranger is the Legend
	jeep: boolean, -- Patrol Jeep: the squad drives the side's track
	trap: boolean, -- Snare Kit: a trap at each post
	trapEvery: number, -- s between a post's traps (0 = Tuning Trap every (s))
	trapStunSeconds: number, -- a trap's hard stop (not bosses)
	trapLine: boolean, -- Master Trapper: one-shot traps along the side's track each round played
	decoySeconds: number, -- Decoy Calls: a dino entering a ranger's reach stops this long, once per post
	postAura: boolean, -- Sandbags: Aura HP % on towers near a post
	bossRoundGuard: boolean, -- Hold the Line: rangers can't drop below 1 HP while a boss is out
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
	"entombHitsMult",
	"walkerHpMult",
	"walkerSpeedMult",
	"walkerRespawnMult",
	"chargeMult",
	"chargeNeededMult",
	"hunterCooldownMult",
	"blimpSpeedMult",
	"flowLengthMult",
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
	-- PLAN 9g (T123): the Amber Resin Cannon and the shared Take-down mark %
	"entombSeconds",
	"entombAmpPercent",
	"entombSpread",
	"entombSlowPercent",
	"bossEntombSeconds",
	"sendBack",
	"fossilBelowPercent",
	"fossilRatePercent",
	"bountyFossilsX",
	"sealSeconds",
	"sealHealPercent",
	"reflectDamage",
	"wallSeconds",
	"takeDownMarkPercent",
	-- PLAN 9g (T124): walkers and the Raptor Pen
	"walkers",
	"walkerResistPercent",
	"holdSeconds",
	"bossHoldSeconds",
	"takeDownStackPercent",
	"avengerX",
	"hunterDamagePercent",
	-- PLAN 9h (T126): the Bone Totem and the shared Aura range %
	"hunterChargeX",
	"bossChargePercent",
	"bountyChargeX",
	"roarEchoes",
	"skulls",
	"fullGuardSeconds",
	"fullCash",
	"paydayCash",
	"chargeAuraDamagePercent",
	"boneCash",
	"bankCashPerCharge",
	"auraRangePercent",
	-- PLAN 9h (T125b): the Spotter Blimp
	"lapRepairs",
	"crateHealPercent",
	"paratroopers",
	"throwMissPercent",
	"auraReachX",
	-- PLAN 9i (T127): the Meteor Beacon
	"meteors",
	"craterSeconds",
	"craterAmpPercent",
	"biteMissPercent",
	"craterFreezeSeconds",
	"sideSlowPercent",
	"sideSlowSeconds",
	"biggestBreaks",
	-- PLAN 9i (T128): the Volcano Vent
	"flowSeconds",
	"extraVents",
	"sideThrowMissPercent",
	"crustDps",
	"mazeStuds",
	"freezeFlowSeconds",
	"throwResistPercent",
	-- PLAN 9j (T129): the Ranger Station
	"walkerRegen",
	"trapStunSeconds",
	"decoySeconds",
}
-- Timers where the shortest non-zero wins (PLAN 9g, the exporter's "minpos" kind).
local MIN_POSITIVE = {
	"entombAllEvery",
	"heartEvery",
	"sealEvery",
	"stunRoarEvery",
	"hookEvery",
	"meteorEvery",
	"starfallEvery",
	"geyserEvery",
	"trapEvery",
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
	"hitsAir",
	"flanking",
	"targetsFirst",
	"healsBetweenRounds",
	"dodge",
	"alpha",
	"swarm",
	"charge",
	"guard",
	"roarWholeTrack",
	"spiritHunters",
	"treasure",
	"sideAuraHalf",
	"finishingRoar",
	"lapChests",
	"airlift",
	"dinoOutlines",
	"bombingRun",
	"scatter",
	"fireLine",
	"burnStreak",
	"extinction",
	"burnBreaks",
	"lavaBombs",
	"bossErupt",
	"supervolcano",
	"crust",
	"heavyRanger",
	"legend",
	"jeep",
	"trap",
	"trapLine",
	"postAura",
	"bossRoundGuard",
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
	local shortest: { [string]: number } = {}
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
			for _, field in MIN_POSITIVE do
				local value = step[field] or 0
				if value > 0 and ((shortest[field] or 0) == 0 or value < shortest[field]) then
					shortest[field] = value
				end
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

	local walking = (def.walkers or 0) > 0
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
		firstDiveX = if (def.birds or 0) > 0 or (def.walkers or 0) > 0 then math.max(1, high.firstDiveX or 0) else 1,
		eagle = (def.birds or 0) > 0 and flag.eagle == true,
		murmuration = (def.birds or 0) > 0 and flag.murmuration == true,
		bossMarkPercent = high.bossMarkPercent or 0,
		diveAuraRatePercent = if (def.birds or 0) > 0 or (def.walkers or 0) > 0 then high.diveAuraRatePercent or 0 else 0,
		skewer = def.harpoons == true and flag.skewer == true,
		towLine = def.harpoons == true and flag.towLine == true,
		chainHarpoons = def.harpoons == true and flag.chainHarpoons == true,
		sinkSeconds = if def.onTrack then (if sinkSeconds > 0 then sinkSeconds else Config.Tuning.TarSinkSeconds) else 0,
		sinkCash = if def.onTrack or def.resin then high.sinkCash or 0 else 0, -- a Resin Cannon's fossils too (PLAN 9g)
		sinkChestCash = if def.onTrack or def.resin then high.sinkChestCash or 0 else 0,
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
		fieldStrikeX = if def.chains or flag.bombingRun then high.fieldStrikeX or 0 else 0, -- a Bombing Run's too (T125b)
		chainEffects = def.chains == true and flag.chainEffects == true,
		targetsBiggest = flag.targetsBiggest == true,
		entombSeconds = if def.resin then (if (high.entombSeconds or 0) > 0 then high.entombSeconds else Config.Tuning.EntombBaseS) else 0,
		entombHitsMult = mult.entombHitsMult,
		entombAmpPercent = if def.resin then high.entombAmpPercent or 0 else 0,
		entombSpread = if def.resin then math.floor(high.entombSpread or 0) else 0,
		entombSlowPercent = if def.resin then high.entombSlowPercent or 0 else 0,
		entombAllEvery = if def.resin then shortest.entombAllEvery or 0 else 0,
		bossEntombSeconds = if def.resin then high.bossEntombSeconds or 0 else 0,
		sendBack = if def.resin then high.sendBack or 0 else 0,
		fossilBelowPercent = if def.resin then high.fossilBelowPercent or 0 else 0,
		fossilRatePercent = if def.resin then high.fossilRatePercent or 0 else 0,
		bountyFossilsX = if def.resin then high.bountyFossilsX or 0 else 0,
		heartEvery = if def.resin then math.floor(shortest.heartEvery or 0) else 0,
		sealSeconds = if def.resin then high.sealSeconds or 0 else 0,
		sealEvery = if def.resin then shortest.sealEvery or 0 else 0,
		sealHealPercent = if def.resin then high.sealHealPercent or 0 else 0,
		reflectDamage = high.reflectDamage or 0,
		wallSeconds = if def.resin or (def.nearTrack or 0) > 0 then high.wallSeconds or 0 else 0, -- the Volcano Vent's Obsidian Wall too (PLAN 9i)
		takeDownMarkPercent = high.takeDownMarkPercent or 0,
		hitsAir = def.hitsAir == true or flag.hitsAir == true,
		walkers = if walking then math.floor(math.max(def.walkers, high.walkers or 0)) else 0,
		walkerHpMult = if walking then mult.walkerHpMult else 1,
		walkerSpeedMult = if walking then mult.walkerSpeedMult else 1,
		walkerResistPercent = if walking then high.walkerResistPercent or 0 else 0,
		walkerRespawnMult = if walking then mult.walkerRespawnMult else 1,
		holdSeconds = if walking then (if (high.holdSeconds or 0) > 0 then high.holdSeconds else Config.Tuning.PounceHoldS) else 0,
		bossHoldSeconds = if walking then high.bossHoldSeconds or 0 else 0,
		flanking = walking and flag.flanking == true,
		targetsFirst = walking and flag.targetsFirst == true,
		healsBetweenRounds = walking and flag.healsBetweenRounds == true,
		dodge = walking and flag.dodge == true,
		alpha = walking and flag.alpha == true,
		swarm = walking and flag.swarm == true,
		charge = walking and flag.charge == true,
		guard = walking and flag.guard == true,
		stunRoarEvery = if walking then shortest.stunRoarEvery or 0 else 0,
		takeDownStackPercent = if walking then high.takeDownStackPercent or 0 else 0,
		avengerX = if walking then high.avengerX or 0 else 0,
		hunterDamagePercent = high.hunterDamagePercent or 0,
		chargeMult = mult.chargeMult,
		hunterChargeX = math.max(1, high.hunterChargeX or 0),
		bossChargePercent = high.bossChargePercent or 0,
		bountyChargeX = math.max(1, high.bountyChargeX or 0),
		chargeNeededMult = mult.chargeNeededMult,
		roarEchoes = math.floor(high.roarEchoes or 0),
		roarWholeTrack = flag.roarWholeTrack == true,
		skulls = math.floor(high.skulls or 0),
		fullGuardSeconds = high.fullGuardSeconds or 0,
		spiritHunters = flag.spiritHunters == true,
		fullCash = high.fullCash or 0,
		paydayCash = high.paydayCash or 0,
		treasure = flag.treasure == true,
		chargeAuraDamagePercent = high.chargeAuraDamagePercent or 0,
		hunterCooldownMult = mult.hunterCooldownMult,
		sideAuraHalf = flag.sideAuraHalf == true,
		boneCash = high.boneCash or 0,
		bankCashPerCharge = high.bankCashPerCharge or 0,
		finishingRoar = flag.finishingRoar == true,
		auraRangePercent = high.auraRangePercent or 0,
		blimpSpeedMult = mult.blimpSpeedMult,
		lapChests = flag.lapChests == true,
		lapRepairs = math.floor(high.lapRepairs or 0),
		crateHealPercent = high.crateHealPercent or 0,
		paratroopers = math.floor(high.paratroopers or 0),
		airlift = flag.airlift == true,
		throwMissPercent = high.throwMissPercent or 0,
		auraReachX = math.max(1, high.auraReachX or 0),
		dinoOutlines = flag.dinoOutlines == true,
		bombingRun = flag.bombingRun == true,
		hookEvery = shortest.hookEvery or 0,
		meteors = math.floor(high.meteors or 0),
		scatter = flag.scatter == true,
		meteorEvery = shortest.meteorEvery or 0,
		starfallEvery = shortest.starfallEvery or 0,
		craterSeconds = high.craterSeconds or 0,
		craterAmpPercent = high.craterAmpPercent or 0,
		biteMissPercent = high.biteMissPercent or 0,
		craterFreezeSeconds = high.craterFreezeSeconds or 0,
		fireLine = flag.fireLine == true,
		burnStreak = flag.burnStreak == true,
		extinction = flag.extinction == true,
		sideSlowPercent = high.sideSlowPercent or 0,
		sideSlowSeconds = high.sideSlowSeconds or 0,
		biggestBreaks = math.floor(high.biggestBreaks or 0),
		flowSeconds = high.flowSeconds or 0,
		flowLengthMult = mult.flowLengthMult,
		burnBreaks = flag.burnBreaks == true,
		geyserEvery = shortest.geyserEvery or 0,
		extraVents = math.floor(high.extraVents or 0),
		lavaBombs = flag.lavaBombs == true,
		bossErupt = flag.bossErupt == true,
		sideThrowMissPercent = high.sideThrowMissPercent or 0,
		supervolcano = flag.supervolcano == true,
		crust = flag.crust == true,
		crustDps = high.crustDps or 0,
		mazeStuds = high.mazeStuds or 0,
		freezeFlowSeconds = high.freezeFlowSeconds or 0,
		throwResistPercent = high.throwResistPercent or 0,
		walkerRegen = high.walkerRegen or 0,
		heavyRanger = flag.heavyRanger == true,
		legend = flag.legend == true,
		jeep = flag.jeep == true,
		trap = flag.trap == true,
		trapEvery = shortest.trapEvery or 0,
		trapStunSeconds = high.trapStunSeconds or 0,
		trapLine = flag.trapLine == true,
		decoySeconds = high.decoySeconds or 0,
		postAura = flag.postAura == true,
		bossRoundGuard = flag.bossRoundGuard == true,
	}
end

-- The field lists, for specs and tools that check the combine rule.
TowerStats.MULTIPLIERS = MULTIPLIERS
TowerStats.HIGHEST = HIGHEST
TowerStats.FLAGS = FLAGS
TowerStats.MIN_POSITIVE = MIN_POSITIVE

-- Every tower's damage multiplier: the team's level (1 + TowerDamagePerLevel per level
-- past 1) times the difficulty's Tower damage x (Chaos = gun skill, PLAN T50 final).
function TowerStats.damageScale(level: number, difficulty: { towerDamageMult: number }?): number
	local levelScale = (1 + Config.Tuning.TowerDamagePerLevel) ^ math.max(0, level - 1)
	return levelScale * (if difficulty then difficulty.towerDamageMult else 1)
end

return TowerStats
