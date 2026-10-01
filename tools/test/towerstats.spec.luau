--[[
	TowerStats.compute: every Config tier alone gives exactly that row's numbers, and two
	paths combine by the rule (x columns multiply, amounts take the highest, flags OR,
	freezeEvery the shortest pulse). Tiers are keyed by (tower, path, tier), never by name.
]]

local Config = require(src.shared.Config)
local TowerStats = require(src.shared.TowerStats)
local Upgrades = require(src.shared.Upgrades)

local ROUNDED_DOWN = { bomblets = true, bombletGenerations = true, chests = true, medKits = true }
local AT_LEAST_ONE = { shots = true, lineHits = true }

local function where(key: string, tiers: { number }): string
	return `{key} {table.concat(tiers, "/")}`
end

-- The stats a tower should have with these (legal) tiers, built straight from the
-- Config rows by the combine rule.
local function expected(def, tiers: { number })
	local rows = {}
	for pathIndex, tier in tiers do
		if tier > 0 then
			table.insert(rows, def.paths[pathIndex].tiers[tier])
		end
	end
	local function product(field: string): number
		local value = 1
		for _, row in rows do
			value *= row[field]
		end
		return value
	end
	local function highest(field: string): number
		local value = if AT_LEAST_ONE[field] then 1 else 0
		for _, row in rows do
			value = math.max(value, row[field])
		end
		return value
	end
	local function any(field: string): boolean
		for _, row in rows do
			if row[field] then
				return true
			end
		end
		return false
	end

	local e: { [string]: any } = {
		damage = def.baseDamage * product("damageMult"),
		rate = def.baseRate * product("rateMult"),
		targets = math.max(1, math.floor(def.baseTargets * product("targetsMult") + 0.5)),
		range = def.range * product("rangeMult"),
		splashRadius = def.splashRadius * product("splashMult"),
		armoredMult = product("armoredMult"),
		bossMult = product("bossMult"),
		incomeMult = product("incomeMult"),
		hunterRecoilMult = product("hunterRecoilMult"),
		hunterReloadMult = product("hunterReloadMult"),
		hunterSpreadMult = product("hunterSpreadMult"),
		healPerSecond = def.healPerSecond * product("healMult"),
	}
	for _, field in TowerStats.HIGHEST do
		local value = highest(field)
		if ROUNDED_DOWN[field] or AT_LEAST_ONE[field] then
			value = math.floor(value)
		end
		e[field] = value
	end
	e.slowPercent = math.max(def.slowPercent, highest("slowPercent"))
	e.resistPercent = math.max(def.resistPercent, highest("resistPercent"))
	for _, field in TowerStats.FLAGS do
		e[field] = any(field)
	end
	local every = 0
	for _, row in rows do
		if row.freezeEvery > 0 and (every == 0 or row.freezeEvery < every) then
			every = row.freezeEvery
		end
	end
	e.freezeEvery = every
	return e
end

local function compare(key: string, def, tiers: { number })
	local stats = TowerStats.compute(def, tiers)
	local e = expected(def, tiers)
	for field, value in stats do
		local want = e[field]
		local what = `{where(key, tiers)} {field}`
		ok(want ~= nil, `{what} is not covered by this spec`)
		if type(want) == "number" then
			near(value, want, what, 1e-9 * math.max(1, math.abs(want)))
		else
			eq(value, want, what)
		end
	end
	for field in e do
		ok(stats[field] ~= nil, `{where(key, tiers)} {field} missing from compute`)
	end
end

test("every combine-list field exists on every Config tier", function()
	for _, key in Config.TowerOrder do
		for pathIndex, path in Config.Towers[key].paths do
			for tier, row in path.tiers do
				for _, list in { TowerStats.MULTIPLIERS, TowerStats.HIGHEST, TowerStats.FLAGS } do
					for _, field in list do
						ok(row[field] ~= nil, `{key} path {pathIndex} tier {tier} has no {field}`)
					end
				end
				ok(row.freezeEvery ~= nil, `{key} path {pathIndex} tier {tier} has no freezeEvery`)
			end
		end
	end
end)

test("an untouched tower is its base row", function()
	for _, key in Config.TowerOrder do
		compare(key, Config.Towers[key], { 0, 0, 0 })
	end
end)

test("each tier alone gives that Config row's numbers (15 per tower)", function()
	local count = 0
	for _, key in Config.TowerOrder do
		local def = Config.Towers[key]
		for pathIndex, path in def.paths do
			for tier in path.tiers do
				local tiers = { 0, 0, 0 }
				tiers[pathIndex] = tier
				compare(key, def, tiers)
				count += 1
			end
		end
	end
	eq(count, 15 * #Config.TowerOrder, "tower tiers in Config")
end)

test("every legal two-path crossover multiplies, takes the highest and ORs", function()
	local count = 0
	for _, key in Config.TowerOrder do
		local def = Config.Towers[key]
		for p = 1, 3 do
			for q = p + 1, 3 do
				for a = 1, #def.paths[p].tiers do
					for b = 1, #def.paths[q].tiers do
						local tiers = { 0, 0, 0 }
						tiers[p], tiers[q] = a, b
						if a <= 2 or b <= 2 then -- the crossover rule (cap 2)
							compare(key, def, tiers)
							count += 1
						end
					end
				end
			end
		end
	end
	ok(count > 0, "no crossovers checked")
end)

test("a known crossover: Hunting Blind Lookout 3 + Trigger Happy 2", function()
	local def = Config.Towers.SCOUT
	local a, b = def.paths[1].tiers[3], def.paths[2].tiers[2]
	eq(Upgrades.check({ 3, 1, 0 }, 2, 5), "ok", "legal")
	local stats = TowerStats.compute(def, { 3, 2, 0 })
	near(stats.damage, def.baseDamage * a.damageMult * b.damageMult, "damage")
	near(stats.rate, def.baseRate * a.rateMult * b.rateMult, "rate")
	eq(stats.shots, math.max(1, math.floor(math.max(a.shots, b.shots))), "shots")
	eq(stats.piercesArmor, a.piercesArmor or b.piercesArmor, "piercesArmor")
end)
