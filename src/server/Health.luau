--[[
	Health: the only thing that changes a player's HP (ARCHITECTURE.md §4).

	The Humanoid is the one source of truth (DECISIONS #7): MaxHealth is Tuning
	Player max health, Roblox's own regeneration is removed (the empty Health
	script in StarterCharacterScripts), and players heal only through here —
	Heal per round when a round is cleared, and later the Field Medic and the
	Field Hospital. On spawn a force field gives Spawn protection seconds of
	safety; Humanoid:TakeDamage respects it.

	damage() applies damage resistance first (Shared/Combat: the strongest
	source wins, capped). The sources (Armory aura, Second Wind) come with
	later steps and plug in through the `resistOf` hook. A hit from a dino
	tells that hunter alone what it was (the "Hurt" remote, Shared/HitNotice;
	DECISIONS #39).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Combat = require(Shared:WaitForChild("Combat"))

local Health = {}

-- Every resistance source that applies to this player right now (percents).
local resistOf: ((Player) -> { number })? = nil
local hurtEvent: RemoteEvent? = nil

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

export type Hooks = {
	resistOf: ((Player) -> { number })?,
}

function Health.init(remotes: Folder, hooks: Hooks?)
	resistOf = hooks and hooks.resistOf
	local hurt = Instance.new("RemoteEvent")
	hurt.Name = "Hurt" -- (species, attack, damage), to the hunter who was hit only
	hurt.Parent = remotes
	hurtEvent = hurt
end

-- A fresh character: full health at the Tuning max, and a short force field.
function Health.setUp(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.MaxHealth = Config.Tuning.PlayerMaxHealth
	humanoid.Health = humanoid.MaxHealth
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
