--[[
	Towers: placement, stats, abilities, targeting, firing.

	A tower is a plain table of state (ARCHITECTURE.md §5.1 — the model is a
	view, never the source of truth). Upgrades change `pathTiers` and
	recompute cached stats; the model can be swapped freely without losing
	anything.

	Towers never touch cash (ARCHITECTURE.md §5.4). The shop pays first, then
	calls place() / upgrade() / remove().

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
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Placement = require(Shared:WaitForChild("Placement"))
local TowerLook = require(Shared:WaitForChild("TowerLook"))
local Upgrades = require(Shared:WaitForChild("Upgrades"))

local Enemies = require(script.Parent.Enemies)

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
}

-- What nearby auras give this tower right now.
type Buff = { ratePercent: number, damagePercent: number, piercesArmor: boolean }

export type Tower = {
	id: number,
	key: string,
	def: any,
	base: Vector3, -- on the build floor; what Placement checks against
	position: Vector3,
	muzzle: Vector3,
	pathTiers: { number },
	stats: Stats,
	buff: Buff,
	cooldown: number,
	model: Model,
}

type Burn = { distance: number, reach: number, dps: number, untilTime: number, piercesArmor: boolean }

-- Visuals only.
local TRACER_LIFETIME = 0.06
local BURN_COLOR = Color3.fromRGB(255, 110, 40)
local BOMBLET_COLOR = Color3.fromRGB(255, 190, 90)

local towers: { Tower } = {}
local burns: { Burn } = {}
local towerFolder: Instance
local nextId = 0

------------------------------------------------------------------ stats

local MULTIPLIERS = { "damageMult", "rateMult", "targetsMult", "rangeMult", "armoredMult", "bossMult", "splashMult" }
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
}
local FLAGS = { "piercesArmor", "stunsBosses", "auraPiercesArmor" }

local function computeStats(def, pathTiers: { number }): Stats
	local mult: { [string]: number } = {}
	for _, field in MULTIPLIERS do
		mult[field] = 1
	end
	local high: { [string]: number } = { shots = 1, lineHits = 1 }
	local flag: { [string]: boolean } = {}

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
	}
end

local NO_BUFF: Buff = table.freeze({ ratePercent = 0, damagePercent = 0, piercesArmor = false })

-- Recomputed whenever a tower is placed, upgraded or removed.
local function refreshAuras()
	for _, tower in towers do
		local rate, damage, pierce = 0, 0, false
		for _, source in towers do
			local s = source.stats
			if source ~= tower and (s.auraRatePercent > 0 or s.auraDamagePercent > 0 or s.auraPiercesArmor) then
				local offset = tower.base - source.base
				if Vector2.new(offset.X, offset.Z).Magnitude <= s.range then
					rate = math.max(rate, s.auraRatePercent)
					damage = math.max(damage, s.auraDamagePercent)
					pierce = pierce or s.auraPiercesArmor
				end
			end
		end
		tower.buff = if rate > 0 or damage > 0 or pierce
			then { ratePercent = rate, damagePercent = damage, piercesArmor = pierce }
			else NO_BUFF
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

------------------------------------------------------------------ visuals

local function effect(size: Vector3, cframe: CFrame, color: Color3, lifetime: number, shape: Enum.PartType?)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = color
	if shape then
		part.Shape = shape
	end
	part.Size = size
	part.CFrame = cframe
	part.Parent = towerFolder
	Debris:AddItem(part, lifetime)
	return part
end

local function tracer(from: Vector3, to: Vector3, color: Color3)
	local length = (to - from).Magnitude
	if length < 0.1 then
		return
	end
	effect(Vector3.new(0.15, 0.15, length), CFrame.lookAt((from + to) / 2, to), color, TRACER_LIFETIME)
end

------------------------------------------------------------------ public

function Towers.init(folder: Instance)
	towerFolder = folder
end

-- Callers check Placement first (Shop does); this only builds.
function Towers.place(key: string, position: Vector3): Tower?
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
		base = base,
		position = base + Vector3.new(0, TowerLook.BODY_HEIGHT / 2, 0),
		muzzle = base + Vector3.new(0, TowerLook.BODY_HEIGHT - 0.5, 0),
		pathTiers = pathTiers,
		stats = computeStats(def, pathTiers),
		buff = NO_BUFF,
		cooldown = 0,
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
	Enemies.damage(enemy, damage, pierce)
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
		effect(Vector3.one * 2, CFrame.new(Enemies.pointAt(centre) + Vector3.new(0, 1, 0)), BOMBLET_COLOR, 0.15, Enum.PartType.Ball)
		bomblets(tower, centre, blastDamage, generation + 1, live)
	end
end

local function addBurn(tower: Tower, primary: Enemies.Enemy)
	local stats = tower.stats
	if stats.burnDps <= 0 or stats.burnSeconds <= 0 or primary.def.flying then
		return
	end
	local reach = math.max(stats.splashRadius, 1)
	table.insert(burns, {
		distance = primary.distance,
		reach = reach,
		dps = stats.burnDps,
		untilTime = os.clock() + stats.burnSeconds,
		piercesArmor = piercing(tower),
	})
	local ground = Enemies.pointAt(primary.distance)
	effect(
		Vector3.new(0.3, reach * 2, reach * 2),
		CFrame.new(ground + Vector3.new(0, 0.45, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		BURN_COLOR,
		stats.burnSeconds,
		Enum.PartType.Cylinder
	).Transparency = 0.5
end

local function fire(tower: Tower, live): boolean
	local stats = tower.stats
	local damage = stats.damage * (1 + tower.buff.damagePercent / 100)
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

		tracer(tower.muzzle, targetPosition, TowerLook.COLORS[tower.key] or Color3.new(1, 1, 1))
	end
	return fired
end

-- Burning patches damage ground enemies standing in them.
local function stepBurns(dt: number, live)
	local now = os.clock()
	for i = #burns, 1, -1 do
		local burn = burns[i]
		if now >= burn.untilTime then
			table.remove(burns, i)
			continue
		end
		for _, enemy in live do
			if not enemy.def.flying and math.abs(enemy.distance - burn.distance) <= burn.reach then
				Enemies.damage(enemy, burn.dps * dt, burn.piercesArmor)
			end
		end
	end
end

-- Called every Heartbeat by Main.
-- NOTE: fires at most once per frame (times `shots`), so fire rates above
-- ~60/s are capped.
function Towers.step(dt: number)
	local live = Enemies.getLive()
	stepBurns(dt, live)

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
			tower.cooldown += 1 / (stats.rate * (1 + tower.buff.ratePercent / 100))
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

function Towers.all(): { Tower }
	return towers
end

return Towers
