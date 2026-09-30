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
	STORM = { -- Gallimimus: long legs and neck, built to run
		color = Color3.fromRGB(225, 195, 90),
		body = Vector3.new(1.2, 1.1, 2),
		legLength = 2.2,
		parts = biped(Vector3.new(1.2, 1.1, 2), 2.2, Vector3.new(0.5, 0.5, 0.9), {
			{ name = "Neck", size = Vector3.new(0.4, 1.4, 0.4), offset = Vector3.new(0, 1.1, -1), color = nil },
		}),
	},
	LLAMA = { -- Pteranodon: wings and a crest
		color = Color3.fromRGB(150, 125, 165),
		body = Vector3.new(0.9, 0.7, 1.8),
		legLength = 0,
		parts = {
			{ name = "WingL", size = Vector3.new(3.4, 0.15, 1.3), offset = Vector3.new(-2, 0.1, 0) },
			{ name = "WingR", size = Vector3.new(3.4, 0.15, 1.3), offset = Vector3.new(2, 0.1, 0) },
			{ name = "Head", size = Vector3.new(0.5, 0.5, 1.4), offset = Vector3.new(0, 0.3, -1.4) },
			{ name = "Crest", size = Vector3.new(0.2, 0.4, 1.1), offset = Vector3.new(0, 0.55, -0.6), color = Color3.fromRGB(220, 110, 90) },
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
		parts = biped(Vector3.new(4.5, 4.5, 7), 4, Vector3.new(3.2, 3, 4.2), {
			{ name = "Jaw", size = Vector3.new(2.8, 0.8, 3.4), offset = Vector3.new(0, 0.5, -6.1), color = Color3.fromRGB(55, 75, 45) },
			{ name = "ArmL", size = Vector3.new(0.4, 1.1, 0.4), offset = Vector3.new(-1.4, -0.4, -3), color = nil },
			{ name = "ArmR", size = Vector3.new(0.4, 1.1, 0.4), offset = Vector3.new(1.4, -0.4, -3), color = nil },
		}),
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
		part.CFrame = cframe * CFrame.new(spec.offset * scale)
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

-- Sedated by a Tranq Station: a small teal dart sticks out of the flank.
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
	-- Half in the right flank, pointing out and a little up.
	dart.CFrame = root.CFrame
		* CFrame.new(body.X / 2, body.Y * 0.15, 0)
		* CFrame.Angles(0, math.rad(90), 0)
		* CFrame.Angles(math.rad(25), 0, 0)
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

return DinoLook
