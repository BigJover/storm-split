--[[
	Ranked Trophies and arenas (PLAN phase 7 T72, DECISIONS #217-#218), Clash Royale-style.
	Pure; Server/Progression (T80) saves what this says. Arenas come from the Arenas sheet
	(Config.Arenas, lowest first, the first floor 0); every function takes an optional list
	instead, for specs.

	  delta(mode, placement, n, practice?)  Trophies one match gives. Team: placement 1 (a
	      winning or tied side) Tuning TeamWinTrophies, else TeamLossTrophies. Royale, n
	      players, third = n // 3: the top third gain, 1st Royale1stTrophies and each place
	      below it one third-step less (n = 10: +30, +20, +10); the middle gets 0; the
	      bottom third lose, last RoyaleLastTrophies and each place above it one step less
	      (n = 10: -7, -13, -20); rounded to the nearest whole. 0 in co-op, in Practice, or
	      for a placement outside 1..n
	  arenaOf(trophies)        the index of the highest arena whose floor is reached
	  apply(trophies, delta)   the new count: never below the floor of the arena you're
	      in, and never below 0. Since a loss can't take you under that floor, the arena
	      you're in is always the best you've reached
	  newArenas(old, new)      the arenas reached for the first time going from old to new
	                           (indices, lowest first); empty when none
	  leaverDelta(mode, n, practice?)  a Ranked leaver's Trophies (PLAN T82, DECISIONS #233):
	      what last place in that lobby gives (Camp Clash: the loss; Bone Rush: last of n)
]]

local Config = require(script.Parent.Config)

export type Arena = { key: string, display: string, floor: number, reward: string }

local Trophies = {}

local function round(x: number): number
	return if x >= 0 then math.floor(x + 0.5) else -math.floor(-x + 0.5)
end

function Trophies.delta(modeKey: string, placement: number, n: number, practice: boolean?): number
	if practice or placement < 1 or placement > n then
		return 0
	end
	local t = Config.Tuning
	if modeKey == "TEAM" then
		return if placement == 1 then t.TeamWinTrophies else t.TeamLossTrophies
	elseif modeKey ~= "ROYALE" then
		return 0
	end
	local third = n // 3
	if third < 1 then
		return 0
	elseif placement <= third then
		return round(t.Royale1stTrophies * (third - placement + 1) / third)
	elseif placement > n - third then
		return round(t.RoyaleLastTrophies * (placement - (n - third)) / third)
	end
	return 0
end

function Trophies.leaverDelta(modeKey: string, n: number, practice: boolean?): number
	return Trophies.delta(modeKey, n, n, practice)
end

function Trophies.arenaOf(trophies: number, arenas: { Arena }?): number
	local list = arenas or Config.Arenas
	local found = 1
	for i, arena in list do
		if trophies >= arena.floor then
			found = i
		end
	end
	return found
end

function Trophies.apply(trophies: number, delta: number, arenas: { Arena }?): number
	local list = arenas or Config.Arenas
	local floor = list[Trophies.arenaOf(trophies, list)].floor
	return math.max(0, floor, trophies + delta)
end

function Trophies.newArenas(old: number, new: number, arenas: { Arena }?): { number }
	local from, to = Trophies.arenaOf(old, arenas), Trophies.arenaOf(new, arenas)
	local out = {}
	for i = from + 1, to do
		table.insert(out, i)
	end
	return out
end

return table.freeze(Trophies)
