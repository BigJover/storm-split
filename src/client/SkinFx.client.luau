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
	low graphics, rates scaled by the graphics quality (SkinFx.qualityScale). Tier 3 adds the
	fire-textured aura, swirling spark embers, a flickering light, a three-colour trail and an idle
	flare with a light pop. Studio-only aid: ReplicatedStorage `SkinFxTier` (0..4) forces a tier.

	Tier 4, the pack layer (#462, v3 #465; params per theme element in Shared/SkinFx.ELEMENTS):
	when the wearer owns the item's whole class pack (player attribute `SkinFxPacks`, published by
	the store wiring later; Studio: `SkinFxTier` = 4):
	  hunter   flame tongues licking off the helm horns + pauldrons (fire texture, colour over life
	           white-yellow -> orange -> red -> smoke), slow swirling embers, a flickering heat light,
	           a torso aura, lava drips off the pauldrons that hiss where they land, a scorched ground
	           ring with flames while standing still, molten footprints (+ a flame lick) that crust
	           over, and a take-down burst (fireball, ember shower, ground shockwave ring, a glowing
	           ground crack that cools, a light flash; `SkinFxTakedownAt`, stamped by the server)
	  weapon   heat from the replicated `Ammo` drops: the `glow` goes cool -> white-hot; every shot a
	           muzzle flash + light scaled by heat, a molten casing kicked out, a glowing bolt with a
	           fire trail along the server's tracer; heat haze from the vents when hot; the overheat
	           moment at max heat (vents flare, steam blast); steam on a reload (`ReloadUntil`)
	  grenade  a thrown grenade stamped `SkinFxGrenade` + `SkinFxOwner`: fire + smoke trails,
	           spinning embers and a flame in flight; on impact a fireball, a smoke plume, debris
	           sparks, a lava splash that bubbles then cools, lingering flames, a light flash and the
	           client's built-in explosion sound
	All within PACK_DISTANCE; world pieces come from fixed pools (MARK_CAP, DRIP_CAP, RING_CAP,
	BOLT_CAP, TAKEDOWN_CAP, SPLASH_CAP; the oldest is reused), bursts from one shared set of world
	emitters, animation in this loop (no tweens, no per-frame Instance.new). Your own aura, drips
	and ring are off in first person; your take-down burst and heat show on the viewmodel.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SkinFx = require(Shared:WaitForChild("SkinFx"))
local HunterBody = require(Shared:WaitForChild("HunterBody"))
local GunArt = require(Shared:WaitForChild("GunArt"))
local Config = require(Shared:WaitForChild("Config"))

local RESCAN = 0.75
local FX_TAG = "SkinFxObject" -- every instance this script adds carries this attribute
local IS_STUDIO = RunService:IsStudio()
local TEX = SkinFx.TEXTURES
local FAR = CFrame.new(0, -10000, 0) -- where idle pooled parts wait
local GRAVITY = 60 -- lava drips: studs/s^2 (a bit floaty, so they read)
local SHOCK_FILL = 0.55 -- the shockwave texture's ring sits at ~55% of its half-width (checked in Studio)

type Target = {
	root: Instance,
	where: string, -- "hunter" | "weapon" | "tower"
	key: string,
	theme: SkinFx.Theme,
	tier: number,
	quality: number,
	glow: { BasePart },
	phases: { number },
	authored: { Color3 },
	anchor: BasePart?,
	made: { Instance },
	emitters: { ParticleEmitter }, -- continuous; on / off by the budget (first person, distance, cap)
	light: PointLight?,
	own: boolean,
	stage: number,
	flareAt: number,
	popAt: number, -- tier 3+: the idle flare's light pop
	seed: number,
	player: Player?, -- whose (the wearer / holder / viewmodel = you)
	element: SkinFx.Element?, -- the theme's element (tier 4's pack layer)
	burst: ParticleEmitter?, -- tier 4: take-down burst (hunter) / muzzle flash (weapon), Emit only
	puff: ParticleEmitter?, -- tier 4 weapon: the cooling puff
	muzzle: BasePart?, -- tier 4 weapon: the art's muzzle piece
	lastPos: Vector3?, -- tier 4 hunter: footstep tracking
	walked: number,
	stepSide: number,
	-- tier 4 hunter
	still: number,
	ring: { part: BasePart, edgePart: BasePart, scorch: Decal, glow: Decal, edge: Decal, at: Attachment, fx: ParticleEmitter }?,
	ringAlpha: number,
	ringCheck: number,
	nextDrip: number,
	-- tier 4 weapon
	core: ParticleEmitter?,
	haze: ParticleEmitter?,
	steam: ParticleEmitter?,
	shell: ParticleEmitter?,
	flashLight: PointLight?,
	flash: number,
	flareUntil: number,
	steamUntil: number,
}

local targets: { [Instance]: Target } = {}
local firstPerson = false
local quality = 1 -- SkinFx.qualityScale of the current graphics level (0 = low: nothing)

-- Client-only things the pack layer drops in the world (marks, splashes...): one local folder.
local fxFolder = Instance.new("Folder")
fxFolder.Name = "SkinFxClient"
fxFolder.Parent = workspace

local function packsOf(player: Player?): { [string]: boolean }?
	return if player then SkinFx.parsePacks(player:GetAttribute(SkinFx.PACKS_ATTRIBUTE)) else nil
end

local function readQuality(): number
	local ok, level = pcall(function()
		return UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value
	end)
	return SkinFx.qualityScale(if ok then level else nil)
end
quality = readQuality()

local function lowGraphics(): boolean
	return quality <= 0
end

local function overrideTier(): number?
	local v = ReplicatedStorage:GetAttribute(SkinFx.OVERRIDE_ATTRIBUTE)
	return if IS_STUDIO and type(v) == "number" then v else nil
end

local function mark(inst: Instance): Instance
	inst:SetAttribute(FX_TAG, true)
	return inst
end

local function seq(points: { { number } }): NumberSequence
	local kps = {}
	for _, p in points do
		table.insert(kps, NumberSequenceKeypoint.new(p[1], p[2]))
	end
	return NumberSequence.new(kps)
end

local function colours(list: { Color3 }): ColorSequence
	if #list == 1 then
		return ColorSequence.new(list[1])
	end
	local kps = {}
	for i, c in list do
		table.insert(kps, ColorSequenceKeypoint.new((i - 1) / (#list - 1), c))
	end
	return ColorSequence.new(kps)
end

-- A particle emitter with these properties (LightInfluence 0 unless given).
local function pe(parent: Instance, name: string, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.LightInfluence = 0
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return mark(e) :: ParticleEmitter
end

local function emitter(spec: SkinFx.Emitter, parent: Instance, name: string, texture: string?): ParticleEmitter
	return pe(parent, name, {
		Rate = spec.rate * quality,
		Lifetime = NumberRange.new(spec.lifetime[1], spec.lifetime[2]),
		Speed = NumberRange.new(spec.speed[1], spec.speed[2]),
		Size = NumberSequence.new(spec.size[1], spec.size[2]),
		SpreadAngle = Vector2.new(spec.spread, spec.spread),
		Color = ColorSequence.new(spec.colour[1], spec.colour[2]),
		LightEmission = spec.lightEmission,
		Acceleration = Vector3.new(0, spec.rise, 0),
		Transparency = NumberSequence.new(0.1, 1),
		EmissionDirection = Enum.NormalId.Top,
		Texture = texture,
		RotSpeed = if texture then NumberRange.new(-60, 60) else NumberRange.new(0, 0),
		Rotation = NumberRange.new(0, 360),
	})
end

-- An Emit-only emitter (Rate 0) for bursts.
local function burster(spec: SkinFx.Burst, parent: Instance, name: string, rise: number, texture: string?): ParticleEmitter
	return pe(parent, name, {
		Rate = 0,
		Lifetime = NumberRange.new(0.35, 0.8),
		Speed = NumberRange.new(spec.speed * 0.5, spec.speed),
		Size = NumberSequence.new(spec.size, 0),
		SpreadAngle = Vector2.new(180, 180),
		Color = ColorSequence.new(spec.colour[1], spec.colour[2]),
		LightEmission = 0.7,
		Acceleration = Vector3.new(0, rise, 0),
		Drag = 3,
		Transparency = NumberSequence.new(0, 1),
		Texture = texture,
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-120, 120),
	})
end

local function fxPart(name: string, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Name = name
	if shape then
		part.Shape = shape
	end
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
	part.Material = Enum.Material.Neon
	part.Transparency = 1
	part.CFrame = FAR
	mark(part)
	return part
end

local function topDecal(part: BasePart, texture: string, name: string): Decal
	local d = Instance.new("Decal")
	d.Name = name
	d.Face = Enum.NormalId.Top
	d.Texture = texture
	d.Transparency = 1
	d.Parent = part
	return mark(d) :: Decal
end

------------------------------------------------------------------ animation + pools

-- One list of running animations, stepped by the Heartbeat loop. A pooled item's `token` changes
-- when it's reused, which silently drops the old owner's animation.
type Item = { part: BasePart, token: number, free: boolean, used: number, [string]: any }
type Anim = { t0: number, dur: number, item: Item?, token: number, step: (u: number, t: number) -> (), done: (() -> ())? }
local anims: { Anim } = {}

local function animate(dur: number, item: Item?, step: (u: number, t: number) -> (), done: (() -> ())?)
	table.insert(anims, { t0 = os.clock(), dur = dur, item = item, token = if item then item.token else 0, step = step, done = done })
end

local function stepAnims(now: number)
	for i = #anims, 1, -1 do
		local a = anims[i]
		local item = a.item
		if item and item.token ~= a.token then
			table.remove(anims, i) -- the item was reused: drop this one quietly
		else
			local t = now - a.t0
			local u = math.clamp(t / a.dur, 0, 1)
			local ok, err = pcall(a.step, u, t)
			if not ok then
				warn(`[SkinFx] {err}`)
			end
			if u >= 1 or not ok then
				table.remove(anims, i)
				if a.done then
					pcall(a.done)
				end
			end
		end
	end
end

type Pool = { items: { Item }, cap: number, make: () -> Item }
local function newPool(cap: number, make: () -> Item): Pool
	return { items = {}, cap = cap, make = make }
end

-- A free item, else a new one (under the cap), else the oldest one (its animation is dropped).
local function acquire(pool: Pool): Item
	local now = os.clock()
	local pick: Item? = nil
	for _, it in pool.items do
		if it.free then
			pick = it
			break
		end
	end
	if not pick and #pool.items < pool.cap then
		local it = pool.make()
		it.token, it.free, it.used = 0, true, now
		table.insert(pool.items, it)
		pick = it
	end
	if not pick then
		local oldest = pool.items[1]
		for _, it in pool.items do
			if it.used < oldest.used then
				oldest = it
			end
		end
		pick = oldest
	end
	local it = pick :: Item
	it.token += 1
	it.free, it.used = false, now
	return it
end

local function release(item: Item, hide: () -> ())
	item.free = true
	hide()
end

------------------------------------------------------------------ shared world emitters

-- Bursts at a point (fireballs, smoke, sparks, steam...): one hidden anchored part with one
-- emitter each, moved to the spot and Emit()ed (particles stay in the world where emitted).
local worldPart = fxPart("SkinFxWorld")
worldPart.Size = Vector3.new(0.4, 0.4, 0.4)
worldPart.Parent = fxFolder
local world: { [string]: ParticleEmitter } = {}

local function worldEmitter(name: string, props: { [string]: any })
	world[name] = pe(worldPart, name, props)
end

local FIRE_LIFE = { Color3.fromRGB(255, 250, 215), Color3.fromRGB(255, 196, 70), Color3.fromRGB(255, 108, 18), Color3.fromRGB(190, 32, 8), Color3.fromRGB(70, 60, 60) }

worldEmitter("fireball", {
	Rate = 0, Texture = TEX.core, Lifetime = NumberRange.new(0.35, 0.6), Speed = NumberRange.new(3, 8),
	SpreadAngle = Vector2.new(180, 180), Size = seq({ { 0, 1.6 }, { 0.3, 4 }, { 1, 5 } }), Color = colours(FIRE_LIFE),
	Transparency = seq({ { 0, 0 }, { 0.6, 0.3 }, { 1, 1 } }), LightEmission = 0.9, Drag = 5,
	Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-90, 90), Acceleration = Vector3.new(0, 6, 0), ZOffset = 1,
})
worldEmitter("plume", {
	Rate = 0, Texture = TEX.plume, Lifetime = NumberRange.new(1.8, 2.6), Speed = NumberRange.new(2, 4),
	SpreadAngle = Vector2.new(35, 35), Size = seq({ { 0, 1.5 }, { 1, 6 } }),
	Color = ColorSequence.new(Color3.fromRGB(90, 70, 62), Color3.fromRGB(40, 36, 38)),
	Transparency = seq({ { 0, 0.25 }, { 0.5, 0.5 }, { 1, 1 } }), LightEmission = 0, LightInfluence = 0.6, Drag = 1.5,
	Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-30, 30), Acceleration = Vector3.new(0, 3.5, 0),
	EmissionDirection = Enum.NormalId.Top,
})
worldEmitter("sparks", { -- debris sparks / the ember shower: thrown up, falling
	Rate = 0, Texture = TEX.sparks, Lifetime = NumberRange.new(0.6, 1.2), Speed = NumberRange.new(14, 26),
	SpreadAngle = Vector2.new(65, 65), Size = seq({ { 0, 0.35 }, { 1, 0 } }),
	Color = ColorSequence.new(Color3.fromRGB(255, 236, 160), Color3.fromRGB(255, 70, 10)),
	Transparency = seq({ { 0, 0 }, { 1, 0.4 } }), LightEmission = 1, Drag = 1.2,
	Acceleration = Vector3.new(0, -45, 0), EmissionDirection = Enum.NormalId.Top,
	Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-200, 200),
})
worldEmitter("shower", { -- slow ember rain after a take-down
	Rate = 0, Texture = TEX.sparks, Lifetime = NumberRange.new(1.2, 2), Speed = NumberRange.new(6, 12),
	SpreadAngle = Vector2.new(80, 80), Size = seq({ { 0, 0.25 }, { 0.7, 0.2 }, { 1, 0 } }),
	Color = ColorSequence.new(Color3.fromRGB(255, 226, 130), Color3.fromRGB(255, 84, 10)),
	Transparency = seq({ { 0, 0 }, { 1, 0.6 } }), LightEmission = 1, Drag = 2.5,
	Acceleration = Vector3.new(0, -8, 0), EmissionDirection = Enum.NormalId.Top,
	Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-150, 150),
})
worldEmitter("lick", { -- a small flame lick (footsteps, tracer hits)
	Rate = 0, Texture = TEX.fire, Lifetime = NumberRange.new(0.25, 0.45), Speed = NumberRange.new(1.5, 3),
	SpreadAngle = Vector2.new(15, 15), Size = seq({ { 0, 0.3 }, { 0.35, 0.75 }, { 1, 0.1 } }), Color = colours(FIRE_LIFE),
	Transparency = seq({ { 0, 0.2 }, { 0.7, 0.4 }, { 1, 1 } }), LightEmission = 0.9, Squash = seq({ { 0, 0.5 }, { 1, 0.1 } }),
	Acceleration = Vector3.new(0, 5, 0), EmissionDirection = Enum.NormalId.Top, Rotation = NumberRange.new(-15, 15),
})
worldEmitter("hiss", { -- a lava drip's steam where it lands
	Rate = 0, Texture = TEX.smoke, Lifetime = NumberRange.new(0.6, 1), Speed = NumberRange.new(1.5, 3),
	SpreadAngle = Vector2.new(30, 30), Size = seq({ { 0, 0.3 }, { 1, 1.2 } }),
	Color = ColorSequence.new(Color3.fromRGB(245, 244, 240), Color3.fromRGB(170, 166, 166)),
	Transparency = seq({ { 0, 0.3 }, { 1, 1 } }), LightEmission = 0.1, Acceleration = Vector3.new(0, 3, 0),
	EmissionDirection = Enum.NormalId.Top, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-60, 60),
})

local function emitAt(name: string, pos: Vector3, count: number)
	local e = world[name]
	local n = SkinFx.scaleCount(count, quality)
	if e and n > 0 then
		worldPart.CFrame = CFrame.new(pos)
		e:Emit(n)
	end
end

-- Light flashes (take-downs, splashes): a small pool of lights, each fading out.
local flashPool = newPool(4, function(): Item
	local part = fxPart("SkinFxFlash")
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	local light = mark(Instance.new("PointLight")) :: PointLight
	light.Brightness, light.Shadows = 0, false
	light.Parent = part
	part.Parent = fxFolder
	return { part = part, token = 0, free = true, used = 0, light = light }
end)

local function flashAt(pos: Vector3, colour: Color3, brightness: number, range: number, seconds: number)
	if quality <= 0 then
		return
	end
	local it = acquire(flashPool)
	local light = it.light :: PointLight
	it.part.CFrame = CFrame.new(pos)
	light.Color, light.Range = colour, range
	animate(seconds, it, function(u)
		light.Brightness = brightness * (1 - u) ^ 2
	end, function()
		release(it, function()
			light.Brightness = 0
			it.part.CFrame = FAR
		end)
	end)
end

local function groundBelow(from: Vector3, ignore: { Instance }, depth: number?): RaycastResult?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = true
	return workspace:Raycast(from, Vector3.new(0, -(depth or 6), 0), params)
end

local function near(pos: Vector3): boolean
	local camera = workspace.CurrentCamera
	return camera ~= nil and SkinFx.packVisible((pos - camera.CFrame.Position).Magnitude, lowGraphics())
end

------------------------------------------------------------------ dressing a target

local function clear(t: Target)
	for _, inst in t.made do
		inst:Destroy()
	end
	t.made, t.emitters, t.light, t.burst, t.puff = {}, {}, nil, nil, nil
	t.ring, t.core, t.haze, t.steam, t.shell, t.flashLight = nil, nil, nil, nil, nil, nil
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

local function attachment(parent: Instance, name: string, pos: Vector3, made: { Instance }): Attachment
	local a = mark(Instance.new("Attachment")) :: Attachment
	a.Name = name
	a.Position = pos
	a.Parent = parent
	table.insert(made, a)
	return a
end

-- Tier 4 hunter: flame tongues, swirling embers, the torso aura, the heat light, the ground ring.
local function dressPackHunter(t: Target, element: SkinFx.Element, anchor: BasePart)
	local character = t.root.Parent
	local torso = character and character:FindFirstChild("UpperTorso")
	local host: BasePart = if torso and torso:IsA("BasePart") then torso else anchor
	local rates = SkinFx.packRates(element, quality)
	local f = element.flames
	-- flame tongues: two off the helm's horns (top corners of the head), one off each pauldron
	local spots: { { any } } = {}
	for _, name in f.hosts do
		local part = character and character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			if name == "Head" then
				table.insert(spots, { part, -1 })
				table.insert(spots, { part, 1 })
			else
				table.insert(spots, { part, 0 })
			end
		end
	end
	for _, spot in spots do
		local part, side = spot[1] :: BasePart, spot[2] :: number
		local share = if side ~= 0 then 0.5 else 1 -- the head's rate splits over its two horns
		local outward = if part.Name:find("Left") then -0.15 elseif part.Name:find("Right") then 0.15 else 0
		local at = attachment(part, "SkinFxFlame", Vector3.new(side * part.Size.X * 0.42 + outward, part.Size.Y * 0.5 + (if side ~= 0 then 0.25 else 0.05), 0), t.made)
		table.insert(t.emitters, pe(at, "SkinFxFlames", {
			Rate = rates.flames * share, Texture = TEX.fire,
			Lifetime = NumberRange.new(f.lifetime[1], f.lifetime[2]), Speed = NumberRange.new(f.speed[1], f.speed[2]),
			SpreadAngle = Vector2.new(f.spread, f.spread), Acceleration = Vector3.new(0, f.rise, 0),
			Size = seq({ { 0, f.size[1] }, { 0.35, f.size[2] }, { 1, f.size[3] } }),
			Color = colours(f.colour), Transparency = seq({ { 0, 0.15 }, { 0.55, 0.3 }, { 1, 1 } }),
			Squash = seq({ { 0, 0.6 }, { 0.5, 0.35 }, { 1, -0.1 } }), LightEmission = 0.85, Brightness = 1.4,
			Rotation = NumberRange.new(-15, 15), RotSpeed = NumberRange.new(-45, 45), Drag = 1, ZOffset = 0.3,
			EmissionDirection = Enum.NormalId.Top,
		}))
	end
	local r = element.rising
	local rise = attachment(host, "SkinFxRising", Vector3.zero, t.made)
	table.insert(t.emitters, pe(rise, "SkinFxRising", {
		Rate = rates.rising, Texture = TEX.sparks,
		Lifetime = NumberRange.new(r.lifetime[1], r.lifetime[2]), Speed = NumberRange.new(r.speed[1], r.speed[2]),
		SpreadAngle = Vector2.new(r.spread, r.spread), Acceleration = Vector3.new(0, r.rise, 0), Drag = r.drag,
		Size = seq({ { 0, r.size }, { 0.5, r.size * 1.25 }, { 1, 0 } }), Color = ColorSequence.new(r.colour[1], r.colour[2]),
		Transparency = seq({ { 0, 0 }, { 0.8, 0.25 }, { 1, 1 } }), LightEmission = 1,
		Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-260, 260), EmissionDirection = Enum.NormalId.Top,
	}))
	local packAura = SkinFx.packAura(element, t.tier)
	if packAura then -- emitted from the torso part's box: low flames round the body
		local e = emitter(packAura, host, "SkinFxPackAura", TEX.fire)
		e.Rate = rates.aura
		e.Transparency = seq({ { 0, 0.35 }, { 0.6, 0.55 }, { 1, 1 } })
		e.Squash = seq({ { 0, 0.4 }, { 1, 0 } })
		table.insert(t.emitters, e)
	end
	-- the heat light moves to the torso and flickers (replaces tier 3's pulsing light)
	if t.light then
		t.light.Parent = host
		t.light.Color = element.glow.colour
		t.light.Range = element.glow.range
	end
	-- the standing-still ground ring: a scorch blot + a glowing edge (decals on a flat block) and
	-- flames that pop up at random points on its rim
	local ring = fxPart("SkinFxRing")
	ring.Size = Vector3.new(element.ring.radius * 2.2, 0.05, element.ring.radius * 2.2)
	local scorch = topDecal(ring, TEX.smoke, "Scorch")
	scorch.Color3 = element.ring.scorch
	local glow = topDecal(ring, TEX.smoke, "Glow") -- embers smouldering in the scorch
	glow.Color3 = element.heat.hot
	glow.ZIndex = 2
	local edgePart = fxPart("SkinFxRingEdge")
	local edgeSize = element.ring.radius * 2 / SHOCK_FILL
	edgePart.Size = Vector3.new(edgeSize, 0.05, edgeSize)
	local edge = topDecal(edgePart, TEX.shock, "Edge")
	edge.Color3 = element.heat.hot
	edgePart.Parent = fxFolder
	table.insert(t.made, edgePart)
	local at = mark(Instance.new("Attachment")) :: Attachment
	at.Parent = ring
	local fx = pe(at, "SkinFxRingFlames", {
		Rate = 0, Texture = TEX.fire, Lifetime = NumberRange.new(0.35, 0.6), Speed = NumberRange.new(0.8, 1.8),
		SpreadAngle = Vector2.new(10, 10), Acceleration = Vector3.new(0, 4, 0),
		Size = seq({ { 0, 0.25 }, { 0.35, 0.7 }, { 1, 0.1 } }), Color = colours(f.colour),
		Transparency = seq({ { 0, 0.25 }, { 0.6, 0.4 }, { 1, 1 } }), Squash = seq({ { 0, 0.5 }, { 1, 0 } }),
		LightEmission = 0.85, EmissionDirection = Enum.NormalId.Top, Rotation = NumberRange.new(-12, 12),
	})
	ring.Parent = fxFolder
	table.insert(t.made, ring)
	t.ring = { part = ring, edgePart = edgePart, scorch = scorch, glow = glow, edge = edge, at = at, fx = fx }
	t.burst = burster(element.takedown, host, "SkinFxTakedown", 3, TEX.sparks)
	table.insert(t.made, t.burst :: ParticleEmitter)
end

-- Tier 4 weapon: muzzle flash + light, flame burst, heat haze, steam, casings, the cooling puff.
local function dressPackWeapon(t: Target, element: SkinFx.Element, anchor: BasePart)
	local muzzle: BasePart? = nil
	for _, p in partsIn(t.root) do
		if p:GetAttribute("ArtRole") == "muzzle" then
			muzzle = p
		end
	end
	t.muzzle = muzzle
	local m = element.muzzle
	local mp: BasePart = muzzle or anchor
	t.burst = pe(mp, "SkinFxMuzzle", {
		Rate = 0, Texture = TEX.fire, Lifetime = NumberRange.new(0.07, 0.16), Speed = NumberRange.new(2, m.speed),
		SpreadAngle = Vector2.new(180, 180), Size = seq({ { 0, m.size }, { 0.4, m.size * 2.6 }, { 1, 0 } }),
		Color = ColorSequence.new(m.colour[1], m.colour[2]), Transparency = seq({ { 0, 0 }, { 1, 0.8 } }),
		LightEmission = 1, Brightness = 2, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-200, 200),
		Drag = 6, ZOffset = 0.5,
	})
	t.core = pe(mp, "SkinFxFlameBurst", {
		Rate = 0, Texture = TEX.core, Lifetime = NumberRange.new(0.15, 0.3), Speed = NumberRange.new(1, 3),
		SpreadAngle = Vector2.new(180, 180), Size = seq({ { 0, 0.4 }, { 0.3, 1.3 }, { 1, 1.6 } }), Color = colours(FIRE_LIFE),
		Transparency = seq({ { 0, 0 }, { 0.6, 0.35 }, { 1, 1 } }), LightEmission = 0.9, Drag = 4,
		Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-120, 120), ZOffset = 0.5,
	})
	local light = mark(Instance.new("PointLight")) :: PointLight
	light.Brightness, light.Range, light.Color, light.Shadows = 0, m.range, m.colour[2], false
	light.Parent = mp
	t.flashLight = light
	t.haze = pe(anchor, "SkinFxHaze", {
		Rate = 0, Texture = TEX.smoke, Lifetime = NumberRange.new(1, 1.6), Speed = NumberRange.new(0.4, 0.9),
		SpreadAngle = Vector2.new(20, 20), Size = seq({ { 0, 0.25 }, { 1, 1.4 } }),
		Color = ColorSequence.new(Color3.fromRGB(210, 200, 196), Color3.fromRGB(120, 112, 112)),
		Transparency = seq({ { 0, 0.75 }, { 0.4, 0.7 }, { 1, 1 } }), LightEmission = 0.05, Acceleration = Vector3.new(0.6, 2.6, 0),
		Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-70, 70), EmissionDirection = Enum.NormalId.Top,
	})
	local s = element.steam
	t.steam = pe(anchor, "SkinFxSteam", {
		Rate = 0, Texture = TEX.smoke, Lifetime = NumberRange.new(0.8, 1.4), Speed = NumberRange.new(2, 4.5),
		SpreadAngle = Vector2.new(40, 40), Size = seq({ { 0, 0.35 }, { 1, s.size * 1.6 } }),
		Color = ColorSequence.new(s.colour[1], s.colour[2]), Transparency = seq({ { 0, 0.3 }, { 1, 1 } }),
		LightEmission = 0.15, Acceleration = Vector3.new(0, 3, 0), Drag = 1.5,
		Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-80, 80), EmissionDirection = Enum.NormalId.Top,
	})
	local sh = element.shell
	t.shell = pe(anchor, "SkinFxShell", {
		Rate = 0, Texture = TEX.sparks, Lifetime = NumberRange.new(0.4, 0.6), Speed = NumberRange.new(sh.speed * 0.7, sh.speed),
		SpreadAngle = Vector2.new(25, 25), Size = seq({ { 0, 0.22 }, { 1, 0.1 } }),
		Color = ColorSequence.new(sh.colour[1], sh.colour[2]), LightEmission = 1, Acceleration = Vector3.new(0, -45, 0),
		EmissionDirection = Enum.NormalId.Right, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-300, 300),
	})
	t.puff = burster(element.puff, anchor, "SkinFxPuff", 2.5, TEX.smoke)
	for _, inst: any in { t.burst, t.core, light, t.haze, t.steam, t.shell, t.puff } :: { any } do
		table.insert(t.made, inst)
	end
end

-- The effects a target's tier asks for (re-made when the tier, a tower's stage or the quality changes).
local function dress(t: Target)
	clear(t)
	local anchor = t.anchor
	if not anchor or t.tier < 2 or lowGraphics() then
		return
	end
	local at = attachment(anchor, "SkinFxAt", Vector3.zero, t.made)
	local embers = SkinFx.embers(t.theme, t.tier, t.where, t.stage)
	if embers then
		local e = emitter(embers, at, "SkinFxEmbers", TEX.sparks)
		e.Drag = 0.8
		e.RotSpeed = NumberRange.new(-220, 220)
		e.Size = seq({ { 0, embers.size[1] }, { 0.6, embers.size[1] * 1.2 }, { 1, 0 } })
		e.LightEmission = if t.tier >= 3 then 0.8 else embers.lightEmission
		table.insert(t.emitters, e)
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
		local foot = attachment(low, "SkinFxAura", Vector3.new(0, -low.Size.Y / 2, 0), t.made)
		local e = emitter(aura, foot, "SkinFxAura", TEX.fire)
		e.Transparency = seq({ { 0, 0.45 }, { 0.5, 0.6 }, { 1, 1 } })
		e.Squash = seq({ { 0, 0.3 }, { 1, 0 } })
		table.insert(t.emitters, e)
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
	local life, width = SkinFx.hunterTrail(t.tier)
	if life and width and t.where == "hunter" then -- a trail behind a moving hunter
		local a0 = attachment(anchor, "SkinFxTrail0", Vector3.new(0, width / 2, 0), t.made)
		local a1 = attachment(anchor, "SkinFxTrail1", Vector3.new(0, -width / 2, 0), t.made)
		local trail = mark(Instance.new("Trail")) :: Trail
		trail.Attachment0, trail.Attachment1 = a0, a1
		trail.Color = colours({ t.theme.hot, t.theme.glow, t.theme.deep })
		trail.Transparency = seq({ { 0, 0.3 }, { 0.5, 0.6 }, { 1, 1 } })
		trail.WidthScale = seq({ { 0, 1 }, { 1, 0.15 } })
		trail.Lifetime = life
		trail.MinLength = 0.2
		trail.LightEmission = 0.9
		trail.FaceCamera = true
		trail.Parent = anchor
		table.insert(t.made, trail)
	end
	local element = t.element
	if t.tier >= SkinFx.PACK_TIER and element then
		if t.where == "hunter" then
			dressPackHunter(t, element, anchor)
		elseif t.where == "weapon" then
			dressPackWeapon(t, element, anchor)
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
	local now = os.clock()
	local t: Target = {
		root = root, where = where, key = key, theme = theme,
		tier = SkinFx.tier(key, overrideTier(), IS_STUDIO, packsOf(player)), quality = quality,
		glow = glow, phases = phases, authored = authored,
		anchor = biggest(glow), made = {}, emitters = {}, light = nil,
		own = own, stage = stage, flareAt = now + math.random() * SkinFx.IDLE_FLARE_SECONDS, popAt = -1,
		seed = math.random() * 100,
		player = player, element = SkinFx.element(item.theme), walked = 0, stepSide = 1,
		still = 0, ringAlpha = 0, ringCheck = 0, nextDrip = now + 1 + math.random() * 2,
		flash = 0, flareUntil = 0, steamUntil = 0,
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
	quality = readQuality()
	local found = scan()
	local tier = overrideTier()
	for root, t in targets do
		local f = found[root]
		if not f or f[2] ~= t.key or not root.Parent then
			clear(t)
			targets[root] = nil
		elseif f[5] ~= t.stage or t.quality ~= quality or SkinFx.tier(t.key, tier, IS_STUDIO, packsOf(t.player)) ~= t.tier
			or not (t.glow[1] and t.glow[1].Parent) then
			clear(t)
			targets[root] = nil -- remade below (stage, tier or quality changed)
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
	-- emitter budget: own hunter off in first person; hunters culled by distance; towers nearest
	-- first, capped
	local camera = workspace.CurrentCamera
	local eye = camera and camera.CFrame.Position or Vector3.zero
	firstPerson = camera ~= nil and (camera.Focus.Position - eye).Magnitude < 1.5
	local towerList = {}
	for _, t in targets do
		local on = true
		if t.own and t.where == "hunter" and firstPerson then
			on = false
		end
		if t.where == "hunter" and t.anchor then
			local reach = if t.tier >= SkinFx.PACK_TIER then SkinFx.PACK_DISTANCE else SkinFx.FX_DISTANCE
			on = on and ((t.anchor :: BasePart).Position - eye).Magnitude <= reach
		end
		if t.where == "tower" and t.anchor then
			table.insert(towerList, { t = t, d = (t.anchor.Position - eye).Magnitude })
		end
		for _, e in t.emitters do
			e.Enabled = on
		end
		if t.light and t.where == "hunter" then
			t.light.Enabled = on
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

------------------------------------------------------------------ tier 4 hunter: steps, drips, ring, take-down

local function characterOf(t: Target): (Instance?, BasePart?)
	local character = t.root.Parent
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return character, if root and root:IsA("BasePart") then root else nil
end

-- Footprints: a flat molten disc (white-yellow -> orange -> crust) that fades, + a flame lick.
local markPool = newPool(SkinFx.MARK_CAP, function(): Item
	local part = fxPart("SkinFxMark", Enum.PartType.Cylinder)
	part.Parent = fxFolder
	return { part = part, token = 0, free = true, used = 0 }
end)

local function dropMark(element: SkinFx.Element, at: Vector3, normal: Vector3)
	local m = element.mark
	local it = acquire(markPool)
	local part = it.part
	part.Size = Vector3.new(0.06, m.size, m.size)
	part.CFrame = CFrame.lookAt(at + normal * 0.04, at + normal * 2) * CFrame.Angles(0, math.rad(90), 0)
	part.Material = Enum.Material.Neon
	part.Transparency = 0
	emitAt("lick", at, m.lick)
	animate(m.lifetime, it, function(u)
		part.Color = SkinFx.markColour(element, u)
		if u > 0.55 and part.Material ~= Enum.Material.Slate then
			part.Material = Enum.Material.Slate -- crusted over
		end
		part.Transparency = if u < 0.6 then 0 else (u - 0.6) / 0.4
	end, function()
		release(it, function()
			part.Transparency = 1
			part.CFrame = FAR
		end)
	end)
end

local function stepMarks(t: Target)
	local element = t.element
	local character, root = characterOf(t)
	if not element or not root or not character then
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
	t.stepSide = -t.stepSide
	local foot = pos + root.CFrame.RightVector * 0.45 * t.stepSide
	local hit = groundBelow(foot, { character :: Instance, fxFolder })
	if SkinFx.markDue(element, t.walked, hit ~= nil) and hit then
		t.walked = 0
		dropMark(element, hit.Position, hit.Normal)
	end
end

-- Lava drips off a pauldron: a glowing drop falls, then a spot that crusts + a steam hiss.
local dripPool = newPool(SkinFx.DRIP_CAP, function(): Item
	local drop = fxPart("SkinFxDrip", Enum.PartType.Ball)
	local spot = fxPart("SkinFxDripSpot", Enum.PartType.Cylinder)
	drop.Parent, spot.Parent = fxFolder, fxFolder
	return { part = drop, token = 0, free = true, used = 0, spot = spot }
end)

local function drip(t: Target)
	local element = t.element
	local character = t.root.Parent
	if not element or not character then
		return
	end
	local side = if math.random() < 0.5 then "Left" else "Right"
	local arm = character:FindFirstChild(side .. "UpperArm")
	if not arm or not arm:IsA("BasePart") then
		return
	end
	local d = element.drip
	local out = if side == "Left" then -1 else 1
	local start = (arm.CFrame * CFrame.new(out * arm.Size.X * 0.55, arm.Size.Y * 0.2, (math.random() - 0.5) * 0.4)).Position
	if not near(start) then
		return
	end
	local hit = groundBelow(start, { character, fxFolder }, 14)
	if not hit then
		return
	end
	local fall = math.max(0.3, start.Y - hit.Position.Y)
	local dur = math.sqrt(2 * fall / GRAVITY)
	local it = acquire(dripPool)
	local drop, spot = it.part, it.spot :: BasePart
	drop.Size = Vector3.new(d.size, d.size, d.size)
	drop.Color = d.colour
	drop.Transparency = 0
	spot.Transparency = 1
	spot.CFrame = FAR
	animate(dur, it, function(_u, t2)
		local tt = math.min(t2, dur)
		drop.CFrame = CFrame.new(start - Vector3.new(0, 0.5 * GRAVITY * tt * tt, 0))
	end, function()
		if it.free then
			return
		end
		drop.Transparency = 1
		drop.CFrame = FAR
		emitAt("hiss", hit.Position, d.hiss)
		spot.Size = Vector3.new(0.05, d.size * 2.4, d.size * 2.4)
		spot.CFrame = CFrame.lookAt(hit.Position + hit.Normal * 0.03, hit.Position + hit.Normal * 2) * CFrame.Angles(0, math.rad(90), 0)
		spot.Material = Enum.Material.Neon
		animate(1.4, it, function(u)
			spot.Color = d.colour:Lerp(d.crust, math.min(1, u * 1.6))
			spot.Transparency = if u < 0.5 then 0 else (u - 0.5) / 0.5
		end, function()
			release(it, function()
				spot.Transparency = 1
				spot.CFrame = FAR
			end)
		end)
	end)
end

-- The standing-still ring under a tier-4 hunter (RING_CAP at once, counted per frame).
local function stepRing(t: Target, dt: number, now: number, ringsOn: number): number
	local ring, element = t.ring, t.element
	local character, root = characterOf(t)
	if not ring or not element or not root or not character then
		return ringsOn
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local grounded = humanoid ~= nil and humanoid.FloorMaterial ~= Enum.Material.Air
	local moving = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude > 0.8
	t.still = if moving or not grounded then 0 else t.still + dt
	local allowed = not (t.own and firstPerson) and near(root.Position) and ringsOn < SkinFx.RING_CAP
	local target = if allowed then SkinFx.ringAlpha(element, t.still, grounded) else 0
	-- fade out quickly when moving, in at the element's pace
	local speed = if target < t.ringAlpha then 4 else 1 / math.max(element.ring.fade, 0.05)
	t.ringAlpha = if target > t.ringAlpha then math.min(target, t.ringAlpha + speed * dt) else math.max(target, t.ringAlpha - speed * dt)
	local a = t.ringAlpha
	if a <= 0.01 then
		if ring.part.CFrame ~= FAR then
			ring.part.CFrame, ring.edgePart.CFrame = FAR, FAR
			ring.fx.Rate = 0
		end
		return ringsOn
	end
	if now >= t.ringCheck then -- the ground under the feet, a few times a second
		t.ringCheck = now + 0.3
		local hit = groundBelow(root.Position, { character, fxFolder }, 8)
		if hit then
			ring.part.CFrame = CFrame.new(hit.Position + Vector3.new(0, 0.03, 0))
			ring.edgePart.CFrame = CFrame.new(hit.Position + Vector3.new(0, 0.05, 0))
		end
	end
	local pulse = 0.8 + 0.2 * math.sin(now * 5 + t.seed)
	ring.scorch.Transparency = 1 - 0.8 * a
	ring.glow.Transparency = 1 - 0.45 * a * (0.7 + 0.3 * math.sin(now * 3.1 + t.seed * 2))
	ring.edge.Transparency = 1 - 0.95 * a * pulse
	local radius = element.ring.radius * 0.9
	local angle = math.random() * 2 * math.pi
	ring.at.Position = Vector3.new(math.cos(angle) * radius, 0.05, math.sin(angle) * radius)
	ring.fx.Rate = element.ring.rate * quality * a
	return ringsOn + 1
end

-- Take-down: ground shockwave ring + glowing crack + light (one of TAKEDOWN_CAP sets).
local takedownPool = newPool(SkinFx.TAKEDOWN_CAP, function(): Item
	local ring = fxPart("SkinFxShock")
	local shock = topDecal(ring, TEX.shock, "Shock")
	ring.Parent = fxFolder
	local arms = {}
	for i = 1, 9 do
		local arm = fxPart("SkinFxCrack" .. i)
		arm.Parent = fxFolder
		arms[i] = arm
	end
	return { part = ring, token = 0, free = true, used = 0, shock = shock, arms = arms }
end)

local function groundBurst(element: SkinFx.Element, centre: Vector3, character: Instance?)
	local ignore: { Instance } = { fxFolder }
	if character then
		table.insert(ignore, character)
	end
	local hit = groundBelow(centre, ignore, 8)
	if not hit then
		return
	end
	local ground = hit.Position + Vector3.new(0, 0.03, 0)
	local td = element.takedown
	local it = acquire(takedownPool)
	local ring, shock, arms = it.part, it.shock :: Decal, it.arms :: { BasePart }
	shock.Color3 = element.heat.hot
	animate(td.ring.seconds, it, function(u)
		local radius, transparency = SkinFx.shockwave(element, u)
		ring.Size = Vector3.new(radius * 2 / SHOCK_FILL, 0.05, radius * 2 / SHOCK_FILL)
		ring.CFrame = CFrame.new(ground)
		shock.Transparency = transparency
	end, function()
		shock.Transparency = 1
		ring.CFrame = FAR
	end)
	local n = math.min(td.crack.arms, #arms)
	local spin = math.random() * 2 * math.pi
	for i = 1, #arms do
		local arm = arms[i]
		if i <= n then
			local len = td.crack.length * (0.55 + 0.45 * math.random())
			local angle = spin + (i / n) * 2 * math.pi + (math.random() - 0.5) * 0.5
			arm.Size = Vector3.new(0.16 + math.random() * 0.1, 0.05, len)
			arm.CFrame = CFrame.new(ground) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, -len / 2 - 0.25)
			arm.Material = Enum.Material.Neon
		else
			arm.CFrame = FAR
		end
	end
	animate(td.crack.seconds, it, function(u)
		local colour, transparency = SkinFx.crackColour(element, u)
		for i = 1, n do
			arms[i].Color = colour
			arms[i].Transparency = transparency
			if u > 0.6 and arms[i].Material ~= Enum.Material.Slate then
				arms[i].Material = Enum.Material.Slate
			end
		end
	end, function()
		release(it, function()
			for _, arm in arms do
				arm.Transparency = 1
				arm.CFrame = FAR
			end
			shock.Transparency = 1
			ring.CFrame = FAR
		end)
	end)
end

------------------------------------------------------------------ tier 4 weapon: heat

type Heat = { heat: number, ammo: number?, reloading: boolean, armed: boolean }
local heats: { [Player]: Heat } = {}
local demoShots = 0 -- Studio demo (`SkinFxDemo`): your stand-in gun's simulated shots
local demoReloadUntil = 0 -- Studio demo: a simulated reload (os.clock)

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

-- Where a gun's effects show: your viewmodel in first person, else the held gun (else any).
local function shownGun(guns: { Target }, player: Player): Target?
	local me = Players.LocalPlayer
	local fallback: Target? = nil
	for _, t in guns do
		local isViewmodel = t.root.Parent == workspace.CurrentCamera
		if player == me and firstPerson then
			if isViewmodel then
				return t
			end
		elseif not isViewmodel then
			return t
		end
		fallback = fallback or t
	end
	return fallback
end

local function stepHeat(dt: number)
	local now = workspace:GetServerTimeNow()
	local clock = os.clock()
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
			local h = heats[player] or { heat = 0, ammo = nil, reloading = false, armed = true }
			heats[player] = h
			local before = h.heat
			local ammo = player:GetAttribute("Ammo")
			local shots = if type(ammo) == "number" and type(h.ammo) == "number" and ammo < h.ammo then h.ammo - ammo else 0
			local isMe = player == Players.LocalPlayer
			if isMe and demoShots > 0 then
				shots += demoShots
				demoShots = 0
			end
			h.ammo = if type(ammo) == "number" then ammo else nil
			local reloadUntil = player:GetAttribute("ReloadUntil")
			local reloading = (type(reloadUntil) == "number" and reloadUntil > now) or (isMe and demoReloadUntil > clock)
			local reloadStarted = reloading and not h.reloading
			h.reloading = reloading
			local gun = shownGun(guns, player)
			local visible = gun ~= nil and gun.anchor ~= nil and near((gun.anchor :: BasePart).Position)
			if shots > 0 then
				h.heat = SkinFx.heatAfterShots(element, h.heat, shots, heroRate(guns[1].key))
				if visible and gun then
					local count, bright = SkinFx.muzzleFlash(element, h.heat)
					if gun.burst then
						(gun.burst :: ParticleEmitter):Emit(SkinFx.scaleCount(count, quality))
					end
					gun.flash = math.max(gun.flash, bright)
					if gun.shell then
						(gun.shell :: ParticleEmitter):Emit(SkinFx.scaleCount(element.shell.count * math.min(shots, 3), quality))
					end
					if gun.core and SkinFx.muzzleBurst(element, h.heat) then
						(gun.core :: ParticleEmitter):Emit(SkinFx.scaleCount(3, quality))
					end
				end
			else
				h.heat = SkinFx.heatAfter(element, h.heat, dt)
			end
			local fire, armed = SkinFx.overheat(element, h.armed, h.heat)
			h.armed = armed
			if fire and visible and gun then -- the overheat moment: vents flare + a steam blast
				gun.flareUntil = clock + 0.7
				gun.flash = element.muzzle.lightHot * 1.5
				if gun.steam then
					(gun.steam :: ParticleEmitter):Emit(SkinFx.scaleCount(element.steam.overheat, quality))
				end
				if gun.core then
					(gun.core :: ParticleEmitter):Emit(SkinFx.scaleCount(5, quality))
				end
			end
			if visible and gun and gun.puff and SkinFx.coolPuff(element, before, h.heat, reloadStarted) then
				(gun.puff :: ParticleEmitter):Emit(SkinFx.scaleCount(element.puff.count, quality))
			end
			if reloadStarted and gun then -- cool-down steam for the reload (stronger when hot)
				gun.steamUntil = clock + 1.4
				if gun.steam then
					gun.steam.Rate = element.steam.reloadRate * math.max(0.35, before) * quality
				end
			end
			for _, g in guns do
				if g.haze then
					g.haze.Rate = if visible and g == gun then SkinFx.hazeRate(element, h.heat) * quality else 0
				end
				if g.steam and clock >= g.steamUntil and g.steam.Rate ~= 0 then
					g.steam.Rate = 0
				end
				if g ~= gun and g.steam and g.steam.Rate ~= 0 then
					g.steam.Rate = 0
				end
			end
		end
	end
end

-- Glowing bolts along a pack gun's tracer: a hot ball with a fire trail, flying muzzle -> hit.
local boltPool = newPool(SkinFx.BOLT_CAP, function(): Item
	local part = fxPart("SkinFxBolt", Enum.PartType.Ball)
	part.Size = Vector3.new(0.3, 0.3, 0.3)
	local a0 = mark(Instance.new("Attachment")) :: Attachment
	local a1 = mark(Instance.new("Attachment")) :: Attachment
	a0.Position, a1.Position = Vector3.new(0, 0.18, 0), Vector3.new(0, -0.18, 0)
	a0.Parent, a1.Parent = part, part
	local trail = mark(Instance.new("Trail")) :: Trail
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Lifetime = 0.14
	trail.LightEmission = 1
	trail.FaceCamera = true
	trail.WidthScale = seq({ { 0, 1.2 }, { 1, 0.1 } })
	trail.Transparency = seq({ { 0, 0 }, { 1, 1 } })
	trail.Enabled = false
	trail.Parent = part
	part.Parent = fxFolder
	return { part = part, token = 0, free = true, used = 0, trail = trail }
end)

local function onTracer(part: BasePart)
	if math.abs(part.Size.X - 0.15) > 0.02 or part.Size.Z < 1 then
		return
	end
	local cf, len = part.CFrame, part.Size.Z
	local from, to = cf.Position - cf.LookVector * len / 2, cf.Position + cf.LookVector * len / 2
	if not near(from) then
		return
	end
	local owner: Target? = nil
	for _, t in targets do
		if t.where == "weapon" and t.tier >= SkinFx.PACK_TIER and t.element and t.anchor
			and ((t.anchor :: BasePart).Position - from).Magnitude < 6 then
			owner = t
			break
		end
	end
	if not owner or not owner.element or not owner.player then
		return
	end
	local element = owner.element :: SkinFx.Element
	local h = heats[owner.player :: Player]
	local heat = if h then h.heat else 0.5
	local hot = SkinFx.heatColour(element, math.max(heat, 0.5))
	part.Color = hot -- this screen only: the server's tracer glows with the heat
	part.Material = Enum.Material.Neon
	local gun = shownGun(weaponTargets(owner.player :: Player), owner.player :: Player)
	local start = if gun and gun.muzzle then (gun.muzzle :: BasePart).Position elseif gun and gun.anchor then (gun.anchor :: BasePart).Position else from
	local it = acquire(boltPool)
	local bolt, trail = it.part, it.trail :: Trail
	trail.Enabled = false
	bolt.Color = hot
	bolt.Transparency = 0
	bolt.CFrame = CFrame.new(start)
	trail:Clear()
	trail.Color = ColorSequence.new(hot, element.trail.colour[2])
	trail.Enabled = true
	local dur = math.clamp((to - start).Magnitude / 450, 0.05, 0.14)
	animate(dur, it, function(u)
		bolt.CFrame = CFrame.new(start:Lerp(to, u))
	end, function()
		emitAt("sparks", to, 2)
		bolt.Transparency = 1
		animate(trail.Lifetime, it, function() end, function()
			release(it, function()
				trail.Enabled = false
				bolt.CFrame = FAR
			end)
		end)
	end)
end

------------------------------------------------------------------ take-downs

-- A take-down: the wearer's burst (your own in first person: from the viewmodel gun).
local function takedown(player: Player)
	for _, t in targets do
		if t.where == "hunter" and t.player == player and t.tier >= SkinFx.PACK_TIER and t.element and t.burst then
			local element = t.element :: SkinFx.Element
			local td = element.takedown
			if player == Players.LocalPlayer and firstPerson then
				local gun = shownGun(weaponTargets(player), player)
				if gun and gun.burst then
					(gun.burst :: ParticleEmitter):Emit(SkinFx.scaleCount(td.count, quality))
				end
				if gun and gun.core then
					(gun.core :: ParticleEmitter):Emit(SkinFx.scaleCount(4, quality))
				end
			elseif t.anchor and near((t.anchor :: BasePart).Position) then
				local character, root = characterOf(t)
				local centre = if root then root.Position else (t.anchor :: BasePart).Position
				;(t.burst :: ParticleEmitter):Emit(SkinFx.scaleCount(td.count, quality))
				emitAt("fireball", centre + Vector3.new(0, 0.5, 0), td.fireball)
				emitAt("shower", centre + Vector3.new(0, 1.5, 0), td.shower)
				flashAt(centre + Vector3.new(0, 2, 0), element.heat.hot, td.flash.brightness, td.flash.range, td.flash.seconds)
				groundBurst(element, centre, character)
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

------------------------------------------------------------------ reactive grenades

-- The server stamps a thrown premium grenade (prop or today's ball) with the worn skin + the
-- thrower; trails + embers + a flame ride it, a layered explosion shows where it lands.
local splashPool = newPool(SkinFx.SPLASH_CAP, function(): Item
	local disc = fxPart("SkinFxSplash", Enum.PartType.Cylinder)
	local at = mark(Instance.new("Attachment")) :: Attachment
	at.Parent = disc
	local bubbles = pe(disc, "SkinFxBubbles", {
		Rate = 0, Texture = TEX.sparkles, Lifetime = NumberRange.new(0.25, 0.5), Speed = NumberRange.new(0.5, 1.5),
		SpreadAngle = Vector2.new(20, 20), Size = seq({ { 0, 0.1 }, { 0.7, 0.35 }, { 1, 0 } }),
		Color = ColorSequence.new(Color3.fromRGB(255, 236, 160), Color3.fromRGB(255, 110, 20)), LightEmission = 1,
		EmissionDirection = Enum.NormalId.Right, -- a Cylinder's X is the ground normal
	})
	local flames = pe(at, "SkinFxLinger", {
		Rate = 0, Texture = TEX.fire, Lifetime = NumberRange.new(0.35, 0.6), Speed = NumberRange.new(1, 2),
		SpreadAngle = Vector2.new(10, 10), Acceleration = Vector3.new(0, 4, 0),
		Size = seq({ { 0, 0.3 }, { 0.35, 0.8 }, { 1, 0.1 } }), Color = colours(FIRE_LIFE),
		Transparency = seq({ { 0, 0.2 }, { 0.6, 0.4 }, { 1, 1 } }), Squash = seq({ { 0, 0.5 }, { 1, 0 } }),
		LightEmission = 0.85, EmissionDirection = Enum.NormalId.Top, Rotation = NumberRange.new(-12, 12),
	})
	local sound = mark(Instance.new("Sound")) :: Sound
	sound.Parent = disc
	disc.Parent = fxFolder
	return { part = disc, token = 0, free = true, used = 0, at = at, bubbles = bubbles, flames = flames, sound = sound }
end)

local function splash(element: SkinFx.Element, at: Vector3)
	if not near(at) then
		return
	end
	local s = element.splash
	local hit = groundBelow(at + Vector3.new(0, 1.5, 0), { fxFolder })
	local ground = if hit then hit.Position else at
	emitAt("fireball", ground + Vector3.new(0, 1, 0), s.fireball)
	emitAt("plume", ground + Vector3.new(0, 1.5, 0), s.plume)
	emitAt("sparks", ground + Vector3.new(0, 0.5, 0), s.count)
	flashAt(ground + Vector3.new(0, 2.5, 0), element.heat.hot, s.flash.brightness, s.flash.range, s.flash.seconds)
	local it = acquire(splashPool)
	local disc, ember = it.part, it.at :: Attachment
	local bubbles, flames, sound = it.bubbles :: ParticleEmitter, it.flames :: ParticleEmitter, it.sound :: Sound
	disc.CFrame = CFrame.new(ground + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90))
	disc.Material = Enum.Material.Neon
	disc.Color = element.heat.white
	disc.Transparency = 0.05
	disc.Size = Vector3.new(0.08, s.radius * 0.6, s.radius * 0.6)
	local boom = element.sound.boom
	if boom and element.sound.volume > 0 then
		sound.SoundId = boom
		sound.Volume = element.sound.volume
		sound.RollOffMaxDistance = SkinFx.PACK_DISTANCE
		sound:Play()
	end
	animate(s.lifetime, it, function(u, t)
		local grow = math.min(1, u / 0.12)
		local size = s.radius * (0.6 + 1.4 * (1 - (1 - grow) ^ 3))
		disc.Size = Vector3.new(0.08, size, size)
		if u < 0.08 then
			disc.Color = element.heat.white:Lerp(s.colour, u / 0.08)
		elseif u < 0.55 then -- bubbling: the molten pool throbs
			local throb = 0.5 + 0.5 * math.sin(t * 18)
			disc.Color = s.colour:Lerp(element.heat.white, 0.25 * throb)
		else
			disc.Color = s.colour:Lerp(s.crust, math.min(1, (u - 0.55) / 0.25))
			if u > 0.75 and disc.Material ~= Enum.Material.Slate then
				disc.Material = Enum.Material.Slate
			end
		end
		disc.Transparency = if u < 0.7 then 0.05 else 0.05 + 0.95 * (u - 0.7) / 0.3
		bubbles.Rate = if u < 0.6 then s.bubbles * quality else 0
		local lingering = t < s.linger
		flames.Rate = if lingering then 12 * quality * (1 - t / s.linger) else 0
		if lingering then
			local r = size * 0.4 * math.sqrt(math.random())
			local a = math.random() * 2 * math.pi
			ember.Position = Vector3.new(0, math.cos(a) * r, math.sin(a) * r) -- the disc's YZ is the ground
			ember.WorldCFrame = CFrame.new(ember.WorldPosition) -- emit straight up in the world
		end
	end, function()
		release(it, function()
			bubbles.Rate, flames.Rate = 0, 0
			disc.Transparency = 1
			disc.CFrame = FAR
		end)
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
	-- once per throw (the grenade's own instances go with it): fire trail, smoke trail, embers, flame
	local tr = element.trail
	local made = {}
	local a0 = attachment(part, "SkinFxT0", Vector3.new(0, tr.width / 2, 0), made)
	local a1 = attachment(part, "SkinFxT1", Vector3.new(0, -tr.width / 2, 0), made)
	local s0 = attachment(part, "SkinFxS0", Vector3.new(0, tr.width, 0), made)
	local s1 = attachment(part, "SkinFxS1", Vector3.new(0, -tr.width, 0), made)
	local function trail(b0: Attachment, b1: Attachment, colour: ColorSequence, life: number, light: number, transparency: NumberSequence, width: NumberSequence)
		local t = mark(Instance.new("Trail")) :: Trail
		t.Attachment0, t.Attachment1 = b0, b1
		t.Color, t.Lifetime, t.LightEmission, t.Transparency, t.WidthScale = colour, life, light, transparency, width
		t.FaceCamera = true
		t.Parent = part
	end
	trail(a0, a1, colours({ element.heat.white, tr.colour[1], tr.colour[2] }), tr.lifetime, 0.9, seq({ { 0, 0 }, { 1, 1 } }), seq({ { 0, 1 }, { 1, 0.2 } }))
	trail(s0, s1, ColorSequence.new(tr.smoke), tr.smokeLifetime, 0, seq({ { 0, 0.5 }, { 1, 1 } }), seq({ { 0, 0.4 }, { 1, 1.6 } }))
	pe(part, "SkinFxGrenadeEmbers", {
		Rate = tr.rate * quality, Texture = TEX.sparks, Lifetime = NumberRange.new(0.3, 0.6), Speed = NumberRange.new(0.5, 2),
		SpreadAngle = Vector2.new(180, 180), Size = seq({ { 0, 0.3 }, { 1, 0 } }), Color = ColorSequence.new(tr.colour[1], tr.colour[2]),
		LightEmission = 1, Acceleration = Vector3.new(0, 2, 0), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-400, 400),
	})
	pe(part, "SkinFxGrenadeFlame", {
		Rate = 22 * quality, Texture = TEX.fire, Lifetime = NumberRange.new(0.12, 0.22), Speed = NumberRange.new(0.2, 0.6),
		SpreadAngle = Vector2.new(180, 180), Size = seq({ { 0, 0.7 }, { 1, 0.2 } }), Color = colours(FIRE_LIFE),
		Transparency = seq({ { 0, 0.1 }, { 1, 1 } }), LightEmission = 0.9, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-200, 200),
	})
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

-- The map's effects folder: today's grenade ball, and the server's tracers (bolts ride them).
local function onEffect(obj: Instance)
	maybeGrenade(obj)
	if obj:IsA("BasePart") and obj.Material == Enum.Material.Neon and next(heats) ~= nil then
		local ok, err = pcall(onTracer, obj)
		if not ok then
			warn(`[SkinFx] {err}`)
		end
	end
end
local function watchEffects()
	local map = workspace:FindFirstChild("StormSplitMap")
	local effects = map and map:FindFirstChild("Effects")
	if effects then
		effects.ChildAdded:Connect(onEffect)
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
	and your character gets a blocky Magma Monarch stand-in + a blocky Lava Lance by the right hand
	(local, glow pieces only), then a 12 s loop shows every effect:
	  0.0-3.2  firing at the Big Game Hunter's pace: heat to white-hot, muzzle flashes + light,
	           casings, glowing tracer bolts, heat haze, the overheat moment (vents flare + steam)
	  3.4      a reload: cool-down steam + puff
	  4.0      a thrown Lava Lob: trails + embers in flight, the layered explosion + boom
	  5.6      a take-down: fireball, ember shower, shockwave ring, ground crack, light flash
	  6.5-8.3  a short walk out and back: molten footprints + flame licks
	  8.3-12   standing still: the scorched ground ring with flames; forced lava drips at 9 + 10.5
	Flames, embers and the heat light run the whole time (third person: in first person your own
	aura is off by design). Clearing the attribute removes the stand-ins. Real effects code, fake art.
]]

local DEMO = "SkinFxDemo"
local DEMO_CYCLE = 12
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
		piece("Head", Vector3.new(0.18, 0.18, 0.18), CFrame.new(0.78 * s, 1.3, 0), true) -- glowing horn tip
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

-- A stand-in for the server's tracer (same size / Neon), so the bolt code runs on the demo gun.
local function demoTracer()
	local gun = demoParts[2]
	local muzzle: BasePart? = nil
	for _, d in (gun and gun:GetDescendants() or {}) do
		if d:IsA("BasePart") and d:GetAttribute("ArtRole") == "muzzle" then
			muzzle = d
		end
	end
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not muzzle or not root or not root:IsA("BasePart") then
		return
	end
	local from = muzzle.Position
	local to = from + (root.CFrame.LookVector + Vector3.new((math.random() - 0.5) * 0.08, -0.03, 0)).Unit * 30
	local part = Instance.new("Part")
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = true, false, false, false
	part.Material = Enum.Material.Neon
	part.Size = Vector3.new(0.15, 0.15, (to - from).Magnitude)
	part.CFrame = CFrame.lookAt((from + to) / 2, to)
	part.Color = SkinFx.THEMES.LAVA_LORD.tracer
	part.Parent = fxFolder
	task.delay(0.06, function()
		part:Destroy()
	end)
	onTracer(part)
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

local function myHunterTarget(): Target?
	for _, t in targets do
		if t.where == "hunter" and t.own and t.tier >= SkinFx.PACK_TIER then
			return t
		end
	end
	return nil
end

if IS_STUDIO then
	task.spawn(function()
		local built, cycle = false, 0
		local walkFrom: Vector3? = nil
		local function at(when: number): boolean
			return math.abs(cycle - when) < 0.06
		end
		while true do
			task.wait(0.125)
			if ReplicatedStorage:GetAttribute(DEMO) == true then
				if not built or not (demoParts[1] and demoParts[1].Parent) then
					demoClear()
					built = demoBuild()
					cycle = 0
				end
				cycle = (cycle + 0.125) % DEMO_CYCLE
				local character = Players.LocalPlayer.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local ok, err = pcall(function()
					if cycle < 3.2 then
						demoShots += 1 -- 8 shots a second, the Big Game Hunter's pace
						demoTracer()
					elseif at(3.375) then
						demoReloadUntil = os.clock() + 1.6
					elseif at(4) then
						demoThrow()
					elseif at(5.625) then
						takedown(Players.LocalPlayer)
					elseif at(6.5) and humanoid and root and root:IsA("BasePart") then
						walkFrom = root.Position
						humanoid:MoveTo(root.Position + root.CFrame.LookVector * 7)
					elseif at(7.375) and humanoid and walkFrom then
						humanoid:MoveTo(walkFrom)
					elseif at(9) or at(10.5) then
						local t = myHunterTarget()
						if t then
							drip(t)
						end
					end
				end)
				if not ok then
					warn(`[SkinFx] demo: {err}`)
				end
			elseif built then
				demoClear()
				built = false
			end
		end
	end)
end

------------------------------------------------------------------ the loop

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
	stepAnims(now)
	local ringsOn = 0
	for _, t in targets do
		local anchor = t.anchor
		if t.tier >= SkinFx.PACK_TIER and t.where == "hunter" and quality > 0 then
			local ok2, err2 = pcall(function()
				stepMarks(t)
				ringsOn = stepRing(t, dt, now, ringsOn)
				if now >= t.nextDrip then
					t.nextDrip = now + SkinFx.dripDelay(t.element :: SkinFx.Element, math.random())
					if not (t.own and firstPerson) then
						drip(t)
					end
				end
			end)
			if not ok2 then
				warn(`[SkinFx] {err2}`)
			end
		end
		if t.tier >= 1 and anchor and anchor.Parent and (anchor.Position - eye).Magnitude <= SkinFx.FX_DISTANCE then
			local boost = if t.where == "tower" and t.stage >= 2 then 1 else 0
			local heat = if t.where == "weapon" and t.tier >= SkinFx.PACK_TIER and t.player and t.element
				then heats[t.player :: Player]
				else nil
			local flaring = now < t.flareUntil
			for i, part in t.glow do
				if heat and t.element then -- the reactive weapon: cool -> white-hot with the shots
					local element = t.element :: SkinFx.Element
					part.Color = if flaring then element.heat.white else SkinFx.heatColour(element, heat.heat)
				else
					part.Color = SkinFx.glowColour(t.theme, t.tier, now, t.phases[i], boost)
				end
			end
			local light = t.light
			if light then
				local pop = math.max(0, 1 - (now - t.popAt) / 0.35)
				if t.tier >= SkinFx.PACK_TIER and t.element and t.where == "hunter" then
					local g = (t.element :: SkinFx.Element).glow
					local n = math.noise(now * 7, t.seed) + 0.5 * math.noise(now * 17, t.seed + 3)
					light.Brightness = math.max(0.2, g.brightness * (1 + g.flicker * n) + 2 * pop)
				else
					local base, pulse = SkinFx.light(t.tier, t.where, t.stage)
					if base and pulse then
						local flicker = 0.15 * math.noise(now * 6, t.seed)
						light.Brightness = base + pulse * (math.sin(now * 2 * math.pi / t.theme.pulseSeconds) + 1) / 2 + flicker + 1.5 * pop
					end
				end
			end
			local flashLight = t.flashLight
			if flashLight then
				flashLight.Brightness = t.flash
				t.flash = math.max(0, t.flash - dt * 30)
			end
			if t.tier >= 3 and now >= t.flareAt and t.emitters[1] and t.emitters[1].Enabled then
				t.flareAt = now + SkinFx.IDLE_FLARE_SECONDS
				t.emitters[1]:Emit(SkinFx.scaleCount(SkinFx.IDLE_FLARE_COUNT, quality))
				t.popAt = now
			end
		end
	end
end)
