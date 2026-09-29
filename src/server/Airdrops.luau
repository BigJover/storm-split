--[[
	Airdrops (Quartermaster's Airdrop path): at the start of each round, chests
	land around each airdropping Quartermaster. A player runs over one to add
	its cash to the team's pot. Uncollected chests vanish after ChestLifetime.

	Collection is server-side (Touched on the server, checked against a real
	player's character), so a client can't claim a chest it isn't touching.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Placement = require(Shared:WaitForChild("Placement"))

local Economy = require(script.Parent.Economy)
local Towers = require(script.Parent.Towers)

local Airdrops = {}

-- Visuals only.
local CHEST_SIZE = Vector3.new(2.5, 2, 2)
local CHEST_COLOR = Color3.fromRGB(250, 205, 80)

local folder: Instance
local random = Random.new()

function Airdrops.init(effectFolder: Instance)
	folder = effectFolder
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
	chest.Touched:Connect(function(part)
		if taken then
			return
		end
		local player = Players:GetPlayerFromCharacter(part.Parent)
		if not player then
			return
		end
		taken = true
		Economy.earn(cash)
		chest:Destroy()
	end)

	chest.Parent = folder
	task.delay(Config.Tuning.ChestLifetime, function()
		if chest.Parent then
			chest:Destroy()
		end
	end)
end

-- Called by Main at the start of every round.
function Airdrops.drop()
	for _, drop in Towers.airdrops() do
		for _ = 1, drop.count do
			local angle = random:NextNumber() * 2 * math.pi
			local reach = random:NextNumber() * Config.Tuning.ChestSpread
			local spot = Placement.ground(drop.base + Vector3.new(math.cos(angle) * reach, 0, math.sin(angle) * reach))
			spawnChest(spot, drop.cash)
		end
	end
end

return Airdrops
