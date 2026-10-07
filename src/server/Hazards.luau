--[[
	Hazards: fire.

	Burning patches on the track (Napalm towers, Incendiary rounds, Dragon's
	Breath): a patch covers a stretch of track around a distance and damages
	ground enemies standing in it every frame until it expires.

	Ignited enemies (Dragon's Breath): the enemy burns for a moment, then takes
	one tick of fire damage — a share of the shot that lit it. The fire lives on
	the dino (Enemies.ignite) and stays lit as it shrinks, so a dino shot down
	a size still takes the tick when it lands.

	Kills are credited to whoever lit the fire.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Combat = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Combat"))

local Effects = require(script.Parent.Effects)
local Enemies = require(script.Parent.Enemies)

local Hazards = {}

type Burn = {
	side: number, -- whose track (Shared/Sides)
	distance: number,
	reach: number,
	dps: number,
	untilTime: number,
	piercesArmor: boolean,
	owner: Player?,
}

-- Visuals only.
local BURN_COLOR = Color3.fromRGB(255, 110, 40)

local burns: { Burn } = {}
-- (who gets the pop, or nil if they've left; the species key if the dino is gone, nil
-- for a shrink)
local onPop: ((Player?, string?) -> ())? = nil

function Hazards.init(hooks: { onPop: ((Player?, string?) -> ())? }?)
	onPop = hooks and hooks.onPop
end

-- A burning stretch of track `reach` studs either side of `distance`, on one side's track
-- (default 1, co-op; Shared/Sides): it burns only that track's dinos.
function Hazards.burn(distance: number, reach: number, dps: number, seconds: number, piercesArmor: boolean, owner: Player?, side: number?)
	if dps <= 0 or seconds <= 0 then
		return
	end
	reach = Combat.burnPatchReach(reach) -- readable even with no splash
	table.insert(burns, {
		side = side or 1,
		distance = distance,
		reach = reach,
		dps = dps,
		untilTime = os.clock() + seconds,
		piercesArmor = piercesArmor,
		owner = owner,
	})
	Effects.disc(Enemies.pointAt(distance, side) + Vector3.new(0, 0.45, 0), reach, BURN_COLOR, seconds, 0.5)
end

-- Burns always break 1 size (DECISIONS #127), so `dropped` is at most 1 here.
local function credit(owner: Player?, killed: boolean, gone: string?, _dropped: number?)
	if killed and onPop then
		onPop(if owner and owner.Parent then owner else nil, gone)
	end
end

-- Set one enemy on fire: after `seconds` it (at whatever size it's shrunk to) takes
-- `tick` damage once.
function Hazards.ignite(enemy: Enemies.Enemy, tick: number, seconds: number, piercesArmor: boolean, owner: Player?)
	if seconds <= 0 or tick <= 0 then
		return
	end
	Enemies.ignite(enemy, { tick = tick, untilTime = os.clock() + seconds, piercesArmor = piercesArmor, owner = owner })
end

local function stepFires(now: number, live)
	for _, enemy in live do
		local fire = enemy.fire
		if fire and now >= fire.untilTime then
			Enemies.extinguish(enemy)
			credit(fire.owner, Enemies.damage(enemy, fire.tick, fire.piercesArmor))
		end
	end
end

-- Between matches: no burning patches left over.
function Hazards.clear()
	table.clear(burns)
end

-- Called every Heartbeat by Main.
function Hazards.step(dt: number)
	local now = os.clock()
	local live = Enemies.getLive()
	stepFires(now, live)
	for i = #burns, 1, -1 do
		local burn = burns[i]
		if now >= burn.untilTime then
			table.remove(burns, i)
			continue
		end
		for _, enemy in live do
			if not enemy.def.flying and enemy.side == burn.side and math.abs(enemy.distance - burn.distance) <= burn.reach then
				credit(burn.owner, Enemies.damage(enemy, burn.dps * dt, burn.piercesArmor))
			end
		end
	end
end

return Hazards
