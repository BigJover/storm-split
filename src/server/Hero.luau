--[[
	Hero: the player character is the hero (HEROES.md, design doc §02).

	Picking a hero (Pistol, Assault Rifle, Shotgun) is free: switch freely in the
	build phase, with any upgrades refunded; after Start it's locked. A player
	who joins mid-match picks once. Upgrades cost the team's cash: three paths
	of five tiers per hero, under the same crossover rule as towers
	(Shared/Upgrades). What the gun does right now comes from Shared/HeroStats,
	which the client uses too.

	Gun mechanics, all enforced here:
	  magazine    each trigger pull uses rounds; empty starts a reload
	  recoil      each shot widens this player's spread (bloom); it settles over
	              time. The server scatters every pellet inside that cone, so a
	              client can't shoot straighter than its gun
	  fire rate   pulls closer together than the gun allows are ignored
	              (Spin-Up raises the rate while the trigger is held)
	  pellets     each pellet travels its own ray, passes through `pierce`
	              enemies, can ricochet, splash, burn, knock back and mark

	The hero's ability (Mark, Overdrive, Airburst, Heal) is available from the
	start on its cooldown.

	FIELD MEDIC (PLAN T16, DECISIONS #13/#14/#25): the Triage Kit heals the
	medic and every hunter in its radius through Server/Health (flat: hero
	levels don't scale it). Patch Up also heals standing towers in the radius
	(Towers.heal). Second Wind guards everything it healed: a damage
	resistance source that Main feeds to Health and Towers (Hero.guardOf /
	Hero.towerGuardOf; the strongest source wins, DECISIONS #12). Muzzle rounds
	slow a hit dino (Enemies.chill; bosses ignore it) and Jaw Lock disarms it
	(Enemies.disarm; bosses for Tuning Boss jaw lock x of the time), spreading
	to dinos nearby with Lullaby Rounds.

	MASTERY (Server/Progression): the player's mastery with their hero makes
	hero upgrades cheaper, shortens the ability cooldown, can make the first
	upgrade of the match free, raises the crossover cap at level 20, and turns
	the gun gold at max mastery. Read at pick time and on every purchase.

	HERO LEVELS: each level multiplies all of the hero's damage — rounds,
	splash, fire, Airburst — by 1 + HeroDamagePerLevel, compounding, so the
	hero keeps pace with enemy HP. For now every hero levels up together every
	RoundsPerLevel rounds cleared (Hero.setLevel from Main); levels are kept per
	player so hero XP from their own pops can drive them later (HEROES.md).

	SERVER AUTHORITATIVE: a client only says "I pulled the trigger along this
	camera ray", "reload", or "use my ability along this ray". Hits are echoed
	back to the shooter for the hit marker.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local HeroStats = require(Shared:WaitForChild("HeroStats"))
local Track = require(Shared:WaitForChild("Track"))
local Theme = require(Shared:WaitForChild("Theme"))
local Upgrades = require(Shared:WaitForChild("Upgrades"))

local Economy = require(script.Parent.Economy)
local Progression = require(script.Parent.Progression)
local Effects = require(script.Parent.Effects)
local Enemies = require(script.Parent.Enemies)
local Hazards = require(script.Parent.Hazards)
local Health = require(script.Parent.Health)
local Towers = require(script.Parent.Towers)

local Hero = {}

type State = {
	hero: string?,
	tiers: { number },
	spent: number, -- cash put into upgrades (refunded if the hero is switched in the build phase)
	stats: HeroStats.Stats?,
	ammo: number,
	reloadUntil: number, -- os.clock(); 0 when not reloading
	lastShot: number,
	spinTime: number,
	bloom: number, -- extra spread in degrees from recoil
	bloomAt: number,
	gunSide: number, -- alternates 1 / -1 for dual guns (visual)
	level: number,
	freeUpgrade: boolean, -- mastery 10: the first upgrade of the match costs nothing
	abilityReadyAt: number,
	overdriveUntil: number,
	overdrivePercent: number,
	overdriveRadius: number,
	gear: HeroStats.Gear, -- an Outfitter Armory's buffs where the hunter stands
}

-- Visuals only.
local HERO_COLORS = {
	PISTOL = Color3.fromRGB(255, 90, 110),
	RIFLE = Color3.fromRGB(255, 220, 90),
	SHOTGUN = Color3.fromRGB(255, 140, 50),
	MEDIC = Color3.fromRGB(110, 230, 140),
}
local DUAL_GUN_OFFSET = 0.9 -- studs sideways for the second gun's tracer
local MASTERY_GOLD = Color3.fromRGB(250, 200, 60)

local SHOT_GAP_SLACK = 0.8 -- accept pulls up to 20% early, for network jitter
local RAY_ORIGIN_SLACK = 20 -- studs beyond max camera zoom a ray may start from
local SPIN_KEEP = 0.35 -- seconds between pulls that still count as holding the trigger

local states: { [Player]: State } = {}
local teamLevel = 1 -- what new players start at
local onPop: ((Player) -> ())? = nil
local gearAt: ((Vector3) -> HeroStats.Gear)? = nil -- Towers.hunterGearAt
local GEAR_CHECK = 0.2 -- seconds between checks of where each hunter stands
local fireEvent: RemoteEvent

-- Second Wind: who is guarded, how much and until when (os.clock()). Keyed by
-- the hunter or tower that was healed, not by the medic.
type Guard = { percent: number, untilTime: number }
local playerGuards: { [Player]: Guard } = {}
local towerGuards: { [any]: Guard } = setmetatable({}, { __mode = "k" }) :: any

------------------------------------------------------------------ state

local function stateOf(player: Player): State
	local state = states[player]
	if not state then
		state = {
			hero = nil,
			tiers = { 0, 0, 0 },
			spent = 0,
			stats = nil,
			ammo = 0,
			reloadUntil = 0,
			lastShot = 0,
			spinTime = 0,
			bloom = 0,
			bloomAt = 0,
			gunSide = 1,
			level = teamLevel,
			freeUpgrade = false,
			abilityReadyAt = 0,
			overdriveUntil = 0,
			overdrivePercent = 0,
			overdriveRadius = 0,
			gear = HeroStats.NO_GEAR,
		}
		states[player] = state
	end
	return state
end

-- Damage multiplier from this player's hero level.
local function levelScale(s: State): number
	return (1 + Config.Tuning.HeroDamagePerLevel) ^ math.max(0, s.level - 1)
end

-- The mastery rewards this player has with their current hero, or nil.
local function mastery(player: Player, s: State): any?
	if not s.hero then
		return nil
	end
	return Progression.masteryRewards(Progression.masteryLevel(player, s.hero))
end

local function credit(player: Player, killed: boolean)
	if killed and onPop and player.Parent then
		onPop(player)
	end
end

local function root(player: Player): BasePart?
	local character = player.Character
	local part = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if part and part:IsA("BasePart") and humanoid and humanoid.Health > 0 then
		return part
	end
	return nil
end

local function isFinite(v: Vector3): boolean
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z and v.Magnitude < 1e6
end

-- A sane aim ray from this player's camera, or nil.
local function validRay(player: Player, body: BasePart, origin: unknown, direction: unknown): (Vector3?, Vector3?)
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
		return nil, nil
	end
	if not isFinite(origin) or not isFinite(direction) or direction.Magnitude < 0.01 then
		return nil, nil
	end
	if (origin - body.Position).Magnitude > player.CameraMaxZoomDistance + RAY_ORIGIN_SLACK then
		return nil, nil
	end
	return origin, direction.Unit
end

local function gameOver(): boolean
	local state = ReplicatedStorage:GetAttribute("State")
	return state == "GameOver" or state == "Victory"
end

-- Everything the client HUD needs, as player attributes. Times are server time.
local function publish(player: Player)
	local s = stateOf(player)
	local clockToServer = workspace:GetServerTimeNow() - os.clock()
	player:SetAttribute("Hero", s.hero or "")
	player:SetAttribute("HeroLevel", s.level)
	player:SetAttribute("FreeUpgrade", s.freeUpgrade)
	for i = 1, 3 do
		player:SetAttribute(`HeroPath{i}`, s.tiers[i])
	end
	player:SetAttribute("Ammo", s.ammo)
	player:SetAttribute("Magazine", if s.stats then s.stats.magazine else 0)
	player:SetAttribute("ReloadUntil", if s.reloadUntil > 0 then s.reloadUntil + clockToServer else 0)
	player:SetAttribute("AbilityReadyAt", s.abilityReadyAt + clockToServer)
end

------------------------------------------------------------------ the tool

local function findTool(player: Player): Tool?
	for _, container in { player:FindFirstChildOfClass("Backpack"), player.Character } do
		if container then
			for _, child in container:GetChildren() do
				if child:IsA("Tool") and child:GetAttribute("HeroWeapon") then
					return child
				end
			end
		end
	end
	return nil
end

-- One Tool in the hotbar: the hero's gun. Safe to call any time.
local function syncTool(player: Player)
	local s = stateOf(player)
	local tool = findTool(player)
	if not s.hero then
		if tool then
			tool:Destroy()
		end
		return
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not tool then
		if not backpack then
			return
		end
		tool = Instance.new("Tool")
		assert(tool)
		tool.RequiresHandle = true
		tool.CanBeDropped = false
		tool:SetAttribute("HeroWeapon", true)
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.4, 0.5, 2)
		handle.Material = Enum.Material.SmoothPlastic
		handle.CanCollide = false
		handle.Massless = true
		handle.Parent = tool
		tool.Parent = backpack
	end
	local hero = Config.Heroes[s.hero]
	local maxed = Progression.masteryLevel(player, s.hero) >= #Config.Mastery
	tool.Name = hero.weapon ~= "" and hero.weapon or hero.display
	tool.ToolTip = `{hero.display} · {hero.ability} (F)`
	local handle = tool:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") then
		-- Mastery skin: a gold gun at max mastery.
		handle.Color = if maxed then MASTERY_GOLD else (HERO_COLORS[s.hero] or Color3.new(1, 1, 1))
		handle.Material = if maxed then Enum.Material.Neon else Enum.Material.SmoothPlastic
	end
end

local function refresh(player: Player, refill: boolean)
	local s = stateOf(player)
	s.stats = if s.hero then HeroStats.compute(s.hero, s.tiers, s.gear) else nil
	if s.stats and refill then
		s.ammo = s.stats.magazine
		s.reloadUntil = 0
	end
	syncTool(player)
	publish(player)
end

------------------------------------------------------------------ picking and upgrading

local function pick(player: Player, key: unknown): (boolean, string)
	if typeof(key) ~= "string" or not Config.Heroes[key] then
		return false, "Unknown hero"
	end
	if not Progression.ownsHero(player, key) then
		return false, `Unlock {Config.Heroes[key].display} with {Theme.Currency} first (M)`
	end
	local s = stateOf(player)
	local building = ReplicatedStorage:GetAttribute("State") ~= "Playing"
	if s.hero and not building then
		return false, "Heroes lock when the game starts"
	end
	if s.hero == key then
		return true, `{Config.Heroes[key].display} it is`
	end
	if s.spent > 0 then
		Economy.earn(s.spent) -- switching in the build phase refunds every upgrade
	end
	s.hero = key
	s.tiers = { 0, 0, 0 }
	s.spent = 0
	local rewards = Progression.masteryRewards(Progression.masteryLevel(player, key))
	s.freeUpgrade = rewards ~= nil and rewards.freeFirstUpgrade == true
	s.bloom = 0
	s.abilityReadyAt = 0
	refresh(player, true)
	return true, `{Config.Heroes[key].display} it is`
end

local REFUSALS = {
	maxed = "That path is maxed",
	["third path"] = "Only two paths can be opened",
	crossover = "Only one path can go past tier 2",
}

local function upgrade(player: Player, pathIndex: unknown): (boolean, string)
	local s = stateOf(player)
	if not s.hero then
		return false, "Pick a hero first"
	end
	if typeof(pathIndex) ~= "number" then
		return false, "Unknown upgrade"
	end
	local path = Config.Heroes[s.hero].paths[pathIndex]
	if not path then
		return false, "Unknown upgrade"
	end
	local rewards = mastery(player, s)
	local why = Upgrades.check(s.tiers, pathIndex, #path.tiers, if rewards then rewards.crossoverCap else nil)
	if why ~= "ok" then
		return false, REFUSALS[why] or "Can't upgrade that"
	end
	local step = path.tiers[s.tiers[pathIndex] + 1]
	-- Mastery: a discount on every upgrade, and possibly the first one free.
	local discount = if rewards then rewards.upgradeDiscountPercent else 0
	local cost = if s.freeUpgrade then 0 else math.floor(step.cost * (1 - discount / 100) + 0.5)
	if not Economy.trySpend(cost) then
		return false, "Not enough cash"
	end
	s.freeUpgrade = false
	s.tiers[pathIndex] += 1
	s.spent += cost
	refresh(player, true) -- a fresh magazine with every upgrade
	return true, `{step.name}!`
end

------------------------------------------------------------------ reloading

local function finishReloadIfDue(player: Player, s: State)
	if s.reloadUntil > 0 and os.clock() >= s.reloadUntil and s.stats then
		s.reloadUntil = 0
		s.ammo = s.stats.magazine
		publish(player)
	end
end

local function startReload(player: Player, s: State)
	local stats = s.stats
	if not stats or s.reloadUntil > 0 or s.ammo >= stats.magazine then
		return
	end
	s.reloadUntil = os.clock() + stats.reload
	publish(player)
	task.delay(stats.reload, function()
		if states[player] == s then
			finishReloadIfDue(player, s)
		end
	end)
end

------------------------------------------------------------------ guard

local function guard(guards: { [any]: Guard }, target: any, percent: number, seconds: number)
	if percent <= 0 or seconds <= 0 then
		return
	end
	local now = os.clock()
	local old = guards[target]
	local active = old ~= nil and now < old.untilTime
	guards[target] = {
		percent = if active and old then math.max(old.percent, percent) else percent,
		untilTime = if active and old then math.max(old.untilTime, now + seconds) else now + seconds,
	}
end

local function guardFrom(guards: { [any]: Guard }, target: any): number
	local g = guards[target]
	return if g and os.clock() < g.untilTime then g.percent else 0
end

------------------------------------------------------------------ shooting

local function canHit(enemy: Enemies.Enemy, stats: HeroStats.Stats): boolean
	if enemy.def.flying and not stats.hitsAir then
		return false
	end
	return Enemies.canHurt(enemy, stats.piercesArmor)
end

-- A random direction inside a cone of `degrees` around `direction`.
local random = Random.new()
local function scatter(direction: Vector3, degrees: number): Vector3
	if degrees <= 0 then
		return direction
	end
	local frame = CFrame.lookAt(Vector3.zero, direction)
	local angle = math.rad(degrees) * math.sqrt(random:NextNumber())
	local around = random:NextNumber() * 2 * math.pi
	return (frame * CFrame.Angles(0, 0, around) * CFrame.Angles(angle, 0, 0)).LookVector
end

-- Enemies a pellet passes through, nearest first: in weapon range of the
-- player, in front of the camera, and within aim assist of the ray.
local function alongRay(origin: Vector3, direction: Vector3, from: Vector3, stats: HeroStats.Stats, live, count: number): { Enemies.Enemy }
	local hits = {}
	local assist = Config.Tuning.WeaponAimAssist
	for _, enemy in live do
		local position = enemy.part.Position
		if canHit(enemy, stats) and (position - from).Magnitude <= stats.range then
			local along = (position - origin):Dot(direction)
			if along > 0 and (origin + direction * along - position).Magnitude <= assist then
				table.insert(hits, { enemy = enemy, along = along })
			end
		end
	end
	table.sort(hits, function(a, b)
		return a.along < b.along
	end)
	local result = {}
	for i = 1, math.min(count, #hits) do
		table.insert(result, hits[i].enemy)
	end
	return result
end

type Outcome = { hit: boolean, killed: boolean }

-- One enemy taking a round: damage, then what the round does on impact.
local function impact(player: Player, stats: HeroStats.Stats, enemy: Enemies.Enemy, live, outcome: Outcome)
	if not enemy.alive then
		return
	end
	outcome.hit = true
	local scale = levelScale(stateOf(player))
	local damage = stats.damage * scale * (if Enemies.isMarked(enemy) then stats.markedDamageMult else 1)
	local distance, position, flying = enemy.distance, enemy.part.Position, enemy.def.flying

	if stats.markPercent > 0 then
		Enemies.mark(enemy, stats.markPercent, Config.Tuning.MarkDuration)
	end
	-- Ignite before the damage, so if this round shrinks the dino, the smaller
	-- size keeps the fire.
	if stats.igniteShare > 0 then
		Hazards.ignite(enemy, stats.shotDamage * scale * stats.igniteShare, stats.igniteSeconds, stats.piercesArmor, player)
	end
	Enemies.knockback(enemy, stats.knockback)
	-- Muzzle rounds, before the damage so a shrunk dino keeps them.
	if stats.slowPercent > 0 then
		Enemies.chill(enemy, {
			slowPercent = stats.slowPercent,
			seconds = stats.slowSeconds,
			affectsBosses = false,
			brittlePercent = 0,
			stripsArmor = false,
		})
	end
	if stats.jawLockSeconds > 0 then
		for _, other in live do
			if other == enemy or (stats.jawLockSpread > 0 and (other.part.Position - position).Magnitude <= stats.jawLockSpread) then
				local spread = other ~= enemy -- Lullaby Rounds: the strap flashes
				if other.def.boss then
					Enemies.disarm(other, stats.jawLockSeconds * Config.Tuning.BossJawLockX, true, spread)
				else
					Enemies.disarm(other, stats.jawLockSeconds, false, spread)
				end
			end
		end
	end
	local killed = Enemies.damage(enemy, damage, stats.piercesArmor)
	credit(player, killed)
	outcome.killed = outcome.killed or killed

	if stats.splashRadius > 0 then
		for _, other in live do
			if other ~= enemy and canHit(other, stats) and (other.part.Position - position).Magnitude <= stats.splashRadius then
				local splashKill = Enemies.damage(other, damage, stats.piercesArmor)
				credit(player, splashKill)
				outcome.killed = outcome.killed or splashKill
			end
		end
	end
	if not flying then
		Hazards.burn(distance, stats.splashRadius, stats.burnDps * scale, stats.burnSeconds, stats.piercesArmor, player)
	end
end

-- Ricochet: hop from `from` to the nearest enemy not hit yet, `bounces` times.
local function ricochet(player: Player, stats: HeroStats.Stats, from: Enemies.Enemy, live, hit: { [any]: boolean }, color: Color3, outcome: Outcome)
	local lastPosition = from.part.Position
	for _ = 1, stats.bounces do
		local best, bestGap = nil, Config.Tuning.RicochetReach
		for _, enemy in live do
			if not hit[enemy] and canHit(enemy, stats) then
				local gap = (enemy.part.Position - lastPosition).Magnitude
				if gap <= bestGap then
					best, bestGap = enemy, gap
				end
			end
		end
		if not best then
			return
		end
		hit[best] = true
		Effects.tracer(lastPosition, best.part.Position, color)
		lastPosition = best.part.Position
		impact(player, stats, best, live, outcome)
	end
end

local function trigger(player: Player, rayOrigin: unknown, rayDirection: unknown)
	if gameOver() then
		return
	end
	local s = stateOf(player)
	local stats = s.stats
	local body = root(player)
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	if not stats or not body or not tool or not tool:GetAttribute("HeroWeapon") then
		return
	end
	local origin, direction = validRay(player, body, rayOrigin, rayDirection)
	if not origin or not direction then
		return
	end

	finishReloadIfDue(player, s)
	if s.reloadUntil > 0 then
		return
	end
	if s.ammo <= 0 then
		startReload(player, s)
		return
	end

	-- Fire rate: dual guns alternate; Overdrive and Spin-Up speed it up.
	local now = os.clock()
	local sinceLast = now - s.lastShot
	s.spinTime = if sinceLast <= SPIN_KEEP then s.spinTime + sinceLast else 0
	local spin = 1 + (stats.spinUp - 1) * math.min(1, s.spinTime / Config.Tuning.SpinUpTime)
	local overdrive = now < s.overdriveUntil
	local rate = stats.rate * stats.guns * spin * (if overdrive then Config.Tuning.OverdriveFireRateX else 1)
	if sinceLast < SHOT_GAP_SLACK / rate then
		return
	end
	s.lastShot = now

	-- Recoil settles over time, then this pull adds to it.
	s.bloom = math.max(0, s.bloom - stats.recoilRecovery * (now - s.bloomAt))
	s.bloomAt = now
	local cone = stats.spread + s.bloom

	local handle = tool:FindFirstChild("Handle")
	local muzzle = if handle and handle:IsA("BasePart") then handle.Position else body.Position
	if stats.guns > 1 then
		s.gunSide = -s.gunSide
		muzzle += body.CFrame.RightVector * DUAL_GUN_OFFSET * s.gunSide
	end
	local color = HERO_COLORS[s.hero or ""] or Color3.new(1, 1, 1)
	local live = Enemies.getLive()
	local outcome: Outcome = { hit = false, killed = false }

	for _ = 1, stats.shotsPerTrigger do
		for _ = 1, stats.pellets do
			local pelletDirection = scatter(direction, cone)
			local struck = alongRay(origin, pelletDirection, body.Position, stats, live, stats.pierce)
			if #struck == 0 then
				Effects.tracer(muzzle, origin + pelletDirection * ((muzzle - origin).Magnitude + stats.range), color)
			else
				Effects.tracer(muzzle, struck[#struck].part.Position, color)
				local hit: { [any]: boolean } = {}
				for _, enemy in struck do
					hit[enemy] = true
					impact(player, stats, enemy, live, outcome)
				end
				if stats.bounces > 0 then
					ricochet(player, stats, struck[#struck], live, hit, color, outcome)
				end
			end
		end
	end

	local speed = body.AssemblyLinearVelocity.Magnitude
	local recoil = stats.recoilPerShot * stats.shotsPerTrigger * (if speed < Config.Tuning.StillSpeed then stats.stillRecoilMult else 1)
	s.bloom = math.min(stats.recoilMax, s.bloom + recoil)

	if not (stats.beltFed and overdrive) then
		s.ammo = math.max(0, s.ammo - stats.shotsPerTrigger)
	end
	publish(player)
	if s.ammo <= 0 then
		startReload(player, s)
	end
	if outcome.hit then
		fireEvent:FireClient(player, outcome.killed)
	end
end

------------------------------------------------------------------ ability

local function ability(player: Player, rayOrigin: unknown, rayDirection: unknown): (boolean, string)
	local s = stateOf(player)
	local stats = s.stats
	local body = root(player)
	if not s.hero or not stats or not body then
		return false, "Pick a hero first"
	end
	local origin, direction = validRay(player, body, rayOrigin, rayDirection)
	if not origin or not direction then
		return false, "Aim somewhere"
	end
	local hero = Config.Heroes[s.hero]
	local now = os.clock()
	if now < s.abilityReadyAt then
		return false, `{hero.ability} ready in {math.ceil(s.abilityReadyAt - now)}s`
	end
	local color = HERO_COLORS[s.hero] or Color3.new(1, 1, 1)

	if hero.abilityKind == "MARK" then
		-- Marks ignore armour and air limits: it's a paint, not a bullet.
		local markStats = table.clone(stats)
		markStats.hitsAir = true
		markStats.piercesArmor = true
		local target = alongRay(origin, direction, body.Position, markStats, Enemies.getLive(), 1)[1]
		if not target then
			return false, "No dino there to dart"
		end
		Enemies.mark(target, stats.abilityPower, stats.abilitySeconds)
		Effects.part(Vector3.one * 3, CFrame.new(target.part.Position + Vector3.new(0, 3, 0)), color, 0.6, Enum.PartType.Ball)
	elseif hero.abilityKind == "OVERDRIVE" then
		s.overdriveUntil = now + stats.abilitySeconds
		s.overdrivePercent = stats.abilityPower
		s.overdriveRadius = stats.abilityRadius
		player:SetAttribute("OverdriveUntil", workspace:GetServerTimeNow() + stats.abilitySeconds)
		Effects.disc(body.Position - Vector3.new(0, 2.8, 0), stats.abilityRadius, color, 0.5, 0.7)
	elseif hero.abilityKind == "AIRBURST" then
		if direction.Y >= -0.01 then
			return false, "Aim at the ground"
		end
		local aim = origin + direction * ((Track.GroundTop - origin.Y) / direction.Y)
		if (aim - body.Position).Magnitude > Config.Tuning.AirburstReach then
			return false, "Too far away"
		end
		local centre = Enemies.trackDistanceNear(aim)
		local ground = Enemies.pointAt(centre) + Vector3.new(0, 0.5, 0)
		local delay = Config.Tuning.AirburstDelay
		local power, stun, radius = stats.abilityPower * levelScale(s), stats.abilitySeconds, stats.abilityRadius
		Effects.disc(ground, radius, color, delay, 0.75) -- the warning
		task.delay(delay, function()
			Effects.part(Vector3.one * radius * 2, CFrame.new(ground), color, 0.25, Enum.PartType.Ball).Transparency = 0.4
			for _, enemy in Enemies.getLive() do
				if math.abs(enemy.distance - centre) <= radius then
					Enemies.stun(enemy, stun)
					credit(player, Enemies.damage(enemy, power, true))
				end
			end
		end)
	elseif hero.abilityKind == "HEAL" then
		-- Flat heal, no level scaling (DECISIONS #13).
		local radius = stats.healRadius
		for _, other in Players:GetPlayers() do
			local otherBody = root(other)
			if otherBody and (otherBody.Position - body.Position).Magnitude <= radius then
				Health.heal(other, stats.heal)
				guard(playerGuards, other, stats.guardPercent, stats.guardSeconds)
			end
		end
		if stats.healRepairsTowers then
			for _, tower in Towers.targets() do
				if (tower.position - body.Position).Magnitude <= radius then
					Towers.heal(tower, stats.heal)
					guard(towerGuards, tower, stats.guardPercent, stats.guardSeconds)
				end
			end
		end
		Effects.disc(body.Position - Vector3.new(0, 2.8, 0), radius, color, 0.5, 0.7)
	else
		return false, "No ability"
	end

	local rewards = mastery(player, s)
	s.abilityReadyAt = now + stats.abilityCooldown * (if rewards then rewards.abilityCooldownMult else 1)
	publish(player)
	return true, `{hero.ability}!`
end

------------------------------------------------------------------ public

-- Between matches: everyone keeps their hero pick but starts over — no
-- upgrades, a full magazine, level 1, ability ready, first upgrade free again
-- with mastery 10+.
function Hero.resetMatch()
	teamLevel = 1
	for player, s in states do
		s.tiers = { 0, 0, 0 }
		s.spent = 0
		s.bloom = 0
		s.level = 1
		s.abilityReadyAt = 0
		s.overdriveUntil = 0
		local rewards = mastery(player, s)
		s.freeUpgrade = rewards ~= nil and rewards.freeFirstUpgrade == true
		player:SetAttribute("OverdriveUntil", 0)
		refresh(player, true)
	end
	table.clear(playerGuards)
	table.clear(towerGuards)
end

-- Mastery was just bought: apply a new free first upgrade (if nothing has
-- been bought yet this match) and the gold gun right away.
function Hero.masteryChanged(player: Player)
	local s = states[player]
	if not s or not s.hero then
		return
	end
	local rewards = mastery(player, s)
	if s.spent == 0 and s.tiers[1] + s.tiers[2] + s.tiers[3] == 0 then
		s.freeUpgrade = rewards ~= nil and rewards.freeFirstUpgrade == true
	end
	syncTool(player)
	publish(player)
end

-- Level every hero (and anyone who joins later) to `level`; each player's
-- level shows on their HeroLevel attribute.
function Hero.setLevel(level: number)
	teamLevel = level
	for player, s in states do
		s.level = level
		publish(player)
	end
end

-- Overdrive: the strongest active boost from a player standing near this point.
function Hero.towerRateBoost(position: Vector3): number
	local now = os.clock()
	local best = 0
	for player, s in states do
		if now < s.overdriveUntil and s.overdrivePercent > best then
			local body = root(player)
			if body and (body.Position - position).Magnitude <= s.overdriveRadius then
				best = s.overdrivePercent
			end
		end
	end
	return best
end

-- Second Wind: this hunter's guard right now (a resistance percent for Health).
function Hero.guardOf(player: Player): number
	return guardFrom(playerGuards, player)
end

-- Second Wind: this tower's guard right now (a resistance percent for Towers).
function Hero.towerGuardOf(tower: any): number
	return guardFrom(towerGuards, tower)
end

function Hero.init(remotes: Folder, hooks: { onPop: ((Player) -> ())?, gearAt: ((Vector3) -> HeroStats.Gear)? }?)
	onPop = hooks and hooks.onPop
	gearAt = hooks and hooks.gearAt

	-- Outfitter Armory buffs follow the hunter around: a few times a second,
	-- re-read what covers where they stand; publish it (Gear* attributes, so
	-- the client's fire loop agrees) and recompute the gun when it changes.
	if gearAt then
		local since = 0
		RunService.Heartbeat:Connect(function(dt)
			since += dt
			if since < GEAR_CHECK then
				return
			end
			since = 0
			for player, s in states do
				local body = root(player)
				local gear = if body and gearAt then gearAt(body.Position) else HeroStats.NO_GEAR
				local old = s.gear
				if gear.recoilMult ~= old.recoilMult or gear.reloadMult ~= old.reloadMult or gear.spreadMult ~= old.spreadMult or gear.ratePercent ~= old.ratePercent then
					s.gear = gear
					player:SetAttribute("GearRecoil", gear.recoilMult)
					player:SetAttribute("GearReload", gear.reloadMult)
					player:SetAttribute("GearSpread", gear.spreadMult)
					player:SetAttribute("GearRate", gear.ratePercent)
					refresh(player, false)
				end
			end
		end)
	end

	local request = Instance.new("RemoteFunction")
	request.Name = "HeroRequest"
	-- ("pick", heroKey), ("upgrade", pathIndex), ("reload"), ("ability", rayOrigin, rayDirection)
	request.OnServerInvoke = function(player: Player, action: unknown, a: unknown, b: unknown)
		local ok, success, message = pcall(function()
			if gameOver() then
				return false, "The game is over"
			end
			if action == "pick" then
				return pick(player, a)
			elseif action == "upgrade" then
				return upgrade(player, a)
			elseif action == "reload" then
				startReload(player, stateOf(player))
				return true, "Reloading"
			elseif action == "ability" then
				return ability(player, a, b)
			end
			return false, "Unknown request"
		end)
		if not ok then
			warn(`[Hero] request from {player.Name} failed: {success}`)
			return false, "Something went wrong"
		end
		return success, message
	end
	request.Parent = remotes

	-- Client -> server: (rayOrigin, rayDirection) per trigger pull.
	-- Server -> shooter: (killed) when a pull hit something.
	fireEvent = Instance.new("RemoteEvent")
	fireEvent.Name = "HeroFire"
	fireEvent.OnServerEvent:Connect(function(player, origin, direction)
		local ok, err = pcall(trigger, player, origin, direction)
		if not ok then
			warn(`[Hero] fire from {player.Name} failed: {err}`)
		end
	end)
	fireEvent.Parent = remotes

	local function setUp(player: Player)
		stateOf(player)
		publish(player)
		-- The Backpack is rebuilt on every respawn; put the gun back.
		player.CharacterAdded:Connect(function()
			task.defer(syncTool, player)
		end)
	end
	Players.PlayerAdded:Connect(setUp)
	for _, player in Players:GetPlayers() do
		setUp(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
		playerGuards[player] = nil
	end)
end

return Hero
