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
				ok(part.Material ~= Enum.Material.Neon or part.Name:sub(1, 3) == "Tip", `{key} {part.Name} not glowing yet`)
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
