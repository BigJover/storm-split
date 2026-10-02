--[[
	One health pool per dino, sizes as thresholds on it, and pierce-through
	(DECISIONS #125-#128, PLAN "One health pool and pierce-through"). Pure, so
	the rule has headless specs; Server/Enemies applies it.

	A dino's pool is its species' total HP. With `sizes` s and share = pool / s,
	it is size k while its HP is in ((k-1)*share, k*share]. Crossing a threshold
	shrinks it one size and pays like an emptied size always has.

	  breaks  the most thresholds one hit may cross:
	            b = min(Max size breaks, max(1, base + level bonus - resist))
	          base = the tier's Size breaks (1 when blank); level bonus =
	          floor((tower level - 1) / Break level step), only when base >= 2,
	          never for heroes; resist = the species' Break resist.
	  apply   one hit on the pool: the HP never drops below (k - b)*share, where
	          k is the size when it lands; the rest of the damage is lost. With
	          b = 1 this is exactly the old per-size rule (overflow lost, the next
	          size starts full). Returns the new HP, sizes dropped and whether it
	          died (only when k - b <= 0 and the damage reaches 0 HP).
	  sizeOf  the size for an HP on the pool (k with HP in ((k-1)*share, k*share])
]]

local Config = require(script.Parent.Config)

local SizeBreaks = {}

-- A hit that lands within this share-relative sliver of a threshold counts as
-- reaching it (floating-point slack on the pool, never a real remainder).
local EPSILON = 1e-9

local function lever(name: string, default: number): number
	local tuning = Config.Tuning
	local value = tuning and tuning[name]
	return if type(value) == "number" then value else default
end

function SizeBreaks.breaks(base: number?, towerLevel: number?, resist: number?, isHero: boolean?): number
	local b = math.max(1, math.floor(base or 1))
	if b >= 2 and not isHero then
		local step = lever("BreakLevelStep", 3)
		if step > 0 then
			b += math.floor((math.max(1, towerLevel or 1) - 1) / step)
		end
	end
	b -= math.max(0, math.floor(resist or 0))
	return math.clamp(b, 1, math.max(1, math.floor(lever("MaxSizeBreaks", 4))))
end

function SizeBreaks.sizeOf(hp: number, share: number): number
	if hp <= 0 or share <= 0 then
		return 0
	end
	return math.max(1, math.ceil(hp / share - EPSILON))
end

-- One hit of `amount` on a dino at `size` with `hp` left on its pool.
function SizeBreaks.apply(hp: number, share: number, size: number, amount: number, b: number?): (number, number, boolean)
	if amount <= 0 or size <= 0 then
		return hp, 0, size <= 0
	end
	local cap = math.max(1, math.floor(b or 1))
	local floorHp = math.max(0, size - cap) * share
	local left = math.max(hp - amount, floorHp)
	local slack = share * EPSILON
	local now = size
	while now > 0 and left <= (now - 1) * share + slack do -- never past size - cap: left >= floorHp
		now -= 1
	end
	local dropped = size - now
	if now <= 0 then
		return 0, dropped, true
	end
	return left, dropped, false
end

return SizeBreaks
