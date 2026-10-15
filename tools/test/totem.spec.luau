--[[
	Bone Totem (PLAN 9h T126, DECISIONS #312-#320): the Towers row and Tuning block, every PLAN
	row (Round-19 names, T126's three option-bar lever steps), and the pure rules in
	Shared/Totem: charge from pops in range (a hunter's x Hunter charge x, a boss's share, never
	from any totem's own pops), full and the overflow, the charge carried over, the Spirit Roar's
	breaks, Fear on small dinos only, Bone Market paying instead of roaring, Ancient Treasure
	once, Bone Bank, Old Bones / Totem Pole auras, Finishing Roar once per boss, Skull Storm's
	targets, Bounty Wall's extra take-downs; and that Bones, Bone Rush score, Ranked results and
	Hunt Board counts are identical with and without a totem.
]]

local fs = require("@lune/fs")
local Config = require(src.shared.Config)
local Totem = require(src.shared.Totem)
local TowerStats = require(src.shared.TowerStats)
local ShopRules = require(src.shared.ShopRules)

local TOTEM = Config.Towers.TOTEM
local T = Config.Tuning

local function pathOf(id: string): (any, number)
	for i, path in TOTEM.paths do
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
	return TowerStats.compute(TOTEM, tiers, all)
end

local function close(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

test("the Towers row (PLAN 9h): 800 cash, 450 Amber, 60 a roar hit, no shots, 24 studs, hits air, 200 HP, unreleased", function()
	eq(TOTEM.display, "Bone Totem")
	eq(TOTEM.baseCost, 800)
	eq(TOTEM.unlockCost, 450)
	eq(TOTEM.baseDamage, 60)
	eq(TOTEM.baseRate, 0)
	eq(TOTEM.range, 24)
	eq(TOTEM.hitsAir, true)
	eq(TOTEM.maxHp, 200)
	ok(not TOTEM.untouchable and not TOTEM.onTrack and not TOTEM.chains and not TOTEM.resin and TOTEM.walkers == 0, "no other kind flag")
	eq(ShopRules.Unreleased.TOTEM, true, "unreleased until the 9h release (T126b, #312)")
end)

test("the BONE TOTEM Tuning block (seeds; Spirit hunter damage after T126's lever step)", function()
	eq(T.TotemChargeBones, 8)
	eq(T.RoarBreaks, 2)
	eq(T.FearKnockbackStuds, 8)
	eq(T.ShatterStripS, 4)
	eq(T.SkullX, 0.6)
	eq(T.SpiritHunters, 3)
	eq(T.SpiritHunterDamage, 9) -- 10 -> 9: Spirit Hunters' lever, one 10 % step (PLAN 9g rule 7)
	eq(T.SpiritHunterRate, 2)
	eq(T.SpiritS, 6)
	eq(T.FullBuffS, 6)
	eq(T.Finisher, 25)
	eq(T.TreasureCash, 1500)
end)

-- PLAN 9h's table: path, tier, letter, name, cells (T1-3 cumulative; T4/T5 own step).
local ROWS = {
	{ "Roar", 1, "", "Louder Roar", { damageMult = 1.6 } },
	{ "Roar", 2, "", "Quick Charge", { damageMult = 2.2, chargeNeededMult = 0.8 } },
	{ "Roar", 3, "", "Thunder Roar", { damageMult = 4.2, chargeNeededMult = 0.8, sizeBreaks = 3, piercesArmor = true } },
	{ "Roar", 4, "A", "Echo Roar", { damageMult = 0.9, roarEchoes = 1 } }, -- Damage x 1 -> 0.9: its lever, one step
	{ "Roar", 4, "B", "Fear", { damageMult = 1.85, knockback = 8 } },
	{ "Roar", 4, "C", "Shatter Roar", { damageMult = 1.8, stripsArmor = true } },
	{ "Roar", 5, "A", "Ancient Roar", { damageMult = 0.8, roarWholeTrack = true } },
	{ "Roar", 5, "B", "Skull Storm", { damageMult = 1.76, skulls = 8 } }, -- 1.6 -> 1.76: its lever, one step
	{ "Roar", 5, "C", "Finishing Roar", { damageMult = 1.8, finishingRoar = true } },
	{ "Ancestors", 1, "", "Old Bones", { chargeAuraDamagePercent = 20 } },
	{ "Ancestors", 2, "", "Shared Charge", { chargeAuraDamagePercent = 20, hunterChargeX = 2 } },
	{ "Ancestors", 3, "", "Spirit Guard", { chargeAuraDamagePercent = 20, hunterChargeX = 2, fullGuardSeconds = 4 } },
	{ "Ancestors", 4, "A", "War Paint", { hunterDamagePercent = 15 } },
	{ "Ancestors", 4, "B", "Bone Armour", { auraHpPercent = 20 } },
	{ "Ancestors", 4, "C", "Ancestor's Eye", { auraRangePercent = 10 } },
	{ "Ancestors", 5, "A", "Spirit Hunters", { spiritHunters = true } },
	{ "Ancestors", 5, "B", "Totem Pole", { sideAuraHalf = true, chargeAuraDamagePercent = 30 } },
	{ "Ancestors", 5, "C", "Elder Wisdom", { hunterCooldownMult = 0.75 } },
	{ "Bone Pile", 1, "", "Bone Collector", { boneCash = 6 } },
	{ "Bone Pile", 2, "", "Trade Post", { boneCash = 14 } },
	{ "Bone Pile", 3, "", "Bone Market", { boneCash = 14, fullCash = 400 } },
	{ "Bone Pile", 4, "A", "Rare Bones", { bossChargePercent = 50 } },
	{ "Bone Pile", 4, "B", "Bone Bank", { bankCashPerCharge = 25 } },
	{ "Bone Pile", 4, "C", "Bone Bonus", { fullCash = 560 } },
	{ "Bone Pile", 5, "A", "Camp Payday", { paydayCash = 30 } },
	{ "Bone Pile", 5, "B", "Bounty Wall", { chargeMult = 1.25, bountyChargeX = 1.25 } },
	{ "Bone Pile", 5, "C", "Ancient Treasure", { treasure = true } },
}

test("every PLAN row: name, letter and cells (T4 over T3, T5 over A4); options share their slot's price; no Raider option", function()
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
			elseif below and type(value) == "number" then
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
			ok(row.pvpEffect ~= true, `{id} T{tier}{letter}: no Raider option on the totem (#320)`)
		end
	end
end)

test("charge: 1 a pop (x Charge x), a hunter's x Hunter charge x, a boss's share instead; never a totem's own", function()
	local base = stats("Roar", 1)
	eq(Totem.popCharge(base, "tower", false), 1)
	eq(Totem.popCharge(base, "hunter", false), 1, "no Hunter charge x: like any pop")
	eq(Totem.popCharge(base, "totem", false), 0, "a roar's pops never charge (#316)")
	local shared = stats("Ancestors", 2)
	eq(Totem.popCharge(shared, "hunter", false), 2, "Shared Charge: hunter pops x2")
	eq(Totem.popCharge(shared, "tower", true), 1, "a boss without Rare Bones: a plain pop")
	local rare = stats("Bone Pile", 5, "AA")
	eq(Totem.popCharge(rare, "tower", true), T.TotemChargeBones * 0.5, "Rare Bones: a boss's pop is half a charge")
	eq(Totem.popCharge(rare, "totem", true), 0)
	local wall = stats("Bone Pile", 5, "BB")
	ok(close(Totem.popCharge(wall, "tower", false), 1.25), "Bounty Wall: x1.25")
end)

test("full: Totem charge x Charge needed x; the overflow is kept; the charge carries over", function()
	local roar = stats("Roar", 2) -- Charge needed x 0.8: 6.4
	local state = Totem.new()
	eq(state.charge, 0, "a new totem starts empty")
	eq(Totem.full(roar), T.TotemChargeBones * 0.8)
	local fills = 0
	for _ = 1, 6 do
		fills += Totem.add(state, roar, 1)
	end
	eq(fills, 0, "6 of 6.4")
	eq(Totem.add(state, roar, 1), 1, "the 7th fills it")
	ok(close(state.charge, 0.6), "0.6 overflow kept")
	eq(Totem.add(state, roar, 13), 2, "a big add fills it twice")
	ok(close(state.charge, 13.6 - 12.8), "and keeps the rest")
	eq(state.fills, 3)
	eq(Totem.add(state, roar, 0), 0, "nothing added: nothing fires")
end)

test("Bones, Bone Rush score, Ranked results and Hunt Board counts are identical with and without a totem", function()
	-- A scripted round of pops (who made it, the species if the dino is gone) through a tally like
	-- Server/Main's `popped` (Scoreboard Bones per hunter; Bounties per gone species; Bone Rush and
	-- Ranked read the same Bones). A totem watching every pop only returns charge and fills.
	local pops = {
		{ "Ana", nil, "hunter", false }, { "Ana", "RAPTOR", "hunter", false }, { "Bo", nil, "tower", false },
		{ "Bo", "TREX", "tower", true }, { "Bo", nil, "totem", false }, { "Ana", "COMPY", "totem", false },
	}
	local function tally(watch: ((source: string, boss: boolean) -> ())?)
		local bones, bounties = {}, {}
		for _, p in pops do
			bones[p[1]] = (bones[p[1]] or 0) + 1
			if p[2] then
				bounties[p[2]] = (bounties[p[2]] or 0) + 1
			end
			if watch then
				watch(p[3], p[4])
			end
		end
		return bones, bounties
	end
	local bonesA, bountiesA = tally(nil)
	local state = Totem.new()
	local s = stats("Ancestors", 2)
	local bonesB, bountiesB = tally(function(source, boss)
		Totem.observe(state, s, source :: any, boss)
	end)
	for who, n in bonesA do
		eq(bonesB[who], n, `{who}'s Bones`)
	end
	for species, n in bountiesA do
		eq(bountiesB[species], n, `{species} bounty count`)
	end
	ok(state.charge > 0, "the totem did charge (2 + 2 + 1 + 1, the totem's own pops none)")
	ok(close(state.charge, 6), `charge {state.charge}`)
	-- The server: the totem reads pops from Main's onKilled hook (after the Bone is counted), its
	-- Bone cash and pay go through onCash (cash, never Amber), and Towers never calls onPop for a charge.
	local main = fs.readFile("src/server/Main.server.luau")
	ok(main:find("Towers.dinoPopped(enemy, Enemies.source())", 1, true) ~= nil, "onKilled feeds the totem")
	local towers = fs.readFile("src/server/Towers.luau")
	local from = towers:find("function Towers.dinoPopped", 1, true)
	local body = towers:sub(from :: number, (towers:find("\nend\n", from :: number, true) :: number))
	ok(body:find("onPop", 1, true) == nil and body:find("credit(", 1, true) == nil, "a charge never credits a pop")
	ok(body:find("Amber", 1, true) == nil, "no Amber")
end)

test("the Spirit Roar: breaks Roar breaks (Thunder Roar 3); Fear only on small dinos; Bone Market pays instead", function()
	eq(Totem.roarBreaks(stats("Roar", 1)), 2, "Roar breaks 2 below Thunder Roar")
	eq(Totem.roarBreaks(stats("Roar", 3)), 3, "Thunder Roar: 3")
	local fear = stats("Roar", 4, "B")
	eq(Totem.knock(fear, 2, false), 8, "a small dino: 8 studs back")
	eq(Totem.knock(fear, 3, false), 0, "a big one stays")
	eq(Totem.knock(fear, 1, true), 0, "never a boss")
	eq(Totem.knock(stats("Roar", 3), 1, false), 0, "no Fear: no knockback")
	ok(Totem.roars(stats("Roar", 3)) and Totem.roars(stats("Bone Pile", 2)), "Bone Pile T1-T2 still roar")
	local market = stats("Bone Pile", 3)
	ok(not Totem.roars(market), "Bone Market: no roar")
	eq(Totem.fullPay(market, 3), 400)
	eq(Totem.fullPay(stats("Bone Pile", 5, "AA"), 3), 400 + 30 * 3, "Camp Payday: + 30 per hunter")
	eq(Totem.fullPay(stats("Bone Pile", 5, "CB"), 3), 560, "Bone Bonus (then Bounty Wall: no Payday)")
	eq(Totem.fullPay(stats("Roar", 3), 3), 0, "a roaring totem pays nothing")
end)

test("Ancient Treasure once a match; Bone Bank at round end; Bounty Wall's extra take-downs", function()
	local treasure = stats("Bone Pile", 5, "AC")
	local state = Totem.new()
	eq(Totem.treasure(state, treasure), T.TreasureCash, "the first full")
	eq(Totem.treasure(state, treasure), 0, "never again this match")
	eq(Totem.treasure(Totem.new(), stats("Bone Pile", 5, "AA")), 0, "not without Ancient Treasure")
	local bank = stats("Bone Pile", 4, "B")
	local held = Totem.new()
	held.charge = 3
	eq(Totem.bank(held, bank), 75)
	eq(Totem.bank(held, stats("Bone Pile", 3)), 0)
	local wall = stats("Bone Pile", 5, "AB")
	local w = Totem.new()
	local extra = 0
	for _ = 1, 8 do
		extra += Totem.bountyExtra(w, wall)
	end
	eq(extra, 2, "+25 %: 2 extra take-downs in 8")
	eq(Totem.bountyExtra(Totem.new(), stats("Bone Pile", 3)), 0)
end)

test("auras: Old Bones x the charge share; Totem Pole half on the rest of the side", function()
	local old = stats("Ancestors", 1)
	local state = Totem.new()
	state.charge = T.TotemChargeBones / 2
	eq(Totem.chargeAura(state, old, true), 10, "20 % x half charged")
	eq(Totem.chargeAura(state, old, false), 0, "out of range: none")
	local pole = stats("Ancestors", 5, "AB")
	eq(Totem.chargeAura(state, pole, true), 15, "30 % x half")
	eq(Totem.chargeAura(state, pole, false), 7.5, "the rest of the side: half")
	eq(Totem.auraAt(20, false, true), 10)
	eq(Totem.auraAt(20, false, false), 0)
end)

test("Finishing Roar once per boss under 25 %; Skull Storm hits different dinos, furthest first", function()
	ok(Totem.finishes(0.24, false), "under 25 %")
	ok(not Totem.finishes(0.26, false), "above")
	ok(not Totem.finishes(0.1, true), "once per boss")
	local picked = Totem.skullTargets({ 10, 50, 30, 40 }, 3)
	eq(#picked, 3)
	eq(picked[1], 2)
	eq(picked[2], 4)
	eq(picked[3], 3)
	eq(#Totem.skullTargets({ 5 }, 8), 1, "never two skulls on one dino")
end)

test("the server: the roar goes through Enemies marked as the totem's; Fear through the knockback rule", function()
	local towers = fs.readFile("src/server/Towers.luau")
	ok(towers:find('Enemies.setSource("totem")', 1, true) ~= nil, "a totem's hits are marked")
	ok(towers:find("Enemies.knockback(enemy, fear)", 1, true) ~= nil, "Fear: the knockback rule (never a boss)")
	ok(towers:find("Enemies.strip(enemy, Config.Tuning.ShatterStripS)", 1, true) ~= nil, "Shatter: the strip rule")
	local hero = fs.readFile("src/server/Hero.luau")
	ok(select(2, hero:gsub('Enemies.setSource%("hunter"%)', "")) >= 3, "every hunter hit is marked a hunter's")
end)
