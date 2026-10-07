--[[
	Sides: where each side of a match sits on the map, and the rules that keep sides apart
	(PLAN phase 7 T75/T76, DECISIONS #209, #210, #212). Pure; server and client.

	A side is a build plot with its own copy of the track (Shared/Track), its own build zone,
	Fence, cash and dinos. Co-op is ONE side, and side 1 is always exactly today's map:
	offset zero, Track.Waypoints, Track.BuildArea. Battle copies sit in a row (Team: 2-3
	sides) or a grid of Track.GridRows rows (Royale), Track.CrossingStrip studs of open
	ground (no track) between two build zones. Hunters walk anywhere; they build only in
	their own side's zone (Shared/Placement takes the zone).

	  new(sides, grid?)            -> Layout: zones (one per side), crossing strips
	  fromAttributes(sides, grid)  -> the Layout the ReplicatedStorage attributes "Sides" /
	                                  "SideGrid" describe (missing = co-op, 1 side)
	  gridFor(modeKey)             -> true for a mode with one side per player (Royale)
	  zone(layout, side)           -> that side's Zone (offset, build rect)
	  sideAt(layout, point)        -> the side whose build zone holds the point, or nil
	  waypoints(layout, side)      -> that side's track
	  spawn(layout, side)          -> where that side's hunters spawn (on the ground)
	  sideOf(value, sides)         -> a side number from an attribute (bad/missing = 1)
	  density(modeKey, sides)      -> dino count multiplier per side: Tuning BattleSideDensity
	                                  for Royale and 3-side Team, else 1
	  sideCap(cap, sides)          -> each side's share of the shared live-enemy cap
]]

local Config = require(script.Parent.Config)
local Modes = require(script.Parent.Modes)
local Track = require(script.Parent.Track)

local Sides = {}

export type Zone = {
	side: number,
	offset: Vector3, -- this side's copy = the co-op map moved by this much
	min: Vector2, -- the build zone, flat (X, Z)
	max: Vector2,
	battle: boolean, -- more than one side in the match
}

export type Rect = { min: Vector2, max: Vector2 }

export type Layout = {
	sides: number,
	grid: boolean,
	zones: { Zone },
	crossings: { Rect }, -- open ground between neighbouring zones (no track, no building)
}

local function flat(v: Vector3): Vector2
	return Vector2.new(v.X, v.Z)
end

function Sides.new(sides: number, grid: boolean?): Layout
	local n = math.max(1, math.floor(sides))
	local area = Track.BuildArea
	local size = area.Max - area.Min
	local stepX, stepZ = size.X + Track.CrossingStrip, size.Y + Track.CrossingStrip
	local columns = if grid then math.ceil(n / Track.GridRows) else n

	local zones: { Zone } = {}
	for side = 1, n do
		local column, row = (side - 1) % columns, (side - 1) // columns
		local offset = Vector3.new(column * stepX, 0, row * stepZ)
		local shift = flat(offset)
		zones[side] = table.freeze({
			side = side,
			offset = offset,
			min = area.Min + shift,
			max = area.Max + shift,
			battle = n > 1,
		})
	end

	-- Strips: between neighbours in a row, and between two rows (full width of the upper,
	-- which is never the shorter one).
	local crossings: { Rect } = {}
	for side = 1, n do
		local column = (side - 1) % columns
		local right = zones[side + 1]
		if right and column < columns - 1 then
			local a = zones[side]
			table.insert(crossings, table.freeze({ min = Vector2.new(a.max.X, a.min.Y), max = Vector2.new(right.min.X, a.max.Y) }))
		end
	end
	local rows = (n - 1) // columns + 1
	for row = 0, rows - 2 do
		local first, last = zones[row * columns + 1], zones[math.min(n, (row + 1) * columns)]
		local below = zones[(row + 1) * columns + 1]
		table.insert(crossings, table.freeze({ min = Vector2.new(first.min.X, first.max.Y), max = Vector2.new(last.max.X, below.min.Y) }))
	end

	return table.freeze({ sides = n, grid = grid == true, zones = table.freeze(zones), crossings = table.freeze(crossings) })
end

function Sides.fromAttributes(sides: unknown, grid: unknown): Layout
	local n = if typeof(sides) == "number" and sides == sides and sides >= 1 then math.floor(sides) else 1
	return Sides.new(n, grid == true)
end

function Sides.gridFor(modeKey: string): boolean
	local mode = Modes.Modes[modeKey]
	return mode ~= nil and mode.sides == "perPlayer"
end

function Sides.zone(layout: Layout, side: number): Zone
	return layout.zones[side] or layout.zones[1]
end

function Sides.sideAt(layout: Layout, point: Vector3): number?
	local p = flat(point)
	for _, zone in layout.zones do
		if p.X >= zone.min.X and p.X <= zone.max.X and p.Y >= zone.min.Y and p.Y <= zone.max.Y then
			return zone.side
		end
	end
	return nil
end

function Sides.waypoints(layout: Layout, side: number): { Vector3 }
	local offset = Sides.zone(layout, side).offset
	local points = {}
	for i, point in Track.Waypoints do
		points[i] = point + offset
	end
	return points
end

function Sides.spawn(layout: Layout, side: number): Vector3
	local offset = Sides.zone(layout, side).offset
	return Vector3.new(Track.SideSpawn.X, Track.GroundTop, Track.SideSpawn.Z) + offset
end

function Sides.sideOf(value: unknown, sides: number): number
	if typeof(value) == "number" and value == math.floor(value) and value >= 1 and value <= sides then
		return value
	end
	return 1
end

function Sides.density(modeKey: string, sides: number): number
	if sides <= 1 then
		return 1
	elseif Sides.gridFor(modeKey) or (modeKey == "TEAM" and sides >= 3) then
		return Config.Tuning.BattleSideDensity
	end
	return 1
end

function Sides.sideCap(cap: number, sides: number): number
	return math.max(1, math.floor(cap / math.max(1, sides)))
end

return Sides
