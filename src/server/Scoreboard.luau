--[[
	Scoreboard: per-player pops (kills credited to towers they built), shown on
	Roblox's built-in player list through leaderstats.

	Co-op uses it as a scoreboard; battle royale (VISION.md) will rank by it.

	Four columns (PLAN T83, DECISIONS #233; Shared/PanelRules.playerListColumns): Bones,
	the player level, Trophies and the Title. Mastery left the list (it stays on the
	Mastery screen, Profile and the hero card). Each hunter's player
	level badge and title (PLAN T58), on the home screen and in a match alike, from
	the PlayerXp and Equip_title attributes Progression publishes. And their ranked
	Trophies with the arena badge (PLAN T81, Shared/TrophyBoard.badge).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerLevel = require(Shared:WaitForChild("PlayerLevel"))
local Cosmetics = require(Shared:WaitForChild("Cosmetics"))
local TrophyBoard = require(Shared:WaitForChild("TrophyBoard"))
local PanelRules = require(Shared:WaitForChild("PanelRules"))

local Scoreboard = {}

local pops: { [Player]: IntValue } = {}

local function setUp(player: Player)
	-- The four player-list columns, created in Shared/PanelRules' order (PLAN T83,
	-- DECISIONS #233): Bones, Level, Trophies, Title. Mastery left the list (#233).
	local columns = PanelRules.playerListColumns()
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local value = Instance.new("IntValue")
	value.Name = columns[1] -- Bones: display name only (DECISIONS #130); per match, never saved
	value.Parent = stats
	local level = Instance.new("IntValue")
	level.Name = columns[2] -- never "Lv": that's the hunter's in-match level (DECISIONS #118)
	level.Parent = stats
	-- Ranked Trophies and the arena badge (PLAN T81): "320 · Raptor Ridge", from the
	-- Trophies attribute Progression publishes.
	local trophies = Instance.new("StringValue")
	trophies.Name = columns[3]
	trophies.Parent = stats
	local title = Instance.new("StringValue")
	title.Name = columns[4]
	title.Parent = stats
	stats.Parent = player
	pops[player] = value
	local function refreshTrophies()
		local count = player:GetAttribute("Trophies")
		trophies.Value = TrophyBoard.badge(if type(count) == "number" then count else 0)
	end
	player:GetAttributeChangedSignal("Trophies"):Connect(refreshTrophies)
	refreshTrophies()
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
