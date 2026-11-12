--!strict
--[[
	Walker art (PLAN 11d2 runtime, DECISIONS #450, tools/art/README.md "Walkers and dino
	projectiles"): dresses the walker looks (RaptorLook, RangerLook, the Patrol Jeep,
	TowerLook.buildRanger's Paratrooper) in their kind "walker" art through Shared/ArtSlot.
	Blank id / not loaded / ArtOff: nothing happens and the look builds its blocks as today.

	Visual only, like every walker: the art is anchored and ghost to physics (no collide,
	query, touch, shadow), placed about the look's Body (the art's origin), which stays the
	PrimaryPart with its Size and CFrame and is hidden. Each kind's art is authored at its
	final scale, so it is dressed at 1. Group `camp` is the camp colour (the authored blue is
	preview only); every other group keeps its authored colour.

	Lift (#450): Server/Walkers pivots every walker to track + 1.2. The art's feet sit
	1.2 x scale below the Body, so with art the Body's PivotOffset drops the pivot by
	(scale - 1) x 1.2: big kinds stand on the track and the Swarm doesn't float. No per-frame
	work: PivotTo applies it.

	Extras (#450): the Paratrooper's PARATROOPER_CHUTE canopy for a short visual descent
	(Server/Walkers lowers the model by `dropHeight` and takes the chute off on landing;
	gameplay never waits), and seats for rangers riding the Patrol Jeep's art.
]]

local ArtSlot = require(script.Parent.ArtSlot)

local WalkerArt = {}

WalkerArt.KIND = "walker"
WalkerArt.LIFT = 1.2 -- studs per unit of scale over 1 (#450)
WalkerArt.CHUTE = "PARATROOPER_CHUTE"
WalkerArt.DROP_HEIGHT = 14 -- studs the paratrooper drifts down from (visual)
WalkerArt.DROP_SECONDS = 1.5
WalkerArt.JEEP_LIFT = 0.7 -- Server/Towers pivots the jeep this far over the track

WalkerArt.RAPTOR_KEYS = table.freeze({ raptor = "RAPTOR", alpha = "RAPTOR_ALPHA", rex = "RAPTOR_REX", swarm = "RAPTOR_SWARM" })
WalkerArt.RANGER_KEYS = table.freeze({ ranger = "RANGER", heavy = "RANGER_HEAVY", legend = "RANGER_LEGEND" })

-- The jeep art's seat tops (two front buckets, three on the rear bench), in its Body's frame
-- (tools/art/models/walker/PATROL_JEEP.py).
local SEATS = table.freeze({
	Vector3.new(-0.6, 0.65, -0.05),
	Vector3.new(0.6, 0.65, -0.05),
	Vector3.new(-0.7, 0.65, 1.45),
	Vector3.new(0.7, 0.65, 1.45),
	Vector3.new(0, 0.65, 1.45),
})
local HIPS = 0.55 -- a ranger's hips below its Body centre at scale 1 (RangerLook)

local muzzles: { [Model]: BasePart } = setmetatable({} :: any, { __mode = "k" })

-- How far the art lifts a walker of this scale over today's pivot (#450).
function WalkerArt.lift(scale: number): number
	return (scale - 1) * WalkerArt.LIFT
end

local function walkerPaints(body: BasePart, camp: Color3): { [string]: Color3 }
	local paints = ArtSlot.paints(body.Color)
	paints.camp = camp
	return paints
end

-- Dress `model` (PrimaryPart = its Body, at the look's origin) in walker art `key` of this
-- scale. False: no art, nothing changed (build the blocks).
function WalkerArt.dress(model: Model, key: string, scale: number, camp: Color3): boolean
	local body = model.PrimaryPart
	if not body then
		return false
	end
	local dressed, art = ArtSlot.dress(model, WalkerArt.KIND, key, 1, body, walkerPaints(body, camp), {
		anchored = true,
		override = { camp = camp },
	})
	if not dressed then
		return false
	end
	body.Transparency = 1
	body.PivotOffset = CFrame.new(0, -WalkerArt.lift(scale), 0)
	for _, part in art do
		if part:GetAttribute("ArtRole") == "muzzle" then
			muzzles[model] = part
		end
	end
	return true
end

-- Where this walker's shot leaves from: its art `muzzle` piece centre (world), or nil (the
-- caller keeps today's origin).
function WalkerArt.muzzle(model: Model?): Vector3?
	local piece = model and muzzles[model]
	if piece and piece.Parent == model then
		return piece.CFrame.Position
	end
	return nil
end

-- The Paratrooper's canopy over `model` (its frame = the trooper's Body), if its art is
-- loaded. Pieces carry attribute Chute; the model too, while it has one.
function WalkerArt.addChute(model: Model, camp: Color3): boolean
	local body = model.PrimaryPart
	if not body then
		return false
	end
	local scratch = Instance.new("Model") -- keeps the trooper's ArtKey
	local dressed, art = ArtSlot.dress(scratch, WalkerArt.KIND, WalkerArt.CHUTE, 1, body, walkerPaints(body, camp), {
		anchored = true,
		override = { camp = camp },
	})
	if dressed then
		for _, part in art do
			part:SetAttribute("Chute", true)
			part.Parent = model
		end
		model:SetAttribute("Chute", true)
	end
	scratch:Destroy()
	return dressed
end

-- Landed: the canopy goes.
function WalkerArt.dropChute(model: Model)
	for _, child in model:GetChildren() do
		if child:GetAttribute("Chute") then
			child:Destroy()
		end
	end
	model:SetAttribute("Chute", nil)
end

-- How high over its spot a dropping paratrooper is drawn `age` seconds after it was sent
-- (a steady drift, 0 once landed).
function WalkerArt.dropHeight(age: number): number
	return WalkerArt.DROP_HEIGHT * (1 - math.clamp(age / WalkerArt.DROP_SECONDS, 0, 1))
end

-- Ranger `index` riding the jeep art: its pivot in the jeep's track frame (the track point,
-- facing ahead; Towers pivots the jeep JEEP_LIFT above it), hips on seat ((index - 1) % 5) + 1.
function WalkerArt.seat(index: number, scale: number): CFrame
	local s = SEATS[((index - 1) % #SEATS) + 1]
	return CFrame.new(s.X, WalkerArt.JEEP_LIFT + s.Y + HIPS * scale - WalkerArt.lift(scale), s.Z)
end

return WalkerArt
