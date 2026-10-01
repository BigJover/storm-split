--[[
	Dino ranged attacks (DECISIONS #3, #5, #25, Dino review round 4): the Config values,
	Combat.landingHits, and DinoLook's projectile shapes, paths and warning ring.
]]

local Config = require(src.shared.Config)
local Combat = require(src.shared.Combat)
local DinoLook = require(src.shared.DinoLook)

-- key -> name, damage, every, reach, speed, impact radius, style
local RANGED = {
	SHIELD = { "Skull Toss", 5, 5, 22, 40, 3, "lob" },
	ARMOR = { "Spike Flick", 6, 5, 20, 50, 3, "spike" },
	STORM = { "Gravel Spray", 8, 4, 25, 70, 3, "gravel" },
	LLAMA = { "Stone Drop", 8, 4, 18, 35, 4, "drop" },
	ZEP = { "Horn Toss", 20, 5, 30, 45, 5, "roll" },
	BARGE = { "Bone Spit", 35, 6, 35, 35, 8, "capsule" },
}

test("ranged attacks in Config, by species key", function()
	for key, want in RANGED do
		local e = Config.Enemies[key]
		local where = `{key} ({e.display})`
		eq(e.rangedName, want[1], `{where} name`)
		eq(e.rangedDamage, want[2], `{where} damage`)
		eq(e.rangedEvery, want[3], `{where} every`)
		eq(e.rangedReach, want[4], `{where} reach`)
		eq(e.projectileSpeed, want[5], `{where} speed`)
		eq(e.impactRadius, want[6], `{where} impact radius`)
		eq(DinoLook.PROJECTILE_STYLE[key], want[7], `{where} look`)
	end
	for _, key in { "HUSK", "BRUTE" } do
		eq(Config.Enemies[key].rangedDamage, 0, `{key} only bites`)
	end
	eq(Config.Tuning.MaxProjectiles, 80, "cap")
end)

local function target(x: number, z: number, standing: boolean, name: string): Combat.Target
	return { position = Vector3.new(x, 3, z), standing = standing, ref = name }
end

test("landingHits: everyone standing inside the radius, sideways, inclusive", function()
	local at = Vector3.new(10, 0.1, 10)
	local inside, edge, outside = target(12, 10, true, "inside"), target(10, 13, true, "edge"), target(14, 10, true, "outside")
	local trampled, dead = target(10, 10, false, "trampled tower"), target(11, 11, false, "dead hunter")
	local hits = Combat.landingHits(at, 3, { inside, edge, outside, trampled, dead })
	local names = {}
	for _, h in hits do
		names[h.ref] = true
	end
	ok(names.inside and names.edge, "inside and on the edge are hit")
	ok(not names.outside, "outside the radius is safe (dodged)")
	ok(not names["trampled tower"] and not names["dead hunter"], "trampled towers and the dead are skipped")
	eq(#hits, 2, "hit count")
	eq(#Combat.landingHits(at, 3, {}), 0, "nothing there")
end)

test("every ranged species builds its own projectile shape", function()
	for key, want in RANGED do
		local e = Config.Enemies[key]
		local model = DinoLook.buildProjectile(key, e.impactRadius, 1)
		local shot = model.PrimaryPart
		ok(shot ~= nil and shot.Name == "Shot", `{key} has a Shot`)
		eq(model:GetAttribute("Style"), want[7], `{key} style`)
		local parts = 0
		for _, part in model:GetChildren() do
			if part:IsA("BasePart") then
				parts += 1
				eq(part.Anchored, true, `{key} {part.Name} anchored`)
				eq(part.CanCollide, false, `{key} {part.Name} no collision`)
				eq(part.CanQuery, false, `{key} {part.Name} no query`)
				ok(part.Size.Magnitude <= 3 * math.sqrt(3) + 1e-3, `{key} {part.Name} at most 3 studs`)
			end
		end
		if want[7] == "gravel" then
			eq(parts, 3, "Gravel Spray is 3 pebbles")
		elseif want[7] == "capsule" then
			eq(parts, 3, "Bone Spit capsule: a cylinder and two caps")
		end
		local small = DinoLook.buildProjectile(key, e.impactRadius, 0.5)
		ok(small.PrimaryPart.Size.Magnitude < shot.Size.Magnitude, `{key} a shrunk dino throws smaller`)
	end
	local spike = DinoLook.buildProjectile("ARMOR", 3, 1).PrimaryPart
	ok(spike.Size.Z > spike.Size.X * 3, "Spike Flick is a long thin wedge")
	local boulder = DinoLook.buildProjectile("ZEP", 5, 1).PrimaryPart
	ok(boulder.Size.X >= 2.5 - 1e-3, "Horn Toss boulder is big")
end)

test("projectile paths: start at the thrower, end on the ring; lob arcs, drop falls, roll rolls", function()
	local from, to = Vector3.new(0, 4, 0), Vector3.new(20, 0.1, 0)
	for _, style in { "lob", "spike", "gravel", "capsule" } do
		local start = DinoLook.projectilePose(style, from, to, 0, 0, 1).Position
		local finish = DinoLook.projectilePose(style, from, to, 1, 1, 1).Position
		ok((start - from).Magnitude < 1e-3, `{style} starts at the thrower`)
		ok((finish - to).Magnitude < 1e-3, `{style} lands on the ring`)
	end
	local mid = DinoLook.projectilePose("lob", from, to, 0.5, 0.5, 1).Position
	ok(mid.Y > (from.Y + to.Y) / 2 + 3, "Skull Toss is a high lob")
	local flat = DinoLook.projectilePose("spike", from, to, 0.5, 0.5, 1)
	near(flat.Position.Y, (from.Y + to.Y) / 2, "Spike Flick flies flat", 1e-3)
	ok(flat.LookVector.X > 0.9, "Spike Flick points along its flight")
	local flier = Vector3.new(0, 9, 0)
	for _, f in { 0, 0.3, 0.7, 1 } do
		local p = DinoLook.projectilePose("drop", flier, to, f, f, 1).Position
		near(p.X, to.X, `Stone Drop straight down at {f} (x)`, 1e-3)
		near(p.Z, to.Z, `Stone Drop straight down at {f} (z)`, 1e-3)
	end
	near(DinoLook.projectilePose("drop", flier, to, 0, 0, 1).Position.Y, 9, "Stone Drop starts at the flier's height", 1e-3)
	for _, f in { 0, 0.25, 0.5, 0.75, 1 } do
		local p = DinoLook.projectilePose("roll", from, to, f, f, 2.5).Position
		ok(p.Y >= to.Y + 1.25 - 1e-3 and p.Y <= to.Y + 1.25 + 0.6 + 1e-3, `Horn Toss rolls along the ground at {f}`)
	end
end)

test("warning ring: impact-radius wide, orange, fades in toward impact", function()
	local ring = DinoLook.buildWarningRing(Vector3.new(5, 0.1, 5), 8)
	eq(ring.Size.Y, 16, "diameter = 2 x impact radius")
	eq(ring.Color, Color3.fromRGB(255, 150, 40), "one orange for every attack")
	eq(ring.Material, Enum.Material.Neon, "Neon")
	near(ring.Transparency, 0.75, "faint at launch", 1e-3)
	near(DinoLook.ringTransparency(1), 0.35, "solid just before impact", 1e-9)
	ok(DinoLook.ringTransparency(0.5) < DinoLook.ringTransparency(0.2), "grows more solid")
	eq(ring.CanCollide, false, "no collision")
end)

-- Round 40 load against the cap (report only; printed by tools/test.sh).
test("round 40 projectile estimate", function()
	local round = Config.Rounds[#Config.Rounds]
	local throwsPerSecond, flight = 0, 0
	local shooters = 0
	for key, count in round.counts do
		local e = Config.Enemies[key]
		if e.rangedDamage > 0 then
			shooters += count
			throwsPerSecond += count / e.rangedEvery
			-- a typical throw: half its reach, plus the flier's height for Stone Drop
			flight = math.max(flight, e.rangedReach / 2 / e.projectileSpeed)
		end
	end
	print(`       round 40 (Easy, 1 player): {shooters} ranged dinos spawned; if all were alive and in reach at once: {string.format("%.1f", throwsPerSecond)} throws/s x <= {string.format("%.2f", flight)}s flight = {string.format("%.1f", throwsPerSecond * flight)} in the air vs cap {Config.Tuning.MaxProjectiles}`)
	ok(true)
end)
