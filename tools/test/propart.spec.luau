--[[
	Outpost props in their art (PLAN 11f T156, DECISIONS #426/#450/#455, tools/art/README
	"Outpost props"): Shared/PropArt, Shared/Decor's art and the art-only prop spots, on fake
	templates under Lune.
	1. No loaded art: nothing is added or hidden (today's camp and decorations exactly).
	2. Dressed: the art stands with its origin on the anchor, ghost pieces; every replaced block
	   is kept (size, CFrame, collision, query, touch, attributes, signs, lights) and only hidden,
	   and undress puts its Transparency back exactly. `face` pieces carry the sign.
	3. Decorations: body / accent = the Skins look in its material, cloth = the flag colour, the
	   Fire Pit's flames Neon, glow Neon, the Wanted Poster's signs on its face.
	4. The art-only spots (tent, signpost, Hunt Board) keep clear of everything already there.
	5. Every prop key Server/Outpost and Wardrobe dress is in ArtIds.
]]

local fs = require("@lune/fs")
local ArtSlot = require(src.shared.ArtSlot)
local ArtIds = require(src.shared.ArtIds)
local PropArt = require(src.shared.PropArt)
local Decor = require(src.shared.Decor)
local Outpost = require(src.shared.Outpost)

local ID = 9119
local ANCHOR = CFrame.new(4, 0.1, -30) * CFrame.Angles(0, 0.5, 0)

local function num(n: number): string
	if math.abs(n) < 5e-4 then
		n = 0
	end
	return string.format("%.3f", n)
end
local function vec(v: Vector3): string
	return `{num(v.X)},{num(v.Y)},{num(v.Z)}`
end

local function describe(inst: Instance, depth: number, out: { string })
	local line = `{string.rep(" ", depth)}{inst.ClassName} {inst.Name}`
	if inst:IsA("BasePart") then
		local c = inst.CFrame
		line ..= ` size={vec(inst.Size)} pos={vec(c.Position)} x={vec(c.XVector)} y={vec(c.YVector)}`
		line ..= ` rgb={num(inst.Color.R)},{num(inst.Color.G)},{num(inst.Color.B)} mat={inst.Material.Name}`
		line ..= ` tr={num(inst.Transparency)} anch={tostring(inst.Anchored)} coll={tostring(inst.CanCollide)}`
		line ..= ` q={tostring(inst.CanQuery)} t={tostring(inst.CanTouch)} sh={tostring(inst.CastShadow)}`
	elseif inst:IsA("SurfaceGui") then
		line ..= ` face={inst.Face.Name}`
	elseif inst:IsA("TextLabel") then
		line ..= ` text={inst.Text}`
	end
	local names = {}
	for n in inst:GetAttributes() do
		table.insert(names, n)
	end
	table.sort(names)
	for _, n in names do
		line ..= ` @{n}={tostring(inst:GetAttribute(n))}`
	end
	table.insert(out, line)
	for _, child in inst:GetChildren() do
		describe(child, depth + 1, out)
	end
end
local function print_(inst: Instance): string
	local out = {}
	describe(inst, 0, out)
	return table.concat(out, "\n")
end

local function withArt(art: Instance?, ids: any, fn: () -> ())
	ArtSlot.setIds(ids)
	ArtSlot.setSource(art)
	local success, err = pcall(fn)
	ArtSlot.setIds(nil)
	ArtSlot.setSource(nil)
	if not success then
		error(err, 0)
	end
end

-- A fake prop template for every prop key: a body piece, a glow piece and a face plate.
local function fakeArt(): (Instance, any)
	local art = Instance.new("Folder")
	art.Name = "Art"
	local folder = Instance.new("Folder")
	folder.Name = "prop"
	folder.Parent = art
	local ids: any = { prop = {} }
	for key, entry in ArtIds.prop do
		local model = Instance.new("Model")
		model.Name = key
		model:SetAttribute("ArtId", ID)
		for _, row in {
			{ "body", Vector3.new(2, 2, 2), Vector3.new(0, 1, 0) },
			{ "accent", Vector3.new(1, 0.5, 1), Vector3.new(0, 2.25, 0) },
			{ "cloth", Vector3.new(1, 0.5, 0.1), Vector3.new(0, 3, 0) },
			{ "glow", Vector3.new(0.5, 0.5, 0.5), Vector3.new(0, 2.8, 0) },
			{ "face", Vector3.new(2.1, 2, 0.05), Vector3.new(0, 2.3, -1.1) },
			{ "wood", Vector3.new(0.3, 3, 0.3), Vector3.new(1, 1.5, 0) },
		} do
			local p = Instance.new("MeshPart")
			p.Name = row[1]
			p.Size = row[2]
			p.CFrame = CFrame.new(row[3])
			p.CanCollide = true
			p.CanQuery = true
			p.Parent = model
		end
		model.Parent = folder
		ids.prop[key] = { model = ID, colors = entry.colors }
	end
	return art, ids
end

-- A little blocky prop: a colliding block with an attribute and a sign, and a light block.
local function blocky(): (Model, { BasePart })
	local m = Instance.new("Model")
	local a = Instance.new("Part")
	a.Name = "HatcheryHut"
	a.Size = Vector3.new(10, 7, 8)
	a.CFrame = ANCHOR * CFrame.new(0, 3.5, 0)
	a.Anchored = true
	a:SetAttribute("Station", "reach")
	local sign = Instance.new("BillboardGui")
	sign.Name = "Sign"
	sign.Parent = a
	a.Parent = m
	local b = Instance.new("Part")
	b.Name = "CampFire"
	b.Size = Vector3.new(3, 1.2, 3)
	b.CFrame = ANCHOR * CFrame.new(0, 0.7, 0)
	b.Material = Enum.Material.Neon
	b.Transparency = 0.2
	b.Anchored = true
	local light = Instance.new("PointLight")
	light.Parent = b
	b.Parent = m
	return m, { a, b }
end

test("no loaded art: PropArt adds and hides nothing; the real ids are colours only", function()
	for key, entry in ArtIds.prop do
		eq(entry.model, nil, `prop/{key} has no id yet`)
		eq(PropArt.loaded(key), false, `prop/{key} not loaded`)
	end
	local m, parts = blocky()
	local before = print_(m)
	eq(PropArt.dress(m, "HATCHERY_HUT", ANCHOR, parts), nil, "nothing dressed")
	PropArt.undress(m)
	eq(print_(m), before, "untouched")
	local art, ids = fakeArt()
	withArt(Instance.new("Folder"), ids, function()
		eq(PropArt.dress(m, "HATCHERY_HUT", ANCHOR, parts), nil, "ids but nothing loaded: nothing")
	end)
	art:SetAttribute("ArtOff", true)
	withArt(art, ids, function()
		eq(PropArt.dress(m, "HATCHERY_HUT", ANCHOR, parts), nil, "ArtOff: nothing")
	end)
	eq(print_(m), before, "still untouched")
end)

test("dressed: art on the anchor, ghost pieces; replaced blocks kept and only hidden; undress restores", function()
	local art, ids = fakeArt()
	withArt(art, ids, function()
		local m, parts = blocky()
		local before = print_(m)
		local dressed = PropArt.dress(m, "HATCHERY_HUT", ANCHOR, parts) :: Model
		ok(dressed ~= nil and dressed.Parent == m, "art model under the prop")
		eq(dressed.Name, "Art_HATCHERY_HUT", "named")
		ok(dressed:GetAttribute(PropArt.MARK) == true, "marked")
		local count = 0
		for _, p in dressed:GetDescendants() do
			if p:IsA("BasePart") then
				count += 1
				ok(p.Anchored and p.Massless and not p.CanCollide and not p.CanQuery and not p.CanTouch, `{p.Name} ghost`)
				if p:GetAttribute("PaintGroup") == "body" then
					eq(vec(p.CFrame.Position), vec((ANCHOR * CFrame.new(0, 1, 0)).Position), "origin on the anchor")
					eq(p.Color, ArtIds.prop.HATCHERY_HUT.colors.body or p.Color, "authored colour")
				elseif p:GetAttribute("PaintGroup") == "glow" then
					eq(p.Material, Enum.Material.Neon, "glow is Neon")
				end
			end
		end
		eq(count, 6, "every piece")
		local hut, fire = parts[1], parts[2]
		eq(hut.Transparency, 1, "replaced block hidden")
		eq(fire.Transparency, 1, "replaced fire hidden")
		near(fire:GetAttribute(PropArt.HIDDEN) :: number, 0.2, "its own Transparency saved", 1e-6)
		eq(vec(hut.Size) .. vec(hut.CFrame.Position), vec(Vector3.new(10, 7, 8)) .. vec((ANCHOR * CFrame.new(0, 3.5, 0)).Position), "block keeps size + place")
		ok(hut.CanCollide and hut.CanQuery and hut.CanTouch, "block keeps its collision, query, touch")
		eq(hut:GetAttribute("Station"), "reach", "attributes kept")
		ok(hut:FindFirstChild("Sign") and fire:FindFirstChildOfClass("PointLight"), "signs and lights kept")
		local labels = PropArt.face(dressed, "Hatchery Hut")
		eq(#labels, 1, "one sign on the face plate")
		local gui = labels[1].Parent :: SurfaceGui
		eq(gui.Face, Enum.NormalId.Front, "on the front")
		eq((gui.Parent :: Instance):GetAttribute("PaintGroup"), "face", "on the face piece")
		eq(labels[1].Text, "Hatchery Hut", "today's title")
		-- Re-dressing never stacks; undress restores exactly.
		PropArt.undress(m)
		eq(print_(m), before, "undress: exactly as before")
		PropArt.dress(m, "HATCHERY_HUT", ANCHOR, parts)
		PropArt.dress(m, "HATCHERY_HUT", ANCHOR, parts)
		near(fire:GetAttribute(PropArt.HIDDEN) :: number, 0.2, "hiding twice keeps the first saved value", 1e-6)
		PropArt.undress(m)
		eq(print_(m), before, "and still restores exactly")
		-- Colour / material overrides (decorations).
		local over = PropArt.dress(m, "DECOR_FIRE_PIT", ANCHOR, {}, { colors = { body = Color3.new(1, 0, 0) }, materials = { body = Enum.Material.Slate } }) :: Model
		for _, p in over:GetDescendants() do
			if p:IsA("BasePart") and p:GetAttribute("PaintGroup") == "body" then
				eq(p.Color, Color3.new(1, 0, 0), "override colour")
				eq(p.Material, Enum.Material.Slate, "override material")
			end
		end
	end)
end)

local LOOK = { colour = Color3.fromRGB(10, 20, 30), accent = Color3.fromRGB(200, 100, 50), material = Enum.Material.Slate }
local FLAG = Color3.fromRGB(1, 2, 3)

test("decorations: blank = today; with art blocks hidden (kept), look colours, flag cloth, Neon fire, poster on its face", function()
	local at = CFrame.new(2, 0.3, 4)
	local today: { [string]: string } = {}
	for key in Decor.SIZE do
		today[key] = print_(Decor.build(key, LOOK, at, { flag = FLAG, poster = "WANTED\nX" }) :: Model)
		ok(not string.find(today[key], "PropArt", 1, true) and not string.find(today[key], "ArtHidden", 1, true), `{key} blank: no art, nothing hidden`)
	end
	local art, ids = fakeArt()
	withArt(art, ids, function()
		for key in Decor.SIZE do
			local m = Decor.build(key, LOOK, at, { flag = FLAG, poster = "WANTED\nX" }) :: Model
			local dressed = m:FindFirstChild(`Art_DECOR_{key}`) :: Model
			ok(dressed ~= nil, `{key} dressed`)
			eq(m.PrimaryPart and m.PrimaryPart.Parent, m, `{key} PrimaryPart is still a block`)
			for _, b in m:GetChildren() do
				if b:IsA("BasePart") then
					eq(b.Transparency, 1, `{key} block {b.Name} hidden`)
					ok(b.Anchored and not b.CanQuery and not b.CanTouch, `{key} block {b.Name} still inert`)
				end
			end
			for _, p in dressed:GetDescendants() do
				if p:IsA("BasePart") then
					local g = p:GetAttribute("PaintGroup")
					if g == "body" then
						eq(p.Color, LOOK.colour, `{key} body = look colour`)
						eq(p.Material, LOOK.material, `{key} body in the look's material`)
					elseif g == "accent" then
						eq(p.Color, LOOK.accent, `{key} accent = look accent`)
						eq(p.Material, if key == "FIRE_PIT" then Enum.Material.Neon else LOOK.material, `{key} accent material`)
					elseif g == "cloth" then
						eq(p.Color, FLAG, `{key} cloth = the flag colour`)
					elseif g == "glow" then
						eq(p.Material, Enum.Material.Neon, `{key} glow Neon`)
					end
				end
			end
		end
		local noFlag = Decor.build("HUNTERS_FLAG", LOOK, at, {}) :: Model
		for _, p in noFlag:GetDescendants() do
			if p:IsA("BasePart") and p:GetAttribute("PaintGroup") == "cloth" then
				eq(p.Color, LOOK.accent, "no flag worn: cloth = accent")
			end
		end
		local poster = Decor.build("WANTED_POSTER", LOOK, at, { poster = "WANTED\nX" }) :: Model
		local board = poster:FindFirstChild("Board") :: BasePart
		eq(board:FindFirstChildOfClass("SurfaceGui"), nil, "the board's signs moved")
		local faces = {}
		for _, gui in poster:GetDescendants() do
			if gui:IsA("SurfaceGui") then
				eq((gui.Parent :: Instance):GetAttribute("PaintGroup"), "face", "poster sign on the face plate")
				table.insert(faces, gui.Face.Name)
				eq((gui:FindFirstChild("Poster") :: TextLabel).Text, "WANTED\nX", "the poster text")
			end
		end
		table.sort(faces)
		eq(table.concat(faces, ","), "Back,Front", "front and back")
	end)
end)

-- Footprints in a Campsite's frame: centre (x, z) and half sizes.
type Box = { x: number, z: number, hx: number, hz: number }
local function overlaps(a: Box, b: Box): boolean
	return math.abs(a.x - b.x) < a.hx + b.hx and math.abs(a.z - b.z) < a.hz + b.hz
end

test("art-only spots: tent and signpost clear of the pen, Display Towers, decorations; Hunt Board clear", function()
	local half = Outpost.CAMPSITE_SIZE / 2
	-- Manifest boxes (tools/art/manifest.json): tent x -2.07..1.99, z -3.14..2.53; marker x +-1.35, z -0.2..0.4.
	local tent = { x = Outpost.TENT_SPOT.X - 0.04, z = Outpost.TENT_SPOT.Z - 0.3, hx = 2.04, hz = 2.84 }
	local marker = { x = Outpost.MARKER_SPOT.X, z = Outpost.MARKER_SPOT.Z + 0.1, hx = 1.35, hz = 0.3 }
	local taken: { [string]: Box } = { pen = { x = -6, z = 5, hx = 3.75, hz = 4.06 } }
	for i, spot in Outpost.DECO_SPOTS do
		taken[`display{i}`] = { x = spot.X, z = spot.Z, hx = 1.9, hz = 1.9 } -- the pedestal deck
	end
	local widest = Vector2.zero
	for _, size in Decor.SIZE do
		widest = Vector2.new(math.max(widest.X, size.X), math.max(widest.Y, size.Y))
	end
	for i, spot in Outpost.DECOR_SPOTS do
		taken[`decor{i}`] = { x = spot.X, z = spot.Z, hx = widest.X / 2, hz = widest.Y / 2 }
	end
	for name, box in { tent = tent, marker = marker } do
		ok(math.abs(box.x) + box.hx <= half and math.abs(box.z) + box.hz <= half, `{name} inside its Campsite`)
		for other, b in taken do
			ok(not overlaps(box, b), `{name} clear of the {other}`)
		end
	end
	ok(not overlaps(tent, marker), "tent clear of the signpost")
	-- The Hunt Board (x +-3.15, z +-0.75) by the spawn ring: clear of every spawn point, the fire,
	-- the hut, the shop and the stations.
	local board = { x = Outpost.HUNT_BOARD.X, z = Outpost.HUNT_BOARD.Z, hx = 3.15, hz = 0.75 }
	for i = 1, 12 do
		local p = Outpost.spawnPoint(i) - Outpost.CENTRE
		ok(not overlaps(board, { x = p.X, z = p.Z, hx = 1.5, hz = 1.5 }), `Hunt Board clear of spawn {i}`)
	end
	ok(not overlaps(board, { x = Outpost.CAMPFIRE.X, z = Outpost.CAMPFIRE.Z, hx = 2.9, hz = 2.9 }), "clear of the fire")
	ok(not Outpost.atHut(Outpost.CENTRE + Outpost.HUNT_BOARD) and not Outpost.atShop(Outpost.CENTRE + Outpost.HUNT_BOARD), "not in the hut's or shop's circle")
	ok(Outpost.stationAt(Outpost.CENTRE + Outpost.HUNT_BOARD) == nil, "not at a station")
	eq(Outpost.PEDESTAL_LIFT, 0.3, "Display Towers stand on the 0.3 deck")
end)

test("every prop key dressed by Server/Outpost, Decor and Wardrobe is in ArtIds", function()
	local outpost = fs.readFile("src/server/Outpost.luau")
	local keys = {}
	for key in string.gmatch(outpost, 'prop%("([%u_]+)"') do
		keys[key] = true
	end
	for key in string.gmatch(outpost, '= "(STATION_%u+)"') do
		keys[key] = true
	end
	for key in Decor.SIZE do
		keys[`DECOR_{key}`] = true
	end
	keys.DISPLAY_PEDESTAL = true
	ok(string.find(fs.readFile("src/server/Wardrobe.luau"), '"DISPLAY_PEDESTAL"', 1, true) ~= nil, "Wardrobe dresses the pedestal")
	local n = 0
	for key in keys do
		n += 1
		ok(ArtIds.prop[key] ~= nil, `prop/{key} in ArtIds`)
	end
	eq(n, 22, "all 22 props used")
end)
