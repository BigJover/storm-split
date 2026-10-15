--[[
	Shop rules shared by server and client. Feature gating and interaction
	distances only — prices and stats come from Config, never from here.
]]

return table.freeze({
	-- In Config but not sold (or unlockable) yet: a 4x tower until its batch's release
	-- task (PLAN 9g-9j, DECISIONS #312; the Amber Resin Cannon and Raptor Pen released at T124d, the
	-- Bone Totem at T126c, the Spotter Blimp at T125b; the Volcano Vent at T128b; the Meteor Beacon at T128c). Placeable in
	-- Studio through the J unlock + K cash path. tools/value.py reads this list: medians
	-- count released towers only (DECISIONS #196).
	Unreleased = table.freeze({} :: { [string]: boolean }),

	-- How far (studs) from your character you can place a tower. Keeps
	-- placement walk-up: you go to where you want to build.
	PlaceRange = 40,

	-- How close (studs) you must be to a tower to manage it.
	PromptDistance = 10,
})
