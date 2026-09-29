--[[
	Progression: what a player keeps between matches (design doc §05, phase 6).

	Saved per player (DataStoreService): Storm Cores, what they own, a mastery
	level per hero, and the highest round they've ever reached.

	  Storm Cores   the permanent currency (VISION.md). Casual payouts:
	                clearing the track pays the difficulty's Clear reward to
	                everyone; a multiplayer match that ends without a clear pays
	                MultiplayerLossPayout each; a solo loss pays nothing.
	                (Competitive buy-ins and pots come with the battle modes.)
	  Unlocks       heroes and towers with an Unlock cost are bought with Cores.
	                Free ones (cost 0) are owned by everyone. You can only pick
	                heroes and place towers you own; upgrading a teammate's
	                tower doesn't need ownership (Shop).
	  Mastery       bought with Cores, per owned hero, up to 20 levels (Mastery
	                sheet): cheaper hero upgrades, shorter cooldowns, a free
	                first upgrade, a higher crossover cap — never damage

	Unlocks and mastery can only be bought outside a running match, so a match
	always plays with what everyone started it with.

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

local Progression = {}

type Profile = {
	cores: number,
	owned: { [string]: boolean }, -- "tower:CHILLER", "hero:RIFLE"; free ones aren't stored
	mastery: { [string]: number }, -- hero key -> level
	highestRound: number,
}

local STORE_NAME = "StormSplitProgress_v1"
local LOAD_ATTEMPTS = 3
local RETRY_DELAY = 2 -- seconds between load attempts

local profiles: { [Player]: Profile } = {}
local onMasteryChanged: ((Player) -> ())? = nil
local canSave: { [Player]: boolean } = {} -- false = session-only (store unreachable at load)
local store: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn(`[Progression] No data store (is the place published?): {result}`)
	end
end

local function key(player: Player): string
	return `player_{player.UserId}`
end

local function blank(): Profile
	return { cores = 0, owned = {}, mastery = {}, highestRound = 0 }
end

-- Anything read from the store is data from an older version or a bad write
-- until proven otherwise.
local function sanitize(raw: any): Profile
	local profile = blank()
	if typeof(raw) ~= "table" then
		return profile
	end
	if typeof(raw.cores) == "number" and raw.cores >= 0 then
		profile.cores = math.floor(raw.cores)
	end
	if typeof(raw.highestRound) == "number" and raw.highestRound >= 0 then
		profile.highestRound = math.floor(raw.highestRound)
	end
	if typeof(raw.owned) == "table" then
		for id, value in raw.owned do
			if value == true and typeof(id) == "string" then
				local kind, itemKey = string.match(id, "^(%a+):(.+)$")
				if (kind == "tower" and Config.Towers[itemKey]) or (kind == "hero" and Config.Heroes[itemKey]) then
					profile.owned[id] = true
				end
			end
		end
	end
	if typeof(raw.mastery) == "table" then
		for heroKey, level in raw.mastery do
			if Config.Heroes[heroKey] and typeof(level) == "number" then
				profile.mastery[heroKey] = math.clamp(math.floor(level), 0, #Config.Mastery)
			end
		end
	end
	return profile
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
				profile = sanitize(raw)
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
	profiles[player] = profile or blank()
	publish(player)
end

local function save(player: Player)
	local profile = profiles[player]
	if not profile or not canSave[player] or not store then
		return
	end
	local ok, err = pcall(function()
		(store :: DataStore):SetAsync(key(player), {
			cores = profile.cores,
			owned = profile.owned,
			mastery = profile.mastery,
			highestRound = profile.highestRound,
		})
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
		return false, "Not enough Storm Cores"
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
		return false, "Not enough Storm Cores"
	end
	profile.cores -= cost
	profile.owned[`{kind}:{itemKey}`] = true
	publish(player)
	task.spawn(save, player)
	local def = if kind == "tower" then Config.Towers[itemKey] else Config.Heroes[itemKey]
	return true, `{def.display} unlocked!`
end

------------------------------------------------------------------ match end

export type MatchResult = {
	cleared: boolean, -- every round of the track beaten
	roundReached: number,
	difficulty: string, -- key in Config.Difficulties
}

-- Casual payouts (VISION.md): a clear pays the difficulty's reward to everyone
-- here; a multiplayer loss pays everyone MultiplayerLossPayout; a solo loss
-- pays nothing. Also records the round reached.
function Progression.endMatch(result: MatchResult)
	local present = 0
	for _ in profiles do
		present += 1
	end
	local difficulty = Config.Difficulties[result.difficulty]
	local payout = if result.cleared
		then (if difficulty then difficulty.clearReward else 0)
		elseif present >= 2 then Config.Tuning.MultiplayerLossPayout
		else 0
	for player, profile in profiles do
		profile.cores += payout
		profile.highestRound = math.max(profile.highestRound, result.roundReached)
		publish(player)
		task.spawn(save, player)
	end
	print(`[StormSplit] Match over (round {result.roundReached}, {if result.cleared then "cleared" else "lost"}): +{payout} Storm Cores each`)
end

------------------------------------------------------------------ public

function Progression.init(remotes: Folder, hooks: { onMasteryChanged: ((Player) -> ())? }?)
	onMasteryChanged = hooks and hooks.onMasteryChanged
	local request = Instance.new("RemoteFunction")
	request.Name = "ProgressRequest"
	-- ("mastery", heroKey) or ("unlock", "tower" | "hero", key)
	request.OnServerInvoke = function(player: Player, action: unknown, a: unknown, b: unknown)
		local ok, success, message = pcall(function()
			if action == "mastery" then
				return buyMastery(player, a)
			elseif action == "unlock" then
				return buyUnlock(player, a, b)
			end
			return false, "Unknown request"
		end)
		if not ok then
			warn(`[Progression] request from {player.Name} failed: {success}`)
			return false, "Something went wrong"
		end
		return success, message
	end
	request.Parent = remotes

	-- Studio-only test shortcut (J): Cores and every hero and tower owned for
	-- this session. Never saved, never present in a published game.
	if RunService:IsStudio() then
		local studio = Instance.new("RemoteEvent")
		studio.Name = "StudioProgress"
		studio.OnServerEvent:Connect(function(player)
			local profile = profiles[player]
			if profile then
				canSave[player] = false -- keep test progress out of the real save
				profile.cores += 100
				for towerKey in Config.Towers do
					profile.owned[`tower:{towerKey}`] = true
				end
				for heroKey in Config.Heroes do
					profile.owned[`hero:{heroKey}`] = true
				end
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
