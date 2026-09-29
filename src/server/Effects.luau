--[[
	Short-lived visual effects: tracers, blasts, burning patches. Visuals only —
	nothing here affects gameplay. Shared by towers and the hero.
]]

local Debris = game:GetService("Debris")

local Effects = {}

local TRACER_LIFETIME = 0.06

local folder: Instance

function Effects.init(effectFolder: Instance)
	folder = effectFolder
end

-- A neon part that disappears after `lifetime` seconds.
function Effects.part(size: Vector3, cframe: CFrame, color: Color3, lifetime: number, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = color
	if shape then
		part.Shape = shape
	end
	part.Size = size
	part.CFrame = cframe
	part.Parent = folder
	Debris:AddItem(part, lifetime)
	return part
end

function Effects.tracer(from: Vector3, to: Vector3, color: Color3)
	local length = (to - from).Magnitude
	if length < 0.1 then
		return
	end
	Effects.part(Vector3.new(0.15, 0.15, length), CFrame.lookAt((from + to) / 2, to), color, TRACER_LIFETIME)
end

-- A flat disc lying on the ground, e.g. a burning patch or a blast zone.
function Effects.disc(centre: Vector3, radius: number, color: Color3, lifetime: number, transparency: number): Part
	local part = Effects.part(
		Vector3.new(0.3, radius * 2, radius * 2),
		CFrame.new(centre) * CFrame.Angles(0, 0, math.rad(90)),
		color,
		lifetime,
		Enum.PartType.Cylinder
	)
	part.Transparency = transparency
	return part
end

return Effects
