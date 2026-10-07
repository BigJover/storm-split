--[[
	Economy: each side's cash and lives (the Fence) (ARCHITECTURE.md §4, §5.3).

	OWNERSHIP: the only module that changes cash or lives. Cash is one pot per side, shared
	by everyone on that side (design doc: "Co-op 2–4, shared cash"; PLAN phase 7 T76: a
	battle side has its own pot and Fence). Co-op is one side, side 1, and the old API
	(earn / trySpend / cash / setLives / lose / lives, no side) is side 1, unchanged.
	The arithmetic is the pure Shared/Ledger; this module holds the one ledger and
	publishes it.

	Every spend goes through trySpend / trySpendFor, which checks and deducts in one
	step with no yield in between, so four players clicking at once can never all
	pass the same check.

	Cash is kept fractional internally because kill income is HP destroyed x
	CashPerEffectiveHP (a Husk pays 0.43). Clients see the floor through the
	side's cash attribute (Shared/Sides.attr: "Cash" for side 1, "Cash2"... for the
	others; lives likewise "Lives", "Lives2"...), and trySpend compares against the real
	value, so what the HUD shows is never more than what can be spent.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ledger = require(Shared:WaitForChild("Ledger"))
local Sides = require(Shared:WaitForChild("Sides"))

local Economy = {}

local ledger = Ledger.new(1, 0, 0)
local published = 0 -- sides with attributes out
local onOut: ((number) -> ())? = nil

local function publishCash(side: number)
	ReplicatedStorage:SetAttribute(Sides.attr("Cash", side), math.floor(Ledger.cash(ledger, side)))
end

local function publishLives(side: number)
	ReplicatedStorage:SetAttribute(Sides.attr("Lives", side), Ledger.lives(ledger, side))
end

local function unknown(side: number): boolean
	if Ledger.has(ledger, side) then
		return false
	end
	warn(`[Economy] No side {side} in this match`)
	return true
end

-- A fresh match: `sides` pots, each with the same starting cash and Fence.
-- `whenOut(side)` runs once when a side's lives reach 0.
function Economy.initSides(sides: number, startingCash: number, startingLives: number, whenOut: (number) -> ())
	ledger = Ledger.new(sides, startingCash, startingLives)
	onOut = whenOut
	local count = #ledger.pots
	for side = count + 1, published do -- a smaller match than the last: drop the extras
		ReplicatedStorage:SetAttribute(Sides.attr("Cash", side), nil)
		ReplicatedStorage:SetAttribute(Sides.attr("Lives", side), nil)
	end
	published = count
	for side = 1, count do
		publishCash(side)
		publishLives(side)
	end
end

-- Co-op: one side.
function Economy.init(startingCash: number, startingLives: number, whenLivesZero: () -> ())
	Economy.initSides(1, startingCash, startingLives, function(_side: number)
		whenLivesZero()
	end)
end

------------------------------------------------------------------ cash

function Economy.earnFor(side: number, amount: number)
	if unknown(side) then
		return
	end
	if Ledger.earn(ledger, side, amount) then
		publishCash(side)
	end
end

-- Returns true and deducts if the side can afford it; otherwise changes nothing.
function Economy.trySpendFor(side: number, amount: number): boolean
	if unknown(side) then
		return false
	end
	if not Ledger.trySpend(ledger, side, amount) then
		return false
	end
	publishCash(side)
	return true
end

function Economy.cashOf(side: number): number
	return Ledger.cash(ledger, side)
end

function Economy.earn(amount: number)
	Economy.earnFor(1, amount)
end

function Economy.trySpend(amount: number): boolean
	return Economy.trySpendFor(1, amount)
end

function Economy.cash(): number
	return Economy.cashOf(1)
end

------------------------------------------------------------------ lives

-- Difficulty sets lives when the match starts.
function Economy.setLivesFor(side: number, amount: number)
	if unknown(side) then
		return
	end
	Ledger.setLives(ledger, side, amount)
	publishLives(side)
end

function Economy.loseFor(side: number, amount: number)
	if unknown(side) then
		return
	end
	local changed, out = Ledger.lose(ledger, side, amount)
	if not changed then
		return
	end
	publishLives(side)
	if out and onOut then
		onOut(side)
	end
end

function Economy.livesOf(side: number): number
	return Ledger.lives(ledger, side)
end

function Economy.setLives(amount: number)
	Economy.setLivesFor(1, amount)
end

function Economy.lose(amount: number)
	Economy.loseFor(1, amount)
end

function Economy.lives(): number
	return Economy.livesOf(1)
end

return Economy
