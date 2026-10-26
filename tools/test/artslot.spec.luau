--[[
	Art slots (PLAN 11a T148, DECISIONS #425/#426), built as real instances under Lune.
	1. Fallback = today: with the real (empty) ArtIds, an id that isn't loaded, a stale
	   template, ArtOff, or a template missing its head piece, every dino at every size and
	   every tower builds exactly what it built before art slots existed
	   (looks_snapshot.json, made from the pre-T148 looks: ARTSLOT_WRITE=1 rewrites it).
	2. Visual only, with a fake loaded template: the gameplay part (dino Root, tower Body)
	   keeps its Size, CFrame, collision, query, touch, mass and anchoring; every art piece
	   is Massless, no collide / query / touch, welded or anchored, no scripts; per-size
	   scaling applies; status effects, pool bar, range ring, tier label, HP bar, crown and
	   flag still show.
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local Config = require(src.shared.Config)
local DinoLook = require(src.shared.DinoLook)
local TowerLook = require(src.shared.TowerLook)

local SNAPSHOT_PATH = "tools/test/looks_snapshot.json"
local AT = CFrame.new(10, 3, -5) * CFrame.Angles(0, 0.7, 0)
local BASE = Vector3.new(40, 2, -30)
local RANGE = 20

local function num(n: number): string
	if math.abs(n) < 5e-4 then
		n = 0
	end
	return string.format("%.3f", n)
end
local function vec(v: Vector3): string
	return `{num(v.X)},{num(v.Y)},{num(v.Z)}`
end

-- One line per instance, depth-first, with every visual and physical property we build.
local function describe(inst: Instance, depth: number, out: { string })
	local line = `{string.rep(" ", depth)}{inst.ClassName} {inst.Name}`
	if inst:IsA("BasePart") then
		local c = inst.CFrame
		line ..= ` size={vec(inst.Size)} pos={vec(c.Position)} x={vec(c.XVector)} y={vec(c.YVector)}`
		line ..= ` rgb={num(inst.Color.R)},{num(inst.Color.G)},{num(inst.Color.B)} mat={inst.Material.Name}`
		line ..= ` tr={num(inst.Transparency)} anch={tostring(inst.Anchored)} mass0={tostring(inst.Massless)}`
		line ..= ` coll={tostring(inst.CanCollide)} q={tostring(inst.CanQuery)} t={tostring(inst.CanTouch)} sh={tostring(inst.CastShadow)}`
		if inst:IsA("Part") then
			line ..= ` shape={inst.Shape.Name}`
		end
	elseif inst:IsA("WeldConstraint") then
		line ..= ` {inst.Part0 and inst.Part0.Name or "-"}>{inst.Part1 and inst.Part1.Name or "-"}`
	end
	local names = {}
	for name in inst:GetAttributes() do
		table.insert(names, name)
	end
	table.sort(names)
	for _, name in names do
		line ..= ` @{name}={tostring(inst:GetAttribute(name))}`
	end
	table.insert(out, line)
	for _, child in inst:GetChildren() do
		describe(child, depth + 1, out)
	end
end

local function fingerprint(model: Instance, extra: string?): string
	local out = { extra or "" }
	describe(model, 0, out)
	return table.concat(out, "\n")
end

local function dinoPrint(key: string, size: number, sizes: number): string
	local model, height = DinoLook.build(key, DinoLook.scale(size, sizes), AT)
	return fingerprint(model, `height={num(height)}`)
end

-- Every look the art slots touch, today.
local function allLooks(): { [string]: string }
	local looks = {}
	for _, key in Config.EnemyOrder do
		local sizes = math.max(1, Config.Enemies[key].sizes or 1)
		for size = 1, sizes do
			looks[`dino:{key}:{size}`] = dinoPrint(key, size, sizes)
		end
	end
	for _, key in Config.TowerOrder do
		looks[`tower:{key}`] = fingerprint(TowerLook.build(key, RANGE, BASE))
	end
	return looks
end

if process.env.ARTSLOT_WRITE == "1" then
	fs.writeFile(SNAPSHOT_PATH, serde.encode("json", allLooks(), true))
	print(`  wrote {SNAPSHOT_PATH}`)
	return
end

local ArtSlot = require(src.shared.ArtSlot)
local SNAPSHOT = serde.decode("json", fs.readFile(SNAPSHOT_PATH))

local function sameAsSnapshot(what: string)
	local looks = allLooks()
	local count = 0
	for key, before in SNAPSHOT do
		count += 1
		eq(looks[key], before, `{what}: {key} built as before`)
	end
	for key in looks do
		ok(SNAPSHOT[key] ~= nil, `{key} in the snapshot`)
	end
	ok(count > 0, "snapshot has looks")
end

test("real ArtIds: generated header, and no model id anywhere today (colours only)", function()
	local text = fs.readFile("src/shared/ArtIds.luau")
	ok(string.find(text, "GENERATED", 1, true) and string.find(text, "DO NOT EDIT", 1, true), "do-not-edit header")
	ok(string.find(text, "tools/art", 1, true), "names its writer")
	local ArtIds = require(src.shared.ArtIds)
	for kind, byKey in ArtIds do
		for key, entry in byKey do
			ok(entry.model == nil, `{kind}/{key} has an id: re-check the fallback snapshot by hand`)
			for group, c in entry.colors or {} do
				ok(typeof(c) == "Color3", `{kind}/{key} colour {group} is a Color3`)
			end
		end
	end
	local llama = ArtIds.dino.LLAMA
	ok(llama and llama.colors and llama.colors.glow ~= nil, "LLAMA carries its authored glow colour (#439)")
end)

test("empty ArtIds: every dino at every size and every tower builds exactly as before", function()
	ArtSlot.setIds(nil)
	ArtSlot.setSource(nil)
	sameAsSnapshot("empty ids")
end)

-- A fake loaded template: a body, a head (ArtRole head, with a Mouth attachment), an eye,
-- plus a script and a joint that must not survive the clone.
local ID = 4242
local function template(key: string, bodySize: Vector3, bodyAt: Vector3, withHead: boolean?, low: number?): Model
	local drop = CFrame.new(0, -(low or 0), 0) -- towers: head and eye kept below the body's top
	local model = Instance.new("Model")
	model.Name = key
	model:SetAttribute("ArtId", ID)
	local body = Instance.new("MeshPart")
	body.Name = "body"
	body.Size = bodySize
	body.CFrame = CFrame.new(bodyAt)
	body.Anchored = true
	body.CanCollide = true
	body.Parent = model
	local script = Instance.new("Script")
	script.Parent = body
	local joint = Instance.new("WeldConstraint")
	joint.Parent = body
	if withHead ~= false then
		local head = Instance.new("MeshPart")
		head.Name = "headpiece"
		head:SetAttribute("PaintGroup", "accent")
		head:SetAttribute("ArtRole", "head")
		head.Size = Vector3.new(1, 0.9, 1.2)
		head.CFrame = drop * CFrame.new(0, 0.6, -1.4) * CFrame.Angles(0.2, 0, 0)
		head.CanQuery = true
		head.Parent = model
		local mouth = Instance.new("Attachment")
		mouth.Name = "Mouth"
		mouth.Parent = head
	end
	local eye = Instance.new("MeshPart")
	eye.Name = "eye"
	eye.Size = Vector3.new(0.2, 0.2, 0.2)
	eye.CFrame = drop * CFrame.new(0.3, 0.8, -1.9)
	eye.CanTouch = true
	eye.Parent = model
	return model
end

-- A fake ReplicatedStorage.Art with a template for every dino and tower, and ids for all.
local function fakeArt(withHead: boolean?): (Instance, { [string]: { [string]: any } })
	local art = Instance.new("Folder")
	art.Name = "Art"
	local ids = { dino = {}, tower = {} }
	local dinos = Instance.new("Folder")
	dinos.Name = "dino"
	dinos.Parent = art
	for _, key in Config.EnemyOrder do
		template(key, Vector3.new(1.5, 1.2, 2.5), Vector3.zero, withHead).Parent = dinos
		ids.dino[key] = { model = ID }
	end
	local towers = Instance.new("Folder")
	towers.Name = "tower"
	towers.Parent = art
	for _, key in Config.TowerOrder do
		-- Reaches exactly as high as today's look, so the crown and flag land where they did.
		local blocky = TowerLook.build(key, RANGE, BASE)
		local body = blocky.PrimaryPart :: BasePart
		local top = (blocky:GetAttribute("LookTop") or body.Size.Y) :: number
		template(key, Vector3.new(2, 2, 2), Vector3.new(0, top - body.Size.Y / 2 - 1, 0), true, 3).Parent = towers
		ids.tower[key] = { model = ID }
	end
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

test("ids but nothing loaded, a stale template, ArtOff, or no head piece: blocky as before", function()
	local _, ids = fakeArt()
	withArt(Instance.new("Folder"), ids, function()
		sameAsSnapshot("not loaded")
	end)
	local stale, staleIds = fakeArt()
	for kind, byKey in staleIds do
		for key in byKey do
			staleIds[kind][key] = { model = ID + 1 } -- re-uploaded; the old template is stale
		end
	end
	withArt(stale, staleIds, function()
		sameAsSnapshot("stale")
	end)
	local off, offIds = fakeArt()
	off:SetAttribute("ArtOff", true)
	withArt(off, offIds, function()
		sameAsSnapshot("ArtOff")
	end)
	local headless, headlessIds = fakeArt(false)
	headlessIds.tower = {} -- towers need no head
	withArt(headless, headlessIds, function()
		sameAsSnapshot("no head piece")
	end)
end)

local function samePhysics(a: BasePart, b: BasePart, what: string)
	eq(vec(a.Size), vec(b.Size), `{what} Size`)
	eq(vec(a.CFrame.Position), vec(b.CFrame.Position), `{what} position`)
	eq(vec(a.CFrame.XVector) .. vec(a.CFrame.YVector), vec(b.CFrame.XVector) .. vec(b.CFrame.YVector), `{what} rotation`)
	for _, prop in { "CanCollide", "CanQuery", "CanTouch", "Massless", "Anchored" } do
		eq((a :: any)[prop], (b :: any)[prop], `{what} {prop}`)
	end
end

-- Every art piece: Massless, ghost to physics, no scripts or stray joints, attached.
local function artPieces(model: Model, gameplay: BasePart, anchored: boolean, what: string): { BasePart }
	local pieces = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("ArtPiece") then
			table.insert(pieces, d)
			ok(d.Massless and not d.CanCollide and not d.CanQuery and not d.CanTouch, `{what} {d.Name} ghost + massless`)
			eq(d.Anchored, anchored, `{what} {d.Name} anchored`)
			for _, inner in d:GetDescendants() do
				ok(not inner:IsA("LuaSourceContainer"), `{what} {d.Name} has no scripts`)
				ok(inner:IsA("Attachment") or inner:IsA("WeldConstraint"), `{what} {d.Name} keeps only attachments + its weld`)
				if inner:IsA("WeldConstraint") then
					ok(inner.Part0 == gameplay and inner.Part1 == d, `{what} {d.Name} welded to the gameplay part`)
				end
			end
		end
	end
	return pieces
end

test("dino art is visual only: Root, height and per-size scale unchanged; effects still show", function()
	local art, ids = fakeArt()
	for _, key in Config.EnemyOrder do
		local sizes = math.max(1, Config.Enemies[key].sizes or 1)
		for size = 1, sizes do
			local scale = DinoLook.scale(size, sizes)
			local what = `{key} size {size}`
			local blocky, blockyHeight = DinoLook.build(key, scale, AT)
			local model, height
			withArt(art, ids, function()
				model, height = DinoLook.build(key, scale, AT)
			end)
			eq(num(height), num(blockyHeight), `{what} root height`)
			local root = model.PrimaryPart :: BasePart
			eq(root.Name, "Root", `{what} PrimaryPart`)
			samePhysics(root, blocky.PrimaryPart :: BasePart, `{what} Root`)
			eq(model:GetAttribute("ArtKey"), key, `{what} dressed`)
			local pieces = artPieces(model, root, false, what)
			eq(#pieces, 3, `{what} body + head + eye, no blocks`)
			for _, p in pieces do
				eq(p.CastShadow, false, `{what} {p.Name} no shadow`)
				ok(p:FindFirstChildWhichIsA("WeldConstraint") ~= nil, `{what} {p.Name} welded`)
			end
			local head = model:FindFirstChild("Head") :: BasePart
			ok(head and head:GetAttribute("ArtPiece"), `{what} art head named Head`)
			eq(vec(head.Size), vec(Vector3.new(1, 0.9, 1.2) * scale), `{what} head scaled`)
			local expected = AT * CFrame.new(Vector3.new(0, 0.6, -1.4) * scale)
			eq(vec(head.CFrame.Position), vec(expected.Position), `{what} head placed x scale`)
			ok(head:FindFirstChild("Mouth") ~= nil, `{what} Mouth attachment kept`)
			local body = model:FindFirstChild("Art_body") :: BasePart
			ok(body ~= nil and body.Color == DinoLook.colorOf(key), `{what} body painted the species colour`)
			DinoLook.setSedated(model, true)
			DinoLook.setMuzzled(model, true)
			DinoLook.setAsleep(model, true)
			DinoLook.setPoolBar(model, 0.5, { 0.5 })
			ok(model:FindFirstChild("SedationDart") ~= nil, `{what} sedation dart`)
			ok(model:FindFirstChild("Muzzle") ~= nil, `{what} Jaw Lock muzzle`)
			ok(root:FindFirstChild("Asleep") ~= nil, `{what} zzz`)
			ok(model:FindFirstChild("PoolBar", true) ~= nil, `{what} pool bar`)
			DinoLook.flashHead(model)
			ok(head:GetAttribute("FlashColor") ~= nil, `{what} throw cue flashes the head`)
			DinoLook.endHeadFlash(model)
		end
	end
end)

-- A tower's overlays (everything but its look parts), with the Body's transparency and the
-- art's own key left out: the look parts are the only thing art may change.
local function overlays(model: Model): string
	local out = {}
	local function walk(inst: Instance, depth: number)
		if inst:IsA("BasePart") and inst ~= model.PrimaryPart and inst:GetAttribute("LookMaterial") ~= nil then
			return -- a silhouette block or an art piece
		end
		local lines = {}
		describe(inst, depth, lines)
		local line = lines[1]
		if inst == model.PrimaryPart then
			line = string.gsub(line, " tr=[%d%.%-]+", "")
		elseif inst == model then
			line = string.gsub(string.gsub(line, " @ArtKey=%S+", ""), " @LookTop=%S+", "")
		end
		table.insert(out, line)
		for _, child in inst:GetChildren() do
			walk(child, depth + 1)
		end
	end
	walk(model, 0)
	return table.concat(out, "\n")
end

local function dressUp(model: Model)
	TowerLook.refresh(model, RANGE, { 3, 1, 0 }, 1, "Test Tier")
	TowerLook.setHealth(model, 0.5)
	TowerLook.addFlag(model, Color3.fromRGB(200, 40, 40))
end

test("tower art is visual only: Body, ring, tier label, HP bar, crown and flag unchanged", function()
	local art, ids = fakeArt()
	for _, key in Config.TowerOrder do
		local blocky = TowerLook.build(key, RANGE, BASE)
		dressUp(blocky)
		local model
		withArt(art, ids, function()
			model = TowerLook.build(key, RANGE, BASE)
		end)
		dressUp(model)
		local body = model.PrimaryPart :: BasePart
		eq(body.Name, "Body", `{key} PrimaryPart`)
		samePhysics(body, blocky.PrimaryPart :: BasePart, `{key} Body`)
		eq(body.Transparency, 1, `{key} Body hidden under the art`)
		eq(model:GetAttribute("ArtKey"), key, `{key} dressed`)
		local pieces = artPieces(model, body, true, key)
		eq(#pieces, 3, `{key} art pieces, no silhouette blocks`)
		for _, p in pieces do
			ok(typeof(p:GetAttribute("LookMaterial")) == "string", `{key} {p.Name} restorable by the glow`)
		end
		local got, want = string.split(overlays(model), "\n"), string.split(overlays(blocky), "\n")
		eq(#got, #want, `{key} overlay count`)
		for i, line in want do
			eq(got[i], line, `{key} overlay {i}`)
		end
		ok(model:FindFirstChild("Crown") and model:FindFirstChild("Range"), `{key} crown + ring present`)
	end
end)

-- #439: the art's authored colour per paint group wins; groups without one take the look's
-- paints; group "glow" is Neon; the gameplay part is untouched.
test("authored colours: per group, look paints as fallback, glow is Neon, gameplay part untouched", function()
	local art = Instance.new("Folder")
	art.Name = "Art"
	local dinos = Instance.new("Folder")
	dinos.Name = "dino"
	dinos.Parent = art
	local model = template("LLAMA", Vector3.new(1.5, 1.2, 2.5), Vector3.zero)
	local glow = Instance.new("MeshPart")
	glow.Name = "glow"
	glow.Size = Vector3.new(0.3, 0.6, 0.8)
	glow.CFrame = CFrame.new(0, 1, -1)
	glow.Parent = model
	local belly = Instance.new("MeshPart")
	belly.Name = "belly"
	belly.Size = Vector3.new(1, 0.4, 2)
	belly.CFrame = CFrame.new(0, -0.5, 0)
	belly.Parent = model
	model.Parent = dinos
	local BODY, ACCENT, GLOW = Color3.fromRGB(70, 55, 150), Color3.fromRGB(225, 50, 170), Color3.fromRGB(90, 245, 255)
	local ids = { dino = { LLAMA = { model = ID, colors = { body = BODY, accent = ACCENT, glow = GLOW } } }, tower = {} }
	local paints = ArtSlot.paints(Color3.fromRGB(200, 10, 10), Color3.fromRGB(10, 200, 10))

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(2, 2, 3)
	root.CFrame = AT
	root.Anchored = true
	root.CanCollide = true
	root.CanQuery = true
	root.CanTouch = true
	root.Color = Color3.fromRGB(1, 2, 3)
	root.Material = Enum.Material.Plastic
	local before = root:Clone()
	local host = Instance.new("Model")
	root.Parent = host

	local dressed, made
	withArt(art, ids, function()
		eq(ArtSlot.colors("dino", "LLAMA"), ids.dino.LLAMA.colors, "colors() reads the entry")
		eq(ArtSlot.colors("dino", "HUSK"), nil, "no entry, no authored colours")
		dressed, made = ArtSlot.dress(host, "dino", "LLAMA", 1.5, root, paints, { roles = { "head" } })
	end)
	ok(dressed, "dressed")
	eq(#made, 5, "body, head, eye, glow, belly")
	local byGroup: { [string]: BasePart } = {}
	for _, p in made do
		byGroup[p:GetAttribute("PaintGroup") :: string] = p
	end
	eq(byGroup.body.Color, BODY, "authored body colour beats the look's")
	eq(byGroup.accent.Color, ACCENT, "authored accent on the head piece (group accent)")
	eq(byGroup.accent.Name, "Head", "head role still named Head")
	eq(byGroup.glow.Color, GLOW, "authored glow colour")
	eq(byGroup.glow.Material, Enum.Material.Neon, "glow is Neon")
	eq(byGroup.belly.Color, paints.belly, "no authored belly: the look's belly paint")
	eq(byGroup.eye.Color, paints.eye, "no authored eye: the look's eye paint")
	for group, p in byGroup do
		if group ~= "glow" then
			eq(p.Material, Enum.Material.SmoothPlastic, `{group} SmoothPlastic`)
		end
	end
	artPieces(host, root, false, "authored")
	samePhysics(root, before, "Root")
	eq(root.Color, before.Color, "Root colour untouched")
	eq(root.Material, before.Material, "Root material untouched")
	eq(root.Transparency, before.Transparency, "Root transparency untouched by dress()")

	-- No authored colours (towers today, future skins): the look's paints, glow still Neon.
	local plainHost = Instance.new("Model")
	local plainRoot = root:Clone()
	plainRoot.Parent = plainHost
	withArt(art, { dino = { LLAMA = { model = ID } }, tower = {} }, function()
		dressed, made = ArtSlot.dress(plainHost, "dino", "LLAMA", 1, plainRoot, paints, { roles = { "head" } })
	end)
	ok(dressed, "dressed without colours")
	for _, p in made do
		local group = p:GetAttribute("PaintGroup") :: string
		eq(p.Color, paints[group] or paints.body, `{group} falls back to the look's paints`)
		eq(p.Material, if group == "glow" then Enum.Material.Neon else Enum.Material.SmoothPlastic, `{group} material`)
	end
end)
