--[[
	Shop rules shared by server and client. Feature gating and interaction
	distances only — prices and stats come from Config, never from here.
]]

return table.freeze({
	-- In Config but not sold (or unlockable) yet, because their behaviour isn't
	-- built. Empty since PLAN T68 released the round-4 batch (Storm Coil, Falcon
	-- Roost, Tar Pit, Harpoon Ballista). tools/value.py reads this list: medians
	-- count released towers only (DECISIONS #196).
	Unreleased = table.freeze({} :: { [string]: boolean }),

	-- How far (studs) from your character you can place a tower. Keeps
	-- placement walk-up: you go to where you want to build.
	PlaceRange = 40,

	-- How close (studs) you must be to a tower to manage it.
	PromptDistance = 10,
})
