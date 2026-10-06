--[[
	Player level: the overall level saved between matches (PLAN round 4 T55, DECISIONS
	#118-#121, #124). Not the hunter's in-match level (Shared/HeroXp, untouched), so its
	label is never "Lv N". Pure: Config in, numbers out. Server/Progression is the only
	mutator of a player's saved XP.

	  Curve      level n -> n+1 costs PlayerXPBase + PlayerXPStep x (n-1), at most
	             PlayerXPPerLevelMax; no top level.
	  Match XP   the hero XP banked on cleared rounds, counted before the hunter-level
	             clamp: round XP + take-down XP (x SoloTakeDownXPX in solo, player XP
	             only), + the difficulty's Clear XP if the track was cleared. Banked
	             once, when the match ends, won or lost, for the hunters still there.
	  Rewards    cosmetics and titles only (rewardAt), never gameplay power.
]]

local Config = require(script.Parent.Config)

local PlayerLevel = {}

export type Reward = "common" | "rare" | "legendary" | "title" | "none"

-- Whole, finite and not negative: anything else counts as 0.
local function whole(n: any): number
	if type(n) ~= "number" or n ~= n or n == math.huge then
		return 0
	end
	return math.max(0, math.floor(n))
end
PlayerLevel.whole = whole

local function levers(): (number, number, number)
	local t = Config.Tuning
	return t.PlayerXPBase, t.PlayerXPStep, t.PlayerXPPerLevelMax
end

-- The first level whose next level costs the max (math.huge if the curve never gets there).
local function capLevel(): number
	local base, step, max = levers()
	if base >= max then
		return 1
	end
	if step <= 0 then
		return math.huge
	end
	return 1 + math.ceil((max - base) / step)
end

-- XP it takes to go from `level` to the next one.
function PlayerLevel.cost(level: number): number
	local base, step, max = levers()
	return math.min(base + step * (math.max(1, math.floor(level)) - 1), max)
end

-- Total XP to reach `level` from nothing (level 1 = 0).
function PlayerLevel.xpFor(level: number): number
	local base, step, max = levers()
	local target = math.max(1, math.floor(level))
	local cap = capLevel()
	local function rising(l: number): number -- levels below the cap: an arithmetic series
		return (l - 1) * base + step * (l - 1) * (l - 2) / 2
	end
	if target <= cap then
		return rising(target)
	end
	return rising(cap) + (target - cap) * max
end

-- The level `xp` total XP reaches.
function PlayerLevel.level(xp: number): number
	local have = whole(xp)
	local cap = capLevel()
	if cap ~= math.huge then
		local atCap = PlayerLevel.xpFor(cap)
		if have >= atCap then
			local _, _, max = levers()
			return cap + math.floor((have - atCap) / max)
		end
	end
	-- Below the cap: the highest level whose total is within `have`.
	local low, high = 1, 2
	while PlayerLevel.xpFor(high) <= have do
		low, high = high, high * 2
	end
	while high - low > 1 do
		local mid = (low + high) // 2
		if PlayerLevel.xpFor(mid) <= have then
			low = mid
		else
			high = mid
		end
	end
	return low
end

-- What a level bar shows: XP into the current level, XP this level takes, the level.
function PlayerLevel.progress(xp: number): (number, number, number)
	local have = whole(xp)
	local level = PlayerLevel.level(have)
	return have - PlayerLevel.xpFor(level), PlayerLevel.cost(level), level
end

-- One match's player XP. `difficulty` is a Config.Difficulties key.
function PlayerLevel.matchXp(
	bankedRoundXp: number,
	bankedTakedownXp: number,
	solo: boolean,
	cleared: boolean,
	difficulty: string?
): number
	local takedown = whole(bankedTakedownXp)
	if solo then
		takedown *= Config.Tuning.SoloTakeDownXPX
	end
	local row = if difficulty then (Config.Difficulties :: any)[difficulty] else nil
	local clear = if cleared and row then whole(row.clearXp) else 0
	return whole(whole(bankedRoundXp) + takedown + clear)
end

-- The reward tier a level unlocks (DECISIONS #121). The T57 Cosmetics sheet will name
-- the items; the ladder itself is this.
function PlayerLevel.rewardAt(level: number): Reward
	local l = math.floor(level)
	if l < 2 then
		return "none"
	elseif l == 150 or l == 200 then
		return "legendary"
	elseif l <= 100 then
		return if l % 10 == 0 then "rare" else "common"
	elseif l > 200 and l % 50 == 0 then
		return "title"
	end
	return "none"
end

return PlayerLevel
