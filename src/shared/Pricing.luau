--[[
	Tower prices the shop charges and pays back. Pure, so the numbers can be
	tested headlessly; Server/Shop is the only caller that moves cash.

	  upgradeCost   a tier's Config cost, less a Supply Camp Logistics discount
	                (percent), rounded to the nearest whole
	  sellRefund    everything put into the tower (base + upgrades paid) times
	                the refund rate: Tuning SellRefund, or a Logistics aura's
	                higher rate (Recycler, Base Camp), rounded down, less
	                what repairing it would cost right now (never below 0;
	                DECISIONS #35), so selling and rebuying a damaged tower
	                never beats repairing it
	  startingPot   the difficulty's Starting cash (DECISIONS #136), plus
	                Tuning Starting cash per extra player for each player
	                beyond the first
]]

local Config = require(script.Parent.Config)

local Pricing = {}

function Pricing.upgradeCost(step, discountPercent: number): number
	return math.floor(step.cost * (1 - discountPercent / 100) + 0.5)
end

-- `repairPrice` is Combat.repairCost for the tower's current HP (0 at full).
function Pricing.sellRefund(spent: number, auraRefund: number, repairPrice: number?): number
	local refund = math.floor(spent * math.max(Config.Tuning.SellRefund, auraRefund))
	return math.max(0, refund - (repairPrice or 0))
end

-- The shared pot once `players` have joined the match (Server/Main seeds it with one
-- player, then adds the per-player share as each extra player joins).
function Pricing.startingPot(difficulty: { startingCash: number }, players: number): number
	return difficulty.startingCash + Config.Tuning.StartingCashPerExtraPlayer * math.max(0, players - 1)
end

return Pricing
