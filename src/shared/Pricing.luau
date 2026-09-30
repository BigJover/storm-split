--[[
	Tower prices the shop charges and pays back. Pure, so the numbers can be
	tested headlessly; Server/Shop is the only caller that moves cash.

	  upgradeCost   a tier's Config cost, less a Supply Camp Logistics discount
	                (percent), rounded to the nearest whole
	  sellRefund    everything put into the tower (base + upgrades paid) times
	                the refund rate: Tuning SellRefund, or a Logistics aura's
	                higher rate (Recycler, Command Center), rounded down
]]

local Config = require(script.Parent.Config)

local Pricing = {}

function Pricing.upgradeCost(step, discountPercent: number): number
	return math.floor(step.cost * (1 - discountPercent / 100) + 0.5)
end

function Pricing.sellRefund(spent: number, auraRefund: number): number
	return math.floor(spent * math.max(Config.Tuning.SellRefund, auraRefund))
end

return Pricing
