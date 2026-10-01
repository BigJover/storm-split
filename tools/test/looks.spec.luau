--[[
	TowerLook and DinoLook, built as real instances under Lune (visuals only, but the
	placement rule depends on towers staying inside their footprint). A tower's silhouette
	stays inside the 3x3x5 body box, the body is still the PrimaryPart that Shop.decorate,
	the range ring and the tier label use, the crown sits on top at stage 1 and the
	silhouette glows at stage 2. The sedation dart and "zzz" come and go.
]]

local Config = require(src.shared.Config)
local Track = require(src.shared.Track)
local TowerLook = require(src.shared.TowerLook)
local DinoLook = require(src.shared.DinoLook)

local BASE = Vector3.new(40, 2, -30)
local EPS = 1e-3 -- instance properties are 32-bit floats

-- The world-space bounding box corners of a part (as a block).
local function corners(part): { Vector3 }
	local out = {}
	local half = part.Size / 2
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			for _, sz in { -1, 1 } do
				table.insert(out, (part.CFrame * CFrame.new(half.X * sx, half.Y * sy, half.Z * sz)).Position)
			end
		end
	end
	return out
end

test("the body's half-diagonal fits Track.TowerRadius", function()
	ok(math.sqrt(2) * 1.5 <= Track.TowerRadius, "TowerRadius")
end)

test("every tower's silhouette stays inside the 3x3x5 body box", function()
	for _, key in Config.TowerOrder do
		local model = TowerLook.build(key, Config.Towers[key].range, BASE)
		local body = model.PrimaryPart
		eq(body and body.Name, "Body", `{key} PrimaryPart`)
		eq(body.Size, Vector3.new(3, TowerLook.BODY_HEIGHT, 3), `{key} body size`)
		eq(body.Anchored, true, `{key} body anchored`)
		local looks = 0
		for _, part in model:GetChildren() do
			if part:IsA("BasePart") and part:GetAttribute("LookMaterial") then
				looks += 1
				eq(part.Anchored, true, `{key} {part.Name} anchored`)
				eq(part.CanCollide, false, `{key} {part.Name} CanCollide`)
				eq(part.CanQuery, false, `{key} {part.Name} CanQuery`)
				ok(part.Material ~= Enum.Material.SmoothPlastic, `{key} {part.Name} real material`)
				for _, c in corners(part) do
					local d = c - BASE
					ok(math.abs(d.X) <= 1.5 + EPS and math.abs(d.Z) <= 1.5 + EPS, `{key} {part.Name} outside the 3x3 footprint`)
					ok(d.Y >= -EPS and d.Y <= TowerLook.BODY_HEIGHT + EPS, `{key} {part.Name} outside 0..5 high`)
				end
			end
		end
		ok(looks >= 3, `{key} has a silhouette`)
		eq(body.Transparency, 1, `{key} body hidden behind its silhouette`)
		local ring = model:FindFirstChild("Range")
		if Config.Towers[key].range <= 200 then -- TowerLook draws no ring for the Perch's "global" 999
			ok(ring ~= nil, `{key} range ring`)
			eq(ring.Color, body.Color, `{key} ring colour`)
		end
	end
end)

test("crown on top at stage 1, glow at stage 2, tier label on the body", function()
	for _, key in Config.TowerOrder do
		local model = TowerLook.build(key, Config.Towers[key].range, BASE)
		local body = model.PrimaryPart
		TowerLook.refresh(model, 20, { 3, 1, 0 }, 1)
		local crown = model:FindFirstChild("Crown")
		ok(crown ~= nil, `{key} crown at stage 1`)
		local top = model:GetAttribute("LookTop")
		near(crown.CFrame.Position.Y - crown.Size.Y / 2, BASE.Y + top, `{key} crown sits on the silhouette`, 1e-3)
		ok(crown.Size.X <= 3 and crown.Size.Z <= 3, `{key} crown inside the footprint`)
		ok(body:FindFirstChild("Tiers") ~= nil, `{key} tier label on the body`)
		for _, part in model:GetChildren() do
			if part:GetAttribute("LookMaterial") then
				eq(part.Material.Name, part:GetAttribute("LookMaterial"), `{key} {part.Name} not glowing yet`)
			end
		end
		TowerLook.refresh(model, 20, { 5, 2, 0 }, 2)
		for _, part in model:GetChildren() do
			if part:GetAttribute("LookMaterial") then
				eq(part.Material, Enum.Material.Neon, `{key} {part.Name} glows at stage 2`)
			end
		end
		ok(model:FindFirstChild("Crown") ~= nil, `{key} crown kept at stage 2`)
		TowerLook.refresh(model, 20, { 0, 0, 0 }, 0)
		ok(model:FindFirstChild("Crown") == nil, `{key} crown gone at stage 0`)
		for _, part in model:GetChildren() do
			local material = part:GetAttribute("LookMaterial")
			if material then
				eq(part.Material.Name, material, `{key} {part.Name} material restored`)
			end
		end
	end
end)

test("sedated dart and zzz come and go on every species", function()
	for _, key in Config.EnemyOrder do
		local model = DinoLook.build(key, 0.75, CFrame.new(0, 5, 0))
		DinoLook.setSedated(model, true)
		DinoLook.setSedated(model, true)
		local darts = 0
		for _, part in model:GetChildren() do
			if part.Name == "SedationDart" then
				darts += 1
			end
		end
		eq(darts, 1, `{key} one dart`)
		DinoLook.setAsleep(model, true)
		ok(model.PrimaryPart:FindFirstChild("Asleep") ~= nil, `{key} zzz`)
		DinoLook.setSedated(model, false)
		DinoLook.setAsleep(model, false)
		ok(model:FindFirstChild("SedationDart") == nil, `{key} dart removed`)
		ok(model.PrimaryPart:FindFirstChild("Asleep") == nil, `{key} zzz removed`)
	end
end)

test("DinoLook fixes: Gallimimus head on its neck, Raptor stripe and crest, T-Rex teeth, Pteranodon crest back", function()
	local galli = DinoLook.build("STORM", 1, CFrame.new())
	local head, neck = galli:FindFirstChild("Head"), galli:FindFirstChild("Neck")
	local neckTop = neck.CFrame.Position.Y + neck.Size.Y / 2
	ok(head.CFrame.Position.Y - head.Size.Y / 2 >= neckTop - 0.5, "Gallimimus head sits on top of the neck")
	local raptor = DinoLook.build("BRUTE", 1, CFrame.new())
	ok(raptor:FindFirstChild("Stripe") ~= nil and raptor:FindFirstChild("Crest") ~= nil, "Raptor stripe and crest")
	local rex = DinoLook.build("BARGE", 1, CFrame.new())
	local teeth = 0
	for _, part in rex:GetChildren() do
		if part.Name:sub(1, 5) == "Tooth" then
			teeth += 1
		end
	end
	ok(teeth >= 4, "T-Rex teeth")
	local ptera = DinoLook.build("LLAMA", 1, CFrame.new())
	local pHead, crest = ptera:FindFirstChild("Head"), ptera:FindFirstChild("Crest")
	-- dinos face -Z: "backward" is +Z, so the crest's centre is behind the head's
	ok(crest.CFrame.Position.Z > pHead.CFrame.Position.Z, "Pteranodon crest points back")
	ok(crest.CFrame.Position.Z + crest.Size.Z / 2 > pHead.CFrame.Position.Z + pHead.Size.Z / 2, "crest sticks out behind the head")
end)

test("trampled look: tilt, Slate, dust, debris, no ring, TRAMPLED label; all undone on repair", function()
	for _, key in Config.TowerOrder do
		local model = TowerLook.build(key, 15, BASE)
		TowerLook.refresh(model, 15, { 5, 2, 0 }, 2)
		local body = model.PrimaryPart
		local before = {}
		for _, part in model:GetChildren() do
			if part:GetAttribute("LookMaterial") then
				before[part] = { cframe = part.CFrame, color = part.Color }
			end
		end
		TowerLook.setKnockedOut(model, true)
		local label = body:FindFirstChild("Trampled")
		ok(label ~= nil, `{key} label`)
		eq(label:FindFirstChildOfClass("TextLabel").Text, "TRAMPLED", `{key} label text`)
		ok(body:FindFirstChild("TrampledDust") ~= nil, `{key} dust`)
		ok(model:FindFirstChild("Debris1") ~= nil and model:FindFirstChild("Debris3") ~= nil, `{key} debris`)
		eq(model:FindFirstChild("Range").Transparency, 1, `{key} ring hidden`)
		for part in before do
			eq(part.Material, Enum.Material.Slate, `{key} {part.Name} Slate`)
			local tipped = part.CFrame.UpVector:Dot(Vector3.yAxis)
			ok(tipped < 0.99, `{key} {part.Name} tipped over`)
		end
		eq(body.CFrame.Position, BASE + Vector3.new(0, TowerLook.BODY_HEIGHT / 2, 0), `{key} body doesn't move`)
		TowerLook.setKnockedOut(model, false)
		ok(body:FindFirstChild("Trampled") == nil and body:FindFirstChild("TrampledDust") == nil, `{key} label and dust gone`)
		ok(model:FindFirstChild("Debris1") == nil, `{key} debris gone`)
		near(model:FindFirstChild("Range").Transparency, 0.85, `{key} ring back`, 1e-3)
		for part, was in before do
			ok((part.CFrame.Position - was.cframe.Position).Magnitude < 1e-3, `{key} {part.Name} upright again`)
			eq(part.Color, was.color, `{key} {part.Name} colour back`)
			eq(part.Material, Enum.Material.Neon, `{key} {part.Name} stage-2 glow back`)
		end
	end
end)

test("health bar: hidden at full, shown when damaged", function()
	local model = TowerLook.build("SCOUT", 20, BASE)
	local body = model.PrimaryPart
	TowerLook.setHealth(model, 1)
	ok(body:FindFirstChild("HealthBar") == nil, "hidden at full")
	TowerLook.setHealth(model, 0.4)
	local bar = body:FindFirstChild("HealthBar")
	ok(bar ~= nil, "shown when damaged")
	near(bar.Back.Fill.Size.X.Scale, 0.4, "fill", 1e-3)
	TowerLook.setHealth(model, 1)
	ok(body:FindFirstChild("HealthBar") == nil, "hidden again at full")
end)

test("T10c: slits and rails on all four sides, barrel angled up, dart fletching", function()
	local blind = TowerLook.build("SCOUT", 20, BASE)
	for _, name in { "SlitFront", "SlitBack", "SlitLeft", "SlitRight" } do
		ok(blind:FindFirstChild(name) ~= nil, `Hunting Blind {name}`)
	end
	local perch = TowerLook.build("SNIPER", 999, BASE)
	for _, name in { "RailFront", "RailBack", "RailLeft", "RailRight" } do
		ok(perch:FindFirstChild(name) ~= nil, `Longshot Perch {name}`)
	end
	local barrel = perch:FindFirstChild("Barrel")
	near(math.deg(math.asin(math.abs(barrel.CFrame.LookVector.Y))), 30, "barrel angle", 0.5)
	-- the end that points forward (toward -Z of the tower) is the raised one
	local frontEnd = if barrel.CFrame.LookVector.Z < 0 then barrel.CFrame.LookVector else -barrel.CFrame.LookVector
	ok(frontEnd.Y > 0, "barrel's front end points up")
	ok(barrel.Size.Z < 1.3, "barrel shorter than before")
	local tranq = TowerLook.build("CHILLER", 12, BASE)
	for i = 1, 3 do
		local dart, fletching = tranq:FindFirstChild(`Dart{i}`), tranq:FindFirstChild(`Fletching{i}`)
		ok(fletching ~= nil, `dart {i} fletching`)
		ok(fletching.CFrame.Position.Y < dart.CFrame.Position.Y, `dart {i} fletching at the bottom`)
	end
end)

test("T10c: sedation dart sticks up out of the back; zzz MaxDistance 80", function()
	for _, key in Config.EnemyOrder do
		local model = DinoLook.build(key, 1, CFrame.new(0, 5, 0))
		local root = model.PrimaryPart
		DinoLook.setSedated(model, true)
		local dart = model:FindFirstChild("SedationDart")
		local top = root.CFrame.Position.Y + root.Size.Y / 2
		-- its highest end pokes out above the body: visible from the top
		local reach = math.abs(dart.CFrame.LookVector.Y) * dart.Size.Z / 2
		ok(dart.CFrame.Position.Y + reach > top + 0.1, `{key} dart visible from above`)
		near(dart.CFrame.Position.X, root.CFrame.Position.X, `{key} dart on the spine`, 1e-3)
		ok(dart.CFrame.Position.Z > root.CFrame.Position.Z, `{key} dart toward the tail`)
		DinoLook.setAsleep(model, true)
		eq(root:FindFirstChild("Asleep").MaxDistance, 80, `{key} zzz MaxDistance`)
	end
end)

test("T12b: dust cloud, tip direction varies by spot, one low-HP orange, hit flash", function()
	local model = TowerLook.build("SCOUT", 20, BASE)
	TowerLook.setKnockedOut(model, true)
	local dust = model.PrimaryPart:FindFirstChild("TrampledDust")
	eq(dust.Color, Color3.fromRGB(150, 125, 90), "dust colour")
	near(dust.Opacity, 0.2, "dust opacity", 1e-3)
	near(dust.RiseVelocity, 1.5, "dust rises slowly", 1e-3)
	-- two spots tip different ways
	local axisA, axisB = TowerLook.tipAxis(Vector3.new(0, 0, 0)), TowerLook.tipAxis(Vector3.new(1, 0, 0))
	ok((axisA - axisB).Magnitude > 0.1, "two positions tip along different axes")
	near(axisA.Y, 0, "horizontal axis", 1e-9)
	local function hideAt(spot)
		local m = TowerLook.build("SCOUT", 20, spot)
		TowerLook.setKnockedOut(m, true)
		local hide = m:FindFirstChild("Hide")
		return hide.CFrame.UpVector
	end
	local upA, upB = hideAt(Vector3.new(0, 0, 0)), hideAt(Vector3.new(1, 0, 0))
	near(math.deg(math.acos(math.clamp(upA:Dot(Vector3.yAxis), -1, 1))), 15, "still 15 degrees", 0.1)
	ok((upA - upB).Magnitude > 0.05, "and they lean different ways")
	-- one low-HP orange on the tower bar (Hud uses the same constant)
	eq(TowerLook.LOW_HP_COLOR, Color3.fromRGB(230, 170, 60), "low-HP orange")
	local hurt = TowerLook.build("SCOUT", 20, BASE)
	TowerLook.setHealth(hurt, 0.2)
	eq(hurt.PrimaryPart.HealthBar.Back.Fill.BackgroundColor3, TowerLook.LOW_HP_COLOR, "tower bar uses it when low")
	-- hit flash: red, then the real colours back; a trampled tower doesn't flash
	local hide = hurt:FindFirstChild("Hide")
	local before = hide.Color
	TowerLook.flashHit(hurt)
	eq(hide.Color, Color3.fromRGB(255, 60, 60), "flashes red")
	TowerLook.endHitFlash(hurt)
	eq(hide.Color, before, "colour restored")
	TowerLook.flashHit(hurt)
	TowerLook.setKnockedOut(hurt, true)
	TowerLook.setKnockedOut(hurt, false)
	eq(hide.Color, before, "trampled mid-flash still repairs to the real colour")
	local down = TowerLook.build("SCOUT", 20, BASE)
	TowerLook.setKnockedOut(down, true)
	local slate = down:FindFirstChild("Hide").Color
	TowerLook.flashHit(down)
	eq(down:FindFirstChild("Hide").Color, slate, "no flash on a trampled tower")
end)

test("Jaw Lock muzzle: one dark strap on the snout of every species, removed after", function()
	for _, key in Config.EnemyOrder do
		local model = DinoLook.build(key, 0.75, CFrame.new(0, 5, 0))
		local snout = model:FindFirstChild("Jaw") or model:FindFirstChild("Head")
		ok(snout ~= nil, `{key} has a Jaw or Head for the strap`)
		DinoLook.setMuzzled(model, true)
		DinoLook.setMuzzled(model, true)
		local straps = 0
		for _, part in model:GetChildren() do
			if part.Name == "Muzzle" then
				straps += 1
			end
		end
		eq(straps, 1, `{key} one strap`)
		local strap = model:FindFirstChild("Muzzle") :: BasePart
		ok((strap.CFrame.Position - (snout :: BasePart).CFrame.Position).Magnitude < (snout :: BasePart).Size.Magnitude, `{key} strap sits on the snout`)
		ok(strap.Color.R < 0.3 and strap.Color.G < 0.3 and strap.Color.B < 0.3, `{key} strap is dark`)
		DinoLook.setMuzzled(model, false)
		ok(model:FindFirstChild("Muzzle") == nil, `{key} strap removed`)
	end
end)
