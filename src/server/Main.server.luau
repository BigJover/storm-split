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

	Every round prints peak live enemies and how many milliseconds our own code
	costs per frame (ARCHITECTURE.md §7). Watch the Output window.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Modes = require(Shared:WaitForChild("Modes"))
local HeroXp = require(Shared:WaitForChild("HeroXp"))

local MapBuilder = require(script.Parent.MapBuilder)
local Enemies = require(script.Parent.Enemies)
local Towers = require(script.Parent.Towers)
local Waves = require(script.Parent.Waves)
local Economy = require(script.Parent.Economy)
local Shop = require(script.Parent.Shop)
local Scoreboard = require(script.Parent.Scoreboard)
local Effects = require(script.Parent.Effects)
local Hero = require(script.Parent.Hero)
local Hazards = require(script.Parent.Hazards)
local Airdrops = require(script.Parent.Airdrops)
local Progression = require(script.Parent.Progression)
local Health = require(script.Parent.Health)
local DinoAttacks = require(script.Parent.DinoAttacks)

-- Testing only: set above 1 to jump straight to a later round.
local START_ROUND = 1
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
-- Home screen, host only: ("mode" | "track" | "difficulty", key) or ("play")
local lobby = Instance.new("RemoteEvent")
lobby.Name = "Lobby"
lobby.Parent = remotes
if RunService:IsStudio() then
	local studioCash = Instance.new("RemoteEvent")
	studioCash.Name = "StudioCash"
	studioCash.OnServerEvent:Connect(function()
		Economy.earn(STUDIO_CASH_GRANT)
	end)
	studioCash.Parent = remotes

	local studioTrample = Instance.new("RemoteEvent")
	studioTrample.Name = "StudioTowerHit"
	studioTrample.OnServerEvent:Connect(function(player)
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

Enemies.init(map.path, map.enemyFolder, {
	onLeak = function(enemy)
		Economy.lose(Enemies.leakCost(enemy))
	end,
	-- Each split layer pays for its own HP, so a full cascade pays the round's
	-- effective HP x CashPerEffectiveHP — the spreadsheet's "Kill income".
	onKilled = function(enemy)
		Economy.earn(enemy.maxHp * Config.Tuning.CashPerEffectiveHP * difficulty().cashMult)
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
		return Hero.towerRateBoost(tower.position) -- Overdrive
	end,
	resistOf = function(tower)
		return { Hero.towerGuardOf(tower) } -- Field Medic Second Wind
	end,
})
Progression.init(remotes, { onMasteryChanged = Hero.masteryChanged })
Health.init(remotes, {
	-- An Armory covering where the hunter stands, and a Field Medic's Second Wind.
	resistOf = function(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local guard = Hero.guardOf(player)
		return if root and root:IsA("BasePart") then { Towers.resistAt(root.Position), guard } else { guard }
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
Hero.init(remotes, { onPop = popped, onBounty = Progression.bountyEvent, gearAt = Towers.hunterGearAt }) -- ability

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
	if ReplicatedStorage:GetAttribute("State") ~= "Lobby" or not isHost(player) then
		return
	end
	if action == "mode" and typeof(key) == "string" and Modes.Modes[key] and Modes.Modes[key].available then
		ReplicatedStorage:SetAttribute("Mode", key)
	elseif action == "track" and typeof(key) == "string" and Modes.Tracks[key] then
		ReplicatedStorage:SetAttribute("Track", key)
	elseif action == "difficulty" and typeof(key) == "string" and Config.Difficulties[key] then
		ReplicatedStorage:SetAttribute("Difficulty", key)
	elseif action == "play" then
		playPressed = true
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

local function watchCharacter(player: Player)
	player.CharacterAdded:Connect(function(character)
		Health.setUp(character)
		local beacon = rescueAt[player]
		rescueAt[player] = nil
		if beacon then
			task.defer(function()
				if character.Parent then
					character:PivotTo(CFrame.new(beacon + RESCUE_OFFSET))
				end
			end)
		end
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Connect(function()
			local base, share = Towers.rescueBeacon()
			task.delay(Config.Tuning.RespawnTime * (if base then share else 1), function()
				if player.Character == character then
					local stillThere = Towers.rescueBeacon() -- still standing?
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
	if inMatch() then
		joinMatch(player) -- dropped in mid-match: straight onto the track
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
	end
end

local function playMatch()
	local chosen = difficulty()

	-- Building: fresh economy, everyone on the track.
	Economy.init(Config.Tuning.StartingCash, chosen.startingLives, function()
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
	-- Towers ride the round level (the old every-RoundsPerLevel curve); each
	-- hunter's own level comes from their XP and is Hero's to change.
	local level = HeroXp.roundLevel(START_ROUND - 1)
	ReplicatedStorage:SetAttribute("Level", level)
	ReplicatedStorage:SetAttribute("RoundsCleared", START_ROUND - 1)
	Hero.startMatch(START_ROUND - 1)
	Towers.setLevel(level)
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
		startRound = START_ROUND,
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
			Health.healAll(Config.Tuning.HealPerRound)

			ReplicatedStorage:SetAttribute("RoundsCleared", index)
			Hero.roundCleared(index) -- banks Round XP and this round's pending pop XP
			local newLevel = HeroXp.roundLevel(index)
			if newLevel > level then
				level = newLevel
				Towers.setLevel(level)
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
	Progression.endMatch({
		cleared = won,
		roundReached = if won then #Config.Rounds else round,
		difficulty = ReplicatedStorage:GetAttribute("Difficulty"),
		players = players,
	})
	ReplicatedStorage:SetAttribute("HomeAt", workspace:GetServerTimeNow() + Config.Tuning.ResultsTime)
	task.wait(Config.Tuning.ResultsTime)
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
