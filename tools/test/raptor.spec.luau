--[[
	Raptor Pen (PLAN 9g T124, DECISIONS #312-#320): the Towers row and Tuning block, every
	PLAN cell, the composed builds (walkers, HP, Hold, Alpha, Hits air), Shared/Raptor's
	rules (Swarm within the cap, Charge, Guard posts, the Rex roar, Hungry Alpha's stack,
	Raider Hounds' Avenger, Pack Bond only with 3+ out and only vs dinos, the Dive aura), the
	look, the server wiring, and the perf bound: 10 players x a Raptor Swarm each stays under
	the walker cap.
]]

local fs = require("@lune/fs")
local Config = require(src.shared.Config)
local Raptor = require(src.shared.Raptor)
local RaptorLook = require(src.shared.RaptorLook)
local TowerStats = require(src.shared.TowerStats)
local ShopRules = require(src.shared.ShopRules)
local Walker = require(src.shared.Walker)

local PEN = Config.Towers.RAPTOR
local T = Config.Tuning

local function pathOf(id: string): (any, number)
	for i, path in PEN.paths do
		if path.id == id then
			return path, i
		end
	end
	error(`no path {id}`)
end

local function stats(id: string, tier: number, picks: string?)
	local _, i = pathOf(id)
	local tiers, all = { 0, 0, 0 }, { "", "", "" }
	tiers[i], all[i] = tier, picks or ""
	return TowerStats.compute(PEN, tiers, all)
end

local function close(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

test("the Towers row (PLAN T124c, #326: cost at the 600 floor, Damage 10, the walker exit raises bite rate 1.5 -> 2.3): 500 Amber, 10 a bite x 2.3/s, 22 studs, ground, 150 HP, 1 raptor, unreleased", function()
	eq(PEN.display, "Raptor Pen")
	eq(PEN.baseCost, 600)
	eq(PEN.unlockCost, 500, "Amber never moves (#313)")
	eq(PEN.baseDamage, 10)
	eq(PEN.baseRate, 2.3)
	eq(PEN.baseTargets, 1)
	eq(PEN.range, 22)
	eq(PEN.hitsAir, false)
	eq(PEN.maxHp, 150)
	eq(PEN.walkers, 1)
	ok(not PEN.untouchable and not PEN.resin and PEN.birds == 0, "no other kind flag")
	eq(ShopRules.Unreleased.RAPTOR, nil, "released at T124d (#312, #329-#330)")
end)

test("the RAPTOR PEN Tuning block (seeds)", function()
	local want = {
		RaptorHP = 60, RaptorSpeed = 30, RaptorReach = 4, PounceHoldS = 0.5, RetreatHPShare = 0.3, RaptorRespawnS = 8,
		PenHealHPS = 15, LeashX = 1.5, TrampleSize = 3, TrampleShare = 0.25, DodgeEveryS = 3, SwarmRaptors = 10,
		SwarmShare = 0.4, SwarmS = 15, ChargeKnockbackStuds = 6, GuardReachStuds = 10, RoarReachStuds = 10, HungryAlphaCap = 50,
	}
	for key, value in want do
		eq(T[key], value, key)
	end
end)

-- PLAN 9g's table: path, tier, letter, name, cells (T1-3 cumulative; T4 own step over T3).
local ROWS = {
	{ "Pack", 1, "", "Second Raptor", { walkers = 2 } },
	{ "Pack", 2, "", "Quick Whistle", { walkers = 2, damageMult = 1.4, walkerSpeedMult = 1.3, walkerRespawnMult = 0.7 } },
	{ "Pack", 3, "", "Pack of Five", { walkers = 5, damageMult = 1.4, walkerSpeedMult = 1.3, walkerRespawnMult = 0.7 } },
	{ "Pack", 4, "A", "Hide Rippers", { damageMult = 1.75, piercesArmor = true } },
	{ "Pack", 4, "B", "Flanking", { damageMult = 1.85, flanking = true } },
	{ "Pack", 4, "C", "Ambush", { damageMult = 1.75, firstDiveX = 2 } },
	{ "Alpha", 1, "", "Sharp Claws", { damageMult = 1.9 } },
	{ "Alpha", 2, "", "Thick Hide", { damageMult = 3.6, walkerHpMult = 1.6, walkerResistPercent = 25 } },
	{ "Alpha", 3, "", "Alpha Raptor", { damageMult = 7, walkerHpMult = 3, walkerResistPercent = 25, sizeBreaks = 2, holdSeconds = 1, alpha = true } },
	{ "Alpha", 4, "A", "Sickle Claw", { damageMult = 1.8, sizeBreaks = 3 } },
	{ "Alpha", 4, "B", "Boss Hunter", { damageMult = 1.6, bossMult = 1.6, bossHoldSeconds = 0.5 } },
	{ "Alpha", 4, "C", "Scent Trail", { damageMult = 1.7, markPercent = 15 } },
	{ "Trainer", 1, "", "Tracking Nose", { damageMult = 1.3, rangeMult = 1.15, targetsFirst = true } },
	{ "Trainer", 2, "", "Herding Call", { damageMult = 1.6, rangeMult = 1.15, targetsFirst = true, slowPercent = 20, slowLinger = 1 } },
	{ "Trainer", 3, "", "Pack Howl", { walkers = 2, damageMult = 2.2, rangeMult = 1.15, targetsFirst = true, slowPercent = 20, slowLinger = 1, diveAuraRatePercent = 15 } },
	{ "Trainer", 4, "A", "Treat Bag", { damageMult = 1.4, healsBetweenRounds = true, walkerRespawnMult = 0.5 } },
	{ "Trainer", 4, "B", "Guard Raptors", { damageMult = 1.3, guard = true } },
	{ "Trainer", 4, "C", "Whistle Drill", { damageMult = 1.3, walkerSpeedMult = 1.3, diveAuraRatePercent = 20 } },
}
-- Tier-5 own steps, checked on the composed build after T4 A (x columns over A4's).
local T5 = {
	{ "Pack", "A", "Raptor Swarm", { damageMult = 1.7 }, { swarm = true } },
	{ "Pack", "B", "Clever Girls", { damageMult = 1.75 }, { dodge = true } },
	{ "Pack", "C", "Sky Leap", { damageMult = 1.95 }, { hitsAir = true } },
	{ "Alpha", "A", "King of the Pack", { damageMult = 1.9, walkerHpMult = 1.5 }, { sizeBreaks = 4, walkerResistPercent = 50 } },
	{ "Alpha", "B", "Rex Tamer", { damageMult = 2, walkerHpMult = 1.4 }, { stunRoarEvery = 15, stunSeconds = 1 } },
	{ "Alpha", "C", "Hungry Alpha", { damageMult = 1.75 }, { takeDownStackPercent = 10 } },
	{ "Trainer", "A", "Raptor Charge", { damageMult = 1.5 }, { charge = true } },
	{ "Trainer", "B", "Pack Bond", { damageMult = 1.1 }, { walkers = 3, hunterDamagePercent = 20 } },
	{ "Trainer", "C", "Raider Hounds", { damageMult = 1.5 }, { avengerX = 2, sizeBreaks = 2, raiderDamage = 10, raiderSlowPercent = 20, raiderSlowSeconds = 1 } },
}

test("every PLAN row: name, letter, cells; T5 own steps compose after any T4; Raider Hounds the one Raider option", function()
	for _, r in ROWS do
		local id, tier, letter, name, cells = r[1], r[2], r[3], r[4], r[5]
		local path = pathOf(id)
		local row = if tier <= 3 then path.tiers[tier] else path.t4[letter]
		ok(row ~= nil, `{id} T{tier}{letter}`)
		eq(row.name, name, `{id} T{tier}{letter} name`)
		local base = if tier == 4 then path.tiers[3] else nil
		for field, value in cells do
			local want: any = value
			if base and string.find(field, "Mult$") and field ~= "firstDiveX" then
				want = (base[field] or 1) * value
			elseif base and type(value) == "number" then
				want = math.max(value, base[field] or 0)
			end
			if type(want) == "number" then
				ok(close(row[field] or 0, want), `{id} T{tier}{letter} {field} = {want} (got {row[field]})`)
			else
				eq(row[field], want, `{id} T{tier}{letter} {field}`)
			end
		end
	end
	for _, r in T5 do
		local id, letter, name, mults, cells = r[1], r[2], r[3], r[4], r[5]
		local path = pathOf(id)
		local row = path.t5["A" .. letter]
		eq(row.name, name, `{id} T5{letter}`)
		for field, value in mults do
			ok(close(row[field], path.t4.A[field] * value), `{id} T5{letter} {field} x{value}`)
		end
		for field, value in cells do
			if type(value) == "number" then
				ok(close(row[field], math.max(value, path.t4.A[field] or 0)), `{id} T5{letter} {field}`)
			else
				eq(row[field], value, `{id} T5{letter} {field}`)
			end
		end
	end
	local raiders = 0
	for _, path in PEN.paths do
		for _, row in path.t5 do
			if row.pvpEffect then
				raiders += 1
			end
		end
	end
	eq(raiders, 3, "Raider Hounds after each T4 (#320)")
end)

test("composed builds: walkers, hold, Alpha, Hits air, timers", function()
	local base = TowerStats.compute(PEN, { 0, 0, 0 })
	eq(base.walkers, 1, "1 raptor at tier 0")
	eq(base.holdSeconds, 0.5, "Pounce hold (s) when the build sets none")
	eq(stats("Pack", 3).walkers, 5)
	eq(stats("Alpha", 3).walkers, 1, "the alpha: one big raptor")
	ok(stats("Alpha", 3).alpha, "Alpha flag")
	eq(stats("Alpha", 3).holdSeconds, 1)
	eq(stats("Trainer", 5, "AB").walkers, 3, "Pack Bond: 3 raptors")
	ok(stats("Pack", 5, "AC").hitsAir and not base.hitsAir, "Sky Leap hits flyers")
	eq(stats("Alpha", 5, "AB").stunRoarEvery, 15)
	ok(close(stats("Pack", 3).walkerRespawnMult, 0.7) and close(stats("Pack", 3).walkerSpeedMult, 1.3), "Quick Whistle")
	eq(TowerStats.compute(Config.Towers.SCOUT, { 0, 0, 0 }).walkers, 0, "no walkers on other towers")
	eq(TowerStats.compute(Config.Towers.SCOUT, { 0, 0, 0 }).hitsAir, true, "a tower that hits air still does")
end)

test("a raptor's walker params: HP per tier like towers, speed, respawn, swarm share", function()
	local s = stats("Alpha", 3)
	local p = Raptor.params(s, 3)
	ok(close(p.maxHp, 60 * 3 * (1 + T.TowerHPPerTier * 3)), "Raptor HP x Walker HP x x (1 + Tower HP per tier x 3)")
	eq(p.resist, 25)
	eq(p.hold, 1)
	eq(p.speed, 30)
	local q = Raptor.params(stats("Pack", 3), 3)
	ok(close(q.speed, 39) and close(q.respawn, 8 * 0.7), "Quick Whistle: faster, back sooner")
	local sw = Raptor.params(stats("Pack", 3), 3, true)
	ok(close(sw.maxHp, q.maxHp * 0.4) and sw.range == math.huge, "a swarm raptor: x0.4 HP, anywhere on the track")
	eq(Raptor.swarmBite(), 0.4)
end)

test("Raptor Swarm within the side's cap; 10 players x a Swarm each stays under it", function()
	eq(Raptor.swarmCount(0), 10)
	eq(Raptor.swarmCount(20), 4, "the cap: 24 a side")
	eq(Raptor.swarmCount(24), 0)
	-- 10 players on one co-op side, each with a Pack of Five pen and a Swarm.
	local onSide = 0
	for _ = 1, 10 do
		onSide += Walker.room(5, onSide, T.WalkerCapPerSide)
	end
	for _ = 1, 10 do
		onSide += Raptor.swarmCount(onSide)
	end
	ok(onSide <= T.WalkerCapPerSide, `walkers on the side: {onSide} <= {T.WalkerCapPerSide}`)
end)

test("Raptor Charge: from the exit end back at x2 speed; knocks small dinos back, never a boss", function()
	eq(Raptor.chargeAt(300, 30, 0), 300)
	eq(Raptor.chargeAt(300, 30, 1), 240)
	eq(Raptor.chargeAt(300, 30, 6), nil, "past the start: over")
	eq(Raptor.chargeKnock(1, false), 6)
	eq(Raptor.chargeKnock(3, false), 0, "not a small dino")
	eq(Raptor.chargeKnock(1, true), 0, "never a boss")
end)

test("Guard Raptors: the most damaged towers first, wrapping; answer within Guard reach", function()
	local posts = Raptor.guardPosts(3, { 1, 0.4, 0.7 })
	eq(table.concat(posts, ","), "2,3,1")
	eq(table.concat(Raptor.guardPosts(4, { 0.5, 0.9 }), ","), "1,2,1,2")
	eq(#Raptor.guardPosts(2, {}), 0, "no tower in range: none posted")
	ok(Raptor.guardAnswers(10) and not Raptor.guardAnswers(10.5), "Guard reach 10")
end)

test("Rex Tamer's roar: small dinos within Roar reach; Hungry Alpha's stack capped", function()
	local hit = Raptor.roared({ 5, 5, 12, 3 }, { 1, 3, 1, 2 }, { false, false, false, true })
	eq(table.concat(hit, ","), "1", "small, near, not a boss")
	eq(Raptor.stack(3, 10), 30)
	eq(Raptor.stack(9, 10), 50, "cap 50 %")
end)

test("Raider Hounds: the dino that hurt a tower, bites x Avenger x, unless a raider was stung in the last 3 s", function()
	local dino = {}
	local target, x = Raptor.avenger(2, nil, 10, dino)
	ok(target == dino and x == 2, "no raider stung: hunt it")
	target, x = Raptor.avenger(2, 8, 10, dino)
	ok(target == nil and x == 1, "a raider stung 2 s ago: raiders first")
	target = Raptor.avenger(2, 6, 10, dino)
	eq(target, dino, "3 s quiet: back to the dino")
	eq((Raptor.avenger(0, nil, 10, dino)), nil, "no Avenger x: off")
end)

test("Pack Bond: +20 % only with 3+ raptors out and only against dinos (#319); Dive aura while fighting", function()
	eq(Raptor.packBond(20, 3, true), 20)
	eq(Raptor.packBond(20, 2, true), 0, "2 out: nothing")
	eq(Raptor.packBond(20, 5, false), 0, "never against a hunter or a tower")
	eq(Raptor.diveAura(15, 1), 15)
	eq(Raptor.diveAura(15, 0), 0)
	local hero = fs.readFile("src/server/Hero.luau")
	local at = hero:find("Towers.hunterDamageAt(", 1, true)
	local impact = hero:find("local function impact(", 1, true)
	local foe = hero:find("local function hitFoe(", 1, true) or 0
	ok(at ~= nil and impact ~= nil and at > impact, "applied in impact() (shots on dinos)")
	ok(foe == 0 or not hero:sub(foe, foe + 2000):find("hunterDamageAt", 1, true), "not in hitFoe (hunters, towers)")
end)

test("looks: a tamed raptor with a collar and stripe in the camp colour; the alpha and rex are bigger", function()
	local camp = Color3.fromRGB(200, 30, 30)
	for kind, scale in RaptorLook.KINDS do
		local model = RaptorLook.build(kind, camp)
		ok(model.PrimaryPart ~= nil, `{kind} has a body`)
		local collar = model:FindFirstChild("Collar") :: BasePart
		ok(collar ~= nil and collar.Color == camp, `{kind} collar in the camp colour`)
		for _, p in model:GetChildren() do
			if p:IsA("BasePart") then
				ok(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery, `{kind} {p.Name}: never blocks or touches`)
			end
		end
		ok(scale > 0, kind)
	end
	ok(RaptorLook.KINDS.alpha > 1 and RaptorLook.KINDS.rex > RaptorLook.KINDS.alpha and RaptorLook.KINDS.swarm < 1, "sizes")
end)

test("server wiring: a pen never shoots, bites through Walkers and Enemies; Trampled sends none; firenow; the cap", function()
	local towers = fs.readFile("src/server/Towers.luau")
	ok(towers:find("tower.knockedOut or tower.raptor or tower.ranger then", 1, true) ~= nil, "a Raptor Pen doesn't fire like a tower")
	ok(towers:find("sending = not tower.knockedOut", 1, true) ~= nil, "a Trampled pen keeps its raptors out but sends none")
	ok(towers:find("syncWalkers(tower) -- a Trampled pen", 1, true) ~= nil, "re-synced on trample / repair")
	ok(towers:find("local gone = hit(tower, enemy, raptorDamage(tower) * x * avenge, stats.sizeBreaks, true)", 1, true) ~= nil, "bites through the tower's hit rules")
	ok(towers:find('table.insert(fired, "Raptor Swarm")', 1, true) ~= nil and towers:find('table.insert(fired, "Raptor Charge")', 1, true) ~= nil, "firenow RAPTOR")
	local walkers = fs.readFile("src/server/Walkers.luau")
	ok(walkers:find("Walker.room(spec.count - #pack.units, onSide(spec.side), Config.Tuning.WalkerCapPerSide)", 1, true) ~= nil, "the side cap on every spawn")
end)
