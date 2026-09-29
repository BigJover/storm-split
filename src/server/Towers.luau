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
	amounts take the highest, and yes/no flags combine with OR.

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
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Placement = require(Shared:WaitForChild("Placement"))
local TowerLook = require(Shared:WaitForChild("TowerLook"))
local Upgrades = require(Shared:WaitForChild("Upgrades"))

local Effects = require(script.Parent.Effects)
local Enemies = require(script.Parent.Enemies)
local Hazards = require(script.Parent.Hazards)

local Towers = {}

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
}

-- What nearby auras give this tower right now.
type Buff = {
	ratePercent: number,
	damagePercent: number,
	piercesArmor: boolean,
	discountPercent: number, -- off its upgrades (Logistics)
	sellRefund: number, -- 0 = the normal SellRefund
}

export type Tower = {
	id: number,
	key: string,
	def: any,
	owner: Player?, -- who built it; nil if they've left
	base: Vector3, -- on the build floor; what Placement checks against
	position: Vector3,
	muzzle: Vector3,
	pathTiers: { number },
	stats: Stats,
	buff: Buff,
	cooldown: number,
	freezeTimer: number,
	model: Model,
}

-- Visuals only.
local BOMBLET_COLOR = Color3.fromRGB(255, 190, 90)

local towers: { Tower } = {}
local towerFolder: Instance
local nextId = 0
local onPop: ((Player) -> ())? = nil
local levelScale = 1 -- damage multiplier from the team's level
local extraRatePercent: ((Tower) -> number)? = nil -- boosts from outside towers (hero Overdrive)

local function credit(owner: Player?, killed: boolean)
	if killed and owner and owner.Parent and onPop then
		onPop(owner)
	end
end

------------------------------------------------------------------ stats

local MULTIPLIERS = { "damageMult", "rateMult", "targetsMult", "rangeMult", "armoredMult", "bossMult", "splashMult", "incomeMult" }
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
}
local FLAGS = { "piercesArmor", "stunsBosses", "auraPiercesArmor", "slowsBosses", "freezeHoldsBosses", "stripsArmor" }

local function computeStats(def, pathTiers: { number }): Stats
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
	}
end

local NO_BUFF: Buff = table.freeze({ ratePercent = 0, damagePercent = 0, piercesArmor = false, discountPercent = 0, sellRefund = 0 })

local function hasAura(s: Stats): boolean
	return s.auraRatePercent > 0 or s.auraDamagePercent > 0 or s.auraPiercesArmor or s.discountPercent > 0 or s.sellRefund > 0
end

-- Recomputed whenever a tower is placed, upgraded or removed. The shop panel
-- reads Discount / RefundRate from the tower's body.
local function refreshAuras()
	for _, tower in towers do
		local rate, damage, pierce, discount, refund = 0, 0, false, 0, 0
		for _, source in towers do
			local s = source.stats
			if source ~= tower and hasAura(s) then
				local offset = tower.base - source.base
				if Vector2.new(offset.X, offset.Z).Magnitude <= s.range then
					rate = math.max(rate, s.auraRatePercent)
					damage = math.max(damage, s.auraDamagePercent)
					pierce = pierce or s.auraPiercesArmor
					discount = math.max(discount, s.discountPercent)
					refund = math.max(refund, s.sellRefund)
				end
			end
		end
		tower.buff = if rate > 0 or damage > 0 or pierce or discount > 0 or refund > 0
			then { ratePercent = rate, damagePercent = damage, piercesArmor = pierce, discountPercent = discount, sellRefund = refund }
			else NO_BUFF
		local body = tower.model.PrimaryPart
		if body then
			body:SetAttribute("Discount", discount)
			body:SetAttribute("RefundRate", math.max(Config.Tuning.SellRefund, refund))
		end
	end
end

-- The crossover rule lives in Shared/Upgrades so the client can grey out buttons.
function Towers.canUpgrade(tower: Tower, pathIndex: number): boolean
	local path = tower.def.paths[pathIndex]
	return path ~= nil and Upgrades.check(tower.pathTiers, pathIndex, #path.tiers) == "ok"
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

------------------------------------------------------------------ public

export type Hooks = {
	onPop: ((Player) -> ())?,
	extraRatePercent: ((Tower) -> number)?,
}

function Towers.init(folder: Instance, hooks: Hooks?)
	towerFolder = folder
	onPop = hooks and hooks.onPop
	extraRatePercent = hooks and hooks.extraRatePercent
end

-- Callers check Placement first (Shop does); this only builds.
function Towers.place(key: string, position: Vector3, owner: Player?): Tower?
	local def = Config.Towers[key]
	if not def then
		warn(`[Towers] Unknown tower '{key}'`)
		return nil
	end

	local base = Placement.ground(position)
	local model = TowerLook.build(key, def.range, base)
	model.Parent = towerFolder

	nextId += 1
	local pathTiers = { 0, 0, 0 }
	local tower: Tower = {
		id = nextId,
		key = key,
		def = def,
		owner = owner,
		base = base,
		position = base + Vector3.new(0, TowerLook.BODY_HEIGHT / 2, 0),
		muzzle = base + Vector3.new(0, TowerLook.BODY_HEIGHT - 0.5, 0),
		pathTiers = pathTiers,
		stats = computeStats(def, pathTiers),
		buff = NO_BUFF,
		cooldown = 0,
		freezeTimer = 0,
		model = model,
	}
	table.insert(towers, tower)
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
	tower.stats = computeStats(tower.def, tower.pathTiers)
	TowerLook.refresh(tower.model, tower.stats.range, tower.pathTiers, swapStage(tower))
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
		if enemy ~= primary and canTarget(tower, enemy) then
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

local function hit(tower: Tower, enemy: Enemies.Enemy, damage: number)
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
	Enemies.stun(enemy, stats.stunSeconds, stats.stunsBosses)
	Enemies.knockback(enemy, stats.knockback)
	credit(tower.owner, Enemies.damage(enemy, damage, pierce))
end

-- Bomblets land along the track around `distance`, alternating behind and
-- ahead of it. Each generation throws the same number again, weaker.
local function bomblets(tower: Tower, distance: number, damage: number, generation: number, live)
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
			if canTarget(tower, enemy) and math.abs(enemy.distance - centre) <= spread / 2 then
				hit(tower, enemy, blastDamage)
			end
		end
		Effects.part(Vector3.one * 2, CFrame.new(Enemies.pointAt(centre) + Vector3.new(0, 1, 0)), BOMBLET_COLOR, 0.15, Enum.PartType.Ball)
		bomblets(tower, centre, blastDamage, generation + 1, live)
	end
end

local function addBurn(tower: Tower, primary: Enemies.Enemy)
	local stats = tower.stats
	if primary.def.flying then
		return
	end
	Hazards.burn(primary.distance, stats.splashRadius, stats.burnDps * levelScale, stats.burnSeconds, piercing(tower), tower.owner)
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

		local hits = if stats.lineHits > 1 then lineTargets(tower, target, live) else splashTargets(tower, target, live)
		for _, enemy in hits do
			hit(tower, enemy, damage)
		end
		bomblets(tower, targetDistance, damage, 1, live)

		Effects.tracer(tower.muzzle, targetPosition, TowerLook.COLORS[tower.key] or Color3.new(1, 1, 1))
	end
	return fired
end

-- Visuals only.
local FREEZE_COLOR = Color3.fromRGB(150, 220, 255)
-- How long a chill lasts after the last frame an enemy spent in range (plus
-- any Permafrost linger). Keeps the chill continuous between frames.
local CHILL_REFRESH = 0.25

-- Chillers: chill everything in range every frame; Freeze pulses hard stops.
local function stepChill(tower: Tower, dt: number, live)
	local stats = tower.stats
	if stats.slowPercent <= 0 and stats.freezeEvery <= 0 then
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
				Enemies.stun(enemy, stats.freezeSeconds, stats.freezeHoldsBosses)
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

-- Called every Heartbeat by Main.
-- NOTE: fires at most once per frame (times `shots`), so fire rates above
-- ~60/s are capped.
function Towers.step(dt: number)
	local live = Enemies.getLive()
	for _, tower in towers do
		stepChill(tower, dt, live)
	end

	for _, tower in towers do
		local stats = tower.stats
		if stats.rate <= 0 or stats.damage <= 0 then
			continue -- Quartermaster and anything else that doesn't shoot
		end

		tower.cooldown -= dt
		if tower.cooldown > 0 then
			continue
		end

		if fire(tower, live) then
			local boost = tower.buff.ratePercent + (if extraRatePercent then extraRatePercent(tower) else 0)
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
	tower.model:Destroy()
	refreshAuras()
end

-- Level 1 is the start; each level multiplies tower damage by 1 + TowerDamagePerLevel.
function Towers.setLevel(level: number)
	levelScale = (1 + Config.Tuning.TowerDamagePerLevel) ^ math.max(0, level - 1)
end

-- Quartermaster income for the round that just ended. Interest is on the
-- team's banked cash; the best Storm Bank applies, they don't stack.
function Towers.roundIncome(bankedCash: number): number
	local income, interest = 0, 0
	for _, tower in towers do
		local perRound = tower.def.incomePerRound or 0
		if perRound > 0 then
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
		if tower.stats.chests > 0 and tower.stats.chestCash > 0 then
			table.insert(drops, { base = tower.base, count = tower.stats.chests, cash = tower.stats.chestCash, owner = tower.owner })
		end
	end
	return drops
end

-- Between matches: every tower off the map.
function Towers.clearAll()
	for i = #towers, 1, -1 do
		towers[i].model:Destroy()
		towers[i] = nil
	end
	levelScale = 1
end

function Towers.all(): { Tower }
	return towers
end

return Towers
