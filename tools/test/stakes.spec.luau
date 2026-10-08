--[[
	Competitive stakes, pots, battle payouts (Shared/Stakes) and ranked Trophies
	(Shared/Trophies): PLAN phase 7 T72, DECISIONS #215-#218.
]]

local Config = require(src.shared.Config)
local Stakes = require(src.shared.Stakes)
local Trophies = require(src.shared.Trophies)

local T = Config.Tuning
local BUY = T.CompetitiveBuyIn

test("the seeds this spec means", function()
	eq(BUY, 15, "buy-in")
	eq(T.RoyalePot1st, 72)
	eq(T.RoyalePot2nd, 23)
	eq(T.RoyalePot3rd, 5)
	eq(T.TeamWinPayout, 50)
	eq(T.TeamLossPayout, 5)
	eq(T.Royale1stPayout, 60)
	eq(T.Royale2ndPayout, 30)
	eq(T.Royale3rdPayout, 10)
	eq(T.RoyaleRestPayout, 5)
	eq(T.TeamWinTrophies, 30)
	eq(T.TeamLossTrophies, -30)
	eq(T.Royale1stTrophies, 30)
	eq(T.RoyaleLastTrophies, -20)
	local floors = { 0, 300, 600, 1000, 1500, 2000, 3000, 4000 }
	eq(#Config.Arenas, #floors, "arenas")
	for i, f in floors do
		eq(Config.Arenas[i].floor, f, `arena {i} floor`)
	end
end)

-- canStake --------------------------------------------------------------------

test("a loaded, published profile with the Amber can stake", function()
	local okay, why = Stakes.canStake(true, true, 100, BUY)
	eq(okay, true)
	eq(why, nil)
	okay = Stakes.canStake(true, true, BUY, BUY)
	eq(okay, true, "exactly the buy-in")
end)

test("offline (save didn't load) is refused", function()
	local okay, why = Stakes.canStake(false, true, 1000, BUY)
	eq(okay, false)
	eq(why, "offline")
end)

test("can't afford is refused", function()
	local okay, why = Stakes.canStake(true, true, BUY - 1, BUY)
	eq(okay, false)
	eq(why, "cantAfford")
	okay, why = Stakes.canStake(false, false, BUY - 1, BUY)
	eq(why, "cantAfford", "Practice too: same rules")
end)

test("unpublished runs as Practice, loaded or not", function()
	local okay, why = Stakes.canStake(false, false, 100, BUY)
	eq(okay, true)
	eq(why, "practice")
	okay, why = Stakes.canStake(true, false, 100, BUY)
	eq(okay, true)
	eq(why, "practice")
end)

-- escrow, refund, pot ---------------------------------------------------------

test("escrow and refund", function()
	local e = Stakes.escrow("match-7", BUY)
	eq(e.matchId, "match-7")
	eq(e.amount, 15)
	eq(Stakes.refund(e), 15, "refund gives the stake back")
	eq(Stakes.refund(nil), 0, "no escrow")
	eq(Stakes.refund({ matchId = "x" }), 0, "malformed")
	eq(Stakes.refund({ matchId = "x", amount = -3 }), 0, "negative")
	eq(Stakes.refund({ matchId = "x", amount = 0 / 0 }), 0, "NaN")
end)

test("the pot is every stake; a leaver's stays in", function()
	eq(Stakes.pot({ 15, 15, 15, 15 }), 60)
	eq(Stakes.pot({}), 0)
end)

-- team split ------------------------------------------------------------------

test("pot 4 x 15 -> 2 winners get 30 each", function()
	local share, left = Stakes.teamSplit(Stakes.pot({ 15, 15, 15, 15 }), { "a", "b" })
	eq(share, 30)
	eq(left, 0)
end)

test("team shares round down; leftover is a sink", function()
	local share, left = Stakes.teamSplit(Stakes.pot({ 15, 15, 15, 15, 15 }), { "a", "b" })
	eq(share, 37, "75 / 2")
	eq(left, 1)
	share, left = Stakes.teamSplit(100, { "a", "b", "c" })
	eq(share, 33)
	eq(left, 1)
end)

test("a winner who left isn't counted; nobody present = whole pot left over", function()
	-- 2v2, one winner left: the one still present takes the side's pot
	local share = Stakes.teamSplit(60, { "a" })
	eq(share, 60)
	local none, left = Stakes.teamSplit(60, {})
	eq(none, 0)
	eq(left, 60)
end)

-- royale split ----------------------------------------------------------------

test("Royale 3 x 15 = 45 -> 32 / 10 / 2 (floors)", function()
	local shares, left = Stakes.royaleSplit(Stakes.pot({ 15, 15, 15 }), { "a", "b", "c" })
	eq(shares.a, 32)
	eq(shares.b, 10)
	eq(shares.c, 2)
	eq(left, 1)
end)

test("Royale: 4th and below get no share", function()
	local shares, left = Stakes.royaleSplit(150, { "a", "b", "c", "d", "e" })
	eq(shares.a, 108)
	eq(shares.b, 34, "34.5 -> 34")
	eq(shares.c, 7, "7.5 -> 7")
	eq(shares.d, nil)
	eq(shares.e, nil)
	eq(left, 1)
end)

test("Royale: 2 finishers -> the unused 3rd share goes to 1st", function()
	local shares, left = Stakes.royaleSplit(45, { "a", "b" })
	eq(shares.a, 34, "77% of 45 = 34.65")
	eq(shares.b, 10)
	eq(left, 1)
end)

test("Royale: 1 finisher takes 100%", function()
	local shares, left = Stakes.royaleSplit(45, { "a" })
	eq(shares.a, 45)
	eq(left, 0)
	local none, all = Stakes.royaleSplit(45, {})
	eq(next(none), nil)
	eq(all, 45)
end)

-- casual + settle ----------------------------------------------------------------

test("casual battle payouts", function()
	eq(Stakes.casualBattle("TEAM", 1, 2), 50, "team win")
	eq(Stakes.casualBattle("TEAM", 2, 2), 5, "team loss")
	eq(Stakes.casualBattle("TEAM", 3, 3), 5, "3rd side")
	eq(Stakes.casualBattle("ROYALE", 1, 10), 60)
	eq(Stakes.casualBattle("ROYALE", 2, 10), 30)
	eq(Stakes.casualBattle("ROYALE", 3, 10), 10)
	eq(Stakes.casualBattle("ROYALE", 4, 10), 5)
	eq(Stakes.casualBattle("ROYALE", 10, 10), 5)
	eq(Stakes.casualBattle("ROYALE", 11, 10), 0, "outside the lobby")
	eq(Stakes.casualBattle("COOP", 1, 4), 0, "co-op pays through Payouts")
end)

test("settle = casual + share; a leaver gets nothing", function()
	eq(Stakes.settle("TEAM", 1, 4, 30, true), 80)
	eq(Stakes.settle("TEAM", 2, 4, 0, true), 5)
	eq(Stakes.settle("ROYALE", 1, 3, 32, true), 92)
	eq(Stakes.settle("ROYALE", 1, 3, 32, false), 0, "leaver forfeits")
	eq(Stakes.settle("TEAM", 1, 2, 0, true), 50, "casual: no share")
end)

test("a leaver forfeits: their stake stays in the pot for the rest", function()
	-- 2v2, a loser leaves: pot is still 60, the 2 winners split it
	local pot = Stakes.pot({ 15, 15, 15, 15 })
	local share = Stakes.teamSplit(pot, { "w1", "w2" })
	eq(share, 30)
	eq(Stakes.settle("TEAM", 2, 4, 0, false), 0, "the leaver")
end)

test("competitive winner > casual winner at the minimum lobby (net of the stake too)", function()
	-- Team 1v1
	local teamPot = Stakes.pot({ BUY, BUY })
	local teamShare = Stakes.teamSplit(teamPot, { "a" })
	local teamComp = Stakes.settle("TEAM", 1, T.TeamMinPlayers, teamShare, true)
	local teamCasual = Stakes.settle("TEAM", 1, T.TeamMinPlayers, 0, true)
	ok(teamComp > teamCasual, `team {teamComp} > {teamCasual}`)
	ok(teamComp - BUY > teamCasual, "team net")
	-- Royale 3
	local stakes = {}
	for i = 1, T.RoyaleMinPlayers do
		stakes[i] = BUY
	end
	local shares = Stakes.royaleSplit(Stakes.pot(stakes), { "a", "b", "c" })
	local royaleComp = Stakes.settle("ROYALE", 1, T.RoyaleMinPlayers, shares.a, true)
	local royaleCasual = Stakes.settle("ROYALE", 1, T.RoyaleMinPlayers, 0, true)
	ok(royaleComp > royaleCasual, `royale {royaleComp} > {royaleCasual}`)
	ok(royaleComp - BUY > royaleCasual, "royale net")
end)

-- Trophies ------------------------------------------------------------------------

test("Team: +30 / -30", function()
	eq(Trophies.delta("TEAM", 1, 4), 30)
	eq(Trophies.delta("TEAM", 2, 4), -30)
	eq(Trophies.delta("TEAM", 3, 6), -30)
end)

test("Practice and co-op don't change Trophies", function()
	eq(Trophies.delta("TEAM", 1, 4, true), 0)
	eq(Trophies.delta("ROYALE", 1, 5, true), 0)
	eq(Trophies.delta("COOP", 1, 4), 0)
	eq(Trophies.delta("TEAM", 0, 4), 0, "no placement")
end)

test("Royale 3: +30 / 0 / -20", function()
	eq(Trophies.delta("ROYALE", 1, 3), 30)
	eq(Trophies.delta("ROYALE", 2, 3), 0)
	eq(Trophies.delta("ROYALE", 3, 3), -20)
end)

test("Royale 10: top third gains, middle 0, bottom third loses", function()
	local want = { 30, 20, 10, 0, 0, 0, 0, -7, -13, -20 }
	for place, d in want do
		eq(Trophies.delta("ROYALE", place, 10), d, `place {place}`)
	end
end)

test("Royale: the shape holds for every lobby size", function()
	for n = 3, 10 do
		local third = n // 3
		eq(Trophies.delta("ROYALE", 1, n), 30, `1st of {n}`)
		eq(Trophies.delta("ROYALE", n, n), -20, `last of {n}`)
		local prev = math.huge
		for place = 1, n do
			local d = Trophies.delta("ROYALE", place, n)
			ok(d <= prev, `never more for a worse place ({place} of {n})`)
			prev = d
			if place > third and place <= n - third then
				eq(d, 0, `middle {place} of {n}`)
			end
		end
	end
end)

test("arenaOf", function()
	eq(Trophies.arenaOf(0), 1)
	eq(Trophies.arenaOf(299), 1)
	eq(Trophies.arenaOf(300), 2)
	eq(Trophies.arenaOf(3999), 7)
	eq(Trophies.arenaOf(4000), 8)
	eq(Trophies.arenaOf(99999), 8)
end)

test("no negative Trophies", function()
	eq(Trophies.apply(0, -30), 0)
	eq(Trophies.apply(10, -20), 0)
	eq(Trophies.apply(50, -30), 20)
end)

test("the arena floor holds a loss", function()
	eq(Trophies.apply(300, -30), 300, "just reached arena 2")
	eq(Trophies.apply(310, -30), 300, "310 - 30 stops at the floor")
	eq(Trophies.apply(4000, -20), 4000)
	eq(Trophies.apply(330, -30), 300)
	eq(Trophies.apply(400, -30), 370, "above the floor: the full loss")
	eq(Trophies.apply(290, 30), 320, "gains are never capped")
end)

test("newArenas: first-time arenas going up; none going down", function()
	local reached = Trophies.newArenas(290, 320)
	eq(#reached, 1)
	eq(reached[1], 2)
	reached = Trophies.newArenas(0, 1000)
	eq(#reached, 3)
	eq(reached[1], 2)
	eq(reached[3], 4)
	eq(#Trophies.newArenas(320, 340), 0)
	eq(#Trophies.newArenas(300, 300), 0)
end)

test("custom arena lists work (lowest first, floor 0)", function()
	local list = {
		{ key = "A", display = "A", floor = 0, reward = "" },
		{ key = "B", display = "B", floor = 100, reward = "" },
	}
	eq(Trophies.arenaOf(150, list), 2)
	eq(Trophies.apply(110, -30, list), 100)
	eq(#Trophies.newArenas(90, 110, list), 1)
end)

-- T80: one battle's settlement (Stakes.settleBattle) --------------------------------

local function seat(id: string, place: number, present: boolean?, stake: number?)
	return { id = id, place = place, present = present ~= false, stake = stake or BUY }
end

test("T80 Ranked Camp Clash 2v2: pot 60 -> winners 30 + casual 50 = 80; losers 5; Trophies +/-30", function()
	local out, pot, left = Stakes.settleBattle("TEAM", 2, { seat("a", 1), seat("b", 1), seat("c", 2), seat("d", 2) }, true, false)
	eq(pot, 60)
	eq(left, 0)
	eq(out.a.payout, 80)
	eq(out.a.share, 30)
	eq(out.a.trophies, 30)
	eq(out.c.payout, 5)
	eq(out.c.share, 0)
	eq(out.c.trophies, -30)
end)

test("T80 a leaver forfeits: stake in the pot, nothing paid, no Trophy change here", function()
	local out, pot = Stakes.settleBattle("TEAM", 2, { seat("a", 1), seat("b", 1, false), seat("c", 2) }, true, false)
	eq(pot, 45, "the leaver's stake stays in")
	eq(out.a.share, 45, "the one winner still here takes the pot")
	eq(out.b.payout, 0)
	eq(out.b.share, 0)
	eq(out.b.trophies, 0)
end)

test("T80 Ranked Bone Rush 3: 32 / 10 / 2 on top of 60 / 30 / 10; leavers aren't finishers", function()
	local out, pot, left = Stakes.settleBattle("ROYALE", 3, { seat("x", 3), seat("y", 1), seat("z", 2) }, true, false)
	eq(pot, 45)
	eq(out.y.payout, 60 + 32)
	eq(out.z.payout, 30 + 10)
	eq(out.x.payout, 10 + 2)
	eq(left, 1)
	local gone = Stakes.settleBattle("ROYALE", 3, { seat("x", 1, false), seat("y", 2), seat("z", 3) }, true, false)
	eq(gone.x.payout, 0, "1st left: gets nothing")
	eq(gone.y.share, 45 * (72 + 5) // 100, "y is the 1st finisher, with the unused 3rd share")
	eq(gone.z.share, 45 * 23 // 100)
end)

test("T80 Practice: the same pot and payouts, Trophies 0", function()
	local out = Stakes.settleBattle("TEAM", 2, { seat("a", 1), seat("b", 2) }, true, true)
	eq(out.a.payout, 50 + 30)
	eq(out.a.trophies, 0)
	eq(out.b.trophies, 0)
end)

test("T80 Casual: casual payout only, no pot, no Trophies (stakes ignored)", function()
	local out, pot = Stakes.settleBattle("ROYALE", 4, { seat("a", 1), seat("b", 4) }, false, false)
	eq(pot, 0)
	eq(out.a.payout, 60)
	eq(out.a.trophies, 0)
	eq(out.b.payout, 5)
end)

test("T80 a solo Practice against stand-ins: the stake comes back by the split", function()
	-- Camp Clash, 1 hunter + 1 stand-in side: the hunter is the only staker.
	local win = Stakes.settleBattle("TEAM", 2, { seat("me", 1) }, true, true)
	eq(win.me.payout, 50 + BUY, "win: casual + the whole pot")
	local loss = Stakes.settleBattle("TEAM", 2, { seat("me", 2) }, true, true)
	eq(loss.me.payout, 5, "loss: the stake stays in the pot (a sink)")
end)
