--[[
	The Profile screen (PLAN round 4 T57, DECISIONS #118-#121): your player level, the XP
	bar, the next rewards, and what you wear — a row per slot (the title and one cosmetic
	per kind) with every unlocked item to pick from.

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
local ProfileScreen = require(Shared:WaitForChild("ProfileScreen"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local progressRequest = remotes:WaitForChild("ProgressRequest") :: RemoteFunction

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

-- The level block: "Player level 12", the bar, "340 / 1,050 XP to level 13".
local levelBlock = section(2, ProfileScreen.LEVEL)
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
list.LayoutOrder = 3
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

local message = label(section(4, ProfileScreen.MESSAGE), "", 14, Enum.Font.Gotham, TEXT_DIM)
message.Size = UDim2.fromScale(1, 1)

------------------------------------------------------------------ state

local listContent = 0
local busy = false

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

render = function()
	if not gui.Enabled then
		return
	end
	local xp = player:GetAttribute("PlayerXp")
	xp = if type(xp) == "number" then xp else 0
	levelLabel.Text = ProfileScreen.levelLine(xp)
	local line, fraction = ProfileScreen.xpLine(xp)
	xpLabel.Text = line
	barFill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)

	local position = list.CanvasPosition
	clear(list)
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
		list.CanvasPosition = Vector2.zero
		say("")
		render()
	end
end

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

gui.Parent = playerGui
apply()
