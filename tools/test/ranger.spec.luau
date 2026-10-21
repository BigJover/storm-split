--[[
	Ranger Station (PLAN 9j T129, DECISIONS #340): the Towers row and Tuning block, every PLAN
	row (Round-19 names incl. "Ranger Troop", #340's numbers), and the pure rules in
	Shared/Ranger: ranger params (HP per tier, the Legend's HP), heavy / Legend roles, posts
	round-robin + formation, default posts, the posts check, the jeep's lap, traps (first
	ground dino in reach; stun and knockback never on bosses; the trap line), Decoy once per
	dino per post, the net once per boss, the dart timer, bites at a post, Hold the Line,
	Sandbags reach. Released at T130b.
]]

local Config = require(src.shared.Config)
local Ranger = require(src.shared.Ranger)
local TowerStats = require(src.shared.TowerStats)
local ShopRules = require(src.shared.ShopRules)

local RANGER = Config.Towers.RANGER
local T = Config.Tuning

local function pathOf(id: string): (any, number)
	for i, path in RANGER.paths do
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
	return TowerStats.compute(RANGER, tiers, all)
end

local function close(a: number, b: number): boolean
	return math.abs(a - b) < 1e-3
end

test("the Towers row (#340): 600 cash, 500 Amber, 10 x 2.3/s, 1 ranger, range 30, ground only, 200 HP", function()
	eq(RANGER.display, "Ranger Station")
	eq(RANGER.baseCost, 600)
	eq(RANGER.unlockCost, 500 * Config.Tuning.AmberScale)
	eq(RANGER.baseDamage, 10)
	eq(RANGER.baseRate, 2.3)
	eq(RANGER.baseTargets, 1)
	eq(RANGER.walkers, 1)
	eq(RANGER.range, 30)
	eq(RANGER.hitsAir, false)
	eq(RANGER.maxHp, 200)
	eq(ShopRules.Unreleased.RANGER, nil, "released at T130b (#312, #340)")
end)

test("the RANGER STATION Tuning block", function()
	eq(T.RangerHP, 100)
	eq(T.RangerSpeed, 16)
	eq(T.RangerReach, 14)
	eq(T.RangerRetreatHPShare, 0.3)
	eq(T.RangerRespawnS, 10)
	eq(T.CabinHealHPS, 20)
	eq(T.RangerLeashX, 1)
	eq(T.MaxPosts, 3)
	eq(T.TrapEveryS, 8)
	eq(T.TrapSlow, 40)
	eq(T.TrapSlowS, 2)
	eq(T.TrapReachStuds, 3)
	eq(T.TrapLineTraps, 6)
	eq(T.HeavyX, 3)
	eq(T.LegendX, 3)
	eq(T.LegendHPX, 3)
	eq(T.LegendDartEveryS, 12)
	eq(T.LegendDartMark, 25)
	eq(T.LegendDartS, 8)
	eq(T.JeepSpeed, 20)
	eq(T.RangerGuardReachStuds, 10)
	eq(T.RetreatHPShare, 0.3, "the Raptor Pen's own block is untouched")
	eq(T.LeashX, 1.5)
end)

local Y = true
local ROWS = {
	{ "Riflemen", 1, "", "Recruit", { walkers = 2 } },
	{ "Riflemen", 2, "", "Sharpshooter", { walkers = 2, damageMult = 1.8, rangeMult = 1.2 } },
	{ "Riflemen", 3, "", "Squad", { walkers = 3, damageMult = 2.8, rangeMult = 1.2 } },
	{ "Riflemen", 4, "A", "Elite Squad", { damageMult = 1.75, piercesArmor = Y } },
	{ "Riflemen", 4, "B", "Heavy Rifle", { damageMult = 1.1, heavyRanger = Y } },
	{ "Riflemen", 4, "C", "Flare Rounds", { damageMult = 1.9, hitsAir = Y } },
	{ "Riflemen", 5, "A", "Ranger Troop", { damageMult = 1.2, walkers = 5 } },
	{ "Riflemen", 5, "B", "Legend Ranger", { damageMult = 1.2, legend = Y } },
	{ "Riflemen", 5, "C", "Patrol Jeep", { damageMult = 2.25, jeep = Y } },
	{ "Trackers", 1, "", "Snare Kit", { trap = Y } },
	{ "Trackers", 2, "", "Bait", { trap = Y, trapEvery = 5, damageMult = 1.3 } },
	{ "Trackers", 3, "", "Snap Traps", { trap = Y, trapEvery = 5, damageMult = 1.6, trapStunSeconds = 0.6, walkers = 2 } },
	{ "Trackers", 4, "A", "Pit Traps", { trapStunSeconds = 1.5 } },
	{ "Trackers", 4, "B", "Decoy Calls", { decoySeconds = 1 } },
	{ "Trackers", 4, "C", "Tripwire", { knockback = 4 } },
	{ "Trackers", 5, "A", "Master Trapper", { trapLine = Y } },
	{ "Trackers", 5, "B", "Net Launchers", { bossHoldSeconds = 2, damageMult = 1.3 } },
	{ "Trackers", 5, "C", "Head Ranger", { takeDownMarkPercent = 20, damageMult = 1.2 } },
	{ "Wardens", 1, "", "Leather Coats", { damageMult = 1.3, walkerHpMult = 1.5 } },
	{ "Wardens", 2, "", "Medic Bag", { walkers = 2, damageMult = 1.5, walkerHpMult = 1.5, walkerRegen = 5 } },
	{ "Wardens", 3, "", "Shield Wall", { walkers = 2, damageMult = 2, walkerHpMult = 1.5, walkerRegen = 5, walkerResistPercent = 40 } },
	{ "Wardens", 4, "A", "Field Rations", { healsBetweenRounds = Y, walkerHpMult = 1.3 } },
	{ "Wardens", 4, "B", "Rally Point", { walkerRespawnMult = 0.5 } },
	{ "Wardens", 4, "C", "Sandbags", { postAura = Y, auraHpPercent = 10 } },
	{ "Wardens", 5, "A", "Hold the Line", { bossRoundGuard = Y } },
	{ "Wardens", 5, "B", "Bodyguards", { guard = Y } },
	{ "Wardens", 5, "C", "Hunter's Lodge", { rescueRespawnMult = 0.5 } },
}
local TIMERS = { trapEvery = true }

test("every PLAN row: name, letter and cells (T4 over T3, T5 over A4); one price a slot; no Raider option (#320)", function()
	for _, r in ROWS do
		local id, tier, letter, name, cells = r[1], r[2], r[3], r[4], r[5]
		local path = pathOf(id)
		local row = if tier <= 3 then path.tiers[tier] elseif tier == 4 then path.t4[letter] else path.t5["A" .. letter]
		local below = if tier <= 3 then nil elseif tier == 4 then path.tiers[3] else path.t4.A
		ok(row ~= nil, `{id} T{tier}{letter}`)
		eq(row.name, name, `{id} T{tier}{letter} name`)
		for field, value in cells do
			local want: any = value
			if below and string.find(field, "Mult$") and field ~= "rescueRespawnMult" then -- Rescue x is the Hospital's max column
				want = (below[field] or 1) * value
			elseif below and type(value) == "number" and not TIMERS[field] then
				want = math.max(value, below[field] or 0)
			end
			if type(want) == "number" then
				ok(close(row[field] or 0, want), `{id} T{tier}{letter} {field} = {want} (got {row[field]})`)
			else
				eq(row[field], want, `{id} T{tier}{letter} {field}`)
			end
		end
		if tier >= 4 then
			local slot = if tier == 4 then path.t4 else { A = path.t5.AA, B = path.t5.AB, C = path.t5.AC }
			eq(row.cost, slot.A.cost, `{id} T{tier}{letter}: one price a slot (#277)`)
			ok(row.pvpEffect ~= true, `{id} T{tier}{letter}: no Raider option on the station (#320)`)
		end
	end
	eq(stats("Riflemen", 5, "AA").walkers, 5, "Ranger Troop: 5 rangers")
	eq(stats("Trackers", 3).trapEvery, 5, "Trap every: the shortest wins")
	eq(stats("Trackers", 1).trapEvery, 0, "blank = Tuning")
	ok(stats("Wardens", 5, "AA").bossRoundGuard and stats("Wardens", 5, "AA").healsBetweenRounds, "Hold the Line over Field Rations")
end)

test("ranger params: HP per tier, x Legend HP; respawn x Walker respawn x; regen; furthest along first", function()
	local s = stats("Wardens", 4, "B")
	local p = Ranger.params(s :: any, 4)
	ok(close(p.maxHp, T.RangerHP * 1.5 * (1 + T.TowerHPPerTier * 4)), "HP = base x Walker HP x x tiers")
	ok(close(p.respawn, T.RangerRespawnS * 0.5), "Rally Point: back 2x faster")
	eq(p.regen, 5, "Medic Bag")
	eq(p.resist, 40, "Shield Wall")
	ok(p.targetsFirst and p.range == T.RangerReach and p.retreatShare == T.RangerRetreatHPShare)
	local legend = Ranger.params(stats("Riflemen", 5, "AB") :: any, 5, true)
	ok(close(legend.maxHp, T.RangerHP * (1 + T.TowerHPPerTier * 5) * T.LegendHPX), "the Legend: x Legend HP x")
	eq(Ranger.params(stats("Riflemen", 4, "C") :: any, 4).hitsAir, true, "Flare Rounds hit flyers")
end)

test("roles and shots: Heavy = ranger 1 (x3, breaks 3); the Legend = ranger 2 with a heavy, else 1", function()
	local x, breaks = Ranger.shot(1, { heavyRanger = true, legend = false })
	ok(x == T.HeavyX and breaks == 3)
	x, breaks = Ranger.shot(2, { heavyRanger = true, legend = false })
	ok(x == 1 and breaks == 0, "the others shoot plain")
	eq((Ranger.shot(2, { heavyRanger = true, legend = true })), T.LegendX)
	eq((Ranger.shot(1, { heavyRanger = false, legend = true })), T.LegendX)
	local h, l = Ranger.roles({ heavyRanger = false, legend = false })
	ok(h == 0 and l == 0)
end)

test("posts: round-robin, formation on 3, default nearest posts within Range, the posts check", function()
	local posts = { 50, 80, 110 }
	local at, slot = Ranger.postFor(4, posts)
	ok(at == 50 and slot == 2, "ranger 4 shares post 1, second in formation")
	eq((Ranger.postFor(5, posts)), 80)
	eq((Ranger.postFor(1, {})), nil)
	local d = Ranger.defaultPosts({
		{ at = 100, dist = 5 }, { at = 104, dist = 6 }, { at = 130, dist = 9 }, { at = 70, dist = 12 }, { at = 160, dist = 20 }, { at = 300, dist = 40 },
	}, 30, 3)
	ok(#d == 3 and d[1] == 100 and d[2] == 130 and d[3] == 70, "nearest first, one every Ranger reach")
	eq(#Ranger.defaultPosts({ { at = 0, dist = 31 } }, 30, 3), 0, "none beyond Range")
	eq(#Ranger.defaultPosts({ { at = 100, dist = 5 }, { at = 130, dist = 9 } }, 30, 1), 1, "one post per ranger")
	eq(Ranger.postCount(1), 1)
	eq(Ranger.postCount(5), T.MaxPosts, "Ranger Troop's 5 share Max posts")
	local fitted = Ranger.fitPosts({ 200 }, { 100, 205, 130 }, 3)
	ok(#fitted == 3 and fitted[1] == 200 and fitted[2] == 100 and fitted[3] == 130, "own posts first, defaults clear of them")
	eq(#Ranger.fitPosts({ 1, 50, 90 }, {}, 2), 2, "never more than the rangers")
	ok(Ranger.checkPost(true, 20, 30, false))
	ok(not Ranger.checkPost(false, 20, 30, false), "on the track")
	ok(not Ranger.checkPost(true, 31, 30, false), "within Range")
	ok(not Ranger.checkPost(true, 20, 30, true), "not in a tar pool")
end)

test("Patrol Jeep: there and back along the track at Jeep speed", function()
	eq(Ranger.jeepAt(0, 400), 0)
	eq(Ranger.jeepAt(5, 400), 5 * T.JeepSpeed)
	eq(Ranger.jeepAt(400 / T.JeepSpeed + 5, 400), 400 - 5 * T.JeepSpeed, "and back")
	eq(Ranger.jeepAt(800 / T.JeepSpeed, 400), 0)
end)

test("traps: the first ground dino in reach; stun and knockback never on a boss; trap line; trap timer", function()
	local d = { { id = "a", at = 98, boss = false, flying = false }, { id = "b", at = 102, boss = false, flying = false },
		{ id = "c", at = 101, boss = false, flying = true }, { id = "d", at = 110, boss = false, flying = false } }
	local pick = Ranger.trapPick(100, d)
	eq(pick and pick.id, "b", "furthest along within Trap reach, ground only")
	eq(Ranger.trapPick(100, { d[3], d[4] }), nil)
	local s = stats("Trackers", 4, "A")
	local e = Ranger.trapEffect(s :: any, false)
	ok(e.slowPercent == 40 and e.slowSeconds == 2 and e.stun == 1.5, "Pit Traps: hold 1.5 s")
	local b = Ranger.trapEffect(stats("Trackers", 4, "C") :: any, true)
	ok(b.stun == 0 and b.knockback == 0 and b.slowPercent == 40, "a boss: slowed only")
	eq(Ranger.trapEffect(stats("Trackers", 4, "C") :: any, false).knockback, 4, "Tripwire")
	eq(Ranger.trapEvery(stats("Trackers", 1) :: any), T.TrapEveryS)
	eq(Ranger.trapEvery(stats("Trackers", 2) :: any), 5)
	local line = Ranger.trapLine(600)
	ok(#line == T.TrapLineTraps and line[1] == 50 and line[6] == 550, "evenly along the track")
end)

test("Decoy once per dino per post (bosses x Boss hard stop x); the net once per boss, full; the dart timer", function()
	local seen = {}
	eq(Ranger.decoy(seen, "a", false, 1), 1)
	eq(Ranger.decoy(seen, "a", false, 1), 0, "once per dino at this post")
	eq(Ranger.decoy({}, "a", false, 0), 0, "no Decoy")
	eq(Ranger.decoy({}, "boss", true, 1), T.BossHardStopX)
	local netted = {}
	eq(Ranger.net(netted, "rex", true, 2), 2, "full length on a boss")
	eq(Ranger.net(netted, "rex", true, 2), 0, "once per boss")
	eq(Ranger.net(netted, "small", false, 2), 0, "bosses only")
	local mark, secs, nextAt = Ranger.dartDue(0, 1)
	ok(mark == T.LegendDartMark and secs == T.LegendDartS and nextAt == 1 + T.LegendDartEveryS)
	local none = Ranger.dartDue(nextAt, 5)
	eq(none, nil)
end)

test("bites at a post, Hold the Line, Sandbags reach", function()
	ok(Ranger.bitesAtPost(100, 103, 4))
	ok(not Ranger.bitesAtPost(100, 105, 4))
	eq(Ranger.guarded(10, 30, false), 30)
	eq(Ranger.guarded(10, 30, true), 9, "never below 1 HP while a boss is out")
	eq(Ranger.guarded(1, 30, true), 0)
	ok(Ranger.inPostAura(T.RangerGuardReachStuds) and not Ranger.inPostAura(T.RangerGuardReachStuds + 1))
end)

test("server wiring: a station never shoots like a tower; rangers shoot through Walkers at posts; traps; firenow", function()
	local fs = require("@lune/fs")
	local towers = fs.readFile("src/server/Towers.luau")
	ok(towers:find("tower.knockedOut or tower.raptor or tower.ranger then", 1, true) ~= nil, "a Ranger Station doesn't fire like a tower")
	ok(towers:find('raptor = if (def.walkers or 0) > 0 and key ~= "RANGER"', 1, true) ~= nil, "a station is not a Raptor Pen")
	ok(towers:find("if tower.ranger then\n%s*syncRangers%(tower%)") ~= nil, "place / upgrade / trample re-sync the rangers")
	ok(towers:find("if not tower.ranger then -- a Ranger Station's Knockback is its traps'", 1, true) ~= nil, "Tripwire knocks back from traps, not shots")
	ok(towers:find("stepRanger(tower, dt, own)", 1, true) ~= nil, "stepped")
	ok(towers:find("setTrapLine(tower) -- Master Trapper", 1, true) ~= nil, "the trap line at a round played's start")
	ok(towers:find('table.insert(fired, "Master Trapper")', 1, true) ~= nil and towers:find('table.insert(fired, "Tracking Dart")', 1, true) ~= nil, "firenow RANGER")
	ok(towers:find("auraCovers(source, tower.base)", 1, true) ~= nil, "Sandbags: the aura reaches towers near a post")
	local walkers = fs.readFile("src/server/Walkers.luau")
	ok(walkers:find("Ranger.bitesAtPost(unit.at, enemy.distance, reach or 0)", 1, true) ~= nil, "dinos walking past bite a ranger at its post")
	ok(walkers:find("pack.ride == nil", 1, true) ~= nil, "never a riding jeep's")
	local attacks = fs.readFile("src/server/DinoAttacks.luau")
	ok(attacks:find("Towers.guardBite(target.ref, damage)", 1, true) ~= nil, "Bodyguards take bites aimed at their towers")
	ok(attacks:find("def.meleeReach)", 1, true) ~= nil, "the dino's own bite reach")
end)
