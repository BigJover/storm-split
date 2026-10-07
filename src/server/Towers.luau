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
	  stunSeconds, knockback  on every enemy it damages
	  burnDps/burnSeconds    leaves a burning patch on the track
	  bomblets           each shell throws this many smaller blasts
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
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
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

local Effects = require(script.Parent.Effects)
local Enemies = require(script.Parent.Enemies)
local Hazards = require(script.Parent.Hazards)
local Health = require(script.Parent.Health)

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
}

export type Tower = {
	id: number,
	key: string,
	def: any,
	owner: Player?, -- who built it; nil if they've left
	side: number, -- the side it was built on (Shared/Sides; co-op = 1); its pool and track effects use that track
	base: Vector3, -- on the build floor; what Placement checks against
	position: Vector3,
	muzzle: Vector3,
	pathTiers: { number },
	stats: Stats,
	buff: Buff,
	cooldown: number,
	freezeTimer: number,
	hp: number,
	maxHp: number,
	knockedOut: boolean, -- trampled at 0 HP until repaired
	lastStandUsed: boolean, -- a Field Hospital's Last Stand has saved a tower this round
	boltTimer: number, -- Storm Coil: seconds toward its next Judgement Bolt
	static: { [any]: boolean }, -- Storm Coil Static Shock: dinos its last strike charged (weak keys)
	sorties: { Sortie }, -- Falcon Roost: birds out of the roost
	dived: { [any]: boolean }, -- Falcon Roost Power Dive: dinos it has dived on (weak keys)
	towTimer: number, -- Harpoon Ballista: seconds toward its next Tow Line pull
	poolAt: number, -- Tar Pit: distance along the track of the pool's centre
	eruptTimer: number, -- Tar Pit: seconds toward its next Eruption
	tracksUntil: number, -- Tar Pit: Tar Tracks' footprints last until then (os.clock)
	model: Model,
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
local onSink: ((cash: number, chestCash: number, position: Vector3) -> ())? = nil -- Dig Site pay
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

------------------------------------------------------------------ stats

local NO_BUFF: Buff =
	table.freeze({ ratePercent = 0, damagePercent = 0, piercesArmor = false, discountPercent = 0, sellRefund = 0, resistPercent = 0, hpPercent = 0, arcPercent = 0, slowedPercent = 0 })
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
end

local function covers(source: Tower, point: Vector3): boolean
	local offset = point - source.base
	return Vector2.new(offset.X, offset.Z).Magnitude <= source.stats.range
end

-- Recomputed whenever a tower is placed, upgraded or removed. The shop panel
-- reads Discount / RefundRate from the tower's body.
local function refreshAuras()
	for _, tower in towers do
		local rate, damage, pierce, discount, refund, resist, hpBonus, arc, slowed = 0, 0, false, 0, 0, 0, 0, 0, 0
		for _, source in towers do
			local s = source.stats
			if not source.knockedOut and hasAura(s) and covers(source, tower.base) then
				-- An Armory's resistance covers itself too; the other auras are for others.
				-- Armory and Field Hospital auras skip a tower that can't be damaged (#148).
				if not tower.def.untouchable then
					resist = math.max(resist, s.resistPercent)
				end
				if source ~= tower then
					rate = math.max(rate, s.auraRatePercent)
					damage = math.max(damage, s.auraDamagePercent)
					pierce = pierce or s.auraPiercesArmor
					discount = math.max(discount, s.discountPercent)
					refund = math.max(refund, s.sellRefund)
					hpBonus = if tower.def.untouchable then 0 else math.max(hpBonus, s.auraHpPercent)
					arc = math.max(arc, s.auraArcPercent)
					slowed = math.max(slowed, s.auraSlowedPercent)
				end
			end
		end
		tower.buff = if rate > 0 or damage > 0 or pierce or discount > 0 or refund > 0 or resist > 0 or hpBonus > 0 or arc > 0 or slowed > 0
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
end

-- The crossover rule lives in Shared/Upgrades so the client can grey out buttons.
-- A trampled tower can't be upgraded until it's repaired.
function Towers.canUpgrade(tower: Tower, pathIndex: number): boolean
	local path = tower.def.paths[pathIndex]
	return path ~= nil and not tower.knockedOut and Upgrades.check(tower.pathTiers, pathIndex, #path.tiers) == "ok"
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

local function setKnockedOut(tower: Tower, on: boolean)
	if tower.knockedOut == on then
		return
	end
	tower.knockedOut = on
	tower.cooldown = 0
	tower.freezeTimer = 0
	TowerLook.setKnockedOut(tower.model, on)
	refreshAuras() -- its auras go (and come back on repair)
end

-- Last Stand: the first standing hospital covering this tower that hasn't
-- saved one yet this round spends its save. Returns that hospital, or nil.
local function lastStand(tower: Tower): Tower?
	for _, source in towers do
		if source.stats.lastStand and not source.lastStandUsed and not source.knockedOut and covers(source, tower.base) then
			source.lastStandUsed = true
			return source
		end
	end
	return nil
end

-- Hurts a standing tower, less its resistance. At 0 HP it's trampled.
-- `source` is who or what did it (kept for PvP later). Returns the damage dealt.
-- A tower that can't be damaged (DECISIONS #148) takes nothing and shows nothing.
function Towers.damage(tower: Tower, amount: number, source: any?): number
	if not Combat.canBeHit(tower.def, tower.knockedOut) or amount <= 0 or not table.find(towers, tower) then
		return 0
	end
	local sources = if resistOf then table.clone(resistOf(tower)) else {}
	table.insert(sources, tower.buff.resistPercent) -- an Armory in range
	local resist = Combat.combineResist(sources)
	local dealt = Combat.towerDealt(tower.def, tower.hp, amount, resist)
	tower.hp -= dealt
	local saver = if tower.hp <= 0 then lastStand(tower) else nil
	local outcome = Combat.hitOutcome(tower.hp, dealt, saver ~= nil)
	if outcome == "saved" then
		tower.hp = 1 -- a Field Hospital's Last Stand: not this time
	elseif outcome == "trampled" then
		tower.hp = 0
		setKnockedOut(tower, true)
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

-- The strongest Armory resistance covering a point (a hunter standing there).
function Towers.resistAt(position: Vector3): number
	local best = 0
	for _, source in towers do
		if not source.knockedOut and source.stats.resistPercent > 0 and covers(source, position) then
			best = math.max(best, source.stats.resistPercent)
		end
	end
	return best
end

-- A dino just bit something standing at `position`: the strongest Thorn
-- Plating covering it bites back (pierces armour, scales with the team's
-- level, kill credited to the Armory's owner), and Bulwark stuns the biter
-- (not bosses). Called by DinoAttacks through its onBite hook.
function Towers.bitten(enemy: Enemies.Enemy, position: Vector3)
	local thorns, thornsOwner, stun = 0, nil, 0
	for _, source in towers do
		local s = source.stats
		if not source.knockedOut and (s.thornsDamage > 0 or s.stunBitersSeconds > 0) and covers(source, position) then
			if s.thornsDamage > thorns then
				thorns, thornsOwner = s.thornsDamage, source.owner
			end
			stun = math.max(stun, s.stunBitersSeconds)
		end
	end
	if stun > 0 then
		Enemies.stun(enemy, stun, false)
	end
	if thorns > 0 then
		credit(thornsOwner, Enemies.damage(enemy, thorns * levelScale, true))
	end
end

export type HunterGear = { recoilMult: number, reloadMult: number, spreadMult: number, ratePercent: number }

-- What an Outfitter Armory covering this point does for a hunter's gun: the
-- strongest of each buff (auras don't stack).
function Towers.hunterGearAt(position: Vector3): HunterGear
	local gear = { recoilMult = 1, reloadMult = 1, spreadMult = 1, ratePercent = 0 }
	for _, source in towers do
		local s = source.stats
		if not source.knockedOut and covers(source, position) then
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
			if tower.def.paths[pathIndex].tiers[t].swapsModel then
				reached += 1
			end
		end
		stage = math.max(stage, reached)
	end
	return stage
end

------------------------------------------------------------------ Tar Pit pool

local POOL_STEP = 3 -- visuals only: studs between the pool's drawn points

-- The range ring: a Tar Pit's range is its pool's length of track, drawn as the pool
-- itself, so it only gets a ring when it has an aura (Tar Totem).
local function ringRange(def, stats: Stats): number
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
	onSink: ((cash: number, chestCash: number, position: Vector3) -> ())?,
}

function Towers.init(folder: Instance, hooks: Hooks?)
	towerFolder = folder
	onPop = hooks and hooks.onPop
	extraRatePercent = hooks and hooks.extraRatePercent
	resistOf = hooks and hooks.resistOf
	onSink = hooks and hooks.onSink
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
		side = side or 1,
		base = base,
		position = base + Vector3.new(0, TowerLook.BODY_HEIGHT / 2, 0),
		muzzle = base + Vector3.new(0, TowerLook.BODY_HEIGHT - 0.5, 0),
		pathTiers = pathTiers,
		stats = stats,
		buff = NO_BUFF,
		cooldown = 0,
		freezeTimer = 0,
		hp = maxHp,
		maxHp = maxHp,
		knockedOut = false,
		lastStandUsed = false,
		boltTimer = 0,
		static = setmetatable({}, { __mode = "k" }) :: any,
		sorties = {},
		dived = setmetatable({}, { __mode = "k" }) :: any,
		towTimer = 0,
		poolAt = if def.onTrack then Enemies.trackDistanceNear(base, side) else 0,
		eruptTimer = 0,
		tracksUntil = 0,
		model = model,
	}
	table.insert(towers, tower)
	showPool(tower)
	showHealth(tower)
	refreshAuras()
	return tower
end

-- Returns true if the upgrade was applied. Does NOT charge cash — the caller
-- (Shop) must Economy.trySpend first. Keeps this module free of money.
function Towers.upgrade(tower: Tower, pathIndex: number): boolean
	if not Towers.canUpgrade(tower, pathIndex) then
		return false
	end
	tower.pathTiers[pathIndex] += 1
	tower.stats = TowerStats.compute(tower.def, tower.pathTiers)
	-- The HP an upgrade adds to the max is added to current HP too.
	local maxHp = Combat.towerMaxHp(tower.def, tower.pathTiers, tower.buff.hpPercent)
	tower.hp = math.min(maxHp, tower.hp + (maxHp - tower.maxHp))
	tower.maxHp = maxHp
	TowerLook.refresh(tower.model, ringRange(tower.def, tower.stats), tower.pathTiers, swapStage(tower))
	showPool(tower) -- Wide Pool / Tar Lake lengthen it
	TowerLook.setLantern(tower.model, tower.stats.rescueRespawnMult > 0) -- Rescue Beacon
	showHealth(tower)
	refreshAuras()
	return true
end

------------------------------------------------------------------ targeting

local function piercing(tower: Tower): boolean
	return tower.stats.piercesArmor or tower.buff.piercesArmor
end

-- Can this tower both reach and hurt this enemy?
local function canTarget(tower: Tower, enemy: Enemies.Enemy): boolean
	if enemy.def.flying and not tower.def.hitsAir then
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
local function hit(tower: Tower, enemy: Enemies.Enemy, damage: number, breaks: number?)
	local stats = tower.stats
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
	if tower.buff.slowedPercent > 0 and Enemies.isSlowed(enemy) then
		damage *= 1 + tower.buff.slowedPercent / 100 -- Tar Totem
	end
	Enemies.stun(enemy, stats.stunSeconds, stats.stunsBosses)
	Enemies.knockback(enemy, stats.knockback)
	local b = if breaks and breaks > 1 then Enemies.breaksFor(enemy, breaks, towerLevel, false) else 1
	credit(tower.owner, Enemies.damage(enemy, damage, pierce, b))
end

-- Bomblets land along the track (side `trackSide`'s) around `distance`, alternating behind
-- and ahead of it. Each generation throws the same number again, weaker.
local function bomblets(tower: Tower, trackSide: number, distance: number, damage: number, generation: number, live)
	local stats = tower.stats
	if generation > stats.bombletGenerations or stats.bomblets <= 0 then
		return
	end
	local spread = Config.Tuning.BombletSpread or 0
	local share = Config.Tuning.BombletDamage or 0
	local blastDamage = damage * share
	for i = 1, stats.bomblets do
		local side = if i % 2 == 1 then -1 else 1
		local centre = distance + side * spread * math.ceil(i / 2)
		for _, enemy in live do
			if enemy.side == trackSide and canTarget(tower, enemy) and math.abs(enemy.distance - centre) <= spread / 2 then
				hit(tower, enemy, blastDamage)
			end
		end
		Effects.part(Vector3.one * 2, CFrame.new(Enemies.pointAt(centre, trackSide) + Vector3.new(0, 1, 0)), BOMBLET_COLOR, 0.15, Enum.PartType.Ball)
		bomblets(tower, trackSide, centre, blastDamage, generation + 1, live)
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
		bomblets(tower, target.side, targetDistance, damage, 1, live)

		Effects.tracer(tower.muzzle, targetPosition, TowerLook.COLORS[tower.key] or Color3.new(1, 1, 1))
	end
	return fired
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
	Enemies.stun(target, stats.stunSeconds, false) -- Thunderclap: the first dino only
	for _, link in links do
		local enemy = list[link.index]
		local from = if link.from then list[link.from].part.Position else tower.muzzle
		Effects.tracer(from, enemy.part.Position, ARC_COLOR)
		coilHit(tower, enemy, damage * link.x)
	end
	return true
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
local gridTimer = 0
local function stepGrid(dt: number, live)
	local striker, coils = nil, 0
	for _, tower in towers do
		if isCoil(tower) then
			coils += 1
			if tower.stats.powerGrid and (striker == nil or coilDamage(tower) > coilDamage(striker)) then
				striker = tower
			end
		end
	end
	if not striker then
		gridTimer = 0
		return
	end
	local every = Config.Tuning.PowerGridEvery
	gridTimer += dt
	if gridTimer < every then
		return
	end
	gridTimer -= every
	local rangeMult, damageMult = StormCoil.grid(coils)
	local areas = {}
	for _, tower in towers do
		if isCoil(tower) then
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
local function stepSorties(tower: Tower, dt: number)
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
					Effects.tracer(sortie.at + Vector3.new(0, 6, 0), sortie.at, BIRD_COLOR)
					falconHit(tower, enemy, damage, stats.sizeBreaks)
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
		if enemy.alive and enemy.def.boss and (enemy.part.Position - tower.position).Magnitude <= tower.stats.range then
			Enemies.mark(enemy, percent, HOOD_REFRESH)
		end
	end
end

-- Hunting Party: every roost with the aura and a bird out, for Falcon.huntingParty.
local function huntingParties(): { Falcon.Party }
	local parties = {}
	for _, tower in towers do
		if tower.stats.diveAuraRatePercent > 0 and #tower.sorties > 0 then
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
	local list, distances, points = {}, {}, {}
	for _, enemy in live do
		if enemy.alive and canTarget(tower, enemy) and (enemy.part.Position - tower.position).Magnitude <= stats.range then
			table.insert(list, enemy)
			table.insert(distances, enemy.distance)
			table.insert(points, enemy.part.Position)
		end
	end
	local picks = Ballista.volley(distances, stats.shots, stats.chainHarpoons)
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
		for _, enemy in struck do
			hit(tower, enemy, damage, stats.sizeBreaks)
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
		if (enemy.part.Position - tower.position).Magnitude <= range then
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
			if pit.side == enemy.side and TarPit.contains(enemy.distance, pit.poolAt, pit.stats.range) then
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
				if other.side == enemy.side and now < other.tracksUntil and TarPit.onTracks(enemy.distance, other.poolAt, other.stats.range, tuning.TarTracksLength) then
					Enemies.tar(enemy, other.stats.tracksSlowPercent, TAR_REFRESH)
				end
			end
			continue
		end
		lastPool[enemy] = pit
		local stats = pit.stats
		Enemies.tar(enemy, stats.slowPercent, TAR_REFRESH)
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
						onSink(stats.sinkCash, stats.sinkChestCash, Placement.ground(position))
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

-- The strongest standing hospital's heal (and revive) rate covering a point.
local function healRates(point: Vector3): (number, number)
	local heal, revive = 0, 0
	for _, source in towers do
		local s = source.stats
		if s.healPerSecond > 0 and not source.knockedOut and covers(source, point) then
			heal = math.max(heal, s.healPerSecond)
			if s.revives then
				revive = math.max(revive, s.healPerSecond * s.reviveSpeed)
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
		local heal, revive = healRates(tower.base)
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
			local heal = healRates(root.Position)
			if heal > 0 then
				Health.heal(player, heal * dt)
			end
		end
	end
end

export type MedKitDrop = { base: Vector3, count: number, heal: number }

-- Med kits each standing hospital drops this round.
function Towers.medKits(): { MedKitDrop }
	local drops = {}
	for _, tower in towers do
		local s = tower.stats
		if s.medKits > 0 and s.medKitHeal > 0 and not tower.knockedOut then
			table.insert(drops, { base = tower.base, count = s.medKits, heal = s.medKitHeal })
		end
	end
	return drops
end

-- A standing Rescue Beacon: where downed hunters come back, and the share of
-- the respawn time they wait. nil if there's none.
function Towers.rescueBeacon(): (Vector3?, number)
	local best, mult = nil, 1
	for _, tower in towers do
		local m = tower.stats.rescueRespawnMult
		if m > 0 and not tower.knockedOut and (best == nil or m < mult) then
			best, mult = tower.base, m
		end
	end
	return best, mult
end

-- A new round: every Last Stand is ready again.
function Towers.newRound()
	for _, tower in towers do
		tower.lastStandUsed = false
	end
end

function Towers.step(dt: number)
	stepHealing(dt)
	local live = Enemies.getLive()
	for _, tower in towers do
		stepChill(tower, dt, live)
		stepBolt(tower, dt, live)
		stepSorties(tower, dt)
		stepHood(tower, live)
		stepTow(tower, dt, live)
	end
	stepGrid(dt, live)
	stepTar(dt, live)
	local parties = huntingParties()

	for _, tower in towers do
		local stats = tower.stats
		if stats.rate <= 0 or stats.damage <= 0 or tower.knockedOut then
			continue -- Quartermaster and anything else that doesn't shoot; trampled towers
		end

		tower.cooldown -= dt
		if tower.cooldown > 0 then
			continue
		end

		local fired = if tower.def.chains
			then fireChain(tower, live)
			elseif hasBirds(tower) then fireFalcon(tower, live)
			elseif tower.def.harpoons then fireBallista(tower, live)
			else fire(tower, live)
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
-- team's banked cash; the best Amber Vault applies, they don't stack.
function Towers.roundIncome(bankedCash: number): number
	local income, interest = 0, 0
	for _, tower in towers do
		local perRound = tower.def.incomePerRound or 0
		if perRound > 0 and not tower.knockedOut then
			local stats = tower.stats
			income += perRound * stats.incomeMult
			if stats.interestPercent > 0 then
				interest = math.max(interest, math.min(stats.interestCap, bankedCash * stats.interestPercent / 100))
			end
		end
	end
	return income + interest
end

export type Airdrop = { base: Vector3, count: number, cash: number, owner: Player? }

-- Chests each Quartermaster drops this round.
function Towers.airdrops(): { Airdrop }
	local drops = {}
	for _, tower in towers do
		if tower.stats.chests > 0 and tower.stats.chestCash > 0 and not tower.knockedOut then
			table.insert(drops, { base = tower.base, count = tower.stats.chests, cash = tower.stats.chestCash, owner = tower.owner })
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
	gridTimer = 0
end

function Towers.all(): { Tower }
	return towers
end

return Towers
