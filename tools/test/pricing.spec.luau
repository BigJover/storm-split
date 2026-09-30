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
	eq(COMMAND_CENTER.name, "Command Center")
	eq(BULK_ORDER.discountPercent, 5, "Bulk Order discount")
	eq(COMMAND_CENTER.discountPercent, 20, "Command Center discount")
	eq(RECYCLER.sellRefund, 0.9, "Recycler refund")
	eq(COMMAND_CENTER.sellRefund, 1, "Command Center refund")
	eq(Config.Tuning.SellRefund, 0.7, "normal refund")
end)

test("upgrade cost: no discount is the Config price", function()
	eq(Pricing.upgradeCost({ cost = 460 }, 0), 460)
	eq(Pricing.upgradeCost({ cost = 64363 }, 0), 64363)
end)

test("upgrade cost: Bulk Order 5% and Command Center 20%, rounded to nearest", function()
	eq(Pricing.upgradeCost({ cost = 460 }, BULK_ORDER.discountPercent), 437)
	eq(Pricing.upgradeCost({ cost = 1058 }, BULK_ORDER.discountPercent), 1005) -- 1005.1
	eq(Pricing.upgradeCost({ cost = 2300 }, COMMAND_CENTER.discountPercent), 1840)
	eq(Pricing.upgradeCost({ cost = 5290 }, BULK_ORDER.discountPercent), 5026) -- 5025.5 rounds up
	eq(Pricing.upgradeCost({ cost = 12167 }, COMMAND_CENTER.discountPercent), 9734) -- 9733.6
end)

test("sell refund: 0.7 normally, Recycler 0.9, Command Center 1.0, rounded down", function()
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
	eq(Combat.repairCost(2000, 0, 100, COMMAND_CENTER.discountPercent), 480, "trampled, Command Center: 600 less 20%")
	eq(Combat.repairCost(2000, 75, 100, 0), 150, "a quarter missing")
	-- DECISIONS #10 says a full repair (30% of spent) beats selling and buying again.
	-- At the normal 70% refund the two cost the same; with Recycler / Command Center
	-- refunds, rebuilding is cheaper. Recorded here so a tuning change shows up.
	local spent = 2000
	local rebuildNet = spent - Pricing.sellRefund(spent, 0)
	eq(Combat.repairCost(spent, 0, 100), rebuildNet, "normal refund: repair == rebuild")
	ok(spent - Pricing.sellRefund(spent, RECYCLER.sellRefund) < Combat.repairCost(spent, 0, 100), "Recycler: rebuild cheaper")
end)
