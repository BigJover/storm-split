--[[
	LevelBoard: the level leaderboard (PLAN round 4 T58, DECISIONS #122). The only thing
	that talks to the leaderboard's OrderedDataStore. The rules — the tick (writes, one
	read, one warning per run of failures), merge, sort, fallback and your own row — are
	Shared/LevelBoard, spec-tested with a fake store.

	Published: at most one tick every REFRESH_SECONDS (60) writes the player XP of hunters
	whose XP changed since their last write (and only while the write budget is above
	0, DECISIONS #183) and whose save is live (SaveStatus "saved": never a session-only or
	J test profile), then reads the top 50 once and caches it. A failed read shows "This
	server" until the store answers again. Unpublished or in Studio the store is never
	touched: one warning at start, and the "This server" board with its note.

	Players ask with the "LevelBoard" RemoteFunction; the answer comes from the cache and
	the players here, never from a store request. Player XP itself is Server/Progression's;
	this only reads the PlayerXp and SaveStatus attributes it publishes.

	start() runs one such board for any player attribute: Server/TrophyBoard (PLAN T81)
	runs the Trophy board through it on its own store, remote and cache.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Rules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("LevelBoard"))

local LevelBoard = {}

export type Spec = {
	store: string, -- the OrderedDataStore's name
	attribute: string, -- the player attribute Progression publishes ("PlayerXp", "Trophies")
	remote: string, -- the RemoteFunction players ask
	label: string, -- for warnings
	live: boolean?, -- the score can drop: this server's saved hunters count with their live value
}

local names: { [number]: string } = {} -- userId -> name, looked up once (shared by every board)

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

function LevelBoard.start(remotes: Folder, spec: Spec)
	local cache = Rules.newCache()
	local store: Rules.Store? = nil

	local function queue(player: Player)
		local value = player:GetAttribute(spec.attribute)
		if store and player:GetAttribute("SaveStatus") == "saved" and type(value) == "number" then
			-- The first time the save is live, its value is the one read at join: seed it as
			-- written so an unchanged hunter costs no write (PLAN T68, #192).
			Rules.seed(cache, player.UserId, value)
			Rules.queue(cache, player.UserId, value)
		end
	end

	-- The board as `player` sees it (Shared/LevelBoard.View).
	local function viewFor(player: Player): Rules.View
		local here = {}
		for _, other in Players:GetPlayers() do
			local value = other:GetAttribute(spec.attribute)
			table.insert(here, {
				userId = other.UserId,
				name = other.DisplayName,
				xp = if type(value) == "number" then value else 0,
				-- a session-only profile never overrides the stored score (#216's rule for saves)
				live = spec.live == true and (store == nil or other:GetAttribute("SaveStatus") == "saved"),
			})
		end
		return Rules.view(cache.world, here, player.UserId)
	end

	if RunService:IsStudio() or game.PlaceId == 0 then
		warn(`[LevelBoard] Not published (or in Studio): the {spec.label} shows this server only`)
	else
		local ok, result = pcall(function()
			return DataStoreService:GetOrderedDataStore(spec.store)
		end)
		if ok then
			local ordered: OrderedDataStore = result
			store = {
				write = function(key: string, value: number)
					ordered:SetAsync(key, value)
				end,
				budget = function(): number
					return DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.SetIncrementSortedAsync)
				end,
				read = function(count: number): any
					return ordered:GetSortedAsync(false, count):GetCurrentPage()
				end,
				nameOf = nameOf,
			}
		else
			warn(`[LevelBoard] No store for the {spec.label}, so it shows this server only: {result}`)
		end
	end

	local request = Instance.new("RemoteFunction")
	request.Name = spec.remote
	-- () -> Shared/LevelBoard.View. Never errors: the worst case is "This server".
	request.OnServerInvoke = function(player: Player)
		local ok, view = pcall(viewFor, player)
		if ok then
			return view
		end
		warn(`[LevelBoard] {spec.label} view for {player.Name} failed: {view}`)
		return Rules.view(nil, {}, player.UserId)
	end
	request.Parent = remotes

	local function watch(player: Player)
		player.AttributeChanged:Connect(function(name)
			if name == spec.attribute or name == "SaveStatus" then
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
		local live = store
		task.spawn(function()
			while true do
				Rules.step(cache, live, os.clock(), warn)
				task.wait(5) -- step itself runs at most once a minute
			end
		end)
	end
end

-- The level leaderboard (PLAN T58).
function LevelBoard.init(remotes: Folder)
	LevelBoard.start(remotes, { store = Rules.STORE, attribute = "PlayerXp", remote = "LevelBoard", label = "level leaderboard" })
end

return LevelBoard
