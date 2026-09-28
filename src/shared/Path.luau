--[[
	Path math. Enemies are not physics objects and do not pathfind: each one is
	just a distance along this polyline, and its world position is sampled from
	that distance every frame. This is why 100+ enemies are cheap, and why a
	split child can appear exactly where its parent died.
]]

local Path = {}
Path.__index = Path

export type Path = typeof(setmetatable(
	{} :: {
		points: { Vector3 },
		cumulative: { number },
		length: number,
	},
	Path
))

function Path.new(points: { Vector3 }): Path
	assert(#points >= 2, "Path needs at least two waypoints")

	local cumulative = { 0 }
	local total = 0
	for i = 2, #points do
		local segment = (points[i] - points[i - 1]).Magnitude
		assert(segment > 0, `Waypoints {i - 1} and {i} are identical`)
		total += segment
		cumulative[i] = total
	end

	return setmetatable({
		points = points,
		cumulative = cumulative,
		length = total,
	}, Path)
end

-- World position and unit facing direction at `distance` studs along the path.
function Path.sample(self: Path, distance: number): (Vector3, Vector3)
	local points, cumulative = self.points, self.cumulative
	local n = #points

	if distance <= 0 then
		return points[1], (points[2] - points[1]).Unit
	end
	if distance >= self.length then
		return points[n], (points[n] - points[n - 1]).Unit
	end

	-- Linear scan is fine for a handful of waypoints. Swap for a binary
	-- search if a track ever grows past ~50 points.
	for i = 2, n do
		if cumulative[i] >= distance then
			local a, b = points[i - 1], points[i]
			local t = (distance - cumulative[i - 1]) / (cumulative[i] - cumulative[i - 1])
			return a:Lerp(b, t), (b - a).Unit
		end
	end

	return points[n], (points[n] - points[n - 1]).Unit
end

return Path
