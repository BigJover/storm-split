--[[
	Shared/Bounties: the Daily Haul and the daily/weekly bounties (PLAN round 2 T26,
	DECISIONS #63-#71, #75-#76). Times are UTC; rolls use scripted random numbers.
]]

local Config = require(src.shared.Config)
local Bounties = require(src.shared.Bounties)

local DAY = 86400
local THURSDAY = 1790812800 -- 2026-10-01 00:00:00 UTC
local SUNDAY = 1791072000 -- 2026-10-04 00:00:00 UTC
local MONDAY = 1791158400 -- 2026-10-05 00:00:00 UTC

local function first(_n: number): number
	return 1
end
local function last(n: number): number
	return n
end

local function entry(id: string, progress: number?, claimed: boolean?)
	return { id = id, progress = progress or 0, claimed = claimed or false }
end

-- A board with known bounties, rolled for `now`.
local function board(now: number)
	return {
		day = Bounties.dayIndex(now),
		week = Bounties.weekIndex(now),
		daily = { entry("D_COMPY_SWEEP"), entry("D_DEEP_TRAIL_15"), entry("D_CLEAN_SWEEP") },
		weekly = { entry("W_STAMPEDE"), entry("W_ROUGH_COUNTRY"), entry("W_DEEP_TRAIL_4") },
		dailySwaps = 0,
		weeklySwaps = 0,
		haul = { day = 0, claimedOn = nil :: number? },
	}
end

local function ids(entries): string
	local out = {}
	for _, e in entries do
		table.insert(out, e.id)
	end
	return table.concat(out, ",")
end

-- One per slot in the order easy, medium, hard; right pool; no duplicates; sane fields.
local function checkPool(entries, pool: string, what: string)
	local slots = Bounties.slots(pool)
	eq(#entries, #slots, `{what}: {pool} count`)
	local seen = {}
	for i, e in entries do
		local def = Config.Bounties[e.id]
		ok(def ~= nil, `{what}: {pool} #{i} is a known bounty`)
		eq(def.pool, pool, `{what}: {e.id} pool`)
		eq(def.slot, slots[i], `{what}: {e.id} slot`)
		ok(not seen[e.id], `{what}: {e.id} appears once`)
		seen[e.id] = true
		ok(type(e.progress) == "number" and e.progress >= 0 and e.progress <= def.count, `{what}: {e.id} progress in range`)
		ok(type(e.claimed) == "boolean", `{what}: {e.id} claimed is a boolean`)
	end
end

local function checkState(state, what: string)
	checkPool(state.daily, "daily", what)
	checkPool(state.weekly, "weekly", what)
	ok(state.dailySwaps >= 0 and state.dailySwaps <= Config.Tuning.DailySwaps, `{what}: daily swaps used`)
	ok(state.weeklySwaps >= 0 and state.weeklySwaps <= Config.Tuning.WeeklySwaps, `{what}: weekly swaps used`)
	ok(state.haul.day >= 0 and state.haul.day <= #Config.DailyHaul, `{what}: haul day`)
	ok(type(state.day) == "number" and type(state.week) == "number", `{what}: day and week`)
end

test("the sheet is the one this spec means", function()
	local t = Config.Tuning
	eq(t.DailyBounties, 3, "Daily bounties")
	eq(t.WeeklyBounties, 3, "Weekly bounties")
	eq(t.DailySwaps, 1, "Daily swaps")
	eq(t.WeeklySwaps, 1, "Weekly swaps")
	eq(t.HaulResetsAfterMissedDays, 0, "Haul resets after missed days")
	eq(t.DailyResetHourUTC, 0, "Daily reset hour UTC")
	eq(t.WeeklyResetDay, 1, "Weekly reset day")
	local haul = {}
	for i, day in Config.DailyHaul do
		haul[i] = tostring(day.amber)
	end
	eq(table.concat(haul, ","), "5,5,10,10,15,15,40", "Daily Haul")
	local daily, weekly = 0, 0
	for _, id in Config.BountyOrder do
		if Config.Bounties[id].pool == "daily" then
			daily += 1
		else
			weekly += 1
		end
	end
	eq(daily, 14, "daily pool")
	eq(weekly, 10, "weekly pool")
	eq(Config.Bounties.D_COMPY_SWEEP.count, 150, "Compy Sweep count")
	eq(Config.Bounties.W_DEEP_TRAIL_4.round, 31, "weekly Deep Trail round")
end)

test("a new day starts at 00:00 UTC", function()
	eq(Bounties.dayIndex(THURSDAY), 20727, "2026-10-01")
	eq(Bounties.dayIndex(THURSDAY - 1), 20726, "23:59:59 the day before")
	eq(Bounties.dayIndex(THURSDAY + DAY - 1), 20727, "23:59:59 that day")
	eq(Bounties.dayIndex(THURSDAY + DAY), 20728, "the next midnight")
	eq(Bounties.secondsToDaily(THURSDAY), DAY, "at midnight a full day is left")
	eq(Bounties.secondsToDaily(THURSDAY + DAY - 1), 1, "one second before the reset")
end)

test("a new week starts on Monday 00:00 UTC", function()
	local week = Bounties.weekIndex(THURSDAY)
	eq(Bounties.weekIndex(MONDAY - 7 * DAY), week, "Monday of that week")
	eq(Bounties.weekIndex(MONDAY - 7 * DAY - 1), week - 1, "the Sunday before, 23:59:59")
	eq(Bounties.weekIndex(SUNDAY + DAY - 1), week, "Sunday 23:59:59")
	eq(Bounties.weekIndex(MONDAY), week + 1, "Monday 00:00:00")
	eq(Bounties.weekIndex(4 * DAY), 1, "the first Monday of 1970")
	eq(Bounties.weekIndex(4 * DAY - 1), 0, "the second before it")
	eq(Bounties.secondsToWeekly(SUNDAY + DAY - 60), 60, "Sunday 23:59")
	eq(Bounties.secondsToWeekly(MONDAY), 7 * DAY, "Monday 00:00: a full week")
	eq(Bounties.secondsToWeekly(THURSDAY), 4 * DAY, "Thursday 00:00")
end)

test("a roll is one bounty per slot, in the order easy, medium, hard, with no duplicates", function()
	eq(table.concat(Bounties.slots("daily"), ","), "easy,medium,hard", "daily slots")
	eq(table.concat(Bounties.slots("weekly"), ","), "easy,medium,hard", "weekly slots")
	eq(ids(Bounties.roll("daily", first)), "D_COMPY_SWEEP,D_HEADBUTT_HUNT,D_RUN_THEM_DOWN", "first of each daily slot")
	eq(ids(Bounties.roll("daily", last)), "D_PITCH_CAMP,D_SHARPEN_UP,D_CLEAN_SWEEP", "last of each daily slot")
	eq(ids(Bounties.roll("weekly", first)), "W_STAMPEDE,W_CLEAN_SWEEP,W_BADLANDS", "first of each weekly slot")
	for seed = 1, 40 do
		local n = seed
		local function rng(size: number): number
			n = (n * 7 + 3) % 101
			return n % size + 1
		end
		checkPool(Bounties.roll("daily", rng), "daily", `seed {seed}`)
		checkPool(Bounties.roll("weekly", rng), "weekly", `seed {seed}`)
	end
	-- An rng that answers out of range can't break a roll.
	checkPool(Bounties.roll("daily", function() return 99 end), "daily", "rng too high")
	checkPool(Bounties.roll("daily", function() return 0 end), "daily", "rng too low")
end)

test("a new player's state", function()
	local state = Bounties.fresh(THURSDAY, first)
	checkState(state, "fresh")
	eq(state.day, 20727, "day")
	eq(state.week, Bounties.weekIndex(THURSDAY), "week")
	eq(state.dailySwaps, 0, "no daily swap used")
	eq(state.weeklySwaps, 0, "no weekly swap used")
	eq(state.haul.day, 0, "no Haul day claimed")
	eq(state.haul.claimedOn, nil, "never claimed")
	for _, e in state.daily do
		eq(e.progress, 0, `{e.id} progress`)
		eq(e.claimed, false, `{e.id} claimed`)
	end
end)

test("an old profile without the field loads as a new state", function()
	local state = Bounties.sanitize(nil, THURSDAY, first)
	checkState(state, "nil")
	eq(ids(state.daily), ids(Bounties.fresh(THURSDAY, first).daily), "same as fresh")
	eq(state.haul.day, 0, "Haul not started")
end)

test("a garbage field loads as a valid state", function()
	local huge = math.huge
	local garbage: { any } = {
		"junk", 5, true, {}, { daily = "no", weekly = 7, haul = "x" },
		{ day = "x", week = {}, daily = { 1, "a", {}, { id = 5 }, { id = "NOPE" } }, weekly = { { id = "D_COMPY_SWEEP" } }, dailySwaps = -3, weeklySwaps = 0 / 0, haul = { day = 99, claimedOn = "y" } },
		{ day = huge, week = -huge, daily = { { id = "D_COMPY_SWEEP", progress = huge, claimed = "yes" } }, haul = { day = 2.5, claimedOn = huge } },
	}
	for i, raw in garbage do
		local state = Bounties.sanitize(raw, THURSDAY, first)
		checkState(state, `garbage {i}`)
		eq(state.day, 20727, `garbage {i}: day is today`)
		eq(state.haul.day, 0, `garbage {i}: Haul day`)
		eq(state.haul.claimedOn, nil, `garbage {i}: Haul claim day`)
		eq(Bounties.refresh(state, THURSDAY, first), 0, `garbage {i}: nothing to pay`)
	end
end)

test("sanitize keeps what is valid, drops unknown ids and refills them", function()
	local raw = {
		day = 20727,
		week = Bounties.weekIndex(THURSDAY),
		daily = {
			{ id = "D_GONE_BOUNTY", progress = 3, claimed = false }, -- removed from the sheet
			{ id = "D_SHELL_CRACKER", progress = 12, claimed = false },
			{ id = "D_SHELL_CRACKER", progress = 30, claimed = false }, -- duplicate
			{ id = "D_PATCH_JOB", progress = 2, claimed = true },
			{ id = "W_STAMPEDE", progress = 5, claimed = false }, -- wrong pool
		},
		weekly = {
			{ id = "W_GEAR_CHECK", progress = 9999, claimed = false }, -- over its count
			{ id = "W_PATCH_JOB", progress = -4, claimed = false },
			{ id = "W_TYRANTS_END", progress = 0.5, claimed = false },
		},
		dailySwaps = 1,
		weeklySwaps = 7,
		haul = { day = 3, claimedOn = 20726 },
	}
	local state = Bounties.sanitize(raw, THURSDAY, first)
	checkState(state, "mixed")
	eq(ids(state.daily), "D_COMPY_SWEEP,D_SHELL_CRACKER,D_PATCH_JOB", "easy slot refilled; the rest kept in slot order")
	eq(state.daily[1].progress, 0, "the refill starts at 0")
	eq(state.daily[2].progress, 12, "Shell Cracker keeps its progress (first copy)")
	eq(state.daily[3].claimed, true, "Patch Job stays claimed")
	eq(ids(state.weekly), "W_GEAR_CHECK,W_PATCH_JOB,W_TYRANTS_END", "weeklies kept")
	eq(state.weekly[1].progress, 30, "progress capped at the count")
	eq(state.weekly[2].progress, 0, "negative progress -> 0")
	eq(state.weekly[3].progress, 0, "fractional progress -> 0")
	eq(state.dailySwaps, 1, "daily swaps used kept")
	eq(state.weeklySwaps, 1, "weekly swaps used capped at the allowance")
	eq(state.haul.day, 3, "Haul day kept")
	eq(state.haul.claimedOn, 20726, "Haul claim day kept")
	eq(raw.daily[2].progress, 12, "the raw value isn't changed")

	local future = Bounties.sanitize({ day = 99999, week = 99999, haul = { day = 2, claimedOn = 99999 } }, THURSDAY, first)
	eq(future.day, 20727, "a future day counts as today")
	eq(future.week, Bounties.weekIndex(THURSDAY), "a future week counts as this week")
	eq(future.haul.claimedOn, nil, "a future Haul claim is forgotten")
	ok(Bounties.canClaimHaul(future, THURSDAY), "so the Haul isn't locked")
end)

test("refresh changes nothing within the same day", function()
	local state = board(THURSDAY)
	state.daily[1].progress = 40
	state.dailySwaps = 1
	eq(Bounties.refresh(state, THURSDAY + DAY - 1, last), 0, "payout")
	eq(ids(state.daily), "D_COMPY_SWEEP,D_DEEP_TRAIL_15,D_CLEAN_SWEEP", "dailies")
	eq(state.daily[1].progress, 40, "progress")
	eq(state.dailySwaps, 1, "swaps used")
	-- A clock that goes backwards changes nothing either.
	eq(Bounties.refresh(state, THURSDAY - 3 * DAY, last), 0, "payout, earlier clock")
	eq(state.day, 20727, "day")
	eq(state.daily[1].progress, 40, "progress, earlier clock")
end)

test("at 00:00 UTC the dailies roll and the daily swap comes back; weeklies stay", function()
	local state = board(THURSDAY)
	state.daily[1].progress = 40
	state.weekly[1].progress = 700
	state.dailySwaps = 1
	state.weeklySwaps = 1
	eq(Bounties.refresh(state, THURSDAY + DAY, last), 0, "nothing was finished")
	eq(state.day, 20728, "day")
	eq(ids(state.daily), "D_PITCH_CAMP,D_SHARPEN_UP,D_CLEAN_SWEEP", "new dailies")
	eq(state.daily[1].progress, 0, "new dailies start at 0")
	eq(state.dailySwaps, 0, "daily swap back")
	eq(ids(state.weekly), "W_STAMPEDE,W_ROUGH_COUNTRY,W_DEEP_TRAIL_4", "weeklies kept")
	eq(state.weekly[1].progress, 700, "weekly progress kept")
	eq(state.weeklySwaps, 1, "weekly swap still used")
end)

test("Sunday 23:59 -> Monday 00:00 rolls the weeklies", function()
	local state = board(SUNDAY)
	state.weekly[1].progress = 700
	state.weeklySwaps = 1
	eq(Bounties.refresh(state, SUNDAY + DAY - 60, last), 0, "Sunday 23:59: payout")
	eq(ids(state.weekly), "W_STAMPEDE,W_ROUGH_COUNTRY,W_DEEP_TRAIL_4", "Sunday 23:59: weeklies kept")
	eq(state.weeklySwaps, 1, "Sunday 23:59: swap still used")
	eq(Bounties.refresh(state, MONDAY, last), 0, "Monday 00:00: payout")
	eq(ids(state.weekly), "W_DEEP_TRAIL_2,W_PATCH_JOB,W_DEEP_TRAIL_4", "Monday 00:00: new weeklies")
	eq(state.weekly[3].progress, 0, "a re-rolled bounty starts again")
	eq(state.weeklySwaps, 0, "weekly swap back")
	eq(state.week, Bounties.weekIndex(MONDAY), "week")
	eq(ids(state.daily), "D_PITCH_CAMP,D_SHARPEN_UP,D_CLEAN_SWEEP", "the dailies roll too")
end)

test("finished but unclaimed bounties are paid at the reset", function()
	local state = board(SUNDAY)
	state.daily[1].progress = 150 -- Compy Sweep done, unclaimed: 10
	state.daily[2].progress = 15 -- Deep Trail done and claimed: not paid again
	state.daily[2].claimed = true
	state.daily[3].progress = 0 -- Clean Sweep unfinished: nothing
	state.weekly[1].progress = 1499 -- one short: nothing
	state.weekly[2].progress = 1 -- Rough Country done, unclaimed: 60
	eq(Bounties.refresh(state, SUNDAY + DAY - 1, first), 0, "nothing is paid before the reset")
	eq(Bounties.refresh(state, MONDAY, first), 70, "daily 10 + weekly 60")
	eq(Bounties.refresh(state, MONDAY, first), 0, "paid once")

	local midweek = board(THURSDAY)
	midweek.daily[1].progress = 150
	midweek.weekly[2].progress = 1
	eq(Bounties.refresh(midweek, THURSDAY + DAY, first), 10, "a daily reset pays only the dailies")
	eq(midweek.weekly[2].progress, 1, "the finished weekly waits")
	ok(Bounties.claim(midweek, "W_ROUGH_COUNTRY"), "and can still be claimed by hand")
end)

test("the Daily Haul: once per UTC day, days 1-7, then round again", function()
	local state = board(THURSDAY)
	local paid = {}
	for i = 0, 8 do
		local now = THURSDAY + i * DAY + 3600
		ok(Bounties.canClaimHaul(state, now), `day {i}: can claim`)
		local today, claimedToday = Bounties.haulToday(state, now)
		eq(claimedToday, false, `day {i}: not claimed yet`)
		local claimed, amber, day = Bounties.claimHaul(state, now)
		eq(claimed, true, `day {i}: claimed`)
		eq(day, i % 7 + 1, `day {i}: Haul day`)
		eq(today, day, `day {i}: haulToday agreed`)
		table.insert(paid, tostring(amber))
		-- a second claim the same UTC day is refused, right up to 23:59:59
		eq(Bounties.canClaimHaul(state, THURSDAY + (i + 1) * DAY - 1), false, `day {i}: no second claim`)
		local again, nothing = Bounties.claimHaul(state, THURSDAY + (i + 1) * DAY - 1)
		eq(again, false, `day {i}: double claim refused`)
		eq(nothing, 0, `day {i}: double claim pays nothing`)
		local shown, done = Bounties.haulToday(state, now)
		eq(shown, day, `day {i}: the calendar still shows the day claimed`)
		eq(done, true, `day {i}: marked claimed`)
	end
	eq(table.concat(paid, ","), "5,5,10,10,15,15,40,5,5", "Amber, looping after the Big Haul")
end)

test("a missed day pauses the Daily Haul; it never resets (lever 0)", function()
	local state = board(THURSDAY)
	local _, amber, day = Bounties.claimHaul(state, THURSDAY)
	eq(day, 1, "day 1")
	eq(amber, 5, "day 1 Amber")
	-- three days away
	local claimed, amber2, day2 = Bounties.claimHaul(state, THURSDAY + 4 * DAY)
	eq(claimed, true, "claimed after the gap")
	eq(day2, 2, "carries on at day 2")
	eq(amber2, 5, "day 2 Amber")
	local _, amber3, day3 = Bounties.claimHaul(state, THURSDAY + 40 * DAY)
	eq(day3, 3, "and at day 3 after a month")
	eq(amber3, 10, "day 3 Amber")
	-- an unclaimed day isn't paid later: one claim per day, never a catch-up
	eq(Bounties.canClaimHaul(state, THURSDAY + 40 * DAY + 5), false, "no catch-up claim")
end)

test("the Haul reset lever, when it's set (nextHaulDay)", function()
	local haul = { day = 4, claimedOn = 100 }
	eq(Bounties.nextHaulDay(haul, 101), 5, "lever from the sheet (0): next day")
	eq(Bounties.nextHaulDay(haul, 150), 5, "lever 0: a long gap still pauses")
	eq(Bounties.nextHaulDay(haul, 101, 1), 5, "lever 1: no day missed")
	eq(Bounties.nextHaulDay(haul, 102, 1), 1, "lever 1: one day missed -> day 1")
	eq(Bounties.nextHaulDay(haul, 102, 2), 5, "lever 2: one day missed is fine")
	eq(Bounties.nextHaulDay(haul, 103, 2), 1, "lever 2: two days missed -> day 1")
	eq(Bounties.nextHaulDay({ day = 7, claimedOn = 100 }, 101), 1, "after the last day comes day 1")
	eq(Bounties.nextHaulDay({ day = 0 }, 101, 1), 1, "never claimed: day 1")
end)

test("pops count for their species and for pop-any bounties", function()
	local state = board(THURSDAY)
	eq(#Bounties.progress(state, "pop", "HUSK", 3), 0, "nothing finished yet")
	eq(state.daily[1].progress, 3, "Compy Sweep")
	eq(state.weekly[1].progress, 3, "Stampede (pop any)")
	Bounties.progress(state, "pop", "BRUTE")
	eq(state.daily[1].progress, 3, "a Raptor isn't a Compy")
	eq(state.weekly[1].progress, 4, "but it's a dino (amount defaults to 1)")
	eq(state.daily[2].progress, 0, "Deep Trail untouched")
	eq(state.daily[3].progress, 0, "Clean Sweep untouched")
	-- bad amounts and unknown events are ignored
	Bounties.progress(state, "pop", "HUSK", 0)
	Bounties.progress(state, "pop", "HUSK", -5)
	Bounties.progress(state, "pop", "HUSK", 0 / 0)
	Bounties.progress(state, "pop", "HUSK", 1.5)
	Bounties.progress(state, "popTotal", nil, 50)
	Bounties.progress(state, "chest", nil, 50)
	eq(state.daily[1].progress, 3, "Compy Sweep unchanged")
	eq(state.weekly[1].progress, 4, "Stampede unchanged")
end)

test("progress stops at the count and reports a bounty the moment it's finished", function()
	local state = board(THURSDAY)
	Bounties.progress(state, "pop", "HUSK", 149)
	eq(Bounties.isDone(state.daily[1]), false, "149 of 150")
	local finished = Bounties.progress(state, "pop", "HUSK", 5)
	eq(table.concat(finished, ","), "D_COMPY_SWEEP", "finished")
	eq(state.daily[1].progress, 150, "capped at the count")
	eq(Bounties.isDone(state.daily[1]), true, "done")
	eq(#Bounties.progress(state, "pop", "HUSK", 5), 0, "reported once")
	eq(state.daily[1].progress, 150, "no progress past the count")
	eq(state.weekly[1].progress, 159, "Stampede counted them all")
end)

test("only a boss pop counts for hunters who didn't get the pop", function()
	local state = board(THURSDAY)
	state.weekly[2] = entry("W_HORN_BREAKER")
	Bounties.progress(state, "pop", "HUSK", 1, { credited = false })
	eq(state.daily[1].progress, 0, "someone else's Compy: no Compy Sweep")
	eq(state.weekly[1].progress, 0, "someone else's Compy: no Stampede")
	Bounties.progress(state, "pop", "ZEP", 1, { credited = false })
	eq(state.weekly[2].progress, 1, "someone else's Triceratops counts for Horn Breaker")
	eq(state.weekly[1].progress, 1, "and for Stampede")
	Bounties.progress(state, "pop", "ZEP", 1, { credited = true })
	Bounties.progress(state, "pop", "HUSK", 1, {})
	eq(state.weekly[2].progress, 2, "your own Triceratops")
	eq(state.daily[1].progress, 1, "your own Compy")
	ok(Config.Enemies.ZEP.boss and Config.Enemies.BARGE.boss and not Config.Enemies.HUSK.boss, "bosses are Triceratops and T-Rex")
end)

test("clears: any track, or a difficulty and anything harder", function()
	local state = board(THURSDAY)
	local clean = entry("W_CLEAN_SWEEP")
	state.daily[3] = entry("D_PATCH_JOB")
	state.weekly = { clean, entry("W_ROUGH_COUNTRY"), entry("W_BADLANDS") }

	Bounties.progress(state, "clear", "EASY")
	eq(clean.progress, 1, "Clean Sweep: an Easy clear counts")
	eq(state.weekly[2].progress, 0, "Rough Country: Easy isn't Normal or harder")
	eq(state.weekly[3].progress, 0, "Badlands: Easy isn't Hard or harder")
	Bounties.progress(state, "clear", "NORMAL")
	eq(state.weekly[2].progress, 1, "Rough Country: Normal counts")
	eq(state.weekly[3].progress, 0, "Badlands: Normal doesn't")
	local finished = Bounties.progress(state, "clear", "CHAOS")
	eq(table.concat(finished, ","), "W_CLEAN_SWEEP,W_BADLANDS", "Chaos finishes Clean Sweep (3) and Badlands")
	eq(state.weekly[2].progress, 1, "Rough Country was already done")

	local other = board(THURSDAY)
	other.weekly[3] = entry("W_BADLANDS")
	Bounties.progress(other, "clear", "HARD")
	eq(other.weekly[3].progress, 1, "Badlands: Hard counts")
	eq(other.weekly[2].progress, 1, "Rough Country: Hard counts")
	eq(other.daily[3].progress, 1, "daily Clean Sweep")
	local unknown = board(THURSDAY)
	Bounties.progress(unknown, "clear", "NIGHTMARE")
	Bounties.progress(unknown, "clear", nil)
	eq(unknown.weekly[2].progress, 0, "an unknown difficulty isn't 'Normal or harder'")
	eq(unknown.daily[3].progress, 1, "but the first clear finished the any-track bounty")
end)

test("reach round: the round itself, or a round reached several times", function()
	local state = board(THURSDAY) -- Deep Trail 15 (daily) and Deep Trail 31 x 4 (weekly)
	for round = 1, 9 do
		Bounties.progress(state, "reachRound", nil, round)
	end
	eq(state.daily[2].progress, 9, "Deep Trail 15 shows the best round")
	Bounties.progress(state, "reachRound", nil, 4)
	eq(state.daily[2].progress, 9, "a worse match doesn't lower it")
	eq(state.weekly[3].progress, 0, "round 31 not reached")
	local finished = {}
	for round = 1, 40 do
		for _, id in Bounties.progress(state, "reachRound", nil, round) do
			table.insert(finished, `{id}@{round}`)
		end
	end
	eq(table.concat(finished, ","), "D_DEEP_TRAIL_15@15", "done on reaching round 15")
	eq(state.daily[2].progress, 15, "capped at 15")
	eq(state.weekly[3].progress, 1, "one match past round 31 counts once")
	for _ = 1, 3 do
		for round = 1, 33 do
			Bounties.progress(state, "reachRound", nil, round)
		end
	end
	eq(state.weekly[3].progress, 4, "four matches")
	eq(Bounties.isDone(state.weekly[3]), true, "done")
end)

test("ability, build, upgrade and repair count their own bounties only", function()
	local state = board(THURSDAY)
	state.daily = { entry("D_GEAR_CHECK"), entry("D_SHARPEN_UP"), entry("D_PATCH_JOB") }
	state.weekly = { entry("W_GEAR_CHECK"), entry("W_PATCH_JOB"), entry("W_TYRANTS_END") }
	Bounties.progress(state, "ability")
	Bounties.progress(state, "ability")
	eq(state.daily[1].progress, 2, "daily Gear Check")
	eq(state.weekly[1].progress, 2, "weekly Gear Check")
	Bounties.progress(state, "upgrade", nil, 3)
	eq(state.daily[2].progress, 3, "Sharpen Up")
	Bounties.progress(state, "build", nil, 2)
	eq(state.daily[2].progress, 3, "a build isn't an upgrade")
	local finished = Bounties.progress(state, "repair", nil, 2)
	eq(table.concat(finished, ","), "D_PATCH_JOB", "daily Patch Job done at 2")
	eq(state.weekly[2].progress, 2, "weekly Patch Job 2 of 10")
	state.daily[1] = entry("D_PITCH_CAMP")
	Bounties.progress(state, "build", nil, 2)
	eq(state.daily[1].progress, 2, "Pitch Camp")
	eq(#Bounties.progress(state, "pop", "BARGE"), 1, "a T-Rex finishes Tyrant's End")
end)

test("claim pays a finished bounty once; a double claim is refused", function()
	local state = board(THURSDAY)
	local early, nothing = Bounties.claim(state, "D_COMPY_SWEEP")
	eq(early, false, "not finished: refused")
	eq(nothing, 0, "not finished: no Amber")
	Bounties.progress(state, "pop", "HUSK", 150)
	local claimed, amber = Bounties.claim(state, "D_COMPY_SWEEP")
	eq(claimed, true, "claimed")
	eq(amber, 10, "the daily easy reward")
	eq(state.daily[1].claimed, true, "marked claimed")
	local again, more = Bounties.claim(state, "D_COMPY_SWEEP")
	eq(again, false, "double claim refused")
	eq(more, 0, "double claim pays nothing")
	eq((Bounties.claim(state, "D_RAPTOR_CULL")), false, "a bounty that isn't on the board")
	eq((Bounties.claim(state, "NOPE")), false, "an unknown id")
	-- a claimed bounty takes no more progress and isn't paid at the reset
	Bounties.progress(state, "pop", "HUSK", 5)
	eq(state.daily[1].progress, 150, "progress unchanged")
	eq(Bounties.refresh(state, THURSDAY + DAY, first), 0, "not paid again at the reset")
	state.weekly[2].progress = 1
	local weeklyClaimed, weeklyAmber = Bounties.claim(state, "W_ROUGH_COUNTRY")
	eq(weeklyClaimed, true, "weekly claimed")
	eq(weeklyAmber, 60, "the weekly medium reward")
end)

test("swap: an unfinished bounty for another from its slot", function()
	local state = board(THURSDAY)
	state.daily[2].progress = 9
	eq(Bounties.swapsLeft(state, "daily"), 1, "one daily swap")
	local swapped, newId = Bounties.swap(state, "D_DEEP_TRAIL_15", first)
	eq(swapped, true, "swapped")
	eq(newId, "D_HEADBUTT_HUNT", "the first other medium daily")
	eq(ids(state.daily), "D_COMPY_SWEEP,D_HEADBUTT_HUNT,D_CLEAN_SWEEP", "same place on the board")
	eq(state.daily[2].progress, 0, "the new one starts at 0")
	eq(state.dailySwaps, 1, "swap used")
	eq(Bounties.swapsLeft(state, "daily"), 0, "none left")
	eq(Bounties.swapsLeft(state, "weekly"), 1, "the weekly swap is separate")
	checkState(state, "after a swap")
end)

test("swap never gives back the same bounty or one already on the board", function()
	for pick = 1, 6 do
		local state = board(THURSDAY)
		state.daily = { entry("D_COMPY_SWEEP"), entry("D_HEADBUTT_HUNT"), entry("D_PATCH_JOB") }
		local _, newId = Bounties.swap(state, "D_PATCH_JOB", function(n: number): number
			return (pick - 1) % n + 1
		end)
		ok(newId ~= nil and newId ~= "D_PATCH_JOB", `pick {pick}: not the one swapped out`)
		eq(Config.Bounties[newId :: string].slot, "hard", `pick {pick}: same slot`)
		checkState(state, `pick {pick}`)
	end
end)

test("swap limit: one a day, back after the reset", function()
	local state = board(THURSDAY)
	ok(Bounties.swap(state, "D_COMPY_SWEEP", first), "first swap")
	local before = ids(state.daily)
	local second, newId = Bounties.swap(state, "D_DEEP_TRAIL_15", first)
	eq(second, false, "second swap refused")
	eq(newId, nil, "no new bounty")
	eq(ids(state.daily), before, "board unchanged")
	ok(Bounties.swap(state, "W_STAMPEDE", first), "the weekly swap still works")
	eq((Bounties.swap(state, "W_ROUGH_COUNTRY", first)), false, "one weekly swap only")
	Bounties.refresh(state, THURSDAY + DAY, first)
	ok(Bounties.swap(state, state.daily[1].id, last), "a new day, a new daily swap")
	eq((Bounties.swap(state, state.weekly[2].id, first)), false, "the weekly swap waits for Monday")
	Bounties.refresh(state, MONDAY, first)
	ok(Bounties.swap(state, state.weekly[2].id, last), "Monday: a new weekly swap")
end)

test("swap is refused on a finished or claimed bounty, or one not on the board", function()
	local state = board(THURSDAY)
	state.daily[1].progress = 150
	eq((Bounties.swap(state, "D_COMPY_SWEEP", first)), false, "finished, unclaimed")
	Bounties.claim(state, "D_COMPY_SWEEP")
	eq((Bounties.swap(state, "D_COMPY_SWEEP", first)), false, "claimed")
	eq((Bounties.swap(state, "D_RAPTOR_CULL", first)), false, "not on the board")
	eq((Bounties.swap(state, "NOPE", first)), false, "unknown id")
	eq(state.dailySwaps, 0, "no swap was used")
	eq(ids(state.daily), "D_COMPY_SWEEP,D_DEEP_TRAIL_15,D_CLEAN_SWEEP", "board unchanged")
end)

test("claimable: an unclaimed Haul day or a finished bounty", function()
	local state = board(THURSDAY)
	eq(Bounties.claimable(state, THURSDAY), true, "today's Haul")
	Bounties.claimHaul(state, THURSDAY)
	eq(Bounties.claimable(state, THURSDAY + 60), false, "nothing left")
	Bounties.progress(state, "clear", "EASY")
	eq(Bounties.claimable(state, THURSDAY + 60), true, "Clean Sweep is done")
	Bounties.claim(state, "D_CLEAN_SWEEP")
	eq(Bounties.claimable(state, THURSDAY + 60), false, "claimed")
	eq(Bounties.claimable(state, THURSDAY + DAY), true, "tomorrow's Haul")
end)
