--[[
	Batch 9d (PLAN Phase 9, DECISIONS #292-#295): the B/C options of Tranq Station, Supply
	Camp, Field Hospital and Armory. Each option's composed row is the build under it plus
	exactly the cells PLAN gives (x columns multiply, amounts take the higher, flags add,
	Freeze every (s) is set), on every one of the 9 builds per path; and the new generic
	mechanics (Shared/TowerPerks): Raider sting (Sleeper Darts, Barbed Wire), Bounty cash
	(Bounty Board / Bounty Hall), Biter slow (Bitter Tonic / Bitter Brew).
]]

local Config = require(src.shared.Config)
local TowerStats = require(src.shared.TowerStats)
local TowerPerks = require(src.shared.TowerPerks)
local Upgrades = require(src.shared.Upgrades)

-- PLAN 9d, cell by cell: tower key, path, tier, letter, name, cells (own step), Raider?
local MULT = {
	damageMult = true, rateMult = true, targetsMult = true, rangeMult = true, armoredMult = true, bossMult = true,
	splashMult = true, incomeMult = true, healMult = true, hunterRecoilMult = true, hunterReloadMult = true, hunterSpreadMult = true,
}
local SET = { freezeEvery = true }
local OPTIONS = {
	{ "CHILLER", "Sedate", 4, "B", "Drowsy Trail", { damageMult = 1.3, rateMult = 1.15132, slowPercent = 65, slowLinger = 4 } },
	{ "CHILLER", "Sedate", 4, "C", "Sleeper Darts", { damageMult = 1.3, rateMult = 1.15132, slowPercent = 72, raiderSlowPercent = 30, raiderSlowSeconds = 2 }, true },
	{ "CHILLER", "Sedate", 5, "B", "Fog Bank", { damageMult = 1.2972, rateMult = 1.14857, slowPercent = 80, rangeMult = 1.6, slowLinger = 3 } },
	{ "CHILLER", "Sedate", 5, "C", "Long Nap", { damageMult = 1.2972, rateMult = 1.14857, slowPercent = 80, slowLinger = 7 } },
	{ "CHILLER", "Knockout", 4, "B", "Long Sleep", { damageMult = 1.34959, rateMult = 1.42308, freezeSeconds = 1.8, freezeDamage = 3 } },
	{ "CHILLER", "Knockout", 4, "C", "Knockout Ring", { damageMult = 1.34959, rateMult = 1.42308, rangeMult = 1.3, freezeEvery = 6, freezeDamage = 3 } },
	{ "CHILLER", "Knockout", 5, "B", "Snooze Alarm", { damageMult = 1.3494, rateMult = 1.41769, freezeEvery = 4, freezeSeconds = 2, freezeDamage = 5 } },
	{ "CHILLER", "Knockout", 5, "C", "Sleep Wave", { damageMult = 1.3494, rateMult = 1.41769, rangeMult = 1.6, freezeSeconds = 2, freezeDamage = 5 } },
	{ "CHILLER", "Weak Spot", 4, "B", "Pack Instinct", { damageMult = 1.9, auraRatePercent = 20, brittlePercent = 40 } },
	{ "CHILLER", "Weak Spot", 4, "C", "Big Game Weakness", { damageMult = 1.9, bossMarkPercent = 40, brittlePercent = 40 } },
	{ "CHILLER", "Weak Spot", 5, "B", "Feeding Frenzy", { damageMult = 1.9, auraRatePercent = 35, brittlePercent = 60 } },
	{ "CHILLER", "Weak Spot", 5, "C", "Killing Ground", { damageMult = 1.9, bossMarkPercent = 75, brittlePercent = 60 } },
	{ "QUARTERMASTER", "Yield", 4, "B", "Savings Jar", { incomeMult = 1.45, interestPercent = 3, interestCap = 250 } },
	{ "QUARTERMASTER", "Yield", 4, "C", "Bounty Board", { incomeMult = 1.3, bountyCash = 8 } },
	{ "QUARTERMASTER", "Yield", 5, "B", "Gold Reserve", { incomeMult = 1.3, interestPercent = 8, interestCap = 1000 } },
	{ "QUARTERMASTER", "Yield", 5, "C", "Bounty Hall", { incomeMult = 1.3, bountyCash = 25 } },
	{ "QUARTERMASTER", "Airdrop", 4, "B", "Heavy Crates", { chestCash = 790 } },
	{ "QUARTERMASTER", "Airdrop", 4, "C", "Extra Drop", { chests = 4 } },
	{ "QUARTERMASTER", "Airdrop", 5, "B", "Supply Fleet", { chests = 5, chestCash = 790 } },
	{ "QUARTERMASTER", "Airdrop", 5, "C", "Gold Crates", { chests = 4, chestCash = 900 } },
	{ "QUARTERMASTER", "Logistics", 4, "B", "Bulk Buyer", { discountPercent = 18 } },
	{ "QUARTERMASTER", "Logistics", 4, "C", "Scrap Dealer", { sellRefund = 0.97 } },
	{ "QUARTERMASTER", "Logistics", 5, "B", "Wholesale", { discountPercent = 32 } },
	{ "QUARTERMASTER", "Logistics", 5, "C", "Depot", { auraRatePercent = 20, discountPercent = 15, sellRefund = 0.95 } },
	{ "HOSPITAL", "Ward", 4, "B", "Quick Stitch", { reviveSpeed = 1 } },
	{ "HOSPITAL", "Ward", 4, "C", "Big Tent", { rangeMult = 1.25 } },
	{ "HOSPITAL", "Ward", 5, "B", "Field Ward", { healMult = 1.2, rangeMult = 1.4 } },
	{ "HOSPITAL", "Ward", 5, "C", "Rapid Recovery", { healMult = 1.25, reviveSpeed = 2 } },
	{ "HOSPITAL", "Rescue", 4, "B", "Long Whistle", { rangeMult = 1.3, medKits = 3 } },
	{ "HOSPITAL", "Rescue", 4, "C", "Kit Bags", { medKits = 4 } },
	{ "HOSPITAL", "Rescue", 5, "B", "Pack Train", { rangeMult = 1.15, medKits = 5, medKitHeal = 50 } },
	{ "HOSPITAL", "Rescue", 5, "C", "Medevac", { rangeMult = 1.15, medKitHeal = 45, rescueRespawnMult = 0.35 } },
	{ "HOSPITAL", "Tonic", 4, "B", "Hot Coffee", { auraRatePercent = 18, auraHpPercent = 25 } },
	{ "HOSPITAL", "Tonic", 4, "C", "Bitter Tonic", { auraHpPercent = 25, biterSlowPercent = 25, biterSlowSeconds = 2 } },
	{ "HOSPITAL", "Tonic", 5, "B", "Adrenaline", { auraRatePercent = 30, auraHpPercent = 40 } },
	{ "HOSPITAL", "Tonic", 5, "C", "Bitter Brew", { auraHpPercent = 45, biterSlowPercent = 30, biterSlowSeconds = 3 } },
	{ "ARMORY", "Plating", 4, "B", "Spiked Walls", { resistPercent = 30, thornsDamage = 10 } },
	{ "ARMORY", "Plating", 4, "C", "Barbed Wire", { resistPercent = 32, raiderSlowPercent = 20, raiderSlowSeconds = 2, raiderDamage = 10 }, true },
	{ "ARMORY", "Plating", 5, "B", "Iron Fortress", { resistPercent = 55 } },
	{ "ARMORY", "Plating", 5, "C", "Spike Fortress", { resistPercent = 40, thornsDamage = 18 } },
	{ "ARMORY", "Gunsmith", 4, "B", "Rapid Feed", { auraRatePercent = 20, auraDamagePercent = 15 } },
	{ "ARMORY", "Gunsmith", 4, "C", "Heavy Loads", { auraRatePercent = 5, auraDamagePercent = 30 } },
	{ "ARMORY", "Gunsmith", 5, "B", "Machine Shop", { auraRatePercent = 30, auraDamagePercent = 25 } },
	{ "ARMORY", "Gunsmith", 5, "C", "Magnum Loads", { auraRatePercent = 15, auraDamagePercent = 40 } },
	{ "ARMORY", "Outfitter", 4, "B", "Loading Bench", { hunterReloadMult = 0.7 } },
	{ "ARMORY", "Outfitter", 4, "C", "Gun Braces", { hunterRecoilMult = 0.7 } },
	{ "ARMORY", "Outfitter", 5, "B", "Gun Oil", { hunterReloadMult = 0.8, rangeMult = 1.15385 } },
	{ "ARMORY", "Outfitter", 5, "C", "Steady Aim", { hunterSpreadMult = 0.8, rangeMult = 1.15385 } },
}
local TOWERS = { "CHILLER", "QUARTERMASTER", "HOSPITAL", "ARMORY" }

local function pathOf(key: string, id: string): (any, number)
	for i, path in Config.Towers[key].paths do
		if path.id == id then
			return path, i
		end
	end
	error(`{key} has no path {id}`)
end

local function close(a: number, b: number): boolean
	return math.abs(a - b) <= 1e-5 * math.max(1, math.abs(b))
end

-- The build under a pick: tier 3 for a T4 option, each T4 letter for a T5 option.
local function belows(path, tier: number): { [string]: any }
	if tier == 4 then
		return { [""] = Upgrades.row(path, 3) }
	end
	return { A = Upgrades.row(path, 4, "A"), B = Upgrades.row(path, 4, "B"), C = Upgrades.row(path, 4, "C") }
end

test("9d options: each row is the build under it plus PLAN's cells, nothing else (all 9 builds per path)", function()
	local seen = 0
	for _, o in OPTIONS do
		local key, id, tier, letter, name, cells, raider = o[1], o[2], o[3], o[4], o[5], o[6], o[7] == true
		local path = pathOf(key, id)
		for before, below in belows(path, tier) do
			local picks = before .. letter
			local row = Upgrades.row(path, tier, picks)
			local where = `{key} {id} {tier}{picks}`
			ok(row ~= nil and below ~= nil, `{where}: has a row`)
			eq(row.name, name, `{where}: name`)
			eq(row.option, letter, `{where}: letter`)
			eq(row.cost, Upgrades.row(path, tier, if tier == 4 then "A" else "AA").cost, `{where}: same price as A (#277)`)
			eq(row.pvpEffect == true, raider, `{where}: PvP effect`)
			for field, value in below do
				if type(value) == "number" and field ~= "cost" then
					local cell = cells[field]
					local want = if MULT[field] then value * (cell or 1)
						elseif SET[field] and cell then cell
						elseif cell then math.max(value, cell)
						else value
					ok(close(row[field], want), `{where}: {field} {row[field]} ~= {want}`)
				elseif type(value) == "boolean" and field ~= "swapsModel" and field ~= "pvpEffect" then
					eq(row[field], value or cells[field] == true, `{where}: {field}`)
				end
			end
			for field in cells do
				ok(below[field] ~= nil, `{where}: {field} is a Config column`)
			end
		end
		seen += 1
	end
	eq(seen, #OPTIONS, "every option checked")
	-- Every slot of these towers has exactly A, B and C, and the list above is all of them.
	for _, key in TOWERS do
		for _, path in Config.Towers[key].paths do
			eq(table.concat(Upgrades.options(path, 4, ""), ""), "ABC", `{key} {path.id} T4`)
			eq(table.concat(Upgrades.options(path, 5, "C"), ""), "ABC", `{key} {path.id} T5 after C`)
		end
	end
end)

local function stats(key: string, id: string, tier: number, picks: string)
	local _, i = pathOf(key, id)
	local tiers, all = { 0, 0, 0 }, { "", "", "" }
	tiers[i], all[i] = tier, picks
	return TowerStats.compute(Config.Towers[key], tiers, all)
end

test("9d wirings reach the stats: Tranq aura rate and Boss mark, Knockout pulse, Depot aura + refund", function()
	eq(stats("CHILLER", "Weak Spot", 4, "B").auraRatePercent, 20, "Pack Instinct aura rate")
	eq(stats("CHILLER", "Weak Spot", 5, "BB").auraRatePercent, 35, "Feeding Frenzy aura rate")
	eq(stats("CHILLER", "Weak Spot", 4, "C").bossMarkPercent, 40, "Big Game Weakness boss mark")
	eq(stats("CHILLER", "Weak Spot", 5, "AC").bossMarkPercent, 75, "Killing Ground boss mark")
	eq(stats("CHILLER", "Knockout", 4, "C").freezeEvery, 6, "Knockout Ring pulses every 6 s")
	eq(stats("CHILLER", "Knockout", 5, "CB").freezeEvery, 4, "Snooze Alarm sets every 4 s")
	eq(stats("CHILLER", "Knockout", 5, "AC").freezeEvery, 5, "Sleep Wave keeps Quick Cycle's 5 s")
	local depot = stats("QUARTERMASTER", "Logistics", 5, "BC")
	ok(depot.auraRatePercent == 20 and depot.discountPercent == 18 and depot.sellRefund == 0.95, "Depot after Bulk Buyer: rate 20, the higher discount, refund 0.95")
	eq(stats("QUARTERMASTER", "Logistics", 5, "CC").sellRefund, 0.97, "Depot after Scrap Dealer keeps 0.97 (amounts take the higher)")
	eq(stats("QUARTERMASTER", "Airdrop", 4, "B").chests, 2, "Heavy Crates: two crates")
	eq(stats("QUARTERMASTER", "Yield", 5, "CC").bountyCash, 25, "Bounty Hall")
	eq(stats("QUARTERMASTER", "Yield", 5, "AA").bountyCash, 0, "option A pays no bounty")
end)

-- A Raider tower / camp as TowerPerks sees it.
local function source(side: number, s, standing: boolean?, covers: boolean?): TowerPerks.Source
	return { side = side, standing = standing ~= false, covers = covers ~= false, stats = s }
end

test("Raider sting: x0.5 PvP, once per cooldown per hunter, never through Camo Cover, enemies only, nothing in co-op", function()
	local cooldown = Config.Tuning.RaiderStingCooldownS
	eq(cooldown, 3, "Tuning Raider sting cooldown (s) seed")
	eq(Config.Tuning.PvPHunterDamage, 0.5, "the PvP hunter lever")
	local darts = stats("CHILLER", "Sedate", 4, "C")
	local wire = stats("ARMORY", "Plating", 4, "C") -- Barbed Wire
	ok(wire.raiderDamage == 10 and wire.raiderSlowPercent == 20 and wire.raiderSlowSeconds == 2, "Barbed Wire's sting cells")
	-- Sleeper Darts on side 1; a side-2 hunter shot a side-1 tower from inside its range.
	local sting = TowerPerks.sting({ source(1, darts) }, 1, 2, false, nil, 100)
	ok(sting ~= nil, "Sleeper Darts stings")
	if sting then
		eq(sting.damage, 0, "Sleeper Darts: no sting damage")
		eq(sting.slowPercent, 30, "slow 30 %")
		eq(sting.slowSeconds, 2, "for 2 s")
	end
	local both = TowerPerks.sting({ source(1, darts), source(1, wire) }, 1, 2, false, nil, 100)
	ok(both ~= nil and both.damage == 10 * 0.5 and both.slowPercent == 30 and both.slowSeconds == 2, "two Raider towers: the strongest of each part, damage x0.5, no stacking")
	-- Cooldown per hunter.
	eq(TowerPerks.sting({ source(1, wire) }, 1, 2, false, 100, 100 + cooldown - 0.01), nil, "inside the cooldown: no sting")
	ok(TowerPerks.sting({ source(1, wire) }, 1, 2, false, 100, 100 + cooldown) ~= nil, "after the cooldown: stung again")
	-- Never through Camo Cover; never a teammate; nothing in co-op (one side).
	eq(TowerPerks.sting({ source(1, wire) }, 1, 2, true, nil, 100), nil, "Camo Cover: nothing")
	eq(TowerPerks.sting({ source(1, wire) }, 1, 1, false, nil, 100), nil, "a teammate / co-op: nothing")
	-- Own side only, standing, covering the hunter.
	eq(TowerPerks.sting({ source(2, wire) }, 1, 2, false, nil, 100), nil, "another side's Raider tower doesn't sting for side 1")
	eq(TowerPerks.sting({ source(1, wire, false) }, 1, 2, false, nil, 100), nil, "a trampled Raider tower doesn't sting")
	eq(TowerPerks.sting({ source(1, wire, true, false) }, 1, 2, false, nil, 100), nil, "a hunter outside its range isn't stung")
	eq(TowerPerks.sting({ source(1, stats("CHILLER", "Sedate", 4, "A")) }, 1, 2, false, nil, 100), nil, "a non-Raider build stings nobody")
	-- Never a stun or a reveal: a sting is damage and a slow, nothing else, within #284's limits.
	for field in both :: any do
		ok(field == "damage" or field == "slowPercent" or field == "slowSeconds", `sting field {field}`)
	end
end)

test("Raider options in co-op: the dino part carries the slot (Sleeper Darts' slow, Barbed Wire's resist, on every build)", function()
	-- No enemy hunters in co-op, so the sting never fires (above); the option still slows dinos.
	for _, picks in { "C", "CA", "CB", "CC" } do
		local s = stats("CHILLER", "Sedate", if #picks == 1 then 4 else 5, picks)
		ok(s.slowPercent >= 72, `Sedate {picks}: slows dinos {s.slowPercent} %`)
		ok(s.raiderSlowPercent == 30 and s.raiderSlowSeconds == 2, `Sedate {picks}: the sting rides every T5 after it`)
	end
	ok(stats("CHILLER", "Sedate", 4, "C").slowPercent > stats("CHILLER", "Sedate", 4, "A").slowPercent, "Sleeper Darts slows dinos harder than 4A")
	for _, picks in { "C", "CA", "CB", "CC" } do
		local s = stats("ARMORY", "Plating", if #picks == 1 then 4 else 5, picks)
		ok(s.resistPercent >= 32, `Plating {picks}: towers in range resist {s.resistPercent} %`)
		ok(s.raiderDamage == 10 and s.raiderSlowPercent == 20, `Plating {picks}: the sting rides every T5 after it`)
	end
	-- Only the two Raider builds' lines carry sting cells (the exporter refuses any other).
	local stinging = 0
	for _, key in TOWERS do
		for _, path in Config.Towers[key].paths do
			for _, row in path.t4 do
				stinging += if (row.raiderSlowPercent or 0) > 0 or (row.raiderDamage or 0) > 0 then 1 else 0
			end
		end
	end
	eq(stinging, 2, "Sleeper Darts and Barbed Wire are the only T4 stings")
	for _, key in TOWERS do
		for _, path in Config.Towers[key].paths do
			for picks, row in path.t5 do
				ok((row.raiderSlowPercent or 0) <= 30 and (row.raiderSlowSeconds or 0) <= 3, `{key} {path.id} {picks}: sting within #284`)
			end
		end
	end
end)

test("Bounty cash: the strongest standing own-side camp covering the take-down pays, once", function()
	local board = stats("QUARTERMASTER", "Yield", 4, "C")
	local hall = stats("QUARTERMASTER", "Yield", 5, "CC")
	eq(TowerPerks.bounty({ source(1, board) }, 1), 8, "Bounty Board: +8")
	eq(TowerPerks.bounty({ source(1, board), source(1, hall) }, 1), 25, "two camps: the stronger pays, not both")
	eq(TowerPerks.bounty({ source(1, board), source(1, board) }, 1), 8, "two Bounty Boards: 8, not 16")
	eq(TowerPerks.bounty({ source(2, hall) }, 1), 0, "another side's camp pays nothing")
	eq(TowerPerks.bounty({ source(1, hall, false) }, 1), 0, "a trampled camp pays nothing")
	eq(TowerPerks.bounty({ source(1, hall, true, false) }, 1), 0, "outside its range: nothing")
	eq(TowerPerks.bounty({ source(1, stats("QUARTERMASTER", "Yield", 5, "AA")) }, 1), 0, "option A: no bounty")
end)

test("Biter slow: a dino biting a tower in range is slowed, the strongest of each; never a boss", function()
	local tonic = stats("HOSPITAL", "Tonic", 4, "C")
	local brew = stats("HOSPITAL", "Tonic", 5, "CC")
	ok(tonic.biterSlowPercent == 25 and tonic.biterSlowSeconds == 2, "Bitter Tonic: 25 % for 2 s")
	ok(brew.biterSlowPercent == 30 and brew.biterSlowSeconds == 3, "Bitter Brew: 30 % for 3 s")
	local p, sec = TowerPerks.biterSlow({ source(1, tonic) }, 1, false)
	ok(p == 25 and sec == 2, "a biter is slowed 25 % for 2 s")
	p, sec = TowerPerks.biterSlow({ source(1, tonic), source(1, brew) }, 1, false)
	ok(p == 30 and sec == 3, "two hospitals: the strongest of each, not added")
	p, sec = TowerPerks.biterSlow({ source(1, brew) }, 1, true)
	ok(p == 0 and sec == 0, "never a boss")
	p = TowerPerks.biterSlow({ source(2, brew) }, 1, false)
	eq(p, 0, "another side's hospital: nothing")
	p = TowerPerks.biterSlow({ source(1, brew, false) }, 1, false)
	eq(p, 0, "a trampled hospital: nothing")
	p = TowerPerks.biterSlow({ source(1, brew, true, false) }, 1, false)
	eq(p, 0, "out of range: nothing")
	p = TowerPerks.biterSlow({ source(1, stats("HOSPITAL", "Tonic", 5, "AA")) }, 1, false)
	eq(p, 0, "option A: no biter slow")
end)

test("9d wirings on Hospital and Armory: Revive speed at T4, range, kits, respawn, hunter gear from the composed build", function()
	eq(stats("HOSPITAL", "Ward", 4, "B").reviveSpeed, 1, "Quick Stitch revives at full speed")
	eq(stats("HOSPITAL", "Ward", 5, "BC").reviveSpeed, 2, "Rapid Recovery: twice that")
	ok(stats("HOSPITAL", "Ward", 4, "C").range > stats("HOSPITAL", "Ward", 4, "A").range, "Big Tent: a wider ring")
	eq(stats("HOSPITAL", "Rescue", 5, "AC").rescueRespawnMult, 0.35, "Medevac: respawn x 0.35")
	eq(stats("HOSPITAL", "Rescue", 4, "C").medKits, 4, "Kit Bags: four kits")
	ok(close(stats("ARMORY", "Outfitter", 4, "B").hunterReloadMult, 0.65 * 0.7), "Loading Bench: reload x 0.7 on Ammo Crate's")
	ok(close(stats("ARMORY", "Outfitter", 4, "C").hunterRecoilMult, 0.75 * 0.7), "Gun Braces: recoil x 0.7 on Recoil Pads'")
	ok(math.abs(stats("ARMORY", "Outfitter", 5, "CC").hunterSpreadMult - 0.8) < 1e-9, "Steady Aim: spread x 0.8")
end)

-- T115b (#309): Bounty cash scales with the difficulty's cash multiplier, as sink cash does.
test("T115b: Bounty cash is scaled by the difficulty's cash multiplier (Hard pays less), like sink cash", function()
	local Ledger = require(src.shared.Ledger)
	local hard = Config.Difficulties.HARD.cashMult
	eq(hard, 0.8, "Hard cash multiplier")
	eq(Ledger.scaled(25, hard), 20, "Bounty Hall on Hard: 25 x 0.8")
	eq(Ledger.scaled(8, Config.Difficulties.EASY.cashMult), 8, "Bounty Board on Easy: 8")
	local main = require("@lune/fs").readFile("src/server/Main.server.luau")
	ok(main:find("Economy.earnScaledFor(enemy.side, cash, difficulty().cashMult)", 1, true) ~= nil, "Bounty cash pays scaled")
	ok(main:find("Economy.earnScaledFor(side, cash, difficulty().cashMult)", 1, true) ~= nil, "sink cash pays through the same helper")
	local economy = require("@lune/fs").readFile("src/server/Economy.luau")
	ok(economy:find("Economy.earnFor(side, Ledger.scaled(amount, cashMult))", 1, true) ~= nil, "Economy.earnScaledFor scales through Ledger")
end)
