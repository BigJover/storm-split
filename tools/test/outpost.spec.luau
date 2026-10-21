--[[
	Hunters' Outpost (PLAN 10c T138, DECISIONS #382-#384, names DINO_REVIEW Round 20):
	Shared/Outpost's layout and rules, plus the server/client wiring read from source (no
	combat in camp, third person only there, Play moves people out, results bring them back).
]]
local fs = require("@lune/fs")
local Outpost = require(src.shared.Outpost)
local Sides = require(src.shared.Sides)
local Track = require(src.shared.Track)

local function flat(v: Vector3): Vector2
	return Vector2.new(v.X, v.Z)
end

-- Shortest distance from a point to an axis-aligned rectangle (0 inside).
local function toRect(p: Vector2, min: Vector2, max: Vector2): number
	local dx = math.max(min.X - p.X, 0, p.X - max.X)
	local dy = math.max(min.Y - p.Y, 0, p.Y - max.Y)
	return math.sqrt(dx * dx + dy * dy)
end

test("four stations with their Round 20 names, one per trained stat", function()
	local want = {
		reach = { "Raptor Dummy", "Reach" },
		speed = { "Raptor Chase", "Speed" },
		health = { "Herb Kitchen", "Health" },
		throw = { "Coconut Toss", "Throw" },
	}
	eq(#Outpost.STATIONS, 4)
	for _, row in Outpost.STATIONS do
		local w = want[row.key]
		ok(w ~= nil, `{row.key} is a stat`)
		eq(row.name, w[1])
		eq(row.stat, w[2])
		eq(Outpost.station(row.key), row)
	end
	eq(Outpost.station("nope"), nil)
	eq(Outpost.NAME, "Hunters' Outpost")
end)

test("stationAt: inside a pad is that station, just outside or off the floor is none", function()
	for _, row in Outpost.STATIONS do
		local centre = Outpost.CENTRE + row.offset + Vector3.new(0, 3, 0)
		eq(Outpost.stationAt(centre), row.key, `{row.name} centre`)
		eq(Outpost.stationAt(centre + Vector3.new(Outpost.STATION_RADIUS - 0.1, 0, 0)), row.key, "edge")
		eq(Outpost.stationAt(centre + Vector3.new(Outpost.STATION_RADIUS + 0.1, 0, 0)), nil, "just outside")
		eq(Outpost.stationAt(centre + Vector3.new(0, 200, 0)), nil, "far above")
		eq(Outpost.stationAt(row.offset), nil, "the same spot on the co-op map")
		for _, other in Outpost.STATIONS do
			if other ~= row then
				ok((flat(row.offset) - flat(other.offset)).Magnitude > 2 * Outpost.STATION_RADIUS, `{row.name} and {other.name} pads don't overlap`)
			end
		end
	end
	eq(Outpost.stationAt("x"), nil)
	eq(Outpost.stationAt(nil), nil)
end)

test("10 Campsites on the floor, apart from each other, the stations, the hut and the spawn", function()
	eq(Outpost.CAMPSITES, 10)
	local half = Outpost.CAMPSITE_SIZE / 2 * math.sqrt(2)
	for i = 1, 10 do
		local spot = Outpost.campsite(i) :: Vector3
		ok(spot ~= nil, `Campsite {i}`)
		ok((flat(spot) - flat(Outpost.CENTRE)).Magnitude + half < Outpost.RADIUS, `Campsite {i} fits on the floor`)
		for j = i + 1, 10 do
			ok((flat(spot) - flat(Outpost.campsite(j) :: Vector3)).Magnitude > Outpost.CAMPSITE_SIZE * math.sqrt(2), `Campsites {i} and {j} apart`)
		end
		for _, row in Outpost.STATIONS do
			ok((flat(spot) - flat(Outpost.CENTRE + row.offset)).Magnitude > half + Outpost.STATION_RADIUS, `Campsite {i} clear of {row.name}`)
		end
		ok((flat(spot) - flat(Outpost.CENTRE + Outpost.HATCHERY_HUT)).Magnitude > half + 8, `Campsite {i} clear of the Hatchery Hut`)
		ok((flat(spot) - flat(Outpost.CENTRE + Vector3.new(0, 0, 12))).Magnitude > half + Outpost.SPAWN_RING, `Campsite {i} clear of the spawn ring`)
	end
	eq(Outpost.campsite(0), nil)
	eq(Outpost.campsite(11), nil)
	eq(Outpost.campsite(1.5), nil)
end)

test("spawn points are inside the camp and off every station pad", function()
	for i = 1, 24 do
		local p = Outpost.spawnPoint(i)
		ok(Outpost.inside(p), `spawn {i} inside`)
		eq(Outpost.stationAt(p), nil, `spawn {i} isn't on a station (no free training)`)
	end
	ok(not Outpost.inside(Vector3.new(0, 3, 0)), "the co-op map isn't the camp")
	ok(not Outpost.inside(nil), "nothing")
end)

test("the camp is clear of every track copy (co-op, Camp Clash, Bone Rush grid)", function()
	for n = 1, 10 do
		for _, grid in { false, true } do
			local layout = Sides.new(n, grid)
			for side = 1, n do
				local zone = Sides.zone(layout, side)
				local gap = toRect(flat(Outpost.CENTRE), zone.min, zone.max)
				ok(gap > Outpost.RADIUS + Track.CrossingStrip, `{n} sides (grid {grid}) side {side}: {gap} studs`)
			end
		end
	end
end)

test("camera and home screen: third person only in camp; the menu is always reachable there", function()
	ok(Outpost.thirdPerson(true), "camp: third person allowed")
	ok(not Outpost.thirdPerson(false), "elsewhere: first person")
	ok(not Outpost.thirdPerson(nil), "no attribute: first person")
	for _, collapsed in { false, true } do
		local v = Outpost.homeView("Lobby", true, collapsed, false)
		ok(v.docked and not v.backdrop, "camp: docked over a clear view")
		ok(v.toggle, "the Menu / Hide menu button is always there")
		eq(v.column, not collapsed)
		ok(v.column or v.toggle, "never trapped without the home controls")
	end
	local wait = Outpost.homeView("Playing", true, false, true)
	eq(wait.banner, "top", "a Ranked late joiner waits in camp under a top banner")
	eq(wait.column, false)
	local old = Outpost.homeView("Lobby", false, false, false)
	ok(old.backdrop and old.column and not old.docked, "still spawning: the old full home screen")
	eq(Outpost.homeView("Playing", false, false, true).banner, "centre")
	eq(Outpost.homeView("Playing", false, false, false).column, false, "in a match: no home screen")
	ok(Outpost.waitsInCamp("Lobby", true), "Lobby: everyone in camp")
	ok(Outpost.waitsInCamp("Playing", false), "not seated: waits in camp")
	ok(not Outpost.waitsInCamp("Playing", true), "never pulled out of a match")
end)

test("wiring: no combat in camp, Play moves people out, results bring them back", function()
	local main = fs.readFile("src/server/Main.server.luau")
	local hero = fs.readFile("src/server/Hero.luau")
	local kit = fs.readFile("src/server/Kit.luau")
	local client = fs.readFile("src/client/Hero.client.luau")
	local outpost = fs.readFile("src/server/Outpost.luau")
	ok(string.find(main, "setState(\"Lobby\")\n\tOutpost.enterAll()", 1, true), "every Lobby: everyone into camp")
	ok(string.find(main, "if Outpost.spawning(player) then nil else Battle.spawnPoint(player)", 1, true), "a camp arrival never goes to a battle side")
	ok(string.find(main, "Outpost.enter(player) -- waits in the Hunters' Outpost", 1, true), "a refused late joiner waits in camp")
	ok(string.find(hero, "player:GetAttribute(\"Out\") == true or player:GetAttribute(\"InOutpost\") == true", 1, true), "no shots from or at camp")
	ok(string.find(hero, "if not s.hero or player:GetAttribute(\"InOutpost\") == true then", 1, true), "no gun in camp")
	ok(string.find(kit, "player:GetAttribute(\"InOutpost\") ~= true -- no combat", 1, true), "no swings or throws in camp")
	ok(string.find(kit, "other:GetAttribute(\"InOutpost\") ~= true", 1, true), "camp players aren't kit foes")
	ok(string.find(client, "player:GetAttribute(\"Placing\") ~= true and player:GetAttribute(\"InOutpost\") ~= true", 1, true), "first person outside camp")
	ok(string.find(outpost, "if not spawningNow[player] then\n\t\t\t\tplayer:SetAttribute(ATTRIBUTE, false)", 1, true), "any other spawn leaves camp")
end)
