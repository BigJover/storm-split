--[[
	Scoreboard: per-player pops (kills credited to towers they built), shown on
	Roblox's built-in player list through leaderstats.

	Co-op uses it as a scoreboard; battle royale (VISION.md) will rank by it.

	Also shows each player's mastery with their current hero next to their
	name — the design doc's visible badge. Read from the Hero and Mastery_*
	player attributes that Hero and Progression publish.
]]

local Players = game:GetService("Players")

local Scoreboard = {}

local pops: { [Player]: IntValue } = {}

local function setUp(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local value = Instance.new("IntValue")
	value.Name = "Bones" -- display name only (DECISIONS #130); per match, never saved
	value.Parent = stats
	local badge = Instance.new("IntValue")
	badge.Name = "Mastery"
	badge.Parent = stats
	stats.Parent = player
	pops[player] = value

	local function refreshBadge()
		local hero = player:GetAttribute("Hero")
		badge.Value = if typeof(hero) == "string" and hero ~= "" then player:GetAttribute(`Mastery_{hero}`) or 0 else 0
	end
	player.AttributeChanged:Connect(function(name)
		if name == "Hero" or string.sub(name, 1, 8) == "Mastery_" then
			refreshBadge()
		end
	end)
	refreshBadge()
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

-- Pops count per match.
function Scoreboard.resetPops()
	for _, value in pops do
		value.Value = 0
	end
end

function Scoreboard.addPop(player: Player)
	local value = pops[player]
	if value then
		value.Value += 1
	end
end

return Scoreboard
