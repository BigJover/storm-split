--[[
	Studio-only test features (PLAN T89): the one rule the server asks before any of them
	exists or acts. Pure, so a spec can prove each is refused in a live server.

	  StudioOnly.allowed(isStudio, feature)   true only in Studio and only for a listed
	                                          feature; anything else (a typo, a new
	                                          feature nobody listed, a live server) is false
	  StudioOnly.startRound(isStudio, wanted) the testing START_ROUND skip: `wanted` in
	                                          Studio, round 1 in a live server
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
	startRound = "START_ROUND above 1: jump to a later round (Server/Main)",
} :: { [string]: string }

function StudioOnly.allowed(isStudio: boolean, feature: string): boolean
	return isStudio == true and StudioOnly.FEATURES[feature] ~= nil
end

function StudioOnly.startRound(isStudio: boolean, wanted: number): number
	if StudioOnly.allowed(isStudio, "startRound") and type(wanted) == "number" and wanted >= 1 then
		return math.floor(wanted)
	end
	return 1
end

return StudioOnly
