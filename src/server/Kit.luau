--[[
	Kit: each hunter's melee (and grenade, T137) on the server (PLAN 10b, DECISIONS #366-#370;
	numbers on the `Hunter Kit` sheet, rules in Shared/HunterKit and Shared/Melee).

	A client only says "I swung along this camera ray". The server checks the hunter is alive,
	in the game (not a spectator, not game over), has a hunter picked and that Swing time has
	passed; then Shared/Melee picks what the swing reaches (reach to the target's near edge,
	within the arc, nearest first, at most Melee targets) among:
	  - its OWN side's dinos (BattleRules.ownDinos; co-op: every dino), not flying, and only
	    ones it can hurt (armour needs Melee pierces armour);
	  - ENEMY hunters and Studio stand-in hunters (BattleRules: never the own side).
	Each pick also needs a clear line from the hunter's head (the map blocks; dinos, towers,
	hunters and effects don't).

	A dino takes Melee damage x the hunter's level scale (like the gun, Hero.kitScale),
	breaking at most 1 size (HunterKit.BREAKS); its dino effect lands first (a slow never
	holds a boss; an amp is a mark: +% damage from everyone). A take-down is the hunter's pop.
	An enemy hunter takes that damage x PvP hunter damage (0 under Camo Cover) and at most a
	capped slow (HunterKit.hunterSlow): no stun, no knockback (#368).

	Published for the HUD (server time): MeleeReadyAt. Trained Reach (T139) is read from the
	Player attribute HunterKit.REACH_ATTRIBUTE, 0 until it is set.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Sides = require(Shared:WaitForChild("Sides"))
local BattleRules = require(Shared:WaitForChild("BattleRules"))
local HunterKit = require(Shared:WaitForChild("HunterKit"))
local Melee = require(Shared:WaitForChild("Melee"))

local Enemies = require(script.Parent.Enemies)
local Effects = require(script.Parent.Effects)
local Health = require(script.Parent.Health)
local Hero = require(script.Parent.Hero)
local StandInHunters = require(script.Parent.StandInHunters)

local Kit = {}

-- Visuals only.
local KIT_COLORS = {
	PISTOL = Color3.fromRGB(255, 90, 110),
	RIFLE = Color3.fromRGB(255, 220, 90),
	SHOTGUN = Color3.fromRGB(255, 140, 50),
	MEDIC = Color3.fromRGB(110, 230, 140),
}
local SWING_SHOW = 0.12 -- s the swing's flash shows
local HEAD_UP = 1.5 -- studs above the root part the line-of-sight check starts
local RAY_ORIGIN_SLACK = 20 -- studs beyond max camera zoom a ray may start from (Server/Hero)

local lastSwing: { [Player]: number } = {}
local kitEvent: RemoteEvent

local function now(): number
	return workspace:GetServerTimeNow()
end

local function sideOf(player: Player): number
	return Sides.playerSide(player:GetAttribute("Side"), ReplicatedStorage:GetAttribute("Sides"))
end

local function root(player: Player): BasePart?
	local character = player.Character
	local part = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if part and part:IsA("BasePart") and humanoid and humanoid.Health > 0 then
		return part
	end
	return nil
end

local function canAct(player: Player): boolean
	local state = ReplicatedStorage:GetAttribute("State")
	return state ~= "GameOver" and state ~= "Victory" and player:GetAttribute("Out") ~= true
end

local function finite(v: Vector3): boolean
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z and v.Magnitude < 1e6
end

-- A sane camera ray from this player, or nil (Server/Hero's validRay).
local function aim(player: Player, body: BasePart, origin: unknown, direction: unknown): (Vector3?, Vector3?)
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
		return nil, nil
	end
	if not finite(origin) or not finite(direction) or direction.Magnitude < 0.01 then
		return nil, nil
	end
	if (origin - body.Position).Magnitude > player.CameraMaxZoomDistance + RAY_ORIGIN_SLACK then
		return nil, nil
	end
	return origin, direction.Unit
end

-- What a kit hit's line of sight ignores: hunters, dinos, towers, walkers, effects, stand-ins.
local function sightParams(): RaycastParams
	local ignore: { Instance } = {}
	for _, other in Players:GetPlayers() do
		if other.Character then
			table.insert(ignore, other.Character)
		end
	end
	local map = workspace:FindFirstChild("StormSplitMap")
	for _, name in { "Enemies", "Towers", "Effects" } do
		local folder = map and map:FindFirstChild(name)
		if folder then
			table.insert(ignore, folder)
		end
	end
	local standIns = workspace:FindFirstChild("StandInHunters")
	if standIns then
		table.insert(ignore, standIns)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	return params
end

function Kit.clearLine(from: Vector3, to: Vector3, params: RaycastParams): boolean
	local gap = to - from
	if gap.Magnitude < 0.1 then
		return true
	end
	return workspace:Raycast(from, gap, params) == nil
end

-- A dino a kit hit may touch: own side's (the list is already filtered), on the ground,
-- hurtable (armour needs the item's pierce).
function Kit.dinoTargets(mySide: number, pierces: boolean): { any }
	local list = {}
	for _, enemy in BattleRules.ownDinos(Enemies.getLive(), mySide, "hunter") do
		if enemy.alive and not enemy.def.flying and Enemies.canHurt(enemy, pierces) then
			table.insert(list, enemy)
		end
	end
	return list
end

export type Foe = { position: Vector3, hunter: Player?, standIn: number? }

-- Enemy hunters (alive, in the game) and Studio stand-ins a kit hit may reach. Empty in co-op.
function Kit.foes(player: Player, mySide: number): { Foe }
	local foes: { Foe } = {}
	if Sides.fromAttributes(ReplicatedStorage:GetAttribute("Sides"), nil).sides <= 1 then
		return foes
	end
	for _, other in Players:GetPlayers() do
		local body = root(other)
		if other ~= player and body and other:GetAttribute("Out") ~= true and BattleRules.canDamage(mySide, sideOf(other), "hunter") then
			table.insert(foes, { position = body.Position, hunter = other })
		end
	end
	for _, dummy in StandInHunters.standing() do
		if BattleRules.canDamage(mySide, dummy.side, "hunter") then
			table.insert(foes, { position = dummy.position, standIn = dummy.side })
		end
	end
	return foes
end

-- One dino takes a kit hit: the effect first (a shrunk dino keeps it), then the damage.
-- Returns whether it popped.
function Kit.hitDino(player: Player, enemy: any, damage: number, pierces: boolean, effect: HunterKit.Effect?): boolean
	if not enemy.alive then
		return false
	end
	if effect and effect.kind == "slow" then
		Enemies.chill(enemy, {
			slowPercent = effect.percent,
			seconds = effect.seconds,
			affectsBosses = false,
			brittlePercent = 0,
			stripsArmor = false,
		})
	elseif effect and effect.kind == "amp" then
		Enemies.mark(enemy, effect.percent, effect.seconds)
	end
	Enemies.setSource("hunter")
	local killed, gone, dropped = Enemies.damage(enemy, damage, pierces, HunterKit.BREAKS)
	Enemies.setSource(nil)
	Hero.kitCredit(player, killed, gone, dropped)
	return killed
end

-- One enemy hunter or stand-in takes a kit hit (x PvP hunter damage; Camo Cover = 0), and at
-- most a capped slow. Returns whether it was downed.
function Kit.hitFoe(player: Player, mySide: number, foe: Foe, damage: number, slowPercent: number, slowSeconds: number): boolean
	if foe.standIn then
		local _, downed = StandInHunters.hit(foe.standIn, damage, mySide, player.DisplayName)
		return downed
	end
	local victim = foe.hunter
	if not victim then
		return false
	end
	local amount = HunterKit.vsHunter(damage, mySide, sideOf(victim), Health.camoCover(victim))
	if amount <= 0 then
		return false -- the own side, or Camo Cover: no damage and no slow
	end
	local _, downed = Health.pvpHit(victim, amount)
	if slowPercent > 0 and not downed then
		Health.slow(victim, slowPercent, slowSeconds)
	end
	if downed then
		Hero.kitDowned(victim, player)
	end
	return downed
end

function Kit.marker(player: Player, killed: boolean)
	kitEvent:FireClient(player, "hit", killed)
end

------------------------------------------------------------------ melee (T136)

local function swing(player: Player, rayOrigin: unknown, rayDirection: unknown)
	local body = root(player)
	local key = player:GetAttribute("Hero")
	local row = HunterKit.row(key)
	local scale = Hero.kitScale(player)
	if not body or not row or not scale or not canAct(player) then
		return
	end
	local origin, look = aim(player, body, rayOrigin, rayDirection)
	if not origin or not look then
		return
	end
	local t = now()
	if not Melee.ready(lastSwing[player], t, row.swingTime) then
		return
	end
	lastSwing[player] = t
	player:SetAttribute("MeleeReadyAt", Melee.readyAt(t, row.swingTime))

	local reach = Melee.reach(key, player:GetAttribute(HunterKit.REACH_ATTRIBUTE))
	local mySide = sideOf(player)
	local from = body.Position
	local dinos = Kit.dinoTargets(mySide, row.meleePiercesArmor)
	local foes = Kit.foes(player, mySide)
	local points, radii = {}, {}
	for _, enemy in dinos do
		table.insert(points, enemy.part.Position)
		table.insert(radii, math.max(enemy.part.Size.X, enemy.part.Size.Z) / 2)
	end
	for _, foe in foes do
		table.insert(points, foe.position)
		table.insert(radii, 1)
	end
	local flat = Vector3.new(look.X, 0, look.Z)
	local facing = if flat.Magnitude > 1e-3 then flat.Unit else body.CFrame.LookVector
	Effects.part(
		Vector3.new(math.min(2 * reach * math.sin(math.rad(math.min(row.arc, 180) / 2)), 2 * reach), 0.15, 0.4),
		CFrame.lookAt(from + facing * reach * 0.6, from + facing * reach * 2),
		KIT_COLORS[key :: string] or Color3.new(1, 1, 1),
		SWING_SHOW
	).Transparency = 0.4

	local damage = row.meleeDamage * scale
	local effect = HunterKit.dinoEffect(row.meleeEffect, row.meleeEffectPercent, row.meleeEffectSeconds)
	local slowPercent, slowSeconds = HunterKit.hunterSlow(row.meleeHunterEffect, row.meleeHunterPercent, row.meleeHunterSeconds)
	local params = sightParams()
	local head = from + Vector3.new(0, HEAD_UP, 0)
	local hit, killed = false, false
	for _, index in Melee.pick(from, look, points, radii, reach, row.arc, row.meleeTargets) do
		if Kit.clearLine(head, points[index], params) then
			hit = true
			if index <= #dinos then
				killed = Kit.hitDino(player, dinos[index], damage, row.meleePiercesArmor, effect) or killed
			else
				killed = Kit.hitFoe(player, mySide, foes[index - #dinos], damage, slowPercent, slowSeconds) or killed
			end
		end
	end
	if hit then
		Kit.marker(player, killed)
	end
end

------------------------------------------------------------------ lifecycle

-- Between matches: every swing ready again.
function Kit.resetMatch()
	table.clear(lastSwing)
	for _, player in Players:GetPlayers() do
		player:SetAttribute("MeleeReadyAt", 0)
	end
end

function Kit.init(remotes: Folder)
	-- Client -> server: ("melee", rayOrigin, rayDirection). Server -> client: ("hit", killed).
	kitEvent = Instance.new("RemoteEvent")
	kitEvent.Name = "HeroKit"
	kitEvent.OnServerEvent:Connect(function(player, action, origin, direction)
		local ok, err = pcall(function()
			if action == "melee" then
				swing(player, origin, direction)
			end
		end)
		if not ok then
			warn(`[Kit] {tostring(action)} from {player.Name} failed: {err}`)
		end
	end)
	kitEvent.Parent = remotes
	Players.PlayerRemoving:Connect(function(player)
		lastSwing[player] = nil
	end)
end

return Kit
