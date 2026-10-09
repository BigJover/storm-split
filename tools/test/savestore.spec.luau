--[[
	DataStore hardening (PLAN T90): Shared/SaveStore + the session lock in Shared/Profile,
	against a fake DataStore (throttling, UpdateAsync conflicts, a failing store), plus the
	escrow / leaver / board-budget rules a live server depends on.
]]
local fs = require("@lune/fs")
local SaveStore = require(src.shared.SaveStore)
local Profile = require(src.shared.Profile)
local Stakes = require(src.shared.Stakes)
local Trophies = require(src.shared.Trophies)
local LevelBoard = require(src.shared.LevelBoard)

local NOON = 1_760_000_000
local function first(_n: number): number
	return 1
end

-- A fake DataStore. `failing` = requests that throw before the next one works; `budget`
-- = requests left (nil = unlimited); `race` = another server's write that lands between
-- UpdateAsync reading a key and committing it, so the transform runs again (Roblox does).
local function fake()
	local f = {
		data = {} :: { [string]: any },
		requests = 0,
		writes = 0,
		failing = 0,
		budgetLeft = nil :: number?,
		race = nil :: ((old: any) -> any)?,
		clock = NOON,
		waits = {} :: { number },
	}
	f.store = {
		update = function(key: string, transform: (any) -> any): any
			f.requests += 1
			if f.failing > 0 then
				f.failing -= 1
				error("502: DataStore request was throttled")
			end
			local value = transform(f.data[key])
			if f.race then
				f.data[key] = f.race(f.data[key])
				f.race = nil
				value = transform(f.data[key]) -- UpdateAsync retries on a conflict
			end
			if value ~= nil then
				f.data[key] = value
				f.writes += 1
			end
			return f.data[key]
		end,
		budget = function(): number
			return if f.budgetLeft == nil then math.huge else f.budgetLeft
		end,
	}
	f.env = {
		now = function()
			return f.clock
		end,
		wait = function(seconds: number)
			table.insert(f.waits, seconds)
			f.clock += seconds
		end,
	}
	return f
end

local KEY = "player_1"

test("T90: a new player's load takes the lock and finds nothing", function()
	local f = fake()
	local status, raw = SaveStore.load(f.store, KEY, "A", f.env)
	eq(status, "ok")
	eq(raw, nil, "a new player")
	eq(f.data[KEY].lock.session, "A", "the lock is stored")
end)

test("T90: a failed load is reported, never written, and leaves the save alone", function()
	local f = fake()
	f.data[KEY] = { cores = 900 }
	f.failing = 99
	local status, err = SaveStore.load(f.store, KEY, "A", f.env)
	eq(status, "failed")
	ok(tostring(err):find("throttled") ~= nil, "the store's error")
	eq(f.requests, SaveStore.ATTEMPTS, "ATTEMPTS requests")
	eq(f.data[KEY].cores, 900, "the save is untouched")
	eq(f.data[KEY].lock, nil, "no lock taken")
	-- The session never took the lock, so it can't write over the save either.
	f.failing = 0
	eq(SaveStore.write(f.store, KEY, "A", f.env, function()
		return Profile.toSave(Profile.blank(NOON, first))
	end), "lost", "a blank profile is refused")
	eq(f.data[KEY].cores, 900, "still untouched")
end)

test("T90: store errors retry with backoff 1, 2 s and then work", function()
	local f = fake()
	f.failing = 2
	local status = SaveStore.load(f.store, KEY, "A", f.env)
	eq(status, "ok")
	eq(f.requests, 3, "two failures, one success")
	eq(#f.waits, 2, "two waits")
	eq(f.waits[1], 1)
	eq(f.waits[2], 2)
	eq(SaveStore.backoff(10), SaveStore.MAX_DELAY, "capped")
end)

test("T90: no request budget = no request; it waits and tries again", function()
	local f = fake()
	f.budgetLeft = 0
	local status, err = SaveStore.load(f.store, KEY, "A", f.env)
	eq(status, "failed")
	eq(err, "no request budget")
	eq(f.requests, 0, "nothing sent over budget")
	eq(#f.waits, SaveStore.ATTEMPTS - 1, "backed off between tries")
	-- The budget comes back during the backoff.
	local g = fake()
	g.budgetLeft = 0
	g.env.wait = function(seconds: number)
		table.insert(g.waits, seconds)
		g.budgetLeft = 5
	end
	eq(SaveStore.load(g.store, KEY, "A", g.env), "ok", "works once there's budget")
	eq(g.requests, 1, "one request")
end)

test("T90: session lock: server B waits while A holds the save, then gets A's last save", function()
	local f = fake()
	f.data[KEY] = { cores = 100 }
	eq(SaveStore.load(f.store, KEY, "A", f.env), "ok", "A loads")
	local status = SaveStore.load(f.store, KEY, "B", f.env)
	eq(status, "locked", "B can't take it")
	eq(f.data[KEY].lock.session, "A", "A still holds it")
	eq(SaveStore.write(f.store, KEY, "A", f.env, function()
		return { cores = 250 }
	end, true), "ok", "A's last write frees it")
	eq(f.data[KEY].lock, nil, "released")
	local status2, raw = SaveStore.load(f.store, KEY, "B", f.env)
	eq(status2, "ok", "B loads now")
	eq(raw.cores, 250, "with A's last save")
	eq(raw.lock, nil, "the lock isn't part of the profile")
end)

test("T90: a crashed server's lock goes stale; its late write can't overwrite the new holder", function()
	local f = fake()
	f.data[KEY] = { cores = 100 }
	SaveStore.load(f.store, KEY, "A", f.env)
	f.clock += Profile.LOCK_STALE -- A stopped writing (crashed)
	eq(SaveStore.load(f.store, KEY, "B", f.env), "ok", "B takes the stale lock")
	SaveStore.write(f.store, KEY, "B", f.env, function()
		return { cores = 300 }
	end)
	eq(SaveStore.write(f.store, KEY, "A", f.env, function()
		return { cores = 1 }
	end), "lost", "A's late write")
	eq(f.data[KEY].cores, 300, "B's save stands")
	ok(Profile.LOCK_REFRESH * 2 < Profile.LOCK_STALE, "a live holder refreshes well inside the stale time")
end)

test("T90: an UpdateAsync conflict re-checks the lock on the newer value", function()
	local f = fake()
	SaveStore.load(f.store, KEY, "A", f.env)
	f.race = function(old)
		return { cores = 5, lock = { session = "B", at = f.clock } } -- B took it meanwhile
	end
	eq(SaveStore.write(f.store, KEY, "A", f.env, function()
		return { cores = 999 }
	end), "lost", "A sees B's lock on the retry")
	eq(f.data[KEY].cores, 5, "B's value stands")
	-- A load racing another server's take gives up as locked, writing nothing.
	local g = fake()
	g.race = function()
		return { lock = { session = "B", at = g.clock } }
	end
	g.failing = 0
	local writes = g.writes
	local status = SaveStore.load(g.store, KEY, "A", g.env)
	eq(status, "locked")
	eq(g.writes, writes, "nothing written by A")
end)

test("T90: a write stores the newest data (read at write time) and refreshes the lock", function()
	local f = fake()
	SaveStore.load(f.store, KEY, "A", f.env)
	local profile = { cores = 1 }
	local data = function()
		return { cores = profile.cores }
	end
	profile.cores = 42
	f.clock += 60
	eq(SaveStore.write(f.store, KEY, "A", f.env, data), "ok")
	eq(f.data[KEY].cores, 42, "the newest value")
	eq(f.data[KEY].lock.at, f.clock, "lock refreshed")
	-- data = nil only refreshes the lock (a save that didn't read keeps the stored one).
	f.data[KEY].cores = 7
	eq(SaveStore.write(f.store, KEY, "A", f.env, nil, true), "ok")
	eq(f.data[KEY].cores, 7, "kept")
	eq(f.data[KEY].lock, nil, "released")
end)

test("T90: a shutdown refunds an open stake in the last save; a crash refunds it on the next load", function()
	local f = fake()
	SaveStore.load(f.store, KEY, "A", f.env)
	local p = Profile.blank(NOON, first)
	p.cores = 100
	p.escrow = Stakes.escrow("m1", 15)
	-- BindToClose: refund, then the releasing write.
	eq(Profile.refundEscrow(p), 15)
	SaveStore.write(f.store, KEY, "A", f.env, function()
		return Profile.toSave(p)
	end, true)
	eq(f.data[KEY].cores, 115, "refunded in the save")
	eq(f.data[KEY].escrow, nil, "escrow closed")
	-- A crash: the escrow is still stored; the next load gives it back.
	local q = Profile.blank(NOON, first)
	q.cores = 100
	q.escrow = Stakes.escrow("m2", 15)
	local g = fake()
	g.data[KEY] = Profile.toSave(q)
	g.data[KEY].lock = { session = "dead", at = g.clock - Profile.LOCK_STALE }
	local status, raw = SaveStore.load(g.store, KEY, "B", g.env)
	eq(status, "ok")
	local loaded = Profile.sanitize(raw, NOON, first)
	eq(loaded.escrow and loaded.escrow.amount, 15, "the escrow loads")
	eq(Profile.refundEscrow(loaded), 15)
	eq(loaded.cores, 115, "back on load")
end)

test("T90: a Ranked leaver's forfeit and last-place Trophies land in one save", function()
	local f = fake()
	SaveStore.load(f.store, KEY, "A", f.env)
	local p = Profile.blank(NOON, first)
	p.cores, p.trophies = 85, 200
	p.escrow = Stakes.escrow("m1", 15)
	local delta = Profile.leaveRanked(p, "m1", "TEAM", 4, false)
	ok(delta < 0, "a Trophy loss")
	local writes = f.writes
	SaveStore.write(f.store, KEY, "A", f.env, function()
		return Profile.toSave(p)
	end, true)
	eq(f.writes - writes, 1, "one write")
	eq(f.data[KEY].escrow, nil, "stake forfeited")
	eq(f.data[KEY].cores, 85, "nothing back")
	eq(f.data[KEY].trophies, Trophies.apply(200, Trophies.leaverDelta("TEAM", 4, false)), "Trophies dropped")
end)

test("T90: both boards stay inside the OrderedDataStore budget with 10 players", function()
	-- Roblox per server per minute: SetAsync 60 + 10 x players, GetSortedAsync 5 + 2 x players.
	local players = 10
	local setBudget, getBudget = 60 + 10 * players, 5 + 2 * players
	local writes, reads = 0, 0
	local store = {
		write = function()
			writes += 1
		end,
		read = function()
			reads += 1
			return {}
		end,
		nameOf = function()
			return "n"
		end,
	}
	local boards = { LevelBoard.newCache(), LevelBoard.newCache() } -- level + Trophy board
	for second = 0, 599, 2 do -- ten minutes; every hunter changes every 2 s
		for _, cache in boards do
			for id = 1, players do
				LevelBoard.queue(cache, id, second + id + 1)
			end
			LevelBoard.step(cache, store, second, function() end)
		end
	end
	ok(writes / 10 <= setBudget, `writes a minute {writes / 10} <= {setBudget}`)
	ok(reads / 10 <= getBudget, `reads a minute {reads / 10} <= {getBudget}`)
	eq(writes, 2 * players * 10, "one write per hunter per board per minute")
end)

test("T90: Progression is the only profile writer and only reaches the save through SaveStore", function()
	local text = fs.readFile("src/server/Progression.luau")
	ok(text:find("SaveStore.load") ~= nil and text:find("SaveStore.write") ~= nil, "uses SaveStore")
	ok(text:find(":GetAsync") == nil and text:find(":SetAsync") == nil, "no direct GetAsync / SetAsync")
	ok(text:find("BindToClose") ~= nil, "flushes on shutdown")
	for _, file in fs.readDir("src/server") do
		if file ~= "Progression.luau" and file:match("%.luau$") then
			local other = fs.readFile(`src/server/{file}`)
			ok(other:find("SaveStore") == nil, `{file} doesn't touch the save`)
			ok(other:find("STORE_NAME") == nil or file == "LevelBoard.luau" or file == "TrophyBoard.luau", `{file}: no save store`)
		end
	end
end)
