--[[
	Pricing: upgrade discounts and sell refunds, with the Supply Camp Logistics tiers
	looked up by (tower, path, tier) so a renamed tier can't hide a changed number.
]]

local Config = require(src.shared.Config)
local Pricing = require(src.shared.Pricing)

local LOGISTICS = Config.Towers.QUARTERMASTER.paths[3]
local BULK_ORDER = LOGISTICS.tiers[1]
local RECYCLER = LOGISTICS.tiers[3]
local COMMAND_CENTER = LOGISTICS.tiers[5]

test("the Logistics tiers are the ones this spec means", function()
	eq(LOGISTICS.id, "Logistics")
	eq(BULK_ORDER.name, "Bulk Order")
	eq(RECYCLER.name, "Recycler")
	eq(COMMAND_CENTER.name, "Base Camp")
	eq(BULK_ORDER.discountPercent, 5, "Bulk Order discount")
	eq(COMMAND_CENTER.discountPercent, 20, "Base Camp discount")
	eq(RECYCLER.sellRefund, 0.9, "Recycler refund")
	eq(COMMAND_CENTER.sellRefund, 1, "Base Camp refund")
	eq(Config.Tuning.SellRefund, 0.7, "normal refund")
end)

test("upgrade cost: no discount is the Config price", function()
	eq(Pricing.upgradeCost({ cost = 460 }, 0), 460)
	eq(Pricing.upgradeCost({ cost = 64363 }, 0), 64363)
end)

test("upgrade cost: Bulk Order 5% and Base Camp 20%, rounded to nearest", function()
	eq(Pricing.upgradeCost({ cost = 460 }, BULK_ORDER.discountPercent), 437)
	eq(Pricing.upgradeCost({ cost = 1058 }, BULK_ORDER.discountPercent), 1005) -- 1005.1
	eq(Pricing.upgradeCost({ cost = 2300 }, COMMAND_CENTER.discountPercent), 1840)
	eq(Pricing.upgradeCost({ cost = 5290 }, BULK_ORDER.discountPercent), 5026) -- 5025.5 rounds up
	eq(Pricing.upgradeCost({ cost = 12167 }, COMMAND_CENTER.discountPercent), 9734) -- 9733.6
end)

test("sell refund: 0.7 normally, Recycler 0.9, Base Camp 1.0, rounded down", function()
	eq(Pricing.sellRefund(1000, 0), 700)
	eq(Pricing.sellRefund(1000, RECYCLER.sellRefund), 900)
	eq(Pricing.sellRefund(1000, COMMAND_CENTER.sellRefund), 1000)
	eq(Pricing.sellRefund(659, 0), 461) -- 461.3
	eq(Pricing.sellRefund(659, RECYCLER.sellRefund), 593) -- 593.1
	eq(Pricing.sellRefund(0, COMMAND_CENTER.sellRefund), 0)
end)

test("sell refund: an aura below the normal rate never lowers it", function()
	eq(Pricing.sellRefund(1000, 0.5), 700)
end)

test("repair (Combat.repairCost) with the Logistics discounts, and against sell-and-rebuild", function()
	local Combat = require(src.shared.Combat)
	eq(Combat.repairCost(2000, 0, 100, BULK_ORDER.discountPercent), 570, "trampled, Bulk Order: 600 less 5%")
	eq(Combat.repairCost(2000, 0, 100, COMMAND_CENTER.discountPercent), 480, "trampled, Base Camp: 600 less 20%")
	eq(Combat.repairCost(2000, 75, 100, 0), 150, "a quarter missing")
end)

test("DECISIONS #35: selling a damaged tower refunds less its repair price, never below 0", function()
	local Combat = require(src.shared.Combat)
	for _, rate in { 0, RECYCLER.sellRefund, COMMAND_CENTER.sellRefund } do -- 0.7 (normal), 0.9, 1.0
		for _, spent in { 200, 659, 2000, 64363 } do
			local where = `rate {math.max(rate, Config.Tuning.SellRefund)}, spent {spent}`
			eq(Pricing.sellRefund(spent, rate, 0), Pricing.sellRefund(spent, rate), `{where}: full HP unchanged`)
			for _, hp in { 0, 50 } do -- trampled, half-damaged
				local repair = Combat.repairCost(spent, hp, 100)
				local refund = Pricing.sellRefund(spent, rate, repair)
				ok(refund >= 0, `{where}, hp {hp}: never below 0`)
				ok(spent - refund >= repair, `{where}, hp {hp}: sell-and-rebuy costs at least the repair`)
			end
		end
	end
	eq(Pricing.sellRefund(1000, 0, 300), 400, "trampled at 0.7: 700 - 300")
	eq(Pricing.sellRefund(1000, COMMAND_CENTER.sellRefund, 300), 700, "trampled at 1.0: 1000 - 300")
	eq(Pricing.sellRefund(100, 0, 500), 0, "never below 0")
end)

test("starting pot per difficulty (DECISIONS #136): Hard 650, others 450, +200 per extra player", function()
	local D = Config.Difficulties
	eq(Pricing.startingPot(D.HARD, 1), 650, "Hard solo")
	eq(Pricing.startingPot(D.HARD, 2), 850, "Hard, 2 players")
	eq(Pricing.startingPot(D.HARD, 10), 650 + 9 * 200, "Hard, 10 players")
	for _, key in { "EASY", "NORMAL", "CHAOS" } do
		eq(Pricing.startingPot(D[key], 1), 450, `{key} solo`)
	end
	eq(D.EASY.startingCash, Config.Tuning.StartingCash, "Easy = the Tuning default")
end)
