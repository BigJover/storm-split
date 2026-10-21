--[[
	Training in the Hunters' Outpost (PLAN 10c T139): the station prompt (E), the training
	panel and the level-up toast. Everything is a request; the server reads where you stand
	and owns the numbers (Server/Training, Server/Progression; rules in Shared/Training).

	  - On a station's pad: "<Station>: press E to train <Stat>" (or how fast it trains).
	  - The panel (top right, camp only): each stat's level, % and bar, which one trains and
	    at what speed (full here / half elsewhere), and an Amber Finish button once the sheet
	    has a price. It folds to a small "Training" button and back (no-trap rule); it never
	    holds the mouse.
	  - A toast when a level is reached (anywhere: training runs in matches too, at half).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Training = require(Shared:WaitForChild("Training"))
local Outpost = require(Shared:WaitForChild("Outpost"))
local Theme = require(Shared:WaitForChild("Theme"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local request = remotes:WaitForChild("Training") :: RemoteFunction
local levelEvent = remotes:WaitForChild("TrainingLevel") :: RemoteEvent

local player = Players.LocalPlayer

-- Visuals only.
local PANEL = Color3.fromRGB(28, 24, 40)
local TEXT = Color3.fromRGB(240, 236, 250)
local TEXT_DIM = Color3.fromRGB(160, 155, 175)
local AMBER = Color3.fromRGB(245, 175, 60)
local BAR = Color3.fromRGB(70, 180, 110)
local BAR_BG = Color3.fromRGB(50, 46, 64)
local WIDTH = 330
local ROW = 46

local gui = Instance.new("ScreenGui")
gui.Name = "Training"
gui.ResetOnSpawn = false
gui.DisplayOrder = 6

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
	label.Parent = parent
	return label
end

-- Station prompt, bottom centre.
local prompt = textLabel(gui, 20, Enum.Font.GothamBold, TEXT)
prompt.AnchorPoint = Vector2.new(0.5, 1)
prompt.Position = UDim2.new(0.5, 0, 1, -110)
prompt.Size = UDim2.fromOffset(560, 34)
prompt.TextXAlignment = Enum.TextXAlignment.Center
prompt.BackgroundTransparency = 0.25
prompt.BackgroundColor3 = PANEL
prompt.Visible = false
corner(prompt, 8)

-- Toast, top centre.
local toast = textLabel(gui, 22, Enum.Font.GothamBold, AMBER)
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, 70)
toast.Size = UDim2.fromOffset(460, 36)
toast.TextXAlignment = Enum.TextXAlignment.Center
toast.Visible = false
local toastToken = 0
local function say(text: string)
	toastToken += 1
	local mine = toastToken
	toast.Text = text
	toast.Visible = true
	task.delay(3, function()
		if toastToken == mine then
			toast.Visible = false
		end
	end)
end

-- Panel, top right.
local folded = false
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -16, 0, 64)
panel.Size = UDim2.fromOffset(WIDTH, 40 + ROW * #Training.STATS)
panel.BackgroundColor3 = PANEL
panel.BackgroundTransparency = 0.15
panel.Visible = false
panel.Parent = gui
corner(panel, 10)

local title = textLabel(panel, 18, Enum.Font.GothamBold, AMBER)
title.Position = UDim2.fromOffset(12, 6)
title.Size = UDim2.new(1, -60, 0, 26)
title.Text = "TRAINING"

local foldButton = Instance.new("TextButton")
foldButton.AnchorPoint = Vector2.new(1, 0)
foldButton.Position = UDim2.new(1, -16, 0, 64)
foldButton.Size = UDim2.fromOffset(110, 32)
foldButton.BackgroundColor3 = PANEL
foldButton.Font = Enum.Font.GothamBold
foldButton.TextSize = 16
foldButton.TextColor3 = TEXT
foldButton.Text = "Training"
foldButton.Visible = false
foldButton.Parent = gui
corner(foldButton, 8)

local closeButton = Instance.new("TextButton")
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -8, 0, 6)
closeButton.Size = UDim2.fromOffset(28, 26)
closeButton.BackgroundColor3 = BAR_BG
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.TextColor3 = TEXT
closeButton.Text = "X"
closeButton.Parent = panel
corner(closeButton, 6)

type RowUi = { line: TextLabel, sub: TextLabel, fill: Frame, finish: TextButton }
local rows: { [string]: RowUi } = {}
for i, stat in Training.STATS do
	local y = 36 + (i - 1) * ROW
	local line = textLabel(panel, 14, Enum.Font.GothamBold, TEXT)
	line.Position = UDim2.fromOffset(12, y)
	line.Size = UDim2.new(1, -24, 0, 18)
	local back = Instance.new("Frame")
	back.Position = UDim2.fromOffset(12, y + 20)
	back.Size = UDim2.new(1, -120, 0, 8)
	back.BackgroundColor3 = BAR_BG
	back.BorderSizePixel = 0
	back.Parent = panel
	corner(back, 4)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = BAR
	fill.BorderSizePixel = 0
	fill.Parent = back
	corner(fill, 4)
	local sub = textLabel(panel, 11, Enum.Font.Gotham, TEXT_DIM)
	sub.Position = UDim2.fromOffset(12, y + 29)
	sub.Size = UDim2.new(1, -120, 0, 14)
	local finish = Instance.new("TextButton")
	finish.AnchorPoint = Vector2.new(1, 0)
	finish.Position = UDim2.new(1, -10, 0, y + 18)
	finish.Size = UDim2.fromOffset(98, 24)
	finish.BackgroundColor3 = AMBER
	finish.Font = Enum.Font.GothamBold
	finish.TextSize = 12
	finish.TextColor3 = PANEL
	finish.Visible = false
	finish.Parent = panel
	corner(finish, 6)
	finish.Activated:Connect(function()
		local ok, message = request:InvokeServer("finish", stat)
		say(if ok then `{Training.NAMES[stat]}: {message}` else tostring(message))
	end)
	rows[stat] = { line = line, sub = sub, fill = fill, finish = finish }
end

local function state(): Training.State
	return Training.fromAttributes(function(name)
		return player:GetAttribute(name)
	end)
end

local function standingAt(): string?
	if player:GetAttribute("InOutpost") ~= true then
		return nil
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then Outpost.stationAt(root.Position) else nil
end

local function refresh()
	local inCamp = player:GetAttribute("InOutpost") == true
	local current = state()
	local at = standingAt()
	panel.Visible = inCamp and not folded
	foldButton.Visible = inCamp and folded
	for _, row in Training.view(current) do
		local ui = rows[row.stat]
		ui.line.Text = Training.line(row)
		ui.fill.Size = UDim2.fromScale(if row.need > 0 then math.clamp(row.progress / row.need, 0, 1) else 1, 1)
		local station = Outpost.station(row.stat)
		if row.level >= row.max then
			ui.sub.Text = "Fully trained"
		elseif row.active then
			ui.sub.Text = if Training.rate(row.stat, at) >= 1 then "Full speed here" else `Half speed — full at the {station and station.name}`
		else
			ui.sub.Text = `Train it at the {station and station.name} (E)`
		end
		local price = Training.finishPrice(current, row.stat)
		ui.finish.Visible = price ~= nil
		if price then
			ui.finish.Text = `Finish {Theme.formatAmber(price)}`
		end
	end
	local station = at and Outpost.station(at)
	prompt.Visible = station ~= nil
	if station then
		local training = table.find(current.active, station.key) ~= nil
		prompt.Text = if (current.levels[station.key] or 0) >= Training.levels()
			then `{station.name}: {station.stat} is fully trained`
			elseif training then `{station.name}: training {station.stat} at full speed`
			else `{station.name}: press E to train {station.stat}`
	end
end

foldButton.Activated:Connect(function()
	folded = false
	refresh()
end)
closeButton.Activated:Connect(function()
	folded = true
	refresh()
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.KeyCode ~= Enum.KeyCode.E or not standingAt() then
		return
	end
	local ok, message = request:InvokeServer("start")
	say(tostring(message))
	if ok then
		refresh()
	end
end)

levelEvent.OnClientEvent:Connect(function(stat, level)
	say(`{Training.NAMES[stat] or tostring(stat)} is now level {tostring(level)}!`)
end)

player.AttributeChanged:Connect(function(name)
	if name == "InOutpost" or name == "TrainActive" or string.sub(name, 1, 5) == "Train" then
		refresh()
	end
end)
task.spawn(function()
	while true do
		task.wait(0.5) -- the prompt follows you between pads
		refresh()
	end
end)

refresh()
gui.Parent = player:WaitForChild("PlayerGui")
