--[[
	What a tower looks like. Visuals only — shared so the server's real towers
	and the client's placement ghost are built the same way.

	The body is 3x3 studs; Track.TowerRadius must stay at least its
	half-diagonal (2.12) or towers could visually overlap.

	Upgrades call refresh(): the range ring follows the tower's real range, a
	label shows its path tiers, and the look changes at the model-swap tiers
	(3 and 5): a crown at the first, a glowing body at the second.
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

	TowerLook.refresh(model, range, { 0, 0, 0 }, 0)
	return model
end

local function setRing(model: Model, range: number)
	local body = model.PrimaryPart
	local ring = model:FindFirstChild("Range") :: BasePart?
	if range <= 0 or range > RING_MAX_RANGE or not body then
		if ring then
			ring:Destroy()
		end
		return
	end
	if not ring then
		local new = Instance.new("Part")
		new.Name = "Range"
		new.Shape = Enum.PartType.Cylinder
		new.Transparency = 0.85
		new.Material = Enum.Material.Neon
		new.Anchored = true
		new.CanCollide = false
		new.CanQuery = false
		new.CanTouch = false
		new.CastShadow = false
		new.Parent = model
		ring = new
	end
	assert(ring)
	local base = body.Position - Vector3.new(0, body.Size.Y / 2, 0)
	ring.Size = Vector3.new(0.1, range * 2, range * 2)
	ring.CFrame = CFrame.new(base + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Color = body.Color
end

local function setTierLabel(model: Model, tiers: { number })
	local body = model.PrimaryPart
	if not body then
		return
	end
	local label = body:FindFirstChild("Tiers") :: BillboardGui?
	local any = tiers[1] + tiers[2] + tiers[3] > 0
	if not any then
		if label then
			label:Destroy()
		end
		return
	end
	if not label then
		local gui = Instance.new("BillboardGui")
		gui.Name = "Tiers"
		gui.Size = UDim2.fromOffset(90, 26)
		gui.StudsOffset = Vector3.new(0, body.Size.Y / 2 + 2, 0)
		gui.AlwaysOnTop = true
		gui.MaxDistance = 80
		local text = Instance.new("TextLabel")
		text.Name = "Text"
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundColor3 = Color3.fromRGB(24, 20, 34)
		text.BackgroundTransparency = 0.3
		text.TextColor3 = Color3.fromRGB(240, 236, 250)
		text.Font = Enum.Font.GothamBold
		text.TextSize = 16
		text.Parent = gui
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = text
		gui.Parent = body
		label = gui
	end
	assert(label)
	local text = label:FindFirstChild("Text") :: TextLabel
	text.Text = `{tiers[1]} · {tiers[2]} · {tiers[3]}`
end

-- `stage` counts model swaps reached: 0 plain, 1 crowned, 2 crowned and glowing.
local function setStage(model: Model, stage: number)
	local body = model.PrimaryPart
	if not body then
		return
	end
	local crown = model:FindFirstChild("Crown")
	if stage >= 1 and not crown then
		local part = Instance.new("Part")
		part.Name = "Crown"
		part.Size = Vector3.new(3, 0.8, 3) -- no wider than the body (Track.TowerRadius)
		part.CFrame = body.CFrame * CFrame.new(0, body.Size.Y / 2 + 0.4, 0)
		part.Color = Color3.fromRGB(250, 205, 80)
		part.Material = Enum.Material.Metal
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Parent = model
	elseif stage < 1 and crown then
		crown:Destroy()
	end
	body.Material = if stage >= 2 then Enum.Material.Neon else Enum.Material.SmoothPlastic
end

function TowerLook.refresh(model: Model, range: number, tiers: { number }, stage: number)
	setRing(model, range)
	setTierLabel(model, tiers)
	setStage(model, stage)
end

return TowerLook
