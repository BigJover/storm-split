--[[
	Training (PLAN 10c T139, DECISIONS #370-#374, #391, #397): Shared/Training's levels, caps,
	online-only accrual (full at the station, half elsewhere, clamped ticks, nothing for time
	away), slots, the Amber finish price, and the save round trip through Shared/Profile and
	Shared/SaveStore on a fake store. Plus: the trained % reach the body, melee and grenade.
]]
local fs = require("@lune/fs")
local Config = require(src.shared.Config)
local Training = require(src.shared.Training)
local Profile = require(src.shared.Profile)
local SaveStore = require(src.shared.SaveStore)
local HunterStats = require(src.shared.HunterStats)
local Melee = require(src.shared.Melee)
local Grenade = require(src.shared.Grenade)

local t = Config.Tuning
local NOON = 1_800_000_000
local function rng(_n: number): number
	return 1
end

-- `seconds` of one-second ticks, standing at `at`.
local function run(state, seconds: number, at: string?)
	local leveled = {}
	for _ = 1, seconds do
		for _, stat in Training.tick(state, 1, at, 1) do
			table.insert(leveled, stat)
		end
	end
	return leveled
end

test("caps reuse the Tuning rows (#397); 10 equal levels reach each cap exactly", function()
	eq(Training.levels(), 10)
	local caps = { reach = 20, speed = 15, health = 10, throw = 30 } -- #370
	eq(Training.cap("health"), t.TrainedHealthMax, "Trained health max is the only source")
	eq(Training.cap("speed"), t.TrainedSpeedMax)
	eq(Training.cap("reach"), t.TrainedReachMax)
	eq(Training.cap("throw"), t.TrainedThrowMax)
	for stat, cap in caps do
		eq(Training.cap(stat), cap, stat)
		local state = Training.blank()
		state.levels[stat] = 10
		eq(Training.percent(state, stat), cap, `{stat} at level 10 = +{cap}%`)
		state.levels[stat] = 1
		eq(Training.percent(state, stat), cap / 10, `{stat} step`)
	end
	eq(Training.cap("nope"), 0)
end)

test("level L takes 10 x L minutes at full rate: 550 min a stat (#371)", function()
	eq(Training.levelSeconds(1), 600)
	eq(Training.levelSeconds(10), 6000)
	local total = 0
	for level = 1, 10 do
		total += Training.levelSeconds(level)
	end
	eq(total, 550 * 60)
end)

test("full speed at its own station, half elsewhere (online only)", function()
	local state = Training.blank()
	ok(Training.start(state, "reach"))
	eq(#run(state, 599, "reach"), 0, "not yet")
	eq(run(state, 1, "reach")[1], "reach", "level 1 after 600 s at the Raptor Dummy")
	eq(state.levels.reach, 1)
	local away = Training.blank()
	Training.start(away, "reach")
	run(away, 600, nil) -- in a match
	eq(away.levels.reach, 0, "600 s elsewhere is only half a level")
	eq(away.progress.reach, 300)
	run(away, 600, "speed") -- at another stat's station: still elsewhere
	eq(away.levels.reach, 1, "1200 s elsewhere = one level")
	eq(Training.rate("reach", "reach"), 1)
	eq(Training.rate("reach", "throw"), t.TrainingElsewhereRate)
	eq(t.TrainingElsewhereRate, 0.5)
end)

test("tick gaps clamp to the tick length: a hitch or a clock jump never over-credits", function()
	local state = Training.blank()
	Training.start(state, "speed")
	Training.tick(state, 3600, "speed", 1)
	eq(state.progress.speed, 1, "an hour-long gap = one tick")
	Training.tick(state, -50, "speed", 1)
	Training.tick(state, 0 / 0, "speed", 1)
	Training.tick(state, math.huge, "speed", 1)
	eq(state.progress.speed, 1, "negative, NaN and infinite gaps credit nothing")
	Training.tick(state, 0.5, "speed", 1)
	eq(state.progress.speed, 1.5, "a short tick counts as it is")
end)

test("nothing trains with nothing started; a load never credits time away", function()
	local idle = Training.blank()
	run(idle, 1000, "reach")
	eq(idle.levels.reach, 0, "standing on a pad without E trains nothing")
	eq(idle.progress.reach, 0)
	local state = Training.blank()
	Training.start(state, "health")
	run(state, 120, "health")
	local stored = Training.toSave(state)
	-- Whatever a save carries about time (or a forged field) never becomes progress.
	stored.savedAt, stored.lastSeen, stored.offlineSeconds = 0, 0, 10 ^ 9
	local back = Training.sanitize(stored)
	eq(back.progress.health, 120, "exactly what was banked")
	eq(back.levels.health, 0)
	eq(back.active[1], "health", "still training after the load")
	eq(Training.sanitize({ levels = { reach = 99 }, progress = { reach = 10 ^ 9 } }).levels.reach, 10, "levels capped")
	eq(Training.sanitize({ levels = { reach = 2 }, progress = { reach = 10 ^ 9 } }).progress.reach, Training.levelSeconds(3), "progress capped at one level")
	eq(Training.sanitize({ levels = { reach = -3, speed = "x" } }).levels.reach, 0)
	eq(Training.sanitize(nil).levels.throw, 0, "an older save: level 0")
	eq(#Training.sanitize({ active = { "reach", "speed", "bogus" } }).active, 1, "at most the slot count")
end)

test("one slot: a new station takes over, the old stat keeps its progress", function()
	eq(t.TrainingSlots, 1)
	local state = Training.blank()
	Training.start(state, "reach")
	run(state, 100, "reach")
	ok(Training.start(state, "throw"))
	eq(#state.active, 1)
	eq(state.active[1], "throw")
	run(state, 100, "throw")
	eq(state.progress.reach, 100, "reach kept, not training")
	eq(state.progress.throw, 100)
	local two = Training.blank()
	Training.start(two, "reach", 2)
	Training.start(two, "speed", 2)
	run(two, 10, "reach")
	eq(two.progress.reach, 10)
	eq(two.progress.speed, 5, "a 2nd slot (the pass, later) trains another at half")
	local okStart, why = Training.start(state, "nope")
	ok(not okStart and why == "Unknown station", "unknown stat refused")
end)

test("a stat stops at its cap: level 10 exactly, then it can't train", function()
	local state = Training.blank()
	Training.start(state, "throw")
	local leveled = Training.credit(state, 550 * 60 + 5000)
	eq(#leveled, 10)
	eq(state.levels.throw, 10)
	eq(Training.percent(state, "throw"), 30, "+30% throw, no more")
	eq(#state.active, 0, "the slot is free")
	eq(state.progress.throw, 0)
	local okStart, why = Training.start(state, "throw")
	ok(not okStart and why == "Fully trained")
	run(state, 100, "throw")
	eq(state.levels.throw, 10)
	eq(Training.remaining(state, "throw"), 0)
end)

test("Amber finish: blank price = not for sale; priced per whole remaining minute", function()
	local state = Training.blank()
	Training.start(state, "speed")
	run(state, 90, "speed")
	eq(t.TrainingFinishAmberPerMin, nil, "the sheet leaves it blank until the Director sets it")
	eq(Training.finishPrice(state, "speed"), nil)
	local tuning = t :: any
	local okSet = pcall(function()
		tuning.TrainingFinishAmberPerMin = 1000
	end)
	if okSet then
		eq(Training.finishPrice(state, "speed"), 9000, "510 s left = 9 minutes (rounded up)")
		ok(Training.finish(state, "speed"))
		eq(state.levels.speed, 1)
		eq(state.progress.speed, 0)
		state.levels.speed = 10
		eq(Training.finishPrice(state, "speed"), nil, "maxed: nothing to finish")
		tuning.TrainingFinishAmberPerMin = nil
	end
	eq(Training.finishPrice(state, "bogus"), nil)
end)

test("saved through Profile + SaveStore: round trip on a fake store; old saves migrate to 0", function()
	local data: { [string]: any } = {}
	local store = {
		update = function(key: string, transform: (any) -> any): any
			local value = transform(data[key])
			if value ~= nil then
				data[key] = value
			end
			return data[key]
		end,
		budget = function(): number
			return math.huge
		end,
	}
	local env = { now = function() return NOON end, wait = function(_s: number) end, log = function(_m: string) end }
	local status, raw = SaveStore.load(store, "player_1", "A", env)
	eq(status, "ok")
	local profile = Profile.sanitize(raw, NOON, rng)
	eq(profile.training.levels.reach, 0, "a new player")
	Training.start(profile.training, "reach")
	Training.credit(profile.training, 600 + 42)
	eq(SaveStore.write(store, "player_1", "A", env, function()
		return Profile.toSave(profile)
	end, true), "ok")
	local status2, raw2 = SaveStore.load(store, "player_1", "B", env)
	eq(status2, "ok")
	local back = Profile.sanitize(raw2, NOON + 86400 * 30, rng) -- a month later
	eq(back.training.levels.reach, 1)
	eq(back.training.progress.reach, 42, "a month away credits nothing (online only)")
	eq(back.training.active[1], "reach")
	-- A save from before T139 (no training) loads at level 0 and keeps everything else.
	local old = Profile.sanitize({ cores = 5000, amberScale = Profile.AMBER_SCALE }, NOON, rng)
	eq(old.cores, 5000)
	for _, stat in Training.STATS do
		eq(old.training.levels[stat], 0, `{stat} starts at 0`)
	end
end)

test("trained % reach the game: body HP/speed, melee reach, grenade range", function()
	local state = Training.blank()
	for _, stat in Training.STATS do
		state.levels[stat] = 10
	end
	for key in Config.Heroes do
		local base = HunterStats.body(key)
		local trained = HunterStats.body(key, { healthPercent = Training.percent(state, "health"), speedPercent = Training.percent(state, "speed") })
		near(trained.maxHealth, base.maxHealth * 1.10, `{key} health +10%`, 1e-6)
		near(trained.walkSpeed, base.walkSpeed * 1.15, `{key} speed +15%`, 1e-6)
		near(Melee.reach(key, Training.percent(state, "reach")), Melee.reach(key) * 1.2, `{key} reach +20%`, 1e-6)
		near(Grenade.range(key, Training.percent(state, "throw")), Grenade.range(key) * 1.3, `{key} throw +30%`, 1e-6)
	end
	local server = fs.readFile("src/server/Progression.luau")
	ok(string.find(server, "player:SetAttribute(HunterKit.REACH_ATTRIBUTE, Training.percent(state, \"reach\"))", 1, true), "reach published")
	ok(string.find(server, "player:SetAttribute(HunterKit.THROW_ATTRIBUTE, Training.percent(state, \"throw\"))", 1, true), "throw published")
	local health = fs.readFile("src/server/Health.luau")
	ok(string.find(health, "player:GetAttribute(\"TrainedHealth\"), player:GetAttribute(\"TrainedSpeed\")", 1, true), "Health reads the trained body")
	local trainingServer = fs.readFile("src/server/Training.luau")
	ok(not string.find(trainingServer, "GetService(\"VirtualUser\")", 1, true), "never fights the idle kick")
	ok(string.find(trainingServer, "Progression.trainingTick, player, dt, Training.stationOf(player), TICK", 1, true), "ticks are clamped to TICK")
end)

test("display lines", function()
	local state = Training.blank()
	state.levels.reach = 3
	Training.start(state, "reach")
	state.progress.reach = Training.levelSeconds(4) * 0.4
	local rows = Training.view(state)
	eq(Training.line(rows[1]), "Reach  Lv 3/10  +6% of +20%  training 40%")
	state.levels.speed = 10
	eq(Training.line(Training.view(state)[2]), "Speed  Lv 10/10  +15% of +15%  MAX")
	eq(Training.line(Training.view(state)[3]), "Health  Lv 0/10  +0% of +10%")
	local back = Training.fromAttributes(function(name)
		return ({ TrainLevel_reach = 3, TrainProgress_reach = 7, TrainActive = "reach" } :: any)[name]
	end)
	eq(back.levels.reach, 3)
	eq(back.progress.reach, 7)
	eq(back.active[1], "reach")
end)
