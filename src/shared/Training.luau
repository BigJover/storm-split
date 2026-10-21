--!strict
--[[
	Training (PLAN 10c T139, DECISIONS #370-#374, #391, #397): four account-wide stats (shared
	by every hunter) trained at the Hunters' Outpost stations. Pure: no clock, no services;
	Server/Progression holds the state (it's part of the saved Profile) and Server/Training
	drives the tick. Numbers are on the Tuning sheet.

	  STATS                  "reach", "speed", "health", "throw" (Shared/Outpost's station keys)
	  cap(stat)              Trained <stat> max % (Tuning; #397: the only source)
	  step(stat)             cap / Training levels: the % one level adds
	  percent(state, stat)   level x step: what the stat adds now (HunterStats, Melee, Grenade)
	  levelSeconds(level)    seconds of full-rate training to reach `level` from the one
	                         below: Train minutes x level x 60 (#371)
	  rate(stat, at)         1 at that stat's own station (`at` = the station key stood at),
	                         Training elsewhere rate (half) anywhere else in the game
	  blank()                a new player's training: every level 0, nothing training
	  sanitize(raw)          any stored value -> a valid state (an older save without
	                         training gets blank()). Nothing about time is stored or read, so
	                         a load can never credit time spent away (online only, #391).
	  toSave(state)          the table to store
	  start(state, stat, slots)   train `stat` (a station's E). Already training: no change.
	                         With every slot busy, the stat trained longest ago makes room
	                         (its progress is kept). A maxed stat is refused.
	  tick(state, dt, at, tickLength)   one server tick of ONLINE time: dt is clamped to
	                         0..tickLength (a server hitch, a clock jump or a negative gap can
	                         never over-credit); each training stat gains dt x rate seconds
	                         and levels up as they fill; a maxed stat stops training.
	                         Returns the stats that levelled.
	  remaining(state, stat) seconds of full-rate training left in the current level
	  finishPrice(state, stat)   Amber to finish the current level now: whole remaining
	                         minutes (rounded up) x Training finish Amber per min; nil while
	                         that price is blank (not for sale) or the stat is maxed
	  finish(state, stat)    complete the current level (the caller took the Amber)
	  credit(state, seconds) Studio test aid `trainskip <min>`: that many full-rate seconds
	                         to every training stat (Server/Training asks StudioOnly first)
	  view(state)            what the Profile / Outpost UI shows, per stat
	  NAMES                  the shown stat words (DINO_REVIEW Round 20): Reach, Speed, Health, Throw
	  line(row)              one stat's text, e.g. "Reach  Lv 3/10  +6% of +20%  training 40%"
	  fromAttributes(get)    a State rebuilt from the Player attributes Progression publishes
	                         (TrainLevel_/TrainProgress_<stat>, TrainActive): the client's copy
]]

local Config = require(script.Parent.Config)

local Training = {}

export type Stat = "reach" | "speed" | "health" | "throw"
export type State = {
	levels: { [string]: number },
	progress: { [string]: number }, -- full-rate seconds banked toward the next level
	active: { string }, -- training now, oldest first (at most the slot count)
}
export type Row = { stat: string, level: number, max: number, percent: number, cap: number, progress: number, need: number, active: boolean }

Training.STATS = table.freeze({ "reach", "speed", "health", "throw" }) :: { string }

local CAP_KEYS = table.freeze({
	reach = "TrainedReachMax",
	speed = "TrainedSpeedMax",
	health = "TrainedHealthMax",
	throw = "TrainedThrowMax",
})

local function isStat(stat: unknown): boolean
	return type(stat) == "string" and (CAP_KEYS :: any)[stat] ~= nil
end
Training.isStat = isStat

function Training.levels(): number
	return math.max(1, math.floor(Config.Tuning.TrainingLevels))
end

function Training.cap(stat: string): number
	local key = (CAP_KEYS :: any)[stat]
	return if key then (Config.Tuning :: any)[key] or 0 else 0
end

function Training.step(stat: string): number
	return Training.cap(stat) / Training.levels()
end

function Training.percent(state: State, stat: string): number
	return (state.levels[stat] or 0) * Training.step(stat)
end

function Training.levelSeconds(level: number): number
	return Config.Tuning.TrainMinutes * 60 * level
end

function Training.rate(stat: string, at: unknown): number
	return if at == stat then 1 else Config.Tuning.TrainingElsewhereRate
end

function Training.blank(): State
	local state: State = { levels = {}, progress = {}, active = {} }
	for _, stat in Training.STATS do
		state.levels[stat] = 0
		state.progress[stat] = 0
	end
	return state
end

local function maxed(state: State, stat: string): boolean
	return (state.levels[stat] or 0) >= Training.levels()
end

local function finiteNumber(value: unknown): number?
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return nil
	end
	return value
end

-- `slots`: the most stats a save may keep training (default the sheet's; Profile passes
-- the most any pass allows, T143, and Progression trims to the player's own count).
function Training.sanitize(raw: unknown, slots: number?): State
	local state = Training.blank()
	if type(raw) ~= "table" then
		return state
	end
	local t = raw :: any
	local top = Training.levels()
	for _, stat in Training.STATS do
		local level = finiteNumber(type(t.levels) == "table" and t.levels[stat] or nil)
		state.levels[stat] = if level then math.clamp(math.floor(level), 0, top) else 0
		local progress = finiteNumber(type(t.progress) == "table" and t.progress[stat] or nil)
		if progress and state.levels[stat] < top then
			-- Never more than the level needs (a full bar levels on the next tick).
			state.progress[stat] = math.clamp(progress, 0, Training.levelSeconds(state.levels[stat] + 1))
		end
	end
	if type(t.active) == "table" then
		local keep = math.max(1, math.floor(slots or Config.Tuning.TrainingSlots))
		for _, stat in t.active do
			if isStat(stat) and not table.find(state.active, stat) and not maxed(state, stat) and #state.active < keep then
				table.insert(state.active, stat)
			end
		end
	end
	return state
end

function Training.toSave(state: State): { [string]: any }
	return {
		levels = table.clone(state.levels),
		progress = table.clone(state.progress),
		active = table.clone(state.active),
	}
end

function Training.start(state: State, stat: unknown, slots: number?): (boolean, string)
	if not isStat(stat) then
		return false, "Unknown station"
	end
	local key = stat :: string
	if maxed(state, key) then
		return false, "Fully trained"
	end
	if table.find(state.active, key) then
		return true, "Already training"
	end
	local n = math.max(1, math.floor(slots or Config.Tuning.TrainingSlots))
	while #state.active >= n do
		table.remove(state.active, 1)
	end
	table.insert(state.active, key)
	return true, "Training"
end

local function levelUp(state: State, stat: string, leveled: { string })
	while not maxed(state, stat) do
		local need = Training.levelSeconds(state.levels[stat] + 1)
		if state.progress[stat] < need then
			return
		end
		state.progress[stat] -= need
		state.levels[stat] += 1
		table.insert(leveled, stat)
	end
	state.progress[stat] = 0
	local index = table.find(state.active, stat)
	if index then
		table.remove(state.active, index) -- maxed: the slot is free
	end
end

local function add(state: State, seconds: number, at: unknown, fullRate: boolean): { string }
	local leveled = {}
	for _, stat in table.clone(state.active) do
		local rate = if fullRate then 1 else Training.rate(stat, at)
		state.progress[stat] = (state.progress[stat] or 0) + seconds * rate
		levelUp(state, stat, leveled)
	end
	return leveled
end

-- `speed`: the 2× Training pass (T143, Store.passEffects; 1 without it). It multiplies the
-- clamped tick, so a hitch still can't over-credit, and the caps are the same for everyone.
function Training.tick(state: State, dt: unknown, at: unknown, tickLength: number, speed: number?): { string }
	local seconds = finiteNumber(dt) or 0
	seconds = math.clamp(seconds, 0, math.max(0, tickLength))
	if seconds <= 0 then
		return {}
	end
	local x = finiteNumber(speed) or 1
	return add(state, seconds * math.clamp(x, 1, 4), at, false)
end

function Training.credit(state: State, seconds: unknown): { string }
	local s = finiteNumber(seconds) or 0
	if s <= 0 then
		return {}
	end
	return add(state, s, nil, true)
end

function Training.remaining(state: State, stat: string): number
	if not isStat(stat) or maxed(state, stat) then
		return 0
	end
	return math.max(0, Training.levelSeconds(state.levels[stat] + 1) - (state.progress[stat] or 0))
end

function Training.finishPrice(state: State, stat: unknown): number?
	local perMinute = (Config.Tuning :: any).TrainingFinishAmberPerMin
	if type(perMinute) ~= "number" or perMinute <= 0 or not isStat(stat) or maxed(state, stat :: string) then
		return nil
	end
	local minutes = math.ceil(Training.remaining(state, stat :: string) / 60) -- a started minute counts (#403)
	if minutes <= 0 then
		return nil -- nothing left: no button
	end
	return minutes * perMinute
end

function Training.finish(state: State, stat: unknown): boolean
	if not isStat(stat) or maxed(state, stat :: string) then
		return false
	end
	local key = stat :: string
	state.progress[key] = Training.levelSeconds(state.levels[key] + 1)
	levelUp(state, key, {})
	return true
end

function Training.view(state: State): { Row }
	local rows = {}
	for _, stat in Training.STATS do
		local level = state.levels[stat] or 0
		table.insert(rows, {
			stat = stat,
			level = level,
			max = Training.levels(),
			percent = Training.percent(state, stat),
			cap = Training.cap(stat),
			progress = if level >= Training.levels() then 0 else state.progress[stat] or 0,
			need = if level >= Training.levels() then 0 else Training.levelSeconds(level + 1),
			active = table.find(state.active, stat) ~= nil,
		})
	end
	return rows
end

Training.NAMES = table.freeze({ reach = "Reach", speed = "Speed", health = "Health", throw = "Throw" }) :: { [string]: string }

function Training.line(row: Row): string
	local head = `{Training.NAMES[row.stat] or row.stat}  Lv {row.level}/{row.max}  +{string.format("%g", row.percent)}% of +{string.format("%g", row.cap)}%`
	if row.level >= row.max then
		return `{head}  MAX`
	end
	if row.active then
		return `{head}  training {math.floor(100 * row.progress / math.max(row.need, 1))}%`
	end
	return head
end

function Training.fromAttributes(get: (string) -> any): State
	local raw = { levels = {}, progress = {}, active = {} }
	for _, stat in Training.STATS do
		raw.levels[stat] = get(`TrainLevel_{stat}`)
		raw.progress[stat] = get(`TrainProgress_{stat}`)
	end
	local active = get("TrainActive")
	if type(active) == "string" then
		for stat in string.gmatch(active, "[^,]+") do
			table.insert(raw.active, stat)
		end
	end
	return Training.sanitize(raw)
end

return Training
