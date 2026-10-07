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
	  Results   each hunter: "BattleSide", "BattlePlace", "BattleBones"; each side
	            "Place"/"Place2"...; ReplicatedStorage "BattleMode". State "Victory" ends
	            the match for everyone (the HUD reads BattlePlace for who won).

	Stand-ins (Studio only, #221): a side with no player has a track, Fence and dinos, and
	the fixed towers of BattleFlow.standInTowers (owner id negative). Never saved, paid or
	ranked: battles don't call Progression at all yet (stakes, payouts, Trophies and XP
	are T80).

	Every round prints the peak live enemies and the script cost, as co-op does.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local BattleFlow = require(Shared:WaitForChild("BattleFlow"))
local BattleRules = require(Shared:WaitForChild("BattleRules"))
local HeroXp = require(Shared:WaitForChild("HeroXp"))
local Modes = require(Shared:WaitForChild("Modes"))
local Sides = require(Shared:WaitForChild("Sides"))
local SmallPerks = require(Shared:WaitForChild("SmallPerks"))

local Airdrops = require(script.Parent.Airdrops)
local Economy = require(script.Parent.Economy)
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

-- Between matches: no battle attributes left behind (co-op reads "Out" for side 1).
function Battle.reset()
	active = false
	for side = 1, math.max(MAX_SIDES, seatedSides) do
		for _, name in { "Camp", "Out", "Place" } do
			ReplicatedStorage:SetAttribute(Sides.attr(name, side), nil)
		end
	end
	seatedSides = 0
	ReplicatedStorage:SetAttribute("BattleMode", nil)
	ReplicatedStorage:SetAttribute("Overtime", nil)
	ReplicatedStorage:SetAttribute("BuildEndsAt", nil)
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
}

-- Runs a whole battle. Returns false if it couldn't start (the lobby stays), true when it
-- ended (results are up; Main waits ResultsTime and resets).
function Battle.play(ctx: Context): boolean
	local modeKey = ReplicatedStorage:GetAttribute("Mode")
	local chosen = ctx.difficulty()
	local roster = Players:GetPlayers()
	local standIns = RunService:IsStudio() and ReplicatedStorage:GetAttribute("StandIns") == true
	local picked = ReplicatedStorage:GetAttribute("BattleSides")
	local seating, why = BattleFlow.seat(modeKey, roster, if typeof(picked) == "number" then picked else nil, standIns)
	if not seating then
		warn(`[DinoHunters] Can't start {modeKey}: {why}`)
		return false
	end
	local sides = seating.sides
	local display = Modes.Modes[modeKey].display

	-- The map: one copy of the track per side.
	layout = Sides.new(sides, Sides.gridFor(modeKey))
	if MapBuilder.relayout(ctx.map, layout) then
		Enemies.setPaths(ctx.map.paths)
	end
	active = true
	seatedSides = sides
	ReplicatedStorage:SetAttribute("BattleMode", modeKey)

	for player, side in seating.sideOf do
		player:SetAttribute("Side", side)
		player:SetAttribute("BattleSide", side)
	end
	for side = 1, sides do
		local first = seating.teams[side][1]
		local camp = BattleFlow.campName(modeKey, side, if first then first.DisplayName else nil)
		ReplicatedStorage:SetAttribute(Sides.attr("Camp", side), camp)
	end

	-- Economy: each side its own pot (scaled by its hunters) and Fence.
	local pendingOut: { number } = {}
	Economy.initSides(sides, 0, chosen.startingLives, function(side)
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

	-- Studio stand-ins: their fixed towers.
	local towerKeys = BattleFlow.standInTowers()
	for side in seating.standIn do
		for i, spot in BattleFlow.standInSpots(layout, side, #towerKeys) do
			Shop.placeStandIn(towerKeys[i], spot, side, BattleFlow.standInOwnerId(side), BattleFlow.standInName(side))
		end
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
	local level = HeroXp.roundLevel(0)
	ReplicatedStorage:SetAttribute("Level", level)
	ReplicatedStorage:SetAttribute("RoundsCleared", 0)
	Hero.startMatch(0)
	Towers.setLevel(level, chosen)
	Enemies.setSpeedMult(chosen.speedMult)
	local density = Sides.density(modeKey, sides)
	local standInCount = 0
	for _ in seating.standIn do
		standInCount += 1
	end
	print(`[DinoHunters] {display} on {chosen.display}: {sides} sides, {#roster} player(s), {standInCount} stand-in(s)`)

	local out: { [number]: boolean } = {}
	local outAt: { [number]: number } = {}
	local frozenBones: { [number]: number } = {}
	local elimination: { { number } } = {}
	local finished = false
	local round = 0
	local startedAt = 0
	local spawnedRound: { [number]: number } = {} -- side -> the last round whose spawning finished
	local matchSeed = math.random(1, 2 ^ 30)

	local function living(): { number }
		local list = {}
		for side = 1, sides do
			if not out[side] then
				table.insert(list, side)
			end
		end
		return list
	end

	local function sideBones(side: number): number
		if frozenBones[side] then
			return frozenBones[side]
		end
		local total = 0
		for _, player in huntersOf(side) do
			total += Scoreboard.bones(player)
		end
		return total
	end

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
		startedAt = os.clock()
		for _, side in living() do
			Airdrops.drop(side) -- each side's chests on its own plot (#231)
			local scale = BattleFlow.sideScale(chosen, #huntersOf(side))
			task.spawn(function()
				Waves.spawnRound({
					side = side,
					index = index,
					scale = scale,
					density = density,
					hpMult = hpExtra,
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
		for _, side in living() do
			Economy.earnFor(side, (Config.Tuning.RoundBonusBase + Config.Tuning.RoundBonusPerRound * index) * chosen.cashMult)
			Economy.earnFor(side, Towers.roundIncome(Economy.cashOf(side), side) * chosen.cashMult) -- its Supply Camps
			for _, hunter in huntersOf(side) do
				Health.heal(hunter, Config.Tuning.HealPerRound + SmallPerks.ofPlayer(hunter).healPerRound)
			end
		end
		ReplicatedStorage:SetAttribute("RoundsCleared", index)
		Hero.roundCleared(index, false)
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
			for _, player in huntersOf(side) do
				player:SetAttribute("Out", true) -- spectating: walk, no damage, no building
			end
			Battle.announce(BattleFlow.outLine(Battle.campOf(side)))
		end
	end

	-- Is the match over? Returns the result once it is.
	local function verdict(roundsDone: boolean): any?
		local bones = {}
		for side = 1, sides do
			bones[side] = sideBones(side)
		end
		if modeKey == "TEAM" then
			local result = BattleRules.teamResult(elimination, bones)
			return if result.over then result else nil
		end
		local seats = {}
		for side = 1, sides do
			table.insert(seats, { id = side, bones = bones[side], fence = Economy.livesOf(side), outAt = outAt[side] })
		end
		local result = BattleRules.royaleResult(seats, roundsDone)
		return if result.over then result else nil
	end

	startRound(1)
	local result: any = nil
	while true do
		task.wait(CHECK_EVERY)
		if #Players:GetPlayers() == 0 then
			finished = true
			return true
		end
		-- A Bone Rush hunter who leaves is out (PLAN T77); a Camp Clash leaver's towers stay.
		if modeKey == "ROYALE" then
			for side = 1, sides do
				if not out[side] and not seating.standIn[side] and #huntersOf(side) == 0 then
					table.insert(pendingOut, side)
				end
			end
		end
		if #pendingOut > 0 then
			local fallen = pendingOut
			pendingOut = {}
			eliminate(fallen)
		end
		result = verdict(false)
		if result then
			break
		end
		local cleared = {}
		for _, side in living() do
			cleared[side] = (spawnedRound[side] or 0) >= round and Enemies.remaining(side) == 0
		end
		if BattleRules.nextRoundDue(cleared, os.clock() - startedAt) then
			endRound(round)
			if not BattleFlow.hasOvertime(modeKey) and round >= #Config.Rounds then
				result = verdict(true)
				break
			end
			startRound(round + 1)
		end
	end
	finished = true

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
		for _, player in huntersOf(side) do
			player:SetAttribute("BattlePlace", places[side])
			-- Camp Clash: the hunter's own Bones; Bone Rush: the seat's final (survivor bonus in).
			player:SetAttribute("BattleBones", if modeKey == "TEAM" then Scoreboard.bones(player) else finalBones[side])
		end
	end
	for _, side in order do
		table.insert(lines, `{places[side]}. {Battle.campOf(side)} ({finalBones[side]} Bones)`)
	end
	ReplicatedStorage:SetAttribute("State", "Victory")
	print(`[DinoHunters] {display} over on round {round}: {table.concat(lines, " | ")}`)
	return true
end

return Battle
