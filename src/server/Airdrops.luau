--[[
	Airdrops (Supply Camp's Airdrop path): at the start of each round, chests
	land around each airdropping Supply Camp. A player runs over one to add
	its cash to the team's pot. Field Hospitals with Med Kits drop heal kits
	the same way: the hunter who runs over one heals (Server/Health).
	Uncollected chests and kits vanish after ChestLifetime.

	Collection is server-side (Touched on the server, checked against a real
	player's character), so a client can't claim a chest it isn't touching.
	A hunter with the Long Arms mastery perk also grabs drops within its reach
	(Shared/SmallPerks), checked here on the server every frame.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Placement = require(Shared:WaitForChild("Placement"))
local Combat = require(Shared:WaitForChild("Combat"))
local SmallPerks = require(Shared:WaitForChild("SmallPerks"))

local Economy = require(script.Parent.Economy)
local Health = require(script.Parent.Health)
local Towers = require(script.Parent.Towers)

local Airdrops = {}

-- Visuals only.
local CHEST_SIZE = Vector3.new(2.5, 2, 2)
local CHEST_COLOR = Color3.fromRGB(250, 205, 80)
local KIT_SIZE = Vector3.new(1.8, 1.2, 1.4)
local KIT_COLOR = Color3.fromRGB(235, 232, 220)
local KIT_CROSS = Color3.fromRGB(60, 190, 90) -- green "+", never a red cross

local folder: Instance
local random = Random.new()

-- Drops on the ground: the part and what picking it up does (false = this
-- player can't take it, e.g. a med kit at full health).
local live: { [BasePart]: (Player) -> boolean } = {}

local function reachPass()
	if next(live) == nil then
		return
	end
	for _, player in Players:GetPlayers() do
		local reach = SmallPerks.ofPlayer(player).pickupReach
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if reach > 0 and root and root:IsA("BasePart") then
			for part, claim in live do
				if part.Parent == nil then
					live[part] = nil -- cleared with the board
				elseif SmallPerks.inReach(SmallPerks.gap(root.Position, root.Size.X / 2, part.Position, part.Size), reach) then
					claim(player)
				end
			end
		end
	end
end

function Airdrops.init(effectFolder: Instance)
	folder = effectFolder
	RunService.Heartbeat:Connect(reachPass)
end

local function spawnChest(position: Vector3, cash: number)
	local chest = Instance.new("Part")
	chest.Name = "AirdropChest"
	chest.Size = CHEST_SIZE
	chest.Color = CHEST_COLOR
	chest.Material = Enum.Material.Neon
	chest.Anchored = true
	chest.CanCollide = false
	chest.CFrame = CFrame.new(position + Vector3.new(0, CHEST_SIZE.Y / 2, 0))
	chest:SetAttribute("Cash", cash)

	local label = Instance.new("BillboardGui")
	label.Size = UDim2.fromOffset(80, 24)
	label.StudsOffset = Vector3.new(0, 2.5, 0)
	label.AlwaysOnTop = true
	label.MaxDistance = 120
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextSize = 16
	text.TextColor3 = CHEST_COLOR
	text.TextStrokeTransparency = 0.3
	text.Text = `+{cash}`
	text.Parent = label
	label.Parent = chest

	local taken = false
	local function claim(_player: Player): boolean
		if taken then
			return false
		end
		taken = true
		live[chest] = nil
		Economy.earn(cash)
		chest:Destroy()
		return true
	end
	chest.Touched:Connect(function(part)
		local player = Players:GetPlayerFromCharacter(part.Parent)
		if player then
			claim(player)
		end
	end)

	chest.Parent = folder
	live[chest] = claim
	task.delay(Config.Tuning.ChestLifetime, function()
		live[chest] = nil
		if chest.Parent then
			chest:Destroy()
		end
	end)
end

-- A white med kit with a green "+". The hunter who touches it heals.
local function spawnKit(position: Vector3, heal: number)
	local kit = Instance.new("Part")
	kit.Name = "MedKit"
	kit.Size = KIT_SIZE
	kit.Color = KIT_COLOR
	kit.Material = Enum.Material.SmoothPlastic
	kit.Anchored = true
	kit.CanCollide = false
	kit.CFrame = CFrame.new(position + Vector3.new(0, KIT_SIZE.Y / 2, 0))
	kit:SetAttribute("Heal", heal)
	for _, size in { Vector3.new(0.3, 0.06, 1), Vector3.new(1, 0.06, 0.3) } do
		local bar = Instance.new("Part")
		bar.Size = size
		bar.Color = KIT_CROSS
		bar.Material = Enum.Material.Neon
		bar.Anchored = true
		bar.CanCollide = false
		bar.CanQuery = false
		bar.CanTouch = false
		bar.CFrame = kit.CFrame * CFrame.new(0, KIT_SIZE.Y / 2 + 0.03, 0)
		bar.Parent = kit
	end

	local label = Instance.new("BillboardGui")
	label.Size = UDim2.fromOffset(80, 24)
	label.StudsOffset = Vector3.new(0, 2, 0)
	label.AlwaysOnTop = true
	label.MaxDistance = 120
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextSize = 16
	text.TextColor3 = KIT_CROSS
	text.TextStrokeTransparency = 0.3
	text.Text = `+{heal} HP`
	text.Parent = label
	label.Parent = kit

	local taken = false
	local function claim(player: Player): boolean
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if taken or not humanoid or not Combat.takesMedKit(humanoid.Health, humanoid.MaxHealth) then
			return false
		end
		taken = true
		live[kit] = nil
		Health.heal(player, heal)
		kit:Destroy()
		return true
	end
	kit.Touched:Connect(function(part)
		local player = Players:GetPlayerFromCharacter(part.Parent)
		if player then
			claim(player)
		end
	end)

	kit.Parent = folder
	live[kit] = claim
	task.delay(Config.Tuning.ChestLifetime, function()
		live[kit] = nil
		if kit.Parent then
			kit:Destroy()
		end
	end)
end

local function landingSpot(base: Vector3): Vector3
	local angle = random:NextNumber() * 2 * math.pi
	local reach = random:NextNumber() * Config.Tuning.ChestSpread
	return Placement.ground(base + Vector3.new(math.cos(angle) * reach, 0, math.sin(angle) * reach))
end

-- Called by Main at the start of every round.
function Airdrops.drop()
	for _, drop in Towers.airdrops() do
		for _ = 1, drop.count do
			spawnChest(landingSpot(drop.base), drop.cash)
		end
	end
	for _, drop in Towers.medKits() do
		for _ = 1, drop.count do
			spawnKit(landingSpot(drop.base), drop.heal)
		end
	end
end

return Airdrops
