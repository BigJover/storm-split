--[[
	Dino Hunters — server entry point.

	The server runs matches in a loop:

	  Lobby     the home screen. No characters. The host (first player in the
	            server) picks the mode, track and difficulty and presses Play.
	  Building  everyone spawns on the track with the team's starting cash,
	            picks a hero, places towers; anyone presses Start.
	  Playing   the rounds. Kills and round ends pay cash; leaks cost lives.
	            Every round scales with the difficulty and the number of players
	            (VISION.md). Dead players respawn after RespawnTime.
	  GameOver / Victory
	            Amber is paid out (Server/Progression); the result shows
	            for ResultsTime, then the board resets and everyone goes home.

	Camp Clash and Bone Rush (PLAN phase 7 T77) run through Server/Battle instead of the
	co-op rounds: sides, one timed build phase, lockstep rounds, elimination, results.
	The host sets the side / seat count ("sides", n); Studio only (Shared/StudioOnly,
	PLAN T89): fill empty sides with stand-ins ("standins", on).

	Every round prints peak live enemies and how many milliseconds our own code
	costs per frame (ARCHITECTURE.md §7). Watch the Output window.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Modes = require(Shared:WaitForChild("Modes"))
local HeroXp = require(Shared:WaitForChild("HeroXp"))
local PlayerLevel = require(Shared:WaitForChild("PlayerLevel"))
local Pricing = require(Shared:WaitForChild("Pricing"))
local SmallPerks = require(Shared:WaitForChild("SmallPerks"))
local Sides = require(Shared:WaitForChild("Sides"))
local BattleFlow = require(Shared:WaitForChild("BattleFlow"))
local HomeLayout = require(Shared:WaitForChild("HomeLayout"))
local StudioOnly = require(Shared:WaitForChild("StudioOnly"))

local MapBuilder = require(script.Parent.MapBuilder)
local Enemies = require(script.Parent.Enemies)
local Towers = require(script.Parent.Towers)
local Waves = require(script.Parent.Waves)
local Economy = require(script.Parent.Economy)
local Shop = require(script.Parent.Shop)
local Scoreboard = require(script.Parent.Scoreboard)
local Wardrobe = require(script.Parent.Wardrobe)
local LevelBoard = require(script.Parent.LevelBoard)
local TrophyBoard = require(script.Parent.TrophyBoard)
local Effects = require(script.Parent.Effects)
local Hero = require(script.Parent.Hero)
local Hazards = require(script.Parent.Hazards)
local Airdrops = require(script.Parent.Airdrops)
local Progression = require(script.Parent.Progression)
local Health = require(script.Parent.Health)
local DinoAttacks = require(script.Parent.DinoAttacks)
local Battle = require(script.Parent.Battle)

-- Testing only: the host's Studio-only "Start at round N" (Lobby ("startround", n), PLAN
-- T91b). A live server always starts at round 1 (Shared/StudioOnly).
local function studioStartRound(): number
	return StudioOnly.startRound(RunService:IsStudio(), ReplicatedStorage:GetAttribute("StudioStartRound"), #Config.Rounds)
end
-- Testing only: what the Studio-only "+cash" button adds. Never active in a
-- published game (checked with RunService:IsStudio() on the server).
local STUDIO_CASH_GRANT = 1000
-- Testing only: the share of max HP the Studio-only L key knocks off the
-- tower nearest you (DECISIONS #11).
local STUDIO_TOWER_HIT = 0.5

------------------------------------------------------------------ setup

Players.CharacterAutoLoads = false -- the match loop decides when people spawn

local map = MapBuilder.build()

local function setState(state: string)
	ReplicatedStorage:SetAttribute("State", state)
end

setState("Lobby")
ReplicatedStorage:SetAttribute("Round", 0)
ReplicatedStorage:SetAttribute("Alive", 0)
ReplicatedStorage:SetAttribute("Mode", Modes.ModeOrder[1])
ReplicatedStorage:SetAttribute("Track", Modes.TrackOrder[1])

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local startGame = Instance.new("RemoteEvent")
startGame.Name = "StartGame"
startGame.Parent = remotes
-- Home screen, host only: ("mode" | "track" | "difficulty", key), ("sides", n), ("standins",
-- on), ("ranked", on) or ("play"); Studio only (PLAN T91b): ("startround", n) and
-- ("standinshold", on). Every player: ("ready", on) for Ranked (PLAN T80; its
-- buttons are T82's)
local lobby = Instance.new("RemoteEvent")
lobby.Name = "Lobby"
lobby.Parent = remotes
-- Studio-only test remotes (PLAN T89): made only in Studio, and each handler asks again.
if StudioOnly.allowed(RunService:IsStudio(), "cash") then
	local studioCash = Instance.new("RemoteEvent")
	studioCash.Name = "StudioCash"
	studioCash.OnServerEvent:Connect(function(player: Player)
		if not StudioOnly.allowed(RunService:IsStudio(), "cash") then
			return
		end
		Economy.earnFor(Sides.playerSide(player:GetAttribute("Side"), ReplicatedStorage:GetAttribute("Sides")), STUDIO_CASH_GRANT)
	end)
	studioCash.Parent = remotes
end
if StudioOnly.allowed(RunService:IsStudio(), "towerHit") then
	local studioTrample = Instance.new("RemoteEvent")
	studioTrample.Name = "StudioTowerHit"
	studioTrample.OnServerEvent:Connect(function(player)
		if not StudioOnly.allowed(RunService:IsStudio(), "towerHit") then
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") then
			return
		end
		local nearest, best = nil, math.huge
		for _, tower in Towers.all() do
			local gap = (tower.base - root.Position).Magnitude
			if gap < best then
				nearest, best = tower, gap
			end
		end
		if nearest then
			Towers.damage(nearest, nearest.maxHp * STUDIO_TOWER_HIT, "studio")
		end
	end)
	studioTrample.Parent = remotes
end
remotes.Parent = ReplicatedStorage

local EASY = Config.DifficultyOrder[1]
ReplicatedStorage:SetAttribute("Difficulty", EASY)

local function difficulty()
	return Config.Difficulties[ReplicatedStorage:GetAttribute("Difficulty")] or Config.Difficulties[EASY]
end

local over = false -- this match has been lost

Enemies.init(map.paths, map.enemyFolder, {
	onLeak = function(enemy)
		Economy.loseFor(enemy.side, Battle.leakCost(enemy.side, Enemies.leakCost(enemy))) -- only that side's Fence (T76)
	end,
	-- Each split layer pays for its own HP, so a full cascade pays the round's
	-- effective HP x CashPerEffectiveHP — the spreadsheet's "Kill income".
	onKilled = function(enemy)
		Economy.earnFor(enemy.side, enemy.share * Config.Tuning.CashPerEffectiveHP * difficulty().cashMult)
		Battle.dinoPopped(enemy.side) -- a stand-in seat's Bone (Studio battles, T79b)
	end,
})

Effects.init(map.effectFolder)
Scoreboard.init()

-- Who has taken part in this match, by UserId (also: starting cash per extra player).
local joinedThisMatch: { [number]: boolean } = {}

-- The hunters in the match: took part and still here.
local function hunters(): { Player }
	local out = {}
	for _, player in Players:GetPlayers() do
		if joinedThisMatch[player.UserId] then
			table.insert(out, player)
		end
	end
	return out
end

-- A pop: a dino lost a size. The Scoreboard counts every one for the hunter who made
-- it, exactly as before. Bounties count dinos, so only the pop that finishes one off
-- (`gone` = its species key) is passed on, to every hunter in the match: `credited`
-- says whose pop it was, and Shared/Bounties counts a teammate's pop only for bosses
-- (DECISIONS #66, #82).
local CREDITED = table.freeze({ credited = true })
local NOT_CREDITED = table.freeze({ credited = false })
local function popped(player: Player?, gone: string?)
	if player then
		Scoreboard.addPop(player)
		Hero.addPop(player) -- pending hero XP, banked when the round is cleared
	end
	if gone then
		for _, hunter in hunters() do
			Progression.bountyEvent(hunter, "pop", gone, 1, if hunter == player then CREDITED else NOT_CREDITED)
		end
	end
end

Hazards.init({ onPop = popped })
Airdrops.init(map.effectFolder)
Towers.init(map.towerFolder, {
	onPop = popped,
	extraRatePercent = function(tower)
		return Hero.towerRateBoost(tower.position, tower.side) -- Overdrive (own side's hunters, T78)
	end,
	resistOf = function(tower)
		return { Hero.towerGuardOf(tower) } -- Field Medic Second Wind
	end,
	-- A Tar Pit sank a dino: Dig Site's cash per sink (scaled like kill pay) and Lucky
	-- Finds' chest where it went under.
	onSink = function(cash, chestCash, position, side)
		if cash > 0 then
			Economy.earnFor(side, cash * difficulty().cashMult) -- the pit's side (T77)
		end
		Airdrops.chestAt(position, chestCash, side)
	end,
})
Progression.init(remotes, { onMasteryChanged = Hero.masteryChanged, onLookChanged = Hero.lookChanged })
-- The home screen's Practice Hunt line under Ready (PLAN T82): unpublished = Practice.
ReplicatedStorage:SetAttribute("PracticeHunt", Progression.practice())
Wardrobe.init() -- hats and trails on characters (PLAN T57)
LevelBoard.init(remotes) -- the level leaderboard (PLAN T58); never blocks play
TrophyBoard.init(remotes) -- the Trophy leaderboard (PLAN T81); never blocks play
Health.init(remotes, {
	-- An Armory covering where the hunter stands, and a Field Medic's Second Wind.
	resistOf = function(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local guard = Hero.guardOf(player)
		-- your own side's Armories only (T78)
		local side = Sides.playerSide(player:GetAttribute("Side"), ReplicatedStorage:GetAttribute("Sides"))
		return if root and root:IsA("BasePart") then { Towers.resistAt(root.Position, side), guard } else { guard }
	end,
})
DinoAttacks.init({
	damageMult = function()
		return difficulty().dinoDamageMult
	end,
	folder = map.effectFolder,
	onBite = Towers.bitten,
})
Shop.init(remotes, { onBounty = Progression.bountyEvent }) -- build, upgrade, repair
Hero.init(remotes, {
	onPop = popped,
	onBounty = Progression.bountyEvent,
	gearAt = Towers.hunterGearAt,
	difficulty = difficulty,
	-- PvP feed (T78): a raid knock-out for everyone; a hunter down told to them alone.
	onRaid = function(player, tower)
		Battle.announce(BattleFlow.raidLine(player.DisplayName, Battle.campOf(tower.side), tower.def.display))
	end,
	onTranq = function(victim, attacker)
		Battle.tell(victim, BattleFlow.tranqLine(attacker.DisplayName))
	end,
}) -- ability
Battle.init(remotes) -- the kill feed

------------------------------------------------------------------ host

-- The host is the longest-connected player; if they leave, the next one is.
local function refreshHost()
	local host = Players:GetPlayers()[1]
	ReplicatedStorage:SetAttribute("Host", if host then host.UserId else 0)
end
Players.PlayerAdded:Connect(refreshHost)
Players.PlayerRemoving:Connect(function()
	task.defer(refreshHost)
end)
refreshHost()

local function isHost(player: Player): boolean
	return ReplicatedStorage:GetAttribute("Host") == player.UserId
end

local playPressed = false
lobby.OnServerEvent:Connect(function(player, action: unknown, key: unknown)
	if ReplicatedStorage:GetAttribute("State") ~= "Lobby" then
		return
	end
	-- Ready is each player's own (DECISIONS #223), checked by Stakes.canStake: a save that
	-- didn't load can't stake (told why: "ReadyRefused" = the reason key, T82 words it).
	if action == "ready" and typeof(key) == "boolean" then
		local ok, why = true, nil
		if key then
			ok, why = Progression.canStake(player)
		end
		player:SetAttribute("Ready", key and ok)
		player:SetAttribute("ReadyRefused", if key and not ok then why else nil)
		return
	end
	if not isHost(player) then
		return
	end
	-- Ranked is a battle queue: it fixes the difficulty only while a battle mode is picked.
	local function rankedBattle(): boolean
		return ReplicatedStorage:GetAttribute("Ranked") == true and HomeLayout.isBattle(ReplicatedStorage:GetAttribute("Mode"))
	end
	if action == "ranked" and typeof(key) == "boolean" then
		ReplicatedStorage:SetAttribute("Ranked", key) -- Casual / Ranked (battle modes only)
		if rankedBattle() then
			ReplicatedStorage:SetAttribute("Difficulty", PlayerLevel.BATTLE_CLEAR) -- Ranked is always Normal (#217)
		end
	elseif action == "difficulty" and rankedBattle() then
		return -- fixed to Normal while Ranked
	elseif action == "mode" and typeof(key) == "string" and Modes.Modes[key] and Modes.Modes[key].available then
		ReplicatedStorage:SetAttribute("Mode", key) -- Camp Clash and Bone Rush are open from T82
		if key == "TEAM" and not table.find(Modes.TeamSides, ReplicatedStorage:GetAttribute("BattleSides")) then
			ReplicatedStorage:SetAttribute("BattleSides", nil) -- a Bone Rush seat count isn't a camp count
		end
		if rankedBattle() then
			ReplicatedStorage:SetAttribute("Difficulty", PlayerLevel.BATTLE_CLEAR)
		end
	elseif action == "sides" and typeof(key) == "number" and key == math.floor(key) and key >= 2 and key <= Config.Tuning.BattleMaxPlayers then
		ReplicatedStorage:SetAttribute("BattleSides", key) -- Camp Clash 2 or 3; Bone Rush seats with stand-ins
	elseif action == "standins" and typeof(key) == "boolean" and StudioOnly.allowed(RunService:IsStudio(), "standIns") then
		ReplicatedStorage:SetAttribute("StandIns", key) -- "Fill with stand-ins" (DECISIONS #221)
	elseif action == "startround" and typeof(key) == "number" and StudioOnly.allowed(RunService:IsStudio(), "startRound") then
		ReplicatedStorage:SetAttribute("StudioStartRound", StudioOnly.startRound(RunService:IsStudio(), key, #Config.Rounds))
	elseif action == "standinshold" and typeof(key) == "boolean" and StudioOnly.allowed(RunService:IsStudio(), "standInsHold") then
		ReplicatedStorage:SetAttribute("StandInsHold", key) -- a stand-in camp's Fence never drops below 1
	elseif action == "track" and typeof(key) == "string" and Modes.Tracks[key] then
		ReplicatedStorage:SetAttribute("Track", key)
	elseif action == "difficulty" and typeof(key) == "string" and Config.Difficulties[key] then
		ReplicatedStorage:SetAttribute("Difficulty", key)
	elseif action == "play" then
		-- PLAY works once the minimum is met (PLAN T82): Ranked counts the Ready hunters.
		local ready = 0
		for _, each in Players:GetPlayers() do
			if each:GetAttribute("Ready") == true then
				ready += 1
			end
		end
		local picked = ReplicatedStorage:GetAttribute("BattleSides")
		local canPlay = HomeLayout.canPlay(
			ReplicatedStorage:GetAttribute("Mode"),
			ReplicatedStorage:GetAttribute("Ranked") == true,
			#Players:GetPlayers(),
			ready,
			if typeof(picked) == "number" then picked else nil,
			StudioOnly.allowed(RunService:IsStudio(), "standIns") and ReplicatedStorage:GetAttribute("StandIns") == true
		)
		if canPlay then
			playPressed = true
		end
	end
end)

------------------------------------------------------------------ spawning

local function inMatch(): boolean
	local state = ReplicatedStorage:GetAttribute("State")
	return state == "Building" or state == "Playing"
end

local function spawn(player: Player)
	if player.Parent and inMatch() then
		task.spawn(function()
			local ok, err = pcall(function()
				player:LoadCharacterAsync()
			end)
			if not ok then
				warn(`[DinoHunters] Couldn't spawn {player.Name}: {err}`)
			end
		end)
	end
end

-- During a match, the dead come back after RespawnTime, at full health with
-- a short force field (Server/Health). A standing Rescue Beacon (Field
-- Hospital) brings them back sooner, next to it.
local RESCUE_OFFSET = Vector3.new(0, 3, 4) -- visual placement beside the hospital
local rescueAt: { [Player]: Vector3 } = {}

local SPAWN_LIFT = Vector3.new(0, 3, 0) -- visual placement: stand on the ground, not in it

local function sideOfPlayer(player: Player): number
	return Sides.playerSide(player:GetAttribute("Side"), ReplicatedStorage:GetAttribute("Sides"))
end

local function watchCharacter(player: Player)
	player.CharacterAdded:Connect(function(character)
		Health.setUp(character)
		local beacon = rescueAt[player]
		rescueAt[player] = nil
		-- A battle hunter (re)spawns on their own side (T77); co-op is unchanged.
		local battleHome = Battle.spawnPoint(player)
		local at = if beacon then beacon + RESCUE_OFFSET elseif battleHome then battleHome + SPAWN_LIFT else nil
		if at then
			task.defer(function()
				if character.Parent then
					character:PivotTo(CFrame.new(at))
				end
			end)
		end
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Connect(function()
			local base, share = Towers.rescueBeacon(sideOfPlayer(player)) -- your own side's (T77)
			-- Back in Action (Shared/SmallPerks) stacks with a Rescue Beacon's share.
			local perk = SmallPerks.ofPlayer(player).respawnMult
			task.delay(Config.Tuning.RespawnTime * (if base then share else 1) * perk, function()
				if player.Character == character then
					local stillThere = Towers.rescueBeacon(sideOfPlayer(player)) -- still standing?
					if stillThere then
						rescueAt[player] = stillThere
					end
					spawn(player)
				end
			end)
		end)
	end)
end

-- Starting cash: each player beyond the first adds to the pot, once per match.
local function joinMatch(player: Player)
	if not joinedThisMatch[player.UserId] then
		local first = next(joinedThisMatch) == nil
		joinedThisMatch[player.UserId] = true
		if not first then
			Economy.earn(Config.Tuning.StartingCashPerExtraPlayer)
		end
	end
	spawn(player)
end

Players.PlayerAdded:Connect(function(player)
	watchCharacter(player)
	if inMatch() and not Battle.active() then
		joinMatch(player) -- dropped in mid-match: straight onto the track (co-op; a battle's sides are set)
	end
end)
for _, player in Players:GetPlayers() do
	watchCharacter(player)
end

------------------------------------------------------------------ simulation loop

local frames, costSum, costWorst = 0, 0, 0
local lastAlive = -1

RunService.Heartbeat:Connect(function(dt)
	local started = os.clock()
	Enemies.step(dt)
	Towers.step(dt)
	DinoAttacks.step(dt) -- bites and projectiles (Playing only)
	Hazards.step(dt)
	local cost = os.clock() - started

	frames += 1
	costSum += cost
	if cost > costWorst then
		costWorst = cost
	end

	local alive = Enemies.aliveCount()
	if alive ~= lastAlive then
		lastAlive = alive
		ReplicatedStorage:SetAttribute("Alive", alive)
	end
end)

------------------------------------------------------------------ one match

-- Back to a clean board. Unlocks, mastery and hero picks are kept.
local function resetBoard()
	Battle.reset()
	Enemies.clearAll()
	Towers.clearAll()
	Shop.reset()
	Hazards.clear()
	DinoAttacks.clear()
	Effects.clear()
	Hero.resetMatch()
	Scoreboard.resetPops()
	table.clear(joinedThisMatch)
	over = false
	ReplicatedStorage:SetAttribute("Round", 0)
	ReplicatedStorage:SetAttribute("Level", 1) -- the tower level
	ReplicatedStorage:SetAttribute("RoundsCleared", 0)
	for _, player in Players:GetPlayers() do
		if player.Character then
			player.Character:Destroy()
		end
		player:SetAttribute("LastPayout", nil)
		player:SetAttribute("LastPlayerXp", nil)
		player:SetAttribute("LastPlayerLevelFrom", nil)
		player:SetAttribute("LastPlayerLevel", nil)
		for _, name in { "LastPotShare", "LastTrophies", "LastArena", "Ready", "ReadyRefused" } do
			player:SetAttribute(name, nil) -- Ranked: a new Ready for every match (T80)
		end
	end
	ReplicatedStorage:SetAttribute("BattleRanked", nil)
	ReplicatedStorage:SetAttribute("BattlePractice", nil)
	ReplicatedStorage:SetAttribute("BattlePot", nil)
end

local function playBattle()
	-- Ranked (PLAN T80, DECISIONS #216): the Ready hunters who can still stake are seated,
	-- their buy-in taken into escrow now (saved at once); anyone else waits for the next
	-- hunt. Casual seats everyone and stakes nothing.
	local ranked = ReplicatedStorage:GetAttribute("Ranked") == true
	local roster: { Player }? = nil
	local matchId: string? = nil
	local staked: { [Player]: boolean } = {}
	if ranked then
		matchId = HttpService:GenerateGUID(false)
		local list = {}
		for _, player in Players:GetPlayers() do
			if player:GetAttribute("Ready") == true and Progression.stake(player, matchId :: string) then
				staked[player] = true
				table.insert(list, player)
			end
		end
		roster = list
	end
	ReplicatedStorage:SetAttribute("BattleRanked", if ranked then true else nil)
	local started, outcome = Battle.play({
		roster = roster,
		startRound = studioStartRound(), -- 1 unless the Studio host picked "Start at round N"
		competitive = ranked,
		onRoundStart = function(round, still)
			for _, hunter in still do
				Progression.bountyEvent(hunter, "reachRound", nil, round) -- battles count as matches (#222)
			end
		end,
		map = map,
		difficulty = difficulty,
		spawn = function(player)
			joinedThisMatch[player.UserId] = true
			spawn(player)
		end,
		resetCost = function()
			frames, costSum, costWorst = 0, 0, 0
		end,
		costLine = function()
			local average = if frames > 0 then costSum / frames else 0
			return string.format("script cost avg %.2f ms, worst %.2f ms", average * 1000, costWorst * 1000)
		end,
	})
	if not started then
		for player in staked do
			Progression.refundStake(player) -- the match never began: every stake back
		end
		return -- couldn't seat the sides: back to the lobby
	end
	if outcome then
		-- Player XP (#222): cleared rounds, a win counts as a Normal clear. Before
		-- endBattle, which saves. Leavers get nothing.
		local tallies: { [Player]: PlayerLevel.Tally } = {}
		local places: { [Player]: number } = {}
		for _, hunter in outcome.hunters do
			local tally = if hunter.present then Hero.matchTally(hunter.player) else nil
			if tally then
				tallies[hunter.player] = tally
				places[hunter.player] = hunter.place
			end
		end
		for hunter, xp in PlayerLevel.battleAwards(tallies, places) do
			Progression.addPlayerXp(hunter, xp)
		end
		local hunters = {}
		for _, hunter in outcome.hunters do
			table.insert(hunters, { player = hunter.player, place = hunter.place, present = hunter.present, staked = staked[hunter.player] == true })
		end
		Progression.endBattle({ mode = outcome.mode, n = outcome.n, ranked = ranked, matchId = matchId, hunters = hunters, standIns = outcome.standIns })
	end
	local resultsTime = BattleFlow.resultsTime(true) -- battles: Battle results time (T86b)
	ReplicatedStorage:SetAttribute("HomeAt", workspace:GetServerTimeNow() + resultsTime)
	task.wait(resultsTime)
end

local function playMatch()
	local mode = Modes.Modes[ReplicatedStorage:GetAttribute("Mode")]
	if mode and mode.sides ~= "one" then
		playBattle()
		return
	end
	-- Co-op: back to the one-side map if a battle changed it.
	if MapBuilder.relayout(map, Sides.new(1)) then
		Enemies.setPaths(map.paths)
	end
	local chosen = difficulty()

	-- Building: fresh economy, everyone on the track.
	Economy.init(Pricing.startingPot(chosen, 1), chosen.startingLives, function()
		over = true
	end)
	setState("Building")
	for _, player in Players:GetPlayers() do
		joinMatch(player)
	end

	local startPressed = false
	local connection = startGame.OnServerEvent:Connect(function()
		if ReplicatedStorage:GetAttribute("State") == "Building" then
			startPressed = true
		end
	end)
	while not startPressed and #Players:GetPlayers() > 0 do
		task.wait(0.1)
	end
	connection:Disconnect()
	if #Players:GetPlayers() == 0 then
		return -- everyone left before starting
	end

	-- Playing.
	setState("Playing")
	local startAt = studioStartRound()
	-- Towers ride the round level (the old every-RoundsPerLevel curve); each
	-- hunter's own level comes from their XP and is Hero's to change.
	local level = HeroXp.roundLevel(startAt - 1)
	ReplicatedStorage:SetAttribute("Level", level)
	ReplicatedStorage:SetAttribute("RoundsCleared", startAt - 1)
	Hero.startMatch(startAt - 1)
	Towers.setLevel(level, difficulty())
	Enemies.setSpeedMult(chosen.speedMult)
	print(`[DinoHunters] {Modes.Modes[ReplicatedStorage:GetAttribute("Mode")].display} on {chosen.display} with {#Players:GetPlayers()} player(s)`)

	-- Difficulty x player count, re-read every round so drop-in players count.
	local function roundScale(): Waves.Scale
		local extraPlayers = math.max(0, #Players:GetPlayers() - 1)
		return {
			countMult = chosen.countMult * (1 + Config.Tuning.ExtraEnemiesPerPlayer * extraPlayers),
			hpMult = chosen.hpMult * (1 + Config.Tuning.ExtraHPPerPlayer * extraPlayers),
			promoteChance = chosen.promoteChance,
		}
	end

	local won = Waves.run({
		startRound = startAt,
		isOver = function()
			return over or #Players:GetPlayers() == 0
		end,
		scale = roundScale,
		onRoundStart = function(index)
			for _, hunter in hunters() do
				Progression.bountyEvent(hunter, "reachRound", nil, index) -- once per round
			end
			frames, costSum, costWorst = 0, 0, 0
			Enemies.resetPeak()
			DinoAttacks.resetPeak()
			Towers.newRound() -- Last Stand is ready again
			Airdrops.drop()
		end,
		onRoundEnd = function(index)
			Economy.earn((Config.Tuning.RoundBonusBase + Config.Tuning.RoundBonusPerRound * index) * chosen.cashMult)
			Economy.earn(Towers.roundIncome(Economy.cash()) * chosen.cashMult) -- Quartermasters
			for _, hunter in Players:GetPlayers() do -- plus each hunter's First Aid (Shared/SmallPerks)
				Health.heal(hunter, Config.Tuning.HealPerRound + SmallPerks.ofPlayer(hunter).healPerRound)
			end

			ReplicatedStorage:SetAttribute("RoundsCleared", index)
			Hero.roundCleared(index, #hunters() == 1) -- banks Round XP and this round's pending pop XP; solo per round (#177)
			local newLevel = HeroXp.roundLevel(index)
			if newLevel > level then
				level = newLevel
				Towers.setLevel(level, difficulty())
				ReplicatedStorage:SetAttribute("Level", level) -- the HUD announces it
				print(`[DinoHunters] Tower level {level}: towers hit harder`)
			end

			local average = if frames > 0 then costSum / frames else 0
			print(string.format(
				"[DinoHunters] Round %d cleared | %s, %d player(s) | lives %d | cash %d | peak enemies %d | peak projectiles %d/%d | script cost avg %.2f ms, worst %.2f ms",
				index,
				chosen.display,
				#Players:GetPlayers(),
				Economy.lives(),
				math.floor(Economy.cash()),
				Enemies.peak(),
				DinoAttacks.peak(),
				Config.Tuning.MaxProjectiles,
				average * 1000,
				costWorst * 1000
			))
		end,
	})

	-- Result: pay out, show it, then home.
	local round = ReplicatedStorage:GetAttribute("Round") or 0
	setState(if won then "Victory" else "GameOver")
	print(if won then "[DinoHunters] VICTORY — all rounds cleared" else `[DinoHunters] GAME OVER on round {round}`)
	-- Everyone who took part and is still here counts toward "multiplayer",
	-- whether or not their save loaded (DECISIONS #19).
	local players = 0
	for userId in joinedThisMatch do
		if Players:GetPlayerByUserId(userId) then
			players += 1
		end
	end
	-- Player XP (PLAN T56, DECISIONS #119, #124): every hunter still here banks the hero
	-- XP of their cleared rounds (+ Clear XP on a win); the solo boost was decided round
	-- by round as each was cleared (#177).
	-- Leavers aren't in hunters(), so they get nothing. Before endMatch, which saves.
	local tallies: { [Player]: PlayerLevel.Tally } = {}
	for _, hunter in hunters() do
		local tally = Hero.matchTally(hunter)
		if tally then
			tallies[hunter] = tally
		end
	end
	local difficultyKey = ReplicatedStorage:GetAttribute("Difficulty")
	for hunter, xp in PlayerLevel.matchAwards(tallies, won, difficultyKey) do
		Progression.addPlayerXp(hunter, xp)
	end
	Progression.endMatch({
		cleared = won,
		roundReached = if won then #Config.Rounds else round,
		difficulty = ReplicatedStorage:GetAttribute("Difficulty"),
		players = players,
	})
	local resultsTime = BattleFlow.resultsTime(false) -- co-op keeps Results time (T86b)
	ReplicatedStorage:SetAttribute("HomeAt", workspace:GetServerTimeNow() + resultsTime)
	task.wait(resultsTime)
end

------------------------------------------------------------------ the loop

while true do
	resetBoard()
	playPressed = false
	setState("Lobby")
	while not playPressed or #Players:GetPlayers() == 0 do
		task.wait(0.1)
	end
	playMatch()
end
