--[[
	Progression: what a player keeps between matches (design doc §05, phase 6).

	Saved per player (DataStoreService): Amber (stored as `cores`), what they own, a mastery
	level per hero, the highest round they've ever reached, and their Hunt Board (`rewards`).
	The profile's shape and rules are Shared/Profile (pure, spec-tested); this module is
	the only one that holds profiles, changes them and talks to the data store.

	  Amber         the permanent currency (VISION.md). Casual payouts:
	                clearing the track pays the difficulty's Clear reward to
	                everyone; a multiplayer match that ends without a clear pays
	                MultiplayerLossPayout each; a solo loss pays nothing.
	  Player level  total player XP (`playerXp`, Shared/PlayerLevel, DECISIONS #118-#124),
	                added once per match by Main through addPlayerXp just before
	                endMatch saves; the level is derived, rewards are cosmetic.
	                XP for a player whose save is still loading is held here and
	                added once the load succeeds; a failed load drops it with one
	                warning and never overwrites (DECISIONS #179).
	  Cosmetics     what a player wears (`equipped`, Shared/Cosmetics, PLAN T57):
	                checked against the level on load and on every "equip" request,
	                published as Equip_<slot> attributes on the Player for everyone
	                to show. Unlocks come from the level; nothing else is stored.
	  Ranked        Trophies, the best arena and an open stake's escrow (PLAN T80,
	                DECISIONS #215-#218): canStake / stake / refundStake / endBattle.
	                Unpublished (Studio) = Practice: session Amber, no Trophies.
	  Unlocks       heroes and towers with an Unlock cost are bought with Amber.
	                Free ones (cost 0) are owned by everyone. You can only pick
	                heroes and place towers you own; upgrading a teammate's
	                tower doesn't need ownership (Shop).
	  Mastery       bought with Amber, per owned hero, up to 20 levels (Mastery
	                sheet): cheaper hero upgrades, shorter cooldowns, a free
	                first upgrade, a higher crossover cap — never damage

	Unlocks and mastery can only be bought outside a running match, so a match
	always plays with what everyone started it with.

	  Hunt Board    the Daily Haul and the daily and weekly Bounties (Shared/Bounties,
	                DECISIONS #63-#71). Claims and swaps are Lobby only and save
	                straight away; a reset is checked on load, before every claim or
	                swap, when the board is read in the Lobby, and at match end, and
	                pays bounties that were done but not claimed. The owner reads their
	                board with the "getRewards" request; RewardsClaimable (is there
	                something to claim) and RewardsVersion (bumped on every change:
	                ask again) are attributes on their Player. If the Hunt Board can't
	                be read the player plays on without it and their stored board is
	                left as it was.
	  Training      the four account-wide trained stats (`training`, Shared/Training, PLAN
	                10c T139). Server/Training ticks ONLINE time in through trainingTick
	                (full rate at the stat's station, half elsewhere, each tick clamped);
	                nothing is credited for time away. Changes are banked by bankTraining
	                every Training bank (s), on leave and at shutdown (the normal saves).
	                trainStart (a station's E), trainFinish (Amber, between matches, once
	                a price is set) and Studio's trainSkip (saving off, like J). Published
	                as attributes: TrainLevel_/TrainProgress_<stat>, TrainActive, and the
	                percents the game reads (TrainedReach, TrainedThrow, TrainedHealth,
	                TrainedSpeed).
	  Bounty progress   Progression.bountyEvent is the one way in for match events
	                (Main, Shop and Hero call it; the events are Bounties.EVENTS). It
	                only listens while a match is on (`ability` only during a round,
	                DECISIONS #85), never pays, and tells the owner
	                alone when a bounty is finished (the BountyDone remote).

	SAVING needs a place published to Roblox (Studio: Game Settings > Security >
	Enable Studio Access to API Services). If the data store can't be reached,
	the player plays on a session-only profile and their "SaveStatus"
	attribute says "offline" — nothing is lost that was saved before, and
	nothing new is written over it.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Payouts = require(Shared:WaitForChild("Payouts"))
local Bounties = require(Shared:WaitForChild("Bounties"))
local Profile = require(Shared:WaitForChild("Profile"))
local PlayerLevel = require(Shared:WaitForChild("PlayerLevel"))
local Cosmetics = require(Shared:WaitForChild("Cosmetics"))
local Theme = require(Shared:WaitForChild("Theme"))
local ShopRules = require(Shared:WaitForChild("ShopRules"))
local Stakes = require(Shared:WaitForChild("Stakes"))
local Trophies = require(Shared:WaitForChild("Trophies"))
local StudioOnly = require(Shared:WaitForChild("StudioOnly"))
local SaveStore = require(Shared:WaitForChild("SaveStore"))
local Training = require(Shared:WaitForChild("Training"))
local HunterKit = require(Shared:WaitForChild("HunterKit"))
local Pets = require(Shared:WaitForChild("Pets"))
local Skins = require(Shared:WaitForChild("Skins"))
local StoreRules = require(Shared:WaitForChild("Store"))

local Progression = {}

type Profile = Profile.Profile

local STORE_NAME = "StormSplitProgress_v1"
local CLOSE_DEADLINE = 25 -- seconds BindToClose waits for the last saves (Roblox allows 30)

local profiles: { [Player]: Profile } = {}
local onMasteryChanged: ((Player) -> ())? = nil
local canSave: { [Player]: boolean } = {} -- false = session-only (store unreachable at load)
local held: { [Player]: Profile.Held } = {} -- player XP that arrived while the save was loading
local onLookChanged: ((Player) -> ())? = nil
local bountyDone: RemoteEvent? = nil -- (bounty id), to the hunter who finished it only
local store: SaveStore.Store? = nil -- the DataStore behind Shared/SaveStore (PLAN T90)
local sessions: { [Player]: string } = {} -- this server's lock id for each player's save
local locked: { [Player]: boolean } = {} -- this server holds that save's session lock
local leaving: { [Player]: boolean } = {} -- PlayerRemoving is saving them (BindToClose skips)
local inFlight = 0 -- store requests still running (BindToClose waits for them)
local sessionCount = 0
local env: SaveStore.Env = {
	now = os.time,
	wait = function(seconds: number)
		task.wait(seconds)
	end,
	log = function(text: string)
		warn(text)
	end,
}
local passEffects: { [Player]: StoreRules.Effects } = {} -- Game Pass effects (Server/Store, T143)
local function effectsOf(player: Player): StoreRules.Effects
	return passEffects[player] or StoreRules.passEffects({})
end
local saveHintGiven = false -- the developer's "publish the place" hint: one warn per session
local closing = false -- the server is shutting down (BindToClose): open stakes are refunded
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		local dataStore: DataStore = result
		store = {
			update = function(k: string, transform: (any) -> any): any
				return dataStore:UpdateAsync(k, transform)
			end,
			budget = function(): number
				return DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync)
			end,
		}
	else
		warn(`[Progression] No data store, so progress isn't saving. Publish the place to Roblox to keep it (SETUP.md): {result}`)
		saveHintGiven = true
	end
end

local function key(player: Player): string
	return `player_{player.UserId}`
end

-- One random stream per server, for rolling bounties.
local random = Random.new()
local function rng(n: number): number
	return random:NextInteger(1, n)
end

------------------------------------------------------------------ replication

local function costOf(kind: string, itemKey: string): number?
	local def = if kind == "tower" then Config.Towers[itemKey] elseif kind == "hero" then Config.Heroes[itemKey] else nil
	return if def then def.unlockCost or 0 else nil
end

local function owns(player: Player, kind: string, itemKey: string): boolean
	local cost = costOf(kind, itemKey)
	if cost == nil then
		return false
	end
	if cost <= 0 then
		return true
	end
	local profile = profiles[player]
	return profile ~= nil and profile.owned[`{kind}:{itemKey}`] == true
end

-- Training (T139): levels, progress and the percents the game reads, as attributes.
local function publishTraining(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	local state = profile.training
	for _, row in Training.view(state) do
		player:SetAttribute(`TrainLevel_{row.stat}`, row.level)
		player:SetAttribute(`TrainProgress_{row.stat}`, math.floor(row.progress))
	end
	player:SetAttribute("TrainActive", table.concat(state.active, ","))
	player:SetAttribute(HunterKit.REACH_ATTRIBUTE, Training.percent(state, "reach"))
	player:SetAttribute(HunterKit.THROW_ATTRIBUTE, Training.percent(state, "throw"))
	player:SetAttribute("TrainedHealth", Training.percent(state, "health"))
	player:SetAttribute("TrainedSpeed", Training.percent(state, "speed"))
end

-- Skins (T142): what each slot wears and the Display Towers, as attributes (Wardrobe,
-- Hero and Towers read them; looks only), and a change counter the shop re-asks on.
local function publishSkins(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	local level = PlayerLevel.level(profile.playerXp)
	for _, hero in Config.HeroOrder do
		for _, kind in { "hunter", "weapon" } do
			local slot = Skins.slot(kind, hero)
			player:SetAttribute(Skins.attribute(slot), Skins.worn(profile.skins, slot, level))
		end
	end
	for _, tower in Config.TowerOrder do
		local slot = Skins.slot("tower", tower)
		player:SetAttribute(Skins.attribute(slot), Skins.worn(profile.skins, slot, level))
	end
	for i = 1, Skins.DECO_SLOTS do
		local tower = profile.skins.deco[i]
		player:SetAttribute(`{Skins.DECO_PREFIX}{i}`, if tower and tower ~= "" and owns(player, "tower", tower) then tower else nil)
	end
	player:SetAttribute("SkinsVersion", ((player:GetAttribute("SkinsVersion") :: number?) or 0) + 1)
end

local function publish(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	player:SetAttribute("Cores", profile.cores)
	player:SetAttribute("HighestRound", profile.highestRound)
	player:SetAttribute("PlayerXp", profile.playerXp)
	for _, slot in Cosmetics.SLOTS do
		player:SetAttribute(`Equip_{slot}`, profile.equipped[slot]) -- nil clears it
	end
	for heroKey in Config.Heroes do
		player:SetAttribute(`Mastery_{heroKey}`, profile.mastery[heroKey] or 0)
	end
	for towerKey in Config.Towers do
		player:SetAttribute(`OwnsTower_{towerKey}`, owns(player, "tower", towerKey))
	end
	for heroKey in Config.Heroes do
		player:SetAttribute(`OwnsHero_{heroKey}`, owns(player, "hero", heroKey))
	end
	player:SetAttribute("SaveStatus", if canSave[player] then "saved" else "offline")
	player:SetAttribute("Trophies", profile.trophies) -- ranked (PLAN T80); the leaderboard and Profile read it
	player:SetAttribute("Arena", Trophies.arenaOf(profile.trophies))
	player:SetAttribute("RewardsClaimable", Profile.claimable(profile, os.time()))
	player:SetAttribute("RewardsVersion", profile.rewardsVersion)
	publishTraining(player)
	-- Game Pass effects (T143): the client shows slots and incubators from these.
	local effects = effectsOf(player)
	player:SetAttribute("TrainRate", effects.trainRate)
	player:SetAttribute("TrainSlots", effects.trainSlots)
	player:SetAttribute("Incubators", effects.incubators)
	-- Pets (T140/T141): the pet taken along (name, kind, rarity) and a change counter the
	-- Hatchery Hut re-asks on. No pets readable = none.
	local along = profile.pets and Pets.along(profile.pets)
	player:SetAttribute("Pet", if along then Pets.name(along) else nil)
	player:SetAttribute("PetKind", if along then along.kind else nil)
	player:SetAttribute("PetRarity", if along then along.rarity else nil)
	player:SetAttribute("PetsVersion", ((player:GetAttribute("PetsVersion") :: number?) or 0) + 1)
	publishSkins(player)
end

------------------------------------------------------------------ load / save

local save: (Player, boolean?) -> boolean -- below: a load that settles held XP saves it

local function load(player: Player)
	local profile: Profile? = nil
	local session = ""
	local took = false -- this load took the session lock
	if store then
		sessionCount += 1
		session = `{if game.JobId ~= "" then game.JobId else "studio"}/{player.UserId}/{sessionCount}`
		sessions[player] = session
		-- Takes the session lock in the same step (Shared/SaveStore, Profile.mayTake): a
		-- save another server still holds waits for its last write instead of loading old data.
		inFlight += 1
		local status, raw = SaveStore.load(store, key(player), session, env)
		inFlight -= 1
		if status == "ok" then
			took = true
			locked[player] = true
			-- A stored value that can't be read at all counts as a failed load.
			local ok, result = pcall(Profile.sanitize, raw, os.time(), rng)
			if ok then
				profile = result
			else
				warn(`[Progression] Couldn't read {player.Name}'s save: {result}`)
			end
		elseif status == "locked" then
			warn(`[Progression] {player.Name}'s save is still open on another server; this session won't save`)
		else
			warn(`[Progression] Load failed for {player.Name}: {raw}`)
		end
	end
	if not player.Parent then
		held[player] = nil
		if took then
			-- Left while loading: free the lock, write nothing else (PlayerRemoving may
			-- already have cleared this player's entries).
			sessions[player], locked[player], profiles[player] = session, true, nil
			save(player, true)
		end
		sessions[player], locked[player] = nil, nil
		return
	end
	-- Only a successful load may ever be saved back, so a failed load can't
	-- overwrite real progress with a blank profile.
	canSave[player] = profile ~= nil
	if not profile and not saveHintGiven then
		-- Players only read "Progress isn't saving right now." (DECISIONS #94).
		saveHintGiven = true
		warn("[Progression] Progress isn't saving. In Studio, publish the place to Roblox to keep it (SETUP.md).")
	end
	local loaded = profile or Profile.blank(os.time(), rng)
	if not loaded.rewards then
		warn(`[Progression] No Hunt Board for {player.Name} this session; their stored one is kept`)
	end
	pcall(Profile.refresh, loaded, os.time(), rng) -- a new day or week since they last played
	-- A ranked stake that was never settled (a crash): back to the player, saved now
	-- (DECISIONS #216). Only a save that loaded has one, so only a loaded save is written.
	local refunded = Profile.refundEscrow(loaded)
	profiles[player] = loaded
	if refunded > 0 then
		print(`[Progression] Refunded {player.Name}'s unsettled stake of {Theme.amberExact(refunded)} {Theme.Currency}`)
		task.spawn(save, player)
	end
	-- Player XP that arrived while loading: added once to a save that loaded; dropped
	-- (never written over anything) when it didn't (DECISIONS #179).
	local waiting = held[player]
	if waiting then
		local added, dropped = Profile.settleHeld(waiting, profile)
		if dropped > 0 then
			warn(`[Progression] {player.Name}'s save didn't load, so the {dropped} player XP held for it is dropped`)
		elseif added > 0 then
			player:SetAttribute("LastPlayerXp", added)
			task.spawn(save, player)
		end
	end
	publish(player)
	if onLookChanged then
		onLookChanged(player)
	end
end

-- Write this player's save (or, with `release`, the last write: it frees the lock).
-- Only a save that loaded is ever written (canSave); one that didn't only frees its lock.
-- If another server took the lock, nothing is written and this session stops saving.
-- Returns true only when this profile was written (the store receipt rule waits on it).
save = function(player: Player, release: boolean?): boolean
	local session = sessions[player]
	if not store or not session or not locked[player] then
		return false
	end
	local profile = profiles[player]
	local data = if profile and canSave[player]
		then function()
			return Profile.toSave(profile)
		end
		else nil
	inFlight += 1
	local status, err = SaveStore.write(store, key(player), session, env, data, release)
	inFlight -= 1
	if status == "lost" then
		locked[player] = nil
		if canSave[player] then
			canSave[player] = false
			warn(`[Progression] {player.Name}'s save was taken by another server; this session stops saving`)
			if player.Parent then
				publish(player)
			end
		end
	elseif status ~= "ok" then
		warn(`[Progression] Save failed for {player.Name}: {err}`)
	elseif release then
		locked[player] = nil
	end
	return status == "ok" and data ~= nil
end

------------------------------------------------------------------ mastery

-- This player's mastery level with a hero (0 = none).
function Progression.masteryLevel(player: Player, heroKey: string): number
	local profile = profiles[player]
	return if profile then profile.mastery[heroKey] or 0 else 0
end

-- The rewards at a mastery level, or nil at level 0.
function Progression.masteryRewards(level: number): any?
	return Config.Mastery[level]
end

local function buyMastery(player: Player, heroKey: unknown): (boolean, string)
	if ReplicatedStorage:GetAttribute("State") == "Playing" then
		return false, "Mastery can be bought between matches and before Start"
	end
	if typeof(heroKey) ~= "string" or not Config.Heroes[heroKey] then
		return false, "Unknown hero"
	end
	if not owns(player, "hero", heroKey) then
		return false, `Unlock {Config.Heroes[heroKey].display} first`
	end
	local profile = profiles[player]
	if not profile then
		return false, "Still loading your progress"
	end
	local level = profile.mastery[heroKey] or 0
	local nextLevel = Config.Mastery[level + 1]
	if not nextLevel then
		return false, "Mastery is maxed"
	end
	if profile.cores < nextLevel.coreCost then
		return false, `Not enough {Theme.Currency}`
	end
	profile.cores -= nextLevel.coreCost
	profile.mastery[heroKey] = level + 1
	publish(player)
	task.spawn(save, player)
	if onMasteryChanged then
		onMasteryChanged(player)
	end
	return true, `{Config.Heroes[heroKey].display} mastery {level + 1}!`
end

------------------------------------------------------------------ unlocks

function Progression.ownsTower(player: Player, towerKey: string): boolean
	return owns(player, "tower", towerKey)
end

function Progression.ownsHero(player: Player, heroKey: string): boolean
	return owns(player, "hero", heroKey)
end

local function buyUnlock(player: Player, kind: unknown, itemKey: unknown): (boolean, string)
	if ReplicatedStorage:GetAttribute("State") == "Playing" then
		return false, "Unlocks can be bought between matches and before Start"
	end
	if typeof(kind) ~= "string" or typeof(itemKey) ~= "string" then
		return false, "Unknown unlock"
	end
	local cost = costOf(kind, itemKey)
	if cost == nil then
		return false, "Unknown unlock"
	end
	if kind == "tower" and ShopRules.Unreleased[itemKey] then
		return false, "That tower isn't out yet"
	end
	local profile = profiles[player]
	if not profile then
		return false, "Still loading your progress"
	end
	if owns(player, kind, itemKey) then
		return false, "You already own that"
	end
	if profile.cores < cost then
		return false, `Not enough {Theme.Currency}`
	end
	profile.cores -= cost
	profile.owned[`{kind}:{itemKey}`] = true
	publish(player)
	task.spawn(save, player)
	local def = if kind == "tower" then Config.Towers[itemKey] else Config.Heroes[itemKey]
	return true, `{def.display} unlocked!`
end

------------------------------------------------------------------ hunt board

-- Claims and swaps happen on the home screen only (DECISIONS #69).
local function boardOpen(player: Player): (Profile?, string)
	if ReplicatedStorage:GetAttribute("State") ~= "Lobby" then
		return nil, "The Hunt Board is on the home screen"
	end
	local profile = profiles[player]
	if not profile then
		return nil, "Still loading your progress"
	end
	if not profile.rewards then
		return nil, "The Hunt Board is closed right now"
	end
	return profile, ""
end

-- After a claim or swap was tried: show what changed, and save it if it worked.
local function settle(player: Player, changed: boolean)
	publish(player)
	if changed then
		task.spawn(save, player)
	end
end

local function claimHaul(player: Player): (boolean, string, number?)
	local profile, why = boardOpen(player)
	if not profile then
		return false, why
	end
	local version = profile.rewardsVersion
	local ok, amber = Profile.claimHaul(profile, os.time(), rng)
	settle(player, profile.rewardsVersion ~= version)
	if not ok then
		return false, "Today's Haul is already claimed"
	end
	return true, `+{Theme.formatAmber(amber)} {Theme.Currency}`, amber
end

local function claimBounty(player: Player, id: unknown): (boolean, string, number?)
	local profile, why = boardOpen(player)
	if not profile then
		return false, why
	end
	local version = profile.rewardsVersion
	local ok, amber = Profile.claimBounty(profile, id, os.time(), rng)
	settle(player, profile.rewardsVersion ~= version)
	if not ok then
		return false, "That bounty can't be claimed"
	end
	return true, `+{Theme.formatAmber(amber)} {Theme.Currency}`, amber
end

local function swapBounty(player: Player, id: unknown): (boolean, string, string?)
	local profile, why = boardOpen(player)
	if not profile then
		return false, why
	end
	local version = profile.rewardsVersion
	local ok, newId = Profile.swapBounty(profile, id, os.time(), rng)
	settle(player, profile.rewardsVersion ~= version)
	if not ok or not newId then
		return false, "That bounty can't be swapped"
	end
	return true, "Bounty swapped", newId
end

-- The owner's own board (Profile.View). `open` = true when the board is on their
-- screen: the "unclaimed bounties paid" amount is then handed over once.
local function getRewards(player: Player, open: unknown): (boolean, any)
	local profile = profiles[player]
	if not profile then
		return false, "Still loading your progress"
	end
	if not profile.rewards then
		return false, "The Hunt Board is closed right now"
	end
	if ReplicatedStorage:GetAttribute("State") == "Lobby" then
		local version = profile.rewardsVersion
		Profile.refresh(profile, os.time(), rng)
		settle(player, profile.rewardsVersion ~= version)
	end
	return true, Profile.view(profile, os.time(), open == true)
end

-- Count a match event for one hunter. Never errors (it's called from the middle of
-- combat and the shop) and never pays: a finished bounty is claimed on the Hunt Board.
local function bountyProgress(player: Player, event: string, target: string?, amount: number?, context: Bounties.Context?)
	local profile = profiles[player]
	if not profile or not profile.rewards then
		return
	end
	local ok, finished = pcall(Profile.bountyEvent, profile, event, target, amount, context)
	if not ok then
		warn(`[Progression] bounty event {event} failed for {player.Name}: {finished}`)
		return
	end
	if #finished == 0 then
		return
	end
	for _, id in finished do
		if bountyDone then
			bountyDone:FireClient(player, id) -- the client shows Bounties.doneText(id)
		end
	end
	publish(player)
end

-- A match event for this hunter: one of Bounties.EVENTS, with its target (species or
-- difficulty key), amount and context as Shared/Bounties describes. Ignored outside a
-- match, so nothing can be finished in the lobby (DECISIONS #66); `ability` also waits
-- for a round to be running (DECISIONS #85). The rule is Bounties.counts.
function Progression.bountyEvent(player: Player, event: string, target: string?, amount: number?, context: Bounties.Context?)
	if not Bounties.counts(event, ReplicatedStorage:GetAttribute("State")) then
		return
	end
	bountyProgress(player, event, target, amount, context)
end

------------------------------------------------------------------ match end

export type MatchResult = {
	cleared: boolean, -- every round of the track beaten
	roundReached: number,
	difficulty: string, -- key in Config.Difficulties
	players: number, -- took part in the match and still here (Main counts them)
}

-- Casual payouts (Shared/Payouts, VISION.md): a clear pays the difficulty's
-- reward to everyone here; a multiplayer loss pays everyone
-- MultiplayerLossPayout; a solo loss pays nothing. Also records the round
-- reached.
function Progression.endMatch(result: MatchResult)
	local payout = Payouts.casualPayout(result.cleared, result.players, result.difficulty)
	for player, profile in profiles do
		profile.cores += payout
		profile.highestRound = math.max(profile.highestRound, result.roundReached)
		if result.cleared then
			-- Straight in: the match state is already Victory.
			bountyProgress(player, "clear", result.difficulty)
		end
		pcall(Profile.refresh, profile, os.time(), rng) -- the match may have run past a reset
		player:SetAttribute("LastPayout", payout) -- the results screen shows it
		publish(player)
		task.spawn(save, player)
	end
	print(`[DinoHunters] Match over (round {result.roundReached}, {if result.cleared then "cleared" else "lost"}): +{Theme.amberExact(payout)} {Theme.Currency} each`)
end

------------------------------------------------------------------ ranked battles

-- Published = a live server, where saves are real. Studio (or an unpublished place) is
-- Practice: session Amber is staked and paid by the same rules, Trophies don't change
-- (DECISIONS #216).
function Progression.practice(): boolean
	return RunService:IsStudio() or game.PlaceId == 0
end

-- May this player press Ready for Ranked? (Stakes.canStake.) The reason is a key the
-- home screen words (T82): "offline" (their save didn't load), "cantAfford", "loading"
-- (still loading), or "practice" when allowed in Practice.
function Progression.canStake(player: Player): (boolean, string?)
	local profile = profiles[player]
	if not profile then
		return false, "loading"
	end
	return Stakes.canStake(canSave[player] == true, not Progression.practice(), profile.cores, Config.Tuning.CompetitiveBuyIn)
end

-- Take the buy-in into escrow when the match starts (Building), and save at once.
-- False when the player can't stake now (nothing is taken).
function Progression.stake(player: Player, matchId: string): boolean
	local ok = Progression.canStake(player)
	local profile = profiles[player]
	if not ok or not profile or not Profile.stake(profile, matchId, Config.Tuning.CompetitiveBuyIn) then
		return false
	end
	publish(player)
	task.spawn(save, player)
	return true
end

-- A match that never started after stakes were taken (couldn't seat): every stake back.
function Progression.refundStake(player: Player)
	local profile = profiles[player]
	if profile and Profile.refundEscrow(profile) > 0 then
		publish(player)
		task.spawn(save, player)
	end
end

export type BattleHunter = { player: Player, place: number, present: boolean, staked: boolean }
export type BattleResult = {
	mode: string, -- "TEAM" / "ROYALE"
	n: number, -- sides (Camp Clash) or seats (Bone Rush), stand-ins included
	ranked: boolean,
	matchId: string?,
	hunters: { BattleHunter }, -- every real hunter seated at the start; never stand-ins or joiners
	standIns: { number }?, -- each stand-in seat's placement: they hold their places in Practice's split (T86b)
}

-- A battle's end (PLAN T80, DECISIONS #215-#218, #222): each hunter still here is paid
-- (casual payout + pot share), their Trophies move (Ranked, not Practice) and their
-- escrow is cleared, in one save. A winner's match counts as a Normal clear for bounties.
-- Leavers forfeited at leaving and get nothing here.
function Progression.endBattle(result: BattleResult)
	local practice = Progression.practice()
	local seats = {}
	for _, h in result.hunters do
		table.insert(seats, { id = h.player, place = h.place, present = h.present and h.player.Parent ~= nil, stake = if h.staked then Config.Tuning.CompetitiveBuyIn else 0 })
	end
	local settled, pot, leftover = Stakes.settleBattle(result.mode, result.n, seats, result.ranked, practice, result.standIns)
	ReplicatedStorage:SetAttribute("BattlePractice", if result.ranked and practice then true else nil)
	ReplicatedStorage:SetAttribute("BattlePot", if result.ranked then pot else nil) -- the results' Amber Hoard (T83)
	for _, seat in seats do
		local player: Player = seat.id
		local profile = profiles[player]
		local got = settled[player]
		if seat.present and profile and got then
			local ok, err = pcall(function()
				local change, reached = Profile.settleBattle(profile, if result.ranked then result.matchId else nil, got.payout, got.trophies)
				if seat.place == 1 then
					bountyProgress(player, "clear", PlayerLevel.BATTLE_CLEAR) -- a win counts as a Normal clear (#222)
				end
				pcall(Profile.refresh, profile, os.time(), rng)
				player:SetAttribute("LastPayout", got.payout)
				player:SetAttribute("LastPotShare", if result.ranked then got.share else nil)
				player:SetAttribute("LastTrophies", if result.ranked and not practice then change else nil)
				player:SetAttribute("LastArena", if #reached > 0 then Config.Arenas[reached[#reached]].key else nil)
			end)
			if not ok then
				warn(`[Progression] Battle settle failed for {player.Name}: {err}`)
			end
			publish(player)
			task.spawn(save, player)
		end
	end
	print(`[DinoHunters] Battle settled ({if result.ranked then (if practice then "Practice Hunt" else "Ranked") else "Casual"}): pot {pot}, sink {leftover}`)
end

------------------------------------------------------------------ player level

-- One match's player XP for a hunter (Main, at match end, before endMatch, which
-- saves it). The result screen reads LastPlayerXp, and LastPlayerLevelFrom /
-- LastPlayerLevel when it raised the level. A player whose save didn't load keeps it
-- for the session only, like Amber.
function Progression.addPlayerXp(player: Player, amount: number)
	local profile = profiles[player]
	if not profile then
		-- Still loading: hold it until the load ends (DECISIONS #179).
		local waiting = held[player]
		if waiting and player.Parent then
			Profile.hold(waiting, amount)
		end
		return
	end
	local ok, err = pcall(function()
		local before = PlayerLevel.level(profile.playerXp)
		local added = Profile.addPlayerXp(profile, amount)
		local after = PlayerLevel.level(profile.playerXp)
		player:SetAttribute("LastPlayerXp", added)
		player:SetAttribute("LastPlayerLevelFrom", if after > before then before else nil)
		player:SetAttribute("LastPlayerLevel", if after > before then after else nil)
	end)
	if not ok then
		warn(`[Progression] Player XP for {player.Name} failed: {err}`)
	end
	publish(player)
end

------------------------------------------------------------------ cosmetics

-- Wear an unlocked item, or take one off (id ""). Any time: it's only a look.
local function equip(player: Player, slot: unknown, id: unknown): (boolean, string)
	local profile = profiles[player]
	if not profile then
		return false, "Still loading your progress"
	end
	-- Lobby only, and the player sees only REFUSED / NOT_LOBBY (DECISIONS #184, #187).
	local state = ReplicatedStorage:GetAttribute("State")
	local allowed, text, why = Cosmetics.request(state, slot, id, PlayerLevel.level(profile.playerXp), Profile.bestArenaIndex(profile))
	if not allowed then
		warn(`[Progression] equip refused for {player.Name}: {why}`)
		return false, text
	end
	local ok, internal = Profile.equip(profile, slot, id)
	if not ok then
		warn(`[Progression] equip refused for {player.Name}: {internal}`)
		return false, Cosmetics.REFUSED
	end
	publish(player)
	task.spawn(save, player)
	if onLookChanged then
		onLookChanged(player)
	end
	return true, if id == nil or id == "" then "Taken off" else "Equipped"
end

------------------------------------------------------------------ skins (T142)

-- What the shop counter shows: every skin you own (bought, granted or by level), what each
-- slot wears, the Display Towers, your level and Amber.
local function skinView(player: Player): (boolean, any)
	local profile = profiles[player]
	if not profile then
		return false, "Still loading your progress"
	end
	local level = PlayerLevel.level(profile.playerXp)
	local owned = {}
	for _, key in Config.SkinOrder do
		if Skins.owns(profile.skins, key, level) then
			owned[key] = true
		end
	end
	return true, { owned = owned, wear = table.clone(profile.skins.wear), deco = Skins.toSave(profile.skins).deco, level = level }
end

-- Buy (Amber), wear, Display Towers: between matches only (nothing bought mid-match, #389),
-- each saved at once. Looks only.
local function skinAction(player: Player, action: unknown, a: unknown, b: unknown): (boolean, string)
	local state = ReplicatedStorage:GetAttribute("State")
	if state ~= "Lobby" and player:GetAttribute("InOutpost") ~= true then
		return false, "Skins wait in camp between matches"
	end
	local profile = profiles[player]
	if not profile then
		return false, "Still loading your progress"
	end
	local level = PlayerLevel.level(profile.playerXp)
	local ok, message
	if action == "buySkin" then
		local price, refusal = Skins.canBuy(profile.skins, a, level)
		if not price then
			return false, refusal
		end
		if profile.cores < price then
			return false, `Not enough {Theme.Currency}`
		end
		profile.cores -= price
		ok, message = Skins.buy(profile.skins, a), "It's yours!"
	elseif action == "wearSkin" then
		ok, message = Skins.wear(profile.skins, a, b, level)
	elseif action == "setDeco" then
		ok, message = Skins.setDeco(profile.skins, a, b, function(tower: string): boolean
			return owns(player, "tower", tower)
		end)
	elseif action == "studioSkins" then
		-- Studio test aid (StudioOnly skins): every skin owned, saving off like J.
		if not StudioOnly.allowed(RunService:IsStudio(), "skins") then
			return false, "Studio only"
		end
		canSave[player] = false
		Skins.grant(profile.skins, Config.SkinOrder)
		ok, message = true, "Studio: every skin (saving off)"
	else
		return false, "Unknown request"
	end
	if ok then
		publish(player)
		task.spawn(save, player)
		if onLookChanged then
			onLookChanged(player)
		end
	end
	return ok, message
end

------------------------------------------------------------------ store (T143)

-- Game Pass effects for this player (Server/Store after UserOwnsGamePassAsync or a purchase).
function Progression.setPasses(player: Player, owned: { [string]: boolean })
	passEffects[player] = StoreRules.passEffects(owned)
	publish(player)
end

-- The earliest egg of `egg` still warming, or nil.
local function warmingSlot(profile: Profile, egg: string, now: number): number?
	if not profile.pets then
		return nil
	end
	for slot, e in profile.pets.eggs do
		if e.egg == egg and e.readyAt > now then
			return slot
		end
	end
	return nil
end

function Progression.hasWarmingEgg(player: Player, egg: string): boolean
	local profile = profiles[player]
	return profile ~= nil and warmingSlot(profile, egg, os.time()) ~= nil
end

-- What the store shows this player besides the catalogue: paid Hatch now credits.
function Progression.storeView(player: Player): { [string]: number }
	local profile = profiles[player]
	return if profile then table.clone(profile.store.hatchCredits) else {}
end

-- A Developer Product receipt (Server/Store's ProcessReceipt). Only a profile that loaded
-- and may be saved gets a grant; the PurchaseId is granted once; PurchaseGranted only
-- after the save went through (Shared/Store.processReceipt).
function Progression.storeReceipt(player: Player, purchaseId: string, key: string?): string
	local profile = profiles[player]
	local row = StoreRules.row(key)
	local decision = StoreRules.processReceipt(
		profile ~= nil and canSave[player] == true,
		profile and profile.store,
		purchaseId,
		if row and row.type == "product" then key else nil,
		function(): boolean
			local p = profile :: Profile
			local r = row :: StoreRules.Row
			if r.grant == "amber" and r.amount then
				p.cores += r.amount
			elseif r.grant == "hatch" and r.items[1] then
				local egg = r.items[1]
				local slot = warmingSlot(p, egg, os.time())
				if slot and p.pets then
					Pets.warm(p.pets, slot, os.time())
				else
					p.store.hatchCredits[egg] = (p.store.hatchCredits[egg] or 0) + 1
				end
			elseif r.grant == "skins" then
				Skins.grant(p.skins, r.items)
			else
				return false
			end
			return true
		end,
		function(): boolean
			return save(player)
		end
	)
	if decision == StoreRules.GRANTED then
		publish(player)
		if onLookChanged then
			onLookChanged(player)
		end
	end
	return decision
end

------------------------------------------------------------------ public

------------------------------------------------------------------ training (T139)

do
	local dirty: { [Player]: boolean } = {} -- training changed since the last bank

	-- One tick of online time (Server/Training). Returns the stats that levelled.
	function Progression.trainingTick(player: Player, dt: number, at: string?, tickLength: number): { string }
		local profile = profiles[player]
		if not profile or #profile.training.active == 0 then
			return {}
		end
		local effects = effectsOf(player)
		while #profile.training.active > effects.trainSlots do
			table.remove(profile.training.active, 1) -- more than this player's slots (T143)
		end
		local leveled = Training.tick(profile.training, dt, at, tickLength, effects.trainRate)
		dirty[player] = true
		publishTraining(player)
		return leveled
	end

	function Progression.trainStart(player: Player, stat: unknown): (boolean, string)
		local profile = profiles[player]
		if not profile then
			return false, "Still loading your progress"
		end
		local ok, message = Training.start(profile.training, stat, effectsOf(player).trainSlots)
		if ok then
			dirty[player] = true
			publishTraining(player)
		end
		return ok, message
	end

	-- Amber finishes the current level (#373): between matches only (nothing bought
	-- mid-match), once the sheet has a price; saved at once like any purchase.
	function Progression.trainFinish(player: Player, stat: unknown): (boolean, string)
		local state = ReplicatedStorage:GetAttribute("State")
		if state ~= "Lobby" and player:GetAttribute("InOutpost") ~= true then
			return false, "Finish a level between matches"
		end
		local profile = profiles[player]
		if not profile then
			return false, "Still loading your progress"
		end
		local price = Training.finishPrice(profile.training, stat)
		if not price then
			return false, if Training.isStat(stat) then "Not for sale yet" else "Unknown station"
		end
		if profile.cores < price then
			return false, `Not enough {Theme.Currency}`
		end
		profile.cores -= price
		Training.finish(profile.training, stat)
		publish(player)
		task.spawn(save, player)
		return true, "Level finished!"
	end

	-- Studio test aid "trainskip <min>" (StudioOnly trainSkip): that many full-rate minutes
	-- to whatever is training; saving off for that player, like J.
	function Progression.trainSkip(player: Player, minutes: unknown): boolean
		if not StudioOnly.allowed(RunService:IsStudio(), "trainSkip") or type(minutes) ~= "number" or minutes ~= minutes then
			return false
		end
		local profile = profiles[player]
		if not profile then
			return false
		end
		canSave[player] = false -- keep test progress out of the real save
		Training.credit(profile.training, math.clamp(minutes, 0, 10000) * 60)
		publish(player)
		return true
	end

	-- Every Training bank (s): write the saves whose training moved (only saves that loaded
	-- are ever written: save() checks).
	function Progression.bankTraining()
		for player in dirty do
			dirty[player] = nil
			if player.Parent and canSave[player] then
				task.spawn(save, player)
			end
		end
	end

	Players.PlayerRemoving:Connect(function(player)
		dirty[player] = nil -- the leave save writes it
	end)
end

-- Eggs and pets (PLAN 10d T140/T141): the rules are Shared/Pets; Server/Pets owns the remote,
-- the Hatchery Hut and the pet in play, and calls these. Every change between matches
-- only (nothing bought or swapped mid-match, #389), saved at once like any purchase.
do
	local function petsOf(player: Player): (Pets.State?, string)
		local profile = profiles[player]
		if not profile then
			return nil, "Still loading your progress"
		end
		if not profile.pets then
			return nil, "Your pets couldn't be loaded this session; they're safe"
		end
		return profile.pets, ""
	end

	local function changed(player: Player)
		publish(player)
		task.spawn(save, player)
	end

	-- What the Hatchery Hut shows: the saved state (the client runs Shared/Pets on it) and
	-- the server clock it was read at.
	function Progression.petView(player: Player): (boolean, any)
		local state, why = petsOf(player)
		if not state then
			return false, why
		end
		return true, { state = Pets.toSave(state), now = os.time() }
	end

	function Progression.petAlong(player: Player): Pets.Pet?
		local profile = profiles[player]
		return if profile and profile.pets then Pets.along(profile.pets) else nil
	end

	function Progression.petPen(player: Player): { Pets.Pet }
		local profile = profiles[player]
		local out = {}
		if profile and profile.pets then
			for _, id in profile.pets.pen do
				for _, pet in profile.pets.pets do
					if pet.id == id then
						table.insert(out, pet)
					end
				end
			end
		end
		return out
	end

	function Progression.petAction(player: Player, action: unknown, a: unknown, b: unknown): (boolean, string)
		local game_ = ReplicatedStorage:GetAttribute("State")
		if game_ ~= "Lobby" and player:GetAttribute("InOutpost") ~= true then
			return false, "Pets wait in camp between matches"
		end
		local state, why = petsOf(player)
		if not state then
			return false, why
		end
		local profile = profiles[player] :: Profile
		local now = os.time()
		local ok, message
		if action == "buy" then
			local price, refusal = Pets.canBuy(state, a, effectsOf(player).incubators)
			if not price then
				return false, refusal
			end
			if profile.cores < price then
				return false, `Not enough {Theme.Currency}`
			end
			profile.cores -= price
			ok, message = Pets.buy(state, a, now)
			-- A paid Hatch now that found no egg of this kind (T143) hatches this one.
			local credits = profile.store.hatchCredits
			if ok and type(a) == "string" and (credits[a] or 0) > 0 then
				credits[a] -= 1
				if credits[a] <= 0 then
					credits[a] = nil
				end
				Pets.warm(state, #state.eggs, now)
				message = "Your paid Hatch now was used: it's ready!"
			end
		elseif action == "warm" then
			local price = Pets.warmPrice(state, a, now)
			if not price then
				return false, "Nothing to warm up"
			end
			if profile.cores < price then
				return false, `Not enough {Theme.Currency}`
			end
			profile.cores -= price
			ok, message = Pets.warm(state, a, now), "Warmed up!"
		elseif action == "hatch" then
			ok, message = Pets.hatch(state, a, now, rng)
		elseif action == "fuse" then
			ok, message = Pets.fuse(state, a, b)
		elseif action == "along" then
			ok, message = Pets.takeAlong(state, if a == 0 then nil else a)
		elseif action == "pen" then
			ok, message = Pets.setPen(state, a, b == true)
		elseif action == "studioegg" or action == "hatchnow" or action == "studiopet" then
			-- Studio test aids (StudioOnly pets): free eggs / instant hatch / pets for fuse
			-- tests; saving off for that player, like J.
			if not StudioOnly.allowed(RunService:IsStudio(), "pets") then
				return false, "Studio only"
			end
			canSave[player] = false
			if action == "studioegg" then
				if not Pets.hatchSeconds(a) then
					return false, "Unknown egg"
				end
				table.insert(state.eggs, { egg = a :: string, readyAt = now + (Pets.hatchSeconds(a) :: number) })
				ok, message = true, "Studio: free egg (saving off)"
			elseif action == "hatchnow" then
				for slot in state.eggs do
					Pets.warm(state, slot, now)
				end
				ok, message = true, "Studio: every egg is ready (saving off)"
			else
				local n = math.clamp(math.floor(tonumber(b) or 1), 1, 60)
				local kind, rarity = string.match(tostring(a), "^(%S+)%s+(%S+)$")
				if not (Config :: any).Pets[kind] or not Pets.rarityMult(rarity) then
					return false, "Studio: studiopet <PET> <RARITY>"
				end
				for _ = 1, n do
					table.insert(state.pets, { id = state.nextId, kind = kind :: string, rarity = rarity :: string })
					state.nextId += 1
				end
				ok, message = true, `Studio: +{n} pets (saving off)`
			end
		else
			return false, "Unknown request"
		end
		if ok then
			changed(player)
		end
		return ok, message
	end
end

function Progression.init(
	remotes: Folder,
	hooks: { onMasteryChanged: ((Player) -> ())?, onLookChanged: ((Player) -> ())? }?
)
	onMasteryChanged = hooks and hooks.onMasteryChanged
	onLookChanged = hooks and hooks.onLookChanged
	local request = Instance.new("RemoteFunction")
	request.Name = "ProgressRequest"
	-- ("mastery", heroKey) or ("unlock", "tower" | "hero", key) -> ok, message
	-- Hunt Board: ("claimHaul") or ("claimBounty", id) -> ok, message, Amber
	--             ("swapBounty", id) -> ok, message, the new bounty's id
	--             ("getRewards", boardIsOpen) -> true, Profile.View | false, message
	-- Cosmetics:  ("equip", slot, itemId | "") -> ok, message
	-- Skins (T142): ("skins") -> true, view | ("buySkin", key) | ("wearSkin", slot, key | "")
	--             | ("setDeco", 1..3, towerKey | "") | ("studioSkins") Studio only -> ok, message
	request.OnServerInvoke = function(player: Player, action: unknown, a: unknown, b: unknown)
		local ok, success, message, detail = pcall(function(): (boolean, any, any)
			if action == "mastery" then
				return buyMastery(player, a)
			elseif action == "unlock" then
				return buyUnlock(player, a, b)
			elseif action == "claimHaul" then
				return claimHaul(player)
			elseif action == "claimBounty" then
				return claimBounty(player, a)
			elseif action == "swapBounty" then
				return swapBounty(player, a)
			elseif action == "getRewards" then
				return getRewards(player, a)
			elseif action == "equip" then
				return equip(player, a, b)
			elseif action == "skins" then
				return skinView(player)
			elseif action == "buySkin" or action == "wearSkin" or action == "setDeco" or action == "studioSkins" then
				return skinAction(player, action, a, b)
			end
			return false, "Unknown request"
		end)
		if not ok then
			warn(`[Progression] request from {player.Name} failed: {success}`)
			return false, "Something went wrong"
		end
		return success, message, detail
	end
	request.Parent = remotes

	local done = Instance.new("RemoteEvent")
	done.Name = "BountyDone"
	done.Parent = remotes
	bountyDone = done

	-- Studio-only test shortcut (J): +100 Amber x Amber scale (100K) for this session, so buying
	-- unlocks and mastery can be tried. Never saved, never present in a
	-- published game.
	if StudioOnly.allowed(RunService:IsStudio(), "amber") then
		local studio = Instance.new("RemoteEvent")
		studio.Name = "StudioProgress"
		studio.OnServerEvent:Connect(function(player)
			if not StudioOnly.allowed(RunService:IsStudio(), "amber") then
				return
			end
			local profile = profiles[player]
			if profile then
				canSave[player] = false -- keep test progress out of the real save
				profile.cores += 100 * Profile.AMBER_SCALE
				publish(player)
			end
		end)
		studio.Parent = remotes
	end

	Players.PlayerAdded:Connect(function(player)
		held[player] = Profile.newHeld()
		task.spawn(load, player)
	end)
	for _, player in Players:GetPlayers() do
		held[player] = Profile.newHeld()
		task.spawn(load, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		leaving[player] = true
		-- An open ranked stake: a leaver forfeits it to the pot and loses Trophies as last
		-- place in that lobby (PLAN T82, DECISIONS #233; never in Practice); a shutdown gives
		-- it back (DECISIONS #216). Either way the escrow is closed before the last save.
		local profile = profiles[player]
		if profile and profile.escrow then
			if closing then
				Profile.refundEscrow(profile)
			else
				local modeKey = ReplicatedStorage:GetAttribute("BattleMode")
				local n = ReplicatedStorage:GetAttribute("Sides")
				Profile.leaveRanked(
					profile,
					profile.escrow.matchId,
					if typeof(modeKey) == "string" then modeKey else "",
					if typeof(n) == "number" then n else 0,
					Progression.practice()
				)
			end
		end
		save(player, true) -- the last write frees the session lock for the next server
		profiles[player] = nil
		canSave[player] = nil
		held[player] = nil
		passEffects[player] = nil
		sessions[player], locked[player], leaving[player] = nil, nil, nil
	end)
	-- Keep each held lock fresh (well inside Profile.LOCK_STALE), so only a crashed
	-- server's lock ever goes stale. A save that loaded is written; others only touch the lock.
	task.spawn(function()
		while true do
			task.wait(Profile.LOCK_REFRESH)
			for player in locked do
				if not leaving[player] and not closing then
					task.spawn(save, player)
				end
			end
		end
	end)
	-- Shutdown: every open stake comes back (#216) and every save is written and released
	-- at once, in parallel; wait (up to CLOSE_DEADLINE) for those and any leaver's save.
	game:BindToClose(function()
		closing = true
		for player, profile in profiles do
			if not leaving[player] then
				Profile.refundEscrow(profile)
				task.spawn(save, player, true)
			end
		end
		local started = os.clock()
		task.wait() -- let the saves start
		while inFlight > 0 and os.clock() - started < CLOSE_DEADLINE do
			task.wait(0.25)
		end
	end)
end

return Progression
