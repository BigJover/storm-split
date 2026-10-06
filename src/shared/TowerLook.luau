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
	setKnockedOut() shows a trampled one — tipped over about 15 degrees (which
	way depends on where it stands), dark Slate, a dust cloud, a few Slate debris blocks at its base, no range ring, and a
	TRAMPLED label (DECISIONS #9/#21). All of it undoes on repair.
	flashHit() tints a bitten tower red for a moment.
]]

local TowerLook = {}

TowerLook.COLORS = table.freeze({
	SCOUT = Color3.fromRGB(100, 140, 70), -- Hunting Blind: camo green
	SNIPER = Color3.fromRGB(200, 180, 130), -- Longshot Perch: khaki
	GRENADIER = Color3.fromRGB(120, 115, 70), -- Mortar Pit: olive
	CHILLER = Color3.fromRGB(70, 190, 180), -- Tranq Station: tranquilizer teal
	QUARTERMASTER = Color3.fromRGB(230, 150, 50), -- Supply Camp: supply-crate orange
	ARMORY = Color3.fromRGB(115, 125, 140), -- Armory: plate-steel grey
	HOSPITAL = Color3.fromRGB(235, 232, 220), -- Field Hospital: canvas white
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
	-- Hunting Blind: a low camo hide with viewing slits all round and a leafy roof.
	SCOUT = function(color)
		local slit = Color3.fromRGB(25, 25, 20)
		return {
			block("Hide", Vector3.new(3, 2.6, 3), at(0, 1.3, 0), color, Enum.Material.Fabric),
			block("SlitFront", Vector3.new(2.2, 0.35, 0.1), at(0, 1.9, -1.45), slit, Enum.Material.Fabric),
			block("SlitBack", Vector3.new(2.2, 0.35, 0.1), at(0, 1.9, 1.45), slit, Enum.Material.Fabric),
			block("SlitLeft", Vector3.new(0.1, 0.35, 2.2), at(-1.45, 1.9, 0), slit, Enum.Material.Fabric),
			block("SlitRight", Vector3.new(0.1, 0.35, 2.2), at(1.45, 1.9, 0), slit, Enum.Material.Fabric),
			block("Roof", Vector3.new(3, 0.4, 3), at(0, 2.8, 0), LEAF, Enum.Material.Grass),
			block("Leaves", Vector3.new(1.6, 0.5, 1.4), at(-0.5, 3.2, 0.4), LEAF, Enum.Material.Grass),
		}
	end,
	-- Longshot Perch: a tree stand on four stilts, railed all round, a rifle
	-- over the front rail angled up.
	SNIPER = function(color)
		local parts = {
			block("Platform", Vector3.new(3, 0.3, 3), at(0, 3.6, 0), color, Enum.Material.Wood),
			block("RailFront", Vector3.new(3, 0.6, 0.2), at(0, 4.05, -1.4), DARK_WOOD, Enum.Material.Wood),
			block("RailBack", Vector3.new(3, 0.6, 0.2), at(0, 4.05, 1.4), DARK_WOOD, Enum.Material.Wood),
			block("RailLeft", Vector3.new(0.2, 0.6, 2.6), at(-1.4, 4.05, 0), DARK_WOOD, Enum.Material.Wood),
			block("RailRight", Vector3.new(0.2, 0.6, 2.6), at(1.4, 4.05, 0), DARK_WOOD, Enum.Material.Wood),
			block("Roof", Vector3.new(3, 0.25, 3), at(0, 4.85, 0), DARK_WOOD, Enum.Material.Wood),
			block("Barrel", Vector3.new(0.2, 0.2, 1), at(0.4, 4.5, -0.9) * CFrame.Angles(math.rad(30), 0, 0), STEEL, Enum.Material.Metal),
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
			table.insert(parts, block(`Fletching{i}`, Vector3.new(0.45, 0.3, 0.05), at(x, 2.5, -0.3), Color3.fromRGB(230, 225, 210), Enum.Material.Fabric))
		end
		return parts
	end,
	-- Field Hospital: a white canvas A-frame tent with a green "+" on each side
	-- (green, never a red cross: DINO_REVIEW R2).
	HOSPITAL = function(color)
		local green = Color3.fromRGB(60, 190, 90)
		local lean = math.atan(1.35 / 2.5) -- each canvas side, from upright
		local length = math.sqrt(1.35 ^ 2 + 2.5 ^ 2)
		local parts = {
			block("Groundsheet", Vector3.new(2.9, 0.1, 2.9), at(0, 0.05, 0), Color3.fromRGB(120, 110, 90), Enum.Material.Fabric),
			block("Ridge", Vector3.new(0.2, 0.2, 2.9), at(0, 2.55, 0), WOOD, Enum.Material.Wood),
		}
		for _, side in { -1, 1 } do
			local name = if side < 0 then "Left" else "Right"
			local canvas = at(side * 0.675, 1.3, 0) * CFrame.Angles(0, 0, -side * lean)
			table.insert(parts, block(`Canvas{name}`, Vector3.new(0.15, length, 2.8), canvas, color, Enum.Material.Fabric))
			-- the "+" lies on the outside of the canvas
			local face = canvas * CFrame.new(side * 0.1, 0.25, 0)
			table.insert(parts, block(`Cross{name}V`, Vector3.new(0.05, 0.9, 0.28), face, green, Enum.Material.Neon))
			table.insert(parts, block(`Cross{name}H`, Vector3.new(0.05, 0.28, 0.9), face, green, Enum.Material.Neon))
		end
		return parts
	end,
	-- Armory: a dark wood back wall with a gun rack, a steel plate shield in front.
	ARMORY = function(color)
		local parts = {
			block("Floor", Vector3.new(3, 0.3, 3), at(0, 0.15, 0), WOOD, Enum.Material.WoodPlanks),
			block("Wall", Vector3.new(3, 3.6, 0.4), at(0, 1.8, 1.3), DARK_WOOD, Enum.Material.Wood),
			block("RackLow", Vector3.new(2.6, 0.15, 0.2), at(0, 1.2, 1), DARK_WOOD, Enum.Material.Wood),
			block("RackHigh", Vector3.new(2.6, 0.15, 0.2), at(0, 2.8, 1), DARK_WOOD, Enum.Material.Wood),
			block("Plate", Vector3.new(1.8, 2, 0.25), at(0, 1.3, -0.9) * CFrame.Angles(math.rad(-10), 0, 0), color, Enum.Material.Metal),
			block("Boss", Vector3.new(0.5, 0.5, 0.15), at(0, 1.35, -1.08) * CFrame.Angles(math.rad(-10), 0, 0), STEEL, Enum.Material.Metal),
		}
		-- Rifles on the rack: a wooden stock at the base, a shorter steel barrel above.
		for i, x in { -0.9, -0.3, 0.3, 0.9 } do
			table.insert(parts, block(`Stock{i}`, Vector3.new(0.25, 0.6, 0.25), at(x, 1.25, 0.85), WOOD, Enum.Material.Wood))
			table.insert(parts, block(`Gun{i}`, Vector3.new(0.15, 1.5, 0.15), at(x, 2.3, 0.85), STEEL, Enum.Material.Metal))
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

-- Does this tower have its own silhouette yet? (The round-4 batch gets theirs in
-- its behaviour tasks, PLAN T64-T67; until then the plain body shows.)
function TowerLook.hasSilhouette(key: string): boolean
	return SILHOUETTES[key] ~= nil
end

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
local TRAMPLED_COLOR = Color3.fromRGB(45, 45, 48)
local TRAMPLED_TEXT = Color3.fromRGB(255, 120, 110)
local HP_GOOD = Color3.fromRGB(110, 210, 110)
-- One orange for "low HP" on every bar, the hunter's (Hud) and the towers';
-- red stays for hits and Trampled.
TowerLook.LOW_HP_COLOR = Color3.fromRGB(230, 170, 60)
local HIT_COLOR = Color3.fromRGB(255, 60, 60)
local HIT_FLASH = 0.15 -- seconds
local DUST_COLOR = Color3.fromRGB(150, 125, 90)

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
	fill.BackgroundColor3 = if shown < 0.35 then TowerLook.LOW_HP_COLOR else HP_GOOD
end

-- Everything that makes up the visible tower (the silhouette and the crown).
local function visibleParts(model: Model): { BasePart }
	local parts = {}
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") and (part:GetAttribute("LookMaterial") ~= nil or part.Name == "Crown" or part:GetAttribute("OwnerFlag")) then
			table.insert(parts, part)
		end
	end
	return parts
end

-- Ends a hit flash early (or on time): every part gets its colour back.
function TowerLook.endHitFlash(model: Model)
	if not model:GetAttribute("HitFlash") then
		return
	end
	model:SetAttribute("HitFlash", nil)
	for _, part in visibleParts(model) do
		local color = part:GetAttribute("FlashColor")
		if typeof(color) == "Color3" then
			part.Color = color
		end
		part:SetAttribute("FlashColor", nil)
	end
end

-- A bitten (or hit) tower's silhouette flashes red for a moment. Not on a
-- trampled tower.
function TowerLook.flashHit(model: Model)
	if model:GetAttribute("Trampled") or model:GetAttribute("HitFlash") then
		return
	end
	model:SetAttribute("HitFlash", true)
	for _, part in visibleParts(model) do
		part:SetAttribute("FlashColor", part.Color)
		part.Color = HIT_COLOR
	end
	task.delay(HIT_FLASH, function()
		TowerLook.endHitFlash(model)
	end)
end

-- Visuals only.
local SAVED_COLOR = Color3.fromRGB(60, 190, 90) -- the hospital's green "+"
local SAVED_FLASH = 0.3 -- seconds
local SAVED_LABEL_TIME = 1.2 -- seconds
local CROSS_PULSE_COLOR = Color3.fromRGB(200, 255, 210)

-- Last Stand saved this tower: its silhouette flashes green for a moment and
-- a short "Last Stand!" label pops up. Shares the hit flash's colour restore.
function TowerLook.flashSaved(model: Model)
	local body = model.PrimaryPart
	if not body or model:GetAttribute("Trampled") then
		return
	end
	TowerLook.endHitFlash(model)
	model:SetAttribute("HitFlash", true)
	for _, part in visibleParts(model) do
		part:SetAttribute("FlashColor", part.Color)
		part.Color = SAVED_COLOR
	end
	task.delay(SAVED_FLASH, function()
		TowerLook.endHitFlash(model)
	end)
	local old = body:FindFirstChild("LastStand")
	if old then
		old:Destroy()
	end
	local label = Instance.new("BillboardGui")
	label.Name = "LastStand"
	label.Size = UDim2.fromOffset(120, 26)
	label.StudsOffset = Vector3.new(0, body.Size.Y / 2 + 4.6, 0)
	label.MaxDistance = 120
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = "Last Stand!"
	text.TextColor3 = SAVED_COLOR
	text.TextStrokeTransparency = 0.3
	text.Font = Enum.Font.GothamBlack
	text.TextScaled = true
	text.Parent = label
	label.Parent = body
	task.delay(SAVED_LABEL_TIME, function()
		if label.Parent then
			label:Destroy()
		end
	end)
end

-- The hospital whose Last Stand just fired: its green "+" pulses bright.
function TowerLook.pulseCross(model: Model)
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") and part.Name:sub(1, 5) == "Cross" and part:GetAttribute("PulseColor") == nil then
			part:SetAttribute("PulseColor", part.Color)
			part.Color = CROSS_PULSE_COLOR
			task.delay(SAVED_FLASH, function()
				local color = part:GetAttribute("PulseColor")
				if typeof(color) == "Color3" then
					part.Color = color
				end
				part:SetAttribute("PulseColor", nil)
			end)
		end
	end
end

-- What a hit looks like (Combat.hitOutcome): red flash on a plain hit;
-- green save flash, plus the saving hospital's pulse, on a Last Stand.
function TowerLook.showHit(model: Model, outcome: string, saver: Model?)
	if outcome == "saved" then
		TowerLook.flashSaved(model)
		if saver then
			TowerLook.pulseCross(saver)
		end
	elseif outcome == "hit" then
		TowerLook.flashHit(model)
	end
end

-- A Field Hospital with a Rescue Beacon: a wooden pole with a green Neon
-- lantern at the tent's front corner, inside the 3x3x5 box. Driven by the
-- tower's stats (rescueRespawnMult > 0), not its tier.
local LANTERN_X, LANTERN_Z = 1.25, -1.25
function TowerLook.setLantern(model: Model, on: boolean)
	local body = model.PrimaryPart
	local pole, lantern = model:FindFirstChild("BeaconPole"), model:FindFirstChild("BeaconLantern")
	if not on or not body then
		if pole then
			pole:Destroy()
		end
		if lantern then
			lantern:Destroy()
		end
		return
	end
	if pole and lantern then
		return
	end
	local base = body.CFrame * CFrame.new(0, -body.Size.Y / 2, 0)
	local specs = {
		{ "BeaconPole", Vector3.new(0.15, 3.4, 0.15), 1.7, WOOD, Enum.Material.Wood },
		{ "BeaconLantern", Vector3.new(0.4, 0.45, 0.4), 3.6, SAVED_COLOR, Enum.Material.Neon },
	}
	for _, spec in specs do
		local part = Instance.new("Part")
		part.Name = spec[1]
		part.Size = spec[2]
		part.CFrame = base * CFrame.new(LANTERN_X, spec[3], LANTERN_Z)
		part.Color = spec[4]
		part.Material = spec[5]
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part:SetAttribute("LookMaterial", spec[5].Name)
		part.Parent = model
	end
end

-- Which way a trampled tower tips: picked from where it stands, so a row of
-- trampled towers doesn't all fall the same way. A horizontal axis.
function TowerLook.tipAxis(base: Vector3): Vector3
	local step = (math.floor(base.X) * 7 + math.floor(base.Z) * 13) % 8
	local angle = math.rad(step * 45)
	return Vector3.new(math.cos(angle), 0, math.sin(angle))
end

function TowerLook.setKnockedOut(model: Model, on: boolean)
	local body = model.PrimaryPart
	if not body or (model:GetAttribute("Trampled") == true) == on then
		return
	end
	TowerLook.endHitFlash(model) -- so the colours saved below are the real ones
	model:SetAttribute("Trampled", on)
	local ring = model:FindFirstChild("Range")
	local base = body.CFrame * CFrame.new(0, -body.Size.Y / 2, 0)

	if on then
		-- Tip over about the base, go dark.
		local axis = TowerLook.tipAxis(base.Position)
		local tilt = base * CFrame.fromAxisAngle(axis, TRAMPLED_TILT) * base:Inverse()
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
		local dust = Instance.new("Smoke") -- a dust cloud, not fire smoke
		dust.Name = "TrampledDust"
		dust.Color = DUST_COLOR
		dust.Opacity = 0.2
		dust.RiseVelocity = 1.5
		dust.Size = 2
		dust.Parent = body
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
		for _, name in { "TrampledDust", "Trampled" } do
			local thing = body:FindFirstChild(name)
			if thing then
				thing:Destroy()
			end
		end
	end
end

-- The builder's tower flag (PLAN T57, a cosmetic): a thin pole at the body's back corner
-- with a small pennant in `color`. Inside the tower's footprint (Track.TowerRadius), and
-- it can't collide, be hit or be touched, so it changes nothing in play. It tips over
-- and flashes with the tower (visibleParts) but never glows at stage 2.
TowerLook.FLAG_POLE = "OwnerFlagPole"
TowerLook.FLAG_CLOTH = "OwnerFlag"
function TowerLook.addFlag(model: Model, color: Color3)
	local body = model.PrimaryPart
	if not body then
		return
	end
	local top = model:GetAttribute("LookTop") or body.Size.Y
	local foot = body.CFrame * CFrame.new(1.2, -body.Size.Y / 2, 1.2)
	local poleHeight = top + 1.4
	local function part(name: string, size: Vector3, cf: CFrame, partColor: Color3, material: Enum.Material)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = partColor
		p.Material = material
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p:SetAttribute("OwnerFlag", true)
		p.Parent = model
	end
	part(TowerLook.FLAG_POLE, Vector3.new(0.12, poleHeight, 0.12), foot * CFrame.new(0, poleHeight / 2, 0), Color3.fromRGB(90, 70, 50), Enum.Material.Wood)
	part(TowerLook.FLAG_CLOTH, Vector3.new(0.06, 0.55, 0.85), foot * CFrame.new(0, poleHeight - 0.35, -0.45), color, Enum.Material.Fabric)
end

function TowerLook.refresh(model: Model, range: number, tiers: { number }, stage: number)
	setRing(model, range)
	setTierLabel(model, tiers)
	setStage(model, stage)
end

return TowerLook
