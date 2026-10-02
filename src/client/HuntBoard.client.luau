--[[
	The Hunt Board screen (DECISIONS #63-#70, #76): the Daily Haul calendar and the
	daily and weekly Bounties, on the home screen.

	Open and close: G, the home screen's Hunt Board button, or the X. Shop.client owns
	which panel is open (its mode "huntBoard", so the Hunt Board and its panels never
	overlap) and Shared/PanelRules closes it on every match-state change; this script
	shows the board while the "HuntBoardOpen" attribute is set and the state is Lobby.

	No pop-up may trap a player (DIRECTION):
	  - Shared/HuntBoard.layout fits the board between the top bar and the home
	    screen's Play row on any window: the bounty list scrolls first, then the whole
	    board scales down. The header and its X are outside the scrolling list.
	  - Nothing here dims or covers the rest of the screen, and Play stays in reach.
	  - The X is Modal, so the mouse is free while the board is open.
	  - A board that can't load says why and still closes.

	Everything shown comes from the server ("getRewards" on ProgressRequest), asked for
	when the board opens and whenever the player's RewardsVersion changes. Claim and Swap
	are requests; the server decides and the board is redrawn from its answer. What to
	draw (text, button states, sizes) is Shared/HuntBoard.
]]

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DinoLook = require(Shared:WaitForChild("DinoLook"))
local HuntBoard = require(Shared:WaitForChild("HuntBoard"))
local Theme = require(Shared:WaitForChild("Theme"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local progressRequest = remotes:WaitForChild("ProgressRequest") :: RemoteFunction

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Visuals only.
local WOOD = Color3.fromRGB(70, 50, 35)
local WOOD_LIGHT = Color3.fromRGB(96, 71, 50)
local RIM = Color3.fromRGB(125, 95, 65)
local AMBER = Color3.fromRGB(245, 175, 60)
local PAPER = Color3.fromRGB(235, 225, 200)
local INK = Color3.fromRGB(55, 40, 30)
local INK_DIM = Color3.fromRGB(110, 95, 80)
local RED_INK = Color3.fromRGB(185, 45, 40)
local TACK = Color3.fromRGB(150, 45, 40)
local TEXT = Color3.fromRGB(240, 230, 210)
local TEXT_DIM = Color3.fromRGB(185, 165, 140)
local GREY = Color3.fromRGB(150, 145, 140)
local BAD = Color3.fromRGB(240, 130, 110)
local TOP_GAP = 8 -- px under the top bar
local BOTTOM_GAP = 8 -- px above the home screen's Play row
local RETRY_SECONDS = 5 -- how often an open board that failed to load asks again
local FLOAT_SECONDS = 1.2 -- the "+15 Amber" that drifts up from a claim

------------------------------------------------------------------ layout

local gui = Instance.new("ScreenGui")
gui.Name = "DinoHuntersHuntBoard"
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

-- The board: dark wood with a lighter rim. Only as big as it needs to be; nothing
-- else on the screen is covered or dimmed.
local board = Instance.new("Frame")
board.Name = "Board"
board.AnchorPoint = Vector2.new(0.5, 0)
board.BackgroundColor3 = WOOD
board.BorderSizePixel = 0
board.Active = true -- clicks on the board don't fall through to the cards behind it
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
	padding.PaddingTop = UDim.new(0, HuntBoard.PAD)
	padding.PaddingBottom = UDim.new(0, HuntBoard.PAD)
	padding.PaddingLeft = UDim.new(0, HuntBoard.PAD)
	padding.PaddingRight = UDim.new(0, HuntBoard.PAD)
	padding.Parent = content
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, HuntBoard.GAP)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = content
end

-- "+15 Amber" floats are drawn here, over the board, so a redraw doesn't cut them off.
local floats = Instance.new("Frame")
floats.Name = "Floats"
floats.Size = UDim2.fromScale(1, 1)
floats.BackgroundTransparency = 1
floats.ZIndex = 5
floats.Parent = board

local function section(order: number, height: number): Frame
	local frame = Instance.new("Frame")
	frame.LayoutOrder = order
	frame.Size = UDim2.new(1, 0, 0, height)
	frame.BackgroundTransparency = 1
	frame.Parent = content
	return frame
end

-- Header bar: the title and the X. Never inside the scrolling list.
local header = section(1, HuntBoard.HEADER)
header.Name = "Header"
local title = label(header, HuntBoard.TITLE, 24, Enum.Font.GothamBlack, AMBER)
title.Size = UDim2.new(1, -(HuntBoard.HEADER + 8), 1, 0)

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.fromScale(1, 0)
closeButton.Size = UDim2.fromOffset(HuntBoard.HEADER, HuntBoard.HEADER)
closeButton.BackgroundColor3 = WOOD_LIGHT
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 18
closeButton.TextColor3 = TEXT
closeButton.Text = "X"
closeButton.Modal = true -- the mouse is free while the board is showing
closeButton.Parent = header
corner(closeButton, 6)

local resetLabel = label(section(2, HuntBoard.LINE), "", 14, Enum.Font.Gotham, TEXT_DIM)
resetLabel.Size = UDim2.fromScale(1, 1)

local haulTitle = label(section(3, HuntBoard.SECTION), Theme.DailyHaul, 16, Enum.Font.GothamBold, TEXT)
haulTitle.Size = UDim2.fromScale(1, 1)

local strip = section(4, HuntBoard.TILE)
strip.Name = "Haul"

local haulNote = label(section(5, HuntBoard.LINE), HuntBoard.haulNote(), 13, Enum.Font.Gotham, TEXT_DIM)
haulNote.Size = UDim2.fromScale(1, 1)

-- The only part that scrolls.
local list = Instance.new("ScrollingFrame")
list.Name = "Bounties"
list.LayoutOrder = 6
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
	layout.Padding = UDim.new(0, HuntBoard.GAP)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
end

local message = label(section(7, HuntBoard.MESSAGE), "", 14, Enum.Font.Gotham, TEXT_DIM)
message.Size = UDim2.fromScale(1, 1)

------------------------------------------------------------------ state

type View = {
	daily: { HuntBoard.Entry },
	weekly: { HuntBoard.Entry },
	haulDay: number,
	haulClaimed: boolean,
	dailySwapsLeft: number,
	weeklySwapsLeft: number,
	secondsToDaily: number,
	secondsToWeekly: number,
	lastResetPayout: number,
}

local view: View? = nil -- the server's last answer
local viewAt = 0 -- os.clock() when it arrived
local problem: string? = nil -- why there's no board to show
local inFlight: string? = nil -- a bounty id or HuntBoard.HAUL while a claim or swap is out
local fetching = false
local fetchAgain = false
local lastAsked = 0
local payout = 0 -- the reset payout, kept on show until the board closes
local said: string? = nil -- the last request's answer, for the message line
local saidColor = TEXT_DIM
local listContent = 0 -- the bounty list's full height
local weeklyLabel: TextLabel? = nil

local function shown(): boolean
	return HuntBoard.shown(player:GetAttribute("HuntBoardOpen") == true, ReplicatedStorage:GetAttribute("State"))
end

-- The band the board may use: under the top bar, above the home screen's Play row.
local function band(): (number, number)
	local top = GuiService:GetGuiInset().Y + TOP_GAP
	local bottom = gui.AbsoluteSize.Y - HuntBoard.EDGE
	local home = playerGui:FindFirstChild("StormSplitHome")
	local actions = home and home:FindFirstChild("Actions", true)
	if actions and actions:IsA("GuiObject") and actions.AbsoluteSize.Y > 0 then
		local rowTop = actions.AbsolutePosition.Y - gui.AbsolutePosition.Y
		if rowTop > top then
			bottom = math.min(bottom, rowTop - BOTTOM_GAP)
		end
	end
	return top, bottom
end

local renderHaul: (width: number) -> ()

local lastStripWidth = -1
local function fit()
	if not gui.Enabled then
		return
	end
	local top, bottom = band()
	local layout = HuntBoard.layout(gui.AbsoluteSize.X, top, bottom, listContent)
	boardScale.Scale = layout.scale
	board.Position = UDim2.new(0.5, 0, 0, top)
	board.Size = UDim2.fromOffset(layout.width, layout.height)
	list.Size = UDim2.new(1, 0, 0, layout.listHeight)
	strip.Size = UDim2.new(1, 0, 0, HuntBoard.stripHeight(layout.wrap))
	local stripWidth = layout.width - HuntBoard.PAD * 2
	if stripWidth ~= lastStripWidth then
		lastStripWidth = stripWidth
		renderHaul(stripWidth)
	end
end

local function updateLines()
	local current = view
	local elapsed = os.clock() - viewAt
	resetLabel.Text = if current then HuntBoard.resetLine(HuntBoard.remaining(current.secondsToDaily, elapsed)) else ""
	if weeklyLabel then
		weeklyLabel.Text = if current then HuntBoard.weeklyLine(HuntBoard.remaining(current.secondsToWeekly, elapsed)) else ""
	end
	if said then
		message.Text, message.TextColor3 = said, saidColor
	else
		message.Text, message.TextColor3 = HuntBoard.payoutLine(payout) or "", TEXT_DIM
	end
end

local function say(text: string?, color: Color3?)
	said, saidColor = text, color or TEXT_DIM
	updateLines()
end

-- Where a button is on the board (bottom centre), in the board's own pixels.
local function spotOf(from: GuiObject): Vector2
	local scale = math.max(boardScale.Scale, 0.01)
	local at = (from.AbsolutePosition - board.AbsolutePosition) / scale
	local size = from.AbsoluteSize / scale
	return Vector2.new(at.X + size.X / 2, at.Y + size.Y)
end

-- "+15 Amber" drifting up from where a claim was pressed. Not a pop-up: it's a line
-- of text that fades in about a second.
local function float(spot: Vector2, text: string)
	local l = label(floats, text, 16, Enum.Font.GothamBlack, AMBER)
	l.TextXAlignment = Enum.TextXAlignment.Center
	l.TextTruncate = Enum.TextTruncate.None
	l.AnchorPoint = Vector2.new(0.5, 1)
	l.Size = UDim2.fromOffset(160, 20)
	l.Position = UDim2.fromOffset(spot.X, spot.Y)
	l.TextStrokeColor3 = INK
	l.TextStrokeTransparency = 0.3
	l.ZIndex = 6
	local tween = TweenService:Create(l, TweenInfo.new(FLOAT_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromOffset(spot.X, spot.Y - 28),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	tween.Completed:Once(function()
		l:Destroy()
	end)
	tween:Play()
end

local render: () -> ()
local fetch: () -> ()

-- One claim or swap. Every button is disabled until the server answers.
local function act(key: string, action: string, arg: string?, from: GuiObject?)
	if inFlight or not shown() then
		return
	end
	inFlight = key
	local spot = if from then spotOf(from) else nil -- before the redraw replaces the button
	say(nil)
	render()
	local ok, success, text = pcall(function()
		return progressRequest:InvokeServer(action, arg)
	end)
	inFlight = nil
	if not ok then
		say(HuntBoard.UNREACHABLE, BAD)
	elseif success ~= true then
		say(tostring(text), BAD)
	elseif action == "swapBounty" then
		say(nil)
	elseif spot and gui.Enabled then
		float(spot, tostring(text)) -- the server's "+15 Amber"
	end
	render()
	fetch()
end

------------------------------------------------------------------ drawing

local function clear(parent: Instance)
	for _, child in parent:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- A small three-toed footprint: the stamp on a claimed Haul day.
local function footprint(parent: Instance, x: UDim, y: number)
	local stamp = Instance.new("Frame")
	stamp.Name = "Footprint"
	stamp.AnchorPoint = Vector2.new(0.5, 0)
	stamp.Position = UDim2.new(x, UDim.new(0, y))
	stamp.Size = UDim2.fromOffset(20, 20)
	stamp.BackgroundTransparency = 1
	stamp.Rotation = -12
	stamp.Parent = parent
	local function blob(px: number, py: number, w: number, h: number, turn: number)
		local part = Instance.new("Frame")
		part.AnchorPoint = Vector2.new(0.5, 0.5)
		part.Position = UDim2.fromOffset(px, py)
		part.Size = UDim2.fromOffset(w, h)
		part.Rotation = turn
		part.BackgroundColor3 = PAPER
		part.BackgroundTransparency = 0.25
		part.BorderSizePixel = 0
		part.Parent = stamp
		corner(part, 3)
	end
	blob(10, 14, 8, 8, 0) -- heel
	blob(4, 6, 4, 9, -28) -- toes
	blob(10, 4, 4, 9, 0)
	blob(16, 6, 4, 9, 28)
end

-- The small solid button on a card or tile: Claim (amber) or "…" (grey).
local function pill(parent: Instance, text: string, waiting: boolean): TextLabel
	local p = Instance.new("TextLabel")
	p.BackgroundColor3 = if waiting then GREY else AMBER
	p.BorderSizePixel = 0
	p.Font = Enum.Font.GothamBold
	p.TextSize = 13
	p.TextColor3 = INK
	p.Text = text
	p.Parent = parent
	corner(p, 5)
	return p
end

renderHaul = function(width: number)
	clear(strip)
	local current = view
	if not current then
		return
	end
	local rects = HuntBoard.tileRects(width)
	for day, tile in HuntBoard.haul(current.haulDay, current.haulClaimed, inFlight) do
		local rect = rects[day]
		local dim = tile.state == "future"

		local button = Instance.new("TextButton")
		button.Name = `Day{day}`
		button.Position = UDim2.fromOffset(math.floor(rect.x), rect.y)
		button.Size = UDim2.fromOffset(math.floor(rect.width), rect.height)
		button.BackgroundColor3 = WOOD_LIGHT
		button.BackgroundTransparency = if dim then 0.6 else 0
		button.BorderSizePixel = 0
		button.AutoButtonColor = tile.enabled
		button.Active = tile.enabled
		button.Text = ""
		button.Parent = strip
		corner(button, 6)
		if tile.today then
			local outline = Instance.new("UIStroke")
			outline.Thickness = 2
			outline.Color = AMBER
			outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			outline.Parent = button
		end

		local name = label(button, tile.label, 12, Enum.Font.GothamBold, if dim then TEXT_DIM else TEXT)
		name.TextXAlignment = Enum.TextXAlignment.Center
		name.Position = UDim2.fromOffset(0, 5)
		name.Size = UDim2.new(1, 0, 0, 14)
		name.TextTransparency = if dim then 0.3 else 0

		local amount = label(button, tile.chip, 17, Enum.Font.GothamBlack, AMBER)
		amount.TextXAlignment = Enum.TextXAlignment.Center
		amount.Position = UDim2.fromOffset(if tile.big then 8 else 0, 20)
		amount.Size = UDim2.new(1, 0, 0, 20)
		amount.TextTransparency = if dim then 0.45 elseif tile.state == "claimed" then 0.3 else 0
		if tile.big then
			-- Big Haul: a chunk of amber beside the amount.
			local chunk = Instance.new("Frame")
			chunk.AnchorPoint = Vector2.new(0.5, 0.5)
			chunk.Position = UDim2.new(0.5, -20, 0, 30)
			chunk.Size = UDim2.fromOffset(9, 9)
			chunk.Rotation = 45
			chunk.BackgroundColor3 = AMBER
			chunk.BackgroundTransparency = amount.TextTransparency
			chunk.BorderSizePixel = 0
			chunk.Parent = button
			corner(chunk, 2)
		end

		if tile.state == "claimed" then
			footprint(button, UDim.new(0.5, 0), 40)
		elseif tile.action ~= "none" then
			local p = pill(button, tile.actionText, tile.action == "wait")
			p.AnchorPoint = Vector2.new(0.5, 0)
			p.Position = UDim2.new(0.5, 0, 0, 41)
			p.Size = UDim2.new(1, -10, 0, 17)
		end
		if tile.enabled then
			button.Activated:Connect(function()
				act(HuntBoard.HAUL, "claimHaul", nil, button)
			end)
		end
	end
end

local function addCard(order: number, card: HuntBoard.Card)
	local claimed = card.state == "claimed"
	local frame = Instance.new("Frame")
	frame.Name = card.id
	frame.LayoutOrder = order
	frame.Size = UDim2.new(1, -8, 0, HuntBoard.CARD) -- clear of the scroll bar
	frame.BackgroundColor3 = PAPER
	frame.BackgroundTransparency = if claimed then 0.5 else 0
	frame.BorderSizePixel = 0
	frame.Parent = list
	corner(frame, 4)
	local fade = if claimed then 0.45 else 0

	local tack = Instance.new("Frame")
	tack.AnchorPoint = Vector2.new(0.5, 0)
	tack.Position = UDim2.new(0.5, 0, 0, 3)
	tack.Size = UDim2.fromOffset(8, 8)
	tack.BackgroundColor3 = TACK
	tack.BorderSizePixel = 0
	tack.Parent = frame
	corner(tack, 4)

	local left = 10
	if card.species then
		local dot = Instance.new("Frame") -- the dino's own colour (Shared/DinoLook)
		dot.Position = UDim2.fromOffset(10, 13)
		dot.Size = UDim2.fromOffset(10, 10)
		dot.BackgroundColor3 = DinoLook.colorOf(card.species)
		dot.BackgroundTransparency = fade
		dot.BorderSizePixel = 0
		dot.Parent = frame
		corner(dot, 5)
		left = 26
	end

	local name = label(frame, card.title, 16, Enum.Font.GothamBold, INK)
	name.Position = UDim2.fromOffset(left, 9)
	name.Size = UDim2.new(1, -(left + 70), 0, 18)
	name.TextTransparency = fade

	local chip = pill(frame, card.chip, false)
	chip.AnchorPoint = Vector2.new(1, 0)
	chip.Position = UDim2.new(1, -10, 0, 8)
	chip.Size = UDim2.fromOffset(52, 20)
	chip.BackgroundTransparency = fade
	chip.TextTransparency = fade

	local text = label(frame, card.text, 14, Enum.Font.Gotham, INK_DIM)
	text.Position = UDim2.fromOffset(10, 29)
	text.Size = UDim2.new(1, -20, 0, 18)
	text.TextTransparency = fade
	-- One line, never cut short: the longest text ("Take down 6 Triceratops (team
	-- take-downs count)") shrinks to fit a narrow board instead of ending in "…".
	text.TextScaled = true
	text.TextTruncate = Enum.TextTruncate.None
	local fitText = Instance.new("UITextSizeConstraint")
	fitText.MaxTextSize = 14
	fitText.MinTextSize = 9
	fitText.Parent = text

	-- Bottom row: bar, "12 / 40", then the button (or the stamp).
	local ACTION = 104
	local COUNT = 76
	local bar = Instance.new("Frame")
	bar.Position = UDim2.fromOffset(10, 58)
	bar.Size = UDim2.new(1, -(10 + 6 + COUNT + 6 + ACTION + 10), 0, 6)
	bar.BackgroundColor3 = INK
	bar.BackgroundTransparency = 0.8
	bar.BorderSizePixel = 0
	bar.Parent = frame
	corner(bar, 3)
	if card.fraction > 0 then
		local fill = Instance.new("Frame")
		fill.Size = UDim2.fromScale(card.fraction, 1)
		fill.BackgroundColor3 = if card.state == "progress" then INK_DIM else AMBER
		fill.BackgroundTransparency = fade
		fill.BorderSizePixel = 0
		fill.Parent = bar
		corner(fill, 3)
	end

	local count = label(frame, card.progress, 13, Enum.Font.GothamBold, INK_DIM)
	count.AnchorPoint = Vector2.new(1, 0)
	count.Position = UDim2.new(1, -(10 + ACTION + 6), 0, 52)
	count.Size = UDim2.fromOffset(COUNT, 18)
	count.TextXAlignment = Enum.TextXAlignment.Right
	count.TextTransparency = fade

	if claimed then
		local stamp = label(frame, HuntBoard.BAGGED, 15, Enum.Font.GothamBlack, RED_INK)
		stamp.AnchorPoint = Vector2.new(1, 0)
		stamp.Position = UDim2.new(1, -14, 0, 46)
		stamp.Size = UDim2.fromOffset(ACTION - 14, 22)
		stamp.TextXAlignment = Enum.TextXAlignment.Center
		stamp.Rotation = -10
		local ring = Instance.new("UIStroke")
		ring.Thickness = 2
		ring.Color = RED_INK
		ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ring.Parent = stamp
		corner(stamp, 4)
	elseif card.action ~= "none" then
		local button = Instance.new("TextButton")
		button.Name = "Action"
		button.AnchorPoint = Vector2.new(1, 0)
		button.Position = UDim2.new(1, -10, 0, 46)
		button.Size = UDim2.fromOffset(ACTION, 24)
		button.BorderSizePixel = 0
		button.Font = Enum.Font.GothamBold
		button.TextSize = 13
		button.Text = card.actionText
		button.AutoButtonColor = card.enabled
		button.Active = card.enabled
		if card.action == "swap" then
			-- A plain text button: Swap is the quiet choice, Claim the loud one.
			button.BackgroundTransparency = 1
			button.TextColor3 = if card.enabled then INK else INK_DIM
			button.TextXAlignment = Enum.TextXAlignment.Right
		else
			button.BackgroundColor3 = if card.action == "wait" then GREY elseif card.enabled then AMBER else GREY
			button.TextColor3 = INK
			corner(button, 5)
		end
		button.Parent = frame
		if card.enabled then
			local action = if card.action == "claim" then "claimBounty" else "swapBounty"
			button.Activated:Connect(function()
				act(card.id, action, card.id, button)
			end)
		end
	end
end

local function addLine(order: number, text: string, color: Color3, height: number): TextLabel
	local l = label(list, text, 14, Enum.Font.Gotham, color)
	l.LayoutOrder = order
	l.Size = UDim2.new(1, -8, 0, height)
	l.TextWrapped = true
	l.TextTruncate = Enum.TextTruncate.None
	l.TextYAlignment = Enum.TextYAlignment.Top
	return l
end

local function addSection(order: number, text: string): TextLabel
	local row = Instance.new("Frame")
	row.LayoutOrder = order
	row.Size = UDim2.new(1, -8, 0, HuntBoard.SECTION)
	row.BackgroundTransparency = 1
	row.Parent = list
	local name = label(row, text, 16, Enum.Font.GothamBold, TEXT)
	name.Size = UDim2.fromScale(1, 1)
	local side = label(row, "", 13, Enum.Font.Gotham, TEXT_DIM)
	side.Size = UDim2.fromScale(1, 1)
	side.TextXAlignment = Enum.TextXAlignment.Right
	return side
end

render = function()
	if not gui.Enabled then
		return
	end
	clear(list)
	weeklyLabel = nil
	local heights: { number } = {}
	local current = view
	if current then
		local order = 1
		addSection(order, Theme.DailyBounties)
		table.insert(heights, HuntBoard.SECTION)
		for _, card in HuntBoard.cards(current.daily, current.dailySwapsLeft, inFlight) do
			order += 1
			addCard(order, card)
			table.insert(heights, HuntBoard.CARD)
		end
		order += 1
		weeklyLabel = addSection(order, Theme.WeeklyBounties)
		table.insert(heights, HuntBoard.SECTION)
		for _, card in HuntBoard.cards(current.weekly, current.weeklySwapsLeft, inFlight) do
			order += 1
			addCard(order, card)
			table.insert(heights, HuntBoard.CARD)
		end
		if player:GetAttribute("SaveStatus") == "offline" then
			-- The same words as Unlocks & Mastery (Shop.client).
			addLine(order + 1, "Progress isn't saving right now.", TEXT_DIM, 36)
			table.insert(heights, 36)
		end
	else
		-- No board to show: say why. The header, the X and Play all still work.
		addLine(1, problem or HuntBoard.LOADING, if problem then BAD else TEXT_DIM, 36)
		table.insert(heights, 36)
	end
	listContent = 0
	for i, height in heights do
		listContent += height + (if i > 1 then HuntBoard.GAP else 0)
	end
	list.CanvasSize = UDim2.fromOffset(0, listContent)
	-- Blank, not hidden, without a board: the sections keep their places.
	haulTitle.Text = if current then Theme.DailyHaul else ""
	haulNote.Text = if current then HuntBoard.haulNote() else ""
	lastStripWidth = -1 -- redraw the Haul tiles too
	fit()
	updateLines()
end

------------------------------------------------------------------ data

-- Ask the server for the board. Only while it's on screen: the dot on the home
-- button follows the RewardsClaimable attribute and needs no request.
fetch = function()
	if not shown() then
		return
	end
	if fetching then
		fetchAgain = true
		return
	end
	fetching = true
	lastAsked = os.clock()
	local ok, success, result = pcall(function()
		return progressRequest:InvokeServer("getRewards", true)
	end)
	fetching = false
	if ok and success == true and type(result) == "table" then
		view = result :: View
		viewAt = os.clock()
		problem = nil
		if type(result.lastResetPayout) == "number" then
			payout = math.max(payout, result.lastResetPayout)
		end
	else
		-- Keep the last good board if there is one; otherwise say why there's none.
		problem = if ok and type(result) == "string" then result else HuntBoard.UNREACHABLE
		if view then
			say(problem, BAD)
		end
	end
	render()
	if fetchAgain then
		fetchAgain = false
		fetch()
	end
end

local function setShown(show: boolean)
	if show == gui.Enabled then
		return
	end
	gui.Enabled = show
	if show then
		list.CanvasPosition = Vector2.zero
		say(nil)
		render()
		task.spawn(fetch)
	else
		payout = 0 -- shown once
		said = nil
		clear(floats)
	end
end

local function apply()
	setShown(shown())
end

closeButton.Activated:Connect(function()
	setShown(false) -- at once, whatever else happens
	player:SetAttribute("OpenPanel", "closed") -- Shop.client owns the panel mode
end)

player:GetAttributeChangedSignal("HuntBoardOpen"):Connect(apply)
ReplicatedStorage:GetAttributeChangedSignal("State"):Connect(apply)
player:GetAttributeChangedSignal("RewardsVersion"):Connect(function()
	if gui.Enabled and not inFlight then
		task.spawn(fetch) -- a claim or swap asks again itself, when it's answered
	end
end)
player:GetAttributeChangedSignal("SaveStatus"):Connect(function()
	render()
end)

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
-- The home screen rescales with the window, moving its Play row: follow it.
task.spawn(function()
	local home = playerGui:WaitForChild("StormSplitHome")
	local actions = home:FindFirstChild("Actions", true) -- built before the home screen is parented
	if actions and actions:IsA("GuiObject") then
		actions:GetPropertyChangedSignal("AbsolutePosition"):Connect(fit)
		fit()
	end
end)

-- Count the timers down, and ask again when one runs out (the server rolls the new
-- bounties) or while a board that failed to load is still open.
task.spawn(function()
	while true do
		task.wait(1)
		if gui.Enabled then
			updateLines()
			local current = view
			local elapsed = os.clock() - viewAt
			local due = current == nil
				or HuntBoard.remaining(current.secondsToDaily, elapsed) <= 0
				or HuntBoard.remaining(current.secondsToWeekly, elapsed) <= 0
			if due and not fetching and not inFlight and os.clock() - lastAsked >= RETRY_SECONDS then
				task.spawn(fetch)
			end
		end
	end
end)

gui.Parent = playerGui
apply()
