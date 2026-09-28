--[[
	Track layout. Hand-authored (not generated) — this is level design, not balance.

	The map is built at runtime from these values by MapBuilder, so a fresh
	Baseplate place needs zero manual building: sync with Rojo and press Play.

	Units are studs. Y = 0 is the top of the default Baseplate.
]]

return table.freeze({
	-- Enemies walk these in order. Serpentine: four lanes, 30 studs apart.
	Waypoints = {
		Vector3.new(-80, 0, -45),
		Vector3.new(60, 0, -45),
		Vector3.new(60, 0, -15),
		Vector3.new(-60, 0, -15),
		Vector3.new(-60, 0, 15),
		Vector3.new(60, 0, 15),
		Vector3.new(60, 0, 45),
		Vector3.new(-80, 0, 45),
	},

	-- Tower pads sit between lanes, 15 studs from each neighbouring lane,
	-- so a 20-stud Scout covers a short window of two lanes. Placement matters.
	-- Order: row by row, near to far.
	Pads = {
		Vector3.new(-35, 0, -30),
		Vector3.new(0, 0, -30),
		Vector3.new(35, 0, -30),
		Vector3.new(-35, 0, 0),
		Vector3.new(0, 0, 0),
		Vector3.new(35, 0, 0),
		Vector3.new(-35, 0, 30),
		Vector3.new(0, 0, 30),
		Vector3.new(35, 0, 30),
	},

	LaneWidth = 10,
	PadSize = 6,

	-- Studs per second for a 1.0x speed enemy. Path is ~610 studs, so a Husk
	-- takes ~44s to walk it. NOTE: the spreadsheet's round-length formula
	-- assumes 14s of walk time. Measure the real number in phase 1 and fix
	-- the spreadsheet, not this file.
	BaseEnemySpeed = 14,

	EnemyHeight = 1.5, -- centre height of ground enemies
	FlyingHeight = 9, -- centre height of flying enemies

	Colors = {
		Lane = Color3.fromRGB(92, 84, 110),
		Spawn = Color3.fromRGB(90, 200, 120),
		Exit = Color3.fromRGB(220, 70, 90),
		Pad = Color3.fromRGB(200, 170, 90),
	},
})
