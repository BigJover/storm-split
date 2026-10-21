--[[
	Grenade (PLAN 10b T137, DECISIONS #366-#370, names DINO_REVIEW Round 20): Shared/Grenade's
	range, landing, arc, splash and charges over the `Hunter Kit` sheet. The kit guard
	(gun + melee + grenade < the best tower, #369) is the exporter's (validate_kit_guard,
	doctested) and value.py's hero lines.
]]
local Config = require(src.shared.Config)
local HunterKit = require(src.shared.HunterKit)
local Grenade = require(src.shared.Grenade)

local NAMES = { -- Round 20
	PISTOL = "Stink Bomb",
	RIFLE = "Safari Grenade",
	SHOTGUN = "Cherry Bomb",
	MEDIC = "Dozy Cloud",
}
local FROM = Vector3.new(0, 3, 0)
local NORTH = Vector3.new(0, 0, -1)

test("every hunter has a grenade with its Round 20 name; seeds 1 charge, 20 s recharge (#369)", function()
	for key in Config.Heroes do
		local row = HunterKit.row(key)
		eq(row.grenadeName, NAMES[key], `{key} grenade name`)
		eq(row.charges, 1, `{key} charges`)
		eq(row.recharge, 20, `{key} recharge`)
		ok(row.baseRange > 0 and row.splash > 0 and row.grenadeDamage > 0, `{key} numbers`)
	end
	local stink, safari, cherry, dozy = HunterKit.row("PISTOL"), HunterKit.row("RIFLE"), HunterKit.row("SHOTGUN"), HunterKit.row("MEDIC")
	for _, other in { stink, cherry, dozy } do
		ok(safari.splash > other.splash and safari.grenadeDamage > other.grenadeDamage, "the Safari Grenade is the biggest blast")
	end
	eq(stink.grenadeEffect, "amp", "Stink Bomb: dinos inside take more damage")
	ok(stink.cloudSeconds > 0, "...a cloud")
	eq(cherry.grenadeEffect, "slow", "Cherry Bomb: dinos stumble (a short slow)")
	eq(cherry.cloudSeconds, 0)
	eq(dozy.grenadeEffect, "slow", "Dozy Cloud: dinos slow")
	ok(dozy.cloudSeconds > 0, "...a cloud")
	eq(dozy.grenadeHunterEffect, "slow")
	ok(dozy.grenadeHunterPercent <= 30 and dozy.grenadeHunterSeconds <= 2, "Dozy Cloud on hunters: <= 30 %, <= 2 s")
	for key in Config.Heroes do
		local row = HunterKit.row(key)
		ok(row.grenadeHunterEffect == "none" or row.grenadeHunterEffect == "slow", `{key}: no stun or knockback on hunters`)
	end
end)

test("range: Base range + trained Throw % capped at Trained throw max (30 %, #370)", function()
	eq(Config.Tuning.TrainedThrowMax, 30)
	local base = HunterKit.row("RIFLE").baseRange
	eq(Grenade.range("RIFLE"), base)
	near(Grenade.range("RIFLE", 15), base * 1.15)
	near(Grenade.range("RIFLE", 30), base * 1.3)
	near(Grenade.range("RIFLE", 99), base * 1.3, "never past the cap")
	eq(Grenade.range("RIFLE", "x" :: any), base, "an unset stat reads 0 (10c fills it)")
	eq(Grenade.range(nil), 0)
	eq(HunterKit.THROW_ATTRIBUTE, "TrainedThrow")
end)

test("landing: where the camera ray hit, never past the range along the ground", function()
	local near_ = FROM + NORTH * 10 + Vector3.new(0, -3, 0)
	eq(Grenade.landing(FROM, near_, NORTH, 40), near_, "in range: right there")
	local far = Grenade.landing(FROM, FROM + NORTH * 100, NORTH, 40)
	near((far - FROM).Magnitude, 40, "clamped to the range", 1e-3)
	near(far.Z, -40, "north", 1e-3)
	local sky = Grenade.landing(FROM, nil, (NORTH + Vector3.new(0, 1, 0)).Unit, 40)
	near(sky.Z, -40, "aiming at the sky: full range straight ahead", 1e-3)
	eq(sky.Y, FROM.Y)
	eq(Grenade.landing(FROM, nil, Vector3.new(0, 1, 0), 40), FROM, "straight up: at your feet")
	local trained = Grenade.landing(FROM, FROM + NORTH * 100, NORTH, Grenade.range("RIFLE", 30))
	ok((trained - FROM).Magnitude > (far - FROM).Magnitude, "trained Throw lands further")
end)

test("the arc: starts and ends on the points, peaks halfway; flight = distance / throw speed", function()
	local to = FROM + NORTH * 40
	eq(Grenade.arcPoint(FROM, to, 0), FROM)
	eq(Grenade.arcPoint(FROM, to, 1), to)
	local top = Grenade.arcPoint(FROM, to, 0.5)
	near(top.Y - FROM.Y, 10, "a quarter of the ground distance up", 1e-3)
	ok(Grenade.arcPoint(FROM, to, 0.25).Y < top.Y)
	near(Grenade.flightTime(FROM, to), 40 / Config.Tuning.GrenadeThrowSpeed, "flight", 1e-4)
	eq(Grenade.flightTime(FROM, FROM), Grenade.MIN_FLIGHT)
end)

test("splash: inside the radius only", function()
	ok(Grenade.inSplash(FROM, 10, FROM + NORTH * 9.9))
	ok(not Grenade.inSplash(FROM, 10, FROM + NORTH * 10.1))
	ok(Grenade.inSplash(FROM, 10, FROM + Vector3.new(6, 0, 8)), "straight-line distance")
end)

test("charges: 1, back after Recharge; the HUD counts down to it", function()
	local row = HunterKit.row("PISTOL")
	eq(Grenade.charges(0, 100, row), 1, "full at the start")
	local full = Grenade.use(0, 100, row)
	eq(full, 120)
	eq(Grenade.charges(full, 100, row), 0, "spent")
	eq(Grenade.charges(full, 119.9, row), 0)
	eq(Grenade.charges(full, 120, row), 1, "back after 20 s")
	eq(Grenade.readyAt(full, 105, row), 120)
	local two = table.clone(row)
	two.charges = 2
	local f2 = Grenade.use(Grenade.use(0, 100, two), 100, two)
	eq(Grenade.charges(f2, 100, two), 0)
	eq(Grenade.charges(f2, 120, two), 1, "charges come back one Recharge apart")
end)

test("an enemy hunter is slowed once per grenade (blast and cloud together)", function()
	local seen = {}
	ok(Grenade.firstTouch(seen, "rival"))
	ok(not Grenade.firstTouch(seen, "rival"), "not again in the cloud")
	ok(Grenade.firstTouch(seen, "other"))
end)
