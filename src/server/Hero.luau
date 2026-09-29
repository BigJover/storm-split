--[[
	Hero: the player character is the hero (design doc §02, VISION.md).

	Each player buys tiers of three weapon types — Precision, Sustained,
	Ordnance — with the team's shared cash. The same crossover rule as towers
	applies (Shared/Upgrades): at most two weapon types, and only one past
	tier 2. Every owned weapon is a Tool in the player's hotbar, named after
	its tier ("Marksman rifle").

	Tier 2 of each type unlocks its ability; a second weapon type is capped at
	tier 2, so its ability stays at its weakest form ("commit for power, split
	for flexibility"):
	  Mark (Precision)     the enemy nearest your aim takes +power% damage from
	                       everything for (s) seconds; the mark passes to its splits
	  Overdrive (Sustained) for (s) seconds your fire rate is x OverdriveFireRateX
	                       and towers within the radius fire +power% faster
	  Airburst (Ordnance)  after AirburstDelay, the stretch of track nearest your
	                       aim takes `power` damage and everything there is stunned

	SERVER AUTHORITATIVE: a client only says "I fired, aiming here" or "use my
	ability here". The server checks the equipped weapon, the fire rate, the
	range and the cooldown, and picks what gets hit itself.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Upgrades = require(Shared:WaitForChild("Upgrades"))

local Economy = require(script.Parent.Economy)
local Effects = require(script.Parent.Effects)
local Enemies = require(script.Parent.Enemies)

local Hero = {}

type State = {
	tiers: { number }, -- by index in Config.WeaponOrder
	lastShot: number,
	abilityReadyAt: { [string]: number }, -- os.clock() time, per weapon type
	overdriveUntil: number,
	overdrivePercent: number,
	overdriveRadius: number,
}

-- Visuals only.
local WEAPON_COLORS = {
	PRECISION = Color3.fromRGB(255, 90, 110),
	SUSTAINED = Color3.fromRGB(255, 220, 90),
	ORDNANCE = Color3.fromRGB(255, 140, 50),
}
local SHOT_GAP_SLACK = 0.8 -- accept shots up to 20% early, for network jitter

local states: { [Player]: State } = {}
local onPop: ((Player) -> ())? = nil

------------------------------------------------------------------ state

local function stateOf(player: Player): State
	local state = states[player]
	if not state then
		local tiers = {}
		for i = 1, #Config.WeaponOrder do
			tiers[i] = 0
		end
		state = {
			tiers = tiers,
			lastShot = 0,
			abilityReadyAt = {},
			overdriveUntil = 0,
			overdrivePercent = 0,
			overdriveRadius = 0,
		}
		states[player] = state
	end
	return state
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

-- The weapon in the player's hands and its tier, if it's one of ours.
local function equipped(player: Player): (string?, number, Tool?)
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	local key = tool and tool:GetAttribute("WeaponType")
	if typeof(key) ~= "string" then
		return nil, 0, nil
	end
	local index = table.find(Config.WeaponOrder, key)
	local tier = if index then stateOf(player).tiers[index] else 0
	return key, tier, tool
end

local function isFinite(v: Vector3): boolean
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z and v.Magnitude < 1e6
end

------------------------------------------------------------------ tools

local function findTool(player: Player, key: string): Tool?
	for _, container in { player:FindFirstChildOfClass("Backpack"), player.Character } do
		if container then
			for _, child in container:GetChildren() do
				if child:IsA("Tool") and child:GetAttribute("WeaponType") == key then
					return child
				end
			end
		end
	end
	return nil
end

local function makeTool(key: string): Tool
	local tool = Instance.new("Tool")
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("WeaponType", key)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 0.5, 2)
	handle.Color = WEAPON_COLORS[key] or Color3.new(1, 1, 1)
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool
	return tool
end

-- Makes the hotbar match what the player owns. Safe to call any time.
local function syncTools(player: Player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	local state = stateOf(player)
	for index, key in Config.WeaponOrder do
		local tier = state.tiers[index]
		local tool = findTool(player, key)
		if tier == 0 then
			if tool then
				tool:Destroy()
			end
		else
			if not tool then
				tool = makeTool(key)
				tool.Parent = backpack
			end
			assert(tool)
			local step = Config.Weapons[key].tiers[tier]
			tool.Name = step.name
			tool.ToolTip = `{Config.Weapons[key].display} {tier}`
			tool:SetAttribute("Tier", tier)
		end
	end
end

local function publish(player: Player)
	local state = stateOf(player)
	for index, key in Config.WeaponOrder do
		player:SetAttribute(`Weapon_{key}`, state.tiers[index])
	end
end

------------------------------------------------------------------ buying

local REFUSALS = {
	maxed = "That weapon is maxed",
	["third path"] = "You can only carry two weapon types",
	crossover = "Only one weapon type can go past tier 2",
}

local function buy(player: Player, key: unknown): (boolean, string)
	if typeof(key) ~= "string" then
		return false, "Unknown weapon"
	end
	local index = table.find(Config.WeaponOrder, key)
	local def = Config.Weapons[key]
	if not index or not def then
		return false, "Unknown weapon"
	end
	local state = stateOf(player)
	local why = Upgrades.check(state.tiers, index, #def.tiers)
	if why ~= "ok" then
		return false, REFUSALS[why] or "Can't buy that"
	end
	local step = def.tiers[state.tiers[index] + 1]
	if not Economy.trySpend(step.cost) then
		return false, "Not enough cash"
	end
	state.tiers[index] += 1
	syncTools(player)
	publish(player)
	return true, `{step.name}!`
end

------------------------------------------------------------------ firing

local function canHit(enemy: Enemies.Enemy, row): boolean
	if enemy.def.flying and not row.hitsAir then
		return false
	end
	return Enemies.canHurt(enemy, row.piercesArmor)
end

-- The hittable enemy in range that is nearest (flat) to the aim point, within aim assist.
local function nearestTo(aim: Vector3, from: Vector3, row, live): Enemies.Enemy?
	local best, bestGap = nil, Config.Tuning.WeaponAimAssist
	for _, enemy in live do
		if canHit(enemy, row) and (enemy.part.Position - from).Magnitude <= row.range then
			local offset = enemy.part.Position - aim
			local gap = Vector2.new(offset.X, offset.Z).Magnitude
			if gap <= bestGap then
				best, bestGap = enemy, gap
			end
		end
	end
	return best
end

-- Extra targets: a splash around the primary if the weapon has one, otherwise
-- a line through the enemies right behind it (Railgun "pierces a lane").
local function extraTargets(primary: Enemies.Enemy, row, live): { Enemies.Enemy }
	local extra = {}
	local wanted = math.floor(row.targets) - 1
	if wanted <= 0 then
		return extra
	end
	local candidates = {}
	for _, enemy in live do
		if enemy ~= primary and canHit(enemy, row) then
			if row.splashRadius > 0 then
				if (enemy.part.Position - primary.part.Position).Magnitude <= row.splashRadius then
					table.insert(candidates, enemy)
				end
			else
				local gap = primary.distance - enemy.distance
				if gap >= 0 and gap <= Config.Tuning.LinePierceReach then
					table.insert(candidates, enemy)
				end
			end
		end
	end
	table.sort(candidates, function(a, b)
		return math.abs(a.distance - primary.distance) < math.abs(b.distance - primary.distance)
	end)
	for i = 1, math.min(wanted, #candidates) do
		table.insert(extra, candidates[i])
	end
	return extra
end

local function fire(player: Player, aim: unknown)
	if typeof(aim) ~= "Vector3" or not isFinite(aim) then
		return
	end
	local state = ReplicatedStorage:GetAttribute("State")
	if state == "GameOver" or state == "Victory" then
		return
	end
	local key, tier, tool = equipped(player)
	local body = root(player)
	if not key or tier <= 0 or not body then
		return
	end

	local s = stateOf(player)
	local row = Config.Weapons[key].tiers[tier]
	local now = os.clock()
	local rate = row.rate * (if now < s.overdriveUntil then Config.Tuning.OverdriveFireRateX else 1)
	if now - s.lastShot < SHOT_GAP_SLACK / rate then
		return -- faster than the weapon can fire
	end
	s.lastShot = now

	local handle = tool and tool:FindFirstChild("Handle")
	local muzzle = if handle and handle:IsA("BasePart") then handle.Position else body.Position
	local live = Enemies.getLive()
	local primary = nearestTo(aim, body.Position, row, live)
	local color = WEAPON_COLORS[key] or Color3.new(1, 1, 1)

	if not primary then
		-- A miss: draw it, capped at the weapon's range.
		local direction = aim - muzzle
		local reach = math.min(direction.Magnitude, row.range)
		if reach > 0.1 then
			Effects.tracer(muzzle, muzzle + direction.Unit * reach, color)
		end
		return
	end

	Effects.tracer(muzzle, primary.part.Position, color)
	for _, enemy in { primary, table.unpack(extraTargets(primary, row, live)) } do
		credit(player, Enemies.damage(enemy, row.damage, row.piercesArmor))
	end
end

------------------------------------------------------------------ abilities

local function ability(player: Player, aim: unknown): (boolean, string)
	if typeof(aim) ~= "Vector3" or not isFinite(aim) then
		return false, "Aim somewhere"
	end
	local key, tier = equipped(player)
	local body = root(player)
	if not key or not body then
		return false, "Equip a weapon first"
	end
	if tier < 2 then
		return false, `{Config.Weapons[key].ability} unlocks at tier 2`
	end

	local s = stateOf(player)
	local now = os.clock()
	local readyAt = s.abilityReadyAt[key] or 0
	if now < readyAt then
		return false, `{Config.Weapons[key].ability} ready in {math.ceil(readyAt - now)}s`
	end
	local row = Config.Weapons[key].tiers[tier]
	local color = WEAPON_COLORS[key] or Color3.new(1, 1, 1)

	if key == "PRECISION" then
		local target = nearestTo(aim, body.Position, row, Enemies.getLive())
		if not target then
			return false, "No enemy there to mark"
		end
		Enemies.mark(target, row.abilityPower, row.abilitySeconds)
		Effects.part(Vector3.one * 3, CFrame.new(target.part.Position + Vector3.new(0, 3, 0)), color, 0.6, Enum.PartType.Ball)
	elseif key == "SUSTAINED" then
		s.overdriveUntil = now + row.abilitySeconds
		s.overdrivePercent = row.abilityPower
		s.overdriveRadius = row.abilityRadius
		player:SetAttribute("OverdriveUntil", workspace:GetServerTimeNow() + row.abilitySeconds)
		Effects.disc(body.Position - Vector3.new(0, 2.8, 0), row.abilityRadius, color, 0.5, 0.7)
	elseif key == "ORDNANCE" then
		if (aim - body.Position).Magnitude > row.range then
			return false, "Too far away"
		end
		local centre = Enemies.trackDistanceNear(aim)
		local ground = Enemies.pointAt(centre) + Vector3.new(0, 0.5, 0)
		local delay = Config.Tuning.AirburstDelay
		Effects.disc(ground, row.abilityRadius, color, delay, 0.75) -- the warning
		task.delay(delay, function()
			Effects.part(Vector3.one * row.abilityRadius * 2, CFrame.new(ground), color, 0.25, Enum.PartType.Ball).Transparency = 0.4
			for _, enemy in Enemies.getLive() do
				if math.abs(enemy.distance - centre) <= row.abilityRadius then
					Enemies.stun(enemy, row.abilitySeconds)
					credit(player, Enemies.damage(enemy, row.abilityPower, true))
				end
			end
		end)
	else
		return false, "No ability"
	end

	s.abilityReadyAt[key] = now + row.cooldown
	player:SetAttribute(`AbilityReadyAt_{key}`, workspace:GetServerTimeNow() + row.cooldown)
	return true, `{Config.Weapons[key].ability}!`
end

------------------------------------------------------------------ public

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

function Hero.init(remotes: Folder, hooks: { onPop: ((Player) -> ())? }?)
	onPop = hooks and hooks.onPop

	local request = Instance.new("RemoteFunction")
	request.Name = "HeroRequest"
	-- ("buy", weaponKey) or ("ability", aimPoint)
	request.OnServerInvoke = function(player: Player, action: unknown, a: unknown)
		local ok, success, message = pcall(function()
			local state = ReplicatedStorage:GetAttribute("State")
			if state == "GameOver" or state == "Victory" then
				return false, "The game is over"
			end
			if action == "buy" then
				return buy(player, a)
			elseif action == "ability" then
				return ability(player, a)
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

	local fireEvent = Instance.new("RemoteEvent")
	fireEvent.Name = "HeroFire"
	fireEvent.OnServerEvent:Connect(function(player, aim)
		local ok, err = pcall(fire, player, aim)
		if not ok then
			warn(`[Hero] fire from {player.Name} failed: {err}`)
		end
	end)
	fireEvent.Parent = remotes

	local function setUp(player: Player)
		stateOf(player)
		publish(player)
		-- The Backpack is rebuilt on every respawn; put the weapons back.
		player.CharacterAdded:Connect(function()
			task.defer(syncTools, player)
		end)
		if player.Character then
			task.defer(syncTools, player)
		end
	end
	Players.PlayerAdded:Connect(setUp)
	for _, player in Players:GetPlayers() do
		setUp(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
end

return Hero
