--[[
	Home screen, shown while the server is in the Lobby state (Main).

	Game mode, track and difficulty cards; for Camp Clash and Bone Rush the battle options
	(Casual / Ranked, camps, Studio stand-ins) and, in Ranked, every player's own Ready with
	its Entry fee confirm (PLAN T82, Shared/HomeLayout); your Amber and hero, buttons
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

-- Battle options (PLAN T82, Shared/HomeLayout): shown only for Camp Clash and Bone Rush.
-- The host's choices (Casual/Ranked, 2/3 camps, Studio stand-ins); everyone sees them live.
local battleHeader = text(9, HomeLayout.BATTLE_HEADER, 16, Enum.Font.GothamBold, TEXT_DIM)
local optionRow = row(10, HomeLayout.OPTION_HEIGHT)
local function chip(order: number, spec: HomeLayout.Card, onClick: () -> ()): TextButton
	local button = card(optionRow, order, spec.width, HomeLayout.OPTION_HEIGHT)
	button.TextSize = spec.textSize
	button.Text = spec.text
	button.Activated:Connect(onClick)
	return button
end
local casualChip = chip(1, HomeLayout.CASUAL, function()
	lobby:FireServer("ranked", false)
end)
local rankedChip = chip(2, HomeLayout.RANKED, function()
	lobby:FireServer("ranked", true)
end)
local sideChips: { [number]: TextButton } = {}
for i, spec in HomeLayout.SIDES do
	local count = Modes.TeamSides[i]
	sideChips[count] = chip(2 + i, spec, function()
		lobby:FireServer("sides", count)
	end)
end
local seatsChip = chip(5, HomeLayout.SEATS, function()
	lobby:FireServer("sides", HomeLayout.nextSeats(ReplicatedStorage:GetAttribute("BattleSides")))
end)
local standInChip = chip(6, HomeLayout.STAND_INS, function()
	lobby:FireServer("standins", ReplicatedStorage:GetAttribute("StandIns") ~= true)
end)

-- Ranked: every player's own Ready (DECISIONS #223). The card opens an inline confirm
-- ("Pay 15 Amber to enter?") with an X beside it; pressing the card again pays. It sits in
-- the home column, so it scales with it, the home screen keeps the mouse free, and it
-- closes on its X, on Ready, and on every state change (HomeLayout.confirmOpen).
local FEE = Config.Tuning.CompetitiveBuyIn
local readyRow = row(11, HomeLayout.ROW_HEIGHT)
local readyCard = card(readyRow, 1, HomeLayout.READY_WIDTH, HomeLayout.ROW_HEIGHT)
readyCard.TextSize = HomeLayout.READY_TEXT
readyCard.Modal = true -- every Ranked player can reach it with a free mouse
local readyX = card(readyRow, 2, HomeLayout.READY_X, HomeLayout.ROW_HEIGHT)
readyX.Text = "X"
local readyInfo = Instance.new("TextLabel")
readyInfo.LayoutOrder = 3
readyInfo.Size = UDim2.fromOffset(HomeLayout.READY_INFO, HomeLayout.ROW_HEIGHT)
readyInfo.BackgroundTransparency = 1
readyInfo.Font = Enum.Font.GothamBold
readyInfo.TextColor3 = TEXT_DIM
readyInfo.TextXAlignment = Enum.TextXAlignment.Left
readyInfo.RichText = true
readyInfo.TextScaled = true -- three short lines; shrinks rather than spill out of the row
readyInfo.Parent = readyRow
do
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 14
	limit.MinTextSize = 8
	limit.Parent = readyInfo
end
local confirmWanted = false

local hostLine = text(12, "", 16, Enum.Font.GothamBold, TEXT_DIM)

-- The Hunt Board has its own row above the action row (DECISIONS #138).
-- HuntBoard.client keeps its board above this row (found by name), so its button,
-- Play and the action row stay in reach while the board is open.
local huntRow = row(13, HomeLayout.ROW_HEIGHT)
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

local actionRow = row(14, HomeLayout.ROW_HEIGHT)
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
	lobby:FireServer("play") -- the server checks the minimum too (HomeLayout.canPlay)
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
	-- The Ready confirm closes on its X, on Ready and on every state change (no-trap rule).
	confirmWanted = HomeLayout.confirmOpen(confirmWanted, ReplicatedStorage:GetAttribute("State"), ReplicatedStorage:GetAttribute("Mode"), ReplicatedStorage:GetAttribute("Ranked") == true, player:GetAttribute("Ready"))
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

	-- Battle options and Ready (PLAN T82).
	local modeKey = ReplicatedStorage:GetAttribute("Mode")
	local ranked = ReplicatedStorage:GetAttribute("Ranked") == true
	local options = HomeLayout.battleOptions(modeKey, RunService:IsStudio())
	local rankedBattle = HomeLayout.readyRowVisible(modeKey, ranked)
	local standIns = options.standIns and ReplicatedStorage:GetAttribute("StandIns") == true
	local picked = ReplicatedStorage:GetAttribute("BattleSides")
	battleHeader.Visible = options.queue
	battleHeader.Text = if rankedBattle then `{HomeLayout.BATTLE_HEADER}  ·  {HomeLayout.RANKED_NORMAL}` else HomeLayout.BATTLE_HEADER
	optionRow.Visible = options.queue
	casualChip.Active, rankedChip.Active = host, host
	mark({ casual = casualChip, ranked = rankedChip }, if ranked then "ranked" else "casual")
	for count, button in sideChips do
		button.Visible = options.sides
		button.Active = host
		local stroke = button:FindFirstChild("Selected") :: UIStroke?
		if stroke then
			stroke.Enabled = count == (if typeof(picked) == "number" then picked else Modes.TeamSides[1])
		end
	end
	seatsChip.Visible = options.seats and standIns
	seatsChip.Active = host
	seatsChip.Text = HomeLayout.seatsText(if typeof(picked) == "number" then picked else 2)
	standInChip.Visible = options.standIns
	standInChip.Active = host
	mark({ on = standInChip }, if standIns then "on" else nil)
	if rankedBattle then
		for _, button in difficultyCards do
			button.Active = false -- Ranked is always Normal (#217)
		end
	end

	local readyNames: { string } = {}
	for _, each in Players:GetPlayers() do
		if each:GetAttribute("Ready") == true then
			table.insert(readyNames, each.DisplayName)
		end
	end
	local amReady = player:GetAttribute("Ready") == true
	readyRow.Visible = rankedBattle
	readyX.Visible = confirmWanted
	readyCard.Text = if amReady then HomeLayout.READY_DONE elseif confirmWanted then HomeLayout.confirmText(FEE, Theme.Currency) else HomeLayout.READY
	readyCard.BackgroundColor3 = if amReady then PLAY else CARD
	local stroke = readyCard:FindFirstChild("Selected") :: UIStroke?
	if stroke then
		stroke.Enabled = confirmWanted
	end
	local playOk, need = HomeLayout.canPlay(modeKey, ranked, #Players:GetPlayers(), #readyNames, if typeof(picked) == "number" then picked else nil, standIns)
	local refused = HomeLayout.refusalLine(player:GetAttribute("ReadyRefused"), FEE, Theme.Currency)
	local second = if refused
		then `<font color="#ff788c">{refused}</font>`
		elseif ReplicatedStorage:GetAttribute("PracticeHunt") == true then HomeLayout.PRACTICE_LINE
		else HomeLayout.HOARD_LINE
	readyInfo.Text = `{HomeLayout.feeLine(FEE, player:GetAttribute("Cores") or 0, Theme.Currency)}\n{second}\n{HomeLayout.readyLine(readyNames, need)}`

	local hostPlayer = Players:GetPlayerByUserId(ReplicatedStorage:GetAttribute("Host") or 0)
	local mode = if type(modeKey) == "string" then Modes.Modes[modeKey] else nil
	hostLine.Text = if not playOk and mode
		then HomeLayout.needLine(mode.display, need)
		elseif host then "You're the host: pick a mode, track and difficulty, then Play."
		else `Waiting for {if hostPlayer then hostPlayer.DisplayName else "the host"} to start…`
	playButton.Visible = host
	playButton.Active = playOk -- PLAY works once the minimum is met (PLAN T82)
	playButton.BackgroundColor3 = if playOk then PLAY else CARD_LOCKED
	huntDot.Visible = player:GetAttribute("RewardsClaimable") == true

	local heroKey = player:GetAttribute("Hero") or ""
	local hero = Config.Heroes[heroKey]
	profileLine.Text = `{player:GetAttribute("Cores") or 0} {Theme.Currency}  ·  Hero: {if hero then hero.display else "none yet (H)"}`
end

readyCard.Activated:Connect(function()
	if player:GetAttribute("Ready") == true then
		lobby:FireServer("ready", false) -- free: the Entry fee is only taken when Building starts
	elseif confirmWanted then
		confirmWanted = false
		lobby:FireServer("ready", true)
	else
		confirmWanted = true
	end
	refresh()
end)
readyX.Activated:Connect(function()
	confirmWanted = false
	refresh()
end)

for _, name in { "State", "Host", "Mode", "Track", "Difficulty", "BattleMode", "Ranked", "BattleSides", "StandIns", "PracticeHunt" } do
	ReplicatedStorage:GetAttributeChangedSignal(name):Connect(refresh)
end
player.AttributeChanged:Connect(function(name)
	if name == "Cores" or name == "Hero" or name == "RewardsClaimable" or name == "BattleSide" or name == "ReadyRefused" then
		refresh()
	end
end)
-- Who's ready: every player's own "Ready" (the server sets it).
local function watchReady(each: Player)
	each:GetAttributeChangedSignal("Ready"):Connect(refresh)
end
for _, each in Players:GetPlayers() do
	watchReady(each)
end
Players.PlayerAdded:Connect(watchReady)
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
