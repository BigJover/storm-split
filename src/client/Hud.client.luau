--[[
	Minimal HUD: round, difficulty, level, cash, lives, dinos alive; the
	Start button in the build phase; your health bar (bottom left, flashes red
	when you're hurt); the result screen after a match (with the Amber earned
	and a countdown home). Hidden on the home screen
	(Home.client). Reads ReplicatedStorage attributes set by the server;
	pressing Start is only a request.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local startGame = remotes:WaitForChild("StartGame") :: RemoteEvent

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))
local TowerLook = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TowerLook"))
local HitNotice = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("HitNotice"))
local Bounties = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Bounties"))

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
-- Modal: during the build phase the mouse is free in first person, so Start
-- can be clicked. Gone once the game starts.
startButton.Modal = true
startButton.Parent = gui

local startCorner = Instance.new("UICorner")
startCorner.CornerRadius = UDim.new(0, 8)
startCorner.Parent = startButton

startButton.Activated:Connect(function()
	startGame:FireServer()
end)

-- Result screen: shown on Victory / Game Over until everyone goes home.
local results = Instance.new("TextLabel")
results.Name = "Results"
results.AnchorPoint = Vector2.new(0.5, 0.5)
results.Position = UDim2.fromScale(0.5, 0.4)
results.Size = UDim2.fromOffset(460, 150)
results.BackgroundColor3 = Color3.fromRGB(24, 20, 34)
results.BackgroundTransparency = 0.1
results.TextColor3 = Color3.fromRGB(240, 236, 250)
results.Font = Enum.Font.GothamBlack
results.TextSize = 24
results.RichText = true
results.TextWrapped = true
results.Visible = false
results.Parent = gui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = results
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
	label.Visible = state ~= "Lobby" -- the home screen has its own layout
	results.Visible = state == "GameOver" or state == "Victory"
	label.TextColor3 = Color3.fromRGB(240, 236, 250)

	local difficultyKey = attr("Difficulty", Config.DifficultyOrder[1])
	local difficultyName = Config.Difficulties[difficultyKey] and Config.Difficulties[difficultyKey].display or ""

	if state == "GameOver" or state == "Victory" then
		local won = state == "Victory"
		local payout = player:GetAttribute("LastPayout")
		local cores = if payout == nil then "" elseif payout > 0 then `+{payout} {Theme.Currency}` else `No {Theme.Currency} (solo pays on a clear)`
		results.Text = `<font color="{if won then "#8cf0aa" else "#ff788c"}">{if won then "VICTORY" else "GAME OVER"}</font>\n<font size="18">{if won then `{difficultyName} cleared` else `Reached round {round} on {difficultyName}`}\n{cores}</font>`
		label.Text = if won then "VICTORY" else `GAME OVER  ·  round {round}`
		label.TextColor3 = if won then Color3.fromRGB(140, 240, 170) else Color3.fromRGB(255, 120, 140)
	elseif state == "Lobby" then
		label.Text = ""
	elseif state == "Building" then
		label.Text = `Build (B), choose a hero (H), then Start  ·  {difficultyName}  ·  Cash {cash}  ·  Camp lives {lives}`
	else
		label.Text = `Round {round}  ·  {difficultyName}  ·  Lv {math.floor(attr("Level", 1))}  ·  Cash {cash}  ·  Camp lives {lives}  ·  Dinos {alive}`
	end
end

-- Level-up banner (every RoundsPerLevel rounds cleared).
local banner = Instance.new("TextLabel")
banner.Name = "LevelUp"
banner.AnchorPoint = Vector2.new(0.5, 0.5)
banner.Position = UDim2.fromScale(0.5, 0.3)
banner.Size = UDim2.fromOffset(0, 56)
banner.AutomaticSize = Enum.AutomaticSize.X
banner.BackgroundColor3 = Color3.fromRGB(24, 20, 34)
banner.BackgroundTransparency = 0.15
banner.TextColor3 = Color3.fromRGB(250, 205, 80)
banner.Font = Enum.Font.GothamBlack
banner.TextSize = 26
banner.Visible = false
banner.Parent = gui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = banner
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 24)
	pad.PaddingRight = UDim.new(0, 24)
	pad.Parent = banner
end

local shownLevel = ReplicatedStorage:GetAttribute("Level") or 1
ReplicatedStorage:GetAttributeChangedSignal("Level"):Connect(function()
	local level = ReplicatedStorage:GetAttribute("Level") or 1
	if level <= shownLevel then
		shownLevel = level
		return
	end
	shownLevel = level
	local hero = math.floor(Config.Tuning.HeroDamagePerLevel * 100 + 0.5)
	local tower = math.floor(Config.Tuning.TowerDamagePerLevel * 100 + 0.5)
	banner.Text = `LEVEL {level}  ·  Heroes +{hero}% damage  ·  Towers +{tower}%`
	banner.Visible = true
	task.delay(4, function()
		if shownLevel == level then
			banner.Visible = false
		end
	end)
end)

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
	local studioProgress = remotes:FindFirstChild("StudioProgress")
	local studioTowerHit = remotes:FindFirstChild("StudioTowerHit")
	game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.K then
			studioCash:FireServer()
		elseif input.KeyCode == Enum.KeyCode.J and studioProgress and studioProgress:IsA("RemoteEvent") then
			studioProgress:FireServer() -- +100 Amber (never saved)
		elseif input.KeyCode == Enum.KeyCode.L and studioTowerHit and studioTowerHit:IsA("RemoteEvent") then
			studioTowerHit:FireServer() -- the nearest tower loses half its max HP
		end
	end)
end

player:GetAttributeChangedSignal("LastPayout"):Connect(function()
	refresh()
end)

-- Health bar, bottom left. Reads the Humanoid; only Server/Health changes it.
local HP_FILL = Color3.fromRGB(110, 200, 110)
local HP_LOW = TowerLook.LOW_HP_COLOR -- one low-HP orange for hunters and towers
local HP_FLASH = Color3.fromRGB(255, 70, 70)
local hpFrame = Instance.new("Frame")
hpFrame.Name = "Health"
hpFrame.AnchorPoint = Vector2.new(0, 1)
hpFrame.Position = UDim2.new(0, 24, 1, -24)
hpFrame.Size = UDim2.fromOffset(240, 28)
hpFrame.BackgroundColor3 = Color3.fromRGB(24, 20, 34)
hpFrame.BackgroundTransparency = 0.25
hpFrame.Visible = false
hpFrame.Parent = gui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = hpFrame
end
local hpFill = Instance.new("Frame")
hpFill.Name = "Fill"
hpFill.Size = UDim2.fromScale(1, 1)
hpFill.BackgroundColor3 = HP_FILL
hpFill.BorderSizePixel = 0
hpFill.Parent = hpFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = hpFill
end
local hpText = Instance.new("TextLabel")
hpText.Size = UDim2.fromScale(1, 1)
hpText.BackgroundTransparency = 1
hpText.TextColor3 = Color3.new(1, 1, 1)
hpText.TextStrokeTransparency = 0.5
hpText.Font = Enum.Font.GothamBold
hpText.TextSize = 16
hpText.ZIndex = 2
hpText.Parent = hpFrame

local lastHealth = 0
local flashId = 0
local function showHealth(humanoid: Humanoid)
	local max = math.max(1, humanoid.MaxHealth)
	local health = math.max(0, humanoid.Health)
	local frac = math.clamp(health / max, 0, 1)
	hpFill.Size = UDim2.fromScale(frac, 1)
	hpText.Text = `HP {math.ceil(health)} / {math.floor(max)}`
	if health < lastHealth then
		flashId += 1
		local mine = flashId
		hpFill.BackgroundColor3 = HP_FLASH
		hpFrame.BackgroundColor3 = Color3.fromRGB(90, 20, 28)
		task.delay(0.25, function()
			if flashId == mine then
				hpFill.BackgroundColor3 = if frac < 0.35 then HP_LOW else HP_FILL
				hpFrame.BackgroundColor3 = Color3.fromRGB(24, 20, 34)
			end
		end)
	else
		hpFill.BackgroundColor3 = if frac < 0.35 then HP_LOW else HP_FILL
	end
	lastHealth = health
end

local function watchHumanoid(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	lastHealth = humanoid.Health
	showHealth(humanoid)
	hpFrame.Visible = true
	humanoid.HealthChanged:Connect(function()
		showHealth(humanoid)
	end)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		showHealth(humanoid)
	end)
end
-- Private hit notice beside the HP bar: "Raptor · Slash −4" (DECISIONS #39).
-- Only this hunter's hits arrive here (Server/Health fires to them alone).
local notice = Instance.new("TextLabel")
notice.Name = "HitNotice"
notice.AnchorPoint = Vector2.new(0, 1)
notice.Position = UDim2.new(0, 24 + 240 + 10, 1, -24)
notice.Size = UDim2.fromOffset(0, 28)
notice.AutomaticSize = Enum.AutomaticSize.X
notice.BackgroundTransparency = 1
notice.TextColor3 = HP_FLASH
notice.TextStrokeTransparency = 0.4
notice.Font = Enum.Font.GothamBold
notice.TextSize = 17
notice.TextXAlignment = Enum.TextXAlignment.Left
notice.Visible = false
notice.Parent = gui

local noticeState: HitNotice.State? = nil
task.spawn(function()
	local hurt = remotes:WaitForChild("Hurt") :: RemoteEvent
	hurt.OnClientEvent:Connect(function(species: unknown, attack: unknown, amount: unknown)
		if typeof(species) ~= "string" or typeof(attack) ~= "string" or typeof(amount) ~= "number" then
			return
		end
		local now = os.clock()
		local state = HitNotice.merge(noticeState, species, attack, amount, now)
		noticeState = state
		notice.Text = HitNotice.text(state)
		notice.Visible = true
		task.delay(HitNotice.FADE, function()
			if noticeState == state then -- no newer hit since
				notice.Visible = false
			end
		end)
	end)
end)

-- Private bounty toast above the HP bar: "Bounty ready: Raptor Cull (claim +15 Amber
-- at the Hunt Board)" (DECISIONS #70, #94); a long line wraps inside the window. Only this hunter's bounties arrive here (Server/Progression
-- fires to them alone). No panel, nothing to click: lines show for a moment and go.
local TOAST_SECONDS = 4 -- UI timing, not a gameplay number
local toast = Instance.new("TextLabel")
toast.Name = "BountyToast"
toast.AnchorPoint = Vector2.new(0, 1)
toast.Position = UDim2.new(0, 24, 1, -24 - 28 - 8)
toast.Size = UDim2.new(1, -48, 0, 0)
toast.AutomaticSize = Enum.AutomaticSize.Y
toast.TextWrapped = true
toast.BackgroundTransparency = 1
toast.TextColor3 = Color3.fromRGB(245, 175, 60) -- the amber title colour
toast.TextStrokeTransparency = 0.4
toast.Font = Enum.Font.GothamBold
toast.TextSize = 17
toast.TextXAlignment = Enum.TextXAlignment.Left
toast.Visible = false
toast.Parent = gui

local toastLines: { string } = {}
local function showToasts()
	toast.Text = table.concat(toastLines, "\n")
	toast.Visible = #toastLines > 0
end
task.spawn(function()
	local done = remotes:WaitForChild("BountyDone") :: RemoteEvent
	done.OnClientEvent:Connect(function(id: unknown)
		local line = if typeof(id) == "string" then Bounties.doneText(id) else nil
		if not line then
			return
		end
		table.insert(toastLines, line)
		showToasts()
		task.delay(TOAST_SECONDS, function()
			table.remove(toastLines, 1) -- the oldest line; they all last the same time
			showToasts()
		end)
	end)
end)

player.CharacterAdded:Connect(watchHumanoid)
player.CharacterRemoving:Connect(function()
	hpFrame.Visible = false
end)
if player.Character then
	task.spawn(watchHumanoid, player.Character)
end

-- Countdown home on the result screen.
task.spawn(function()
	while true do
		task.wait(0.25)
		local state = attr("State", "")
		if state == "GameOver" or state == "Victory" then
			local left = math.max(0, math.ceil(attr("HomeAt", 0) - workspace:GetServerTimeNow()))
			label.Text = `{if state == "Victory" then "VICTORY" else "GAME OVER"}  ·  home in {left}s`
		end
	end
end)

for _, name in { "State", "Round", "Lives", "Alive", "Cash", "Difficulty", "Level" } do
	ReplicatedStorage:GetAttributeChangedSignal(name):Connect(refresh)
end
refresh()

gui.Parent = player:WaitForChild("PlayerGui")
