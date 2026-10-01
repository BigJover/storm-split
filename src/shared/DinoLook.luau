--[[
	What each dinosaur looks like. Visuals only: sizes here never affect HP,
	speed or hit detection (that's Config and Server/Enemies).

	Each species is a handful of blocks around a "Root" body part. The root is
	anchored and moved by Enemies; the rest are welded to it, so moving the root
	moves the whole dino in one step. A shrunken dino is rebuilt at a smaller
	scale: the largest size is 1, the smallest MIN_SCALE.

	Local axes: the dino faces -Z (the way CFrame.lookAt points), up is +Y.
]]

local DinoLook = {}

local MIN_SCALE = 0.5

type PartSpec = {
	name: string,
	size: Vector3,
	offset: Vector3, -- from the root's centre
	color: Color3?, -- defaults to the species colour
	shape: Enum.PartType?,
	tilt: CFrame?, -- a rotation applied at the offset
}
type Species = {
	color: Color3,
	body: Vector3, -- the root part
	legLength: number, -- ground to the bottom of the body
	parts: { PartSpec },
}

local function biped(body: Vector3, legLength: number, head: Vector3, extras: { PartSpec }?): { PartSpec }
	local w, h, l = body.X, body.Y, body.Z
	local parts: { PartSpec } = {
		{ name = "Head", size = head, offset = Vector3.new(0, h * 0.45, -(l / 2 + head.Z * 0.35)) },
		{ name = "Tail", size = Vector3.new(w * 0.45, h * 0.45, l * 0.9), offset = Vector3.new(0, h * 0.1, l * 0.85) },
		{ name = "LegL", size = Vector3.new(w * 0.28, legLength + h * 0.3, w * 0.3), offset = Vector3.new(-w * 0.28, -(h + legLength) / 2 + h * 0.15, 0) },
		{ name = "LegR", size = Vector3.new(w * 0.28, legLength + h * 0.3, w * 0.3), offset = Vector3.new(w * 0.28, -(h + legLength) / 2 + h * 0.15, 0) },
	}
	if extras then
		for _, extra in extras do
			table.insert(parts, extra)
		end
	end
	return parts
end

local function quadruped(body: Vector3, legLength: number, head: Vector3, extras: { PartSpec }?): { PartSpec }
	local w, h, l = body.X, body.Y, body.Z
	local parts: { PartSpec } = {
		{ name = "Head", size = head, offset = Vector3.new(0, 0, -(l / 2 + head.Z * 0.4)) },
		{ name = "Tail", size = Vector3.new(w * 0.35, h * 0.35, l * 0.7), offset = Vector3.new(0, 0, l * 0.75) },
	}
	for i, corner in { Vector2.new(-1, -1), Vector2.new(1, -1), Vector2.new(-1, 1), Vector2.new(1, 1) } do
		table.insert(parts, {
			name = `Leg{i}`,
			size = Vector3.new(w * 0.22, legLength + h * 0.3, w * 0.22),
			offset = Vector3.new(corner.X * w * 0.35, -(h + legLength) / 2 + h * 0.15, corner.Y * l * 0.3),
		})
	end
	if extras then
		for _, extra in extras do
			table.insert(parts, extra)
		end
	end
	return parts
end

-- Moves a built part list's Head (Gallimimus: onto its neck).
local function withHeadAt(parts: { PartSpec }, offset: Vector3): { PartSpec }
	for _, part in parts do
		if part.name == "Head" then
			part.offset = offset
		end
	end
	return parts
end

-- T-Rex: small white teeth along the part of the jaw that juts past the head
-- (the jaw's front is at z -7.8, the head's at about -7.1).
local TOOTH = Color3.fromRGB(245, 240, 225)
local function withTeeth(parts: { PartSpec }): { PartSpec }
	for i, x in { -1, -0.33, 0.33, 1 } do
		table.insert(parts, { name = `ToothF{i}`, size = Vector3.new(0.3, 0.45, 0.3), offset = Vector3.new(x, 1.05, -7.6), color = TOOTH })
	end
	for i, x in { -1.25, 1.25 } do
		table.insert(parts, { name = `ToothS{i}`, size = Vector3.new(0.3, 0.45, 0.3), offset = Vector3.new(x, 1.05, -7.3), color = TOOTH })
	end
	return parts
end

local SPECIES: { [string]: Species } = {
	HUSK = { -- Compy
		color = Color3.fromRGB(126, 196, 110),
		body = Vector3.new(0.9, 0.8, 1.4),
		legLength = 0.7,
		parts = biped(Vector3.new(0.9, 0.8, 1.4), 0.7, Vector3.new(0.6, 0.55, 0.8)),
	},
	BRUTE = { -- Raptor
		color = Color3.fromRGB(205, 140, 70),
		body = Vector3.new(1.1, 1, 2.2),
		legLength = 1.2,
		parts = biped(Vector3.new(1.1, 1, 2.2), 1.2, Vector3.new(0.7, 0.7, 1.2), {
			{ name = "Claw", size = Vector3.new(0.2, 0.5, 0.2), offset = Vector3.new(0, -0.6, -1), color = Color3.fromRGB(240, 235, 220) },
			-- a darker back stripe and a small crest: the tougher small biped (vs the Compy)
			{ name = "Stripe", size = Vector3.new(0.4, 0.12, 2), offset = Vector3.new(0, 0.53, 0), color = Color3.fromRGB(120, 70, 35) },
			{ name = "Crest", size = Vector3.new(0.15, 0.3, 0.6), offset = Vector3.new(0, 0.95, -1.4), color = Color3.fromRGB(120, 70, 35) },
		}),
	},
	SHIELD = { -- Pachycephalosaurus: domed skull
		color = Color3.fromRGB(150, 110, 80),
		body = Vector3.new(1.4, 1.3, 2.2),
		legLength = 1.3,
		parts = biped(Vector3.new(1.4, 1.3, 2.2), 1.3, Vector3.new(0.9, 0.8, 1), {
			{ name = "Dome", size = Vector3.new(1.1, 1.1, 1.1), offset = Vector3.new(0, 1.05, -1.5), color = Color3.fromRGB(215, 190, 150), shape = Enum.PartType.Ball },
		}),
	},
	ARMOR = { -- Ankylosaurus: flat, plated, spiked, club tail
		color = Color3.fromRGB(125, 125, 115),
		body = Vector3.new(2.4, 1.1, 3),
		legLength = 0.8,
		parts = quadruped(Vector3.new(2.4, 1.1, 3), 0.8, Vector3.new(1.1, 0.8, 0.9), {
			{ name = "Plates", size = Vector3.new(2.6, 0.35, 3.1), offset = Vector3.new(0, 0.65, 0), color = Color3.fromRGB(85, 85, 80) },
			{ name = "SpikeL", size = Vector3.new(0.5, 0.3, 2.4), offset = Vector3.new(-1.4, 0.2, 0), color = Color3.fromRGB(230, 225, 210) },
			{ name = "SpikeR", size = Vector3.new(0.5, 0.3, 2.4), offset = Vector3.new(1.4, 0.2, 0), color = Color3.fromRGB(230, 225, 210) },
			{ name = "Club", size = Vector3.new(1.1, 0.9, 0.9), offset = Vector3.new(0, 0, 3.4), color = Color3.fromRGB(85, 85, 80), shape = Enum.PartType.Ball },
		}),
	},
	STORM = { -- Gallimimus: long legs and neck, built to run; the head sits on the neck
		color = Color3.fromRGB(225, 195, 90),
		body = Vector3.new(1.2, 1.1, 2),
		legLength = 2.2,
		parts = withHeadAt(
			biped(Vector3.new(1.2, 1.1, 2), 2.2, Vector3.new(0.5, 0.5, 0.9), {
				{ name = "Neck", size = Vector3.new(0.4, 1.4, 0.4), offset = Vector3.new(0, 1.1, -1), color = nil },
			}),
			Vector3.new(0, 1.9, -1.2)
		),
	},
	LLAMA = { -- Pteranodon: wings and a crest
		color = Color3.fromRGB(150, 125, 165),
		body = Vector3.new(0.9, 0.7, 1.8),
		legLength = 0,
		parts = {
			{ name = "WingL", size = Vector3.new(3.4, 0.15, 1.3), offset = Vector3.new(-2, 0.1, 0) },
			{ name = "WingR", size = Vector3.new(3.4, 0.15, 1.3), offset = Vector3.new(2, 0.1, 0) },
			{ name = "Head", size = Vector3.new(0.5, 0.5, 1.4), offset = Vector3.new(0, 0.3, -1.4) },
			-- the crest starts at the back of the head and sweeps up and back
			{
				name = "Crest",
				size = Vector3.new(0.2, 0.3, 1),
				offset = Vector3.new(0, 0.7, -0.9),
				color = Color3.fromRGB(220, 110, 90),
				tilt = CFrame.Angles(math.rad(-20), 0, 0),
			},
		},
	},
	ZEP = { -- Triceratops: frill and three horns
		color = Color3.fromRGB(95, 115, 145),
		body = Vector3.new(4, 3, 6.5),
		legLength = 1.6,
		parts = quadruped(Vector3.new(4, 3, 6.5), 1.6, Vector3.new(2.4, 2, 2.2), {
			{ name = "Frill", size = Vector3.new(4.2, 3.4, 0.4), offset = Vector3.new(0, 1.2, -3.6), color = Color3.fromRGB(215, 130, 70) },
			{ name = "HornL", size = Vector3.new(0.35, 0.35, 2), offset = Vector3.new(-0.8, 0.9, -5.3), color = Color3.fromRGB(240, 235, 220) },
			{ name = "HornR", size = Vector3.new(0.35, 0.35, 2), offset = Vector3.new(0.8, 0.9, -5.3), color = Color3.fromRGB(240, 235, 220) },
			{ name = "HornN", size = Vector3.new(0.3, 0.3, 1.1), offset = Vector3.new(0, 0.1, -5.3), color = Color3.fromRGB(240, 235, 220) },
		}),
	},
	BARGE = { -- T-Rex: huge head, tiny arms
		color = Color3.fromRGB(75, 100, 60),
		body = Vector3.new(4.5, 4.5, 7),
		legLength = 4,
		parts = biped(Vector3.new(4.5, 4.5, 7), 4, Vector3.new(3.2, 3, 4.2), withTeeth({
			{ name = "Jaw", size = Vector3.new(2.8, 0.8, 3.4), offset = Vector3.new(0, 0.5, -6.1), color = Color3.fromRGB(55, 75, 45) },
			{ name = "ArmL", size = Vector3.new(0.4, 1.1, 0.4), offset = Vector3.new(-1.4, -0.4, -3), color = nil },
			{ name = "ArmR", size = Vector3.new(0.4, 1.1, 0.4), offset = Vector3.new(1.4, -0.4, -3), color = nil },
		})),
	},
}
local DEFAULT: Species = SPECIES.HUSK

-- Scale for size `size` of `sizes` (sizes counts down to 1 as it shrinks).
function DinoLook.scale(size: number, sizes: number): number
	if sizes <= 1 then
		return 1
	end
	return MIN_SCALE + (1 - MIN_SCALE) * (size - 1) / (sizes - 1)
end

local function cosmetic(part: BasePart)
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
end

-- A dino model at `scale`, its Root at `cframe`. Returns the model and how far
-- above the ground its root sits (so walking dinos keep their feet down).
function DinoLook.build(key: string, scale: number, cframe: CFrame): (Model, number)
	local species = SPECIES[key] or DEFAULT
	local model = Instance.new("Model")
	model.Name = key

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = species.body * scale
	root.Color = species.color
	root.Anchored = true
	cosmetic(root)
	root.CFrame = cframe
	root.Parent = model
	model.PrimaryPart = root

	for _, spec in species.parts do
		local part = Instance.new("Part")
		part.Name = spec.name
		if spec.shape then
			part.Shape = spec.shape
		end
		part.Size = spec.size * scale
		part.Color = spec.color or species.color
		part.Anchored = false
		part.Massless = true
		cosmetic(part)
		part.CFrame = cframe * CFrame.new(spec.offset * scale) * (spec.tilt or CFrame.identity)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = part
		weld.Parent = part
		part.Parent = model
	end

	return model, (species.legLength + species.body.Y / 2) * scale
end

-- Visuals only.
local DART_COLOR = Color3.fromRGB(60, 210, 190)
local DART_SIZE = Vector3.new(0.15, 0.15, 0.7)

-- The species and scale a built model was made at (its Root is body x scale).
local function measure(model: Model): (Species, number)
	local species = SPECIES[model.Name] or DEFAULT
	local root = model.PrimaryPart
	return species, if root then root.Size.X / species.body.X else 1
end

-- Sedated by a Tranq Station: a small teal dart sticks out of the back.
function DinoLook.setSedated(model: Model, on: boolean)
	local root = model.PrimaryPart
	local dart = model:FindFirstChild("SedationDart")
	if not on or not root then
		if dart then
			dart:Destroy()
		end
		return
	end
	if dart then
		return
	end
	local species, scale = measure(model)
	local body = species.body * scale
	dart = Instance.new("Part")
	dart.Name = "SedationDart"
	dart.Size = DART_SIZE * math.max(scale, 0.6)
	dart.Color = DART_COLOR
	dart.Anchored = false
	dart.Massless = true
	cosmetic(dart)
	dart.Material = Enum.Material.Neon
	-- Half in the top of the back, leaning toward the tail, so it shows from above
	-- and from both sides.
	dart.CFrame = root.CFrame * CFrame.new(0, body.Y / 2, body.Z * 0.15) * CFrame.Angles(math.rad(-60), 0, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = dart
	weld.Parent = dart
	dart.Parent = model
end

-- Knocked out by a Tranq Station pulse: "zzz" floats above the dino.
function DinoLook.setAsleep(model: Model, on: boolean)
	local root = model.PrimaryPart
	local sign = root and root:FindFirstChild("Asleep")
	if not on or not root then
		if sign then
			sign:Destroy()
		end
		return
	end
	if sign then
		return
	end
	local species, scale = measure(model)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Asleep"
	billboard.Size = UDim2.fromOffset(60, 28)
	billboard.StudsOffset = Vector3.new(0, species.body.Y * scale + 1.5, 0)
	billboard.LightInfluence = 0
	billboard.MaxDistance = 80
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "zzz"
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(235, 245, 255)
	label.TextStrokeTransparency = 0.4
	label.Parent = billboard
	billboard.Parent = root
end

------------------------------------------------------------------ projectiles

--[[
	What each ranged attack looks like in flight (Dino review round 4). Visuals
	only: where it lands and whom it hurts is Server/DinoAttacks' job. Keyed by
	species (the attack names live on the spreadsheet and can change).

	  lob      Skull Toss (Pachycephalosaurus): a stone on a high, spinning arc
	  spike    Spike Flick (Ankylosaurus): a bone spike pointing along a flat,
	           fast path; it sticks in the ground for a moment
	  gravel   Gravel Spray (Gallimimus): 3 pebbles in a tight cluster, low arc
	  drop     Stone Drop (Pteranodon): a stone falling straight down onto the ring
	  roll     Horn Toss (Triceratops): a big boulder rolling and bouncing along
	           the ground
	  capsule  Bone Spit (T-Rex): a bone-white capsule along its flight

	Thrown earth is earth-coloured; only a dino's own spike or bone is bone-white.
	Every attack shares one orange warning ring at the landing point that grows
	more solid as the shot comes in.
]]

export type ProjectileStyle = "lob" | "spike" | "gravel" | "drop" | "roll" | "capsule"

local ROCK = Color3.fromRGB(120, 105, 90)
local BONE = Color3.fromRGB(230, 225, 210)
local SAND = Color3.fromRGB(170, 140, 100)
local BOULDER = Color3.fromRGB(95, 85, 75)

DinoLook.PROJECTILE_STYLE = table.freeze({
	SHIELD = "lob",
	ARMOR = "spike",
	STORM = "gravel",
	LLAMA = "drop",
	ZEP = "roll",
	BARGE = "capsule",
} :: { [string]: ProjectileStyle })

-- The colour of the dust a landing shot throws up (nil: none, e.g. a spike).
DinoLook.PROJECTILE_DUST = table.freeze({
	lob = ROCK,
	gravel = SAND,
	drop = ROCK,
	roll = BOULDER,
	capsule = BONE,
} :: { [string]: Color3 })

-- Rock-type shots leave a few chips where they land.
DinoLook.PROJECTILE_CHIPS = table.freeze({ lob = 2, drop = 2, roll = 3 } :: { [string]: number })

DinoLook.RING_COLOR = Color3.fromRGB(255, 150, 40)
DinoLook.RING_FADE = table.freeze({ 0.75, 0.35 }) -- transparency at launch, just before impact

local function shotPart(model: Model, name: string, size: Vector3, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Name = name
	if shape then
		part.Shape = shape
	end
	part.Size = size
	part.Color = color
	part.Anchored = true
	cosmetic(part)
	part.Material = material
	part.Parent = model
	return part
end

-- A projectile model for this species' ranged attack. `radius` is the impact
-- radius and `scale` the dino's size share (size / sizes): bigger dinos throw
-- bigger shots. PrimaryPart "Shot".
function DinoLook.buildProjectile(key: string, radius: number, scale: number): Model
	local style = DinoLook.PROJECTILE_STYLE[key] or "lob"
	local model = Instance.new("Model")
	model.Name = `Projectile_{key}`
	local s = math.max(scale, MIN_SCALE)
	local base = math.min(0.35 * radius, 3) * s
	local shot: Part
	if style == "spike" then
		shot = shotPart(model, "Shot", Vector3.new(0.3, 0.3, 1.4) * s, BONE, Enum.Material.SmoothPlastic)
	elseif style == "gravel" then
		shot = shotPart(model, "Shot", Vector3.one * 0.4 * s, SAND, Enum.Material.Sand, Enum.PartType.Ball)
		for i, offset in { Vector3.new(0.45, 0.15, 0.2), Vector3.new(-0.35, -0.1, 0.4) } do
			local pebble = shotPart(model, `Pebble{i}`, Vector3.one * 0.35 * s, SAND, Enum.Material.Sand, Enum.PartType.Ball)
			pebble.CFrame = CFrame.new(offset * s)
		end
	elseif style == "drop" then
		shot = shotPart(model, "Shot", Vector3.one * math.max(base, 1.2 * s), ROCK, Enum.Material.Slate, Enum.PartType.Ball)
	elseif style == "roll" then
		shot = shotPart(model, "Shot", Vector3.one * math.max(base, 2.5 * s), BOULDER, Enum.Material.Rock, Enum.PartType.Ball)
	elseif style == "capsule" then
		local length = math.max(base, 1.6 * s)
		local width = length * 0.4
		-- a cylinder lying along Z with rounded ends
		shot = shotPart(model, "Shot", Vector3.new(length, width, width), BONE, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		shot.CFrame = CFrame.Angles(0, math.rad(90), 0)
		shot.PivotOffset = shot.CFrame:Inverse() -- the model's pivot faces along the capsule
		for i, z in { -length / 2, length / 2 } do
			local cap = shotPart(model, `Cap{i}`, Vector3.one * width, BONE, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
			cap.CFrame = CFrame.new(0, 0, z)
		end
	else -- lob
		shot = shotPart(model, "Shot", Vector3.one * math.max(base, 0.8 * s), ROCK, Enum.Material.Rock, Enum.PartType.Ball)
	end
	model.PrimaryPart = shot
	model:SetAttribute("Style", style)
	model:SetAttribute("Height", shot.Size.Y) -- for rolling along the ground
	return model
end

-- Where a shot is `frac` (0..1) of the way through its flight, `age` seconds
-- after launch. `from` is the thrower, `to` the landing point on the ground.
function DinoLook.projectilePose(style: string, from: Vector3, to: Vector3, frac: number, age: number, height: number): CFrame
	local f = math.clamp(frac, 0, 1)
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	local heading = if flat.Magnitude > 0.01 then flat.Unit else Vector3.new(0, 0, -1)
	if style == "drop" then
		-- straight down from the flier's height onto the ring
		local top = Vector3.new(to.X, from.Y, to.Z)
		return CFrame.new(top:Lerp(to, f * f)) -- it speeds up as it falls
	elseif style == "roll" then
		local ground = Vector3.new(from.X, to.Y, from.Z):Lerp(to, f)
		local bounce = math.abs(math.sin(f * math.pi * 3)) * 0.6
		local spin = CFrame.fromAxisAngle(heading:Cross(Vector3.yAxis), -age * 6)
		return CFrame.new(ground + Vector3.new(0, height / 2 + bounce, 0)) * spin
	end
	local arc = if style == "lob" then math.max(4, flat.Magnitude * 0.35) elseif style == "gravel" then 1 else 0
	local point = from:Lerp(to, f) + Vector3.new(0, arc * 4 * f * (1 - f), 0)
	if style == "lob" then
		return CFrame.new(point) * CFrame.Angles(age * 5, age * 3, 0)
	end
	-- spike, gravel, capsule: point along the flight
	local ahead = from:Lerp(to, math.min(1, f + 0.02)) + Vector3.new(0, arc * 4 * (f + 0.02) * (1 - f - 0.02), 0)
	if (ahead - point).Magnitude < 1e-3 then
		return CFrame.lookAt(point, point + heading)
	end
	return CFrame.lookAt(point, ahead)
end

-- The orange ring on the ground where a shot will land.
function DinoLook.buildWarningRing(point: Vector3, radius: number): Part
	local ring = Instance.new("Part")
	ring.Name = "WarningRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.1, radius * 2, radius * 2)
	ring.CFrame = CFrame.new(point + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Color = DinoLook.RING_COLOR
	ring.Anchored = true
	cosmetic(ring)
	ring.Material = Enum.Material.Neon
	ring.Transparency = DinoLook.RING_FADE[1]
	return ring
end

-- The ring grows more solid as the shot comes in.
function DinoLook.ringTransparency(frac: number): number
	local f = math.clamp(frac, 0, 1)
	return DinoLook.RING_FADE[1] + (DinoLook.RING_FADE[2] - DinoLook.RING_FADE[1]) * f
end

return DinoLook
