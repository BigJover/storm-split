--[[
	The hero's gun on the client (HEROES.md).

	TRIGGER: semi fires once per click, auto keeps firing while held, burst
	fires `burstCount` rounds per click. Dual guns and Spin-Up fire faster, as
	the server allows (Shared/HeroStats gives both sides the same numbers).
	R reloads; an empty magazine reloads by itself (the server starts it).
	Right-click zooms if the gun has a scope. F uses the hero's ability.

	CAMERA: everyone is in first person all the time, so nobody gets a
	third-person view advantage in PvP (VISION.md). The one exception is placing
	a tower: the camera pulls back to third person so the ghost lands where you
	mean, then snaps back when you place or cancel. Open panels free the mouse
	(Shop.client makes them Modal) without leaving first person.

	The crosshair opens up with the same recoil the server applies, so what you
	see is the cone your shots land in. Every shot is only a request carrying
	the camera ray: the server checks rate, ammo, recoil and range and decides
	what gets hit, then echoes hits back for the hit marker.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local HeroStats = require(Shared:WaitForChild("HeroStats"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local heroRequest = remotes:WaitForChild("HeroRequest") :: RemoteFunction
local heroFire = remotes:WaitForChild("HeroFire") :: RemoteEvent

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- Visuals only.
local TEXT = Color3.fromRGB(240, 236, 250)
local READY = Color3.fromRGB(200, 90, 110)
local WAITING = Color3.fromRGB(70, 66, 82)
local KILL = Color3.fromRGB(255, 80, 90)
local CROSSHAIR_MIN_GAP = 4 -- px
local THIRD_PERSON_ZOOM = 12 -- studs; where the camera lands when leaving first person
local SCOPE_FOV = 30
local SPIN_KEEP = 0.35 -- must match Server/Hero: pulls closer than this keep spinning

------------------------------------------------------------------ the gun right now

local function heroKey(): string?
	local key = player:GetAttribute("Hero")
	return if typeof(key) == "string" and Config.Heroes[key] then key else nil
end

local function currentStats(): HeroStats.Stats?
	local key = heroKey()
	if not key then
		return nil
	end
	local tiers = {}
	for i = 1, 3 do
		tiers[i] = player:GetAttribute(`HeroPath{i}`) or 0
	end
	return HeroStats.compute(key, tiers)
end

local function equippedGun(): Tool?
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	return if tool and tool:GetAttribute("HeroWeapon") then tool else nil
end

local function reloading(): boolean
	return (player:GetAttribute("ReloadUntil") or 0) > workspace:GetServerTimeNow()
end

local function overdriveOn(): boolean
	return (player:GetAttribute("OverdriveUntil") or 0) > workspace:GetServerTimeNow()
end

-- The camera ray through the crosshair (first person) or the mouse (third).
local function aimRay(): (Vector3, Vector3)
	local ray = mouse.UnitRay
	return ray.Origin, ray.Direction
end

------------------------------------------------------------------ HUD

local gui = Instance.new("ScreenGui")
gui.Name = "StormSplitHero"
gui.ResetOnSpawn = false

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

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
corner(abilityButton, 8)

local ammoLabel = Instance.new("TextLabel")
ammoLabel.Name = "Ammo"
ammoLabel.AnchorPoint = Vector2.new(1, 1)
ammoLabel.Position = UDim2.new(1, -176, 1, -24)
ammoLabel.Size = UDim2.fromOffset(160, 48)
ammoLabel.BackgroundTransparency = 1
ammoLabel.Font = Enum.Font.GothamBold
ammoLabel.TextSize = 26
ammoLabel.TextColor3 = TEXT
ammoLabel.TextStrokeTransparency = 0.5
ammoLabel.TextXAlignment = Enum.TextXAlignment.Right
ammoLabel.Visible = false
ammoLabel.Parent = gui

local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.AnchorPoint = Vector2.new(1, 1)
toast.Position = UDim2.new(1, -24, 1, -192)
toast.Size = UDim2.fromOffset(280, 24)
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

------------------------------------------------------------------ crosshair

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

local markerToken = 0
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

-- Local copy of the server's recoil (bloom) so the crosshair shows the real cone.
local bloom, bloomAt = 0, 0

local function currentBloom(stats: HeroStats.Stats): number
	return math.max(0, bloom - stats.recoilRecovery * (os.clock() - bloomAt))
end

local function addRecoil(stats: HeroStats.Stats)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local speed = if root and root:IsA("BasePart") then root.AssemblyLinearVelocity.Magnitude else 0
	local recoil = stats.recoilPerShot * stats.shotsPerTrigger * (if speed < Config.Tuning.StillSpeed then stats.stillRecoilMult else 1)
	bloom = math.min(stats.recoilMax, currentBloom(stats) + recoil)
	bloomAt = os.clock()
end

------------------------------------------------------------------ camera

local inFirstPerson: boolean? = nil
local defaultMinZoom = player.CameraMinZoomDistance
local defaultFov = camera.FieldOfView
local scoped = false

local function setScope(on: boolean)
	scoped = on
	camera.FieldOfView = if on then SCOPE_FOV else defaultFov
end

local function applyCamera()
	local wantFirst = player:GetAttribute("Placing") ~= true
	local panelOpen = player:GetAttribute("PanelOpen") == true
	-- Crosshair only when the gun is up and the mouse is locked to it.
	crosshair.Visible = wantFirst and not panelOpen and equippedGun() ~= nil
	UserInputService.MouseIconEnabled = not wantFirst or panelOpen
	if wantFirst == inFirstPerson then
		return
	end
	inFirstPerson = wantFirst
	if wantFirst then
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	else
		setScope(false)
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

player:GetAttributeChangedSignal("Placing"):Connect(applyCamera)
player:GetAttributeChangedSignal("PanelOpen"):Connect(applyCamera)
player.CharacterAdded:Connect(function()
	task.defer(applyCamera)
end)
applyCamera()

------------------------------------------------------------------ trigger

local holding = false
local firing = false
local lastPull = 0
local spinTime = 0
local hooked: { [Tool]: boolean } = {}

-- Seconds between trigger pulls right now (mirrors Server/Hero's rate check).
local function pullGap(stats: HeroStats.Stats): number
	local spin = 1 + (stats.spinUp - 1) * math.min(1, spinTime / Config.Tuning.SpinUpTime)
	local rate = stats.rate * stats.guns * spin * (if overdriveOn() then Config.Tuning.OverdriveFireRateX else 1)
	return 1 / rate
end

-- One trigger pull if the gun is ready. Returns "fired", "wait" (not ready
-- yet) or "empty" (reloading or out of rounds).
local function pull(stats: HeroStats.Stats): string
	if reloading() or (player:GetAttribute("Ammo") or 0) <= 0 then
		return "empty"
	end
	local now = os.clock()
	if now - lastPull < pullGap(stats) then
		return "wait"
	end
	spinTime = if now - lastPull <= SPIN_KEEP then spinTime + (now - lastPull) else 0
	lastPull = now
	heroFire:FireServer(aimRay())
	addRecoil(stats)
	return "fired"
end

local function fireLoop(tool: Tool)
	if firing then
		return
	end
	firing = true
	local stats = currentStats()
	if stats and stats.fireMode == "burst" then
		local fired = 0
		while fired < stats.burstCount and tool.Parent == player.Character do
			local result = pull(stats)
			if result == "empty" then
				break
			elseif result == "fired" then
				fired += 1
			end
			task.wait()
		end
	elseif stats and stats.fireMode == "auto" then
		while holding and tool.Parent == player.Character do
			stats = currentStats()
			if not stats or pull(stats) == "empty" then
				break
			end
			task.wait()
		end
	elseif stats then
		pull(stats)
	end
	firing = false
end

local function hook(tool: Instance)
	if not tool:IsA("Tool") or hooked[tool] or not tool:GetAttribute("HeroWeapon") then
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

------------------------------------------------------------------ reload, ability, scope

local function request(action: string, a: any?, b: any?)
	local ok, _, text = pcall(function()
		return heroRequest:InvokeServer(action, a, b)
	end)
	showToast(if ok then tostring(text) else "Couldn't reach the server")
end

local function useAbility()
	if not equippedGun() then
		return
	end
	local origin, direction = aimRay()
	request("ability", origin, direction)
end

abilityButton.Activated:Connect(useAbility)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F then
		useAbility()
	elseif input.KeyCode == Enum.KeyCode.R and equippedGun() then
		request("reload")
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 and inFirstPerson then
		local stats = currentStats()
		if stats and stats.scope then
			setScope(true)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 and scoped then
		setScope(false)
	end
end)

------------------------------------------------------------------ every frame

local hintShown = false

RunService.RenderStepped:Connect(function()
	local stats = currentStats()
	local gun = equippedGun()

	if not stats then
		abilityButton.Visible = false
		ammoLabel.Visible = false
		if not hintShown and ReplicatedStorage:GetAttribute("State") ~= nil then
			hintShown = true
			showToast("Press H to choose your hero (free)")
		end
		return
	end

	-- Crosshair gap from the real cone: spread + recoil, degrees -> pixels.
	local degrees = stats.spread + currentBloom(stats)
	local gap = CROSSHAIR_MIN_GAP + degrees * camera.ViewportSize.Y / camera.FieldOfView
	bars[1].Position = UDim2.fromOffset(0, -gap - 4)
	bars[2].Position = UDim2.fromOffset(0, gap + 4)
	bars[3].Position = UDim2.fromOffset(-gap - 4, 0)
	bars[4].Position = UDim2.fromOffset(gap + 4, 0)

	ammoLabel.Visible = gun ~= nil
	ammoLabel.Text = if reloading()
		then "Reloading…"
		else `{player:GetAttribute("Ammo") or 0} / {player:GetAttribute("Magazine") or 0}`

	local hero = Config.Heroes[heroKey() or ""]
	abilityButton.Visible = gun ~= nil and hero ~= nil
	if hero then
		local remaining = (player:GetAttribute("AbilityReadyAt") or 0) - workspace:GetServerTimeNow()
		abilityButton.Text = if remaining > 0 then `{hero.ability}  {math.ceil(remaining)}s` else `{hero.ability}  (F)`
		abilityButton.BackgroundColor3 = if remaining > 0 then WAITING else READY
	end
end)

gui.Parent = player:WaitForChild("PlayerGui")
