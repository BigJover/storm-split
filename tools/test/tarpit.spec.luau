--[[
	Tar Pit (PLAN T67, UPGRADES.md, DECISIONS #150, #152, #189): the pool, the strongest
	pool only, sinking, Eruption's size drop, Tar Tracks, the pool overlap check, the
	sheet's tiers, and that the server goes through Enemies for every take-down.
]]

local fs = require("@lune/fs")

local Config = require(src.shared.Config)
local Placement = require(src.shared.Placement)
local TarPit = require(src.shared.TarPit)
local TowerStats = require(src.shared.TowerStats)

local PIT = Config.Towers.TARPIT
local T = Config.Tuning

local function at(pathIndex: number, tier: number)
	local tiers = { 0, 0, 0 }
	tiers[pathIndex] = tier
	return TowerStats.compute(PIT, tiers)
end

test("the Tuning levers are the seeds (#150; Eruption every 10 -> 15 s at T68, #199)", function()
	eq(T.EruptionEvery, 15)
	eq(T.EruptionSizes, 2)
	eq(T.TarSinkSeconds, 3)
	eq(T.TarTracksLength, 12)
	eq(T.TarTracksSeconds, 3)
end)

test("the tower: 450 cash, 250 Amber, on the track, can't be damaged, no air, a 12-stud pool slowing 25%", function()
	eq(PIT.display, "Tar Pit")
	eq(PIT.baseCost, 450)
	eq(PIT.unlockCost, 250)
	eq(PIT.onTrack, true)
	eq(PIT.untouchable, true)
	eq(PIT.maxHp, 0)
	eq(PIT.hitsAir, false)
	eq(PIT.baseDamage, 0, "no damage until Bubbling")
	local base = at(1, 0)
	eq(base.range, 12, "pool length")
	eq(base.slowPercent, 25)
	eq(base.sinkSeconds, 3, "sinks after Tar sink seconds")
	eq(base.burnDps, 0)
	eq(base.eruption, false)
end)

test("the paths and names are TOWERS_NEXT's Final names", function()
	local want = {
		{ "Deep Tar", { "Thick Tar", "Wide Pool", "Fast Sink", "Clinging Tar", "Tar Lake" } },
		{ "Bubbling", { "Warm Tar", "Simmer", "Boiling Pit", "Tar Fire", "Eruption" } },
		{ "Dig Site", { "Pick and Shovel", "Fossil Hunter", "Lucky Finds", "Tar Tracks", "Tar Totem" } },
	}
	for i, path in want do
		eq(PIT.paths[i].id, path[1])
		for t, name in path[2] do
			eq(PIT.paths[i].tiers[t].name, name, `{path[1]} T{t}`)
		end
	end
end)

test("Deep Tar: slow 35%, Wide Pool 18 studs, Fast Sink 1.5s, Clinging Tar 3s, Tar Lake x3 the pool", function()
	eq(at(1, 1).slowPercent, 35)
	near(at(1, 2).range, 18, "Wide Pool")
	eq(at(1, 2).sinkSeconds, 3)
	eq(at(1, 3).sinkSeconds, 1.5, "Fast Sink")
	eq(at(1, 3).slowLinger, 0)
	eq(at(1, 4).slowLinger, 3, "Clinging Tar")
	near(at(1, 5).range, 3 * at(1, 4).range, "Tar Lake: three times as much track")
	eq(at(1, 5).sinkSeconds, 1.5)
end)

test("Bubbling: damage per second rising, Tar Fire burns on the way out, Eruption at tier 5 only", function()
	local last = 0
	for t = 1, 5 do
		local s = at(2, t)
		ok(if t <= 3 then s.burnDps > last else s.burnDps >= last, `T{t} deals at least T{t - 1}`)
		last = s.burnDps
		eq(s.eruption, t == 5, `Eruption at T{t}`)
		eq(s.burnSeconds > 0, t >= 4, `Tar Fire at T{t}`)
	end
	eq(at(2, 5).sizeBreaks, 1, "the tar's damage breaks 1 (DECISIONS #127)")
end)

test("Dig Site: cash per sink, Lucky Finds' chest, Tar Tracks 15%, Tar Totem +15% vs slowed", function()
	ok(at(3, 1).sinkCash > 0, "Pick and Shovel pays per sink")
	ok(at(3, 2).sinkCash > at(3, 1).sinkCash, "Fossil Hunter pays more")
	eq(at(3, 2).sinkChestCash, 0)
	ok(at(3, 3).sinkChestCash > 0, "Lucky Finds")
	eq(at(3, 4).tracksSlowPercent, 15, "Tar Tracks")
	eq(at(3, 4).auraSlowedPercent, 0)
	eq(at(3, 5).auraSlowedPercent, 15, "Tar Totem")
	eq(at(3, 5).chests, 0, "no round airdrops: the chest comes from a sink")
end)

test("tar abilities only on a tower placed on the track", function()
	for key, def in Config.Towers do
		if not def.onTrack then
			for i = 1, #def.paths do
				for t = 1, #def.paths[i].tiers do
					local tiers = { 0, 0, 0 }
					tiers[i] = t
					local s = TowerStats.compute(def, tiers)
					eq(s.sinkSeconds, 0, `{key} sink`)
					eq(s.eruption, false, `{key} eruption`)
					eq(s.sinkCash + s.sinkChestCash + s.tracksSlowPercent + s.auraSlowedPercent, 0, `{key} tar fields`)
				end
			end
		end
	end
end)

test("the pool: centred where the pit stands, length studs of track", function()
	eq(TarPit.contains(100, 100, 12), true)
	eq(TarPit.contains(106, 100, 12), true, "the end")
	eq(TarPit.contains(94, 100, 12), true)
	eq(TarPit.contains(106.5, 100, 12), false, "past it")
	eq(TarPit.contains(93, 100, 12), false)
end)

test("pools never overlap when placed; touching ends are fine (#189, on the pool)", function()
	local pools = { { at = 100, length = 12 } }
	eq(TarPit.overlaps(111, 12, pools), true, "1 stud of overlap")
	eq(TarPit.overlaps(112, 12, pools), false, "ends touch")
	eq(TarPit.overlaps(80, 18, { { at = 100, length = 36 } }), true, "against the pool's current (upgraded) length")
	eq(TarPit.overlaps(80, 18, { { at = 100, length = 12 } }), false)
	local fits, why = Placement.checkPool(105, 12, pools)
	eq(fits, false)
	eq(why, "Overlaps another tar pool")
	eq((Placement.checkPool(130, 12, pools)), true)
end)

test("a dino in two pools gets the strongest one only: the most cash in, first placed on a tie", function()
	eq(TarPit.strongest({}), nil)
	eq(TarPit.strongest({ 450 }), 1)
	eq(TarPit.strongest({ 450, 3000, 1200 }), 2)
	eq(TarPit.strongest({ 900, 900 }), 1, "a tie: the first placed")
	eq(TarPit.strength(PIT, { 0, 0, 0 }), 450)
	local cash = 450
	for t = 1, 5 do
		cash += PIT.paths[1].tiers[t].cost
	end
	eq(TarPit.strength(PIT, { 5, 0, 0 }), cash, "Tar Lake: base + every Deep Tar tier")
	ok(TarPit.strength(PIT, { 5, 2, 0 }) > TarPit.strength(PIT, { 5, 0, 0 }))
	-- The server applies one pool per dino: it picks with TarPit.strongest and every effect
	-- below the pick reads `pit`, never the list.
	local towers = fs.readFile("src/server/Towers.luau")
	local body = string.match(towers, "local function stepTar.-\nend\n")
	ok(body ~= nil, "stepTar found")
	ok(string.find(body, "local pick = TarPit.strongest(power)", 1, true) ~= nil, "picks the strongest")
	local after = string.match(body, "lastPool%[enemy%] = pit(.*)")
	ok(after ~= nil and not string.find(after, "inside", 1, true), "nothing after the pick reads the other pools")
end)

test("sinking: a last-size, non-boss, ground dino after Sink seconds", function()
	eq(TarPit.sinks(1, false, false, 3, 3), true)
	eq(TarPit.sinks(1, false, false, 2.9, 3), false, "not yet")
	eq(TarPit.sinks(2, false, false, 10, 3), false, "not its last size")
	eq(TarPit.sinks(1, true, false, 10, 3), false, "never a boss")
	eq(TarPit.sinks(1, false, true, 10, 3), false, "never a Pteranodon")
	eq(TarPit.sinks(1, false, false, 1.5, 1.5), true, "Fast Sink")
end)

test("a sunk dino pays like a kill and counts as a take-down", function()
	-- Enemies.sink: one onKilled (cash and a Bone, like the last size of a kill), then removed.
	local enemies = fs.readFile("src/server/Enemies.luau")
	local sink = string.match(enemies, "function Enemies%.sink.-\nend\n")
	ok(sink ~= nil, "Enemies.sink found")
	local _, kills = string.gsub(sink, "callbacks%.onKilled%(enemy%)", "")
	eq(kills, 1, "pays once")
	ok(string.find(sink, "remove(enemy)", 1, true) ~= nil, "and it's gone")
	ok(string.find(sink, "enemy.def.boss", 1, true) ~= nil and string.find(sink, "enemy.def.flying", 1, true) ~= nil, "refuses bosses and flyers")
	-- Towers credits the pit's owner with the pop and the species (bounties count it).
	local towers = fs.readFile("src/server/Towers.luau")
	ok(string.find(towers, "local sunk, gone = Enemies.sink(enemy)", 1, true) ~= nil, "Towers sinks through Enemies")
	ok(string.find(towers, "credit(pit.owner, true, gone, 1)", 1, true) ~= nil, "the pop goes to the pit's owner")
end)

test("Eruption: a 5-size T-Rex drops to 3, whatever its HP; the last sizes take a dino down", function()
	local rex = Config.Enemies.BARGE
	eq(rex.sizes, 5)
	eq(rex.boss, true, "bosses included")
	ok(rex.breakResist > 0, "Break resist is ignored")
	local share = rex.hp / rex.sizes
	local hp, dropped, dead = TarPit.drop(5 * share, share, 5, T.EruptionSizes)
	eq(dropped, 2)
	eq(dead, false)
	near(hp, 3 * share, "top of size 3")
	hp, dropped = TarPit.drop(4.2 * share, share, 5, 2) -- hurt but still size 5
	eq(dropped, 2)
	near(hp, 3 * share)
	hp, dropped, dead = TarPit.drop(1.5 * share, share, 2, 2)
	eq(dropped, 2)
	eq(dead, true)
	eq(hp, 0)
	hp, dropped, dead = TarPit.drop(0.4 * share, share, 1, 2)
	eq(dropped, 1, "only the size it has")
	eq(dead, true)
	-- Enemies.dropSizes pays every size dropped and goes through the rule.
	local enemies = fs.readFile("src/server/Enemies.luau")
	local drop = string.match(enemies, "function Enemies%.dropSizes.-\nend\n")
	ok(drop ~= nil and string.find(drop, "TarPit.drop(", 1, true) ~= nil, "Enemies uses TarPit.drop")
	ok(string.find(drop, "for _ = 1, dropped do", 1, true) ~= nil, "each size pays")
	ok(not string.find(drop, "breakResist", 1, true), "no Break resist")
end)

test("Eruption every Tuning interval: the timer fires once per fill and carries the rest", function()
	local timer, fired = 0, false
	local count = 0
	for _ = 1, 610 do -- 30.5 s at 20 steps a second
		timer, fired = TarPit.tick(timer, 0.05, T.EruptionEvery)
		if fired then
			count += 1
		end
	end
	eq(count, math.floor(30.5 / T.EruptionEvery)) -- 2 at 15 s (PLAN T68, #199)
	timer, fired = TarPit.tick(9.9, 0.25, 10)
	eq(fired, true)
	near(timer, 0.15)
	eq((select(2, TarPit.tick(0, 100, 0))), false, "no interval, no eruption")
end)

test("Tar Tracks: the footprints are the stretch past the pool's far end", function()
	eq(TarPit.onTracks(107, 100, 12, 12), true)
	eq(TarPit.onTracks(118, 100, 12, 12), true, "its end")
	eq(TarPit.onTracks(106, 100, 12, 12), false, "still the pool")
	eq(TarPit.onTracks(119, 100, 12, 12), false, "past the footprints")
	eq(TarPit.onTracks(93, 100, 12, 12), false, "behind the pool: no footprints yet")
end)

test("the pool is drawn end to end", function()
	local points = TarPit.samples(100, 12, 3)
	eq(#points, 5)
	near(points[1], 94)
	near(points[#points], 106)
end)
