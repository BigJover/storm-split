--!strict
--[[
	Raptor Pen walkers' looks (PLAN 9g T124; visual only): blocky tamed raptors with a collar
	and a back stripe in the camp colour. Kinds: "raptor" (the pack), "alpha" (Alpha Raptor:
	one big raptor), "rex" (Rex Tamer: a small tamed T. rex), "swarm" (Raptor Swarm: small
	raptors). Anchored and ghost-like to physics (no collision, touch or query): walkers
	never block hunters (#315). The model's PrimaryPart is its body; it faces -Z.
]]

local RaptorLook = {}

RaptorLook.KINDS = table.freeze({ raptor = 1, alpha = 1.6, rex = 1.9, swarm = 0.6 })

local HIDE = Color3.fromRGB(150, 120, 70)
local REX_HIDE = Color3.fromRGB(110, 120, 75)
local BELLY = Color3.fromRGB(215, 195, 150)
local CLAW = Color3.fromRGB(235, 230, 215)

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

-- One walker's model. `camp`: the collar and stripe colour.
function RaptorLook.build(kind: string, camp: Color3): Model
	local scale = RaptorLook.KINDS[kind] or 1
	local rex = kind == "rex"
	local hide = if rex then REX_HIDE else HIDE
	local model = Instance.new("Model")
	model.Name = if rex then "TamedRex" elseif kind == "alpha" then "AlphaRaptor" else "Raptor"
	local body = part(model, "Body", Vector3.new(0.9, 0.8, 1.8), CFrame.new(0, 0, 0), hide, scale)
	part(model, "Belly", Vector3.new(0.8, 0.3, 1.4), CFrame.new(0, -0.35, 0), BELLY, scale)
	local head = if rex then Vector3.new(1, 0.9, 1.3) else Vector3.new(0.6, 0.55, 1)
	part(model, "Head", head, CFrame.new(0, if rex then 0.75 else 0.6, -1.3), hide, scale)
	part(model, "Neck", Vector3.new(0.45, 0.7, 0.45), CFrame.new(0, 0.35, -0.85) * CFrame.Angles(math.rad(-30), 0, 0), hide, scale)
	part(model, "Tail", Vector3.new(0.35, 0.35, 1.8), CFrame.new(0, 0.2, 1.6) * CFrame.Angles(math.rad(10), 0, 0), hide, scale)
	part(model, "LegL", Vector3.new(0.25, 0.9, 0.3), CFrame.new(-0.3, -0.75, 0.2), hide, scale)
	part(model, "LegR", Vector3.new(0.25, 0.9, 0.3), CFrame.new(0.3, -0.75, 0.2), hide, scale)
	if rex then
		part(model, "ArmL", Vector3.new(0.12, 0.3, 0.12), CFrame.new(-0.35, 0.05, -0.75), hide, scale)
		part(model, "ArmR", Vector3.new(0.12, 0.3, 0.12), CFrame.new(0.35, 0.05, -0.75), hide, scale)
	else
		part(model, "Claw", Vector3.new(0.12, 0.35, 0.12), CFrame.new(0.3, -1.15, -0.05) * CFrame.Angles(math.rad(40), 0, 0), CLAW, scale)
	end
	-- Tamed: a collar and a back stripe in the camp colour.
	part(model, "Collar", Vector3.new(0.6, 0.2, 0.6), CFrame.new(0, 0.55, -0.95) * CFrame.Angles(math.rad(-30), 0, 0), camp, scale)
	part(model, "Stripe", Vector3.new(0.2, 0.05, 1.6), CFrame.new(0, 0.42, 0), camp, scale)
	model.PrimaryPart = body
	return model
end

return RaptorLook
