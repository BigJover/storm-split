--[[
	Scoreboard: per-player pops (kills credited to towers they built), shown on
	Roblox's built-in player list through leaderstats.

	Co-op uses it as a scoreboard; battle royale (VISION.md) will rank by it.

	Also shows each player's mastery with their current hero next to their
	name — the design doc's visible badge. Read from the Hero and Mastery_*
	player attributes that Hero and Progression publish. And each hunter's player
	level badge and title (PLAN T58), on the home screen and in a match alike, from
	the PlayerXp and Equip_title attributes Progression publishes.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local PlayerLevel = require(Shared:WaitForChild("PlayerLevel"))
local Cosmetics = require(Shared:WaitForChild("Cosmetics"))

local Scoreboard = {}

local pops: { [Player]: IntValue } = {}

local function setUp(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local value = Instance.new("IntValue")
	value.Name = Theme.Bones -- display name only (DECISIONS #130); per match, never saved
	value.Parent = stats
	local badge = Instance.new("IntValue")
	badge.Name = "Mastery"
	badge.Parent = stats
	local level = Instance.new("IntValue")
	level.Name = Theme.PlayerLevel -- never "Lv": that's the hunter's in-match level (DECISIONS #118)
	level.Parent = stats
	local title = Instance.new("StringValue")
	title.Name = "Title"
	title.Parent = stats
	stats.Parent = player
	pops[player] = value
	local function refreshLevel()
		local xp = player:GetAttribute("PlayerXp")
		level.Value = PlayerLevel.level(if type(xp) == "number" then xp else 0)
		title.Value = Cosmetics.titleOf(function(name)
			return player:GetAttribute(name)
		end) or ""
	end
	player.AttributeChanged:Connect(function(name)
		if name == "PlayerXp" or name == "Equip_title" then
			refreshLevel()
		end
	end)
	refreshLevel()

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

-- This hunter's Bones this match (0 if they have no board entry).
function Scoreboard.bones(player: Player): number
	local value = pops[player]
	return if value then value.Value else 0
end

function Scoreboard.addPop(player: Player)
	local value = pops[player]
	if value then
		value.Value += 1
	end
end

return Scoreboard
