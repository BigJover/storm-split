--[[
	Studio-only test features (PLAN T89): the one rule the server asks before any of them
	exists or acts. Pure, so a spec can prove each is refused in a live server.

	  StudioOnly.allowed(isStudio, feature)   true only in Studio and only for a listed
	                                          feature; anything else (a typo, a new
	                                          feature nobody listed, a live server) is false
	  StudioOnly.startRound(isStudio, wanted, last?) "Start at round N": `wanted` (whole,
	                                          at most `last`) in Studio, round 1 live
	  StudioOnly.heldLoss(isStudio, hold, standIn, fence, cost, realAlive)
	                                          "Stand-ins hold": the Fence a leak takes. A
	                                          stand-in camp with hold on keeps 1 while a
	                                          real hunter's camp is still in (PLAYTEST N7:
	                                          once they're all out the hold lets go, so the
	                                          match can end); anything else (or a live
	                                          server) loses `cost`
	  StudioOnly.matchCap(isStudio, wanted, cap?) the battle clock (T104): a Studio test
	                                          clock of `wanted` seconds (whole, above 0)
	                                          when shorter than `cap`; `cap` otherwise and
	                                          always live (nil cap = no clock, co-op)
	  StudioOnly.FEATURES                     every Studio-only feature and what it does

	The server passes RunService:IsStudio(); a client is never asked (it could lie). The
	Studio remotes are only created when this says yes, and each handler asks again, so a
	remote that somehow existed in a live server still does nothing.
]]

local StudioOnly = {}

StudioOnly.FEATURES = {
	cash = "K: +cash for your camp (the StudioCash remote, Server/Main)",
	amber = "J: +100 Amber and saving off for that player (the StudioProgress remote, Server/Progression)",
	towerHit = "L: knock HP off the tower nearest you (the StudioTowerHit remote, Server/Main)",
	standIns = "Fill with stand-ins: camps with no player in battles (Server/Main lobby, Server/Battle)",
	startRound = 'Start at round N: the host\'s Lobby ("startround", n), co-op and battles (Server/Main, Server/Battle)',
	standInsHold = 'Stand-ins hold: a stand-in camp\'s Fence stays at 1 while a real camp is in (Lobby ("standinshold", on), also mid-match; Server/Battle)',
	standInPierce = "Stand-in camps' fixed towers pierce armour, for test fidelity (Server/Shop, PLAN T91b)",
	clockCap = 'Short match clock: the host\'s Lobby ("clockcap", seconds) for testing the clock end and its warning (Server/Main, Server/Battle, PLAN T104)',
} :: { [string]: string }

function StudioOnly.allowed(isStudio: boolean, feature: string): boolean
	return isStudio == true and StudioOnly.FEATURES[feature] ~= nil
end

function StudioOnly.startRound(isStudio: boolean, wanted: unknown, last: number?): number
	if StudioOnly.allowed(isStudio, "startRound") and type(wanted) == "number" and wanted >= 1 and wanted < math.huge then
		local round = math.floor(wanted)
		return if last then math.min(round, last) else round
	end
	return 1
end

function StudioOnly.matchCap(isStudio: boolean, wanted: unknown, cap: number?): number?
	if cap and StudioOnly.allowed(isStudio, "clockCap") and type(wanted) == "number" and wanted >= 1 and wanted < cap then
		return math.floor(wanted)
	end
	return cap
end

function StudioOnly.heldLoss(isStudio: boolean, hold: unknown, standIn: boolean, fence: number, cost: number, realAlive: boolean?): number
	if StudioOnly.allowed(isStudio, "standInsHold") and hold == true and standIn and realAlive == true then
		return math.max(0, math.min(cost, fence - 1))
	end
	return cost
end

return StudioOnly
