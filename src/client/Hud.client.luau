--[[
	Minimal HUD: round, lives, enemies alive. Reads ReplicatedStorage
	attributes set by the server, so it needs no RemoteEvents.
	Phase 2 adds cash and the shop panel.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "StormSplitHud"
gui.ResetOnSpawn = false

local label = Instance.new("TextLabel")
label.Name = "Status"
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, 12)
label.Size = UDim2.fromOffset(420, 40)
label.BackgroundColor3 = Color3.fromRGB(24, 20, 34)
label.BackgroundTransparency = 0.25
label.TextColor3 = Color3.fromRGB(240, 236, 250)
label.Font = Enum.Font.GothamBold
label.TextSize = 18
label.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = label

local function attr(name: string, default: any): any
	local value = ReplicatedStorage:GetAttribute(name)
	if value == nil then
		return default
	end
	return value
end

local function refresh()
	local state = attr("State", "Waiting")
	local round = math.floor(attr("Round", 0))
	local lives = math.floor(attr("Lives", 0))
	local alive = math.floor(attr("Alive", 0))

	if state == "GameOver" then
		label.Text = `GAME OVER  ·  reached round {round}`
		label.TextColor3 = Color3.fromRGB(255, 120, 140)
	elseif state == "Victory" then
		label.Text = "VICTORY  ·  all rounds cleared"
		label.TextColor3 = Color3.fromRGB(140, 240, 170)
	elseif state == "Waiting" then
		label.Text = "Starting…"
	else
		label.Text = `Round {round}  ·  Lives {lives}  ·  Enemies {alive}`
	end
end

for _, name in { "State", "Round", "Lives", "Alive" } do
	ReplicatedStorage:GetAttributeChangedSignal(name):Connect(refresh)
end
refresh()

gui.Parent = player:WaitForChild("PlayerGui")
