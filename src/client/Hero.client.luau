--[[
	The hero's gun on the client (HEROES.md).

	TRIGGER: semi fires once per click, auto keeps firing while held, burst
	fires `burstCount` rounds per click. Dual guns and Spin-Up fire faster, as
	the server allows (Shared/HeroStats gives both sides the same numbers).
	R reloads; an empty magazine reloads by itself (the server starts it).
	Right-click zooms if the gun has a scope. F uses the hero's ability.
	V swings the hunter's melee (PLAN 10b T136; free, short reach): the server checks reach,
	arc, swing time and line of sight (Server/Kit) and echoes hits for the hit marker.
	C throws the hunter's grenade (T137) along the camera on a fixed arc; the server owns the
	throw (charges, range, landing, splash). Both indicators sit left of the ability button.

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
local GunRules = require(Shared:WaitForChild("GunRules"))
local HunterKit = require(Shared:WaitForChild("HunterKit"))
local Grenade = require(Shared:WaitForChild("Grenade"))
local Cosmetics = require(Shared:WaitForChild("Cosmetics"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local heroRequest = remotes:WaitForChild("HeroRequest") :: RemoteFunction
local heroFire = remotes:WaitForChild("HeroFire") :: RemoteEvent
local heroKit = remotes:WaitForChild("HeroKit") :: RemoteEvent

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
	local tiers, picks = {}, {}
	for i = 1, 3 do
		tiers[i] = player:GetAttribute(`HeroPath{i}`) or 0
		picks[i] = player:GetAttribute(`HeroPicks{i}`) or ""
	end
	-- Outfitter buffs and mastery perks agree with the server.
	local mastery = player:GetAttribute(`Mastery_{key}`)
	return HeroStats.compute(key, tiers, HeroStats.gearOf(player), if typeof(mastery) == "number" then mastery else 0, picks)
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

-- The melee's cooldown indicator, left of the ability button (also a touch button).
local meleeButton = abilityButton:Clone()
meleeButton.Name = "Melee"
meleeButton.Position = UDim2.new(1, -176, 1, -136)
meleeButton.Size = UDim2.fromOffset(124, 48)
meleeButton.TextSize = 14
meleeButton.TextWrapped = true
meleeButton.Parent = gui

-- The grenade's charges and recharge, left of the melee (also a touch button).
local grenadeButton = meleeButton:Clone()
grenadeButton.Name = "Grenade"
grenadeButton.Position = UDim2.new(1, -308, 1, -136)
grenadeButton.Parent = gui

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

-- What this hunter wears (PLAN T57, Shared/Cosmetics): the crosshair's colour, the
-- hit-marker's glyph and plain-hit colour. A take-down keeps KILL so the two read apart.
local function wornSlot(slot: string): Cosmetics.Item?
	return Cosmetics.worn(function(name)
		return player:GetAttribute(name)
	end, slot)
end
local hitColour = TEXT
local function dressCrosshair()
	local colour = Cosmetics.crosshairColour(wornSlot, TEXT)
	for _, bar in bars do
		bar.BackgroundColor3 = colour
	end
	local glyph, colourOfHit = Cosmetics.hitMarker(wornSlot, TEXT)
	hitMarker.Text = glyph
	hitColour = colourOfHit
end
player.AttributeChanged:Connect(function(name)
	if string.sub(name, 1, 6) == "Equip_" then
		dressCrosshair()
	end
end)
dressCrosshair()

local markerToken = 0
local function showHit(killed: boolean)
	markerToken += 1
	local token = markerToken
	hitMarker.TextColor3 = if killed then KILL else hitColour
	hitMarker.Visible = true
	task.delay(if killed then 0.2 else 0.1, function()
		if markerToken == token then
			hitMarker.Visible = false
		end
	end)
end
heroFire.OnClientEvent:Connect(showHit)
heroKit.OnClientEvent:Connect(function(kind: unknown, killed: unknown)
	if kind == "hit" then
		showHit(killed == true)
	end
end)

-- Local copy of the server's recoil (bloom) so the crosshair shows the real cone.
local bloom, bloomAt = 0, 0

local function currentBloom(stats: HeroStats.Stats): number
	return math.max(0, bloom - stats.recoilRecovery * (os.clock() - bloomAt))
end

local function standingStill(): boolean
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local speed = if root and root:IsA("BasePart") then root.AssemblyLinearVelocity.Magnitude else 0
	return speed < Config.Tuning.StillSpeed
end

local function addRecoil(stats: HeroStats.Stats)
	local recoil = stats.recoilPerShot * stats.shotsPerTrigger * (if standingStill() then stats.stillRecoilMult else 1)
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

-- The mouse is free (a Modal button is showing) while a panel is open, during
-- the build phase (Start, difficulty, Choose hero), and for anyone who still
-- has to pick a hero. Must match the Modal buttons in Shop.client and Hud.client.
local function mouseFree(): boolean
	return player:GetAttribute("PanelOpen") == true
		or ReplicatedStorage:GetAttribute("State") ~= "Playing"
		or heroKey() == nil
end

local function applyCamera()
	-- First person always, except while placing a tower and in the Hunters' Outpost (T138,
	-- #383: no combat there, so you may see yourself).
	local wantFirst = player:GetAttribute("Placing") ~= true and player:GetAttribute("InOutpost") ~= true
	local free = mouseFree()
	-- Crosshair only when the gun is up and the mouse is locked to it;
	-- otherwise show the normal cursor.
	crosshair.Visible = wantFirst and not free and equippedGun() ~= nil
	UserInputService.MouseIconEnabled = not wantFirst or free
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
player:GetAttributeChangedSignal("InOutpost"):Connect(applyCamera)
player:GetAttributeChangedSignal("PanelOpen"):Connect(applyCamera)
player:GetAttributeChangedSignal("Hero"):Connect(applyCamera)
ReplicatedStorage:GetAttributeChangedSignal("State"):Connect(applyCamera)
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
	local origin, direction = aimRay()
	heroFire:FireServer(origin, direction, scoped)
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
		if stats.burstRecoilReset then
			bloom = 0 -- Big Five: each burst starts steady (the server agrees)
		end
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

-- Melee (T136): what the swing looks like in your own first-person view (each hunter's
-- item; visuals only), then the request. The server decides what it hits.
local MELEE_LOOK = { -- size, colour, material
	PISTOL = { Vector3.new(0.12, 0.2, 1.3), Color3.fromRGB(205, 210, 215), Enum.Material.Metal }, -- Hunting Knife
	RIFLE = { Vector3.new(0.35, 0.55, 1.5), Color3.fromRGB(120, 78, 44), Enum.Material.Wood }, -- Stock Swing
	SHOTGUN = { Vector3.new(0.1, 0.45, 2.1), Color3.fromRGB(150, 160, 140), Enum.Material.Metal }, -- Brush Machete
	MEDIC = { Vector3.new(0.22, 0.22, 1.6), Color3.fromRGB(225, 205, 160), Enum.Material.Wood }, -- Splint Stick
}
local MELEE_SWEEP = 0.15 -- s the item sweeps across the view
local function swingLook(key: string)
	local look = MELEE_LOOK[key]
	if not look then
		return
	end
	local item = Instance.new("Part")
	item.Anchored, item.CanCollide, item.CanQuery, item.CanTouch, item.CastShadow = true, false, false, false, false
	item.Size, item.Color, item.Material = look[1], look[2], look[3]
	item.Parent = camera
	local started = os.clock()
	local step
	step = RunService.RenderStepped:Connect(function()
		local t = (os.clock() - started) / MELEE_SWEEP
		if t >= 1 then
			step:Disconnect()
			item:Destroy()
			return
		end
		item.CFrame = camera.CFrame * CFrame.new(0.9 - 1.6 * t, -0.7, -2.2) * CFrame.Angles(0, math.rad(50 - 100 * t), math.rad(-30))
	end)
end

local function useMelee()
	local key = heroKey()
	local row = HunterKit.row(key)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not key or not row or not humanoid or humanoid.Health <= 0 then
		return
	end
	if player:GetAttribute("PanelOpen") == true or player:GetAttribute("Placing") == true then
		return
	end
	if (player:GetAttribute("MeleeReadyAt") or 0) > workspace:GetServerTimeNow() then
		return
	end
	swingLook(key)
	local origin, direction = aimRay()
	heroKit:FireServer("melee", origin, direction)
end

meleeButton.Activated:Connect(useMelee)

-- Grenade (T137): only a request; the server's ball is what everyone sees.
local function grenadeCharges(row: any): number
	return Grenade.charges(player:GetAttribute("GrenadeFullAt") or 0, workspace:GetServerTimeNow(), row)
end

local function useGrenade()
	local row = HunterKit.row(heroKey())
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not row or not humanoid or humanoid.Health <= 0 then
		return
	end
	if player:GetAttribute("PanelOpen") == true or player:GetAttribute("Placing") == true then
		return
	end
	if grenadeCharges(row) <= 0 then
		return
	end
	local origin, direction = aimRay()
	heroKit:FireServer("grenade", origin, direction)
end

grenadeButton.Activated:Connect(useGrenade)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F then
		useAbility()
	elseif input.KeyCode == Enum.KeyCode.V then
		useMelee()
	elseif input.KeyCode == Enum.KeyCode.C then
		useGrenade()
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
		meleeButton.Visible = false
		grenadeButton.Visible = false
		ammoLabel.Visible = false
		if not hintShown and ReplicatedStorage:GetAttribute("State") ~= nil then
			hintShown = true
			showToast("Press H to choose your hero (free)")
		end
		return
	end

	-- Crosshair gap from the real cone: spread + recoil, degrees -> pixels.
	local degrees = GunRules.cone(stats, currentBloom(stats), standingStill(), scoped)
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
		local charges, maxCharges = player:GetAttribute("AbilityCharges") or 1, player:GetAttribute("AbilityMaxCharges") or 1
		local stock = if maxCharges > 1 then `  x{charges}` else ""
		abilityButton.Text = if remaining > 0 then `{hero.ability}  {math.ceil(remaining)}s` else `{hero.ability}{stock}  (F)`
		abilityButton.BackgroundColor3 = if remaining > 0 then WAITING else READY
	end
	local kit = HunterKit.row(heroKey())
	meleeButton.Visible = gun ~= nil and kit ~= nil
	if kit then
		local cooling = (player:GetAttribute("MeleeReadyAt") or 0) > workspace:GetServerTimeNow()
		meleeButton.Text = `{kit.meleeName}  (V)`
		meleeButton.BackgroundColor3 = if cooling then WAITING else READY
	end
	grenadeButton.Visible = meleeButton.Visible
	if kit then
		local charges = grenadeCharges(kit)
		local wait = Grenade.readyAt(player:GetAttribute("GrenadeFullAt") or 0, workspace:GetServerTimeNow(), kit) - workspace:GetServerTimeNow()
		grenadeButton.Text = if charges > 0
			then `{kit.grenadeName}{if kit.charges > 1 then ` x{charges}` else ""}  (C)`
			else `{kit.grenadeName}  {math.ceil(wait)}s`
		grenadeButton.BackgroundColor3 = if charges > 0 then READY else WAITING
	end
end)

gui.Parent = player:WaitForChild("PlayerGui")
