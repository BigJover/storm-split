--[[
	Enemies: the dinosaurs — spawning, movement, damage, shrinking, and the
	live cap.

	OWNERSHIP: this module is the only thing that creates, moves, damages or
	removes enemies. Towers and weapons read the live list and call
	Enemies.damage() / stun() / knockback() / mark(); they never touch an
	enemy's fields directly.

	ARMOUR (UPGRADES.md): an Armored enemy takes no damage from a hit that
	doesn't pierce armour. Bosses shrug off stun and knockback unless a hit
	says otherwise.

	CHILL (Chiller): a chilled enemy moves slower, may take extra damage from
	every source (brittle), and may lose its armour while the chill lasts
	(Shatter). Chill is refreshed every frame an enemy stands in a Chiller's
	range; Lingering Dose makes it linger after it leaves. A chilled (sedated)
	dino shows a tranq dart; one knocked out by a Tranq Station pulse shows "zzz".

	SHRINKING (VISION.md, DECISIONS #125-#127): each tier is its own species,
	and a dino never turns into a different enemy. It has ONE health pool (the
	species' HP); its sizes are evenly spaced thresholds on it (`share` each).
	It spawns at its largest size; crossing a threshold pays out like a kill
	(onKilled once per size: cash, a Bone) and the dino shrinks — same species,
	smaller model — keeping its mark, chill and fire. Crossing the last kills
	it. A hit may cross at most `breaks` thresholds (pierce-through; default 1,
	which is the old rule: excess damage doesn't carry into the next size).
	The rule is Shared/SizeBreaks.

	THE CAP (ARCHITECTURE.md §5): nothing spawns directly — everything goes
	through a queue that only drains while live enemies are under
	MaxConcurrentEnemies.

	TAR (Tar Pit, PLAN T67, rules in Shared/TarPit): a tarred dino walks slower (the
	stronger of its tar and its sedation slow; tar slows bosses too and doesn't touch
	attack cooldowns). sink() takes a last-size dino down (never a boss or a flyer), paying
	like a kill; dropSizes() is Eruption's size drop, Break resist ignored, each size paying.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Track = require(Shared:WaitForChild("Track"))
local Path = require(Shared:WaitForChild("Path"))
local DinoLook = require(Shared:WaitForChild("DinoLook"))
local Combat = require(Shared:WaitForChild("Combat"))
local SizeBreaks = require(Shared:WaitForChild("SizeBreaks"))
local Ballista = require(Shared:WaitForChild("Ballista"))
local TarPit = require(Shared:WaitForChild("TarPit"))

local Enemies = {}

export type Enemy = {
	id: number,
	key: string,
	def: any,
	hp: number, -- what's left of the one pool (all sizes)
	share: number, -- HP per size: the pool's thresholds are multiples of it
	hpMult: number,
	distance: number,
	speed: number,
	height: number,
	size: number, -- current size: sizes (largest) counting down to 1 (smallest)
	sizes: number,
	model: Model,
	part: BasePart, -- the model's Root: where the dino is, for targeting
	alive: boolean,
	stunnedUntil: number,
	disarmedUntil: number, -- can't bite or shoot until then (Field Medic Jaw Lock)
	markPercent: number,
	markedUntil: number,
	chilledUntil: number,
	slowPercent: number,
	brittlePercent: number,
	armorStripped: boolean,
	sleepUntil: number, -- knocked out by a Tranq Station pulse (a stun; visuals only)
	sedatedShown: boolean, -- what the model currently shows
	asleepShown: boolean,
	muzzledShown: boolean,
	muzzleFlash: boolean, -- flash the strap once it's on (Lullaby Rounds spread)
	fire: Fire?, -- burning: one damage tick when it runs out (Server/Hazards)
	tarSlow: number, -- Tar Pit: % slower while tarred (until tarUntil)
	tarUntil: number,
}

-- A burn on an enemy. `owner` is whoever lit it (for pops); Enemies only
-- carries it, Hazards acts on it.
export type Fire = { tick: number, untilTime: number, piercesArmor: boolean, owner: any }

type Pending = { key: string, distance: number, hpMult: number }

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

-- Bosses carry a pool bar with a notch per size threshold (DECISIONS #129).
local function showPool(enemy: Enemy)
	if enemy.def.boss and enemy.model then
		DinoLook.setPoolBar(enemy.model, SizeBreaks.fill(enemy.hp, enemy.share, enemy.sizes), SizeBreaks.notches(enemy.sizes))
	end
end

-- (Re)build an enemy's model for its current size. Visuals only; keeps the
-- chill and fire looks.
local function dress(enemy: Enemy)
	local old = enemy.model
	local scale = DinoLook.scale(enemy.size, enemy.sizes)
	local ground = Track.GroundTop
	local model, rootHeight = DinoLook.build(enemy.key, scale, CFrame.new())
	enemy.height = if enemy.def.flying then Track.FlyingHeight else rootHeight + ground
	enemy.model = model
	enemy.part = model.PrimaryPart :: BasePart
	enemy.part.CFrame = cframeAt(enemy.distance, enemy.height)
	model.Parent = enemyFolder
	if old then
		old:Destroy()
	end
	enemy.sedatedShown, enemy.asleepShown, enemy.muzzledShown = false, false, false -- step() re-applies them on the new model
	showPool(enemy)
	if enemy.fire then
		Enemies.showBurning(enemy, true)
	end
end

local function spawnNow(item: Pending)
	local def = Config.Enemies[item.key]
	if not def then
		warn(`[Enemies] Unknown enemy tier '{item.key}' — check the spreadsheet`)
		return
	end

	nextId += 1
	local sizes = math.max(1, def.sizes or 1)
	-- def.hp is the species' total (the spreadsheet's Scaled HP, GlobalHPScalar
	-- included), shared evenly across its sizes.
	local hpPerSize = def.hp * item.hpMult / sizes
	local enemy: Enemy = {
		id = nextId,
		key = item.key,
		def = def,
		hp = hpPerSize * sizes,
		share = hpPerSize,
		hpMult = item.hpMult,
		distance = item.distance,
		speed = baseSpeed * speedMult * def.speedMult,
		height = 0,
		size = sizes,
		sizes = sizes,
		model = nil :: any,
		part = nil :: any,
		alive = true,
		stunnedUntil = 0,
		disarmedUntil = 0,
		markPercent = 0,
		markedUntil = 0,
		chilledUntil = 0,
		slowPercent = 0,
		brittlePercent = 0,
		armorStripped = false,
		sleepUntil = 0,
		sedatedShown = false,
		asleepShown = false,
		muzzledShown = false,
		muzzleFlash = false,
		fire = nil,
		tarSlow = 0,
		tarUntil = 0,
	}
	dress(enemy)

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
	enemy.model:Destroy()
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

local function chilled(enemy: Enemy): boolean
	return os.clock() < enemy.chilledUntil
end

-- Whether a hit with these properties can hurt this enemy at all.
function Enemies.canHurt(enemy: Enemy, piercesArmor: boolean): boolean
	return piercesArmor or not enemy.def.armored or (enemy.armorStripped and chilled(enemy))
end

-- Apply damage. Returns true if this hit crossed a threshold (a pop: it shrank
-- or died), then the species key if the dino is gone (nil for a shrink;
-- bounties count dinos, DECISIONS #66), then how many sizes it dropped (one pop
-- each). `breaks` is the most thresholds this hit may cross (Shared/SizeBreaks;
-- default 1: splash, damage over time, bounces and everything else). A hit that
-- can't pierce an Armored enemy does nothing. An active mark or brittle chill
-- adds its percentage (to the damage, never to the breaks).
function Enemies.damage(enemy: Enemy, amount: number, piercesArmor: boolean?, breaks: number?): (boolean, string?, number)
	if not enemy.alive or not Enemies.canHurt(enemy, piercesArmor == true) then
		return false, nil, 0
	end
	if enemy.markPercent > 0 and os.clock() < enemy.markedUntil then
		amount *= 1 + enemy.markPercent / 100
	end
	if enemy.brittlePercent > 0 and chilled(enemy) then
		amount *= 1 + enemy.brittlePercent / 100
	end
	local hp, dropped, dead = SizeBreaks.apply(enemy.hp, enemy.share, enemy.size, amount, breaks)
	enemy.hp = hp
	if dropped == 0 then
		showPool(enemy)
		return false, nil, 0
	end

	for _ = 1, dropped do
		if callbacks.onKilled then
			callbacks.onKilled(enemy) -- a size is done: cash and a pop
		end
	end
	if not dead then
		enemy.size -= dropped
		dress(enemy) -- smaller, same species (one redress however many sizes dropped)
		return true, nil, dropped
	end
	remove(enemy)
	return true, enemy.key, dropped
end

-- The breaks a direct hit gets on this dino: the hitter's base and level less
-- the species' Break resist (Shared/SizeBreaks).
function Enemies.breaksFor(enemy: Enemy, base: number, level: number, isHero: boolean): number
	return SizeBreaks.breaks(base, level, enemy.def.breakResist, isHero)
end

function Enemies.isMarked(enemy: Enemy): boolean
	return enemy.markPercent > 0 and os.clock() < enemy.markedUntil
end

export type Chill = {
	slowPercent: number,
	seconds: number,
	affectsBosses: boolean,
	brittlePercent: number,
	stripsArmor: boolean,
}

-- Chill an enemy for `seconds`. The strongest slow and brittle in effect win
-- while the chill lasts; a fresh chill with weaker numbers only extends it.
function Enemies.chill(enemy: Enemy, c: Chill)
	if not enemy.alive or c.seconds <= 0 or (enemy.def.boss and not c.affectsBosses) then
		return
	end
	local now = os.clock()
	if now >= enemy.chilledUntil then
		enemy.slowPercent, enemy.brittlePercent, enemy.armorStripped = 0, 0, false
	end
	enemy.chilledUntil = math.max(enemy.chilledUntil, now + c.seconds)
	enemy.slowPercent = math.max(enemy.slowPercent, c.slowPercent)
	enemy.brittlePercent = math.max(enemy.brittlePercent, c.brittlePercent)
	enemy.armorStripped = enemy.armorStripped or c.stripsArmor
end

function Enemies.stun(enemy: Enemy, seconds: number, affectsBosses: boolean?)
	if not enemy.alive or seconds <= 0 or (enemy.def.boss and not affectsBosses) then
		return
	end
	enemy.stunnedUntil = math.max(enemy.stunnedUntil, os.clock() + seconds)
end

function Enemies.isStunned(enemy: Enemy): boolean
	return os.clock() < enemy.stunnedUntil
end

-- A disarmed dino keeps walking but can't bite or shoot (Server/DinoAttacks
-- checks). Bosses shrug it off unless `affectsBosses`. `flash` flashes the
-- muzzle strap (Lullaby Rounds spreading the lock).
function Enemies.disarm(enemy: Enemy, seconds: number, affectsBosses: boolean?, flash: boolean?)
	if not enemy.alive or seconds <= 0 or (enemy.def.boss and not affectsBosses) then
		return
	end
	enemy.disarmedUntil = math.max(enemy.disarmedUntil, os.clock() + seconds)
	enemy.muzzleFlash = enemy.muzzleFlash or flash == true
end

function Enemies.isDisarmed(enemy: Enemy): boolean
	return os.clock() < enemy.disarmedUntil
end

-- How much a sedation slow holds this dino back right now (0..0.95): its
-- walking speed and, in DinoAttacks, its attack cooldowns (DECISIONS #6).
function Enemies.slowFraction(enemy: Enemy): number
	if os.clock() >= enemy.chilledUntil then
		return 0
	end
	return math.clamp(enemy.slowPercent, 0, 95) / 100
end

-- Tar (PLAN T67): `percent` slower for `seconds`. While tarred the strongest tar slow
-- wins; a weaker one only extends it. Flying dinos never touch the tar.
function Enemies.tar(enemy: Enemy, percent: number, seconds: number)
	if not enemy.alive or enemy.def.flying or percent <= 0 or seconds <= 0 then
		return
	end
	local now = os.clock()
	if now >= enemy.tarUntil then
		enemy.tarSlow = 0
	end
	enemy.tarUntil = math.max(enemy.tarUntil, now + seconds)
	enemy.tarSlow = math.max(enemy.tarSlow, percent)
end

-- How much tar holds this dino back right now (0..0.95). Walking only.
local function tarFraction(enemy: Enemy): number
	if os.clock() >= enemy.tarUntil then
		return 0
	end
	return math.clamp(enemy.tarSlow, 0, 95) / 100
end

-- Slowed by anything (tar or a sedation chill): Tar Totem's bonus applies.
function Enemies.isSlowed(enemy: Enemy): boolean
	return tarFraction(enemy) > 0 or Enemies.slowFraction(enemy) > 0
end

-- Sinks a last-size dino in the tar (a take-down: it pays like a kill). Never a boss or
-- a flyer. Returns true and the species key if it went under.
function Enemies.sink(enemy: Enemy): (boolean, string?)
	if not enemy.alive or enemy.size > 1 or enemy.def.boss or enemy.def.flying then
		return false, nil
	end
	enemy.hp = 0
	if callbacks.onKilled then
		callbacks.onKilled(enemy)
	end
	remove(enemy)
	return true, enemy.key
end

-- Eruption (DECISIONS #150): drops `sizes` sizes outright, whatever the HP, bosses
-- included, Break resist ignored. Each size pays. Same returns as damage().
function Enemies.dropSizes(enemy: Enemy, sizes: number): (boolean, string?, number)
	if not enemy.alive then
		return false, nil, 0
	end
	local hp, dropped, dead = TarPit.drop(enemy.hp, enemy.share, enemy.size, sizes)
	if dropped == 0 then
		return false, nil, 0
	end
	enemy.hp = hp
	for _ = 1, dropped do
		if callbacks.onKilled then
			callbacks.onKilled(enemy)
		end
	end
	if not dead then
		enemy.size -= dropped
		dress(enemy)
		return true, nil, dropped
	end
	remove(enemy)
	return true, enemy.key, dropped
end

-- A Tranq Station knockout pulse: a stun that also shows "zzz" while it holds.
function Enemies.knockOut(enemy: Enemy, seconds: number, affectsBosses: boolean?)
	local before = enemy.stunnedUntil
	Enemies.stun(enemy, seconds, affectsBosses)
	if enemy.stunnedUntil > before then
		enemy.sleepUntil = enemy.stunnedUntil
	end
end

-- Pushes an enemy back along the track. Bosses are too heavy to move, except by a
-- Harpoon Ballista's Tow Line (`towLine`, the one caller that passes it; PLAN T66).
function Enemies.knockback(enemy: Enemy, studs: number, towLine: boolean?)
	if not enemy.alive or studs <= 0 or not Ballista.movesBoss(enemy.def.boss == true, towLine) then
		return
	end
	enemy.distance = math.max(0, enemy.distance - studs)
end

-- Marked enemies take +percent damage from every source until the mark expires.
-- The stronger mark wins outright (DECISIONS #106): while a mark is running a weaker
-- one changes nothing, an equal one keeps the longer time, and a stronger one
-- replaces it. The rule is Combat.mergeMark.
function Enemies.mark(enemy: Enemy, percent: number, seconds: number)
	if not enemy.alive or percent <= 0 then
		return
	end
	local now = os.clock()
	local merged, remaining = Combat.mergeMark(enemy.markPercent, enemy.markedUntil - now, percent, seconds)
	enemy.markPercent = merged
	enemy.markedUntil = now + remaining
end

-- Set an enemy on fire, or refresh its fire (biggest tick and latest end
-- win, so several pellets still mean one tick). It keeps burning as it shrinks.
function Enemies.ignite(enemy: Enemy, fire: Fire)
	if not enemy.alive then
		return
	end
	local current = enemy.fire
	if current then
		enemy.fire = {
			tick = math.max(current.tick, fire.tick),
			untilTime = math.max(current.untilTime, fire.untilTime),
			piercesArmor = current.piercesArmor or fire.piercesArmor,
			owner = fire.owner,
		}
	else
		enemy.fire = fire
		Enemies.showBurning(enemy, true)
	end
end

-- The fire has run its course; returns it so Hazards can deal the tick.
function Enemies.extinguish(enemy: Enemy): Fire?
	local fire = enemy.fire
	enemy.fire = nil
	Enemies.showBurning(enemy, false)
	return fire
end

-- Visual only: flames on a burning enemy.
function Enemies.showBurning(enemy: Enemy, on: boolean)
	local fire = enemy.part:FindFirstChildOfClass("Fire")
	if on and not fire then
		local flames = Instance.new("Fire")
		flames.Size = enemy.part.Size.Magnitude
		flames.Heat = 4
		flames.Parent = enemy.part
	elseif not on and fire then
		fire:Destroy()
	end
end

-- Lives lost when this enemy leaks: its effective HP for the sizes it still
-- has (BTD6's RBE idea), so leaking a big dino hurts more than a shrunk one.
function Enemies.leakCost(enemy: Enemy): number
	return math.max(1, math.ceil(enemy.def.effectiveHp * enemy.size / enemy.sizes))
end

-- Called every Heartbeat by Main.
function Enemies.step(dt: number)
	while liveCount < cap do
		local item = pop(spawnQueue)
		if not item then
			break
		end
		spawnNow(item)
	end

	local now = os.clock()
	for _, enemy in live do
		local isChilled = now < enemy.chilledUntil
		if now >= enemy.stunnedUntil then
			local slow = math.max(Enemies.slowFraction(enemy), tarFraction(enemy))
			enemy.distance += enemy.speed * (1 - slow) * dt
		end
		-- Visuals only.
		if isChilled ~= enemy.sedatedShown then
			enemy.sedatedShown = isChilled
			DinoLook.setSedated(enemy.model, isChilled)
		end
		local asleep = now < enemy.sleepUntil and now < enemy.stunnedUntil
		if asleep ~= enemy.asleepShown then
			enemy.asleepShown = asleep
			DinoLook.setAsleep(enemy.model, asleep)
		end
		local muzzled = now < enemy.disarmedUntil
		if muzzled ~= enemy.muzzledShown then
			enemy.muzzledShown = muzzled
			DinoLook.setMuzzled(enemy.model, muzzled)
		end
		if enemy.muzzleFlash then
			enemy.muzzleFlash = false
			DinoLook.flashMuzzle(enemy.model)
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

-- Distance along the track of the point nearest to a world position.
function Enemies.trackDistanceNear(point: Vector3): number
	return path:closest(point)
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
	return liveCount + size(spawnQueue)
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
	spawnQueue = newQueue()
end

return Enemies
