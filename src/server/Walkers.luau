--[[
	Walkers (PLAN 9g, DECISIONS #315): owns every walker — the NPC units a tower sends
	along its own side's track (Raptor Pen raptors; Paratroopers and rangers later). The
	rules are the pure Shared/Walker; this module keeps the units, moves their looks,
	hands each landed hit back to the owning tower (Towers applies it through Enemies,
	rule 4) and takes bites and tramples from dinos (DinoAttacks asks `biteOn`).

	Towers calls `sync` after a place / upgrade / repair / trample, `clear` when the tower
	goes, and `step` every frame. Hunters can't hit walkers and walkers never touch
	hunters (#315); walkers never leave their side's track.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Walker = require(Shared:WaitForChild("Walker"))

local Enemies = require(script.Parent.Enemies)

local Walkers = {}

-- What a tower tells Walkers about its pack (built by Towers from its composed stats).
export type Spec = {
	count: number, -- walkers this build has
	params: Walker.Params,
	side: number,
	base: Vector3, -- the tower on the build floor
	homeAt: number, -- the track point nearest it
	sending: boolean, -- false while the tower is Trampled: walkers out stay out, none leave
	healsBetweenRounds: boolean,
	look: (index: number) -> Model, -- one walker's look (visual only)
	onHit: (enemy: any, hit: Walker.Hit) -> (), -- the tower lands it (Enemies.damage etc.)
	-- Optional, per walker: its own home (Guard Raptors: a post beside another tower) and
	-- which of the side's dinos it may go for (Guard, Raider Hounds).
	homeFor: ((index: number) -> (Vector3, number))?,
	candidates: ((index: number, dinos: { Walker.Dino }) -> { Walker.Dino })?,
}

type Pack = {
	tower: any,
	spec: Spec,
	units: { Walker.Unit },
	models: { Model },
	override: number?, -- Raptor Charge: every standing walker runs with the sweep here
}

local packs: { [any]: Pack } = {}
local folder: Instance? = nil
local now = 0 -- the walkers' clock (s), advanced by step

function Walkers.init(walkerFolder: Instance)
	folder = walkerFolder
end

local function onSide(side: number): number
	local n = 0
	for _, pack in packs do
		if pack.spec.side == side then
			n += #pack.units
		end
	end
	return n
end

local function dropUnit(pack: Pack, i: number)
	local model = pack.models[i]
	if model then
		model:Destroy()
	end
	table.remove(pack.units, i)
	table.remove(pack.models, i)
end

-- Make the tower's pack match its build: more walkers (within the side's cap, Walker cap
-- per side), fewer, or new numbers for the ones out.
function Walkers.sync(tower: any, spec: Spec)
	local pack = packs[tower]
	if not pack then
		pack = { tower = tower, spec = spec, units = {}, models = {} }
		packs[tower] = pack
	end
	pack.spec = spec
	while #pack.units > spec.count do
		dropUnit(pack, #pack.units)
	end
	local add = Walker.room(spec.count - #pack.units, onSide(spec.side), Config.Tuning.WalkerCapPerSide)
	for _ = 1, add do
		local unit = Walker.new(spec.side, spec.params, spec.homeAt)
		table.insert(pack.units, unit)
		local model = spec.look(#pack.units)
		model.Parent = folder
		table.insert(pack.models, model)
	end
	for _, unit in pack.units do
		unit.hp = math.min(unit.hp, spec.params.maxHp)
	end
end

-- The tower is sold or removed: its walkers go with it.
function Walkers.clear(tower: any)
	local pack = packs[tower]
	if not pack then
		return
	end
	for i = #pack.units, 1, -1 do
		dropUnit(pack, i)
	end
	packs[tower] = nil
end

function Walkers.clearAll()
	for tower in packs do
		Walkers.clear(tower)
	end
end

-- Every walker of `tower` (for its own rules: Swarm, Charge, Guard, the 3+ out aura).
function Walkers.unitsOf(tower: any): { Walker.Unit }
	local pack = packs[tower]
	return if pack then pack.units else {}
end

-- How many of `tower`'s walkers are out on the track now.
function Walkers.outCount(tower: any): number
	local n = 0
	for _, unit in Walkers.unitsOf(tower) do
		if unit.state == "out" or unit.state == "fight" then
			n += 1
		end
	end
	return n
end

local function asDino(enemy: any, base: Vector3): Walker.Dino
	local offset = enemy.part.Position - base
	return {
		id = enemy,
		at = enemy.distance,
		side = enemy.side,
		boss = enemy.def.boss == true,
		flying = enemy.def.flying == true,
		sizesLeft = enemy.size,
		fromHome = Vector2.new(offset.X, offset.Z).Magnitude,
	}
end

local function homeOf(pack: Pack, i: number): (Vector3, number)
	if pack.spec.homeFor then
		return pack.spec.homeFor(i)
	end
	return pack.spec.base, pack.spec.homeAt
end

local function place(pack: Pack, i: number, unit: Walker.Unit)
	local model = pack.models[i]
	if not model then
		return
	end
	local visible = unit.state ~= "down"
	local base = homeOf(pack, i)
	local at = if unit.state == "home" then base + Vector3.new(1.5 * ((i % 3) - 1), 0, 2) else Enemies.pointAt(unit.at, pack.spec.side)
	local ahead = Enemies.pointAt(unit.at + 1, pack.spec.side)
	local look = if (ahead - at).Magnitude > 1e-3 then CFrame.lookAt(at, Vector3.new(ahead.X, at.Y, ahead.Z)) else CFrame.new(at)
	model:PivotTo(look + Vector3.new(0, if visible then 1.2 else -500, 0))
end

-- One frame: every walker moves, lands its hits through its tower, and dinos trample it.
function Walkers.step(dt: number)
	now += dt
	if next(packs) == nil then
		return
	end
	local live = Enemies.getLive()
	for _, pack in packs do
		local spec = pack.spec
		local enemies = {}
		for _, enemy in live do
			if enemy.alive and enemy.side == spec.side then
				table.insert(enemies, enemy)
			end
		end
		local shared = {}
		for _, enemy in enemies do
			table.insert(shared, asDino(enemy, spec.base))
		end
		for i, unit in pack.units do
			local charging = pack.override ~= nil and unit.state ~= "down"
			if charging then
				unit.at = pack.override :: number -- Raptor Charge: it runs with the sweep
				unit.state = "back"
				unit.target = nil
				place(pack, i, unit)
				continue
			end
			if unit.state == "home" and not spec.sending then
				unit.hp = math.min(spec.params.maxHp, unit.hp + spec.params.homeHeal * dt)
				place(pack, i, unit)
				continue
			end
			local base, homeAt = homeOf(pack, i)
			local dinos = shared
			if spec.homeFor then
				dinos = {}
				for _, enemy in enemies do
					table.insert(dinos, asDino(enemy, base))
				end
			end
			if spec.candidates then
				dinos = spec.candidates(i, dinos)
			end
			local claimed = {}
			if spec.params.flanking then
				for j, other in pack.units do
					if j ~= i and other.target ~= nil then
						claimed[other.target] = true
					end
				end
			end
			for _, hit in Walker.step(unit, dt, now, spec.params, homeAt, dinos, claimed) do
				local enemy = hit.target
				if enemy and enemy.alive then
					spec.onHit(enemy, hit)
				end
			end
			if Walker.exposed(unit) then
				for _, dino in shared do
					Walker.trample(unit, dino, spec.params, now)
				end
			end
			place(pack, i, unit)
		end
	end
end

-- Raptor Charge: while `at` is set every standing walker of `tower` runs with the sweep
-- there (no bites of its own; the tower bites what the sweep passes); nil ends it and they
-- run home from where the sweep left them.
function Walkers.charge(tower: any, at: number?)
	local pack = packs[tower]
	if pack then
		pack.override = at
	end
end

-- How many of `tower`'s walkers are fighting now (Dive aura).
function Walkers.fighting(tower: any): number
	local n = 0
	for _, unit in Walkers.unitsOf(tower) do
		if unit.state == "fight" then
			n += 1
		end
	end
	return n
end

-- Where `tower`'s first standing walker is (the alpha's roar), or nil.
function Walkers.firstAt(tower: any): Vector3?
	local pack = packs[tower]
	if not pack then
		return nil
	end
	for i, unit in pack.units do
		if unit.state ~= "down" then
			if unit.state == "home" then
				return (homeOf(pack, i))
			end
			return Enemies.pointAt(unit.at, pack.spec.side)
		end
	end
	return nil
end

-- A dino is about to bite: if one of its own side's walkers is on it (fighting it), the
-- walker takes the bite instead of a tower (#315). Returns true if a walker took it.
function Walkers.biteOn(enemy: any, amount: number): boolean
	for _, pack in packs do
		if pack.spec.side == enemy.side then
			for _, unit in pack.units do
				if unit.state == "fight" and unit.target == enemy then
					Walker.bitten(unit, amount, pack.spec.params, now)
					return true
				end
			end
		end
	end
	return false
end

-- Between rounds: Heals between rounds tops the pack up.
function Walkers.roundEnd()
	for _, pack in packs do
		for _, unit in pack.units do
			Walker.roundEnd(unit, pack.spec.params, pack.spec.homeAt, pack.spec.healsBetweenRounds)
		end
	end
end

-- Studio `walkers` (Shared/StudioOnly): one line per walker.
function Walkers.describe(): { string }
	local lines = {}
	for tower, pack in packs do
		for i, unit in pack.units do
			local target = unit.target
			local what = if target then `{target.key} @{math.floor(target.distance)}` else "-"
			table.insert(lines, `{tower.key}#{tower.id} walker {i}: {unit.state} HP {math.ceil(unit.hp)}/{math.floor(pack.spec.params.maxHp)} at {math.floor(unit.at)} target {what}`)
		end
	end
	if #lines == 0 then
		table.insert(lines, "no walkers")
	end
	return lines
end

return Walkers
