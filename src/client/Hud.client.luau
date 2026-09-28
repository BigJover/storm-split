--[[
	Minimal HUD: round, cash, lives, enemies alive, and the Start button for the
	build phase. Reads ReplicatedStorage attributes set by the server. Start is
	only a request; the server decides whether the game begins.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local startGame = remotes:WaitForChild("StartGame") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "StormSplitHud"
gui.ResetOnSpawn = false

local label = Instance.new("TextLabel")
label.Name = "Status"
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, 12)
label.Size = UDim2.fromOffset(520, 40)
label.BackgroundColor3 = Color3.fromRGB(24, 20, 34)
label.BackgroundTransparency = 0.25
label.TextColor3 = Color3.fromRGB(240, 236, 250)
label.Font = Enum.Font.GothamBold
label.TextSize = 18
label.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = label

local startButton = Instance.new("TextButton")
startButton.Name = "Start"
startButton.AnchorPoint = Vector2.new(0.5, 0)
startButton.Position = UDim2.new(0.5, 0, 0, 60)
startButton.Size = UDim2.fromOffset(220, 44)
startButton.BackgroundColor3 = Color3.fromRGB(70, 180, 110)
startButton.TextColor3 = Color3.new(1, 1, 1)
startButton.Font = Enum.Font.GothamBold
startButton.TextSize = 20
startButton.Text = "Start round 1"
startButton.Visible = false
startButton.Parent = gui

local startCorner = Instance.new("UICorner")
startCorner.CornerRadius = UDim.new(0, 8)
startCorner.Parent = startButton

startButton.Activated:Connect(function()
	startGame:FireServer()
end)

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
	local cash = math.floor(attr("Cash", 0))

	startButton.Visible = state == "Building"

	if state == "GameOver" then
		label.Text = `GAME OVER  ·  reached round {round}`
		label.TextColor3 = Color3.fromRGB(255, 120, 140)
	elseif state == "Victory" then
		label.Text = "VICTORY  ·  all rounds cleared"
		label.TextColor3 = Color3.fromRGB(140, 240, 170)
	elseif state == "Waiting" then
		label.Text = "Starting…"
	elseif state == "Building" then
		label.Text = `Walk to a gold pad to build  ·  Cash {cash}  ·  Lives {lives}`
	else
		label.Text = `Round {round}  ·  Cash {cash}  ·  Lives {lives}  ·  Enemies {alive}`
	end
end

for _, name in { "State", "Round", "Lives", "Alive", "Cash" } do
	ReplicatedStorage:GetAttributeChangedSignal(name):Connect(refresh)
end
refresh()

gui.Parent = player:WaitForChild("PlayerGui")
