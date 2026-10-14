--!strict
--[[
	Walkers (PLAN 9g "The walker module", DECISIONS #315): NPC units a tower owns that run
	along its own side's track — Raptor Pen raptors (9g), Paratroopers (9h), rangers (9j).
	Pure, so specs run headlessly; Server/Walkers owns the state, damage to dinos goes
	through Enemies, bites on a walker are decided here (bitten / trample).

	A walker lives on its side's track: `at` is its distance along that track. Home is the
	track point nearest its tower (`homeAt`); at home it stands at the tower.

	  states   home  at the tower; heals Home heal HP/s; leaves when HP >= 80 % and a
	                 target is in range
	           out   runs along the track toward its target
	           fight in reach: the first contact is a POUNCE (x First dive x on the first
	                 pounce after leaving home; a hard stop of Hold (s) on a non-boss, Boss
	                 hold (s) once per boss), then a bite every 1 / rate s; it follows
	                 the target
	           back  target gone, target beyond range x leash, or HP <= retreat share:
	                 runs home at speed x 1.5
	           down  at 0 HP: gone, back at home (full HP) after its respawn time
	           post  (9j rangers) stands at a set track point, hits in range, never chases
	  targets  dinos on its side within the tower's range, ground only unless Hits air;
	           nearest to home by default; Targets first = the furthest along; Flanking =
	           no two walkers of a tower on one dino while another is free
	  bitten   a dino with a walker on it bites the walker (x (1 - Walker resist %));
	           Dodge ignores one bite per Dodge every (s)
	  trample  a walker in the path of a dino with >= Trample size sizes left (not the one
	           it fights) takes Trample share x its max HP, once per dino; Dodge: never
	           from small dinos (at most Small size sizes left)
	  cap      walkers past the side's cap aren't spawned
]]

local Walker = {}

Walker.LEAVE_SHARE = 0.8 -- HP share a walker at home needs before it runs out (PLAN)
Walker.BACK_SPEED_X = 1.5 -- runs home this much faster (PLAN)

-- One walker kind with one tower's build (the caller composes Tuning base x build columns).
export type Params = {
	maxHp: number,
	speed: number, -- studs/s along the track
	reach: number, -- studs: contact distance
	range: number, -- the tower's range (its hunting ground)
	leash: number, -- x range: a target further than this from home is let go
	retreatShare: number, -- HP share at or below which it runs home
	respawn: number, -- s down before it is back at home
	homeHeal: number, -- HP/s at home
	rate: number, -- bites (shots) a second
	hold: number, -- s a pounce holds a non-boss
	bossHold: number, -- s a pounce holds a boss, once per boss (0 = never)
	firstDiveX: number, -- x on the first pounce after leaving home
	flanking: boolean,
	targetsFirst: boolean,
	hitsAir: boolean,
	resist: number, -- Walker resist %
	dodge: boolean,
	dodgeEvery: number,
	trampleSize: number,
	trampleShare: number,
	smallSize: number, -- 4x TOWERS Small size: "small dinos" have at most this many sizes left
}

-- A dino as walkers see it. `at`: distance along its side's track; `fromHome`: flat studs
-- from the walker's tower (for range and leash).
export type Dino = {
	id: any,
	at: number,
	side: number,
	boss: boolean,
	flying: boolean,
	sizesLeft: number,
	fromHome: number,
}

export type State = "home" | "out" | "fight" | "back" | "down" | "post"

export type Unit = {
	side: number,
	state: State,
	hp: number,
	at: number,
	target: any?,
	nextBite: number,
	fresh: boolean, -- the next pounce is the first since it left home
	downUntil: number,
	heldBosses: { [any]: boolean },
	trampled: { [any]: boolean },
	lastDodge: number,
	postAt: number?,
}

-- One hit on a dino: the tower's composed damage x `x`; `hold` s of hard stop (0 = none).
export type Hit = { target: any, x: number, pounce: boolean, hold: number }

function Walker.new(side: number, params: Params, homeAt: number, postAt: number?): Unit
	return {
		side = side,
		state = if postAt then "post" else "home",
		hp = params.maxHp,
		at = postAt or homeAt,
		target = nil,
		nextBite = 0,
		fresh = true,
		downUntil = 0,
		heldBosses = {},
		trampled = {},
		lastDodge = -math.huge,
		postAt = postAt,
	}
end

-- Can this walker go after `dino` at all? Its own side only (never another camp's), in
-- the tower's range, on the ground unless Hits air.
function Walker.canTarget(unit: Unit, dino: Dino, params: Params): boolean
	return dino.side == unit.side and dino.fromHome <= params.range and (params.hitsAir or not dino.flying)
end

-- The dino this walker goes for (nil = none). `claimed[id]`: another walker of the same
-- tower is on it (Flanking).
function Walker.pick(unit: Unit, dinos: { Dino }, params: Params, claimed: { [any]: boolean }?): Dino?
	local best, bestFree = nil, nil
	local function better(a: Dino, b: Dino?): boolean
		if b == nil then
			return true
		end
		if params.targetsFirst then
			return a.at > b.at
		end
		return a.fromHome < b.fromHome
	end
	for _, dino in dinos do
		if Walker.canTarget(unit, dino, params) then
			if better(dino, best) then
				best = dino
			end
			if not (claimed and claimed[dino.id]) and better(dino, bestFree) then
				bestFree = dino
			end
		end
	end
	if params.flanking then
		return bestFree or best
	end
	return best
end

local function find(dinos: { Dino }, id: any): Dino?
	for _, dino in dinos do
		if dino.id == id then
			return dino
		end
	end
	return nil
end

local function moveToward(from: number, to: number, step: number): number
	if math.abs(to - from) <= step then
		return to
	end
	return from + (if to > from then step else -step)
end

local function pounce(unit: Unit, dino: Dino, params: Params, now: number): Hit
	local x = if unit.fresh then math.max(1, params.firstDiveX) else 1
	unit.fresh = false
	local hold = 0
	if dino.boss then
		if params.bossHold > 0 and not unit.heldBosses[dino.id] then
			unit.heldBosses[dino.id] = true
			hold = params.bossHold
		end
	else
		hold = params.hold
	end
	unit.nextBite = now + 1 / math.max(params.rate, 1e-6)
	return { target = dino.id, x = x, pounce = true, hold = hold }
end

-- Advance one walker by `dt` s to `now`. `dinos`: every live dino (any side; the walker
-- keeps to its own). Returns the hits it lands this step.
function Walker.step(unit: Unit, dt: number, now: number, params: Params, homeAt: number, dinos: { Dino }, claimed: { [any]: boolean }?): { Hit }
	local hits: { Hit } = {}
	if unit.state == "down" then
		if now >= unit.downUntil then
			unit.state = if unit.postAt then "post" else "home"
			unit.hp = params.maxHp
			unit.at = unit.postAt or homeAt
			unit.fresh = true
		end
		return hits
	end

	if unit.state == "post" then
		local target = unit.target and find(dinos, unit.target)
		if not (target and Walker.canTarget(unit, target, params)) then
			local picked = Walker.pick(unit, dinos, params, claimed)
			unit.target = picked and picked.id
			target = picked
		end
		if target and now >= unit.nextBite then
			unit.nextBite = now + 1 / math.max(params.rate, 1e-6)
			table.insert(hits, { target = target.id, x = 1, pounce = false, hold = 0 })
		end
		return hits
	end

	if unit.state == "home" then
		unit.at = homeAt
		unit.hp = math.min(params.maxHp, unit.hp + params.homeHeal * dt)
		if unit.hp >= params.maxHp * Walker.LEAVE_SHARE then
			local picked = Walker.pick(unit, dinos, params, claimed)
			if picked then
				unit.state = "out"
				unit.target = picked.id
				unit.fresh = true
			end
		end
		return hits
	end

	if (unit.state == "out" or unit.state == "fight") and unit.hp <= params.maxHp * params.retreatShare then
		unit.state = "back"
		unit.target = nil
	end

	if unit.state == "out" or unit.state == "fight" then
		local target = unit.target and find(dinos, unit.target)
		if not target or target.side ~= unit.side or target.fromHome > params.range * params.leash then
			unit.state = "back"
			unit.target = nil
		elseif unit.state == "out" then
			unit.at = moveToward(unit.at, target.at, params.speed * dt)
			if math.abs(unit.at - target.at) <= params.reach then
				unit.state = "fight"
				table.insert(hits, pounce(unit, target, params, now))
			end
		else
			unit.at = target.at -- follows it
			if now >= unit.nextBite then
				unit.nextBite = now + 1 / math.max(params.rate, 1e-6)
				table.insert(hits, { target = target.id, x = 1, pounce = false, hold = 0 })
			end
		end
	end

	if unit.state == "back" then
		unit.at = moveToward(unit.at, homeAt, params.speed * Walker.BACK_SPEED_X * dt)
		if unit.at == homeAt then
			unit.state = "home"
		end
	end
	return hits
end

-- Is the walker out on the track, where dinos can bite and trample it?
function Walker.exposed(unit: Unit): boolean
	return unit.state == "out" or unit.state == "fight" or unit.state == "back" or unit.state == "post"
end

-- At 0 HP: down until `now` + its respawn time.
function Walker.down(unit: Unit, params: Params, now: number)
	unit.state = "down"
	unit.hp = 0
	unit.target = nil
	unit.downUntil = now + params.respawn
end

-- A dino it fights bites it for `amount` (the dino's melee damage, size share and
-- difficulty already applied). Returns the HP it lost.
function Walker.bitten(unit: Unit, amount: number, params: Params, now: number): number
	if not Walker.exposed(unit) or amount <= 0 then
		return 0
	end
	if params.dodge and now - unit.lastDodge >= params.dodgeEvery then
		unit.lastDodge = now
		return 0
	end
	local dealt = math.min(unit.hp, amount * (1 - math.clamp(params.resist, 0, 100) / 100))
	unit.hp -= dealt
	if unit.hp <= 0 then
		Walker.down(unit, params, now)
	end
	return dealt
end

-- A dino walking through this walker's spot: Trample share x max HP, once per dino, from a
-- dino with at least Trample size sizes left that isn't its target. Returns the HP lost.
function Walker.trample(unit: Unit, dino: Dino, params: Params, now: number): number
	if not Walker.exposed(unit) or dino.side ~= unit.side or dino.flying or dino.id == unit.target then
		return 0
	end
	if dino.sizesLeft < params.trampleSize or unit.trampled[dino.id] or math.abs(dino.at - unit.at) > params.reach then
		return 0
	end
	if params.dodge and dino.sizesLeft <= params.smallSize then
		return 0
	end
	unit.trampled[dino.id] = true
	local dealt = math.min(unit.hp, params.maxHp * params.trampleShare)
	unit.hp -= dealt
	if unit.hp <= 0 then
		Walker.down(unit, params, now)
	end
	return dealt
end

-- Between rounds: Heals between rounds tops every walker up (down ones come back).
function Walker.roundEnd(unit: Unit, params: Params, homeAt: number, healsBetweenRounds: boolean)
	if not healsBetweenRounds then
		return
	end
	unit.hp = params.maxHp
	if unit.state == "down" then
		unit.state = if unit.postAt then "post" else "home"
		unit.at = unit.postAt or homeAt
		unit.fresh = true
	end
end

-- How many of `want` new walkers a side may spawn with `onSide` already out (Walker cap
-- per side; the rest aren't spawned).
function Walker.room(want: number, onSide: number, cap: number): number
	return math.max(0, math.min(want, cap - onSide))
end

-- Walker HP for a build: base x Walker HP x x (1 + Tower HP per tier x tiers bought), as
-- towers grow.
function Walker.maxHp(base: number, hpX: number, hpPerTier: number, tiersBought: number): number
	return base * hpX * (1 + hpPerTier * tiersBought)
end

return Walker
