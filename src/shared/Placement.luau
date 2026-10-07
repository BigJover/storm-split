--[[
	Where a tower may stand. Shared so the client colours its ghost with the
	same rule the server enforces — but only the server's answer counts.

	A spot is valid when it is inside Track.BuildArea, at least TowerRadius from
	every lane and the spawn/exit squares, and at least 2 x TowerRadius from
	every other tower. Everything is checked flat, in XZ.

	A tower flagged On track (the Tar Pit, DECISIONS #152) is the exception: its
	centre must be ON a lane (not off it, not on the spawn or exit square), and it
	still never overlaps another tower or pit (2 x TowerRadius), and its pool must not
	overlap another pit's pool at that pool's current length (checkPool, DECISIONS #189).

	SIDES (PLAN T75, DECISIONS #209): `zone` is the builder's side (Shared/Sides). The spot
	must be inside that side's build zone, and the track rules use that side's copy of the
	track, so a Tar Pit only ever goes on its own side's track. No zone = side 1 of co-op,
	which is exactly Track.BuildArea and Track.Waypoints.
]]

local Sides = require(script.Parent.Sides)
local Track = require(script.Parent.Track)
local TarPit = require(script.Parent.TarPit)

local COOP_ZONE = Sides.zone(Sides.new(1), 1)

local Placement = {}

type Rect = { center: Vector2, axis: Vector2, halfLength: number, halfWidth: number }

local function flat(v: Vector3): Vector2
	return Vector2.new(v.X, v.Z)
end

-- Built to match MapBuilder: each lane is a box LaneWidth wide, lengthened by
-- one lane width so corners overlap.
local blocked: { Rect } = {}
local lanes: { Rect } = {} -- the lane boxes only (blocked also has the spawn/exit squares)
local markers: { Rect } = {}
do
	local points = Track.Waypoints
	for i = 2, #points do
		local a, b = flat(points[i - 1]), flat(points[i])
		local lane = {
			center = (a + b) / 2,
			axis = (b - a).Unit,
			halfLength = ((b - a).Magnitude + Track.LaneWidth) / 2,
			halfWidth = Track.LaneWidth / 2,
		}
		table.insert(blocked, lane)
		table.insert(lanes, lane)
	end
	for _, point in { points[1], points[#points] } do
		local marker = {
			center = flat(point),
			axis = Vector2.new(1, 0),
			halfLength = Track.MarkerSize / 2,
			halfWidth = Track.MarkerSize / 2,
		}
		table.insert(blocked, marker)
		table.insert(markers, marker)
	end
end

local function distanceToRect(p: Vector2, rect: Rect): number
	local offset = p - rect.center
	local along = math.abs(offset:Dot(rect.axis))
	local across = math.abs(offset.X * -rect.axis.Y + offset.Y * rect.axis.X)
	local dx = math.max(along - rect.halfLength, 0)
	local dz = math.max(across - rect.halfWidth, 0)
	return math.sqrt(dx * dx + dz * dz)
end

-- The point on the build floor under (x, z). Y from a client is never used.
function Placement.ground(position: Vector3): Vector3
	return Vector3.new(position.X, Track.GroundTop, position.Z)
end

-- `others` are the positions of towers already built (pits included). `onTrack`:
-- the tower's On track flag (Config.Towers[key].onTrack). `zone`: the builder's side.
function Placement.check(position: Vector3, others: { Vector3 }, onTrack: boolean?, zone: Sides.Zone?): (boolean, string?)
	local world = flat(position)
	if world.X ~= world.X or world.Y ~= world.Y then
		return false, "Invalid spot" -- NaN
	end

	local z = zone or COOP_ZONE
	if world.X < z.min.X or world.X > z.max.X or world.Y < z.min.Y or world.Y > z.max.Y then
		return false, if z.battle then Sides.ZONE_REFUSAL else "Outside the build area"
	end
	-- The track rules below run on the co-op track: move the spot back by the side's offset.
	local p = world - flat(z.offset)

	if onTrack then
		local onLane = false
		for _, rect in lanes do
			if distanceToRect(p, rect) <= 0 then
				onLane = true
				break
			end
		end
		if not onLane then
			return false, "Must go on the track"
		end
		for _, rect in markers do
			if distanceToRect(p, rect) <= 0 then
				return false, "Not on the spawn or exit"
			end
		end
	else
		for _, rect in blocked do
			if distanceToRect(p, rect) < Track.TowerRadius then
				return false, "Too close to the track"
			end
		end
	end

	for _, other in others do
		if (flat(other) - world).Magnitude < Track.TowerRadius * 2 then
			return false, "Overlaps another tower"
		end
	end

	return true, nil
end

-- A new pit's pool (centred `at` studs along the track, `length` long) against the pools
-- already on the track. Touching ends are fine; a later Tar Lake may make pools touch or
-- overlap, and then a dino gets only the strongest (Shared/TarPit.strongest).
function Placement.checkPool(at: number, length: number, pools: { TarPit.Pool }): (boolean, string?)
	if TarPit.overlaps(at, length, pools) then
		return false, "Overlaps another tar pool"
	end
	return true, nil
end

return Placement
