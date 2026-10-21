--[[
	Training on the server (PLAN 10c T139, DECISIONS #370-#374, #391): the online tick, the
	station E and the Amber finish. The rules are Shared/Training; the saved state belongs to
	Server/Progression (the only saved-data mutator), which this module only calls.

	TICK. Every TICK seconds of server time, each player in the server gets one tick of
	online time (Progression.trainingTick, clamped to TICK: a hitch never over-credits): full
	rate while standing on the station of a stat they train (in the Hunters' Outpost), half
	(Training elsewhere rate) anywhere else — in a match, around camp. Nothing ever counts
	time a player wasn't in the server (online only, #391). Every Training bank (s) the
	changed saves are written (Progression.bankTraining); leaving and shutdown save as usual.

	IDLE. We never fight Roblox's 20-minute idle kick (no VirtualUser or fake input): the kick
	just ends that session, and at most one bank interval of training is lost.

	REQUESTS (the "Training" RemoteFunction):
	  ("start")            E at a station: train the stat of the station you stand on (the
	                       server reads where you are; the client never names the stat)
	  ("finish", stat)     Amber finishes that stat's level (between matches, once priced)
	  ("trainskip", min)   Studio only (StudioOnly trainSkip): that many full-rate minutes
	Server -> client: the "TrainingLevel" RemoteEvent (stat, level) when a level is reached.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local OutpostRules = require(Shared:WaitForChild("Outpost"))
local StudioOnly = require(Shared:WaitForChild("StudioOnly"))

local Progression = require(script.Parent.Progression)

local Training = {}

local TICK = 1 -- s of server time per training tick (engine cadence; the clamp in Shared/Training)

-- The station this player stands on, or nil: only in the Hunters' Outpost, alive.
function Training.stationOf(player: Player): string?
	if player:GetAttribute("InOutpost") ~= true then
		return nil
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return OutpostRules.stationAt(root.Position)
end

local function request(player: Player, action: unknown, a: unknown): (boolean, string)
	if action == "start" then
		local stat = Training.stationOf(player)
		if not stat then
			return false, "Stand on a training station"
		end
		return Progression.trainStart(player, stat)
	elseif action == "finish" then
		return Progression.trainFinish(player, a)
	elseif action == "trainskip" then
		if not StudioOnly.allowed(RunService:IsStudio(), "trainSkip") then
			return false, "Studio only"
		end
		return Progression.trainSkip(player, tonumber(a)), "Studio: training skipped (saving off)"
	end
	return false, "Unknown request"
end

function Training.init(remotes: Folder)
	local levelEvent = Instance.new("RemoteEvent")
	levelEvent.Name = "TrainingLevel"
	levelEvent.Parent = remotes
	local fn = Instance.new("RemoteFunction")
	fn.Name = "Training"
	fn.OnServerInvoke = function(player: Player, action: unknown, a: unknown)
		local ok, success, message = pcall(request, player, action, a)
		if not ok then
			warn(`[Training] {tostring(action)} from {player.Name} failed: {success}`)
			return false, "Something went wrong"
		end
		return success, message
	end
	fn.Parent = remotes

	task.spawn(function()
		local last = os.clock()
		local sinceBank = 0
		while true do
			task.wait(TICK)
			local now = os.clock()
			local dt = now - last
			last = now
			for _, player in Players:GetPlayers() do
				local ok, leveled = pcall(Progression.trainingTick, player, dt, Training.stationOf(player), TICK)
				if ok then
					for _, stat in leveled do
						levelEvent:FireClient(player, stat, player:GetAttribute(`TrainLevel_{stat}`))
					end
				else
					warn(`[Training] tick for {player.Name} failed: {leveled}`)
				end
			end
			sinceBank += math.min(dt, TICK)
			if sinceBank >= Config.Tuning.TrainingBankS then
				sinceBank = 0
				Progression.bankTraining()
			end
		end
	end)
end

return Training
