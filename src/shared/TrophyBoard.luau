--[[
	The Trophy leaderboard's rules (PLAN phase 7 T81, DECISIONS #218). Pure. It is the
	level board (Shared/LevelBoard) ranking Trophies instead of player XP: the same tick,
	merge, top 50, "This server" fallback (unpublished, Studio or a failing store) with its
	note, and your own row. Trophies can drop, so this server's hunters count with their
	live Trophies (`live` rows) rather than the higher of live and stored.
	Server/TrophyBoard talks to its own OrderedDataStore; the Profile screen's Trophies tab
	(T83) draws `view`.

	  view(world, here, me)  LevelBoard.view with live rows (`here` = { userId, name, trophies })
	  arenaName(trophies)    the arena badge: the name of the arena those Trophies are in
	  badge(trophies)        "<Trophies> · <Arena>" for the in-game player list
]]

local Config = require(script.Parent.Config)
local LevelBoard = require(script.Parent.LevelBoard)
local Trophies = require(script.Parent.Trophies)

local TrophyBoard = {}

TrophyBoard.STORE = "DinoHuntersTrophies_v1"
TrophyBoard.TOP = LevelBoard.TOP
TrophyBoard.COLUMN = "Trophies" -- the player list column (the word is reserved for ranked, #130)

export type Here = { userId: number, name: string, trophies: number }

function TrophyBoard.view(world: { LevelBoard.Row }?, here: { Here }, me: number): LevelBoard.View
	local rows: { LevelBoard.Row } = {}
	for _, h in here do
		table.insert(rows, { userId = h.userId, name = h.name, xp = h.trophies, live = true })
	end
	return LevelBoard.view(world, rows, me)
end

function TrophyBoard.arenaName(trophies: number): string
	return Config.Arenas[Trophies.arenaOf(trophies)].display
end

function TrophyBoard.badge(trophies: number): string
	return `{math.max(0, math.floor(trophies))} · {TrophyBoard.arenaName(trophies)}`
end

return table.freeze(TrophyBoard)
