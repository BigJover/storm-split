--[[
	Pet + egg art at runtime (PLAN 11f T156, DECISIONS #426/#450, tools/art/README "Pets, eggs,
	incubator"), Shared/PetLook on fake templates under Lune.
	1. No loaded art (blank ids, not loaded, stale, ArtOff): every species at every rarity builds
	   exactly today's blocky hatchling (the pre-11f Server/Pets build, kept below as LEGACY),
	   follows at today's FOLLOW, stands at today's pen spot, and no incubator is shown.
	2. Dressed: the Body stays the pivot (invisible, never collides / queried / touched) on the
	   ground; art pieces are ghosts, anchored, no shadows; no blocks; follow / pen put the feet
	   on the floor; fliers hover on top.
	3. Rarity: accent = the rarity colour at every rarity; glow = authored tone (Common /
	   Uncommon), rarity colour (Rare / Epic), rarity colour + Neon (Legendary / Mythic); a light
	   sparkle on Mythic only; other groups authored.
	4. Incubators: one per slot beside the hut door, the warming egg at eggSeat, bulb lit only
	   while warming; nothing without the Incubator art.
]]

local Config = require(src.shared.Config)
local ArtSlot = require(src.shared.ArtSlot)
local ArtIds = require(src.shared.ArtIds)
local PetLook = require(src.shared.PetLook)
local PetRules = require(src.shared.Pets)

local AT = CFrame.new(5, 2, -9) * CFrame.Angles(0, 0.8, 0)
local ID = 7311
local KINDS = Config.PetOrder :: { string }
local RARITIES = { "COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY", "MYTHIC" }

------------------------------------------------------------------ the pre-11f build (Server/Pets)

local LOOKS = {
	HONKER = { body = Color3.fromRGB(120, 150, 90), size = Vector3.new(1.4, 1.4, 2), flies = false },
	FETCHER = { body = Color3.fromRGB(150, 110, 80), size = Vector3.new(1, 0.8, 1.4), flies = true },
	FERN_MUNCHER = { body = Color3.fromRGB(90, 160, 110), size = Vector3.new(1.6, 1.4, 2.2), flies = false },
	SHINY_SNATCHER = { body = Color3.fromRGB(220, 140, 70), size = Vector3.new(1.2, 1.3, 1.8), flies = false },
	FRILL_GUARD = { body = Color3.fromRGB(200, 170, 120), size = Vector3.new(1.6, 1.3, 2.2), flies = false },
}
local RARITY_COLOURS = {
	COMMON = Color3.fromRGB(170, 170, 170),
	UNCOMMON = Color3.fromRGB(90, 200, 100),
	RARE = Color3.fromRGB(80, 150, 255),
	EPIC = Color3.fromRGB(180, 100, 240),
	LEGENDARY = Color3.fromRGB(250, 200, 60),
	MYTHIC = Color3.fromRGB(240, 70, 70),
}
local LEAF = Color3.fromRGB(60, 150, 70)
local LEGACY_FOLLOW = Vector3.new(3, -1.6, 2.5)

local function block(name: string, size: Vector3, cframe: CFrame, color: Color3, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Parent = parent
	return p
end

local function legacy(pet: { kind: string, rarity: string }, at: CFrame, label: boolean): Model
	local look = LOOKS[pet.kind] or LOOKS.HONKER
	local model = Instance.new("Model")
	model.Name = PetRules.name(pet)
	local s = look.size
	local body = block("Body", s, at, look.body, model)
	model.PrimaryPart = body
	local head = block("Head", Vector3.new(s.X * 0.8, s.Y * 0.7, s.Z * 0.45), at * CFrame.new(0, s.Y * 0.55, -s.Z * 0.6), look.body, model)
	block("Collar", Vector3.new(s.X * 0.85, s.Y * 0.2, s.Z * 0.15), at * CFrame.new(0, s.Y * 0.3, -s.Z * 0.42), RARITY_COLOURS[pet.rarity] or LEAF, model)
	block("LeafTag", Vector3.new(0.3, 0.4, 0.1), at * CFrame.new(0, s.Y * 0.05, -s.Z * 0.5), LEAF, model)
	if pet.kind == "HONKER" then
		block("Crest", Vector3.new(0.3, 0.3, 1.2), head.CFrame * CFrame.new(0, 0.5, 0.6) * CFrame.Angles(math.rad(30), 0, 0), look.body:Lerp(Color3.new(1, 1, 1), 0.2), model)
	elseif pet.kind == "FETCHER" then
		for _, x in { -1, 1 } do
			block("Wing", Vector3.new(1.6, 0.1, 0.8), at * CFrame.new(x * (s.X / 2 + 0.7), 0.2, 0), look.body:Lerp(Color3.new(0, 0, 0), 0.2), model)
		end
	elseif pet.kind == "FERN_MUNCHER" then
		block("Neck", Vector3.new(0.5, 1.4, 0.5), at * CFrame.new(0, s.Y * 0.9, -s.Z * 0.45), look.body, model)
	elseif pet.kind == "FRILL_GUARD" then
		block("Frill", Vector3.new(s.X * 1.4, s.Y, 0.2), head.CFrame * CFrame.new(0, 0.3, 0.4), look.body:Lerp(Color3.fromRGB(200, 90, 60), 0.4), model)
	end
	if label then
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(150, 22)
		gui.StudsOffset = Vector3.new(0, s.Y + 0.8, 0)
		gui.MaxDistance = 45
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.GothamBold
		text.TextScaled = true
		text.TextColor3 = RARITY_COLOURS[pet.rarity] or Color3.new(1, 1, 1)
		text.TextStrokeTransparency = 0.4
		text.Text = model.Name
		text.Parent = gui
		gui.Parent = body
	end
	return model
end

------------------------------------------------------------------ fingerprints

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
	elseif inst:IsA("BillboardGui") then
		line ..= ` off={vec(inst.StudsOffset)} max={num(inst.MaxDistance)}`
	elseif inst:IsA("TextLabel") then
		line ..= ` text={inst.Text} rgb={num(inst.TextColor3.R)},{num(inst.TextColor3.G)},{num(inst.TextColor3.B)}`
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

local function print_(model: Instance): string
	local out = {}
	describe(model, 0, out)
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

local function sameAsToday(what: string)
	for _, kind in KINDS do
		for _, rarity in RARITIES do
			local pet = { id = 1, kind = kind, rarity = rarity }
			for _, label in { true, false } do
				eq(print_(PetLook.build(pet, AT, label)), print_(legacy(pet, AT, label)), `{what}: {rarity} {kind} label={label} as today`)
			end
			local model = PetLook.build(pet, AT, true)
			eq(vec(PetLook.follow(model, 3)), vec(LEGACY_FOLLOW), `{what}: {kind} follows at FOLLOW`)
			local pen = block("HatchlingPen", Vector3.new(7, 0.25, 7), CFrame.new(3, 0.4, 8) * CFrame.Angles(0, 1, 0), Color3.new(), Instance.new("Folder"))
			for i = 1, 3 do
				local want = pen.CFrame * CFrame.new((i - 2) * 2.2, 1, 0) * CFrame.Angles(0, math.rad(180), 0)
				local got = PetLook.penSpot(pen, i, model)
				eq(vec(got.Position) .. vec(got.LookVector), vec(want.Position) .. vec(want.LookVector), `{what}: {kind} pen spot {i}`)
			end
			pen:Destroy()
		end
	end
	eq(PetLook.incubators({ { egg = "MUD", readyAt = 100 } }, 50, 2, AT), nil, `{what}: no incubator art = nothing shown`)
end

------------------------------------------------------------------ fake templates

local GROUPS: { [string]: { Vector3 } } = { -- size, centre (about the ground under the pet)
	body = { Vector3.new(1, 1, 2), Vector3.new(0, 1, 0) },
	accent = { Vector3.new(0.9, 0.2, 0.3), Vector3.new(0, 1.4, -0.8) },
	glow = { Vector3.new(0.3, 0.3, 0.6), Vector3.new(0, 1.8, 0.2) },
	leaf = { Vector3.new(0.2, 0.3, 0.1), Vector3.new(0, 1.2, -1) },
	eye = { Vector3.new(0.1, 0.1, 0.1), Vector3.new(0.3, 1.9, -1) },
}

local function piece(model: Model, group: string, size: Vector3, at: Vector3)
	local p = Instance.new("MeshPart")
	p.Name = group
	p.Size = size
	p.CFrame = CFrame.new(at)
	p.Anchored = true
	p.CanCollide = true
	p.Parent = model
end

local function fakeArt(): (Instance, any)
	local art = Instance.new("Folder")
	art.Name = "Art"
	local ids: any = { pet = {}, egg = {} }
	local pets = Instance.new("Folder")
	pets.Name = "pet"
	pets.Parent = art
	for _, kind in KINDS do
		local model = Instance.new("Model")
		model.Name = kind
		model:SetAttribute("ArtId", ID)
		for group, row in GROUPS do
			piece(model, group, row[1], row[2])
		end
		model.Parent = pets
		ids.pet[kind] = { model = ID, colors = ArtIds.pet[kind].colors }
	end
	local eggs = Instance.new("Folder")
	eggs.Name = "egg"
	eggs.Parent = art
	for _, key in { "INCUBATOR", "MUD", "SPECKLED", "GOLDEN" } do
		local model = Instance.new("Model")
		model.Name = key
		model:SetAttribute("ArtId", ID)
		if key == "INCUBATOR" then
			piece(model, "wood", Vector3.new(2.2, 1, 2.2), Vector3.new(0, 0.5, 0))
			piece(model, "glow", Vector3.new(0.4, 0.4, 0.4), Vector3.new(0, 3, 0))
		else
			piece(model, "shell", Vector3.new(1, 1.4, 1), Vector3.new(0, 0.7, 0))
		end
		model.Parent = eggs
		ids.egg[key] = { model = ID, colors = ArtIds.egg[key].colors }
	end
	return art, ids
end

------------------------------------------------------------------ specs

test("ArtIds lists every pet species and egg, plus the Incubator (colours only today)", function()
	for _, kind in KINDS do
		ok(ArtIds.pet[kind] ~= nil and ArtIds.pet[kind].colors ~= nil, `pet/{kind} in ArtIds`)
		ok(ArtIds.pet[kind].colors.accent ~= nil and ArtIds.pet[kind].colors.glow ~= nil, `pet/{kind} has accent + glow`)
	end
	for _, egg in Config.EggOrder :: { string } do
		ok(ArtIds.egg[egg] ~= nil, `egg/{egg} in ArtIds`)
	end
	ok(ArtIds.egg.INCUBATOR ~= nil, "egg/INCUBATOR in ArtIds")
end)

test("no loaded art: every pet at every rarity is today's blocky hatchling, same follow + pen spot", function()
	sameAsToday("real ids")
	local art, ids = fakeArt()
	withArt(Instance.new("Folder"), ids, function()
		sameAsToday("not loaded")
	end)
	local stale = {}
	for kind, byKey in ids do
		stale[kind] = {}
		for key, entry in byKey do
			stale[kind][key] = { model = ID + 1, colors = entry.colors }
		end
	end
	withArt(art, stale, function()
		sameAsToday("stale")
	end)
	art:SetAttribute("ArtOff", true)
	withArt(art, ids, function()
		sameAsToday("ArtOff")
	end)
end)

local function artParts(model: Model): { BasePart }
	local out = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("ArtPiece") then
			table.insert(out, d)
		end
	end
	return out
end

local function byGroup(model: Model, group: string): BasePart
	for _, p in artParts(model) do
		if p:GetAttribute("PaintGroup") == group then
			return p
		end
	end
	error(`no {group} piece`)
end

test("dressed pets: Body = invisible ground pivot, ghost art, no blocks, feet on the floor", function()
	local art, ids = fakeArt()
	withArt(art, ids, function()
		for _, kind in KINDS do
			local pet = { id = 1, kind = kind, rarity = "RARE" }
			local model = PetLook.build(pet, AT, true)
			local body = model.PrimaryPart :: BasePart
			eq(body.Name, "Body", `{kind} pivot`)
			eq(vec(body.CFrame.Position), vec(AT.Position), `{kind} pivot at the given spot (the ground)`)
			eq(body.Transparency, 1, `{kind} Body hidden`)
			ok(not body.CanCollide and not body.CanQuery and not body.CanTouch, `{kind} Body never hit or touched`)
			ok(PetLook.dressed(model), `{kind} dressed`)
			eq(model.Name, PetRules.name(pet), `{kind} named as shown`)
			for _, name in { "Head", "Collar", "LeafTag", "Crest", "Wing", "Neck", "Frill" } do
				ok(model:FindFirstChild(name) == nil, `{kind} no blocky {name}`)
			end
			local parts = artParts(model)
			eq(#parts, 5, `{kind} one piece per group`)
			for _, p in parts do
				ok(p.Anchored and p.Massless and not p.CanCollide and not p.CanQuery and not p.CanTouch, `{kind} {p.Name} ghost`)
				eq(p.CastShadow, false, `{kind} {p.Name} no shadow`)
			end
			local b = byGroup(model, "body")
			eq(vec(b.CFrame.Position), vec((AT * CFrame.new(0, 1, 0)).Position), `{kind} art placed about the ground pivot`)
			local gui = body:FindFirstChildOfClass("BillboardGui")
			ok(gui ~= nil and gui.StudsOffset.Y > 2, `{kind} name label over the art`)
			-- Follow: feet on the floor under the hunter; fliers hover on top.
			local follow = PetLook.follow(model, 3)
			eq(vec(follow), vec(Vector3.new(3, -3, 2.5)), `{kind} follows with its feet on the floor`)
			eq(vec(PetLook.follow(model, 3.4)), vec(Vector3.new(3, -3.4, 2.5)), `{kind} taller rig: still the floor`)
			if kind == "FETCHER" then
				ok(PetLook.hover(kind, 0) >= 3.2, "Fetcher hovers")
			else
				eq(PetLook.hover(kind, 0), 0, `{kind} walks`)
			end
			-- Pen: standing on the pen's top.
			local pen = block("HatchlingPen", Vector3.new(7, 0.25, 7), CFrame.new(3, 0.4, 8), Color3.new(), Instance.new("Folder"))
			local spot = PetLook.penSpot(pen, 1, model)
			eq(vec(spot.Position), vec(Vector3.new(3 - 2.2, 0.525, 8)), `{kind} stands on the pen floor`)
			pen:Destroy()
		end
	end)
	local root = Instance.new("Part")
	root.Size = Vector3.new(2, 2, 1)
	eq(PetLook.groundBelow(root, nil), 3, "default rig: floor 3 below the root")
	local humanoid = Instance.new("Humanoid")
	humanoid.HipHeight = 2.5
	eq(PetLook.groundBelow(root, humanoid), 3.5, "the rig's own hip height")
end)

test("rarity paint: accent = rarity colour; glow by tier; Neon at Legendary+; Mythic sparkle", function()
	local art, ids = fakeArt()
	withArt(art, ids, function()
		for _, kind in KINDS do
			local authored = ArtIds.pet[kind].colors
			for _, rarity in RARITIES do
				local model = PetLook.build({ id = 1, kind = kind, rarity = rarity }, AT, false)
				local colour = PetLook.RARITY_COLOURS[rarity]
				local accent, glow = byGroup(model, "accent"), byGroup(model, "glow")
				eq(accent.Color, colour, `{kind} {rarity} accent`)
				eq(accent.Material, Enum.Material.SmoothPlastic, `{kind} {rarity} accent material`)
				local marked = rarity ~= "COMMON" and rarity ~= "UNCOMMON"
				local neon = rarity == "LEGENDARY" or rarity == "MYTHIC"
				eq(glow.Color, if marked then colour else authored.glow, `{kind} {rarity} glow colour`)
				eq(glow.Material, if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic, `{kind} {rarity} glow material`)
				eq(byGroup(model, "leaf").Color, authored.leaf, `{kind} {rarity} leaf tag stays green`)
				eq(byGroup(model, "body").Color, authored.body, `{kind} {rarity} body authored`)
				local sparkle = model:FindFirstChild(PetLook.SPARKLE, true)
				eq(sparkle ~= nil, rarity == "MYTHIC", `{kind} {rarity} sparkle only on Mythic`)
				if sparkle then
					ok(sparkle:IsA("ParticleEmitter") and (sparkle :: ParticleEmitter).Rate <= 5, "the sparkle is light")
				end
			end
		end
	end)
end)

test("incubators: one per slot by the hut door, the warming egg at eggSeat, bulb lit while warming", function()
	local art, ids = fakeArt()
	withArt(art, ids, function()
		local now = 1000
		local root = PetLook.incubators({ { egg = "SPECKLED", readyAt = now + 60 } }, now, 1, AT) :: Model
		ok(root ~= nil, "shown with the Incubator art")
		eq(#root:GetChildren(), 1, "one slot = one incubator")
		local one = root:FindFirstChild("Incubator1") :: Model
		local wood = byGroup(one, "wood")
		eq(vec(wood.CFrame.Position), vec((AT * CFrame.new(PetLook.INCUBATOR_SPOTS[1]) * CFrame.new(0, 0.5, 0)).Position), "at slot 1's spot")
		local bulb = byGroup(one, "glow")
		eq(bulb.Material, Enum.Material.Neon, "bulb lit while warming")
		eq(one:GetAttribute("Warming"), true, "warming")
		local egg = one:FindFirstChild("Egg_SPECKLED") :: Model
		ok(egg ~= nil, "the warming egg sits in it")
		local shell = byGroup(egg, "shell")
		eq(vec(shell.CFrame.Position), vec((AT * CFrame.new(PetLook.INCUBATOR_SPOTS[1] + PetLook.EGG_SEAT + Vector3.new(0, 0.7, 0))).Position), "egg base at eggSeat")
		eq(shell.Color, ArtIds.egg.SPECKLED.colors.shell, "egg in its authored colours")
		for _, p in artParts(root) do
			ok(p.Anchored and not p.CanCollide and not p.CanQuery and not p.CanTouch, `{p.Name} ghost`)
		end

		local two = PetLook.incubators({ { egg = "MUD", readyAt = now - 1 } }, now, 2, AT) :: Model
		eq(#two:GetChildren(), 2, "two slots = two incubators")
		local ready = two:FindFirstChild("Incubator1") :: Model
		eq(byGroup(ready, "glow").Material, Enum.Material.SmoothPlastic, "a ready egg's bulb is off")
		ok(ready:FindFirstChild("Egg_MUD") ~= nil, "the ready egg still sits there")
		local empty = two:FindFirstChild("Incubator2") :: Model
		eq(byGroup(empty, "glow").Material, Enum.Material.SmoothPlastic, "an empty incubator's bulb is off")
		eq(#empty:GetChildren() > 0 and empty:FindFirstChildWhichIsA("Model") == nil, true, "empty: no egg")
	end)
	local _, ids2 = fakeArt()
	local noEggs = fakeArt()
	for _, key in { "MUD", "SPECKLED", "GOLDEN" } do
		(noEggs:FindFirstChild("egg") :: Instance):FindFirstChild(key):Destroy()
	end
	withArt(noEggs, ids2, function()
		local root = PetLook.incubators({ { egg = "GOLDEN", readyAt = 9e9 } }, 0, 1, AT) :: Model
		local one = root:FindFirstChild("Incubator1") :: Model
		ok(one ~= nil and one:FindFirstChildWhichIsA("Model") == nil, "egg art not loaded: the incubator alone")
	end)
end)
