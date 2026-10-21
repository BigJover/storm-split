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
	  StudioOnly.standInPick(isStudio, text, towers)
                                          "standinpick <tower> <path> <letters>" (PLAN
                                          T115b, #310): the tower key (or its display
                                          name), the path id and 1-2 option letters,
                                          e.g. "Tranq Station Sedate C" -> "CHILLER", 1,
                                          "C"; nil in a live server or on a bad text
  StudioOnly.FEATURES                     every Studio-only feature and what it does

	The server passes RunService:IsStudio(); a client is never asked (it could lie). The
	Studio remotes are only created when this says yes, and each handler asks again, so a
	remote that somehow existed in a live server still does nothing.
]]

local StudioOnly = {}

StudioOnly.FEATURES = {
	cash = "K: +cash for your camp (the StudioCash remote, Server/Main)",
	amber = "J: +100K Amber and saving off for that player (the StudioProgress remote, Server/Progression)",
	towerHit = "L: knock HP off the tower nearest you (the StudioTowerHit remote, Server/Main)",
	standIns = "Fill with stand-ins: camps with no player in battles (Server/Main lobby, Server/Battle)",
	startRound = 'Start at round N: the host\'s Lobby ("startround", n), co-op and battles (Server/Main, Server/Battle)',
	standInsHold = 'Stand-ins hold: a stand-in camp\'s Fence stays at 1 while a real camp is in (Lobby ("standinshold", on), also mid-match; Server/Battle)',
	standInPierce = "Stand-in camps' fixed towers pierce armour, for test fidelity (Server/Shop, PLAN T91b)",
	lateStandIn = 'Late stand-in joins now: the host\'s Lobby ("latestandin") mid-battle seats a stand-in as a late joiner (catch-up cash, toast), refused like a player in Ranked/Practice or after Late join last round (Server/Main, Server/Battle, PLAN T105)',
	clockCap = 'Short match clock: the host\'s Lobby ("clockcap", seconds) for testing the clock end and its warning (Server/Main, Server/Battle, PLAN T104)',
	standInPick = 'Stand-in picks: the host\'s Lobby ("standinpick", "<tower> <path> <letters>") mid-battle sets every stand-in camp\'s tower of that kind to that path\'s tier 3 + those options (placing one if the camp has none), so the Tester can raid a B/C option (Server/Main, Server/Battle, PLAN T115b, #310)',
	fireNow = 'Fire now: the host\'s Lobby ("firenow", "<tower key>") makes the nearest tower of that key fire its once-a-round / timed effect now (Amber Age, Resin Wall; Raptor Swarm, Raptor Charge; a Bone Totem fills; a Spotter Blimp: Bombing Run, Paratroopers, Airlift; a Meteor Beacon: a strike, Extinction Event, Comet Tail; a Volcano Vent: an eruption, Supervolcano; a Ranger Station: Master Trapper\'s line, the Legend\'s dart), ignoring AutoFire and timers (Server/Main, PLAN 9g)',
	fossils = 'Fossils: the host\'s Lobby ("fossils", n) sets the nearest Amber Resin Cannon\'s match fossil count (Amber Heart tests; Server/Main, PLAN 9g)',
	walkers = 'Walkers: the host\'s Lobby ("walkers") prints every walker (tower, state, HP, target) to Output (Server/Main, PLAN 9g)',
	trainSkip = 'Train skip: "trainskip <min>" (the Training remote) credits that many full-rate minutes to whatever you are training, and turns saving off for that player like J (Server/Training, Server/Progression, PLAN 10c T139)',
	pets = 'Pet aids: the Pets remote ("studioegg", egg) puts a free egg in the incubator, ("hatchnow") makes every egg ready, ("studiopet", "<PET> <RARITY>", n) adds pets for fuse tests; each turns saving off for that player like J (Server/Pets, Server/Progression, PLAN 10d T140)',
	charge = 'Charge: the host\'s Lobby ("charge", n) sets the nearest Bone Totem\'s charge; at or over full it fires (Server/Main, PLAN 9h)',
} :: { [string]: string }

function StudioOnly.allowed(isStudio: boolean, feature: string): boolean
	return isStudio == true and StudioOnly.FEATURES[feature] ~= nil
end

-- "firenow <tower>" (PLAN 9g): the tower key (or display name) in Studio; nil live or unknown.
function StudioOnly.fireNow(isStudio: boolean, text: unknown, towers: { [string]: any }): string?
	if not StudioOnly.allowed(isStudio, "fireNow") or type(text) ~= "string" then
		return nil
	end
	local wanted = string.lower((string.gsub(string.gsub(text, "^%s+", ""), "%s+$", "")))
	for key, def in towers do
		if string.lower(key) == wanted or string.lower(def.display or "") == wanted then
			return key
		end
	end
	return nil
end

-- "fossils <n>" (PLAN 9g): a whole n >= 0 in Studio; nil live or not a count.
function StudioOnly.fossils(isStudio: boolean, n: unknown): number?
	if StudioOnly.allowed(isStudio, "fossils") and type(n) == "number" and n >= 0 and n < 1e6 then
		return math.floor(n)
	end
	return nil
end

-- "charge <n>" (PLAN 9h): a number n >= 0 in Studio; nil live or not a number.
function StudioOnly.charge(isStudio: boolean, n: unknown): number?
	if StudioOnly.allowed(isStudio, "charge") and type(n) == "number" and n >= 0 and n < 1e6 then
		return n
	end
	return nil
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

local function trim(text: string): string
	return (string.gsub(string.gsub(text, "^%s+", ""), "%s+$", ""))
end

function StudioOnly.standInPick(isStudio: boolean, text: unknown, towers: { [string]: any }): (string?, number?, string?)
	if not StudioOnly.allowed(isStudio, "standInPick") or type(text) ~= "string" then
		return nil
	end
	local rest, letters = string.match(trim(text), "^(.-)%s+(%a+)$")
	if not rest or not letters then
		return nil
	end
	letters = string.upper(letters)
	if #letters > 2 or string.find(letters, "[^ABC]") then
		return nil
	end
	local lower = string.lower(trim(rest))
	for key, def in towers do
		for _, name in { string.lower(key), string.lower(def.display or key) } do
			if string.sub(lower, 1, #name + 1) == name .. " " then
				local pathName = trim(string.sub(lower, #name + 2))
				for i, path in def.paths or {} do
					if string.lower(path.id) == pathName then
						return key, i, letters
					end
				end
			end
		end
	end
	return nil
end

return StudioOnly
