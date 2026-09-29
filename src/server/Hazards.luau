--[[
	Hazards: fire.

	Burning patches on the track (Napalm towers, Incendiary rounds, Dragon's
	Breath): a patch covers a stretch of track around a distance and damages
	ground enemies standing in it every frame until it expires.

	Ignited enemies (Dragon's Breath): the enemy itself burns for a moment, then
	takes one tick of fire damage — a share of the shot that lit it. Early on
	that's enough to take it down a level; later, against tougher layers, it's
	a small extra. Its split children don't inherit the fire; the patch on the
	ground is what catches them.

	Kills are credited to whoever lit the fire.
]]

local Effects = require(script.Parent.Effects)
local Enemies = require(script.Parent.Enemies)

local Hazards = {}

type Burn = {
	distance: number,
	reach: number,
	dps: number,
	untilTime: number,
	piercesArmor: boolean,
	owner: Player?,
}

-- Visuals only.
local BURN_COLOR = Color3.fromRGB(255, 110, 40)

type Ignited = {
	enemy: Enemies.Enemy,
	tick: number, -- damage dealt once, when the burn ends
	untilTime: number,
	piercesArmor: boolean,
	owner: Player?,
}

local burns: { Burn } = {}
local ignited: { Ignited } = {}
local onPop: ((Player) -> ())? = nil

function Hazards.init(hooks: { onPop: ((Player) -> ())? }?)
	onPop = hooks and hooks.onPop
end

-- A burning stretch of track `reach` studs either side of `distance`.
function Hazards.burn(distance: number, reach: number, dps: number, seconds: number, piercesArmor: boolean, owner: Player?)
	if dps <= 0 or seconds <= 0 then
		return
	end
	reach = math.max(reach, 1)
	table.insert(burns, {
		distance = distance,
		reach = reach,
		dps = dps,
		untilTime = os.clock() + seconds,
		piercesArmor = piercesArmor,
		owner = owner,
	})
	Effects.disc(Enemies.pointAt(distance) + Vector3.new(0, 0.45, 0), reach, BURN_COLOR, seconds, 0.5)
end

local function credit(owner: Player?, killed: boolean)
	if killed and owner and owner.Parent and onPop then
		onPop(owner)
	end
end

-- Set one enemy on fire: after `seconds` it takes `tick` damage once.
-- Re-igniting a burning enemy refreshes the fire (biggest tick wins) rather
-- than stacking it, so nine pellets on one enemy still mean one tick.
function Hazards.ignite(enemy: Enemies.Enemy, tick: number, seconds: number, piercesArmor: boolean, owner: Player?)
	if not enemy.alive or seconds <= 0 or not Enemies.canHurt(enemy, piercesArmor) then
		return
	end
	local untilTime = os.clock() + seconds
	for _, entry in ignited do
		if entry.enemy == enemy then
			entry.tick = math.max(entry.tick, tick)
			entry.untilTime = math.max(entry.untilTime, untilTime)
			return
		end
	end
	table.insert(ignited, { enemy = enemy, tick = tick, untilTime = untilTime, piercesArmor = piercesArmor, owner = owner })
	Enemies.showBurning(enemy, true)
end

local function stepIgnited(now: number)
	for i = #ignited, 1, -1 do
		local entry = ignited[i]
		local enemy = entry.enemy
		if not enemy.alive then
			table.remove(ignited, i)
		elseif now >= entry.untilTime then
			table.remove(ignited, i)
			Enemies.showBurning(enemy, false)
			credit(entry.owner, Enemies.damage(enemy, entry.tick, entry.piercesArmor))
		end
	end
end

-- Called every Heartbeat by Main.
function Hazards.step(dt: number)
	local now = os.clock()
	stepIgnited(now)
	local live = Enemies.getLive()
	for i = #burns, 1, -1 do
		local burn = burns[i]
		if now >= burn.untilTime then
			table.remove(burns, i)
			continue
		end
		for _, enemy in live do
			if not enemy.def.flying and math.abs(enemy.distance - burn.distance) <= burn.reach then
				credit(burn.owner, Enemies.damage(enemy, burn.dps * dt, burn.piercesArmor))
			end
		end
	end
end

return Hazards
