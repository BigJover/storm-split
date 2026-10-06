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
	                (Competitive buy-ins and pots come with the battle modes.)
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
local Theme = require(Shared:WaitForChild("Theme"))

local Progression = {}

type Profile = Profile.Profile

local STORE_NAME = "StormSplitProgress_v1"
local LOAD_ATTEMPTS = 3
local RETRY_DELAY = 2 -- seconds between load attempts

local profiles: { [Player]: Profile } = {}
local onMasteryChanged: ((Player) -> ())? = nil
local canSave: { [Player]: boolean } = {} -- false = session-only (store unreachable at load)
local bountyDone: RemoteEvent? = nil -- (bounty id), to the hunter who finished it only
local store: DataStore? = nil
local saveHintGiven = false -- the developer's "publish the place" hint: one warn per session
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
	player:SetAttribute("RewardsClaimable", Profile.claimable(profile, os.time()))
	player:SetAttribute("RewardsVersion", profile.rewardsVersion)
end

------------------------------------------------------------------ load / save

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
	profiles[player] = loaded
	publish(player)
end

local function save(player: Player)
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

------------------------------------------------------------------ player level

-- One match's player XP for a hunter (Main, at match end, before endMatch, which
-- saves it). The result screen reads LastPlayerXp, and LastPlayerLevelFrom /
-- LastPlayerLevel when it raised the level. A player whose save didn't load keeps it
-- for the session only, like Amber.
function Progression.addPlayerXp(player: Player, amount: number)
	local profile = profiles[player]
	if not profile then
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

------------------------------------------------------------------ public

function Progression.init(remotes: Folder, hooks: { onMasteryChanged: ((Player) -> ())? }?)
	onMasteryChanged = hooks and hooks.onMasteryChanged
	local request = Instance.new("RemoteFunction")
	request.Name = "ProgressRequest"
	-- ("mastery", heroKey) or ("unlock", "tower" | "hero", key) -> ok, message
	-- Hunt Board: ("claimHaul") or ("claimBounty", id) -> ok, message, Amber
	--             ("swapBounty", id) -> ok, message, the new bounty's id
	--             ("getRewards", boardIsOpen) -> true, Profile.View | false, message
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
		task.spawn(load, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		save(player)
		profiles[player] = nil
		canSave[player] = nil
	end)
	game:BindToClose(function()
		for player in profiles do
			save(player)
		end
	end)
end

return Progression
