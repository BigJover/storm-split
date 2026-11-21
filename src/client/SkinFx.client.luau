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
	Studio-only aid: ReplicatedStorage attribute `SkinFxTier` (0..3) forces a tier to compare.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SkinFx = require(Shared:WaitForChild("SkinFx"))
local HunterBody = require(Shared:WaitForChild("HunterBody"))
local GunArt = require(Shared:WaitForChild("GunArt"))

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
}

local targets: { [Instance]: Target } = {}

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

local function clear(t: Target)
	for _, inst in t.made do
		inst:Destroy()
	end
	t.made, t.emitters, t.light = {}, {}, nil
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
end

local function makeTarget(root: Instance, where: string, key: string, item: SkinFx.Item, pieces: { BasePart }, own: boolean, stage: number): Target?
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
		tier = SkinFx.tier(key, overrideTier(), IS_STUDIO),
		glow = glow, phases = phases, authored = authored,
		anchor = biggest(glow), made = {}, emitters = {}, light = nil,
		own = own, stage = stage, flareAt = os.clock() + math.random() * SkinFx.IDLE_FLARE_SECONDS,
	}
	dress(t)
	return t
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
				found[body] = { "hunter", key, item, player == me, 0 }
			end
			local tool = character:FindFirstChildOfClass("Tool")
			local gun = tool and tool:FindFirstChild(GunArt.FOLDER)
			if gun then
				local first = gun:FindFirstChildWhichIsA("BasePart")
				local gkey, gitem = SkinFx.fromArt("weapon", first and first:GetAttribute("ArtKey"))
				if gkey and gitem then
					found[gun] = { "weapon", gkey, gitem, player == me, 0 }
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
					found[child] = { "weapon", gkey, gitem, false, 0 }
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
		elseif f[5] ~= t.stage or SkinFx.tier(t.key, tier, IS_STUDIO) ~= t.tier or not (t.glow[1] and t.glow[1].Parent) then
			clear(t)
			targets[root] = nil -- remade below (stage or tier changed)
		end
	end
	for root, f in found do
		if not targets[root] then
			local t = makeTarget(root, f[1], f[2], f[3], partsIn(root), f[4], f[5])
			if t then
				targets[root] = t
			end
		end
	end
	-- emitter budget: own hunter off in first person; towers nearest first, capped
	local camera = workspace.CurrentCamera
	local eye = camera and camera.CFrame.Position or Vector3.zero
	local firstPerson = camera ~= nil and (camera.Focus.Position - eye).Magnitude < 1.5
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
	for _, t in targets do
		local anchor = t.anchor
		if t.tier >= 1 and anchor and anchor.Parent and (anchor.Position - eye).Magnitude <= SkinFx.FX_DISTANCE then
			local boost = if t.where == "tower" and t.stage >= 2 then 1 else 0
			for i, part in t.glow do
				part.Color = SkinFx.glowColour(t.theme, t.tier, now, t.phases[i], boost)
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
