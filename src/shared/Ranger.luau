--!strict
--[[
	Ranger Station rules (PLAN 9j T129, UPGRADES.md "Ranger Station", DECISIONS #340). Pure,
	so specs run headlessly; Server/Towers and Server/Walkers apply them. Rangers are walkers
	on Shared/Walker's `post` state.

	  params       one ranger's Shared/Walker params from the station's composed stats and the
	               RANGER STATION Tuning block (HP = Ranger HP x Walker HP x x (1 + Tower HP
	               per tier x tiers bought), x Legend HP x for the Legend); it shoots dinos
	               within Ranger reach of its post, furthest along first, never chases
	  posts        up to Max posts track points within the station's Range; rangers share
	               them round-robin (Ranger Troop's 5 stand in formation on 3); default =
	               the nearest track points (one every Ranger reach), moved in the posts UI
	  checkPost    a post must be on the track, within Range of the cabin, not in a Tar Pit
	  squad        Heavy ranger: ranger 1 shoots x Heavy x, breaks 3; Legend: one ranger
	               (ranger 2 if ranger 1 is heavy) has x Legend x damage, x Legend HP x HP
	               and its own Tracking Dart every Legend dart s (Legend dart mark % for
	               Legend dart s on its target, the Tracker dart's mark rules)
	  jeep         Patrol Jeep: the squad rides the side's track there and back at Jeep
	               speed, shooting in reach as it passes; dinos can't bite it; posts unused
	  traps        each post's trap: the first ground dino within Trap reach, every Trap
	               every (s): slowed Trap slow % for Trap slow s, + Trap stun (hard stop) and
	               Knockback (neither on bosses); Trap line: Trap line traps one-shot traps
	               evenly along the side's track at each round played's start
	  decoy        a dino entering a ranger's reach stops Decoy s, once per dino per post
	               (a hard stop: bosses x Boss hard stop x)
	  net          the first boss within a ranger's reach is netted Boss hold s, full
	               length, once per boss
	  bitten       dinos walking past a post bite its ranger (within the dino's bite reach
	               along the track); Hold the Line: while a boss is out on the side a
	               ranger can't drop below 1 HP
	  aura         Sandbags: the station's Aura HP % on towers within Ranger guard reach of
	               a post
]]

local Config = require(script.Parent.Config)
local FourX = require(script.Parent.FourX)
local Walker = require(script.Parent.Walker)

local Ranger = {}

Ranger.HEAVY_BREAKS = 3 -- Heavy Rifle: "×3, breaks 3" (PLAN)

export type Stats = {
	range: number,
	rate: number,
	walkers: number,
	walkerHpMult: number,
	walkerSpeedMult: number,
	walkerResistPercent: number,
	walkerRespawnMult: number,
	walkerRegen: number,
	hitsAir: boolean,
	heavyRanger: boolean,
	legend: boolean,
}

-- Which ranger is the heavy one and which the Legend (0 = none).
function Ranger.roles(stats: { heavyRanger: boolean, legend: boolean }): (number, number)
	local heavy = if stats.heavyRanger then 1 else 0
	local legend = if stats.legend then (if heavy == 1 then 2 else 1) else 0
	return heavy, legend
end

-- One ranger's walker params. `tiersBought`: every tier on every path (towers' HP rule).
function Ranger.params(stats: Stats, tiersBought: number, legend: boolean?): Walker.Params
	local t = Config.Tuning
	return {
		maxHp = Walker.maxHp(t.RangerHP, stats.walkerHpMult, t.TowerHPPerTier, tiersBought) * (if legend then t.LegendHPX else 1),
		speed = t.RangerSpeed * stats.walkerSpeedMult,
		reach = t.RangerReach,
		range = t.RangerReach, -- Dino.fromHome is measured from its post (Server/Walkers)
		leash = t.RangerLeashX,
		retreatShare = t.RangerRetreatHPShare,
		respawn = t.RangerRespawnS * stats.walkerRespawnMult,
		homeHeal = t.CabinHealHPS,
		rate = stats.rate,
		hold = 0,
		bossHold = 0, -- Net Launchers is the station's own rule (Ranger.net)
		firstDiveX = 1,
		flanking = false,
		targetsFirst = true, -- furthest along first
		hitsAir = stats.hitsAir,
		resist = stats.walkerResistPercent,
		dodge = false,
		dodgeEvery = t.DodgeEveryS,
		trampleSize = t.TrampleSize,
		trampleShare = t.TrampleShare,
		smallSize = t.SmallSize,
		regen = stats.walkerRegen,
	}
end

-- Ranger `index`'s shot: (damage x, Size breaks at least) for the heavy one and the Legend.
function Ranger.shot(index: number, stats: { heavyRanger: boolean, legend: boolean }): (number, number)
	local heavy, legend = Ranger.roles(stats)
	if index == heavy then
		return Config.Tuning.HeavyX, Ranger.HEAVY_BREAKS
	elseif index == legend then
		return Config.Tuning.LegendX, 0
	end
	return 1, 0
end

-- The posts a station can have: Max posts.
function Ranger.maxPosts(): number
	return Config.Tuning.MaxPosts
end

-- Ranger `index`'s post among `posts` (round-robin) and its formation slot on it (1 = the
-- first ranger there; visual only).
function Ranger.postFor(index: number, posts: { number }): (number?, number)
	local n = #posts
	if n == 0 then
		return nil, 1
	end
	return posts[((index - 1) % n) + 1], (index - 1) // n + 1
end

-- Default posts (before the player moves them): the nearest track points within Range,
-- at least Ranger reach apart. `samples`: track points { at = distance along the track,
-- dist = flat studs from the cabin }.
function Ranger.defaultPosts(samples: { { at: number, dist: number } }, range: number): { number }
	local sorted = table.clone(samples)
	table.sort(sorted, function(a, b)
		return a.dist < b.dist
	end)
	local out: { number } = {}
	for _, s in sorted do
		if s.dist > range or #out >= Config.Tuning.MaxPosts then
			break
		end
		local free = true
		for _, at in out do
			if math.abs(at - s.at) < Config.Tuning.RangerReach then
				free = false
				break
			end
		end
		if free then
			table.insert(out, s.at)
		end
	end
	return out
end

-- A post the player asks for (posts UI): on the track, within Range, not in a Tar Pit pool.
function Ranger.checkPost(onTrack: boolean, fromCabin: number, range: number, inTarPit: boolean): (boolean, string?)
	if not onTrack then
		return false, "Posts go on the track"
	elseif fromCabin > range then
		return false, "Too far from the station"
	elseif inTarPit then
		return false, "Not in a tar pool"
	end
	return true, nil
end

-- Patrol Jeep: where along the track the jeep is at time `t` (there and back at Jeep speed).
function Ranger.jeepAt(t: number, trackLength: number): number
	if trackLength <= 0 then
		return 0
	end
	local lap = 2 * trackLength
	local d = (t * Config.Tuning.JeepSpeed) % lap
	return if d <= trackLength then d else lap - d
end

-- Traps -----------------------------------------------------------------------------------

export type TrapDino = { id: any, at: number, boss: boolean, flying: boolean }
export type TrapEffect = { slowPercent: number, slowSeconds: number, stun: number, knockback: number }

-- s between a post's traps (Trap every (s) from the build, else Tuning).
function Ranger.trapEvery(stats: { trapEvery: number }): number
	return if stats.trapEvery > 0 then stats.trapEvery else Config.Tuning.TrapEveryS
end

-- The dino a trap at `postAt` catches: the first ground dino within Trap reach (the one
-- furthest along), or nil.
function Ranger.trapPick(postAt: number, dinos: { TrapDino }): TrapDino?
	local best = nil
	for _, d in dinos do
		if not d.flying and math.abs(d.at - postAt) <= Config.Tuning.TrapReachStuds and (best == nil or d.at > best.at) then
			best = d
		end
	end
	return best
end

-- What a trap does to `dino`: Trap slow % for Trap slow s, + Trap stun and Knockback
-- (neither on bosses).
function Ranger.trapEffect(stats: { trapStunSeconds: number, knockback: number }, boss: boolean): TrapEffect
	local t = Config.Tuning
	return {
		slowPercent = t.TrapSlow,
		slowSeconds = t.TrapSlowS,
		stun = if boss then 0 else stats.trapStunSeconds,
		knockback = if boss then 0 else stats.knockback,
	}
end

-- Master Trapper: the one-shot traps' track points at a round played's start.
function Ranger.trapLine(trackLength: number): { number }
	local n = Config.Tuning.TrapLineTraps
	local out = {}
	for k = 1, n do
		table.insert(out, (k - 0.5) / n * trackLength)
	end
	return out
end

-- Decoy Calls: `seen` is the post's memory; returns the hard stop for `dino` entering a
-- ranger's reach (0 = already decoyed at this post, or no Decoy).
function Ranger.decoy(seen: { [any]: boolean }, id: any, boss: boolean, seconds: number): number
	if seconds <= 0 or seen[id] then
		return 0
	end
	seen[id] = true
	return FourX.hardStop(seconds, boss)
end

-- Net Launchers: the first boss within a ranger's reach is netted once per boss (full
-- length). `netted` is the station's memory.
function Ranger.net(netted: { [any]: boolean }, id: any, boss: boolean, seconds: number): number
	if seconds <= 0 or not boss or netted[id] then
		return 0
	end
	netted[id] = true
	return FourX.hardStop(seconds, true, true)
end

-- The Legend's Tracking Dart: (mark %, mark s) when due at `now` (next due = now + Legend
-- dart every), else nil.
function Ranger.dartDue(nextDart: number, now: number): (number?, number?, number)
	if now < nextDart then
		return nil, nil, nextDart
	end
	local t = Config.Tuning
	return t.LegendDartMark, t.LegendDartS, now + t.LegendDartEveryS
end

-- Bites ------------------------------------------------------------------------------------

-- Does a dino at `dinoAt` with bite reach `reach` bite a ranger standing at its post at
-- `unitAt`? (no trample at a post: dinos walking past bite instead)
function Ranger.bitesAtPost(unitAt: number, dinoAt: number, reach: number): boolean
	return math.abs(unitAt - dinoAt) <= reach
end

-- Hold the Line: the bite a ranger at `hp` takes, kept above 0 while a boss is out.
function Ranger.guarded(hp: number, amount: number, bossOut: boolean): number
	if bossOut then
		return math.max(0, math.min(amount, hp - 1))
	end
	return amount
end

-- Sandbags: is a tower at flat distance `fromPost` from a post inside its aura?
function Ranger.inPostAura(fromPost: number): boolean
	return fromPost <= Config.Tuning.RangerGuardReachStuds
end

return Ranger
