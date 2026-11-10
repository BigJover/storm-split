--[[
	Gun + kit art and the first-person viewmodel (PLAN 11c T151 + T151b, DECISIONS #435/#449),
	Shared/GunArt and Shared/Viewmodel on fake tools, characters and templates, under Lune.
	1. No art (the real ArtIds: no ids yet; not loaded; ArtOff) = the gun Tool exactly as today
	   (nothing added, Handle untouched), no muzzles (today's tracer origin), no kit props, no
	   viewmodel.
	2. Dressed: pieces welded to the Handle at identity (the grip convention), ghost, no
	   scripts; the Handle keeps size / CFrame / grip / collision / mass and only turns invisible;
	   Muzzle (+ Muzzle2) at the art's muzzle; attachments only when the stats show them; Dual
	   Pistols' left gun on the LeftHand's grip; paint: accent = the gun paint, mastery gold =
	   steel + brass; a re-dress replaces, a lost template restores the Handle.
	3. Kit props: anchored ghost models with the origin at the pivot.
	4. Viewmodel: the gun pieces at their grip offsets and the arms where they sit relative to
	   the held gun in the rest pose; anchored ghosts; stale when the gun is re-dressed.
	5. The real ArtIds carry every gun, attachment and kit key with the roles the runtime needs.
]]

local Config = require(src.shared.Config)
local ArtSlot = require(src.shared.ArtSlot)
local GunArt = require(src.shared.GunArt)
local HunterBody = require(src.shared.HunterBody)
local Viewmodel = require(src.shared.Viewmodel)

local ID = 7151
local KEYS = Config.HeroOrder :: { string }
local AT = CFrame.new(5, 3, -2) * CFrame.Angles(0.2, 0.9, -0.1)
local MUZZLE = Vector3.new(0, 0.25, -1.5)
local MUZZLE2 = Vector3.new(-0.12, 0.25, -1.5)
local OFFSET = CFrame.new(0.02, 0.1, -0.4) * CFrame.Angles(0, 0, 0.3)
local AUTHORED = {
	steel = Color3.fromRGB(64, 72, 86),
	brass = Color3.fromRGB(214, 168, 70),
	wood = Color3.fromRGB(132, 86, 50),
	accent = Color3.fromRGB(1, 2, 3),
}
local ACCENT = Color3.fromRGB(10, 200, 30)
local GOLD = Color3.fromRGB(250, 200, 60)
local PLAIN = { accent = ACCENT, accentMaterial = Enum.Material.Neon }
local STATS = { scope = false, beltFed = false, shotsPerTrigger = 1, fireMode = "semi", guns = 1 }

local function with(base: any, changes: any): any
	local out = table.clone(base)
	for k, v in changes do
		out[k] = v
	end
	return out
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
local function closeCf(a: CFrame, b: CFrame): boolean
	return (a.Position - b.Position).Magnitude < 1e-3 and (a.XVector - b.XVector).Magnitude < 1e-3 and (a.YVector - b.YVector).Magnitude < 1e-3
end

-- A template: a few pieces about the grip; `muzzle` / `muzzle2` roles from the ids' pieces.
local function template(key: string, names: { string }): Model
	local model = Instance.new("Model")
	model.Name = key
	model:SetAttribute("ArtId", ID)
	for i, name in names do
		local piece = Instance.new("MeshPart")
		piece.Name = name
		piece.Size = Vector3.new(0.2, 0.3, 0.5 + i * 0.1)
		piece.CFrame = if name == "muzzle" then CFrame.new(MUZZLE) elseif name == "muzzle2" then CFrame.new(MUZZLE2) else OFFSET * CFrame.new(0, 0, i * 0.1)
		piece.Anchored = true
		piece.CanCollide = true
		piece.CanQuery = true
		piece.Parent = model
		if i == 1 then
			Instance.new("Script").Parent = piece
			Instance.new("WeldConstraint").Parent = piece
		end
	end
	return model
end

local function fakeArt(): (Instance, any)
	local art = Instance.new("Folder")
	art.Name = "Art"
	local guns = Instance.new("Folder")
	guns.Name = "gun"
	guns.Parent = art
	local kit = Instance.new("Folder")
	kit.Name = "kit"
	kit.Parent = art
	local ids: any = { dino = {}, tower = {}, hunter = {}, gun = {}, kit = {} }
	local muzzleRole = { muzzle = { group = "steel", role = "muzzle" } }
	for _, key in KEYS do
		template(key, { "steel", "wood", "accent", "brass", "muzzle" }).Parent = guns
		ids.gun[key] = { model = ID, colors = table.clone(AUTHORED), pieces = muzzleRole }
		for _, which in { "MELEE", "GRENADE" } do
			local k = `{key}_{which}`
			template(k, { "steel", "accent" }).Parent = kit
			ids.kit[k] = { model = ID, colors = table.clone(AUTHORED) }
		end
	end
	for _, a in GunArt.ATTACHMENTS do
		local names = if a.key == "SHOTGUN_DOUBLE" then { "steel", "muzzle2" } else { "steel", "brass" }
		template(a.key, names).Parent = guns
		ids.gun[a.key] = {
			model = ID,
			colors = table.clone(AUTHORED),
			pieces = if a.key == "SHOTGUN_DOUBLE" then { muzzle2 = { group = "steel", role = "muzzle2" } } else nil,
		}
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

-- Today's gun Tool (Server/Hero syncTool).
local function gunTool(): (Tool, Part)
	local tool = Instance.new("Tool")
	tool.RequiresHandle = true
	tool:SetAttribute("HeroWeapon", true)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 0.5, 2)
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.Massless = true
	handle.CFrame = AT
	handle.Color = ACCENT
	handle.Parent = tool
	return tool, handle
end

local function fingerprint(inst: Instance): string
	local lines = {}
	for _, d in { inst, unpack(inst:GetDescendants()) } do
		local line = `{d:GetFullName()} {d.ClassName}`
		if d:IsA("BasePart") then
			line ..= ` size={d.Size} cf={cf(d.CFrame)} tr={num(d.Transparency)} rgb={d.Color} mat={d.Material.Name} coll={d.CanCollide} q={d.CanQuery} t={d.CanTouch} m0={d.Massless} anch={d.Anchored}`
		elseif d:IsA("Tool") then
			line ..= ` grip={cf(d.Grip)}`
		end
		local names = {}
		for name in d:GetAttributes() do
			table.insert(names, name)
		end
		table.sort(names)
		for _, name in names do
			line ..= ` @{name}={tostring(d:GetAttribute(name))}`
		end
		table.insert(lines, line)
	end
	table.sort(lines)
	return table.concat(lines, "\n")
end

local function artPieces(tool: Instance, folder: string): { BasePart }
	local out = {}
	local f = tool:FindFirstChild(folder)
	for _, d in (if f then f:GetChildren() else {}) do
		if d:IsA("BasePart") then
			table.insert(out, d)
		end
	end
	return out
end

local function keysOf(pieces: { BasePart }): { [string]: number }
	local out = {}
	for _, p in pieces do
		local k = p:GetAttribute("ArtKey")
		out[k] = (out[k] or 0) + 1
	end
	return out
end

-- A minimal R15 rig: the 15 parts on Motor6Ds about the root, grip attachments on the hands.
local CENTRE = {
	HumanoidRootPart = Vector3.zero,
	LowerTorso = Vector3.new(0, -0.8, 0),
	UpperTorso = Vector3.new(0, 0.2, 0),
	Head = Vector3.new(0, 1.586, 0),
}
local PARENT = { LowerTorso = "HumanoidRootPart", UpperTorso = "LowerTorso", Head = "UpperTorso" }
for _, pair in { { -1, "Left" }, { 1, "Right" } } do
	local s, side = pair[1] :: number, pair[2] :: string
	CENTRE[side .. "UpperArm"] = Vector3.new(1.5 * s, 0.369, 0)
	CENTRE[side .. "LowerArm"] = Vector3.new(1.5 * s, -0.224, 0)
	CENTRE[side .. "Hand"] = Vector3.new(1.5 * s, -0.85, 0)
	CENTRE[side .. "UpperLeg"] = Vector3.new(0.5 * s, -1.421, 0)
	CENTRE[side .. "LowerLeg"] = Vector3.new(0.5 * s, -2.201, 0)
	CENTRE[side .. "Foot"] = Vector3.new(0.5 * s, -2.85, 0)
	PARENT[side .. "UpperArm"] = "UpperTorso"
	PARENT[side .. "LowerArm"] = side .. "UpperArm"
	PARENT[side .. "Hand"] = side .. "LowerArm"
	PARENT[side .. "UpperLeg"] = "LowerTorso"
	PARENT[side .. "LowerLeg"] = side .. "UpperLeg"
	PARENT[side .. "Foot"] = side .. "LowerLeg"
end
local GRIP_ATT = CFrame.new(0, -0.15, 0) * CFrame.Angles(-math.pi / 2, 0, 0)

local function character(): Model
	local model = Instance.new("Model")
	model.Name = "Hunter"
	local parts = {}
	for name, centre in CENTRE do
		local part = Instance.new("MeshPart")
		part.Name = name
		part.Size = Vector3.new(1, 1, 1)
		part.CFrame = AT * CFrame.new(centre)
		part.Parent = model
		parts[name] = part
	end
	for name, parent in PARENT do
		local motor = Instance.new("Motor6D")
		motor.Part0 = parts[parent]
		motor.Part1 = parts[name]
		motor.C0 = CFrame.new(CENTRE[name] - CENTRE[parent])
		motor.C1 = CFrame.identity
		motor.Parent = parts[name]
	end
	for _, side in { "Left", "Right" } do
		local a = Instance.new("Attachment")
		a.Name = side .. "GripAttachment"
		a.CFrame = GRIP_ATT
		a.Parent = parts[side .. "Hand"]
	end
	return model
end

local function bodyArt(art: Instance, ids: any)
	local hunters = Instance.new("Folder")
	hunters.Name = "hunter"
	hunters.Parent = art
	for _, key in KEYS do
		local model = Instance.new("Model")
		model.Name = key
		model:SetAttribute("ArtId", ID)
		for _, part in HunterBody.PARTS do
			local piece = Instance.new("MeshPart")
			piece.Name = `{part}__shirt`
			piece.Size = Vector3.new(0.5, 0.5, 0.5)
			piece.CFrame = CFrame.new(CENTRE[part]) * CFrame.new(0.03, 0.05, 0)
			piece.Parent = model
		end
		model.Parent = hunters
		ids.hunter[key] = { model = ID, colors = { shirt = Color3.fromRGB(90, 100, 60) } }
	end
end

test("no art: the gun Tool exactly as today, today's tracer origin, no props, no viewmodel", function()
	local art, ids = fakeArt()
	local off, offIds = fakeArt()
	off:SetAttribute("ArtOff", true)
	local stale, staleIds = fakeArt()
	for _, byKey in { staleIds.gun, staleIds.kit } do
		for _, entry in byKey do
			entry.model = ID + 1
		end
	end
	local cases = {
		real = { nil, nil },
		notLoaded = { Instance.new("Folder"), ids },
		artOff = { off, offIds },
		staleId = { stale, staleIds },
	}
	for name, case in cases do
		withArt(case[1], case[2], function()
			for _, key in KEYS do
				local tool, handle = gunTool()
				local before = fingerprint(tool)
				local stats = with(STATS, { scope = true, beltFed = true, shotsPerTrigger = 2, fireMode = "auto", guns = 2 })
				eq(GunArt.dressTool(tool, handle, key, stats, PLAIN, nil), false, `{name} {key}: not dressed`)
				eq(fingerprint(tool), before, `{name} {key}: Tool and Handle unchanged`)
				eq(GunArt.muzzles(tool, 1), nil, `{name} {key}: today's tracer origin`)
				eq(GunArt.muzzles(tool, -1), nil, `{name} {key}: today's left-gun origin`)
				eq(GunArt.prop(key, "melee"), nil, `{name} {key}: today's melee block`)
				eq(GunArt.prop(key, "grenade"), nil, `{name} {key}: today's grenade ball`)
				eq(GunArt.copy(tool), nil, `{name} {key}: no rifle to swing`)
				eq(Viewmodel.build(tool, character(), key), nil, `{name} {key}: no viewmodel`)
			end
		end)
	end
end)

test("dressed: welded at identity to an unchanged Handle; ghost pieces; Muzzle at the art's tip", function()
	local art, ids = fakeArt()
	withArt(art, ids, function()
		for _, key in KEYS do
			local tool, handle = gunTool()
			local bare = fingerprint(handle)
			eq(GunArt.dressTool(tool, handle, key, STATS, PLAIN, nil), true, `{key} dressed`)
			ok((handle.Size - Vector3.new(0.4, 0.5, 2)).Magnitude < 1e-4, `{key} Handle size`)
			ok(closeCf(handle.CFrame, AT), `{key} Handle CFrame`)
			eq(handle.CanCollide, false, `{key} Handle collide`)
			eq(handle.Massless, true, `{key} Handle massless`)
			eq(handle.Transparency, 1, `{key} Handle hidden under the art`)
			eq(tool.Grip, CFrame.identity, `{key} grip unchanged`)
			local pieces = artPieces(tool, GunArt.FOLDER)
			eq(#pieces, 5, `{key} every base piece, no attachments at base stats`)
			for _, p in pieces do
				local w = p:FindFirstChild("ArtWeld")
				ok(w and w:IsA("Weld") and w.Part0 == handle and w.Part1 == p, `{key} {p.Name} welded to the Handle`)
				ok(closeCf(p.CFrame, handle.CFrame * w.C0), `{key} {p.Name} at the Handle x its authored offset`)
				eq(p.Massless and not p.CanCollide and not p.CanQuery and not p.CanTouch and not p.CastShadow and not p.Anchored, true, `{key} {p.Name} ghost, welded`)
				for _, d in p:GetDescendants() do
					ok(d:IsA("Weld") or d:IsA("Attachment"), `{key} {p.Name}: no {d.ClassName}`)
				end
				local group = p:GetAttribute("PaintGroup")
				if group == "accent" then
					eq(p.Color, ACCENT, `{key} accent = the gun paint`)
					eq(p.Material, Enum.Material.Neon, `{key} accent material = the gun paint's`)
				elseif group == "steel" or group == "brass" or group == "wood" then
					eq(p.Color, AUTHORED[group], `{key} {group} authored`)
				end
			end
			local muzzle = handle:FindFirstChild(GunArt.MUZZLE)
			ok(muzzle and muzzle:IsA("Attachment"), `{key} Muzzle attachment`)
			local starts = GunArt.muzzles(tool, 1)
			ok(starts and #starts == 1 and (starts[1] - (AT * CFrame.new(MUZZLE)).Position).Magnitude < 1e-3, `{key} tracers from the muzzle`)
			eq(handle:FindFirstChild(GunArt.MUZZLE2), nil, `{key} one barrel`)
			-- art gone: the Handle is back to today's exactly
			ArtSlot.setSource(Instance.new("Folder"))
			eq(GunArt.dressTool(tool, handle, key, STATS, PLAIN, nil), false, `{key} art gone`)
			eq(fingerprint(handle), bare, `{key} Handle restored`)
			eq(tool:FindFirstChild(GunArt.FOLDER), nil, `{key} art removed`)
			ArtSlot.setSource(art)
		end
	end)
end)

test("attachments show with their stats; mastery gold paints steel + brass; re-dress replaces", function()
	local art, ids = fakeArt()
	withArt(art, ids, function()
		eq(table.concat(GunArt.keys("PISTOL", with(STATS, { scope = true })), ","), "PISTOL,PISTOL_SCOPE", "scope")
		eq(table.concat(GunArt.keys("RIFLE", with(STATS, { beltFed = true })), ","), "RIFLE,RIFLE_BELT", "belt fed")
		eq(table.concat(GunArt.keys("RIFLE", with(STATS, { fireMode = "auto", scope = true })), ","), "RIFLE", "auto / scope don't add to the rifle")
		eq(table.concat(GunArt.keys("SHOTGUN", with(STATS, { shotsPerTrigger = 2, fireMode = "auto" })), ","), "SHOTGUN,SHOTGUN_DOUBLE,SHOTGUN_DRUM", "both shotgun attachments")
		eq(table.concat(GunArt.keys("MEDIC", with(STATS, { scope = true, beltFed = true, shotsPerTrigger = 2, fireMode = "auto" })), ","), "MEDIC", "no Medic variants")

		local tool, handle = gunTool()
		GunArt.dressTool(tool, handle, "SHOTGUN", with(STATS, { shotsPerTrigger = 2, fireMode = "auto" }), { accent = ACCENT, accentMaterial = Enum.Material.SmoothPlastic, gold = GOLD }, nil)
		local counts = keysOf(artPieces(tool, GunArt.FOLDER))
		eq(counts.SHOTGUN, 5, "base")
		eq(counts.SHOTGUN_DOUBLE, 2, "double barrel")
		eq(counts.SHOTGUN_DRUM, 2, "drum")
		for _, p in artPieces(tool, GunArt.FOLDER) do
			local group = p:GetAttribute("PaintGroup")
			if group == "steel" or group == "brass" then
				eq(p.Color, GOLD, `mastery gold on {group}`)
			elseif group == "accent" then
				eq(p.Color, ACCENT, "accent keeps the class / skin colour at mastery")
			elseif group == "wood" then
				eq(p.Color, AUTHORED.wood, "wood stays")
			end
		end
		local starts = GunArt.muzzles(tool, 1)
		ok(starts and #starts == 2, "double barrel: two muzzles to alternate")
		ok(starts and (starts[2] - (AT * CFrame.new(MUZZLE2)).Position).Magnitude < 1e-3, "muzzle2 = the left barrel's tip")

		-- re-dress at base stats: the attachments go, nothing doubles
		GunArt.dressTool(tool, handle, "SHOTGUN", STATS, PLAIN, nil)
		counts = keysOf(artPieces(tool, GunArt.FOLDER))
		eq(counts.SHOTGUN, 5, "base once")
		eq(counts.SHOTGUN_DOUBLE, nil, "double gone")
		eq(#tool:GetChildren(), 2, "Handle + one art model")
		local m = 0
		for _, c in handle:GetChildren() do
			m += if c:IsA("Attachment") then 1 else 0
		end
		eq(m, 1, "one Muzzle")

		-- an attachment whose art isn't loaded is left off; the gun still dresses
		art.gun.PISTOL_SCOPE:Destroy()
		GunArt.dressTool(tool, handle, "PISTOL", with(STATS, { scope = true }), PLAIN, nil)
		eq(keysOf(artPieces(tool, GunArt.FOLDER)).PISTOL_SCOPE, nil, "missing attachment skipped")
		eq(handle:GetAttribute("GunArt"), "PISTOL", "still dressed")
	end)
end)

test("Dual Pistols: a second PISTOL on the LeftHand's grip; left tracers from it", function()
	local art, ids = fakeArt()
	withArt(art, ids, function()
		local rig = character()
		local leftHand = rig:FindFirstChild("LeftHand") :: BasePart
		local tool, handle = gunTool()
		GunArt.dressTool(tool, handle, "PISTOL", with(STATS, { guns = 2, scope = true }), PLAIN, leftHand)
		local left = artPieces(tool, GunArt.OFFHAND)
		eq(#left, 5, "the base pistol only, in the left hand")
		for _, p in left do
			local w = p:FindFirstChild("ArtWeld") :: Weld
			ok(w and w.Part0 == leftHand, "welded to the LeftHand")
			ok(closeCf(p.CFrame, leftHand.CFrame * w.C0), "placed on the weld")
			-- held like a Tool: hand x grip attachment x Grip^-1 x the authored offset
			local rel = (GRIP_ATT * tool.Grip:Inverse()):Inverse() * w.C0
			local found = false
			for _, t in art.gun.PISTOL:GetChildren() do
				found = found or closeCf(t.CFrame, rel)
			end
			ok(found, "an authored piece, on the left grip")
		end
		local leftStart = GunArt.muzzles(tool, -1)
		ok(leftStart and (leftStart[1] - (leftHand.CFrame * GRIP_ATT * CFrame.new(MUZZLE)).Position).Magnitude < 1e-3, "left muzzle = the left gun's tip")
		local rightStart = GunArt.muzzles(tool, 1)
		ok(rightStart and (rightStart[1] - (AT * CFrame.new(MUZZLE)).Position).Magnitude < 1e-3, "right muzzle")
		-- one pistol: no left gun
		GunArt.dressTool(tool, handle, "PISTOL", STATS, PLAIN, leftHand)
		eq(tool:FindFirstChild(GunArt.OFFHAND), nil, "single pistol: no left gun")
		eq(GunArt.muzzles(tool, -1), nil, "no left muzzle")
		-- not a pistol: guns never doubles another gun
		GunArt.dressTool(tool, handle, "RIFLE", with(STATS, { guns = 2 }), PLAIN, leftHand)
		eq(tool:FindFirstChild(GunArt.OFFHAND), nil, "only Dual Pistols")
	end)
end)

test("kit props: anchored ghosts, origin at the pivot, authored paint; the rifle copy for Stock Swing", function()
	local art, ids = fakeArt()
	withArt(art, ids, function()
		for _, key in KEYS do
			for _, which in { "melee", "grenade" } do
				local prop = GunArt.prop(key, which)
				ok(prop ~= nil, `{key} {which} prop`)
				if prop then
					eq(prop.Name, `{key}_{if which == "melee" then "MELEE" else "GRENADE"}`, "key")
					ok(closeCf(prop.WorldPivot, CFrame.identity), "origin at the pivot")
					for _, p in prop:GetChildren() do
						ok(p:IsA("BasePart") and p.Anchored and not p.CanCollide and not p.CanQuery and not p.CanTouch and not p.CastShadow, `{key} {which} {p.Name} ghost`)
						ok(#p:GetChildren() == 0, `{key} {which} no scripts / joints`)
						eq(p.Color, AUTHORED[p:GetAttribute("PaintGroup")], "authored colour (accent = class colour)")
					end
				end
			end
		end
		local tool, handle = gunTool()
		GunArt.dressTool(tool, handle, "RIFLE", STATS, PLAIN, nil)
		local copy = GunArt.copy(tool)
		ok(copy ~= nil and #copy:GetChildren() == 5, "rifle copy")
		for _, p in (if copy then copy:GetChildren() else {}) do
			ok(p:IsA("BasePart") and p.Anchored and #p:GetChildren() == 0, "anchored, no weld")
		end
	end)
end)

test("viewmodel: gun at its grip offsets, arms as held in the rest pose, ghost; stale on re-dress", function()
	local art, ids = fakeArt()
	bodyArt(art, ids)
	withArt(art, ids, function()
		for _, key in KEYS do
			local rig = character()
			ok(HunterBody.apply(rig, key), `{key} body on`)
			local tool, handle = gunTool()
			GunArt.dressTool(tool, handle, key, STATS, PLAIN, nil)
			local vm = Viewmodel.build(tool, rig, key)
			ok(vm ~= nil, `{key} viewmodel`)
			if not vm then
				continue
			end
			local camera = CFrame.new(1, 2, 3) * CFrame.Angles(0.1, 0.4, 0)
			Viewmodel.step(vm, camera, 1 / 60)
			local grip = Viewmodel.gripFrame(vm, camera)
			local gunCount, right, left = 0, 0, 0
			local heldAt = rig.RightHand.CFrame * GRIP_ATT * tool.Grip:Inverse()
			for _, item in vm.items do
				local p = item.part
				ok(p.Anchored and not p.CanCollide and not p.CanQuery and not p.CanTouch and not p.CastShadow, `{key} {p.Name} ghost`)
				ok(p.Parent == vm.model, "in the viewmodel")
				ok(closeCf(p.CFrame, grip * item.rel), "placed on the grip")
				eq(p.Color, item.source.Color, "paint follows the source")
				local part = HunterBody.parse(item.source.Name)
				if part then
					ok(part:find("Arm") or part:find("Hand"), `{key} only arm pieces ({part})`)
					if part:sub(1, 5) == "Right" then
						right += 1
						-- the rig stands in its rest pose: the arm sits on the gun as it does in hand
						ok(closeCf(item.rel, heldAt:Inverse() * item.source.CFrame), `{key} {part} as held in the rest pose`)
					else
						left += 1
					end
				else
					gunCount += 1
				end
			end
			eq(gunCount, 5, `{key} gun pieces`)
			eq(right, 3, `{key} right arm`)
			eq(left, if key == "PISTOL" then 0 else 3, `{key} left arm on two-handed guns`)
			-- a camera turn sways, a shot kicks, both settle
			Viewmodel.kick(vm)
			ok(vm.kick > 0.9, "kick")
			for _ = 1, 120 do
				Viewmodel.step(vm, camera, 1 / 60)
			end
			ok(vm.kick < 0.01 and vm.sway.Magnitude < 0.01, "settles")
			ok(not Viewmodel.stale(vm, tool, rig), "fresh")
			GunArt.dressTool(tool, handle, key, STATS, PLAIN, nil)
			ok(Viewmodel.stale(vm, tool, rig), "stale after a re-dress")
			Viewmodel.destroy(vm)
		end
		-- Dual Pistols: two guns and both arms; no body art: the gun alone
		local rig = character()
		HunterBody.apply(rig, "PISTOL")
		local tool, handle = gunTool()
		GunArt.dressTool(tool, handle, "PISTOL", with(STATS, { guns = 2 }), PLAIN, rig:FindFirstChild("LeftHand") :: BasePart)
		local vm = Viewmodel.build(tool, rig, "PISTOL")
		eq(vm and #vm.items, 5 + 5 + 3 + 3, "two pistols, two arms")
		local bare = character()
		local alone = Viewmodel.build(tool, bare, "PISTOL")
		eq(alone and #alone.items, 10, "no body: the guns alone")
	end)
end)

test("real ArtIds: every gun, attachment and kit prop, no ids yet; the roles the runtime reads", function()
	local ArtIds = require(src.shared.ArtIds)
	for _, key in KEYS do
		local gun = ArtIds.gun and ArtIds.gun[key]
		ok(gun ~= nil, `gun {key}`)
		eq(gun and gun.model, nil, `gun {key}: no id yet`)
		eq(gun and gun.pieces and gun.pieces.muzzle and gun.pieces.muzzle.role, "muzzle", `gun {key} muzzle role`)
		ok(gun and gun.colors and gun.colors.accent ~= nil, `gun {key} accent (class colour)`)
		for _, which in { "MELEE", "GRENADE" } do
			local entry = ArtIds.kit and ArtIds.kit[`{key}_{which}`]
			ok(entry ~= nil, `kit {key}_{which}`)
			eq(entry and entry.model, nil, `kit {key}_{which}: no id yet`)
		end
	end
	for _, a in GunArt.ATTACHMENTS do
		ok(ArtIds.gun[a.key] ~= nil, `attachment {a.key}`)
		ok(ArtIds.gun[a.base] ~= nil, `{a.key}'s base`)
	end
	eq(ArtIds.gun.SHOTGUN_DOUBLE.pieces.muzzle2.role, "muzzle2", "double barrel's second muzzle")
end)
