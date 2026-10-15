--[[
	TowerStats.compute: every Config tier alone gives exactly that row's numbers, and two
	paths combine by the rule (x columns multiply, amounts take the highest, flags OR,
	freezeEvery the shortest pulse). Tiers are keyed by (tower, path, tier), never by name.
]]

local Config = require(src.shared.Config)
local TowerStats = require(src.shared.TowerStats)
local Upgrades = require(src.shared.Upgrades)

local ROUNDED_DOWN = { bomblets = true, bombletGenerations = true, chests = true, medKits = true, arcs = true, arcForks = true, birds = true }
local AT_LEAST_ONE = { shots = true, lineHits = true, sizeBreaks = true }

local function where(key: string, tiers: { number }): string
	return `{key} {table.concat(tiers, "/")}`
end

-- The stats a tower should have with these (legal) tiers, built straight from the
-- Config rows by the combine rule.
local function expected(def, tiers: { number })
	local rows = {}
	for pathIndex, tier in tiers do
		if tier > 0 then
			table.insert(rows, Upgrades.row(def.paths[pathIndex], tier))
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
		entombHitsMult = product("entombHitsMult"),
		walkerHpMult = product("walkerHpMult"),
		walkerSpeedMult = product("walkerSpeedMult"),
		walkerRespawnMult = product("walkerRespawnMult"),
		chargeMult = product("chargeMult"), -- PLAN 9h: the Bone Totem
		chargeNeededMult = product("chargeNeededMult"),
		hunterCooldownMult = product("hunterCooldownMult"),
		blimpSpeedMult = product("blimpSpeedMult"), -- PLAN 9h (T125b): the Spotter Blimp
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
	-- PLAN 9c: only a path that both throws bomblets and burns lights its bomblets; a
	-- shooting tower's Strips armour strips on its hits, a chilling tower's is its chill.
	e.bombletBurnDps, e.bombletBurnSeconds = 0, 0
	for _, row in rows do
		if row.bomblets > 0 and row.burnDps > 0 then
			e.bombletBurnDps = math.max(e.bombletBurnDps, row.burnDps)
			e.bombletBurnSeconds = math.max(e.bombletBurnSeconds, row.burnSeconds)
		end
	end
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
	e.stripsOnHit = e.stripsArmor and e.slowPercent <= 0 and every <= 0
	-- The chain (PLAN T64): a tower that chains gets Tuning's arcs and reach unless a tier
	-- sets them, and at least 1 dino per hop; on any other tower the chain fields are off.
	local chain = { "arcs", "arcReach", "arcForks", "staticPercent", "arcJumps", "powerGrid", "judgementBolt" }
	if def.chains then
		e.arcs = if e.arcs > 0 then e.arcs else Config.Tuning.CoilArcs
		e.arcReach = if e.arcReach > 0 then e.arcReach else Config.Tuning.CoilArcReach
		e.arcForks = math.max(1, e.arcForks)
	else
		for _, field in chain do
			e[field] = if type(e[field]) == "boolean" then false else 0
		end
	end
	-- The flock (PLAN T65): a tower with birds flies the Towers row's flock unless a tier
	-- raises it, one eagle with Eagle of the Peak, and a first dive of at least x1; on any
	-- other tower the bird fields are off.
	if def.birds > 0 then
		e.birds = if e.eagle then 1 else math.max(def.birds, e.birds)
		e.firstDiveX = math.max(1, e.firstDiveX)
	else
		e.birds, e.firstDiveX, e.eagle, e.murmuration, e.diveAuraRatePercent = 0, 1, false, false, 0
	end
	-- Harpoons (PLAN T66): Skewer, Tow Line and Chain Harpoons only on a tower with harpoons.
	if not def.harpoons then
		e.skewer, e.towLine, e.chainHarpoons = false, false, false
	end
	-- The tar (PLAN T67): a tower on the track sinks after the shortest Sink seconds any path
	-- gives, else Tuning's; sinking, Dig Site pay, Eruption and Tar Tracks only on the track.
	local sink = 0
	for _, row in rows do
		if row.sinkSeconds > 0 and (sink == 0 or row.sinkSeconds < sink) then
			sink = row.sinkSeconds
		end
	end
	if def.onTrack then
		e.sinkSeconds = if sink > 0 then sink else Config.Tuning.TarSinkSeconds
	else
		e.sinkSeconds, e.eruption, e.tracksSlowPercent = 0, false, 0
		if not def.resin then -- a Resin Cannon's fossils pay Sink cash too (PLAN 9g)
			e.sinkCash, e.sinkChestCash = 0, 0
		end
	end
	-- Timers where the shortest non-zero wins (PLAN 9g); the Resin fields only on a Resin tower.
	for _, field in TowerStats.MIN_POSITIVE do
		local value = 0
		for _, row in rows do
			if (row[field] or 0) > 0 and (value == 0 or row[field] < value) then
				value = row[field]
			end
		end
		e[field] = value
	end
	-- Walkers (PLAN 9g): the Towers row's count unless a tier raises it, Tuning's pounce hold
	-- unless a tier sets one; Hits air from the row or a tier; off on a tower without walkers.
	e.hitsAir = def.hitsAir or e.hitsAir
	if (def.walkers or 0) > 0 then
		e.walkers = math.max(def.walkers, e.walkers)
		e.holdSeconds = if e.holdSeconds > 0 then e.holdSeconds else Config.Tuning.PounceHoldS
		e.firstDiveX = math.max(1, highest("firstDiveX"))
		e.diveAuraRatePercent = highest("diveAuraRatePercent")
	else
		for _, field in { "walkers", "walkerResistPercent", "holdSeconds", "bossHoldSeconds", "stunRoarEvery", "takeDownStackPercent", "avengerX" } do
			e[field] = 0
		end
		for _, field in { "walkerHpMult", "walkerSpeedMult", "walkerRespawnMult" } do
			e[field] = 1
		end
		for _, field in { "flanking", "targetsFirst", "healsBetweenRounds", "dodge", "alpha", "swarm", "charge", "guard" } do
			e[field] = false
		end
	end
	if def.resin then
		e.entombSeconds = if e.entombSeconds > 0 then e.entombSeconds else Config.Tuning.EntombBaseS
		e.entombSpread = math.floor(e.entombSpread)
		e.heartEvery = math.floor(e.heartEvery)
	else
		for _, field in { "entombSeconds", "entombAmpPercent", "entombSpread", "entombSlowPercent", "entombAllEvery", "bossEntombSeconds", "sendBack", "fossilBelowPercent", "fossilRatePercent", "bountyFossilsX", "heartEvery", "sealSeconds", "sealEvery", "sealHealPercent", "wallSeconds" } do
			e[field] = 0
		end
	end
	-- Bone Totem (PLAN 9h): Hunter / Bounty charge x are 1 when no tier sets them; counts are whole.
	e.hunterChargeX = math.max(1, e.hunterChargeX)
	e.bountyChargeX = math.max(1, e.bountyChargeX)
	e.roarEchoes = math.floor(e.roarEchoes)
	e.skulls = math.floor(e.skulls)
	-- Spotter Blimp (PLAN 9h T125b): Aura reach x is 1 (Range) when no tier sets it; counts are whole.
	e.auraReachX = math.max(1, e.auraReachX)
	e.lapRepairs = math.floor(e.lapRepairs)
	e.paratroopers = math.floor(e.paratroopers)
	-- Meteor Beacon (PLAN 9i T127): counts are whole.
	e.meteors = math.floor(e.meteors)
	e.biggestBreaks = math.floor(e.biggestBreaks)
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
			for tier, row in Upgrades.line(path) do
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
			for tier in Upgrades.line(path) do
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
				for a = 1, Upgrades.tierCount(def.paths[p]) do
					for b = 1, Upgrades.tierCount(def.paths[q]) do
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
	local a, b = Upgrades.row(def.paths[1], 3), Upgrades.row(def.paths[2], 2)
	eq(Upgrades.check({ 3, 1, 0 }, 2, 5), "ok", "legal")
	local stats = TowerStats.compute(def, { 3, 2, 0 })
	near(stats.damage, def.baseDamage * a.damageMult * b.damageMult, "damage")
	near(stats.rate, def.baseRate * a.rateMult * b.rateMult, "rate")
	eq(stats.shots, math.max(1, math.floor(math.max(a.shots, b.shots))), "shots")
	eq(stats.piercesArmor, a.piercesArmor or b.piercesArmor, "piercesArmor")
end)

-- A/B/C picks (PLAN T111, DECISIONS #276, #287): compute reads the composed row of each
-- path's picks. A copy of the Hunting Blind whose Lookout tier 4 has a B (double A's
-- damage x) and whose tier 5 has B after A and after B.
local function withB()
	local real = Config.Towers.SCOUT
	local def = table.clone(real) :: any
	local path = table.clone(real.paths[1]) :: any
	local a4, a5 = path.t4.A, path.t5.AA
	local b4 = table.clone(a4)
	b4.damageMult = a4.damageMult * 2
	local ab5, bb5 = table.clone(a5), table.clone(a5)
	ab5.rateMult = a5.rateMult * 3
	bb5.damageMult = b4.damageMult
	path.t4 = { A = a4, B = b4 }
	path.t5 = { AA = a5, AB = ab5, BA = table.clone(a5), BB = bb5 }
	def.paths = { path, real.paths[2], real.paths[3] }
	return def, a4, a5
end

test("T111: compute reads each path's picks; nil picks = option A", function()
	local def, a4, a5 = withB()
	local base = def.baseDamage
	near(TowerStats.compute(def, { 4, 0, 0 }, { "A", "", "" }).damage, base * a4.damageMult, "4A")
	near(TowerStats.compute(def, { 4, 0, 0 }, { "B", "", "" }).damage, base * a4.damageMult * 2, "4B")
	near(TowerStats.compute(def, { 4, 0, 0 }).damage, base * a4.damageMult, "no picks = A")
	near(TowerStats.compute(def, { 5, 0, 0 }, { "AB", "", "" }).rate, def.baseRate * a5.rateMult * 3, "5 AB")
	near(TowerStats.compute(def, { 5, 0, 0 }, { "BB", "", "" }).damage, base * a4.damageMult * 2, "5 BB")
	near(TowerStats.compute(def, { 5, 2, 0 }, { "BB", "", "" }).damage, base * a4.damageMult * 2 * Upgrades.row(def.paths[2], 2).damageMult, "5 BB with path 2 at 2")
end)

test("T111: a tier with no row for its picks is an error, never a silent option A", function()
	local def = withB()
	ok(not pcall(TowerStats.compute, def, { 4, 0, 0 }, { "", "", "" }), "tier 4 with no pick")
	ok(not pcall(TowerStats.compute, def, { 4, 0, 0 }, { "C", "", "" }), "tier 4 with a pick that has no row")
	ok(not pcall(TowerStats.compute, def, { 5, 0, 0 }, { "AC", "", "" }), "tier 5 with a pick that has no row (every real tower has B/C since 9e)")
	ok(pcall(TowerStats.compute, Config.Towers.SCOUT, { 5, 0, 0 }, { "AB", "", "" }), "a starter path has B (9c)")
end)
