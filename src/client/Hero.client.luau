--[[
	Hero weapons on the client: hold click (or touch) with a weapon equipped to
	keep firing along your aim; F or the ability button uses the equipped
	weapon's ability.

	CAMERA: holding a weapon puts you in first person with a crosshair, for
	gunplay. Unarmed, or with any panel open (Build, Hero, a tower), you're in
	third person with a free mouse so you can see the map and click the HUD.
	V (or the View button) turns first person off and on.

	Shots send the camera's aim ray. They're only requests: the server
	(Server/Hero) checks the weapon, fire rate, range and cooldown and decides
	what gets hit, then echoes hits back for the hit marker.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local heroRequest = remotes:WaitForChild("HeroRequest") :: RemoteFunction
local heroFire = remotes:WaitForChild("HeroFire") :: RemoteEvent

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Visuals only.
local TEXT = Color3.fromRGB(240, 236, 250)
local READY = Color3.fromRGB(200, 90, 110)
local WAITING = Color3.fromRGB(70, 66, 82)
local KILL = Color3.fromRGB(255, 80, 90)
local CROSSHAIR_GAP = 5 -- px, at rest
local CROSSHAIR_KICK = 7 -- px added per shot
local CROSSHAIR_SETTLE = 14 -- how fast the spread recovers (per second, exponential)
local THIRD_PERSON_ZOOM = 12 -- studs; where the camera lands when leaving first person

------------------------------------------------------------------ ability button

local gui = Instance.new("ScreenGui")
gui.Name = "StormSplitHero"
gui.ResetOnSpawn = false

local abilityButton = Instance.new("TextButton")
abilityButton.Name = "Ability"
abilityButton.AnchorPoint = Vector2.new(1, 1)
abilityButton.Position = UDim2.new(1, -24, 1, -136)
abilityButton.Size = UDim2.fromOffset(140, 48)
abilityButton.Font = Enum.Font.GothamBold
abilityButton.TextSize = 18
abilityButton.TextColor3 = TEXT
abilityButton.Visible = false
abilityButton.Parent = gui

do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = abilityButton
end

local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.AnchorPoint = Vector2.new(1, 1)
toast.Position = UDim2.new(1, -24, 1, -192)
toast.Size = UDim2.fromOffset(260, 24)
toast.BackgroundTransparency = 1
toast.Font = Enum.Font.GothamBold
toast.TextSize = 16
toast.TextColor3 = TEXT
toast.TextStrokeTransparency = 0.5
toast.TextXAlignment = Enum.TextXAlignment.Right
toast.Text = ""
toast.Parent = gui

local toastToken = 0
local function showToast(text: string)
	toastToken += 1
	local token = toastToken
	toast.Text = text
	task.delay(2, function()
		if toastToken == token then
			toast.Text = ""
		end
	end)
end

------------------------------------------------------------------ equipped weapon

local function equippedTool(): Tool?
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	if tool and typeof(tool:GetAttribute("WeaponType")) == "string" then
		return tool
	end
	return nil
end

local function weaponRow(tool: Tool)
	local key = tool:GetAttribute("WeaponType") :: string
	local tier = player:GetAttribute(`Weapon_{key}`) or 0
	local weapon = Config.Weapons[key]
	return weapon, if weapon and tier > 0 then weapon.tiers[tier] else nil, tier
end

-- The camera ray through the crosshair (first person) or the mouse (third).
local function aimRay(): (Vector3, Vector3)
	local ray = mouse.UnitRay
	return ray.Origin, ray.Direction
end

------------------------------------------------------------------ crosshair and camera

local crosshair = Instance.new("Frame")
crosshair.Name = "Crosshair"
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.fromScale(0.5, 0.5)
crosshair.Size = UDim2.fromOffset(0, 0)
crosshair.BackgroundTransparency = 1
crosshair.Visible = false
crosshair.Parent = gui

local bars: { Frame } = {}
for i = 1, 4 do
	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.Size = if i <= 2 then UDim2.fromOffset(2, 8) else UDim2.fromOffset(8, 2)
	bar.BackgroundColor3 = TEXT
	bar.BorderSizePixel = 0
	bar.Parent = crosshair
	bars[i] = bar
end

local hitMarker = Instance.new("TextLabel")
hitMarker.AnchorPoint = Vector2.new(0.5, 0.5)
hitMarker.Size = UDim2.fromOffset(30, 30)
hitMarker.BackgroundTransparency = 1
hitMarker.Font = Enum.Font.GothamBold
hitMarker.TextSize = 26
hitMarker.Text = "×"
hitMarker.Visible = false
hitMarker.Parent = crosshair

local spread = 0
local markerToken = 0

local function kickCrosshair()
	spread += CROSSHAIR_KICK
end

heroFire.OnClientEvent:Connect(function(killed: boolean)
	markerToken += 1
	local token = markerToken
	hitMarker.TextColor3 = if killed then KILL else TEXT
	hitMarker.Visible = true
	task.delay(if killed then 0.2 else 0.1, function()
		if markerToken == token then
			hitMarker.Visible = false
		end
	end)
end)

local viewButton = Instance.new("TextButton")
viewButton.Name = "View"
viewButton.AnchorPoint = Vector2.new(1, 0)
viewButton.Position = UDim2.new(1, -24, 0, 12)
viewButton.Size = UDim2.fromOffset(110, 36)
viewButton.BackgroundColor3 = WAITING
viewButton.Font = Enum.Font.GothamBold
viewButton.TextSize = 15
viewButton.TextColor3 = TEXT
viewButton.Parent = gui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = viewButton
end

local preferFirstPerson = true -- flipped by V; first person also needs a weapon in hand
local inFirstPerson: boolean? = nil
local defaultMinZoom = player.CameraMinZoomDistance

local function applyCamera()
	local wantFirst = preferFirstPerson and equippedTool() ~= nil and player:GetAttribute("PanelOpen") ~= true
	viewButton.Text = if preferFirstPerson then "Aim: 1st (V)" else "Aim: 3rd (V)"
	if wantFirst == inFirstPerson then
		return
	end
	inFirstPerson = wantFirst
	crosshair.Visible = wantFirst
	UserInputService.MouseIconEnabled = not wantFirst
	if wantFirst then
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	else
		player.CameraMode = Enum.CameraMode.Classic
		-- Leaving first person leaves the camera zoomed all the way in; push it
		-- back out, then let the player zoom freely again.
		player.CameraMinZoomDistance = THIRD_PERSON_ZOOM
		task.delay(0.1, function()
			if not inFirstPerson then
				player.CameraMinZoomDistance = defaultMinZoom
			end
		end)
	end
end

local function toggleView()
	preferFirstPerson = not preferFirstPerson
	applyCamera()
end

viewButton.Activated:Connect(toggleView)
player:GetAttributeChangedSignal("PanelOpen"):Connect(applyCamera)
applyCamera()

RunService.RenderStepped:Connect(function(dt)
	spread *= math.exp(-CROSSHAIR_SETTLE * dt)
	local gap = CROSSHAIR_GAP + spread
	bars[1].Position = UDim2.fromOffset(0, -gap - 4)
	bars[2].Position = UDim2.fromOffset(0, gap + 4)
	bars[3].Position = UDim2.fromOffset(-gap - 4, 0)
	bars[4].Position = UDim2.fromOffset(gap + 4, 0)
end)

------------------------------------------------------------------ firing

local holding = false
local firing = false
local hooked: { [Tool]: boolean } = {}

local function fireLoop(tool: Tool)
	if firing then
		return
	end
	firing = true
	while holding and tool.Parent == player.Character do
		local _, row = weaponRow(tool)
		if not row then
			break
		end
		heroFire:FireServer(aimRay())
		kickCrosshair()
		local overdrive = (player:GetAttribute("OverdriveUntil") or 0) > workspace:GetServerTimeNow()
		local rate = row.rate * (if overdrive then Config.Tuning.OverdriveFireRateX else 1)
		task.wait(1 / rate)
	end
	firing = false
end

local function hook(tool: Instance)
	if not tool:IsA("Tool") or hooked[tool] or typeof(tool:GetAttribute("WeaponType")) ~= "string" then
		return
	end
	hooked[tool] = true
	tool.Activated:Connect(function()
		holding = true
		task.spawn(fireLoop, tool)
	end)
	tool.Deactivated:Connect(function()
		holding = false
	end)
	tool.Equipped:Connect(function()
		task.defer(applyCamera)
	end)
	tool.Unequipped:Connect(function()
		holding = false
		task.defer(applyCamera)
	end)
	tool.Destroying:Connect(function()
		hooked[tool] = nil
	end)
end

local function watch(container: Instance)
	for _, child in container:GetChildren() do
		hook(child)
	end
	container.ChildAdded:Connect(hook)
end

local function onCharacter(character: Model)
	holding = false
	watch(character)
	watch(player:WaitForChild("Backpack"))
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then
	onCharacter(player.Character)
end

------------------------------------------------------------------ ability

local function useAbility()
	if not equippedTool() then
		return
	end
	local ok, _, text = pcall(function()
		local origin, direction = aimRay()
		return heroRequest:InvokeServer("ability", origin, direction)
	end)
	showToast(if ok then tostring(text) else "Couldn't reach the server")
end

abilityButton.Activated:Connect(useAbility)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F then
		useAbility()
	elseif input.KeyCode == Enum.KeyCode.V then
		toggleView()
	end
end)

-- Keep the button showing the equipped weapon's ability and its cooldown.
RunService.Heartbeat:Connect(function()
	local tool = equippedTool()
	if not tool then
		abilityButton.Visible = false
		return
	end
	local key = tool:GetAttribute("WeaponType") :: string
	local weapon, _, tier = weaponRow(tool)
	if not weapon or tier < 2 then
		abilityButton.Visible = false
		return
	end
	abilityButton.Visible = true
	local remaining = (player:GetAttribute(`AbilityReadyAt_{key}`) or 0) - workspace:GetServerTimeNow()
	if remaining > 0 then
		abilityButton.Text = `{weapon.ability}  {math.ceil(remaining)}s`
		abilityButton.BackgroundColor3 = WAITING
	else
		abilityButton.Text = `{weapon.ability}  (F)`
		abilityButton.BackgroundColor3 = READY
	end
end)

gui.Parent = player:WaitForChild("PlayerGui")
