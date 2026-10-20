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
local Ranger = require(Shared:WaitForChild("Ranger"))

local Enemies = require(script.Parent.Enemies)

local Walkers = {}

-- What a tower tells Walkers about its pack (built by Towers from its composed stats).
export type Spec = {
	count: number, -- walkers this build has
	want: number?, -- what the tower panel says it bought when `count` is already capped (the Swarm)
	params: Walker.Params,
	side: number,
	base: Vector3, -- the tower on the build floor
	homeAt: number, -- the track point nearest it
	sending: boolean, -- false while the tower is Trampled: walkers out stay out, none leave
	healsBetweenRounds: boolean,
	look: (index: number) -> Model, -- one walker's look (visual only)
	onHit: (enemy: any, hit: Walker.Hit, index: number) -> (), -- the tower lands it (Enemies.damage etc.)
	-- Optional, per walker: its own home (Guard Raptors: a post beside another tower) and
	-- which of the side's dinos it may go for (Guard, Raider Hounds).
	homeFor: ((index: number) -> (Vector3, number))?,
	candidates: ((index: number, dinos: { Walker.Dino }) -> { Walker.Dino })?,
	-- Rangers (PLAN 9j): each walker's post (track distance; Shared/Walker's post state), its
	-- own params (the Legend), a hook on a bite it takes (Hold the Line) and a sideways
	-- formation offset at its post (visual).
	postFor: ((index: number) -> number?)?,
	paramsFor: ((index: number) -> Walker.Params)?,
	biteHook: ((unit: Walker.Unit, amount: number) -> number)?,
	offsetFor: ((index: number) -> number)?,
}

type Pack = {
	tower: any,
	spec: Spec,
	units: { Walker.Unit },
	models: { Model },
	override: number?, -- Raptor Charge: every standing walker runs with the sweep here
	ride: number?, -- Patrol Jeep (PLAN 9j): every standing walker rides the jeep here
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

-- This side's walker cap now (Shared/Walker.sideCap, #354): the server's total split over the
-- match's sides (MapBuilder's "Sides").
function Walkers.cap(): number
	local sides = ReplicatedStorage:GetAttribute("Sides")
	return Walker.sideCap(Config.Tuning.WalkerCapPerSide, Config.Tuning.WalkerCapTotal, if typeof(sides) == "number" then sides else 1)
end

local function paramsOf(pack: Pack, i: number): Walker.Params
	return if pack.spec.paramsFor then pack.spec.paramsFor(i) else pack.spec.params
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
	local add = Walker.room(spec.count - #pack.units, onSide(spec.side), Walkers.cap())
	for _ = 1, add do
		local index = #pack.units + 1
		local unit = Walker.new(spec.side, paramsOf(pack, index), spec.homeAt, if spec.postFor then spec.postFor(index) else nil)
		table.insert(pack.units, unit)
		local model = spec.look(index)
		model.Parent = folder
		table.insert(pack.models, model)
	end
	for i, unit in pack.units do
		unit.hp = math.min(unit.hp, paramsOf(pack, i).maxHp)
		local post = if spec.postFor then spec.postFor(i) else nil
		if post and post ~= unit.postAt then
			Walker.setPost(unit, post) -- a moved post (posts UI) or a new guard spot: it walks there
		end
	end
end

-- The tower panel's short-pack line (#359): walkers out and bought over `keys` (a tower and
-- its Swarm), and the side's cap, on the tower's body (Shop.client reads them).
function Walkers.showCap(body: Instance?, keys: { any })
	if not body then
		return
	end
	local out, want = 0, 0
	for _, key in keys do
		local pack = packs[key]
		if pack then
			out += #pack.units
			want += pack.spec.want or pack.spec.count
		end
	end
	body:SetAttribute("WalkersOut", out)
	body:SetAttribute("WalkersWant", want)
	body:SetAttribute("WalkerCap", Walkers.cap())
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
	if unit.state == "post" and pack.spec.offsetFor then -- formation at a shared post (visual)
		local dir = (ahead - at) * Vector3.new(1, 0, 1)
		if dir.Magnitude > 1e-3 then
			dir = dir.Unit
			at += Vector3.new(-dir.Z, 0, dir.X) * pack.spec.offsetFor(i)
			ahead = at + dir
		end
	end
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
			local params = paramsOf(pack, i)
			if pack.ride ~= nil and unit.state ~= "down" then
				unit.postAt = pack.ride -- Patrol Jeep: it rides, shooting from the jeep (PLAN 9j)
				unit.at = pack.ride :: number
				unit.state = "post"
			end
			if unit.state == "home" and not spec.sending then
				unit.hp = math.min(params.maxHp, unit.hp + params.homeHeal * dt)
				place(pack, i, unit)
				continue
			end
			local base, homeAt = homeOf(pack, i)
			local dinos = shared
			if unit.postAt then
				-- A ranger shoots what is within its reach of its post (PLAN 9j).
				local post = Enemies.pointAt(unit.postAt :: number, spec.side)
				dinos = {}
				for _, enemy in enemies do
					table.insert(dinos, asDino(enemy, post))
				end
			elseif spec.homeFor then
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
			for _, hit in Walker.step(unit, dt, now, params, homeAt, dinos, claimed) do
				local enemy = hit.target
				if enemy and enemy.alive then
					spec.onHit(enemy, hit, i)
				end
			end
			if Walker.exposed(unit) then
				for _, dino in shared do
					Walker.trample(unit, dino, params, now)
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

-- Patrol Jeep (PLAN 9j): while `at` is set every standing walker of `tower` rides the jeep
-- there, shooting in reach (dinos can't bite it); nil ends it and they walk to their posts.
function Walkers.ride(tower: any, at: number?)
	local pack = packs[tower]
	if not pack then
		return
	end
	if at == nil and pack.ride ~= nil then
		for i, unit in pack.units do
			if unit.state ~= "down" then
				unit.state = "out"
				unit.postAt = if pack.spec.postFor then pack.spec.postFor(i) else unit.postAt
			end
		end
	end
	pack.ride = at
end

-- Where `tower`'s walker `index` stands now (nil when down), and its unit.
function Walkers.unitAt(tower: any, index: number): (Vector3?, Walker.Unit?)
	local pack = packs[tower]
	local unit = pack and pack.units[index]
	if not pack or not unit or unit.state == "down" then
		return nil, unit
	end
	if unit.state == "home" then
		return (homeOf(pack, index)), unit
	end
	return Enemies.pointAt(unit.at, pack.spec.side), unit
end

-- Bodyguards (PLAN 9j): `tower`'s walker `index`, standing at its post, takes a bite aimed
-- at the tower it guards. Returns true if it took it.
function Walkers.biteUnit(tower: any, index: number, amount: number): boolean
	local pack = packs[tower]
	local unit = pack and pack.units[index]
	if not pack or not unit or unit.state ~= "post" or pack.ride ~= nil then
		return false
	end
	local hook = pack.spec.biteHook
	Walker.bitten(unit, if hook then hook(unit, amount) else amount, paramsOf(pack, index), now)
	return true
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
function Walkers.biteOn(enemy: any, amount: number, reach: number?): boolean
	for _, pack in packs do
		if pack.spec.side == enemy.side then
			for i, unit in pack.units do
				if unit.state == "fight" and unit.target == enemy then
					Walker.bitten(unit, amount, paramsOf(pack, i), now)
					return true
				end
			end
		end
	end
	-- A ranger at its post (PLAN 9j): a ground dino walking past bites it (no trample at a
	-- post); never a riding jeep's.
	if enemy.def.flying then
		return false
	end
	for _, pack in packs do
		if pack.spec.side == enemy.side and pack.ride == nil then
			for i, unit in pack.units do
				if unit.state == "post" and Ranger.bitesAtPost(unit.at, enemy.distance, reach or 0) then
					local hook = pack.spec.biteHook
					Walker.bitten(unit, if hook then hook(unit, amount) else amount, paramsOf(pack, i), now)
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
		for i, unit in pack.units do
			Walker.roundEnd(unit, paramsOf(pack, i), pack.spec.homeAt, pack.spec.healsBetweenRounds)
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
			local post = if unit.postAt then ` post {math.floor(unit.postAt)}` else ""
			table.insert(lines, `{tower.key}#{tower.id} walker {i}: {unit.state} HP {math.ceil(unit.hp)}/{math.floor(paramsOf(pack, i).maxHp)} at {math.floor(unit.at)}{post} target {what}`)
		end
	end
	if #lines == 0 then
		table.insert(lines, "no walkers")
	end
	return lines
end

return Walkers
