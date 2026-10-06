--[[
	LevelBoard: the level leaderboard (PLAN round 4 T58, DECISIONS #122). The only thing
	that talks to the leaderboard's OrderedDataStore. The rules — the tick (writes, one
	read, one warning per run of failures), merge, sort, fallback and your own row — are
	Shared/LevelBoard, spec-tested with a fake store.

	Published: at most one tick every REFRESH_SECONDS (60) writes the player XP of hunters
	whose XP changed and whose save is live (SaveStatus "saved": never a session-only or
	J test profile), then reads the top 50 once and caches it. A failed read shows "This
	server" until the store answers again. Unpublished or in Studio the store is never
	touched: one warning at start, and the "This server" board with its note.

	Players ask with the "LevelBoard" RemoteFunction; the answer comes from the cache and
	the players here, never from a store request. Player XP itself is Server/Progression's;
	this only reads the PlayerXp and SaveStatus attributes it publishes.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Rules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("LevelBoard"))

local LevelBoard = {}

local cache = Rules.newCache()
local store: Rules.Store? = nil
local names: { [number]: string } = {} -- userId -> name, looked up once

local function nameOf(userId: number): string
	local player = Players:GetPlayerByUserId(userId)
	if player then
		return player.DisplayName
	end
	local known = names[userId]
	if not known then
		local ok, name = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)
		known = if ok and type(name) == "string" then name else "Hunter"
		names[userId] = known
	end
	return known
end

local function queue(player: Player)
	local xp = player:GetAttribute("PlayerXp")
	if store and player:GetAttribute("SaveStatus") == "saved" and type(xp) == "number" then
		Rules.queue(cache, player.UserId, xp)
	end
end

-- The board as `player` sees it (Shared/LevelBoard.View).
local function viewFor(player: Player): Rules.View
	local here = {}
	for _, other in Players:GetPlayers() do
		local xp = other:GetAttribute("PlayerXp")
		table.insert(here, { userId = other.UserId, name = other.DisplayName, xp = if type(xp) == "number" then xp else 0 })
	end
	return Rules.view(cache.world, here, player.UserId)
end

function LevelBoard.init(remotes: Folder)
	if RunService:IsStudio() or game.PlaceId == 0 then
		warn("[LevelBoard] Not published (or in Studio): the level leaderboard shows this server only")
	else
		local ok, result = pcall(function()
			return DataStoreService:GetOrderedDataStore(Rules.STORE)
		end)
		if ok then
			local ordered: OrderedDataStore = result
			store = {
				write = function(key: string, xp: number)
					ordered:SetAsync(key, xp)
				end,
				read = function(count: number): any
					return ordered:GetSortedAsync(false, count):GetCurrentPage()
				end,
				nameOf = nameOf,
			}
		else
			warn(`[LevelBoard] No leaderboard store, so it shows this server only: {result}`)
		end
	end

	local request = Instance.new("RemoteFunction")
	request.Name = "LevelBoard"
	-- () -> Shared/LevelBoard.View. Never errors: the worst case is "This server".
	request.OnServerInvoke = function(player: Player)
		local ok, view = pcall(viewFor, player)
		if ok then
			return view
		end
		warn(`[LevelBoard] view for {player.Name} failed: {view}`)
		return Rules.view(nil, {}, player.UserId)
	end
	request.Parent = remotes

	local function watch(player: Player)
		player.AttributeChanged:Connect(function(name)
			if name == "PlayerXp" or name == "SaveStatus" then
				queue(player)
			end
		end)
		queue(player)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end

	if store then
		task.spawn(function()
			while true do
				Rules.step(cache, store, os.clock(), warn)
				task.wait(5) -- step itself runs at most once a minute
			end
		end)
	end
end

return LevelBoard
