--[[
	Towers: placement, stats, abilities, targeting, firing.

	A tower is a plain table of state (ARCHITECTURE.md §5.1 — the model is a
	view, never the source of truth). Upgrades change `pathTiers` and
	recompute cached stats; the model can be swapped freely without losing
	anything.

	Towers never touch cash (ARCHITECTURE.md §5.4). The shop pays first, then
	calls place() / upgrade() / remove().

	Every tower has an owner — the player who built it (VISION.md). Kills by
	its shots, bomblets and burns are reported through the onPop hook.

	ABILITIES (UPGRADES.md) come from the spreadsheet's ability columns, which
	are cumulative per tier. Across a tower's paths, multipliers multiply,
	amounts take the highest, and yes/no flags combine with OR (Shared/TowerStats).

	  shots              trigger pulls per fire (Double Tap)
	  lineHits           a shot keeps going through enemies behind its target
	  piercesArmor       can damage Armored enemies at all
	  armoredMult/bossMult  extra damage against those enemies
	  splashMult         scales the tower's splash radius
	  markPercent        its target takes +% from every source for a while
	  stunSeconds, knockback  on every enemy it damages (bomblets too)
	  stripsArmor        on a shooting tower: every dino it damages loses its armour for
	                     Tuning Strip (s), for every tower (PLAN 9c); on a Tranq Station
	                     it's the chill's strip instead
	  burnDps/burnSeconds    leaves a burning patch on the track
	  bomblets           each shell throws this many smaller blasts; a bomblet path that
	                     burns (Fire Bomblets) leaves a small fire under each one
	  aura*              buffs OTHER towers inside this tower's range
	                     (strongest aura wins; auras don't stack)

	LEVELS: every tower's damage (shots, bomblets, freeze, burns) is multiplied
	by the team's level (Towers.setLevel, raised by Main every RoundsPerLevel
	rounds cleared), so towers keep pace with enemy HP alongside upgrades.

	CHILLER: every frame it chills enemies in range (slow, brittle, armour
	strip — Enemies.chill); Freeze towers also pulse a hard stop every
	`freezeEvery` seconds. QUARTERMASTER: never shoots; pays round income
	(Towers.roundIncome), drops chests (Towers.airdrops), and its Logistics
	aura discounts upgrades and raises sell refunds for towers in range.

	HEALTH (VISION.md Step 2, DECISIONS #8/#9): every tower has HP — its Max HP
	column, +Tower HP per tier x base for each tier bought (Shared/Combat).
	Towers owns it: damage() (resistance applied), heal(), repair(). At 0 HP a
	tower is trampled (`knockedOut`): it stops firing, chilling, giving auras,
	paying income and dropping chests, dinos stop targeting it (targets()),
	and it can't be upgraded until repaired. It keeps its tiers.

	FIELD HOSPITAL (DECISIONS #15): each frame it heals standing towers and
	hunters in range (the strongest hospital covering each, no stacking);
	Stitch-Up / Miracle Ward also raise trampled towers in range, which
	stand back up at full HP. Tonic's Aura HP % raises the max HP of towers in
	range (Shared/Combat.towerMaxHp), and Last Stand keeps one tower in range
	per round at 1 HP instead of trampled. Med kits ride Airdrops; the Rescue
	Beacon is Main's (respawn here, sooner).

	STORM COIL (PLAN T64, rules in Shared/StormCoil): a strike hits the first dino
	in range, then arcs from dino to dino (falloff per hop, breaks 1, never past the
	coil's range unless Jump Spark lets it use any Storm Coil's). Static Shock: a
	dino it struck takes +% from its next strike. Thunderclap stuns the first dino
	only. Judgement Bolt: every few seconds one bolt on the dino with the most HP in
	range (x, breaks, stun, bosses too). Power Grid: one shared strike every few
	seconds through every dino in every Storm Coil's range (scaled by how many stand),
	from the strongest Power Grid coil. Lightning Rodeo: an aura; other towers' shots
	in its range arc once to one more dino. Grounding Spike is DinoAttacks' (throws).

	FALCON ROOST (PLAN T65, rules in Shared/Falcon): can't be damaged. Each shot sends a
	bird from the flock at the first dino in range no other bird of the roost is already
	after; it lands after its travel time (the hit), then flies home, and can't go out
	again until it's back. A bird whose dino is gone by then lands nothing. Power Dive:
	the first dive on each dino is stronger; Eagle of the Peak: one eagle, much bigger
	dives that stun. Murmuration: no dives; every shot pecks every dino in range (breaks
	1). Falcon Bells marks the struck dino; Hooded Scout keeps bosses in range marked;
	Lure pulls a struck dino back (Enemies: not bosses). Hunting Party: towers in range
	shoot faster while one of its birds is out (the strongest rate aura wins).

	HARPOON BALLISTA (PLAN T66, rules in Shared/Ballista): heavy bolts. A volley's bolts
	(Shots) spread over the dinos in range, furthest along first. Each bolt is a direct
	hit with the tier's Size breaks (Crusher Bolt 2, Great Harpoon 3). Skewer: each bolt
	flies on through every dino on its line out to the tower's range, each taking the full
	hit and breaks. Chain Harpoons: bolts fly in linked pairs spanning the crowd (the k-th
	dino from the front and from the back); the chain hits every other dino on the segment
	between them (breaks 1, an area hit). Pin Down and Reel In are the hit's stun and
	knockback (never bosses). Tow Line: every Tow Line every s the boss furthest along in
	range is pulled Tow Line pull studs back: the only knockback that moves a boss.

	TAR PIT (PLAN T67, rules in Shared/TarPit): can't be damaged; stands on the track.
	Its pool is `range` studs of track centred where it stands. Every frame each ground dino
	in a pool gets the strongest pool only (#189): its slow, its damage per second
	(Bubbling: Burn DPS, breaks 1), and, at its last size and not a boss, the sink clock:
	after Sink seconds in the tar it sinks (a take-down; Pick and Shovel's cash and Lucky
	Finds' chest go through the onSink hook). Walking out: Clinging Tar keeps it slowed,
	Tar Fire sets it alight (one tick of the pool's damage over Burn seconds), Tar Tracks
	slows the track past the pool for a while. Eruption: every Eruption every s each dino
	in that pool drops Eruption sizes outright (Enemies.dropSizes). Tar Totem: an aura;
	towers in range deal +% to slowed dinos.

	BONE TOTEM (PLAN 9h T126, rules in Shared/Totem): never shoots. Every pop in its range on its
	side (Main's onKilled -> dinoPopped, with who made it: Enemies.source) charges it; full = the
	path's effect next frame (the Spirit Roar, Bone Market's pay, Spirit Guard, War Paint, Spirit
	Hunters, Ancient Treasure). Its own roar, skulls and ghosts never charge a totem. It only reads
	pops: Bones and scores are Main's, as without it. Old Bones' aura follows the charge (refreshed
	at most every AURA_REFRESH s); Bone Bank pays in roundIncome.

	SIDES (PLAN T78, DECISIONS #228, #231; rules in Shared/BattleRules): a tower only ever
	aims at, hurts, slows, stuns or marks its own side's dinos (step() hands each tower its
	own side's dinos; canTarget checks again), and its pool, Power Grid, Thorn Plating,
	auras, healing, Armory cover and Outfitter gear reach only its own side. Co-op is one
	side, so nothing changes there.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Pace = require(Shared:WaitForChild("Pace"))
local Combat = require(Shared:WaitForChild("Combat"))
local Placement = require(Shared:WaitForChild("Placement"))
local Ballista = require(Shared:WaitForChild("Ballista"))
local Falcon = require(Shared:WaitForChild("Falcon"))
local StormCoil = require(Shared:WaitForChild("StormCoil"))
local TarPit = require(Shared:WaitForChild("TarPit"))
local TowerLook = require(Shared:WaitForChild("TowerLook"))
local Cosmetics = require(Shared:WaitForChild("Cosmetics"))
local TowerStats = require(Shared:WaitForChild("TowerStats"))
local Upgrades = require(Shared:WaitForChild("Upgrades"))
local OptionPick = require(Shared:WaitForChild("OptionPick"))
local Sides = require(Shared:WaitForChild("Sides"))
local BattleRules = require(Shared:WaitForChild("BattleRules"))
local TowerPerks = require(Shared:WaitForChild("TowerPerks"))
local Resin = require(Shared:WaitForChild("Resin"))
local Raptor = require(Shared:WaitForChild("Raptor"))
local RaptorLook = require(Shared:WaitForChild("RaptorLook"))
local BattleFlow = require(Shared:WaitForChild("BattleFlow"))
local FourX = require(Shared:WaitForChild("FourX"))
local AutoFire = require(Shared:WaitForChild("AutoFire"))
local Totem = require(Shared:WaitForChild("Totem"))
local Blimp = require(Shared:WaitForChild("Blimp"))
local Meteor = require(Shared:WaitForChild("Meteor"))

local Effects = require(script.Parent.Effects)
local Enemies = require(script.Parent.Enemies)
local Hazards = require(script.Parent.Hazards)
local Health = require(script.Parent.Health)
local Walkers = require(script.Parent.Walkers)

local Towers = {}

export type Stats = TowerStats.Stats

-- What nearby auras give this tower right now.
type Buff = {
	ratePercent: number,
	damagePercent: number,
	piercesArmor: boolean,
	discountPercent: number, -- off its upgrades (Logistics)
	sellRefund: number, -- 0 = the normal SellRefund
	resistPercent: number, -- damage resistance (an Armory in range, itself included)
	hpPercent: number, -- +% max HP (a Field Hospital's Tonic in range)
	arcPercent: number, -- Lightning Rodeo in range: each shot arcs once at this %
	slowedPercent: number, -- Tar Totem in range: +% damage against slowed dinos
	rangePercent: number, -- +% range (Ancestor's Eye, PLAN 9h; never on a Tar Pit's pool)
}

export type Tower = {
	id: number,
	key: string,
	def: any,
	owner: Player?, -- who built it; nil if they've left
	standInPierce: boolean, -- a Studio stand-in camp's tower: pierces armour (PLAN T91b, Shared/StudioOnly)
	side: number, -- the side it was built on (Shared/Sides; co-op = 1); its pool and track effects use that track
	base: Vector3, -- on the build floor; what Placement checks against
	position: Vector3,
	muzzle: Vector3,
	pathTiers: { number },
	pathPicks: { string }, -- each path's A/B/C letters: "", "B", "BA" (PLAN T111, #287; match only)
	stats: Stats,
	buff: Buff,
	cooldown: number,
	freezeTimer: number,
	hp: number,
	maxHp: number,
	knockedOut: boolean, -- trampled at 0 HP until repaired
	lastStandUsed: boolean, -- a Field Hospital's Last Stand has saved a tower this round
	boltTimer: number, -- Storm Coil: seconds toward its next Judgement Bolt
	fieldTimer: number, -- Storm Coil Storm Front: seconds toward its next field strike (PLAN 9e)
	static: { [any]: boolean }, -- Storm Coil Static Shock: dinos its last strike charged (weak keys)
	sorties: { Sortie }, -- Falcon Roost: birds out of the roost
	dived: { [any]: boolean }, -- Falcon Roost Power Dive: dinos it has dived on (weak keys)
	towTimer: number, -- Harpoon Ballista: seconds toward its next Tow Line pull
	poolAt: number, -- Tar Pit: distance along the track of the pool's centre
	eruptTimer: number, -- Tar Pit: seconds toward its next Eruption
	tracksUntil: number, -- Tar Pit: Tar Tracks' footprints last until then (os.clock)
	sealedUntil: number, -- an Amber Shield seal: no damage until then (os.clock; PLAN 9g)
	sealHealPercent: number, -- ... and Self-Sealing's heal when it breaks (0 = none)
	resin: ResinState?, -- Amber Resin Cannon (PLAN 9g T123); nil on every other tower
	raptor: RaptorState?, -- Raptor Pen (PLAN 9g T124); nil on every other tower
	totem: TotemState?, -- Bone Totem (PLAN 9h T126); nil on every other tower
	blimp: BlimpState?, -- Spotter Blimp (PLAN 9h T125b); nil on every other tower
	meteor: MeteorState?, -- Meteor Beacon (PLAN 9i T127); nil on every other tower
	rangeBase: number, -- stats.range before any range aura (PLAN 9h)
	hurtBy: any?, -- the last dino that bit or hit it with a throw (Guard Raptors, PLAN 9g)
	model: Model,
}

-- A Raptor Pen's own state (Shared/Raptor rules; its raptors are Server/Walkers').
type RaptorState = {
	auto: AutoFire.State, -- Raptor Swarm / Raptor Charge, once a round
	swarmKey: { key: string, id: number }, -- the Swarm's own pack in Walkers
	swarmUntil: number,
	charge: { elapsed: number, bitten: { [any]: boolean } }?,
	roarTimer: number,
	takeDowns: number, -- by its raptors this round (Hungry Alpha)
	attacker: any?, -- the last dino that hurt a tower in range (Raider Hounds)
	lastStung: number?, -- when it last stung a raider (os.clock)
	posts: { any }, -- Guard Raptors: the tower each raptor guards
	postTimer: number,
}

-- A Bone Totem's own state (Shared/Totem rules).
type TotemState = {
	rules: Totem.State, -- the charge, full charges this match, the treasure, Bounty Wall's fraction
	pending: number, -- full charges waiting to fire (a pop fills it inside Enemies' damage call)
	echoAt: number, -- Echo Roar: when the second roar goes (os.clock; 0 = none)
	buffUntil: number, -- War Paint: own hunters in range +% until then
	spiritUntil: number, -- Spirit Hunters: the ghost hunters fire until then
	spiritTimer: number,
	finished: { [any]: boolean }, -- Finishing Roar: bosses that had their free roar (weak keys)
	shownShare: number, -- the charge ring's share as last drawn (visual)
}

-- A Spotter Blimp's own state (Shared/Blimp rules). The tower's `position` is the ground point
-- its circle is centred on (below the blimp, or Tracking Beam's point); `base` is the mast.
type BlimpState = {
	at: number, -- the blimp's distance along its side's track
	dir: number, -- +1 toward the exit end, -1 back
	focus: number, -- the circle's centre along the track (Tracking Beam follows the biggest dino)
	model: Model, -- the flying blimp (visual)
	auto: AutoFire.State, -- Bombing Run, once a round played
	hookTimer: number, -- Sky Hook
	roundClock: number, -- s into the round played (Paratroopers)
	paraDropped: boolean,
	airliftUsed: boolean,
	paraKey: { key: string, id: number }, -- its Paratroopers' own pack in Walkers
}

-- A Meteor Beacon's own state (Shared/Meteor rules).
type MeteorState = {
	timer: number, -- s toward the next strike (Starfall's wave with Starfall)
	rainTimer: number, -- Endless Rain: s toward the next small meteor
	landings: { any }, -- meteors on their way (warning ring showing)
	craters: { Meteor.Crater },
	auto: AutoFire.State, -- Comet Tail, once a round played
	extinctionAuto: { fired: boolean }, -- Extinction Event, once a round played
}

-- An Amber Resin Cannon's own state (Shared/Resin rules).
type ResinState = {
	dinos: { [any]: Resin.Dino }, -- resin on each dino it hit (weak keys)
	entombed: { [any]: number }, -- dinos it entombed and until when (weak keys; Sticky Bed)
	allTimer: number, -- Amber Age: seconds toward the next entomb-all
	fossils: number, -- this match (Amber Heart, the Studio `fossils` aid)
	fossilsRound: number, -- this round (Fossil Fuel)
	fuelPercent: number, -- Fossil Fuel's rate aura now
	sealUsed: boolean, -- its once-a-round seal is spent
	sealedAt: { [any]: number }, -- Amber Fortress: when it last sealed each tower (weak keys)
	auto: AutoFire.State, -- Resin Wall's once-a-round trigger
	wall: { at: number, raisedAt: number, part: BasePart? }?, -- a raised Resin Wall
}

-- One bird out of a Falcon Roost: it lands on `enemy` when `out` runs down, and is home
-- when `back` does. The part is the look only.
type Sortie = { enemy: any, out: number, back: number, landed: boolean, at: Vector3, part: BasePart }

-- Visuals only.
local BOMBLET_COLOR = Color3.fromRGB(255, 190, 90)
local ARC_COLOR = Color3.fromRGB(170, 210, 255)
local BOLT_COLOR = Color3.fromRGB(255, 250, 200)
local BIRD_COLOR = Color3.fromRGB(120, 85, 55)
local PECK_COLOR = Color3.fromRGB(200, 170, 130)
local HARPOON_COLOR = Color3.fromRGB(90, 70, 50)
local CHAIN_COLOR = Color3.fromRGB(110, 110, 120)

local towers: { Tower } = {}
local towerFolder: Instance
local nextId = 0
local onPop: ((Player?, string?) -> ())? = nil
local onSink: ((cash: number, chestCash: number, position: Vector3, side: number) -> ())? = nil -- Dig Site pay
local onBountyExtra: ((Player, string, number) -> ())? = nil -- Prize Fossils (PLAN 9g), Bounty Wall (9h)
local onCash: ((side: number, cash: number) -> ())? = nil -- Bone Totem cash (PLAN 9h; Main pays, scaled)
local onCrate: ((position: Vector3, cash: number, side: number) -> ())? = nil -- Ancient Treasure's chest (9h)
local huntersOn: ((side: number) -> number)? = nil -- hunters on a side (Camp Payday, 9h)
local onKit: ((position: Vector3, heal: number, side: number) -> ())? = nil -- a Spotter Blimp's lap med kit (9h)
local auraDirty = false -- a Bone Totem's charge share moved: auras are refreshed at most every AURA_REFRESH s
local auraClock = 0
local levelScale = 1 -- damage multiplier from the team's level
local towerLevel = 1 -- the team's level itself (pierce-through's level bonus)
local extraRatePercent: ((Tower) -> number)? = nil -- boosts from outside towers (hero Rally Cry)
local resistOf: ((Tower) -> { number })? = nil -- extra damage resistance sources (Field Medic Second Wind)

-- A pop goes to the tower's owner; if they've left, nobody gets it, but the hook still
-- hears which dino is gone (a boss counts for the whole team's bounties). A hit that
-- dropped several sizes (pierce-through) is one pop per size; the last says "gone".
local function credit(owner: Player?, killed: boolean, gone: string?, dropped: number?)
	if killed and onPop then
		local who = if owner and owner.Parent then owner else nil
		local pops = math.max(1, dropped or 1)
		for i = 1, pops do
			onPop(who, if i == pops then gone else nil)
		end
	end
end

local TOWER: BattleRules.DamageOpts = table.freeze({ attacker = "tower" })
local HAZARD: BattleRules.DamageOpts = table.freeze({ attacker = "hazard" })

-- Its own side's dino? (Shared/BattleRules: a tower never touches another side's.)
local function ownSide(tower: Tower, enemy: Enemies.Enemy): boolean
	return BattleRules.canDamage(tower.side, enemy.side, "dino", TOWER)
end

------------------------------------------------------------------ stats

local NO_BUFF: Buff =
	table.freeze({ ratePercent = 0, damagePercent = 0, piercesArmor = false, discountPercent = 0, sellRefund = 0, resistPercent = 0, hpPercent = 0, arcPercent = 0, slowedPercent = 0, rangePercent = 0 })
local showHealth: (Tower) -> () -- below, with the rest of health

local function hasAura(s: Stats): boolean
	return s.auraRatePercent > 0
		or s.auraDamagePercent > 0
		or s.auraPiercesArmor
		or s.discountPercent > 0
		or s.sellRefund > 0
		or s.resistPercent > 0
		or s.auraHpPercent > 0
		or s.auraArcPercent > 0
		or s.auraSlowedPercent > 0
		or s.auraRangePercent > 0
end

local function covers(source: Tower, point: Vector3): boolean
	-- A Spotter Blimp's circle is centred below it (PLAN 9h), not on its mast.
	local offset = point - (if source.blimp then source.position else source.base)
	return Vector2.new(offset.X, offset.Z).Magnitude <= source.stats.range
end

-- Recomputed whenever a tower is placed, upgraded or removed (and as a Bone Totem's charge
-- moves, PLAN 9h). The shop panel reads Discount / RefundRate from the tower's body.
local function refreshAuras()
	local ranges: { [Tower]: number } = {}
	for _, tower in towers do
		local rate, damage, pierce, discount, refund, resist, hpBonus, arc, slowed, range = 0, 0, false, 0, 0, 0, 0, 0, 0, 0
		for _, source in towers do
			local s = source.stats
			local fuel = if source.resin then source.resin.fuelPercent else 0 -- Fossil Fuel (PLAN 9g)
			-- A Bone Totem (PLAN 9h): Old Bones scales with its charge; Totem Pole's auras reach the
			-- rest of its side at half strength.
			local totem = source.totem
			if totem and source ~= tower and not source.knockedOut and BattleRules.canSupport(source.side, tower.side) then
				local inRange = covers(source, tower.base)
				damage = math.max(damage, Totem.chargeAura(totem.rules, s, inRange))
				if not inRange and s.sideAuraHalf then
					hpBonus = if tower.def.untouchable then hpBonus else math.max(hpBonus, Totem.auraAt(s.auraHpPercent, false, true))
					range = math.max(range, Totem.auraAt(s.auraRangePercent, false, true))
				end
			end
			-- Lighthouse (PLAN 9h T125b): a blimp's aura damage reaches Range x Aura reach x.
			if source.blimp and source ~= tower and s.auraDamagePercent > 0 and BattleRules.canSupport(source.side, tower.side)
				and Blimp.under(tower.base, source.position, s.range * s.auraReachX) then
				damage = math.max(damage, s.auraDamagePercent)
			end
			if not source.knockedOut and (hasAura(s) or fuel > 0) and covers(source, tower.base) and BattleRules.canSupport(source.side, tower.side) then
				-- An Armory's resistance covers itself too; the other auras are for others.
				-- Armory and Field Hospital auras skip a tower that can't be damaged (#148).
				if not tower.def.untouchable then
					resist = math.max(resist, s.resistPercent)
				end
				if source ~= tower then
					rate = math.max(rate, s.auraRatePercent, fuel)
					damage = math.max(damage, s.auraDamagePercent)
					pierce = pierce or s.auraPiercesArmor
					discount = math.max(discount, s.discountPercent)
					refund = math.max(refund, s.sellRefund)
					hpBonus = if tower.def.untouchable then 0 else math.max(hpBonus, s.auraHpPercent)
					arc = math.max(arc, s.auraArcPercent)
					slowed = math.max(slowed, s.auraSlowedPercent)
					range = math.max(range, s.auraRangePercent)
				end
			end
		end
		ranges[tower] = range
		tower.buff = if rate > 0 or damage > 0 or pierce or discount > 0 or refund > 0 or resist > 0 or hpBonus > 0 or arc > 0 or slowed > 0 or range > 0
			then {
				ratePercent = rate,
				damagePercent = damage,
				piercesArmor = pierce,
				discountPercent = discount,
				sellRefund = refund,
				resistPercent = resist,
				hpPercent = hpBonus,
				arcPercent = arc,
				slowedPercent = slowed,
				rangePercent = range,
			}
			else NO_BUFF
		-- Tonic: gaining the aura adds the HP it gives; losing it only caps HP.
		local maxHp = Combat.towerMaxHp(tower.def, tower.pathTiers, hpBonus)
		if maxHp ~= tower.maxHp then
			if maxHp > tower.maxHp and not tower.knockedOut then
				tower.hp += maxHp - tower.maxHp
			end
			tower.maxHp = maxHp
			tower.hp = math.min(tower.hp, maxHp)
			showHealth(tower)
		end
		local body = tower.model.PrimaryPart
		if body then
			body:SetAttribute("Discount", discount)
			body:SetAttribute("RefundRate", math.max(Config.Tuning.SellRefund, refund))
		end
	end
	-- Range auras land after every tower's cover is worked out (a Tar Pit's range is its pool's
	-- length: never stretched).
	for tower, range in ranges do
		if not tower.def.onTrack then
			tower.stats.range = tower.rangeBase * (1 + range / 100)
		end
	end
end

-- The crossover rule lives in Shared/Upgrades so the client can grey out buttons.
-- A trampled tower can't be upgraded until it's repaired.
function Towers.canUpgrade(tower: Tower, pathIndex: number): boolean
	local path = tower.def.paths[pathIndex]
	return path ~= nil and not tower.knockedOut and Upgrades.check(tower.pathTiers, pathIndex, Upgrades.tierCount(path)) == "ok"
end

------------------------------------------------------------------ health

-- The body carries HP / MaxHP / KO for the tower panel; the model shows a bar.
function showHealth(tower: Tower)
	local body = tower.model.PrimaryPart
	if body then
		-- Exact values, so the panel's repair price matches the server's.
		body:SetAttribute("HP", tower.hp)
		body:SetAttribute("MaxHP", tower.maxHp)
		body:SetAttribute("KO", tower.knockedOut)
	end
	TowerLook.setHealth(tower.model, if tower.maxHp > 0 then tower.hp / tower.maxHp else 1)
end

-- Set below (Raptor Pen): tells Server/Walkers what a tower's walkers are now.
local syncWalkers: (Tower) -> () = function(_tower) end
local airlift: (Tower) -> () = function(_tower) end -- Spotter Blimp Airlift (below)

local function setKnockedOut(tower: Tower, on: boolean)
	if tower.knockedOut == on then
		return
	end
	tower.knockedOut = on
	tower.cooldown = 0
	tower.freezeTimer = 0
	TowerLook.setKnockedOut(tower.model, on)
	refreshAuras() -- its auras go (and come back on repair)
	syncWalkers(tower) -- a Trampled pen keeps its raptors out but sends none (#315)
end

-- Last Stand: the first standing hospital covering this tower that hasn't
-- saved one yet this round spends its save. Returns that hospital, or nil.
local function lastStand(tower: Tower): Tower?
	for _, source in towers do
		if source.stats.lastStand and not source.lastStandUsed and not source.knockedOut and covers(source, tower.base) and BattleRules.canSupport(source.side, tower.side) then
			source.lastStandUsed = true
			return source
		end
	end
	return nil
end

-- Amber Shield (PLAN 9g): a tower in a standing own-side cannon's range that would be
-- Trampled is left at 1 HP and sealed for Seal (s) instead (once a round per cannon, or
-- Amber Fortress: once per Seal every (s) per tower). Returns true if it was sealed.
local function seal(tower: Tower): boolean
	local now = os.clock()
	for _, source in towers do
		local s, state = source.stats, source.resin
		if state and not source.knockedOut and s.sealSeconds > 0 and covers(source, tower.base) and BattleRules.canSupport(source.side, tower.side)
			and Resin.canSeal(s.sealSeconds, s.sealEvery, state.sealUsed, state.sealedAt[tower], now) then
			if s.sealEvery > 0 then
				state.sealedAt[tower] = now
			else
				state.sealUsed = true
			end
			tower.hp = 1
			tower.sealedUntil = now + s.sealSeconds
			tower.sealHealPercent = s.sealHealPercent
			local shell = Effects.part(Vector3.new(4.5, TowerLook.BODY_HEIGHT + 1, 4.5), CFrame.new(tower.position), Color3.fromRGB(255, 160, 40), s.sealSeconds)
			shell.Transparency = 0.5
			shell.Material = Enum.Material.Glass
			return true
		end
	end
	return false
end

------------------------------------------------------------------ PLAN 9d perks (Shared/TowerPerks)

local stungAt: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any -- last Raider sting, per hunter

local POOL_STEP = 3 -- studs between a pool's drawn (and sting-measured) points

-- A Raider tower's sting reach (#321): its range, but an on-track tower (Bog Boots) stings
-- only within Pool sting reach of the nearest point of its pool (current length).
local function stingCovers(source: Tower, point: Vector3): boolean
	if not source.def.onTrack then
		return covers(source, point)
	end
	local points = {}
	for _, d in TarPit.samples(source.poolAt, source.stats.range, POOL_STEP) do
		table.insert(points, Enemies.pointAt(d, source.side))
	end
	return TarPit.nearPool(point, points, Config.Tuning.PoolStingReachStuds)
end

-- The towers with any of `fields` > 0, as Shared/TowerPerks sees them from `point`.
-- `reach`: how a source covers the point (default its range, `covers`).
local function perkSources(point: Vector3, fields: { string }, reach: ((Tower, Vector3) -> boolean)?): { TowerPerks.Source }
	local covered = reach or covers
	local out = {}
	for _, source in towers do
		local has = false
		for _, field in fields do
			has = has or ((source.stats :: any)[field] or 0) > 0
		end
		if has then
			table.insert(out, { side = source.side, standing = not source.knockedOut, covers = covered(source, point), stats = source.stats })
		end
	end
	return out
end

-- Raider sting (#294): `hunter` just damaged `tower`. Sleeper Darts / Barbed Wire covering
-- where the hunter stands, on the tower's side, sting them (battles only, enemies only).
local RAIDER_FIELDS = { "raiderSlowPercent", "raiderDamage" }
local BOUNTY_FIELDS = { "bountyCash" }
local BITER_FIELDS = { "biterSlowPercent" }
local function stingRaider(tower: Tower, hunter: Player)
	local character = hunter.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return
	end
	local sources = perkSources(root.Position, RAIDER_FIELDS, stingCovers)
	if #sources == 0 then
		return
	end
	local now = os.clock()
	local hunterSide = Sides.playerSide(hunter:GetAttribute("Side"), ReplicatedStorage:GetAttribute("Sides"))
	local sting = TowerPerks.sting(sources, tower.side, hunterSide, Health.camoCover(hunter), stungAt[hunter], now)
	if not sting then
		return
	end
	stungAt[hunter] = now
	for _, pen in towers do -- Raider Hounds: a raider was stung here (PLAN 9g, Shared/Raptor.avenger)
		if pen.raptor and pen.stats.avengerX > 0 and pen.side == tower.side and stingCovers(pen, root.Position) then
			pen.raptor.lastStung = now
		end
	end
	if sting.damage > 0 then
		Health.pvpHit(hunter, sting.damage)
	end
	if sting.slowPercent > 0 then
		Health.slow(hunter, sting.slowPercent, sting.slowSeconds)
	end
end

-- Bounty cash (#294) for a dino of `side` taken down at `position`: the strongest standing
-- own-side Supply Camp covering it (Main pays it through Economy).
function Towers.bountyAt(position: Vector3, side: number): number
	return TowerPerks.bounty(perkSources(position, BOUNTY_FIELDS), side)
end

-- Hurts a standing tower, less its resistance. At 0 HP it's trampled.
-- `source` is who or what did it (kept for PvP later). Returns the damage dealt.
-- A tower that can't be damaged (DECISIONS #148) takes nothing and shows nothing.
function Towers.damage(tower: Tower, amount: number, source: any?): number
	if not Combat.canBeHit(tower.def, tower.knockedOut) or amount <= 0 or not table.find(towers, tower) then
		return 0
	end
	if os.clock() < tower.sealedUntil then
		return 0 -- sealed in amber (PLAN 9g): no damage until the seal breaks
	end
	local sources = if resistOf then table.clone(resistOf(tower)) else {}
	table.insert(sources, tower.buff.resistPercent) -- an Armory in range
	local resist = Combat.combineResist(sources)
	local dealt = Combat.towerDealt(tower.def, tower.hp, amount, resist)
	if dealt > 0 and typeof(source) == "Instance" and source:IsA("Player") then
		stingRaider(tower, source) -- before the hit lands: a Raider tower trampled by it still stings
	elseif dealt > 0 and type(source) == "table" and source.alive ~= nil then
		-- A dino bit it or hit it with a throw (PLAN 9g): Guard Raptors answer at its post;
		-- Raider Hounds remember it for every pen covering this tower.
		tower.hurtBy = source
		for _, pen in towers do
			if pen.raptor and pen.stats.avengerX > 0 and covers(pen, tower.base) and BattleRules.canSupport(pen.side, tower.side) then
				pen.raptor.attacker = source
			end
		end
	end
	tower.hp -= dealt
	if tower.hp <= 0 and seal(tower) then
		showHealth(tower)
		return dealt
	end
	local saver = if tower.hp <= 0 then lastStand(tower) else nil
	local outcome = Combat.hitOutcome(tower.hp, dealt, saver ~= nil)
	if outcome == "saved" then
		tower.hp = 1 -- a Field Hospital's Last Stand: not this time
	elseif outcome == "trampled" then
		tower.hp = 0
		setKnockedOut(tower, true)
		airlift(tower)
	end
	-- Visual only: a red hit flash, or Last Stand's green save flash and the
	-- saving hospital's "+" pulse (DECISIONS #48).
	TowerLook.showHit(tower.model, outcome, if saver then saver.model else nil)
	showHealth(tower)
	return dealt
end

-- Heals a standing tower, never past max. Trampled towers need a repair; one
-- that can't be damaged has no HP to heal.
function Towers.heal(tower: Tower, amount: number)
	if tower.knockedOut or tower.def.untouchable or amount <= 0 or tower.hp >= tower.maxHp then
		return
	end
	tower.hp = math.min(tower.maxHp, tower.hp + amount)
	showHealth(tower)
end

-- Back to full HP, and standing again if it was trampled. Doesn't charge
-- cash: the caller (Shop) pays first. A tower that can't be damaged is never
-- repaired (Shop refuses; this is a no-op for it).
function Towers.repair(tower: Tower)
	if tower.def.untouchable then
		return
	end
	tower.hp = tower.maxHp
	setKnockedOut(tower, false)
	showHealth(tower)
end

------------------------------------------------------------------ Armory

-- The strongest Armory resistance covering a point (a hunter standing there), from the
-- hunter's own side's Armories only (`side`, default 1, co-op).
function Towers.resistAt(position: Vector3, side: number?): number
	local best = 0
	for _, source in towers do
		if not source.knockedOut and source.stats.resistPercent > 0 and covers(source, position) and BattleRules.canSupport(source.side, side or 1) then
			best = math.max(best, source.stats.resistPercent)
		end
	end
	return best
end

-- A dino just bit something standing at `position`: the strongest Thorn
-- Plating covering it bites back (pierces armour, scales with the team's
-- level, kill credited to the Armory's owner), Bulwark stuns the biter
-- (not bosses), and a Biter slow tower slows it (not bosses). Called by DinoAttacks through its onBite hook.
function Towers.bitten(enemy: Enemies.Enemy, position: Vector3, onTower: boolean?)
	local thorns, thornsOwner, stun = 0, nil, 0
	for _, source in towers do
		local s = source.stats
		if not source.knockedOut and (s.thornsDamage > 0 or s.stunBitersSeconds > 0) and covers(source, position) and ownSide(source, enemy) then
			if s.thornsDamage > thorns then
				thorns, thornsOwner = s.thornsDamage, source.owner
			end
			stun = math.max(stun, s.stunBitersSeconds)
		end
	end
	if stun > 0 then
		Enemies.stun(enemy, stun, false)
	end
	-- Biter slow (Bitter Tonic / Bitter Brew, PLAN 9d #294): a sedation slow, never on a boss.
	local slow, seconds = 0, 0
	if onTower then -- a bite on a tower in range (a hunter bitten there doesn't count)
		slow, seconds = TowerPerks.biterSlow(perkSources(position, BITER_FIELDS), enemy.side, enemy.def.boss == true)
	end
	if slow > 0 then
		Enemies.chill(enemy, { slowPercent = slow, seconds = seconds, affectsBosses = false, brittlePercent = 0, stripsArmor = false })
	end
	if thorns > 0 then
		credit(thornsOwner, Enemies.damage(enemy, thorns * levelScale, true))
	end
end

-- Amber Mirror (PLAN 9g): a throw this tower's Grounding caught hits its thrower for
-- Reflect damage, x the team's level like thorns (pierces armour; the owner gets the pop).
function Towers.reflect(tower: Tower, thrower: Enemies.Enemy)
	local amount = tower.stats.reflectDamage
	if amount > 0 and thrower.alive and ownSide(tower, thrower) then
		credit(tower.owner, Enemies.damage(thrower, amount * levelScale, true))
	end
end

export type HunterGear = { recoilMult: number, reloadMult: number, spreadMult: number, ratePercent: number }

-- What an Outfitter Armory covering this point does for a hunter's gun: the
-- strongest of each buff (auras don't stack). Own side's Armories only (`side`, default 1).
function Towers.hunterGearAt(position: Vector3, side: number?): HunterGear
	local gear = { recoilMult = 1, reloadMult = 1, spreadMult = 1, ratePercent = 0 }
	for _, source in towers do
		local s = source.stats
		if not source.knockedOut and covers(source, position) and BattleRules.canSupport(source.side, side or 1) then
			gear.recoilMult = math.min(gear.recoilMult, s.hunterRecoilMult)
			gear.reloadMult = math.min(gear.reloadMult, s.hunterReloadMult)
			gear.spreadMult = math.min(gear.spreadMult, s.hunterSpreadMult)
			gear.ratePercent = math.max(gear.ratePercent, s.hunterRatePercent)
		end
	end
	return gear
end

-- Standing towers dinos can hurt, for them to pick targets from (bites, throws,
-- landing splash). Never one that can't be damaged (DECISIONS #148).
function Towers.targets(): { Tower }
	local standing = {}
	for _, tower in towers do
		if Combat.canBeHit(tower.def, tower.knockedOut) then
			table.insert(standing, tower)
		end
	end
	return standing
end

-- How many model swaps the tower has reached (0, 1 or 2), from the tiers
-- flagged swapsModel in Config.
local function swapStage(tower: Tower): number
	local stage = 0
	for pathIndex, tier in tower.pathTiers do
		local reached = 0
		for t = 1, tier do
			if Upgrades.row(tower.def.paths[pathIndex], t, tower.pathPicks[pathIndex]).swapsModel then
				reached += 1
			end
		end
		stage = math.max(stage, reached)
	end
	return stage
end

------------------------------------------------------------------ Tar Pit pool


-- The range ring: a Tar Pit's range is its pool's length of track, drawn as the pool
-- itself, so it only gets a ring when it has an aura (Tar Totem).
local function ringRange(def, stats: Stats): number
	if def == Config.Towers.BLIMP or def == Config.Towers.METEOR then
		return 0 -- the blimp's circle is under it; a Meteor Beacon reaches its whole side -- its circle is under the flying blimp (TowerLook.poseBlimp), not at the mast
	end
	if def.onTrack and stats.auraSlowedPercent <= 0 then
		return 0
	end
	return stats.range
end

-- Draws a pit's pool along the track and publishes it on the body (the client's placing
-- ghost checks new pools against PoolAt / PoolLength, Shared/Placement.checkPool).
local function showPool(tower: Tower)
	if not tower.def.onTrack then
		return
	end
	local points = {}
	for _, d in TarPit.samples(tower.poolAt, tower.stats.range, POOL_STEP) do
		table.insert(points, Enemies.pointAt(d, tower.side))
	end
	TowerLook.setPool(tower.model, points)
	local body = tower.model.PrimaryPart
	if body then
		body:SetAttribute("PoolAt", tower.poolAt)
		body:SetAttribute("PoolSide", tower.side)
		body:SetAttribute("PoolLength", tower.stats.range)
	end
end

-- Every pit's pool at its current length on one side's track (default 1, co-op) (Shop checks
-- a new pit against them, #189).
function Towers.pools(side: number?): { TarPit.Pool }
	local list = {}
	for _, tower in towers do
		if tower.def.onTrack and tower.side == (side or 1) then
			table.insert(list, { at = tower.poolAt, length = tower.stats.range })
		end
	end
	return list
end

-- Where along a side's track (default 1) a pit placed at `position` would centre its pool.
function Towers.poolAtFor(position: Vector3, side: number?): number
	return Enemies.trackDistanceNear(Placement.ground(position), side)
end

------------------------------------------------------------------ public

export type Hooks = {
	-- (who gets the pop, or nil if they've left; the species key if the dino is gone,
	-- nil for a shrink)
	onPop: ((Player?, string?) -> ())?,
	extraRatePercent: ((Tower) -> number)?,
	resistOf: ((Tower) -> { number })?,
	-- A Tar Pit sank a dino: its Dig Site cash and Lucky Finds chest (Main pays; Towers never
	-- touches cash).
	onSink: ((cash: number, chestCash: number, position: Vector3, side: number) -> ())?,
	-- Prize Fossils (PLAN 9g): a fossil counts `extra` more take-downs of `gone` for this
	-- hunter's Bounties (Main reports them; meta only). Bounty Wall too (PLAN 9h).
	onBountyExtra: ((Player, string, number) -> ())?,
	-- Bone Totem (PLAN 9h): cash to a side (Bone cash, Bone Market, Camp Payday; Main pays it
	-- scaled like kill pay), a chest (Ancient Treasure) and how many hunters a side has.
	onCash: ((side: number, cash: number) -> ())?,
	onCrate: ((position: Vector3, cash: number, side: number) -> ())?,
	huntersOn: ((side: number) -> number)?,
	-- Spotter Blimp (PLAN 9h T125b): a med kit on the ground for a side (Airdrops' kit rules).
	onKit: ((position: Vector3, heal: number, side: number) -> ())?,
}

function Towers.init(folder: Instance, hooks: Hooks?)
	towerFolder = folder
	local walkerFolder = Instance.new("Folder")
	walkerFolder.Name = "Walkers"
	walkerFolder.Parent = folder
	Walkers.init(walkerFolder) -- raptors and other walkers (PLAN 9g, #315)
	onPop = hooks and hooks.onPop
	extraRatePercent = hooks and hooks.extraRatePercent
	resistOf = hooks and hooks.resistOf
	onSink = hooks and hooks.onSink
	onBountyExtra = hooks and hooks.onBountyExtra
	onCash = hooks and hooks.onCash
	onCrate = hooks and hooks.onCrate
	huntersOn = hooks and hooks.huntersOn
	onKit = hooks and hooks.onKit
end

-- Callers check Placement first (Shop does); this only builds. `side`: the builder's side
-- (default 1, co-op).
function Towers.place(key: string, position: Vector3, owner: Player?, side: number?): Tower?
	local def = Config.Towers[key]
	if not def then
		warn(`[Towers] Unknown tower '{key}'`)
		return nil
	end

	local base = Placement.ground(position)
	local stats = TowerStats.compute(def, { 0, 0, 0 })
	local model = TowerLook.build(key, ringRange(def, stats), base)
	-- The builder's tower flag, if they wear one (a look only; Shared/Cosmetics).
	local flag = if owner
		then Cosmetics.colour(Cosmetics.worn(function(name)
			return owner:GetAttribute(name)
		end, "towerFlag"))
		else nil
	if flag then
		TowerLook.addFlag(model, flag)
	end
	model.Parent = towerFolder

	nextId += 1
	local pathTiers = { 0, 0, 0 }
	local maxHp = Combat.towerMaxHp(def, pathTiers)
	local tower: Tower = {
		id = nextId,
		key = key,
		def = def,
		owner = owner,
		standInPierce = false,
		side = side or 1,
		base = base,
		position = base + Vector3.new(0, TowerLook.BODY_HEIGHT / 2, 0),
		muzzle = base + Vector3.new(0, TowerLook.BODY_HEIGHT - 0.5, 0),
		pathTiers = pathTiers,
		pathPicks = { "", "", "" },
		stats = stats,
		buff = NO_BUFF,
		cooldown = 0,
		freezeTimer = 0,
		hp = maxHp,
		maxHp = maxHp,
		knockedOut = false,
		lastStandUsed = false,
		boltTimer = 0,
		fieldTimer = 0,
		static = setmetatable({}, { __mode = "k" }) :: any,
		sorties = {},
		dived = setmetatable({}, { __mode = "k" }) :: any,
		towTimer = 0,
		poolAt = if def.onTrack then Enemies.trackDistanceNear(base, side) else 0,
		eruptTimer = 0,
		tracksUntil = 0,
		sealedUntil = 0,
		sealHealPercent = 0,
		resin = if def.resin
			then {
				dinos = setmetatable({}, { __mode = "k" }) :: any,
				entombed = setmetatable({}, { __mode = "k" }) :: any,
				allTimer = 0,
				fossils = 0,
				fossilsRound = 0,
				fuelPercent = 0,
				sealUsed = false,
				sealedAt = setmetatable({}, { __mode = "k" }) :: any,
				auto = AutoFire.new(),
				wall = nil,
			}
			else nil,
		raptor = if (def.walkers or 0) > 0
			then {
				auto = AutoFire.new(),
				swarmKey = { key = key .. " swarm", id = nextId },
				swarmUntil = 0,
				charge = nil,
				roarTimer = 0,
				takeDowns = 0,
				attacker = nil,
				lastStung = nil,
				posts = {},
				postTimer = 0,
			}
			else nil,
		totem = if key == "TOTEM"
			then {
				rules = Totem.new(), -- a new totem starts empty (the charge starts at 0 each match)
				pending = 0,
				echoAt = 0,
				buffUntil = 0,
				spiritUntil = 0,
				spiritTimer = 0,
				finished = setmetatable({}, { __mode = "k" }) :: any,
				shownShare = -1,
			}
			else nil,
		blimp = if key == "BLIMP"
			then {
				at = 0,
				dir = 1,
				focus = 0,
				model = TowerLook.buildBlimp(TowerLook.COLORS.BLIMP),
				auto = AutoFire.new(),
				hookTimer = 0,
				roundClock = 0,
				paraDropped = false,
				airliftUsed = false,
				paraKey = { key = key .. " paratroopers", id = nextId },
			}
			else nil,
		meteor = if key == "METEOR"
			then { timer = 0, rainTimer = 0, landings = {}, craters = {}, auto = AutoFire.new(), extinctionAuto = { fired = false } }
			else nil,
		rangeBase = stats.range,
		hurtBy = nil,
		model = model,
	}
	table.insert(towers, tower)
	if tower.blimp then
		tower.blimp.model.Parent = model -- goes when the mast goes
		tower.position = Enemies.pointAt(0, tower.side) + Vector3.new(0, TowerLook.BODY_HEIGHT / 2, 0)
	end
	showPool(tower)
	showHealth(tower)
	refreshAuras()
	syncWalkers(tower)
	return tower
end

-- Returns true if the upgrade was applied. Does NOT charge cash — the caller
-- (Shop) must Economy.trySpend first. Keeps this module free of money. `option` is the
-- A/B/C pick a tier-4 or tier-5 step needs (none at other tiers; Shared/Upgrades.stepFor);
-- a pick is final until the tower is sold (#277).
function Towers.upgrade(tower: Tower, pathIndex: number, option: string?): boolean
	if not Towers.canUpgrade(tower, pathIndex) then
		return false
	end
	local _, why = Upgrades.stepFor(tower.def, tower.pathTiers, tower.pathPicks, pathIndex, option)
	if why ~= "ok" then
		return false
	end
	local nextTier = tower.pathTiers[pathIndex] + 1
	tower.pathPicks[pathIndex] = Upgrades.pickAfter(tower.pathPicks[pathIndex], nextTier, option)
	tower.pathTiers[pathIndex] = nextTier
	tower.stats = TowerStats.compute(tower.def, tower.pathTiers, tower.pathPicks)
	tower.rangeBase = tower.stats.range
	-- The HP an upgrade adds to the max is added to current HP too.
	local maxHp = Combat.towerMaxHp(tower.def, tower.pathTiers, tower.buff.hpPercent)
	tower.hp = math.min(maxHp, tower.hp + (maxHp - tower.maxHp))
	tower.maxHp = maxHp
	TowerLook.refresh(tower.model, ringRange(tower.def, tower.stats), tower.pathTiers, swapStage(tower), OptionPick.tierLabel(tower.pathTiers, tower.pathPicks))
	showPool(tower) -- Wide Pool / Tar Lake lengthen it
	TowerLook.setLantern(tower.model, tower.stats.rescueRespawnMult > 0) -- Rescue Beacon
	showHealth(tower)
	refreshAuras()
	syncWalkers(tower) -- Raptor Pen: more raptors, stronger raptors
	return true
end

-- Studio "standinpick" (PLAN T115b, #310; Battle asks StudioOnly first): a stand-in camp's
-- tower is rebuilt to one path's tier 3 plus `letters` (its T4 / T5 options), every other
-- path back to 0. Goes through Towers.upgrade, so every rule still holds.
function Towers.setPicksForStandIn(tower: Tower, pathIndex: number, letters: string): boolean
	tower.pathTiers = { 0, 0, 0 }
	tower.pathPicks = { "", "", "" }
	tower.stats = TowerStats.compute(tower.def, tower.pathTiers, tower.pathPicks)
	tower.rangeBase = tower.stats.range
	local done = true
	for _ = 1, 3 do
		done = done and Towers.upgrade(tower, pathIndex)
	end
	for i = 1, #letters do
		done = done and Towers.upgrade(tower, pathIndex, string.sub(letters, i, i))
	end
	-- Publish the build as Shop does on a purchase (F10): the panel, the tier label and
	-- Inspect read the body's Path<n> / Picks<n>.
	local body = tower.model.PrimaryPart
	if body then
		for i, tier in tower.pathTiers do
			body:SetAttribute(`Path{i}`, tier)
			body:SetAttribute(`Picks{i}`, tower.pathPicks[i])
		end
	end
	return done
end

------------------------------------------------------------------ targeting

local function piercing(tower: Tower): boolean
	return tower.stats.piercesArmor or tower.buff.piercesArmor or tower.standInPierce
end

-- A Studio stand-in camp's fixed tower pierces armour (PLAN T91b): test fidelity only, so a
-- stand-in camp isn't buried by armoured leaks. Shop.placeStandIn asks Shared/StudioOnly first.
function Towers.pierceArmourForStandIn(tower: Tower)
	tower.standInPierce = true
end

-- Can this tower both reach and hurt this enemy?
local function canTarget(tower: Tower, enemy: Enemies.Enemy): boolean
	if not ownSide(tower, enemy) then
		return false
	end
	if enemy.def.flying and not tower.stats.hitsAir then -- the Towers row, or a Hits air tier (PLAN 9g)
		return false
	end
	return Enemies.canHurt(enemy, piercing(tower))
end

-- "First" targeting: the enemy furthest along the track that is in range.
-- Enemies the tower can't hurt (armour without pierce) are ignored.
local function pickFirst(tower: Tower, live): Enemies.Enemy?
	local best, bestDistance = nil, -1
	local range = tower.stats.range
	for _, enemy in live do
		if enemy.distance > bestDistance and canTarget(tower, enemy) and (enemy.part.Position - tower.position).Magnitude <= range then
			best, bestDistance = enemy, enemy.distance
		end
	end
	return best
end

local function splashTargets(tower: Tower, primary: Enemies.Enemy, live): { Enemies.Enemy }
	local hits = { primary }
	local count, radius = tower.stats.targets, tower.stats.splashRadius
	if count <= 1 or radius <= 0 then
		return hits
	end
	local centre = primary.part.Position
	for _, enemy in live do
		if #hits >= count then
			break
		end
		if enemy ~= primary and canTarget(tower, enemy) and (enemy.part.Position - centre).Magnitude <= radius then
			table.insert(hits, enemy)
		end
	end
	return hits
end

-- The target plus the enemies right behind it on the track, nearest first.
local function lineTargets(tower: Tower, primary: Enemies.Enemy, live): { Enemies.Enemy }
	local reach = Config.Tuning.LinePierceReach or 0
	local behind = {}
	for _, enemy in live do
		if enemy ~= primary and canTarget(tower, enemy) and enemy.side == primary.side then
			local gap = primary.distance - enemy.distance
			if gap >= 0 and gap <= reach then
				table.insert(behind, enemy)
			end
		end
	end
	table.sort(behind, function(a, b)
		return a.distance > b.distance
	end)
	local hits = { primary }
	for i = 1, math.min(#behind, tower.stats.lineHits - 1) do
		table.insert(hits, behind[i])
	end
	return hits
end

------------------------------------------------------------------ hitting

-- `breaks` is the tier's Size breaks for a direct hit (line pierce gives every dino
-- in the line the shot's); splash and bomblets pass nothing (1, DECISIONS #127).
------------------------------------------------------------------ Amber Resin Cannon (PLAN 9g T123)

-- Visuals only.
local AMBER_COLOR = Color3.fromRGB(255, 160, 40)
local STONE_COLOR = Color3.fromRGB(150, 145, 135)
local STICKY_REFRESH = 0.25 -- s a Sticky Bed slow lasts after the last frame near the tomb

-- Take-down mark % (4x common rule 4): a take-down at `at` by this tower marks the dinos near it.
local function takeDownMark(tower: Tower, at: Vector3)
	local percent = tower.stats.takeDownMarkPercent
	if percent <= 0 then
		return
	end
	local list, points = {}, {}
	for _, other in Enemies.getLive() do
		if other.alive and ownSide(tower, other) then
			table.insert(list, other)
			table.insert(points, other.part.Position)
		end
	end
	for _, i in FourX.markNear(at, points) do
		Enemies.mark(list[i], percent, FourX.takeDownMarkSeconds())
	end
end

local entomb: (Tower, Enemies.Enemy, number, boolean) -> ()

-- A fossil: taken down whole (every size pays and is a pop for the owner), plus Sink cash
-- and Dig Crew's chest; then Bone Dust's mark, Fossil Fuel and Amber Heart.
local function fossilize(tower: Tower, enemy: Enemies.Enemy)
	local state = tower.resin :: ResinState
	local stats = tower.stats
	local at = enemy.part.Position
	local size = enemy.part.Size
	local killed, gone, dropped = Enemies.dropSizes(enemy, enemy.size)
	if not killed then
		return
	end
	credit(tower.owner, killed, gone, dropped)
	-- Turns to stone and crumbles (a look only).
	local stone = Effects.part(size * 1.1, CFrame.new(at), STONE_COLOR, 0.6)
	stone.Material = Enum.Material.Slate
	for i = 1, 4 do
		Effects.part(Vector3.one * 0.6, CFrame.new(at + Vector3.new(math.cos(i * 1.6) * 1.2, -0.5, math.sin(i * 1.6) * 1.2)), STONE_COLOR, 0.9)
	end
	if onSink and (stats.sinkCash > 0 or stats.sinkChestCash > 0) then
		onSink(stats.sinkCash, stats.sinkChestCash, at, tower.side)
	end
	if gone and stats.bountyFossilsX > 1 and onBountyExtra and tower.owner and tower.owner.Parent then
		onBountyExtra(tower.owner, gone, math.floor(stats.bountyFossilsX) - 1)
	end
	takeDownMark(tower, at)
	state.fossils += 1
	state.fossilsRound += 1
	if stats.fossilRatePercent > 0 then
		local fuel = Resin.fuel(state.fossilsRound, stats.fossilRatePercent)
		if fuel ~= state.fuelPercent then
			state.fuelPercent = fuel
			refreshAuras()
		end
	end
	if Resin.heart(state.fossils, stats.heartEvery) then
		-- Amber Heart: every dino on the side entombed 1 s (bosses x Boss hard stop x).
		for _, other in Enemies.getLive() do
			if other.alive and ownSide(tower, other) then
				entomb(tower, other, FourX.hardStop(1, other.def.boss == true), false)
			end
		end
	end
end

-- Entombs `enemy` for `seconds` (already halved for a boss): a hard stop that glows amber;
-- Hardened Amber's amp, a fossil if it is low enough, else Time Capsule's send back; and
-- Spreading Amber takes the nearest dinos too (`spread`: not for the ones it spreads to).
entomb = function(tower: Tower, enemy: Enemies.Enemy, seconds: number, spread: boolean)
	local state = tower.resin
	if not state or not enemy.alive or seconds <= 0 then
		return
	end
	local stats = tower.stats
	local boss = enemy.def.boss == true
	Enemies.stun(enemy, seconds, true)
	state.entombed[enemy] = os.clock() + seconds
	local glow = Effects.part(enemy.part.Size * 1.25, enemy.part.CFrame, AMBER_COLOR, seconds)
	glow.Transparency = 0.45
	glow.Material = Enum.Material.Glass
	if stats.entombAmpPercent > 0 then
		Enemies.mark(enemy, stats.entombAmpPercent, seconds)
	end
	local share = Resin.hpShare(enemy.hp, enemy.share, enemy.sizes)
	if Resin.isFossil(stats.fossilBelowPercent, share, boss, enemy.def.flying == true) then
		fossilize(tower, enemy)
		return
	end
	local back = Resin.sendBack(stats.sendBack, boss) -- Time Capsule (0 for a boss)
	Enemies.knockback(enemy, back)
	if spread and stats.entombSpread > 0 then
		local list, distances = {}, {}
		for _, other in Enemies.getLive() do
			if other ~= enemy and other.alive and ownSide(tower, other) and not other.def.flying then
				table.insert(list, other)
				table.insert(distances, (other.part.Position - enemy.part.Position).Magnitude)
			end
		end
		for _, i in Resin.spreadTo(distances, stats.entombSpread) do
			local other = list[i]
			local dino = state.dinos[other] or { resin = 0, bossNextAt = 0 }
			state.dinos[other] = dino
			if not (other.def.boss and os.clock() < dino.bossNextAt) then
				entomb(tower, other, Resin.entombFor(stats, other.def.boss == true, os.clock(), dino), false)
			end
		end
	end
end

-- A resin glob lands: the hit slow (not bosses) and 1 resin; entombed at the threshold.
local function resinHit(tower: Tower, enemy: Enemies.Enemy)
	local state = tower.resin
	if not state or not enemy.alive then
		return
	end
	local tuning = Config.Tuning
	Enemies.chill(enemy, { slowPercent = tuning.ResinHitSlow, seconds = tuning.ResinHitSlowS, affectsBosses = false, brittlePercent = 0, stripsArmor = false })
	local dino = state.dinos[enemy] or { resin = 0, bossNextAt = 0 }
	state.dinos[enemy] = dino
	local share = Resin.hpShare(enemy.hp, enemy.share, enemy.sizes)
	local seconds = Resin.hit(dino, tower.stats, share, enemy.def.boss == true, enemy.def.flying == true, os.clock())
	if seconds > 0 then
		entomb(tower, enemy, seconds, true)
	end
end

-- One hit of the tower's: armour, boss x, its stun and knockback, breaks, the pop. Returns
-- the species key if the dino is gone. `walker`: a Raptor Pen bite (PLAN 9g): its Stun (s) is
-- Rex Tamer's roar, never a bite's.
local function hit(tower: Tower, enemy: Enemies.Enemy, damage: number, breaks: number?, walker: boolean?): string?
	local stats = tower.stats
	local pierce = piercing(tower)
	if not ownSide(tower, enemy) or not Enemies.canHurt(enemy, pierce) then
		return nil
	end
	if enemy.def.armored then
		damage *= stats.armoredMult
	end
	if enemy.def.boss then
		damage *= stats.bossMult
	end
	if tower.buff.slowedPercent > 0 and Enemies.isSlowed(enemy) then
		damage *= 1 + tower.buff.slowedPercent / 100 -- Tar Totem
	end
	if not walker then
		Enemies.stun(enemy, stats.stunSeconds, stats.stunsBosses)
	end
	Enemies.knockback(enemy, stats.knockback)
	local b = if breaks and breaks > 1 then Enemies.breaksFor(enemy, breaks, towerLevel, false) else 1
	local at = enemy.part.Position
	local killed, gone, dropped = Enemies.damage(enemy, damage, pierce, b)
	credit(tower.owner, killed, gone, dropped)
	if gone then
		takeDownMark(tower, at) -- 4x common rule 4 (Take-down mark %)
	end
	if stats.stripsOnHit then
		Enemies.strip(enemy, Config.Tuning.StripS or 0) -- PLAN 9c: bare for every tower a while
	end
	if tower.resin and enemy.alive then
		resinHit(tower, enemy) -- Amber Resin Cannon: slow + resin + entomb (PLAN 9g)
	end
	return gone
end

-- Bomblets land along the track (side `trackSide`'s) around `distance`, alternating behind
-- and ahead of it. Each generation throws the same number again around every bomblet of the
-- one before, weaker. Generation by generation, so the fires (Fire Bomblets) go to the
-- first generation first, at most Tuning Bomblet fires per shell (#306, Combat.bombletFires).
local function bomblets(tower: Tower, trackSide: number, distance: number, damage: number, live)
	local stats = tower.stats
	if stats.bombletGenerations <= 0 or stats.bomblets <= 0 then
		return
	end
	local spread = Config.Tuning.BombletSpread or 0
	local share = Config.Tuning.BombletDamage or 0
	local fires = Combat.bombletFires(stats.bomblets, stats.bombletGenerations, Config.Tuning.BombletFiresPerShell or 0)
	local centres = { distance }
	local blastDamage = damage
	for generation = 1, stats.bombletGenerations do
		blastDamage *= share
		local nextCentres = {}
		for _, parent in centres do
			for i = 1, stats.bomblets do
				local side = if i % 2 == 1 then -1 else 1
				local centre = parent + side * spread * math.ceil(i / 2)
				table.insert(nextCentres, centre)
				for _, enemy in live do
					if enemy.side == trackSide and canTarget(tower, enemy) and math.abs(enemy.distance - centre) <= spread / 2 then
						hit(tower, enemy, blastDamage)
					end
				end
				-- Fire Bomblets (PLAN 9c): a bomblet leaves a small fire as wide as its blast.
				if stats.bombletBurnDps > 0 and fires[generation] > 0 then
					fires[generation] -= 1
					Hazards.burn(centre, spread / 2, stats.bombletBurnDps * levelScale, stats.bombletBurnSeconds, piercing(tower), tower.owner, trackSide)
				end
				Effects.part(Vector3.one * 2, CFrame.new(Enemies.pointAt(centre, trackSide) + Vector3.new(0, 1, 0)), BOMBLET_COLOR, 0.15, Enum.PartType.Ball)
			end
		end
		centres = nextCentres
	end
end

local function addBurn(tower: Tower, primary: Enemies.Enemy)
	local stats = tower.stats
	if primary.def.flying then
		return
	end
	Hazards.burn(primary.distance, stats.splashRadius, stats.burnDps * levelScale, stats.burnSeconds, piercing(tower), tower.owner, primary.side)
end

-- Lightning Rodeo (a Storm Coil's aura): the shot arcs once from its target to the
-- nearest other dino within Coil arc reach that it didn't already hit, at the aura's %.
-- Breaks 1, like every arc.
local function rodeoArc(tower: Tower, target: Enemies.Enemy, hits: { Enemies.Enemy }, damage: number, live)
	local percent = tower.buff.arcPercent
	if percent <= 0 then
		return
	end
	local list, points, skip, first = {}, {}, {}, nil
	for _, enemy in live do
		if enemy.alive and canTarget(tower, enemy) then
			table.insert(list, enemy)
			table.insert(points, enemy.part.Position)
			if enemy == target then
				first = #list
			elseif table.find(hits, enemy) then
				skip[#list] = true
			end
		end
	end
	if not first then
		return
	end
	local links = StormCoil.chain(points, first, 1, Config.Tuning.CoilArcReach, 1, percent / 100, skip)
	for i = 2, #links do
		local enemy = list[links[i].index]
		Effects.tracer(target.part.Position, enemy.part.Position, ARC_COLOR)
		hit(tower, enemy, damage * links[i].x, 1)
	end
end

local function fire(tower: Tower, live): boolean
	local stats = tower.stats
	local damage = stats.damage * (1 + tower.buff.damagePercent / 100) * levelScale
	local fired = false

	for _ = 1, stats.shots do
		local target = pickFirst(tower, live)
		if not target then
			break
		end
		fired = true
		local targetPosition = target.part.Position
		local targetDistance = target.distance

		if stats.markPercent > 0 then
			Enemies.mark(target, stats.markPercent, Config.Tuning.MarkDuration or 0)
		end
		addBurn(tower, target)

		local line = stats.lineHits > 1
		local hits = if line then lineTargets(tower, target, live) else splashTargets(tower, target, live)
		-- Pierce-through: a line or a single target gets the tier's breaks; a splash breaks 1.
		local splash = not line and stats.targets > 1 and stats.splashRadius > 0
		local breaks = if splash then 1 else stats.sizeBreaks
		for _, enemy in hits do
			hit(tower, enemy, damage, breaks)
		end
		rodeoArc(tower, target, hits, damage, live)
		bomblets(tower, target.side, targetDistance, damage, live)

		Effects.tracer(tower.muzzle, targetPosition, TowerLook.COLORS[tower.key] or Color3.new(1, 1, 1))
	end
	return fired
end

------------------------------------------------------------------ Raptor Pen (PLAN 9g T124)

-- Its bite: the pen's composed damage (its auras, the team's level, Hungry Alpha's stack).
local function raptorDamage(tower: Tower): number
	local state = tower.raptor :: RaptorState
	local stack = Raptor.stack(state.takeDowns, tower.stats.takeDownStackPercent)
	return tower.stats.damage * (1 + tower.buff.damagePercent / 100) * levelScale * (1 + stack / 100)
end

-- A raptor's bite or pounce lands (x `x`: First dive x, Swarm share, Avenger x): the generic
-- hit rules (armour, boss x, breaks, Mark %, Slow % / linger) and the pounce's hold.
local function raptorBite(tower: Tower, enemy: Enemies.Enemy, x: number, hold: number)
	local state = tower.raptor
	if not state or not enemy.alive or not canTarget(tower, enemy) then
		return
	end
	local stats = tower.stats
	local _, avenge = Raptor.avenger(stats.avengerX, state.lastStung, os.clock(), state.attacker)
	if enemy ~= state.attacker then
		avenge = 1
	end
	if stats.markPercent > 0 then
		Enemies.mark(enemy, stats.markPercent, Config.Tuning.MarkDuration or 0)
	end
	if stats.slowPercent > 0 then
		Enemies.chill(enemy, { slowPercent = stats.slowPercent, seconds = math.max(stats.slowLinger, 0.5), affectsBosses = stats.slowsBosses, brittlePercent = 0, stripsArmor = false })
	end
	if hold > 0 then
		Enemies.stun(enemy, hold, true) -- the pounce's hold (Shared/Walker: a boss only with Boss hold, once)
	end
	local gone = hit(tower, enemy, raptorDamage(tower) * x * avenge, stats.sizeBreaks, true)
	if gone and stats.takeDownStackPercent > 0 then
		state.takeDowns += 1 -- Hungry Alpha
	end
end

local function campColour(tower: Tower): Color3
	return BrickColor.new(BattleFlow.campColor(tower.side) :: any).Color
end

-- Guard Raptors: re-post each raptor beside a tower in range, the most damaged first.
local function guardPosts(tower: Tower, count: number)
	local state = tower.raptor :: RaptorState
	local list, shares = {}, {}
	for _, other in towers do
		if other ~= tower and not other.def.untouchable and BattleRules.canSupport(tower.side, other.side) and covers(tower, other.base) then
			table.insert(list, other)
			table.insert(shares, if other.maxHp > 0 then other.hp / other.maxHp else 1)
		end
	end
	local posts = {}
	for i, index in Raptor.guardPosts(count, shares) do
		posts[i] = list[index]
	end
	state.posts = posts
end

local function raptorKind(stats: Stats, swarm: boolean?): string
	return if swarm then "swarm" elseif stats.stunRoarEvery > 0 then "rex" elseif stats.alpha then "alpha" else "raptor"
end

local function tiersBought(tower: Tower): number
	return tower.pathTiers[1] + tower.pathTiers[2] + tower.pathTiers[3]
end

syncWalkers = function(tower: Tower)
	local state = tower.raptor
	if not state then
		return
	end
	local stats = tower.stats
	local colour = campColour(tower)
	local homeAt = Enemies.trackDistanceNear(tower.base, tower.side)
	local params = Raptor.params(stats, tiersBought(tower))
	params.rate = stats.rate * (1 + tower.buff.ratePercent / 100)
	if stats.guard then
		guardPosts(tower, stats.walkers)
	else
		state.posts = {}
	end
	Walkers.sync(tower, {
		count = stats.walkers,
		params = params,
		side = tower.side,
		base = tower.base,
		homeAt = homeAt,
		sending = not tower.knockedOut,
		healsBetweenRounds = stats.healsBetweenRounds,
		look = function()
			return RaptorLook.build(raptorKind(tower.stats), colour)
		end,
		onHit = function(enemy, landed)
			raptorBite(tower, enemy, landed.x, landed.hold)
		end,
		homeFor = if stats.guard
			then function(i)
				local post = state.posts[i]
				if post and table.find(towers, post) then
					return post.base, Enemies.trackDistanceNear(post.base, tower.side)
				end
				return tower.base, homeAt
			end
			else nil,
		candidates = if stats.guard or stats.avengerX > 0
			then function(i, dinos)
				if tower.stats.guard then
					-- Guard: only a dino that hurt its post, within Guard reach of it.
					local post = state.posts[i]
					local out = {}
					if post and post.hurtBy then
						for _, dino in dinos do
							if dino.id == post.hurtBy and Raptor.guardAnswers(dino.fromHome) then
								table.insert(out, dino)
							end
						end
					end
					return out
				end
				local target = Raptor.avenger(tower.stats.avengerX, state.lastStung, os.clock(), state.attacker)
				if target then
					for _, dino in dinos do
						if dino.id == target then
							return { dino }
						end
					end
				end
				return dinos
			end
			else nil,
	})
end

-- Raptor Swarm: Swarm raptors small raptors (Swarm share HP and bite) hunt anywhere on the
-- side's track for Swarm (s), then vanish; never past the side's walker cap.
local function releaseSwarm(tower: Tower)
	local state = tower.raptor
	if not state or not tower.stats.swarm then
		return
	end
	local stats = tower.stats
	local onSide = 0
	for _, other in towers do
		if other.side == tower.side then
			onSide += #Walkers.unitsOf(other)
		end
	end
	local params = Raptor.params(stats, tiersBought(tower), true)
	params.respawn = math.huge -- a swarm raptor bitten down is gone
	params.rate = stats.rate * (1 + tower.buff.ratePercent / 100)
	local colour = campColour(tower)
	Walkers.sync(state.swarmKey, {
		count = Raptor.swarmCount(onSide),
		params = params,
		side = tower.side,
		base = tower.base,
		homeAt = Enemies.trackDistanceNear(tower.base, tower.side),
		sending = true,
		healsBetweenRounds = false,
		look = function()
			return RaptorLook.build("swarm", colour)
		end,
		onHit = function(enemy, landed)
			raptorBite(tower, enemy, landed.x * Raptor.swarmBite(), landed.hold)
		end,
	})
	state.swarmUntil = os.clock() + Config.Tuning.SwarmS
end

-- Raptor Charge: every standing raptor sweeps the side's track from the exit end back.
local function startCharge(tower: Tower)
	local state = tower.raptor
	if state and tower.stats.charge then
		state.charge = { elapsed = 0, bitten = {} }
	end
end

local function stepRaptor(tower: Tower, dt: number, own)
	local state = tower.raptor
	if not state then
		return
	end
	local stats, now = tower.stats, os.clock()
	-- The Swarm runs out.
	if state.swarmUntil > 0 and now >= state.swarmUntil then
		state.swarmUntil = 0
		Walkers.clear(state.swarmKey)
	end
	if tower.knockedOut then
		return
	end
	-- Guard Raptors: re-post about once a second (the most damaged tower first).
	if stats.guard then
		state.postTimer += dt
		if state.postTimer >= 1 then
			state.postTimer = 0
			guardPosts(tower, stats.walkers)
		end
	end
	-- Raptor Swarm / Raptor Charge: once a round, fired by Shared/AutoFire.
	if stats.swarm or stats.charge then
		local inArea, boss = 0, false
		for _, enemy in own do
			if enemy.alive and (enemy.part.Position - tower.position).Magnitude <= stats.range then
				inArea += 1
				boss = boss or enemy.def.boss == true
			end
		end
		if AutoFire.check(state.auto, boss, inArea, Enemies.allSpawned(tower.side), #own) then
			if stats.swarm then
				releaseSwarm(tower)
			else
				startCharge(tower)
			end
		end
	end
	local charge = state.charge
	if charge then
		charge.elapsed += dt
		local speed = Config.Tuning.RaptorSpeed * stats.walkerSpeedMult
		local at = Raptor.chargeAt(Enemies.trackLength(tower.side), speed, charge.elapsed)
		if not at then
			state.charge = nil
			Walkers.charge(tower, nil)
		else
			Walkers.charge(tower, at)
			for _, enemy in own do
				if enemy.alive and not charge.bitten[enemy] and math.abs(enemy.distance - at) <= Config.Tuning.RaptorReach then
					charge.bitten[enemy] = true
					local knock = Raptor.chargeKnock(enemy.size, enemy.def.boss == true) -- small dinos only, never a boss
					raptorBite(tower, enemy, 1, 0)
					if enemy.alive then
						Enemies.knockback(enemy, knock)
					end
				end
			end
		end
	end
	-- Rex Tamer: the roar stuns small dinos near the alpha.
	if stats.stunRoarEvery > 0 then
		state.roarTimer += dt
		if state.roarTimer >= stats.stunRoarEvery then
			local at = Walkers.firstAt(tower)
			if at then
				state.roarTimer = 0
				local list, distances, sizes, bosses = {}, {}, {}, {}
				for _, enemy in own do
					if enemy.alive then
						table.insert(list, enemy)
						table.insert(distances, (enemy.part.Position - at).Magnitude)
						table.insert(sizes, enemy.size)
						table.insert(bosses, enemy.def.boss == true)
					end
				end
				for _, i in Raptor.roared(distances, sizes, bosses) do
					Enemies.stun(list[i], stats.stunSeconds, false)
				end
				Effects.disc(at, Config.Tuning.RoarReachStuds, campColour(tower), 0.4, 0.7)
			end
		end
	end
end

-- Pack Bond (#319): the strongest own-side pen covering `position` with 3+ raptors out, or a
-- War Paint Bone Totem for Full buff (s) after a full charge (PLAN 9h): its hunters' extra damage %
-- against dinos only (Hero asks for its shots on dinos).
function Towers.hunterDamageAt(position: Vector3, side: number?): number
	local best = 0
	for _, source in towers do
		local percent = source.stats.hunterDamagePercent
		if percent > 0 and not source.knockedOut and covers(source, position) and BattleRules.canSupport(source.side, side or 1) then
			if source.totem then
				best = math.max(best, if os.clock() < source.totem.buffUntil then percent else 0)
			else
				best = math.max(best, Raptor.packBond(percent, Walkers.outCount(source), true))
			end
		end
	end
	return best
end

-- Elder Wisdom (PLAN 9h, #319): the lowest ability cooldown x of an own-side Bone Totem covering
-- `position` (1 = none). Ability tempo for hunters, never damage.
function Towers.hunterCooldownAt(position: Vector3, side: number?): number
	local best = 1
	for _, source in towers do
		local mult = source.stats.hunterCooldownMult
		if mult < 1 and not source.knockedOut and covers(source, position) and BattleRules.canSupport(source.side, side or 1) then
			best = math.min(best, mult)
		end
	end
	return best
end

------------------------------------------------------------------ Bone Totem (PLAN 9h T126)

-- Visuals only.
local BONE_COLOR = Color3.fromRGB(235, 225, 200)
local GHOST_COLOR = Color3.fromRGB(150, 230, 255)
local AURA_REFRESH = 0.25 -- s: a totem's charge aura is refreshed at most this often

-- One hit of a totem's (roar, skull, ghost hunter): its armour / boss rules, breaks, Shatter's
-- strip first and Fear's knockback after. Its pops never charge a totem (Enemies source "totem").
local function totemHit(tower: Tower, enemy: Enemies.Enemy, damage: number, breaks: number, strip: boolean)
	local stats = tower.stats
	if not enemy.alive or not ownSide(tower, enemy) or (enemy.def.flying and not stats.hitsAir) then
		return
	end
	if strip then
		Enemies.strip(enemy, Config.Tuning.ShatterStripS) -- Shatter Roar: bare for every tower a while
	end
	local pierce = piercing(tower)
	if not Enemies.canHurt(enemy, pierce) then
		return
	end
	if enemy.def.armored then
		damage *= stats.armoredMult
	end
	if enemy.def.boss then
		damage *= stats.bossMult
	end
	local b = if breaks > 1 then Enemies.breaksFor(enemy, breaks, towerLevel, false) else 1
	Enemies.setSource("totem")
	local killed, gone, dropped = Enemies.damage(enemy, damage, pierce, b)
	Enemies.setSource(nil)
	credit(tower.owner, killed, gone, dropped)
	local fear = if enemy.alive then Totem.knock(stats, enemy.size, enemy.def.boss == true) else 0 -- Fear: small dinos only
	if fear > 0 then
		Enemies.knockback(enemy, fear)
	end
end

-- The Spirit Roar: every dino in range (Ancient Roar: on its side); Skull Storm: skulls instead.
local function spiritRoar(tower: Tower, own)
	local stats = tower.stats
	local damage = stats.damage * (1 + tower.buff.damagePercent / 100) * levelScale
	local list = {}
	for _, enemy in own do
		if enemy.alive and (stats.roarWholeTrack or stats.skulls > 0 or covers(tower, enemy.part.Position)) then
			table.insert(list, enemy)
		end
	end
	if stats.skulls > 0 then
		local distances = {}
		for i, enemy in list do
			distances[i] = enemy.distance
		end
		for _, i in Totem.skullTargets(distances, stats.skulls) do
			local enemy = list[i]
			Effects.tracer(tower.muzzle, enemy.part.Position, BONE_COLOR)
			Effects.part(Vector3.one * 1.2, CFrame.new(enemy.part.Position + Vector3.new(0, 1.5, 0)), BONE_COLOR, 0.3, Enum.PartType.Ball)
			totemHit(tower, enemy, damage * Config.Tuning.SkullX, 1, stats.stripsArmor)
		end
		return
	end
	Effects.disc(tower.base + Vector3.new(0, 0.2, 0), stats.range, BONE_COLOR, 0.5, 0.55) -- the shockwave
	local breaks = Totem.roarBreaks(stats)
	for _, enemy in list do
		totemHit(tower, enemy, damage, breaks, stats.stripsArmor)
	end
end

-- A full charge: the path's effect (roar or pay), then Spirit Guard, War Paint, Spirit Hunters
-- and Ancient Treasure.
local function totemFull(tower: Tower, own)
	local state = tower.totem :: TotemState
	local stats, now = tower.stats, os.clock()
	if Totem.roars(stats) then
		spiritRoar(tower, own)
		if stats.roarEchoes > 0 then
			state.echoAt = now + Totem.ECHO_DELAY
		end
	elseif onCash then
		onCash(tower.side, Totem.fullPay(stats, if huntersOn then huntersOn(tower.side) else 1)) -- Bone Market, Camp Payday
		Effects.disc(tower.base + Vector3.new(0, 0.2, 0), 3, Color3.fromRGB(250, 205, 80), 0.6, 0.4)
	end
	local treasure = Totem.treasure(state.rules, stats)
	if treasure > 0 and onCrate then
		onCrate(tower.base + Vector3.new(3, 0, 0), treasure, tower.side) -- Ancient Treasure
	end
	if stats.fullGuardSeconds > 0 then -- Spirit Guard: towers in range take no damage a while
		for _, other in towers do
			if not other.def.untouchable and covers(tower, other.base) and BattleRules.canSupport(tower.side, other.side) then
				other.sealedUntil = math.max(other.sealedUntil, now + stats.fullGuardSeconds)
				local shell = Effects.part(Vector3.new(4, TowerLook.BODY_HEIGHT + 1, 4), CFrame.new(other.position), GHOST_COLOR, stats.fullGuardSeconds)
				shell.Transparency = 0.7
				shell.Material = Enum.Material.ForceField
			end
		end
	end
	if stats.hunterDamagePercent > 0 then
		state.buffUntil = now + Config.Tuning.FullBuffS -- War Paint
	end
	if stats.spiritHunters then
		state.spiritUntil = now + Config.Tuning.SpiritS
		state.spiritTimer = 0
	end
end

-- Spirit Hunters: each ghost fires at a dino in range, the furthest along first.
local function ghostVolley(tower: Tower, own)
	local list = {}
	for _, enemy in own do
		if enemy.alive and covers(tower, enemy.part.Position) and (tower.stats.hitsAir or not enemy.def.flying) then
			table.insert(list, enemy)
		end
	end
	if #list == 0 then
		return
	end
	table.sort(list, function(a, b)
		return a.distance > b.distance
	end)
	local count = Config.Tuning.SpiritHunters
	for i = 1, count do
		local enemy = list[(i - 1) % #list + 1]
		local angle = i * 2 * math.pi / count
		local ghost = tower.base + Vector3.new(math.cos(angle) * 2.5, 2.5, math.sin(angle) * 2.5)
		local body = Effects.part(Vector3.new(1, 2.4, 1), CFrame.new(ghost), GHOST_COLOR, 0.35)
		body.Transparency = 0.5
		Effects.tracer(ghost, enemy.part.Position, GHOST_COLOR)
		totemHit(tower, enemy, Config.Tuning.SpiritHunterDamage * levelScale, 1, false)
	end
end

local function stepTotem(tower: Tower, dt: number, own)
	local state = tower.totem
	if not state then
		return
	end
	local stats, now = tower.stats, os.clock()
	local share = Totem.share(state.rules, stats)
	if math.abs(share - state.shownShare) > 0.01 then
		state.shownShare = share
		TowerLook.setCharge(tower.model, share) -- the charge glow ring
	end
	if tower.knockedOut then
		return -- Trampled: no effects (its charge waits)
	end
	while state.pending > 0 do
		state.pending -= 1
		totemFull(tower, own)
	end
	if state.echoAt > 0 and now >= state.echoAt then
		state.echoAt = 0
		spiritRoar(tower, own) -- Echo Roar
	end
	if now < state.spiritUntil then
		state.spiritTimer -= dt
		if state.spiritTimer <= 0 then
			state.spiritTimer += 1 / Config.Tuning.SpiritHunterRate
			ghostVolley(tower, own)
		end
	end
	if stats.finishingRoar then -- a free roar at a weak boss in range, once per boss
		for _, enemy in own do
			if enemy.alive and enemy.def.boss and covers(tower, enemy.part.Position)
				and Totem.finishes(enemy.hp / math.max(1e-9, enemy.share * enemy.sizes), state.finished[enemy] == true) then
				state.finished[enemy] = true
				spiritRoar(tower, own)
			end
		end
	end
end

------------------------------------------------------------------ Spotter Blimp (PLAN 9h T125b)

-- Visuals only.
local HOOK_COLOR = Color3.fromRGB(90, 90, 95)
local BOMB_COLOR = Color3.fromRGB(255, 150, 60)
local LIGHT_REFRESH = 0.25 -- s the searchlight's +% lasts after the last frame under it (keeps it continuous)

local pendingAirlifts: { { tower: Tower, at: number } } = {}

-- Sky Hook: the smallest small dino under it is lifted off the track (a take-down: every
-- size pays, pops to the owner).
local function skyHook(tower: Tower, dinos: { Enemies.Enemy }, ground: Vector3)
	local list = {}
	for i, enemy in dinos do
		list[i] = {
			hp = enemy.hp,
			at = enemy.distance,
			boss = enemy.def.boss == true,
			sizesLeft = enemy.size,
			inRange = ownSide(tower, enemy) and Blimp.under(enemy.part.Position, ground, tower.stats.range),
		}
	end
	local i = Blimp.hookPick(list)
	if not i then
		return
	end
	local enemy = dinos[i]
	local at = enemy.part.Position
	local killed, gone, dropped = Enemies.dropSizes(enemy, enemy.size)
	credit(tower.owner, killed, gone, dropped)
	if gone then
		takeDownMark(tower, at)
	end
	Effects.tracer(tower.muzzle, at, HOOK_COLOR)
end

-- Bombing Run (AutoFire, once a round played): every dino on the side's track takes Field
-- strike x x the gun's shot (9e Field strike rules: air too, armour only if it pierces, breaks 1).
local function bombingRun(tower: Tower, dinos: { Enemies.Enemy })
	local stats = tower.stats
	local list, field = {}, {}
	for _, enemy in dinos do
		if enemy.alive and ownSide(tower, enemy) then
			table.insert(list, enemy)
			table.insert(field, { side = tower.side, flying = enemy.def.flying == true, armored = enemy.def.armored == true, bare = Enemies.canHurt(enemy, false) })
		end
	end
	local damage = stats.damage * (1 + tower.buff.damagePercent / 100) * levelScale * stats.fieldStrikeX
	for _, i in StormCoil.fieldTargets(field, tower.side, piercing(tower)) do
		local enemy = list[i]
		Effects.tracer(enemy.part.Position + Vector3.new(0, Blimp.HEIGHT, 0), enemy.part.Position, BOMB_COLOR)
		hit(tower, enemy, damage, 1)
	end
end

-- A paratrooper's shot lands (ground dinos only; breaks 1).
local function paraShot(tower: Tower, enemy: Enemies.Enemy, x: number)
	if not enemy.alive or enemy.def.flying or not canTarget(tower, enemy) then
		return
	end
	hit(tower, enemy, Blimp.paraDamage() * x * levelScale, 1, true)
end

-- Paratroopers: n walkers drop below the blimp and fight until the round ends (Shared/Walker,
-- fight mode; within the side's walker cap).
local function dropParatroopers(tower: Tower)
	local state = tower.blimp :: BlimpState
	local landAt = state.at
	local land = Enemies.pointAt(landAt, tower.side)
	local colour = campColour(tower)
	Walkers.sync(state.paraKey, {
		count = tower.stats.paratroopers,
		params = Blimp.paraParams(),
		side = tower.side,
		base = land,
		homeAt = landAt,
		sending = true,
		healsBetweenRounds = false,
		look = function()
			return TowerLook.buildRanger(colour)
		end,
		onHit = function(enemy, landed)
			paraShot(tower, enemy, landed.x)
		end,
	})
	Effects.disc(land + Vector3.new(0, 0.3, 0), 4, colour, 0.3, 0.8)
end

-- Airlift: the first of its side's towers Trampled each round is lifted and set down repaired
-- Blimp.AIRLIFT_S later (one per blimp per round).
airlift = function(tower: Tower)
	if tower.def.untouchable then
		return
	end
	for _, source in towers do
		local state = source.blimp
		if state and source.side == tower.side and Blimp.airlifts(source.stats, state.airliftUsed) then
			state.airliftUsed = true
			table.insert(pendingAirlifts, { tower = tower, at = os.clock() + Blimp.AIRLIFT_S })
			Effects.tracer(source.muzzle, tower.position, HOOK_COLOR)
			return
		end
	end
end

local function stepAirlifts()
	local now = os.clock()
	for i = #pendingAirlifts, 1, -1 do
		local lift = pendingAirlifts[i]
		if now >= lift.at then
			table.remove(pendingAirlifts, i)
			if table.find(towers, lift.tower) and lift.tower.knockedOut then
				Towers.repair(lift.tower)
			end
		end
	end
end

-- The standing tower with HP nearest `point` on `side` (Spare Parts' crate heal).
local function nearestDamageable(point: Vector3, side: number): Tower?
	local best, bestD = nil, math.huge
	for _, other in towers do
		local d = (other.base - point).Magnitude
		if other.side == side and not other.def.untouchable and not other.knockedOut and d < bestD then
			best, bestD = other, d
		end
	end
	return best
end

local function crateHeal(tower: Tower, point: Vector3, crates: number)
	if tower.stats.crateHealPercent <= 0 or crates <= 0 then
		return
	end
	local near = nearestDamageable(point, tower.side)
	if near then
		Towers.heal(near, Blimp.crateHeal(tower.stats, near.maxHp) * crates)
	end
end

-- A finished lap: a crate (Lap chests), med kits and Rebuild Kits' repairs below its path.
local function lapDrops(tower: Tower, below: Vector3)
	local stats = tower.stats
	local drops = Blimp.lapDrops(stats)
	if drops.crates > 0 and onCrate then
		for _ = 1, drops.crates do
			onCrate(below, stats.chestCash, tower.side)
		end
		crateHeal(tower, below, drops.crates)
	end
	if drops.kits > 0 and onKit then
		for _ = 1, drops.kits do
			onKit(below, stats.medKitHeal, tower.side)
		end
	end
	if drops.repairs > 0 then
		local trampled, distances = {}, {}
		for _, other in towers do
			if other.side == tower.side and other.knockedOut and not other.def.untouchable then
				local onPath = Enemies.pointAt(Enemies.trackDistanceNear(other.base, tower.side), tower.side)
				local offset = other.base - onPath
				table.insert(trampled, other)
				table.insert(distances, Vector2.new(offset.X, offset.Z).Magnitude)
			end
		end
		for _, i in Blimp.repairs(distances, stats.range, drops.repairs) do
			Towers.repair(trampled[i])
			Effects.tracer(tower.muzzle, trampled[i].position, HOOK_COLOR)
		end
	end
end

local function stepBlimp(tower: Tower, dt: number, own)
	local state = tower.blimp
	if not state then
		return
	end
	local stats = tower.stats
	local speed = Blimp.speed(stats)
	local lapDone
	state.at, state.dir, lapDone = Blimp.advance(state.at, state.dir, speed, dt, Enemies.trackLength(tower.side))
	local dinos = {}
	for _, enemy in own do
		if enemy.alive then
			table.insert(dinos, enemy)
		end
	end
	-- Tracking Beam: the light and gun centre on the side's biggest dino, moving at Blimp speed.
	if stats.targetsBiggest then
		local list = {}
		for i, enemy in dinos do
			list[i] = { hp = enemy.hp, at = enemy.distance, boss = enemy.def.boss == true, sizesLeft = enemy.size, inRange = true }
		end
		local i = Blimp.biggest(list)
		state.focus = Blimp.follow(state.focus, if i then dinos[i].distance else state.at, speed, dt)
	else
		state.focus = state.at
	end
	local ground = Enemies.pointAt(state.focus, tower.side)
	local below = Enemies.pointAt(state.at, tower.side)
	local air = below + Vector3.new(0, Blimp.HEIGHT, 0)
	tower.position = ground + Vector3.new(0, TowerLook.BODY_HEIGHT / 2, 0)
	tower.muzzle = air - Vector3.new(0, 4, 0)
	TowerLook.poseBlimp(state.model, air, Enemies.pointAt(state.at + state.dir, tower.side) - below, ground, stats.range)
	if hasAura(stats) then
		auraDirty = true -- its auras move with it (refreshed at most every AURA_REFRESH s)
	end
	-- Searchlight: dinos under the light take +Brittle % (bosses too).
	if stats.brittlePercent > 0 then
		for _, enemy in dinos do
			if ownSide(tower, enemy) and Blimp.under(enemy.part.Position, ground, stats.range) then
				Enemies.chill(enemy, { slowPercent = 0, seconds = LIGHT_REFRESH, affectsBosses = true, brittlePercent = stats.brittlePercent, stripsArmor = false })
			end
		end
	end
	if stats.hookEvery > 0 then
		local fire
		state.hookTimer, fire = Blimp.hookTick(state.hookTimer, dt, stats.hookEvery)
		if fire then
			skyHook(tower, dinos, ground)
		end
	end
	if stats.bombingRun then
		local boss = false
		for _, enemy in dinos do
			boss = boss or enemy.def.boss == true
		end
		if AutoFire.check(state.auto, boss, #dinos, Enemies.allSpawned(tower.side), #dinos) then
			bombingRun(tower, dinos)
		end
	end
	state.roundClock += dt
	if Blimp.paraDue(stats.paratroopers, state.roundClock, state.paraDropped) then
		state.paraDropped = true
		dropParatroopers(tower)
	end
	if lapDone then
		lapDrops(tower, below)
	end
end

------------------------------------------------------------------ Meteor Beacon (PLAN 9i T127)

-- Visuals only.
local WARN_COLOR = Color3.fromRGB(230, 40, 30)
local ROCK_COLOR = Color3.fromRGB(95, 60, 45)
local CRATER_COLOR = Color3.fromRGB(255, 110, 30)
local ICE_COLOR = Color3.fromRGB(170, 225, 255)
local ASH_COLOR = Color3.fromRGB(120, 115, 110)
local CRATER_TICK = 0.25 -- s a crater's touch (strip, amp, miss, ash) lasts after the last frame in it

-- One meteor on its way: it lands at `at` (distance along its side's track) at `when`.
type Landing = { at: number, when: number, damage: number, splash: number, crater: boolean, small: boolean, giant: boolean? }

-- A meteor lands: every dino it can hit in the splash takes the hit and breaks the build's
-- sizes (the biggest one more with Dino Killer); a crater, a Cinder Trail strip, Impact
-- Winter's side slow after.
local function meteorLand(tower: Tower, landing: Landing, own)
	local state = tower.meteor :: MeteorState
	local stats = tower.stats
	local dinos, list = {}, {}
	for _, enemy in own do
		if enemy.alive and ownSide(tower, enemy) then
			table.insert(list, enemy)
			table.insert(dinos, { id = enemy, at = enemy.distance, boss = enemy.def.boss == true, flying = enemy.def.flying == true, sizes = enemy.size })
		end
	end
	local point = Enemies.pointAt(landing.at, tower.side)
	Effects.part(Vector3.one * (if landing.small then 1.5 else 3), CFrame.new(point + Vector3.new(0, 1, 0)), ROCK_COLOR, 0.4, Enum.PartType.Ball)
	Effects.disc(point + Vector3.new(0, 0.3, 0), landing.splash, CRATER_COLOR, 0.35, 0.4)
	local hits = Meteor.hits(dinos, landing.at, landing.splash, stats.hitsAir)
	local biggest = Meteor.biggest(hits)
	for _, d in hits do
		local enemy = d.id :: Enemies.Enemy
		if stats.stripsArmor then
			Enemies.strip(enemy, Config.Tuning.StripS) -- Glass Crater: the meteor bares them too
		end
		hit(tower, enemy, landing.damage, Meteor.breaksFor(stats, d == biggest))
	end
	if landing.crater then
		local crater = Meteor.crater(stats, landing.at, os.clock())
		table.insert(state.craters, crater)
		local seconds = Meteor.craterSeconds(stats)
		Hazards.burn(landing.at, Config.Tuning.CraterRadius, Meteor.craterBurn(stats) * levelScale, seconds, piercing(tower) or stats.stripsArmor, tower.owner, tower.side)
		if stats.craterFreezeSeconds > 0 then
			Effects.disc(point + Vector3.new(0, 0.5, 0), Config.Tuning.CraterRadius, ICE_COLOR, seconds, 0.55)
		elseif stats.throwMissPercent > 0 or stats.biteMissPercent > 0 then
			Effects.disc(point + Vector3.new(0, 0.5, 0), Config.Tuning.CraterRadius, ASH_COLOR, seconds, 0.6)
		end
		if stats.fireLine then -- Fire Line: the stretch to a close live crater burns too
			local now = os.clock()
			for _, other in state.craters do
				local gap = math.abs(other.at - landing.at)
				if other ~= crater and other.ends > now and gap > 0 and gap <= Config.Tuning.FireLineGapStuds then
					local both = math.min(other.ends, crater.ends) - now
					Hazards.burn((other.at + landing.at) / 2, gap / 2, Meteor.craterBurn(stats) * levelScale, both, piercing(tower) or stats.stripsArmor, tower.owner, tower.side)
				end
			end
		end
	end
	if landing.small and stats.burnStreak then -- Cinder Trail
		local from, to = Meteor.streak(landing.at)
		Hazards.burn((from + to) / 2, (to - from) / 2, Meteor.craterBurn(stats) * levelScale, Meteor.STREAK_SECONDS, piercing(tower), tower.owner, tower.side)
	end
	if stats.sideSlowPercent > 0 and stats.sideSlowSeconds > 0 then -- Impact Winter: every dino on the side
		for _, enemy in list do
			Enemies.chill(enemy, { slowPercent = stats.sideSlowPercent, seconds = stats.sideSlowSeconds, affectsBosses = true, brittlePercent = 0, stripsArmor = false })
		end
	end
end

-- Queue meteors at `points` after the warning ring (n small ones spread over Meteor.SMALL_SPREAD s).
local function meteorQueue(tower: Tower, points: { number }, damage: number, splash: number, small: boolean, crater: boolean)
	local state = tower.meteor :: MeteorState
	local now, warn = os.clock(), Meteor.warning()
	for i, at in points do
		local delay = if #points > 1 then (i - 1) * Meteor.SMALL_SPREAD / #points else 0
		local point = Enemies.pointAt(at, tower.side)
		task.delay(delay, function()
			Effects.disc(point + Vector3.new(0, 0.35, 0), splash, WARN_COLOR, warn, 0.5) -- the warning ring
		end)
		table.insert(state.landings, { at = at, when = now + delay + warn, damage = damage, splash = splash, crater = crater and i == 1, small = small })
	end
	Effects.tracer(tower.muzzle, tower.muzzle + Vector3.new(0, 30, 0), WARN_COLOR) -- the red flare
end

local function meteorDinos(tower: Tower, own): { Meteor.Dino }
	local dinos = {}
	for _, enemy in own do
		if enemy.alive and ownSide(tower, enemy) then
			table.insert(dinos, { id = enemy, at = enemy.distance, boss = enemy.def.boss == true, flying = enemy.def.flying == true, sizes = enemy.size })
		end
	end
	return dinos
end

local function meteorDamage(tower: Tower): number
	return tower.stats.damage * (1 + tower.buff.damagePercent / 100) * levelScale
end

-- A strike now: one meteor on the densest bunch, n small ones (Sky Rocks; Scatter's segments),
-- or a Starfall wave (no crater).
local function meteorStrike(tower: Tower, dinos: { Meteor.Dino }, starfall: boolean)
	local stats = tower.stats
	local length = Enemies.trackLength(tower.side)
	local x = meteorDamage(tower) / math.max(1e-9, stats.damage)
	if starfall then
		local n, dmg, splash = Meteor.starfall(stats)
		meteorQueue(tower, Meteor.points(dinos, n, true, length, stats.hitsAir), dmg * x, splash, true, false)
		return
	end
	local n, dmg, splash = Meteor.strike(stats)
	meteorQueue(tower, Meteor.points(dinos, n, stats.scatter, length, stats.hitsAir), dmg * x, splash, n > 1, true)
end

-- Extinction Event: every dino on the side takes Extinction x the meteor (breaks 1); the
-- densest bunch's break Extinction breaks.
local function extinctionEvent(tower: Tower, own)
	local stats = tower.stats
	local dinos = meteorDinos(tower, own)
	local centre = Meteor.densest(dinos, stats.hitsAir)
	if centre == nil then
		return
	end
	Effects.disc(Enemies.pointAt(centre, tower.side) + Vector3.new(0, 0.4, 0), Config.Tuning.BunchRadiusStuds * 2, CRATER_COLOR, 1, 0.3)
	local scale = meteorDamage(tower) / math.max(1e-9, stats.damage)
	for _, d in dinos do
		if stats.hitsAir or not d.flying then
			local inBunch = math.abs(d.at - centre) <= Config.Tuning.BunchRadiusStuds
			local dmg, breaks = Meteor.extinctionHit(stats, inBunch)
			hit(tower, d.id :: Enemies.Enemy, dmg * scale, breaks)
		end
	end
end

-- Comet Tail (Bombing run): once a round played, Field strike x the meteor on every dino on the
-- side's track (the 9h Bombing Run rules: air too, armour only if it pierces, breaks 1).
local function cometTail(tower: Tower, own)
	local stats = tower.stats
	local list, field = {}, {}
	for _, enemy in own do
		if enemy.alive and ownSide(tower, enemy) then
			table.insert(list, enemy)
			table.insert(field, { side = tower.side, flying = enemy.def.flying == true, armored = enemy.def.armored == true, bare = Enemies.canHurt(enemy, false) })
		end
	end
	local damage = meteorDamage(tower) * stats.fieldStrikeX
	for _, i in StormCoil.fieldTargets(field, tower.side, piercing(tower)) do
		local enemy = list[i]
		Effects.tracer(enemy.part.Position + Vector3.new(0, 25, 0), enemy.part.Position, CRATER_COLOR)
		hit(tower, enemy, damage, 1)
	end
end

local function stepMeteor(tower: Tower, dt: number, own)
	local state = tower.meteor
	if not state then
		return
	end
	local stats, now = tower.stats, os.clock()
	state.craters = Meteor.prune(state.craters, now)
	-- Craters touch the dinos in them: Glass Crater strips, Scorch Marks marks, New Ice Age freezes once.
	if #state.craters > 0 then
		for _, enemy in own do
			if enemy.alive and ownSide(tower, enemy) and (stats.hitsAir or not enemy.def.flying) then
				local crater = Meteor.inCrater(state.craters, enemy.distance, now, stats.fireLine)
				if crater then
					if stats.stripsArmor then
						Enemies.strip(enemy, CRATER_TICK)
					end
					if stats.craterAmpPercent > 0 then
						Enemies.mark(enemy, stats.craterAmpPercent, Meteor.AMP_SECONDS)
					end
					if stats.craterFreezeSeconds > 0 and Meteor.freezeOnce(crater, enemy) then
						Enemies.stun(enemy, FourX.hardStop(stats.craterFreezeSeconds, enemy.def.boss == true), true)
					end
				end
			end
		end
	end
	for i = #state.landings, 1, -1 do
		local landing = state.landings[i]
		if now >= landing.when then
			table.remove(state.landings, i)
			meteorLand(tower, landing, own)
		end
	end
	if tower.knockedOut then
		return -- Trampled: no new meteors
	end
	local dinos = meteorDinos(tower, own)
	local every, starfall = Meteor.strikeEvery(stats)
	state.timer += dt * (1 + tower.buff.ratePercent / 100)
	if state.timer >= every and #dinos > 0 then
		state.timer = 0
		meteorStrike(tower, dinos, starfall)
	end
	if stats.meteorEvery > 0 then -- Endless Rain: one more small meteor on its own timer
		state.rainTimer += dt
		if state.rainTimer >= stats.meteorEvery and #dinos > 0 then
			state.rainTimer = 0
			local dmg, splash = Meteor.small(stats)
			meteorQueue(tower, Meteor.points(dinos, 1, false, 1, stats.hitsAir), dmg * meteorDamage(tower) / math.max(1e-9, stats.damage), splash, true, false)
		end
	end
	if stats.extinction then
		local centre = Meteor.densest(dinos, stats.hitsAir)
		local boss, count = false, 0
		if centre then
			for _, d in dinos do
				if math.abs(d.at - centre) <= Config.Tuning.BunchRadiusStuds then
					count += 1
					boss = boss or d.boss == true
				end
			end
		end
		if Meteor.extinctionNow(state.extinctionAuto, boss, count, Enemies.allSpawned(tower.side), #dinos) then
			extinctionEvent(tower, own)
		end
	end
	if stats.bombingRun then
		local boss = false
		for _, d in dinos do
			boss = boss or d.boss == true
		end
		if AutoFire.check(state.auto, boss, #dinos, Enemies.allSpawned(tower.side), #dinos) then
			cometTail(tower, own)
		end
	end
end

-- Ash Cloud / Blinding Dust: the strongest Throw / Bite miss % of its side's craters holding `point`.
local function craterMiss(point: Vector3, side: number, field: string): number
	local percent, now = 0, os.clock()
	for _, tower in towers do
		local state = tower.meteor
		if state and tower.side == side and (tower.stats :: any)[field] > 0 and #state.craters > 0 then
			if Meteor.inCrater(state.craters, Enemies.trackDistanceNear(point, side), now, tower.stats.fireLine) then
				percent = math.max(percent, (tower.stats :: any)[field])
			end
		end
	end
	return percent
end

-- Ash Cloud / Blinding Dust: dinos in a crater miss this % of their bites.
function Towers.biteMissAt(point: Vector3, side: number): number
	return craterMiss(point, side, "biteMissPercent")
end

-- Studio `firenow METEOR`: a strike now; Extinction Event / Comet Tail now (ignoring the trigger).
local function meteorFireNow(tower: Tower, fired: { string })
	if not tower.meteor then
		return
	end
	local own = BattleRules.ownDinos(Enemies.getLive(), tower.side, "tower")
	local dinos = meteorDinos(tower, own)
	if #dinos > 0 then
		local _, starfall = Meteor.strikeEvery(tower.stats)
		meteorStrike(tower, dinos, starfall)
		table.insert(fired, if starfall then "Starfall" else "meteor strike")
	end
	if tower.stats.extinction then
		extinctionEvent(tower, own)
		table.insert(fired, "Extinction Event")
	end
	if tower.stats.bombingRun then
		cometTail(tower, own)
		table.insert(fired, "Comet Tail")
	end
end

-- Blinding Glare: the strongest Throw miss % of its side's blimps whose circle holds `point`.
function Towers.throwMissAt(point: Vector3, side: number): number
	local percent = 0
	for _, tower in towers do
		if tower.blimp and tower.side == side and tower.stats.throwMissPercent > 0 and covers(tower, point) then
			percent = math.max(percent, tower.stats.throwMissPercent)
		end
	end
	return math.max(percent, craterMiss(point, side, "throwMissPercent")) -- Ash Cloud / Blinding Dust (PLAN 9i)
end

-- Spotter's Map: publishes which sides' dinos are outlined (each client outlines its own side's).
local outlined: { [number]: boolean } = {}
local function publishOutlines()
	local now: { [number]: boolean } = {}
	for _, tower in towers do
		if tower.blimp and tower.stats.dinoOutlines then
			now[tower.side] = true
		end
	end
	for side in outlined do
		if not now[side] then
			ReplicatedStorage:SetAttribute(Blimp.outlineAttribute(side), nil)
		end
	end
	for side in now do
		if not outlined[side] then
			ReplicatedStorage:SetAttribute(Blimp.outlineAttribute(side), true)
		end
	end
	outlined = now
end

-- Studio `firenow BLIMP`: Bombing Run, Paratroopers and Airlift (on the nearest Trampled own
-- tower) now.
local function blimpFireNow(tower: Tower, fired: { string })
	local state = tower.blimp
	if not state then
		return
	end
	local own = BattleRules.ownDinos(Enemies.getLive(), tower.side, "tower")
	if tower.stats.bombingRun then
		bombingRun(tower, own)
		table.insert(fired, "Bombing Run")
	end
	if tower.stats.paratroopers > 0 then
		Walkers.clear(state.paraKey)
		dropParatroopers(tower)
		state.paraDropped = true
		table.insert(fired, "Paratroopers")
	end
	if tower.stats.airlift then
		for _, other in towers do
			if other.side == tower.side and other.knockedOut and not other.def.untouchable then
				state.airliftUsed = false
				airlift(other)
				table.insert(fired, "Airlift")
				break
			end
		end
	end
end

-- A pop (a dino lost a size; `source` = Enemies.source(): "tower", "hunter" or "totem"): every
-- standing own-side Bone Totem whose range holds it charges and pays its Bone cash. It only
-- reads the pop: Bones, scores and Bounties are counted by Main exactly as without a totem.
function Towers.dinoPopped(enemy: Enemies.Enemy, source: string)
	local kind: Totem.Source = if source == "hunter" then "hunter" elseif source == "totem" then "totem" else "tower"
	for _, tower in towers do
		local state = tower.totem
		if state and not tower.knockedOut and ownSide(tower, enemy) and covers(tower, enemy.part.Position) then
			local stats = tower.stats
			if kind ~= "totem" and stats.boneCash > 0 and onCash then
				onCash(tower.side, stats.boneCash)
			end
			local _, fills = Totem.observe(state.rules, stats, kind, enemy.def.boss == true)
			state.pending += fills -- fired next frame, outside Enemies' damage call
			auraDirty = auraDirty or stats.chargeAuraDamagePercent > 0
		end
	end
end

-- A whole dino taken down (Bounty Wall, PLAN 9h): inside a Bounty charge x totem's range, the
-- owner's Bounties count it Bounty charge x times (the extra whole take-downs reported as they add up).
function Towers.dinoTakenDown(enemy: Enemies.Enemy, source: string)
	if source == "totem" or not onBountyExtra then
		return
	end
	for _, tower in towers do
		local state = tower.totem
		local owner = tower.owner
		if state and owner and owner.Parent and tower.stats.bountyChargeX > 1 and not tower.knockedOut and ownSide(tower, enemy) and covers(tower, enemy.part.Position) then
			local extra = Totem.bountyExtra(state.rules, tower.stats)
			if extra > 0 then
				onBountyExtra(owner, enemy.key, extra)
			end
		end
	end
end

------------------------------------------------------------------ Storm Coil

local function isCoil(tower: Tower): boolean
	return tower.def.chains == true and not tower.knockedOut
end

-- The circles a coil's arcs may use: its own range, or every standing Storm Coil's
-- with Jump Spark.
local function coilAreas(tower: Tower): { StormCoil.Area }
	local areas = { { center = tower.base, radius = tower.stats.range } }
	if tower.stats.arcJumps then
		for _, other in towers do
			if other ~= tower and isCoil(other) then
				table.insert(areas, { center = other.base, radius = other.stats.range })
			end
		end
	end
	return areas
end

local function coilDamage(tower: Tower): number
	return tower.stats.damage * (1 + tower.buff.damagePercent / 100) * levelScale
end

-- One coil hit: Static Shock's bonus if its last strike charged this dino, breaks 1
-- unless `breaks` says more (Judgement Bolt).
local function coilHit(tower: Tower, enemy: Enemies.Enemy, damage: number, breaks: number?)
	local stats = tower.stats
	local pierce = piercing(tower)
	if not Enemies.canHurt(enemy, pierce) then
		return
	end
	if stats.staticPercent > 0 then
		if tower.static[enemy] then
			damage *= 1 + stats.staticPercent / 100
		end
		tower.static[enemy] = true
	end
	if enemy.def.armored then
		damage *= stats.armoredMult
	end
	if enemy.def.boss then
		damage *= stats.bossMult
	end
	if tower.buff.slowedPercent > 0 and Enemies.isSlowed(enemy) then
		damage *= 1 + tower.buff.slowedPercent / 100 -- Tar Totem
	end
	local b = if breaks and breaks > 1 then Enemies.breaksFor(enemy, breaks, towerLevel, false) else 1
	credit(tower.owner, Enemies.damage(enemy, damage, pierce, b))
end

-- A chain strike from the first dino in range. Returns true if it fired.
local function fireChain(tower: Tower, live): boolean
	local stats = tower.stats
	local target = pickFirst(tower, live)
	if not target then
		return false
	end
	local areas = coilAreas(tower)
	local list, points, first = {}, {}, nil
	for _, enemy in live do
		if enemy.alive and canTarget(tower, enemy) and (enemy == target or StormCoil.covered(enemy.part.Position, areas)) then
			table.insert(list, enemy)
			table.insert(points, enemy.part.Position)
			if enemy == target then
				first = #list
			end
		end
	end
	if not first then
		return false
	end
	local links = StormCoil.chain(points, first, stats.arcs, stats.arcReach, stats.arcForks, Config.Tuning.CoilArcFalloff)
	-- Static Shock: only dinos this strike reaches stay charged for the next one.
	local charged = {}
	for _, link in links do
		charged[list[link.index]] = tower.static[list[link.index]]
	end
	table.clear(tower.static)
	for enemy, was in charged do
		tower.static[enemy] = was
	end
	local damage = coilDamage(tower)
	-- Supercell's slow (PLAN 9e): on the first dino, or the whole chain with Chain effects.
	local slow: Enemies.Chill? = if stats.slowPercent > 0
		then { slowPercent = stats.slowPercent, seconds = stats.slowLinger, affectsBosses = stats.slowsBosses, brittlePercent = 0, stripsArmor = false }
		else nil
	for _, link in links do
		local enemy = list[link.index]
		local from = if link.from then list[link.from].part.Position else tower.muzzle
		Effects.tracer(from, enemy.part.Position, ARC_COLOR)
		-- Thunderclap stuns the first dino; Chain effects (Superconductor) every arc, capped.
		Enemies.stun(enemy, StormCoil.linkStun(link.hop, stats.stunSeconds, stats.chainEffects), stats.stunsBosses)
		if slow and StormCoil.linkSlows(link.hop, stats.chainEffects) then
			Enemies.chill(enemy, slow)
		end
		-- Thunderstrike (PLAN 9e): the strike's first dino gets the build's Size breaks; arcs 1.
		coilHit(tower, enemy, damage * link.x, if link.hop == 0 then stats.sizeBreaks else nil)
	end
	return true
end

-- Storm Front (PLAN 9e, #297): every Field strike every s, every dino on this coil's side's
-- field takes Field strike x its damage, wherever it is (fliers too; armour only if it
-- pierces; breaks 1). Each Storm Front coil fires its own.
local FIELD_COLOR = Color3.fromRGB(200, 230, 255) -- visuals only
local function stepField(tower: Tower, dt: number, live)
	local stats = tower.stats
	if stats.fieldStrikeEvery <= 0 or tower.knockedOut then
		tower.fieldTimer = 0
		return
	end
	local fired
	tower.fieldTimer, fired = StormCoil.fieldTick(tower.fieldTimer, dt, stats.fieldStrikeEvery)
	if not fired then
		return
	end
	local list, dinos = {}, {}
	for _, enemy in live do
		if enemy.alive and ownSide(tower, enemy) then
			table.insert(list, enemy)
			table.insert(dinos, { side = tower.side, flying = enemy.def.flying == true, armored = enemy.def.armored == true, bare = Enemies.canHurt(enemy, false) })
		end
	end
	local damage = coilDamage(tower) * stats.fieldStrikeX
	for _, i in StormCoil.fieldTargets(dinos, tower.side, piercing(tower)) do
		local enemy = list[i]
		Effects.tracer(enemy.part.Position + Vector3.new(0, 30, 0), enemy.part.Position, FIELD_COLOR)
		coilHit(tower, enemy, damage)
	end
end

-- Judgement Bolt: the dino with the most HP in the coil's range.
local function stepBolt(tower: Tower, dt: number, live)
	if not tower.stats.judgementBolt or tower.knockedOut then
		tower.boltTimer = 0
		return
	end
	local every = Config.Tuning.JudgementBoltEvery
	tower.boltTimer = math.min(every, tower.boltTimer + dt)
	if tower.boltTimer < every then
		return
	end
	local list, hps = {}, {}
	local range = tower.stats.range
	for _, enemy in live do
		if enemy.alive and canTarget(tower, enemy) and (enemy.part.Position - tower.position).Magnitude <= range then
			table.insert(list, enemy)
			table.insert(hps, enemy.hp)
		end
	end
	local pick = StormCoil.biggest(hps)
	if not pick then
		return -- stays ready
	end
	tower.boltTimer = 0
	local enemy = list[pick]
	local tuning = Config.Tuning
	Effects.tracer(enemy.part.Position + Vector3.new(0, 30, 0), enemy.part.Position, BOLT_COLOR)
	Enemies.stun(enemy, tuning.JudgementBoltStun, true)
	coilHit(tower, enemy, coilDamage(tower) * tuning.JudgementBoltX, tuning.JudgementBoltBreaks)
end

-- Power Grid: one shared strike every Power Grid every seconds, however many Power
-- Grid coils stand, from the one that hits hardest (DECISIONS #151).
-- One Power Grid per side (its own coils, its own dinos, #231); co-op is side 1 alone.
local gridTimers: { [number]: number } = {}
local function stepGridSide(side: number, dt: number, live)
	local striker, coils = nil, 0
	for _, tower in towers do
		if isCoil(tower) and tower.side == side then
			coils += 1
			if tower.stats.powerGrid and (striker == nil or coilDamage(tower) > coilDamage(striker)) then
				striker = tower
			end
		end
	end
	if not striker then
		gridTimers[side] = 0
		return
	end
	local every = Config.Tuning.PowerGridEvery
	local timer = (gridTimers[side] or 0) + dt
	gridTimers[side] = timer
	if timer < every then
		return
	end
	gridTimers[side] = timer - every
	local rangeMult, damageMult = StormCoil.grid(coils)
	local areas = {}
	for _, tower in towers do
		if isCoil(tower) and tower.side == side then
			table.insert(areas, { center = tower.base, radius = tower.stats.range * rangeMult })
			Effects.disc(tower.base + Vector3.new(0, 0.3, 0), tower.stats.range * rangeMult, ARC_COLOR, 0.3, 0.4)
		end
	end
	local damage = coilDamage(striker) * damageMult
	for _, enemy in live do
		if enemy.alive and canTarget(striker, enemy) and StormCoil.covered(enemy.part.Position, areas) then
			Effects.tracer(enemy.part.Position + Vector3.new(0, 12, 0), enemy.part.Position, ARC_COLOR)
			coilHit(striker, enemy, damage)
		end
	end
end

local function stepGrid(dt: number, live)
	local seen: { [number]: boolean } = {}
	for _, tower in towers do
		if isCoil(tower) and not seen[tower.side] then
			seen[tower.side] = true
			stepGridSide(tower.side, dt, live)
		end
	end
	for side in gridTimers do
		if not seen[side] then
			gridTimers[side] = 0 -- no coils left on that side
		end
	end
end

------------------------------------------------------------------ Falcon Roost

local function hasBirds(tower: Tower): boolean
	return (tower.def.birds or 0) > 0
end

-- How long a Hooded Scout mark lasts after the last frame a boss spent in range.
local HOOD_REFRESH = 0.25

-- One bird's (or peck's) hit: the tower's hit (armour, boss x, stun, Lure's knockback,
-- breaks), then Falcon Bells' mark on what it struck.
local function falconHit(tower: Tower, enemy: Enemies.Enemy, damage: number, breaks: number)
	hit(tower, enemy, damage, breaks)
	if tower.stats.markPercent > 0 then
		Enemies.mark(enemy, tower.stats.markPercent, Config.Tuning.FalconBellsMark)
	end
end

local function falconDamage(tower: Tower): number
	return tower.stats.damage * (1 + tower.buff.damagePercent / 100) * levelScale
end

-- Murmuration: every dino in range takes a peck (breaks 1, no travel time).
local function peck(tower: Tower, live): boolean
	local range, pecked = tower.stats.range, false
	local damage = falconDamage(tower)
	for _, enemy in live do
		if enemy.alive and canTarget(tower, enemy) and (enemy.part.Position - tower.position).Magnitude <= range then
			pecked = true
			Effects.part(Vector3.one * 0.6, CFrame.new(enemy.part.Position + Vector3.new(0, 2, 0)), PECK_COLOR, 0.12, Enum.PartType.Ball)
			falconHit(tower, enemy, damage, 1)
		end
	end
	return pecked
end

-- Sends a free bird at the first dino in range no other bird of this roost is after.
local function fireFalcon(tower: Tower, live): boolean
	local stats = tower.stats
	if stats.murmuration then
		return peck(tower, live)
	end
	if Falcon.free(stats.birds, #tower.sorties) <= 0 then
		return false -- every bird is out: wait for one to come home
	end
	local list, distances, claimed = {}, {}, {}
	local after = {}
	for _, sortie in tower.sorties do
		if not sortie.landed then
			after[sortie.enemy] = true
		end
	end
	for _, enemy in live do
		if enemy.alive and canTarget(tower, enemy) and (enemy.part.Position - tower.position).Magnitude <= stats.range then
			table.insert(list, enemy)
			table.insert(distances, enemy.distance)
			claimed[#list] = after[enemy] == true
		end
	end
	local pick = Falcon.pick(distances, claimed)
	if not pick then
		return false
	end
	local enemy = list[pick]
	local oneWay = Falcon.flight((enemy.part.Position - tower.muzzle).Magnitude)
	local size = if stats.eagle then Vector3.new(2.4, 0.4, 1.4) else Vector3.new(1.1, 0.25, 0.7)
	local part = Effects.part(size, CFrame.new(tower.muzzle), BIRD_COLOR, 2 * oneWay + 0.5)
	table.insert(tower.sorties, { enemy = enemy, out = oneWay, back = 2 * oneWay, landed = false, at = tower.muzzle, part = part })
	return true
end

-- Birds in flight: a bird lands its dive when its travel time runs out, then flies home.
local function stepSorties(tower: Tower, dt: number, live)
	for i = #tower.sorties, 1, -1 do
		local sortie = tower.sorties[i]
		sortie.out -= dt
		sortie.back -= dt
		local enemy = sortie.enemy
		if not sortie.landed then
			if enemy.alive then
				sortie.at = enemy.part.Position
			end
			if sortie.out <= 0 then
				sortie.landed = true
				if enemy.alive then
					local first = not tower.dived[enemy]
					tower.dived[enemy] = true
					local stats = tower.stats
					local damage = Falcon.diveDamage(falconDamage(tower), first, stats.firstDiveX, stats.eagle)
					-- Raking Strike / Strafing Run (PLAN 9e): who else the dive hits, picked before
					-- the dive lands (it may take the struck dino down).
					local extra, line, list = {}, false, {}
					if stats.targets > 1 or stats.lineHits > 1 then
						local candidates, struck = {}, nil
						for _, other in live do
							if other == enemy or (other.alive and canTarget(tower, other) and (other.part.Position - tower.position).Magnitude <= stats.range) then
								table.insert(list, other)
								table.insert(candidates, { position = other.part.Position, distance = other.distance })
								if other == enemy then
									struck = #list
								end
							end
						end
						if struck then
							extra, line = Falcon.extraHits(candidates, struck, stats.targets, stats.lineHits)
						end
					end
					Effects.tracer(sortie.at + Vector3.new(0, 6, 0), sortie.at, BIRD_COLOR)
					falconHit(tower, enemy, damage, stats.sizeBreaks)
					for _, i in extra do
						Effects.tracer(sortie.at, list[i].part.Position, BIRD_COLOR)
						falconHit(tower, list[i], damage, if line then stats.sizeBreaks else 1)
					end
				end
			end
		end
		local whole = math.max(1e-3, sortie.back - sortie.out) -- one way, in seconds
		local position = if not sortie.landed
			then tower.muzzle:Lerp(sortie.at, math.clamp(1 - sortie.out / whole, 0, 1))
			else sortie.at:Lerp(tower.muzzle, math.clamp(1 - sortie.back / whole, 0, 1))
		if sortie.part.Parent then
			sortie.part.CFrame = CFrame.lookAt(position, if sortie.landed then tower.muzzle else sortie.at + Vector3.new(0, 0.01, 0))
		end
		if sortie.back <= 0 then
			sortie.part:Destroy()
			table.remove(tower.sorties, i)
		end
	end
end

-- Hooded Scout: bosses in range stay marked while they're in it.
local function stepHood(tower: Tower, live)
	local percent = tower.stats.bossMarkPercent
	if percent <= 0 or tower.knockedOut then
		return
	end
	for _, enemy in live do
		if enemy.alive and enemy.def.boss and ownSide(tower, enemy) and (enemy.part.Position - tower.position).Magnitude <= tower.stats.range then
			Enemies.mark(enemy, percent, HOOD_REFRESH)
		end
	end
end

-- Hunting Party: every roost with the aura and a bird out, for Falcon.huntingParty.
local function huntingParties(): { Falcon.Party }
	local parties = {}
	for _, tower in towers do
		-- A roost while a bird dives; a Raptor Pen while a raptor fights (PLAN 9g, Raptor.diveAura).
		local active = if tower.raptor then Raptor.diveAura(1, Walkers.fighting(tower)) > 0 else #tower.sorties > 0
		if tower.stats.diveAuraRatePercent > 0 and active then
			table.insert(parties, { center = tower.base, radius = tower.stats.range, percent = tower.stats.diveAuraRatePercent, diving = true, source = tower })
		end
	end
	return parties
end

------------------------------------------------------------------ Harpoon Ballista

-- One volley: each bolt at its dino (Ballista.volley), Skewer's line through every dino
-- on it, Chain Harpoons' chain between each linked pair. Returns true if it fired.
local function fireBallista(tower: Tower, live): boolean
	local stats = tower.stats
	local list, distances, points, hps = {}, {}, {}, {}
	for _, enemy in live do
		if enemy.alive and canTarget(tower, enemy) and (enemy.part.Position - tower.position).Magnitude <= stats.range then
			table.insert(list, enemy)
			table.insert(distances, enemy.distance)
			table.insert(points, enemy.part.Position)
			table.insert(hps, enemy.hp)
		end
	end
	-- Heartseeker (PLAN 9e): Targets biggest ranks by HP left, not distance.
	local picks = Ballista.volley(Ballista.aimKeys(distances, hps, stats.targetsBiggest), stats.shots, stats.chainHarpoons)
	-- PLAN 9e wirings: bolts mark (Serrated Head), slow (Anchor Line: bosses too) and burn
	-- (Fire Bolts, Firestorm Volley: a burning patch under the target, like a shooter's).
	local slow: Enemies.Chill? = if stats.slowPercent > 0
		then { slowPercent = stats.slowPercent, seconds = stats.slowLinger, affectsBosses = stats.slowsBosses, brittlePercent = 0, stripsArmor = false }
		else nil
	if #picks == 0 then
		return false
	end
	local damage = stats.damage * (1 + tower.buff.damagePercent / 100) * levelScale
	local landed = {} -- each bolt's impact point
	for i, pick in picks do
		local target = list[pick]
		landed[i] = points[pick]
		local struck = { target }
		if stats.skewer then
			local stop = Ballista.lineEnd(tower.muzzle, points[pick], stats.range)
			for _, index in Ballista.onLine(points, tower.muzzle, stop) do
				if index ~= pick then
					table.insert(struck, list[index])
				end
			end
			Effects.tracer(tower.muzzle, stop, HARPOON_COLOR)
		else
			Effects.tracer(tower.muzzle, points[pick], HARPOON_COLOR)
		end
		addBurn(tower, target)
		for _, enemy in struck do
			if stats.markPercent > 0 and ownSide(tower, enemy) then
				Enemies.mark(enemy, stats.markPercent, Config.Tuning.MarkDuration or 0)
			end
			hit(tower, enemy, damage, stats.sizeBreaks)
			if slow and enemy.alive and ownSide(tower, enemy) then
				Enemies.chill(enemy, slow)
			end
		end
		rodeoArc(tower, target, struck, damage, live)
	end
	if stats.chainHarpoons then
		for _, pair in Ballista.pairs(#picks) do
			local a, b = picks[pair[1]], picks[pair[2]]
			Effects.tracer(landed[pair[1]], landed[pair[2]], CHAIN_COLOR)
			for _, index in Ballista.onLine(points, landed[pair[1]], landed[pair[2]]) do
				if index ~= a and index ~= b then
					hit(tower, list[index], damage, 1)
				end
			end
		end
	end
	return true
end

-- Tow Line: every Tow Line every s, the boss furthest along in range is pulled back; stays
-- ready while no boss is in range.
local function stepTow(tower: Tower, dt: number, live)
	if not tower.stats.towLine or tower.knockedOut then
		tower.towTimer = 0
		return
	end
	local tuning = Config.Tuning
	tower.towTimer = math.min(tuning.TowLineEvery, tower.towTimer + dt)
	if tower.towTimer < tuning.TowLineEvery then
		return
	end
	local list, distances, bosses = {}, {}, {}
	for _, enemy in live do
		if enemy.alive and canTarget(tower, enemy) and (enemy.part.Position - tower.position).Magnitude <= tower.stats.range then
			table.insert(list, enemy)
			table.insert(distances, enemy.distance)
			bosses[#list] = enemy.def.boss == true
		end
	end
	local pick = Ballista.towPick(distances, bosses)
	if not pick then
		return
	end
	tower.towTimer = 0
	local boss = list[pick]
	Effects.tracer(tower.muzzle, boss.part.Position, HARPOON_COLOR)
	Enemies.knockback(boss, tuning.TowLinePull, true) -- the one boss knockback (PLAN T66)
end

-- Visuals only.
local FREEZE_COLOR = Color3.fromRGB(150, 220, 255)
-- How long a chill lasts after the last frame an enemy spent in range (plus
-- any Permafrost linger). Keeps the chill continuous between frames.
local CHILL_REFRESH = 0.25

-- Chillers: chill everything in range every frame; Freeze pulses hard stops.
local function stepChill(tower: Tower, dt: number, live)
	local stats = tower.stats
	if tower.knockedOut or (stats.slowPercent <= 0 and stats.freezeEvery <= 0) then
		return
	end
	if tower.def.chains or tower.def.harpoons or tower.def.onTrack then
		-- Coil / Ballista Slow % rides their hits (Supercell, Anchor Line; PLAN 9e); a Tar Pit's
		-- is its pool's (stepTar: ground dinos in the pool only), never a ring
		return
	end
	local range = stats.range
	local chill: Enemies.Chill = {
		slowPercent = stats.slowPercent,
		seconds = CHILL_REFRESH + stats.slowLinger,
		affectsBosses = stats.slowsBosses,
		brittlePercent = stats.brittlePercent,
		stripsArmor = stats.stripsArmor,
	}
	local pulse = false
	if stats.freezeEvery > 0 then
		tower.freezeTimer += dt
		if tower.freezeTimer >= stats.freezeEvery then
			tower.freezeTimer -= stats.freezeEvery
			pulse = true
		end
	end
	for _, enemy in live do
		if ownSide(tower, enemy) and (enemy.part.Position - tower.position).Magnitude <= range then
			if stats.slowPercent > 0 then
				Enemies.chill(enemy, chill)
			end
			if pulse then
				Enemies.knockOut(enemy, stats.freezeSeconds, stats.freezeHoldsBosses)
				if stats.freezeDamage > 0 then
					credit(tower.owner, Enemies.damage(enemy, stats.freezeDamage * levelScale, piercing(tower)))
				end
			end
		end
	end
	if pulse then
		Effects.disc(tower.base + Vector3.new(0, 0.3, 0), range, FREEZE_COLOR, 0.3, 0.6)
	end
end

------------------------------------------------------------------ Tar Pit

local TAR_COLOR = Color3.fromRGB(30, 24, 20) -- visuals only
local ERUPTION_COLOR = Color3.fromRGB(255, 120, 40)
-- How long tar slow lasts after the last frame a dino spent in a pool (keeps it
-- continuous between frames), like CHILL_REFRESH.
local TAR_REFRESH = 0.25

-- Seconds each last-size dino has spent in the tar, and the pool it was last in.
local soaked: { [any]: number } = setmetatable({}, { __mode = "k" }) :: any
local lastPool: { [any]: Tower } = setmetatable({}, { __mode = "k" }) :: any

local function isPit(tower: Tower): boolean
	return tower.def.onTrack == true
end

-- A dino walked out of `pit`'s pool: Clinging Tar, Tar Fire, Tar Tracks.
local function leftPool(pit: Tower, enemy: Enemies.Enemy, now: number)
	local stats = pit.stats
	if stats.slowLinger > 0 then
		Enemies.tar(enemy, stats.slowPercent, stats.slowLinger)
	end
	if stats.burnSeconds > 0 and stats.burnDps > 0 then
		local tick = stats.burnDps * stats.burnSeconds * (1 + pit.buff.damagePercent / 100) * levelScale
		Hazards.ignite(enemy, tick, stats.burnSeconds, piercing(pit), pit.owner)
	end
	if stats.tracksSlowPercent > 0 then
		pit.tracksUntil = now + Config.Tuning.TarTracksSeconds
	end
end

local function stepTar(dt: number, live)
	local pits, strengths = {}, {}
	for _, tower in towers do
		if isPit(tower) then
			table.insert(pits, tower)
			table.insert(strengths, TarPit.strength(tower.def, tower.pathTiers))
		end
	end
	if #pits == 0 then
		return
	end
	local tuning = Config.Tuning
	local now = os.clock()
	local erupting = {}
	for _, pit in pits do
		if pit.stats.eruption then
			local fired
			pit.eruptTimer, fired = TarPit.tick(pit.eruptTimer, dt, tuning.EruptionEvery)
			if fired then
				erupting[pit] = true
				for _, d in TarPit.samples(pit.poolAt, pit.stats.range, pit.stats.range / 3) do
					Effects.part(Vector3.new(1.5, 7, 1.5), CFrame.new(Enemies.pointAt(d, pit.side) + Vector3.new(0, 3.5, 0)), ERUPTION_COLOR, 0.4) -- a geyser
				end
			end
		else
			pit.eruptTimer = 0
		end
	end

	for _, enemy in live do
		if not enemy.alive or enemy.def.flying then
			continue
		end
		-- The strongest pool this dino stands in (#189: never more than one).
		local inside, power = {}, {}
		for i, pit in pits do
			if BattleRules.canDamage(pit.side, enemy.side, "dino", HAZARD) and TarPit.contains(enemy.distance, pit.poolAt, pit.stats.range) then
				table.insert(inside, pit)
				table.insert(power, strengths[i])
			end
		end
		local pick = TarPit.strongest(power)
		local pit = if pick then inside[pick] else nil
		if not pit then
			local was = lastPool[enemy]
			if was then
				lastPool[enemy], soaked[enemy] = nil, nil
				if table.find(towers, was) then
					leftPool(was, enemy, now)
				end
			end
			for _, other in pits do
				if BattleRules.canDamage(other.side, enemy.side, "dino", HAZARD) and now < other.tracksUntil and TarPit.onTracks(enemy.distance, other.poolAt, other.stats.range, tuning.TarTracksLength) then
					Enemies.tar(enemy, other.stats.tracksSlowPercent, TAR_REFRESH)
				end
			end
			continue
		end
		lastPool[enemy] = pit
		local stats = pit.stats
		Enemies.tar(enemy, stats.slowPercent, TAR_REFRESH)
		if stats.stripsArmor then
			Enemies.strip(enemy, tuning.StripS or 0) -- Pitch Coat (PLAN 9e): bare while in it, then Strip (s)
		end
		if stats.burnDps > 0 then
			local damage = stats.burnDps * dt * (1 + pit.buff.damagePercent / 100) * levelScale
			credit(pit.owner, Enemies.damage(enemy, damage, piercing(pit)))
		end
		if enemy.alive and erupting[pit] then
			credit(pit.owner, Enemies.dropSizes(enemy, tuning.EruptionSizes))
		end
		if not enemy.alive then
			continue
		end
		if enemy.size <= 1 and not enemy.def.boss then
			soaked[enemy] = (soaked[enemy] or 0) + dt
			if TarPit.sinks(enemy.size, enemy.def.boss == true, false, soaked[enemy], stats.sinkSeconds) then
				local position = enemy.part.Position
				local sunk, gone = Enemies.sink(enemy)
				if sunk then
					lastPool[enemy], soaked[enemy] = nil, nil
					credit(pit.owner, true, gone, 1)
					Effects.disc(Placement.ground(position) + Vector3.new(0, 0.2, 0), 1.5, TAR_COLOR, 0.6, 0.2) -- it goes under
					if onSink and (stats.sinkCash > 0 or stats.sinkChestCash > 0) then
						onSink(stats.sinkCash, stats.sinkChestCash, Placement.ground(position), pit.side)
					end
				end
			end
		else
			soaked[enemy] = 0
		end
	end
end

-- Called every Heartbeat by Main.
-- NOTE: fires at most once per frame (times `shots`), so fire rates above
-- ~60/s are capped.
------------------------------------------------------------------ Field Hospital

-- The strongest standing hospital's heal (and revive) rate covering a point, from
-- `side`'s hospitals only; x Ability tempo (Shared/Pace.healRate, #259).
local function healRates(point: Vector3, side: number): (number, number)
	local heal, revive = 0, 0
	for _, source in towers do
		local s = source.stats
		if s.healPerSecond > 0 and not source.knockedOut and covers(source, point) and BattleRules.canSupport(source.side, side) then
			heal = math.max(heal, Pace.healRate(s.healPerSecond))
			if s.revives then
				revive = math.max(revive, Pace.healRate(s.healPerSecond) * s.reviveSpeed)
			end
		end
	end
	return heal, revive
end

local function stepHealing(dt: number)
	local any = false
	for _, source in towers do
		if source.stats.healPerSecond > 0 and not source.knockedOut then
			any = true
			break
		end
	end
	if not any then
		return
	end
	for _, tower in towers do
		local heal, revive = healRates(tower.base, tower.side)
		if tower.def.untouchable then
			continue -- no HP: a Field Hospital skips it (#148)
		elseif not tower.knockedOut and heal > 0 and tower.hp < tower.maxHp then
			Towers.heal(tower, heal * dt)
		elseif tower.knockedOut and revive > 0 then
			-- Revive: HP climbs while it stays trampled; it stands at full.
			tower.hp = math.min(tower.maxHp, tower.hp + revive * dt)
			if tower.hp >= tower.maxHp then
				Towers.repair(tower)
			else
				showHealth(tower)
			end
		end
	end
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local heal = healRates(root.Position, Sides.playerSide(player:GetAttribute("Side"), ReplicatedStorage:GetAttribute("Sides")))
			if heal > 0 then
				Health.heal(player, heal * dt)
			end
		end
	end
end

export type MedKitDrop = { base: Vector3, count: number, heal: number, side: number }

-- Med kits each standing hospital drops this round.
function Towers.medKits(): { MedKitDrop }
	local drops = {}
	for _, tower in towers do
		local s = tower.stats
		if s.medKits > 0 and s.medKitHeal > 0 and not tower.knockedOut and not tower.blimp then -- a blimp's come each lap
			table.insert(drops, { base = tower.base, count = s.medKits, heal = s.medKitHeal, side = tower.side })
		end
	end
	return drops
end

-- A standing Rescue Beacon: where downed hunters come back, and the share of
-- the respawn time they wait. nil if there's none. `side`: the hunter's (default 1, co-op;
-- a battle hunter only comes back at their own side's beacon, T77).
function Towers.rescueBeacon(side: number?): (Vector3?, number)
	local best, mult = nil, 1
	for _, tower in towers do
		local m = tower.stats.rescueRespawnMult
		if m > 0 and not tower.knockedOut and tower.side == (side or 1) and (best == nil or m < mult) then
			best, mult = tower.base, m
		end
	end
	return best, mult
end

------------------------------------------------------------------ Amber Resin Cannon, per frame

local WALL_STEP = 2 -- studs: how finely the wall's spot is searched along the track
local WALL_CATCH = 1.5 -- studs before the wall where a dino stops

-- The furthest-along point of the side's track still inside the cannon's range.
local function wallSpot(tower: Tower): number
	local d = Enemies.trackDistanceNear(tower.base, tower.side)
	local range = tower.stats.range
	for _ = 1, 400 do
		local p = Enemies.pointAt(d + WALL_STEP, tower.side)
		local flat = Vector2.new(p.X - tower.base.X, p.Z - tower.base.Z).Magnitude
		if flat > range or (p - Enemies.pointAt(d, tower.side)).Magnitude < 1e-3 then
			break
		end
		d += WALL_STEP
	end
	return d
end

-- Raises Resin Wall now (AutoFire, or the Studio `firenow`).
local function raiseWall(tower: Tower)
	local state = tower.resin
	if not state or tower.stats.wallSeconds <= 0 then
		return
	end
	local at = wallSpot(tower)
	local point = Enemies.pointAt(at, tower.side)
	local ahead = Enemies.pointAt(at + 1, tower.side)
	local facing = if (ahead - point).Magnitude > 1e-3 then CFrame.lookAt(point, Vector3.new(ahead.X, point.Y, ahead.Z)) else CFrame.new(point)
	local part = Effects.part(Vector3.new(10, 6, 1.5), facing + Vector3.new(0, 3, 0), AMBER_COLOR, tower.stats.wallSeconds)
	part.Transparency = 0.3
	part.Material = Enum.Material.Glass
	state.wall = { at = at, raisedAt = os.clock(), part = part }
end

-- Amber Age: entombs everything in range now.
local function entombAll(tower: Tower, own)
	local stats = tower.stats
	for _, enemy in own do
		if enemy.alive and not enemy.def.flying and (enemy.part.Position - tower.position).Magnitude <= stats.range then
			entomb(tower, enemy, FourX.hardStop(stats.entombSeconds, enemy.def.boss == true), false)
		end
	end
end

local function stepResin(tower: Tower, dt: number, own)
	local state = tower.resin
	if not state then
		return
	end
	local stats, now = tower.stats, os.clock()
	if tower.knockedOut then
		state.wall = nil
		return
	end
	-- Amber Age: every Entomb all every (s).
	if stats.entombAllEvery > 0 then
		state.allTimer += dt
		if state.allTimer >= stats.entombAllEvery then
			state.allTimer -= stats.entombAllEvery
			entombAll(tower, own)
		end
	end
	-- Sticky Bed: dinos near one it entombed walk slower.
	if stats.entombSlowPercent > 0 then
		for tomb, untilTime in state.entombed do
			if now >= untilTime or not tomb.alive then
				state.entombed[tomb] = nil
				continue
			end
			for _, enemy in own do
				if enemy ~= tomb and enemy.alive and Resin.inStickyBed((enemy.part.Position - tomb.part.Position).Magnitude) then
					Enemies.chill(enemy, { slowPercent = stats.entombSlowPercent, seconds = STICKY_REFRESH, affectsBosses = false, brittlePercent = 0, stripsArmor = false })
				end
			end
		end
	end
	-- Resin Wall: once a round, fired by Shared/AutoFire; it holds every dino reaching it.
	if stats.wallSeconds > 0 then
		if not state.wall then
			local inArea, boss = 0, false
			for _, enemy in own do
				if enemy.alive and (enemy.part.Position - tower.position).Magnitude <= stats.range then
					inArea += 1
					boss = boss or enemy.def.boss == true
				end
			end
			if AutoFire.check(state.auto, boss, inArea, Enemies.allSpawned(tower.side), #own) then
				raiseWall(tower)
			end
		end
		local wall = state.wall
		if wall then
			local since = now - wall.raisedAt
			if since >= stats.wallSeconds then
				state.wall = nil
			else
				for _, enemy in own do
					local boss = enemy.def.boss == true
					if enemy.alive and enemy.distance >= wall.at - WALL_CATCH and enemy.distance <= wall.at + 0.5 and Resin.wallHolds(stats.wallSeconds, since, boss) then
						Enemies.stun(enemy, FourX.hardStop(stats.wallSeconds, boss) - since, true)
					end
				end
			end
		end
	end
end

-- An Amber Shield seal broke: Self-Sealing's heal.
local function stepSeals()
	local now = os.clock()
	for _, tower in towers do
		if tower.sealedUntil > 0 and now >= tower.sealedUntil then
			tower.sealedUntil = 0
			if tower.sealHealPercent > 0 and not tower.knockedOut then
				Towers.heal(tower, Resin.sealHeal(tower.maxHp, tower.sealHealPercent))
			end
			tower.sealHealPercent = 0
		end
	end
end

-- A new round: every Last Stand is ready again.
function Towers.newRound()
	local fuel = false
	for _, tower in towers do
		tower.lastStandUsed = false
		local state = tower.resin
		if state then -- once a round: the seal, Resin Wall; Fossil Fuel's stack is per round
			state.sealUsed = false
			state.fossilsRound = 0
			fuel = fuel or state.fuelPercent > 0
			state.fuelPercent = 0
			AutoFire.reset(state.auto)
		end
		local pen = tower.raptor
		if pen then -- once a round: Raptor Swarm / Raptor Charge; Hungry Alpha's stack is per round
			AutoFire.reset(pen.auto)
			pen.takeDowns = 0
		end
		local blimp = tower.blimp
		if blimp then -- once a round: Bombing Run, Paratroopers (last round's go), Airlift
			AutoFire.reset(blimp.auto)
			blimp.roundClock = 0
			blimp.paraDropped = false
			blimp.airliftUsed = false
			Walkers.clear(blimp.paraKey)
		end
		local meteor = tower.meteor
		if meteor then -- once a round played: Extinction Event, Comet Tail
			AutoFire.reset(meteor.auto)
			meteor.extinctionAuto.fired = false
		end
	end
	if fuel then
		refreshAuras()
	end
	Walkers.roundEnd() -- Heals between rounds (PLAN 9g)
end

local NO_DINOS = table.freeze({})

function Towers.step(dt: number)
	stepHealing(dt)
	local live = Enemies.getLive()
	-- Each tower only ever sees its own side's dinos (a targeting filter, #231).
	local bySide: { [number]: { Enemies.Enemy } } = {}
	for _, tower in towers do
		if not bySide[tower.side] then
			bySide[tower.side] = BattleRules.ownDinos(live, tower.side, "tower")
		end
	end
	for _, tower in towers do
		local own = bySide[tower.side] or NO_DINOS
		stepChill(tower, dt, own)
		stepBolt(tower, dt, own)
		stepSorties(tower, dt, own)
		stepField(tower, dt, own)
		stepHood(tower, own)
		stepTow(tower, dt, own)
		stepResin(tower, dt, own)
		stepRaptor(tower, dt, own)
		stepTotem(tower, dt, own)
		stepBlimp(tower, dt, own)
		stepMeteor(tower, dt, own)
	end
	stepAirlifts()
	publishOutlines()
	-- Old Bones (PLAN 9h): a totem's charge aura follows its charge, at most every AURA_REFRESH s.
	auraClock += dt
	if auraDirty and auraClock >= AURA_REFRESH then
		auraDirty, auraClock = false, 0
		refreshAuras()
	end
	stepSeals()
	stepGrid(dt, live)
	stepTar(dt, live)
	Walkers.step(dt) -- walkers land their hits through their towers (PLAN 9g)
	local parties = huntingParties()

	for _, tower in towers do
		local stats = tower.stats
		if stats.rate <= 0 or stats.damage <= 0 or tower.knockedOut or tower.raptor then
			continue -- Quartermaster and anything else that doesn't shoot; trampled towers; a Raptor Pen's raptors bite (Walkers)
		end
		if tower.meteor then
			continue -- a Meteor Beacon calls meteors (stepMeteor)
		end

		tower.cooldown -= dt
		if tower.cooldown > 0 then
			continue
		end

		local own = bySide[tower.side] or NO_DINOS
		local fired = if tower.def.chains
			then fireChain(tower, own)
			elseif hasBirds(tower) then fireFalcon(tower, own)
			elseif tower.def.harpoons then fireBallista(tower, own)
			else fire(tower, own)
		if fired then
			-- Auras don't stack: Hunting Party only counts if it beats the standing ones.
			local aura = math.max(tower.buff.ratePercent, Falcon.huntingParty(tower.base, parties, tower))
			local boost = aura + (if extraRatePercent then extraRatePercent(tower) else 0)
			tower.cooldown += 1 / (stats.rate * (1 + boost / 100))
		else
			tower.cooldown = 0 -- stay ready
		end
	end
end

function Towers.byId(id: number): Tower?
	for _, tower in towers do
		if tower.id == id then
			return tower
		end
	end
	return nil
end

function Towers.positions(): { Vector3 }
	local list = {}
	for _, tower in towers do
		table.insert(list, tower.base)
	end
	return list
end

-- Takes the tower off the map. Refunds are the caller's job.
function Towers.remove(tower: Tower)
	local index = table.find(towers, tower)
	if not index then
		return
	end
	table.remove(towers, index)
	for _, sortie in tower.sorties do
		sortie.part:Destroy()
	end
	Walkers.clear(tower) -- a sold tower's walkers go with it (#315)
	if tower.raptor then
		Walkers.clear(tower.raptor.swarmKey)
	end
	if tower.blimp then
		Walkers.clear(tower.blimp.paraKey) -- its blimp model goes with the mast's model
	end
	tower.model:Destroy()
	refreshAuras()
end

-- Level 1 is the start; each level multiplies tower damage by 1 + TowerDamagePerLevel,
-- and the difficulty's Tower damage x applies on top (TowerStats.damageScale).
function Towers.setLevel(level: number, difficulty: { towerDamageMult: number }?)
	levelScale = TowerStats.damageScale(level, difficulty)
	towerLevel = math.max(1, level)
end

-- Quartermaster income for the round that just ended. Interest is on the
-- team's banked cash; the best Amber Vault applies, they don't stack. `side`: whose
-- Supply Camps (default 1, co-op; a battle pays each side its own, T77).
function Towers.roundIncome(bankedCash: number, side: number?): number
	local income, interest = 0, 0
	for _, tower in towers do
		local perRound = tower.def.incomePerRound or 0
		if perRound > 0 and not tower.knockedOut and tower.side == (side or 1) then
			local stats = tower.stats
			income += perRound * stats.incomeMult
			if stats.interestPercent > 0 then
				interest = math.max(interest, math.min(stats.interestCap, bankedCash * stats.interestPercent / 100))
			end
		end
	end
	-- Bone Bank (PLAN 9h): each standing own-side Bone Totem pays for the charge it holds.
	local bank = 0
	for _, tower in towers do
		if tower.totem and not tower.knockedOut and tower.side == (side or 1) then
			bank += Totem.bank(tower.totem.rules, tower.stats)
		end
	end
	return income + interest + bank
end

export type Airdrop = { base: Vector3, count: number, cash: number, owner: Player?, side: number }

-- Chests each Quartermaster drops this round.
function Towers.airdrops(): { Airdrop }
	local drops = {}
	for _, tower in towers do
		if tower.blimp then
			-- Spotter Blimp Cargo (PLAN 9h): its crates land below the blimp (none with Lap chests).
			local count = Blimp.roundCrates(tower.stats)
			if count > 0 then
				table.insert(drops, { base = tower.position, count = count, cash = tower.stats.chestCash, owner = tower.owner, side = tower.side })
				crateHeal(tower, tower.position, count)
			end
		elseif tower.stats.chests > 0 and tower.stats.chestCash > 0 and not tower.knockedOut then
			table.insert(drops, { base = tower.base, count = tower.stats.chests, cash = tower.stats.chestCash, owner = tower.owner, side = tower.side })
		end
	end
	return drops
end

-- Between matches: every tower off the map.
function Towers.clearAll()
	for i = #towers, 1, -1 do
		for _, sortie in towers[i].sorties do
			sortie.part:Destroy()
		end
		towers[i].model:Destroy()
		towers[i] = nil
	end
	levelScale = 1
	towerLevel = 1
	table.clear(gridTimers)
	table.clear(stungAt)
	table.clear(pendingAirlifts)
	Walkers.clearAll()
	publishOutlines()
end

-- A battle side is out (PLAN T77, DECISIONS #213): its towers come off the map.
function Towers.removeSide(side: number)
	for i = #towers, 1, -1 do
		if towers[i].side == side then
			Towers.remove(towers[i])
		end
	end
end

-- The nearest tower of `key` to `position` (Studio aids, PLAN 9g).
local function nearestOf(key: string, position: Vector3): Tower?
	local best, bestD = nil, math.huge
	for _, tower in towers do
		local d = (tower.base - position).Magnitude
		if tower.key == key and d < bestD then
			best, bestD = tower, d
		end
	end
	return best
end

-- Studio `firenow <tower>` (Shared/StudioOnly, PLAN 9g): the nearest tower of `key` fires
-- its once-a-round / timed effects now. Returns what it fired ("" = nothing).
function Towers.fireNow(key: string, position: Vector3): string
	local tower = nearestOf(key, position)
	if not tower then
		return ""
	end
	local fired = {}
	local own = BattleRules.ownDinos(Enemies.getLive(), tower.side, "tower")
	if tower.resin then
		if tower.stats.entombAllEvery > 0 then
			entombAll(tower, own)
			table.insert(fired, "Amber Age")
		end
		if tower.stats.wallSeconds > 0 then
			raiseWall(tower)
			table.insert(fired, "Resin Wall")
		end
	end
	if tower.raptor then
		if tower.stats.swarm then
			releaseSwarm(tower)
			table.insert(fired, "Raptor Swarm")
		end
		if tower.stats.charge then
			startCharge(tower)
			table.insert(fired, "Raptor Charge")
		end
	end
	blimpFireNow(tower, fired) -- Spotter Blimp (PLAN 9h T125b)
	meteorFireNow(tower, fired) -- Meteor Beacon (PLAN 9i T127)
	local totem = tower.totem
	if totem then -- fills it now (PLAN 9h)
		totem.pending += Totem.add(totem.rules, tower.stats, Totem.full(tower.stats) - totem.rules.charge)
		table.insert(fired, "full charge")
	end
	return table.concat(fired, ", ")
end

-- Studio `charge <n>` (PLAN 9h): sets the nearest Bone Totem's charge (at or over full it fires).
function Towers.setCharge(n: number, position: Vector3): boolean
	local tower = nearestOf("TOTEM", position)
	local totem = tower and tower.totem
	if not (tower and totem) then
		return false
	end
	totem.rules.charge = 0
	totem.pending += Totem.add(totem.rules, tower.stats, n)
	auraDirty = true
	return true
end

-- Studio `fossils <n>`: the nearest Amber Resin Cannon's match fossil count.
function Towers.setFossils(n: number, position: Vector3): boolean
	local tower = nearestOf("RESIN", position)
	if not (tower and tower.resin) then
		return false
	end
	tower.resin.fossils = n
	return true
end

function Towers.all(): { Tower }
	return towers
end

return Towers
