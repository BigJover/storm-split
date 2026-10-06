--[[
	Side assignment inside one server (PLAN phase 7 T71, DECISIONS #219, #225). Pure, so
	a lobby place can reuse it later.

	  assign(players, sides, trophies?) -> (teams, sideOf)
	      players   the players (any ids) in the order they joined / pressed Ready
	      sides     how many sides (Shared/Modes.sideCount)
	      trophies  optional id -> Trophies (competitive). Given: players are ranked by
	                Trophies, most first (equal Trophies keep the order given), then
	                snake-drafted: 1, 2, 3, 3, 2, 1, 1, ... Not given: dealt round-robin
	                in the order given.
	      teams     side -> its players, in draft order; sideOf: id -> side
	  Side sizes always differ by at most 1, and the same input always gives the same
	  answer.
]]

local Matchmaking = {}

function Matchmaking.assign<Id>(players: { Id }, sides: number, trophies: { [Id]: number }?): ({ { Id } }, { [Id]: number })
	local teams: { { Id } } = {}
	for side = 1, math.max(1, sides) do
		teams[side] = {}
	end
	local count = #teams
	local order = table.clone(players)
	if trophies then
		local index: { [Id]: number } = {}
		for i, id in players do
			index[id] = i
		end
		table.sort(order, function(a, b)
			local ta, tb = trophies[a] or 0, trophies[b] or 0
			if ta ~= tb then
				return ta > tb
			end
			return index[a] < index[b]
		end)
	end
	local sideOf: { [Id]: number } = {}
	for i, id in order do
		local lap, pos = (i - 1) // count, (i - 1) % count
		local side = if trophies and lap % 2 == 1 then count - pos else pos + 1
		table.insert(teams[side], id)
		sideOf[id] = side
	end
	return teams, sideOf
end

return table.freeze(Matchmaking)
