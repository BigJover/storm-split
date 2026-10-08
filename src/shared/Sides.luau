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
	  playerSide(side, sides)      -> sideOf with the "Sides" attribute's count
	  density(modeKey, sides)      -> dino count multiplier per side: Tuning BattleSideDensity
	                                  for Royale and 3-side Team, else 1
	  sideCap(cap, sides)          -> each side's share of the shared live-enemy cap
	  manageRefusal(action, mySide, towerSide) -> why "upgrade"/"repair"/"sell" is refused on
	                                  another side's tower, or nil on your own side's
	  attr(name, side)           -> a per-side attribute's name: side 1 keeps today's name
	                                  ("Cash"), side n adds n ("Cash2"); Server/Economy publishes
	  ZONE_REFUSAL               -> a battle build in a rival camp's zone (Shared/Placement, T78)
	  STRIP_REFUSAL              -> a battle build off every zone: the crossing strip (T79b)
	  buildRefusal(zone, point)  -> which of the two a build at `point` (flat X, Z) gets
	  cashRefusal(sides)         -> "Not enough cash" (co-op) / "Not enough cash in your camp."
	  isEnemyTower(mySide, towerSide) -> another camp's tower: its panel is read-only (T78)
]]

local Config = require(script.Parent.Config)
local Modes = require(script.Parent.Modes)
local Track = require(script.Parent.Track)

local Sides = {}

export type Rect = { min: Vector2, max: Vector2 }

export type Zone = {
	side: number,
	offset: Vector3, -- this side's copy = the co-op map moved by this much
	min: Vector2, -- the build zone, flat (X, Z)
	max: Vector2,
	battle: boolean, -- more than one side in the match
	rivals: { Rect }, -- every other side's build zone (which refusal a build outside yours gets)
}

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
	local rects: { Rect } = {}
	for side = 1, n do
		local column, row = (side - 1) % columns, (side - 1) // columns
		local shift = flat(Vector3.new(column * stepX, 0, row * stepZ))
		rects[side] = table.freeze({ min = area.Min + shift, max = area.Max + shift })
	end
	for side = 1, n do
		local column, row = (side - 1) % columns, (side - 1) // columns
		local offset = Vector3.new(column * stepX, 0, row * stepZ)
		local rivals: { Rect } = {}
		for other, rect in rects do
			if other ~= side then
				table.insert(rivals, rect)
			end
		end
		zones[side] = table.freeze({
			side = side,
			offset = offset,
			min = rects[side].min,
			max = rects[side].max,
			battle = n > 1,
			rivals = table.freeze(rivals),
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

-- A hunter's side from their "Side" attribute and ReplicatedStorage's "Sides" (bad or
-- missing = 1, co-op).
function Sides.playerSide(sideValue: unknown, sidesValue: unknown): number
	return Sides.sideOf(sideValue, Sides.fromAttributes(sidesValue, nil).sides)
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

-- Why a hunter on `mySide` may not upgrade / repair / sell a tower on `towerSide`, or nil
-- when they may: only their own side's towers (a teammate's too), never an enemy's
-- (PLAN T76, DECISIONS #211, #212). Selling stays the builder's on top of this (Server/Shop).
-- The exact refusal strings (PLAN T78, DECISIONS #231).
local MANAGE_REFUSALS = table.freeze({
	upgrade = "You can't upgrade another camp's tower.",
	repair = "You can't repair another camp's tower.",
	sell = "You can't sell another camp's tower.",
})
-- A battle build outside your own zone (Shared/Placement; PLAN T78).
Sides.ZONE_REFUSAL = "That's another camp's zone. Build inside your own camp."
-- A battle build off every camp's zone: the crossing strip or past the map (T79b, #232).
Sides.STRIP_REFUSAL = "You can only build inside your own camp."

-- Why a battle build at `point` outside `zone` is refused: a rival's zone or open ground.
function Sides.buildRefusal(zone: Zone, point: Vector2): string
	for _, rect in zone.rivals do
		if point.X >= rect.min.X and point.X <= rect.max.X and point.Y >= rect.min.Y and point.Y <= rect.max.Y then
			return Sides.ZONE_REFUSAL
		end
	end
	return Sides.STRIP_REFUSAL
end

function Sides.manageRefusal(action: string, mySide: number, towerSide: number): string?
	if mySide == towerSide then
		return nil
	end
	return MANAGE_REFUSALS[action] or "That's another camp's tower"
end

-- Another camp's tower: the tower panel is read-only on it (PLAN T78).
function Sides.isEnemyTower(mySide: number, towerSide: number): boolean
	return mySide ~= towerSide
end

-- Not enough of your side's cash: co-op keeps its words; a battle says whose cash (T78).
function Sides.cashRefusal(sides: number): string
	return if sides > 1 then "Not enough cash in your camp." else "Not enough cash"
end

function Sides.attr(name: string, side: number): string
	return if side == 1 then name else `{name}{side}`
end

return Sides
