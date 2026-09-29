--[[
	Hazards: fire.

	Burning patches on the track (Napalm towers, Incendiary rounds, Dragon's
	Breath): a patch covers a stretch of track around a distance and damages
	ground enemies standing in it every frame until it expires.

	Ignited enemies (Dragon's Breath): the enemy burns for a moment, then takes
	one tick of fire damage — a share of the shot that lit it. The fire lives on
	the enemy (Enemies.ignite) and passes to its split children, so a Brute
	shot down to Husks sees them burn out together when the tick lands.

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

local burns: { Burn } = {}
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

-- Set one enemy on fire: after `seconds` it (or its split children) takes
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
			if not enemy.def.flying and math.abs(enemy.distance - burn.distance) <= burn.reach then
				credit(burn.owner, Enemies.damage(enemy, burn.dps * dt, burn.piercesArmor))
			end
		end
	end
end

return Hazards
