--[[
	Game modes and tracks the home screen offers. Display and availability only;
	numbers live in the spreadsheet. A mode or track that isn't built yet is
	listed with `available = false` so players can see what's coming.
]]

local Theme = require(script.Parent.Theme)

export type Mode = { display: string, blurb: string, available: boolean }
export type TrackInfo = { display: string, blurb: string }

return table.freeze({
	ModeOrder = { "COOP", "TEAM", "ROYALE" },
	Modes = table.freeze({
		COOP = { display = "Co-op", blurb = "Defend the track together. Casual: no buy-in.", available = true },
		TEAM = { display = "Team Battle", blurb = "Two or three teams, each defending its own side.", available = false },
		ROYALE = { display = "Battle Royale", blurb = `Every player for themselves. Most {Theme.Bones} wins.`, available = false },
	} :: { [string]: Mode }),

	-- Each track is its own level (VISION.md). One for now: Shared/Track.
	TrackOrder = { "SERPENTINE" },
	Tracks = table.freeze({
		SERPENTINE = { display = "Serpentine", blurb = "Four lanes snaking across the field." },
	} :: { [string]: TrackInfo }),
})
