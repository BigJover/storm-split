--[[
	The shop counter in the Hunters' Outpost (PLAN 10e T142; names DINO_REVIEW Round 22).
	Standing at the counter shows "Shop: press E" (also a button); E opens it. Everything is
	a request; the server owns prices and what you own (Server/Progression, Shared/Skins).

	  Hunter skins   per hunter: each skin with its price (or "yours" / "not for sale yet"),
	                 Buy (Amber) and Wear / Take off
	  Weapon skins   the same, per gun
	  Tower sets     each tower you own: which set it wears (a button cycles your sets)
	  Campsite       your three Display Tower spots: which owned tower stands on each
	  Store (T143)   Amber · Passes · Hatchery · Skins: Robux items (Shared/Store). Only in a
	                 published game; otherwise every store tab says "The store opens when
	                 the game is published" and nothing can be bought. Buy asks the server,
	                 which checks and shows Roblox's own purchase prompt.

	No-trap rule: X Close (Modal: frees the mouse) and E close it, it closes when you leave
	camp, the prompt only shows at the counter, and the panel sits under the CoreGui band
	(SafeArea) with its list scrolling, so the X is always on screen and clickable.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Skins = require(Shared:WaitForChild("Skins"))
local Outpost = require(Shared:WaitForChild("Outpost"))
local Theme = require(Shared:WaitForChild("Theme"))
local SafeArea = require(Shared:WaitForChild("SafeArea"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local request = remotes:WaitForChild("ProgressRequest") :: RemoteFunction
local storeRequest = remotes:WaitForChild("StoreRequest") :: RemoteFunction
local StoreRules = require(Shared:WaitForChild("Store"))
local Training = require(Shared:WaitForChild("Training"))

local player = Players.LocalPlayer

-- Visuals only.
local PANEL = Color3.fromRGB(28, 24, 40)
local CARD = Color3.fromRGB(44, 38, 60)
local TEXT = Color3.fromRGB(240, 236, 250)
local TEXT_DIM = Color3.fromRGB(160, 155, 175)
local AMBER = Color3.fromRGB(245, 175, 60)
local GREEN = Color3.fromRGB(70, 180, 110)
local GREY = Color3.fromRGB(80, 76, 96)
local WIDTH = 460

local gui = Instance.new("ScreenGui")
gui.Name = "ShopCounter"
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

-- Prompt at the counter, bottom centre (a button too, for touch).
local prompt = button(gui, "Shop: press E", PANEL, 300)
prompt.AnchorPoint = Vector2.new(0.5, 1)
prompt.Position = UDim2.new(0.5, 0, 1, -150)
prompt.Size = UDim2.fromOffset(300, 34)
prompt.TextSize = 18
prompt.TextColor3 = TEXT
prompt.BackgroundTransparency = 0.25
prompt.Visible = false

-- Toast, under the panel's header line.
local toast = textLabel(gui, 18, Enum.Font.GothamBold, AMBER)
toast.AnchorPoint = Vector2.new(0.5, 1)
toast.Position = UDim2.new(0.5, 0, 1, -110)
toast.Size = UDim2.fromOffset(520, 28)
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

-- The panel, top centre under the CoreGui band, its bottom 16 px above the window's.
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, SafeArea.localTop(GuiService:GetGuiInset().Y))
panel.Size = UDim2.new(0, WIDTH, 1, -(SafeArea.localTop(GuiService:GetGuiInset().Y) + 16))
panel.BackgroundColor3 = PANEL
panel.BackgroundTransparency = 0.05
panel.Visible = false
panel.Parent = gui
corner(panel, 12)
do
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(WIDTH, 640)
	limit.Parent = panel
	-- Under the CoreGui band, and under the chat window when its left edge is in it (Run 14 F13b).
	local function fitWidth()
		local camera = workspace.CurrentCamera
		if camera then
			local inset = GuiService:GetGuiInset().Y
			local width = math.min(WIDTH, camera.ViewportSize.X - 16)
			local top = SafeArea.topFor((camera.ViewportSize.X - width) / 2, inset, SafeArea.liveChat(TextChatService)) - inset
			panel.Position = UDim2.new(0.5, 0, 0, top)
			panel.Size = UDim2.new(0, width, 1, -(top + 16))
		end
	end
	fitWidth()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitWidth)
	end
end

local header = textLabel(panel, 22, Enum.Font.GothamBold, AMBER)
header.Position = UDim2.fromOffset(14, 8)
header.Size = UDim2.new(1, -120, 0, 30)
header.Text = "Shop"

local close = button(panel, "X Close", GREY, 84)
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -10, 0, 10)
close.Modal = true -- frees the mouse while the shop is open

local tabsRow = Instance.new("Frame")
tabsRow.Position = UDim2.fromOffset(10, 44)
tabsRow.Size = UDim2.new(1, -20, 0, 26)
tabsRow.BackgroundTransparency = 1
tabsRow.Parent = panel
do
	local l = Instance.new("UIListLayout")
	l.FillDirection = Enum.FillDirection.Horizontal
	l.Padding = UDim.new(0, 6)
	l.Parent = tabsRow
end

local storeRow = tabsRow:Clone()
storeRow.Position = UDim2.fromOffset(10, 74)
storeRow.Parent = panel

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(10, 108)
list.Size = UDim2.new(1, -20, 1, -118)
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

type View = { owned: { [string]: boolean }, wear: { [string]: string }, deco: { string }, decor: { string }?, level: number }
local view: View? = nil
local open = false
local tab = "hunter"
local order = 0

local TABS = { { "hunter", "Hunter skins" }, { "weapon", "Weapon skins" }, { "tower", "Tower sets" }, { "campsite", "Campsite" } }
local STORE_TABS = { { "store:Amber", "Amber" }, { "store:Passes", "Passes" }, { "store:Hatchery", "Hatchery" }, { "store:Skins", "Skins" } }
type StoreView = { open: boolean, restricted: boolean, passes: { [string]: boolean }, credits: { [string]: number }, trainCredits: number? }
local storeView: StoreView? = nil
local tabButtons: { [string]: TextButton } = {}

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

local load: () -> ()

local function act(action: string, a: any?, b: any?)
	local ok, message = request:InvokeServer(action, a, b)
	say(tostring(message))
	if ok then
		load()
	end
end

local function swatch(parent: Instance, key: string)
	local look = Skins.look(key)
	if not look then
		return
	end
	for i, c in { look.colour, look.accent } do
		local s = Instance.new("Frame")
		s.Size = UDim2.fromOffset(14, 14)
		s.Position = UDim2.fromOffset(10 + (i - 1) * 16, 9)
		s.BackgroundColor3 = c
		s.Parent = parent
		corner(s, 3)
	end
end

-- One skin row: swatches, its line, Buy and / or Wear / Take off for `slot`.
local function skinRow(v: View, key: string, slot: string)
	local f = card(32)
	swatch(f, key)
	local owned = v.owned[key] == true
	local line = textLabel(f, 14, Enum.Font.Gotham, if owned then TEXT else TEXT_DIM)
	line.Position = UDim2.fromOffset(46, 0)
	line.Size = UDim2.new(1, -150, 1, 0)
	line.Text = Skins.line({ owned = v.owned, wear = {}, deco = {}, decor = {} }, key, v.level)
	local action: TextButton
	if owned then
		local wearing = v.wear[slot] == key
		action = button(f, if wearing then "Take off" else "Wear", if wearing then GREY else GREEN, 90)
		action.Activated:Connect(function()
			act("wearSkin", slot, if wearing then "" else key)
		end)
	else
		local row = Skins.row(key)
		local price = row and row.price
		action = button(f, if price then `Buy {Theme.formatAmber(price)}` else "—", if price then AMBER else GREY, 90)
		action.Active = price ~= nil
		if price then
			action.Activated:Connect(function()
				act("buySkin", key)
			end)
		end
	end
	action.AnchorPoint = Vector2.new(1, 0.5)
	action.Position = UDim2.new(1, -8, 0.5, 0)
end

-- A row whose button cycles through `choices` (key or "" for none), showing `name(choice)`.
local function cycleRow(label: string, current: string, choices: { string }, name: (string) -> string, pick: (string) -> ())
	local f = card(32)
	local text = textLabel(f, 14, Enum.Font.Gotham, TEXT)
	text.Position = UDim2.fromOffset(10, 0)
	text.Size = UDim2.new(1, -190, 1, 0)
	text.Text = label
	local b = button(f, `{name(current)}  ▸`, GREY, 170)
	b.AnchorPoint = Vector2.new(1, 0.5)
	b.Position = UDim2.new(1, -8, 0.5, 0)
	b.Activated:Connect(function()
		local at = table.find(choices, current) or 0
		pick(choices[at % #choices + 1])
	end)
end

local function ownsTower(key: string): boolean
	return player:GetAttribute(`OwnsTower_{key}`) == true
end

-- The Robux store tabs (T143). Nothing here grants anything: Buy asks the server, which
-- shows Roblox's purchase prompt; the grant comes with the receipt (Server/Store).
local function renderStore(tabName: string)
	local sv = storeView
	if not sv or not sv.open then
		heading(StoreRules.CLOSED_LINE)
		return
	end
	local any = false
	-- "Finish this level" (#414) shows only while a stat is training.
	local active = Training.fromAttributes(function(name: string): any
		return player:GetAttribute(name)
	end).active
	local function storeBuy(key: string, stat: string?)
		local ok, message = storeRequest:InvokeServer("buy", key, stat)
		if not ok then
			say(tostring(message))
		end
	end
	for _, key in StoreRules.order() do
		local row = StoreRules.row(key)
		if row and row.tab == tabName and StoreRules.shown(key, sv.restricted) and (row.grant ~= "trainFinish" or #active > 0) then
			any = true
			local f = card(52)
			local name = textLabel(f, 15, Enum.Font.GothamBold, TEXT)
			name.Position = UDim2.fromOffset(10, 4)
			name.Size = UDim2.new(1, -130, 0, 20)
			local egg = if row.grant == "hatch" then (Config :: any).Eggs[row.items[1]] else nil
			name.Text = if egg then `{row.display} — {egg.display}` else row.display
			local line = textLabel(f, 12, Enum.Font.Gotham, TEXT_DIM)
			line.Position = UDim2.fromOffset(10, 24)
			line.Size = UDim2.new(1, -130, 0, 26)
			line.Text = StoreRules.cardLine(key, function(item)
				local r = Skins.row(item)
				return r and r.display
			end, function(item)
				local r = Skins.row(item)
				return r and r.price
			end, function(item)
				return view ~= nil and view.owned[item] == true
			end)
			local mine = row.type == "pass" and sv.passes[key] == true
			local b = button(f, if mine then "Yours" else `Buy {StoreRules.priceLabel(key)}`, if mine then GREY else AMBER, 110)
			b.AnchorPoint = Vector2.new(1, 0.5)
			b.Position = UDim2.new(1, -8, 0.5, 0)
			if not mine and row.grant == "trainFinish" and StoreRules.needsPick(active) then
				-- Two stats training: pick which one first (#414), then the prompt.
				b.Visible = false
				local pick = card(36)
				for i, stat in active do
					local s = button(pick, `{Training.NAMES[stat] or stat} · {StoreRules.priceLabel(key)}`, AMBER, 150)
					s.AnchorPoint = Vector2.new(0, 0.5)
					s.Position = UDim2.new(0, 10 + (i - 1) * 160, 0.5, 0)
					s.Activated:Connect(function()
						storeBuy(key, stat)
					end)
				end
			elseif not mine then
				b.Activated:Connect(function()
					storeBuy(key)
				end)
			end
		end
	end
	if not any then
		heading("Nothing here yet")
	end
	if (sv.trainCredits or 0) > 0 then
		heading(`Paid Finish this level waiting: {sv.trainCredits} (used on the next level you start)`)
	end
	for egg, n in sv.credits do
		local def = (Config :: any).Eggs[egg]
		heading(`Paid Hatch now waiting: {n} × {if def then def.display else egg} (used on your next one)`)
	end
end

local function render()
	clear()
	for key, b in tabButtons do
		b.BackgroundColor3 = if key == tab then AMBER else GREY
		b.TextColor3 = if key == tab then PANEL else TEXT
	end
	if string.sub(tab, 1, 6) == "store:" then
		renderStore(string.sub(tab, 7))
		return
	end
	local v = view
	if not v then
		heading("Your skins couldn't be loaded right now")
		return
	end
	if tab == "hunter" or tab == "weapon" then
		for _, hero in Config.HeroOrder do
			local def = Config.Heroes[hero]
			local keys = Skins.catalogue(tab, hero)
			if #keys > 0 then
				heading(if tab == "hunter" then def.display else (def.weapon ~= "" and def.weapon or def.display))
				for _, key in keys do
					skinRow(v, key, Skins.slot(tab, hero))
				end
			end
		end
	elseif tab == "tower" then
		local sets = Skins.catalogue("tower", nil)
		heading("Sets")
		for _, key in sets do
			local f = card(32)
			swatch(f, key)
			local owned = v.owned[key] == true
			local line = textLabel(f, 14, Enum.Font.Gotham, if owned then TEXT else TEXT_DIM)
			line.Position = UDim2.fromOffset(46, 0)
			line.Size = UDim2.new(1, -150, 1, 0)
			line.Text = Skins.line({ owned = v.owned, wear = {}, deco = {}, decor = {} }, key, v.level)
			local row = Skins.row(key)
			if not owned and row and row.price then
				local buy = button(f, `Buy {Theme.formatAmber(row.price)}`, AMBER, 90)
				buy.AnchorPoint = Vector2.new(1, 0.5)
				buy.Position = UDim2.new(1, -8, 0.5, 0)
				buy.Activated:Connect(function()
					act("buySkin", key)
				end)
			end
		end
		local mine = { "" }
		for _, key in sets do
			if v.owned[key] then
				table.insert(mine, key)
			end
		end
		heading("Your towers wear")
		for _, tower in Config.TowerOrder do
			if ownsTower(tower) then
				local slot = Skins.slot("tower", tower)
				cycleRow(Config.Towers[tower].display, v.wear[slot] or "", mine, function(key)
					local row = Skins.row(key)
					return if row then row.display else "Plain"
				end, function(key)
					act("wearSkin", slot, key)
				end)
			end
		end
	else
		heading("Display Towers — for show, they never shoot")
		local towers = { "" }
		for _, tower in Config.TowerOrder do
			if ownsTower(tower) then
				table.insert(towers, tower)
			end
		end
		for i = 1, Skins.DECO_SLOTS do
			cycleRow(`Spot {i}`, v.deco[i] or "", towers, function(key)
				local def = Config.Towers[key]
				return if def then def.display else "Empty"
			end, function(key)
				act("setDeco", i, key)
			end)
		end
		-- Decorations (T143c, #415): earned by level or bought, then placed on a spot.
		heading("Decorations — for show, one of each")
		local mineDecor = { "" }
		for _, key in Skins.catalogue("deco", nil) do
			local f = card(32)
			swatch(f, key)
			local owned = v.owned[key] == true
			if owned then
				table.insert(mineDecor, key)
			end
			local line = textLabel(f, 14, Enum.Font.Gotham, if owned then TEXT else TEXT_DIM)
			line.Position = UDim2.fromOffset(46, 0)
			line.Size = UDim2.new(1, -150, 1, 0)
			line.Text = Skins.line({ owned = v.owned, wear = {}, deco = {}, decor = {} }, key, v.level)
			local row = Skins.row(key)
			if not owned and row and row.price then
				local buy = button(f, `Buy {Theme.formatAmber(row.price)}`, AMBER, 90)
				buy.AnchorPoint = Vector2.new(1, 0.5)
				buy.Position = UDim2.new(1, -8, 0.5, 0)
				buy.Activated:Connect(function()
					act("buySkin", key)
				end)
			end
		end
		heading("Decoration spots")
		for i = 1, Skins.DECOR_SPOTS do
			cycleRow(`Spot {i}`, (v.decor or {})[i] or "", mineDecor, function(key)
				local row = Skins.row(key)
				return if row then row.display else "Empty"
			end, function(key)
				act("setDecor", i, key)
			end)
		end
	end
	if RunService:IsStudio() then
		order += 1
		local studio = button(list, "Studio: every skin (saving off)", GREY, 240)
		studio.LayoutOrder = order
		studio.Activated:Connect(function()
			act("studioSkins")
		end)
	end
end

for _, t in TABS do
	local b = button(tabsRow, t[2], GREY, 104)
	tabButtons[t[1]] = b
	b.Activated:Connect(function()
		tab = t[1]
		render()
	end)
end
do
	local label = textLabel(storeRow, 13, Enum.Font.GothamBold, AMBER)
	label.Size = UDim2.fromOffset(44, 26)
	label.Text = "Store"
	for _, t in STORE_TABS do
		local b = button(storeRow, t[2], GREY, 88)
		tabButtons[t[1]] = b
		b.Activated:Connect(function()
			tab = t[1]
			render()
		end)
	end
end

load = function()
	local storeOk, storeResult = storeRequest:InvokeServer("view")
	storeView = if storeOk and type(storeResult) == "table" then storeResult :: StoreView else nil
	local ok, result = request:InvokeServer("skins")
	if ok and type(result) == "table" then
		view = result :: View
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

local function atCounter(): boolean
	if player:GetAttribute("InOutpost") ~= true then
		return false
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and root:IsA("BasePart") and Outpost.atShop(root.Position)
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
	if processed or input.KeyCode ~= Enum.KeyCode.E or not atCounter() then
		return
	end
	setOpen(not open)
end)

player.AttributeChanged:Connect(function(name)
	if name == "SkinsVersion" and open then
		load()
	elseif name == "InOutpost" and player:GetAttribute("InOutpost") ~= true and open then
		setOpen(false) -- the counter is a camp thing: never left open in a match
	end
end)

task.spawn(function()
	while true do
		task.wait(0.5)
		prompt.Visible = atCounter() and not open
	end
end)

gui.Parent = player:WaitForChild("PlayerGui")
