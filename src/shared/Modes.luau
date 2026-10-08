--[[
	Game modes and tracks the home screen offers. Display, availability and how many
	sides a mode plays with; numbers live in the spreadsheet. A mode or track that isn't
	built yet is listed with `available = false` so players can see what's coming.

	Sides (PLAN phase 7 T71, DECISIONS #209, #217, #225). A side is a build plot with its
	own track, Fence, cash pot and dinos.
	  COOP    one side, every player on it
	  TEAM    2 or 3 sides, the host's pick; each side needs a player, so 3 sides need 3
	          players; at least Tuning TeamMinPlayers (1v1 allowed)
	  ROYALE  one side per player: 2 or more casual, Tuning RoyaleMinPlayers competitive
	Battles take at most Tuning BattleMaxPlayers players.

	  sideCount(mode, players, picked?, competitive?)   -> sides, or nil + a reason code (unknownMode, tooFew,
	                                          tooMany, badSides, emptySide)
	  minPlayers(mode, competitive?)       -> the fewest players the mode starts with
]]

local Config = require(script.Parent.Config)
local Theme = require(script.Parent.Theme)

export type SideRule = "one" | "choice" | "perPlayer"
export type Mode = { display: string, blurb: string, available: boolean, sides: SideRule }
export type TrackInfo = { display: string, blurb: string }

-- Structure, not tuning: Camp Clash (team battle) is two or three teams (VISION.md), and a battle
-- needs at least two sides.
local TEAM_SIDES = table.freeze({ 2, 3 })
local BATTLE_SIDES_MIN = 2

local Modes = {
	ModeOrder = { "COOP", "TEAM", "ROYALE" },
	Modes = table.freeze({
		COOP = { display = "Co-op", blurb = "Defend the track together. Casual: no buy-in.", available = true, sides = "one" },
		TEAM = { display = "Camp Clash", blurb = "Two or three camps, each defending its own side.", available = true, sides = "choice" },
		ROYALE = { display = "Bone Rush", blurb = `Every hunter for themselves. Most {Theme.Bones} wins.`, available = true, sides = "perPlayer" },
	} :: { [string]: Mode }),
	TeamSides = TEAM_SIDES,

	-- Each track is its own level (VISION.md). One for now: Shared/Track.
	TrackOrder = { "SERPENTINE" },
	Tracks = table.freeze({
		SERPENTINE = { display = "Serpentine", blurb = "Four lanes snaking across the field." },
	} :: { [string]: TrackInfo }),
}

-- The fewest players a mode starts with. Co-op: one. Team: TeamMinPlayers. Royale:
-- two casual, RoyaleMinPlayers competitive (72/23/5 needs three; DECISIONS #217).
function Modes.minPlayers(modeKey: string, competitive: boolean?): number
	if modeKey == "TEAM" then
		return math.max(BATTLE_SIDES_MIN, Config.Tuning.TeamMinPlayers)
	elseif modeKey == "ROYALE" then
		return if competitive then math.max(BATTLE_SIDES_MIN, Config.Tuning.RoyaleMinPlayers) else BATTLE_SIDES_MIN
	end
	return 1
end

-- How many sides a match of this mode has with `players` players, or nil and why not.
-- `picked` is the host's Team side count (2 when not given).
function Modes.sideCount(modeKey: string, players: number, picked: number?, competitive: boolean?): (number?, string?)
	local mode = Modes.Modes[modeKey]
	if not mode then
		return nil, "unknownMode"
	elseif players < Modes.minPlayers(modeKey, competitive) then
		return nil, "tooFew"
	elseif mode.sides == "one" then
		return 1, nil
	elseif players > Config.Tuning.BattleMaxPlayers then
		return nil, "tooMany"
	elseif mode.sides == "perPlayer" then
		return players, nil
	end
	local sides = picked or TEAM_SIDES[1]
	if not table.find(TEAM_SIDES, sides) then
		return nil, "badSides"
	elseif players < sides then
		return nil, "emptySide"
	end
	return sides, nil
end

return table.freeze(Modes)
