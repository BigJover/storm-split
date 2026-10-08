--[[
	Minimal HUD: round, difficulty, cash, lives, dinos alive; your hunter level
	and XP under it while a round is on (a plain label: no input, no mouse); the
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
local HeroXp = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("HeroXp"))
local PanelRules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PanelRules"))
local Sides = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Sides"))
local BattleFlow = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BattleFlow"))

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
results.Size = UDim2.new(1, -32, 0, 190) -- never wider than the window (16 px each side)
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
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(460, 190)
	limit.Parent = results
end

-- Hunter level and XP, under the status line while a round is on. A label only:
-- nothing here is a button, takes input or touches the mouse, and it is hidden in
-- the build phase (where Start sits), on the result screen and at home. It shrinks
-- with the window (scale layout + scaled text), never past the screen edge.
local XP_ROW_WIDTH = 420
local XP_ROW_EDGE = 16 -- kept clear of each screen edge
local xpRow = Instance.new("Frame")
xpRow.Name = "HeroXp"
xpRow.AnchorPoint = Vector2.new(0.5, 0)
xpRow.Position = UDim2.new(0.5, 0, 0, 56) -- just under the status line
xpRow.Size = UDim2.new(1, -XP_ROW_EDGE * 2, 0, 24)
xpRow.BackgroundColor3 = Color3.fromRGB(24, 20, 34)
xpRow.BackgroundTransparency = 0.25
xpRow.BorderSizePixel = 0
xpRow.Active = false
xpRow.Visible = false
xpRow.Parent = gui
do
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(XP_ROW_WIDTH, 24)
	limit.Parent = xpRow
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = xpRow
end

local function xpText(name: string, x: number, width: number, align: Enum.TextXAlignment): TextLabel
	local text = Instance.new("TextLabel")
	text.Name = name
	text.Position = UDim2.fromScale(x, 0.15)
	text.Size = UDim2.fromScale(width, 0.7)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.fromRGB(240, 236, 250)
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true -- shrinks to fit, never clips
	text.TextXAlignment = align
	text.Active = false
	text.Parent = xpRow
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 14
	limit.MinTextSize = 6
	limit.Parent = text
	return text
end

local xpLevel = xpText("Level", 0.03, 0.12, Enum.TextXAlignment.Left)
local xpNumbers = xpText("Numbers", 0.46, 0.51, Enum.TextXAlignment.Right)

local xpBar = Instance.new("Frame")
xpBar.Name = "Bar"
xpBar.AnchorPoint = Vector2.new(0, 0.5)
xpBar.Position = UDim2.fromScale(0.16, 0.5)
xpBar.Size = UDim2.new(0.28, 0, 0, 6)
xpBar.BackgroundColor3 = Color3.fromRGB(60, 54, 78)
xpBar.BorderSizePixel = 0
xpBar.Active = false
xpBar.Parent = xpRow

local xpFill = Instance.new("Frame")
xpFill.Name = "Fill"
xpFill.Size = UDim2.fromScale(0, 1)
xpFill.BackgroundColor3 = Color3.fromRGB(250, 205, 80)
xpFill.BorderSizePixel = 0
xpFill.Active = false
xpFill.Parent = xpBar

-- This round's pending XP on its own line under the XP bar, the same width
-- (DECISIONS #138). Also a label only; shown while there is some.
local clearRow = Instance.new("Frame")
clearRow.Name = "HeroXpClear"
clearRow.AnchorPoint = Vector2.new(0.5, 0)
clearRow.Position = UDim2.new(0.5, 0, 0, 56 + 24 + 4) -- under the XP bar
clearRow.Size = UDim2.new(1, -XP_ROW_EDGE * 2, 0, 24)
clearRow.BackgroundColor3 = Color3.fromRGB(24, 20, 34)
clearRow.BackgroundTransparency = 0.25
clearRow.BorderSizePixel = 0
clearRow.Active = false
clearRow.Visible = false
clearRow.Parent = gui
do
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(XP_ROW_WIDTH, 24)
	limit.Parent = clearRow
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = clearRow
end
local clearText = Instance.new("TextLabel")
clearText.Name = "Pending"
clearText.Position = UDim2.fromScale(0.03, 0.12)
clearText.Size = UDim2.fromScale(0.94, 0.76)
clearText.BackgroundTransparency = 1
clearText.TextColor3 = Color3.fromRGB(250, 205, 80)
clearText.Font = Enum.Font.GothamBold
clearText.TextScaled = true -- shrinks to fit, never clips
clearText.Active = false
clearText.Parent = clearRow
do
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 16
	limit.MinTextSize = 10
	limit.Parent = clearText
end

-- Battle results (PLAN T83; Shared/PanelRules.battleResults/resultsOpen): placements of
-- every camp, your Amber (payout, Amber Hoard share), Trophies and arena, the Practice
-- Hunt note, player XP. No-trap: it fits any window (its body scrolls, the X sits outside
-- the scroll), the X is Modal so the mouse is free, and it closes on X or on going home.
local resultsDismissed = false
local battleResults = Instance.new("Frame")
battleResults.Name = "BattleResults"
battleResults.AnchorPoint = Vector2.new(0.5, 0.5)
battleResults.Position = UDim2.fromScale(0.5, 0.5)
battleResults.Size = UDim2.new(1, -32, 1, -136) -- clear of the status line, inside any window
battleResults.BackgroundColor3 = Color3.fromRGB(24, 20, 34)
battleResults.BackgroundTransparency = 0.1
battleResults.Visible = false
battleResults.Parent = gui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = battleResults
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(480, 460)
	limit.Parent = battleResults
end
local resultsTitle = Instance.new("TextLabel")
resultsTitle.Name = "Title"
resultsTitle.Position = UDim2.new(0, 12, 0, 8)
resultsTitle.Size = UDim2.new(1, -64, 0, 40) -- leaves room for the X
resultsTitle.BackgroundTransparency = 1
resultsTitle.Font = Enum.Font.GothamBlack
resultsTitle.TextScaled = true
resultsTitle.TextXAlignment = Enum.TextXAlignment.Left
resultsTitle.Parent = battleResults
do
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 24
	limit.MinTextSize = 8
	limit.Parent = resultsTitle
end
local resultsClose = Instance.new("TextButton")
resultsClose.Name = "Close"
resultsClose.AnchorPoint = Vector2.new(1, 0)
resultsClose.Position = UDim2.new(1, -8, 0, 8)
resultsClose.Size = UDim2.fromOffset(40, 40)
resultsClose.BackgroundColor3 = Color3.fromRGB(150, 60, 70)
resultsClose.TextColor3 = Color3.new(1, 1, 1)
resultsClose.Font = Enum.Font.GothamBlack
resultsClose.TextSize = 20
resultsClose.Text = "X"
resultsClose.Modal = true -- frees the mouse while the results are up
resultsClose.Parent = battleResults
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = resultsClose
end
local resultsBody = Instance.new("ScrollingFrame")
resultsBody.Name = "Body"
resultsBody.Position = UDim2.new(0, 12, 0, 56)
resultsBody.Size = UDim2.new(1, -24, 1, -64)
resultsBody.BackgroundTransparency = 1
resultsBody.BorderSizePixel = 0
resultsBody.CanvasSize = UDim2.new()
resultsBody.AutomaticCanvasSize = Enum.AutomaticSize.Y
resultsBody.ScrollBarThickness = 6
resultsBody.Parent = battleResults
do
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 4)
	list.Parent = resultsBody
end

local function attr(name: string, default: any): any
	local value = ReplicatedStorage:GetAttribute(name)
	if value == nil then
		return default
	end
	return value
end

local function arenaDisplay(key: unknown): string?
	for _, arena in Config.Arenas do
		if arena.key == key then
			return arena.display
		end
	end
	return nil
end

local function resultsLine(name: string, order: number, text: string, color: Color3, bold: boolean)
	local line = Instance.new("TextLabel")
	line.Name = name
	line.LayoutOrder = order
	line.Size = UDim2.new(1, -8, 0, 0)
	line.AutomaticSize = Enum.AutomaticSize.Y
	line.BackgroundTransparency = 1
	line.TextColor3 = color
	line.Font = if bold then Enum.Font.GothamBlack else Enum.Font.GothamBold
	line.TextSize = 17
	line.TextWrapped = true
	line.TextXAlignment = Enum.TextXAlignment.Left
	line.Text = text
	line.Parent = resultsBody
end

local function renderBattleResults(battle: string)
	local mySide = Sides.playerSide(player:GetAttribute("Side"), attr("Sides", nil))
	local camps = {}
	for side = 1, math.floor(attr("Sides", 1)) do
		local camp, place = attr(Sides.attr("Camp", side), nil), attr(Sides.attr("Place", side), nil)
		if typeof(camp) == "string" and typeof(place) == "number" then
			table.insert(camps, { side = side, camp = camp, place = place, bones = attr(Sides.attr("CampBones", side), 0) })
		end
	end
	local place = player:GetAttribute("BattlePlace")
	local out = PanelRules.battleResults({
		mode = battle,
		place = if typeof(place) == "number" then place else nil,
		mySide = mySide,
		camps = camps,
		payout = player:GetAttribute("LastPayout"),
		share = player:GetAttribute("LastPotShare"),
		trophies = player:GetAttribute("LastTrophies"),
		trophiesNow = player:GetAttribute("Trophies"),
		newArena = arenaDisplay(player:GetAttribute("LastArena")),
		practice = attr("BattlePractice", false) == true,
		xp = player:GetAttribute("LastPlayerXp"),
		levelFrom = player:GetAttribute("LastPlayerLevelFrom"),
		levelTo = player:GetAttribute("LastPlayerLevel"),
	})
	local color = if out.won then Color3.fromRGB(140, 240, 170) else Color3.fromRGB(255, 120, 140)
	resultsTitle.Text = out.title
	resultsTitle.TextColor3 = color
	label.TextColor3 = color
	for _, child in resultsBody:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local order = 0
	for _, row in out.placements do
		order += 1
		resultsLine("Place", order, row.text, if row.mine then Color3.fromRGB(250, 205, 80) else Color3.fromRGB(240, 236, 250), row.mine)
	end
	for _, text in out.lines do
		order += 1
		resultsLine("Line", order, text, Color3.fromRGB(250, 205, 80), false)
	end
end

resultsClose.Activated:Connect(function()
	resultsDismissed = true
	battleResults.Visible = false
end)
ReplicatedStorage:GetAttributeChangedSignal("State"):Connect(function()
	resultsDismissed = false -- every results screen opens once
end)

local function refresh()
	local state = attr("State", "Waiting")
	local round = math.floor(attr("Round", 0))
	local side = Sides.playerSide(player:GetAttribute("Side"), ReplicatedStorage:GetAttribute("Sides"))
	local lives = math.floor(attr(Sides.attr("Lives", side), 0)) -- your side's Fence (T76)
	local alive = math.floor(attr("Alive", 0))
	local cash = math.floor(attr(Sides.attr("Cash", side), 0)) -- your side's cash

	-- A battle (Server/Battle, T77) has a timed build phase and no Start button.
	local battle = attr("BattleMode", nil)
	local camp = if battle then attr(Sides.attr("Camp", side), "") else ""
	startButton.Visible = state == "Building" and battle == nil
	label.Visible = state ~= "Lobby" -- the home screen has its own layout
	results.Visible = state == "GameOver" or state == "Victory"
	label.TextColor3 = Color3.fromRGB(240, 236, 250)

	-- Banked XP fills the bar; this round's pending XP is only named under it,
	-- because it isn't yours until the round is cleared.
	xpRow.Visible = state == "Playing"
	local shown, needed, heroLevel = HeroXp.progress(player:GetAttribute("HeroXp") or 0, attr("RoundsCleared", 0))
	local pending = math.floor(player:GetAttribute("HeroXpPending") or 0)
	xpLevel.Text = `Lv {heroLevel}`
	xpFill.Size = UDim2.fromScale(shown / needed, 1)
	xpNumbers.Text = `{shown} / {needed} XP`
	clearRow.Visible = xpRow.Visible and pending > 0
	clearText.Text = `+{pending} bonus on round clear` -- DECISIONS #157

	local difficultyKey = attr("Difficulty", Config.DifficultyOrder[1])
	local difficultyName = Config.Difficulties[difficultyKey] and Config.Difficulties[difficultyKey].display or ""

	results.Visible = results.Visible and battle == nil -- a battle has its own results panel
	battleResults.Visible = PanelRules.resultsOpen(state, battle, resultsDismissed)
	if battle and (state == "GameOver" or state == "Victory") then
		renderBattleResults(battle)
	elseif state == "GameOver" or state == "Victory" then
		local won = state == "Victory"
		local payout = player:GetAttribute("LastPayout")
		local cores = if payout == nil then "" elseif payout > 0 then `+{payout} {Theme.Currency}` else `No {Theme.Currency} (solo pays on a clear)`
		-- Player XP (PLAN T56): what this match added, and the level-up if it made one.
		-- Never "Lv N": that's the hunter's in-match level (DECISIONS #118).
		local playerXp = player:GetAttribute("LastPlayerXp")
		local levelFrom, levelTo = player:GetAttribute("LastPlayerLevelFrom"), player:GetAttribute("LastPlayerLevel")
		local xpLine = if playerXp == nil then "" else `\n+{playerXp} player XP`
		if playerXp ~= nil and levelFrom ~= nil and levelTo ~= nil then
			xpLine ..= `\n<font color="#facd50">Player level up! {levelFrom} → {levelTo}</font>`
		end
		results.Text = `<font color="{if won then "#8cf0aa" else "#ff788c"}">{if won then "VICTORY" else "GAME OVER"}</font>\n<font size="18">{if won then `{difficultyName} cleared` else `The fence fell on round {round} ({difficultyName})`}\n{cores}{xpLine}</font>`
		label.Text = if won then "VICTORY" else `GAME OVER  ·  round {round}`
		label.TextColor3 = if won then Color3.fromRGB(140, 240, 170) else Color3.fromRGB(255, 120, 140)
	elseif state == "Lobby" then
		label.Text = ""
	elseif state == "Building" and battle then
		label.Text = `{camp}  ·  Build (B), choose a hero (H)  ·  {difficultyName}  ·  Cash {cash}  ·  {Theme.Fence} {lives}`
	elseif state == "Building" then
		label.Text = `Build (B), choose a hero (H), then Start  ·  {difficultyName}  ·  Cash {cash}  ·  {Theme.Fence} {lives}`
	elseif battle then
		label.Text = `{camp}  ·  Round {round}  ·  {difficultyName}  ·  Cash {cash}  ·  {Theme.Fence} {lives}  ·  Dinos {alive}`
	else
		label.Text = `Round {round}  ·  {difficultyName}  ·  Cash {cash}  ·  {Theme.Fence} {lives}  ·  Dinos {alive}`
	end
end

-- Level-up banner: one banner, at most two lines. Your own line when your
-- HeroLevel rises (hero XP), the tower line when the team's tower level rises
-- (every RoundsPerLevel rounds cleared). Both in the same clear share the banner.
-- A label: it takes no input and goes away by itself.
local BANNER_SECONDS = 4
local BANNER_EDGE = 16 -- kept clear of each screen edge
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
banner.TextSize = 24
banner.Active = false
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

local hunterLine: string? = nil
local towerLine: string? = nil
local bannerShow = 0 -- the latest showing; an older one's timer doesn't hide a newer banner

local function hideBanner()
	bannerShow += 1
	hunterLine, towerLine = nil, nil
	banner.Visible = false
end

local function showBanner()
	if not PanelRules.bannersShown(ReplicatedStorage:GetAttribute("State")) then
		hideBanner() -- never over a results screen (T86b F5)
		return
	end
	local lines = {}
	if hunterLine then
		table.insert(lines, hunterLine)
	end
	if towerLine then
		table.insert(lines, towerLine)
	end
	-- The text shrinks with the window so the longest line stays on screen.
	local camera = workspace.CurrentCamera
	local width = if camera then camera.ViewportSize.X else 800
	local longest = 0
	for _, line in lines do
		longest = math.max(longest, utf8.len(line) or #line)
	end
	local room = math.max(1, width - BANNER_EDGE * 2 - 48) -- 48: the banner's padding
	local size = math.clamp(math.floor(room / (longest * 0.62)), 10, 24) -- ~0.62 em a letter
	banner.TextSize = size
	banner.Size = UDim2.fromOffset(0, #lines * (size + 8) + 24)
	banner.Text = table.concat(lines, "\n")
	banner.Visible = true

	bannerShow += 1
	local mine = bannerShow
	task.delay(BANNER_SECONDS, function()
		if bannerShow == mine then
			hideBanner()
		end
	end)
end

ReplicatedStorage:GetAttributeChangedSignal("State"):Connect(function()
	if not PanelRules.bannersShown(ReplicatedStorage:GetAttribute("State")) then
		hideBanner() -- the results are up: no banner over them (T86b F5)
	end
end)

local shownHeroLevel = player:GetAttribute("HeroLevel") or 1
player:GetAttributeChangedSignal("HeroLevel"):Connect(function()
	local level = player:GetAttribute("HeroLevel") or 1
	local rose = level > shownHeroLevel
	shownHeroLevel = level
	if not rose then
		hideBanner() -- a new match: back to level 1, nothing to announce
		return
	end
	local percent = math.floor(Config.Tuning.HeroDamagePerLevel * 100 + 0.5)
	hunterLine = `Hunter level {level} — your shots hit {percent}% harder`
	showBanner()
end)

local shownTowerLevel = ReplicatedStorage:GetAttribute("Level") or 1
ReplicatedStorage:GetAttributeChangedSignal("Level"):Connect(function()
	local level = ReplicatedStorage:GetAttribute("Level") or 1
	local rose = level > shownTowerLevel
	shownTowerLevel = level
	if not rose then
		hideBanner()
		return
	end
	local percent = math.floor(Config.Tuning.TowerDamagePerLevel * 100 + 0.5)
	towerLine = `Tower level {level} — towers hit {percent}% harder`
	showBanner()
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
player:GetAttributeChangedSignal("LastPlayerXp"):Connect(function()
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

-- Shared/PanelRules: shown with a character, never on the home screen (PLAYTEST F1:
-- the character outlives the match, so CharacterRemoving alone left it showing).
local watched: Model? = nil
local function updateHpVisible()
	local hasCharacter = watched ~= nil and watched.Parent ~= nil
	hpFrame.Visible = PanelRules.hpBarVisible(ReplicatedStorage:GetAttribute("State"), hasCharacter)
end

local function watchHumanoid(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	lastHealth = humanoid.Health
	showHealth(humanoid)
	watched = character
	updateHpVisible()
	character.AncestryChanged:Connect(updateHpVisible)
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
player.CharacterRemoving:Connect(function(character)
	if watched == character then
		watched = nil
	end
	updateHpVisible()
end)
ReplicatedStorage:GetAttributeChangedSignal("State"):Connect(updateHpVisible)
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
			local battle = attr("BattleMode", nil)
			local won = if battle then BattleFlow.resultTitle(battle, player:GetAttribute("BattlePlace")) ~= nil else state == "Victory"
			label.Text = `{if won then "VICTORY" else "GAME OVER"}  ·  home in {left}s`
		end
	end
end)

for _, name in { "State", "Round", "Lives", "Alive", "Cash", "Difficulty", "RoundsCleared", "Sides", "BattleMode" } do
	ReplicatedStorage:GetAttributeChangedSignal(name):Connect(refresh)
end
for _, name in { "HeroXp", "HeroXpPending", "HeroLevel", "Side", "BattlePlace", "BattleBones", "LastPotShare", "LastTrophies", "LastArena", "LastPlayerLevel", "Trophies" } do
	player:GetAttributeChangedSignal(name):Connect(refresh)
end
-- Another battle side's cash or Fence ("Cash2", "Lives3"...; Shared/Sides.attr).
ReplicatedStorage.AttributeChanged:Connect(function(name: string)
	if
		string.match(name, "^Cash%d+$")
		or string.match(name, "^Lives%d+$")
		or string.match(name, "^Camp%d*$")
		or string.match(name, "^Place%d*$")
		or string.match(name, "^CampBones%d*$")
		or name == "BattlePot"
		or name == "BattlePractice"
	then
		refresh()
	end
end)
refresh()

-- Battle feed (Server/Battle, T77/T78): raid knock-outs and this hunter's own "Tranqed by
-- <name>!"; camp-out lines go to the top-centre banners (PanelRules.feedSlot). Top right, nothing to click:
-- each line shows for a moment and goes (the DIRECTION no-trap rule has nothing to trap).
local FEED_SECONDS = 6 -- UI timing, not a gameplay number
local FEED_LINES = 4
local feedList = Instance.new("Frame")
feedList.Name = "BattleFeed"
feedList.AnchorPoint = Vector2.new(1, 0)
feedList.Position = UDim2.new(1, -16, 0, 64)
feedList.Size = UDim2.new(0.4, 0, 0, 0)
feedList.AutomaticSize = Enum.AutomaticSize.Y
feedList.BackgroundTransparency = 1
feedList.Active = false
feedList.Parent = gui
local feedLayout = Instance.new("UIListLayout")
feedLayout.SortOrder = Enum.SortOrder.LayoutOrder
feedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
feedLayout.Padding = UDim.new(0, 4)
feedLayout.Parent = feedList
local feedCount = 0
local showOutBanner: (text: string) -> () -- set below the top-centre banner stack (Run 4 F7)
task.spawn(function()
	local event = remotes:WaitForChild("Feed") :: RemoteEvent
	event.OnClientEvent:Connect(function(text: unknown)
		if typeof(text) ~= "string" then
			return
		end
		if PanelRules.feedSlot(text) == "banner" then
			showOutBanner(text) -- a camp-out: top centre, below the camps board
			return
		end
		feedCount += 1
		local line = Instance.new("TextLabel")
		line.LayoutOrder = feedCount
		line.Size = UDim2.new(1, 0, 0, 0)
		line.AutomaticSize = Enum.AutomaticSize.Y
		line.BackgroundColor3 = Color3.fromRGB(24, 20, 34)
		line.BackgroundTransparency = 0.3
		line.TextColor3 = Color3.fromRGB(250, 205, 80)
		line.TextStrokeTransparency = 0.5
		line.Font = Enum.Font.GothamBold
		line.TextSize = 16
		line.TextWrapped = true
		line.TextXAlignment = Enum.TextXAlignment.Right
		line.Text = text
		line.Parent = feedList
		local lines = {}
		for _, child in feedList:GetChildren() do
			if child:IsA("TextLabel") then
				table.insert(lines, child)
			end
		end
		table.sort(lines, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		for i = 1, #lines - FEED_LINES do
			lines[i]:Destroy() -- only the newest few stay
		end
		task.delay(FEED_SECONDS, function()
			line:Destroy()
		end)
	end)
end)

-- Battle screens (PLAN T83, DECISIONS #223; Shared/PanelRules.battleHud). All labels:
-- nothing to click, no mouse, nothing to close (the no-trap rule has nothing to trap).
-- Camps board, top left: every camp's colour, Fence and Bones, the camps still in first;
-- your camp in bold (the scoreboard by side; the player list groups hunters by camp).
-- Top centre, below the camps board: the Final Stampede banner in overtime. Bottom
-- centre: the spectate banner once your camp is out, or Camo Cover while your spawn
-- shield lasts (T86b F6). None of them, nor the feed, show over the results (T86b F5).
-- The status line takes your camp's colour as an outline. Co-op shows none of these.
local function richEscape(text: string): string
	return (string.gsub(string.gsub(string.gsub(text, "&", "&amp;"), "<", "&lt;"), ">", "&gt;"))
end

local campStroke = Instance.new("UIStroke")
campStroke.Thickness = 3
campStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
campStroke.Enabled = false
campStroke.Parent = label

local campsBoard = Instance.new("TextLabel")
campsBoard.Name = "CampsBoard"
campsBoard.Position = UDim2.new(0, 12, 0, 104) -- under Studio's +1000 cash button
campsBoard.Size = UDim2.new(0.3, 0, 0.42, 0) -- shrinks with the window, never off screen
campsBoard.BackgroundColor3 = Color3.fromRGB(24, 20, 34)
campsBoard.BackgroundTransparency = 0.3
campsBoard.TextColor3 = Color3.fromRGB(240, 236, 250)
campsBoard.Font = Enum.Font.GothamBold
campsBoard.RichText = true
campsBoard.TextScaled = true -- ten camps still fit: the text shrinks, never clips
campsBoard.TextXAlignment = Enum.TextXAlignment.Left
campsBoard.TextYAlignment = Enum.TextYAlignment.Top
campsBoard.Active = false
campsBoard.Visible = false
campsBoard.Parent = gui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = campsBoard
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.Parent = campsBoard
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(300, 250)
	limit.Parent = campsBoard
	local text = Instance.new("UITextSizeConstraint")
	text.MaxTextSize = 15
	text.MinTextSize = 6
	text.Parent = campsBoard
end

local battleBanners = Instance.new("Frame")
battleBanners.Name = "BattleBanners"
battleBanners.AnchorPoint = Vector2.new(0.5, 0)
local BANNERS_TOP = 116 -- under the XP rows; below the camps board when it shows (T86b F6)
battleBanners.Position = UDim2.new(0.5, 0, 0, BANNERS_TOP)
battleBanners.Size = UDim2.new(1, -32, 0, 0)
battleBanners.AutomaticSize = Enum.AutomaticSize.Y
battleBanners.BackgroundTransparency = 1
battleBanners.Active = false
battleBanners.Parent = gui
do
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(520, math.huge)
	limit.Parent = battleBanners
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Padding = UDim.new(0, 4)
	list.Parent = battleBanners
end

local function battleLabel(name: string, order: number, color: Color3, parent: Instance): TextLabel
	local line = Instance.new("TextLabel")
	line.Name = name
	line.LayoutOrder = order
	line.Size = UDim2.new(1, 0, 0, 30)
	line.BackgroundColor3 = Color3.fromRGB(24, 20, 34)
	line.BackgroundTransparency = 0.2
	line.TextColor3 = color
	line.Font = Enum.Font.GothamBlack
	line.TextScaled = true
	line.Active = false
	line.Visible = false
	line.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = line
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 20
	limit.MinTextSize = 8
	limit.Parent = line
	return line
end

-- Bottom centre above the hotbar (T86b F6), where Camo Cover shows: never both (a
-- spectator has no Camo Cover), and never over the camps board.
local spectateBanner = battleLabel("Spectate", 1, Color3.fromRGB(255, 120, 140), gui)
spectateBanner.Text = PanelRules.SPECTATE_LINE
spectateBanner.AnchorPoint = Vector2.new(0.5, 1)
spectateBanner.Position = UDim2.new(0.5, 0, 1, -96)
spectateBanner.Size = UDim2.new(1, -32, 0, 30)
do
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(520, 30)
	limit.Parent = spectateBanner
end
-- Camp-out lines (PLAN T86b F6, PLAYTEST Run 4 F7): top centre in the banner stack, so
-- below the camps board; each shows for a moment and goes, like a feed line.
local outBanners = Instance.new("Frame")
outBanners.Name = "CampOut"
outBanners.LayoutOrder = 1
outBanners.Size = UDim2.new(1, 0, 0, 0)
outBanners.AutomaticSize = Enum.AutomaticSize.Y
outBanners.BackgroundTransparency = 1
outBanners.Active = false
outBanners.Parent = battleBanners
do
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Padding = UDim.new(0, 4)
	list.Parent = outBanners
end
local outCount = 0
showOutBanner = function(text: string)
	outCount += 1
	local line = battleLabel("Out", outCount, Color3.fromRGB(250, 205, 80), outBanners)
	line.Text = text
	line.Visible = true
	local lines = {}
	for _, child in outBanners:GetChildren() do
		if child:IsA("TextLabel") then
			table.insert(lines, child)
		end
	end
	table.sort(lines, function(x, y)
		return x.LayoutOrder < y.LayoutOrder
	end)
	for i = 1, #lines - FEED_LINES do
		lines[i]:Destroy() -- only the newest few stay
	end
	task.delay(FEED_SECONDS, function()
		line:Destroy()
	end)
end
local stampedeBanner = battleLabel("FinalStampede", 2, Color3.fromRGB(250, 205, 80), battleBanners)
stampedeBanner.Text = PanelRules.STAMPEDE_LINE
local camoTag = battleLabel("CamoCover", 1, Color3.fromRGB(140, 240, 170), gui)
camoTag.AnchorPoint = Vector2.new(0.5, 1)
camoTag.Position = UDim2.new(0.5, 0, 1, -96)
camoTag.Size = UDim2.new(0.5, 0, 0, 28)
do
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(320, 28)
	limit.Parent = camoTag
end

local function camoLeft(): number
	local character = player.Character
	local untilAt = if character then character:GetAttribute("CamoUntil") else nil
	if typeof(untilAt) ~= "number" then
		return 0
	end
	return math.max(0, untilAt - workspace:GetServerTimeNow())
end

local function refreshBattle()
	local state = attr("State", "Waiting")
	local battle = attr("BattleMode", nil)
	local out = player:GetAttribute("Out") == true
	local left = camoLeft()
	local show = PanelRules.battleHud(state, battle, out, attr("Overtime", nil), left)
	spectateBanner.Visible = show.spectate
	stampedeBanner.Visible = show.stampede
	camoTag.Visible = show.camo
	feedList.Visible = show.feed -- hidden while the results are up (T86b F5)
	outBanners.Visible = show.feed -- camp-out banners too (T86b F5)
	if show.camo then
		camoTag.Text = `{PanelRules.CAMO_LINE} ({math.ceil(left)}s)`
	end
	campsBoard.Visible = show.camps
	local boardBottom = if show.camps then campsBoard.Position.Y.Offset + campsBoard.AbsoluteSize.Y else nil
	battleBanners.Position = UDim2.new(0.5, 0, 0, PanelRules.bannerTop(BANNERS_TOP, boardBottom, 8))
	local mySide = Sides.playerSide(player:GetAttribute("Side"), attr("Sides", nil))
	campStroke.Enabled = show.camps
	if not show.camps then
		return
	end
	campStroke.Color = BrickColor.new(BattleFlow.campColor(mySide) :: any).Color
	local camps = {}
	for side = 1, math.floor(attr("Sides", 1)) do
		local camp = attr(Sides.attr("Camp", side), nil)
		if typeof(camp) == "string" then
			table.insert(camps, {
				side = side,
				camp = camp,
				fence = attr(Sides.attr("Lives", side), 0),
				bones = attr(Sides.attr("CampBones", side), 0),
				out = attr(Sides.attr("Out", side), false) == true,
			})
		end
	end
	local rows = PanelRules.campRows(camps, mySide)
	local lines = { PanelRules.campsHeader(rows) }
	for _, row in rows do
		local swatch = `<font color="#{BrickColor.new(BattleFlow.campColor(row.side) :: any).Color:ToHex()}">■</font>`
		local text = richEscape(PanelRules.campLine(row))
		table.insert(lines, if row.mine then `{swatch} <b>{text}</b>` else `{swatch} {text}`)
	end
	campsBoard.Text = table.concat(lines, "\n")
end

for _, name in { "State", "BattleMode", "Overtime", "Sides" } do
	ReplicatedStorage:GetAttributeChangedSignal(name):Connect(refreshBattle)
end
ReplicatedStorage.AttributeChanged:Connect(function(name: string)
	for _, prefix in { "^Camp%d*$", "^CampBones%d*$", "^Lives%d*$", "^Out%d*$" } do
		if string.match(name, prefix) then
			refreshBattle()
			return
		end
	end
end)
for _, name in { "Out", "Side" } do
	player:GetAttributeChangedSignal(name):Connect(refreshBattle)
end
task.spawn(function() -- Camo Cover's countdown
	while true do
		task.wait(0.25)
		if camoTag.Visible or camoLeft() > 0 then
			refreshBattle()
		end
	end
end)
campsBoard:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshBattle) -- the board resizes with the window
refreshBattle()

gui.Parent = player:WaitForChild("PlayerGui")
