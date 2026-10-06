--[[
	Shared/Placement: towers go anywhere off the track, never overlapping; a tower flagged
	On track (the Tar Pit, DECISIONS #152, PLAN T63) goes ON a lane instead, never on the
	spawn or exit square, and never overlapping another tower or pit.
]]

local Config = require(src.shared.Config)
local Placement = require(src.shared.Placement)
local Track = require(src.shared.Track)

local function at(x: number, z: number): Vector3
	return Vector3.new(x, Track.GroundTop, z)
end

test("only the Tar Pit is flagged On track", function()
	for _, key in Config.TowerOrder do
		eq(Config.Towers[key].onTrack, key == "TARPIT", `{key} onTrack`)
	end
end)

test("a pit goes on the track, not off it", function()
	eq((Placement.check(at(0, -45), {}, true)), true, "lane 1 centre line")
	eq((Placement.check(at(0, -41), {}, true)), true, "near the lane's edge, still on it")
	eq((Placement.check(at(60, -30), {}, true)), true, "the bend between lanes 1 and 2")
	local fits, why = Placement.check(at(0, -30), {}, true)
	eq(fits, false, "mid-gap is off the track")
	eq(why, "Must go on the track")
	eq((Placement.check(at(0, -39), {}, true)), false, "just past the lane's edge")
	fits, why = Placement.check(at(-80, -45), {}, true)
	eq(fits, false, "the spawn square")
	eq(why, "Not on the spawn or exit")
	eq((Placement.check(at(-80, 45), {}, true)), false, "the exit square")
end)

test("pits never overlap each other (or any tower)", function()
	local fits, why = Placement.check(at(3, -45), { at(0, -45) }, true)
	eq(fits, false, "3 studs from another pit")
	eq(why, "Overlaps another tower")
	eq((Placement.check(at(2 * Track.TowerRadius, -45), { at(0, -45) }, true)), true, "just clear of it")
	eq((Placement.check(at(0, -41), { at(0, -40 + Track.TowerRadius) }, true)), false, "a pit at the lane edge vs a tower hugging the lane")
end)

test("other towers are unchanged: off the track only", function()
	eq((Placement.check(at(0, -30), {})), true, "mid-gap")
	eq((Placement.check(at(0, -30), {}, false)), true, "On track false = the old rule")
	local fits, why = Placement.check(at(0, -45), {})
	eq(fits, false, "on the lane")
	eq(why, "Too close to the track")
	eq((Placement.check(at(0, -40 + Track.TowerRadius - 0.1), {})), false, "too close to the lane's edge")
	eq((Placement.check(at(0, -40 + Track.TowerRadius), {})), true, "TowerRadius from the edge")
	eq((Placement.check(at(0, -30), { at(4, -30) })), false, "overlapping a tower")
	eq((Placement.check(at(0, -30), { at(0, -45) })), true, "a pit on the lane doesn't block the gap")
end)
