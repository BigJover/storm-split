--[[
	Per-side economy and shop rules (PLAN phase 7 T76, DECISIONS #209, #211, #212):
	Shared/Ledger (each side's cash and Fence), Shared/Sides' shop rules and attribute
	names, and that the server applies them: Economy is still the only cash mutator, Shop
	spends the builder's side's cash and refuses every action on an enemy's tower.
	Co-op (one side) must behave exactly like the pre-T76 Economy.
]]

local fs = require("@lune/fs")
local Ledger = require(src.shared.Ledger)
local Sides = require(src.shared.Sides)

-- The pre-T76 Server/Economy (4b2a3bc), its arithmetic only: the reference co-op keeps.
local function oldEconomy(startingCash: number, startingLives: number)
	local e = { cash = startingCash, lives = startingLives, zeros = 0 }
	function e.earn(amount: number)
		if amount <= 0 then
			return
		end
		e.cash += amount
	end
	function e.trySpend(amount: number): boolean
		if amount < 0 or e.cash < amount then
			return false
		end
		e.cash -= amount
		return true
	end
	function e.setLives(amount: number)
		e.lives = amount
	end
	function e.lose(amount: number)
		if e.lives <= 0 then
			return
		end
		e.lives = math.max(0, e.lives - amount)
		if e.lives == 0 then
			e.zeros += 1
		end
	end
	return e
end

local seed = 11
local function nextInt(lo: number, hi: number): number -- a small LCG (no Random headless)
	seed = (seed * 1103515245 + 12345) % 2147483648
	return lo + seed % (hi - lo + 1)
end

test("co-op (side 1) is exactly the old Economy, op by op", function()
	for run = 1, 200 do
		local cash, lives = nextInt(0, 900), nextInt(1, 60)
		local old = oldEconomy(cash, lives)
		local l = Ledger.new(1, cash, lives)
		local zeros = 0
		for step = 1, 80 do
			local op = nextInt(1, 4)
			local amount = (nextInt(-20, 400)) / (if nextInt(0, 1) == 1 then 1 else 7) -- fractional too
			if op == 1 then
				old.earn(amount)
				Ledger.earn(l, 1, amount)
			elseif op == 2 then
				eq(Ledger.trySpend(l, 1, amount), old.trySpend(amount), `run {run} step {step}: spend {amount}`)
			elseif op == 3 then
				local _, out = Ledger.lose(l, 1, amount)
				old.lose(amount)
				if out then
					zeros += 1
				end
			else
				local n = nextInt(0, 60)
				old.setLives(n)
				Ledger.setLives(l, 1, n)
			end
			eq(Ledger.cash(l, 1), old.cash, `run {run} step {step}: cash`)
			eq(Ledger.lives(l, 1), old.lives, `run {run} step {step}: lives`)
			eq(zeros, old.zeros, `run {run} step {step}: out calls`)
		end
	end
end)

test("each side has its own pot and Fence", function()
	local l = Ledger.new(3, 450, 40)
	eq(Ledger.cash(l, 2), 450, "same start")
	eq(Ledger.lives(l, 3), 40)
	ok(Ledger.trySpend(l, 2, 400), "side 2 spends")
	eq(Ledger.cash(l, 1), 450, "side 1 untouched")
	eq(Ledger.cash(l, 3), 450, "side 3 untouched")
	eq(Ledger.trySpend(l, 2, 100), false, "side 2 can't spend side 1's cash")
	ok(Ledger.earn(l, 3, 25))
	eq(Ledger.cash(l, 3), 475)
	eq(Ledger.cash(l, 2), 50)
	ok(Ledger.trySpend(l, 2, 50), "spending exactly what the side has")
	eq(Ledger.cash(l, 2), 0)
	eq(Ledger.trySpend(l, 2, -5), false, "a negative spend is refused")
	local changed, out = Ledger.lose(l, 1, 40)
	ok(changed and out, "side 1's Fence falls")
	eq(Ledger.lives(l, 2), 40, "a leak hurts only that side's Fence")
	eq(select(2, Ledger.lose(l, 1, 5)), false, "out only once")
	eq(Ledger.lose(l, 1, 5), false, "a fallen Fence doesn't change")
end)

test("an unknown side is refused and changes nothing", function()
	local l = Ledger.new(2, 100, 10)
	eq(Ledger.has(l, 3), false)
	eq(Ledger.has(l, 0), false)
	eq(Ledger.earn(l, 3, 50), false)
	eq(Ledger.trySpend(l, 3, 0), false)
	eq(Ledger.lose(l, 0, 1), false)
	eq(Ledger.setLives(l, 3, 5), false)
	eq(Ledger.cash(l, 3), 0)
	eq(Ledger.cash(l, 1) + Ledger.cash(l, 2), 200, "the real pots are untouched")
	eq(#Ledger.new(0, 1, 1).pots, 1, "never fewer than one side")
end)

test("shop rules: your own side's towers only, never an enemy's", function()
	for _, action in { "upgrade", "repair", "sell" } do
		eq(Sides.manageRefusal(action, 1, 1), nil, `{action}: co-op`)
		eq(Sides.manageRefusal(action, 2, 2), nil, `{action}: a teammate's tower on your side`)
		local why = Sides.manageRefusal(action, 1, 2)
		ok(type(why) == "string" and #why > 0, `{action}: enemy refused`)
		ok(Sides.manageRefusal(action, 3, 1) ~= nil, `{action}: the other way too`)
	end
	eq(Sides.manageRefusal("upgrade", 1, 2), "You can't upgrade another camp's tower")
	eq(Sides.manageRefusal("repair", 2, 1), "Only its own camp can repair it")
	eq(Sides.manageRefusal("sell", 1, 3), "You can't sell another camp's tower")
	ok(Sides.manageRefusal("anything", 1, 2) ~= nil, "an unknown action is still refused")
end)

test("per-side attribute names: side 1 keeps today's names", function()
	eq(Sides.attr("Cash", 1), "Cash", "co-op cash")
	eq(Sides.attr("Lives", 1), "Lives", "co-op Fence")
	eq(Sides.attr("Cash", 2), "Cash2")
	eq(Sides.attr("Lives", 10), "Lives10")
	eq(Sides.playerSide(nil, nil), 1, "co-op: no attributes")
	eq(Sides.playerSide(2, 3), 2)
	eq(Sides.playerSide(2, nil), 1, "no Sides attribute = co-op")
	eq(Sides.playerSide(4, 3), 1)
end)

-- The server applies the rules (source checks, as tarpit.spec does for Towers) ----------

local function count(text: string, needle: string): number
	local n, from = 0, 1
	while true do
		local at = string.find(text, needle, from, true)
		if not at then
			return n
		end
		n += 1
		from = at + #needle
	end
end

test("Economy is still the only cash and Fence mutator", function()
	for _, entry in fs.readDir("src/server") do
		local text = fs.readFile(`src/server/{entry}`)
		if entry ~= "Economy.luau" then
			eq(count(text, "Shared:WaitForChild(\"Ledger\")"), 0, `{entry} reaches the ledger`)
			eq(count(text, "ReplicatedStorage:SetAttribute(\"Cash\""), 0, `{entry} sets cash`)
			eq(count(text, "ReplicatedStorage:SetAttribute(\"Lives\""), 0, `{entry} sets lives`)
			eq(count(text, "Sides.attr(\"Cash\""), 0, `{entry} sets a side's cash`)
		end
	end
	for _, entry in fs.readDir("src/client") do
		eq(count(fs.readFile(`src/client/{entry}`), "Ledger"), 0, `{entry} reaches the ledger`)
	end
	local economy = fs.readFile("src/server/Economy.luau")
	ok(count(economy, "Ledger.trySpend(ledger, side, amount)") == 1, "one spend path")
end)

test("Shop spends the builder's side's cash and refuses enemy towers", function()
	local shop = fs.readFile("src/server/Shop.luau")
	eq(count(shop, "Economy.trySpend("), 0, "no side-less spend left")
	eq(count(shop, "Economy.earn("), 0, "no side-less refund left")
	eq(count(shop, "Economy.trySpendFor(side,"), 3, "build, upgrade, repair pay from your side")
	for _, action in { "upgrade", "repair", "sell" } do
		eq(count(shop, `Sides.manageRefusal("{action}"`), 1, `{action} checks the side`)
	end
	ok(count(shop, "Placement.check(spot, Towers.positions(), def.onTrack, Sides.zone(layout, side))") == 1, "build checks your zone")
	local hero = fs.readFile("src/server/Hero.luau")
	eq(count(hero, "Economy.trySpend("), 0, "hero upgrades pay from your side")
	eq(count(hero, "Economy.earn("), 0, "hero refunds go to your side")
end)
