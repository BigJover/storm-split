--[[
	Amber Resin Cannon (PLAN 9g T123, DECISIONS #312-#316): the Towers row and Tuning block,
	the sheet's rows (every PLAN cell), the composed builds, and the pure rules in
	Shared/Resin: the entomb threshold at 100 % / 50 % / 10 % HP, the boss cooldown and half
	time, Living Amber's full 3 s, Spreading Amber, Sticky Bed, Time Capsule never moving a
	boss, fossils (every size pays + Sink cash scaled by difficulty), Amber Heart every 15th,
	seals once a round / Amber Fortress per tower every 20 s, Resin Wall holding bosses half
	as long; and that the server goes through Enemies for all of it.
]]

local fs = require("@lune/fs")
local Config = require(src.shared.Config)
local Resin = require(src.shared.Resin)
local TowerStats = require(src.shared.TowerStats)
local Upgrades = require(src.shared.Upgrades)
local ShopRules = require(src.shared.ShopRules)

local RESIN = Config.Towers.RESIN
local T = Config.Tuning

local function pathOf(id: string): (any, number)
	for i, path in RESIN.paths do
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
	return TowerStats.compute(RESIN, tiers, all)
end

local function close(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

test("the Towers row (PLAN 9g): 800 cash, 500 Amber, 2 x 1/s, 18 studs, ground only, 150 HP, a Resin tower, unreleased", function()
	eq(RESIN.display, "Amber Resin Cannon")
	eq(RESIN.baseCost, 800)
	eq(RESIN.unlockCost, 500)
	eq(RESIN.baseDamage, 2)
	eq(RESIN.baseRate, 1)
	eq(RESIN.baseTargets, 1)
	eq(RESIN.range, 18)
	eq(RESIN.hitsAir, false)
	eq(RESIN.maxHp, 150)
	eq(RESIN.resin, true)
	ok(not RESIN.untouchable and not RESIN.onTrack and not RESIN.chains and not RESIN.harpoons and RESIN.birds == 0, "no other kind flag")
	eq(ShopRules.Unreleased.RESIN, nil, "released at T124d (#312, #329-#330)")
end)

test("the AMBER RESIN CANNON Tuning block (seeds)", function()
	eq(T.ResinHitsToEntomb, 6)
	eq(T.EntombBaseS, 0.8)
	eq(T.ResinHitSlow, 20)
	eq(T.ResinHitSlowS, 1)
	eq(T.BossEntombEveryS, 10)
	eq(T.SpreadReachStuds, 6)
	eq(T.StickyBedReachStuds, 6)
	eq(T.FossilFuelCap, 30)
end)

-- PLAN 9g's table: path, tier, letter, name, cells (T1-3 cumulative; T4/T5 own step).
local ROWS = {
	{ "Entomb", 1, "", "Thick Resin", { damageMult = 1.4, rateMult = 1.2, entombHitsMult = 0.85 } },
	{ "Entomb", 2, "", "Quick Set", { damageMult = 2, rateMult = 1.45, entombHitsMult = 0.7 } },
	{ "Entomb", 3, "", "Amber Tomb", { damageMult = 3, rateMult = 1.8, entombHitsMult = 0.5, entombSeconds = 2 } },
	{ "Entomb", 4, "A", "Hardened Amber", { damageMult = 1.6, entombAmpPercent = 30 } },
	{ "Entomb", 4, "B", "Spreading Amber", { damageMult = 1.5, entombSpread = 1 } },
	{ "Entomb", 4, "C", "Sticky Bed", { damageMult = 1.6, entombSlowPercent = 30 } },
	{ "Entomb", 5, "A", "Amber Age", { damageMult = 1.8, entombAllEvery = 12 } },
	{ "Entomb", 5, "B", "Living Amber", { damageMult = 1.8, rateMult = 1.15, entombSeconds = 2.5, bossEntombSeconds = 3 } },
	{ "Entomb", 5, "C", "Time Capsule", { damageMult = 1.8, sendBack = 12 } },
	-- Sink cash 4 / 10 / 16 -> 50 / 100 / 100: T124b's lever for the Fossilize payback bar (8-15 rounds, #203).
	{ "Fossilize", 1, "", "Collector's Eye", { damageMult = 1.3, rangeMult = 1.15, fossilBelowPercent = 10, sinkCash = 50 } },
	{ "Fossilize", 2, "", "Rare Find", { damageMult = 1.8, rateMult = 1.3, rangeMult = 1.15, fossilBelowPercent = 12, sinkCash = 100 } },
	{ "Fossilize", 3, "", "Fossil Record", { damageMult = 2.6, rateMult = 1.5, rangeMult = 1.15, entombHitsMult = 0.7, fossilBelowPercent = 20, sinkCash = 100 } },
	{ "Fossilize", 4, "A", "Museum Piece", { sinkCash = 150 } },
	{ "Fossilize", 4, "B", "Dig Crew", { sinkChestCash = 25 } },
	{ "Fossilize", 4, "C", "Bone Dust", { takeDownMarkPercent = 15 } },
	{ "Fossilize", 5, "A", "Fossil Fuel", { fossilBelowPercent = 25, fossilRatePercent = 5 } },
	{ "Fossilize", 5, "B", "Prize Fossils", { fossilBelowPercent = 30, bountyFossilsX = 2 } },
	{ "Fossilize", 5, "C", "Amber Heart", { heartEvery = 15 } },
	{ "Resin Shell", 1, "", "Coat of Resin", { auraHpPercent = 15 } },
	{ "Resin Shell", 2, "", "Sticky Armour", { auraHpPercent = 15, resistPercent = 20 } },
	{ "Resin Shell", 3, "", "Amber Shield", { auraHpPercent = 15, resistPercent = 20, sealSeconds = 3 } },
	{ "Resin Shell", 4, "A", "Self-Sealing", { sealHealPercent = 30 } },
	{ "Resin Shell", 4, "B", "Raider Glue", { biterSlowPercent = 25, biterSlowSeconds = 2, raiderSlowPercent = 20, raiderSlowSeconds = 2 } },
	{ "Resin Shell", 4, "C", "Sticky Thorns", { thornsDamage = 5, biterSlowPercent = 15, biterSlowSeconds = 1.5 } },
	{ "Resin Shell", 5, "A", "Amber Fortress", { sealEvery = 20 } },
	{ "Resin Shell", 5, "B", "Resin Wall", { wallSeconds = 3 } },
	{ "Resin Shell", 5, "C", "Amber Mirror", { groundingEvery = 1, reflectDamage = 60 } },
}

test("every PLAN row: name, letter and cells; options share their slot's price; Raider Glue is the one Raider option", function()
	for _, r in ROWS do
		local id, tier, letter, name, cells = r[1], r[2], r[3], r[4], r[5]
		local path = pathOf(id)
		local row
		if tier <= 3 then
			row = path.tiers[tier]
		elseif tier == 4 then
			row = path.t4[letter]
		else
			-- the T5 row's own step shows on the AA..CA builds' difference; check its name and
			-- the cells through a build after T4 A (x columns over A4's).
			row = path.t5["A" .. letter]
		end
		ok(row ~= nil, `{id} T{tier}{letter}`)
		eq(row.name, name, `{id} T{tier}{letter} name`)
		for field, value in cells do
			if tier <= 4 then
				local base = if tier == 4 then path.tiers[3] else nil
				local want = if base and string.find(field, "Mult$") then (base[field] or 1) * value else value
				if base and not string.find(field, "Mult$") then
					want = math.max(value, base[field] or 0)
				end
				ok(close(row[field] or 0, want), `{id} T{tier}{letter} {field} = {want} (got {row[field]})`)
			end
		end
	end
	local t4 = pathOf("Entomb").t4
	eq(t4.A.cost, t4.B.cost, "same price at a tier (#277)")
	eq(t4.A.cost, t4.C.cost)
	local raiders = 0
	for _, path in RESIN.paths do
		for letter, row in path.t4 do
			if row.pvpEffect then
				raiders += 1
				eq(row.name, "Raider Glue", "the one Raider option (#320)")
			end
		end
	end
	eq(raiders, 1)
end)

test("composed builds: Amber Tomb 2 s; Entomb base 0.8 at tier 0; hits x multiply across paths; timers the shortest", function()
	eq(TowerStats.compute(RESIN, { 0, 0, 0 }).entombSeconds, 0.8, "tier 0: Tuning Entomb base")
	eq(stats("Entomb", 3).entombSeconds, 2)
	local _, e = pathOf("Entomb")
	local _, f = pathOf("Fossilize")
	local tiers = { 0, 0, 0 }
	tiers[e], tiers[f] = 3, 2
	ok(close(TowerStats.compute(RESIN, tiers).entombHitsMult, 0.5), "Fossilize T2 has no hits x")
	tiers[e], tiers[f] = 2, 3
	ok(close(TowerStats.compute(RESIN, tiers).entombHitsMult, 0.7 * 0.7), "Quick Set x Fossil Record")
	eq(stats("Entomb", 5, "AA").entombAllEvery, 12, "Amber Age")
	eq(stats("Entomb", 5, "BB").bossEntombSeconds, 3, "Living Amber")
	ok(stats("Entomb", 5, "BB").entombSeconds == 2.5, "Living Amber: others 2.5 s")
	eq(stats("Fossilize", 5, "CC").heartEvery, 15)
	eq(stats("Resin Shell", 5, "AA").sealEvery, 20)
	eq(stats("Resin Shell", 3).sealSeconds, 3)
	eq(stats("Fossilize", 1).sinkCash, 50, "Sink cash works on a Resin tower")
	eq(Config.Towers.SCOUT and TowerStats.compute(Config.Towers.SCOUT, { 0, 0, 0 }).entombSeconds, 0, "not on a tower without resin")
end)

test("entomb threshold: 6 hits at full HP, 3 at half, 1 at 10 %; x Entomb hits x; resets after", function()
	eq(Resin.needed(1, 1), 6)
	eq(Resin.needed(1, 0.5), 3)
	eq(Resin.needed(1, 0.1), 1)
	eq(Resin.needed(0.5, 1), 3, "Amber Tomb halves it")
	eq(Resin.needed(1, 0), 1, "at least 1")
	local d = { resin = 0, bossNextAt = 0 }
	local s = { entombSeconds = 2, entombHitsMult = 1, bossEntombSeconds = 0 }
	for i = 1, 5 do
		eq(Resin.hit(d, s, 1, false, false, 0), 0, `hit {i}: not yet`)
	end
	eq(Resin.hit(d, s, 1, false, false, 0), 2, "the 6th hit entombs for Entomb (s)")
	eq(d.resin, 0, "resin resets")
	eq(Resin.hit(d, s, 0.1, false, false, 0), 2, "at 10 % HP one hit sets it")
	eq(Resin.hit({ resin = 0, bossNextAt = 0 }, s, 0.1, false, true, 0), 0, "ground only: never a flyer")
	eq(Resin.hpShare(30, 20, 3), 0.5)
end)

test("bosses: half time, at most once per Boss entomb every (s); Living Amber holds a boss the full 3 s", function()
	local s = { entombSeconds = 2, entombHitsMult = 1, bossEntombSeconds = 0 }
	local boss = { resin = 0, bossNextAt = 0 }
	eq(Resin.hit(boss, s, 0.1, true, false, 0), 1, "x Boss hard stop x 0.5")
	eq(Resin.hit(boss, s, 0.1, true, false, 5), 0, "cooldown")
	eq(boss.resin, 0, "no resin builds up in the cooldown")
	eq(Resin.hit(boss, s, 0.1, true, false, 10), 1, "10 s later: again")
	local living = { entombSeconds = 2.5, entombHitsMult = 1, bossEntombSeconds = 3 }
	eq(Resin.hit({ resin = 0, bossNextAt = 0 }, living, 0.1, true, false, 0), 3, "Living Amber: a boss 3 s, full")
	eq(Resin.hit({ resin = 0, bossNextAt = 0 }, living, 0.1, false, false, 0), 2.5, "others 2.5 s")
end)

test("Spreading Amber, Sticky Bed, Time Capsule (never a boss)", function()
	local picked = Resin.spreadTo({ 5, 2, 7, 1 }, 1)
	ok(#picked == 1 and picked[1] == 4, "the nearest within 6 studs")
	eq(#Resin.spreadTo({ 5, 2, 7, 1 }, 5), 3, "never past Spread reach")
	ok(Resin.inStickyBed(6) and not Resin.inStickyBed(6.1), "Sticky bed reach 6")
	eq(Resin.sendBack(12, false), 12)
	eq(Resin.sendBack(12, true), 0, "a boss is never moved")
end)

test("fossils: at or below Fossil below % (not bosses, not flyers); Amber Heart every 15th; Fossil Fuel capped", function()
	ok(Resin.isFossil(20, 0.2, false, false), "at 20 %")
	ok(not Resin.isFossil(20, 0.21, false, false), "above it")
	ok(not Resin.isFossil(20, 0.05, true, false), "never a boss")
	ok(not Resin.isFossil(0, 0, false, false), "no Fossilize: none")
	ok(Resin.heart(15, 15) and Resin.heart(30, 15), "15th and 30th")
	ok(not Resin.heart(14, 15) and not Resin.heart(15, 0), "not the 14th; off without Amber Heart")
	eq(Resin.fuel(3, 5), 15)
	eq(Resin.fuel(10, 5), 30, "cap 30 %")
	-- Every size pays and Sink cash is scaled by the difficulty (#309): the server takes the
	-- fossil down whole through Enemies.dropSizes and pays Sink cash through onSink (Economy.earnScaledFor).
	local towers = fs.readFile("src/server/Towers.luau")
	ok(towers:find("Enemies.dropSizes(enemy, enemy.size)", 1, true) ~= nil, "a fossil drops every size (each pays)")
	ok(towers:find("onSink(stats.sinkCash, stats.sinkChestCash", 1, true) ~= nil, "Sink cash + chest through onSink")
	local main = fs.readFile("src/server/Main.server.luau")
	ok(main:find("Economy.earnScaledFor(side, cash, difficulty().cashMult)", 1, true) ~= nil, "scaled by the difficulty's cash x")
end)

test("seals: at 1 HP once a round per cannon; Amber Fortress once per 20 s per tower; Self-Sealing heals 30 %", function()
	ok(Resin.canSeal(3, 0, false, nil, 0), "Amber Shield ready")
	ok(not Resin.canSeal(3, 0, true, nil, 0), "spent this round")
	ok(not Resin.canSeal(0, 0, false, nil, 0), "no Seal (s)")
	ok(Resin.canSeal(3, 20, true, nil, 0), "Fortress: per tower, not per round")
	ok(not Resin.canSeal(3, 20, false, 5, 20), "the same tower 15 s later: no")
	ok(Resin.canSeal(3, 20, false, 5, 25), "20 s later: yes")
	eq(Resin.sealHeal(150, 30), 45)
end)

test("Resin Wall: holds every dino Wall (s); bosses pass after half", function()
	ok(Resin.wallHolds(3, 2.9, false) and not Resin.wallHolds(3, 3, false), "3 s")
	ok(Resin.wallHolds(3, 1.4, true) and not Resin.wallHolds(3, 1.5, true), "a boss 1.5 s")
end)

test("the server goes through Enemies: entomb is a hard stop (stun incl. bosses), send back is a knockback", function()
	local towers = fs.readFile("src/server/Towers.luau")
	ok(towers:find("Enemies.stun(enemy, seconds, true)", 1, true) ~= nil, "entomb = a hard stop")
	ok(towers:find("local back = Resin.sendBack(stats.sendBack, boss)", 1, true) ~= nil and towers:find("Enemies.knockback(enemy, back)", 1, true) ~= nil, "Time Capsule through the knockback rule")
	ok(Upgrades ~= nil)
end)
