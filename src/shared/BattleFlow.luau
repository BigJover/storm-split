--[[
	BattleFlow: the battle match's flow helpers (PLAN phase 7 T77, DECISIONS #210, #213,
	#214, #221, #229-#231). Pure: Config in, answers out. Server/Battle runs the match and
	only calls these (and Shared/BattleRules); specs run them headlessly. Co-op never
	calls them.

	  campName(mode, side, ownerName?) Camp Clash: "Red Camp" / "Blue Camp" / "Green Camp";
	                                   Bone Rush: "<Name>'s Camp" (T74, #229)
	  outLine(camp)                    "<Camp>'s Fence is down! They're out."
	  tranqLine(name)                  "Tranqed by <name>!" (a hunter down, T78)
	  raidLine(name, camp, tower)      "<name> trampled <Camp>'s <tower>" (a raid knock-out)
	  resultTitle(mode, place)         the winner's results title: "Camp Clash — Your camp
	                                   wins the hunt!" / "Bone Rush — Top Hunter!"; nil
	                                   for any other place (T74)
	  standInName(side)                a stand-in side's name ("Stand-in 2")
	  standInOwnerId(side)             a stand-in's owner id: negative, never a real UserId
	  creditStandIn(bones, standIn, side) a pop on a stand-in's track = a Bone for that seat
	                                   (T79b; battle-local, never saved, paid or ranked)
	  seat(mode, ids, picked?, standIns?, competitive?)
	      the match's sides. Without stand-ins: Shared/Modes.sideCount decides (nil + reason
	      when the lobby can't start). With stand-ins (Studio only, #221): one real player is
	      enough; Camp Clash plays `picked` sides (2 or 3), Bone Rush max(players, picked)
	      seats; every side with no player is a stand-in. Players are dealt by
	      Shared/Matchmaking. Returns { sides, teams (side -> ids), sideOf (id -> side),
	      standIn (side -> true) }.
	  roundRow(round)                  the Config.Rounds row a battle round plays, the extra
	                                   HP multiplier and the overtime repeat (Camp Clash's
	                                   Final Stampede: past the table the last row repeats,
	                                   HP x BattleRules.overtimeHpMult each time)
	  clearedSides(sides, out, fenceOf) the sides that cleared a round: in, with Fence left
	                                   (a Fence broken by the round's last dino = no clear, F4)
	  roundDue(cleared, elapsed, clearedAt?) lockstep with the BattleRoundBreak pause after the
	                                   last living side clears (T79b); -> due, clearedAt
	  hasOvertime(mode)                Camp Clash only; Bone Rush ends at the last round
	  sideScale(difficulty, hunters)   a side's Waves.Scale from its own hunter count (the
	                                   CO-OP levers, as co-op scales by the whole server)
	  startingCash(difficulty, hunters) a side's starting cash (Pricing.startingPot)
	  teamPlaces(eliminationOrder, result, sides)
	      side -> placement: the winners 1st (a tie shares 1st), then the sides that fell,
	      the latest fall first; sides that fell in one step share a place
	  royalePlaces(ranking)            id -> placement (1st first)
	  standInTowers()                  the stand-ins' fixed towers: one of each free tower
	                                   that can be damaged (raid targets), in TowerOrder
	  standInSpots(layout, side, n)    n build spots in that side's zone beside its track,
	                                   each passing Shared/Placement like a hunter's
]]

local Config = require(script.Parent.Config)
local BattleRules = require(script.Parent.BattleRules)
local Matchmaking = require(script.Parent.Matchmaking)
local Modes = require(script.Parent.Modes)
local Placement = require(script.Parent.Placement)
local Pricing = require(script.Parent.Pricing)
local ShopRules = require(script.Parent.ShopRules)
local Sides = require(script.Parent.Sides)

local BattleFlow = {}

-- Names (DINO_REVIEW Round 16, DECISIONS #229). Team camps by side; Royale by the hunter.
BattleFlow.TeamCamps = table.freeze({ "Red Camp", "Blue Camp", "Green Camp" })

function BattleFlow.campName(modeKey: string, side: number, ownerName: string?): string
	if modeKey == "TEAM" then
		return BattleFlow.TeamCamps[side] or `Camp {side}`
	end
	return `{ownerName or BattleFlow.standInName(side)}'s Camp`
end

function BattleFlow.outLine(camp: string): string
	return `{camp}'s Fence is down! They're out.`
end

function BattleFlow.tranqLine(name: string): string
	return `Tranqed by {name}!`
end

function BattleFlow.raidLine(name: string, camp: string, tower: string): string
	return `{name} trampled {camp}'s {tower}`
end

function BattleFlow.resultTitle(modeKey: string, place: number?): string?
	local mode = Modes.Modes[modeKey]
	if not mode or mode.sides == "one" or place ~= 1 then
		return nil
	end
	return `{mode.display} — {if modeKey == "TEAM" then "Your camp wins the hunt!" else "Top Hunter!"}`
end

function BattleFlow.standInName(side: number): string
	return `Stand-in {side}`
end

-- A size taken off a dino on `side`: a stand-in seat scores it as a Bone (PLAN T79b, #232).
-- Every dino on a side is only ever hurt by that side's own towers and hunters (#228,
-- #231), so a pop on a stand-in's track is its own towers' take-down. Battle-local tally:
-- never saved, paid or ranked. Returns whether it was credited (false = a real side; the
-- Scoreboard counts its hunters' Bones).
function BattleFlow.creditStandIn(bones: { [number]: number }, standIn: { [number]: boolean }, side: number): boolean
	if not standIn[side] then
		return false
	end
	bones[side] = (bones[side] or 0) + 1
	return true
end

function BattleFlow.standInOwnerId(side: number): number
	return -side
end

export type Seating<Id> = {
	sides: number,
	teams: { { Id } },
	sideOf: { [Id]: number },
	standIn: { [number]: boolean },
}

function BattleFlow.seat<Id>(modeKey: string, ids: { Id }, picked: number?, standIns: boolean?, competitive: boolean?): (Seating<Id>?, string?)
	local mode = Modes.Modes[modeKey]
	if not mode or mode.sides == "one" then
		return nil, "notBattle"
	end
	local players = #ids
	local sides: number
	if standIns then
		if players < 1 then
			return nil, "tooFew"
		elseif players > Config.Tuning.BattleMaxPlayers then
			return nil, "tooMany"
		end
		if mode.sides == "perPlayer" then
			sides = math.clamp(math.max(players, picked or 0), 2, Config.Tuning.BattleMaxPlayers)
		else
			sides = picked or Modes.TeamSides[1]
			if not table.find(Modes.TeamSides, sides) then
				return nil, "badSides"
			end
		end
	else
		local count, why = Modes.sideCount(modeKey, players, picked, competitive) -- Ranked minimums (T80)
		if not count then
			return nil, why
		end
		sides = count
	end
	local teams, sideOf = Matchmaking.assign(ids, sides)
	local standIn = {}
	for side = 1, sides do
		teams[side] = teams[side] or {}
		if #teams[side] == 0 then
			standIn[side] = true
		end
	end
	return { sides = sides, teams = teams, sideOf = sideOf, standIn = standIn }, nil
end

function BattleFlow.roundRow(round: number): (number, number, number)
	local repeats = BattleRules.overtimeRepeat(round)
	return math.min(round, #Config.Rounds), BattleRules.overtimeHpMult(repeats), repeats
end

-- The sides that cleared a round: still in, with Fence left. A side whose last leak broke
-- its Fence on the round's final dino didn't clear it (PLAYTEST F4), even before the
-- elimination check has marked it out: no round bonus, heal or hero XP for it.
function BattleFlow.clearedSides(sides: number, out: { [number]: boolean }, fenceOf: (number) -> number): { number }
	local list = {}
	for side = 1, sides do
		if not out[side] and not BattleRules.sideOut(fenceOf(side)) then
			table.insert(list, side)
		end
	end
	return list
end

-- Lockstep with a break (PLAN T79b, DECISIONS #232): once every living side has cleared
-- the round, the next waits Tuning BattleRoundBreak seconds so hunters can repair and
-- spend; BattleRoundTime after the round started still forces it (BattleRules.nextRoundDue).
-- `clearedAt`: when (in round time) every side was first seen cleared, nil until then.
-- Returns whether the next round is due, and the clearedAt to keep for the next check.
function BattleFlow.roundDue(sidesCleared: { [number]: boolean }, elapsed: number, clearedAt: number?): (boolean, number?)
	if elapsed >= Config.Tuning.BattleRoundTime then
		return true, clearedAt
	end
	if not BattleRules.nextRoundDue(sidesCleared, 0) then
		return false, nil -- not everyone has cleared (a side's dinos came back? start over)
	end
	local at = clearedAt or elapsed
	return elapsed - at >= Config.Tuning.BattleRoundBreak, at
end

function BattleFlow.hasOvertime(modeKey: string): boolean
	return modeKey == "TEAM"
end

export type Scale = { countMult: number, hpMult: number, promoteChance: number }

function BattleFlow.sideScale(difficulty: { countMult: number, hpMult: number, promoteChance: number }, hunters: number): Scale
	local extra = math.max(0, hunters - 1)
	return {
		countMult = difficulty.countMult * (1 + Config.Tuning.ExtraEnemiesPerPlayer * extra),
		hpMult = difficulty.hpMult * (1 + Config.Tuning.ExtraHPPerPlayer * extra),
		promoteChance = difficulty.promoteChance,
	}
end

function BattleFlow.startingCash(difficulty: { startingCash: number }, hunters: number): number
	return Pricing.startingPot(difficulty, math.max(1, hunters))
end

function BattleFlow.teamPlaces(eliminationOrder: { { number } }, result: BattleRules.TeamResult, sides: number): { [number]: number }
	local places: { [number]: number } = {}
	local won: { [number]: boolean } = {}
	for _, side in result.winners do
		places[side] = 1
		won[side] = true
	end
	local place = #result.winners + 1
	for step = #eliminationOrder, 1, -1 do
		local fell = 0
		for _, side in eliminationOrder[step] do
			if not won[side] and places[side] == nil then
				places[side] = place
				fell += 1
			end
		end
		place += fell
	end
	for side = 1, sides do
		if places[side] == nil then -- still standing when the match stopped (everyone left)
			places[side] = place
		end
	end
	return places
end

function BattleFlow.royalePlaces<Id>(ranking: { Id }): { [Id]: number }
	local places = {}
	for i, id in ranking do
		places[id] = i
	end
	return places
end

function BattleFlow.standInTowers(): { string }
	local keys = {}
	for _, key in Config.TowerOrder do
		local def = Config.Towers[key]
		if def and (def.unlockCost or 0) <= 0 and not def.untouchable and not def.onTrack and not ShopRules.Unreleased[key] then
			table.insert(keys, key)
		end
	end
	return keys
end

-- Visual layout only: how far beside the lane centre a stand-in tower is tried.
local SPOT_GAPS = { 9, 12, 15 }

function BattleFlow.standInSpots(layout: Sides.Layout, side: number, n: number): { Vector3 }
	local zone = Sides.zone(layout, side)
	local points = Sides.waypoints(layout, side)
	local spots: { Vector3 } = {}
	for i = 2, #points do
		if #spots >= n then
			break
		end
		local a, b = points[i - 1], points[i]
		local mid = (a + b) / 2
		local along = (b - a).Unit
		local across = Vector3.new(-along.Z, 0, along.X)
		for _, gap in SPOT_GAPS do
			local found = false
			for _, sign in { 1, -1 } do
				local spot = Placement.ground(mid + across * gap * sign)
				if Placement.check(spot, spots, false, zone) then
					table.insert(spots, spot)
					found = true
					break
				end
			end
			if found then
				break
			end
		end
	end
	return spots
end

return table.freeze(BattleFlow)
