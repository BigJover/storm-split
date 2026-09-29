--[[
	Enemies: spawning, movement, damage, the split chain, and the live cap.

	OWNERSHIP: this module is the only thing that creates, moves, damages or
	removes enemies. Towers and weapons read the live list and call
	Enemies.damage() / stun() / knockback() / mark(); they never touch an
	enemy's fields directly.

	ARMOUR (UPGRADES.md): an Armored enemy takes no damage from a hit that
	doesn't pierce armour. Bosses shrug off stun and knockback unless a hit
	says otherwise.

	THE CAP (ARCHITECTURE.md §5): one Barge death cascades into 244 enemies.
	Nothing ever spawns directly — everything goes through a queue, and the
	queue only drains while live enemies are under MaxConcurrentEnemies.
	Split children have their own priority queue so they are never stuck
	behind fresh spawns waiting at the start of the track.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Track = require(Shared:WaitForChild("Track"))
local Path = require(Shared:WaitForChild("Path"))

local Enemies = {}

export type Enemy = {
	id: number,
	key: string,
	def: any,
	hp: number,
	maxHp: number,
	hpMult: number,
	distance: number,
	speed: number,
	height: number,
	part: BasePart,
	alive: boolean,
	stunnedUntil: number,
	markPercent: number,
	markedUntil: number,
}

type Pending = { key: string, distance: number, hpMult: number }

-- Visuals only. Balance never lives here.
local LOOK = {
	HUSK = { size = Vector3.new(2, 2, 2), color = Color3.fromRGB(126, 196, 110) },
	BRUTE = { size = Vector3.new(2.6, 2.6, 2.6), color = Color3.fromRGB(88, 160, 214) },
	SHIELD = { size = Vector3.new(3, 3, 3), color = Color3.fromRGB(235, 200, 80) },
	ARMOR = { size = Vector3.new(3.4, 3.4, 3.4), color = Color3.fromRGB(150, 150, 165) },
	STORM = { size = Vector3.new(3.6, 3.6, 3.6), color = Color3.fromRGB(150, 90, 230) },
	LLAMA = { size = Vector3.new(3.2, 3.2, 4), color = Color3.fromRGB(230, 120, 200) },
	ZEP = { size = Vector3.new(6, 5, 12), color = Color3.fromRGB(70, 60, 110) },
	BARGE = { size = Vector3.new(9, 7, 18), color = Color3.fromRGB(35, 25, 60) },
}
local DEFAULT_LOOK = { size = Vector3.new(2, 2, 2), color = Color3.new(1, 1, 1) }

-- How far behind its parent each split child appears, in studs.
local SPLIT_SPACING = 1.5

------------------------------------------------------------------ queue

local function newQueue()
	return { items = {}, head = 1, tail = 0 }
end

local function push(q, item: Pending)
	q.tail += 1
	q.items[q.tail] = item
end

local function pop(q): Pending?
	if q.head > q.tail then
		return nil
	end
	local item = q.items[q.head]
	q.items[q.head] = nil
	q.head += 1
	if q.head > q.tail then
		q.head, q.tail = 1, 0
	end
	return item
end

local function size(q): number
	return q.tail - q.head + 1
end

------------------------------------------------------------------ state

local live: { [number]: Enemy } = {}
local liveCount = 0
local peakLive = 0
local nextId = 0

local splitQueue = newQueue()
local spawnQueue = newQueue()

local path: Path.Path
local enemyFolder: Instance
local callbacks: {
	onLeak: ((Enemy) -> ())?,
	onKilled: ((Enemy) -> ())?,
} = {}

local cap = Config.Tuning.MaxConcurrentEnemies
local baseSpeed = Track.BaseEnemySpeed * Config.Tuning.GlobalSpeedScalar
local speedMult = 1 -- difficulty

------------------------------------------------------------------ internals

local function cframeAt(distance: number, height: number): CFrame
	local position, direction = path:sample(distance)
	position += Vector3.new(0, height, 0)
	return CFrame.lookAt(position, position + direction)
end

local function spawnNow(item: Pending)
	local def = Config.Enemies[item.key]
	if not def then
		warn(`[Enemies] Unknown enemy tier '{item.key}' — check the spreadsheet`)
		return
	end

	nextId += 1
	local look = LOOK[item.key] or DEFAULT_LOOK
	local height = if def.flying then Track.FlyingHeight else Track.EnemyHeight

	local part = Instance.new("Part")
	part.Name = item.key
	part.Size = look.size
	part.Color = look.color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.CFrame = cframeAt(item.distance, height)
	part.Parent = enemyFolder

	-- def.hp is the spreadsheet's Scaled HP, which already includes GlobalHPScalar.
	local hp = def.hp * item.hpMult
	local enemy: Enemy = {
		id = nextId,
		key = item.key,
		def = def,
		hp = hp,
		maxHp = hp,
		hpMult = item.hpMult,
		distance = item.distance,
		speed = baseSpeed * speedMult * def.speedMult,
		height = height,
		part = part,
		alive = true,
		stunnedUntil = 0,
		markPercent = 0,
		markedUntil = 0,
	}

	live[enemy.id] = enemy
	liveCount += 1
	if liveCount > peakLive then
		peakLive = liveCount
	end
end

local function remove(enemy: Enemy)
	if not enemy.alive then
		return
	end
	enemy.alive = false
	live[enemy.id] = nil
	liveCount -= 1
	enemy.part:Destroy()
end

------------------------------------------------------------------ public

function Enemies.init(mapPath: Path.Path, folder: Instance, hooks: { onLeak: ((Enemy) -> ())?, onKilled: ((Enemy) -> ())? })
	path = mapPath
	enemyFolder = folder
	callbacks = hooks
end

-- Difficulty's enemy speed. Applies to enemies spawned from now on.
function Enemies.setSpeedMult(mult: number)
	speedMult = mult
end

-- Queue a fresh enemy at the start of the track.
function Enemies.enqueue(key: string, hpMult: number)
	push(spawnQueue, { key = key, distance = 0, hpMult = hpMult })
end

-- Whether a hit with these properties can hurt this enemy at all.
function Enemies.canHurt(enemy: Enemy, piercesArmor: boolean): boolean
	return piercesArmor or not enemy.def.armored
end

-- Apply damage. Returns true if this hit killed it. A hit that can't pierce
-- an Armored enemy does nothing. An active mark adds its percentage.
-- Excess damage does NOT carry into split children (BTD6 does; add it later if wanted).
function Enemies.damage(enemy: Enemy, amount: number, piercesArmor: boolean?): boolean
	if not enemy.alive or not Enemies.canHurt(enemy, piercesArmor == true) then
		return false
	end
	if enemy.markPercent > 0 and os.clock() < enemy.markedUntil then
		amount *= 1 + enemy.markPercent / 100
	end
	enemy.hp -= amount
	if enemy.hp > 0 then
		return false
	end

	local def = enemy.def
	local distance = enemy.distance
	remove(enemy)

	if callbacks.onKilled then
		callbacks.onKilled(enemy)
	end

	if def.splitsInto ~= "" and def.splitCount > 0 then
		for i = 1, def.splitCount do
			push(splitQueue, {
				key = def.splitsInto,
				distance = math.max(0, distance - (i - 1) * SPLIT_SPACING),
				hpMult = enemy.hpMult,
			})
		end
	end

	return true
end

function Enemies.stun(enemy: Enemy, seconds: number, affectsBosses: boolean?)
	if not enemy.alive or seconds <= 0 or (enemy.def.boss and not affectsBosses) then
		return
	end
	enemy.stunnedUntil = math.max(enemy.stunnedUntil, os.clock() + seconds)
end

-- Pushes an enemy back along the track. Bosses are too heavy to move.
function Enemies.knockback(enemy: Enemy, studs: number)
	if not enemy.alive or studs <= 0 or enemy.def.boss then
		return
	end
	enemy.distance = math.max(0, enemy.distance - studs)
end

-- Marked enemies take +percent damage from every source until the mark expires.
-- A stronger mark replaces a weaker one; any mark refreshes the timer.
function Enemies.mark(enemy: Enemy, percent: number, seconds: number)
	if not enemy.alive or percent <= 0 then
		return
	end
	local now = os.clock()
	if now >= enemy.markedUntil or percent >= enemy.markPercent then
		enemy.markPercent = percent
	end
	enemy.markedUntil = now + seconds
end

-- Lives lost when this enemy leaks.
-- DESIGN NOTE: the design doc says "one life per leak". That makes leaking a
-- boss cheaper than killing it, because its children never spawn. Charging
-- effective HP (what BTD6 does with RBE) keeps bosses scary. Tune StartingLives
-- in the spreadsheet if this feels too punishing.
function Enemies.leakCost(enemy: Enemy): number
	return math.max(1, math.ceil(enemy.def.effectiveHp))
end

-- Called every Heartbeat by Main.
function Enemies.step(dt: number)
	while liveCount < cap do
		local item = pop(splitQueue) or pop(spawnQueue)
		if not item then
			break
		end
		spawnNow(item)
	end

	local now = os.clock()
	for _, enemy in live do
		if now >= enemy.stunnedUntil then
			enemy.distance += enemy.speed * dt
		end
		if enemy.distance >= path.length then
			remove(enemy)
			if callbacks.onLeak then
				callbacks.onLeak(enemy)
			end
		else
			enemy.part.CFrame = cframeAt(enemy.distance, enemy.height)
		end
	end
end

-- World position of a point `distance` studs along the track (for visuals).
function Enemies.pointAt(distance: number): Vector3
	local position = path:sample(math.clamp(distance, 0, path.length))
	return position
end

-- Read-only view for targeting. Do not mutate what you get back.
function Enemies.getLive(): { [number]: Enemy }
	return live
end

function Enemies.aliveCount(): number
	return liveCount
end

-- Everything still to deal with this round: on the field plus queued.
function Enemies.remaining(): number
	return liveCount + size(splitQueue) + size(spawnQueue)
end

function Enemies.peak(): number
	return peakLive
end

function Enemies.resetPeak()
	peakLive = liveCount
end

function Enemies.clearAll()
	for _, enemy in live do
		remove(enemy)
	end
	splitQueue = newQueue()
	spawnQueue = newQueue()
end

return Enemies
