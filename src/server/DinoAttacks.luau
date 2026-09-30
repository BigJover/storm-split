--[[
	DinoAttacks: the dinos fight back (VISION.md Step 2, DECISIONS #2-#6).

	BITES: every species with a Melee damage bites the nearest target within
	its Melee reach — a standing tower or a living hunter, treated alike —
	measured sideways from the dino (Shared/Combat.pickTarget). Dinos never stop
	walking to fight. A bite deals Melee damage x size/sizes x the difficulty's
	Dino damage x (Combat.attackDamage) through Towers.damage / Health.damage,
	which apply resistance.

	Timing: each dino's bite comes round every Melee every seconds. The timer
	starts at a random point of its cooldown so a wave doesn't bite in unison,
	runs slower while the dino is sedated (by the same slow %), and is paused
	while it's stunned (knocked out) or disarmed. A ready dino with nothing in
	reach bites the moment something is.

	This module only reads enemies (Enemies.getLive and its state queries) and
	keeps its own timers keyed by enemy id; Enemies stays their only mutator.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Combat = require(Shared:WaitForChild("Combat"))

local Effects = require(script.Parent.Effects)
local Enemies = require(script.Parent.Enemies)
local Health = require(script.Parent.Health)
local Towers = require(script.Parent.Towers)

local DinoAttacks = {}

-- Visuals only.
local BITE_COLOR = Color3.fromRGB(255, 60, 60)
local BITE_FLASH = 0.15 -- seconds

local biteIn: { [number]: number } = {} -- enemy id -> seconds until its next bite
local damageMult: () -> number = function()
	return 1
end
local random = Random.new()

export type Hooks = {
	damageMult: (() -> number)?, -- the difficulty's Dino damage x
}

function DinoAttacks.init(hooks: Hooks?)
	if hooks and hooks.damageMult then
		damageMult = hooks.damageMult
	end
end

-- Everything a dino could bite right now.
local function candidates(): { Combat.Target }
	local list: { Combat.Target } = {}
	for _, tower in Towers.targets() do
		table.insert(list, { position = tower.base, standing = true, ref = tower })
	end
	-- Characters only exist during a match (Main spawns them), so a living
	-- character is a hunter in the match.
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and root:IsA("BasePart") and humanoid then
			table.insert(list, { position = root.Position, standing = humanoid.Health > 0, ref = player })
		end
	end
	return list
end

local function stillStanding(target: Combat.Target): boolean
	local ref = target.ref
	if typeof(ref) == "Instance" and ref:IsA("Player") then
		local humanoid = ref.Character and ref.Character:FindFirstChildOfClass("Humanoid")
		return humanoid ~= nil and humanoid.Health > 0
	end
	return not ref.knockedOut
end

local function bite(enemy: Enemies.Enemy, target: Combat.Target)
	local def = enemy.def
	local damage = Combat.attackDamage(def.meleeDamage, enemy.size, enemy.sizes, damageMult())
	if typeof(target.ref) == "Instance" and target.ref:IsA("Player") then
		Health.damage(target.ref, damage)
	else
		Towers.damage(target.ref, damage, enemy)
	end
	Effects.part(Vector3.new(1.6, 1.6, 1.6), CFrame.new(target.position + Vector3.new(0, 2, 0)), BITE_COLOR, BITE_FLASH, Enum.PartType.Ball)
end

-- Called every Heartbeat by Main, after Towers.step, while the match is Playing.
function DinoAttacks.step(dt: number)
	if ReplicatedStorage:GetAttribute("State") ~= "Playing" then
		return
	end
	local live = Enemies.getLive()
	local targets: { Combat.Target }? = nil -- built once, only if some dino is ready

	for id, enemy in live do
		local def = enemy.def
		local every = def.meleeEvery or 0
		if (def.meleeDamage or 0) <= 0 or every <= 0 then
			continue
		end
		local left = biteIn[id]
		if left == nil then
			left = random:NextNumber() * every -- random initial phase
		end
		if Enemies.isStunned(enemy) or Enemies.isDisarmed(enemy) then
			biteIn[id] = left -- paused
			continue
		end
		left -= dt * (1 - Enemies.slowFraction(enemy))
		if left <= 0 then
			targets = targets or candidates()
			local target = Combat.pickTarget(enemy.part.Position, targets :: { Combat.Target }, def.meleeReach)
			if target then
				bite(enemy, target)
				target.standing = stillStanding(target) -- trampled or killed: the rest look elsewhere
				left += every
			else
				left = 0 -- ready; bites as soon as something is in reach
			end
		end
		biteIn[id] = left
	end

	-- Forget dinos that are gone.
	for id in biteIn do
		if not live[id] then
			biteIn[id] = nil
		end
	end
end

-- Between matches.
function DinoAttacks.clear()
	table.clear(biteIn)
end

return DinoAttacks
