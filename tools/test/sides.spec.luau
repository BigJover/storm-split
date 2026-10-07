--[[
	Map sides (PLAN phase 7 T75, DECISIONS #209, #210): Shared/Sides layouts, build zones,
	crossing strips, spawns, and Shared/Placement's zone check. Co-op (one side) must be
	exactly today's map and today's placement rule.
]]

local Config = require(src.shared.Config)
local Placement = require(src.shared.Placement)
local Sides = require(src.shared.Sides)
local Track = require(src.shared.Track)

local function flat(v: Vector3): Vector2
	return Vector2.new(v.X, v.Z)
end

-- Today's (pre-T75) placement rule, copied from 4b2a3bc's Shared/Placement.check without
-- the pool part, as the reference co-op must keep matching.
local function oldCheck(position: Vector3, others: { Vector3 }, onTrack: boolean?): (boolean, string?)
	local function distanceToRect(p: Vector2, center: Vector2, axis: Vector2, halfLength: number, halfWidth: number): number
		local offset = p - center
		local along = math.abs(offset:Dot(axis))
		local across = math.abs(offset.X * -axis.Y + offset.Y * axis.X)
		local dx = math.max(along - halfLength, 0)
		local dz = math.max(across - halfWidth, 0)
		return math.sqrt(dx * dx + dz * dz)
	end
	local p = flat(position)
	local area = Track.BuildArea
	if p.X < area.Min.X or p.X > area.Max.X or p.Y < area.Min.Y or p.Y > area.Max.Y then
		return false, "Outside the build area"
	end
	local points = Track.Waypoints
	local lanes, markers = {}, {}
	for i = 2, #points do
		local a, b = flat(points[i - 1]), flat(points[i])
		table.insert(lanes, { (a + b) / 2, (b - a).Unit, ((b - a).Magnitude + Track.LaneWidth) / 2, Track.LaneWidth / 2 })
	end
	for _, point in { points[1], points[#points] } do
		table.insert(markers, { flat(point), Vector2.new(1, 0), Track.MarkerSize / 2, Track.MarkerSize / 2 })
	end
	if onTrack then
		local onLane = false
		for _, r in lanes do
			if distanceToRect(p, r[1], r[2], r[3], r[4]) <= 0 then
				onLane = true
			end
		end
		if not onLane then
			return false, "Must go on the track"
		end
		for _, r in markers do
			if distanceToRect(p, r[1], r[2], r[3], r[4]) <= 0 then
				return false, "Not on the spawn or exit"
			end
		end
	else
		for _, list in { lanes, markers } do
			for _, r in list do
				if distanceToRect(p, r[1], r[2], r[3], r[4]) < Track.TowerRadius then
					return false, "Too close to the track"
				end
			end
		end
	end
	for _, other in others do
		if (flat(other) - p).Magnitude < Track.TowerRadius * 2 then
			return false, "Overlaps another tower"
		end
	end
	return true, nil
end

-- Every spot on a 2.5-stud grid over the build area and 20 studs past it.
local function grid(each: (Vector3) -> ())
	local area = Track.BuildArea
	for x = area.Min.X - 20, area.Max.X + 20, 2.5 do
		for z = area.Min.Y - 20, area.Max.Y + 20, 2.5 do
			each(Vector3.new(x, Track.GroundTop, z))
		end
	end
end

-- The XZ box a side's track covers (lanes are lengthened by a lane width; the spawn and
-- exit squares).
local function trackBox(layout: Sides.Layout, side: number): (Vector2, Vector2)
	local lo, hi = Vector2.new(math.huge, math.huge), Vector2.new(-math.huge, -math.huge)
	local pad = math.max(Track.LaneWidth, Track.MarkerSize) / 2
	for _, point in Sides.waypoints(layout, side) do
		local p = flat(point)
		lo = Vector2.new(math.min(lo.X, p.X - pad), math.min(lo.Y, p.Y - pad))
		hi = Vector2.new(math.max(hi.X, p.X + pad), math.max(hi.Y, p.Y + pad))
	end
	return lo, hi
end

-- Gap between two XZ boxes (0 when they touch or overlap).
local function gap(aMin: Vector2, aMax: Vector2, bMin: Vector2, bMax: Vector2): number
	local dx = math.max(bMin.X - aMax.X, aMin.X - bMax.X, 0)
	local dz = math.max(bMin.Y - aMax.Y, aMin.Y - bMax.Y, 0)
	return math.max(dx, dz)
end

local function overlaps(aMin: Vector2, aMax: Vector2, bMin: Vector2, bMax: Vector2): boolean
	return aMin.X < bMax.X and bMin.X < aMax.X and aMin.Y < bMax.Y and bMin.Y < aMax.Y
end

local function touches(aMin: Vector2, aMax: Vector2, bMin: Vector2, bMax: Vector2): boolean
	return aMin.X <= bMax.X and bMin.X <= aMax.X and aMin.Y <= bMax.Y and bMin.Y <= aMax.Y
end

-- Every layout a match can have: co-op, Team 2/3 in a row, Royale 2-10 in a grid.
local function everyLayout(): { Sides.Layout }
	local list = { Sides.new(1), Sides.new(2), Sides.new(3) }
	for n = 2, Config.Tuning.BattleMaxPlayers do
		table.insert(list, Sides.new(n, true))
	end
	return list
end

-- Co-op ------------------------------------------------------------------------

test("co-op is one side: today's track, build area and no strips", function()
	local layout = Sides.new(1)
	eq(layout.sides, 1)
	eq(#layout.crossings, 0, "crossings")
	local zone = Sides.zone(layout, 1)
	eq(zone.offset, Vector3.zero, "offset")
	eq(zone.min, Track.BuildArea.Min, "zone min")
	eq(zone.max, Track.BuildArea.Max, "zone max")
	eq(zone.battle, false, "battle")
	local points = Sides.waypoints(layout, 1)
	eq(#points, #Track.Waypoints, "waypoint count")
	for i, point in Track.Waypoints do
		eq(points[i], point, `waypoint {i}`)
	end
	-- No attributes published (a fresh server) is co-op too.
	eq(Sides.fromAttributes(nil, nil).sides, 1, "no attributes")
	eq(Sides.zone(Sides.fromAttributes(nil, nil), 1).offset, Vector3.zero)
end)

test("co-op placement is exactly today's rule, with or without the zone", function()
	local zone = Sides.zone(Sides.new(1), 1)
	local others = { Vector3.new(0, Track.GroundTop, 0), Vector3.new(-100, Track.GroundTop, 60) }
	local checked = 0
	for _, onTrack in { false, true } do
		grid(function(p)
			local wantOk, wantWhy = oldCheck(p, others, onTrack)
			local gotOk, gotWhy = Placement.check(p, others, onTrack)
			local zoneOk, zoneWhy = Placement.check(p, others, onTrack, zone)
			if gotOk ~= wantOk or gotWhy ~= wantWhy or zoneOk ~= wantOk or zoneWhy ~= wantWhy then
				error(`{p}: old {wantOk}/{wantWhy}, now {gotOk}/{gotWhy}, zone {zoneOk}/{zoneWhy}`)
			end
			checked += 1
		end)
	end
	ok(checked > 5000, `spots checked ({checked})`)
end)

-- Battle layouts ------------------------------------------------------------------

test("Team sides sit in a row, Royale in a two-row grid; side 1 never moves", function()
	local step = Track.BuildArea.Max - Track.BuildArea.Min + Vector2.new(Track.CrossingStrip, Track.CrossingStrip)
	local three = Sides.new(3)
	for side = 1, 3 do
		eq(Sides.zone(three, side).offset, Vector3.new((side - 1) * step.X, 0, 0), `team side {side}`)
	end
	local ten = Sides.new(10, true)
	eq(Sides.zone(ten, 1).offset, Vector3.zero, "royale side 1")
	eq(Sides.zone(ten, 5).offset, Vector3.new(4 * step.X, 0, 0), "royale side 5 (end of row 1)")
	eq(Sides.zone(ten, 6).offset, Vector3.new(0, 0, step.Y), "royale side 6 (row 2)")
	eq(Sides.zone(ten, 10).offset, Vector3.new(4 * step.X, 0, step.Y), "royale side 10")
	eq(Sides.zone(Sides.new(3, true), 3).offset, Vector3.new(0, 0, step.Y), "royale of 3: side 3 starts row 2")
	eq(Sides.zone(three, 2).battle, true, "a battle zone knows it")
	eq(Sides.gridFor("ROYALE"), true)
	eq(Sides.gridFor("TEAM"), false)
	eq(Sides.gridFor("COOP"), false)
end)

test("zones never overlap and never touch another side's track", function()
	for _, layout in everyLayout() do
		for a = 1, layout.sides do
			local za = Sides.zone(layout, a)
			local tMin, tMax = trackBox(layout, a)
			ok(tMin.X >= za.min.X and tMax.X <= za.max.X and tMin.Y >= za.min.Y and tMax.Y <= za.max.Y, `{layout.sides}: side {a}'s track inside its zone`)
			for b = 1, layout.sides do
				if a ~= b then
					local zb = Sides.zone(layout, b)
					ok(gap(za.min, za.max, zb.min, zb.max) >= Track.CrossingStrip, `{layout.sides}: zones {a}/{b} a strip apart`)
					local oMin, oMax = trackBox(layout, b)
					ok(gap(za.min, za.max, oMin, oMax) >= Track.CrossingStrip, `{layout.sides}: zone {a} clear of track {b}`)
				end
			end
		end
	end
end)

test("crossing strips join neighbouring zones and hold no zone or track", function()
	for _, layout in everyLayout() do
		if layout.sides > 1 then
			ok(#layout.crossings > 0, `{layout.sides}: has strips`)
		end
		for i, strip in layout.crossings do
			local joined = 0
			for side = 1, layout.sides do
				local zone = Sides.zone(layout, side)
				ok(not overlaps(strip.min, strip.max, zone.min, zone.max), `{layout.sides}: strip {i} not on zone {side}`)
				local tMin, tMax = trackBox(layout, side)
				ok(not overlaps(strip.min, strip.max, tMin, tMax), `{layout.sides}: strip {i} has no track`)
				if touches(strip.min, strip.max, zone.min, zone.max) then
					joined += 1
				end
			end
			ok(joined >= 2, `{layout.sides}: strip {i} joins two zones`)
			ok(math.min(strip.max.X - strip.min.X, strip.max.Y - strip.min.Y) == Track.CrossingStrip, `{layout.sides}: strip {i} is a strip wide`)
		end
		-- Every zone reaches a strip, so every hunter can cross.
		for side = 1, layout.sides do
			if layout.sides > 1 then
				local zone, reached = Sides.zone(layout, side), false
				for _, strip in layout.crossings do
					reached = reached or touches(strip.min, strip.max, zone.min, zone.max)
				end
				ok(reached, `{layout.sides}: side {side} reaches a strip`)
			end
		end
	end
end)

test("each side's spawn is on its own ground, off the track", function()
	for _, layout in everyLayout() do
		for side = 1, layout.sides do
			local spawn = Sides.spawn(layout, side)
			eq(Sides.sideAt(layout, spawn), side, `{layout.sides}: spawn {side}'s zone`)
			eq((Placement.check(spawn, {}, false, Sides.zone(layout, side))), true, `{layout.sides}: spawn {side} off the track`)
		end
	end
end)

test("every side's copy places exactly like co-op's map", function()
	local layout = Sides.new(10, true)
	for _, side in { 2, 5, 6, 10 } do
		local zone = Sides.zone(layout, side)
		for _, onTrack in { false, true } do
			grid(function(p)
				local wantOk, wantWhy = Placement.check(p, {}, onTrack)
				local gotOk, gotWhy = Placement.check(p + zone.offset, {}, onTrack, zone)
				if wantWhy == "Outside the build area" then
					wantWhy = "Outside your build zone"
				end
				if gotOk ~= wantOk or gotWhy ~= wantWhy then
					error(`side {side} at {p}: co-op {wantOk}/{wantWhy}, side {gotOk}/{gotWhy}`)
				end
			end)
		end
	end
end)

test("a ghost outside your zone is refused, the same rule client and server", function()
	local layout = Sides.new(2)
	local mine, theirs = Sides.zone(layout, 1), Sides.zone(layout, 2)
	local spot = Vector3.new(0, Track.GroundTop, 0) + theirs.offset -- open ground on side 2
	local fits, why = Placement.check(spot, {}, false, mine)
	eq(fits, false, "side 1 builds on side 2")
	eq(why, "Outside your build zone")
	eq((Placement.check(spot, {}, false, theirs)), true, "side 2 builds there")
	-- The crossing strip is nobody's.
	local strip = layout.crossings[1]
	local middle = (strip.min + strip.max) / 2
	local onStrip = Vector3.new(middle.X, Track.GroundTop, middle.Y)
	eq(Sides.sideAt(layout, onStrip), nil, "the strip is no side's")
	eq((Placement.check(onStrip, {}, false, mine)), false, "strip, side 1")
	eq((Placement.check(onStrip, {}, false, theirs)), false, "strip, side 2")
	-- A Tar Pit goes only on its own side's track.
	local theirLane = Vector3.new(0, Track.GroundTop, -45) + theirs.offset
	eq((Placement.check(theirLane, {}, true, theirs)), true, "pit on side 2's lane by side 2")
	eq((Placement.check(theirLane, {}, true, mine)), false, "pit on side 2's lane by side 1")
	-- Overlap is world-wide: a tower right at the zone edge still blocks.
	local edge = Vector3.new(theirs.min.X + 1, Track.GroundTop, 0)
	eq((Placement.check(edge, { edge + Vector3.new(1, 0, 0) }, false, theirs)), false, "overlap on side 2")
end)

-- Small rules ------------------------------------------------------------------------

test("a side from an attribute: bad or missing is side 1", function()
	eq(Sides.sideOf(2, 3), 2)
	eq(Sides.sideOf(3, 3), 3)
	eq(Sides.sideOf(4, 3), 1, "past the last side")
	eq(Sides.sideOf(0, 3), 1)
	eq(Sides.sideOf(1.5, 3), 1)
	eq(Sides.sideOf(nil, 3), 1)
	eq(Sides.sideOf("2", 3), 1)
	eq(Sides.sideOf(0 / 0, 3), 1, "NaN")
	eq(Sides.fromAttributes(3, false).sides, 3)
	eq(Sides.fromAttributes(4, true).grid, true)
	eq(Sides.fromAttributes(0 / 0, nil).sides, 1, "NaN sides")
end)

test("density: Royale and 3-side Team thin each side, co-op and 2-side Team don't", function()
	local d = Config.Tuning.BattleSideDensity
	eq(d, 0.6, "the seed")
	eq(Sides.density("COOP", 1), 1)
	eq(Sides.density("TEAM", 2), 1)
	eq(Sides.density("TEAM", 3), d)
	eq(Sides.density("ROYALE", 2), d)
	eq(Sides.density("ROYALE", 10), d)
end)

test("the live cap is shared and split evenly", function()
	local cap = Config.Tuning.MaxConcurrentEnemies
	eq(Sides.sideCap(cap, 1), cap, "co-op keeps the whole cap")
	eq(Sides.sideCap(130, 2), 65)
	eq(Sides.sideCap(130, 3), 43)
	eq(Sides.sideCap(130, 10), 13)
	eq(Sides.sideCap(5, 10), 1, "never zero")
end)
