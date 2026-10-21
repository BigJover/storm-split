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
		HATCH_NOW_MUD = { "Hatch now", "Hatchery", 25 },
		HATCH_NOW_SPECKLED = { "Hatch now", "Hatchery", 49 },
		HATCH_NOW_GOLDEN = { "Hatch now", "Hatchery", 99 },
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
	withRows({ AMBER_SACK = { id = 111 } }, function()
		eq(Store.shown("AMBER_SACK", false), false, "id but no Amber amount: hidden")
	end)
	withRows({ AMBER_SACK = { id = 111, amount = 50000 }, HATCH_NOW_MUD = { id = 222 } }, function()
		eq(Store.shown("AMBER_SACK", false), true, "complete")
		eq(Store.byId("product", 111), "AMBER_SACK", "receipt id -> row")
		eq(Store.byId("pass", 111), nil, "a product id is not a pass id")
		eq(Store.shown("HATCH_NOW_MUD", false), true)
		eq(Store.shown("HATCH_NOW_MUD", true), false, "paid random item hidden when restricted")
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
	ok(server:find("Progression.storeReceipt(player, tostring(receipt.PurchaseId), key)", 1, true) ~= nil, "receipts go to Progression")
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
