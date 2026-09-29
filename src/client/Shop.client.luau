--[[
	Building and managing towers.

	Build: the Build button (or B) opens the tower list. Picking one starts
	placement: a see-through ghost follows the mouse (or the last tap), green
	where Shared/Placement says it fits and red where it doesn't. Click or tap
	to place; Q or Cancel to stop.

	Manage: walking up to a tower shows its prompt; triggering it opens a panel
	with its three upgrade paths and Sell. Paths the crossover rule
	(Shared/Upgrades) or the team's cash won't allow are greyed out.

	Everything here is a request. The server re-checks the spot, the distance
	and the cash with the same rules and has the final say. Prices shown come
	from Config for display only.
]]

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Placement = require(Shared:WaitForChild("Placement"))
local ShopRules = require(Shared:WaitForChild("ShopRules"))
local TowerLook = require(Shared:WaitForChild("TowerLook"))
local Upgrades = require(Shared:WaitForChild("Upgrades"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local request = remotes:WaitForChild("ShopRequest") :: RemoteFunction

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Visuals only.
local PANEL_COLOR = Color3.fromRGB(24, 20, 34)
local BUY_COLOR = Color3.fromRGB(60, 110, 190)
local SELL_COLOR = Color3.fromRGB(190, 80, 90)
local LOCKED_COLOR = Color3.fromRGB(70, 66, 82)
local BUILD_COLOR = Color3.fromRGB(70, 180, 110)
local TEXT = Color3.fromRGB(240, 236, 250)
local TEXT_DIM = Color3.fromRGB(150, 145, 165)
local GOOD = Color3.fromRGB(140, 240, 170)
local BAD = Color3.fromRGB(255, 120, 140)
local GHOST_OK = Color3.fromRGB(90, 230, 120)
local GHOST_BAD = Color3.fromRGB(240, 70, 80)
local GHOST_TRANSPARENCY = 0.5

------------------------------------------------------------------ layout

local gui = Instance.new("ScreenGui")
gui.Name = "StormSplitShop"
gui.ResetOnSpawn = false

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local buildButton = Instance.new("TextButton")
buildButton.Name = "Build"
buildButton.AnchorPoint = Vector2.new(1, 1)
buildButton.Position = UDim2.new(1, -24, 1, -24)
buildButton.Size = UDim2.fromOffset(140, 48)
buildButton.BackgroundColor3 = BUILD_COLOR
buildButton.Font = Enum.Font.GothamBold
buildButton.TextSize = 20
buildButton.TextColor3 = TEXT
buildButton.Text = "Build  (B)"
buildButton.Parent = gui
corner(buildButton, 8)

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
corner(panel, 10)

do
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
corner(closeButton, 6)

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

type Mode = "closed" | "list" | "placing" | "manage"

local mode: Mode = "closed"
local placingKey: string? = nil
local ghost: Model? = nil
local ghostSpot: Vector3? = nil
local ghostFits = false
local managed: BasePart? = nil -- body of the tower being managed
local managedPrompt: ProximityPrompt? = nil
local managedConnections: { RBXScriptConnection } = {}
local busy = false

local function escape(text: string): string
	return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function say(text: string, color: Color3?)
	message.Text = text
	message.TextColor3 = color or TEXT_DIM
end

local LOCK_REASONS = {
	["third path"] = "locked · only two paths per tower",
	crossover = "locked · only one path past tier 2",
}

-- "+30% damage · +15% rate" for going from `current` to `current + 1` on a path.
local function describeStep(path, current: number): string
	local now = if current > 0 then path.tiers[current] else nil
	local nextStep = path.tiers[current + 1]
	local parts = {}
	for _, stat in { { "damageMult", "damage" }, { "rateMult", "rate" }, { "targetsMult", "targets" }, { "rangeMult", "range" } } do
		local before = if now then (now[stat[1]] or 1) else 1
		local after = nextStep[stat[1]] or 1
		local change = after / before - 1
		if math.abs(change) >= 0.005 then
			table.insert(parts, `{if change > 0 then "+" else ""}{math.floor(change * 100 + 0.5)}% {stat[2]}`)
		end
	end
	return if #parts > 0 then table.concat(parts, " · ") else path.focus
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
	corner(button, 8)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.Parent = button

	if enabled and onClick then
		button.Activated:Connect(onClick)
	end
	button.Parent = list
end

------------------------------------------------------------------ ghost

local function mapFolder(name: string): Instance?
	local map = workspace:FindFirstChild("StormSplitMap")
	return map and map:FindFirstChild(name)
end

local function towerFolder(): Instance?
	return mapFolder("Towers")
end

local function builtPositions(): { Vector3 }
	local positions = {}
	local folder = towerFolder()
	if folder then
		for _, model in folder:GetChildren() do
			if model:IsA("Model") and model.PrimaryPart then
				table.insert(positions, Placement.ground(model.PrimaryPart.Position))
			end
		end
	end
	return positions
end

local function characterRoot(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function destroyGhost()
	if ghost then
		ghost:Destroy()
	end
	ghost, ghostSpot, ghostFits = nil, nil, false
end

local function makeGhost(key: string)
	destroyGhost()
	local def = Config.Towers[key]
	local model = TowerLook.build(key, def.range, Vector3.zero)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.CastShadow = false
			if part.Name == "Body" then
				part.Transparency = GHOST_TRANSPARENCY
			end
		end
	end
	model.Parent = camera -- local only; never replicates
	ghost = model
end

-- Where a screen point lands on the ground, ignoring enemies, towers and us.
local function groundUnder(screenPoint: Vector2, includesInset: boolean): Vector3?
	local ray = if includesInset
		then camera:ViewportPointToRay(screenPoint.X, screenPoint.Y)
		else camera:ScreenPointToRay(screenPoint.X, screenPoint.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = {}
	for _, instance in { player.Character, ghost, mapFolder("Enemies"), towerFolder() } do
		if instance then
			table.insert(ignore, instance)
		end
	end
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
	return hit and Placement.ground(hit.Position)
end

local function moveGhost(spot: Vector3?)
	if not ghost or not ghost.PrimaryPart then
		return
	end
	ghostSpot = spot
	if not spot then
		ghostFits = false
		ghost.Parent = nil
		return
	end
	ghost.Parent = camera

	local fits, reason = Placement.check(spot, builtPositions())
	local root = characterRoot()
	if fits and root then
		local offset = root.Position - spot
		if Vector2.new(offset.X, offset.Z).Magnitude > ShopRules.PlaceRange then
			fits, reason = false, "Too far from you — walk closer"
		end
	end
	ghostFits = fits

	ghost:PivotTo(CFrame.new(spot + Vector3.new(0, TowerLook.BODY_HEIGHT / 2, 0)))
	local color = if fits then GHOST_OK else GHOST_BAD
	for _, part in ghost:GetDescendants() do
		if part:IsA("BasePart") then
			part.Color = color
		end
	end
	if not busy then
		say(if fits then "Click or tap to place  ·  Q to cancel" else (reason or "Can't build here"), if fits then TEXT_DIM else BAD)
	end
end

------------------------------------------------------------------ panel

local render: () -> ()

local function setMode(newMode: Mode)
	if newMode ~= "placing" then
		destroyGhost()
		placingKey = nil
	end
	if newMode ~= "manage" then
		for _, connection in managedConnections do
			connection:Disconnect()
		end
		table.clear(managedConnections)
		managed, managedPrompt = nil, nil
	end
	mode = newMode
	say("")
	render()
end

local function send(action: string, a: any, b: any): boolean
	if busy then
		return false
	end
	busy = true
	say("…")
	local ok, success, text = pcall(function()
		return request:InvokeServer(action, a, b)
	end)
	busy = false
	if not ok then
		say("Couldn't reach the server", BAD)
		return false
	end
	say(tostring(text), if success then GOOD else BAD)
	return success == true
end

local function startPlacing(key: string)
	setMode("placing")
	placingKey = key
	makeGhost(key)
	render()
	moveGhost(groundUnder(UserInputService:GetMouseLocation(), true))
end

local function tryPlace()
	local key, spot = placingKey, ghostSpot
	if busy or not key or not spot then
		return
	end
	if not ghostFits then
		return -- the message already says why
	end
	if send("build", key, spot) then
		setMode("closed")
	end
end

render = function()
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	panel.Visible = mode ~= "closed"
	buildButton.Text = if mode == "closed" then "Build  (B)" else "Close  (B)"
	local cash = math.floor(ReplicatedStorage:GetAttribute("Cash") or 0)

	if mode == "list" then
		title.Text = `Build  ·  Cash {cash}`
		for order, key in Config.TowerOrder do
			local def = Config.Towers[key]
			local name = escape(def.display)
			if ShopRules.Unreleased[key] then
				addRow(order, `<b>{name}</b>  ·  coming later`, LOCKED_COLOR, false)
			else
				local affordable = cash >= def.baseCost
				local text = `<b>{name}</b>  ·  {def.baseCost}\n<font size="13">{escape(def.role)}</font>`
				addRow(order, text, if affordable then BUY_COLOR else LOCKED_COLOR, affordable, function()
					startPlacing(key)
				end)
			end
		end
	elseif mode == "placing" and placingKey then
		local def = Config.Towers[placingKey]
		title.Text = `Placing {def.display}  ·  {def.baseCost}`
		addRow(1, "<b>Cancel</b>  (Q)", LOCKED_COLOR, true, function()
			setMode("list")
		end)
	elseif mode == "manage" and managed then
		local key = managed:GetAttribute("Tower") :: string
		local def = Config.Towers[key]
		local towerId = managed:GetAttribute("TowerId")
		local tiers = {}
		for pathIndex = 1, 3 do
			tiers[pathIndex] = managed:GetAttribute(`Path{pathIndex}`) or 0
		end
		title.Text = `{if def then def.display else "Tower"}  ·  {tiers[1]} · {tiers[2]} · {tiers[3]}`

		if def then
			for pathIndex, path in def.paths do
				local current = tiers[pathIndex]
				local name = escape(path.id)
				local why = Upgrades.check(tiers, pathIndex, #path.tiers)
				if why == "maxed" then
					addRow(pathIndex, `<b>{name}</b>  ·  maxed`, LOCKED_COLOR, false)
				elseif why ~= "ok" then
					addRow(pathIndex, `<b>{name}</b>  ·  tier {current}\n<font size="13">{LOCK_REASONS[why] or "locked"}</font>`, LOCKED_COLOR, false)
				else
					local step = path.tiers[current + 1]
					local affordable = cash >= step.cost
					local text = `<b>{name}</b>  ·  tier {current + 1}  ·  {step.cost}\n<font size="13">{escape(describeStep(path, current))}</font>`
					addRow(pathIndex, text, if affordable then BUY_COLOR else LOCKED_COLOR, affordable, function()
						send("upgrade", towerId, pathIndex)
					end)
				end
			end
		end

		local refund = math.floor((managed:GetAttribute("Spent") or 0) * Config.Tuning.SellRefund)
		addRow(10, `<b>Sell</b>  for {refund}`, SELL_COLOR, true, function()
			if send("sell", towerId) then
				setMode("closed")
			end
		end)
	end
end

local function openManage(body: BasePart, prompt: ProximityPrompt)
	setMode("manage")
	managed, managedPrompt = body, prompt
	for _, name in { "Spent", "Tower", "Path1", "Path2", "Path3" } do
		table.insert(managedConnections, body:GetAttributeChangedSignal(name):Connect(render))
	end
	table.insert(managedConnections, body.AncestryChanged:Connect(function()
		if not body:IsDescendantOf(workspace) then
			setMode("closed") -- sold, possibly by a teammate
		end
	end))
	render()
end

------------------------------------------------------------------ input

local function toggleBuild()
	setMode(if mode == "closed" or mode == "manage" then "list" else "closed")
end

buildButton.Activated:Connect(toggleBuild)
closeButton.Activated:Connect(function()
	setMode("closed")
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return -- typing in chat, or clicking our own buttons
	end
	if input.KeyCode == Enum.KeyCode.B then
		toggleBuild()
	elseif mode == "placing" then
		if input.KeyCode == Enum.KeyCode.Q then
			setMode("list")
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			tryPlace()
		elseif input.UserInputType == Enum.UserInputType.Touch then
			moveGhost(groundUnder(Vector2.new(input.Position.X, input.Position.Y), false))
			tryPlace()
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if mode == "placing" and ghost and UserInputService.MouseEnabled then
		moveGhost(groundUnder(UserInputService:GetMouseLocation(), true))
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
	if who ~= player or mode == "placing" then
		return
	end
	local body = prompt.Parent
	if body and body:IsA("BasePart") and body:GetAttribute("TowerId") then
		openManage(body, prompt)
	end
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
	if mode == "manage" and prompt == managedPrompt then
		setMode("closed")
	end
end)

ReplicatedStorage:GetAttributeChangedSignal("Cash"):Connect(function()
	if mode == "list" or mode == "manage" then
		render()
	end
end)

render()
gui.Parent = player:WaitForChild("PlayerGui")
