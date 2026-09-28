--[[
	What a tower looks like. Visuals only — shared so the server's real towers
	and the client's placement ghost are built the same way.

	The body is 3x3 studs; Track.TowerRadius must stay at least its
	half-diagonal (2.12) or towers could visually overlap.
]]

local TowerLook = {}

TowerLook.COLORS = table.freeze({
	SCOUT = Color3.fromRGB(96, 170, 255),
	SNIPER = Color3.fromRGB(240, 240, 240),
	GRENADIER = Color3.fromRGB(255, 140, 60),
	CHILLER = Color3.fromRGB(120, 230, 255),
	QUARTERMASTER = Color3.fromRGB(250, 205, 80),
})

TowerLook.BODY_HEIGHT = 5
local BODY_SIZE = Vector3.new(3, TowerLook.BODY_HEIGHT, 3)
local RING_MAX_RANGE = 200 -- Sniper's "global" 999 range would draw a 2000-stud disc

-- Builds the model with its base centred on `base`. PrimaryPart is "Body".
function TowerLook.build(key: string, range: number, base: Vector3): Model
	local model = Instance.new("Model")
	model.Name = key

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = BODY_SIZE
	body.CFrame = CFrame.new(base + Vector3.new(0, BODY_SIZE.Y / 2, 0))
	body.Color = TowerLook.COLORS[key] or Color3.new(1, 1, 1)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.Parent = model
	model.PrimaryPart = body

	if range > 0 and range <= RING_MAX_RANGE then
		local ring = Instance.new("Part")
		ring.Name = "Range"
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.1, range * 2, range * 2)
		ring.CFrame = CFrame.new(base + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90))
		ring.Color = body.Color
		ring.Transparency = 0.85
		ring.Material = Enum.Material.Neon
		ring.Anchored = true
		ring.CanCollide = false
		ring.CanQuery = false
		ring.CanTouch = false
		ring.CastShadow = false
		ring.Parent = model
	end

	return model
end

return TowerLook
