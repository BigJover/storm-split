--[[
	The Robux store (PLAN 10e T143, DECISIONS #387-#389/#395; Shared/Store): the catalogue and
	Round 22 names/prices, blank id = hidden, published-only, PolicyService hiding, the receipt
	rule (a failed load never grants, a PurchaseId grants once, a failed save answers
	NotProcessedYet and a retry grants nothing twice), the grant mapping, pass effects, and
	source guards on Server/Store. Each rule is shown failing on a doctored version.
]]
local fs = require("@lune/fs")
local Config = require(src.shared.Config)
local Store = require(src.shared.Store)
local Training = require(src.shared.Training)
local Pets = require(src.shared.Pets)

local function withRows(patch: { [string]: { [string]: any } }, body: () -> ())
	local rows = (Config :: any).Store
	local over = {}
	for key, fields in patch do
		local row = table.clone(rows[key])
		for k, v in fields do
			row[k] = v
		end
		over[key] = row
	end
	Store.rowsOverride = setmetatable(over, { __index = rows }) :: any
	local ok, err = pcall(body)
	Store.rowsOverride = nil
	assert(ok, err)
end

test("the store is published-only: never in Studio, never unpublished, no test path", function()
	eq(Store.isOpen(true, 12345), false, "Studio, even a published place")
	eq(Store.isOpen(false, 0), false, "unpublished")
	eq(Store.isOpen(false, 12345), true, "a live published server")
	eq(Store.CLOSED_LINE, "The store opens when the game is published")
end)

test("Round 22 / #395 catalogue: names, tabs and Robux; every id blank, so nothing shows yet", function()
	local want = {
		AMBER_SACK = { "Amber Sack", "Amber", 49 },
		AMBER_CRATE = { "Amber Crate", "Amber", 199 },
		AMBER_WAGON = { "Amber Wagon", "Amber", 799 },
		TRAINING_2X = { "2× Training", "Passes", 299 },
		EXTRA_TRAINING_SPOT = { "Extra Training Spot", "Hatchery", 199 },
		SECOND_HATCHERY_HUT = { "Second Hatchery Hut", "Hatchery", 199 },
		HATCH_NOW_SPECKLED = { "Hatch now — Speckled Egg", "Hatchery", 25 },
		HATCH_NOW_GOLDEN = { "Hatch now — Golden Egg", "Hatchery", 79 },
		FINISH_LEVEL = { "Finish this level", "Hatchery", 25 },
	}
	for key, w in want do
		local row = Store.row(key)
		ok(row ~= nil, key)
		eq(row.display, w[1], `{key} name`)
		eq(row.tab, w[2], `{key} tab`)
		eq(row.robux, w[3], `{key} Robux`)
	end
	eq(Store.row("TRAINING_2X").line, "Train twice as fast, forever. Same max for everyone.")
	for _, set in { "Treehouse", "Stone Age", "Brass Gear", "Midnight", "Gold Rush" } do
		local key = string.upper(string.gsub(set, " ", "_")) .. "_BUNDLE"
		eq(Store.row(key).display, `{set} Bundle`, key)
	end
	for _, key in Store.order() do
		eq(Store.row(key).id, nil, `{key}: id blank until Jovan creates it`)
		eq(Store.shown(key, false), false, `{key}: hidden`)
	end
	for _, words in { "free", "guaranteed", "best deal" } do
		for _, key in Store.order() do
			local row = Store.row(key)
			ok(not string.find(string.lower(row.display .. " " .. row.line), words, 1, true), `{key}: no "{words}"`)
		end
	end
end)

test("a row shows only with an id AND what it grants; Hatch now is hidden for restricted players", function()
	withRows({ AMBER_SACK = { id = 111, amount = 0 } }, function()
		Store.rowsOverride.AMBER_SACK.amount = nil -- a blank Amount
		eq(Store.shown("AMBER_SACK", false), false, "id but no Amber amount: hidden")
	end)
	withRows({ AMBER_SACK = { id = 111, amount = 50000, line = "" }, HATCH_NOW_SPECKLED = { id = 222 } }, function()
		eq(Store.shown("AMBER_SACK", false), true, "complete")
		eq(Store.byId("product", 111), "AMBER_SACK", "receipt id -> row")
		eq(Store.byId("pass", 111), nil, "a product id is not a pass id")
		eq(Store.shown("HATCH_NOW_SPECKLED", false), true)
		eq(Store.shown("HATCH_NOW_SPECKLED", true), false, "paid random item hidden when restricted")
		eq(Store.shown("AMBER_SACK", true), true, "Amber isn't random")
		eq(Store.cardLine("AMBER_SACK", function() return nil end, function() return nil end), "50,000 Amber", "the exact Amber")
	end)
end)

-- A tiny profile + fake grant/save to run the receipt rule.
local function harness(saveWorks: { boolean }, grantWorks: boolean?)
	local h = { state = Store.blank(), cores = 0, grants = 0, saves = 0, saved = 0 }
	function h.receipt(id: string, loaded: boolean?): string
		return Store.processReceipt(loaded ~= false, h.state, id, "AMBER_SACK", function()
			if grantWorks == false then
				return false
			end
			h.grants += 1
			h.cores += 50000
			return true
		end, function()
			h.saves += 1
			local works = table.remove(saveWorks, 1)
			if works == nil then
				works = true
			end
			if works then
				h.saved = h.cores
			end
			return works
		end)
	end
	return h
end

test("receipts: a failed load never grants; the same PurchaseId grants once", function()
	local h = harness({})
	eq(h.receipt("p1", false), Store.NOT_YET, "failed load")
	eq(h.grants, 0, "nothing granted")
	eq(h.saves, 0, "nothing written")
	eq(Store.processReceipt(true, nil, "p1", "AMBER_SACK", function() return true end, function() return true end), Store.NOT_YET, "no store state")
	eq(h.receipt("p1"), Store.GRANTED)
	eq(h.receipt("p1"), Store.GRANTED, "a duplicate is acknowledged")
	eq(h.grants, 1, "but granted once")
	eq(h.cores, 50000)
	eq(h.receipt("p2"), Store.GRANTED, "a new purchase")
	eq(h.grants, 2)
	eq(Store.processReceipt(true, h.state, "p3", nil, function() return true end, function() return true end), Store.NOT_YET, "unknown product: kept for later")
	eq(Store.processReceipt(true, h.state, "", "AMBER_SACK", function() return true end, function() return true end), Store.NOT_YET, "no PurchaseId")
end)

test("receipts: a failed save answers NotProcessedYet; the retry saves without granting again", function()
	local h = harness({ false, false, true })
	eq(h.receipt("p9"), Store.NOT_YET, "save failed")
	eq(h.saved, 0, "nothing stored yet")
	eq(h.receipt("p9"), Store.NOT_YET, "still failing")
	eq(h.receipt("p9"), Store.GRANTED, "saved on the third try")
	eq(h.grants, 1, "granted once across all three")
	eq(h.saved, 50000)
	local bad = harness({}, false)
	eq(bad.receipt("p10"), Store.NOT_YET, "a grant that couldn't apply")
	eq(Store.ledgerHas(bad.state, "p10"), false, "isn't recorded, so the retry grants it")
end)

test("the rules can fail: without the ledger a duplicate pays twice; granting on a failed load pays a blank save", function()
	-- A doctored rule: grant every time, no ledger.
	local grants = 0
	local function naive(_id: string): string
		grants += 1
		return Store.GRANTED
	end
	naive("p1")
	naive("p1")
	ok(grants == 2, "the doctored rule double-grants (what the ledger prevents)")
	-- A doctored rule that ignores `loaded`.
	local wrote = 0
	local function careless(loaded: boolean): string
		local _ = loaded
		wrote += 1
		return Store.GRANTED
	end
	careless(false)
	ok(wrote == 1, "the doctored rule writes on a failed load (what `loaded` prevents)")
	-- And the real rule against the same inputs.
	local h = harness({})
	h.receipt("x", false)
	h.receipt("y")
	h.receipt("y")
	eq(h.grants, 1, "real rule: 1 grant")
end)

test("the ledger: bounded, sanitized", function()
	local s = Store.blank()
	for i = 1, Store.LEDGER_MAX + 5 do
		Store.ledgerAdd(s, `id{i}`)
	end
	eq(#s.receipts, Store.LEDGER_MAX)
	ok(Store.ledgerHas(s, `id{Store.LEDGER_MAX + 5}`) and not Store.ledgerHas(s, "id1"), "oldest dropped")
	local back = Store.sanitize({ receipts = { "a", 5, "b" }, hatchCredits = { MUD = 2, BAD = -1, X = "y" } })
	eq(table.concat(back.receipts, ","), "a,b")
	eq(back.hatchCredits.MUD, 2)
	eq(back.hatchCredits.BAD, nil)
	eq(#Store.sanitize("junk").receipts, 0)
end)

test("pass effects: the base without passes; 2× training, +1 training spot, +1 hatchery hut with them", function()
	local none = Store.passEffects({})
	eq(none.trainRate, 1)
	eq(none.trainSlots, Config.Tuning.TrainingSlots)
	eq(none.incubators, Config.Tuning.Incubators)
	local all = Store.passEffects({ TRAINING_2X = true, EXTRA_TRAINING_SPOT = true, SECOND_HATCHERY_HUT = true })
	eq(all.trainRate, 2)
	eq(all.trainSlots, Config.Tuning.TrainingSlots + 1)
	eq(all.incubators, Config.Tuning.Incubators + 1)
	eq(Store.maxTrainingSlots(), Config.Tuning.TrainingSlots + 1)
	-- In the rules: twice the progress a tick (same caps), two stats, two eggs.
	local a, b = Training.blank(), Training.blank()
	Training.start(a, "reach")
	Training.start(b, "reach")
	Training.tick(a, 30, "reach", 60)
	Training.tick(b, 30, "reach", 60, all.trainRate)
	eq(b.progress.reach, a.progress.reach * 2, "2× Training")
	Training.tick(b, 9999, "reach", 60, all.trainRate)
	eq(b.progress.reach, a.progress.reach * 2 + 120, "still clamped to the tick: a hitch can't over-credit")
	local c = Training.blank()
	Training.start(c, "reach", all.trainSlots)
	Training.start(c, "speed", all.trainSlots)
	eq(#c.active, 2, "two at once")
	eq(#Training.sanitize(Training.toSave(c), Store.maxTrainingSlots()).active, 2, "a save keeps both")
	local pets = Pets.blank()
	table.insert(pets.eggs, { egg = "MUD", readyAt = 1e9 })
	eq((Pets.canBuy(pets, "MUD")), nil, "one hut: busy")
	ok(Pets.canBuy(pets, "MUD", all.incubators) ~= nil, "second hut: room")
end)

test("bundle cards say 'saves X Amber' only when it's true", function()
	withRows({ MIDNIGHT_BUNDLE = { robux = 199, items = { "MIDNIGHT", "NIGHT_PROWLER" } } }, function()
		local function name(k: string): string?
			return k
		end
		eq(Store.cardLine("MIDNIGHT_BUNDLE", name, function()
			return nil
		end), "Inside: MIDNIGHT, NIGHT_PROWLER", "no Amber prices: no saving claimed")
		eq(Store.cardLine("MIDNIGHT_BUNDLE", name, function(k: string)
			return if k == "MIDNIGHT" then 100000 else nil
		end), "Inside: MIDNIGHT, NIGHT_PROWLER", "one unpriced item: still no claim")
		eq(Store.cardLine("MIDNIGHT_BUNDLE", name, function()
			return 50000
		end), "Inside: MIDNIGHT, NIGHT_PROWLER · saves 100,000 Amber", "all priced: the true figure")
	end)
end)

test("source guards: Server/Store grants nothing itself, sets ProcessReceipt only when open; Progression grants on a loaded save", function()
	local server = fs.readFile("src/server/Store.luau")
	local closed = server:find("if not open then", 1, true)
	local receipt = server:find("MarketplaceService.ProcessReceipt =", 1, true)
	ok(closed and receipt and closed < receipt, "ProcessReceipt only after the open check")
	for _, banned in { ".cores", "profiles[", "Skins.grant", "SaveStore" } do
		ok(server:find(banned, 1, true) == nil, `Server/Store never touches {banned}`)
	end
	ok(server:find("Progression.storeReceipt(player, purchaseId, key, pickOf[purchaseId])", 1, true) ~= nil, "receipts go to Progression")
	ok(server:find("local purchaseId = tostring(receipt.PurchaseId)", 1, true) ~= nil, "keyed by the PurchaseId")
	ok(server:find("ArePaidRandomItemsRestricted", 1, true) ~= nil, "PolicyService checked")
	ok(server:find("UserOwnsGamePassAsync", 1, true) ~= nil, "passes checked")
	local progression = fs.readFile("src/server/Progression.luau")
	ok(progression:find("profile ~= nil and canSave[player] == true,", 1, true) ~= nil, "a failed / session-only load never grants")
	ok(progression:find("return save(player)", 1, true) ~= nil, "PurchaseGranted waits on the save")
	ok(progression:find("return status == \"ok\" and data ~= nil", 1, true) ~= nil, "save reports success only when written")
	local client = fs.readFile("src/client/Counter.client.luau")
	ok(client:find("heading(StoreRules.CLOSED_LINE)", 1, true) ~= nil, "the closed store says so")
	ok(client:find("PromptProductPurchase", 1, true) == nil and client:find("ProcessReceipt", 1, true) == nil, "the client never prompts or grants itself")
end)

-- PLAN T143b (#411-#414).
test("T143b numbers: Amber packs, bundles, Hatch now (Mud gone), Finish this level", function()
	local packs = {
		AMBER_SACK = { 150000, "150,000 Amber — about 50 minutes of Normal hunting." },
		AMBER_CRATE = { 700000, "700,000 Amber — about 4 hours of Normal hunting." },
		AMBER_WAGON = { 3000000, "3,000,000 Amber — about 17 hours of Normal hunting." },
	}
	for key, w in packs do
		eq(Store.row(key).amount, w[1], `{key} Amber`)
		eq(Store.cardLine(key, function() return nil end, function() return nil end), w[2], `{key} card`)
	end
	local bundles = {
		TREEHOUSE_BUNDLE = { "TREEHOUSE,JUNGLE_GHOST,BAMBOO_BOOMSTICK", 249 },
		STONE_AGE_BUNDLE = { "STONE_AGE,CROC_HIDE_CRUSHER,CROC_HIDE", 249 },
		BRASS_GEAR_BUNDLE = { "BRASS_GEAR,MOUNTAIN_RESCUE,BRASS_SADDLE", 249 },
		MIDNIGHT_BUNDLE = { "MIDNIGHT,NIGHT_PROWLER,SILVER_SPUR", 299 },
		GOLD_RUSH_BUNDLE = { "GOLD_RUSH,GOLD_RUSH_SAFARI,ENGRAVED_GOLD", 599 },
	}
	for key, w in bundles do
		eq(table.concat(Store.row(key).items, ","), w[1], `{key} items`)
		eq(Store.row(key).robux, w[2], `{key} Robux`)
		ok(Store.ready(Store.row(key) :: any), `{key} complete (only the id missing)`)
	end
	eq(Store.row("HATCH_NOW_MUD"), nil, "Mud's Hatch now removed (#413)")
	local finish = Store.row("FINISH_LEVEL") :: any
	eq(finish.grant, "trainFinish")
	eq(finish.type, "product")
	eq(finish.random, false, "not a random item")
	eq(finish.line, "Finishes the level you're training now. Same max for everyone.")
	ok(Store.ready(finish), "complete (only the id missing)")
end)

test("a bundle you partly own: still sold, lists what's new, saves only the unowned Amber", function()
	local Skins = require(src.shared.Skins)
	local function name(k: string): string?
		local r = Skins.row(k)
		return r and r.display
	end
	local function price(k: string): number?
		local r = Skins.row(k)
		return r and r.price
	end
	eq(Store.cardLine("MIDNIGHT_BUNDLE", name, price), "Inside: Midnight, Night Prowler, Silver Spur · saves 1,350,000 Amber", "own none")
	eq(Store.cardLine("MIDNIGHT_BUNDLE", name, price, function(k: string)
		return k == "NIGHT_PROWLER"
	end), "New for you: Midnight, Silver Spur (you have Night Prowler) · saves 1,050,000 Amber", "own one")
	eq(Store.cardLine("MIDNIGHT_BUNDLE", name, price, function()
		return true
	end), "You have everything inside: Midnight, Night Prowler, Silver Spur", "own all: no saving claimed")
end)

test("#414 Finish this level: the pick, the only stat, a credit when nothing trains, never past a cap, a receipt once", function()
	eq(Store.finishTarget({ "reach", "speed" }, "speed"), "speed", "two training: the pick")
	eq(Store.finishTarget({ "reach" }, nil), "reach", "one training: that one")
	eq(Store.finishTarget({ "reach", "speed" }, "health"), "reach", "a pick that isn't training: not that one")
	eq(Store.finishTarget({}, "reach"), nil, "nothing training: a credit")
	ok(Store.needsPick({ "reach", "speed" }) and not Store.needsPick({ "reach" }), "the pick is asked only with two")
	-- The grant as Progression runs it, on a real training state.
	local function grant(state: any, t: any, pick: string?): boolean
		local stat = Store.finishTarget(t.active, pick)
		if stat then
			Training.finish(t, stat)
		else
			state.trainCredits += 1
		end
		return true
	end
	local state, t = Store.blank(), Training.blank()
	Training.start(t, "reach", 2)
	Training.start(t, "speed", 2)
	local saves = 0
	local function save(): boolean
		saves += 1
		return true
	end
	eq(Store.processReceipt(true, state, "P1", "FINISH_LEVEL", function() return grant(state, t, "speed") end, save), Store.GRANTED)
	eq(t.levels.speed, 1, "the picked stat levelled")
	eq(t.levels.reach, 0, "the other didn't")
	eq(Store.processReceipt(true, state, "P1", "FINISH_LEVEL", function() return grant(state, t, "speed") end, save), Store.GRANTED)
	eq(t.levels.speed, 1, "the same PurchaseId never finishes a second level")
	-- At the cap: a maxed stat leaves training, so a later receipt finds nothing of it.
	for _ = 1, Training.levels() do
		Training.finish(t, "reach")
	end
	eq(t.levels.reach, Training.levels(), "reach maxed")
	eq(table.find(t.active, "reach"), nil, "and no longer training")
	eq(Store.processReceipt(true, state, "P2", "FINISH_LEVEL", function() return grant(state, t, "reach") end, save), Store.GRANTED)
	eq(t.levels.reach, Training.levels(), "never past the cap")
	eq(t.levels.speed, 2, "the pick fell back to the stat still training")
	-- Nothing training: a saved credit, kept by the save.
	local idle = Training.blank()
	eq(Store.processReceipt(true, state, "P3", "FINISH_LEVEL", function() return grant(state, idle, nil) end, save), Store.GRANTED)
	eq(state.trainCredits, 1, "a credit")
	eq(Store.sanitize(Store.toSave(state)).trainCredits, 1, "saved")
	eq(Store.sanitize({ trainCredits = -3 }).trainCredits, 0, "garbage refused")
	eq(Store.sanitize({}).trainCredits, 0, "an older save: none")
end)

test("source guards: the credit finishes the next level started; Server/Store asks for a pick with two training", function()
	local prog = fs.readFile("src/server/Progression.luau")
	ok(prog:find("if ok and not was and profile.store.trainCredits > 0 and Training.finish(profile.training, stat) then", 1, true) ~= nil, "trainStart uses a credit")
	ok(prog:find("local stat = StoreRules.finishTarget(p.training.active, pick)", 1, true) ~= nil, "the receipt grant")
	local server = fs.readFile("src/server/Store.luau")
	ok(server:find("StoreRules.needsPick(active) and not", 1, true) ~= nil, "two training: a pick first")
	ok(server:find("if #active == 0 then", 1, true) ~= nil, "nothing training: not prompted")
end)

test("T144 (Round 23): store wording — R$49, Hatch now rows name their egg", function()
	eq(Store.priceLabel("AMBER_SACK"), "R$49", "no space after R$")
	eq(Store.row("HATCH_NOW_SPECKLED").display, "Hatch now — Speckled Egg")
	eq(Store.row("HATCH_NOW_GOLDEN").display, "Hatch now — Golden Egg")
	local counter = fs.readFile("src/client/Counter.client.luau")
	ok(counter:find("Buy {Theme.formatAmber(price)} {Theme.Currency}", 1, true) ~= nil, "Amber skin Buy says Amber")
	ok(counter:find("`Buy {Theme.formatAmber(row.price)}`", 1, true) == nil, "no bare Amber number on a Buy")
	ok(counter:find("\"Outpost Shop\"", 1, true) ~= nil, "header: Outpost Shop")
	ok(fs.readFile("src/client/Training.client.luau"):find("`Finish now — {Theme.formatAmber(price)} {Theme.Currency}`", 1, true) ~= nil, "Finish now — 24K Amber")
	ok(fs.readFile("src/client/Pets.client.luau"):find("Incubator (", 1, true) == nil, "no 'Incubator' heading")
	ok(fs.readFile("src/client/Home.client.luau"):find("string.lower(Theme.Currency)", 1, true) == nil, "Amber capitalised")
	ok(fs.readFile("src/client/Hero.client.luau"):find("`{kit.meleeName}  {math.ceil(meleeWait)}s`", 1, true) ~= nil, "melee cooldown shown")
end)
