--[[
	The game's name and wording in one place (VISION.md: Dino Hunters). Change a
	name here and every screen follows. Internal keys (SCOUT, HUSK, ...) and the
	save-file name never change.
]]

-- Amber numbers (PLAN 10a T134, DECISIONS #394). Pure.
--   amberExact(n)  the whole figure with separators: 1250000 -> "1,250,000" (prices you pay,
--                  tooltips, results lines where it fits)
--   formatAmber(n) short: under 1,000 as is; then K / M / B with one decimal, a trailing
--                  ".0" dropped, rounded DOWN so it never shows more than you have:
--                  999 -> "999", 12500 -> "12.5K", 100000 -> "100K", 999999 -> "999.9K",
--                  1250000 -> "1.2M", 5325000 -> "5.3M". Fractions are dropped first;
--                  a negative number gets a "-" in front of its size.
local function amberExact(n: number): string
	if n ~= n or n == math.huge or n == -math.huge then
		return "0"
	end
	local whole = math.floor(math.abs(n))
	local out = string.format("%d", whole)
	repeat
		local replaced
		out, replaced = string.gsub(out, "^(%d+)(%d%d%d)", "%1,%2")
	until replaced == 0
	return if n <= -1 then `-{out}` else out
end

local UNITS = { { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }

local function formatAmber(n: number): string
	if n ~= n or n == math.huge or n == -math.huge then
		return "0"
	end
	local whole = math.floor(math.abs(n))
	local sign = if n <= -1 then "-" else ""
	for _, unit in UNITS do
		if whole >= unit[1] then
			local tenths = math.floor(whole / (unit[1] / 10)) -- rounded down
			local head, decimal = tenths // 10, tenths % 10
			return `{sign}{string.format("%d", head)}{if decimal > 0 then `.{decimal}` else ""}{unit[2]}`
		end
	end
	return `{sign}{whole}`
end

-- A price you pay: the short form when it says the exact amount (every price in the sheet
-- today: multiples of 100 under a million, e.g. 300000 -> "300K"), else the exact figure
-- (1234000 -> "1,234,000"), so a price is never rounded.
local function amberPrice(n: number): string
	local whole = math.floor(math.abs(if n == n then n else 0))
	for _, unit in UNITS do
		if whole >= unit[1] then
			return if whole % (unit[1] / 10) == 0 then formatAmber(n) else amberExact(n)
		end
	end
	return formatAmber(n)
end

return table.freeze({
	amberExact = amberExact,
	formatAmber = formatAmber,
	amberPrice = amberPrice,
	Title = "Dino Hunters",
	Currency = "Amber", -- the permanent currency (was "Storm Cores")
	Fence = "Fence", -- what the dinos break through: the lives (DECISIONS #130)
	Bones = "Bones", -- per-match score on the player list (DECISIONS #130)

	-- The Hunt Board (DECISIONS #63, #76): log-in calendar and challenges.
	HuntBoard = "Hunt Board",
	DailyHaul = "Daily Haul",
	BigHaul = "Big Haul", -- the last day of the Daily Haul
	DailyBounties = "Daily Bounties",
	WeeklyBounties = "Weekly Bounties",
	Swap = "Swap", -- trading a bounty for another
	-- Player level (PLAN round 4, working names until the Dino review, T59). Never "Lv":
	-- that's the hunter's in-match level (DECISIONS #118).
	PlayerLevel = "Player level",
	Profile = "Profile",
})
