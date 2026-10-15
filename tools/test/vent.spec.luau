--[[
	Volcano Vent (PLAN 9i T128, DECISIONS #339): the Towers row and Tuning block, every PLAN row
	(Round-19 names, #339's numbers), and the pure rules in Shared/Vent: the stretch from the
	nearest track point, flow timing, the shove (not bosses) and the walk back, overlapping flows
	(strongest only), crust after the flow, Glass Maze's detour, Frozen Fire once at the flow's
	end, Ring of Fire's turns, Lava Bombs on the biggest, Pressure Valve once per boss; and the
	Near track placement rule (8 studs from the track yes, 12 no).
]]

local Config = require(src.shared.Config)
local Vent = require(src.shared.Vent)
local Placement = require(src.shared.Placement)
local Track = require(src.shared.Track)
local TowerStats = require(src.shared.TowerStats)

local VENT = Config.Towers.VENT
local T = Config.Tuning

local function pathOf(id: string): (any, number)
	for i, path in VENT.paths do
		if path.id == id then
			return path, i
		end
	end
	error(`no path {id}`)
end

local function stats(id: string, tier: number, picks: string?)
	local _, i = pathOf(id)
	local tiers, all = { 0, 0, 0 }, { "", "", "" }
	tiers[i], all[i] = tier, picks or ""
	return TowerStats.compute(VENT, tiers, all)
end

local function close(a: number, b: number): boolean
	return math.abs(a - b) < 1e-3
end

test("the Towers row (#339): 600 cash, 600 Amber, 30 every 12 s on 4, range 20, ground only, 200 HP, near track 8", function()
	eq(VENT.display, "Volcano Vent")
	eq(VENT.baseCost, 600)
	eq(VENT.unlockCost, 600)
	eq(VENT.baseDamage, 30)
	eq(VENT.baseRate, 0.0833)
	eq(VENT.baseTargets, 4)
	eq(VENT.range, 20)
	eq(VENT.hitsAir, false)
	eq(VENT.maxHp, 200)
	eq(VENT.nearTrack, 8)
	for key, def in Config.Towers do
		if key ~= "VENT" then
			eq(def.nearTrack, 0, `{key}: no Near track rule`)
		end
	end
end)

test("the VOLCANO VENT Tuning block", function()
	eq(T.FlowLengthStuds, 24)
	eq(T.FlowS, 6)
	eq(T.FlowBurnDPS, 8)
	eq(T.FlowShoveStudsS, 3)
	eq(T.ShoveMaxStuds, 4)
	eq(T.GeyserX, 0.3)
	eq(T.CrustS, 6)
	eq(T.CrustSlow, 30)
	eq(T.LavaBombX, 0.5)
	eq(T.LavaBombs, 6)
	eq(T.ExtraVentX, 0.5)
	eq(T.SupervolcanoS, 4)
	eq(T.AshS, 5)
end)

local Y = true
local ROWS = {
	{ "Magma", 1, "", "Hot Rock", { damageMult = 1.6 } },
	{ "Magma", 2, "", "Searing Flow", { damageMult = 3 } },
	{ "Magma", 3, "", "Lava Lake", { damageMult = 5.4, flowSeconds = 10, burnBreaks = Y } },
	{ "Magma", 4, "A", "White Hot", { damageMult = 1.75, piercesArmor = Y } },
	{ "Magma", 4, "B", "Rivers of Fire", { damageMult = 1.3, flowLengthMult = 1.8 } },
	{ "Magma", 4, "C", "Ember Rain", { damageMult = 1.85, hitsAir = Y } },
	{ "Magma", 5, "A", "Supervolcano", { damageMult = 1.5, supervolcano = Y } },
	{ "Magma", 5, "B", "Lava Bombs", { damageMult = 1.5, lavaBombs = Y } },
	{ "Magma", 5, "C", "Fire Mountain", { damageMult = 1.05, flowLengthMult = 2, targetsMult = 2 } },
	{ "Pressure", 1, "", "Shorter Fuse", { damageMult = 1.2, rateMult = 1.33 } },
	{ "Pressure", 2, "", "Twin Vents", { damageMult = 1.5, rateMult = 2 } },
	{ "Pressure", 3, "", "Geyser", { damageMult = 2.5, rateMult = 2, geyserEvery = 5 } },
	{ "Pressure", 4, "A", "Steam Burst", { damageMult = 1.75, knockback = 6 } },
	{ "Pressure", 4, "B", "Rumble", { damageMult = 1.75, slowPercent = 20 } },
	{ "Pressure", 4, "C", "Pressure Valve", { damageMult = 1.85, bossErupt = Y } },
	{ "Pressure", 5, "A", "Ring of Fire", { damageMult = 0.85, extraVents = 3 } },
	{ "Pressure", 5, "B", "Old Faithful", { damageMult = 0.8, rateMult = 2.5 } },
	{ "Pressure", 5, "C", "Ash Blanket", { damageMult = 1.9, sideThrowMissPercent = 30 } },
	{ "Obsidian", 1, "", "Cooling Crust", { crust = Y } },
	{ "Obsidian", 2, "", "Sharp Glass", { crust = Y, stripsArmor = Y } },
	{ "Obsidian", 3, "", "Obsidian Wall", { crust = Y, stripsArmor = Y, wallSeconds = 2 } },
	{ "Obsidian", 4, "A", "Jagged Crust", { crustDps = 35 } },
	{ "Obsidian", 4, "B", "Black Glass", { auraRangePercent = 15, crustDps = 15 } },
	{ "Obsidian", 4, "C", "Heat Shimmer", { throwMissPercent = 100, crustDps = 10 } },
	{ "Obsidian", 5, "A", "Glass Maze", { mazeStuds = 12 } },
	{ "Obsidian", 5, "B", "Obsidian Armour", { throwResistPercent = 30, crustDps = 15 } },
	{ "Obsidian", 5, "C", "Frozen Fire", { freezeFlowSeconds = 2 } },
}
local TIMERS = { geyserEvery = true }

test("every PLAN row: name, letter and cells (T4 over T3, T5 over A4); one price a slot; no Raider option (#320)", function()
	for _, r in ROWS do
		local id, tier, letter, name, cells = r[1], r[2], r[3], r[4], r[5]
		local path = pathOf(id)
		local row = if tier <= 3 then path.tiers[tier] elseif tier == 4 then path.t4[letter] else path.t5["A" .. letter]
		local below = if tier <= 3 then nil elseif tier == 4 then path.tiers[3] else path.t4.A
		ok(row ~= nil, `{id} T{tier}{letter}`)
		eq(row.name, name, `{id} T{tier}{letter} name`)
		for field, value in cells do
			local want: any = value
			if below and string.find(field, "Mult$") then
				want = (below[field] or 1) * value
			elseif below and type(value) == "number" and not TIMERS[field] then
				want = math.max(value, below[field] or 0)
			end
			if type(want) == "number" then
				ok(close(row[field] or 0, want), `{id} T{tier}{letter} {field} = {want} (got {row[field]})`)
			else
				eq(row[field], want, `{id} T{tier}{letter} {field}`)
			end
		end
		if tier >= 4 then
			local slot = if tier == 4 then path.t4 else { A = path.t5.AA, B = path.t5.AB, C = path.t5.AC }
			eq(row.cost, slot.A.cost, `{id} T{tier}{letter}: one price a slot (#277)`)
			ok(row.pvpEffect ~= true, `{id} T{tier}{letter}: no Raider option on the vent (#320)`)
		end
	end
	eq(stats("Obsidian", 3).wallSeconds, 2, "Obsidian Wall reaches the stats (a Resin column the vent shares)")
	eq(stats("Magma", 5, "AC").targets, 8, "Fire Mountain: twice the targets")
end)

test("the stretch, flow time and burn", function()
	local s = stats("Magma", 4, "B")
	local from, to = Vent.stretch(s, 100, 500)
	ok(close(to - from, 24 * 1.8) and close((from + to) / 2, 100), "Rivers of Fire: 1.8x the stretch, centred on the nearest point")
	local a, b = Vent.stretch(stats("Magma", 1), 5, 500)
	ok(a == 0 and b == 17, "clamped at the track's end")
	eq(Vent.flowSeconds(stats("Magma", 1)), T.FlowS, "blank Flow (s) = Tuning")
	eq(Vent.flowSeconds(stats("Magma", 3)), 10, "Lava Lake: 10 s")
	ok(close(Vent.flowBurn(stats("Magma", 2), VENT.baseDamage), T.FlowBurnDPS * 3), "burn x Damage x")
	ok(Vent.inStretch(100, from, to) and not Vent.inStretch(200, from, to))
end)

test("the shove: sideways up to Shove max, never a boss; the walk back; strongest flow only", function()
	eq(Vent.shove(0, 1, false), T.FlowShoveStudsS)
	eq(Vent.shove(3, 1, false), T.ShoveMaxStuds, "capped at Shove max")
	eq(Vent.shove(0, 1, true), 0, "bosses aren't shoved")
	eq(Vent.rejoinSeconds(4, 8), 0.5)
	local weak = { from = 0, to = 50, ends = 10, dps = 8, frozen = false }
	local strong = { from = 20, to = 60, ends = 10, dps = 20, frozen = false }
	ok(Vent.strongest({ weak, strong }, 30, 1) == strong, "overlap: the strongest only")
	ok(Vent.strongest({ weak, strong }, 10, 1) == weak)
	eq(Vent.strongest({ weak, strong }, 30, 11), nil, "gone after its time")
end)

test("crust, Glass Maze, Frozen Fire once at the flow's end, Ring of Fire, Lava Bombs, Pressure Valve", function()
	local ends, slow = Vent.crust(stats("Obsidian", 1), 10)
	ok(ends == 10 + T.CrustS and slow == T.CrustSlow, "crust after the flow")
	local noEnds, noSlow = Vent.crust(stats("Magma", 1), 10)
	ok(noEnds == 10 and noSlow == 0, "no Crust flag: no crust")
	eq(Vent.mazeSeconds(12, 6), 2)
	local flow = { from = 0, to = 24, ends = 5, dps = 8, frozen = false }
	ok(not Vent.freezeAtEnd(flow, 4), "not before the end")
	ok(Vent.freezeAtEnd(flow, 5), "at the end")
	ok(not Vent.freezeAtEnd(flow, 6), "once per flow")
	local times = Vent.ringTimes(3, 12)
	ok(#times == 3 and times[1] == 3 and times[3] == 9, "3 small vents in turn between eruptions")
	local picks, x = Vent.bombTargets({ { sizes = 2 }, { sizes = 5 }, { sizes = 1, boss = true }, { sizes = 3 } })
	ok(picks[1] == 3 and picks[2] == 2 and picks[3] == 4 and #picks == 4, "the biggest first, a boss before all")
	eq(x, T.LavaBombX)
	local seen = {}
	ok(Vent.bossErupts(seen, "rex"), "a boss enters: erupt")
	ok(not Vent.bossErupts(seen, "rex"), "once per boss")
	ok(Vent.bossErupts(seen, "other"))
end)

test("Near track placement: 8 studs from the track yes, 12 no; towers without the rule anywhere", function()
	local found = false
	local points = Track.Waypoints
	for i = 2, #points do
		local a, b = points[i - 1], points[i]
		local mid = (a + b) / 2
		local along = Vector3.new(b.X - a.X, 0, b.Z - a.Z).Unit
		for _, sign in { 1, -1 } do
			local across = Vector3.new(-along.Z, 0, along.X) * sign
			local at8 = mid + across * (Track.LaneWidth / 2 + 8)
			local at12 = mid + across * (Track.LaneWidth / 2 + 12)
			if Placement.checkNear(at8, VENT.nearTrack) and not Placement.checkNear(at12, VENT.nearTrack) then
				found = true
			end
			ok(Placement.checkNear(at8, VENT.nearTrack), "8 studs from a lane: yes")
		end
	end
	ok(found, "12 studs from the track: no")
	ok(Placement.checkNear(Vector3.new(1e4, 0, 1e4), 0), "no rule: anywhere")
	local okFar, why = Placement.checkNear(Vector3.new(1e4, 0, 1e4), VENT.nearTrack)
	ok(not okFar and why ~= nil, "far away: refused with a reason")
end)

test("the server wires it: eruptions each frame (not the shooting loop), Near track on build and ghost, throws, firenow", function()
	local fs = require("@lune/fs")
	local towers = fs.readFile("src/server/Towers.luau")
	ok(string.find(towers, "stepVent(tower, dt, own)", 1, true) ~= nil, "Towers.step erupts every vent")
	ok(string.find(towers, "if tower.meteor or tower.vent then", 1, true) ~= nil, "a vent never fires the generic shot")
	ok(string.find(towers, "AutoFire.reset(vent.auto)", 1, true) ~= nil, "Supervolcano resets each round played")
	ok(string.find(towers, "ventFireNow(tower, fired)", 1, true) ~= nil, "firenow VENT")
	ok(string.find(towers, "ventThrowMiss(point, side)", 1, true) ~= nil, "Heat Shimmer / Ash Blanket on throws")
	ok(string.find(fs.readFile("src/server/Shop.luau"), "Placement.checkNear(spot, def.nearTrack", 1, true) ~= nil, "the server refuses a vent far from the track")
	ok(string.find(fs.readFile("src/client/Shop.client.luau"), "Placement.checkNear(spot, placingDef.nearTrack", 1, true) ~= nil, "the ghost shows it")
	ok(string.find(fs.readFile("src/server/DinoAttacks.luau"), "Towers.throwResistAt(target.ref.base, target.ref.side)", 1, true) ~= nil, "Obsidian Armour on throws")
	ok(string.find(fs.readFile("src/server/Enemies.luau"), "now >= enemy.detourUntil", 1, true) ~= nil, "a shoved dino walks back before it moves on")
end)
