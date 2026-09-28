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
local Placement = require(Shared:WaitForChild("Placement"))
local TowerLook = require(Shared:WaitForChild("TowerLook"))

local Enemies = require(script.Parent.Enemies)

local Towers = {}

export type Stats = { damage: number, rate: number, targets: number, range: number }

export type Tower = {
	id: number,
	key: string,
	def: any,
	base: Vector3, -- on the build floor; what Placement checks against
	position: Vector3,
	muzzle: Vector3,
	pathTiers: { number },
	stats: Stats,
	cooldown: number,
	model: Model,
}

local SPLASH_RADIUS = 6
local TRACER_LIFETIME = 0.06

local towers: { Tower } = {}
local towerFolder: Instance
local nextId = 0

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
		tracer(tower.muzzle, targetPosition, TowerLook.COLORS[tower.key] or Color3.new(1, 1, 1))

		tower.cooldown += 1 / stats.rate
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
end

function Towers.all(): { Tower }
	return towers
end

return Towers
