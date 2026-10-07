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
	local side = Sides.playerSide(player:GetAttribute("Side"), ReplicatedStorage:GetAttribute("Sides"))
	local lives = math.floor(attr(Sides.attr("Lives", side), 0)) -- your side's Fence (T76)
	local alive = math.floor(attr("Alive", 0))
	local cash = math.floor(attr(Sides.attr("Cash", side), 0)) -- your side's cash

	startButton.Visible = state == "Building"
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

	if state == "GameOver" or state == "Victory" then
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
	elseif state == "Building" then
		label.Text = `Build (B), choose a hero (H), then Start  ·  {difficultyName}  ·  Cash {cash}  ·  {Theme.Fence} {lives}`
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
			label.Text = `{if state == "Victory" then "VICTORY" else "GAME OVER"}  ·  home in {left}s`
		end
	end
end)

for _, name in { "State", "Round", "Lives", "Alive", "Cash", "Difficulty", "RoundsCleared", "Sides" } do
	ReplicatedStorage:GetAttributeChangedSignal(name):Connect(refresh)
end
for _, name in { "HeroXp", "HeroXpPending", "HeroLevel", "Side" } do
	player:GetAttributeChangedSignal(name):Connect(refresh)
end
-- Another battle side's cash or Fence ("Cash2", "Lives3"...; Shared/Sides.attr).
ReplicatedStorage.AttributeChanged:Connect(function(name: string)
	if string.match(name, "^Cash%d+$") or string.match(name, "^Lives%d+$") then
		refresh()
	end
end)
refresh()

gui.Parent = player:WaitForChild("PlayerGui")
