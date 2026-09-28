--[[
	Storm Split — server entry point (phase 1).

	Phase 1 goal: towers shoot enemies that walk a track, leaks cost lives.
	No cash, no shop, no upgrades. Towers are hardcoded below on purpose.

	It also answers the most load-bearing open question in the project
	(ARCHITECTURE.md §7): how many enemies can run at once? Every round
	prints peak live enemies and how many milliseconds our own code costs
	per frame. Watch the Output window.
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
local Lives = require(script.Parent.Lives)

------------------------------------------------------------------ phase 1 test setup

-- TEMPORARY. These free towers exist only so phase 1 can be playtested without a shop.
-- Remove them in phase 2: the real game starts with an empty map and Starting cash
-- (spreadsheet Tuning!B6) that buys 2 Scouts or 1 mid-priced tower, never three.

local PHASE1 = {
	StartRound = 1,
	-- Pads are numbered row by row (see Shared/Track). 2, 5, 8 is the centre column.
	Towers = {
		{ key = "SCOUT", pad = 2 },
		{ key = "SCOUT", pad = 5 },
		{ key = "SCOUT", pad = 8 },
	},
}

------------------------------------------------------------------ setup

local map = MapBuilder.build()
local over = false

ReplicatedStorage:SetAttribute("State", "Waiting")
ReplicatedStorage:SetAttribute("Round", 0)
ReplicatedStorage:SetAttribute("Alive", 0)

Lives.init(Config.Tuning.StartingLives, function()
	over = true
	ReplicatedStorage:SetAttribute("State", "GameOver")
	print(`[StormSplit] GAME OVER on round {ReplicatedStorage:GetAttribute("Round")}`)
end)

Enemies.init(map.path, map.enemyFolder, {
	onLeak = function(enemy)
		Lives.lose(Enemies.leakCost(enemy))
	end,
})

Towers.init(map.towerFolder)
for _, spec in PHASE1.Towers do
	local pad = map.pads[spec.pad]
	if pad then
		Towers.place(spec.key, pad)
	else
		warn(`[StormSplit] No pad {spec.pad} — check Shared/Track.Pads`)
	end
end

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
task.wait(3)
ReplicatedStorage:SetAttribute("State", "Playing")

local won = Waves.run({
	startRound = PHASE1.StartRound,
	isOver = function()
		return over
	end,
	onRoundStart = function()
		frames, costSum, costWorst = 0, 0, 0
		Enemies.resetPeak()
	end,
	onRoundEnd = function(index)
		local average = if frames > 0 then costSum / frames else 0
		print(string.format(
			"[StormSplit] Round %d cleared | lives %d | peak enemies %d | script cost avg %.2f ms, worst %.2f ms",
			index,
			Lives.get(),
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
