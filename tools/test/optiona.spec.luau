--[[
	Option A changes no number (PLAN Phase 9 T110/T111, DECISIONS #275, #281).

	tools/test/option_a_snapshot.json was written from the game BEFORE the A/B/C system
	(commit fad6140's Config and TowerStats/HeroStats): every tower's stats with each path
	alone at every tier and every maxed path with each other path at 1 or 2, every hero's
	the same up to tier 6 (second path 1-3), and each tier's cost, name and model swap.
	Numbers are stored as "%.17g" strings, so the comparison is exact (JSON floats aren't).
	Here the same builds are computed today with option A picked at tiers 4 and 5 ("A",
	"AA") and must match exactly: every field, no field missing or added.
]]

local fs = require("@lune/fs")
local serde = require("@lune/serde")
local Config = require(src.shared.Config)
local TowerStats = require(src.shared.TowerStats)
local HeroStats = require(src.shared.HeroStats)
local Upgrades = require(src.shared.Upgrades)

local SNAPSHOT = serde.decode("json", fs.readFile("tools/test/option_a_snapshot.json"))

-- A value as the snapshot stores it.
local function exact(x: any): any
	return if type(x) == "number" then string.format("%.17g", x) else x
end

local function numbers(list: { string }): { number }
	local out = {}
	for i, x in list do
		out[i] = assert(tonumber(x))
	end
	return out
end

-- Option A on every path that reached tier 4 or 5 (and the hero tier 6 above them).
local function picksFor(tiers: { number }): { string }
	local picks = {}
	for i, tier in tiers do
		picks[i] = if tier >= 5 then "AA" elseif tier == 4 then "A" else ""
	end
	return picks
end

-- Stats fields added after the snapshot (PLAN 9c, 9d), with the value every option-A build has.
local AFTER_SNAPSHOT: { [string]: any } = {
	bombletBurnDps = 0,
	bombletBurnSeconds = 0,
	stripsOnHit = false,
	raiderSlowPercent = 0, -- 9d Raider sting
	raiderSlowSeconds = 0,
	raiderDamage = 0,
	bountyCash = 0, -- 9d Bounty cash
}

local function same(actual: { [string]: any }, expected: { [string]: any }, where: string): number
	local bad = 0
	for field, value in expected do
		if exact(actual[field]) ~= value then
			bad += 1
			eq(exact(actual[field]), value, `{where} {field}`)
		end
	end
	for field, value in actual do
		if expected[field] == nil then
			-- Fields added after the snapshot hold their "does nothing" value on every
			-- option-A build, so option A plays exactly as before (PLAN 9c wirings).
			local idle = AFTER_SNAPSHOT[field]
			if idle == nil or value ~= idle then
				bad += 1
				eq(value, idle, `{where} {field} is new`)
			end
		end
	end
	return bad
end

local function checkSteps(paths, snapSteps, key: string)
	eq(#paths, #snapSteps, `{key} path count`)
	for p, steps in snapSteps do
		local path = paths[p]
		eq(Upgrades.tierCount(path), #steps, `{key} path {p} tier count`)
		for t, step in steps do
			local row = Upgrades.row(path, t, "AA")
			ok(row ~= nil, `{key} path {p} T{t} has an option-A row`)
			eq(exact(row.cost), step.cost, `{key} path {p} T{t} cost`)
			eq(row.name, step.name, `{key} path {p} T{t} name`)
			eq(row.swapsModel, step.swapsModel, `{key} path {p} T{t} swapsModel`)
		end
	end
end

test("the snapshot covers every tower and hero in Config, and nothing else", function()
	for key in Config.Towers do
		ok(SNAPSHOT.towers[key] ~= nil, `{key} in the snapshot`)
	end
	for key in SNAPSHOT.towers do
		ok(Config.Towers[key] ~= nil, `{key} still in Config`)
	end
	for key in Config.Heroes do
		ok(SNAPSHOT.heroes[key] ~= nil, `{key} in the snapshot`)
	end
	for key in SNAPSHOT.heroes do
		ok(Config.Heroes[key] ~= nil, `{key} still in Config`)
	end
end)

test("every tower build with option A computes exactly the stats it had before A/B/C", function()
	local builds, bad = 0, 0
	for key, snap in SNAPSHOT.towers do
		local def = Config.Towers[key]
		for _, build in snap.builds do
			local tiers = numbers(build.tiers)
			local stats = TowerStats.compute(def, tiers, picksFor(tiers)) :: any
			bad += same(stats, build.stats, `{key} {table.concat(tiers, "/")}`)
			builds += 1
		end
	end
	ok(builds >= 11 * 3 * (5 + 4), `{builds} tower builds checked`)
	eq(bad, 0, "tower fields that changed")
end)

test("every hero build with option A computes exactly the stats it had before A/B/C", function()
	local builds, bad = 0, 0
	for key, snap in SNAPSHOT.heroes do
		for _, build in snap.builds do
			local tiers = numbers(build.tiers)
			local stats = HeroStats.compute(key, tiers, nil, nil, picksFor(tiers)) :: any
			bad += same(stats, build.stats, `{key} {table.concat(tiers, "/")}`)
			builds += 1
		end
	end
	ok(builds >= 4 * 3 * (6 + 6), `{builds} hero builds checked`)
	eq(bad, 0, "hero fields that changed")
end)

test("every tier's cost, name and model swap with option A are the ones before A/B/C", function()
	for key, snap in SNAPSHOT.towers do
		checkSteps(Config.Towers[key].paths, snap.steps, key)
	end
	for key, snap in SNAPSHOT.heroes do
		checkSteps(Config.Heroes[key].paths, snap.steps, key)
	end
end)
