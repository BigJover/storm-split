--[[
	Battle: runs one Camp Clash (TEAM) or Bone Rush (ROYALE) match (PLAN phase 7 T77,
	DECISIONS #209-#214, #221, #231). Main calls play() instead of the co-op loop; co-op
	never comes here. The rules are pure and specced: Shared/BattleRules (lockstep, side
	out, results, overtime) and Shared/BattleFlow (seating, camp names, round rows, side
	scale, placements, stand-ins).

	  Seating   Shared/BattleFlow.seat: the host's mode, side count and (Studio only) the
	            "Fill with stand-ins" toggle. Each hunter gets a "Side" attribute; each side a
	            camp name (ReplicatedStorage "Camp", "Camp2", ... via Sides.attr).
	  Building  one build phase of Tuning BattleBuildTime seconds, no Start button.
	  Playing   rounds in lockstep: round N+1 starts on every living side once each has
	            cleared round N, or BattleRoundTime seconds after N started (left-over
	            dinos stay). Every living side gets the same seeded dinos (one Random seed
	            per round), scaled by its own hunter count, x Battle side density. When a
	            round ends each living side is paid its own round bonus and Supply Camp
	            income, and its hunters heal; each side's airdrops land on its own plot.
	  Out       a side is out at Fence 0 (or a Bone Rush hunter leaves): its towers come
	            off, its dinos despawn, its hunters spectate ("Out"/"Out2"... = true: they
	            walk, deal no damage, can't build). The feed says "<Camp>'s Fence is down!
	            They're out." Sides that fall on the same check fall together.
	  End       Camp Clash: last side standing; past the last round the Final Stampede
	            repeats it with more HP until one side falls (BattleRules.teamResult).
	            Bone Rush: at most one alive or the last round done; most Bones wins
	            (BattleRules.royaleResult, survivor bonus included).
	  Board     each side's Bones as "CampBones"/"CampBones2"... (the HUD's camps board),
	            and a Roblox Team per camp (its name and colour, BattleFlow.campColor), so
	            the player list (Tab) groups hunters by camp with each camp's Bones total.
	  Results   each hunter: "BattleSide", "BattlePlace", "BattleBones"; each side
	            "Place"/"Place2"...; ReplicatedStorage "BattleMode". State "Victory" ends
	            the match for everyone (the HUD reads BattlePlace for who won).

	Stand-ins (Studio only, #221): a side with no player has a track, Fence and dinos, and
	the fixed towers of BattleFlow.standInTowers (owner id negative), and scores the Bones
	those towers take (BattleFlow.creditStandIn, T79b). Never saved, paid or ranked: play()
	returns an Outcome of the real seated hunters only, and Main settles that through
	Progression.endBattle (payouts, stakes, Trophies, XP; T80). Battle itself never calls
	Progression.

	Every round prints the peak live enemies and the script cost, as co-op does.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local BattleFlow = require(Shared:WaitForChild("BattleFlow"))
local BattleLoop = require(Shared:WaitForChild("BattleLoop"))
local BattleRules = require(Shared:WaitForChild("BattleRules"))
local HeroXp = require(Shared:WaitForChild("HeroXp"))
local Modes = require(Shared:WaitForChild("Modes"))
local Pace = require(Shared:WaitForChild("Pace"))
local Sides = require(Shared:WaitForChild("Sides"))
local SmallPerks = require(Shared:WaitForChild("SmallPerks"))
local StudioOnly = require(Shared:WaitForChild("StudioOnly"))

local Airdrops = require(script.Parent.Airdrops)
local Economy = require(script.Parent.Economy)
local StandInHunters = require(script.Parent.StandInHunters)
local Enemies = require(script.Parent.Enemies)
local Health = require(script.Parent.Health)
local Hero = require(script.Parent.Hero)
local MapBuilder = require(script.Parent.MapBuilder)
local Scoreboard = require(script.Parent.Scoreboard)
local Shop = require(script.Parent.Shop)
local Towers = require(script.Parent.Towers)
local Waves = require(script.Parent.Waves)

local Battle = {}

local CHECK_EVERY = 0.25 -- seconds between flow checks (the co-op loop polls at the same rate)
local MAX_SIDES = 10 -- attributes cleared between matches (Bone Rush's most seats)

local feed: RemoteEvent? = nil
local active = false
local seatedSides = 0
local layout: Sides.Layout = Sides.new(1)
-- Studio stand-in seats and the Bones their own towers take (PLAN T79b): battle-local only.
local standInSeats: { [number]: boolean } = {}
local realCampIn = false -- a real hunter's camp is still in (Studio "Stand-ins hold" needs one, N7)
local standInBones: { [number]: number } = {}
local campTeams: { Team } = {} -- one per camp this match (the player list's groups)
-- Seats a late joiner in the match under way (T105); nil between matches. (player, host):
-- a real player, or (nil, host) for the Studio-only late stand-in.
local lateJoiner: ((Player?, Player?) -> (boolean, string?))? = nil

------------------------------------------------------------------ public helpers

function Battle.init(remotes: Folder)
	local event = Instance.new("RemoteEvent")
	event.Name = "Feed" -- (text): kill feed lines; to everyone, or one hunter's own notice
	event.Parent = remotes
	feed = event
end

-- A line for everyone's feed (a side out, a raid knock-out).
function Battle.announce(text: string)
	if feed then
		feed:FireAllClients(text)
	end
	print(`[DinoHunters] {text}`)
end

-- A line for one hunter only ("Tranqed by <name>!").
function Battle.tell(player: Player, text: string)
	if feed then
		feed:FireClient(player, text)
	end
end

function Battle.active(): boolean
	return active
end

-- A side's camp name, as published for this match.
function Battle.campOf(side: number): string
	local name = ReplicatedStorage:GetAttribute(Sides.attr("Camp", side))
	return if typeof(name) == "string" then name else BattleFlow.TeamCamps[1]
end

-- Where a battle hunter comes back: their own side's spawn (nil outside a battle).
function Battle.spawnPoint(player: Player): Vector3?
	if not active then
		return nil
	end
	return Sides.spawn(layout, Sides.sideOf(player:GetAttribute("Side"), layout.sides))
end

-- A size came off a dino on `side` (Main's Enemies onKilled): a stand-in seat's Bone.
function Battle.dinoPopped(side: number)
	if active then
		BattleFlow.creditStandIn(standInBones, standInSeats, side)
	end
end

-- Between matches: no battle attributes left behind (co-op reads "Out" for side 1).
-- The Fence a leak takes on `side` (PLAN T91b): Studio "Stand-ins hold" keeps a stand-in
-- camp at 1, so the Tester can reach round 40 and Final Stampede; real camps pay in full.
-- Once every real hunter's camp is out the hold lets go (PLAYTEST N7), so the match ends.
function Battle.leakCost(side: number, cost: number): number
	local hold = ReplicatedStorage:GetAttribute("StandInsHold")
	return StudioOnly.heldLoss(RunService:IsStudio(), hold, standInSeats[side] == true, Economy.livesOf(side), cost, realCampIn)
end

-- A player arrived mid-battle (Main's PlayerAdded) or the Studio host asked for a late
-- stand-in (player nil): seated by Shared/BattleFlow.lateJoin / lateSeat with catch-up cash
-- (Shared/Pace.catchUpCash), or refused with the reason ("ranked", "closed", "full",
-- "noCamp", "over"). Refused players wait on the home screen for the next hunt (#232).
-- Never staked or ranked: Battle never calls Progression, and Ranked never seats one.
function Battle.lateJoin(player: Player?, host: Player?): (boolean, string?)
	if not active or not lateJoiner then
		return false, "over"
	end
	return lateJoiner(player, host)
end

function Battle.reset()
	active = false
	lateJoiner = nil
	for side = 1, math.max(MAX_SIDES, seatedSides) do
		for _, name in { "Camp", "Out", "Place", "CampBones" } do
			ReplicatedStorage:SetAttribute(Sides.attr(name, side), nil)
		end
	end
	seatedSides = 0
	table.clear(standInSeats)
	table.clear(standInBones)
	realCampIn = false
	StandInHunters.clear()
	for _, player in Players:GetPlayers() do
		if player.Team and table.find(campTeams, player.Team) then
			player.Team = nil
			player.Neutral = true
		end
	end
	for _, team in campTeams do
		team:Destroy()
	end
	table.clear(campTeams)
	ReplicatedStorage:SetAttribute("BattleMode", nil)
	ReplicatedStorage:SetAttribute("Overtime", nil)
	ReplicatedStorage:SetAttribute("BuildEndsAt", nil)
	ReplicatedStorage:SetAttribute("MatchEndsAt", nil)
	ReplicatedStorage:SetAttribute("BattleDecidedBy", nil)
	ReplicatedStorage:SetAttribute("BattleAtClock", nil)
	for _, player in Players:GetPlayers() do
		for _, name in { "Side", "Out", "BattleSide", "BattlePlace", "BattleBones" } do
			player:SetAttribute(name, nil)
		end
	end
end

------------------------------------------------------------------ one match

export type Context = {
	map: MapBuilder.Map,
	difficulty: () -> any,
	spawn: (Player) -> (), -- Main: load the character if the match is on
	resetCost: () -> (), -- Main's per-round script cost counters
	costLine: () -> string,
	roster: { Player }?, -- who is seated (Ranked: the Ready hunters who staked); nil = everyone
	competitive: boolean?, -- Ranked: the competitive minimum players (Modes.minPlayers)
	onRoundStart: ((number, { Player }) -> ())?, -- a round began: the hunters still in it (bounties)
	startRound: number?, -- Studio "Start at round N" (Shared/StudioOnly already applied; nil = 1)
	matchId: string, -- every battle's id: the tie-break coin flip's seed (#261), Ranked's escrow
}

-- What Main settles at the end (Progression.endBattle, PLAN T80): every real hunter seated
-- at the start, their placement, and whether they're still here. Stand-ins are never in it.
export type Outcome = {
	mode: string,
	n: number,
	hunters: { { player: Player, place: number, present: boolean } },
	standIns: { number }, -- each stand-in seat's placement (Practice's Hoard split, T86b)
}

-- Runs a whole battle. Returns false if it couldn't start (the lobby stays), true when it
-- ended (results are up; Main waits ResultsTime and resets), with the Outcome to settle
-- (nil when everyone left before the end).
function Battle.play(ctx: Context): (boolean, Outcome?)
	local modeKey = ReplicatedStorage:GetAttribute("Mode")
	local chosen = ctx.difficulty()
	local roster = ctx.roster or Players:GetPlayers()
	local standIns = StudioOnly.allowed(RunService:IsStudio(), "standIns") and ReplicatedStorage:GetAttribute("StandIns") == true
	local picked = ReplicatedStorage:GetAttribute("BattleSides")
	local seating, why = BattleFlow.seat(modeKey, roster, if typeof(picked) == "number" then picked else nil, standIns, ctx.competitive)
	if not seating then
		warn(`[DinoHunters] Can't start {modeKey}: {why}`)
		return false
	end
	local sides = seating.sides -- grows when a late joiner takes a Bone Rush spare plot (T105)
	local display = Modes.Modes[modeKey].display

	-- The map: one copy of the track per side, plus a casual Bone Rush's spare plots (T105).
	layout = Sides.new(sides + BattleFlow.sparePlots(modeKey, ctx.competitive, sides), Sides.gridFor(modeKey))
	if MapBuilder.relayout(ctx.map, layout) then
		Enemies.setPaths(ctx.map.paths)
	end
	Enemies.setSeatedSides(sides)
	active = true
	seatedSides = layout.sides
	ReplicatedStorage:SetAttribute("BattleMode", modeKey)

	local function openCamp(side: number, ownerName: string?)
		local camp = BattleFlow.campName(modeKey, side, ownerName)
		ReplicatedStorage:SetAttribute(Sides.attr("Camp", side), camp)
		ReplicatedStorage:SetAttribute(Sides.attr("CampBones", side), 0)
		local team = Instance.new("Team")
		team.Name = camp
		team.TeamColor = BrickColor.new(BattleFlow.campColor(side) :: any)
		team.AutoAssignable = false
		team.Parent = Teams
		campTeams[side] = team
	end
	local function joinCamp(player: Player, side: number)
		player:SetAttribute("Side", side)
		player:SetAttribute("BattleSide", side)
		player.Neutral = false
		player.Team = campTeams[side]
	end
	for side = 1, sides do
		local first = seating.teams[side][1]
		openCamp(side, if first then first.DisplayName else nil)
		for _, player in seating.teams[side] do
			joinCamp(player, side)
		end
	end

	-- Economy: each side its own pot (scaled by its hunters) and Fence; spare plots get a
	-- full Fence and no cash until a late joiner takes one (T105).
	local pendingOut: { number } = {}
	Economy.initSides(layout.sides, 0, chosen.startingLives, function(side)
		table.insert(pendingOut, side)
	end)
	local function huntersOf(side: number): { Player }
		local list = {}
		for _, player in seating.teams[side] do
			if player.Parent then
				table.insert(list, player)
			end
		end
		return list
	end
	for side = 1, sides do
		Economy.earnFor(side, BattleFlow.startingCash(chosen, #seating.teams[side]))
	end

	-- Studio stand-ins: their fixed towers, and their Bones from them (T79b).
	local towerKeys = BattleFlow.standInTowers()
	local function seatStandIn(side: number)
		standInSeats[side] = true
		for i, spot in BattleFlow.standInSpots(layout, side, #towerKeys) do
			Shop.placeStandIn(towerKeys[i], spot, side, BattleFlow.standInOwnerId(side), BattleFlow.standInName(side))
		end
		-- And a stand-in hunter to shoot (T93, Studio only like every stand-in).
		StandInHunters.spawn(side, Sides.spawn(layout, side), Battle.campOf(side))
	end
	for side in seating.standIn do
		seatStandIn(side)
	end

	-- The match's standing (out sides, Bones), shared by the late joiners below and the rounds.
	local out: { [number]: boolean } = {}
	local outAt: { [number]: number } = {}
	local frozenBones: { [number]: number } = {}
	local bonesStart: { [number]: number } = {} -- a Bone Rush joiner's Bones floor (T105)
	local lateStandIns: { [number]: number } = {} -- Studio late stand-ins on a camp: hunters with no player
	local finished = false
	local round = 0
	local density = Sides.density(modeKey, sides) -- the seats at the start; spare plots don't change it
	-- The queue's first played round (#251); Studio "Start at round N" snaps to the next played one.
	local firstRound = Pace.firstRound(modeKey, ctx.competitive, ctx.startRound)

	local function living(): { number }
		local list = {}
		for side = 1, sides do
			if not out[side] then
				table.insert(list, side)
			end
		end
		return list
	end

	-- A side's hunters for its dino scale and income: its players still here, plus Studio
	-- late stand-ins (T105). A late joiner counts from the next round (Waves reads it as a
	-- round starts).
	local function hunterCount(side: number): number
		return #huntersOf(side) + (lateStandIns[side] or 0)
	end

	local function refreshRealCampIn()
		realCampIn = false
		for _, side in living() do
			if not seating.standIn[side] then
				realCampIn = true
			end
		end
	end
	refreshRealCampIn()

	local function sideBones(side: number): number
		if frozenBones[side] then
			return frozenBones[side]
		end
		local total = 0
		for _, player in huntersOf(side) do
			total += Scoreboard.bones(player)
		end
		-- a stand-in's towers' take-downs (T79b), and a Bone Rush joiner's floor (T105)
		return total + (standInBones[side] or 0) + (bonesStart[side] or 0)
	end

	-- Late joiners (T105, #254, #262): open in casual through Late join last round; Ranked
	-- never seats one. Camp Clash: the standing camp with the fewest hunters; Bone Rush: a
	-- spare plot with full Fence and the Bones floor. Catch-up cash on the seat; the dino
	-- scale grows from the next round. Never staked or ranked (Battle never calls
	-- Progression); a seated joiner is in the Outcome like anyone (casual payouts).
	lateJoiner = function(player: Player?, host: Player?): (boolean, string?)
		if finished then
			return false, "over"
		end
		local open, why = BattleFlow.lateJoin(modeKey, ctx.competitive, round)
		if not open then
			return false, why
		end
		local camps: { BattleFlow.LateCamp } = {}
		for side = 1, sides do
			table.insert(camps, { side = side, hunters = hunterCount(side), fence = Economy.livesOf(side), bones = sideBones(side), out = out[side] == true })
		end
		local seat, refused = BattleFlow.lateSeat(modeKey, camps, if sides < layout.sides then sides + 1 else nil)
		if not seat then
			return false, refused
		end
		local side = seat.side
		local playing = ReplicatedStorage:GetAttribute("State") == "Playing"
		local cash = Pace.catchUpCash(Pace.joinRound(playing, round), seat.hunters, chosen, density)
		if seat.newPlot then
			sides = side -- the next spare plot is now a seat
			Enemies.setSeatedSides(sides)
			seating.teams[side] = {}
			bonesStart[side] = seat.bones
			openCamp(side, if player then player.DisplayName else nil)
			if not player then
				seating.standIn[side] = true -- Studio: a stand-in seat, towers and all
				seatStandIn(side)
			end
		elseif not player then
			lateStandIns[side] = (lateStandIns[side] or 0) + 1
		end
		Economy.earnFor(side, cash)
		ReplicatedStorage:SetAttribute(Sides.attr("CampBones", side), sideBones(side))
		local line = BattleFlow.lateJoinLine(modeKey, Battle.campOf(side), if playing then round else firstRound, cash, seat.bones)
		if player then
			table.insert(seating.teams[side], player)
			seating.sideOf[player] = side
			joinCamp(player, side)
			ctx.spawn(player)
			Battle.tell(player, line)
		elseif host then
			Battle.tell(host, line) -- the Studio tester sees the stand-in's toast
		end
		refreshRealCampIn()
		print(`[DinoHunters] Late join ({if player then player.Name else "stand-in"}): {line}`)
		return true, nil
	end

	-- The match clock (T104, #252): from Building; casual 900 s, Ranked 1800 s (a Studio
	-- test clock may be shorter, Shared/StudioOnly). The HUD counts down to MatchEndsAt.
	local cap = StudioOnly.matchCap(RunService:IsStudio(), ReplicatedStorage:GetAttribute("StudioClockCap"), Pace.matchCap(modeKey, ctx.competitive))
	local clockStart = os.clock()
	if cap then
		ReplicatedStorage:SetAttribute("MatchEndsAt", workspace:GetServerTimeNow() + cap)
	end

	-- Building: one shared build phase.
	ReplicatedStorage:SetAttribute("State", "Building")
	ReplicatedStorage:SetAttribute("BuildEndsAt", workspace:GetServerTimeNow() + Config.Tuning.BattleBuildTime)
	for player in seating.sideOf do
		ctx.spawn(player)
	end
	local buildUntil = os.clock() + Config.Tuning.BattleBuildTime
	while os.clock() < buildUntil and #Players:GetPlayers() > 0 do
		task.wait(CHECK_EVERY)
	end
	if #Players:GetPlayers() == 0 then
		return true
	end

	-- Playing.
	ReplicatedStorage:SetAttribute("State", "Playing")
	ReplicatedStorage:SetAttribute("BuildEndsAt", nil)
	local level = HeroXp.roundLevel(firstRound - 1)
	ReplicatedStorage:SetAttribute("Level", level)
	ReplicatedStorage:SetAttribute("RoundsCleared", firstRound - 1)
	Hero.startMatch(firstRound - 1)
	Towers.setLevel(level, chosen)
	Enemies.setSpeedMult(chosen.speedMult)
	Enemies.resetDamage() -- the tie-break's damage dealt counts from round 1 (T104)
	local standInCount = 0
	for _ in seating.standIn do
		standInCount += 1
	end
	print(`[DinoHunters] {display} on {chosen.display}: {sides} sides, {#roster} player(s), {standInCount} stand-in(s)`)

	local elimination: { { number } } = {}
	local spawnedRound: { [number]: number } = {} -- side -> the last round whose spawning finished
	local matchSeed = math.random(1, 2 ^ 30)

	local function startRound(r: number)
		round = r
		local index, hpExtra, repeats = BattleFlow.roundRow(r)
		ReplicatedStorage:SetAttribute("Round", r)
		ReplicatedStorage:SetAttribute("Overtime", if repeats > 0 then repeats else nil)
		if repeats > 0 then
			print(`[DinoHunters] Final Stampede {repeats}: round {index} again, dino HP x{string.format("%.2f", hpExtra)}`)
		end
		ctx.resetCost()
		Enemies.resetPeak()
		Towers.newRound()
		if ctx.onRoundStart then
			local still = {}
			for _, side in living() do
				for _, hunter in huntersOf(side) do
					table.insert(still, hunter)
				end
			end
			ctx.onRoundStart(r, still) -- bounties' reachRound (T80): the seated hunters still in
		end
		for _, side in living() do
			Airdrops.drop(side) -- each side's chests on its own plot (#231)
			local scale = BattleFlow.sideScale(chosen, hunterCount(side))
			task.spawn(function()
				Waves.spawnRound({
					side = side,
					index = index,
					scale = scale,
					density = density,
					hpMult = hpExtra,
					speedMult = chosen.speedMult,
					crowd = Pace.crowd(modeKey), -- Battle crowd x (#258)
					random = Random.new(matchSeed + r), -- every side rolls the same promotions
					isOver = function()
						return finished or out[side] == true
					end,
				})
				spawnedRound[side] = math.max(spawnedRound[side] or 0, r)
			end)
		end
	end

	-- A round is over for everyone: each living side gets its round pay and heals.
	local function endRound(r: number)
		local index = math.min(r, #Config.Rounds)
		local clearedBy: { [Player]: boolean } = {}
		-- Only sides still in with Fence left cleared it (PLAYTEST F4).
		for _, side in BattleFlow.clearedSides(sides, out, Economy.livesOf) do
			Economy.earnFor(side, (Config.Tuning.RoundBonusBase + Config.Tuning.RoundBonusPerRound * index) * chosen.cashMult)
			Economy.earnFor(side, Towers.roundIncome(Economy.cashOf(side), side) * chosen.cashMult) -- its Supply Camps
			for _, hunter in huntersOf(side) do
				Health.heal(hunter, Config.Tuning.HealPerRound + SmallPerks.ofPlayer(hunter).healPerRound)
				clearedBy[hunter] = true
			end
		end
		ReplicatedStorage:SetAttribute("RoundsCleared", index)
		Hero.roundCleared(index, false, clearedBy)
		local newLevel = HeroXp.roundLevel(index)
		if newLevel > level then
			level = newLevel
			Towers.setLevel(level, chosen)
			ReplicatedStorage:SetAttribute("Level", level)
		end
		local fences = {}
		for side = 1, sides do
			table.insert(fences, if out[side] then "out" else tostring(Economy.livesOf(side)))
		end
		print(string.format(
			"[DinoHunters] Round %d over | %s, %d sides (%d alive) | Fences %s | peak enemies %d/%d | %s",
			r,
			display,
			sides,
			#living(),
			table.concat(fences, " / "),
			Enemies.peak(),
			Config.Tuning.MaxConcurrentEnemies,
			ctx.costLine()
		))
	end

	-- Sides that fell since the last check fall together (one elimination step).
	local function eliminate(fallen: { number })
		local step = {}
		for _, side in fallen do
			if not out[side] then
				out[side] = true
				table.insert(step, side)
			end
		end
		if #step == 0 then
			return
		end
		table.sort(step)
		table.insert(elimination, step)
		for _, side in step do
			outAt[side] = #elimination
			frozenBones[side] = sideBones(side) -- an out side's Bones freeze (#214)
			ReplicatedStorage:SetAttribute(Sides.attr("Out", side), true)
			Towers.removeSide(side)
			Enemies.clearSide(side)
			StandInHunters.remove(side)
			for _, player in huntersOf(side) do
				player:SetAttribute("Out", true) -- spectating: walk, no damage, no building
			end
			Battle.announce(BattleFlow.outLine(Battle.campOf(side)))
		end
		refreshRealCampIn()
	end

	-- The tie-break chain's inputs (#253, T104): Fence, damage dealt to its own dinos (capped
	-- per dino, Enemies.damageDealt), total round-clear seconds (BattleLoop), the matchId seed.
	local clearTime: { [number]: number } = {}
	local atClock = false
	local function standings()
		local bones, fence, damage, clear = {}, {}, {}, {}
		for side = 1, sides do
			bones[side] = sideBones(side)
			fence[side] = Economy.livesOf(side)
			damage[side] = Enemies.damageDealt(side)
			clear[side] = clearTime[side] or 0
		end
		local seats = {}
		for side = 1, sides do
			table.insert(seats, { id = side, bones = bones[side], fence = fence[side], outAt = outAt[side], damage = damage[side], clearTime = clear[side] })
		end
		return bones, fence, damage, clear, seats
	end

	-- Is the match over? Returns the result once it is.
	local function verdict(roundsDone: boolean): any?
		local bones, fence, damage, clear, seats = standings()
		if modeKey == "TEAM" then
			local result = BattleRules.teamResult(elimination, bones, { fence = fence, damage = damage, clearTime = clear, seed = ctx.matchId })
			return if result.over then result else nil
		end
		local result = BattleRules.royaleResult(seats, roundsDone, ctx.matchId)
		return if result.over then result else nil
	end

	-- The clock ran out (#252): over at once, everyone standing ranked by the chain.
	local function clockEnd(): any
		atClock = true
		local bones, fence, damage, clear, seats = standings()
		if modeKey == "TEAM" then
			return BattleRules.atClock({ modeKey = "TEAM", eliminationOrder = elimination, bones = bones, fence = fence, damage = damage, clearTime = clear, seed = ctx.matchId })
		end
		return BattleRules.atClock({ modeKey = "ROYALE", players = seats, seed = ctx.matchId })
	end

	-- The skipped rounds' expected income, to each living side as a played round starts (#251).
	local function paySkipped(from: number, to: number)
		for _, side in living() do
			local hunters = huntersOf(side)
			local amount = Pace.skippedIncome(from, to, hunterCount(side), chosen, density)
			Economy.earnFor(side, amount)
			for _, hunter in hunters do
				Battle.tell(hunter, BattleFlow.suppliesLine(amount, from, to))
			end
		end
	end

	local empty = {} -- the result when everyone left
	local result: any
	result, round = BattleLoop.run({
		modeKey = modeKey,
		competitive = ctx.competitive,
		first = firstRound,
		poll = CHECK_EVERY,
		now = os.clock,
		wait = function(seconds)
			task.wait(seconds)
		end,
		tick = function()
			if #Players:GetPlayers() == 0 then
				return empty
			end
			-- A Bone Rush hunter who leaves is out (PLAN T77); a Camp Clash leaver's towers stay.
			if modeKey == "ROYALE" then
				for side = 1, sides do
					if not out[side] and not seating.standIn[side] and #huntersOf(side) == 0 then
						table.insert(pendingOut, side)
					end
				end
			end
			for side = 1, sides do -- the camps board (only a change replicates)
				ReplicatedStorage:SetAttribute(Sides.attr("CampBones", side), sideBones(side))
			end
			if #pendingOut > 0 then
				local fallen = pendingOut
				pendingOut = {}
				eliminate(fallen)
			end
			return verdict(false)
		end,
		cleared = function(r)
			local cleared = {}
			for _, side in living() do
				cleared[side] = (spawnedRound[side] or 0) >= r and Enemies.remaining(side) == 0
			end
			return cleared
		end,
		startRound = startRound,
		endRound = endRound,
		paySkipped = paySkipped,
		finish = function()
			return verdict(true)
		end,
		cap = cap,
		clockStart = clockStart,
		atClock = clockEnd,
		clearTime = clearTime,
	})
	finished = true
	if result == empty then
		return true
	end

	-- Results.
	local places: { [number]: number }
	local finalBones: { [number]: number } = {}
	if modeKey == "TEAM" then
		places = BattleFlow.teamPlaces(elimination, result, sides)
		for side = 1, sides do
			finalBones[side] = sideBones(side)
		end
	else
		places = BattleFlow.royalePlaces(result.ranking)
		finalBones = result.bones
	end
	local lines: { string } = {}
	local order = {}
	for side = 1, sides do
		table.insert(order, side)
	end
	table.sort(order, function(a, b)
		return if places[a] ~= places[b] then places[a] < places[b] else a < b
	end)
	for side = 1, sides do
		ReplicatedStorage:SetAttribute(Sides.attr("Place", side), places[side])
		ReplicatedStorage:SetAttribute(Sides.attr("CampBones", side), finalBones[side]) -- the results' placements
		for _, player in huntersOf(side) do
			player:SetAttribute("BattlePlace", places[side])
			-- Camp Clash: the hunter's own Bones; Bone Rush: the seat's final (survivor bonus in).
			player:SetAttribute("BattleBones", if modeKey == "TEAM" then Scoreboard.bones(player) else finalBones[side])
		end
	end
	for _, side in order do
		table.insert(lines, `{places[side]}. {Battle.campOf(side)} ({finalBones[side]} Bones)`)
	end
	ReplicatedStorage:SetAttribute("MatchEndsAt", nil)
	ReplicatedStorage:SetAttribute("BattleDecidedBy", result.decidedBy) -- the results' "Decided by" line (T104)
	ReplicatedStorage:SetAttribute("BattleAtClock", if atClock then true else nil)
	ReplicatedStorage:SetAttribute("State", "Victory")
	print(`[DinoHunters] {display} over on round {round}{if atClock then " at the clock" else ""}, decided by {result.decidedBy or "-"}: {table.concat(lines, " | ")}`)
	-- Every real hunter seated at the start, leavers included (they forfeit); never a
	-- stand-in (no player) or a mid-battle joiner (never seated).
	local outcome: Outcome = { mode = modeKey, n = sides, hunters = {}, standIns = {} }
	for side = 1, sides do
		if seating.standIn[side] then
			table.insert(outcome.standIns, places[side])
		end
		for _, player in seating.teams[side] do
			table.insert(outcome.hunters, { player = player, place = places[side], present = player.Parent ~= nil })
		end
	end
	return true, outcome
end

return Battle
