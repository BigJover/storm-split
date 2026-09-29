--[[
	Hazards: burning patches on the track (Napalm towers, Incendiary rounds,
	Dragon's Breath). A patch covers a stretch of track around a distance and
	damages ground enemies standing in it every frame until it expires. Kills
	are credited to whoever made the patch.
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

-- Called every Heartbeat by Main.
function Hazards.step(dt: number)
	local now = os.clock()
	local live = Enemies.getLive()
	for i = #burns, 1, -1 do
		local burn = burns[i]
		if now >= burn.untilTime then
			table.remove(burns, i)
			continue
		end
		for _, enemy in live do
			if not enemy.def.flying and math.abs(enemy.distance - burn.distance) <= burn.reach then
				local killed = Enemies.damage(enemy, burn.dps * dt, burn.piercesArmor)
				if killed and burn.owner and burn.owner.Parent and onPop then
					onPop(burn.owner)
				end
			end
		end
	end
end

return Hazards
