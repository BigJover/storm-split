--[[
	Hunter hero bodies at runtime (PLAN 11c T150 + T150b, DECISIONS #434/#436/#442/#445),
	Shared/HunterBody on fake R15 characters and fake templates, under Lune.
	1. No template (no id, not loaded, ArtOff, not R15) = the avatar exactly as before.
	2. Dressed: every R15 part and the HumanoidRootPart keep size, CFrame, collision, query,
	   touch, mass and anchoring; the Humanoid's MaxHealth / WalkSpeed never change; the avatar's
	   visuals (parts, face, accessories) are hidden and come back exactly on remove().
	3. Each `<Part>__<group>` piece is welded to its R15 part at its offset from the part's REST
	   CFrame (Motor6D C0 / C1, not the animated pose); ghost, massless, no shadows, no scripts.
	4. Paint: authored per group; `skin` = the avatar's BodyColors, else the class tone; a hunter
	   skin recolours shirt / pants when its own variant isn't loaded, its variant otherwise.
	5. One hit envelope for all four classes; stand-in dummies wear the body over their blocks.
	6. ArtIds carries what the runtime needs: hunter colours, piece groups / roles (#445).
]]

local Config = require(src.shared.Config)
local ArtSlot = require(src.shared.ArtSlot)
local HunterBody = require(src.shared.HunterBody)

local AT = CFrame.new(12, 4, -7) * CFrame.Angles(0, 0.6, 0)
local ID = 5150
local KEYS = Config.HeroOrder :: { string }

-- The default R15 rest layout (tools/art/models/hunter/_body.py R15 / JOINTS), about the root.
local CENTRE: { [string]: Vector3 } = {
	Head = Vector3.new(0, 1.5, 0),
	UpperTorso = Vector3.new(0, 0.2, 0),
	LowerTorso = Vector3.new(0, -0.8, 0),
}
local SIZE: { [string]: Vector3 } = {
	Head = Vector3.new(1.2, 1.2, 1.2),
	UpperTorso = Vector3.new(2, 1.6, 1),
	LowerTorso = Vector3.new(2, 0.4, 1),
}
-- part -> (parent, joint pivot)
local JOINT: { [string]: { any } } = {
	LowerTorso = { "HumanoidRootPart", Vector3.new(0, -0.6, 0) },
	UpperTorso = { "LowerTorso", Vector3.new(0, -0.6, 0) },
	Head = { "UpperTorso", Vector3.new(0, 1, 0) },
}
for _, pair in { { -1, "Left" }, { 1, "Right" } } do
	local s, side = pair[1] :: number, pair[2] :: string
	CENTRE[side .. "UpperArm"] = Vector3.new(1.5 * s, 0.369, 0)
	CENTRE[side .. "LowerArm"] = Vector3.new(1.5 * s, -0.157, 0)
	CENTRE[side .. "Hand"] = Vector3.new(1.5 * s, -0.783, 0)
	CENTRE[side .. "UpperLeg"] = Vector3.new(0.5 * s, -1.421, 0)
	CENTRE[side .. "LowerLeg"] = Vector3.new(0.5 * s, -2.215, 0)
	CENTRE[side .. "Foot"] = Vector3.new(0.5 * s, -2.85, 0)
	SIZE[side .. "UpperArm"] = Vector3.new(1, 1.169, 1)
	SIZE[side .. "LowerArm"] = Vector3.new(1, 1.052, 1)
	SIZE[side .. "Hand"] = Vector3.new(1, 0.3, 1)
	SIZE[side .. "UpperLeg"] = Vector3.new(1, 1.217, 1)
	SIZE[side .. "LowerLeg"] = Vector3.new(1, 1.193, 1)
	SIZE[side .. "Foot"] = Vector3.new(1, 0.3, 1)
	JOINT[side .. "UpperArm"] = { "UpperTorso", Vector3.new(1.0 * s, 0.763, 0) }
	JOINT[side .. "LowerArm"] = { side .. "UpperArm", Vector3.new(1.5 * s, 0.035, 0) }
	JOINT[side .. "Hand"] = { side .. "LowerArm", Vector3.new(1.5 * s, -0.658, 0) }
	JOINT[side .. "UpperLeg"] = { "LowerTorso", Vector3.new(0.5 * s, -1.0, 0) }
	JOINT[side .. "LowerLeg"] = { side .. "UpperLeg", Vector3.new(0.5 * s, -1.821, 0) }
	JOINT[side .. "Foot"] = { side .. "LowerLeg", Vector3.new(0.5 * s, -2.762, 0) }
end
CENTRE.HumanoidRootPart = Vector3.zero
SIZE.HumanoidRootPart = Vector3.new(2, 2, 1)

local SKIN_AVATAR = Color3.fromRGB(90, 60, 40)

-- A fake R15 avatar: parts, Motor6Ds, Humanoid, clothes, a hat accessory, a face, BodyColors,
-- a name billboard. `skip` leaves one part out (not R15).
local function character(opts: { bodyColors: boolean?, skip: string? }?): Model
	local o = opts or {}
	local model = Instance.new("Model")
	model.Name = "Hunter"
	local parts: { [string]: BasePart } = {}
	for name, centre in CENTRE do
		if name ~= o.skip then
			local part = Instance.new("MeshPart")
			part.Name = name
			part.Size = SIZE[name]
			part.CFrame = AT * CFrame.new(centre)
			part.Transparency = if name == "HumanoidRootPart" then 1 else 0
			part.CanCollide = name == "HumanoidRootPart" or name == "UpperTorso"
			part.CanQuery = true
			part.CanTouch = true
			part.Color = Color3.fromRGB(200, 200, 200)
			part.Parent = model
			parts[name] = part
		end
	end
	model.PrimaryPart = parts.HumanoidRootPart
	for name, joint in JOINT do
		local p0, p1 = parts[joint[1]], parts[name]
		if p0 and p1 then
			local motor = Instance.new("Motor6D")
			motor.Name = name .. "Joint"
			motor.Part0 = p0
			motor.Part1 = p1
			motor.C0 = CFrame.new(joint[2] - CENTRE[joint[1]])
			motor.C1 = CFrame.new(joint[2] - CENTRE[name])
			motor.Parent = p1
		end
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 95
	humanoid.Health = 95
	humanoid.WalkSpeed = 17
	humanoid.Parent = model
	if parts.Head then
		local face = Instance.new("Decal")
		face.Name = "face"
		face.Parent = parts.Head
		local tag = Instance.new("BillboardGui")
		tag.Name = "NameTag"
		tag.Parent = parts.Head
	end
	Instance.new("Shirt").Parent = model
	Instance.new("Pants").Parent = model
	local hat = Instance.new("Accessory")
	hat.Name = "CoolHat"
	local handle = Instance.new("MeshPart")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 0.5, 1)
	handle.Transparency = 0.2
	handle.Parent = hat
	hat.Parent = model
	if o.bodyColors ~= false then
		local colours = Instance.new("BodyColors")
		colours.HeadColor3 = SKIN_AVATAR
		colours.Parent = model
	end
	return model
end

local GROUPS = { "skin", "shirt", "pants", "dark" }
local OFFSET = CFrame.new(0.05, -0.02, 0.03) * CFrame.Angles(0, 0.1, 0)

-- A fake body template: one piece per (R15 part, group) at its part's rest centre, authored
-- about the root; plus a script, a joint and a stray non-body piece that must not survive.
local function bodyTemplate(key: string): Model
	local model = Instance.new("Model")
	model.Name = key
	model:SetAttribute("ArtId", ID)
	for _, part in HunterBody.PARTS do
		for _, group in GROUPS do
			local piece = Instance.new("MeshPart")
			piece.Name = `{part}__{group}`
			piece.Size = Vector3.new(0.4, 0.4, 0.4)
			piece.CFrame = CFrame.new(CENTRE[part]) * OFFSET
			piece.CanCollide = true
			piece.CanQuery = true
			piece.Anchored = true
			piece.Parent = model
			if part == "Head" and group == "skin" then
				Instance.new("Script").Parent = piece
				Instance.new("WeldConstraint").Parent = piece
				Instance.new("Attachment").Parent = piece
			end
		end
	end
	local junk = Instance.new("MeshPart")
	junk.Name = "Junk"
	junk.Parent = model
	return model
end

local AUTHORED = {
	skin = Color3.fromRGB(205, 150, 108),
	shirt = Color3.fromRGB(112, 126, 78),
	pants = Color3.fromRGB(192, 168, 120),
	dark = Color3.fromRGB(76, 54, 38),
}
local VARIANT = "SWAMP_TEST"
local VARIANT_SHIRT = Color3.fromRGB(10, 90, 20)

local function fakeArt(): (Instance, any)
	local art = Instance.new("Folder")
	art.Name = "Art"
	local hunters = Instance.new("Folder")
	hunters.Name = "hunter"
	hunters.Parent = art
	local ids = { dino = {}, tower = {}, hunter = {} }
	for _, key in KEYS do
		bodyTemplate(key).Parent = hunters
		ids.hunter[key] = { model = ID, colors = table.clone(AUTHORED) }
	end
	bodyTemplate(VARIANT).Parent = hunters
	local variantColours = table.clone(AUTHORED)
	variantColours.shirt = VARIANT_SHIRT
	ids.hunter[VARIANT] = { model = ID, colors = variantColours }
	return art, ids
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

local function num(n: number): string
	if math.abs(n) < 5e-4 then
		n = 0
	end
	return string.format("%.3f", n)
end
local function cf(c: CFrame): string
	local out = {}
	for _, v in { c:GetComponents() } do
		table.insert(out, num(v))
	end
	return table.concat(out, ",")
end

-- Everything about the avatar that a body must never change (and, with `visual`, its look).
local function fingerprint(model: Instance, visual: boolean?): string
	local lines = {}
	for _, d in model:GetDescendants() do
		local line = `{d:GetFullName()} {d.ClassName}`
		if d:IsA("BasePart") then
			line ..= ` size={d.Size} cf={cf(d.CFrame)} coll={d.CanCollide} q={d.CanQuery} t={d.CanTouch} m0={d.Massless} anch={d.Anchored}`
			if visual then
				line ..= ` tr={num(d.Transparency)} rgb={d.Color} mat={d.Material.Name}`
			end
		elseif d:IsA("Decal") and visual then
			line ..= ` tr={num(d.Transparency)}`
		elseif d:IsA("Humanoid") then
			line ..= ` max={d.MaxHealth} hp={d.Health} speed={d.WalkSpeed}`
		elseif d:IsA("Motor6D") then
			line ..= ` c0={cf(d.C0)} c1={cf(d.C1)}`
		end
		table.insert(lines, line)
	end
	table.sort(lines)
	return table.concat(lines, "\n")
end

local function avatarOnly(model: Model): string
	local copy = model:Clone()
	local body = copy:FindFirstChild(HunterBody.FOLDER)
	if body then
		body:Destroy()
	end
	return fingerprint(copy)
end

local function pieces(model: Instance): { BasePart }
	local out = {}
	local folder = model:FindFirstChild(HunterBody.FOLDER)
	for _, d in (if folder then folder:GetChildren() else {}) do
		if d:IsA("BasePart") then
			table.insert(out, d)
		end
	end
	return out
end

local function closeCf(a: CFrame, b: CFrame): boolean
	local pa, pb = a.Position, b.Position
	return (pa - pb).Magnitude < 1e-3 and (a.XVector - b.XVector).Magnitude < 1e-3 and (a.YVector - b.YVector).Magnitude < 1e-3
end

test("real ArtIds: four hunter bodies with authored colours (skin included), no id yet; piece roles", function()
	local ArtIds = require(src.shared.ArtIds)
	for _, key in KEYS do
		local entry = ArtIds.hunter and ArtIds.hunter[key]
		ok(entry ~= nil, `{key} has an ArtIds entry`)
		ok(entry and entry.model == nil, `{key} has no id yet (blocky/avatar fallback)`)
		ok(entry and entry.colors and typeof(entry.colors.skin) == "Color3", `{key} class skin tone (#442 fallback)`)
		ok(entry and entry.pieces == nil, `{key} piece names say their part and group`)
	end
	local dino = ArtIds.dino.HUSK
	eq(dino.pieces and dino.pieces.head and dino.pieces.head.role, "head", "dino head role from the manifest")
	local air = ArtIds.tower.BLIMP_AIR
	eq(air.pieces and air.pieces.lamp and air.pieces.lamp.role, "lamp", "blimp searchlight role")
	eq(air.pieces and air.pieces.hubs and air.pieces.hubs.group, "steel", "a piece's group when its name isn't it")
	eq(ArtIds.tower.SCOUT.pieces.muzzle.role, "muzzle", "tower muzzle role")
	ok(ArtIds.tower.HOSPITAL_S2 ~= nil and ArtIds.tower.SCOUT_S1 ~= nil, "every tower stage has an entry")
end)

test("keys and piece names", function()
	eq(HunterBody.key(nil), KEYS[1], "no hero yet: the starter's body")
	eq(HunterBody.key(""), KEYS[1], "blank hero")
	eq(HunterBody.key("NOPE"), KEYS[1], "unknown hero")
	for _, key in KEYS do
		eq(HunterBody.key(key), key, `{key} wears its own`)
	end
	local part, group = HunterBody.parse("LeftUpperArm__shirt")
	eq(part, "LeftUpperArm", "part")
	eq(group, "shirt", "group")
	eq((HunterBody.parse("Junk")), nil, "not a body piece")
	eq((HunterBody.parse("Tail__skin")), nil, "not an R15 part")
	eq(#HunterBody.PARTS, 15, "15 R15 parts")
end)

test("no template (no ids, not loaded, ArtOff, stale id): the avatar exactly as before", function()
	local cases = {}
	local art, ids = fakeArt()
	cases.none = { nil, nil }
	cases.notLoaded = { Instance.new("Folder"), ids }
	local off, offIds = fakeArt()
	off:SetAttribute("ArtOff", true)
	cases.artOff = { off, offIds }
	local _, staleIds = fakeArt()
	for key in staleIds.hunter do
		staleIds.hunter[key] = { model = ID + 1 }
	end
	cases.stale = { art, staleIds }
	for name, case in cases do
		local model = character()
		local before = fingerprint(model, true)
		local dressed
		withArt(case[1], case[2], function()
			dressed = HunterBody.apply(model, "PISTOL", {})
		end)
		eq(dressed, false, `{name}: not dressed`)
		eq(fingerprint(model, true), before, `{name}: avatar unchanged`)
		eq(HunterBody.worn(model), nil, `{name}: wears nothing`)
	end
end)

test("not an R15 rig: the avatar as before", function()
	local art, ids = fakeArt()
	local model = character({ skip = "UpperTorso" })
	local before = fingerprint(model, true)
	withArt(art, ids, function()
		eq(HunterBody.apply(model, "PISTOL", {}), false, "no UpperTorso: not dressed")
	end)
	eq(fingerprint(model, true), before, "unchanged")
end)

test("dressed: hit parts, Humanoid and joints unchanged; avatar visuals hidden; billboard kept", function()
	local art, ids = fakeArt()
	local model = character()
	local before = fingerprint(model)
	withArt(art, ids, function()
		eq(HunterBody.apply(model, "PISTOL", {}), true, "dressed")
	end)
	eq(avatarOnly(model), before, "every R15 part, the root, the Humanoid and the Motor6Ds keep size, CFrame, collision, query, touch, mass")
	eq(HunterBody.worn(model), "PISTOL", "wears the Tracker")
	for _, name in HunterBody.PARTS do
		eq((model:FindFirstChild(name) :: BasePart).Transparency, 1, `{name} hidden`)
	end
	eq((model:FindFirstChild("HumanoidRootPart") :: BasePart).Transparency, 1, "root as it was")
	eq((model.Head:FindFirstChild("face") :: Decal).Transparency, 1, "face decal hidden")
	eq((model.CoolHat.Handle :: BasePart).Transparency, 1, "accessory hidden")
	ok(model.Head:FindFirstChild("NameTag") ~= nil, "name tag billboard still on the head")
	local humanoid = model:FindFirstChildWhichIsA("Humanoid") :: Humanoid
	eq(humanoid.MaxHealth, 95, "MaxHealth")
	eq(humanoid.WalkSpeed, 17, "WalkSpeed")
end)

test("pieces: welded to their R15 part at the rest offset, ghost, massless, no shadows or scripts", function()
	local art, ids = fakeArt()
	local model = character()
	withArt(art, ids, function()
		HunterBody.apply(model, "PISTOL", {})
	end)
	local made = pieces(model)
	eq(#made, #HunterBody.PARTS * #GROUPS, "one per (part, group); the stray piece left out")
	local root = model.HumanoidRootPart :: BasePart
	for _, p in made do
		local partName = HunterBody.parse(p.Name)
		local part = model:FindFirstChild(partName :: string) :: BasePart
		ok(p.Massless and not p.CanCollide and not p.CanQuery and not p.CanTouch and not p.Anchored, `{p.Name} ghost`)
		eq(p.CastShadow, false, `{p.Name} no shadow`)
		local welds = 0
		for _, d in p:GetDescendants() do
			ok(d:IsA("Weld") or d:IsA("Attachment"), `{p.Name} carries only its weld + attachments ({d.ClassName})`)
			if d:IsA("Weld") then
				welds += 1
				ok(d.Part0 == part and d.Part1 == p, `{p.Name} welded to {partName}`)
				-- rest pose: the part sits at its rest centre, so piece = root * authored offset
				ok(closeCf(part.CFrame * d.C0, root.CFrame * CFrame.new(CENTRE[partName :: string]) * OFFSET), `{p.Name} at its authored place`)
			end
		end
		eq(welds, 1, `{p.Name} one weld`)
		ok(closeCf(p.CFrame, root.CFrame * CFrame.new(CENTRE[partName :: string]) * OFFSET), `{p.Name} placed`)
	end
end)

test("an animated pose: offsets still come from the rest pose (Motor6D C0/C1)", function()
	local art, ids = fakeArt()
	local model = character()
	local arm = model.LeftLowerArm :: BasePart
	arm.CFrame = arm.CFrame * CFrame.Angles(1.2, 0, 0) + Vector3.new(0, 0.5, 0) -- mid-swing
	withArt(art, ids, function()
		HunterBody.apply(model, "PISTOL", {})
	end)
	local piece = model[HunterBody.FOLDER]:FindFirstChild("LeftLowerArm__shirt") :: BasePart
	local weld = piece:FindFirstChildWhichIsA("Weld") :: Weld
	local expected = CFrame.new(CENTRE.LeftLowerArm):Inverse() * CFrame.new(CENTRE.LeftLowerArm) * OFFSET
	ok(closeCf(weld.C0, expected), "C0 = rest^-1 * authored, not the swung arm")
	local rest = HunterBody.restPose(model)
	for _, name in HunterBody.PARTS do
		ok(rest[name] and closeCf(rest[name], CFrame.new(CENTRE[name])), `{name} rest from the Motor6D chain`)
	end
end)

test("paint: authored per group; skin = the avatar's BodyColors, else the class tone", function()
	local art, ids = fakeArt()
	local model = character()
	local plain = character({ bodyColors = false })
	withArt(art, ids, function()
		HunterBody.apply(model, "RIFLE", {})
		HunterBody.apply(plain, "RIFLE", {})
	end)
	for _, p in pieces(model) do
		local _, group = HunterBody.parse(p.Name)
		local want = if group == "skin" then SKIN_AVATAR else AUTHORED[group :: string]
		eq(p.Color, want, `{p.Name} colour`)
		eq(p.Material, Enum.Material.SmoothPlastic, `{p.Name} SmoothPlastic`)
		eq(p:GetAttribute("PaintGroup"), group, `{p.Name} PaintGroup`)
	end
	for _, p in pieces(plain) do
		local _, group = HunterBody.parse(p.Name)
		eq(p.Color, AUTHORED[group :: string], `{p.Name} class colour with no BodyColors`)
	end
end)

test("hunter skins (#436): variant blank = shirt/pants recoloured; variant loaded = the variant", function()
	local art, ids = fakeArt()
	local look = { colour = Color3.fromRGB(30, 60, 30), accent = Color3.fromRGB(60, 40, 20), material = Enum.Material.Fabric }
	local model = character()
	withArt(art, ids, function()
		HunterBody.apply(model, "PISTOL", { look = look, variant = "NOT_LOADED" })
	end)
	eq(HunterBody.worn(model), "PISTOL", "the class body (the variant has no id)")
	for _, p in pieces(model) do
		local _, group = HunterBody.parse(p.Name)
		if group == "shirt" then
			ok(p.Color == look.colour and p.Material == look.material, `{p.Name} skin colour + material`)
		elseif group == "pants" then
			ok(p.Color == look.accent and p.Material == look.material, `{p.Name} skin accent + material`)
		elseif group == "skin" then
			eq(p.Color, SKIN_AVATAR, `{p.Name} keeps the avatar skin`)
		else
			eq(p.Color, AUTHORED[group :: string], `{p.Name} untouched by the skin`)
		end
	end
	withArt(art, ids, function()
		HunterBody.apply(model, "PISTOL", { look = look, variant = VARIANT })
	end)
	eq(HunterBody.worn(model), VARIANT, "the skin's own body variant")
	for _, p in pieces(model) do
		local _, group = HunterBody.parse(p.Name)
		if group == "shirt" then
			eq(p.Color, VARIANT_SHIRT, "variant's authored shirt, no recolour")
		end
	end
	eq(#pieces(model), #HunterBody.PARTS * #GROUPS, "replaced, not doubled")
end)

test("hero change replaces the body; remove() shows the avatar exactly as it was", function()
	local art, ids = fakeArt()
	local model = character()
	local before = fingerprint(model, true)
	withArt(art, ids, function()
		HunterBody.apply(model, "PISTOL", {})
		HunterBody.apply(model, "MEDIC", {})
	end)
	local folders = 0
	for _, child in model:GetChildren() do
		folders += if child.Name == HunterBody.FOLDER then 1 else 0
	end
	eq(folders, 1, "one body")
	eq(HunterBody.worn(model), "MEDIC", "the new hero's")
	-- a late accessory is hidden too
	local late = Instance.new("Accessory")
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Parent = late
	late.Parent = model
	HunterBody.hideAvatar(model)
	eq(handle.Transparency, 1, "late accessory hidden")
	late:Destroy()
	withArt(nil, nil, function()
		eq(HunterBody.apply(model, "MEDIC", {}), false, "art gone")
	end)
	eq(fingerprint(model, true), before, "avatar restored exactly")
end)

test("one hit envelope for every class (#434)", function()
	local art, ids = fakeArt()
	local prints = {}
	for _, key in KEYS do
		local model = character()
		withArt(art, ids, function()
			HunterBody.apply(model, key, {})
		end)
		prints[key] = avatarOnly(model)
	end
	for _, key in KEYS do
		eq(prints[key], prints[KEYS[1]], `{key} same R15 parts, sizes, Humanoid as {KEYS[1]}`)
	end
end)

test("stand-in hunters: the body over the blocks; Body/Head kept as hit + billboard parts", function()
	local function dummy(): (Model, BasePart, BasePart)
		local model = Instance.new("Model")
		local body = Instance.new("Part")
		body.Name = "Body"
		body.Size = Vector3.new(2, 3, 1.2)
		body.Anchored = true
		body.CFrame = AT
		body.Parent = model
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Size = Vector3.new(1.4, 1.4, 1.4)
		head.Anchored = true
		head.CFrame = AT * CFrame.new(0, 2.2, 0)
		head.Parent = model
		Instance.new("BillboardGui").Parent = head
		return model, body, head
	end
	local plain, plainBody, plainHead = dummy()
	local before = fingerprint(plain, true)
	eq(HunterBody.applyStandIn(plain, plainBody, plainHead, HunterBody.DEFAULT), nil, "no art: blocks")
	eq(fingerprint(plain, true), before, "blocks unchanged")

	local art, ids = fakeArt()
	local model, body, head = dummy()
	local physics = fingerprint(model)
	local made
	withArt(art, ids, function()
		made = HunterBody.applyStandIn(model, body, head, HunterBody.DEFAULT)
	end)
	ok(made ~= nil and #made == #HunterBody.PARTS * #GROUPS, "dressed")
	eq(avatarOnly(model), physics, "Body and Head keep size, CFrame and collision")
	eq(body.Transparency, 1, "Body hidden")
	eq(head.Transparency, 1, "Head hidden")
	ok(head:FindFirstChildWhichIsA("BillboardGui") ~= nil, "billboard kept")
	for _, p in made :: { BasePart } do
		local weld = p:FindFirstChildWhichIsA("Weld") :: Weld
		local partName = HunterBody.parse(p.Name) :: string
		ok(weld and weld.Part0 == body, `{p.Name} welded to the Body`)
		ok(closeCf(weld.C0, HunterBody.STAND_IN_ROOT * CFrame.new(CENTRE[partName]) * OFFSET), `{p.Name} at the root's rest height`)
		local _, group = HunterBody.parse(p.Name)
		eq(p.Color, AUTHORED[group :: string], `{p.Name} class colours (no avatar)`)
	end
	HunterBody.fade(model, 0.5)
	for _, p in made :: { BasePart } do
		eq(p.Transparency, 0.5, `{p.Name} fades when downed`)
	end
end)

test("ArtSlot reads piece groups and roles from ArtIds (FBX has no attributes, #445)", function()
	local art = Instance.new("Folder")
	art.Name = "Art"
	local towers = Instance.new("Folder")
	towers.Name = "tower"
	towers.Parent = art
	local template = Instance.new("Model")
	template.Name = "SCOUT"
	template:SetAttribute("ArtId", ID)
	for _, name in { "body", "muzzle", "hubs" } do
		local p = Instance.new("MeshPart")
		p.Name = name
		p.Parent = template
	end
	template.Parent = towers
	local ids = { tower = { SCOUT = { model = ID, colors = { metal = Color3.fromRGB(1, 2, 3), steel = Color3.fromRGB(4, 5, 6) },
		pieces = { muzzle = { group = "metal", role = "muzzle" }, hubs = { group = "steel" } } } } }
	local host = Instance.new("Model")
	local gameplay = Instance.new("Part")
	gameplay.Parent = host
	local dressed, made
	withArt(art, ids, function()
		dressed, made = ArtSlot.dress(host, "tower", "SCOUT", 1, gameplay, ArtSlot.paints(Color3.new(1, 1, 1)), { anchored = true, roles = { "muzzle" } })
	end)
	ok(dressed, "dressed; the muzzle role found through the entry")
	local byName = {}
	for _, p in made do
		byName[p:GetAttribute("PaintGroup") .. ":" .. tostring(p:GetAttribute("ArtRole"))] = p
	end
	ok(byName["metal:muzzle"] ~= nil, "muzzle piece: group metal, ArtRole muzzle")
	eq(byName["metal:muzzle"].Color, Color3.fromRGB(1, 2, 3), "painted its group's colour")
	ok(byName["steel:nil"] ~= nil and byName["steel:nil"].Color == Color3.fromRGB(4, 5, 6), "hubs painted steel")
	ok(byName["body:nil"] ~= nil, "a piece named by its group needs no entry")
end)
