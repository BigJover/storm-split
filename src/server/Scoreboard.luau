--[[
	Scoreboard: per-player pops (kills credited to towers they built), shown on
	Roblox's built-in player list through leaderstats.

	Co-op uses it as a scoreboard; battle royale (VISION.md) will rank by it.
]]

local Players = game:GetService("Players")

local Scoreboard = {}

local pops: { [Player]: IntValue } = {}

local function setUp(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local value = Instance.new("IntValue")
	value.Name = "Pops"
	value.Parent = stats
	stats.Parent = player
	pops[player] = value
end

function Scoreboard.init()
	Players.PlayerAdded:Connect(setUp)
	for _, player in Players:GetPlayers() do
		if not pops[player] then
			setUp(player)
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		pops[player] = nil
	end)
end

function Scoreboard.addPop(player: Player)
	local value = pops[player]
	if value then
		value.Value += 1
	end
end

return Scoreboard
