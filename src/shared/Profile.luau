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

export type Profile = {
	cores: number,
	owned: { [string]: boolean }, -- "tower:CHILLER", "hero:RIFLE"; free ones aren't stored
	mastery: { [string]: number }, -- hero key -> level
	highestRound: number,
	rewards: Bounties.State?,
	rewardsRaw: any,
	playerXp: number,
	equipped: { [string]: string },
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
	-- Only what this level has unlocked, in the right slot; anything else is dropped.
	profile.equipped = Cosmetics.clean(raw.equipped, PlayerLevel.level(profile.playerXp))
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
		rewards = if profile.rewards then profile.rewards else profile.rewardsRaw,
	}
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
	local ok, why = Cosmetics.check(slot, id, PlayerLevel.level(profile.playerXp))
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
