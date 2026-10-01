--[[
	DinoAttacks: the dinos fight back (VISION.md Step 2, DECISIONS #2-#6).

	BITES: every species with a Melee damage bites the nearest target within
	its Melee reach — a standing tower or a living hunter, treated alike —
	measured sideways from the dino (Shared/Combat.pickTarget). Dinos never stop
	walking to fight. A bite deals Melee damage x size/sizes x the difficulty's
	Dino damage x (Combat.attackDamage) through Towers.damage / Health.damage,
	which apply resistance.

	RANGED (mid and high tiers): the same way, the nearest target within Ranged
	reach gets a projectile thrown at where it stands right now. It never homes
	in: it flies at Projectile speed to that point on the ground, an orange ring
	marks the spot for the whole flight, and on landing it hurts every hunter
	and standing tower within the Impact radius (Combat.landingHits), so a
	hunter who moves out of the ring is safe (DECISIONS #5). Projectiles are
	data stepped here every frame; at most Tuning Max projectiles fly at once,
	and launching past that drops the oldest. Shapes and paths are DinoLook's.

	Timing: each attack comes round every Melee / Ranged every seconds. A timer
	starts at a random point of its cooldown so a wave doesn't attack in
	unison, runs slower while the dino is sedated (by the same slow %), and is
	paused while it's stunned (knocked out) or disarmed. A ready dino with
	nothing in reach attacks the moment something is.

	This module only reads enemies (Enemies.getLive and its state queries) and
	keeps its own timers keyed by enemy id; Enemies stays their only mutator.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Combat = require(Shared:WaitForChild("Combat"))
local Config = require(Shared:WaitForChild("Config"))
local DinoLook = require(Shared:WaitForChild("DinoLook"))
local Track = require(Shared:WaitForChild("Track"))

local Effects = require(script.Parent.Effects)
local Enemies = require(script.Parent.Enemies)
local Health = require(script.Parent.Health)
local Towers = require(script.Parent.Towers)

local DinoAttacks = {}

-- Visuals only.
local BITE_SNAP = 0.15 -- seconds for the teeth to close
local TOOTH_BAR = Vector3.new(1.6, 0.25, 0.3)
local BOSS_BITE = 2 -- bosses' teeth are this much bigger
local PUFF_TIME = 0.3
local CHIP_TIME = 0.6
local SPIKE_STICK_TIME = 0.5
local MIN_FLIGHT = 0.25 -- seconds; a point-blank shot still shows its ring

type Projectile = {
	from: Vector3, -- where it was thrown from
	to: Vector3, -- where it lands (on the ground, under where the target was)
	duration: number,
	age: number,
	damage: number,
	radius: number,
	style: string,
	species: string, -- for the hit notice
	attack: string,
	model: Model,
	ring: BasePart,
}

local biteIn: { [number]: number } = {} -- enemy id -> seconds until its next bite
local shootIn: { [number]: number } = {} -- enemy id -> seconds until its next throw
local projectiles: { Projectile } = {} -- oldest first
local peakInFlight = 0 -- most in the air at once this round (round summary)
local folder: Instance? = nil
local damageMult: () -> number = function()
	return 1
end
local onBite: ((Enemies.Enemy, Vector3) -> ())? = nil -- Armory thorns / Bulwark (Towers.bitten)
local random = Random.new()

export type Hooks = {
	damageMult: (() -> number)?, -- the difficulty's Dino damage x
	folder: Instance?, -- where projectile visuals live (the map's effect folder)
	onBite: ((Enemies.Enemy, Vector3) -> ())?, -- after every bite, with where the target stood
}

function DinoAttacks.init(hooks: Hooks?)
	if hooks and hooks.damageMult then
		damageMult = hooks.damageMult
	end
	folder = hooks and hooks.folder
	onBite = hooks and hooks.onBite
end

-- Everything a dino could attack right now.
local function candidates(): { Combat.Target }
	local list: { Combat.Target } = {}
	for _, tower in Towers.targets() do
		table.insert(list, { position = tower.base, standing = true, ref = tower })
	end
	-- Characters only exist during a match (Main spawns them), so a living
	-- character is a hunter in the match.
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and root:IsA("BasePart") and humanoid then
			table.insert(list, { position = root.Position, standing = humanoid.Health > 0, ref = player })
		end
	end
	return list
end

local function stillStanding(target: Combat.Target): boolean
	local ref = target.ref
	if typeof(ref) == "Instance" and ref:IsA("Player") then
		local humanoid = ref.Character and ref.Character:FindFirstChildOfClass("Humanoid")
		return humanoid ~= nil and humanoid.Health > 0
	end
	return not ref.knockedOut
end

local function hurt(target: Combat.Target, damage: number, enemy: Enemies.Enemy?, source: Health.Source)
	if typeof(target.ref) == "Instance" and target.ref:IsA("Player") then
		Health.damage(target.ref, damage, source)
	else
		Towers.damage(target.ref, damage, enemy)
	end
	target.standing = stillStanding(target) -- trampled or killed: the rest look elsewhere
end

-- Two tooth bars in the species colour snap shut over the target; bigger for
-- a bigger dino, bigger still for a boss.
local function biteLook(enemy: Enemies.Enemy, at: Vector3)
	local scale = math.max(0.5, enemy.size / math.max(1, enemy.sizes)) * (if enemy.def.boss then BOSS_BITE else 1)
	local size = TOOTH_BAR * scale
	local gap = 0.6 * scale
	local color = DinoLook.colorOf(enemy.key)
	-- facing the dino, level
	local toward = (enemy.part.Position - at) * Vector3.new(1, 0, 1)
	local centre = if toward.Magnitude > 0.01 then CFrame.lookAt(at, at + toward) else CFrame.new(at)
	for _, side in { 1, -1 } do
		local tooth = Effects.part(size, centre * CFrame.new(0, side * gap, 0), color, BITE_SNAP + 0.1)
		tooth.Material = Enum.Material.SmoothPlastic
		TweenService:Create(tooth, TweenInfo.new(BITE_SNAP), { CFrame = centre * CFrame.new(0, side * size.Y / 2, 0) }):Play()
	end
end

local function bite(enemy: Enemies.Enemy, target: Combat.Target)
	local damage = Combat.attackDamage(enemy.def.meleeDamage, enemy.size, enemy.sizes, damageMult())
	hurt(target, damage, enemy, { species = enemy.def.display, attack = enemy.def.meleeName })
	biteLook(enemy, target.position + Vector3.new(0, 2, 0))
	if onBite then
		onBite(enemy, target.position) -- may hurt or stun the biter (Armory)
	end
end

------------------------------------------------------------------ projectiles

local function destroy(p: Projectile)
	p.model:Destroy()
	p.ring:Destroy()
end

local function throw(enemy: Enemies.Enemy, target: Combat.Target)
	local def = enemy.def
	local from = enemy.part.Position
	local to = Vector3.new(target.position.X, Track.GroundTop, target.position.Z)
	local cap = Config.Tuning.MaxProjectiles
	while #projectiles >= cap and #projectiles > 0 do
		destroy(table.remove(projectiles, 1) :: Projectile) -- past the cap the oldest goes
	end
	if cap <= 0 then
		return
	end
	local scale = enemy.size / math.max(1, enemy.sizes)
	local model = DinoLook.buildProjectile(enemy.key, def.impactRadius, scale)
	local style = model:GetAttribute("Style") or "lob"
	local ring = DinoLook.buildWarningRing(to, def.impactRadius)
	local p: Projectile = {
		from = from,
		to = to,
		duration = math.max(MIN_FLIGHT, (to - from).Magnitude / def.projectileSpeed),
		age = 0,
		damage = Combat.attackDamage(def.rangedDamage, enemy.size, enemy.sizes, damageMult()),
		radius = def.impactRadius,
		style = style,
		species = def.display,
		attack = def.rangedName,
		model = model,
		ring = ring,
	}
	DinoLook.flashHead(enemy.model) -- telegraphs the throw (visual only)
	model:PivotTo(DinoLook.projectilePose(style, from, to, 0, 0, model:GetAttribute("Height") or 1))
	model.Parent = folder
	ring.Parent = folder
	table.insert(projectiles, p)
	peakInFlight = math.max(peakInFlight, #projectiles)
end

-- A dust puff that grows to the impact radius and fades, plus a few chips.
local function landingLook(p: Projectile)
	local dust = DinoLook.PROJECTILE_DUST[p.style]
	if dust then
		local puff = Effects.part(Vector3.one, CFrame.new(p.to + Vector3.new(0, 0.5, 0)), dust, PUFF_TIME, Enum.PartType.Ball)
		puff.Material = Enum.Material.SmoothPlastic
		puff.Transparency = 0.4
		TweenService:Create(puff, TweenInfo.new(PUFF_TIME), { Size = Vector3.one * p.radius * 2, Transparency = 1 }):Play()
	end
	for i = 1, DinoLook.PROJECTILE_CHIPS[p.style] or 0 do
		local angle = (i / 3) * 2 * math.pi + random:NextNumber()
		local spot = p.to + Vector3.new(math.cos(angle), 0.2, math.sin(angle)) * (p.radius * 0.4)
		local chip = Effects.part(Vector3.new(0.4, 0.3, 0.35), CFrame.new(spot) * CFrame.Angles(angle, angle * 2, 0), dust or Color3.new(0.4, 0.4, 0.4), CHIP_TIME)
		chip.Material = Enum.Material.Slate
	end
	if p.style == "spike" then
		-- the spike sticks upright in the ground for a moment
		local shot = p.model.PrimaryPart
		if shot then
			local stuck = Effects.part(shot.Size, CFrame.new(p.to + Vector3.new(0, shot.Size.Z * 0.3, 0)) * CFrame.Angles(math.rad(80), 0, 0), shot.Color, SPIKE_STICK_TIME)
			stuck.Material = Enum.Material.SmoothPlastic
		end
	end
end

local function land(p: Projectile)
	local targets = candidates()
	for _, target in Combat.landingHits(p.to, p.radius, targets) do
		hurt(target, p.damage, nil, { species = p.species, attack = p.attack })
	end
	landingLook(p)
	destroy(p)
end

local function stepProjectiles(dt: number)
	local i = 1
	while i <= #projectiles do
		local p = projectiles[i]
		p.age += dt
		if p.age >= p.duration then
			table.remove(projectiles, i)
			land(p)
		else
			local frac = p.age / p.duration
			p.model:PivotTo(DinoLook.projectilePose(p.style, p.from, p.to, frac, p.age, p.model:GetAttribute("Height") or 1))
			p.ring.Transparency = DinoLook.ringTransparency(frac)
			i += 1
		end
	end
end

------------------------------------------------------------------ timers

-- Counts an attack timer down; returns the new value and whether it's ready.
local function tick(timers: { [number]: number }, id: number, every: number, dt: number, slow: number): number
	local left = timers[id]
	if left == nil then
		left = random:NextNumber() * every -- random initial phase
	end
	return left - dt * (1 - slow)
end

-- Called every Heartbeat by Main, after Towers.step, while the match is Playing.
function DinoAttacks.step(dt: number)
	if ReplicatedStorage:GetAttribute("State") ~= "Playing" then
		return
	end
	stepProjectiles(dt)

	local live = Enemies.getLive()
	local targets: { Combat.Target }? = nil -- built once, only if some dino is ready

	for id, enemy in live do
		local def = enemy.def
		local bites = (def.meleeDamage or 0) > 0 and (def.meleeEvery or 0) > 0
		local shoots = (def.rangedDamage or 0) > 0 and (def.rangedEvery or 0) > 0
		if not bites and not shoots then
			continue
		end
		if Enemies.isStunned(enemy) or Enemies.isDisarmed(enemy) then
			-- paused (a new dino still gets its random phase)
			if bites and biteIn[id] == nil then
				biteIn[id] = random:NextNumber() * def.meleeEvery
			end
			if shoots and shootIn[id] == nil then
				shootIn[id] = random:NextNumber() * def.rangedEvery
			end
			continue
		end
		local slow = Enemies.slowFraction(enemy)

		if bites then
			local left = tick(biteIn, id, def.meleeEvery, dt, slow)
			if left <= 0 then
				targets = targets or candidates()
				local target = Combat.pickTarget(enemy.part.Position, targets :: { Combat.Target }, def.meleeReach)
				if target then
					bite(enemy, target)
					left += def.meleeEvery
				else
					left = 0 -- ready; bites as soon as something is in reach
				end
			end
			biteIn[id] = left
		end

		if shoots then
			local left = tick(shootIn, id, def.rangedEvery, dt, slow)
			if left <= 0 then
				targets = targets or candidates()
				local target = Combat.pickTarget(enemy.part.Position, targets :: { Combat.Target }, def.rangedReach)
				if target then
					throw(enemy, target)
					left += def.rangedEvery
				else
					left = 0
				end
			end
			shootIn[id] = left
		end
	end

	-- Forget dinos that are gone.
	for id in biteIn do
		if not live[id] then
			biteIn[id] = nil
		end
	end
	for id in shootIn do
		if not live[id] then
			shootIn[id] = nil
		end
	end
end

-- The most projectiles in the air at once since resetPeak (round summary).
function DinoAttacks.peak(): number
	return peakInFlight
end

function DinoAttacks.resetPeak()
	peakInFlight = #projectiles
end

-- Between matches: timers forgotten, projectiles gone.
function DinoAttacks.clear()
	table.clear(biteIn)
	table.clear(shootIn)
	for _, p in projectiles do
		destroy(p)
	end
	table.clear(projectiles)
end

return DinoAttacks
