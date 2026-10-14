--[[
	The 4x towers' shared groundwork (PLAN 9g common rules 3-4, DECISIONS #316): the
	4x TOWERS Tuning block, Shared/AutoFire's three triggers (and never on an empty
	track, once per round played), the densest bunch, hard stops on bosses, small dinos
	and the take-down mark radius.
]]

local Config = require(src.shared.Config)
local AutoFire = require(src.shared.AutoFire)
local FourX = require(src.shared.FourX)

local T = Config.Tuning

test("the 4x TOWERS block (seeds)", function()
	eq(T.BossHardStopX, 0.5)
	eq(T.SmallSize, 2)
	eq(T.WallMinBunch, 6)
	eq(T.WallReachStuds, 10)
	eq(T.TakeDownMarkRadius, 6)
	eq(T.RoundSecondsModel, 50)
	eq(T.WalkerCapPerSide, 24)
end)

test("AutoFire: a boss in its area, Wall min bunch dinos, or the round's last spawn; never on an empty track; once per round", function()
	local s = AutoFire.new()
	eq(AutoFire.check(s, false, 5, false, 9), false, "5 in the area, no boss, spawns still coming: wait")
	eq(AutoFire.check(s, true, 1, false, 9), true, "a boss in its area: fire")
	eq(AutoFire.check(s, true, 9, true, 9), false, "once per round")
	AutoFire.reset(s)
	eq(AutoFire.check(s, false, 6, false, 9), true, "6 in its area: fire")
	AutoFire.reset(s)
	eq(AutoFire.check(s, false, 0, true, 3), true, "the last dino has spawned: fire (at the densest bunch)")
	AutoFire.reset(s)
	eq(AutoFire.check(s, true, 6, true, 0), false, "never on an empty track")
	eq(s.fired, false, "and it stays ready")
end)

test("AutoFire.densest: the point with most dinos within Wall reach; ties the furthest along", function()
	eq(AutoFire.densest({ 10, 50, 55, 58, 120 }), 58, "50, 55 and 58 each see 3: the furthest along")
	eq(AutoFire.densest({ 10, 44, 50, 55, 58, 120 }), 50, "50 sees 44..58: 4")
	eq(AutoFire.densest({ 10, 100 }), 100, "tie: the furthest along")
	eq(AutoFire.densest({}), nil)
end)

test("hard stops: bosses x Boss hard stop x unless the option says full; small dinos; take-down mark radius", function()
	eq(FourX.hardStop(2, false), 2)
	eq(FourX.hardStop(2, true), 1, "a boss: half")
	eq(FourX.hardStop(3, true, true), 3, "Living Amber: the full 3 s")
	eq(FourX.hardStop(0, true), 0)
	ok(FourX.isSmall(2, false) and FourX.isSmall(1, false), "last 2 sizes")
	ok(not FourX.isSmall(3, false), "3 sizes left: not small")
	ok(not FourX.isSmall(1, true), "a boss is never small")
	local hits = FourX.markNear(Vector3.new(0, 0, 0), { Vector3.new(5, 9, 0), Vector3.new(7, 0, 0), Vector3.new(0, 0, -6) })
	eq(#hits, 2, "within 6 studs (flat)")
	eq(FourX.takeDownMarkSeconds(), 3)
end)
