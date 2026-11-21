--[[
	Premium skin effects on this screen (PREMIUM_SKINS.md, DECISIONS #459 tiers; rules in
	Shared/SkinFx). Looks only: nothing here is sent anywhere, and nothing is created by the server.

	Every RESCAN seconds it finds the premium art in view of this client, from what the runtime
	already stamps (no new replication):
	  hunters  a character's HunterBody model (`HunterKey` = the worn body/variant key)
	  guns     a held Tool's GunArt pieces + the first-person Viewmodel's (`ArtKey` = <HERO>_<SKIN>)
	  towers   the map's towers wearing a set (`SkinSet`, TowerLook) - stage from `Stage`
	Unknown keys (every basic skin, and everything while the premium rows aren't in the sheet) are
	skipped: today's look, untouched.

	One Heartbeat loop: within FX_DISTANCE of the camera it recolours each target's `glow` pieces
	(pulse / flow by tier). Emitters are made once per target (tier >= 2), at most
	TOWER_EMITTER_CAP towers on (nearest first), none on your own hunter in first person, none on
	low graphics; tier 3 adds the aura, a light, a short trail and an idle flare.
	Studio-only aid: ReplicatedStorage attribute `SkinFxTier` (0..4) forces a tier to compare.

	Tier 4, the pack layer (#462; params per theme element in Shared/SkinFx.ELEMENTS): when the
	wearer owns the item's whole class pack (player attribute `SkinFxPacks`, published by the store
	wiring later; Studio: `SkinFxTier` = 4):
	  hunter   an element aura round the torso (an emitter on the R15 UpperTorso), footstep marks
	           (a glowing flat disc that cools and fades; <= MARK_CAP on screen), a take-down burst
	           (player attribute `SkinFxTakedownAt`, stamped by the server on a take-down)
	  weapon   heat per player from the replicated `Ammo` attribute (a drop = shots): the gun's
	           `glow` goes cool -> white-hot, a muzzle burst when hot, a puff when it cools or a
	           reload starts (`ReloadUntil`); your own heat shows on the first-person viewmodel
	  grenade  a thrown grenade stamped `SkinFxGrenade` + `SkinFxOwner` by the server: a trail and
	           embers in flight, a short splash (disc + burst) where it lands; <= SPLASH_CAP
	All within PACK_DISTANCE, none on low graphics; your own aura / take-down burst off in first
	person (the burst shows on the viewmodel instead). Nothing is sent anywhere.
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SkinFx = require(Shared:WaitForChild("SkinFx"))
local HunterBody = require(Shared:WaitForChild("HunterBody"))
local GunArt = require(Shared:WaitForChild("GunArt"))
local Config = require(Shared:WaitForChild("Config"))

local RESCAN = 0.75
local FX_TAG = "SkinFxObject" -- every instance this script adds carries this attribute
local IS_STUDIO = RunService:IsStudio()

type Target = {
	root: Instance,
	where: string, -- "hunter" | "weapon" | "tower"
	key: string,
	theme: SkinFx.Theme,
	tier: number,
	glow: { BasePart },
	phases: { number },
	authored: { Color3 },
	anchor: BasePart?,
	made: { Instance },
	emitters: { ParticleEmitter },
	light: PointLight?,
	own: boolean,
	stage: number,
	flareAt: number,
	player: Player?, -- whose (the wearer / holder / viewmodel = you)
	element: SkinFx.Element?, -- the theme's element (tier 4's pack layer)
	burst: ParticleEmitter?, -- tier 4: take-down burst (hunter) / muzzle burst (weapon), Emit only
	puff: ParticleEmitter?, -- tier 4 weapon: the cooling puff
	muzzle: BasePart?, -- tier 4 weapon: the art's muzzle piece
	lastPos: Vector3?, -- tier 4 hunter: footstep tracking
	walked: number,
}

local targets: { [Instance]: Target } = {}
local firstPerson = false

-- Client-only things the pack layer drops in the world (marks, splashes): one local folder.
local fxFolder = Instance.new("Folder")
fxFolder.Name = "SkinFxClient"
fxFolder.Parent = workspace

local function packsOf(player: Player?): { [string]: boolean }?
	return if player then SkinFx.parsePacks(player:GetAttribute(SkinFx.PACKS_ATTRIBUTE)) else nil
end

local function lowGraphics(): boolean
	local ok, level = pcall(function()
		return UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value
	end)
	return ok and type(level) == "number" and level > 0 and level <= 3
end

local function overrideTier(): number?
	local v = ReplicatedStorage:GetAttribute(SkinFx.OVERRIDE_ATTRIBUTE)
	return if IS_STUDIO and type(v) == "number" then v else nil
end

local function mark(inst: Instance): Instance
	inst:SetAttribute(FX_TAG, true)
	return inst
end

local function emitter(spec: SkinFx.Emitter, parent: Instance, name: string): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.Rate = spec.rate
	e.Lifetime = NumberRange.new(spec.lifetime[1], spec.lifetime[2])
	e.Speed = NumberRange.new(spec.speed[1], spec.speed[2])
	e.Size = NumberSequence.new(spec.size[1], spec.size[2])
	e.SpreadAngle = Vector2.new(spec.spread, spec.spread)
	e.Color = ColorSequence.new(spec.colour[1], spec.colour[2])
	e.LightEmission = spec.lightEmission
	e.Acceleration = Vector3.new(0, spec.rise, 0)
	e.Transparency = NumberSequence.new(0.1, 1)
	e.EmissionDirection = Enum.NormalId.Top
	e.LightInfluence = 0
	e.Parent = parent
	return mark(e) :: ParticleEmitter
end

-- An Emit-only emitter (Rate 0) for bursts.
local function burster(spec: { count: number, colour: { Color3 }, size: number, speed: number }, parent: Instance, name: string, rise: number): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.Rate = 0
	e.Lifetime = NumberRange.new(0.35, 0.8)
	e.Speed = NumberRange.new(spec.speed * 0.5, spec.speed)
	e.Size = NumberSequence.new(spec.size, 0)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Color = ColorSequence.new(spec.colour[1], spec.colour[2])
	e.LightEmission = 0.7
	e.LightInfluence = 0
	e.Acceleration = Vector3.new(0, rise, 0)
	e.Drag = 3
	e.Transparency = NumberSequence.new(0, 1)
	e.Parent = parent
	return mark(e) :: ParticleEmitter
end

local function clear(t: Target)
	for _, inst in t.made do
		inst:Destroy()
	end
	t.made, t.emitters, t.light, t.burst, t.puff = {}, {}, nil, nil, nil
	for i, part in t.glow do -- back to the authored glow
		if part.Parent then
			part.Color = t.authored[i]
		end
	end
end

local function biggest(parts: { BasePart }): BasePart?
	local best, size = nil, -1
	for _, p in parts do
		local v = p.Size.X * p.Size.Y * p.Size.Z
		if v > size then
			best, size = p, v
		end
	end
	return best
end

local function partsIn(root: Instance): { BasePart }
	local out = {}
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") and not d:GetAttribute(FX_TAG) then
			table.insert(out, d)
		end
	end
	return out
end

-- The effects a target's tier asks for (re-made when the tier or a tower's stage changes).
local function dress(t: Target)
	clear(t)
	local anchor = t.anchor
	if not anchor or t.tier < 2 or lowGraphics() then
		return
	end
	local at = mark(Instance.new("Attachment")) :: Attachment
	at.Name = "SkinFxAt"
	at.Parent = anchor
	table.insert(t.made, at)
	local embers = SkinFx.embers(t.theme, t.tier, t.where, t.stage)
	if embers then
		table.insert(t.emitters, emitter(embers, at, "SkinFxEmbers"))
	end
	local aura = SkinFx.aura(t.theme, t.tier, t.where, t.stage)
	if aura then
		-- low and round the feet / the tower's base: from the lowest glow piece
		local low = anchor
		for _, p in t.glow do
			if p.Position.Y < low.Position.Y then
				low = p
			end
		end
		local foot = mark(Instance.new("Attachment")) :: Attachment
		foot.Name = "SkinFxAura"
		foot.Position = Vector3.new(0, -low.Size.Y / 2, 0)
		foot.Parent = low
		table.insert(t.made, foot)
		table.insert(t.emitters, emitter(aura, foot, "SkinFxAura"))
	end
	local brightness, _, range = SkinFx.light(t.tier, t.where, t.stage)
	if brightness and range then
		local light = mark(Instance.new("PointLight")) :: PointLight
		light.Color = t.theme.glow
		light.Brightness = brightness
		light.Range = range
		light.Shadows = false
		light.Parent = anchor
		t.light = light
		table.insert(t.made, light)
	end
	if t.tier >= 3 and t.where == "hunter" then -- a short trail behind a moving hunter
		local a0 = mark(Instance.new("Attachment")) :: Attachment
		local a1 = mark(Instance.new("Attachment")) :: Attachment
		a0.Position, a1.Position = Vector3.new(0, 0.4, 0), Vector3.new(0, -0.4, 0)
		a0.Parent, a1.Parent = anchor, anchor
		local trail = mark(Instance.new("Trail")) :: Trail
		trail.Attachment0, trail.Attachment1 = a0, a1
		trail.Color = ColorSequence.new(t.theme.glow, t.theme.deep)
		trail.Transparency = NumberSequence.new(0.45, 1)
		trail.Lifetime = 0.3
		trail.MinLength = 0.3
		trail.LightEmission = 0.8
		trail.FaceCamera = true
		trail.Parent = anchor
		table.insert(t.made, a0)
		table.insert(t.made, a1)
		table.insert(t.made, trail)
	end
	local element = t.element
	if t.tier >= SkinFx.PACK_TIER and element then
		if t.where == "hunter" then
			local character = t.root.Parent
			local torso = character and character:FindFirstChild("UpperTorso")
			local host = if torso and torso:IsA("BasePart") then torso else anchor
			local packAura = SkinFx.packAura(element, t.tier)
			if packAura then -- emitted from the torso part's box: flames round the body
				local e = emitter(packAura, host, "SkinFxPackAura")
				e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(0.6, 0.5), NumberSequenceKeypoint.new(1, 1) })
				if element.behaviour == "flicker" then
					e.RotSpeed = NumberRange.new(-90, 90)
					e.Rotation = NumberRange.new(0, 360)
				end
				table.insert(t.emitters, e)
			end
			local burst = burster(element.takedown, host, "SkinFxTakedown", 3)
			t.burst = burst
			table.insert(t.made, burst)
		elseif t.where == "weapon" then
			local muzzle: BasePart? = nil
			for _, p in partsIn(t.root) do
				if p:GetAttribute("ArtRole") == "muzzle" then
					muzzle = p
				end
			end
			t.muzzle = muzzle
			local burst = burster(element.muzzle, muzzle or anchor, "SkinFxMuzzle", 2)
			local puff = burster(element.puff, anchor, "SkinFxPuff", 2.5)
			t.burst, t.puff = burst, puff
			table.insert(t.made, burst)
			table.insert(t.made, puff)
		end
	end
end

local function makeTarget(root: Instance, where: string, key: string, item: SkinFx.Item, pieces: { BasePart }, own: boolean, stage: number, player: Player?): Target?
	local theme = SkinFx.THEMES[item.theme]
	if not theme then
		return nil
	end
	local glow: { BasePart } = {}
	for _, p in pieces do
		if p:GetAttribute("PaintGroup") == "glow" then
			table.insert(glow, p)
		end
	end
	if #glow == 0 then
		return nil
	end
	local base = math.huge
	for _, p in glow do
		base = math.min(base, p.Position.Y)
	end
	local phases, authored = {}, {}
	for i, p in glow do
		phases[i] = SkinFx.phase(p.Position.Y - base, theme)
		authored[i] = p.Color
	end
	local t: Target = {
		root = root, where = where, key = key, theme = theme,
		tier = SkinFx.tier(key, overrideTier(), IS_STUDIO, packsOf(player)),
		glow = glow, phases = phases, authored = authored,
		anchor = biggest(glow), made = {}, emitters = {}, light = nil,
		own = own, stage = stage, flareAt = os.clock() + math.random() * SkinFx.IDLE_FLARE_SECONDS,
		player = player, element = SkinFx.element(item.theme), walked = 0,
	}
	dress(t)
	return t
end

-- What should be animated now: root -> (where, key, item, own, stage).
local function scan(): { [Instance]: { any } }
	local found = {}
	local me = Players.LocalPlayer
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character then
			local body = character:FindFirstChild(HunterBody.FOLDER)
			local key, item = SkinFx.fromArt("hunter", body and body:GetAttribute("HunterKey"))
			if body and key and item then
				found[body] = { "hunter", key, item, player == me, 0, player }
			end
			local tool = character:FindFirstChildOfClass("Tool")
			local gun = tool and tool:FindFirstChild(GunArt.FOLDER)
			if gun then
				local first = gun:FindFirstChildWhichIsA("BasePart")
				local gkey, gitem = SkinFx.fromArt("weapon", first and first:GetAttribute("ArtKey"))
				if gkey and gitem then
					found[gun] = { "weapon", gkey, gitem, player == me, 0, player }
				end
			end
		end
	end
	local camera = workspace.CurrentCamera
	for _, child in (camera and camera:GetChildren() or {}) do -- the first-person viewmodel's gun copies
		if child:IsA("Model") then
			for _, d in child:GetDescendants() do
				local gkey, gitem = SkinFx.fromArt("weapon", d:GetAttribute("ArtKey"))
				if gkey and gitem then
					found[child] = { "weapon", gkey, gitem, false, 0, me }
					break
				end
			end
		end
	end
	local map = workspace:FindFirstChild("StormSplitMap")
	local towers = map and map:FindFirstChild("Towers")
	for _, model in (towers and towers:GetChildren() or {}) do
		local key, item = SkinFx.fromArt("tower", model:GetAttribute("SkinSet"))
		if key and item then
			local stage = model:GetAttribute("Stage")
			found[model] = { "tower", key, item, false, if type(stage) == "number" then stage else 0 }
		end
	end
	return found
end

local function rescan()
	local found = scan()
	local tier = overrideTier()
	for root, t in targets do
		local f = found[root]
		if not f or f[2] ~= t.key or not root.Parent then
			clear(t)
			targets[root] = nil
		elseif f[5] ~= t.stage or SkinFx.tier(t.key, tier, IS_STUDIO, packsOf(t.player)) ~= t.tier or not (t.glow[1] and t.glow[1].Parent) then
			clear(t)
			targets[root] = nil -- remade below (stage or tier changed)
		end
	end
	for root, f in found do
		if not targets[root] then
			local t = makeTarget(root, f[1], f[2], f[3], partsIn(root), f[4], f[5], f[6])
			if t then
				targets[root] = t
			end
		end
	end
	-- emitter budget: own hunter off in first person; towers nearest first, capped
	local camera = workspace.CurrentCamera
	local eye = camera and camera.CFrame.Position or Vector3.zero
	firstPerson = camera ~= nil and (camera.Focus.Position - eye).Magnitude < 1.5
	local towerList = {}
	for _, t in targets do
		local on = true
		if t.own and t.where == "hunter" and firstPerson then
			on = false
		end
		if t.where == "tower" and t.anchor then
			table.insert(towerList, { t = t, d = (t.anchor.Position - eye).Magnitude })
		end
		for _, e in t.emitters do
			e.Enabled = on
		end
	end
	table.sort(towerList, function(a, b)
		return a.d < b.d
	end)
	for i, entry in towerList do
		for _, e in entry.t.emitters do
			e.Enabled = i <= SkinFx.TOWER_EMITTER_CAP
		end
	end
end

------------------------------------------------------------------ tier 4: the pack layer (#462)

local function lowGraphicsNow(): boolean
	return lowGraphics()
end

local function near(pos: Vector3): boolean
	local camera = workspace.CurrentCamera
	return camera ~= nil and SkinFx.packVisible((pos - camera.CFrame.Position).Magnitude, lowGraphicsNow())
end

local function groundBelow(from: Vector3, ignore: { Instance }): RaycastResult?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = true
	return workspace:Raycast(from, Vector3.new(0, -6, 0), params)
end

-- Footstep marks: a flat disc that starts glowing (the element's rim colour, Neon) and cools to
-- its mark colour while it fades. One local pool, the oldest replaced past MARK_CAP.
local marks: { BasePart } = {}
local function dropMark(element: SkinFx.Element, at: Vector3, normal: Vector3)
	local m = element.mark
	while #marks >= SkinFx.MARK_CAP do
		local old = table.remove(marks, 1)
		if old then
			old:Destroy()
		end
	end
	local part = Instance.new("Part")
	part.Name = "SkinFxMark"
	part.Shape = Enum.PartType.Cylinder
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
	part.Material = Enum.Material.Neon
	part.Color = m.rim
	part.Size = Vector3.new(0.06, m.size, m.size * 0.8)
	part.CFrame = CFrame.lookAt(at + normal * 0.04, at + normal * 2) * CFrame.Angles(0, math.rad(90), 0)
	mark(part)
	part.Parent = fxFolder
	table.insert(marks, part)
	TweenService:Create(part, TweenInfo.new(m.lifetime * 0.35), { Color = m.colour }):Play()
	TweenService:Create(part, TweenInfo.new(m.lifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 }):Play()
	task.delay(m.lifetime, function()
		local i = table.find(marks, part)
		if i then
			table.remove(marks, i)
		end
		part:Destroy()
	end)
end

local function stepMarks(t: Target)
	local element, character = t.element, t.root.Parent
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not element or not root or not root:IsA("BasePart") then
		return
	end
	local pos = root.Position
	local last = t.lastPos
	t.lastPos = pos
	if not last then
		return
	end
	local flat = Vector3.new(pos.X - last.X, 0, pos.Z - last.Z).Magnitude
	if flat > 8 then -- a teleport / respawn, not a step
		t.walked = 0
		return
	end
	t.walked += flat
	if t.walked < element.mark.every or not near(pos) then
		return
	end
	local hit = groundBelow(pos, { character :: Instance, fxFolder })
	if SkinFx.markDue(element, t.walked, hit ~= nil) and hit then
		t.walked = 0
		dropMark(element, hit.Position, hit.Normal)
	end
end

-- Reactive weapon heat, per player (from the replicated `Ammo` / `ReloadUntil`).
type Heat = { heat: number, ammo: number?, reloading: boolean }
local heats: { [Player]: Heat } = {}
local demoShots = 0 -- Studio demo (`SkinFxDemo`): your stand-in gun's simulated shots

local function weaponTargets(player: Player): { Target }
	local out = {}
	for _, t in targets do
		if t.where == "weapon" and t.player == player and t.tier >= SkinFx.PACK_TIER and t.element then
			table.insert(out, t)
		end
	end
	return out
end

-- The gun's base shots a second (Config Heroes `rate`), for the heat per shot.
local function heroRate(itemKey: string): number?
	local item = SkinFx.item(itemKey)
	local row = item and item.hero and (Config.Heroes :: any)[item.hero]
	return if row and type(row.rate) == "number" then row.rate else nil
end

-- Where a gun burst shows: your viewmodel in first person, else the held gun.
local function shownGun(guns: { Target }, player: Player): Target?
	local me = Players.LocalPlayer
	for _, t in guns do
		local isViewmodel = t.root.Parent == workspace.CurrentCamera
		if player == me and firstPerson then
			if isViewmodel then
				return t
			end
		elseif not isViewmodel then
			return t
		end
	end
	return nil
end

local function stepHeat(dt: number)
	local now = workspace:GetServerTimeNow()
	local seen: { [Player]: boolean } = {}
	for _, t in targets do
		if t.where == "weapon" and t.player and t.tier >= SkinFx.PACK_TIER and t.element then
			seen[t.player :: Player] = true
		end
	end
	for player in heats do
		if not seen[player] then
			heats[player] = nil
		end
	end
	for player in seen do
		local guns = weaponTargets(player)
		local element = guns[1] and guns[1].element
		if element then
			local h = heats[player] or { heat = 0, ammo = nil, reloading = false }
			heats[player] = h
			local before = h.heat
			local ammo = player:GetAttribute("Ammo")
			local shots = if type(ammo) == "number" and type(h.ammo) == "number" and ammo < h.ammo then h.ammo - ammo else 0
			if player == Players.LocalPlayer and demoShots > 0 then
				shots += demoShots
				demoShots = 0
			end
			h.ammo = if type(ammo) == "number" then ammo else nil
			local reloadUntil = player:GetAttribute("ReloadUntil")
			local reloading = type(reloadUntil) == "number" and reloadUntil > now
			local reloadStarted = reloading and not h.reloading
			h.reloading = reloading
			local gun = shownGun(guns, player)
			local visible = gun ~= nil and gun.anchor ~= nil and near((gun.anchor :: BasePart).Position)
			if shots > 0 then
				h.heat = SkinFx.heatAfterShots(element, h.heat, shots, heroRate(guns[1].key))
				if visible and gun and gun.burst and SkinFx.muzzleBurst(element, h.heat) then
					(gun.burst :: ParticleEmitter):Emit(element.muzzle.count)
				end
			else
				h.heat = SkinFx.heatAfter(element, h.heat, dt)
			end
			if visible and gun and gun.puff and SkinFx.coolPuff(element, before, h.heat, reloadStarted) then
				(gun.puff :: ParticleEmitter):Emit(element.puff.count)
			end
		end
	end
end

-- A take-down: the wearer's burst (your own in first person: from the viewmodel gun).
local function takedown(player: Player)
	for _, t in targets do
		if t.where == "hunter" and t.player == player and t.tier >= SkinFx.PACK_TIER and t.element and t.burst then
			local element = t.element :: SkinFx.Element
			if player == Players.LocalPlayer and firstPerson then
				local gun = shownGun(weaponTargets(player), player)
				if gun and gun.burst then
					(gun.burst :: ParticleEmitter):Emit(element.takedown.count)
				end
			elseif t.anchor and near((t.anchor :: BasePart).Position) then
				(t.burst :: ParticleEmitter):Emit(element.takedown.count)
			end
		end
	end
end

local function watchPlayer(player: Player)
	player:GetAttributeChangedSignal(SkinFx.TAKEDOWN_ATTRIBUTE):Connect(function()
		local ok, err = pcall(takedown, player)
		if not ok then
			warn(`[SkinFx] {err}`)
		end
	end)
end
Players.PlayerAdded:Connect(watchPlayer)
for _, player in Players:GetPlayers() do
	watchPlayer(player)
end

-- Reactive grenades: the server stamps a thrown premium grenade (prop or today's ball) with the
-- worn skin + the thrower; a trail + embers ride it, a splash shows where it lands.
local splashes: { Instance } = {}

local function splash(element: SkinFx.Element, at: Vector3)
	if not near(at) then
		return
	end
	while #splashes >= SkinFx.SPLASH_CAP do
		local old = table.remove(splashes, 1)
		if old then
			old:Destroy()
		end
	end
	local s = element.splash
	local hit = groundBelow(at + Vector3.new(0, 1.5, 0), { fxFolder })
	local ground = if hit then hit.Position else at
	local disc = Instance.new("Part")
	disc.Name = "SkinFxSplash"
	disc.Shape = Enum.PartType.Cylinder
	disc.Anchored, disc.CanCollide, disc.CanQuery, disc.CanTouch, disc.CastShadow = true, false, false, false, false
	disc.Material = Enum.Material.Neon
	disc.Color = s.colour
	disc.Transparency = 0.15
	disc.Size = Vector3.new(0.08, s.radius * 0.6, s.radius * 0.6)
	disc.CFrame = CFrame.new(ground + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90))
	mark(disc)
	disc.Parent = fxFolder
	table.insert(splashes, disc)
	local burst = burster({ count = s.count, colour = { element.muzzle.colour[1], s.colour }, size = 0.45, speed = 12 }, disc, "SkinFxSplashBurst", -18)
	burst.EmissionDirection = Enum.NormalId.Right -- the disc's X is the ground normal (Cylinder)
	burst.SpreadAngle = Vector2.new(55, 55)
	burst:Emit(s.count)
	TweenService:Create(disc, TweenInfo.new(s.lifetime * 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(0.08, s.radius * 2, s.radius * 2) }):Play()
	TweenService:Create(disc, TweenInfo.new(s.lifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Transparency = 1, Color = element.heat.cool }):Play()
	Debris:AddItem(disc, s.lifetime + 0.8)
	task.delay(s.lifetime + 0.8, function()
		local i = table.find(splashes, disc)
		if i then
			table.remove(splashes, i)
		end
	end)
end

local function grenadeThrown(obj: Instance)
	local key = obj:GetAttribute(SkinFx.GRENADE_ATTRIBUTE)
	local item = SkinFx.item(key)
	if not item or item.kind ~= "grenade" then
		return
	end
	local owner = obj:GetAttribute(SkinFx.OWNER_ATTRIBUTE)
	local player = if type(owner) == "number" then Players:GetPlayerByUserId(owner) else nil
	local tier = SkinFx.tier(key, overrideTier(), IS_STUDIO, packsOf(player))
	local element = SkinFx.element(item.theme)
	if tier < SkinFx.PACK_TIER or not element or lowGraphics() then
		return
	end
	local part: BasePart? = if obj:IsA("BasePart") then obj else obj:FindFirstChildWhichIsA("BasePart", true)
	if not part then
		return
	end
	local tr = element.trail
	local a0 = mark(Instance.new("Attachment")) :: Attachment
	local a1 = mark(Instance.new("Attachment")) :: Attachment
	a0.Position, a1.Position = Vector3.new(0, tr.width / 2, 0), Vector3.new(0, -tr.width / 2, 0)
	a0.Parent, a1.Parent = part, part
	local trail = mark(Instance.new("Trail")) :: Trail
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Color = ColorSequence.new(tr.colour[1], tr.colour[2])
	trail.Transparency = NumberSequence.new(0.1, 1)
	trail.WidthScale = NumberSequence.new(1, 0.2)
	trail.Lifetime = tr.lifetime
	trail.LightEmission = 0.8
	trail.FaceCamera = true
	trail.Parent = part
	local embers = emitter({
		rate = tr.rate, lifetime = { 0.3, 0.6 }, speed = { 0.5, 1.5 }, size = { 0.3, 0 }, spread = 180,
		colour = tr.colour, lightEmission = 0.7, rise = 2,
	}, a0, "SkinFxGrenadeEmbers")
	embers.Parent = part
	local last = part.Position
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		if part.Parent and obj.Parent then
			last = part.Position
			return
		end
		conn:Disconnect()
		local ok, err = pcall(splash, element, last)
		if not ok then
			warn(`[SkinFx] {err}`)
		end
	end)
end

local function maybeGrenade(obj: Instance)
	if obj:GetAttribute(SkinFx.GRENADE_ATTRIBUTE) then
		grenadeThrown(obj)
	elseif obj:IsA("BasePart") or obj:IsA("Model") then
		-- attributes set right after parenting can land a frame later: look once more
		task.delay(0.05, function()
			if obj.Parent and obj:GetAttribute(SkinFx.GRENADE_ATTRIBUTE) then
				grenadeThrown(obj)
			end
		end)
	end
end
workspace.ChildAdded:Connect(maybeGrenade) -- grenade art props
local function watchEffects()
	local map = workspace:FindFirstChild("StormSplitMap")
	local effects = map and map:FindFirstChild("Effects")
	if effects then -- today's ball (no grenade art) lives in the map's effects folder
		effects.ChildAdded:Connect(maybeGrenade)
		return true
	end
	return false
end
if not watchEffects() then
	task.spawn(function()
		for _ = 1, 120 do
			task.wait(1)
			if watchEffects() then
				return
			end
		end
	end)
end

------------------------------------------------------------------ Studio demo (no art needed)
--[[
	Studio only: set ReplicatedStorage attribute `SkinFxDemo` = true (and `SkinFxTier` = 4) in Play
	and your character gets a blocky Magma Monarch stand-in + a blocky Lava Lance in front of it
	(local, glow pieces only), then every 8 s: 3 s of simulated fire (heat ramps to white-hot, muzzle
	bursts), a cooling puff, a thrown Lava Lob (trail + splash) and a take-down burst; walk to leave
	footstep marks. Clearing the attribute removes the stand-ins. Real effects code, fake art.
]]

local DEMO = "SkinFxDemo"
local demoParts: { Instance } = {}

local function demoClear()
	for _, inst in demoParts do
		inst:Destroy()
	end
	table.clear(demoParts)
end

local function demoBuild(): boolean
	local character = Players.LocalPlayer.Character
	local camera = workspace.CurrentCamera
	if not character or not camera or not character:FindFirstChild("UpperTorso") then
		return false
	end
	local OBS, LAVA = Color3.fromRGB(40, 34, 46), Color3.fromRGB(255, 112, 20)
	local body = Instance.new("Model")
	body.Name = HunterBody.FOLDER
	body:SetAttribute("HunterKey", "MAGMA_MONARCH")
	local function piece(partName: string, size: Vector3, offset: CFrame, glow: boolean)
		local host = character:FindFirstChild(partName)
		if not host or not host:IsA("BasePart") then
			return
		end
		local part = Instance.new("Part")
		part.Size, part.Color = size, if glow then LAVA else OBS
		part.Material = if glow then Enum.Material.Neon else Enum.Material.SmoothPlastic
		part.CanCollide, part.CanQuery, part.CanTouch, part.Massless = false, false, false, true
		part:SetAttribute("PaintGroup", if glow then "glow" else "plate")
		part.CFrame = host.CFrame * offset
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1 = host, part
		weld.Parent = part
		part.Parent = body
	end
	piece("UpperTorso", Vector3.new(2.1, 1.7, 1.15), CFrame.new(), false)
	piece("UpperTorso", Vector3.new(0.6, 0.6, 0.1), CFrame.new(0, 0.2, -0.6), true)
	piece("Head", Vector3.new(1.3, 0.5, 1.3), CFrame.new(0, 0.5, 0), false)
	piece("Head", Vector3.new(1.32, 0.1, 1.32), CFrame.new(0, 0.3, 0), true)
	for _, s in { -1, 1 } do
		local side = if s < 0 then "Left" else "Right"
		piece("Head", Vector3.new(0.25, 0.8, 0.25), CFrame.new(0.6 * s, 0.9, 0) * CFrame.Angles(0, 0, math.rad(-25 * s)), false)
		piece(side .. "UpperArm", Vector3.new(1.3, 0.4, 1.3), CFrame.new(0.1 * s, 0.55, 0), false)
		piece(side .. "UpperArm", Vector3.new(1.32, 0.08, 1.32), CFrame.new(0.1 * s, 0.32, 0), true)
		piece(side .. "LowerLeg", Vector3.new(1.05, 0.08, 1.05), CFrame.new(), true)
	end
	body.Parent = character
	table.insert(demoParts, body)
	-- the gun: under the camera (read as your viewmodel), welded by the right hand
	local hand = character:FindFirstChild("RightHand")
	local gun = Instance.new("Model")
	gun.Name = "SkinFxDemoGun"
	local function gp(size: Vector3, offset: CFrame, colour: Color3, group: string, role: string?)
		if not hand or not hand:IsA("BasePart") then
			return
		end
		local part = Instance.new("Part")
		part.CanCollide, part.CanQuery, part.CanTouch, part.Massless = false, false, false, true
		part.Size, part.Color = size, colour
		part.Material = if group == "glow" then Enum.Material.Neon else Enum.Material.SmoothPlastic
		part.CFrame = hand.CFrame * CFrame.new(0, -0.1, -0.9) * offset
		part:SetAttribute("ArtKey", "RIFLE_LAVA_LANCE")
		part:SetAttribute("PaintGroup", group)
		if role then
			part:SetAttribute("ArtRole", role)
		end
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1 = hand, part
		weld.Parent = part
		part.Parent = gun
	end
	gp(Vector3.new(0.25, 0.4, 2.4), CFrame.new(), Color3.fromRGB(28, 24, 30), "dark")
	for i = 0, 2 do
		gp(Vector3.new(0.28, 0.1, 0.18), CFrame.new(0, 0.05, -0.4 - i * 0.35), LAVA, "glow")
	end
	gp(Vector3.new(0.18, 0.18, 0.1), CFrame.new(0, 0.12, -1.3), Color3.fromRGB(62, 58, 66), "steel", "muzzle")
	gun.Parent = camera
	table.insert(demoParts, gun)
	return true
end

local function demoThrow()
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local start = root.Position + Vector3.new(0, 2, 0)
	local landing = (root.CFrame * CFrame.new(1.5, -3, -14)).Position
	local ball = Instance.new("Part")
	ball.Name = "SkinFxDemoGrenade"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(0.9, 0.9, 0.9)
	ball.Anchored, ball.CanCollide, ball.CanQuery, ball.CanTouch = true, false, false, false
	ball.Color = Color3.fromRGB(40, 34, 42)
	ball.CFrame = CFrame.new(start)
	ball:SetAttribute(SkinFx.GRENADE_ATTRIBUTE, "LAVA_LOB")
	ball:SetAttribute(SkinFx.OWNER_ATTRIBUTE, Players.LocalPlayer.UserId)
	ball.Parent = fxFolder
	grenadeThrown(ball)
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local u = (os.clock() - t0) / 1.2
		if u >= 1 then
			conn:Disconnect()
			ball:Destroy()
			return
		end
		ball.CFrame = CFrame.new(start:Lerp(landing, u) + Vector3.new(0, 6 * 4 * u * (1 - u), 0))
	end)
end

if IS_STUDIO then
	task.spawn(function()
		local built, cycle = false, 0
		while true do
			task.wait(0.125)
			if ReplicatedStorage:GetAttribute(DEMO) == true then
				if not built or not (demoParts[1] and demoParts[1].Parent) then
					demoClear()
					built = demoBuild()
					cycle = 0
				end
				cycle = (cycle + 0.125) % 8
				if cycle < 3 then
					demoShots += 1 -- 8 shots a second, the Big Game Hunter's pace
				elseif math.abs(cycle - 4.5) < 0.06 then
					demoThrow()
				elseif math.abs(cycle - 6.5) < 0.06 then
					takedown(Players.LocalPlayer)
				end
			elseif built then
				demoClear()
				built = false
			end
		end
	end)
end

local clock = 0
RunService.Heartbeat:Connect(function(dt)
	clock += dt
	if clock >= RESCAN then
		clock = 0
		local ok, err = pcall(rescan)
		if not ok then
			warn(`[SkinFx] {err}`)
		end
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	local now = os.clock()
	local ok, err = pcall(stepHeat, dt)
	if not ok then
		warn(`[SkinFx] {err}`)
	end
	for _, t in targets do
		local anchor = t.anchor
		if t.tier >= SkinFx.PACK_TIER and t.where == "hunter" then
			stepMarks(t)
		end
		if t.tier >= 1 and anchor and anchor.Parent and (anchor.Position - eye).Magnitude <= SkinFx.FX_DISTANCE then
			local boost = if t.where == "tower" and t.stage >= 2 then 1 else 0
			local heat = if t.where == "weapon" and t.tier >= SkinFx.PACK_TIER and t.player and t.element
				then heats[t.player :: Player]
				else nil
			for i, part in t.glow do
				if heat and t.element then -- the reactive weapon: cool -> white-hot with the shots
					part.Color = SkinFx.heatColour(t.element :: SkinFx.Element, heat.heat)
				else
					part.Color = SkinFx.glowColour(t.theme, t.tier, now, t.phases[i], boost)
				end
			end
			local light = t.light
			if light then
				local base, pulse = SkinFx.light(t.tier, t.where, t.stage)
				if base and pulse then
					light.Brightness = base + pulse * (math.sin(now * 2 * math.pi / t.theme.pulseSeconds) + 1) / 2
				end
			end
			if t.tier >= 3 and now >= t.flareAt and t.emitters[1] and t.emitters[1].Enabled then
				t.flareAt = now + SkinFx.IDLE_FLARE_SECONDS
				t.emitters[1]:Emit(SkinFx.IDLE_FLARE_COUNT)
			end
		end
	end
end)
