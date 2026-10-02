--[[
	Rules for the Hunt Board: the Daily Haul (log-in calendar) and the daily and weekly
	Bounties (DECISIONS #63-#71, #75-#76). Pure: no services, no clock and no random
	numbers of its own, so specs can run it headlessly. Server/Progression owns the saved
	state and pays the Amber this says; nothing here touches a profile or a currency.

	Every number comes from Config: the Daily Haul and Bounties sheets and the REWARDS
	levers on Tuning.

	Callers pass in:
	  now   server time in seconds since 1970 UTC (os.time()); never a client's clock
	  rng   function(n) returning a whole number 1..n (e.g. Random:NextInteger(1, n))

	State (plain data, safe to save as it is):
	  day, week                 the UTC day and week the bounties were last rolled for
	  daily, weekly             lists of { id, progress, claimed }, one per active slot
	  dailySwaps, weeklySwaps   swaps used since the last reset
	  haul = { day, claimedOn } the last Haul day claimed (0 = none yet) and the UTC
	                            day it was claimed on (nil = never)

	Functions that change a state change it in place.

	  dayIndex / weekIndex   UTC day number, and week number starting on Weekly reset
	                         day (1 = Monday) at Daily reset hour UTC
	  secondsToDaily / secondsToWeekly   time left until the next reset
	  slots         the slots on the board for a pool: Daily/Weekly bounties, filled in
	                the order easy, medium, hard
	  roll          a new set for a pool: one bounty per slot, no duplicates
	  fresh         a new player's state
	  sanitize      any saved value -> a valid state (missing or broken -> fresh;
	                unknown ids dropped and refilled), so old saves load cleanly
	  refresh       call before reading or changing a state: a new day rolls the
	                dailies and resets the daily swaps, a new week the weeklies.
	                Bounties that were done but not claimed are paid: returns that
	                Amber (0 if none)
	  canClaimHaul / claimHaul   once per UTC day; day 1 -> last, then round again. A
	                missed day only pauses it, unless Haul resets after missed days
	                is above 0
	  haulToday     which Haul day today is, and whether it's been claimed
	  nextHaulDay   the Haul day the next claim pays (the pause / reset rule)
	  progress      count a match event towards the active bounties; returns the ids
	                that event finished
	  isDone        has this entry reached its Count
	  claim         take a finished bounty's Amber, once
	  swapsLeft     swaps still allowed for a pool
	  swap          trade an unfinished, unclaimed bounty for another from its slot
	                (never itself, never one already on the board), within the
	                swap allowance
	  claimable     is there anything to claim (the dot on the Hunt Board button)
	  doneText      the in-match toast for a finished bounty
	  counts        whether an event counts in the match's current State (#66, #85)

	Events for `progress` (EVENTS below); `amount` defaults to 1:
	  pop         target = the species key. Advances that species' `pop` bounties and
	              every `popTotal` bounty. Call it for every hunter in the match, with
	              context.credited = false for those who didn't get the pop: only a
	              boss pop still counts for them (DECISIONS #66).
	  clear       target = the difficulty key cleared. A bounty with a difficulty
	              Target counts that difficulty or any harder one.
	  reachRound  amount = the round reached; fire it once for each round, as it's
	              reached. A bounty with a round Target counts the times that round
	              is reached; one without wants round Count itself.
	  ability, build, upgrade, repair   no target. `repair` means a trampled tower
	              put back up (DECISIONS #75).
]]

local Config = require(script.Parent.Config)
local Theme = require(script.Parent.Theme)

local Tuning = Config.Tuning

export type Entry = { id: string, progress: number, claimed: boolean }
export type Haul = { day: number, claimedOn: number? }
export type State = {
	day: number,
	week: number,
	daily: { Entry },
	weekly: { Entry },
	dailySwaps: number,
	weeklySwaps: number,
	haul: Haul,
}
export type Rng = (n: number) -> number
export type Context = { credited: boolean? }

local DAY = 86400
local SLOTS = { "easy", "medium", "hard" }

local Bounties = {}

Bounties.POOLS = table.freeze({ "daily", "weekly" })
-- The events callers fire (a `popTotal` bounty is fed by `pop`).
Bounties.EVENTS = table.freeze({ "pop", "clear", "reachRound", "ability", "build", "upgrade", "repair" })

local function whole(x: any): boolean
	return type(x) == "number" and x == x and math.abs(x) ~= math.huge and x == math.floor(x)
end

local function definition(id: string): any
	return (Config.Bounties :: any)[id]
end

-- Time ------------------------------------------------------------------------

function Bounties.dayIndex(now: number): number
	return math.floor((now - Tuning.DailyResetHourUTC * 3600) / DAY)
end

-- Day 0 (1 January 1970) was a Thursday, so day 4 was the first Monday.
function Bounties.weekIndex(now: number): number
	return math.floor((Bounties.dayIndex(now) + 4 - Tuning.WeeklyResetDay) / 7)
end

function Bounties.secondsToDaily(now: number): number
	return (Bounties.dayIndex(now) + 1) * DAY + Tuning.DailyResetHourUTC * 3600 - now
end

function Bounties.secondsToWeekly(now: number): number
	local day = Bounties.dayIndex(now)
	local daysLeft = 7 - (day + 4 - Tuning.WeeklyResetDay) % 7
	return (day + daysLeft) * DAY + Tuning.DailyResetHourUTC * 3600 - now
end

-- Which bounties are on the board ------------------------------------------------

function Bounties.slots(pool: string): { string }
	local count = if pool == "daily" then Tuning.DailyBounties else Tuning.WeeklyBounties
	local out = {}
	for i = 1, count do
		out[i] = SLOTS[(i - 1) % #SLOTS + 1]
	end
	return out
end

-- One bounty of this pool and slot that isn't excluded, or nil if there's none.
local function pick(pool: string, slot: string, exclude: { [string]: boolean }, rng: Rng): string?
	local candidates = {}
	for _, id in Config.BountyOrder do
		local def = definition(id)
		if def.pool == pool and def.slot == slot and not exclude[id] then
			table.insert(candidates, id)
		end
	end
	if #candidates == 0 then
		return nil
	end
	return candidates[math.clamp(math.floor(rng(#candidates)), 1, #candidates)]
end

function Bounties.roll(pool: string, rng: Rng): { Entry }
	local out: { Entry } = {}
	local taken: { [string]: boolean } = {}
	for _, slot in Bounties.slots(pool) do
		local id = pick(pool, slot, taken, rng)
		if id then
			taken[id] = true
			table.insert(out, { id = id, progress = 0, claimed = false })
		end
	end
	return out
end

function Bounties.fresh(now: number, rng: Rng): State
	return {
		day = Bounties.dayIndex(now),
		week = Bounties.weekIndex(now),
		daily = Bounties.roll("daily", rng),
		weekly = Bounties.roll("weekly", rng),
		dailySwaps = 0,
		weeklySwaps = 0,
		haul = { day = 0, claimedOn = nil },
	}
end

function Bounties.isDone(entry: Entry): boolean
	local def = definition(entry.id)
	return def ~= nil and entry.progress >= def.count
end

-- Loading a save ----------------------------------------------------------------

-- The saved list for a pool, made valid: known bounties of this pool only, no
-- duplicates, one per active slot; gaps are rolled.
local function cleanPool(raw: any, pool: string, rng: Rng): { Entry }
	local kept: { Entry } = {}
	local seen: { [string]: boolean } = {}
	if type(raw) == "table" then
		for _, e in raw do
			if type(e) == "table" and type(e.id) == "string" and not seen[e.id] then
				local def = definition(e.id)
				if def and def.pool == pool then
					seen[e.id] = true
					table.insert(kept, {
						id = e.id,
						progress = if whole(e.progress) then math.clamp(e.progress, 0, def.count) else 0,
						claimed = e.claimed == true,
					})
				end
			end
		end
	end

	local slots = Bounties.slots(pool)
	local placed: { [number]: Entry } = {}
	local used: { [number]: boolean } = {}
	local taken: { [string]: boolean } = {}
	for i, slot in slots do
		for k, entry in kept do
			if not used[k] and definition(entry.id).slot == slot then
				placed[i], used[k], taken[entry.id] = entry, true, true
				break
			end
		end
	end
	local out: { Entry } = {}
	for i, slot in slots do
		local entry = placed[i]
		if not entry then
			local id = pick(pool, slot, taken, rng)
			if id then
				taken[id] = true
				entry = { id = id, progress = 0, claimed = false }
			end
		end
		if entry then
			table.insert(out, entry)
		end
	end
	return out
end

function Bounties.sanitize(raw: any, now: number, rng: Rng): State
	if type(raw) ~= "table" then
		return Bounties.fresh(now, rng)
	end
	local today, thisWeek = Bounties.dayIndex(now), Bounties.weekIndex(now)

	local function swaps(x: any, allowance: number): number
		return if whole(x) then math.clamp(x, 0, allowance) else 0
	end

	local haul: Haul = { day = 0, claimedOn = nil }
	if type(raw.haul) == "table" then
		local day, claimedOn = raw.haul.day, raw.haul.claimedOn
		if whole(day) and day >= 0 and day <= #Config.DailyHaul then
			haul.day = day
		end
		-- A claim "in the future" would lock the Haul until then: forget it.
		if whole(claimedOn) and claimedOn <= today then
			haul.claimedOn = claimedOn
		end
	end

	return {
		-- A day or week that's missing or in the future counts as now, so the next
		-- refresh behaves.
		day = if whole(raw.day) and raw.day <= today then raw.day else today,
		week = if whole(raw.week) and raw.week <= thisWeek then raw.week else thisWeek,
		daily = cleanPool(raw.daily, "daily", rng),
		weekly = cleanPool(raw.weekly, "weekly", rng),
		dailySwaps = swaps(raw.dailySwaps, Tuning.DailySwaps),
		weeklySwaps = swaps(raw.weeklySwaps, Tuning.WeeklySwaps),
		haul = haul,
	}
end

-- Resets ------------------------------------------------------------------------

local function unclaimed(entries: { Entry }): number
	local amber = 0
	for _, entry in entries do
		if not entry.claimed and Bounties.isDone(entry) then
			amber += definition(entry.id).amber
		end
	end
	return amber
end

function Bounties.refresh(state: State, now: number, rng: Rng): number
	local payout = 0
	local today, thisWeek = Bounties.dayIndex(now), Bounties.weekIndex(now)
	if today > state.day then
		payout += unclaimed(state.daily)
		state.daily = Bounties.roll("daily", rng)
		state.dailySwaps = 0
		state.day = today
	end
	if thisWeek > state.week then
		payout += unclaimed(state.weekly)
		state.weekly = Bounties.roll("weekly", rng)
		state.weeklySwaps = 0
		state.week = thisWeek
	end
	return payout
end

-- Daily Haul --------------------------------------------------------------------

-- The Haul day the next claim pays. `resetAfter` is the Haul resets after missed days
-- lever (the default); specs pass other values.
function Bounties.nextHaulDay(haul: Haul, today: number, resetAfter: number?): number
	resetAfter = resetAfter or Tuning.HaulResetsAfterMissedDays
	if resetAfter > 0 and haul.claimedOn and today - haul.claimedOn - 1 >= resetAfter then
		return 1
	end
	return haul.day % #Config.DailyHaul + 1
end

function Bounties.canClaimHaul(state: State, now: number): boolean
	local claimedOn = state.haul.claimedOn
	return claimedOn == nil or Bounties.dayIndex(now) > claimedOn
end

-- (Haul day, claimed today?) for the calendar: the day claimed today, or else the
-- day waiting to be claimed.
function Bounties.haulToday(state: State, now: number): (number, boolean)
	if Bounties.canClaimHaul(state, now) then
		return Bounties.nextHaulDay(state.haul, Bounties.dayIndex(now)), false
	end
	return state.haul.day, true
end

-- (claimed?, Amber, the Haul day claimed)
function Bounties.claimHaul(state: State, now: number): (boolean, number, number)
	if not Bounties.canClaimHaul(state, now) then
		return false, 0, state.haul.day
	end
	local today = Bounties.dayIndex(now)
	local day = Bounties.nextHaulDay(state.haul, today)
	state.haul.day = day
	state.haul.claimedOn = today
	return true, Config.DailyHaul[day].amber, day
end

-- Progress, claims and swaps ----------------------------------------------------

-- Is `cleared` the difficulty `wanted`, or a harder one?
local function atLeast(cleared: string?, wanted: string): boolean
	local order = Config.DifficultyOrder
	local c, w = table.find(order, cleared :: any), table.find(order, wanted)
	return c ~= nil and w ~= nil and c >= w
end

-- Does this event count while the match is in `matchState` (the ReplicatedStorage "State"
-- attribute)? Nothing counts outside a match (DECISIONS #66). An `ability` use counts only
-- while a round is running: the Building phase has no timer, so Gear Check could be
-- finished there without facing a dino (DECISIONS #85). Every other event counts in
-- Building and in Playing.
function Bounties.counts(event: string, matchState: any): boolean
	if matchState == "Playing" then
		return true
	end
	return matchState == "Building" and event ~= "ability"
end

function Bounties.progress(state: State, event: string, target: string?, amount: number?, context: Context?): { string }
	local n = if amount == nil then 1 else amount
	local finished: { string } = {}
	if not whole(n) or n <= 0 then
		return finished
	end
	if event == "pop" and context and context.credited == false then
		local species = if target then (Config.Enemies :: any)[target] else nil
		if not (species and species.boss) then
			return finished
		end
	end
	for _, pool in Bounties.POOLS do
		for _, entry in (state :: any)[pool] :: { Entry } do
			local def = definition(entry.id)
			if def and not entry.claimed and entry.progress < def.count then
				local gained = 0
				if event == "pop" then
					if def.event == "popTotal" or (def.event == "pop" and def.target == target) then
						gained = n
					end
				elseif def.event ~= event then
					gained = 0
				elseif event == "clear" then
					if def.target == "" or atLeast(target, def.target) then
						gained = n
					end
				elseif event == "reachRound" then
					if def.round > 0 then
						gained = if n == def.round then 1 else 0
					else
						gained = math.max(0, math.min(n, def.count) - entry.progress)
					end
				elseif table.find(Bounties.EVENTS, event) then
					gained = n
				end
				if gained > 0 then
					entry.progress = math.min(def.count, entry.progress + gained)
					if entry.progress >= def.count then
						table.insert(finished, entry.id)
					end
				end
			end
		end
	end
	return finished
end

-- (pool, position) of an active bounty.
local function find(state: State, id: string): (string?, number?)
	for _, pool in Bounties.POOLS do
		for i, entry in (state :: any)[pool] :: { Entry } do
			if entry.id == id then
				return pool, i
			end
		end
	end
	return nil, nil
end

-- (claimed?, Amber)
function Bounties.claim(state: State, id: string): (boolean, number)
	local pool, i = find(state, id)
	if not pool or not i then
		return false, 0
	end
	local entry = (state :: any)[pool][i] :: Entry
	if entry.claimed or not Bounties.isDone(entry) then
		return false, 0
	end
	entry.claimed = true
	return true, definition(id).amber
end

function Bounties.swapsLeft(state: State, pool: string): number
	if pool == "daily" then
		return math.max(0, Tuning.DailySwaps - state.dailySwaps)
	end
	return math.max(0, Tuning.WeeklySwaps - state.weeklySwaps)
end

-- (swapped?, the new bounty's id)
function Bounties.swap(state: State, id: string, rng: Rng): (boolean, string?)
	local pool, i = find(state, id)
	if not pool or not i then
		return false, nil
	end
	local entries = (state :: any)[pool] :: { Entry }
	local entry = entries[i]
	if entry.claimed or Bounties.isDone(entry) or Bounties.swapsLeft(state, pool) <= 0 then
		return false, nil
	end
	local taken: { [string]: boolean } = {}
	for _, other in entries do
		taken[other.id] = true -- includes the one being swapped out
	end
	local newId = pick(pool, definition(id).slot, taken, rng)
	if not newId then
		return false, nil
	end
	entries[i] = { id = newId, progress = 0, claimed = false }
	if pool == "daily" then
		state.dailySwaps += 1
	else
		state.weeklySwaps += 1
	end
	return true, newId
end

function Bounties.claimable(state: State, now: number): boolean
	if Bounties.canClaimHaul(state, now) then
		return true
	end
	for _, pool in Bounties.POOLS do
		for _, entry in (state :: any)[pool] :: { Entry } do
			if not entry.claimed and Bounties.isDone(entry) then
				return true
			end
		end
	end
	return false
end

-- "Bounty ready: Raptor Cull (claim +15 Amber at the Hunt Board)" (DECISIONS #94), or
-- nil for an unknown id. "Bagged" only ever means claimed.
function Bounties.doneText(id: string): string?
	local def = definition(id)
	if not def then
		return nil
	end
	return `Bounty ready: {def.title} (claim +{def.amber} {Theme.Currency} at the {Theme.HuntBoard})`
end

return Bounties
