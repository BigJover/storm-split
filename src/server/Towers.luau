--[[
	Towers: placement, stats, targeting, firing.

	A tower is a plain table of state (ARCHITECTURE.md §5.1 — the model is a
	view, never the source of truth). Upgrades change `pathTiers` and
	recompute cached stats; the model can be swapped freely without losing
	anything.

	Towers never touch cash (ARCHITECTURE.md §5.4). The shop pays first, then
	calls place() / upgrade() / remove().
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Enemies = require(script.Parent.Enemies)

local Towers = {}

export type Stats = { damage: number, rate: number, targets: number, range: number }

export type Tower = {
	key: string,
	def: any,
	pad: BasePart,
	position: Vector3,
	muzzle: Vector3,
	pathTiers: { number },
	stats: Stats,
	cooldown: number,
	model: Model,
}

-- Visuals only.
local COLORS = {
	SCOUT = Color3.fromRGB(96, 170, 255),
	SNIPER = Color3.fromRGB(240, 240, 240),
	GRENADIER = Color3.fromRGB(255, 140, 60),
	CHILLER = Color3.fromRGB(120, 230, 255),
	QUARTERMASTER = Color3.fromRGB(250, 205, 80),
}

local SPLASH_RADIUS = 6
local TRACER_LIFETIME = 0.06
local RING_MAX_RANGE = 200 -- Sniper's "global" 999 range would draw a 2000-stud disc

local towers: { Tower } = {}
local towerFolder: Instance

------------------------------------------------------------------ stats

local function computeStats(def, pathTiers: { number }): Stats
	local damageMult, rateMult, targetsMult = 1, 1, 1
	for pathIndex, tier in pathTiers do
		if tier > 0 then
			local step = def.paths[pathIndex].tiers[tier]
			damageMult *= step.damageMult
			rateMult *= step.rateMult
			targetsMult *= step.targetsMult
		end
	end
	return {
		damage = def.baseDamage * damageMult,
		rate = def.baseRate * rateMult,
		targets = math.max(1, math.floor(def.baseTargets * targetsMult + 0.5)),
		range = def.range,
	}
end

-- The crossover rule (ARCHITECTURE.md §2). Towers always use the strict version.
function Towers.canUpgrade(tower: Tower, pathIndex: number): boolean
	local tiers = tower.pathTiers
	local current = tiers[pathIndex]
	if current == nil or current >= 5 then
		return false
	end

	local maxOther, nonZeroOthers = 0, 0
	for i, tier in tiers do
		if i ~= pathIndex then
			maxOther = math.max(maxOther, tier)
			if tier > 0 then
				nonZeroOthers += 1
			end
		end
	end

	if current == 0 and nonZeroOthers >= 2 then
		return false -- a third path may never open
	end
	if current >= 2 and maxOther >= 3 then
		return false -- only one path may go past tier 2
	end
	return true
end

------------------------------------------------------------------ visuals

local function buildModel(key: string, def, base: Vector3): Model
	local model = Instance.new("Model")
	model.Name = key

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 5, 3)
	body.CFrame = CFrame.new(base + Vector3.new(0, 2.5, 0))
	body.Color = COLORS[key] or Color3.new(1, 1, 1)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.Parent = model
	model.PrimaryPart = body

	if def.range > 0 and def.range <= RING_MAX_RANGE then
		local ring = Instance.new("Part")
		ring.Name = "Range"
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.1, def.range * 2, def.range * 2)
		ring.CFrame = CFrame.new(base + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90))
		ring.Color = body.Color
		ring.Transparency = 0.85
		ring.Material = Enum.Material.Neon
		ring.Anchored = true
		ring.CanCollide = false
		ring.CanQuery = false
		ring.CanTouch = false
		ring.CastShadow = false
		ring.Parent = model
	end

	return model
end

local function tracer(from: Vector3, to: Vector3, color: Color3)
	local length = (to - from).Magnitude
	if length < 0.1 then
		return
	end
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.CastShadow = false
	beam.Material = Enum.Material.Neon
	beam.Color = color
	beam.Size = Vector3.new(0.15, 0.15, length)
	beam.CFrame = CFrame.lookAt((from + to) / 2, to)
	beam.Parent = towerFolder
	Debris:AddItem(beam, TRACER_LIFETIME)
end

------------------------------------------------------------------ public

function Towers.init(folder: Instance)
	towerFolder = folder
end

function Towers.place(key: string, pad: BasePart): Tower?
	local def = Config.Towers[key]
	if not def then
		warn(`[Towers] Unknown tower '{key}'`)
		return nil
	end
	if pad:GetAttribute("Occupied") then
		return nil
	end

	local base = pad.Position + Vector3.new(0, pad.Size.Y / 2, 0)
	local model = buildModel(key, def, base)
	model.Parent = towerFolder
	pad:SetAttribute("Occupied", true)

	local pathTiers = { 0, 0, 0 }
	local tower: Tower = {
		key = key,
		def = def,
		pad = pad,
		position = base + Vector3.new(0, 2.5, 0),
		muzzle = base + Vector3.new(0, 4.5, 0),
		pathTiers = pathTiers,
		stats = computeStats(def, pathTiers),
		cooldown = 0,
		model = model,
	}
	table.insert(towers, tower)
	return tower
end

-- Returns true if the upgrade was applied. Does NOT charge cash — the caller
-- (Economy, phase 2) must TrySpend first. Keeps this module free of money.
function Towers.upgrade(tower: Tower, pathIndex: number): boolean
	if not Towers.canUpgrade(tower, pathIndex) then
		return false
	end
	tower.pathTiers[pathIndex] += 1
	tower.stats = computeStats(tower.def, tower.pathTiers)
	return true
end

-- "First" targeting: the enemy furthest along the track that is in range.
local function pickFirst(tower: Tower, live): Enemies.Enemy?
	local best, bestDistance = nil, -1
	local range = tower.stats.range
	local hitsAir = tower.def.hitsAir
	for _, enemy in live do
		if enemy.def.flying and not hitsAir then
			continue
		end
		if enemy.distance > bestDistance and (enemy.part.Position - tower.position).Magnitude <= range then
			best, bestDistance = enemy, enemy.distance
		end
	end
	return best
end

local function splashTargets(primary: Enemies.Enemy, live, count: number, hitsAir: boolean): { Enemies.Enemy }
	local hits = { primary }
	if count <= 1 then
		return hits
	end
	local centre = primary.part.Position
	for _, enemy in live do
		if #hits >= count then
			break
		end
		if enemy ~= primary and (hitsAir or not enemy.def.flying) and (enemy.part.Position - centre).Magnitude <= SPLASH_RADIUS then
			table.insert(hits, enemy)
		end
	end
	return hits
end

-- Called every Heartbeat by Main.
-- NOTE: fires at most once per frame, so fire rates above ~60/s are capped.
function Towers.step(dt: number)
	local live = Enemies.getLive()
	for _, tower in towers do
		local stats = tower.stats
		if stats.rate <= 0 or stats.damage <= 0 then
			continue -- Quartermaster and anything else that doesn't shoot
		end

		tower.cooldown -= dt
		if tower.cooldown > 0 then
			continue
		end

		local target = pickFirst(tower, live)
		if not target then
			tower.cooldown = 0 -- stay ready
			continue
		end

		local targetPosition = target.part.Position
		local hits = splashTargets(target, live, stats.targets, tower.def.hitsAir)
		for _, enemy in hits do
			Enemies.damage(enemy, stats.damage)
		end
		tracer(tower.muzzle, targetPosition, COLORS[tower.key] or Color3.new(1, 1, 1))

		tower.cooldown += 1 / stats.rate
	end
end

function Towers.atPad(pad: BasePart): Tower?
	for _, tower in towers do
		if tower.pad == pad then
			return tower
		end
	end
	return nil
end

-- Takes the tower off the map and frees its pad. Refunds are the caller's job.
function Towers.remove(tower: Tower)
	local index = table.find(towers, tower)
	if not index then
		return
	end
	table.remove(towers, index)
	tower.model:Destroy()
	tower.pad:SetAttribute("Occupied", false)
end

function Towers.all(): { Tower }
	return towers
end

return Towers
