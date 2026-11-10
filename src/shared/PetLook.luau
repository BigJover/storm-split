--!strict
--[[
	How a pet (and a warming egg) looks in 3D (PLAN 10d T141 blocks, PLAN 11f T156 art,
	DECISIONS #426/#450 and the tools/art/README "Pets, eggs, incubator" contract). Visual only:
	nothing here is ever hit, touched, queried or weighed, and no rule reads it. Server/Pets
	builds followers and Hatchling Pen pets with `build`; Client/Pets shows the local player's
	own incubators at the Hatchery Hut with `incubators`.

	  build(pet, at, label)      the pet's model, pivoting on its Body at CFrame `at`. With no
	                             loaded art (blank id, not loaded, ArtOff) it is today's blocky
	                             hatchling exactly (body, head, rarity collar, leaf tag, species
	                             part), pivoting on the Body's centre. With art (kind "pet", key =
	                             the species) the Body is kept as the invisible pivot ON THE GROUND
	                             (the art's origin, feet at y 0) and the art pieces replace the
	                             blocks; rarity paints the art (rarityPaint).
	  dressed(model)             is this pet wearing its art
	  follow(model, ground)      where it follows, from its hunter's HumanoidRootPart: blocky =
	                             FOLLOW (floats ~0.7 above the floor, as today); art = the same
	                             spot with its pivot at the hunter's feet (`ground` studs below the
	                             root: HipHeight + half the root's height, 3 on the default rig)
	                             so the feet touch the floor (#450). Fliers add hover() on top.
	  hover(kind, t)             a flier's bob above that spot (Fetcher), else 0
	  penSpot(pen, i, model)     pet i (1..3) of a Hatchling Pen: blocky = today's spot; art =
	                             standing on the pen part's top
	  rarityPaint(parts, rarity, authored)   the art's rarity rule: `accent` (the bandana) =
	                             the rarity colour at every rarity; `glow` (the species' markings)
	                             = its authored darker body tone at Common / Uncommon, the rarity
	                             colour at Rare / Epic (SmoothPlastic), the rarity colour in Neon
	                             at Legendary / Mythic; Mythic also gets a light sparkle
	                             (ParticleEmitter "MythicSparkle" on the body piece). The leaf
	                             tag and every other group keep their authored colours.
	  incubators(eggs, now, slots, anchor)   a Model with one Incubator per warming slot beside
	                             the Hatchery Hut's door (art kind "egg", key INCUBATOR; slot 1
	                             left of the door, slot 2 right), each warming egg (kind "egg",
	                             key = the egg) sitting at the incubator's eggSeat, its bulb
	                             (`glow`) lit only while that egg is still warming. nil when the
	                             Incubator art isn't loaded: nothing is shown (eggs have no blocky
	                             3D look; the hut panel is 2D, as today).
	  RARITY_COLOURS             grey / green / blue / purple / gold / red (DINO_REVIEW Round 21)
]]

local ArtSlot = require(script.Parent.ArtSlot)
local PetRules = require(script.Parent.Pets)

local PetLook = {}

PetLook.KIND = "pet"
PetLook.EGG_KIND = "egg"
PetLook.INCUBATOR = "INCUBATOR"

-- Visuals only.
type Look = { body: Color3, size: Vector3, flies: boolean }
local LOOKS: { [string]: Look } = {
	HONKER = { body = Color3.fromRGB(120, 150, 90), size = Vector3.new(1.4, 1.4, 2), flies = false },
	FETCHER = { body = Color3.fromRGB(150, 110, 80), size = Vector3.new(1, 0.8, 1.4), flies = true },
	FERN_MUNCHER = { body = Color3.fromRGB(90, 160, 110), size = Vector3.new(1.6, 1.4, 2.2), flies = false },
	SHINY_SNATCHER = { body = Color3.fromRGB(220, 140, 70), size = Vector3.new(1.2, 1.3, 1.8), flies = false },
	FRILL_GUARD = { body = Color3.fromRGB(200, 170, 120), size = Vector3.new(1.6, 1.3, 2.2), flies = false },
}
PetLook.RARITY_COLOURS = table.freeze({ -- collar colour (cosmetic, DINO_REVIEW Round 21)
	COMMON = Color3.fromRGB(170, 170, 170),
	UNCOMMON = Color3.fromRGB(90, 200, 100),
	RARE = Color3.fromRGB(80, 150, 255),
	EPIC = Color3.fromRGB(180, 100, 240),
	LEGENDARY = Color3.fromRGB(250, 200, 60),
	MYTHIC = Color3.fromRGB(240, 70, 70),
})
local RARITY_COLOURS: { [string]: Color3 } = PetLook.RARITY_COLOURS :: any
local LEAF = Color3.fromRGB(60, 150, 70)
PetLook.FOLLOW = Vector3.new(3, -1.6, 2.5) -- beside and behind its hunter (blocky: floats)
PetLook.HOVER = 3.5 -- a flier's height over its follow spot
PetLook.SPARKLE = "MythicSparkle"
-- Rarities whose markings take the rarity colour / glow Neon (README "Pets" contract).
local MARKED = { RARE = true, EPIC = true, LEGENDARY = true, MYTHIC = true }
local NEON = { LEGENDARY = true, MYTHIC = true }
-- Incubators beside the Hatchery Hut's door (its front is -Z; the hut art reaches z -6.4).
PetLook.INCUBATOR_SPOTS = table.freeze({ Vector3.new(-4.4, 0, -8), Vector3.new(4.4, 0, -8) })
PetLook.EGG_SEAT = Vector3.new(0, 0.88, 0) -- the egg's base in the nest (manifest eggSeat)

local function block(name: string, size: Vector3, cframe: CFrame, color: Color3, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false -- never picks up a chest or trips a Touched
	p.CanQuery = false -- never hit by a ray: it can't be targeted
	p.CastShadow = false
	p.Parent = parent
	return p
end

local function addLabel(model: Model, body: BasePart, rarity: string, height: number)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(150, 22)
	gui.StudsOffset = Vector3.new(0, height, 0)
	gui.MaxDistance = 45
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.TextColor3 = RARITY_COLOURS[rarity] or Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0.4
	text.Text = model.Name
	text.Parent = gui
	gui.Parent = body
end

-- The art's rarity paint (see the header). `authored` = the species' ArtIds colours.
function PetLook.rarityPaint(parts: { BasePart }, rarity: string, authored: { [string]: Color3 }?)
	local colour = RARITY_COLOURS[rarity] or RARITY_COLOURS.COMMON
	local own: { [string]: Color3 } = authored or {}
	for _, part in parts do
		local group = part:GetAttribute("PaintGroup")
		if group == "accent" then
			part.Color = colour
			part.Material = Enum.Material.SmoothPlastic
		elseif group == "glow" then
			part.Color = if MARKED[rarity] then colour else (own.glow or part.Color)
			part.Material = if NEON[rarity] then Enum.Material.Neon else Enum.Material.SmoothPlastic
		end
	end
	if rarity == "MYTHIC" then
		local host: BasePart? = nil
		for _, part in parts do
			if part:GetAttribute("PaintGroup") == "body" then
				host = part
				break
			end
		end
		host = host or parts[1]
		if host and not host:FindFirstChild(PetLook.SPARKLE) then
			local sparkle = Instance.new("ParticleEmitter")
			sparkle.Name = PetLook.SPARKLE
			sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			sparkle.Color = ColorSequence.new(colour, Color3.new(1, 1, 1))
			sparkle.LightEmission = 1
			sparkle.Size = NumberSequence.new(0.25, 0)
			sparkle.Transparency = NumberSequence.new(0.2, 1)
			sparkle.Lifetime = NumberRange.new(0.6, 1.2)
			sparkle.Rate = 4 -- light: a few twinkles a second
			sparkle.Speed = NumberRange.new(0.3, 0.8)
			sparkle.SpreadAngle = Vector2.new(180, 180)
			sparkle.Parent = host
		end
	end
end

-- The pet's model (see the header), named as Shared/Pets.name shows it.
function PetLook.build(pet: { kind: string, rarity: string }, at: CFrame, label: boolean): Model
	local look = LOOKS[pet.kind] or LOOKS.HONKER
	local model = Instance.new("Model")
	model.Name = PetRules.name(pet)
	local s = look.size
	local body = block("Body", s, at, look.body, model)
	model.PrimaryPart = body
	if ArtSlot.template(PetLook.KIND, pet.kind) then
		-- The Body stays the (invisible) pivot, on the ground under the pet: the art's origin.
		local dressed, art = ArtSlot.dress(model, PetLook.KIND, pet.kind, 1, body, ArtSlot.paints(look.body, RARITY_COLOURS[pet.rarity]), { anchored = true })
		if dressed then
			body.Transparency = 1
			PetLook.rarityPaint(art, pet.rarity, ArtSlot.colors(PetLook.KIND, pet.kind))
			if label then
				addLabel(model, body, pet.rarity, ArtSlot.top(art, at) + 0.6)
			end
			return model
		end
	end
	local head = block("Head", Vector3.new(s.X * 0.8, s.Y * 0.7, s.Z * 0.45), at * CFrame.new(0, s.Y * 0.55, -s.Z * 0.6), look.body, model)
	block("Collar", Vector3.new(s.X * 0.85, s.Y * 0.2, s.Z * 0.15), at * CFrame.new(0, s.Y * 0.3, -s.Z * 0.42), RARITY_COLOURS[pet.rarity] or LEAF, model)
	block("LeafTag", Vector3.new(0.3, 0.4, 0.1), at * CFrame.new(0, s.Y * 0.05, -s.Z * 0.5), LEAF, model)
	if pet.kind == "HONKER" then
		block("Crest", Vector3.new(0.3, 0.3, 1.2), head.CFrame * CFrame.new(0, 0.5, 0.6) * CFrame.Angles(math.rad(30), 0, 0), look.body:Lerp(Color3.new(1, 1, 1), 0.2), model)
	elseif pet.kind == "FETCHER" then
		for _, x in { -1, 1 } do
			block("Wing", Vector3.new(1.6, 0.1, 0.8), at * CFrame.new(x * (s.X / 2 + 0.7), 0.2, 0), look.body:Lerp(Color3.new(0, 0, 0), 0.2), model)
		end
	elseif pet.kind == "FERN_MUNCHER" then
		block("Neck", Vector3.new(0.5, 1.4, 0.5), at * CFrame.new(0, s.Y * 0.9, -s.Z * 0.45), look.body, model)
	elseif pet.kind == "FRILL_GUARD" then
		block("Frill", Vector3.new(s.X * 1.4, s.Y, 0.2), head.CFrame * CFrame.new(0, 0.3, 0.4), look.body:Lerp(Color3.fromRGB(200, 90, 60), 0.4), model)
	end
	if label then
		addLabel(model, body, pet.rarity, s.Y + 0.8)
	end
	return model
end

function PetLook.dressed(model: Model?): boolean
	return model ~= nil and model:GetAttribute("ArtKey") ~= nil
end

function PetLook.flies(kind: string): boolean
	local look = LOOKS[kind]
	return look ~= nil and look.flies
end

-- How far below a HumanoidRootPart's centre the floor is (default R15: 3).
function PetLook.groundBelow(root: BasePart, humanoid: Humanoid?): number
	local hip = if humanoid then humanoid.HipHeight else 2
	return root.Size.Y / 2 + hip
end

function PetLook.follow(model: Model?, ground: number): Vector3
	if PetLook.dressed(model) then
		return Vector3.new(PetLook.FOLLOW.X, -ground, PetLook.FOLLOW.Z)
	end
	return PetLook.FOLLOW
end

function PetLook.hover(kind: string, t: number): number
	return if PetLook.flies(kind) then PetLook.HOVER + math.sin(t * 3) * 0.3 else 0
end

function PetLook.penSpot(pen: BasePart, i: number, model: Model?): CFrame
	local lift = if PetLook.dressed(model) then pen.Size.Y / 2 else 1
	return pen.CFrame * CFrame.new((i - 2) * 2.2, lift, 0) * CFrame.Angles(0, math.rad(180), 0)
end

-- One warming egg's art at `at` (its base), or nil when the egg's art isn't loaded.
local function eggArt(parent: Instance, egg: string, at: CFrame): boolean
	if not ArtSlot.template(PetLook.EGG_KIND, egg) then
		return false
	end
	local holder = Instance.new("Part")
	holder.Name = `Egg_{egg}`
	holder.Size = Vector3.new(0.2, 0.2, 0.2)
	holder.CFrame = at
	holder.Transparency = 1
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	local model = Instance.new("Model")
	model.Name = `Egg_{egg}`
	local dressed = ArtSlot.dress(model, PetLook.EGG_KIND, egg, 1, holder, ArtSlot.paints(Color3.fromRGB(240, 226, 190)), { anchored = true })
	holder:Destroy()
	if dressed then
		model.Parent = parent
	else
		model:Destroy()
	end
	return dressed
end

export type Warming = { egg: string, readyAt: number }

function PetLook.incubators(eggs: { Warming }, now: number, slots: number, anchor: CFrame): Model?
	if not ArtSlot.template(PetLook.EGG_KIND, PetLook.INCUBATOR) then
		return nil
	end
	local root = Instance.new("Model")
	root.Name = "Incubators"
	for slot = 1, math.clamp(math.floor(slots), 0, #PetLook.INCUBATOR_SPOTS) do
		local at = anchor * CFrame.new(PetLook.INCUBATOR_SPOTS[slot])
		local holder = Instance.new("Part")
		holder.Size = Vector3.new(0.2, 0.2, 0.2)
		holder.CFrame = at
		holder.Anchored = true
		local model = Instance.new("Model")
		model.Name = `Incubator{slot}`
		local dressed, art = ArtSlot.dress(model, PetLook.EGG_KIND, PetLook.INCUBATOR, 1, holder, ArtSlot.paints(Color3.fromRGB(150, 104, 62)), { anchored = true, castShadow = true })
		holder:Destroy()
		if dressed then
			local warming = eggs[slot]
			local lit = warming ~= nil and warming.readyAt > now
			for _, part in art do
				if part:GetAttribute("PaintGroup") == "glow" then
					-- The bulb: Neon and warm only while its egg is warming.
					part.Material = if lit then Enum.Material.Neon else Enum.Material.SmoothPlastic
					if not lit then
						part.Color = part.Color:Lerp(Color3.fromRGB(60, 56, 50), 0.6)
					end
				end
			end
			model:SetAttribute("Warming", lit)
			if warming then
				eggArt(model, warming.egg, at * CFrame.new(PetLook.EGG_SEAT))
			end
			model.Parent = root
		end
	end
	return root
end

return PetLook
