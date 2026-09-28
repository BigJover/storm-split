--[[
	Storm Split — server entry point (phase 2).

	The map starts empty. Players place towers anywhere off the track with the
	team's shared cash, and press Start. Kills and round ends pay cash; leaks cost lives.

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

-- Testing only: set above 1 to jump straight to a later round.
local START_ROUND = 1

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
remotes.Parent = ReplicatedStorage

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
		Economy.earn(enemy.maxHp * Config.Tuning.CashPerEffectiveHP)
	end,
})

Towers.init(map.towerFolder)
Shop.init(remotes)

------------------------------------------------------------------ simulation loop

local frames, costSum, costWorst = 0, 0, 0
local lastAlive = -1

RunService.Heartbeat:Connect(function(dt)
	local started = os.clock()
	Enemies.step(dt)
	Towers.step(dt)
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

-- Build phase: anyone on the team can press Start once they've placed towers.
local startPressed = false
startGame.OnServerEvent:Connect(function()
	if ReplicatedStorage:GetAttribute("State") == "Building" then
		startPressed = true
	end
end)
ReplicatedStorage:SetAttribute("State", "Building")
while not startPressed do
	task.wait(0.1)
end
ReplicatedStorage:SetAttribute("State", "Playing")

local won = Waves.run({
	startRound = START_ROUND,
	isOver = function()
		return over
	end,
	onRoundStart = function()
		frames, costSum, costWorst = 0, 0, 0
		Enemies.resetPeak()
	end,
	onRoundEnd = function(index)
		Economy.earn(Config.Tuning.RoundBonusBase + Config.Tuning.RoundBonusPerRound * index)

		local average = if frames > 0 then costSum / frames else 0
		print(string.format(
			"[StormSplit] Round %d cleared | lives %d | cash %d | peak enemies %d | script cost avg %.2f ms, worst %.2f ms",
			index,
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
