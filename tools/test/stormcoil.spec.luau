--[[
	Storm Coil (PLAN T64, DECISIONS #151, UPGRADES.md): the chain, Power Grid's scaling,
	Judgement Bolt's target, Grounding Spike's pick, and the sheet's tiers.
]]

local Config = require(src.shared.Config)
local StormCoil = require(src.shared.StormCoil)
local TowerStats = require(src.shared.TowerStats)

local COIL = Config.Towers.COIL
local T = Config.Tuning

local function row(n: number): { Vector3 }
	local points = {}
	for i = 1, n do
		table.insert(points, Vector3.new((i - 1) * 5, 0, 0))
	end
	return points
end

local function indices(links): string
	local out = {}
	for _, link in links do
		table.insert(out, tostring(link.index))
	end
	return table.concat(out, ",")
end

test("the Tuning levers are the seeds (DECISIONS #151)", function()
	eq(T.CoilArcs, 4)
	eq(T.CoilArcReach, 10)
	eq(T.CoilArcFalloff, 0.8)
	eq(T.PowerGridRangePerCoil, 0.15)
	eq(T.PowerGridDamageBase, 0.5)
	eq(T.PowerGridDamagePerCoil, 0.25)
	eq(T.PowerGridCoilCap, 6)
	eq(T.PowerGridEvery, 6)
	eq(T.JudgementBoltEvery, 10)
	eq(T.JudgementBoltX, 8)
	eq(T.JudgementBoltBreaks, 3)
	eq(T.JudgementBoltStun, 0.5)
end)

test("the tower: 550 cash, 300 Amber, hits air, chains, damageable, short range", function()
	eq(COIL.display, "Storm Coil")
	eq(COIL.baseCost, 550)
	eq(COIL.unlockCost, 300)
	eq(COIL.hitsAir, true)
	eq(COIL.chains, true)
	eq(COIL.untouchable, false)
	eq(COIL.onTrack, false)
	eq(COIL.range, 14)
	ok(COIL.maxHp > 0, "has HP")
	for key, def in Config.Towers do
		eq(def.chains, key == "COIL", `{key} chains`)
	end
	local base = TowerStats.compute(COIL, { 0, 0, 0 })
	eq(base.arcs, 4, "4 arcs at tier 0")
	eq(base.arcReach, 10, "arc reach 10")
	eq(base.arcForks, 1, "one dino per hop")
	eq(base.piercesArmor, false, "no armour until High Voltage")
	eq(base.sizeBreaks, 1, "area: breaks 1")
	local scout = TowerStats.compute(Config.Towers.SCOUT, { 0, 0, 0 })
	eq(scout.arcs, 0, "a tower that doesn't chain has no arcs")
end)

test("the chain: first hit, then the nearest dino within reach, 80% per arc", function()
	local links = StormCoil.chain(row(6), 1, 4, 10, 1, 0.8)
	eq(indices(links), "1,2,3,4,5", "4 arcs after the first hit")
	near(links[1].x, 1, "first hit")
	near(links[2].x, 0.8, "arc 1")
	near(links[5].x, 0.8 ^ 4, "arc 4")
	eq(links[3].from, 2, "arc 2 leaves from dino 2")
	eq(links[1].from, nil, "the first hit comes from the coil")
	-- nearest first, wherever it is in the list
	local points = { Vector3.new(0, 0, 0), Vector3.new(8, 0, 0), Vector3.new(-3, 0, 0) }
	eq(indices(StormCoil.chain(points, 1, 1, 10, 1, 0.8)), "1,3", "the nearer dino")
	-- reach: a gap past it ends the chain
	points = { Vector3.new(0, 0, 0), Vector3.new(5, 0, 0), Vector3.new(16, 0, 0) }
	eq(indices(StormCoil.chain(points, 1, 4, 10, 1, 0.8)), "1,2", "11 studs is past reach 10")
	eq(indices(StormCoil.chain(points, 1, 4, 15, 1, 0.8)), "1,2,3", "Long Arc's 15 reaches it")
	eq(indices(StormCoil.chain(row(3), 2, 0, 10, 1, 0.8)), "2", "no arcs: one hit")
	eq(indices(StormCoil.chain(row(4), 1, 4, 10, 1, 0.8, { [2] = true })), "1,3,4", "skipped dinos are passed over")
	eq(#StormCoil.chain(row(9), 1, 6, 10, 1, 0.8), 7, "Copper Wire: 6 arcs = 7 dinos")
end)

test("Fork Lightning: each hop reaches two dinos", function()
	-- a star: four dinos around the first, two more further out
	local points = {
		Vector3.new(0, 0, 0),
		Vector3.new(3, 0, 0),
		Vector3.new(-4, 0, 0),
		Vector3.new(0, 0, 6),
		Vector3.new(12, 0, 0),
		Vector3.new(-13, 0, 0),
	}
	local links = StormCoil.chain(points, 1, 2, 10, 2, 0.8)
	eq(indices(links), "1,2,3,4,5", "hop 1: the two nearest; hop 2: the two nearest to them")
	eq(links[2].hop, 1)
	eq(links[3].hop, 1)
	near(links[3].x, 0.8, "a fork's second branch is still hop 1")
	eq(links[4].hop, 2)
	near(links[5].x, 0.64)
	eq(links[5].from, 2, "dino 5 arcs from dino 2, its nearest")
	eq(#StormCoil.chain(points, 1, 2, 10, 1, 0.8), 3, "without forks: 2 hops, 3 dinos")
end)

test("Power Grid: n = 1, 2, 6 and 8 (= 6) standing coils (DECISIONS #151)", function()
	local function check(n: number, range: number, damage: number)
		local r, d = StormCoil.grid(n)
		near(r, range, `n = {n} range x`)
		near(d, damage, `n = {n} damage x`)
	end
	check(1, 1, 0.75) -- one coil alone is weaker
	check(2, 1.15, 1)
	check(3, 1.3, 1.25)
	check(6, 1.75, 2)
	check(8, 1.75, 2) -- counted up to 6
	check(0, 1, 0.75) -- never below one (the striking coil stands)
end)

test("Judgement Bolt: the dino with the most HP; Grounding Spike: the soonest throw at a tower in range", function()
	eq(StormCoil.biggest({ 40, 900, 120, 900 }), 2, "most HP, ties to the first")
	eq(StormCoil.biggest({}), nil, "nothing in range")
	local centre = Vector3.new(0, 0, 0)
	local throws = {
		{ to = Vector3.new(5, 0, 0), left = 0.3, atTower = false }, -- at a hunter
		{ to = Vector3.new(30, 0, 0), left = 0.1, atTower = true }, -- out of range
		{ to = Vector3.new(0, 0, 10), left = 0.8, atTower = true },
		{ to = Vector3.new(-6, 0, 0), left = 0.5, atTower = true },
	}
	eq(StormCoil.groundingPick(throws, centre, 14), 4, "lands soonest of those it may catch")
	eq(StormCoil.groundingPick({ throws[1], throws[2] }, centre, 14), nil, "nothing to catch")
	eq(StormCoil.covered(Vector3.new(10, 9, 0), { { center = centre, radius = 10 } }), true, "flat: a flyer above the edge counts")
	eq(StormCoil.covered(Vector3.new(10.1, 0, 0), { { center = centre, radius = 10 } }), false)
end)

test("the sheet's tiers (UPGRADES.md, TOWERS_NEXT final names)", function()
	local function stats(path: number, tier: number)
		local tiers = { 0, 0, 0 }
		tiers[path] = tier
		return TowerStats.compute(COIL, tiers)
	end
	local names = {
		{ "Copper Wire", "Long Arc", "Fork Lightning", "Jump Spark", "Power Grid" },
		{ "Battery Pack", "Static Shock", "Thunderclap", "High Voltage", "Judgement Bolt" },
		{ "Tall Mast", "Charged Air", "Grounding Spike", "Storm Warning", "Lightning Rodeo" },
	}
	for p, path in COIL.paths do
		eq(path.id, ({ "Arc", "Charge", "Lightning Rod" })[p], `path {p}`)
		for t, step in path.tiers do
			eq(step.name, names[p][t], `path {p} T{t}`)
		end
	end
	-- Arc
	eq(stats(1, 1).arcs, 6, "Copper Wire: +2 arcs")
	eq(stats(1, 2).arcReach, 15, "Long Arc")
	eq(stats(1, 3).arcForks, 2, "Fork Lightning")
	eq(stats(1, 3).arcJumps, false)
	eq(stats(1, 4).arcJumps, true, "Jump Spark")
	eq(stats(1, 4).powerGrid, false)
	eq(stats(1, 5).powerGrid, true, "Power Grid")
	-- Charge
	near(stats(2, 1).damage / COIL.baseDamage, 1.3, "Battery Pack +30%")
	eq(stats(2, 2).staticPercent, 10, "Static Shock")
	eq(stats(2, 3).stunSeconds, 0.4, "Thunderclap")
	eq(stats(2, 3).stunsBosses, false)
	eq(stats(2, 3).piercesArmor, false)
	eq(stats(2, 4).piercesArmor, true, "High Voltage pierces armour")
	near(stats(2, 4).damage / stats(2, 3).damage, 1.4, "High Voltage +40%", 1e-6)
	eq(stats(2, 4).judgementBolt, false)
	eq(stats(2, 5).judgementBolt, true, "Judgement Bolt")
	-- Lightning Rod
	near(stats(3, 1).range, COIL.range * 1.2, "Tall Mast range x1.2")
	eq(stats(3, 2).auraRatePercent, 10, "Charged Air")
	eq(stats(3, 3).groundingEvery, 4, "Grounding Spike every 4s")
	eq(stats(3, 4).auraDamagePercent, 15, "Storm Warning")
	eq(stats(3, 5).auraArcPercent, 50, "Lightning Rodeo")
	-- every Storm Coil tier breaks 1 (area damage never pierces through)
	for p = 1, 3 do
		for t = 1, 5 do
			eq(stats(p, t).sizeBreaks, 1, `path {p} T{t} breaks`)
		end
	end
end)
