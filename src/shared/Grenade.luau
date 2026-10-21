--[[
	Grenade (PLAN 10b T137, DECISIONS #366-#370): the pure throw, arc, landing and splash for
	each hunter's grenade (Stink Bomb, Safari Grenade, Cherry Bomb, Dozy Cloud; numbers on
	the `Hunter Kit` sheet). Server/Kit owns the projectile and uses these; the HUD uses the
	charge count.

	  range(heroKey, trained?)     Base range x (1 + trained Throw %), the % clamped to
	                               0..Tuning Trained throw max % (#370); 0 with no hunter
	  landing(from, aimHit?, look, range)
	                               where it comes down: the point the camera ray hit, or
	                               straight ahead along the look at full range when it hit
	                               nothing (aiming at the sky); never farther than `range`
	                               along the ground from `from` (same height as `from` when
	                               clamped: the server then finds the ground under it)
	  flightTime(from, to)         ground distance / Tuning Grenade throw speed, at least
	                               MIN_FLIGHT
	  arcPoint(from, to, t)        the fixed arc at t = 0..1 (a parabola whose top is a
	                               quarter of the ground distance up, at least 2 studs; visual)
	  inSplash(centre, radius, position)   within the splash (straight-line distance)
	  charges(fullAt, now, row) / use(fullAt, now, row) / readyAt(fullAt, now, row)
	                               the charges (Charges, one back per Recharge, GunRules)
	  firstTouch(seen, who)        true the first time `who` is touched by this grenade:
	                               an enemy hunter is slowed once per grenade, blast and cloud
	                               together, so never past the #368 cap
]]

local Config = require(script.Parent.Config)
local GunRules = require(script.Parent.GunRules)
local HunterKit = require(script.Parent.HunterKit)

local Grenade = {}

Grenade.MIN_FLIGHT = 0.25 -- s: a grenade dropped at your feet still flies a moment

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

function Grenade.range(heroKey: unknown, trained: unknown?): number
	local row = HunterKit.row(heroKey)
	if not row then
		return 0
	end
	return row.baseRange * (1 + HunterKit.trained(trained, Config.Tuning.TrainedThrowMax) / 100)
end

function Grenade.landing(from: Vector3, aimHit: Vector3?, look: Vector3, range: number): Vector3
	local target = aimHit
	if not target then
		local ahead = flat(look)
		if ahead.Magnitude < 1e-3 then
			return from -- straight up with nothing hit: it comes back down on you
		end
		target = from + ahead.Unit * range
	end
	local offset = flat(target - from)
	if offset.Magnitude <= range then
		return target
	end
	return from + offset.Unit * range
end

function Grenade.flightTime(from: Vector3, to: Vector3): number
	return math.max(Grenade.MIN_FLIGHT, flat(to - from).Magnitude / Config.Tuning.GrenadeThrowSpeed)
end

function Grenade.arcPoint(from: Vector3, to: Vector3, t: number): Vector3
	local u = math.clamp(t, 0, 1)
	local top = math.max(2, flat(to - from).Magnitude * 0.25)
	return from:Lerp(to, u) + Vector3.new(0, 4 * top * u * (1 - u), 0)
end

function Grenade.inSplash(centre: Vector3, radius: number, position: Vector3): boolean
	return (position - centre).Magnitude <= radius
end

function Grenade.charges(fullAt: number, now: number, row: any): number
	return GunRules.charges(fullAt, now, row.charges, row.recharge)
end

function Grenade.use(fullAt: number, now: number, row: any): number
	return GunRules.useCharge(fullAt, now, row.recharge)
end

function Grenade.readyAt(fullAt: number, now: number, row: any): number
	return GunRules.readyAt(fullAt, now, row.charges, row.recharge)
end

function Grenade.firstTouch(seen: { [any]: boolean }, who: any): boolean
	if seen[who] then
		return false
	end
	seen[who] = true
	return true
end

return Grenade
