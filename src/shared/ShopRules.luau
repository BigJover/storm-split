--[[
	Shop rules shared by server and client. Feature gating and interaction
	distances only — prices and stats come from Config, never from here.
]]

return table.freeze({
	-- In Config but not sold yet: their special behaviour isn't built
	-- (ARCHITECTURE.md §8, phase 5 — Chiller's slow, Quartermaster's income).
	Unreleased = table.freeze({
		CHILLER = true,
		QUARTERMASTER = true,
	}),

	-- How close (studs) a player must be to a pad to open its shop.
	PromptDistance = 10,
})
