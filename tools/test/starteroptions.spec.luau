--[[
	Batch 9c (PLAN Phase 9, DECISIONS #290): the 36 B/C options of Hunting Blind, Longshot
	Perch and Mortar Pit. Each option's composed row is the build under it plus exactly the
	cells PLAN gives (x columns multiply, amounts take the higher, flags add); and the new
	wirings: Strips armour on a hit (Tuning Strip (s)), Boss mark % on Blind/Perch,
	knockback on Perch shots, stun / knockback / burn carried by Mortar bomblets.
]]

local Config = require(src.shared.Config)
local Combat = require(src.shared.Combat)
local TowerStats = require(src.shared.TowerStats)
local Upgrades = require(src.shared.Upgrades)
local Ballista = require(src.shared.Ballista)

-- PLAN 9c, cell by cell: tower key, path, tier, letter, name, cells (own step).
local MULT = { damageMult = true, rateMult = true, targetsMult = true, rangeMult = true, armoredMult = true, bossMult = true, splashMult = true }
local OPTIONS = {
	{ "SCOUT", "Lookout", 4, "B", "Signal Mirror", { damageMult = 1.15, auraRatePercent = 18 } },
	{ "SCOUT", "Lookout", 4, "C", "Spotter's Call", { damageMult = 1.2, rangeMult = 1.1, markPercent = 15 } },
	{ "SCOUT", "Lookout", 5, "B", "Beacon Fire", { damageMult = 1.4, rangeMult = 1.15, auraRatePercent = 35 } },
	{ "SCOUT", "Lookout", 5, "C", "Trophy Spotter", { damageMult = 1.55, rangeMult = 1.1, bossMarkPercent = 40 } },
	{ "SCOUT", "Trigger Happy", 4, "B", "Belt Feed", { damageMult = 1.05, rateMult = 1.45 } },
	{ "SCOUT", "Trigger Happy", 4, "C", "Long Burst", { damageMult = 1.2, rateMult = 1.55, rangeMult = 1.25 } },
	{ "SCOUT", "Trigger Happy", 5, "B", "Bullet Storm", { damageMult = 0.8, lineHits = 4 } },
	{ "SCOUT", "Trigger Happy", 5, "C", "Shredder", { damageMult = 1.7, rateMult = 1.35, stripsArmor = true } },
	{ "SCOUT", "Hardliner", 4, "B", "Cracking Shot", { damageMult = 2.7, lineHits = 2, stripsArmor = true } },
	{ "SCOUT", "Hardliner", 4, "C", "Heavy Slug", { damageMult = 2.6, lineHits = 2, sizeBreaks = 3 } },
	{ "SCOUT", "Hardliner", 5, "B", "Jolt Rounds", { damageMult = 4.6, armoredMult = 2, stunSeconds = 0.3 } },
	{ "SCOUT", "Hardliner", 5, "C", "Rail Lance", { damageMult = 1.5, armoredMult = 1.5, lineHits = 6 } },
	{ "SNIPER", "Deadeye", 4, "B", "Wind Shear", { damageMult = 1.45, targetsMult = 1.2, lineHits = 5, knockback = 3 } },
	{ "SNIPER", "Deadeye", 4, "C", "Fast Bolt", { damageMult = 1.1, rateMult = 1.45, lineHits = 5 } },
	{ "SNIPER", "Deadeye", 5, "B", "Piercing Gale", { damageMult = 1.55, rateMult = 1.6, targetsMult = 1.2, lineHits = 8 } },
	{ "SNIPER", "Deadeye", 5, "C", "Shatterline", { damageMult = 2.4, targetsMult = 1.2, lineHits = 8, stripsArmor = true } },
	{ "SNIPER", "Spotter", 4, "B", "Painted Target", { damageMult = 1.3, rateMult = 1.3, markPercent = 30, bossMarkPercent = 25 } },
	{ "SNIPER", "Spotter", 4, "C", "Quick Spot", { damageMult = 1.2, rateMult = 1.65 } },
	{ "SNIPER", "Spotter", 5, "B", "Spotter Network", { damageMult = 1.3, rateMult = 1.35, markPercent = 45, auraDamagePercent = 15 } },
	{ "SNIPER", "Spotter", 5, "C", "Kill Order", { damageMult = 1.35, rateMult = 1.4, markPercent = 50, bossMarkPercent = 40 } },
	{ "SNIPER", "Big Bore", 4, "B", "Elephant Gun", { damageMult = 1.7, bossMult = 2 } },
	{ "SNIPER", "Big Bore", 4, "C", "Knockdown Round", { damageMult = 2.8, knockback = 4, sizeBreaks = 3 } },
	{ "SNIPER", "Big Bore", 5, "B", "Bone Splitter", { damageMult = 1.9, bossMult = 1.6, sizeBreaks = 5 } },
	{ "SNIPER", "Big Bore", 5, "C", "Hammer Shot", { damageMult = 2.3, stunSeconds = 1.2, knockback = 6 } },
	{ "GRENADIER", "Blast", 4, "B", "Big Shell", { damageMult = 1.3, targetsMult = 1.4, splashMult = 1.3 } },
	{ "GRENADIER", "Blast", 4, "C", "White Phosphorus", { damageMult = 1.4, targetsMult = 1.3, burnDps = 3, burnSeconds = 2 } },
	{ "GRENADIER", "Blast", 5, "B", "Blast Furnace", { damageMult = 1.5, targetsMult = 1.4, splashMult = 1.3 } },
	{ "GRENADIER", "Blast", 5, "C", "Inferno Shell", { damageMult = 1.45, targetsMult = 1.3, burnDps = 6, burnSeconds = 4 } },
	{ "GRENADIER", "Cluster", 4, "B", "Fire Bomblets", { damageMult = 1.4, targetsMult = 1.3, burnDps = 2, burnSeconds = 2 } },
	{ "GRENADIER", "Cluster", 4, "C", "Wide Scatter", { damageMult = 1.3, targetsMult = 1.45, splashMult = 1.3 } },
	{ "GRENADIER", "Cluster", 5, "B", "Firecracker Rain", { damageMult = 1.4, targetsMult = 1.35, bombletGenerations = 3 } },
	{ "GRENADIER", "Cluster", 5, "C", "Thumper Shells", { damageMult = 1.45, targetsMult = 1.3, knockback = 2, stunSeconds = 0.2 } },
	{ "GRENADIER", "Concussive", 4, "B", "Aftershock", { damageMult = 1.8, stunSeconds = 0.5 } },
	{ "GRENADIER", "Concussive", 4, "C", "Armour Splitter", { damageMult = 1.8, armoredMult = 1.5, stripsArmor = true } },
	{ "GRENADIER", "Concussive", 5, "B", "Seismic Charge", { damageMult = 2.4, knockback = 10 } },
	{ "GRENADIER", "Concussive", 5, "C", "Rockfall", { damageMult = 2.3, stunSeconds = 0.5, stunsBosses = true } },
}

local function pathOf(key: string, id: string): (any, number)
	local def = Config.Towers[key]
	for i, path in def.paths do
		if path.id == id then
			return path, i
		end
	end
	error(`{key} has no path {id}`)
end

local function close(a: number, b: number): boolean
	return math.abs(a - b) <= 1e-5 * math.max(1, math.abs(b))
end

test("the 36 options: each row is the build under it plus PLAN's cells, nothing else", function()
	local seen = 0
	for _, o in OPTIONS do
		local key, id, tier, letter, name, cells = o[1], o[2], o[3], o[4], o[5], o[6]
		local path = pathOf(key, id)
		local picks = if tier == 4 then letter else "A" .. letter
		local row = Upgrades.row(path, tier, picks)
		local below = if tier == 4 then Upgrades.row(path, 3) else Upgrades.row(path, 4, "A")
		local where = `{key} {id} {tier}{letter}`
		ok(row ~= nil, `{where}: has a row`)
		eq(row.name, name, `{where}: name`)
		eq(row.option, letter, `{where}: letter`)
		eq(row.cost, Upgrades.row(path, tier, if tier == 4 then "A" else "AA").cost, `{where}: same price as A (#277)`)
		for field, value in below do
			if type(value) == "number" and field ~= "cost" then
				local cell = cells[field]
				local want = if MULT[field] then value * (cell or 1) elseif cell then math.max(value, cell) else value
				ok(close(row[field], want), `{where}: {field} {row[field]} ~= {want}`)
			elseif type(value) == "boolean" and field ~= "swapsModel" then
				eq(row[field], value or cells[field] == true, `{where}: {field}`)
			end
		end
		seen += 1
	end
	eq(seen, 36, "36 options")
	-- Every starter slot has exactly A, B and C, and the PLAN list above is all of them.
	for _, key in { "SCOUT", "SNIPER", "GRENADIER" } do
		for _, path in Config.Towers[key].paths do
			eq(table.concat(Upgrades.options(path, 4, ""), ""), "ABC", `{key} {path.id} T4`)
		end
	end
end)

test("Strip (s): a stripped armoured dino is hurt by a non-piercing hit until the strip runs out", function()
	local strip = Config.Tuning.StripS
	eq(strip, 3, "Tuning Strip (s) seed")
	ok(not Combat.canHurt(true, false, false, 0, 10), "armoured, no pierce: no damage")
	local untilTime = Combat.stripUntil(0, 10, strip)
	eq(untilTime, 13, "bare for 3 s")
	ok(Combat.canHurt(true, false, false, untilTime, 12.9), "stripped: a non-piercing tower hurts it")
	ok(not Combat.canHurt(true, false, false, untilTime, 13), "armour back after 3 s")
	eq(Combat.stripUntil(untilTime, 11, strip), 14, "a fresh strip extends it")
	eq(Combat.stripUntil(20, 11, strip), 20, "never cuts a longer strip short")
	eq(Combat.stripUntil(5, 11, 0), 5, "no Strip (s), no change")
	ok(Combat.canHurt(true, false, true, 0, 10), "a Tranq chill strip still opens armour")
	ok(Combat.canHurt(false, false, false, 0, 10) and Combat.canHurt(true, true, false, 0, 10), "unarmoured / piercing as before")
end)

test("Strips armour on a hit: the four strip options strip on their hits; the Tranq Station's strip stays its chill", function()
	local function stats(key: string, id: string, tier: number, picks: string)
		local _, i = pathOf(key, id)
		local tiers, all = { 0, 0, 0 }, { "", "", "" }
		tiers[i], all[i] = tier, picks
		return TowerStats.compute(Config.Towers[key], tiers, all)
	end
	ok(stats("SCOUT", "Trigger Happy", 5, "AC").stripsOnHit, "Shredder")
	ok(stats("SCOUT", "Hardliner", 4, "B").stripsOnHit, "Cracking Shot")
	ok(stats("SCOUT", "Hardliner", 5, "BA").stripsOnHit, "Cracking Shot under any T5")
	ok(stats("SNIPER", "Deadeye", 5, "AC").stripsOnHit, "Shatterline")
	ok(stats("GRENADIER", "Concussive", 4, "C").stripsOnHit, "Armour Splitter")
	ok(not stats("SCOUT", "Hardliner", 5, "AA").stripsOnHit, "option A builds don't strip")
	ok(not stats("GRENADIER", "Concussive", 5, "AA").stripsOnHit, "Concussive 5A doesn't strip")
	-- The Tranq Station's own Strips armour (its chill) is not a strip on its darts' hits.
	local chillers = 0
	for i, path in Config.Towers.CHILLER.paths do
		for tier = 1, 5 do
			local picks = if tier == 4 then "A" elseif tier == 5 then "AA" else ""
			local row = Upgrades.row(path, tier, picks)
			if row.stripsArmor then
				local tiers, all = { 0, 0, 0 }, { "", "", "" }
				tiers[i], all[i] = tier, picks
				local s = TowerStats.compute(Config.Towers.CHILLER, tiers, all)
				ok(s.stripsArmor and not s.stripsOnHit, `CHILLER {path.id} T{tier}: chill strip only`)
				chillers += 1
			end
		end
	end
	ok(chillers > 0, "a Tranq Station tier strips armour")
end)

test("Boss mark %, knockback and bomblet stun/knockback/burn reach the starter towers' stats", function()
	local function stats(key: string, tiers: { number }, picks: { string })
		return TowerStats.compute(Config.Towers[key], tiers, picks)
	end
	eq(stats("SCOUT", { 5, 0, 0 }, { "AC", "", "" }).bossMarkPercent, 40, "Trophy Spotter boss mark")
	eq(stats("SNIPER", { 0, 4, 0 }, { "", "B", "" }).bossMarkPercent, 25, "Painted Target boss mark")
	eq(stats("SNIPER", { 0, 5, 0 }, { "", "BC", "" }).bossMarkPercent, 40, "Kill Order: the higher boss mark")
	eq(stats("SNIPER", { 4, 0, 0 }, { "B", "", "" }).knockback, 3, "Wind Shear knockback")
	eq(stats("SNIPER", { 0, 0, 5 }, { "", "", "AC" }).knockback, 6, "Hammer Shot knockback")
	local thump = stats("GRENADIER", { 0, 5, 0 }, { "", "AC", "" })
	ok(thump.bomblets > 0 and thump.knockback == 2 and thump.stunSeconds == 0.2, "Thumper Shells: bomblets carry its knockback and stun")
	-- Fire Bomblets: Cluster's own burn lights its bomblets ...
	local fire = stats("GRENADIER", { 0, 4, 0 }, { "", "B", "" })
	eq(fire.bombletBurnDps, 2, "Fire Bomblets burn")
	eq(fire.bombletBurnSeconds, 2, "Fire Bomblets seconds")
	local rain = stats("GRENADIER", { 0, 5, 0 }, { "", "BB", "" })
	ok(rain.bombletBurnDps == 2 and rain.bombletGenerations == 3, "Firecracker Rain after Fire Bomblets: three bursts, all burning")
	-- ... a Blast burn never does, even with Cluster bomblets on the other path.
	local blast = stats("GRENADIER", { 5, 2, 0 }, { "AA", "", "" })
	ok(blast.burnDps > 0 and blast.bomblets > 0, "Blast 5A + Cluster 2: a burning shell with bomblets")
	eq(blast.bombletBurnDps, 0, "the Blast burn doesn't ride Cluster's bomblets")
	eq(stats("GRENADIER", { 0, 5, 0 }, { "", "AA", "" }).bombletBurnDps, 0, "Cluster 5A: no fires")
	-- Seismic Charge never moves a boss; Rockfall stuns bosses.
	local seismic = stats("GRENADIER", { 0, 0, 5 }, { "", "", "AB" })
	eq(seismic.knockback, 10, "Seismic Charge knockback")
	ok(not Ballista.movesBoss(true, nil) and Ballista.movesBoss(false, nil), "a knockback never moves a boss")
	local rock = stats("GRENADIER", { 0, 0, 5 }, { "", "", "AC" })
	ok(rock.stunsBosses and rock.stunSeconds >= 0.5, "Rockfall stuns bosses")
end)
