--[[
	The Hatchery Hut (PLAN 10d T140/T141; strings DINO_REVIEW Round 21). In the Hunters'
	Outpost, standing at the Hatchery Hut shows "Hatchery Hut: press E" (also a button); E
	opens the hut. Everything is a request; the server owns the numbers and rolls the
	rarity (Server/Pets, Server/Progression; rules in Shared/Pets, run here on the state
	the server sends, so timers and prices read the same as on the server).

	  - Eggs: each egg with its line, hatch time, odds ("Hatch odds: Common 55 % · …") and
	    a Buy button (or "Not for sale yet" while the sheet has no price).
	  - Incubator: "Hatching… 4:32 left" / "Ready to hatch!" + Hatch!, and "Warm it up —
	    12.5K Amber (finishes now)" once the sheet has a warm price.
	  - Your pets (n/60): one row per pet + rarity with its effect x, Take along / Taking
	    along, Show in your Hatchling Pen, and Fuse ("Fuse — 3 Rare Honkers → 1 Epic Honker").
	  - A pet that ran back to camp (its hunter fell) says so (the "PetDown" event).
	No-trap rule: the hut always has its Close button (which also frees the mouse), it
	closes when you leave camp, and the prompt only shows at the hut.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Pets = require(Shared:WaitForChild("Pets"))
local Outpost = require(Shared:WaitForChild("Outpost"))
local Theme = require(Shared:WaitForChild("Theme"))
local SafeArea = require(Shared:WaitForChild("SafeArea"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local request = remotes:WaitForChild("Pets") :: RemoteFunction
local downEvent = remotes:WaitForChild("PetDown") :: RemoteEvent

local player = Players.LocalPlayer

-- Visuals only.
local PANEL = Color3.fromRGB(28, 24, 40)
local CARD = Color3.fromRGB(44, 38, 60)
local TEXT = Color3.fromRGB(240, 236, 250)
local TEXT_DIM = Color3.fromRGB(160, 155, 175)
local AMBER = Color3.fromRGB(245, 175, 60)
local GREEN = Color3.fromRGB(70, 180, 110)
local GREY = Color3.fromRGB(80, 76, 96)
local RARITY_COLOURS = { -- DINO_REVIEW Round 21: grey / green / blue / purple / gold / red
	COMMON = Color3.fromRGB(170, 170, 170),
	UNCOMMON = Color3.fromRGB(90, 200, 100),
	RARE = Color3.fromRGB(80, 150, 255),
	EPIC = Color3.fromRGB(180, 100, 240),
	LEGENDARY = Color3.fromRGB(250, 200, 60),
	MYTHIC = Color3.fromRGB(240, 70, 70),
}
local WIDTH = 460

local gui = Instance.new("ScreenGui")
gui.Name = "HatcheryHut"
gui.ResetOnSpawn = false
gui.DisplayOrder = 7

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function textLabel(parent: Instance, size: number, font: Enum.Font, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = font
	label.TextSize = size
	label.TextColor3 = color
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Parent = parent
	return label
end

local function button(parent: Instance, text: string, color: Color3, width: number): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(width, 26)
	b.BackgroundColor3 = color
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.TextColor3 = if color == AMBER or color == GREEN then PANEL else TEXT
	b.Text = text
	b.AutoButtonColor = true
	b.Parent = parent
	corner(b, 6)
	return b
end

-- Prompt at the hut, bottom centre (a button too, for touch).
local prompt = button(gui, "Hatchery Hut: press E", PANEL, 300)
prompt.AnchorPoint = Vector2.new(0.5, 1)
prompt.Position = UDim2.new(0.5, 0, 1, -150)
prompt.Size = UDim2.fromOffset(300, 34)
prompt.TextSize = 18
prompt.TextColor3 = TEXT
prompt.BackgroundTransparency = 0.25
prompt.Visible = false

-- Toast, top centre.
local toast = textLabel(gui, 20, Enum.Font.GothamBold, AMBER)
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, 110)
toast.Size = UDim2.fromOffset(560, 32)
toast.TextXAlignment = Enum.TextXAlignment.Center
toast.Visible = false
local toastToken = 0
local function say(text: string)
	toastToken += 1
	local mine = toastToken
	toast.Text = text
	toast.Visible = true
	task.delay(4, function()
		if toastToken == mine then
			toast.Visible = false
		end
	end)
end

-- The hut panel, top centre: its top (and the X) under the CoreGui band that eats clicks
-- (Run 13 F13), its bottom 16 px above the window's.
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, SafeArea.localTop(GuiService:GetGuiInset().Y))
panel.Size = UDim2.new(0, WIDTH, 1, -(SafeArea.localTop(GuiService:GetGuiInset().Y) + 16))
panel.BackgroundColor3 = PANEL
panel.BackgroundTransparency = 0.05
panel.Visible = false
panel.Parent = gui
corner(panel, 12)
local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MaxSize = Vector2.new(WIDTH, 640)
sizeLimit.Parent = panel

local header = textLabel(panel, 22, Enum.Font.GothamBold, AMBER)
header.Position = UDim2.fromOffset(14, 8)
header.Size = UDim2.new(1, -120, 0, 30)
header.Text = "Hatchery Hut"

local close = button(panel, "X Close", GREY, 84)
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -10, 0, 10)
close.Modal = true -- frees the mouse while the hut is open

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(10, 46)
list.Size = UDim2.new(1, -20, 1, -56)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local view: { state: Pets.State, now: number, at: number }? = nil
local open = false
local order = 0

local function clear()
	for _, child in list:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	order = 0
end

local function card(height: number): Frame
	order += 1
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, -8, 0, height)
	f.BackgroundColor3 = CARD
	f.LayoutOrder = order
	f.Parent = list
	corner(f, 8)
	return f
end

local function heading(text: string)
	order += 1
	local h = textLabel(list, 16, Enum.Font.GothamBold, TEXT)
	h.Size = UDim2.new(1, -8, 0, 22)
	h.Text = text
	h.LayoutOrder = order
end

local function now(): number
	local v = view
	return if v then v.now + (os.clock() - v.at) else os.time()
end

local load: () -> ()

local function act(action: string, a: any?, b: any?)
	local ok, message = request:InvokeServer(action, a, b)
	say(tostring(message))
	if ok then
		load()
	end
end

local function render()
	clear()
	local v = view
	if not v then
		heading("Your pets couldn't be loaded right now")
		return
	end
	local state = v.state
	local t = now()

	heading("Eggs")
	for _, eggKey in (Config :: any).EggOrder do
		local row = (Config :: any).Eggs[eggKey]
		local c = card(92)
		local name = textLabel(c, 15, Enum.Font.GothamBold, AMBER)
		name.Position = UDim2.fromOffset(10, 4)
		name.Size = UDim2.new(1, -150, 0, 20)
		local minutes = row.hatchMinutes
		name.Text = `{row.display}  ·  hatches in {if minutes >= 60 then `{minutes / 60} h` else `{minutes} min`}`
		local line = textLabel(c, 12, Enum.Font.Gotham, TEXT)
		line.Position = UDim2.fromOffset(10, 24)
		line.Size = UDim2.new(1, -150, 0, 18)
		line.Text = row.line
		local odds = textLabel(c, 11, Enum.Font.Gotham, TEXT_DIM)
		odds.Position = UDim2.fromOffset(10, 44)
		odds.Size = UDim2.new(1, -20, 0, 42)
		odds.Text = Pets.oddsLine(eggKey)
		local price = Pets.price(eggKey)
		local buy = button(c, if price then `Buy — {Theme.amberPrice(price)} {Theme.Currency}` else "Not for sale yet", if price then AMBER else GREY, 130)
		buy.AnchorPoint = Vector2.new(1, 0)
		buy.Position = UDim2.new(1, -10, 0, 8)
		if price then
			buy.Activated:Connect(function()
				act("buy", eggKey)
			end)
		end
	end

	heading(`Incubator ({#state.eggs}/{Pets.incubators()})`)
	if #state.eggs == 0 then
		local c = card(30)
		local empty = textLabel(c, 13, Enum.Font.Gotham, TEXT_DIM)
		empty.Position = UDim2.fromOffset(10, 4)
		empty.Size = UDim2.new(1, -20, 0, 22)
		empty.Text = "Empty — buy an egg to warm it up."
	end
	for slot, e in state.eggs do
		local c = card(64)
		local egg = (Config :: any).Eggs[e.egg]
		local name = textLabel(c, 15, Enum.Font.GothamBold, AMBER)
		name.Position = UDim2.fromOffset(10, 4)
		name.Size = UDim2.new(1, -20, 0, 20)
		name.Text = if egg then egg.display else e.egg
		local timer = textLabel(c, 13, Enum.Font.Gotham, TEXT)
		timer.Name = "Timer"
		timer.Position = UDim2.fromOffset(10, 26)
		timer.Size = UDim2.new(1, -20, 0, 18)
		timer.Text = Pets.timerLine(state, slot, t)
		timer:SetAttribute("Slot", slot)
		local left = Pets.remaining(state, slot, t) or 0
		if left <= 0 then
			local hatch = button(c, "Hatch!", GREEN, 110)
			hatch.AnchorPoint = Vector2.new(1, 0)
			hatch.Position = UDim2.new(1, -10, 0, 8)
			hatch.Activated:Connect(function()
				act("hatch", slot)
			end)
		else
			local warm = Pets.warmPrice(state, slot, t)
			if warm then
				local w = button(c, `Warm it up — {Theme.amberPrice(warm)} {Theme.Currency} (finishes now)`, AMBER, 260)
				w.AnchorPoint = Vector2.new(1, 1)
				w.Position = UDim2.new(1, -10, 1, -6)
				w.Activated:Connect(function()
					act("warm", slot)
				end)
			end
		end
	end

	heading(`Your pets ({#state.pets}/{Pets.cap()})`)
	if Pets.full(state) then
		local c = card(26)
		local full = textLabel(c, 13, Enum.Font.GothamBold, AMBER)
		full.Position = UDim2.fromOffset(10, 3)
		full.Size = UDim2.new(1, -20, 0, 20)
		full.Text = Pets.fullLine(state)
	end
	for _, g in Pets.groups(state) do
		local c = card(96)
		local petRow = (Config :: any).Pets[g.kind]
		local example = { kind = g.kind, rarity = g.rarity }
		local name = textLabel(c, 15, Enum.Font.GothamBold, RARITY_COLOURS[g.rarity] or TEXT)
		name.Position = UDim2.fromOffset(10, 4)
		name.Size = UDim2.new(1, -20, 0, 20)
		name.Text = `{Pets.name(example)}  ×{g.count}`
		local info = textLabel(c, 12, Enum.Font.Gotham, TEXT_DIM)
		info.Position = UDim2.fromOffset(10, 24)
		info.Size = UDim2.new(1, -20, 0, 18)
		local rarityName = string.match(Pets.name(example), "^(%S+)") or ""
		info.Text = `{rarityName} · effect ×{Pets.rarityMult(g.rarity)} — {petRow and petRow.line or ""}`
		local along = button(c, if g.along then "Taking along" else "Take along", if g.along then GREEN else GREY, 110)
		along.Position = UDim2.fromOffset(10, 62)
		along.Activated:Connect(function()
			act("along", if g.along then 0 else g.ids[1])
		end)
		local inPen = g.pen > 0
		local pen = button(c, if inPen then `In your Hatchling Pen ({g.pen})` else "Show in your Hatchling Pen", GREY, 170)
		pen.Position = UDim2.fromOffset(126, 62)
		pen.Activated:Connect(function()
			-- Adds one more of this group to the pen, or takes them all back when it's full.
			local free
			for _, id in g.ids do
				if not table.find(state.pen, id) then
					free = id
					break
				end
			end
			if free and #state.pen < Config.Tuning.HatchlingPenPets then
				act("pen", free, true)
			else
				for _, id in g.ids do
					if table.find(state.pen, id) then
						act("pen", id, false)
					end
				end
			end
		end)
		local canFuse, why = Pets.canFuse(state, g.kind, g.rarity)
		local fuse = button(c, "Fuse", if canFuse then AMBER else GREY, 60)
		fuse.Position = UDim2.fromOffset(302, 62)
		local fuseLine = textLabel(c, 11, Enum.Font.Gotham, TEXT_DIM)
		fuseLine.Position = UDim2.fromOffset(10, 42)
		fuseLine.Size = UDim2.new(1, -20, 0, 18)
		fuseLine.Text = if canFuse or not Pets.nextRarity(g.rarity) then Pets.fuseLine(g.kind, g.rarity) else why
		fuse.Activated:Connect(function()
			if canFuse then
				act("fuse", g.kind, g.rarity)
			else
				say(why)
			end
		end)
	end
	if #state.pets == 0 then
		local c = card(30)
		local none = textLabel(c, 13, Enum.Font.Gotham, TEXT_DIM)
		none.Position = UDim2.fromOffset(10, 4)
		none.Size = UDim2.new(1, -20, 0, 22)
		none.Text = "No pets yet — hatch an egg."
	end
end

load = function()
	local ok, result = request:InvokeServer("view")
	if ok and type(result) == "table" then
		local state = Pets.sanitize(result.state, result.now)
		view = { state = state, now = result.now, at = os.clock() }
	else
		view = nil
		if open then
			say(tostring(result))
		end
	end
	if open then
		render()
	end
end

local function atHut(): boolean
	if player:GetAttribute("InOutpost") ~= true then
		return false
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and root:IsA("BasePart") and Outpost.atHut(root.Position)
end

local function setOpen(on: boolean)
	open = on
	panel.Visible = on
	if on then
		load()
	end
end

close.Activated:Connect(function()
	setOpen(false)
end)
prompt.Activated:Connect(function()
	setOpen(true)
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.KeyCode ~= Enum.KeyCode.E or not atHut() then
		return
	end
	setOpen(not open)
end)

downEvent.OnClientEvent:Connect(function(text)
	say(tostring(text))
end)

player.AttributeChanged:Connect(function(name)
	if name == "PetsVersion" and open then
		load()
	elseif name == "InOutpost" and player:GetAttribute("InOutpost") ~= true and open then
		setOpen(false) -- the hut is a camp thing: never left open in a match
	end
end)

task.spawn(function()
	while true do
		task.wait(0.5)
		prompt.Visible = atHut() and not open
		local v = view
		if open and v then
			-- Timers tick on the client from the server clock it was sent; a finished
			-- one redraws so its Hatch! button shows.
			for _, child in list:GetDescendants() do
				if child:IsA("TextLabel") and child.Name == "Timer" then
					local slot = child:GetAttribute("Slot") :: number
					local before = child.Text
					child.Text = Pets.timerLine(v.state, slot, now())
					if child.Text ~= before and (Pets.remaining(v.state, slot, now()) or 0) <= 0 then
						render()
						break
					end
				end
			end
		end
	end
end)

gui.Parent = player:WaitForChild("PlayerGui")
