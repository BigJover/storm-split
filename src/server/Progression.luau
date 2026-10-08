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

local Progression = {}

type Profile = Profile.Profile

local STORE_NAME = "StormSplitProgress_v1"
local LOAD_ATTEMPTS = 3
local RETRY_DELAY = 2 -- seconds between load attempts

local profiles: { [Player]: Profile } = {}
local onMasteryChanged: ((Player) -> ())? = nil
local canSave: { [Player]: boolean } = {} -- false = session-only (store unreachable at load)
local held: { [Player]: Profile.Held } = {} -- player XP that arrived while the save was loading
local onLookChanged: ((Player) -> ())? = nil
local bountyDone: RemoteEvent? = nil -- (bounty id), to the hunter who finished it only
local store: DataStore? = nil
local saveHintGiven = false -- the developer's "publish the place" hint: one warn per session
local closing = false -- the server is shutting down (BindToClose): open stakes are refunded
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
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
end

------------------------------------------------------------------ load / save

local save: (Player) -> () -- below: a load that settles held XP saves it

local function load(player: Player)
	local profile: Profile? = nil
	if store then
		for attempt = 1, LOAD_ATTEMPTS do
			local ok, raw = pcall(function()
				return (store :: DataStore):GetAsync(key(player))
			end)
			if ok then
				-- A stored value that can't be read at all counts as a failed load.
				ok, raw = pcall(Profile.sanitize, raw, os.time(), rng)
				if ok then
					profile = raw
				else
					warn(`[Progression] Couldn't read {player.Name}'s save: {raw}`)
				end
				break
			end
			warn(`[Progression] Load {attempt}/{LOAD_ATTEMPTS} failed for {player.Name}: {raw}`)
			task.wait(RETRY_DELAY)
		end
	end
	if not player.Parent then
		held[player] = nil
		return -- left while loading
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
		print(`[Progression] Refunded {player.Name}'s unsettled stake of {refunded} {Theme.Currency}`)
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

save = function(player: Player)
	local profile = profiles[player]
	if not profile or not canSave[player] or not store then
		return
	end
	local ok, err = pcall(function()
		(store :: DataStore):SetAsync(key(player), Profile.toSave(profile))
	end)
	if not ok then
		warn(`[Progression] Save failed for {player.Name}: {err}`)
	end
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
	return true, `+{amber} {Theme.Currency}`, amber
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
	return true, `+{amber} {Theme.Currency}`, amber
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
	print(`[DinoHunters] Match over (round {result.roundReached}, {if result.cleared then "cleared" else "lost"}): +{payout} {Theme.Currency} each`)
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
	local settled, pot, leftover = Stakes.settleBattle(result.mode, result.n, seats, result.ranked, practice)
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

------------------------------------------------------------------ public

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

	-- Studio-only test shortcut (J): +100 Amber for this session, so buying
	-- unlocks and mastery can be tried. Never saved, never present in a
	-- published game.
	if RunService:IsStudio() then
		local studio = Instance.new("RemoteEvent")
		studio.Name = "StudioProgress"
		studio.OnServerEvent:Connect(function(player)
			local profile = profiles[player]
			if profile then
				canSave[player] = false -- keep test progress out of the real save
				profile.cores += 100
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
		save(player)
		profiles[player] = nil
		canSave[player] = nil
		held[player] = nil
	end)
	game:BindToClose(function()
		closing = true
		for player, profile in profiles do
			Profile.refundEscrow(profile) -- an open stake comes back on a shutdown (#216)
			save(player)
		end
	end)
end

return Progression
