--[[
	The saved profile: what a player keeps between matches, as plain data and pure rules
	(no services, no clock, no random numbers of its own), so specs can run the load, save
	and Hunt Board paths headlessly. Server/Progression is the only thing that holds
	profiles, calls these and talks to the data store; nothing else may change one.

	Callers pass in `now` (server time, os.time()) and `rng` (function(n) -> 1..n), the
	same as Shared/Bounties.

	  cores, owned, mastery, highestRound   Amber and unlocks (Server/Progression)
	  rewards           the Hunt Board state (Shared/Bounties), saved as it is. nil = the
	                    Hunt Board couldn't be read: the player plays on without it, every
	                    Hunt Board call below answers "no", and a save writes the stored
	                    value back untouched (`rewardsRaw`) instead of wiping it.
	  playerXp          total player XP (Shared/PlayerLevel, DECISIONS #118-#123); the level is
	                    derived from it, never stored. An older save without it starts at 0.
	  equipped          what the player wears: "title" and one cosmetic per kind, slot ->
	                    item id (Shared/Cosmetics). Checked against the level on load
	                    (unknown ids, wrong kinds, locked items dropped; DECISIONS #178)
	                    and on every equip.
	  trophies          ranked Trophies (Shared/Trophies, PLAN T80); an older save starts at 0
	  bestArena         the key of the best arena reached (Config.Arenas; nil = the first).
	                    Never below the arena the Trophies are in
	  escrow            a ranked stake taken but not yet settled: { matchId, amount }
	                    (Shared/Stakes, DECISIONS #216). Saved the moment it's taken; the
	                    match end settles it and clears it in the same save; a leaver
	                    forfeits it; a shutdown or a later load finds it and refunds it
	  lastResetPayout   Amber paid at a reset for bounties done but not claimed, since the
	                    board was last opened. Session only, never saved.
	  rewardsVersion    counts Hunt Board changes; the client re-asks when it moves.
	                    Session only.

	Amber only ever changes here by the amounts Shared/Bounties returns.

	  blank        a new player's profile
	  sanitize     any stored value -> a valid profile (an older save without `rewards`
	               gets a fresh Hunt Board; everything else in it is kept)
	  toSave       the table to store
	  addPlayerXp  bank one match's player XP; returns what was added
	  stake        take a ranked stake into escrow (refused while one is open or unaffordable)
	  refundEscrow give back an escrow that was never settled (load, shutdown); returns it
	  forfeitEscrow  a leaver's stake stays in the pot: the escrow just closes
	  leaveRanked  a Ranked leaver: the escrow forfeits and the Trophies drop as last place,
	               together (one save; PLAN T82, DECISIONS #233)
	  settleBattle the match end: pay, apply Trophies, clear that match's escrow (one save)
	  equip        wear an unlocked item in its slot, or take one off
	  hold / settleHeld   player XP that arrived while the save was still loading: held,
	               then added once when the load succeeds, dropped if it fails
	               (DECISIONS #179)
	  refresh      roll the bounties over if a reset has passed and pay what was done but
	               unclaimed; returns that Amber
	  claimHaul / claimBounty / swapBounty   refresh, then the Bounties rule
	  bountyEvent  a match event; returns the ids of the bounties it finished
	  claimable    is there anything to claim
	  view         what the owner's Hunt Board shows
]]

local Config = require(script.Parent.Config)
local Bounties = require(script.Parent.Bounties)
local PlayerLevel = require(script.Parent.PlayerLevel)
local Cosmetics = require(script.Parent.Cosmetics)
local Stakes = require(script.Parent.Stakes)
local Trophies = require(script.Parent.Trophies)

export type Profile = {
	cores: number,
	owned: { [string]: boolean }, -- "tower:CHILLER", "hero:RIFLE"; free ones aren't stored
	mastery: { [string]: number }, -- hero key -> level
	highestRound: number,
	rewards: Bounties.State?,
	rewardsRaw: any,
	playerXp: number,
	equipped: { [string]: string },
	trophies: number,
	bestArena: string?,
	escrow: Stakes.Escrow?,
	lastResetPayout: number,
	rewardsVersion: number,
}

export type View = {
	daily: { Bounties.Entry },
	weekly: { Bounties.Entry },
	haulDay: number,
	haulClaimed: boolean,
	dailySwapsLeft: number,
	weeklySwapsLeft: number,
	secondsToDaily: number,
	secondsToWeekly: number,
	lastResetPayout: number,
}

local Profile = {}

-- The rewards rules, replaceable so a spec can prove a broken Hunt Board never costs a
-- player their save. Nothing else sets this.
Profile.rules = Bounties

local function freshRewards(now: number, rng: Bounties.Rng): Bounties.State?
	local ok, state = pcall(function()
		return Profile.rules.fresh(now, rng)
	end)
	return if ok then state else nil
end

local function arenaIndex(key: unknown): number?
	for i, arena in Config.Arenas do
		if arena.key == key then
			return i
		end
	end
	return nil
end

-- The best arena reached, as a saved key: the stored one (if it's a real arena) or the
-- one the Trophies are in, whichever is higher. nil = the first arena.
function Profile.bestArenaKey(stored: unknown, trophies: number): string?
	local best = math.max(arenaIndex(stored) or 1, Trophies.arenaOf(trophies))
	return if best > 1 then Config.Arenas[best].key else nil
end

-- The best arena reached as an index into Config.Arenas (1 = the first).
function Profile.bestArenaIndex(profile: Profile): number
	return arenaIndex(profile.bestArena) or 1
end

function Profile.blank(now: number, rng: Bounties.Rng): Profile
	return {
		cores = 0,
		owned = {},
		mastery = {},
		highestRound = 0,
		rewards = freshRewards(now, rng),
		rewardsRaw = nil,
		playerXp = 0,
		equipped = {},
		trophies = 0,
		bestArena = nil,
		escrow = nil,
		lastResetPayout = 0,
		rewardsVersion = 0,
	}
end

-- Anything read from the store is data from an older version or a bad write until
-- proven otherwise.
function Profile.sanitize(raw: any, now: number, rng: Bounties.Rng): Profile
	local profile = Profile.blank(now, rng)
	if type(raw) ~= "table" then
		return profile
	end
	if type(raw.cores) == "number" and raw.cores >= 0 then
		profile.cores = math.floor(raw.cores)
	end
	if type(raw.highestRound) == "number" and raw.highestRound >= 0 then
		profile.highestRound = math.floor(raw.highestRound)
	end
	profile.playerXp = PlayerLevel.whole(raw.playerXp) -- missing (an older save) or garbage: 0
	-- Ranked (PLAN T80): older saves have none of these and load as 0 / nil.
	profile.trophies = PlayerLevel.whole(raw.trophies)
	profile.bestArena = Profile.bestArenaKey(raw.bestArena, profile.trophies)
	-- Only what this level (or an arena reached, T81) has unlocked, in the right slot;
	-- anything else is dropped.
	profile.equipped = Cosmetics.clean(raw.equipped, PlayerLevel.level(profile.playerXp), Profile.bestArenaIndex(profile))
	if
		type(raw.escrow) == "table"
		and type(raw.escrow.matchId) == "string"
		and type(raw.escrow.amount) == "number"
		and raw.escrow.amount == raw.escrow.amount
		and raw.escrow.amount > 0
		and raw.escrow.amount < math.huge
	then
		profile.escrow = Stakes.escrow(raw.escrow.matchId, math.floor(raw.escrow.amount))
	end
	if type(raw.owned) == "table" then
		for id, value in raw.owned do
			if value == true and type(id) == "string" then
				local kind, itemKey = string.match(id, "^(%a+):(.+)$")
				local towers, heroes = Config.Towers :: any, Config.Heroes :: any
				if (kind == "tower" and towers[itemKey]) or (kind == "hero" and heroes[itemKey]) then
					profile.owned[id] = true
				end
			end
		end
	end
	if type(raw.mastery) == "table" then
		for heroKey, level in raw.mastery do
			if (Config.Heroes :: any)[heroKey] and type(level) == "number" then
				profile.mastery[heroKey] = math.clamp(math.floor(level), 0, #Config.Mastery)
			end
		end
	end

	-- The Hunt Board is read on its own: if that fails, the rest of the profile still
	-- loads and what was stored is kept for the next save.
	local ok, state = pcall(function()
		return Profile.rules.sanitize(raw.rewards, now, rng)
	end)
	if ok and type(state) == "table" then
		profile.rewards = state
	else
		profile.rewards = nil
		profile.rewardsRaw = raw.rewards
	end
	return profile
end

function Profile.toSave(profile: Profile): { [string]: any }
	return {
		cores = profile.cores,
		owned = profile.owned,
		mastery = profile.mastery,
		highestRound = profile.highestRound,
		playerXp = profile.playerXp,
		equipped = profile.equipped,
		trophies = profile.trophies,
		bestArena = profile.bestArena,
		escrow = profile.escrow,
		rewards = if profile.rewards then profile.rewards else profile.rewardsRaw,
	}
end

-- Session lock (PLAN T90; needed before players hop servers, #240) ---------------------
-- The stored record carries `lock = { session, at }`: the server session that loaded it
-- and when it last wrote. Server B may load (and take) a save only when it's free, already
-- its own, or stale (the holder stopped writing LOCK_STALE seconds ago: it crashed).
-- A server may write only while the stored lock is its own, so a server that lost the
-- lock can never overwrite the newer save. Sanitize ignores the field.
export type Lock = { session: string, at: number }

Profile.LOCK_STALE = 600 -- seconds without a write before a lock counts as abandoned
Profile.LOCK_REFRESH = 120 -- the holder rewrites its lock this often (well inside LOCK_STALE)

function Profile.lockOf(raw: any): Lock?
	local lock = if type(raw) == "table" then raw.lock else nil
	if type(lock) == "table" and type(lock.session) == "string" and type(lock.at) == "number" and lock.at == lock.at then
		return { session = lock.session, at = lock.at }
	end
	return nil
end

-- May `session` load (and take) this stored record now?
function Profile.mayTake(raw: any, session: string, now: number): boolean
	local lock = Profile.lockOf(raw)
	return lock == nil or lock.session == session or now - lock.at >= Profile.LOCK_STALE
end

-- May `session` write over this stored record? Only while it holds the lock: a free
-- record was released (or taken and released by another server), so it isn't ours.
function Profile.mayWrite(raw: any, session: string): boolean
	local lock = Profile.lockOf(raw)
	return lock ~= nil and lock.session == session
end

-- Player level (Shared/PlayerLevel) --------------------------------------------------

-- Bank one match's player XP. Only whole, finite, positive amounts count: XP never
-- goes down. Returns what was added.
function Profile.addPlayerXp(profile: Profile, amount: number): number
	local add = PlayerLevel.whole(amount)
	profile.playerXp = PlayerLevel.whole(profile.playerXp) + add
	return add
end

-- Wear item `id` in `slot` ("" or nil takes it off). Refused (with the reason) for an
-- unknown slot or item, an item of another kind, or one above the player's level.
function Profile.equip(profile: Profile, slot: unknown, id: unknown): (boolean, string)
	local ok, why = Cosmetics.check(slot, id, PlayerLevel.level(profile.playerXp), Profile.bestArenaIndex(profile))
	if not ok then
		return false, why
	end
	local s = slot :: string
	if id == nil or id == "" then
		profile.equipped[s] = nil
	else
		profile.equipped[s] = id :: string
	end
	return true, ""
end

-- Ranked: stakes and Trophies (PLAN T80, DECISIONS #216, #218) ----------------------


-- Take `amount` into escrow for `matchId`. Refused (false) while another escrow is open,
-- for a bad amount, or when the Amber doesn't cover it.
function Profile.stake(profile: Profile, matchId: string, amount: number): boolean
	if profile.escrow ~= nil or type(amount) ~= "number" or amount ~= amount or amount <= 0 or amount ~= math.floor(amount) then
		return false
	end
	if profile.cores < amount then
		return false
	end
	profile.cores -= amount
	profile.escrow = Stakes.escrow(matchId, amount)
	return true
end

-- An escrow that was never settled comes back (Stakes.refund). Returns the Amber.
function Profile.refundEscrow(profile: Profile): number
	local escrow = profile.escrow
	if escrow == nil then
		return 0
	end
	local amount = Stakes.refund(escrow)
	profile.cores += amount
	profile.escrow = nil
	return amount
end

-- A leaver's stake stays in the pot: the escrow closes with nothing back.
function Profile.forfeitEscrow(profile: Profile, matchId: string): boolean
	if profile.escrow == nil or profile.escrow.matchId ~= matchId then
		return false
	end
	profile.escrow = nil
	return true
end

-- A Ranked leaver (PLAN T82, DECISIONS #233): the stake stays in the pot (the escrow
-- closes with nothing back) and the Trophies drop as if they'd placed last in that lobby
-- (Trophies.leaverDelta; the arena floor holds), in one step so one save stores both.
-- Practice changes no Trophies. Returns the Trophies change; nothing is touched (0) when
-- that match's escrow isn't open (a casual battle, or one already settled).
function Profile.leaveRanked(profile: Profile, matchId: string, modeKey: string, n: number, practice: boolean?): number
	if not Profile.forfeitEscrow(profile, matchId) then
		return 0
	end
	local before = profile.trophies
	profile.trophies = Trophies.apply(before, Trophies.leaverDelta(modeKey, n, practice))
	return profile.trophies - before
end

-- The match end for one hunter: `payout` Amber (casual payout + pot share), `delta`
-- Trophies (Trophies.apply: arena floor, never below 0), and that match's escrow cleared,
-- all at once so one save stores it. Returns (Trophies change, arenas reached for the first
-- time). An escrow for another match is left alone (it's refunded on the next load).
function Profile.settleBattle(profile: Profile, matchId: string?, payout: number, delta: number): (number, { number })
	if matchId and profile.escrow and profile.escrow.matchId == matchId then
		profile.escrow = nil
	end
	profile.cores += math.max(0, PlayerLevel.whole(payout))
	local before = profile.trophies
	local bestBefore = arenaIndex(profile.bestArena) or 1
	profile.trophies = Trophies.apply(before, delta)
	profile.bestArena = Profile.bestArenaKey(profile.bestArena, profile.trophies)
	local bestAfter = arenaIndex(profile.bestArena) or 1
	local reached = {}
	for i = bestBefore + 1, bestAfter do
		table.insert(reached, i)
	end
	return profile.trophies - before, reached
end

-- Player XP that arrives while a save is still loading (DECISIONS #179).
export type Held = { xp: number, settled: boolean }

function Profile.newHeld(): Held
	return { xp = 0, settled = false }
end

-- Keep `amount` until the load ends. False once the load has ended (add it directly).
function Profile.hold(held: Held, amount: number): boolean
	if held.settled then
		return false
	end
	held.xp += PlayerLevel.whole(amount)
	return true
end

-- The load ended: `profile` is the loaded save, or nil if it failed. Adds what was held
-- once (a second call adds nothing). Returns (added, dropped).
function Profile.settleHeld(held: Held, profile: Profile?): (number, number)
	if held.settled then
		return 0, 0
	end
	held.settled = true
	local xp = held.xp
	held.xp = 0
	if profile then
		return Profile.addPlayerXp(profile, xp), 0
	end
	return 0, xp
end

-- Hunt Board ----------------------------------------------------------------------

function Profile.refresh(profile: Profile, now: number, rng: Bounties.Rng): number
	local state = profile.rewards
	if not state then
		return 0
	end
	local day, week = state.day, state.week
	local payout = Profile.rules.refresh(state, now, rng)
	if payout > 0 then
		profile.cores += payout
		profile.lastResetPayout += payout
	end
	if payout > 0 or state.day ~= day or state.week ~= week then
		profile.rewardsVersion += 1
	end
	return payout
end

-- (claimed?, Amber, the Haul day claimed)
function Profile.claimHaul(profile: Profile, now: number, rng: Bounties.Rng): (boolean, number, number)
	local state = profile.rewards
	if not state then
		return false, 0, 0
	end
	Profile.refresh(profile, now, rng)
	local ok, amber, day = Profile.rules.claimHaul(state, now)
	if not ok then
		return false, 0, day
	end
	profile.cores += amber
	profile.rewardsVersion += 1
	return true, amber, day
end

-- (claimed?, Amber)
function Profile.claimBounty(profile: Profile, id: unknown, now: number, rng: Bounties.Rng): (boolean, number)
	local state = profile.rewards
	if not state or type(id) ~= "string" then
		return false, 0
	end
	Profile.refresh(profile, now, rng)
	local ok, amber = Profile.rules.claim(state, id)
	if not ok then
		return false, 0
	end
	profile.cores += amber
	profile.rewardsVersion += 1
	return true, amber
end

-- (swapped?, the new bounty's id)
function Profile.swapBounty(profile: Profile, id: unknown, now: number, rng: Bounties.Rng): (boolean, string?)
	local state = profile.rewards
	if not state or type(id) ~= "string" then
		return false, nil
	end
	Profile.refresh(profile, now, rng)
	local ok, newId = Profile.rules.swap(state, id, rng)
	if not ok then
		return false, nil
	end
	profile.rewardsVersion += 1
	return true, newId
end

-- A match event (Bounties.EVENTS). Returns the ids of the bounties it finished. Never
-- pays: a finished bounty is claimed on the Hunt Board, or paid at the next reset.
function Profile.bountyEvent(
	profile: Profile,
	event: string,
	target: string?,
	amount: number?,
	context: Bounties.Context?
): { string }
	local state = profile.rewards
	if not state then
		return {}
	end
	local finished = Profile.rules.progress(state, event, target, amount, context)
	if #finished > 0 then
		profile.rewardsVersion += 1
	end
	return finished
end

function Profile.claimable(profile: Profile, now: number): boolean
	local state = profile.rewards
	return state ~= nil and Profile.rules.claimable(state, now)
end

local function copyEntries(entries: { Bounties.Entry }): { Bounties.Entry }
	local out = {}
	for i, entry in entries do
		out[i] = { id = entry.id, progress = entry.progress, claimed = entry.claimed }
	end
	return out
end

-- What the owner's Hunt Board shows, or nil if there's no Hunt Board. `seen` = the
-- board is open on their screen: the reset payout is handed over once, then forgotten.
function Profile.view(profile: Profile, now: number, seen: boolean?): View?
	local state = profile.rewards
	if not state then
		return nil
	end
	local rules = Profile.rules
	local haulDay, haulClaimed = rules.haulToday(state, now)
	local view: View = {
		daily = copyEntries(state.daily),
		weekly = copyEntries(state.weekly),
		haulDay = haulDay,
		haulClaimed = haulClaimed,
		dailySwapsLeft = rules.swapsLeft(state, "daily"),
		weeklySwapsLeft = rules.swapsLeft(state, "weekly"),
		secondsToDaily = rules.secondsToDaily(now),
		secondsToWeekly = rules.secondsToWeekly(now),
		lastResetPayout = profile.lastResetPayout,
	}
	if seen then
		profile.lastResetPayout = 0
	end
	return view
end

return Profile
