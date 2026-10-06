--[[
	Harpoon Ballista rules (PLAN T66, UPGRADES.md "Harpoon Ballista"). Pure, so specs run
	headlessly; Server/Towers applies them.

	  volley       which dino each bolt of a volley flies at. Bolts spread (Spread Volley):
	              bolt i at the i-th dino furthest along the track in range, starting again
	              from the first when there are fewer dinos than bolts. With Chain Harpoons
	              the bolts fly in pairs and a pair spans the crowd: the first bolt of pair k
	              at the k-th dino from the front, its partner at the k-th from the back
	  pairs        Chain Harpoons: bolts 1-2, 3-4, ... are linked; an odd last bolt flies alone
	  onLine       the dinos within Tuning Bolt width (flat distance, so fliers count) of a
	              straight segment, nearest the start first: Skewer's line (from the muzzle
	              through the target out to the tower's range) and a chain between a pair
	  lineEnd      where Skewer's line ends: the tower's range along the bolt's heading,
	              never short of the target
	  towPick      Tow Line: the boss furthest along the track in range (nil: none, the
	              pull stays ready)
	  movesBoss    whether a knockback may move this dino: never a boss, except Tow Line's
	              pull (the explicit exception, PLAN T66)
]]

local Config = require(script.Parent.Config)

local Ballista = {}

-- Candidates' distances along the track, furthest first (ties: the earlier in the list).
local function byDistance(distances: { number }): { number }
	local order = {}
	for i in distances do
		table.insert(order, i)
	end
	table.sort(order, function(a, b)
		if distances[a] ~= distances[b] then
			return distances[a] > distances[b]
		end
		return a < b
	end)
	return order
end

-- `distances`: each candidate's distance along the track. Returns one candidate index per
-- bolt (an empty list when there's nothing in range).
function Ballista.volley(distances: { number }, bolts: number, chained: boolean?): { number }
	local order = byDistance(distances)
	local n = #order
	local out = {}
	if n == 0 then
		return out
	end
	for i = 1, math.max(1, math.floor(bolts)) do
		if chained then
			local k = math.floor((i - 1) / 2) -- pair index from 0
			local slot = if i % 2 == 1 then k % n + 1 else n - (k % n)
			table.insert(out, order[slot])
		else
			table.insert(out, order[(i - 1) % n + 1])
		end
	end
	return out
end

-- Bolt index pairs linked by a chain: {1, 2}, {3, 4}, ...
function Ballista.pairs(bolts: number): { { number } }
	local out = {}
	for i = 1, math.floor(bolts) - 1, 2 do
		table.insert(out, { i, i + 1 })
	end
	return out
end

local function flat(v: Vector3): Vector2
	return Vector2.new(v.X, v.Z)
end

-- Indices of `points` within `width` (flat) of the segment from `from` to `to`, nearest
-- `from` first.
function Ballista.onLine(points: { Vector3 }, from: Vector3, to: Vector3, width: number?): { number }
	local w = width or Config.Tuning.BoltWidth
	local a, b = flat(from), flat(to)
	local ab = b - a
	local len2 = ab:Dot(ab)
	local found, along = {}, {}
	for i, p in points do
		local ap = flat(p) - a
		local t = if len2 > 0 then math.clamp(ap:Dot(ab) / len2, 0, 1) else 0
		if (ap - ab * t).Magnitude <= w then
			table.insert(found, i)
			along[i] = t
		end
	end
	table.sort(found, function(x, y)
		if along[x] ~= along[y] then
			return along[x] < along[y]
		end
		return x < y
	end)
	return found
end

-- Skewer's line: from the muzzle through the target, `range` long (flat), never short of
-- the target.
function Ballista.lineEnd(from: Vector3, through: Vector3, range: number): Vector3
	local d = flat(through) - flat(from)
	local len = d.Magnitude
	if len <= 0 then
		return through
	end
	local reach = math.max(len, range)
	local unit = d / len
	return Vector3.new(from.X + unit.X * reach, through.Y, from.Z + unit.Y * reach)
end

-- Tow Line: `distances[i]` along the track, `bosses[i]` true for a boss. Returns an index
-- or nil.
function Ballista.towPick(distances: { number }, bosses: { [number]: boolean }): number?
	local best = nil
	for i, d in distances do
		if bosses[i] and (best == nil or d > distances[best]) then
			best = i
		end
	end
	return best
end

-- Bosses are too heavy to knock back; only Tow Line's pull moves one.
function Ballista.movesBoss(isBoss: boolean, towLine: boolean?): boolean
	return not isBoss or towLine == true
end

return Ballista
