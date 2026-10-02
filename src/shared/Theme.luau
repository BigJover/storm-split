--[[
	The game's name and wording in one place (VISION.md: Dino Hunters). Change a
	name here and every screen follows. Internal keys (SCOUT, HUSK, ...) and the
	save-file name never change.
]]

return table.freeze({
	Title = "Dino Hunters",
	Currency = "Amber", -- the permanent currency (was "Storm Cores")

	-- The Hunt Board (DECISIONS #63, #76): log-in calendar and challenges.
	HuntBoard = "Hunt Board",
	DailyHaul = "Daily Haul",
	BigHaul = "Big Haul", -- the last day of the Daily Haul
	DailyBounties = "Daily Bounties",
	WeeklyBounties = "Weekly Bounties",
	Swap = "Swap", -- trading a bounty for another
})
