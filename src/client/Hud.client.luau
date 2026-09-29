--[[
	Minimal HUD: round, difficulty, cash, lives, enemies alive; in the build
	phase, the difficulty picker and the Start button. Reads ReplicatedStorage
	attributes set by the server. Picking and starting are only requests; the
	server decides.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local startGame = remotes:WaitForChild("StartGame") :: RemoteEvent
local chooseDifficulty = remotes:WaitForChild("ChooseDifficulty") :: RemoteEvent

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local gui = Instance.new("ScreenGui")
gui.Name = "StormSplitHud"
gui.ResetOnSpawn = false

local label = Instance.new("TextLabel")
label.Name = "Status"
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, 12)
label.Size = UDim2.fromOffset(0, 40)
label.AutomaticSize = Enum.AutomaticSize.X -- fits whatever the status says
label.BackgroundColor3 = Color3.fromRGB(24, 20, 34)
label.BackgroundTransparency = 0.25
label.TextColor3 = Color3.fromRGB(240, 236, 250)
label.Font = Enum.Font.GothamBold
label.TextSize = 18
label.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = label

local labelPadding = Instance.new("UIPadding")
labelPadding.PaddingLeft = UDim.new(0, 16)
labelPadding.PaddingRight = UDim.new(0, 16)
labelPadding.Parent = label

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
-- Modal: during the build phase the mouse is free in first person, so Start and
-- the difficulty buttons can be clicked. Gone once the game starts.
startButton.Modal = true
startButton.Parent = gui

local startCorner = Instance.new("UICorner")
startCorner.CornerRadius = UDim.new(0, 8)
startCorner.Parent = startButton

startButton.Activated:Connect(function()
	startGame:FireServer()
end)

-- Difficulty picker, shown during the build phase under the Start button.
local picker = Instance.new("Frame")
picker.Name = "Difficulty"
picker.AnchorPoint = Vector2.new(0.5, 0)
picker.Position = UDim2.new(0.5, 0, 0, 112)
picker.Size = UDim2.fromOffset(0, 36)
picker.AutomaticSize = Enum.AutomaticSize.X
picker.BackgroundTransparency = 1
picker.Visible = false
picker.Parent = gui

do
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = picker
end

local difficultyButtons: { [string]: TextButton } = {}
for order, key in Config.DifficultyOrder do
	local button = Instance.new("TextButton")
	button.Name = key
	button.LayoutOrder = order
	button.Size = UDim2.fromOffset(96, 36)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.TextColor3 = Color3.fromRGB(240, 236, 250)
	button.Text = Config.Difficulties[key].display
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = button
	button.Activated:Connect(function()
		chooseDifficulty:FireServer(key)
	end)
	button.Parent = picker
	difficultyButtons[key] = button
end

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
	picker.Visible = state == "Building"

	local difficultyKey = attr("Difficulty", Config.DifficultyOrder[1])
	local difficultyName = Config.Difficulties[difficultyKey] and Config.Difficulties[difficultyKey].display or ""
	for key, button in difficultyButtons do
		local selected = key == difficultyKey
		button.BackgroundColor3 = if selected then Color3.fromRGB(200, 90, 110) else Color3.fromRGB(60, 56, 72)
		button.BackgroundTransparency = if selected then 0 else 0.2
	end

	if state == "GameOver" then
		label.Text = `GAME OVER  ·  reached round {round}`
		label.TextColor3 = Color3.fromRGB(255, 120, 140)
	elseif state == "Victory" then
		label.Text = "VICTORY  ·  all rounds cleared"
		label.TextColor3 = Color3.fromRGB(140, 240, 170)
	elseif state == "Waiting" then
		label.Text = "Starting…"
	elseif state == "Building" then
		label.Text = `Build (B), pick a difficulty, then Start  ·  Cash {cash}  ·  Lives {lives}`
	else
		label.Text = `Round {round}  ·  {difficultyName}  ·  Cash {cash}  ·  Lives {lives}  ·  Enemies {alive}`
	end
end

-- Studio-only test button. The remote only exists when the server runs in
-- Studio, so this never appears in a published game.
local studioCash = remotes:FindFirstChild("StudioCash")
if studioCash and studioCash:IsA("RemoteEvent") then
	local button = Instance.new("TextButton")
	button.Name = "StudioCash"
	button.AnchorPoint = Vector2.new(0, 0)
	button.Position = UDim2.new(0, 12, 0, 60)
	button.Size = UDim2.fromOffset(130, 34)
	button.BackgroundColor3 = Color3.fromRGB(60, 140, 80)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 15
	button.Text = "+1000 cash (K)"
	-- Not Modal: that would free the mouse for the whole game. Click it while
	-- the mouse is free (build phase, a menu open) or press K any time.
	button.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = button
	button.Activated:Connect(function()
		studioCash:FireServer()
	end)
	game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.K then
			studioCash:FireServer()
		end
	end)
end

for _, name in { "State", "Round", "Lives", "Alive", "Cash", "Difficulty" } do
	ReplicatedStorage:GetAttributeChangedSignal(name):Connect(refresh)
end
refresh()

gui.Parent = player:WaitForChild("PlayerGui")
