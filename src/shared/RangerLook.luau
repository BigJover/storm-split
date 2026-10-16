--!strict
--[[
	Ranger Station walkers' looks (PLAN 9j T129; visual only): blocky rangers in khaki with a
	hat band and a scarf in the camp colour, a rifle. Kinds: "ranger", "heavy" (Heavy Rifle: a
	longer, thicker barrel), "legend" (Legend Ranger: bigger, a long coat). The Patrol Jeep is
	buildJeep's. Anchored and ghost-like to physics (no collision, touch or query): walkers
	never block hunters (#315). The model's PrimaryPart is its body; it faces -Z.
]]

local RangerLook = {}

RangerLook.KINDS = table.freeze({ ranger = 1, heavy = 1.1, legend = 1.35 })

local KHAKI = Color3.fromRGB(176, 160, 110)
local DARK_KHAKI = Color3.fromRGB(120, 105, 70)
local SKIN = Color3.fromRGB(225, 185, 150)
local GUN = Color3.fromRGB(55, 50, 45)
local BOOT = Color3.fromRGB(70, 50, 35)

local function part(model: Model, name: string, size: Vector3, at: CFrame, color: Color3, scale: number): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size * scale
	p.CFrame = CFrame.new(at.Position * scale) * at.Rotation
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Parent = model
	return p
end

-- One ranger's model. `camp`: the hat band and scarf colour.
function RangerLook.build(kind: string, camp: Color3): Model
	local scale = RangerLook.KINDS[kind] or 1
	local model = Instance.new("Model")
	model.Name = if kind == "legend" then "LegendRanger" else "Ranger"
	local body = part(model, "Body", Vector3.new(0.9, 1.1, 0.5), CFrame.new(0, 0, 0), KHAKI, scale)
	part(model, "Head", Vector3.new(0.55, 0.55, 0.55), CFrame.new(0, 0.85, 0), SKIN, scale)
	part(model, "Hat", Vector3.new(0.95, 0.12, 0.95), CFrame.new(0, 1.15, 0), DARK_KHAKI, scale)
	part(model, "HatBand", Vector3.new(0.6, 0.12, 0.6), CFrame.new(0, 1.24, 0), camp, scale)
	part(model, "Scarf", Vector3.new(0.7, 0.15, 0.55), CFrame.new(0, 0.5, 0), camp, scale)
	part(model, "LegL", Vector3.new(0.35, 0.8, 0.4), CFrame.new(-0.22, -0.95, 0), DARK_KHAKI, scale)
	part(model, "LegR", Vector3.new(0.35, 0.8, 0.4), CFrame.new(0.22, -0.95, 0), DARK_KHAKI, scale)
	part(model, "Boots", Vector3.new(0.85, 0.2, 0.5), CFrame.new(0, -1.4, -0.05), BOOT, scale)
	local barrel = if kind == "heavy" then Vector3.new(0.2, 0.2, 1.8) else Vector3.new(0.12, 0.12, 1.3)
	part(model, "Rifle", barrel, CFrame.new(0.4, 0.15, -0.6), GUN, scale)
	if kind == "legend" then
		part(model, "Coat", Vector3.new(1.0, 0.9, 0.6), CFrame.new(0, -0.35, 0.05), DARK_KHAKI, scale)
	end
	model.PrimaryPart = body
	return model
end

-- Patrol Jeep: an open khaki jeep with a camp-colour stripe (the rangers ride on it).
function RangerLook.buildJeep(camp: Color3): Model
	local model = Instance.new("Model")
	model.Name = "PatrolJeep"
	local body = part(model, "Body", Vector3.new(3, 0.9, 5), CFrame.new(0, 0, 0), KHAKI, 1)
	part(model, "Hood", Vector3.new(2.8, 0.3, 1.6), CFrame.new(0, 0.55, -1.6), DARK_KHAKI, 1)
	part(model, "Stripe", Vector3.new(0.5, 0.05, 4.8), CFrame.new(0, 0.48, 0), camp, 1)
	part(model, "Roll", Vector3.new(2.8, 0.2, 0.2), CFrame.new(0, 1.6, 0.6), GUN, 1)
	for i, spot in { { -1.5, -1.6 }, { 1.5, -1.6 }, { -1.5, 1.6 }, { 1.5, 1.6 } } do
		part(model, `Wheel{i}`, Vector3.new(0.4, 1, 1), CFrame.new(spot[1], -0.4, spot[2]), GUN, 1)
	end
	model.PrimaryPart = body
	return model
end

return RangerLook
