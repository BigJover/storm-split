--[[
	The Profile screen (PLAN round 4 T57, DECISIONS #118-#121): your player level, the XP
	bar, the next rewards, and what you wear — a row per slot (the title and one cosmetic
	per kind) with every unlocked item to pick from. Its Leaderboard tab (T58, DECISIONS
	#122) shows the level board from Server/LevelBoard: the world top 50 when published,
	else "This server" with its note; your own row always. If the server can't be asked,
	the tab builds the "This server" board itself from the players here, so it never
	errors or hangs.

	Open and close: P, the home screen's Profile button, or the X. Shop.client owns which
	panel is open (its mode "profile", so it never overlaps the Hunt Board or the shop
	panels) and Shared/PanelRules closes it on every match-state change; this script shows
	it while the "ProfileOpen" attribute is set and the state is Lobby.

	No pop-up may trap a player (DIRECTION):
	  - Shared/ProfileScreen.layout fits it between the top bar and the home screen's Hunt
	    Board row on any window: the list scrolls first, then the whole screen scales
	    down. The header and its X are outside the scrolling list.
	  - Nothing here dims or covers the rest of the screen, and Play stays in reach.
	  - The X is Modal, so the mouse is free while it's open.

	Everything shown comes from attributes Server/Progression publishes (PlayerXp,
	Equip_<slot>, SaveStatus) and the Cosmetics sheet. Picking an item is a request
	("equip" on ProgressRequest); the server checks it and the screen redraws from the
	attributes it publishes.
]]

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cosmetics = require(Shared:WaitForChild("Cosmetics"))
local HomeLayout = require(Shared:WaitForChild("HomeLayout"))
local LevelBoard = require(Shared:WaitForChild("LevelBoard"))
local ProfileScreen = require(Shared:WaitForChild("ProfileScreen"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local progressRequest = remotes:WaitForChild("ProgressRequest") :: RemoteFunction
local boardRequest = remotes:WaitForChild("LevelBoard") :: RemoteFunction

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Visuals only.
local BG = Color3.fromRGB(34, 30, 44)
local BG_LIGHT = Color3.fromRGB(52, 46, 66)
local RIM = Color3.fromRGB(95, 85, 120)
local AMBER = Color3.fromRGB(245, 175, 60)
local TEXT = Color3.fromRGB(240, 236, 250)
local TEXT_DIM = Color3.fromRGB(160, 152, 180)
local CHIP = Color3.fromRGB(60, 54, 78)
local CHIP_ON = Color3.fromRGB(200, 90, 110)
local BAR_BACK = Color3.fromRGB(24, 21, 32)
local GOOD = Color3.fromRGB(140, 240, 170)
local BAD = Color3.fromRGB(240, 130, 110)
local TOP_GAP = 8
local BOTTOM_GAP = 8
local CHIP_HEIGHT = 30
local BOARD_ASK_SECONDS = 15 -- an open Leaderboard tab asks the server's cache again
-- The level badge's frame by band (DECISIONS #121: the free badge frame): under 100,
-- 100-149, 150-199, 200 and up. Never gold: that's mastery 20's.
local BAND_COLOURS = {
	Color3.fromRGB(120, 112, 140),
	Color3.fromRGB(90, 160, 200),
	Color3.fromRGB(170, 110, 220),
	Color3.fromRGB(230, 110, 90),
}
local SELF_ROW = Color3.fromRGB(70, 60, 92)

------------------------------------------------------------------ layout

local gui = Instance.new("ScreenGui")
gui.Name = "DinoHuntersProfile"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10 -- above the home screen (5)
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = false

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function label(parent: Instance, text: string, size: number, font: Enum.Font, color: Color3): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = font
	l.TextSize = size
	l.TextColor3 = color
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Text = text
	l.Parent = parent
	return l
end

local board = Instance.new("Frame")
board.Name = "Board"
board.AnchorPoint = Vector2.new(0.5, 0)
board.BackgroundColor3 = BG
board.BorderSizePixel = 0
board.Active = true -- clicks don't fall through to the cards behind it
board.Parent = gui
corner(board, 10)
local boardScale = Instance.new("UIScale")
boardScale.Parent = board
do
	local rim = Instance.new("UIStroke")
	rim.Thickness = 2
	rim.Color = RIM
	rim.Parent = board
end

local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.fromScale(1, 1)
content.BackgroundTransparency = 1
content.Parent = board
do
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, ProfileScreen.PAD)
	padding.PaddingBottom = UDim.new(0, ProfileScreen.PAD)
	padding.PaddingLeft = UDim.new(0, ProfileScreen.PAD)
	padding.PaddingRight = UDim.new(0, ProfileScreen.PAD)
	padding.Parent = content
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, ProfileScreen.GAP)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = content
end

local function section(order: number, height: number): Frame
	local frame = Instance.new("Frame")
	frame.LayoutOrder = order
	frame.Size = UDim2.new(1, 0, 0, height)
	frame.BackgroundTransparency = 1
	frame.Parent = content
	return frame
end

-- Header: the title and the X. Never inside the scrolling list.
local header = section(1, ProfileScreen.HEADER)
header.Name = "Header"
local title = label(header, ProfileScreen.TITLE, 24, Enum.Font.GothamBlack, AMBER)
title.Size = UDim2.new(1, -(ProfileScreen.HEADER + 8), 1, 0)

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.fromScale(1, 0)
closeButton.Size = UDim2.fromOffset(ProfileScreen.HEADER, ProfileScreen.HEADER)
closeButton.BackgroundColor3 = BG_LIGHT
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 18
closeButton.TextColor3 = TEXT
closeButton.Text = "X"
closeButton.Modal = true -- the mouse is free while the screen is showing
closeButton.Parent = header
corner(closeButton, 6)

-- The tabs: Profile and Leaderboard.
local tabRow = section(2, ProfileScreen.TABS)
tabRow.Name = "Tabs"
do
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = tabRow
end
local function tabButton(order: number, text: string): TextButton
	local button = Instance.new("TextButton")
	button.LayoutOrder = order
	button.Size = UDim2.new(0.5, -3, 1, 0)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.TextColor3 = TEXT
	button.Text = text
	button.Parent = tabRow
	corner(button, 6)
	return button
end
local profileTab = tabButton(1, ProfileScreen.TAB_PROFILE)
local boardTab = tabButton(2, ProfileScreen.TAB_BOARD)

-- The level block: "Player level 12", the bar, "340 / 1,050 XP to level 13".
local levelBlock = section(3, ProfileScreen.LEVEL)
levelBlock.Name = "Level"
local levelLabel = label(levelBlock, "", 20, Enum.Font.GothamBold, TEXT)
levelLabel.Size = UDim2.new(1, 0, 0, 24)
local barBack = Instance.new("Frame")
barBack.Position = UDim2.fromOffset(0, 28)
barBack.Size = UDim2.new(1, 0, 0, 8)
barBack.BackgroundColor3 = BAR_BACK
barBack.BorderSizePixel = 0
barBack.Parent = levelBlock
corner(barBack, 4)
local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(0, 1)
barFill.BackgroundColor3 = AMBER
barFill.BorderSizePixel = 0
barFill.Parent = barBack
corner(barFill, 4)
local xpLabel = label(levelBlock, "", 13, Enum.Font.Gotham, TEXT_DIM)
xpLabel.Position = UDim2.fromOffset(0, 38)
xpLabel.Size = UDim2.new(1, 0, 0, 16)

-- The only part that scrolls: next rewards and the slots.
local list = Instance.new("ScrollingFrame")
list.Name = "List"
list.LayoutOrder = 4
list.Size = UDim2.new(1, 0, 0, 0)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.ScrollBarImageColor3 = RIM
list.ScrollingDirection = Enum.ScrollingDirection.Y
list.CanvasSize = UDim2.new()
list.Parent = content
do
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, ProfileScreen.GAP)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
end

local message = label(section(5, ProfileScreen.MESSAGE), "", 14, Enum.Font.Gotham, TEXT_DIM)
message.Size = UDim2.fromScale(1, 1)

------------------------------------------------------------------ state

local listContent = 0
local busy = false
local tab: "profile" | "board" = "profile"
local boardView: LevelBoard.View? = nil -- the last answer from Server/LevelBoard
local boardAskedAt = -math.huge
local boardAsking = false

local function shown(): boolean
	return ProfileScreen.shown(player:GetAttribute("ProfileOpen") == true, ReplicatedStorage:GetAttribute("State"))
end

-- Under the top bar, above the home screen's Hunt Board row (its buttons, Play and the
-- action row below it stay uncovered).
local function band(): (number, number)
	local top = GuiService:GetGuiInset().Y + TOP_GAP
	local bottom = gui.AbsoluteSize.Y - ProfileScreen.EDGE
	local home = playerGui:FindFirstChild("StormSplitHome")
	local row = home and home:FindFirstChild(HomeLayout.HUNT_ROW, true)
	if row and row:IsA("GuiObject") and row.AbsoluteSize.Y > 0 then
		local rowTop = row.AbsolutePosition.Y - gui.AbsolutePosition.Y
		if rowTop > top then
			bottom = math.min(bottom, rowTop - BOTTOM_GAP)
		end
	end
	return top, bottom
end

local function fit()
	if not gui.Enabled then
		return
	end
	local top, bottom = band()
	local layout = ProfileScreen.layout(gui.AbsoluteSize.X, top, bottom, listContent)
	boardScale.Scale = layout.scale
	board.Position = UDim2.new(0.5, 0, 0, top)
	board.Size = UDim2.fromOffset(layout.width, layout.height)
	list.Size = UDim2.new(1, 0, 0, layout.listHeight)
end

local function say(text: string, color: Color3?)
	message.Text = text
	message.TextColor3 = color or TEXT_DIM
end

local function equipped(): { [string]: string? }
	local out = {}
	for _, slot in Cosmetics.SLOTS do
		local id = player:GetAttribute(`Equip_{slot}`)
		out[slot] = if type(id) == "string" then id else nil
	end
	return out
end

local function clear(frame: Instance)
	for _, child in frame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local render: () -> ()

-- The players here with their live XP: the "This server" board when the server can't
-- be asked (Shared/LevelBoard.view with no world board).
local function localBoard(): LevelBoard.View
	local here = {}
	for _, other in Players:GetPlayers() do
		local xp = other:GetAttribute("PlayerXp")
		table.insert(here, { userId = other.UserId, name = other.DisplayName, xp = if type(xp) == "number" then xp else 0 })
	end
	return LevelBoard.view(nil, here, player.UserId)
end

local function askBoard()
	if boardAsking then
		return
	end
	boardAsking = true
	boardAskedAt = os.clock()
	local ok, answer = pcall(function()
		return boardRequest:InvokeServer()
	end)
	boardAsking = false
	boardView = if ok and type(answer) == "table" and type(answer.rows) == "table" then answer :: LevelBoard.View else localBoard()
	render()
end

local function pick(slot: string, id: string)
	if busy then
		return
	end
	busy = true
	say("…")
	local ok, success, text = pcall(function()
		return progressRequest:InvokeServer("equip", slot, id)
	end)
	busy = false
	if not ok then
		say("Couldn't reach the server", BAD)
	else
		say(tostring(text), if success then GOOD else BAD)
	end
	render()
end

local function addLine(order: number, text: string, size: number, font: Enum.Font, color: Color3, height: number)
	local l = label(list, text, size, font, color)
	l.LayoutOrder = order
	l.Size = UDim2.new(1, -8, 0, height)
end

local function addSlot(order: number, row: ProfileScreen.SlotRow)
	local frame = Instance.new("Frame")
	frame.LayoutOrder = order
	frame.Size = UDim2.new(1, -8, 0, ProfileScreen.SLOT)
	frame.BackgroundTransparency = 1
	frame.Parent = list
	local name = label(frame, row.label, 14, Enum.Font.GothamBold, TEXT)
	name.Size = UDim2.new(1, 0, 0, 18)
	if row.locked or #row.chips == 0 then
		local note = label(frame, row.locked or "", 13, Enum.Font.Gotham, TEXT_DIM)
		note.Position = UDim2.fromOffset(0, 22)
		note.Size = UDim2.new(1, 0, 0, CHIP_HEIGHT)
		return
	end
	-- The chips scroll sideways inside their row, so a long title list never widens the screen.
	local strip = Instance.new("ScrollingFrame")
	strip.Position = UDim2.fromOffset(0, 22)
	strip.Size = UDim2.new(1, 0, 0, CHIP_HEIGHT + 6)
	strip.BackgroundTransparency = 1
	strip.BorderSizePixel = 0
	strip.ScrollBarThickness = 4
	strip.ScrollBarImageColor3 = RIM
	strip.ScrollingDirection = Enum.ScrollingDirection.X
	strip.AutomaticCanvasSize = Enum.AutomaticSize.X
	strip.CanvasSize = UDim2.new()
	strip.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = strip
	for i, chip in row.chips do
		local button = Instance.new("TextButton")
		button.LayoutOrder = i
		button.AutomaticSize = Enum.AutomaticSize.X
		button.Size = UDim2.fromOffset(0, CHIP_HEIGHT)
		button.BackgroundColor3 = if chip.selected then CHIP_ON else CHIP
		button.Font = Enum.Font.GothamBold
		button.TextSize = 13
		button.TextColor3 = TEXT
		button.Text = chip.text
		button.AutoButtonColor = not chip.selected
		button.Parent = strip
		corner(button, 6)
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 10)
		pad.PaddingRight = UDim.new(0, 10)
		pad.Parent = button
		-- A swatch of the item's colour, so a "Fern Tint" shows what it is.
		local colour = Cosmetics.colour(Cosmetics.item(chip.id))
		if colour then
			local swatch = Instance.new("Frame")
			swatch.AnchorPoint = Vector2.new(0, 0.5)
			swatch.Position = UDim2.new(0, -6, 0.5, 0)
			swatch.Size = UDim2.fromOffset(4, CHIP_HEIGHT - 12)
			swatch.BackgroundColor3 = colour
			swatch.BorderSizePixel = 0
			swatch.Parent = button
		end
		if not chip.selected then
			button.Activated:Connect(function()
				pick(row.slot, chip.id)
			end)
		end
	end
end

local function addBoardRow(order: number, row: LevelBoard.Row)
	local other = Players:GetPlayerByUserId(row.userId) -- cosmetics are known for players here only
	local function worn(slot: string): Cosmetics.Item?
		return if other
			then Cosmetics.worn(function(name)
				return other:GetAttribute(name)
			end, slot)
			else nil
	end
	local titleItem = worn("title")
	local line = ProfileScreen.boardLine(row, if titleItem then titleItem.name else nil)
	local frame = Instance.new("Frame")
	frame.LayoutOrder = order
	frame.Size = UDim2.new(1, -8, 0, ProfileScreen.BOARD_ROW)
	frame.BackgroundColor3 = Cosmetics.colour(worn("banner")) or (if line.self then SELF_ROW else BG_LIGHT)
	frame.BorderSizePixel = 0
	frame.Parent = list
	corner(frame, 6)
	if line.self then
		local stroke = Instance.new("UIStroke")
		stroke.Color = AMBER
		stroke.Thickness = 1.5
		stroke.Parent = frame
	end
	local rank = label(frame, line.rank, 14, Enum.Font.GothamBold, TEXT)
	rank.Position = UDim2.fromOffset(8, 0)
	rank.Size = UDim2.new(0, 40, 1, 0)
	local badge = Instance.new("TextLabel")
	badge.AnchorPoint = Vector2.new(0, 0.5)
	badge.Position = UDim2.new(0, 50, 0.5, 0)
	badge.Size = UDim2.fromOffset(46, 22)
	badge.BackgroundColor3 = BAR_BACK
	badge.Font = Enum.Font.GothamBold
	badge.TextSize = 13
	badge.TextColor3 = TEXT
	badge.Text = tostring(line.level)
	badge.Parent = frame
	corner(badge, 11)
	local frameStroke = Instance.new("UIStroke")
	frameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	frameStroke.Color = BAND_COLOURS[line.band] or BAND_COLOURS[1]
	frameStroke.Thickness = 2
	frameStroke.Parent = badge
	local name = label(frame, line.name, 14, Enum.Font.GothamBold, Cosmetics.colour(worn("nameColour")) or TEXT)
	name.Position = UDim2.fromOffset(104, 0)
	name.Size = UDim2.new(0.55, -104, 1, 0)
	local title = label(frame, line.title, 12, Enum.Font.Gotham, TEXT_DIM)
	title.AnchorPoint = Vector2.new(1, 0)
	title.Position = UDim2.new(1, -8, 0, 0)
	title.Size = UDim2.new(0.45, -8, 1, 0)
	title.TextXAlignment = Enum.TextXAlignment.Right
end

local function renderBoard(): number
	local current = boardView
	local order = 0
	local function next(): number
		order += 1
		return order
	end
	if not current then
		addLine(next(), LevelBoard.LOADING, 14, Enum.Font.Gotham, TEXT_DIM, ProfileScreen.SECTION)
		return ProfileScreen.boardContent(0, false)
	end
	addLine(next(), current.title, 16, Enum.Font.GothamBold, TEXT, ProfileScreen.SECTION)
	if current.note then
		local note = label(list, current.note, 13, Enum.Font.Gotham, TEXT_DIM)
		note.LayoutOrder = next()
		note.Size = UDim2.new(1, -8, 0, ProfileScreen.NOTE)
		note.TextWrapped = true
		note.TextTruncate = Enum.TextTruncate.None
	end
	for _, row in current.rows do
		addBoardRow(next(), row)
	end
	return ProfileScreen.boardContent(#current.rows, current.note ~= nil)
end

render = function()
	if not gui.Enabled then
		return
	end
	profileTab.BackgroundColor3 = if tab == "profile" then CHIP_ON else CHIP
	boardTab.BackgroundColor3 = if tab == "board" then CHIP_ON else CHIP
	local xp = player:GetAttribute("PlayerXp")
	xp = if type(xp) == "number" then xp else 0
	levelLabel.Text = ProfileScreen.levelLine(xp)
	local line, fraction = ProfileScreen.xpLine(xp)
	xpLabel.Text = line
	barFill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)

	local position = list.CanvasPosition
	clear(list)
	if tab == "board" then
		listContent = renderBoard()
		list.CanvasSize = UDim2.fromOffset(0, listContent)
		list.CanvasPosition = position
		fit()
		return
	end
	local order = 0
	local function next(): number
		order += 1
		return order
	end
	addLine(next(), ProfileScreen.NEXT, 16, Enum.Font.GothamBold, TEXT, ProfileScreen.SECTION)
	local rewards = ProfileScreen.upcoming(xp)
	for _, reward in rewards do
		addLine(next(), reward, 13, Enum.Font.Gotham, TEXT_DIM, ProfileScreen.REWARD)
	end
	addLine(next(), ProfileScreen.WEAR, 16, Enum.Font.GothamBold, TEXT, ProfileScreen.SECTION)
	local rows = ProfileScreen.slotRows(xp, equipped())
	for _, row in rows do
		addSlot(next(), row)
	end
	listContent = ProfileScreen.listContent(#rewards, #rows)
	if player:GetAttribute("SaveStatus") == "offline" then
		-- The same words as Unlocks & Mastery and the Hunt Board.
		addLine(next(), "Progress isn't saving right now.", 13, Enum.Font.Gotham, TEXT_DIM, 36)
		listContent += 36 + ProfileScreen.GAP
	end
	list.CanvasSize = UDim2.fromOffset(0, listContent)
	list.CanvasPosition = position -- a pick doesn't jump the list back to the top
	fit()
end

local function setShown(show: boolean)
	if show == gui.Enabled then
		return
	end
	gui.Enabled = show
	if show then
		tab = "profile" -- opens on the profile, every time
		list.CanvasPosition = Vector2.zero
		say("")
		render()
	end
end

local function showTab(which: "profile" | "board")
	if tab == which then
		return
	end
	tab = which
	list.CanvasPosition = Vector2.zero
	render()
	if which == "board" then
		task.spawn(askBoard)
	end
end
profileTab.Activated:Connect(function()
	showTab("profile")
end)
boardTab.Activated:Connect(function()
	showTab("board")
end)

local function apply()
	setShown(shown())
end

closeButton.Activated:Connect(function()
	setShown(false) -- at once, whatever else happens
	player:SetAttribute("OpenPanel", "closed") -- Shop.client owns the panel mode
end)

player:GetAttributeChangedSignal("ProfileOpen"):Connect(apply)
ReplicatedStorage:GetAttributeChangedSignal("State"):Connect(apply)
player.AttributeChanged:Connect(function(name)
	if name == "PlayerXp" or name == "SaveStatus" or string.sub(name, 1, 6) == "Equip_" then
		render()
	end
end)

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
-- The home screen rescales with the window, moving its Hunt Board row: follow it.
task.spawn(function()
	local home = playerGui:WaitForChild("StormSplitHome")
	local row = home:FindFirstChild(HomeLayout.HUNT_ROW, true)
	if row and row:IsA("GuiObject") then
		row:GetPropertyChangedSignal("AbsolutePosition"):Connect(fit)
		fit()
	end
end)

-- An open Leaderboard tab asks again now and then (the server answers from its cache).
task.spawn(function()
	while true do
		task.wait(1)
		if gui.Enabled and tab == "board" and os.clock() - boardAskedAt >= BOARD_ASK_SECONDS then
			task.spawn(askBoard)
		end
	end
end)

gui.Parent = playerGui
apply()
