--[[
	Batch 9f (PLAN Phase 9, DECISIONS #298-#302): the hero B/C options. Each option's
	composed row is the build under it plus exactly the cells PLAN gives (x columns
	multiply, Fire mode / Burst count / Pellets replace, amounts take the higher, flags add);
	no option touches Damage x; every tier 6 still works after any tier-5 pick (#300); and
	the wirings PLAN lists (Twin Burst with dual guns, Slam Fire auto with 2 per pull, Twin
	Slug, Bird Shot, Mending Salve's Heal regen).
]]

local Config = require(src.shared.Config)
local HeroStats = require(src.shared.HeroStats)
local GunRules = require(src.shared.GunRules)
local Combat = require(src.shared.Combat)
local fs = require("@lune/fs")
local Upgrades = require(src.shared.Upgrades)

-- Heroes whose B/C rows are in (9f lands hero by hero).
local DONE = { PISTOL = true, RIFLE = true, SHOTGUN = true, MEDIC = true }

-- PLAN 9f, cell by cell: path, tier, letter, name, cells (own step).
local OPTIONS = {
	PISTOL = {
		{ "Gunslinger", 4, "B", "Deep Cylinders", { rateMult = 1.15, magazineMult = 1.5 } },
		{ "Gunslinger", 4, "C", "Crossdraw", { rateMult = 1.15, reloadMult = 0.65 } },
		{ "Gunslinger", 5, "B", "Twin Burst", { rateMult = 1.3, fireMode = "burst", burstCount = 3, magazineMult = 1.3 } },
		{ "Gunslinger", 5, "C", "Steady Pair", { rateMult = 1.1, recoilMult = 0.5, spreadMult = 0.8 } },
		{ "Marksman", 4, "B", "Quick Cock", { rateMult = 1.2 } },
		{ "Marksman", 4, "C", "Breath Control", { rangeMult = 1.35, recoilMult = 0.5 } },
		{ "Marksman", 5, "B", "Quick Scope", { rateMult = 1.7, recoilMult = 0.7 } },
		{ "Marksman", 5, "C", "Hunter's Mark", { markPercent = 35, spreadMult = 0.8 } },
		{ "Trick Shot", 4, "B", "Bank Shot", { bounces = 2 } },
		{ "Trick Shot", 4, "C", "Quick Fingers", { rateMult = 1.07, reloadMult = 0.7 } },
		{ "Trick Shot", 5, "B", "Pinball", { rateMult = 1.17, bounces = 3, magazineMult = 1.5 } },
		{ "Trick Shot", 5, "C", "Dart Storm", { rateMult = 1.15, abilityCooldownMult = 0.75, bounces = 3 } },
	},
	RIFLE = {
		{ "Stalker", 4, "B", "Snap Bursts", { rateMult = 1.2 } },
		{ "Stalker", 4, "C", "Quick Mag", { reloadMult = 0.75 } },
		{ "Stalker", 5, "B", "Marking Burst", { rateMult = 1.1, burstCount = 4, markPercent = 25, magazineMult = 1.3 } },
		{ "Stalker", 5, "C", "Rapid Volley", { rateMult = 1.35, recoilMult = 0.5, magazineMult = 1.5 } },
		{ "Heavy", 4, "B", "Steady Sling", { recoilMult = 0.65 } },
		{ "Heavy", 4, "C", "Quick Belt", { recoilMult = 0.8, reloadMult = 0.7 } },
		{ "Heavy", 5, "B", "Hot Barrel", { rateMult = 1.5, spinUp = 1.6, magazineMult = 1.3 } },
		{ "Heavy", 5, "C", "War Drum", { spinUp = 2.3, abilityCooldownMult = 0.5 } },
		{ "Special Ammo", 4, "B", "Phosphor Rounds", { burnDps = 1.1, burnSeconds = 3 } },
		{ "Special Ammo", 4, "C", "Bright Tracers", { markPercent = 30 } },
		{ "Special Ammo", 5, "B", "Fire Tips", { splashRadius = 3, burnSeconds = 2.5 } },
		{ "Special Ammo", 5, "C", "Flat Tips", { splashRadius = 3, rangeMult = 1.25 } },
	},
	SHOTGUN = {
		{ "Slug", 4, "B", "Quick Pump", { rateMult = 1.25 } },
		{ "Slug", 4, "C", "Side Saddle", { reloadMult = 0.8, magazineMult = 1.5 } },
		{ "Slug", 5, "B", "Express Slug", { rateMult = 1.6, magazineMult = 1.5, pierce = 6 } },
		{ "Slug", 5, "C", "Twin Slug", { shotsPerTrigger = 2, pierce = 4, magazineMult = 1.5, oneRoundPerTrigger = true } },
		{ "Buckshot", 4, "B", "Hot Shells", { burnDps = 2.3, burnSeconds = 3 } },
		{ "Buckshot", 4, "C", "Shell Belt", { rateMult = 1.5, magazineMult = 1.5 } },
		{ "Buckshot", 5, "B", "Flame Choke", { igniteShare = 0.9, rateMult = 1.2 } },
		{ "Buckshot", 5, "C", "Pump Storm", { rateMult = 1.5, magazineMult = 1.5 } },
		{ "Point Blank", 4, "B", "Quick Breech", { rateMult = 1.2, reloadMult = 0.65 } },
		{ "Point Blank", 4, "C", "Bird Shot", { rateMult = 1.15, hitsAir = true } },
		{ "Point Blank", 5, "B", "Breech Loader", { rateMult = 1.45, reloadMult = 0.6, magazineMult = 1.5 } },
		{ "Point Blank", 5, "C", "Slam Fire", { rateMult = 1.7, fireMode = "auto" } },
	},
	MEDIC = {
		{ "Triage", 4, "B", "Thick Gauze", { healMult = 1.55 } },
		{ "Triage", 4, "C", "Quick Kit", { abilityCooldownMult = 0.67 } },
		{ "Triage", 5, "B", "Mending Salve", { healRegen = 2, healRegenSeconds = 8 } },
		{ "Triage", 5, "C", "Field Surgeon", { abilityCooldownMult = 0.78 } },
		{ "Lever Action", 4, "B", "Long Tube", { magazineMult = 1.8 } },
		{ "Lever Action", 4, "C", "Snap Lever", { rateMult = 1.14 } },
		{ "Lever Action", 5, "B", "Triple Cycle", { burstCount = 3, rateMult = 1.33 } },
		{ "Lever Action", 5, "C", "Steady Lever", { rateMult = 1.1, recoilMult = 0.5, spreadMult = 0.6 } },
		{ "Muzzle", 4, "B", "Quick Dose", { jawLockSeconds = 2.6, rateMult = 1.12 } },
		{ "Muzzle", 4, "C", "Strap Toss", { slowPercent = 40, jawLockSpread = 2 } },
		{ "Muzzle", 5, "B", "Heavy Lids", { jawLockSeconds = 4.2 } },
		{ "Muzzle", 5, "C", "Drowsy Cloud", { slowPercent = 40, slowSeconds = 2, jawLockSpread = 4 } },
	},
}

local MULT = {
	rateMult = true, magazineMult = true, reloadMult = true, spreadMult = true, recoilMult = true,
	rangeMult = true, damageMult = true, markedDamageMult = true, abilityCooldownMult = true,
	stillRecoilMult = true, spinUp = true, healMult = true, healRadiusMult = true,
	stillSpreadMult = true, scopedSpreadMult = true,
}
local SET = { fireMode = true, burstCount = true, pellets = true }

local function pathOf(key: string, id: string): (any, number)
	for i, path in Config.Heroes[key].paths do
		if path.id == id then
			return path, i
		end
	end
	error(`{key} has no path {id}`)
end

local function close(a: number, b: number, tolerance: number?): boolean
	return math.abs(a - b) <= (tolerance or 1e-5) * math.max(1, math.abs(b))
end

local function stats(key: string, id: string, tier: number, picks: string): HeroStats.Stats
	local _, i = pathOf(key, id)
	local tiers, all = { 0, 0, 0 }, { "", "", "" }
	tiers[i], all[i] = tier, picks
	return HeroStats.compute(key, tiers, nil, nil, all) :: HeroStats.Stats
end

test("9f options: each row is the build under it plus PLAN's cells, nothing else; never Damage x", function()
	local seen = 0
	for key in DONE do
		for _, o in OPTIONS[key] do
			local id, tier, letter, name, cells = o[1], o[2], o[3], o[4], o[5]
			local path = pathOf(key, id)
			local row = Upgrades.row(path, tier, if tier == 4 then letter else "A" .. letter)
			local below = if tier == 4 then Upgrades.row(path, 3) else Upgrades.row(path, 4, "A")
			local where = `{key} {id} {tier}{letter}`
			ok(row ~= nil, `{where}: has a row`)
			eq(row.name, name, `{where}: name`)
			eq(row.option, letter, `{where}: letter`)
			eq(row.cost, Upgrades.row(path, tier, if tier == 4 then "A" else "AA").cost, `{where}: same price as A (#277)`)
			eq(cells.damageMult, nil, `{where}: no Damage x (DIRECTION)`)
			eq(row.damageMult, below.damageMult, `{where}: Damage x unchanged`)
			for field, value in below do
				local cell = cells[field]
				if type(value) == "number" and field ~= "cost" then
					local want = if MULT[field] then value * (cell or 1) elseif SET[field] then (cell or value) elseif cell then math.max(value, cell) else value
					ok(close(row[field], want), `{where}: {field} {row[field]} ~= {want}`)
				elseif type(value) == "boolean" and field ~= "swapsModel" then
					eq(row[field], value or cells[field] == true, `{where}: {field}`)
				elseif field == "fireMode" then
					eq(row[field], cell or value, `{where}: fire mode`)
				end
			end
			for field in cells do
				ok(below[field] ~= nil, `{where}: {field} is a Hero Upgrades column`)
			end
			seen += 1
		end
		for _, path in Config.Heroes[key].paths do
			eq(table.concat(Upgrades.options(path, 4, ""), ""), "ABC", `{key} {path.id} T4`)
			for _, o4 in { "A", "B", "C" } do
				eq(table.concat(Upgrades.options(path, 5, o4), ""), "ABC", `{key} {path.id} T5 after {o4}`)
			end
		end
	end
	ok(seen >= 12, `options checked ({seen})`)
end)

test("9f: every tier 6 still works after any tier-5 pick, its own step on top (#300)", function()
	for key in DONE do
		for _, path in Config.Heroes[key].paths do
			local five, six = Upgrades.row(path, 5, "AA"), Upgrades.row(path, 6, "AA")
			for _, a in { "A", "B", "C" } do
				for _, b in { "A", "B", "C" } do
					local picks = a .. b
					local where = `{key} {path.id} 6{picks}`
					local r5, r6 = Upgrades.row(path, 5, picks), Upgrades.row(path, 6, picks)
					ok(r5 ~= nil and r6 ~= nil, `{where}: composes`)
					eq(r6.name, six.name, `{where}: the T6`)
					for field, v6 in six do
						local v5 = five[field]
						if field ~= "cost" and field ~= "name" and v6 ~= v5 then
							if type(v6) == "boolean" then
								eq(r6[field], true, `{where}: {field}`)
							elseif MULT[field] then
								ok(close(r6[field], r5[field] * v6 / v5, 1e-3), `{where}: {field} x{v6 / v5}`) -- Config keeps 4 decimals
							elseif SET[field] or type(v6) == "string" then
								eq(r6[field], v6, `{where}: {field}`)
							else
								ok(close(r6[field], math.max(r5[field], v6)), `{where}: {field} >= {v6}`)
							end
						end
					end
					local _, i = pathOf(key, path.id)
					local tiers, all = { 0, 0, 0 }, { "", "", "" }
					tiers[i], all[i] = 6, picks
					ok(HeroStats.compute(key, tiers, nil, nil, all) ~= nil, `{where}: hero stats`)
				end
			end
		end
	end
end)

test("9f Tracker: Twin Burst fires 3-round bursts from two guns; Hot Swap still staggers; Hunter's Mark marks", function()
	local twin = stats("PISTOL", "Gunslinger", 5, "AB")
	eq(twin.fireMode, "burst", "Twin Burst is burst fire")
	eq(twin.burstCount, 3, "3 rounds a click")
	eq(twin.guns, 2, "both guns (Dual Pistols)")
	local swap = stats("PISTOL", "Gunslinger", 6, "AB")
	ok(swap.staggeredReload and swap.fireMode == "burst" and swap.burstCount == 3, "Hot Swap after Twin Burst: staggered, still 3-round bursts")
	eq(stats("PISTOL", "Gunslinger", 6, "CC").fireMode, "semi", "Hot Swap after Steady Pair: semi, as the base")
	eq(stats("PISTOL", "Marksman", 5, "AC").markPercent, 35, "Hunter's Mark: Mark % 35")
	ok(close(stats("PISTOL", "Trick Shot", 5, "AC").abilityCooldown, stats("PISTOL", "Trick Shot", 4, "A").abilityCooldown * 0.75), "Dart Storm: Tracking Dart sooner")
	eq(stats("PISTOL", "Trick Shot", 6, "BB").bounces, 3, "Bounce Back after Pinball keeps 3 bounces")
end)

test("9f Big Game Hunter: Big Five bursts 5 and Endless Belt stops reloading after any T5; marks, Rally, blasts", function()
	for _, picks in { "AA", "AB", "AC", "BB", "CC" } do
		local five = stats("RIFLE", "Stalker", 6, picks)
		ok(five.fireMode == "burst" and five.burstCount == 5 and five.burstRecoilReset, `Big Five after {picks}: bursts of 5, recoil reset`)
		local belt = stats("RIFLE", "Heavy", 6, picks)
		ok(belt.spunUpBelt and belt.spinUp > 1, `Endless Belt after {picks}: spins up ({belt.spinUp})`)
		ok(not GunRules.usesRounds(belt, false, 1), `Endless Belt after {picks}: no rounds once fully spun up`)
		ok(GunRules.usesRounds(belt, false, 0.5), `Endless Belt after {picks}: uses rounds while spinning up`)
		local dyn = stats("RIFLE", "Special Ammo", 6, picks)
		ok(dyn.splashRadius == 6 and dyn.piercesArmor, `Dynamite Rounds after {picks}: 6 m, pierces armour`)
	end
	ok(close(stats("RIFLE", "Heavy", 5, "AB").spinUp, 1.6) and close(stats("RIFLE", "Heavy", 5, "AC").spinUp, 2.3), "Hot Barrel 1.6, War Drum 2.3")
	ok(close(stats("RIFLE", "Heavy", 5, "AC").abilityCooldown, Config.Heroes.RIFLE.abilityCooldown * 0.5), "War Drum: Rally Cry twice as often")
	local marking = stats("RIFLE", "Stalker", 5, "AB")
	ok(marking.burstCount == 4 and marking.markPercent == 25, "Marking Burst: 4-round bursts that mark 25%")
	eq(stats("RIFLE", "Special Ammo", 4, "C").markPercent, 30, "Bright Tracers: Mark % 30")
	local phosphor = stats("RIFLE", "Special Ammo", 4, "B")
	ok(close(phosphor.burnDps, 1.1) and phosphor.burnSeconds == 3, "Phosphor Rounds: burn 1.1/s for 3 s")
	eq(stats("RIFLE", "Special Ammo", 5, "AB").splashRadius, 3, "Fire Tips: 3 m blasts")
	ok(close(stats("RIFLE", "Special Ammo", 5, "AC").range, stats("RIFLE", "Special Ammo", 4, "A").range * 1.25), "Flat Tips: 25% further")
end)

test("9f Brush Beater: Twin Slug, Slam Fire (+ Quad Barrel), Bird Shot, Hot Shells, Flame Choke", function()
	local twin = stats("SHOTGUN", "Slug", 5, "AC")
	ok(twin.shotsPerTrigger == 2 and twin.pellets == 1 and twin.pierce == 4, "Twin Slug: 2 slugs per pump, each through 4")
	eq(twin.fireMode, "semi", "Twin Slug: one pump per click")
	eq(stats("SHOTGUN", "Slug", 6, "AC").shotsPerTrigger, 2, "Thunder Slug after Twin Slug: still 2 slugs")
	local slam = stats("SHOTGUN", "Point Blank", 5, "AC")
	ok(slam.fireMode == "auto" and slam.shotsPerTrigger == 2, "Slam Fire: full-auto, 2 blasts per pull")
	local quad = stats("SHOTGUN", "Point Blank", 6, "AC")
	ok(quad.fireMode == "auto" and quad.shotsPerTrigger == 4, "Quad Barrel after Slam Fire: 4 per pull, still auto")
	ok(stats("SHOTGUN", "Point Blank", 4, "C").hitsAir, "Bird Shot hits flying dinos")
	ok(not stats("SHOTGUN", "Point Blank", 4, "A").hitsAir, "Kickback doesn't")
	local hot = stats("SHOTGUN", "Buckshot", 4, "B")
	ok(close(hot.burnDps, 2.3) and hot.burnSeconds == 3, "Hot Shells: burn 2.3/s")
	ok(close(stats("SHOTGUN", "Buckshot", 5, "AB").igniteShare, 0.9), "Flame Choke: ignite tick 0.9 of a shot")
	ok(close(twin.shotDamage, stats("SHOTGUN", "Slug", 4, "A").shotDamage), "Twin Slug keeps the slug's damage per shot")
	-- T120b (#323): a Twin Slug pump fires 2 slugs from ONE round; Double Barrel spends 2.
	eq(GunRules.roundsPerTrigger(twin), 1, "Twin Slug: a pump spends 1 round")
	eq(GunRules.roundsPerTrigger(stats("SHOTGUN", "Slug", 6, "AC")), 1, "Thunder Slug after Twin Slug: still 1 round")
	local double = stats("SHOTGUN", "Point Blank", 3, "")
	ok(double.shotsPerTrigger == 2 and GunRules.roundsPerTrigger(double) == 2, "Double Barrel: 2 shots, 2 rounds")
	eq(GunRules.roundsPerTrigger(slam), 2, "Slam Fire: 2 blasts, 2 rounds")
	eq((pathOf("SHOTGUN", "Buckshot")).t5.AB.blurb, "Dragon's Breath bursts for 90% of a shot", "Flame Choke card says the 0.9 tick (T120b, #322)")
end)

test("9f Field Medic: Mending Salve's Heal regen (strongest wins, a recast refreshes, towers too); Muzzle and Lever options", function()
	local salve = stats("MEDIC", "Triage", 5, "AB")
	ok(salve.healRegen == 2 and salve.healRegenSeconds == 8, "Mending Salve: 2 HP/s for 8 s")
	ok(salve.healRepairsTowers, "with Patch Up, standing towers are healed too")
	eq(stats("MEDIC", "Triage", 5, "AA").healRegen, 0, "Second Wind: no regen")
	eq(stats("MEDIC", "Triage", 6, "BB").healRegen, 2, "Rapid Response after Mending Salve keeps it")
	-- the rule: flat HP/s for the time; no stacking; a recast refreshes
	local r = Combat.regenAfter(nil, 10, 2, 8) :: Combat.Regen
	ok(r.hps == 2 and r.untilTime == 18, "a fresh regen: 2 HP/s until 18")
	eq(Combat.regenHeal(r, 11, 1), 2, "one second: 2 HP")
	eq(Combat.regenHeal(r, 18.5, 1), 1, "the last half second only")
	eq(Combat.regenHeal(r, 20, 1), 0, "run out")
	local again = Combat.regenAfter(r, 12, 2, 8) :: Combat.Regen
	ok(again.hps == 2 and again.untilTime == 20, "a recast refreshes the time, doesn't stack the HP/s")
	local weaker = Combat.regenAfter(again, 13, 1, 4) :: Combat.Regen
	ok(weaker.hps == 2 and weaker.untilTime == 20, "a weaker one never lowers or shortens it")
	eq(Combat.regenAfter(nil, 10, 0, 0), nil, "no regen on the build: none")
	local hero = fs.readFile("src/server/Hero.luau")
	ok(hero:find("playerRegens[other] = Combat.regenAfter(playerRegens[other], os.clock(), stats.healRegen, stats.healRegenSeconds)", 1, true) ~= nil, "every healed hunter (own team) gets it")
	ok(hero:find("towerRegens[tower] = Combat.regenAfter(towerRegens[tower], os.clock(), stats.healRegen, stats.healRegenSeconds)", 1, true) ~= nil, "every healed standing tower gets it")
	ok(hero:find("Towers.heal(tower, Combat.regenHeal(r, now, dt))", 1, true) ~= nil and hero:find("Health.heal(player, Combat.regenHeal(r, now, dt))", 1, true) ~= nil, "ticked each frame")
	-- Muzzle and Lever
	local cloud = stats("MEDIC", "Muzzle", 5, "AC")
	ok(cloud.jawLockSpread == 4 and cloud.jawLockSeconds == 3 and cloud.slowPercent == 40 and cloud.slowSeconds == 2, "Drowsy Cloud after Long Dose: lock 3 s spreads 4 studs, slow 40% for 2 s")
	local lights = stats("MEDIC", "Muzzle", 6, "BB")
	ok(lights.jawLockSeconds >= 4 and lights.jawLockSpread == 9, "Lights Out after Heavy Lids: at least 4 s, 9 studs")
	local triple = stats("MEDIC", "Lever Action", 5, "AB")
	ok(triple.fireMode == "burst" and triple.burstCount == 3, "Triple Cycle: 3-round bursts")
end)
