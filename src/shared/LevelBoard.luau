--[[
	The level leaderboard's rules (PLAN round 4 T58, DECISIONS #122). Pure — no services,
	no clock — so tools/test/levelboard.spec.luau runs them headlessly. Server/LevelBoard
	talks to the OrderedDataStore and calls these; the Profile screen's Leaderboard tab
	draws what `view` returns.

	  World board    published: the top TOP players by player XP (ranked by XP, not
	                 level, so ties break fairly), read at most once every
	                 REFRESH_SECONDS per server and cached. Players in this server
	                 count with their live XP, so a match just won shows at once.
	  This server    unpublished, Studio, or any store failure: everyone here, with the
	                 one-line NOTE. Never an error, never blocks play.
	  Your row       always shown: in the list, or under it with no rank when you're
	                 outside the top.

	A row's cosmetics (name colour, banner, title) are only known for players in this
	server (their Equip_ attributes); the store keeps XP alone.
]]

local PlayerLevel = require(script.Parent.PlayerLevel)

local LevelBoard = {}

LevelBoard.TOP = 50
LevelBoard.REFRESH_SECONDS = 60
LevelBoard.STORE = "DinoHuntersPlayerXp_v1"
LevelBoard.WORLD = "World top 50"
LevelBoard.SERVER = "This server"
LevelBoard.NOTE = "The world board goes live when the game is published." -- DECISIONS #122
LevelBoard.LOADING = "Checking the board…"
LevelBoard.TAB = "Leaderboard"

-- `xp` is the score the board ranks by: player XP here, Trophies on the Trophy board
-- (Shared/TrophyBoard, PLAN T81). `live` (a row from this server): its value replaces the
-- store's, for a score that can go down (Trophies); without it the higher one stands.
export type Row = { userId: number, name: string, xp: number, rank: number?, self: boolean?, live: boolean? }
export type View = { mode: "world" | "server", title: string, note: string?, rows: { Row }, mine: Row? }

-- May the server ask the store again? `lastAt` = when it last asked (nil = never).
function LevelBoard.due(lastAt: number?, now: number): boolean
	return lastAt == nil or now - lastAt >= LevelBoard.REFRESH_SECONDS
end

-- The store's key for a player.
function LevelBoard.key(userId: number): string
	return tostring(math.floor(userId))
end

-- One page of GetSortedAsync ({ key, value } entries) -> rows without names. Anything
-- that isn't a whole positive user id with a whole XP is skipped.
function LevelBoard.fromStore(page: unknown): { Row }
	local out = {}
	if type(page) ~= "table" then
		return out
	end
	for _, entry in page :: { any } do
		if type(entry) == "table" then
			local id = tonumber(entry.key)
			local xp = PlayerLevel.whole(entry.value)
			if id and id > 0 and id == math.floor(id) and type(entry.value) == "number" then
				table.insert(out, { userId = id, name = "", xp = xp })
			end
		end
	end
	return out
end

local function before(a: Row, b: Row): boolean
	if a.xp ~= b.xp then
		return a.xp > b.xp
	end
	return a.userId < b.userId -- a steady order for equal XP
end

-- The board one player sees. `world` = the cached store rows (nil = no world board:
-- unpublished, Studio, or the store failed); `here` = the players in this server with
-- their live XP; `me` = the viewer's user id.
function LevelBoard.view(world: { Row }?, here: { Row }, me: number): View
	local merged: { [number]: Row } = {}
	local function add(row: Row)
		local known = merged[row.userId]
		if not known then
			merged[row.userId] = { userId = row.userId, name = row.name, xp = PlayerLevel.whole(row.xp) }
		elseif row.live then
			known.xp = PlayerLevel.whole(row.xp) -- this server's own value (a score that can drop)
			if row.name ~= "" then
				known.name = row.name
			end
		else
			known.xp = math.max(known.xp, PlayerLevel.whole(row.xp)) -- live XP beats a stale store value
			if row.name ~= "" then
				known.name = row.name
			end
		end
	end
	if world then
		for _, row in world do
			add(row)
		end
	end
	for _, row in here do
		add(row)
	end
	local all = {}
	for _, row in merged do
		table.insert(all, row)
	end
	table.sort(all, before)
	local limit = if world then LevelBoard.TOP else #all
	local rows, mine = {}, nil
	for i, row in all do
		row.self = row.userId == me
		if i <= limit then
			row.rank = i
			table.insert(rows, row)
		end
		if row.self then
			mine = row
		end
	end
	if mine and mine.rank == nil then
		table.insert(rows, mine) -- your own row, always, unranked when outside the top
	end
	return {
		mode = if world then "world" else "server",
		title = if world then LevelBoard.WORLD else LevelBoard.SERVER,
		note = if world then nil else LevelBoard.NOTE,
		rows = rows,
		mine = mine,
	}
end

-- The server's side, with the store passed in so a spec can fake it --------------------

-- What a store must do. Any may throw; `step` catches everything. `budget` = the
-- requests the store may still make for a write now (DECISIONS #183); nil = no limit.
export type Store = {
	write: (key: string, xp: number) -> (),
	budget: (() -> number)?,
	read: (count: number) -> any, -- a page of { key, value }
	nameOf: (userId: number) -> string,
}
export type Cache = {
	world: { Row }?, -- the last good top TOP, nil = no world board now
	lastTick: number?,
	failing: boolean, -- warned about the current run of failures already
	pending: { [number]: number }, -- userId -> XP to write on the next tick
	written: { [number]: number }, -- userId -> XP last written
}

function LevelBoard.newCache(): Cache
	return { world = nil, lastTick = nil, failing = false, pending = {}, written = {} }
end

-- A hunter's XP to write on the next tick (only call for a save that loaded). 0 is only
-- written over a value this server wrote or seeded (Trophies can drop to 0; XP can't).
function LevelBoard.queue(cache: Cache, userId: number, xp: number)
	if xp > 0 or cache.written[userId] ~= nil then
		cache.pending[userId] = PlayerLevel.whole(xp)
	end
end

-- A hunter's XP as loaded at join (profile load) counts as already written (PLAN T68,
-- DECISIONS #192): the store holds it from an earlier session, so an unchanged hunter's
-- first write of this session is skipped. Only the first seed counts: a later value
-- is a change, not a join.
function LevelBoard.seed(cache: Cache, userId: number, xp: number)
	if cache.written[userId] == nil and xp > 0 then
		cache.written[userId] = PlayerLevel.whole(xp)
	end
end

-- May the store write now? False when its request budget is 0 (or the check fails).
function LevelBoard.canWrite(store: Store): boolean
	if not store.budget then
		return true
	end
	local ok, left = pcall(store.budget)
	return ok and type(left) == "number" and left > 0
end

-- One tick, if one is due: write the XP that changed, read the top TOP once. Never
-- throws. Writes only XP that changed since its last write, each after a budget check
-- (none left: skip, retry next tick, no warning). A failure warns once (through `log`) until a tick works again; a failed read
-- drops the world board, so players see "This server". Returns whether it ran.
function LevelBoard.step(cache: Cache, store: Store?, now: number, log: (string) -> ()): boolean
	if not store or not LevelBoard.due(cache.lastTick, now) then
		return false
	end
	cache.lastTick = now
	local function failed(what: string, err: any)
		if not cache.failing then
			cache.failing = true
			log(`[LevelBoard] {what} failed (the board shows this server while reads fail; no more warnings until a tick works): {err}`)
		end
	end
	for userId, xp in cache.pending do
		if cache.written[userId] == xp then
			cache.pending[userId] = nil -- unchanged since the last write: no request
		elseif not LevelBoard.canWrite(store) then
			break -- no budget left: everything pending waits for the next tick
		else
			cache.pending[userId] = nil
			local ok, err = pcall(store.write, LevelBoard.key(userId), xp)
			if ok then
				cache.written[userId] = xp
			else
				cache.pending[userId] = xp -- try again next tick
				failed("Writing the board", err)
			end
		end
	end
	local ok, page = pcall(store.read, LevelBoard.TOP)
	if not ok then
		cache.world = nil
		failed("Reading the board", page)
		return true
	end
	local rows = LevelBoard.fromStore(page)
	for _, row in rows do
		local named, name = pcall(store.nameOf, row.userId)
		row.name = if named and type(name) == "string" then name else "Hunter"
	end
	cache.world = rows
	cache.failing = false
	return true
end

-- "#3", or "–" for your own row outside the top.
function LevelBoard.rankText(row: Row): string
	return if row.rank then `#{row.rank}` else "–"
end

-- The level badge's band (DECISIONS #121, the free badge frame): 1 below 100, 2 for
-- 100-149, 3 for 150-199, 4 from 200.
function LevelBoard.band(level: number): number
	if level >= 200 then
		return 4
	elseif level >= 150 then
		return 3
	elseif level >= 100 then
		return 2
	end
	return 1
end

return LevelBoard
