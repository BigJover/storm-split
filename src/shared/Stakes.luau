--[[
	Competitive buy-ins, the pot and battle payouts (PLAN phase 7 T72, DECISIONS #215-#217).
	Pure, so specs run without a DataStore; Server/Progression (T80) is the only thing that
	moves Amber by what this says.

	  canStake(profileLoaded, published, amber, buyIn) -> (ok, reason?)
	      unpublished (Studio, everyone offline): ok, reason "practice" (session-only
	      Amber, same rules, no Trophies) if the session Amber covers the buy-in;
	      published but the save didn't load: no, "offline" (they may still play casual);
	      not enough Amber: no, "cantAfford"
	  escrow(matchId, amount)    the stake as written to the profile when Building starts
	  refund(escrow)             what a never-settled escrow gives back (BindToClose, or a
	                             later load that finds one): its amount; 0 if malformed
	  pot(stakes)                every stake taken; a leaver's stays in (forfeit)
	  teamSplit(pot, winners)    -> (share each, leftover): the pot split equally among the
	                             winning hunters still present, rounded down; a tie passes
	                             every tied side's present hunters. Nobody present: 0 each,
	                             the whole pot is left over
	  royaleSplit(pot, placements) -> (id -> share, leftover): 1st/2nd/3rd get Tuning
	                             RoyalePot1st/2nd/3rd % of the pot, each rounded down;
	                             with fewer than 3 finishers the unused % go to 1st.
	                             `placements` = the finishers' ids, 1st first
	  casualBattle(mode, placement, n) the casual payout: Team 1st (a winning or tied side)
	                             Tuning TeamWinPayout, any other place TeamLossPayout;
	                             Royale 1st/2nd/3rd/rest. 0 for co-op (Shared/Payouts) or a
	                             placement outside 1..n
	  settle(mode, placement, n, share, present) what a hunter is paid at the end: the
	                             casual payout plus their pot share (0 in casual); a leaver
	                             (not present) gets nothing and forfeits the stake
	  settleBattle(mode, n, hunters, ranked, practice) every seated hunter's payout, pot share
	                             and Trophies at a battle's end (T80; below)
	Leftover coins from rounding are a sink (DECISIONS #215).
]]

local Config = require(script.Parent.Config)
local Trophies = require(script.Parent.Trophies)

export type Escrow = { matchId: string, amount: number }

local Stakes = {}

function Stakes.canStake(profileLoaded: boolean, published: boolean, amber: number, buyIn: number): (boolean, string?)
	if published and not profileLoaded then
		return false, "offline"
	elseif amber < buyIn then
		return false, "cantAfford"
	elseif not published then
		return true, "practice"
	end
	return true, nil
end

function Stakes.escrow(matchId: string, amount: number): Escrow
	return { matchId = matchId, amount = amount }
end

function Stakes.refund(escrow: any): number
	if type(escrow) ~= "table" or type(escrow.amount) ~= "number" or escrow.amount ~= escrow.amount then
		return 0
	end
	return math.max(0, math.floor(escrow.amount))
end

function Stakes.pot(stakes: { number }): number
	local total = 0
	for _, amount in stakes do
		total += amount
	end
	return total
end

function Stakes.teamSplit<Id>(pot: number, winners: { Id }): (number, number)
	if #winners == 0 then
		return 0, pot
	end
	local share = pot // #winners
	return share, pot - share * #winners
end

local function potPercents(): { number }
	local t = Config.Tuning
	return { t.RoyalePot1st, t.RoyalePot2nd, t.RoyalePot3rd }
end

function Stakes.royaleSplit<Id>(pot: number, placements: { Id }): ({ [Id]: number }, number)
	local percents = potPercents()
	local shares: { [Id]: number } = {}
	if #placements == 0 then
		return shares, pot
	end
	local first = 0
	for place = #placements + 1, #percents do
		first += percents[place] -- unused shares go to 1st
	end
	local paid = 0
	for place = 1, math.min(#placements, #percents) do
		local percent = percents[place] + (if place == 1 then first else 0)
		local share = pot * percent // 100
		shares[placements[place]] = share
		paid += share
	end
	return shares, pot - paid
end

function Stakes.casualBattle(modeKey: string, placement: number, n: number): number
	if placement < 1 or placement > n then
		return 0
	end
	local t = Config.Tuning
	if modeKey == "TEAM" then
		return if placement == 1 then t.TeamWinPayout else t.TeamLossPayout
	elseif modeKey == "ROYALE" then
		if placement == 1 then
			return t.Royale1stPayout
		elseif placement == 2 then
			return t.Royale2ndPayout
		elseif placement == 3 then
			return t.Royale3rdPayout
		end
		return t.RoyaleRestPayout
	end
	return 0
end

function Stakes.settle(modeKey: string, placement: number, n: number, share: number, present: boolean): number
	if not present then
		return 0
	end
	return Stakes.casualBattle(modeKey, placement, n) + math.max(0, share)
end

-- One battle's settlement for every seated hunter (PLAN T80, DECISIONS #215-#217, #222).
--   hunters: { id, place, present, stake } — every real hunter seated at the start (stand-ins
--            and mid-battle joiners are never in it); `stake` = what they put in (0 casual);
--            `place` = their side's / seat's placement (1 = a winning or tied side)
--   n:       the match's sides (Camp Clash) or seats (Bone Rush), stand-ins included
--   ranked:  Ranked (competitive): pot shares and Trophies; casual: the casual payout only
--   practice: unpublished Ranked ("Practice Hunt"): stakes and pot as Ranked, Trophies 0
-- Returns (id -> { payout, share, trophies }, pot, leftover). The pot is every stake taken,
-- a leaver's included (forfeit). Camp Clash: split equally among the hunters present on a
-- 1st-place side. Bone Rush: the present hunters in placement order are the finishers
-- for royaleSplit. A leaver (not present) gets nothing and no Trophy change here.
--   standIns: Practice only (PLAN T86b, #236): each stand-in seat's placement. Stand-ins
--            hold their places in the split (a 1st-place stand-in side is a Camp Clash
--            winner; a Bone Rush stand-in takes its place's share) and their shares go to
--            the sink, so a last-place tester gets last place's share. Real matches
--            (not Practice) ignore it: real hunters only (#233).
export type Seat<Id> = { id: Id, place: number, present: boolean, stake: number }
export type Settlement = { payout: number, share: number, trophies: number }

function Stakes.settleBattle<Id>(modeKey: string, n: number, hunters: { Seat<Id> }, ranked: boolean, practice: boolean, standIns: { number }?): ({ [Id]: Settlement }, number, number)
	local stakes = {}
	-- Who holds a place in the split: the present hunters, plus the stand-ins in Practice.
	local split: { { key: any, place: number, real: boolean } } = {}
	for _, h in hunters do
		table.insert(stakes, if ranked then math.max(0, h.stake) else 0)
		if h.present then
			table.insert(split, { key = h.id, place = h.place, real = true })
		end
	end
	if practice and standIns then
		for i, place in standIns do
			table.insert(split, { key = { standIn = i }, place = place, real = false })
		end
	end
	local pot = Stakes.pot(stakes)
	local shares: { [Id]: number } = {}
	local leftover = pot
	if ranked and pot > 0 then
		local paid: { [any]: number } = {}
		if modeKey == "TEAM" then
			local winners = {}
			for _, e in split do
				if e.place == 1 then
					table.insert(winners, e.key)
				end
			end
			local each
			each, leftover = Stakes.teamSplit(pot, winners)
			for _, key in winners do
				paid[key] = each
			end
		else
			local order = table.clone(split)
			table.sort(order, function(a, b)
				if a.place ~= b.place then
					return a.place < b.place
				end
				return a.real and not b.real -- a fixed order (Bone Rush places are unique)
			end)
			local keys = {}
			for _, e in order do
				table.insert(keys, e.key)
			end
			paid, leftover = Stakes.royaleSplit(pot, keys)
		end
		for _, e in split do
			if e.real then
				shares[e.key] = paid[e.key]
			else
				leftover += paid[e.key] or 0 -- a stand-in's share: to the sink
			end
		end
	end
	local out: { [Id]: Settlement } = {}
	for _, h in hunters do
		local share = shares[h.id] or 0
		local trophies = 0
		if ranked and h.present then
			trophies = Trophies.delta(modeKey, h.place, n, practice)
		end
		out[h.id] = { payout = Stakes.settle(modeKey, h.place, n, share, h.present), share = if h.present then share else 0, trophies = trophies }
	end
	return out, pot, leftover
end

return table.freeze(Stakes)
