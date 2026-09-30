--[[
	What a tower looks like. Visuals only — shared so the server's real towers
	and the client's placement ghost are built the same way.

	The body is an invisible 3x3x5 box: the part that anchors the model, carries
	the prompt, label and attributes, and blocks players. What you see is a
	block silhouette per tower in real materials (a hide, a tree stand, a
	sandbagged mortar, a dart barrel, stacked crates), always inside the body's
	box. Track.TowerRadius must stay at least the body's half-diagonal (2.12) or
	towers could visually overlap.

	Upgrades call refresh(): the range ring follows the tower's real range, a
	label shows its path tiers, and the look changes at the model-swap tiers
	(3 and 5): a crown on top at the first, a glowing silhouette at the second.

	Health (Step 2): setHealth() shows a small bar over a damaged tower;
	setKnockedOut() shows a trampled one — tipped over about 15 degrees, dark
	Slate, smoking, a few Slate debris blocks at its base, no range ring, and a
	TRAMPLED label (DECISIONS #9/#21). All of it undoes on repair.
]]

local TowerLook = {}

TowerLook.COLORS = table.freeze({
	SCOUT = Color3.fromRGB(100, 140, 70), -- Hunting Blind: camo green
	SNIPER = Color3.fromRGB(200, 180, 130), -- Longshot Perch: khaki
	GRENADIER = Color3.fromRGB(120, 115, 70), -- Mortar Pit: olive
	CHILLER = Color3.fromRGB(70, 190, 180), -- Tranq Station: tranquilizer teal
	QUARTERMASTER = Color3.fromRGB(230, 150, 50), -- Supply Camp: supply-crate orange
})

TowerLook.BODY_HEIGHT = 5
local BODY_SIZE = Vector3.new(3, TowerLook.BODY_HEIGHT, 3)
local RING_MAX_RANGE = 200 -- Sniper's "global" 999 range would draw a 2000-stud disc
local RING_TRANSPARENCY = 0.85

------------------------------------------------------------------ silhouettes

-- Visuals only.
local WOOD = Color3.fromRGB(110, 80, 50)
local DARK_WOOD = Color3.fromRGB(70, 50, 32)
local SAND = Color3.fromRGB(190, 170, 120)
local STEEL = Color3.fromRGB(70, 72, 75)
local LEAF = Color3.fromRGB(70, 110, 50)
local DART_TIP = Color3.fromRGB(60, 210, 190)
local CYLINDER = Enum.PartType.Cylinder

-- One silhouette block: `at` is its centre, measured from the tower's base
-- (the ground under the body's centre). Anchored and ghost-like to physics:
-- the body does the colliding.
type Block = { name: string, size: Vector3, at: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType? }

local function block(name: string, size: Vector3, at: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Block
	return { name = name, size = size, at = at, color = color, material = material, shape = shape }
end

local function at(x: number, y: number, z: number): CFrame
	return CFrame.new(x, y, z)
end

-- Each list stays inside the 3x3x5 body box (x and z within +-1.5, y 0..5),
-- so the look never reaches past Track.TowerRadius. `color` is the tower's
-- colour; the rest are material colours.
local SILHOUETTES: { [string]: (color: Color3) -> { Block } } = {
	-- Hunting Blind: a low camo hide with a viewing slit and a leafy roof.
	SCOUT = function(color)
		return {
			block("Hide", Vector3.new(3, 2.6, 3), at(0, 1.3, 0), color, Enum.Material.Fabric),
			block("Slit", Vector3.new(2.2, 0.35, 0.1), at(0, 1.9, -1.45), Color3.fromRGB(25, 25, 20), Enum.Material.Fabric),
			block("Roof", Vector3.new(3, 0.4, 3), at(0, 2.8, 0), LEAF, Enum.Material.Grass),
			block("Leaves", Vector3.new(1.6, 0.5, 1.4), at(-0.5, 3.2, 0.4), LEAF, Enum.Material.Grass),
		}
	end,
	-- Longshot Perch: a tree stand on four stilts, a rifle over the rail.
	SNIPER = function(color)
		local parts = {
			block("Platform", Vector3.new(3, 0.3, 3), at(0, 3.6, 0), color, Enum.Material.Wood),
			block("Rail", Vector3.new(3, 0.6, 0.2), at(0, 4.05, -1.4), DARK_WOOD, Enum.Material.Wood),
			block("Roof", Vector3.new(3, 0.25, 3), at(0, 4.85, 0), DARK_WOOD, Enum.Material.Wood),
			block("Barrel", Vector3.new(0.2, 0.2, 1.3), at(0.4, 4.45, -0.8), STEEL, Enum.Material.Metal),
		}
		for i, corner in { Vector2.new(-1, -1), Vector2.new(1, -1), Vector2.new(-1, 1), Vector2.new(1, 1) } do
			table.insert(parts, block(`Stilt{i}`, Vector3.new(0.3, 3.45, 0.3), at(corner.X * 1.25, 1.725, corner.Y * 1.25), WOOD, Enum.Material.Wood))
			if corner.Y > 0 then
				table.insert(parts, block(`Post{i}`, Vector3.new(0.2, 1.1, 0.2), at(corner.X * 1.25, 4.3, corner.Y * 1.25), WOOD, Enum.Material.Wood))
			end
		end
		return parts
	end,
	-- Mortar Pit: a ring of sandbags around a tube angled at 45 degrees.
	GRENADIER = function(color)
		return {
			block("BagsFront", Vector3.new(3, 1, 0.7), at(0, 0.5, -1.15), SAND, Enum.Material.Fabric),
			block("BagsBack", Vector3.new(3, 1, 0.7), at(0, 0.5, 1.15), SAND, Enum.Material.Fabric),
			block("BagsLeft", Vector3.new(0.7, 1, 1.6), at(-1.15, 0.5, 0), SAND, Enum.Material.Fabric),
			block("BagsRight", Vector3.new(0.7, 1, 1.6), at(1.15, 0.5, 0), SAND, Enum.Material.Fabric),
			block("Plate", Vector3.new(1.4, 0.3, 1.4), at(0, 0.3, 0), STEEL, Enum.Material.Metal),
			block("Tube", Vector3.new(0.8, 0.8, 2.6), at(0, 1.4, 0) * CFrame.Angles(math.rad(45), 0, 0), color, Enum.Material.Metal),
		}
	end,
	-- Tranq Station: a teal barrel with a rack of three darts, tips glowing.
	CHILLER = function(color)
		local parts = {
			block("Barrel", Vector3.new(2.6, 2.2, 2.2), at(0, 1.3, 0.2) * CFrame.Angles(0, 0, math.rad(90)), color, Enum.Material.Metal, CYLINDER),
			block("Rack", Vector3.new(2.4, 0.2, 0.25), at(0, 2.7, -0.3), DARK_WOOD, Enum.Material.Wood),
		}
		for i, x in { -0.8, 0, 0.8 } do
			table.insert(parts, block(`Dart{i}`, Vector3.new(0.15, 1.3, 0.15), at(x, 3.0, -0.3), WOOD, Enum.Material.Wood))
			table.insert(parts, block(`Tip{i}`, Vector3.new(0.22, 0.35, 0.22), at(x, 3.8, -0.3), DART_TIP, Enum.Material.Neon))
		end
		return parts
	end,
	-- Supply Camp: stacked crates under an orange tarp, a flag on a pole.
	QUARTERMASTER = function(color)
		return {
			block("CrateA", Vector3.new(1.4, 1.4, 1.4), at(-0.7, 0.7, 0.6), WOOD, Enum.Material.Wood),
			block("CrateB", Vector3.new(1.4, 1.4, 1.4), at(0.7, 0.7, -0.5), WOOD, Enum.Material.Wood),
			block("CrateC", Vector3.new(1.2, 1.2, 1.2), at(-0.4, 2.0, 0.3), DARK_WOOD, Enum.Material.Wood),
			block("Tarp", Vector3.new(2.6, 0.2, 2.6), at(-0.1, 2.7, 0.05), color, Enum.Material.Fabric),
			block("Pole", Vector3.new(0.15, 4.4, 0.15), at(1.3, 2.2, 1.3), STEEL, Enum.Material.Metal),
			block("Flag", Vector3.new(0.08, 0.6, 1), at(1.3, 4.1, 0.75), color, Enum.Material.Fabric),
		}
	end,
}

-- How high the silhouette reaches above the base (the crown sits there).
local function silhouetteTop(blocks: { Block }): number
	local top = 0
	for _, b in blocks do
		local rotated = b.at - b.at.Position
		local half = b.size / 2
		-- the highest corner of the (possibly rotated) block
		local reach = math.abs(rotated.XVector.Y) * half.X + math.abs(rotated.YVector.Y) * half.Y + math.abs(rotated.ZVector.Y) * half.Z
		top = math.max(top, b.at.Position.Y + reach)
	end
	return top
end

-- Builds the model with its base centred on `base`. PrimaryPart is "Body".
function TowerLook.build(key: string, range: number, base: Vector3): Model
	local model = Instance.new("Model")
	model.Name = key
	local color = TowerLook.COLORS[key] or Color3.new(1, 1, 1)

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = BODY_SIZE
	body.CFrame = CFrame.new(base + Vector3.new(0, BODY_SIZE.Y / 2, 0))
	body.Color = color
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.Parent = model
	model.PrimaryPart = body

	local silhouette = SILHOUETTES[key]
	if silhouette then
		body.Transparency = 1 -- the silhouette is the look; the body stays the hitbox
		local blocks = silhouette(color)
		for _, b in blocks do
			local part = Instance.new("Part")
			part.Name = b.name
			if b.shape then
				part.Shape = b.shape
			end
			part.Size = b.size
			part.CFrame = CFrame.new(base) * b.at
			part.Color = b.color
			part.Material = b.material
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part:SetAttribute("LookMaterial", b.material.Name) -- restored if the glow goes
			part.Parent = model
		end
		model:SetAttribute("LookTop", silhouetteTop(blocks))
	end

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
		new.Transparency = RING_TRANSPARENCY
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
	local base = body.CFrame.Position - Vector3.new(0, body.Size.Y / 2, 0)
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
	model:SetAttribute("Stage", stage)
	local crown = model:FindFirstChild("Crown")
	if stage >= 1 and not crown then
		local part = Instance.new("Part")
		part.Name = "Crown"
		part.Size = Vector3.new(3, 0.8, 3) -- no wider than the body (Track.TowerRadius)
		-- on top of the silhouette (or of the body, for a tower without one)
		local top = model:GetAttribute("LookTop") or body.Size.Y
		part.CFrame = body.CFrame * CFrame.new(0, top - body.Size.Y / 2 + 0.4, 0)
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
	local glow = stage >= 2
	local lookParts = 0
	for _, part in model:GetChildren() do
		local material = part:GetAttribute("LookMaterial")
		if part:IsA("BasePart") and typeof(material) == "string" then
			lookParts += 1
			part.Material = if glow then Enum.Material.Neon else (Enum.Material :: any)[material]
		end
	end
	if lookParts == 0 then
		body.Material = if glow then Enum.Material.Neon else Enum.Material.SmoothPlastic
	end
end

------------------------------------------------------------------ health

-- Visuals only.
local TRAMPLED_TILT = math.rad(15)
local TRAMPLED_COLOR = Color3.fromRGB(60, 60, 64)
local TRAMPLED_TEXT = Color3.fromRGB(255, 120, 110)
local HP_GOOD = Color3.fromRGB(110, 210, 110)
local HP_LOW = Color3.fromRGB(235, 90, 70)

-- A small bar over the tower; hidden at full health.
function TowerLook.setHealth(model: Model, frac: number)
	local body = model.PrimaryPart
	if not body then
		return
	end
	local bar = body:FindFirstChild("HealthBar") :: BillboardGui?
	if frac >= 1 then
		if bar then
			bar:Destroy()
		end
		return
	end
	if not bar then
		local gui = Instance.new("BillboardGui")
		gui.Name = "HealthBar"
		gui.Size = UDim2.fromOffset(64, 8)
		gui.StudsOffset = Vector3.new(0, body.Size.Y / 2 + 3.4, 0)
		gui.MaxDistance = 80
		local back = Instance.new("Frame")
		back.Name = "Back"
		back.Size = UDim2.fromScale(1, 1)
		back.BackgroundColor3 = Color3.fromRGB(24, 20, 34)
		back.BorderSizePixel = 0
		back.Parent = gui
		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.BorderSizePixel = 0
		fill.Parent = back
		gui.Parent = body
		bar = gui
	end
	assert(bar)
	local fill = (bar:FindFirstChild("Back") :: Frame):FindFirstChild("Fill") :: Frame
	local shown = math.clamp(frac, 0, 1)
	fill.Size = UDim2.fromScale(shown, 1)
	fill.BackgroundColor3 = if shown < 0.35 then HP_LOW else HP_GOOD
end

-- Everything that makes up the visible tower (the silhouette and the crown).
local function visibleParts(model: Model): { BasePart }
	local parts = {}
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") and (part:GetAttribute("LookMaterial") ~= nil or part.Name == "Crown") then
			table.insert(parts, part)
		end
	end
	return parts
end

function TowerLook.setKnockedOut(model: Model, on: boolean)
	local body = model.PrimaryPart
	if not body or (model:GetAttribute("Trampled") == true) == on then
		return
	end
	model:SetAttribute("Trampled", on)
	local ring = model:FindFirstChild("Range")
	local base = body.CFrame * CFrame.new(0, -body.Size.Y / 2, 0)

	if on then
		-- Tip over about the base, go dark.
		local tilt = base * CFrame.Angles(TRAMPLED_TILT, 0, 0) * base:Inverse()
		for _, part in visibleParts(model) do
			part:SetAttribute("UprightCFrame", part.CFrame)
			part:SetAttribute("UprightColor", part.Color)
			part:SetAttribute("UprightMaterial", part.Material.Name)
			part.CFrame = tilt * part.CFrame
			part.Color = TRAMPLED_COLOR
			part.Material = Enum.Material.Slate
		end
		if ring and ring:IsA("BasePart") then
			ring.Transparency = 1
		end
		local smoke = Instance.new("Smoke")
		smoke.Name = "TrampledSmoke"
		smoke.Color = Color3.fromRGB(80, 80, 80)
		smoke.Opacity = 0.3
		smoke.RiseVelocity = 3
		smoke.Size = 2
		smoke.Parent = body
		for i, spot in { Vector3.new(-1, 0.25, 1), Vector3.new(0.9, 0.2, 0.8), Vector3.new(0.6, 0.3, -1.1) } do
			local debris = Instance.new("Part")
			debris.Name = `Debris{i}`
			debris.Size = Vector3.new(0.7, 0.4 + 0.1 * i, 0.5)
			debris.CFrame = base * CFrame.new(spot) * CFrame.Angles(0, math.rad(35 * i), math.rad(10 * i))
			debris.Color = TRAMPLED_COLOR
			debris.Material = Enum.Material.Slate
			debris.Anchored = true
			debris.CanCollide = false
			debris.CanQuery = false
			debris.CanTouch = false
			debris.Parent = model
		end
		local label = Instance.new("BillboardGui")
		label.Name = "Trampled"
		label.Size = UDim2.fromOffset(110, 26)
		label.StudsOffset = Vector3.new(0, body.Size.Y / 2 + 4.6, 0)
		label.MaxDistance = 120
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Text = "TRAMPLED"
		text.TextColor3 = TRAMPLED_TEXT
		text.TextStrokeTransparency = 0.3
		text.Font = Enum.Font.GothamBlack
		text.TextScaled = true
		text.Parent = label
		label.Parent = body
	else
		local glow = (model:GetAttribute("Stage") or 0) >= 2
		for _, part in visibleParts(model) do
			local upright = part:GetAttribute("UprightCFrame")
			if typeof(upright) == "CFrame" then
				part.CFrame = upright
			end
			local color = part:GetAttribute("UprightColor")
			if typeof(color) == "Color3" then
				part.Color = color
			end
			local material = part:GetAttribute("UprightMaterial")
			if typeof(material) == "string" then
				part.Material = (Enum.Material :: any)[material]
			end
			if glow and part:GetAttribute("LookMaterial") ~= nil then
				part.Material = Enum.Material.Neon
			end
		end
		if ring and ring:IsA("BasePart") then
			ring.Transparency = RING_TRANSPARENCY
		end
		for _, name in { "Debris1", "Debris2", "Debris3" } do
			local debris = model:FindFirstChild(name)
			if debris then
				debris:Destroy()
			end
		end
		for _, name in { "TrampledSmoke", "Trampled" } do
			local thing = body:FindFirstChild(name)
			if thing then
				thing:Destroy()
			end
		end
	end
end

function TowerLook.refresh(model: Model, range: number, tiers: { number }, stage: number)
	setRing(model, range)
	setTierLabel(model, tiers)
	setStage(model, stage)
end

return TowerLook
