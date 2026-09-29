--[[
	Builds the playable map at runtime from Shared.Track.

	Doing this in code (instead of hand-building in Studio) keeps the whole
	level in git and means a fresh Baseplate place works immediately. Swap in
	a hand-built map later by giving MapBuilder a Workspace model to read
	waypoints from instead.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Track = require(Shared:WaitForChild("Track"))
local Path = require(Shared:WaitForChild("Path"))

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
	path: Path.Path,
	enemyFolder: Folder,
	towerFolder: Folder,
	effectFolder: Folder,
}

function MapBuilder.build(): Map
	local existing = workspace:FindFirstChild(MAP_NAME)
	if existing then
		existing:Destroy()
	end

	local root = Instance.new("Folder")
	root.Name = MAP_NAME

	local points = table.clone(Track.Waypoints)
	local path = Path.new(points)

	-- Build-area floor: everything on it that isn't track can hold a tower.
	local area = Track.BuildArea
	local areaSize = area.Max - area.Min
	local areaCentre = (area.Min + area.Max) / 2
	local floorThickness = 0.2
	local floor = makePart(
		"BuildArea",
		Vector3.new(areaSize.X, floorThickness, areaSize.Y),
		CFrame.new(areaCentre.X, Track.GroundTop - floorThickness / 2, areaCentre.Y),
		Track.Colors.BuildGround,
		root
	)
	floor.Material = Enum.Material.Grass

	-- Lanes. Each segment is lengthened by one lane width so corners overlap cleanly.
	local lanes = folder("Lanes", root)
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
	local spawnMarker = makePart("Spawn", markerSize, CFrame.new(first + Vector3.new(0, 0.5, 0)), Track.Colors.Spawn, root)
	spawnMarker.Material = Enum.Material.Neon
	spawnMarker.CanCollide = false
	local exitMarker = makePart("Exit", markerSize, CFrame.new(last + Vector3.new(0, 0.5, 0)), Track.Colors.Exit, root)
	exitMarker.Material = Enum.Material.Neon
	exitMarker.CanCollide = false

	local enemyFolder = folder("Enemies", root)
	local towerFolder = folder("Towers", root)
	local effectFolder = folder("Effects", root)

	root.Parent = workspace

	return {
		root = root,
		path = path,
		enemyFolder = enemyFolder,
		towerFolder = towerFolder,
		effectFolder = effectFolder,
	}
end

return MapBuilder
