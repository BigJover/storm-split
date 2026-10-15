--[[
	Spotter Blimp (PLAN 9h T125 / T125b, DECISIONS #334-#336): the Towers row and Tuning block,
	every PLAN row (Round-19 names, T125b's numbers), and the pure rules in Shared/Blimp: lap
	timing and the bounce, a dino under the blimp is in its circle and one far away isn't,
	Tracking Beam's follow, the biggest dino, Sky Hook's pick, lap drops, round crates, Spare
	Parts' heal, Rebuild Kits' picks, Paratroopers once a round after their delay, Airlift once
	a round, Blinding Glare's miss, and Spotter's Map outlining own-side dinos only, never a
	player. Untouchable: no HP, never a dino target.
]]

local fs = require("@lune/fs")
local Config = require(src.shared.Config)
local Blimp = require(src.shared.Blimp)
local TowerStats = require(src.shared.TowerStats)

local BLIMP = Config.Towers.BLIMP
local T = Config.Tuning

local function pathOf(id: string): (any, number)
	for i, path in BLIMP.paths do
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
	return TowerStats.compute(BLIMP, tiers, all)
end

local function close(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

test("the Towers row (T125b #336): 600 cash, 400 Amber, 5 x 2/s, 14 studs, hits air, untouchable, no HP", function()
	eq(BLIMP.display, "Spotter Blimp")
	eq(BLIMP.baseCost, 600) -- 750 -> 600 (#336)
	eq(BLIMP.unlockCost, 400)
	eq(BLIMP.baseDamage, 5) -- 3 -> 5 (#336)
	eq(BLIMP.baseRate, 2)
	eq(BLIMP.baseTargets, 1)
	eq(BLIMP.range, 14)
	eq(BLIMP.hitsAir, true)
	eq(BLIMP.maxHp, 0)
	eq(BLIMP.untouchable, true, "can't be damaged (#148)")
	ok(not BLIMP.onTrack and not BLIMP.chains and not BLIMP.resin and (BLIMP.walkers or 0) == 0, "no other kind flag")
end)

test("the SPOTTER BLIMP Tuning block (T125b #335: Paratrooper damage 40, rate 1.5)", function()
	eq(T.BlimpSpeedStudsS, 40)
	eq(T.ParatrooperHP, 80)
	eq(T.ParatrooperDamage, 40)
	eq(T.ParatrooperRate, 1.5)
	eq(T.ParatrooperReach, 14)
	eq(T.ParatrooperSpeed, 14)
	eq(T.HookMaxSizes, 2)
end)

-- PLAN 9h's table with T125b's numbers: path, tier, letter, name, cells (T1-3 cumulative; T4/T5 own step).
local ROWS = {
	{ "Door Gun", 1, "", "Belt Gun", { damageMult = 1.5, rateMult = 1.2 } },
	{ "Door Gun", 2, "", "Twin Mount", { damageMult = 1.5, rateMult = 1.2, shots = 2 } },
	{ "Door Gun", 3, "", "Treetop Pass", { damageMult = 2.6, rateMult = 1.2, shots = 2, lineHits = 3 } },
	{ "Door Gun", 4, "A", "Heavy Mount", { damageMult = 1.7, piercesArmor = true, sizeBreaks = 2 } },
	{ "Door Gun", 4, "B", "Rocket Pods", { damageMult = 1.4, bomblets = 3, bombletGenerations = 1 } },
	{ "Door Gun", 4, "C", "Tracer Belt", { damageMult = 1.75, markPercent = 15 } },
	{ "Door Gun", 5, "A", "Gunship", { damageMult = 0.78, shots = 4, bomblets = 2, bombletGenerations = 1, blimpSpeedMult = 1.5 } },
	{ "Door Gun", 5, "B", "Bombing Run", { damageMult = 1.6, bombingRun = true, fieldStrikeX = 12, fieldStrikeEvery = 0 } },
	{ "Door Gun", 5, "C", "Sky Hook", { damageMult = 1.75, hookEvery = 5 } },
	{ "Searchlight", 1, "", "Spotlight", { brittlePercent = 10 } },
	{ "Searchlight", 2, "", "Wide Beam", { brittlePercent = 10, rangeMult = 1.3 } },
	{ "Searchlight", 3, "", "Night Hunt", { brittlePercent = 10, rangeMult = 1.3, auraRangePercent = 15 } },
	{ "Searchlight", 4, "A", "Floodlights", { rangeMult = 1.6 } },
	{ "Searchlight", 4, "B", "Tracking Beam", { targetsBiggest = true, brittlePercent = 14 } },
	{ "Searchlight", 4, "C", "Blinding Glare", { throwMissPercent = 25, brittlePercent = 15 } },
	{ "Searchlight", 5, "A", "All-Seeing Eye", { brittlePercent = 25 } },
	{ "Searchlight", 5, "B", "Lighthouse", { auraDamagePercent = 10, auraReachX = 1.5 } },
	{ "Searchlight", 5, "C", "Spotter's Map", { dinoOutlines = true, brittlePercent = 22 } },
	{ "Cargo", 1, "", "Supply Crates", { chests = 1, chestCash = 200 } },
	{ "Cargo", 2, "", "Ammo Drop", { chests = 1, chestCash = 550, hunterReloadMult = 0.8 } },
	{ "Cargo", 3, "", "Med Drop", { chests = 1, chestCash = 1550, hunterReloadMult = 0.8, medKits = 1, medKitHeal = 40 } },
	{ "Cargo", 4, "A", "Heavy Cargo", { chestCash = 2000 } },
	{ "Cargo", 4, "B", "Rebuild Kits", { lapRepairs = 1 } },
	{ "Cargo", 4, "C", "Spare Parts", { chestCash = 1900, crateHealPercent = 20 } },
	{ "Cargo", 5, "A", "Cargo Run", { lapChests = true } },
	{ "Cargo", 5, "B", "Paratroopers", { paratroopers = 2 } },
	{ "Cargo", 5, "C", "Airlift", { airlift = true, chestCash = 2700 } },
}

test("every PLAN row: name, letter and cells (T4 over T3, T5 over A4); one price a slot; no Raider option", function()
	for _, r in ROWS do
		local id, tier, letter, name, cells = r[1], r[2], r[3], r[4], r[5]
		local path = pathOf(id)
		local row = if tier <= 3 then path.tiers[tier] elseif tier == 4 then path.t4[letter] else path.t5["A" .. letter]
		local below = if tier <= 3 then nil elseif tier == 4 then path.tiers[3] else path.t4.A
		ok(row ~= nil, `{id} T{tier}{letter}`)
		eq(row.name, name, `{id} T{tier}{letter} name`)
		for field, value in cells do
			local want: any = value
			if below and string.find(field, "Mult$") then
				want = (below[field] or 1) * value
			elseif below and type(value) == "number" and field ~= "hookEvery" and field ~= "fieldStrikeEvery" then
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
			ok(row.pvpEffect ~= true, `{id} T{tier}{letter}: no Raider option on the blimp (#320)`)
		end
	end
	eq(stats("Searchlight", 5, "BB").auraReachX, 1.5, "Lighthouse reach")
	eq(stats("Searchlight", 3).auraReachX, 1, "blank Aura reach x = Range")
	ok(close(stats("Door Gun", 5, "AA").blimpSpeedMult, 1.5), "Gunship flies 1.5x")
	eq(stats("Door Gun", 5, "AB").fieldStrikeX, 12, "Bombing Run's Field strike x reaches the stats (not a coil)")
end)

test("lap timing: 2 x track / speed; it bounces at the exit end and a lap ends back at the spawn end", function()
	local speed = Blimp.speed(stats("Door Gun", 0))
	eq(speed, 40)
	eq(Blimp.speed(stats("Door Gun", 5, "AA")), 60, "Gunship")
	eq(Blimp.lapSeconds(610, 40), 30.5)
	local at, dir, lap = Blimp.advance(0, 1, 40, 10, 610)
	eq(at, 400)
	eq(dir, 1)
	eq(lap, false)
	at, dir, lap = Blimp.advance(600, 1, 40, 1, 610) -- 10 to the end, 30 back
	eq(at, 580)
	eq(dir, -1, "turned at the exit end")
	eq(lap, false)
	at, dir, lap = Blimp.advance(20, -1, 40, 1, 610)
	eq(at, 20)
	eq(dir, 1, "turned at the spawn end")
	eq(lap, true, "a lap is done")
	local laps, a, d = 0, 0, 1
	for _ = 1, 610 do -- 61 s at 0.1 s steps = two laps
		local done
		a, d, done = Blimp.advance(a, d, 40, 0.1, 610)
		laps += if done then 1 else 0
	end
	eq(laps, 2)
end)

test("a dino under the blimp is in its circle and one far away isn't (flat distance; it flies 30 up)", function()
	local centre = Vector3.new(100, 0, 50)
	ok(Blimp.under(Vector3.new(110, 3, 50), centre, 14), "10 studs off: hit")
	ok(not Blimp.under(Vector3.new(130, 0, 50), centre, 14), "30 studs off: not hit")
	ok(Blimp.under(Vector3.new(100, 0, 63.9), centre, 14), "the edge")
end)

test("Tracking Beam: the light follows the biggest dino at Blimp speed", function()
	eq(Blimp.follow(100, 300, 40, 1), 140)
	eq(Blimp.follow(100, 120, 40, 1), 120, "arrives")
	eq(Blimp.follow(300, 100, 40, 1), 260, "back along the track")
	local dinos = {
		{ hp = 50, at = 10, boss = false, sizesLeft = 2, inRange = true },
		{ hp = 900, at = 5, boss = true, sizesLeft = 4, inRange = false },
		{ hp = 900, at = 8, boss = false, sizesLeft = 3, inRange = true },
	}
	eq(Blimp.biggest(dinos), 3, "most HP; a tie goes to the furthest along")
	eq(Blimp.biggest({}), nil)
end)

test("Sky Hook: the smallest non-boss dino in range with at most Hook max sizes left", function()
	local dinos = {
		{ hp = 50, at = 10, boss = false, sizesLeft = 2, inRange = true },
		{ hp = 20, at = 5, boss = true, sizesLeft = 1, inRange = true }, -- a boss: never
		{ hp = 30, at = 8, boss = false, sizesLeft = 1, inRange = false }, -- out of range
		{ hp = 30, at = 12, boss = false, sizesLeft = 3, inRange = true }, -- too big
		{ hp = 25, at = 11, boss = false, sizesLeft = 2, inRange = true },
	}
	eq(Blimp.hookPick(dinos), 5, "fewest sizes, then furthest along")
	dinos[1].sizesLeft = 1
	eq(Blimp.hookPick(dinos), 1)
	eq(Blimp.hookPick({ dinos[2], dinos[4] }), nil)
	local timer, fire = Blimp.hookTick(4.9, 0.2, 5)
	ok(fire and close(timer, 0.1), "every 5 s")
	eq(select(2, Blimp.hookTick(0, 10, 0)), false, "no Hook every: never")
end)

test("drops: round crates (not with Lap chests), a crate and the kits each lap, Spare Parts, Rebuild Kits", function()
	eq(Blimp.roundCrates(stats("Cargo", 1)), 1)
	eq(Blimp.roundCrates(stats("Cargo", 0)), 0, "no Chest cash: none")
	local run = stats("Cargo", 5, "AA")
	eq(Blimp.roundCrates(run), 0, "Cargo Run: crates come with the laps instead")
	local d = Blimp.lapDrops(run)
	eq(d.crates, 1)
	eq(d.kits, 1, "Med Drop's kit, every lap")
	eq(d.repairs, 0)
	eq(Blimp.lapDrops(stats("Cargo", 1)).crates, 0, "no Lap chests: no lap crate")
	eq(Blimp.lapDrops(stats("Cargo", 4, "B")).repairs, 1)
	eq(Blimp.crateHeal(stats("Cargo", 4, "C"), 200), 40, "Spare Parts: 20 % of max HP")
	eq(Blimp.crateHeal(stats("Cargo", 3), 200), 0)
	local picks = Blimp.repairs({ 30, 5, 12, 2 }, 14, 2)
	eq(#picks, 2)
	eq(picks[1], 4)
	eq(picks[2], 2)
	eq(#Blimp.repairs({ 30 }, 14, 1), 0, "out of reach")
end)

test("Paratroopers once a round after their delay; Airlift once a round; Blinding Glare misses", function()
	ok(not Blimp.paraDue(2, Blimp.PARA_DELAY - 0.1, false))
	ok(Blimp.paraDue(2, Blimp.PARA_DELAY, false))
	ok(not Blimp.paraDue(2, 30, true), "once a round")
	ok(not Blimp.paraDue(0, 30, false), "no Paratroopers")
	local p = Blimp.paraParams()
	eq(p.maxHp, T.ParatrooperHP)
	eq(p.rate, T.ParatrooperRate)
	eq(p.range, T.ParatrooperReach)
	eq(p.speed, T.ParatrooperSpeed)
	eq(p.hitsAir, false, "ground only")
	eq(p.respawn, math.huge, "down = gone until the round ends")
	eq(Blimp.paraDamage(), T.ParatrooperDamage)
	local air = stats("Cargo", 5, "AC")
	ok(Blimp.airlifts(air, false))
	ok(not Blimp.airlifts(air, true), "the first Trampled tower each round only")
	ok(not Blimp.airlifts(stats("Cargo", 3), false))
	ok(Blimp.misses(25, 0.2) and not Blimp.misses(25, 0.3) and not Blimp.misses(0, 0))
	local short = Blimp.shortOf(Vector3.new(0, 0, 0), Vector3.new(20, 0, 0))
	ok(short.X > 0 and short.X < 20, "a missed throw lands short")
end)

test("Spotter's Map: own-side dinos only, never a player, never another side's dinos (#319)", function()
	ok(Blimp.outlined(true, 2, 2, true))
	ok(not Blimp.outlined(true, 1, 2, true), "another side's dino")
	ok(not Blimp.outlined(false, 2, 2, true), "a player")
	ok(not Blimp.outlined(true, 2, 2, false), "no Spotter's Map")
	eq(Blimp.outlineAttribute(3), "DinoOutlines3")
end)

test("the server wires it: flight + effects each frame, Airlift on a trample, lap kits, Glare on throws, outlines", function()
	local towers = fs.readFile("src/server/Towers.luau")
	ok(string.find(towers, "stepBlimp(tower, dt, own)", 1, true) ~= nil, "Towers.step flies every blimp")
	ok(string.find(towers, "setKnockedOut(tower, true)\n\t\tairlift(tower)", 1, true) ~= nil, "a trample asks Airlift")
	ok(string.find(towers, "if source.blimp then source.position else source.base", 1, true) ~= nil, "its circle is under the blimp, not the mast")
	ok(string.find(towers, "def == Config.Towers.BLIMP", 1, true) ~= nil, "no range ring at the mast")
	ok(string.find(fs.readFile("src/server/DinoAttacks.luau"), "Towers.throwMissAt(from, enemy.side)", 1, true) ~= nil, "Blinding Glare on throws")
	ok(string.find(fs.readFile("src/server/Main.server.luau"), "Airdrops.kitAt(position, heal, side)", 1, true) ~= nil, "lap med kits land")
	local looks = fs.readFile("src/client/Looks.client.luau")
	ok(string.find(looks, "Blimp.outlined(", 1, true) ~= nil and string.find(looks, "FindFirstChild(\"Enemies\")", 1, true) ~= nil,
		"Spotter's Map outlines only the map's dino models, through Blimp.outlined")
end)
