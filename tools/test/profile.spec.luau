--[[
	Shared/Profile: the saved profile and its Hunt Board paths (PLAN round 2 T27,
	DECISIONS #68-#69, #83). What Server/Progression loads, changes and saves, run
	headlessly: an old save loads cleanly, Amber only moves by what Shared/Bounties
	returns, and a broken Hunt Board never costs a player their save or their game.
]]

local Config = require(src.shared.Config)
local Bounties = require(src.shared.Bounties)
local Profile = require(src.shared.Profile)
local Trophies = require(src.shared.Trophies)

local DAY = 86400
local THURSDAY = 1790812800 -- 2026-10-01 00:00:00 UTC
local NOON = THURSDAY + 12 * 3600

local function first(_n: number): number
	return 1
end

local function entry(id: string, progress: number?, claimed: boolean?)
	return { id = id, progress = progress or 0, claimed = claimed or false }
end

local function amberOf(id: string): number
	return Config.Bounties[id].amber
end
local function countOf(id: string): number
	return Config.Bounties[id].count
end

-- A stored save with a known board rolled for `now`, and 100 Amber.
local function saved(now: number)
	return {
		cores = 100,
		owned = { ["hero:RIFLE"] = true },
		mastery = { RIFLE = 2 },
		highestRound = 17,
		rewards = {
			day = Bounties.dayIndex(now),
			week = Bounties.weekIndex(now),
			daily = { entry("D_COMPY_SWEEP"), entry("D_DEEP_TRAIL_15"), entry("D_CLEAN_SWEEP") },
			weekly = { entry("W_STAMPEDE"), entry("W_ROUGH_COUNTRY"), entry("W_DEEP_TRAIL_4") },
			dailySwaps = 0,
			weeklySwaps = 0,
			haul = { day = 0 },
		},
	}
end

local function loaded(now: number)
	return Profile.sanitize(saved(now), now, first)
end

local function ids(entries): string
	local out = {}
	for _, e in entries do
		table.insert(out, e.id)
	end
	return table.concat(out, ",")
end

local function checkBoard(state, what: string)
	ok(state ~= nil, `{what}: has a Hunt Board`)
	for _, pool in Bounties.POOLS do
		local slots = Bounties.slots(pool)
		eq(#state[pool], #slots, `{what}: {pool} count`)
		for i, e in state[pool] do
			local def = Config.Bounties[e.id]
			ok(def ~= nil and def.pool == pool and def.slot == slots[i], `{what}: {pool} #{i} fits its slot`)
		end
	end
end

test("the sheet is the one this spec means", function()
	ok(Config.Heroes.RIFLE ~= nil and Config.Heroes.RIFLE.unlockCost > 0, "RIFLE is a paid hero")
	eq(Config.Bounties.D_COMPY_SWEEP.slot, "easy", "Compy Sweep slot")
	eq(Config.Bounties.D_COMPY_SWEEP.target, "HUSK", "Compy Sweep species key (internal keys predate the theme)")
	eq(Config.Bounties.D_CLEAN_SWEEP.event, "clear", "Clean Sweep event")
	eq(Config.Tuning.DailySwaps, 1, "Daily swaps")
	ok(amberOf("D_COMPY_SWEEP") > 0 and Config.DailyHaul[1].amber > 0, "rewards pay something")
end)

-- Loading ---------------------------------------------------------------------------

test("a round-1 save (no rewards field) keeps everything and gets a fresh Hunt Board", function()
	local old = { cores = 240, owned = { ["hero:RIFLE"] = true, ["tower:NOPE"] = true }, mastery = { RIFLE = 3 }, highestRound = 22 }
	local profile = Profile.sanitize(old, NOON, first)
	eq(profile.cores, 240, "Amber kept")
	eq(profile.owned["hero:RIFLE"], true, "unlock kept")
	eq(profile.owned["tower:NOPE"], nil, "unknown unlock dropped")
	eq(profile.mastery.RIFLE, 3, "mastery kept")
	eq(profile.highestRound, 22, "highest round kept")
	checkBoard(profile.rewards, "old save")
	eq(profile.rewards.haul.day, 0, "Haul not started")
	eq(profile.rewards.day, Bounties.dayIndex(NOON), "rolled for today")
	eq(profile.lastResetPayout, 0, "no reset payout")
	ok(Profile.claimable(profile, NOON), "the first Haul day is waiting")
end)

test("nothing stored, or garbage, is a new player's profile", function()
	for _, raw in { nil :: any, "x", 7, true } do
		local profile = Profile.sanitize(raw, NOON, first)
		eq(profile.cores, 0, "no Amber")
		eq(next(profile.owned), nil, "owns nothing")
		eq(profile.highestRound, 0, "no rounds")
		checkBoard(profile.rewards, "new player")
	end
	checkBoard(Profile.blank(NOON, first).rewards, "blank")
end)

test("a garbage rewards field becomes a fresh board; the rest of the save is kept", function()
	for _, bad in { "x" :: any, 5, true, {}, { daily = "no", weekly = { 1, 2 }, haul = 9 }, { daily = { entry("NOT_A_BOUNTY", 5) } } } do
		local raw = saved(NOON)
		raw.rewards = bad
		local profile = Profile.sanitize(raw, NOON, first)
		eq(profile.cores, 100, "Amber kept")
		eq(profile.owned["hero:RIFLE"], true, "unlock kept")
		checkBoard(profile.rewards, "garbage rewards")
	end
end)

test("negative or wrong-typed Amber never loads as Amber", function()
	eq(Profile.sanitize({ cores = -5 }, NOON, first).cores, 0, "negative")
	eq(Profile.sanitize({ cores = "999" }, NOON, first).cores, 0, "a string")
	eq(Profile.sanitize({ cores = 12.9 }, NOON, first).cores, 12, "floored")
end)

-- Saving ----------------------------------------------------------------------------

test("what is saved loads back the same", function()
	local profile = loaded(NOON)
	Profile.bountyEvent(profile, "pop", "HUSK", 7, { credited = true })
	ok(Profile.claimHaul(profile, NOON, first), "Haul claimed")
	ok(Profile.swapBounty(profile, "D_DEEP_TRAIL_15", NOON, first), "swapped")
	local again = Profile.sanitize(Profile.toSave(profile), NOON, first)
	eq(again.cores, profile.cores, "Amber")
	eq(again.owned["hero:RIFLE"], true, "unlock")
	eq(again.mastery.RIFLE, 2, "mastery")
	eq(again.highestRound, 17, "highest round")
	eq(ids(again.rewards.daily), ids(profile.rewards.daily), "dailies")
	eq(ids(again.rewards.weekly), ids(profile.rewards.weekly), "weeklies")
	eq(again.rewards.daily[1].progress, 7, "progress")
	eq(again.rewards.dailySwaps, 1, "swap used")
	eq(again.rewards.haul.day, 1, "Haul day")
	eq(again.rewards.haul.claimedOn, Bounties.dayIndex(NOON), "Haul claimed on")
	ok(not Bounties.canClaimHaul(again.rewards, NOON), "the Haul stays claimed after a reload")
end)

test("only the saved fields are stored", function()
	local profile = loaded(NOON)
	profile.lastResetPayout = 35
	local out = Profile.toSave(profile)
	local keys = {}
	for k in out do
		table.insert(keys, k)
	end
	table.sort(keys)
	eq(table.concat(keys, ","), "cores,equipped,highestRound,mastery,owned,playerXp,rewards,trophies", "stored keys (T80: + trophies; bestArena and escrow only when set)")
	ok(out.rewards == profile.rewards, "the Hunt Board state itself")
end)

-- A broken Hunt Board ---------------------------------------------------------------

local function withBrokenRules(fn: () -> ())
	local real = Profile.rules
	Profile.rules = setmetatable({}, {
		__index = function()
			return function()
				error("the Hunt Board is broken")
			end
		end,
	}) :: any
	local passed, err = pcall(fn)
	Profile.rules = real
	if not passed then
		error(err, 0)
	end
end

test("a Hunt Board that fails to load never blocks the profile or wipes the stored board", function()
	local raw = saved(NOON)
	raw.rewards.daily[1].progress = 40
	local profile
	withBrokenRules(function()
		profile = Profile.sanitize(raw, NOON, first)
	end)
	eq(profile.cores, 100, "Amber loaded")
	eq(profile.owned["hero:RIFLE"], true, "unlock loaded")
	eq(profile.mastery.RIFLE, 2, "mastery loaded")
	eq(profile.rewards, nil, "no Hunt Board this session")

	-- Every Hunt Board call answers "no" and changes nothing.
	eq(Profile.refresh(profile, NOON + DAY, first), 0, "refresh")
	eq((Profile.claimHaul(profile, NOON, first)), false, "claimHaul")
	eq((Profile.claimBounty(profile, "D_COMPY_SWEEP", NOON, first)), false, "claimBounty")
	eq((Profile.swapBounty(profile, "D_COMPY_SWEEP", NOON, first)), false, "swapBounty")
	eq(#Profile.bountyEvent(profile, "pop", "HUSK", 500, { credited = true }), 0, "bountyEvent")
	eq(Profile.claimable(profile, NOON), false, "claimable")
	eq(Profile.view(profile, NOON), nil, "view")
	eq(profile.cores, 100, "Amber untouched")
	eq(profile.rewardsVersion, 0, "nothing changed")

	-- The save writes the stored board back exactly as it was.
	local out = Profile.toSave(profile)
	ok(out.rewards == raw.rewards, "the stored board is written back untouched")
	eq(out.rewards.daily[1].progress, 40, "its progress is still there")
	eq(out.cores, 100, "Amber saved")
end)

test("a new player still gets a profile when the Hunt Board is broken", function()
	local profile
	withBrokenRules(function()
		profile = Profile.blank(NOON, first)
	end)
	eq(profile.cores, 0, "blank profile")
	eq(profile.rewards, nil, "no Hunt Board")
	eq(Profile.toSave(profile).rewards, nil, "nothing to write")
end)

-- Daily Haul ------------------------------------------------------------------------

test("claiming the Haul pays that day's Amber once per UTC day", function()
	local profile = loaded(NOON)
	local claimed, amber, day = Profile.claimHaul(profile, NOON, first)
	eq(claimed, true, "claimed")
	eq(day, 1, "day 1")
	eq(amber, Config.DailyHaul[1].amber, "day 1 Amber")
	eq(profile.cores, 100 + Config.DailyHaul[1].amber, "paid")
	eq(profile.rewardsVersion, 1, "one change")

	eq((Profile.claimHaul(profile, NOON + 3600, first)), false, "same day refused")
	eq(profile.cores, 100 + Config.DailyHaul[1].amber, "not paid twice")
	eq(profile.rewardsVersion, 1, "a refusal isn't a change")

	local again, amber2, day2 = Profile.claimHaul(profile, NOON + DAY, first)
	eq(again, true, "next day")
	eq(day2, 2, "day 2")
	eq(profile.cores, 100 + Config.DailyHaul[1].amber + amber2, "paid day 2")
end)

-- Bounties --------------------------------------------------------------------------

test("a bounty pays its Amber once, only when done", function()
	local profile = loaded(NOON)
	eq((Profile.claimBounty(profile, "D_COMPY_SWEEP", NOON, first)), false, "not done yet")
	eq(profile.cores, 100, "nothing paid")
	eq(profile.rewardsVersion, 0, "nothing changed")

	local finished = Profile.bountyEvent(profile, "pop", "HUSK", countOf("D_COMPY_SWEEP"), { credited = true })
	eq(table.concat(finished, ","), "D_COMPY_SWEEP", "finished")
	eq(profile.cores, 100, "finishing pays nothing by itself")
	eq(profile.rewardsVersion, 1, "finishing is a change")
	ok(Profile.claimable(profile, NOON), "claimable")

	local claimed, amber = Profile.claimBounty(profile, "D_COMPY_SWEEP", NOON, first)
	eq(claimed, true, "claimed")
	eq(amber, amberOf("D_COMPY_SWEEP"), "its Amber")
	eq(profile.cores, 100 + amberOf("D_COMPY_SWEEP"), "paid")

	eq((Profile.claimBounty(profile, "D_COMPY_SWEEP", NOON, first)), false, "double claim refused")
	eq(profile.cores, 100 + amberOf("D_COMPY_SWEEP"), "not paid twice")
end)

test("claims and swaps refuse ids that aren't on the board or aren't strings", function()
	local profile = loaded(NOON)
	for _, id in { nil :: any, 5, true, {}, "", "D_RAPTOR_CULL", "NOT_A_BOUNTY" } do
		eq((Profile.claimBounty(profile, id, NOON, first)), false, "claim refused")
		eq((Profile.swapBounty(profile, id, NOON, first)), false, "swap refused")
	end
	eq(profile.cores, 100, "nothing paid")
	eq(profile.rewardsVersion, 0, "nothing changed")
	eq(ids(profile.rewards.daily), "D_COMPY_SWEEP,D_DEEP_TRAIL_15,D_CLEAN_SWEEP", "board unchanged")
end)

test("progress that doesn't finish a bounty isn't announced", function()
	local profile = loaded(NOON)
	eq(#Profile.bountyEvent(profile, "pop", "HUSK", 3, { credited = true }), 0, "nothing finished")
	eq(profile.rewards.daily[1].progress, 3, "but counted")
	eq(profile.rewardsVersion, 0, "no re-ask for every pop")
	eq(#Profile.bountyEvent(profile, "pop", "HUSK", 3, { credited = false }), 0, "a teammate's pop")
	eq(profile.rewards.daily[1].progress, 3, "doesn't count unless it's a boss")
end)

test("a swap changes the board, costs nothing, and is limited", function()
	local profile = loaded(NOON)
	local swapped, newId = Profile.swapBounty(profile, "D_COMPY_SWEEP", NOON, first)
	eq(swapped, true, "swapped")
	ok(newId ~= nil and newId ~= "D_COMPY_SWEEP", "a different bounty")
	eq(profile.rewards.daily[1].id, newId, "on the board")
	eq(profile.cores, 100, "free")
	eq(profile.rewardsVersion, 1, "one change")
	eq((Profile.swapBounty(profile, "D_DEEP_TRAIL_15", NOON, first)), false, "out of daily swaps")
	eq(profile.rewardsVersion, 1, "a refusal isn't a change")
end)

-- Resets ----------------------------------------------------------------------------

test("a reset pays done-but-unclaimed bounties once and remembers the amount", function()
	local profile = loaded(NOON)
	Profile.bountyEvent(profile, "clear", "EASY", 1)
	ok(Bounties.isDone(profile.rewards.daily[3]), "Clean Sweep done")
	eq(Profile.refresh(profile, NOON, first), 0, "same day: nothing")

	local tomorrow = NOON + DAY
	local paid = Profile.refresh(profile, tomorrow, first)
	eq(paid, amberOf("D_CLEAN_SWEEP"), "paid at the reset")
	eq(profile.cores, 100 + paid, "into Amber")
	eq(profile.lastResetPayout, paid, "remembered")
	eq(profile.rewards.day, Bounties.dayIndex(tomorrow), "rolled")
	eq(Profile.refresh(profile, tomorrow, first), 0, "not paid again")
	eq(profile.cores, 100 + paid, "Amber unchanged")

	-- Claiming yesterday's bounty after the reset can't pay it a second time.
	eq((Profile.claimBounty(profile, "D_CLEAN_SWEEP", tomorrow, first)), false, "old claim refused")
	eq(profile.cores, 100 + paid, "still paid once")
end)

test("a claim that arrives after midnight is checked against the new board", function()
	local profile = loaded(NOON)
	Profile.bountyEvent(profile, "clear", "EASY", 1)
	local tomorrow = NOON + DAY
	-- The claim itself runs the reset first: paid once, by the reset.
	Profile.claimBounty(profile, "D_CLEAN_SWEEP", tomorrow, first)
	eq(profile.cores, 100 + amberOf("D_CLEAN_SWEEP"), "paid exactly once")
	eq(profile.lastResetPayout, amberOf("D_CLEAN_SWEEP"), "as a reset payout")
end)

test("a reset with nothing unclaimed still counts as a change", function()
	local profile = loaded(NOON)
	eq(Profile.refresh(profile, NOON + DAY, first), 0, "nothing to pay")
	eq(profile.rewardsVersion, 1, "new bounties: ask again")
	eq(profile.lastResetPayout, 0, "no payout line")
	eq(profile.cores, 100, "Amber unchanged")
end)

-- The board the owner sees ----------------------------------------------------------

test("the view shows the board, the Haul, swaps and the time left", function()
	local profile = loaded(NOON)
	Profile.bountyEvent(profile, "pop", "HUSK", 12, { credited = true })
	local view = Profile.view(profile, NOON)
	eq(ids(view.daily), "D_COMPY_SWEEP,D_DEEP_TRAIL_15,D_CLEAN_SWEEP", "dailies")
	eq(ids(view.weekly), "W_STAMPEDE,W_ROUGH_COUNTRY,W_DEEP_TRAIL_4", "weeklies")
	eq(view.daily[1].progress, 12, "progress")
	eq(view.daily[1].claimed, false, "claimed")
	eq(view.haulDay, 1, "Haul day")
	eq(view.haulClaimed, false, "Haul not claimed")
	eq(view.dailySwapsLeft, Config.Tuning.DailySwaps, "daily swaps left")
	eq(view.weeklySwapsLeft, Config.Tuning.WeeklySwaps, "weekly swaps left")
	eq(view.secondsToDaily, 12 * 3600, "to the daily reset")
	eq(view.secondsToWeekly, 3 * DAY + 12 * 3600, "to Monday")
	eq(view.lastResetPayout, 0, "no payout")

	Profile.claimHaul(profile, NOON, first)
	local after = Profile.view(profile, NOON)
	eq(after.haulDay, 1, "still day 1")
	eq(after.haulClaimed, true, "claimed today")

	-- The view is a copy: changing it can't change the profile.
	view.daily[1].progress = 9999
	view.daily[1].claimed = true
	eq(profile.rewards.daily[1].progress, 12, "state progress untouched")
	eq(profile.rewards.daily[1].claimed, false, "state claimed untouched")
end)

test("the reset payout is shown until the board is opened, then forgotten", function()
	local profile = loaded(NOON)
	Profile.bountyEvent(profile, "clear", "EASY", 1)
	local tomorrow = NOON + DAY
	local paid = Profile.refresh(profile, tomorrow, first)
	eq(Profile.view(profile, tomorrow).lastResetPayout, paid, "a background read keeps it")
	eq(Profile.view(profile, tomorrow, false).lastResetPayout, paid, "and again")
	eq(Profile.view(profile, tomorrow, true).lastResetPayout, paid, "the open board gets it")
	eq(Profile.view(profile, tomorrow, true).lastResetPayout, 0, "once")
	eq(profile.cores, 100 + paid, "the Amber stays")
end)

-- Match events (PLAN round 2 T28, DECISIONS #66, #82) --------------------------------

test("the species this spec means", function()
	eq(Config.Bounties.W_STAMPEDE.event, "popTotal", "Stampede counts any pop")
	eq(Config.Enemies.ZEP.boss, true, "ZEP (Triceratops) is a boss")
	eq(Config.Enemies.HUSK.boss, false, "HUSK (Compy) isn't")
end)

test("one pop event feeds the species bounty and the pop-any bounty", function()
	local profile = loaded(NOON)
	Profile.bountyEvent(profile, "pop", "HUSK", 1, { credited = true })
	eq(profile.rewards.daily[1].progress, 1, "Compy Sweep")
	eq(profile.rewards.weekly[1].progress, 1, "Stampede")
	Profile.bountyEvent(profile, "pop", "ZEP", 1, { credited = true })
	eq(profile.rewards.daily[1].progress, 1, "another species doesn't count for Compy Sweep")
	eq(profile.rewards.weekly[1].progress, 2, "but does for Stampede")
end)

test("a teammate's pop counts only when it's a boss", function()
	local raw = saved(NOON)
	raw.rewards.weekly[2] = entry("W_HORN_BREAKER")
	local profile = Profile.sanitize(raw, NOON, first)
	Profile.bountyEvent(profile, "pop", "HUSK", 1, { credited = false })
	eq(profile.rewards.daily[1].progress, 0, "a teammate's Compy: not Compy Sweep")
	eq(profile.rewards.weekly[1].progress, 0, "nor Stampede")
	Profile.bountyEvent(profile, "pop", "ZEP", 1, { credited = false })
	eq(profile.rewards.weekly[2].progress, 1, "a teammate's Triceratops: Horn Breaker")
	eq(profile.rewards.weekly[1].progress, 1, "and Stampede")
end)

test("reaching a round, once per round, finishes Deep Trail at its round", function()
	local profile = loaded(NOON)
	local done = ""
	for round = 1, Config.Bounties.D_DEEP_TRAIL_15.count do
		done ..= table.concat(Profile.bountyEvent(profile, "reachRound", nil, round), ",")
	end
	eq(done, "D_DEEP_TRAIL_15", "finished exactly once, at round 15")
	eq(profile.rewardsVersion, 1, "one change")
	eq(profile.cores, 100, "no Amber until it's claimed")
end)

test("a clear counts for the difficulty cleared or an easier bar", function()
	local profile = loaded(NOON)
	local done = Profile.bountyEvent(profile, "clear", "EASY", 1)
	eq(table.concat(done, ","), "D_CLEAN_SWEEP", "Easy: Clean Sweep only")
	eq(profile.rewards.weekly[2].progress, 0, "Rough Country wants Normal or harder")
	done = Profile.bountyEvent(profile, "clear", "HARD", 1)
	eq(table.concat(done, ","), "W_ROUGH_COUNTRY", "Hard clears Rough Country")
end)

test("every event a caller may fire moves some bounty in the pool", function()
	for _, event in Bounties.EVENTS do
		local moved = false
		for _, id in Config.BountyOrder do
			local def = Config.Bounties[id]
			local raw = saved(NOON)
			raw.rewards[def.pool] = { entry(id) }
			local profile = Profile.sanitize(raw, NOON, first)
			local target = if event == "pop" then (if def.event == "pop" then def.target else "HUSK") elseif event == "clear" then "CHAOS" else nil
			local amount = if event == "reachRound" then math.max(def.round, 1) else 1
			Profile.bountyEvent(profile, event, target, amount, { credited = true })
			for _, e in profile.rewards[def.pool] do
				if e.id == id and e.progress > 0 then
					moved = true
				end
			end
		end
		ok(moved, `{event} moves at least one bounty`)
	end
end)

test("an unknown event or a bad amount changes nothing", function()
	local profile = loaded(NOON)
	for _, call in { { "chest", nil, 1 }, { "popTotal", nil, 50 }, { "pop", "HUSK", 0 }, { "pop", "HUSK", -3 }, { "pop", "HUSK", 0.5 }, { "pop", "NOPE", 5 } } do
		eq(#Profile.bountyEvent(profile, call[1], call[2], call[3], { credited = true }), 0, `{call[1]} finished nothing`)
	end
	local total = 0
	for _, pool in Bounties.POOLS do
		for _, e in profile.rewards[pool] do
			total += e.progress
		end
	end
	eq(total, 5, "only the unknown species counted, and only for Stampede")
	eq(profile.rewards.weekly[1].progress, 5, "Stampede")
	eq(profile.cores, 100, "no Amber")
end)

test("the toast names the bounty by its title and Amber", function()
	eq(Bounties.doneText("D_RAPTOR_CULL"), `Bounty ready: Raptor Cull (claim +{amberOf("D_RAPTOR_CULL")} Amber at the Hunt Board)`, "Raptor Cull")
	eq(Bounties.doneText("W_TYRANTS_END"), `Bounty ready: Tyrant's End (claim +{amberOf("W_TYRANTS_END")} Amber at the Hunt Board)`, "Tyrant's End")
	eq(Bounties.doneText("NOT_A_BOUNTY"), nil, "unknown id")
	for _, id in Config.BountyOrder do
		ok(Bounties.doneText(id) ~= nil, `{id} has a toast`)
	end
end)

-- Player level (PLAN T56) -------------------------------------------------------------

test("an old save (no playerXp, no equipped) loads at 0 XP, nothing equipped, everything else kept", function()
	local profile = Profile.sanitize(saved(NOON), NOON, first)
	eq(profile.playerXp, 0, "player XP")
	eq(next(profile.equipped), nil, "nothing equipped")
	eq(profile.cores, 100, "Amber kept")
	eq(profile.mastery.RIFLE, 2, "mastery kept")
	eq(Profile.blank(NOON, first).playerXp, 0, "a new player")
end)

test("garbage player XP or equipped never loads, and never costs the rest of the save", function()
	for _, bad in { -5 :: any, "9000", 0 / 0, math.huge, {}, true } do
		local raw = saved(NOON)
		raw.playerXp = bad
		raw.equipped = { title = 7, [5] = "x", hat = string.rep("a", 65), gunTint = "TINT_FERN" }
		local profile = Profile.sanitize(raw, NOON, first)
		eq(profile.playerXp, 0, `player XP {bad}`)
		eq(next(profile.equipped), nil, "level 1 wears nothing: every item dropped (#178)")
		eq(profile.cores, 100, "Amber kept")
		checkBoard(profile.rewards, "board kept")
	end
	eq(Profile.sanitize({ playerXp = 1082750.9 }, NOON, first).playerXp, 1082750, "floored")
end)

test("player XP and equipped save and load back the same", function()
	local profile = loaded(NOON)
	eq(Profile.addPlayerXp(profile, 6300), 6300, "added: level 10")
	ok(Profile.equip(profile, "title", "TITLE_10"), "level 10's title")
	ok(Profile.equip(profile, "hat", "HAT_BUSH"), "level 10's hat")
	local again = Profile.sanitize(Profile.toSave(profile), NOON, first)
	eq(again.playerXp, 6300, "player XP")
	eq(again.equipped.title, "TITLE_10", "equipped title")
	eq(again.equipped.hat, "HAT_BUSH", "equipped hat")
end)

test("player XP only goes up", function()
	local profile = loaded(NOON)
	Profile.addPlayerXp(profile, 1000)
	for _, bad in { -300 :: any, 0 / 0, math.huge, "50", nil } do
		eq(Profile.addPlayerXp(profile, bad), 0, `adding {bad}`)
	end
	eq(profile.playerXp, 1000, "untouched")
	eq(Profile.addPlayerXp(profile, 12.7), 12, "whole XP")
	eq(profile.playerXp, 1012, "added")
end)

test("a broken Hunt Board never costs the player level", function()
	local raw = saved(NOON)
	raw.playerXp = 83300
	local profile
	withBrokenRules(function()
		profile = Profile.sanitize(raw, NOON, first)
	end)
	eq(profile.rewards, nil, "no Hunt Board this session")
	eq(profile.playerXp, 83300, "player XP loaded")
	Profile.addPlayerXp(profile, 100)
	local out = Profile.toSave(profile)
	eq(out.playerXp, 83400, "player XP saved")
	ok(out.rewards == raw.rewards, "the stored board is still written back untouched")
end)

-- Cosmetics on the profile (PLAN T57, DECISIONS #178) --------------------------------

local PlayerLevel = require(src.shared.PlayerLevel)

test("an old or bad `equipped` loads as {} (#178)", function()
	local cases = {
		{ "no equipped (an older save)", nil },
		{ "not a table", "TITLE_10" },
		{ "unknown ids", { title = "TITLE_NOPE", gunTint = "TINT_RED" } },
		{ "wrong kind", { title = "HAT_BUSH", hat = "TITLE_10" } },
		{ "above the level", { set = "SET_METEOR", title = "TITLE_ELDER_250" } },
		{ "unknown slot", { cape = "HAT_BUSH" } },
		{ "the bare repeating row", { title = "TITLE_ELDER" } },
	}
	for _, case in cases do
		local raw = saved(NOON)
		raw.playerXp = PlayerLevel.xpFor(100) -- level 100: everything to 100 is unlocked
		raw.equipped = case[2]
		local profile = Profile.sanitize(raw, NOON, first)
		eq(next(profile.equipped), nil, case[1])
		eq(profile.playerXp, PlayerLevel.xpFor(100), `{case[1]}: player XP kept`)
		eq(profile.cores, 100, `{case[1]}: Amber kept`)
	end
end)

test("a good `equipped` loads with the bad slots alone dropped", function()
	local raw = saved(NOON)
	raw.playerXp = PlayerLevel.xpFor(50)
	raw.equipped = { title = "TITLE_50", hat = "HAT_RANGER", trail = "TRAIL_FERN", nameColour = "NAME_FERN" }
	local profile = Profile.sanitize(raw, NOON, first)
	eq(profile.equipped.title, "TITLE_50", "title kept")
	eq(profile.equipped.hat, "HAT_RANGER", "hat kept")
	eq(profile.equipped.trail, nil, "level 80's trail dropped at level 50")
	eq(profile.equipped.nameColour, "NAME_FERN", "level 2's common kept")
end)

test("equip: the server refuses an item above your level, the wrong slot, or junk", function()
	local profile = loaded(NOON)
	Profile.addPlayerXp(profile, PlayerLevel.xpFor(29)) -- level 29
	local okHat = Profile.equip(profile, "hat", "HAT_BUSH")
	ok(okHat, "level 10's hat at level 29")
	local refused, why = Profile.equip(profile, "hitMarker", "MARK_TOOTH")
	eq(refused, false, "level 30's hit-marker at 29")
	eq(why, "Unlocks at player level 30", "says when")
	eq(profile.equipped.hitMarker, nil, "nothing worn")
	eq((Profile.equip(profile, "title", "HAT_BUSH")), false, "a hat isn't a title")
	eq((Profile.equip(profile, "cape", "HAT_BUSH")), false, "no such slot")
	eq((Profile.equip(profile, "hat", 42)), false, "not a string")
	eq((Profile.equip(profile, "hat", "NOPE")), false, "unknown id")
	eq(profile.equipped.hat, "HAT_BUSH", "the refusals changed nothing")
	ok(Profile.equip(profile, "hat", ""), "taking it off is always allowed")
	eq(profile.equipped.hat, nil, "off")
	Profile.addPlayerXp(profile, PlayerLevel.xpFor(30) - PlayerLevel.xpFor(29))
	ok(Profile.equip(profile, "hitMarker", "MARK_TOOTH"), "at level 30 it's allowed")
end)

test("XP that arrives while the save loads is banked once, after it (#179)", function()
	local held = Profile.newHeld()
	ok(Profile.hold(held, 5100), "held while loading")
	ok(Profile.hold(held, 600), "and more")
	local profile = loaded(NOON)
	Profile.addPlayerXp(profile, 1000) -- what the save already had
	local added, dropped = Profile.settleHeld(held, profile)
	eq(added, 5700, "added when the load succeeds")
	eq(dropped, 0, "nothing dropped")
	eq(profile.playerXp, 6700, "on top of the save")
	local again = Profile.settleHeld(held, profile)
	eq(again, 0, "a second settle adds nothing")
	eq(profile.playerXp, 6700, "banked once, not twice")
	eq(Profile.hold(held, 300), false, "after the load, XP goes straight on (not held)")
	eq(profile.playerXp, 6700, "and the hold didn't touch the profile")
end)

test("a failed load drops the held XP and writes nothing (#179)", function()
	local held = Profile.newHeld()
	Profile.hold(held, 5700)
	local added, dropped = Profile.settleHeld(held, nil)
	eq(added, 0, "nothing added")
	eq(dropped, 5700, "dropped (Progression warns once)")
	eq(select(2, Profile.settleHeld(held, nil)), 0, "dropped once")
	ok(not Profile.hold(held, 10), "nothing held after the load ended")
end)

-- T80: ranked fields, escrow, settle (DECISIONS #216, #218) ----------------------------

test("T80 an older save loads with 0 Trophies, no best arena, no escrow", function()
	local p = Profile.sanitize({ cores = 40, highestRound = 3 }, NOON, first)
	eq(p.trophies, 0)
	eq(p.bestArena, nil)
	eq(p.escrow, nil)
	eq(p.cores, 40, "the rest kept")
end)

test("T80 sanitize: garbage Trophies / arena / escrow are dropped; good ones kept", function()
	local bad = Profile.sanitize({ trophies = -5, bestArena = "NOPE", escrow = { matchId = 7, amount = 15 } }, NOON, first)
	eq(bad.trophies, 0)
	eq(bad.bestArena, nil)
	eq(bad.escrow, nil)
	local nan = Profile.sanitize({ trophies = 0 / 0, escrow = { matchId = "m", amount = 0 / 0 } }, NOON, first)
	eq(nan.trophies, 0)
	eq(nan.escrow, nil)
	local good = Profile.sanitize({ trophies = 650.7, escrow = { matchId = "m1", amount = 15 } }, NOON, first)
	eq(good.trophies, 650)
	eq(good.bestArena, Config.Arenas[3].key, "arena from the Trophies (600 floor)")
	eq(good.escrow.matchId, "m1")
	eq(good.escrow.amount, 15)
	-- A stored best arena above the Trophies' one is kept (it's never lost).
	local kept = Profile.sanitize({ trophies = 10, bestArena = Config.Arenas[4].key }, NOON, first)
	eq(kept.bestArena, Config.Arenas[4].key)
end)

test("T80 toSave round-trips Trophies, best arena and escrow", function()
	local p = Profile.sanitize({ trophies = 320, escrow = { matchId = "m2", amount = 15 } }, NOON, first)
	local again = Profile.sanitize(Profile.toSave(p), NOON, first)
	eq(again.trophies, 320)
	eq(again.bestArena, Config.Arenas[2].key)
	eq(again.escrow.matchId, "m2")
end)

test("T80 stake: Amber into escrow once; refused while open or unaffordable", function()
	local p = Profile.blank(NOON, first)
	p.cores = 20
	eq(Profile.stake(p, "m", 15), true)
	eq(p.cores, 5)
	eq(p.escrow.amount, 15)
	eq(Profile.stake(p, "m2", 1), false, "one escrow at a time")
	local poor = Profile.blank(NOON, first)
	poor.cores = 14
	eq(Profile.stake(poor, "m", 15), false)
	eq(poor.cores, 14)
	eq(poor.escrow, nil)
end)

test("T80 refund on load: an unsettled escrow comes back once; a blank (failed) load has none", function()
	local p = Profile.sanitize({ cores = 5, escrow = { matchId = "crashed", amount = 15 } }, NOON, first)
	eq(Profile.refundEscrow(p), 15)
	eq(p.cores, 20)
	eq(p.escrow, nil)
	eq(Profile.refundEscrow(p), 0, "only once")
	eq(Profile.refundEscrow(Profile.blank(NOON, first)), 0, "a failed load's blank profile refunds nothing")
end)

test("T80 a leaver forfeits: the escrow closes with nothing back", function()
	local p = Profile.blank(NOON, first)
	p.cores = 15
	Profile.stake(p, "m", 15)
	eq(Profile.forfeitEscrow(p, "other"), false, "only that match's")
	eq(Profile.forfeitEscrow(p, "m"), true)
	eq(p.cores, 0)
	eq(p.escrow, nil)
end)

test("T80 settleBattle: pay, Trophies (floor holds) and that match's escrow cleared together", function()
	local p = Profile.sanitize({ cores = 0, trophies = 310, escrow = { matchId = "m", amount = 15 } }, NOON, first)
	local change, reached = Profile.settleBattle(p, "m", 80, -30)
	eq(p.escrow, nil, "settled + cleared in the same step")
	eq(p.cores, 80)
	eq(p.trophies, 300, "the arena floor holds")
	eq(change, -10)
	eq(#reached, 0)
	local up = Profile.sanitize({ trophies = 290 }, NOON, first)
	local _, newOnes = Profile.settleBattle(up, nil, 5, 30)
	eq(up.trophies, 320)
	eq(#newOnes, 1)
	eq(newOnes[1], 2)
	eq(up.bestArena, Config.Arenas[2].key)
	local other = Profile.sanitize({ escrow = { matchId = "old", amount = 15 } }, NOON, first)
	Profile.settleBattle(other, "new", 0, 0)
	eq(other.escrow.matchId, "old", "another match's escrow waits for the load refund")
end)

test("T80 Server/Progression: refund on load only after a good load; leave / shutdown paths", function()
	local fs = require("@lune/fs")
	local src = fs.readFile("src/server/Progression.luau")
	local canSaveAt = src:find("canSave[player] = profile ~= nil", 1, true)
	local refundAt = src:find("local refunded = Profile.refundEscrow(loaded)", 1, true)
	ok(canSaveAt ~= nil and refundAt ~= nil and canSaveAt < refundAt, "refund after the load is judged")
	ok(src:find("if not profile or not canSave[player] or not store then", 1, true) ~= nil, "save never writes a failed load")
	ok(src:find("Profile.leaveRanked(", 1, true) ~= nil, "a leaver forfeits and loses Trophies (T82)")
	local leaveAt = src:find("Profile.leaveRanked(", 1, true)
	local saveAt = src:find("save(player)\n\t\tprofiles[player] = nil", 1, true)
	ok(leaveAt ~= nil and saveAt ~= nil and leaveAt < saveAt, "the Trophies drop before the leaver's last save (same save)")
	ok(src:find("Profile.refundEscrow(profile) -- an open stake comes back on a shutdown", 1, true) ~= nil, "BindToClose refunds")
end)

-- T82: a Ranked leaver loses Trophies as last place (DECISIONS #233) ----------------------

test("T82 Trophies.leaverDelta is last place: Camp Clash the loss, Bone Rush last of n", function()
	eq(Trophies.leaverDelta("TEAM", 2), Config.Tuning.TeamLossTrophies)
	eq(Trophies.leaverDelta("TEAM", 3), Config.Tuning.TeamLossTrophies)
	eq(Trophies.leaverDelta("ROYALE", 10), Config.Tuning.RoyaleLastTrophies)
	eq(Trophies.leaverDelta("ROYALE", 10), Trophies.delta("ROYALE", 10, 10))
	eq(Trophies.leaverDelta("ROYALE", 3), Trophies.delta("ROYALE", 3, 3))
	ok(Trophies.leaverDelta("ROYALE", 3) < 0, "last of 3 loses")
	eq(Trophies.leaverDelta("TEAM", 2, true), 0, "Practice")
	eq(Trophies.leaverDelta("COOP", 1), 0, "co-op never")
end)

test("T82 leaveRanked: escrow forfeited and Trophies dropped together; floor holds", function()
	local p = Profile.sanitize({ cores = 5, trophies = 500, escrow = { matchId = "m", amount = 15 } }, NOON, first)
	eq(Profile.leaveRanked(p, "m", "TEAM", 2, false), Config.Tuning.TeamLossTrophies)
	eq(p.trophies, 500 + Config.Tuning.TeamLossTrophies)
	eq(p.escrow, nil, "forfeited")
	eq(p.cores, 5, "nothing back")
	local floor = Profile.sanitize({ trophies = 310, escrow = { matchId = "m", amount = 15 } }, NOON, first)
	eq(Profile.leaveRanked(floor, "m", "ROYALE", 10, false), -10)
	eq(floor.trophies, 300, "the arena floor holds")
	local practice = Profile.sanitize({ trophies = 500, escrow = { matchId = "m", amount = 15 } }, NOON, first)
	eq(Profile.leaveRanked(practice, "m", "TEAM", 2, true), 0)
	eq(practice.trophies, 500)
	eq(practice.escrow, nil, "the Practice stake still stays in the pot")
end)

test("T82 leaveRanked touches nothing without that match's open escrow", function()
	local casual = Profile.sanitize({ trophies = 500 }, NOON, first)
	eq(Profile.leaveRanked(casual, "m", "TEAM", 2, false), 0)
	eq(casual.trophies, 500, "a casual leaver keeps their Trophies")
	local other = Profile.sanitize({ trophies = 500, escrow = { matchId = "old", amount = 15 } }, NOON, first)
	eq(Profile.leaveRanked(other, "new", "TEAM", 2, false), 0)
	eq(other.trophies, 500)
	eq(other.escrow.matchId, "old", "another match's escrow waits for the load refund")
end)
