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
