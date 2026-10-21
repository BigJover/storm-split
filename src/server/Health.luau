--[[
	Health: the only thing that changes a player's HP (ARCHITECTURE.md §4).

	The Humanoid is the one source of truth (DECISIONS #7): MaxHealth and WalkSpeed are
	the picked hunter's body (Shared/HunterStats, the Hunter Stats sheet, PLAN 10a T135;
	no hunter yet = Tuning Player max health / Player walk speed), set on spawn and again
	when the hero pick changes (the same share of HP is kept). Roblox's own regeneration is removed (the empty Health
	script in StarterCharacterScripts), and players heal only through here —
	Heal per round when a round is cleared, and later the Field Medic and the
	Field Hospital. On spawn a force field gives Spawn protection seconds of
	safety; Humanoid:TakeDamage respects it.

	damage() applies damage resistance first (Shared/Combat: the strongest
	source wins, capped). The sources (Armory aura, Field Medic Second Wind)
	plug in through the `resistOf` hook (Main). A hit from a dino
	tells that hunter alone what it was (the "Hurt" remote, Shared/HitNotice;
	DECISIONS #39).

	PvP (PLAN T78, DECISIONS #212): an enemy hunter's shot lands through pvpHit() (the
	damage already x PvP hunter damage, Shared/BattleRules.pvpDamage). Camo Cover: for
	Tuning Spawn shield seconds after each (re)spawn a hunter takes no PvP damage
	(camoCover(); the character's "CamoUntil" attribute, server time, in a battle).

	Raider sting (PLAN 9d, #294; Shared/TowerPerks, applied by Towers): slow() holds a
	hunter's walk speed down by a % for a few seconds (the strongest in effect wins; never a
	stop: the exporter keeps it <= 30 %, <= 3 s), restoring it when it runs out. A slow
	multiplies the hunter's class base (#365), and ends back on the class base of the
	hunter picked by then.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Combat = require(Shared:WaitForChild("Combat"))
local BattleRules = require(Shared:WaitForChild("BattleRules"))
local HunterStats = require(Shared:WaitForChild("HunterStats"))

local Health = {}

-- Every resistance source that applies to this player right now (percents).
local resistOf: ((Player) -> { number })? = nil
local hurtEvent: RemoteEvent? = nil
local spawnedAt: { [Player]: number } = {} -- os.clock() of each hunter's latest spawn (Camo Cover)
type Slow = { humanoid: Humanoid, percent: number, untilAt: number }
local slowed: { [Player]: Slow } = {} -- Raider sting slows in effect

-- What hurt a hunter, for their private hit notice.
export type Source = { species: string, attack: string }

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return humanoid
	end
	return nil
end

-- This hunter's body now: the picked hero's row (Hero publishes the "Hero" attribute) with
-- the account's trained Health / Speed % on top (Progression publishes them, T139).
local function bodyOf(player: Player): HunterStats.Body
	local health, speed = player:GetAttribute("TrainedHealth"), player:GetAttribute("TrainedSpeed")
	return HunterStats.body(player:GetAttribute("Hero"), {
		healthPercent = if type(health) == "number" then health else nil,
		speedPercent = if type(speed) == "number" then speed else nil,
	})
end

local function walkSpeedOf(player: Player): number
	local base = bodyOf(player).walkSpeed
	local slow = slowed[player]
	if slow and os.clock() < slow.untilAt then
		return HunterStats.slowed(base, slow.percent)
	end
	return base
end

-- The hero pick changed: the new body on the living character, keeping its share of HP.
function Health.applyBody(player: Player)
	local humanoid = humanoidOf(player)
	if not humanoid then
		return
	end
	local body = bodyOf(player)
	local health = HunterStats.carryHealth(humanoid.Health, humanoid.MaxHealth, body.maxHealth)
	humanoid.MaxHealth = body.maxHealth
	humanoid.Health = health
	humanoid.WalkSpeed = walkSpeedOf(player)
end

local function watchHero(player: Player)
	for _, name in { "Hero", "TrainedHealth", "TrainedSpeed" } do
		player:GetAttributeChangedSignal(name):Connect(function()
			Health.applyBody(player) -- a new hunter or a trained level: the new body now
		end)
	end
end

export type Hooks = {
	resistOf: ((Player) -> { number })?,
}

function Health.init(remotes: Folder, hooks: Hooks?)
	resistOf = hooks and hooks.resistOf
	local hurt = Instance.new("RemoteEvent")
	hurt.Name = "Hurt" -- (species, attack, damage), to the hunter who was hit only
	hurt.Parent = remotes
	hurtEvent = hurt
	Players.PlayerRemoving:Connect(function(player)
		spawnedAt[player] = nil
		slowed[player] = nil
	end)
	Players.PlayerAdded:Connect(watchHero)
	for _, player in Players:GetPlayers() do
		watchHero(player)
	end
end

-- A fresh character: full health at its hunter's Max HP and Walk speed (unslowed), and a
-- short force field.
function Health.setUp(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local player = Players:GetPlayerFromCharacter(character)
	local body = if player then bodyOf(player) else HunterStats.body(nil)
	if player then
		slowed[player] = nil -- a respawned character starts unslowed
	end
	humanoid.MaxHealth = body.maxHealth
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = body.walkSpeed
	if player then
		spawnedAt[player] = os.clock()
		if ReplicatedStorage:GetAttribute("BattleMode") ~= nil then
			character:SetAttribute("CamoUntil", workspace:GetServerTimeNow() + Config.Tuning.SpawnShield) -- for the HUD
		end
	end
	local seconds = Config.Tuning.SpawnProtection
	if seconds > 0 then
		local shield = Instance.new("ForceField")
		shield.Parent = character
		task.delay(seconds, function()
			shield:Destroy()
		end)
	end
end

-- Hurts a living player by `amount` less their resistance. Returns the damage
-- asked of the Humanoid (a force field still blocks it).
function Health.damage(player: Player, amount: number, source: Source?): number
	local humanoid = humanoidOf(player)
	if not humanoid or amount <= 0 then
		return 0
	end
	local resist = Combat.combineResist(if resistOf then resistOf(player) else {})
	local dealt = Combat.afterResist(amount, resist)
	humanoid:TakeDamage(dealt)
	local shielded = humanoid.Parent ~= nil and humanoid.Parent:FindFirstChildOfClass("ForceField") ~= nil
	if source and hurtEvent and dealt > 0 and not shielded then
		hurtEvent:FireClient(player, source.species, source.attack, dealt)
	end
	return dealt
end

-- Camo Cover: is this hunter still inside Spawn shield seconds of (re)spawning?
function Health.camoCover(player: Player): boolean
	local at = spawnedAt[player]
	return at ~= nil and BattleRules.shielded(os.clock() - at)
end

-- An enemy hunter's shot (already x PvP hunter damage; 0 under Camo Cover is the caller's,
-- through BattleRules.pvpDamage). Returns the damage dealt and whether it downed them.
function Health.pvpHit(player: Player, amount: number): (number, boolean)
	local humanoid = humanoidOf(player)
	if not humanoid or amount <= 0 then
		return 0, false
	end
	local dealt = Health.damage(player, amount, nil)
	return dealt, humanoid.Health <= 0
end

-- Raider sting: `percent` slower for `seconds` (a stronger slow in effect is kept; the
-- longer end wins). A respawned character starts unslowed.
function Health.slow(player: Player, percent: number, seconds: number)
	local humanoid = humanoidOf(player)
	if not humanoid or percent <= 0 or seconds <= 0 then
		return
	end
	local now = os.clock()
	local current = slowed[player]
	if current and (current.humanoid ~= humanoid or now >= current.untilAt) then
		current = nil
	end
	local entry: Slow = {
		humanoid = humanoid,
		percent = if current then math.max(current.percent, percent) else percent,
		untilAt = math.max(if current then current.untilAt else 0, now + seconds),
	}
	slowed[player] = entry
	humanoid.WalkSpeed = walkSpeedOf(player) -- the class base x the slow (#365)
	task.delay(entry.untilAt - now, function()
		if slowed[player] == entry then
			slowed[player] = nil
			if humanoid.Parent then
				humanoid.WalkSpeed = bodyOf(player).walkSpeed -- back to the class base
			end
		end
	end)
end

-- Heals a living player, never past max.
function Health.heal(player: Player, amount: number)
	local humanoid = humanoidOf(player)
	if humanoid and amount > 0 then
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + amount)
	end
end

-- Every living player (round cleared).
function Health.healAll(amount: number)
	for _, player in Players:GetPlayers() do
		Health.heal(player, amount)
	end
end

return Health
