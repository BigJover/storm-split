--[[
	Melee (PLAN 10b T136, DECISIONS #366-#370): the pure hit rule for each hunter's melee
	(Hunting Knife, Stock Swing, Brush Machete, Splint Stick; numbers on the `Hunter Kit`
	sheet). Server/Kit checks every swing with it; the client only asks.

	  reach(heroKey, trained?)     Reach (studs) x (1 + trained Reach %), the % clamped to
	                               0..Tuning Trained reach max % (#370); 0 with no hunter
	  inArc(from, look, target, reach, arc, radius?)
	                               whether `target` is in the swing: no farther than reach (to
	                               its near edge: centre distance - radius) and, seen from
	                               above, within arc / 2 of where the camera looks (straight
	                               up or down: reach only)
	  pick(from, look, points, radii?, reach, arc, most)
	                               the indices of `points` the swing hits, nearest first, at
	                               most `most` (Melee targets)
	  ready(lastSwing, now, swingTime)   a swing is allowed once Swing time has passed since
	                               the last (SLACK: up to 20 % early for network jitter, like
	                               shots); the first swing always is
	  readyAt(lastSwing, swingTime)      when the next swing is due (the HUD indicator)
]]

local Config = require(script.Parent.Config)
local HunterKit = require(script.Parent.HunterKit)

local Melee = {}

Melee.SLACK = 0.8 -- accept swings up to 20 % early (network jitter; Server/Hero's SHOT_GAP_SLACK)

function Melee.reach(heroKey: unknown, trained: unknown?): number
	local row = HunterKit.row(heroKey)
	if not row then
		return 0
	end
	return row.reach * (1 + HunterKit.trained(trained, Config.Tuning.TrainedReachMax) / 100)
end

function Melee.inArc(from: Vector3, look: Vector3, target: Vector3, reach: number, arc: number, radius: number?): boolean
	local offset = target - from
	if offset.Magnitude - math.max(0, radius or 0) > reach then
		return false
	end
	local flat = Vector3.new(offset.X, 0, offset.Z)
	local facing = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.5 or facing.Magnitude < 1e-3 or arc >= 360 then
		return true -- right underfoot, or looking straight up or down
	end
	local cos = math.clamp(flat.Unit:Dot(facing.Unit), -1, 1)
	return math.deg(math.acos(cos)) <= arc / 2 + 1e-6
end

function Melee.pick(from: Vector3, look: Vector3, points: { Vector3 }, radii: { number }?, reach: number, arc: number, most: number): { number }
	local hits = {}
	for i, point in points do
		local radius = if radii then radii[i] or 0 else 0
		if Melee.inArc(from, look, point, reach, arc, radius) then
			table.insert(hits, { index = i, distance = (point - from).Magnitude - radius })
		end
	end
	table.sort(hits, function(a, b)
		return a.distance < b.distance
	end)
	local out = {}
	for i = 1, math.min(math.max(1, math.floor(most)), #hits) do
		out[i] = hits[i].index
	end
	return out
end

function Melee.ready(lastSwing: number?, now: number, swingTime: number): boolean
	if not lastSwing then
		return true
	end
	return now - lastSwing >= swingTime * Melee.SLACK
end

function Melee.readyAt(lastSwing: number?, swingTime: number): number
	return if lastSwing then lastSwing + swingTime else 0
end

return Melee
