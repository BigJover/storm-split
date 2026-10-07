--[[
	Builds the playable map at runtime from Shared.Track.

	Doing this in code (instead of hand-building in Studio) keeps the whole
	level in git and means a fresh Baseplate place works immediately. Swap in
	a hand-built map later by giving MapBuilder a Workspace model to read
	waypoints from instead.

	SIDES (PLAN T75): one copy of the track, build floor and markers per side of the
	match (Shared/Sides), plus the crossing strips between them. Co-op is one side and
	builds exactly the one map it always has.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Track = require(Shared:WaitForChild("Track"))
local Path = require(Shared:WaitForChild("Path"))
local Sides = require(Shared:WaitForChild("Sides"))

local MapBuilder = {}

local MAP_NAME = "StormSplitMap"
local GROUND_LIFT = Vector3.new(0, 0.2, 0)

local function makePart(name: string, size: Vector3, cframe: CFrame, color: Color3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function folder(name: string, parent: Instance): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

export type Map = {
	root: Folder,
	path: Path.Path, -- side 1's track (co-op's only track)
	paths: { Path.Path }, -- one per side (Shared/Sides)
	layout: Sides.Layout,
	enemyFolder: Folder,
	towerFolder: Folder,
	effectFolder: Folder,
}

local function floorPart(name: string, min: Vector2, max: Vector2, color: Color3, parent: Instance): Part
	local size = max - min
	local centre = (min + max) / 2
	local floorThickness = 0.2
	local floor = makePart(
		name,
		Vector3.new(size.X, floorThickness, size.Y),
		CFrame.new(centre.X, Track.GroundTop - floorThickness / 2, centre.Y),
		color,
		parent
	)
	floor.Material = Enum.Material.Grass
	return floor
end

-- One side's build floor, lanes and markers. Side 1 keeps co-op's part names exactly;
-- side n > 1 adds n ("BuildArea2", "Lanes2", "Spawn2", "Exit2").
local function buildSide(layout: Sides.Layout, side: number, root: Instance): Path.Path
	local suffix = if side == 1 then "" else tostring(side)
	local zone = Sides.zone(layout, side)
	local points = Sides.waypoints(layout, side)
	local path = Path.new(points)

	-- Build-area floor: everything on it that isn't track can hold a tower.
	floorPart(`BuildArea{suffix}`, zone.min, zone.max, Track.Colors.BuildGround, root)

	-- Lanes. Each segment is lengthened by one lane width so corners overlap cleanly.
	local lanes = folder(`Lanes{suffix}`, root)
	for i = 2, #points do
		local a, b = points[i - 1] + GROUND_LIFT, points[i] + GROUND_LIFT
		local length = (b - a).Magnitude
		local lane = makePart(
			`Lane{i - 1}`,
			Vector3.new(Track.LaneWidth, 0.4, length + Track.LaneWidth),
			CFrame.lookAt((a + b) / 2, b),
			Track.Colors.Lane,
			lanes
		)
		lane.Material = Enum.Material.Ground -- a dirt trail
	end

	-- Spawn and exit markers.
	local first, last = points[1], points[#points]
	local markerSize = Vector3.new(Track.MarkerSize, 1, Track.MarkerSize)
	local spawnMarker = makePart(`Spawn{suffix}`, markerSize, CFrame.new(first + Vector3.new(0, 0.5, 0)), Track.Colors.Spawn, root)
	spawnMarker.Material = Enum.Material.Neon
	spawnMarker.CanCollide = false
	local exitMarker = makePart(`Exit{suffix}`, markerSize, CFrame.new(last + Vector3.new(0, 0.5, 0)), Track.Colors.Exit, root)
	exitMarker.Material = Enum.Material.Neon
	exitMarker.CanCollide = false

	return path
end

-- Every side's floor, lanes and markers, and the crossing strips, under `root`.
local function buildGround(sides: Sides.Layout, root: Instance): { Path.Path }
	local paths = {}
	for side = 1, sides.sides do
		paths[side] = buildSide(sides, side, root)
	end
	-- The open ground between sides (battle modes only): walkable, no track.
	for i, strip in sides.crossings do
		floorPart(`Crossing{i}`, strip.min, strip.max, Track.Colors.BuildGround, root)
	end
	-- Clients and Shop read the layout back with Shared/Sides.fromAttributes.
	ReplicatedStorage:SetAttribute("Sides", sides.sides)
	ReplicatedStorage:SetAttribute("SideGrid", sides.grid)
	return paths
end

-- `layout`: the match's sides (Shared/Sides); none = co-op, today's one-side map.
function MapBuilder.build(layout: Sides.Layout?): Map
	local existing = workspace:FindFirstChild(MAP_NAME)
	if existing then
		existing:Destroy()
	end

	local root = Instance.new("Folder")
	root.Name = MAP_NAME

	local sides = layout or Sides.new(1)
	local paths = buildGround(sides, root)

	local enemyFolder = folder("Enemies", root)
	local towerFolder = folder("Towers", root)
	local effectFolder = folder("Effects", root)

	root.Parent = workspace

	return {
		root = root,
		path = paths[1],
		paths = paths,
		layout = sides,
		enemyFolder = enemyFolder,
		towerFolder = towerFolder,
		effectFolder = effectFolder,
	}
end

-- Between matches (PLAN T77): the next match has a different number of sides. Rebuilds
-- the ground only; the Enemies / Towers / Effects folders stay (the modules hold them).
-- The caller then gives Enemies the new paths. Returns false (nothing done) when the
-- layout is the same.
function MapBuilder.relayout(map: Map, layout: Sides.Layout): boolean
	if map.layout.sides == layout.sides and map.layout.grid == layout.grid then
		return false
	end
	local keep = { [map.enemyFolder] = true, [map.towerFolder] = true, [map.effectFolder] = true }
	for _, child in map.root:GetChildren() do
		if not keep[child] then
			child:Destroy()
		end
	end
	local paths = buildGround(layout, map.root)
	map.paths = paths
	map.path = paths[1]
	map.layout = layout
	return true
end

return MapBuilder
