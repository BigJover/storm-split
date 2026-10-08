--[[
	Home screen, shown while the server is in the Lobby state (Main).

	Game mode, track and difficulty cards, your Amber and hero, buttons
	for hero select, Unlocks & Mastery (they open Shop.client's panels) and the
	Hunt Board (HuntBoard.client's screen; an amber dot says something is waiting
	to be claimed), the Profile screen beside it (Profile.client, PLAN T57), and Play. The host — the longest-connected player — makes the choices and
	presses Play; everyone else sees them live and waits. Choices are only
	requests to the server.

	Behind it, the camera slowly circles the map. No character exists here;
	the server spawns everyone when Play is pressed.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local HuntBoard = require(Shared:WaitForChild("HuntBoard"))
local ProfileScreen = require(Shared:WaitForChild("ProfileScreen"))
local HomeLayout = require(Shared:WaitForChild("HomeLayout"))
local Modes = require(Shared:WaitForChild("Modes"))
local Theme = require(Shared:WaitForChild("Theme"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local lobby = remotes:WaitForChild("Lobby") :: RemoteEvent

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Visuals only.
local BG = Color3.fromRGB(16, 13, 24)
local CARD = Color3.fromRGB(40, 34, 56)
local CARD_SELECTED = Color3.fromRGB(200, 90, 110)
local CARD_LOCKED = Color3.fromRGB(30, 27, 38)
local TEXT = Color3.fromRGB(240, 236, 250)
local TEXT_DIM = Color3.fromRGB(150, 145, 165)
local PLAY = Color3.fromRGB(70, 180, 110)
local AMBER = Color3.fromRGB(245, 175, 60)
local ORBIT_CENTRE = Vector3.new(-10, 0, 0)
local ORBIT_RADIUS = 150
local ORBIT_HEIGHT = 110
local ORBIT_SPEED = 0.05 -- radians per second

------------------------------------------------------------------ layout

local gui = Instance.new("ScreenGui")
gui.Name = "StormSplitHome"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 5 -- Shop.client's panels (10) open on top of it

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = BG
backdrop.BackgroundTransparency = 0.35
backdrop.Parent = gui

local column = Instance.new("Frame")
column.AnchorPoint = Vector2.new(0.5, 0.5)
column.Position = UDim2.fromScale(0.5, 0.5)
column.Size = UDim2.fromOffset(HomeLayout.COLUMN, 0)
column.AutomaticSize = Enum.AutomaticSize.Y
column.BackgroundTransparency = 1
column.Parent = backdrop

-- The home screen shrinks to fit short or narrow windows, so every card and
-- the Play button are always reachable (a host who can't see Play can't start).
local columnScale = Instance.new("UIScale")
columnScale.Parent = column
local SCREEN_MARGIN = 24 -- px kept clear on each edge

do
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 14)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = column

	local function fit()
		local viewport = camera.ViewportSize
		local content = layout.AbsoluteContentSize / math.max(columnScale.Scale, 0.01)
		local tall = (viewport.Y - SCREEN_MARGIN * 2) / math.max(content.Y, 1)
		local wide = (viewport.X - SCREEN_MARGIN * 2) / HomeLayout.COLUMN
		columnScale.Scale = math.clamp(math.min(tall, wide), 0.4, 1)
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fit)
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	task.defer(fit)
end

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function text(order: number, value: string, size: number, font: Enum.Font, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.LayoutOrder = order
	label.Size = UDim2.new(1, 0, 0, size + 8)
	label.BackgroundTransparency = 1
	label.Font = font
	label.TextSize = size
	label.TextColor3 = color
	label.RichText = true
	label.Text = value
	label.Parent = column
	return label
end

local function row(order: number, height: number): Frame
	local frame = Instance.new("Frame")
	frame.LayoutOrder = order
	frame.Size = UDim2.new(1, 0, 0, height)
	frame.BackgroundTransparency = 1
	frame.Parent = column
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, HomeLayout.GAP)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame
	return frame
end

local function card(parent: Instance, order: number, width: number, height: number): TextButton
	local button = Instance.new("TextButton")
	button.LayoutOrder = order
	button.Size = UDim2.fromOffset(width, height)
	button.BackgroundColor3 = CARD
	button.AutoButtonColor = false
	button.Font = Enum.Font.GothamBold
	button.TextSize = 18
	button.TextColor3 = TEXT
	button.TextWrapped = true
	button.RichText = true
	button.Parent = parent
	corner(button, 10)
	local stroke = Instance.new("UIStroke")
	stroke.Name = "Selected"
	stroke.Thickness = 3
	stroke.Color = CARD_SELECTED
	stroke.Enabled = false
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = button
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, HomeLayout.CARD_PAD)
	padding.PaddingRight = UDim.new(0, HomeLayout.CARD_PAD)
	padding.Parent = button
	return button
end

text(1, string.upper(Theme.Title), 56, Enum.Font.GothamBlack, AMBER)
local profileLine = text(2, "", 18, Enum.Font.GothamBold, TEXT_DIM)

text(3, "GAME MODE", 16, Enum.Font.GothamBold, TEXT_DIM)
local modeRow = row(4, 120)
local modeCards: { [string]: TextButton } = {}
for order, key in Modes.ModeOrder do
	local mode = Modes.Modes[key]
	local button = card(modeRow, order, 236, 120)
	local soon = if mode.available then "" else `\n<font size="14" color="#ffcc55">Coming soon</font>`
	button.Text = `{mode.display}\n<font size="14" color="#aaa3bb">{mode.blurb}</font>{soon}`
	button.Activated:Connect(function()
		lobby:FireServer("mode", key)
	end)
	modeCards[key] = button
end

text(5, "TRACK", 16, Enum.Font.GothamBold, TEXT_DIM)
local trackRow = row(6, 70)
local trackCards: { [string]: TextButton } = {}
for order, key in Modes.TrackOrder do
	local track = Modes.Tracks[key]
	local button = card(trackRow, order, 300, 70)
	button.Text = `{track.display}\n<font size="14" color="#aaa3bb">{track.blurb}</font>`
	button.Activated:Connect(function()
		lobby:FireServer("track", key)
	end)
	trackCards[key] = button
end

text(7, "DIFFICULTY", 16, Enum.Font.GothamBold, TEXT_DIM)
local difficultyRow = row(8, 64)
local difficultyCards: { [string]: TextButton } = {}
for order, key in Config.DifficultyOrder do
	local level = Config.Difficulties[key]
	local button = card(difficultyRow, order, 170, 64)
	button.Text = `{level.display}\n<font size="14" color="#aaa3bb">clear: {level.clearReward} {string.lower(Theme.Currency)}</font>`
	button.Activated:Connect(function()
		lobby:FireServer("difficulty", key)
	end)
	difficultyCards[key] = button
end

local hostLine = text(9, "", 16, Enum.Font.GothamBold, TEXT_DIM)

-- The Hunt Board has its own row above the action row (DECISIONS #138).
-- HuntBoard.client keeps its board above this row (found by name), so its button,
-- Play and the action row stay in reach while the board is open.
local huntRow = row(10, HomeLayout.ROW_HEIGHT)
huntRow.Name = HomeLayout.HUNT_ROW
-- Every player has this button, host or not. Pressing it again closes the board.
local huntCard = card(huntRow, 1, HomeLayout.HUNT_WIDTH, HomeLayout.ROW_HEIGHT)
huntCard.TextSize = HomeLayout.HUNT_TEXT_SIZE
huntCard.Text = HuntBoard.BUTTON
huntCard.Activated:Connect(function()
	player:SetAttribute("OpenPanel", HuntBoard.MODE)
end)
local huntDot = Instance.new("Frame") -- something to claim: a still amber dot
huntDot.Name = "Claimable"
huntDot.AnchorPoint = Vector2.new(1, 0)
huntDot.Position = UDim2.new(1, 4, 0, 6)
huntDot.Size = UDim2.fromOffset(12, 12)
huntDot.BackgroundColor3 = AMBER
huntDot.BorderSizePixel = 0
huntDot.Visible = false
huntDot.Parent = huntCard
corner(huntDot, 6)
-- Profile (PLAN T57): the player level, rewards and what you wear. Every player has it.
local profileCard = card(huntRow, 2, HomeLayout.PROFILE_WIDTH, HomeLayout.ROW_HEIGHT)
profileCard.TextSize = HomeLayout.HUNT_TEXT_SIZE
profileCard.Text = ProfileScreen.BUTTON
profileCard.Activated:Connect(function()
	player:SetAttribute("OpenPanel", ProfileScreen.MODE)
end)

local actionRow = row(11, HomeLayout.ROW_HEIGHT)
actionRow.Name = "Actions"
local heroCard = card(actionRow, 1, HomeLayout.HERO.width, HomeLayout.ROW_HEIGHT)
heroCard.TextSize = HomeLayout.HERO.textSize
heroCard.Text = HomeLayout.HERO.text
-- Modal on a button every player sees: frees the mouse on the home screen for
-- non-hosts too (Play, the host's Modal button, is hidden for them).
heroCard.Modal = true
heroCard.Activated:Connect(function()
	player:SetAttribute("OpenPanel", "heroPick")
end)
local unlockCard = card(actionRow, 2, HomeLayout.UNLOCKS.width, HomeLayout.ROW_HEIGHT)
unlockCard.TextSize = HomeLayout.UNLOCKS.textSize
unlockCard.Text = HomeLayout.UNLOCKS.text
unlockCard.Activated:Connect(function()
	player:SetAttribute("OpenPanel", "mastery")
end)
local playButton = card(actionRow, 3, HomeLayout.PLAY.width, HomeLayout.ROW_HEIGHT)
playButton.BackgroundColor3 = PLAY
playButton.TextSize = HomeLayout.PLAY.textSize
playButton.Text = HomeLayout.PLAY.text
playButton.Modal = true -- the mouse is free on the home screen
playButton.Activated:Connect(function()
	lobby:FireServer("play")
end)

-- The waiting banner (PLAN T79b, DECISIONS #232): a player who joins mid-battle stays here
-- until the next hunt. It wraps to the window's width (fits any size) and is a Modal
-- button, so the mouse stays free; it goes when the hunt ends (refresh, on "State").
local waitBanner = Instance.new("TextButton")
waitBanner.Name = "WaitingBanner"
waitBanner.AnchorPoint = Vector2.new(0.5, 0.5)
waitBanner.Position = UDim2.fromScale(0.5, 0.5)
waitBanner.Size = UDim2.new(0.8, 0, 0, 0)
waitBanner.AutomaticSize = Enum.AutomaticSize.Y
waitBanner.BackgroundColor3 = CARD
waitBanner.AutoButtonColor = false
waitBanner.Modal = true -- the mouse is free while waiting
waitBanner.Font = Enum.Font.GothamBold
waitBanner.TextSize = 26
waitBanner.TextColor3 = AMBER
waitBanner.TextWrapped = true
waitBanner.Text = HomeLayout.WAITING_BANNER
waitBanner.Visible = false
waitBanner.Parent = backdrop
corner(waitBanner, 10)
do
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 18)
	padding.PaddingBottom = UDim.new(0, 18)
	padding.PaddingLeft = UDim.new(0, 18)
	padding.PaddingRight = UDim.new(0, 18)
	padding.Parent = waitBanner
end

------------------------------------------------------------------ state

local function isHost(): boolean
	return ReplicatedStorage:GetAttribute("Host") == player.UserId
end

local function mark(cards: { [string]: TextButton }, selected: string?)
	for key, button in cards do
		local stroke = button:FindFirstChild("Selected") :: UIStroke?
		if stroke then
			stroke.Enabled = key == selected
		end
	end
end

-- Joined while a battle is on (PLAN T79b): the home screen with only the waiting banner.
local function waiting(): boolean
	return HomeLayout.waitingForNextHunt(ReplicatedStorage:GetAttribute("State"), ReplicatedStorage:GetAttribute("BattleMode"), player:GetAttribute("BattleSide"))
end

local function refresh()
	local inLobby = ReplicatedStorage:GetAttribute("State") == "Lobby"
	local wait = waiting()
	gui.Enabled = inLobby or wait
	column.Visible = inLobby
	waitBanner.Visible = wait
	if not inLobby then
		return
	end

	local host = isHost()
	for key, button in modeCards do
		local available = Modes.Modes[key].available
		button.BackgroundColor3 = if available then CARD else CARD_LOCKED
		button.Active = host and available
	end
	for _, cards in { trackCards, difficultyCards } do
		for _, button in cards do
			button.Active = host
		end
	end
	mark(modeCards, ReplicatedStorage:GetAttribute("Mode"))
	mark(trackCards, ReplicatedStorage:GetAttribute("Track"))
	mark(difficultyCards, ReplicatedStorage:GetAttribute("Difficulty"))

	local hostPlayer = Players:GetPlayerByUserId(ReplicatedStorage:GetAttribute("Host") or 0)
	hostLine.Text = if host
		then "You're the host: pick a mode, track and difficulty, then Play."
		else `Waiting for {if hostPlayer then hostPlayer.DisplayName else "the host"} to start…`
	playButton.Visible = host
	huntDot.Visible = player:GetAttribute("RewardsClaimable") == true

	local heroKey = player:GetAttribute("Hero") or ""
	local hero = Config.Heroes[heroKey]
	profileLine.Text = `{player:GetAttribute("Cores") or 0} {Theme.Currency}  ·  Hero: {if hero then hero.display else "none yet (H)"}`
end

for _, name in { "State", "Host", "Mode", "Track", "Difficulty", "BattleMode" } do
	ReplicatedStorage:GetAttributeChangedSignal(name):Connect(refresh)
end
player.AttributeChanged:Connect(function(name)
	if name == "Cores" or name == "Hero" or name == "RewardsClaimable" or name == "BattleSide" then
		refresh()
	end
end)
Players.PlayerAdded:Connect(refresh)
Players.PlayerRemoving:Connect(refresh)

------------------------------------------------------------------ camera

local orbiting = false
RunService.RenderStepped:Connect(function()
	local inLobby = ReplicatedStorage:GetAttribute("State") == "Lobby" or waiting()
	if inLobby then
		orbiting = true
		camera.CameraType = Enum.CameraType.Scriptable
		local angle = os.clock() * ORBIT_SPEED
		local eye = ORBIT_CENTRE + Vector3.new(math.cos(angle) * ORBIT_RADIUS, ORBIT_HEIGHT, math.sin(angle) * ORBIT_RADIUS)
		camera.CFrame = CFrame.lookAt(eye, ORBIT_CENTRE)
	elseif orbiting then
		orbiting = false
		camera.CameraType = Enum.CameraType.Custom -- back to following the character
	end
end)

refresh()
gui.Parent = player:WaitForChild("PlayerGui")
