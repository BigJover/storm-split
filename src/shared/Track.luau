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

	LaneWidth = 10,
	MarkerSize = 12, -- spawn and exit squares

	-- Towers can go anywhere in this XZ rectangle that isn't track (Shared/Placement).
	BuildArea = {
		Min = Vector2.new(-110, -75),
		Max = Vector2.new(90, 75),
	},
	GroundTop = 0.1, -- top of the build-area floor; towers stand on it

	-- Keep-out radius around a tower's centre, from lanes and from other towers.
	-- Must cover the tower body (3x3, half-diagonal 2.12 — Shared/TowerLook).
	TowerRadius = 2.25,

	-- Studs per second for a 1.0x speed enemy. Path is ~610 studs, so a Husk
	-- takes ~44s to walk it (the spreadsheet's 14s is clear time after the
	-- last spawn — ARCHITECTURE.md §6).
	BaseEnemySpeed = 14,

	EnemyHeight = 1.5, -- centre height of ground enemies
	FlyingHeight = 9, -- centre height of flying enemies

	Colors = {
		Lane = Color3.fromRGB(92, 84, 110),
		Spawn = Color3.fromRGB(90, 200, 120),
		Exit = Color3.fromRGB(220, 70, 90),
		BuildGround = Color3.fromRGB(86, 124, 78),
	},
})
