--[[
	Builds the playable map at runtime from Shared.Track.

	Doing this in code (instead of hand-building in Studio) keeps the whole
	level in git and means a fresh Baseplate place works immediately. Swap in
	a hand-built map later by giving MapBuilder a Workspace model to read
	waypoints and pads from instead.
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
	pads: { BasePart },
	enemyFolder: Folder,
	towerFolder: Folder,
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

	-- Lanes. Each segment is lengthened by one lane width so corners overlap cleanly.
	local lanes = folder("Lanes", root)
	for i = 2, #points do
		local a, b = points[i - 1] + GROUND_LIFT, points[i] + GROUND_LIFT
		local length = (b - a).Magnitude
		makePart(
			`Lane{i - 1}`,
			Vector3.new(Track.LaneWidth, 0.4, length + Track.LaneWidth),
			CFrame.lookAt((a + b) / 2, b),
			Track.Colors.Lane,
			lanes
		)
	end

	-- Spawn and exit markers.
	local first, last = points[1], points[#points]
	local spawnMarker = makePart("Spawn", Vector3.new(12, 1, 12), CFrame.new(first + Vector3.new(0, 0.5, 0)), Track.Colors.Spawn, root)
	spawnMarker.Material = Enum.Material.Neon
	spawnMarker.CanCollide = false
	local exitMarker = makePart("Exit", Vector3.new(12, 1, 12), CFrame.new(last + Vector3.new(0, 0.5, 0)), Track.Colors.Exit, root)
	exitMarker.Material = Enum.Material.Neon
	exitMarker.CanCollide = false

	-- Tower pads.
	local padFolder = folder("Pads", root)
	local pads = {}
	for i, position in Track.Pads do
		local pad = makePart(
			`Pad{i}`,
			Vector3.new(Track.PadSize, 0.6, Track.PadSize),
			CFrame.new(position + Vector3.new(0, 0.3, 0)),
			Track.Colors.Pad,
			padFolder
		)
		pad:SetAttribute("PadIndex", i)
		pad:SetAttribute("Occupied", false)
		pads[i] = pad
	end

	local enemyFolder = folder("Enemies", root)
	local towerFolder = folder("Towers", root)

	root.Parent = workspace

	return {
		root = root,
		path = path,
		pads = pads,
		enemyFolder = enemyFolder,
		towerFolder = towerFolder,
	}
end

return MapBuilder
