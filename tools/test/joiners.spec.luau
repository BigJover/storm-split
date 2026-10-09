--[[
	Late joiners (PLAN Phase 8 batch 2 T105, DECISIONS #232, #254, #262): Shared/BattleFlow
	lateJoin (Ranked lock, casual cut-off), lateSeat (camp choice, Bone Rush spare plot),
	bonesFloor, sparePlots, the toast; SpawnQueue.setSeated (spare plots take no share of
	the live cap); and the server wiring that keeps joiners out of stakes and Ranked.
]]

local Config = require(src.shared.Config)
local BattleFlow = require(src.shared.BattleFlow)
local SpawnQueue = require(src.shared.SpawnQueue)
local Sides = require(src.shared.Sides)
local StudioOnly = require(src.shared.StudioOnly)

local T = Config.Tuning

local function camp(side: number, hunters: number, fence: number, bones: number?, isOut: boolean?): BattleFlow.LateCamp
	return { side = side, hunters = hunters, fence = fence, bones = bones or 0, out = isOut == true }
end

test("the seeds this spec means", function()
	eq(T.LateJoinLastRound, 30, "Late join last round (#254)")
	eq(T.BoneRushSparePlots, 2, "Bone Rush spare plots")
	eq(T.BattleMaxPlayers, 10, "Battle max players")
end)

test("lateJoin: Ranked never seats a joiner, from Building on (#254)", function()
	for _, modeKey in { "TEAM", "ROYALE" } do
		for _, round in { 0, 1, 2, 17, 30 } do
			local ok_, why = BattleFlow.lateJoin(modeKey, true, round)
			eq(ok_, false, `{modeKey} Ranked round {round}: refused`)
			eq(why, "ranked")
		end
	end
end)

test("lateJoin: casual open through Late join last round, closed after (#254)", function()
	for _, modeKey in { "TEAM", "ROYALE" } do
		eq(BattleFlow.lateJoin(modeKey, false, 0), true, `{modeKey}: during Building`)
		eq(BattleFlow.lateJoin(modeKey, false, 28), true, `{modeKey}: round 28`)
		eq(BattleFlow.lateJoin(modeKey, false, T.LateJoinLastRound), true, `{modeKey}: during round 30`)
		local ok_, why = BattleFlow.lateJoin(modeKey, false, T.LateJoinLastRound + 1)
		eq(ok_, false, `{modeKey}: round 31 closed`)
		eq(why, "closed")
		eq(BattleFlow.lateJoin(modeKey, false, 41), false, `{modeKey}: Final Stampede closed`)
	end
	eq(BattleFlow.lateJoin("COOP", false, 39), true, "co-op: drop-in stays, any round")
	eq(BattleFlow.lateJoin("COOP", true, 39), true, "co-op ignores the Ranked flag")
end)

test("lateSeat Camp Clash: fewest hunters, then lower Fence, then lower side", function()
	local seat = BattleFlow.lateSeat("TEAM", { camp(1, 2, 40), camp(2, 1, 40), camp(3, 2, 10) }, nil)
	eq(seat and seat.side, 2, "fewest hunters wins over lower Fence")
	eq(seat and seat.hunters, 1, "the side's hunters before the join (catch-up input)")
	eq(seat and seat.newPlot, false)
	seat = BattleFlow.lateSeat("TEAM", { camp(1, 2, 40), camp(2, 2, 25), camp(3, 2, 30) }, nil)
	eq(seat and seat.side, 2, "same hunters: lower Fence")
	seat = BattleFlow.lateSeat("TEAM", { camp(1, 2, 30), camp(2, 2, 30), camp(3, 3, 1) }, nil)
	eq(seat and seat.side, 1, "same hunters and Fence: lower side")
	seat = BattleFlow.lateSeat("TEAM", { camp(1, 3, 40), camp(2, 0, 0, 0, true), camp(3, 1, 40) }, nil)
	eq(seat and seat.side, 3, "a camp that fell is never picked, even with no hunters")
	seat = BattleFlow.lateSeat("TEAM", { camp(3, 1, 40), camp(1, 1, 40) }, 4)
	eq(seat and seat.side, 1, "order of the list doesn't matter; spare plots aren't Camp Clash's")
	local none, why = BattleFlow.lateSeat("TEAM", { camp(1, 1, 0, 0, true), camp(2, 1, 0, 0, true) }, nil)
	eq(none, nil)
	eq(why, "noCamp")
end)

test("lateSeat Bone Rush: the spare plot, Bones = the lowest still standing", function()
	local camps = { camp(1, 1, 30, 120), camp(2, 1, 0, 3, true), camp(3, 1, 12, 45), camp(4, 0, 40, 80) }
	local seat = BattleFlow.lateSeat("ROYALE", camps, 5)
	eq(seat and seat.side, 5, "the spare plot")
	eq(seat and seat.newPlot, true)
	eq(seat and seat.hunters, 0, "a plot of their own: the whole income (Pace.catchUpCash hunters 0)")
	eq(seat and seat.bones, 45, "lowest Bones among the standing (the fallen 3 doesn't count)")
	eq(BattleFlow.bonesFloor(camps), 45)
	eq(BattleFlow.bonesFloor({ camp(1, 1, 0, 7, true) }), 0, "nobody standing: 0")
	eq(BattleFlow.bonesFloor({}), 0)
	local none, why = BattleFlow.lateSeat("ROYALE", camps, nil)
	eq(none, nil, "no spare plot left")
	eq(why, "full")
	eq(BattleFlow.lateSeat("COOP", camps, 5), nil, "not a battle")
end)

test("sparePlots: casual Bone Rush only, within Battle max players", function()
	eq(BattleFlow.sparePlots("ROYALE", false, 4), 2)
	eq(BattleFlow.sparePlots("ROYALE", false, 8), 2)
	eq(BattleFlow.sparePlots("ROYALE", false, 9), 1, "9 seats + 1 = 10")
	eq(BattleFlow.sparePlots("ROYALE", false, 10), 0, "full lobby: none")
	eq(BattleFlow.sparePlots("ROYALE", true, 4), 0, "Ranked: none")
	eq(BattleFlow.sparePlots("TEAM", false, 2), 0, "Camp Clash: joiners go to a camp")
	for seats = 2, T.BattleMaxPlayers do
		ok(seats + BattleFlow.sparePlots("ROYALE", false, seats) <= T.BattleMaxPlayers, `{seats} seats stay within the map's 10`)
	end
end)

test("lateJoinLine: the toast names the camp, round and cash (T106 reviews the words)", function()
	eq(BattleFlow.lateJoinLine("TEAM", "Red Camp", 17, 1234.7, nil), "Joined Red Camp at round 17: +1234 cash to catch up")
	eq(BattleFlow.lateJoinLine("ROYALE", "Ann's Camp", 22, 900, 45), "Joined the hunt at round 22: +900 cash and 45 Bones to catch up")
end)

test("SpawnQueue.setSeated: spare plots take no share of the live cap until seated", function()
	local q = SpawnQueue.new(6)
	eq(q.seated, 6, "default: every side")
	SpawnQueue.setSeated(q, 4)
	for side = 1, 4 do
		for i = 1, 40 do
			SpawnQueue.push(q, side, i)
		end
	end
	local live = {}
	local total = 0
	while true do
		local item, side = SpawnQueue.take(q, total, live, 120)
		if not item then
			break
		end
		live[side :: number] = (live[side :: number] or 0) + 1
		total += 1
	end
	eq(live[1], Sides.sideCap(120, 4), "each seated side gets 120 / 4, not 120 / 6")
	eq(total, 120, "the whole cap used by the four seats")
	SpawnQueue.setSeated(q, 99)
	eq(q.seated, 6, "never more than the map's sides")
	SpawnQueue.setSeated(q, 0)
	eq(q.seated, 1, "at least one")
end)

test("server: joiners never staked or ranked; Ranked join refused; Studio late stand-in", function()
	local fs = require("@lune/fs")
	local battle = fs.readFile("src/server/Battle.luau")
	local main = fs.readFile("src/server/Main.server.luau")
	ok(battle:find("require(script.Parent.Progression)", 1, true) == nil, "Battle never calls Progression: a joiner gets no escrow")
	ok(battle:find("BattleFlow.lateJoin(modeKey, ctx.competitive, round)", 1, true) ~= nil, "seating asks the Ranked lock and cut-off")
	ok(battle:find("Pace.catchUpCash(Pace.joinRound(playing, round), seat.hunters, chosen, density)", 1, true) ~= nil, "catch-up cash on the seat")
	ok(battle:find("BattleFlow.sideScale(chosen, hunterCount(side))", 1, true) ~= nil, "the dino scale reads the hunters as each round starts")
	ok(main:find("Battle.lateJoin(player)", 1, true) ~= nil, "a player arriving mid-battle goes through lateJoin")
	-- Stakes are only ever taken before Battle.play, from the Ready hunters at Building.
	local stake = main:find("Progression.stake(player", 1, true)
	local play = main:find("Battle.play({", 1, true)
	ok(stake ~= nil and play ~= nil and stake < play, "stakes are taken before the battle starts, never for a joiner")
	local _, count = main:gsub("Progression%.stake%(", "")
	eq(count, 1, "one stake call in Main")
	eq(StudioOnly.allowed(true, "lateStandIn"), true, "Studio: Late stand-in joins now")
	eq(StudioOnly.allowed(false, "lateStandIn"), false, "refused on a live server")
end)
