--[[
	Storm Split — server entry point (phase 2).

	The map starts empty. Players place towers anywhere off the track with the
	team's shared cash, pick a difficulty and press Start. Kills and round ends
	pay cash; leaks cost lives. Every round scales with the difficulty and the
	number of players in the game (VISION.md).

	Every round prints peak live enemies and how many milliseconds our own code
	costs per frame (ARCHITECTURE.md §7). Watch the Output window.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

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

-- Testing only: set above 1 to jump straight to a later round.
local START_ROUND = 1
-- Testing only: what the Studio-only "+cash" button adds. Never active in a
-- published game (checked with RunService:IsStudio() on the server).
local STUDIO_CASH_GRANT = 1000

------------------------------------------------------------------ setup

local map = MapBuilder.build()
local over = false

ReplicatedStorage:SetAttribute("State", "Waiting")
ReplicatedStorage:SetAttribute("Round", 0)
ReplicatedStorage:SetAttribute("Alive", 0)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local startGame = Instance.new("RemoteEvent")
startGame.Name = "StartGame"
startGame.Parent = remotes
local chooseDifficulty = Instance.new("RemoteEvent")
chooseDifficulty.Name = "ChooseDifficulty"
chooseDifficulty.Parent = remotes
if RunService:IsStudio() then
	local studioCash = Instance.new("RemoteEvent")
	studioCash.Name = "StudioCash"
	studioCash.OnServerEvent:Connect(function()
		Economy.earn(STUDIO_CASH_GRANT)
	end)
	studioCash.Parent = remotes
end
remotes.Parent = ReplicatedStorage

local EASY = Config.DifficultyOrder[1]
ReplicatedStorage:SetAttribute("Difficulty", EASY)

local function difficulty()
	return Config.Difficulties[ReplicatedStorage:GetAttribute("Difficulty")] or Config.Difficulties[EASY]
end

Economy.init(Config.Tuning.StartingCash, Config.Tuning.StartingLives, function()
	over = true
	ReplicatedStorage:SetAttribute("State", "GameOver")
	print(`[StormSplit] GAME OVER on round {ReplicatedStorage:GetAttribute("Round")}`)
end)

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
Hazards.init({ onPop = Scoreboard.addPop })
Airdrops.init(map.effectFolder)
Towers.init(map.towerFolder, {
	onPop = Scoreboard.addPop,
	extraRatePercent = function(tower)
		return Hero.towerRateBoost(tower.position) -- Overdrive
	end,
})
Shop.init(remotes)
Hero.init(remotes, { onPop = Scoreboard.addPop })

-- Each player beyond the first adds to the shared pot once, whenever they join
-- (a rejoin doesn't pay twice).
local joined: { [number]: boolean } = {}
local joinCount = 0
local function onJoin(player: Player)
	if joined[player.UserId] then
		return
	end
	joined[player.UserId] = true
	joinCount += 1
	if joinCount > 1 then
		Economy.earn(Config.Tuning.StartingCashPerExtraPlayer)
	end
end
Players.PlayerAdded:Connect(onJoin)
for _, player in Players:GetPlayers() do
	onJoin(player)
end

------------------------------------------------------------------ simulation loop

local frames, costSum, costWorst = 0, 0, 0
local lastAlive = -1

RunService.Heartbeat:Connect(function(dt)
	local started = os.clock()
	Enemies.step(dt)
	Towers.step(dt)
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

------------------------------------------------------------------ run

if #Players:GetPlayers() == 0 then
	Players.PlayerAdded:Wait()
end

-- Build phase: anyone can pick the difficulty or press Start. Both lock once
-- the game begins.
local startPressed = false
startGame.OnServerEvent:Connect(function()
	if ReplicatedStorage:GetAttribute("State") == "Building" then
		startPressed = true
	end
end)
chooseDifficulty.OnServerEvent:Connect(function(_player, key: unknown)
	if ReplicatedStorage:GetAttribute("State") == "Building" and typeof(key) == "string" and Config.Difficulties[key] then
		ReplicatedStorage:SetAttribute("Difficulty", key)
		Economy.setLives(Config.Difficulties[key].startingLives)
	end
end)
Economy.setLives(difficulty().startingLives)
ReplicatedStorage:SetAttribute("State", "Building")
while not startPressed do
	task.wait(0.1)
end
ReplicatedStorage:SetAttribute("State", "Playing")

local chosen = difficulty()
Economy.setLives(chosen.startingLives)
Enemies.setSpeedMult(chosen.speedMult)
print(`[StormSplit] {chosen.display} with {#Players:GetPlayers()} player(s)`)

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
		return over
	end,
	scale = roundScale,
	onRoundStart = function()
		frames, costSum, costWorst = 0, 0, 0
		Enemies.resetPeak()
		Airdrops.drop()
	end,
	onRoundEnd = function(index)
		Economy.earn((Config.Tuning.RoundBonusBase + Config.Tuning.RoundBonusPerRound * index) * chosen.cashMult)
		Economy.earn(Towers.roundIncome(Economy.cash()) * chosen.cashMult) -- Quartermasters

		local average = if frames > 0 then costSum / frames else 0
		print(string.format(
			"[StormSplit] Round %d cleared | %s, %d player(s) | lives %d | cash %d | peak enemies %d | script cost avg %.2f ms, worst %.2f ms",
			index,
			chosen.display,
			#Players:GetPlayers(),
			Economy.lives(),
			math.floor(Economy.cash()),
			Enemies.peak(),
			average * 1000,
			costWorst * 1000
		))
	end,
})

if won then
	ReplicatedStorage:SetAttribute("State", "Victory")
	print("[StormSplit] VICTORY — all rounds cleared")
end
