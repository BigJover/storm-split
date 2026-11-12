--[[
	Walker + dino projectile art (PLAN 11d2 runtime, DECISIONS #450), built as real instances
	under Lune with fake loaded templates.
	1. Blank ids = today: with the real ArtIds (no model ids), an id that isn't loaded, or
	   ArtOff, every raptor / ranger kind, the Patrol Jeep, the Paratrooper and every dino
	   projectile style at several sizes build exactly what they built before
	   (walkers_snapshot.json, made from the pre-art looks: WALKERART_WRITE=1 rewrites it).
	2. Visual only: with art, the walker's Body keeps its Size and CFrame (hidden), every art
	   piece is anchored, massless and ghost to physics, camp is painted the camp colour.
	3. Lift rule (#450): with art the model's pivot sits (scale - 1) x 1.2 below the Body, so
	   `PivotTo(track + 1.2)` lifts big kinds and lowers the Swarm; blank = no offset.
	4. Muzzle: the art's `muzzle` piece centre, else nil (the caller's old origin).
	5. Chute: added only with chute art, dropped on landing; the descent is a pure height
	   curve that ends at 0 and never touches gameplay state.
	6. Projectiles: art scaled to the live Shot size; Shot (PrimaryPart), Style and Height
	   unchanged; the blocky extras go.
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local Config = require(src.shared.Config)
local DinoLook = require(src.shared.DinoLook)
local RaptorLook = require(src.shared.RaptorLook)
local RangerLook = require(src.shared.RangerLook)
local TowerLook = require(src.shared.TowerLook)

local SNAPSHOT_PATH = "tools/test/walkers_snapshot.json"
local CAMP = Color3.fromRGB(200, 40, 40)

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
		line ..= ` tr={num(inst.Transparency)} anch={tostring(inst.Anchored)} mass0={tostring(inst.Massless)}`
		line ..= ` coll={tostring(inst.CanCollide)} q={tostring(inst.CanQuery)} t={tostring(inst.CanTouch)} sh={tostring(inst.CastShadow)}`
		line ..= ` pivot={vec(inst.PivotOffset.Position)}`
		if inst:IsA("Part") then
			line ..= ` shape={inst.Shape.Name}`
		end
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

local function fingerprint(model: Model): string
	local out = { `primary={model.PrimaryPart and model.PrimaryPart.Name or "-"}` }
	describe(model, 0, out)
	return table.concat(out, "\n")
end

local SHOT_SCALES = { 0.1, 0.5, 1, 2 }

-- Every look the walker / projectile art touches, today.
local function allLooks(): { [string]: string }
	local looks = {}
	for kind in RaptorLook.KINDS do
		looks[`raptor:{kind}`] = fingerprint(RaptorLook.build(kind, CAMP))
	end
	for kind in RangerLook.KINDS do
		looks[`ranger:{kind}`] = fingerprint(RangerLook.build(kind, CAMP))
	end
	looks.jeep = fingerprint(RangerLook.buildJeep(CAMP))
	looks.paratrooper = fingerprint(TowerLook.buildRanger(CAMP))
	for key in DinoLook.PROJECTILE_STYLE do
		for _, s in SHOT_SCALES do
			looks[`shot:{key}:{s}`] = fingerprint(DinoLook.buildProjectile(key, 4, s))
		end
	end
	return looks
end

if process.env.WALKERART_WRITE == "1" then
	fs.writeFile(SNAPSHOT_PATH, serde.encode("json", allLooks(), true))
	print(`  wrote {SNAPSHOT_PATH}`)
	return
end

local ArtSlot = require(src.shared.ArtSlot)
local WalkerArt = require(src.shared.WalkerArt)

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
	ok(count >= 4 + 3 + 2 + 6 * #SHOT_SCALES, "snapshot has every look")
end

local ID = 5151
local BODY = Color3.fromRGB(11, 22, 33)
local AUTHORED_CAMP = Color3.fromRGB(13, 105, 172)

local function mesh(model: Model, name: string, size: Vector3, at: CFrame, attrs: { [string]: string }?): BasePart
	local p = Instance.new("MeshPart")
	p.Name = name
	p.Size = size
	p.CFrame = at
	p.Anchored = false
	p.CanCollide = true
	p.CanQuery = true
	p.CanTouch = true
	for k, v in attrs or {} do
		p:SetAttribute(k, v)
	end
	p.Parent = model
	return p
end

-- A fake walker template: a body, a camp piece, a head, and (shooters) a muzzle at (0.4, 0.15, -1.2).
local MUZZLE_AT = Vector3.new(0.4, 0.15, -1.2)
local function walkerTemplate(key: string, muzzle: boolean): Model
	local model = Instance.new("Model")
	model.Name = key
	model:SetAttribute("ArtId", ID)
	mesh(model, "body", Vector3.new(1, 1, 2), CFrame.new(0, 0, 0))
	mesh(model, "camp", Vector3.new(0.6, 0.2, 0.6), CFrame.new(0, 0.5, -0.9))
	mesh(model, "head", Vector3.new(0.5, 0.5, 0.8), CFrame.new(0, 0.6, -1.3), { PaintGroup = "body", ArtRole = "head" })
	if muzzle then
		mesh(model, "muzzle", Vector3.new(0.1, 0.1, 0.1), CFrame.new(MUZZLE_AT), { PaintGroup = "gun", ArtRole = "muzzle" })
	end
	return model
end

local SHOOTERS = { RANGER = true, RANGER_HEAVY = true, RANGER_LEGEND = true, PARATROOPER = true }
local WALKER_KEYS = { "RAPTOR", "RAPTOR_ALPHA", "RAPTOR_REX", "RAPTOR_SWARM", "RANGER", "RANGER_HEAVY", "RANGER_LEGEND", "PATROL_JEEP", "PARATROOPER", "PARATROOPER_CHUTE" }

-- A fake projectile template: a rock piece along Z (1 x 1 x 2 at s = 1) and a chip.
local function shotTemplate(key: string): Model
	local model = Instance.new("Model")
	model.Name = key
	model:SetAttribute("ArtId", ID)
	mesh(model, "rock", Vector3.new(1, 1, 2), CFrame.new(0, 0, 0))
	mesh(model, "chip", Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, 0, -1))
	return model
end

local function fakeArt(): (Instance, any)
	local art = Instance.new("Folder")
	art.Name = "Art"
	local ids = { walker = {}, projectile = {} }
	local walkers = Instance.new("Folder")
	walkers.Name = "walker"
	walkers.Parent = art
	for _, key in WALKER_KEYS do
		walkerTemplate(key, SHOOTERS[key] == true).Parent = walkers
		ids.walker[key] = { model = ID, colors = { body = BODY, camp = AUTHORED_CAMP } }
	end
	local shots = Instance.new("Folder")
	shots.Name = "projectile"
	shots.Parent = art
	for _, style in DinoLook.PROJECTILE_STYLE do
		local key = string.upper(style)
		shotTemplate(key).Parent = shots
		ids.projectile[key] = { model = ID }
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

test("blank ids (the real ArtIds), nothing loaded, or ArtOff: every walker and shot builds as before", function()
	ArtSlot.setIds(nil)
	ArtSlot.setSource(nil)
	sameAsSnapshot("real ids")
	local _, ids = fakeArt()
	withArt(Instance.new("Folder"), ids, function()
		sameAsSnapshot("not loaded")
	end)
	local off, offIds = fakeArt()
	off:SetAttribute("ArtOff", true)
	withArt(off, offIds, function()
		sameAsSnapshot("ArtOff")
	end)
	-- Blank ids: no muzzle, no chute, no lift.
	eq(WalkerArt.muzzle(RangerLook.build("ranger", CAMP)), nil, "blocky ranger: no art muzzle")
	eq(WalkerArt.muzzle(TowerLook.buildRanger(CAMP)), nil, "blocky paratrooper: no art muzzle")
	eq(WalkerArt.muzzle(nil), nil, "no model: no muzzle")
	eq(TowerLook.buildRanger(CAMP):GetAttribute("Chute"), nil, "no chute art: no chute, no drop")
end)

-- Every art piece anchored, massless, ghost, shadowless; no blocks left but the Body.
local function checkDressed(model: Model, blocky: Model, what: string)
	local body = model.PrimaryPart :: BasePart
	local before = blocky.PrimaryPart :: BasePart
	eq(body.Name, "Body", `{what} PrimaryPart`)
	eq(vec(body.Size), vec(before.Size), `{what} Body size`)
	eq(vec(body.CFrame.Position), vec(before.CFrame.Position), `{what} Body position`)
	eq(body.Transparency, 1, `{what} Body hidden`)
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") and child ~= body then
			ok(child:GetAttribute("ArtPiece") == true, `{what} {child.Name} is art (no blocks left)`)
			ok(child.Anchored and child.Massless, `{what} {child.Name} anchored + massless`)
			ok(not child.CanCollide and not child.CanQuery and not child.CanTouch and not child.CastShadow, `{what} {child.Name} ghost, no shadow`)
			local group = child:GetAttribute("PaintGroup")
			if group == "camp" then
				eq(child.Color, CAMP, `{what} camp piece in the camp colour, not the authored blue`)
			elseif group == "body" then
				eq(child.Color, BODY, `{what} body piece in its authored colour`)
			end
		end
	end
	ok(model:FindFirstChild("Head") ~= nil, `{what} head role named Head`)
end

test("walker art is visual only: Body kept and hidden, camp colour, lift (scale - 1) x 1.2", function()
	local art, ids = fakeArt()
	local cases = {}
	for kind, scale in RaptorLook.KINDS do
		table.insert(cases, { what = `raptor {kind}`, key = WalkerArt.RAPTOR_KEYS[kind], scale = scale, build = function()
			return RaptorLook.build(kind, CAMP)
		end })
	end
	for kind, scale in RangerLook.KINDS do
		table.insert(cases, { what = `ranger {kind}`, key = WalkerArt.RANGER_KEYS[kind], scale = scale, build = function()
			return RangerLook.build(kind, CAMP)
		end })
	end
	table.insert(cases, { what = "jeep", key = "PATROL_JEEP", scale = 1, build = function()
		return RangerLook.buildJeep(CAMP)
	end })
	table.insert(cases, { what = "paratrooper", key = "PARATROOPER", scale = 1, build = function()
		return TowerLook.buildRanger(CAMP)
	end })
	eq(#cases, 9, "4 raptors + 3 rangers + jeep + paratrooper")
	for _, case in cases do
		local blocky = case.build()
		local model
		withArt(art, ids, function()
			model = case.build()
		end)
		eq(model:GetAttribute("ArtKey"), case.key, `{case.what} dressed as {case.key}`)
		checkDressed(model, blocky, case.what)
		local body = model.PrimaryPart :: BasePart
		local lift = (case.scale - 1) * 1.2
		near(WalkerArt.lift(case.scale), lift, `{case.what} lift`, 1e-9)
		near(body.PivotOffset.Position.Y, -lift, `{case.what} pivot (scale - 1) x 1.2 below the Body`, 1e-4)
		eq((blocky.PrimaryPart :: BasePart).PivotOffset.Position.Y, 0, `{case.what} blocky: pivot = Body`)
		-- PivotTo(track + 1.2) puts the art's feet (1.2 x scale under the Body) on the track.
		local placedBody = (CFrame.new(0, 1.2, 0) * body.PivotOffset:Inverse()).Position.Y
		near(placedBody - 1.2 * case.scale, 0, `{case.what} feet on the track`, 1e-4)
		local muzzle = WalkerArt.muzzle(model)
		if SHOOTERS[case.key] then
			ok(muzzle ~= nil, `{case.what} has an art muzzle`)
			if muzzle then
				eq(vec(muzzle), vec(body.CFrame.Position + MUZZLE_AT), `{case.what} muzzle at the piece centre`)
			end
		else
			eq(muzzle, nil, `{case.what} no muzzle`)
		end
	end
end)

test("lift: big kinds rise, the Swarm drops, scale 1 stays", function()
	ok(WalkerArt.lift(RaptorLook.KINDS.rex) > 1, "rex rises over a stud")
	ok(WalkerArt.lift(RaptorLook.KINDS.swarm) < 0, "swarm lowered")
	eq(WalkerArt.lift(1), 0, "scale 1 unchanged")
end)

test("paratrooper chute: only with its art, comes off on landing; the drop is a visual curve", function()
	local art, ids = fakeArt()
	local model
	withArt(art, ids, function()
		model = TowerLook.buildRanger(CAMP)
	end)
	eq(model:GetAttribute("Chute"), true, "dropping with a canopy")
	eq(model:GetAttribute("ArtKey"), "PARATROOPER", "the trooper's art key, not the chute's")
	local chute = 0
	for _, child in model:GetChildren() do
		if child:GetAttribute("Chute") then
			chute += 1
			ok(child:GetAttribute("ArtPiece") == true and child.Anchored and not child.CanQuery, "canopy piece is ghost art")
			if child:GetAttribute("PaintGroup") == "camp" then
				eq(child.Color, CAMP, "canopy gores in the camp colour")
			end
		end
	end
	ok(chute > 0, "canopy pieces")
	WalkerArt.dropChute(model)
	eq(model:GetAttribute("Chute"), nil, "landed")
	for _, child in model:GetChildren() do
		ok(not child:GetAttribute("Chute"), "canopy gone")
	end
	ok(model:FindFirstChild("Head") ~= nil, "trooper art kept")
	-- Chute art without trooper art: the canopy hangs over today's blocky trooper.
	local onlyChute = table.clone(ids)
	onlyChute.walker = { PARATROOPER_CHUTE = ids.walker.PARATROOPER_CHUTE }
	local blocky
	withArt(art, onlyChute, function()
		blocky = TowerLook.buildRanger(CAMP)
	end)
	eq(blocky:GetAttribute("Chute"), true, "canopy over the blocky trooper")
	ok(blocky:FindFirstChild("Rifle") ~= nil, "blocks kept")
	near(WalkerArt.dropHeight(0), WalkerArt.DROP_HEIGHT, "starts high")
	near(WalkerArt.dropHeight(WalkerArt.DROP_SECONDS), 0, "lands")
	near(WalkerArt.dropHeight(99), 0, "stays landed")
	ok(WalkerArt.dropHeight(0.5) < WalkerArt.dropHeight(0.2), "steady descent")
	ok(WalkerArt.DROP_SECONDS <= 2, "short")
end)

test("jeep seats: hips on the seat tops, five seats then round again", function()
	for _, scale in { 1, 1.1, 1.35 } do
		local seat = WalkerArt.seat(1, scale)
		local body = seat.Position.Y + WalkerArt.lift(scale) -- PivotTo puts the Body here
		near(body - 0.55 * scale, WalkerArt.JEEP_LIFT + 0.65, `scale {scale}: hips on the seat`, 1e-6)
	end
	eq(vec(WalkerArt.seat(6, 1).Position), vec(WalkerArt.seat(1, 1).Position), "sixth = first")
	local seen = {}
	for i = 1, 5 do
		local key = vec(WalkerArt.seat(i, 1).Position)
		ok(not seen[key], `seat {i} its own`)
		seen[key] = true
	end
end)

test("projectile art: scaled to the live Shot; Shot, Style, Height unchanged; extras gone", function()
	local art, ids = fakeArt()
	for key, style in DinoLook.PROJECTILE_STYLE do
		for _, s in SHOT_SCALES do
			local what = `{key} x{s}`
			local blocky = DinoLook.buildProjectile(key, 4, s)
			local model
			withArt(art, ids, function()
				model = DinoLook.buildProjectile(key, 4, s)
			end)
			local shot = model.PrimaryPart :: BasePart
			local before = blocky.PrimaryPart :: BasePart
			eq(shot.Name, "Shot", `{what} PrimaryPart`)
			eq(vec(shot.Size), vec(before.Size), `{what} Shot size`)
			eq(vec(shot.CFrame.Position), vec(before.CFrame.Position), `{what} Shot position`)
			eq(vec(shot.PivotOffset.Position) .. vec(shot.PivotOffset.LookVector), vec(before.PivotOffset.Position) .. vec(before.PivotOffset.LookVector), `{what} pivot`)
			eq(shot.Transparency, 1, `{what} Shot hidden`)
			eq(model:GetAttribute("Style"), blocky:GetAttribute("Style"), `{what} Style`)
			eq(model:GetAttribute("Height"), blocky:GetAttribute("Height"), `{what} Height`)
			local k = shot.Size.Y / DinoLook.SHOT_ART_HEIGHT[style]
			local rock
			for _, child in model:GetChildren() do
				if child:IsA("BasePart") and child ~= shot then
					ok(child:GetAttribute("ArtPiece") == true, `{what} {child.Name} is art`)
					ok(child.Anchored and child.Massless and not child.CanCollide and not child.CanQuery and not child.CanTouch, `{what} {child.Name} ghost`)
					if child:GetAttribute("PaintGroup") == "rock" then
						rock = child
					end
				end
			end
			ok(rock ~= nil, `{what} dressed`)
			if rock then
				eq(vec(rock.Size), vec(Vector3.new(1, 1, 2) * k), `{what} art scaled to the Shot`)
				-- Authored along Z about the model's pivot (also the turned capsule).
				local rel = (shot.CFrame * shot.PivotOffset):ToObjectSpace(rock.CFrame) -- the model's pivot
				eq(vec(rel.Position), vec(Vector3.zero), `{what} art centred on the pivot`)
				eq(vec(rel.LookVector), vec(Vector3.new(0, 0, -1)), `{what} art faces the pivot's front`)
			end
		end
	end
end)
