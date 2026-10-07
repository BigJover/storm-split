--[[
	Ledger: each side's cash and Fence (lives) as plain data (PLAN phase 7 T76, DECISIONS
	#209, ARCHITECTURE §4, §5.3). Pure. Server/Economy holds the only ledger and is still the
	only module that changes cash or lives; this is just its arithmetic, so it can be specced.

	Co-op is one side (side 1), and side 1 follows exactly the pre-T76 Economy rules:
	  earn     ignores amount <= 0
	  trySpend refuses amount < 0 or more than the side has; otherwise deducts in one step
	  lose     does nothing once lives are 0; lives = max(0, lives - amount); reports the
	           step that reaches 0 (the side is out) exactly once
	An unknown side is refused (false): cash always belongs to a real side.

	  new(sides, cash, lives)       -> Ledger (every side starts with the same pot and Fence)
	  has(l, side)                  -> a real side?
	  earn(l, side, amount)         -> changed?
	  trySpend(l, side, amount)     -> paid?
	  lose(l, side, amount)         -> changed?, reached 0 now?
	  setLives(l, side, amount)     -> changed?
	  cash(l, side) / lives(l, side) -> the value (0 for an unknown side)
]]

local Ledger = {}

export type Pot = { cash: number, lives: number }
export type Ledger = { pots: { Pot } }

function Ledger.new(sides: number, cash: number, lives: number): Ledger
	local pots = {}
	for side = 1, math.max(1, math.floor(sides)) do
		pots[side] = { cash = cash, lives = lives }
	end
	return { pots = pots }
end

function Ledger.has(l: Ledger, side: number): boolean
	return l.pots[side] ~= nil
end

function Ledger.earn(l: Ledger, side: number, amount: number): boolean
	local pot = l.pots[side]
	if not pot or amount <= 0 then
		return false
	end
	pot.cash += amount
	return true
end

function Ledger.trySpend(l: Ledger, side: number, amount: number): boolean
	local pot = l.pots[side]
	if not pot or amount < 0 or pot.cash < amount then
		return false
	end
	pot.cash -= amount
	return true
end

function Ledger.setLives(l: Ledger, side: number, amount: number): boolean
	local pot = l.pots[side]
	if not pot then
		return false
	end
	pot.lives = amount
	return true
end

function Ledger.lose(l: Ledger, side: number, amount: number): (boolean, boolean)
	local pot = l.pots[side]
	if not pot or pot.lives <= 0 then
		return false, false
	end
	pot.lives = math.max(0, pot.lives - amount)
	return true, pot.lives == 0
end

function Ledger.cash(l: Ledger, side: number): number
	local pot = l.pots[side]
	return if pot then pot.cash else 0
end

function Ledger.lives(l: Ledger, side: number): number
	local pot = l.pots[side]
	return if pot then pot.lives else 0
end

return Ledger
