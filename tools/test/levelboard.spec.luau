--[[
	Shared/LevelBoard: the level leaderboard (PLAN round 4 T58, DECISIONS #122). The pure
	merge / sort / fallback, your own row, and the server's tick against a fake store: at
	most one request round a minute, one warning for a run of failures, never an error.
]]

local LevelBoard = require(src.shared.LevelBoard)
local PlayerLevel = require(src.shared.PlayerLevel)
local ProfileScreen = require(src.shared.ProfileScreen)

local function row(userId: number, xp: number, name: string?): LevelBoard.Row
	return { userId = userId, name = name or `p{userId}`, xp = xp }
end

test("no world board (unpublished, Studio, a failure): this server, with the note", function()
	local view = LevelBoard.view(nil, { row(1, 500), row(2, 9000), row(3, 0) }, 3)
	eq(view.mode, "server", "mode")
	eq(view.title, "This server", "title")
	eq(view.note, "The world board goes live when the game is published.", "the one-line note")
	eq(#view.rows, 3, "everyone here")
	eq(view.rows[1].userId, 2, "most XP first")
	eq(view.rows[3].userId, 3, "least last")
	eq(view.rows[3].self, true, "your row")
	eq(view.mine and view.mine.rank, 3, "ranked")
end)

test("world board: the top 50 by XP, ties by user id, live XP beats a stale store value", function()
	local world = {}
	for i = 1, 60 do
		table.insert(world, row(100 + i, 1000 * i))
	end
	table.insert(world, row(5, 1000)) -- ties with user 101
	local here = { row(101, 70000, "Live") } -- 101 just won a match: past everyone
	local view = LevelBoard.view(world, here, 999)
	eq(view.mode, "world", "mode")
	eq(view.note, nil, "no note")
	eq(view.rows[1].userId, 101, "live XP counts")
	eq(view.rows[1].name, "Live", "with the live name")
	eq(view.rows[1].xp, 70000, "and the live XP")
	eq(view.rows[50].rank, 50, "fifty ranked")
	eq(#view.rows, 50, "no own row: you aren't on it at all")
	local stale = LevelBoard.view({ row(7, 900), row(8, 900) }, { row(8, 100) }, 8)
	eq(stale.rows[2].xp, 900, "a lower live value never lowers the store's")
	eq(stale.rows[1].userId, 7, "equal XP: the lower user id first")
end)

test("your own row is always there: unranked under the top 50 when you're outside it", function()
	local world = {}
	for i = 1, 50 do
		table.insert(world, row(i, 100000 + i))
	end
	local view = LevelBoard.view(world, { row(777, 300) }, 777)
	eq(#view.rows, 51, "50 + yours")
	eq(view.rows[51].userId, 777, "yours at the bottom")
	eq(view.rows[51].rank, nil, "no rank")
	eq(LevelBoard.rankText(view.rows[51]), "–", "shown as –")
	eq(LevelBoard.rankText(view.rows[1]), "#1", "#1")
	local inside = LevelBoard.view(world, { row(3, 100003) }, 3)
	eq(#inside.rows, 50, "inside the top: not twice")
end)

test("the store's page: bad entries are skipped", function()
	local rows = LevelBoard.fromStore({
		{ key = "123", value = 5000 },
		{ key = "abc", value = 10 },
		{ key = "-4", value = 10 },
		{ key = "12.5", value = 10 },
		{ key = "9", value = "lots" },
		"junk",
	})
	eq(#rows, 1, "one good row")
	eq(rows[1].userId, 123, "its id")
	eq(#LevelBoard.fromStore(nil), 0, "no page")
end)

-- A fake OrderedDataStore that counts requests and fails on demand.
local function fakeStore()
	local s = { reads = 0, writes = 0, failing = false, data = {} :: { [string]: number } }
	s.store = {
		write = function(key: string, xp: number)
			s.writes += 1
			if s.failing then
				error("503 DataStore unavailable")
			end
			s.data[key] = xp
		end,
		read = function(count: number)
			s.reads += 1
			if s.failing then
				error("503 DataStore unavailable")
			end
			local page = {}
			for key, value in s.data do
				table.insert(page, { key = key, value = value })
			end
			table.sort(page, function(a, b)
				return a.value > b.value
			end)
			while #page > count do
				table.remove(page)
			end
			return page
		end,
		nameOf = function(userId: number)
			return `n{userId}`
		end,
	}
	return s
end

test("at most one request round a minute, however often the server ticks", function()
	local fake = fakeStore()
	local cache = LevelBoard.newCache()
	local logs = {}
	local function log(text: string)
		table.insert(logs, text)
	end
	LevelBoard.queue(cache, 42, 5000)
	for second = 0, 179, 5 do -- three minutes of 5-second ticks
		LevelBoard.step(cache, fake.store, second, log)
	end
	eq(fake.reads, 3, "one read a minute")
	eq(fake.writes, 1, "the one change written once")
	eq(#logs, 0, "no warnings")
	eq(cache.world and cache.world[1].name, "n42", "the board has the name")
	LevelBoard.queue(cache, 42, 5000)
	LevelBoard.step(cache, fake.store, 180, log)
	eq(fake.writes, 1, "the same XP isn't written again")
	eq(LevelBoard.step(cache, nil, 1000, log), false, "no store (unpublished): no requests at all")
end)

test("writes only on change (#183): no write when XP is unchanged, one when it moves", function()
	local fake = fakeStore()
	local cache = LevelBoard.newCache()
	local logs = {}
	local function log(text: string)
		table.insert(logs, text)
	end
	LevelBoard.queue(cache, 7, 900)
	LevelBoard.step(cache, fake.store, 0, log)
	eq(fake.writes, 1, "the first XP is written")
	for minute = 1, 5 do -- match ends / leaves with the same XP
		LevelBoard.queue(cache, 7, 900)
		LevelBoard.step(cache, fake.store, minute * 60, log)
	end
	eq(fake.writes, 1, "unchanged XP: no further write")
	eq(next(cache.pending), nil, "and nothing left pending")
	LevelBoard.queue(cache, 7, 1200)
	LevelBoard.step(cache, fake.store, 400, log)
	eq(fake.writes, 2, "changed XP: written")
	eq(#logs, 0, "no warnings")
end)

test("a zero request budget skips the write without error and retries next tick (#183)", function()
	local fake = fakeStore()
	local left = 0
	local asked = 0
	fake.store.budget = function()
		asked += 1
		return left
	end
	local cache = LevelBoard.newCache()
	local logs = {}
	local function log(text: string)
		table.insert(logs, text)
	end
	LevelBoard.queue(cache, 42, 5000)
	LevelBoard.queue(cache, 43, 6000)
	eq(LevelBoard.step(cache, fake.store, 0, log), true, "the tick runs")
	ok(asked > 0, "the budget is checked before writing")
	eq(fake.writes, 0, "no budget: no write")
	eq(fake.reads, 1, "the read still happens")
	eq(cache.pending[42], 5000, "held for the next tick")
	eq(cache.pending[43], 6000, "both held")
	eq(#logs, 0, "skipping isn't a failure: no warning")
	fake.store.budget = function()
		error("budget check broke")
	end
	LevelBoard.step(cache, fake.store, 60, log) -- never throws
	eq(fake.writes, 0, "a failed budget check writes nothing either")
	fake.store.budget = function()
		return 10
	end
	LevelBoard.step(cache, fake.store, 120, log)
	eq(fake.writes, 2, "budget back: both written")
	eq(fake.data["42"], 5000, "the held XP")
	eq(next(cache.pending), nil, "nothing left pending")
	eq(LevelBoard.canWrite(fake.store), true, "budget above 0")
	fake.store.budget = function()
		return 0
	end
	eq(LevelBoard.canWrite(fake.store), false, "budget 0")
end)

test("a failing store: one warning, no error, This server, and it recovers", function()
	local fake = fakeStore()
	fake.failing = true
	local cache = LevelBoard.newCache()
	local logs = {}
	local function log(text: string)
		table.insert(logs, text)
	end
	LevelBoard.queue(cache, 42, 5000)
	for second = 0, 600, 5 do
		LevelBoard.step(cache, fake.store, second, log) -- never throws
	end
	eq(#logs, 1, "one warning for the whole run of failures")
	eq(fake.reads, 11, "still at most one read a minute while failing")
	eq(cache.world, nil, "no world board")
	eq(LevelBoard.view(cache.world, { row(42, 5000) }, 42).mode, "server", "players see This server")
	fake.failing = false
	LevelBoard.step(cache, fake.store, 660, log)
	ok(cache.world ~= nil, "back once the store answers")
	eq(fake.data["42"], 5000, "the held write went through")
	fake.failing = true
	LevelBoard.step(cache, fake.store, 720, log)
	eq(#logs, 2, "a new run of failures warns once more")
	eq(cache.world, nil, "a failed read drops the world board it had: This server again")
end)

test("the level badge: the level and its band; the row text", function()
	eq(LevelBoard.band(1), 1, "1")
	eq(LevelBoard.band(99), 1, "99")
	eq(LevelBoard.band(100), 2, "100")
	eq(LevelBoard.band(150), 3, "150")
	eq(LevelBoard.band(200), 4, "200")
	eq(LevelBoard.band(5000), 4, "5000")
	local line = ProfileScreen.boardLine({ userId = 1, name = "Ava", xp = PlayerLevel.xpFor(30), rank = 3, self = true }, "Trailblazer")
	eq(line.rank, "#3", "rank")
	eq(line.level, 30, "badge level")
	eq(line.title, "Trailblazer", "title")
	eq(line.self, true, "self")
	eq(ProfileScreen.boardLine({ userId = 2, name = "B", xp = 0 }, nil).title, "", "no title")
end)

test("the player list's title comes from Equip_title, and only a real title shows", function()
	local Cosmetics = require(src.shared.Cosmetics)
	local function attrs(map: { [string]: any })
		return function(name: string)
			return map[name]
		end
	end
	eq(Cosmetics.titleOf(attrs({ Equip_title = "TITLE_30" })), "Trailblazer", "a title")
	eq(Cosmetics.titleOf(attrs({ Equip_title = "TITLE_20" })), "Trapper", "trapper before trailblazer (#187)")
	eq(Cosmetics.titleOf(attrs({ Equip_title = "HAT_BUSH" })), nil, "a hat isn't a title")
	eq(Cosmetics.titleOf(attrs({ Equip_title = 5 })), nil, "junk")
	eq(Cosmetics.titleOf(attrs({})), nil, "none worn")
	ok(not string.find(Cosmetics.titleOf(attrs({ Equip_title = "TITLE_ELDER_250" })) or "", "{n}", 1, true), "past 200: the level filled in")
end)
