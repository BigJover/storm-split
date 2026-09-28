--[[
	Shop panel. Opens when the player triggers a pad's ProximityPrompt and
	closes when they walk out of range.

	Empty pad: every tower with its price. Built pad: the tower and a Sell
	button. Buttons only send requests; the server validates, answers with a
	message, and updates the pad and cash attributes that drive this panel.
	Prices shown here come from Config for display only; the server charges
	from its own copy.
]]

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ShopRules = require(Shared:WaitForChild("ShopRules"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local request = remotes:WaitForChild("ShopRequest") :: RemoteFunction

local player = Players.LocalPlayer

-- Visuals only.
local PANEL_COLOR = Color3.fromRGB(24, 20, 34)
local BUY_COLOR = Color3.fromRGB(60, 110, 190)
local SELL_COLOR = Color3.fromRGB(190, 80, 90)
local LOCKED_COLOR = Color3.fromRGB(70, 66, 82)
local TEXT = Color3.fromRGB(240, 236, 250)
local TEXT_DIM = Color3.fromRGB(150, 145, 165)
local GOOD = Color3.fromRGB(140, 240, 170)
local BAD = Color3.fromRGB(255, 120, 140)

------------------------------------------------------------------ layout

local gui = Instance.new("ScreenGui")
gui.Name = "StormSplitShop"
gui.ResetOnSpawn = false

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -24)
panel.Size = UDim2.fromOffset(360, 0)
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.BackgroundColor3 = PANEL_COLOR
panel.BackgroundTransparency = 0.1
panel.Visible = false
panel.Parent = gui

do
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = panel
end

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 28)
header.BackgroundTransparency = 1
header.LayoutOrder = 1
header.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -36, 1, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = TEXT
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, 0, 0, 0)
closeButton.Size = UDim2.fromOffset(28, 28)
closeButton.BackgroundColor3 = LOCKED_COLOR
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.TextColor3 = TEXT
closeButton.Text = "X"
closeButton.Parent = header

do
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = closeButton
end

local list = Instance.new("Frame")
list.Name = "List"
list.Size = UDim2.new(1, 0, 0, 0)
list.AutomaticSize = Enum.AutomaticSize.Y
list.BackgroundTransparency = 1
list.LayoutOrder = 2
list.Parent = panel

do
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
end

local message = Instance.new("TextLabel")
message.Name = "Message"
message.Size = UDim2.new(1, 0, 0, 20)
message.BackgroundTransparency = 1
message.Font = Enum.Font.Gotham
message.TextSize = 15
message.TextColor3 = TEXT_DIM
message.TextXAlignment = Enum.TextXAlignment.Left
message.Text = ""
message.LayoutOrder = 3
message.Parent = panel

------------------------------------------------------------------ state

local currentPad: BasePart? = nil
local currentPrompt: ProximityPrompt? = nil
local padConnections: { RBXScriptConnection } = {}
local busy = false

local function escape(text: string): string
	return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function addRow(order: number, text: string, color: Color3, enabled: boolean, onClick: (() -> ())?)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 48)
	button.BackgroundColor3 = color
	button.BackgroundTransparency = if enabled then 0 else 0.5
	button.AutoButtonColor = enabled
	button.RichText = true
	button.Font = Enum.Font.Gotham
	button.TextSize = 16
	button.TextColor3 = if enabled then TEXT else TEXT_DIM
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.Text = text
	button.LayoutOrder = order

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.Parent = button

	if enabled and onClick then
		button.Activated:Connect(onClick)
	end
	button.Parent = list
end

local render: () -> ()

local function send(action: string, padIndex: number, towerKey: string?)
	if busy then
		return
	end
	busy = true
	message.TextColor3 = TEXT_DIM
	message.Text = "…"

	local ok, success, text = pcall(function()
		return request:InvokeServer(action, padIndex, towerKey)
	end)

	busy = false
	if not ok then
		message.TextColor3 = BAD
		message.Text = "Couldn't reach the server"
	else
		message.TextColor3 = if success then GOOD else BAD
		message.Text = tostring(text)
	end
	render()
end

render = function()
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local pad = currentPad
	if not pad then
		panel.Visible = false
		return
	end
	panel.Visible = true

	local padIndex = pad:GetAttribute("PadIndex") :: number
	local towerKey = pad:GetAttribute("Tower") :: string?
	local cash = math.floor(ReplicatedStorage:GetAttribute("Cash") or 0)

	if towerKey then
		local def = Config.Towers[towerKey]
		local refund = math.floor((pad:GetAttribute("Spent") or 0) * Config.Tuning.SellRefund)
		title.Text = `{def.display}  ·  Pad {padIndex}`
		addRow(1, `<b>Sell</b>  for {refund}`, SELL_COLOR, true, function()
			send("sell", padIndex)
		end)
		addRow(2, "Upgrades are coming soon", LOCKED_COLOR, false)
	else
		title.Text = `Build on pad {padIndex}  ·  Cash {cash}`
		for order, key in Config.TowerOrder do
			local def = Config.Towers[key]
			local name = escape(def.display)
			if ShopRules.Unreleased[key] then
				addRow(order, `<b>{name}</b>  ·  coming later`, LOCKED_COLOR, false)
			else
				local affordable = cash >= def.baseCost
				local text = `<b>{name}</b>  ·  {def.baseCost}\n<font size="13">{escape(def.role)}</font>`
				addRow(order, text, if affordable then BUY_COLOR else LOCKED_COLOR, affordable, function()
					send("build", padIndex, key)
				end)
			end
		end
	end
end

local function close()
	for _, connection in padConnections do
		connection:Disconnect()
	end
	table.clear(padConnections)
	currentPad = nil
	currentPrompt = nil
	message.Text = ""
	render()
end

local function open(pad: BasePart, prompt: ProximityPrompt)
	close()
	currentPad = pad
	currentPrompt = prompt
	for _, name in { "Tower", "Spent" } do
		table.insert(padConnections, pad:GetAttributeChangedSignal(name):Connect(render))
	end
	render()
end

------------------------------------------------------------------ wiring

ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
	if who ~= player then
		return
	end
	local pad = prompt.Parent
	if pad and pad:IsA("BasePart") and pad:GetAttribute("PadIndex") then
		open(pad, prompt)
	end
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
	if prompt == currentPrompt then
		close()
	end
end)

closeButton.Activated:Connect(close)

ReplicatedStorage:GetAttributeChangedSignal("Cash"):Connect(function()
	if currentPad then
		render()
	end
end)

gui.Parent = player:WaitForChild("PlayerGui")
