--[[
	Eggs and pets (PLAN 10d T140, DECISIONS #375-#379, #392/#393/#396, strings DINO_REVIEW
	Round 21): Shared/Pets' odds, roll, fusing, timers, Amber warm-up, cap, take-along,
	Hatchling Pen and the save round trip through Shared/Profile + SaveStore.

	The sheet's prices and warm price (T141b, #405/#406) are checked as they are; the specs
	that need a blank or a round test number set it on Config's (unfrozen) egg row and Tuning
	copy, and put it back.
]]
local Config = require(src.shared.Config)
local Pets = require(src.shared.Pets)
local Profile = require(src.shared.Profile)
local SaveStore = require(src.shared.SaveStore)
local Theme = require(src.shared.Theme)

local NOON = 1_800_000_000
local function one(_n: number): number
	return 1
end

-- An rng that answers `values` in turn.
local function script(values: { number }): (number) -> number
	local i = 0
	return function(_n: number): number
		i += 1
		return values[i]
	end
end

-- Runs `fn` with a test price on the Mud Egg and a test warm price (false = blank), then
-- puts the sheet's back.
local function priced(fn: () -> (), warm: (number | false)?)
	local mud = (Config :: any).Eggs.MUD
	local before = mud.price
	mud.price = 5000
	local tuning = Config.Tuning :: any
	local warmBefore = tuning.EggWarmAmberPerMin
	if warm ~= nil then
		tuning.EggWarmAmberPerMin = if warm then warm else nil
	end
	local ok, err = pcall(fn)
	mud.price = before
	tuning.EggWarmAmberPerMin = warmBefore
	assert(ok, err)
end

local function give(state, kind: string, rarity: string, n: number)
	for _ = 1, n do
		table.insert(state.pets, { id = state.nextId, kind = kind, rarity = rarity })
		state.nextId += 1
	end
end

test("six rarities with Jovan's names, multipliers and the Mud Egg odds (#392)", function()
	local names, mults = {}, {}
	for _, r in Pets.rarities() do
		table.insert(names, r.display)
		table.insert(mults, r.mult)
	end
	eq(table.concat(names, ","), "Common,Uncommon,Rare,Epic,Legendary,Mythic")
	eq(table.concat(mults, ","), "1,1.25,1.5,1.75,2,2.25")
	eq(Pets.oddsLine("MUD"), "Hatch odds: Common 55 % · Uncommon 25 % · Rare 12 % · Epic 5 % · Legendary 2.5 % · Mythic 0.5 %")
	for _, egg in (Config :: any).EggOrder do
		local odds = Pets.odds(egg)
		if odds then
			local tenths = 0
			for _, o in odds do
				tenths += math.round(o.percent * 10)
			end
			eq(tenths, 1000, `{egg} sums to exactly 100 %`)
			ok(odds[6].percent <= Config.Tuning.PetMythicOddsMax, `{egg} Mythic <= 2 %`)
		end
	end
	eq(Pets.nextRarity("LEGENDARY"), "MYTHIC")
	eq(Pets.nextRarity("MYTHIC"), nil)
	eq((Config :: any).Eggs.MUD.hatchMinutes, 5)
	eq((Config :: any).Eggs.SPECKLED.hatchMinutes, 30)
	eq((Config :: any).Eggs.GOLDEN.hatchMinutes, 120)
	eq(Pets.cap(), 60)
end)

test("the hatch roll: six bands on rng(1000), the 0.5 % Mythic edge, species even", function()
	local bands = {
		{ 1, "COMMON" }, { 550, "COMMON" }, { 551, "UNCOMMON" }, { 800, "UNCOMMON" }, { 801, "RARE" },
		{ 920, "RARE" }, { 921, "EPIC" }, { 970, "EPIC" }, { 971, "LEGENDARY" }, { 995, "LEGENDARY" },
		{ 996, "MYTHIC" }, { 1000, "MYTHIC" },
	}
	for _, b in bands do
		eq(Pets.rollRarity("MUD", script({ b[1] })), b[2], `roll {b[1]}`)
	end
	local counts: { [string]: number } = {}
	for roll = 1, 1000 do
		local r = Pets.rollRarity("MUD", script({ roll }))
		counts[r] = (counts[r] or 0) + 1
	end
	eq(counts.MYTHIC, 5, "Mythic = exactly 5 of 1000 (0.5 %)")
	eq(counts.LEGENDARY, 25)
	eq(counts.COMMON, 550)
	-- Seeded RNG: a long run lands near the odds.
	local seed = 12345
	local seeded = function(n: number): number -- a seeded LCG (no Random under Lune)
		seed = (seed * 1103515245 + 12345) % 2147483648
		return 1 + (seed // 65536) % n
	end
	local tally: { [string]: number } = {}
	local N = 200000
	for _ = 1, N do
		local r = Pets.rollRarity("MUD", seeded)
		tally[r] = (tally[r] or 0) + 1
	end
	near(tally.COMMON / N, 0.55, "Common ~55 %", 0.005)
	near((tally.MYTHIC or 0) / N, 0.005, "Mythic ~0.5 %", 0.001)
	local kinds = (Config :: any).PetOrder
	eq(#kinds, 5)
	for i, kind in kinds do
		eq(Pets.rollKind(script({ i })), kind, "species picked evenly by index")
	end
	eq(table.concat(kinds, ","), "HONKER,FETCHER,FERN_MUNCHER,SHINY_SNATCHER,FRILL_GUARD")
	-- #406: Speckled 40/30/17/8/4/1, Golden 20/30/25/14/9/2 -> band edges in tenths.
	for _, case in { { "SPECKLED", 400, "COMMON" }, { "SPECKLED", 401, "UNCOMMON" }, { "SPECKLED", 990, "LEGENDARY" },
		{ "SPECKLED", 991, "MYTHIC" }, { "GOLDEN", 200, "COMMON" }, { "GOLDEN", 750, "RARE" }, { "GOLDEN", 751, "EPIC" },
		{ "GOLDEN", 980, "LEGENDARY" }, { "GOLDEN", 981, "MYTHIC" } } do
		eq(Pets.rollRarity(case[1], script({ case[2] })), case[3], `{case[1]} roll {case[2]}`)
	end
	eq(Pets.oddsLine("GOLDEN"), "Hatch odds: Common 20 % · Uncommon 30 % · Rare 25 % · Epic 14 % · Legendary 9 % · Mythic 2 %")
	local speckled = (Config :: any).Eggs.SPECKLED
	local odds = speckled.odds
	speckled.odds = nil
	local blank = Pets.rollRarity("SPECKLED", script({ 1000 }))
	local sale = select(2, Pets.canBuy(Pets.blank(), "SPECKLED"))
	speckled.odds = odds
	eq(blank, "COMMON", "no odds: never rolls")
	eq(sale, "Not for sale yet", "and isn't for sale")
end)

test("buying: the sheet's prices (#405); blank price = not for sale; one incubator; real-time timer (#396)", function()
	local state = Pets.blank()
	eq((Pets.canBuy(state, "MUD")), 20000, "Mud 20K Amber")
	eq((Pets.canBuy(state, "SPECKLED")), 75000, "Speckled 75K")
	eq((Pets.canBuy(state, "GOLDEN")), 200000, "Golden 200K")
	eq(select(2, Pets.canBuy(state, "BOGUS")), "Unknown egg")
	local mud = (Config :: any).Eggs.MUD
	mud.price = nil
	local price, why = Pets.canBuy(state, "MUD")
	mud.price = 20000
	eq(price, nil)
	eq(why, "Not for sale yet", "a blank price is not for sale")
	priced(function()
		eq((Pets.canBuy(state, "MUD")), 5000)
		ok(Pets.buy(state, "MUD", NOON))
		eq(Pets.remaining(state, 1, NOON), 300)
		eq(Pets.timerLine(state, 1, NOON + 28), "Hatching… 4:32 left")
		local busy, msg = Pets.buy(state, "MUD", NOON)
		ok(not busy and msg == "Your Hatchery Hut is full — hatch an egg first", "one incubator (#377)")
		-- Saved and loaded an hour later: the egg kept warming offline.
		local back = Pets.sanitize(Pets.toSave(state), NOON + 3600)
		eq(Pets.remaining(back, 1, NOON + 3600), 0, "ready after time away")
		eq(Pets.timerLine(back, 1, NOON + 3600), "Ready to hatch!")
		-- A clock that jumped back never makes the wait longer than one full hatch.
		local skew = Pets.sanitize(Pets.toSave(state), NOON - 86400)
		eq(Pets.remaining(skew, 1, NOON - 86400), 300)
	end)
end)

test("Warm it up: Amber per remaining minute, rounded up; blank = no button", function()
	eq(Config.Tuning.EggWarmAmberPerMin, 2000, "#405: 2,000 Amber a minute, like training")
	priced(function()
		local state = Pets.blank()
		Pets.buy(state, "MUD", NOON)
		eq(Pets.warmPrice(state, 1, NOON), 10000, "a whole Mud Egg (5 min) = 10K")
		local golden = Pets.blank()
		Pets.buy(golden, "GOLDEN", NOON)
		eq(Pets.warmPrice(golden, 1, NOON), 240000, "a whole Golden Egg (120 min) = 240K, more than the egg")
	end)
	priced(function()
		local state = Pets.blank()
		Pets.buy(state, "MUD", NOON)
		eq(Pets.warmPrice(state, 1, NOON), nil, "blank warm price: not for sale")
	end, false)
	priced(function()
		local state = Pets.blank()
		Pets.buy(state, "MUD", NOON)
		eq(Pets.warmPrice(state, 1, NOON), 5 * 2500, "5 minutes left")
		eq(Pets.warmPrice(state, 1, NOON + 241), 2500, "59 s = 1 minute")
		eq(Pets.warmPrice(state, 1, NOON + 239), 5000, "61 s = 2 minutes")
		eq(Pets.warmPrice(state, 1, NOON + 300), nil, "ready: nothing to warm")
		eq(Pets.warmPrice(state, 2, NOON), nil, "no egg in that slot")
		eq(`Warm it up — {Theme.formatAmber(12500)} {Theme.Currency} (finishes now)`, "Warm it up — 12.5K Amber (finishes now)")
		ok(Pets.warm(state, 1, NOON))
		eq(Pets.remaining(state, 1, NOON), 0)
	end, 2500)
end)

test("hatching: not before the timer, refused when full, adds the rolled pet", function()
	priced(function()
		local state = Pets.blank()
		Pets.buy(state, "MUD", NOON)
		local early, why = Pets.hatch(state, 1, NOON + 299, one)
		ok(not early and why == "Not ready yet")
		local hatched, line, pet = Pets.hatch(state, 1, NOON + 300, script({ 3, 996 }))
		ok(hatched)
		eq(pet and pet.kind, "FERN_MUNCHER")
		eq(pet and pet.rarity, "MYTHIC")
		eq(line, "New pet: Mythic Fern Muncher!")
		eq(#state.eggs, 0, "the incubator is free again")
		-- Full: the egg waits, nothing is lost.
		local full = Pets.blank()
		give(full, "HONKER", "COMMON", Pets.cap())
		Pets.buy(full, "MUD", NOON)
		local refused, msg = Pets.hatch(full, 1, NOON + 300, one)
		ok(not refused)
		eq(msg, "Pets full (60/60). Fuse some to make room.")
		eq(#full.eggs, 1, "the egg stays in the incubator")
	end)
end)

test("fusing: 3 identical -> next rarity, Legendary -> Mythic, Mythic refused, species kept (#393)", function()
	local state = Pets.blank()
	give(state, "HONKER", "RARE", 2)
	give(state, "FETCHER", "RARE", 1)
	local no, why = Pets.fuse(state, "HONKER", "RARE")
	ok(not no)
	eq(why, "Need 3 of the same pet and rarity.", "two Honkers + a Fetcher don't fuse")
	give(state, "HONKER", "RARE", 2)
	eq(Pets.fuseLine("HONKER", "RARE"), "Fuse — 3 Rare Honkers → 1 Epic Honker")
	Pets.takeAlong(state, 1) -- a Honker taken along is used last
	local fused, line, pet = Pets.fuse(state, "HONKER", "RARE")
	ok(fused)
	eq(line, "New pet: Epic Honker!")
	eq(pet and pet.kind, "HONKER", "species never changes")
	eq(pet and pet.rarity, "EPIC")
	eq(#state.pets, 3, "5 - 3 + 1")
	eq(state.along, 1, "the pet taken along was spared")
	local legend = Pets.blank()
	give(legend, "FRILL_GUARD", "LEGENDARY", 3)
	Pets.setPen(legend, 2, true)
	Pets.takeAlong(legend, 3)
	local okM, _, mythic = Pets.fuse(legend, "FRILL_GUARD", "LEGENDARY")
	ok(okM)
	eq(mythic and mythic.rarity, "MYTHIC", "Legendary x3 -> Mythic")
	eq(legend.along, mythic and mythic.id, "the new pet is taken along in place of the used one")
	eq(#legend.pen, 0, "used pets leave the pen")
	give(legend, "FRILL_GUARD", "MYTHIC", 2)
	local refused, msg = Pets.fuse(legend, "FRILL_GUARD", "MYTHIC")
	ok(not refused)
	eq(msg, "Mythic is the top — it can't fuse.")
	eq(Pets.fuseLine("FRILL_GUARD", "MYTHIC"), "Mythic is the top — it can't fuse.")
	eq(#legend.pets, 3)
end)

test("take along one pet; Hatchling Pen shows at most 3", function()
	local state = Pets.blank()
	give(state, "HONKER", "EPIC", 4)
	local okA, line = Pets.takeAlong(state, 2)
	ok(okA)
	eq(line, "Taking along your Epic Honker")
	eq(Pets.along(state) and Pets.along(state).id, 2)
	ok(not Pets.takeAlong(state, 99), "unknown pet")
	Pets.takeAlong(state, nil)
	eq(Pets.along(state), nil)
	for id = 1, 3 do
		ok(Pets.setPen(state, id, true))
	end
	local full, why = Pets.setPen(state, 4, true)
	ok(not full)
	eq(why, "Your Hatchling Pen is full (3 max)")
	ok(Pets.setPen(state, 1, false))
	ok(Pets.setPen(state, 4, true))
	eq(Pets.name({ kind = "SHINY_SNATCHER", rarity = "LEGENDARY" }), "Legendary Shiny Snatcher")
	local groups = Pets.groups(state)
	eq(#groups, 1)
	eq(groups[1].count, 4)
	eq(groups[1].pen, 3)
end)

test("saved through Profile + SaveStore; older saves start empty; unreadable pets are kept untouched", function()
	local data: { [string]: any } = {}
	local store = {
		update = function(key: string, transform: (any) -> any): any
			local value = transform(data[key])
			if value ~= nil then
				data[key] = value
			end
			return data[key]
		end,
		budget = function(): number
			return math.huge
		end,
	}
	local env = { now = function() return NOON end, wait = function(_s: number) end, log = function(_m: string) end }
	local _, raw = SaveStore.load(store, "player_1", "A", env)
	local profile = Profile.sanitize(raw, NOON, one)
	local pets = profile.pets :: any
	eq(#pets.pets, 0, "a new player has no pets")
	give(pets, "HONKER", "RARE", 2)
	give(pets, "FRILL_GUARD", "MYTHIC", 1)
	Pets.takeAlong(pets, 3)
	Pets.setPen(pets, 1, true)
	table.insert(pets.eggs, { egg = "GOLDEN", readyAt = NOON + 7200 })
	eq(SaveStore.write(store, "player_1", "A", env, function()
		return Profile.toSave(profile)
	end, true), "ok")
	local _, raw2 = SaveStore.load(store, "player_1", "B", env)
	local back = Profile.sanitize(raw2, NOON + 600, one)
	local p2 = back.pets :: any
	eq(#p2.pets, 3)
	eq(Pets.name(p2.pets[3]), "Mythic Frill Guard")
	eq(p2.along, 3)
	eq(p2.pen[1], 1)
	eq(p2.nextId, 4)
	eq(Pets.remaining(p2, 1, NOON + 600), 6600, "the Golden Egg kept its timer")
	-- A save from before T140 has no pets: starts empty, everything else kept.
	local old = Profile.sanitize({ cores = 5000, amberScale = Profile.AMBER_SCALE }, NOON, one)
	eq(old.cores, 5000)
	eq(#(old.pets :: any).pets, 0)
	-- Unreadable pets (a newer version, an unknown pet): the profile still loads, pets are
	-- off this session, and the save writes the stored value back exactly as it was.
	for _, bad in {
		{ v = 2, nextId = 2, pets = { { id = 1, kind = "HONKER", rarity = "RARE" } } },
		{ v = 1, nextId = 2, pets = { { id = 1, kind = "DODO", rarity = "RARE" } } },
		{ v = 1, nextId = 2, pets = { { id = 1, kind = "HONKER", rarity = "SHINY" } } },
		{ v = 1, nextId = 3, pets = { { id = 1, kind = "HONKER", rarity = "RARE" }, { id = 1, kind = "HONKER", rarity = "RARE" } } },
		{ v = 1, nextId = 2, pets = {}, eggs = { { egg = "DRAGON", readyAt = NOON } } },
		"garbage",
	} :: { any } do
		local loaded = Profile.sanitize({ cores = 7000, amberScale = Profile.AMBER_SCALE, pets = bad }, NOON, one)
		eq(loaded.cores, 7000, "the rest of the profile loads")
		eq(loaded.pets, nil, "pets off this session")
		eq(Profile.toSave(loaded).pets, bad, "written back untouched")
	end
end)
