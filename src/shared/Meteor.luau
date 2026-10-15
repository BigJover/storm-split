--!strict
--[[
	Meteor Beacon (PLAN 9i T127, DECISIONS #337/#338). Pure.
	Every 1 / Fire rate s it calls a meteor on the densest bunch of dinos anywhere on its side's
	track (ground dinos; flyers too with Hits air, Shooting Stars):
	  - Densest bunch: the dino position with the most weight within Tuning Bunch radius of it
	    (a boss weighs BOSS_WEIGHT); ties go to the furthest along. Never on an empty track.
	  - After Tuning Strike warning s (a red ring) every dino within the splash takes the hit and
	    breaks the build's Size breaks (#337: every dino in the splash). Dino Killer: the biggest
	    dino hit breaks Biggest breaks + more.
	  - Meteors n: n small meteors (Small meteor x damage, Small splash x radius) on the n densest
	    points, landing over SMALL_SPREAD s; Scatter: the densest point of each of n equal track
	    segments. Meteor every: one more small meteor on its own timer. Starfall every: on that
	    timer Starfall meteors small meteors across the side replace the strike.
	  - Craters: each strike's densest-point meteor (the big one or the first small one; never a
	    Starfall wave) leaves a crater (Tuning Crater radius) for Crater (s): dinos in it burn
	    Burn DPS (Tuning Crater burn DPS when blank) x the tower level, lose armour (Glass Crater),
	    take +Crater amp % for AMP_SECONDS after crossing (Scorch Marks), miss Throw / Bite miss %
	    (Ash Cloud), are hard-stopped Crater freeze s once per crater (New Ice Age). Fire Line:
	    craters within Tuning Fire line gap along the track join into one burning strip. Cinder
	    Trail: each small meteor leaves a Tuning Streak length strip burning STREAK_SECONDS.
	  - Extinction Event (once per round played; AutoFire's rule with Tuning Extinction min bunch):
	    every dino on the side takes Extinction x the meteor (breaks 1); the densest bunch's dinos
	    break Extinction breaks. Comet Tail (Bombing run): once a round, Field strike x the meteor
	    on every dino along the side's track. Impact Winter: after each meteor every dino on the
	    side is slowed Side slow % for Side slow s (bosses too: a slow, not a hard stop).
	Own side only (BattleRules); nothing reaches another camp. The server (Towers) aims, lands and
	draws it (rule 4).
]]

local Config = require(script.Parent.Config)

local Meteor = {}

Meteor.BOSS_WEIGHT = 3 -- a boss counts this many dinos for the densest bunch (PLAN 9i)
Meteor.SMALL_SPREAD = 2 -- s the n small meteors of a strike land over
Meteor.AMP_SECONDS = 3 -- s Scorch Marks' +% lasts after a dino crosses a crater
Meteor.STREAK_SECONDS = 3 -- s a Cinder Trail strip burns
Meteor.HEIGHT = 120 -- studs above the track a meteor falls from (a look)

export type Dino = { id: any, at: number, boss: boolean?, flying: boolean?, sizes: number? }
export type Crater = { at: number, ends: number, frozen: { [any]: boolean } }

type Stats = {
	damage: number,
	rate: number,
	splashRadius: number,
	hitsAir: boolean,
	meteors: number,
	scatter: boolean,
	meteorEvery: number,
	starfallEvery: number,
	craterSeconds: number,
	burnDps: number,
	sizeBreaks: number,
	biggestBreaks: number,
}

local function counts(dino: Dino, hitsAir: boolean): boolean
	return hitsAir or dino.flying ~= true
end

-- The weight of the dinos within Bunch radius of `at`.
function Meteor.weightAt(dinos: { Dino }, at: number, hitsAir: boolean): number
	local reach, w = Config.Tuning.BunchRadiusStuds, 0
	for _, d in dinos do
		if counts(d, hitsAir) and math.abs(d.at - at) <= reach then
			w += if d.boss then Meteor.BOSS_WEIGHT else 1
		end
	end
	return w
end

-- The densest point: the dino position with the most weight around it; ties: the furthest
-- along. nil when no dino it can hit is on the track. `from`/`to` limit it to a segment.
function Meteor.densest(dinos: { Dino }, hitsAir: boolean, from: number?, to: number?): number?
	local best, bestW = nil, 0
	for _, d in dinos do
		if counts(d, hitsAir) and (from == nil or d.at >= from) and (to == nil or d.at <= to) then
			local w = Meteor.weightAt(dinos, d.at, hitsAir)
			if w > bestW or (w == bestW and best ~= nil and d.at > best) then
				best, bestW = d.at, w
			end
		end
	end
	return best
end

-- Up to n aim points. Scatter: the densest point of each of n equal segments of the track
-- (`length` studs). Else the n densest points, each the densest of the dinos not already
-- within Bunch radius of an earlier point (when fewer bunches than n, the rest repeat the first).
function Meteor.points(dinos: { Dino }, n: number, scatter: boolean, length: number, hitsAir: boolean): { number }
	local out: { number } = {}
	n = math.max(1, math.floor(n))
	if scatter then
		for i = 1, n do
			local p = Meteor.densest(dinos, hitsAir, (i - 1) * length / n, i * length / n)
			if p then
				table.insert(out, p)
			end
		end
		return out
	end
	local left = table.clone(dinos)
	local reach = Config.Tuning.BunchRadiusStuds
	for _ = 1, n do
		local p = Meteor.densest(left, hitsAir)
		if p == nil then
			break
		end
		table.insert(out, p)
		local keep = {}
		for _, d in left do
			if math.abs(d.at - p) > reach then
				table.insert(keep, d)
			end
		end
		left = keep
	end
	local first = out[1]
	while first ~= nil and #out < n do
		table.insert(out, first)
	end
	return out
end

-- The dinos a meteor landing at `at` with splash `radius` hits.
function Meteor.hits(dinos: { Dino }, at: number, radius: number, hitsAir: boolean): { Dino }
	local out = {}
	for _, d in dinos do
		if counts(d, hitsAir) and math.abs(d.at - at) <= radius then
			table.insert(out, d)
		end
	end
	return out
end

-- s the warning ring shows before a meteor lands.
function Meteor.warning(): number
	return Config.Tuning.StrikeWarningS
end

-- Cinder Trail: the strip a small meteor at `at` leaves, as (from, to) along the track.
function Meteor.streak(at: number): (number, number)
	local half = Config.Tuning.StreakLengthStuds / 2
	return at - half, at + half
end

-- What one strike is: (meteors, damage each, splash radius each). Starfall builds don't strike.
function Meteor.strike(stats: Stats): (number, number, number)
	local n = math.max(1, math.floor(stats.meteors))
	if n == 1 then
		return 1, stats.damage, stats.splashRadius
	end
	return n, stats.damage * Config.Tuning.SmallMeteorX, stats.splashRadius * Config.Tuning.SmallSplashX
end

-- A small meteor's (damage, splash) (Endless Rain, Starfall, Sky Rocks).
function Meteor.small(stats: Stats): (number, number)
	return stats.damage * Config.Tuning.SmallMeteorX, stats.splashRadius * Config.Tuning.SmallSplashX
end

-- A Starfall wave: (small meteors, damage each, splash each) on the densest points across the side.
function Meteor.starfall(stats: Stats): (number, number, number)
	local dmg, splash = Meteor.small(stats)
	return Config.Tuning.StarfallMeteors, dmg, splash
end

-- Seconds between strikes, and whether the timer is the Starfall one (it replaces the strike).
function Meteor.strikeEvery(stats: Stats): (number, boolean)
	if stats.starfallEvery > 0 then
		return stats.starfallEvery, true
	end
	return if stats.rate > 0 then 1 / stats.rate else math.huge, false
end

-- Sizes a hit dino breaks: the build's Size breaks, + Biggest breaks on the biggest one hit.
function Meteor.breaksFor(stats: Stats, isBiggest: boolean): number
	return math.max(1, stats.sizeBreaks) + (if isBiggest then stats.biggestBreaks else 0)
end

-- The biggest of the hit dinos (most sizes left; a boss first), or nil.
function Meteor.biggest(hit: { Dino }): Dino?
	local best: Dino? = nil
	for _, d in hit do
		local score = (if d.boss then 1000 else 0) + (d.sizes or 1)
		if best == nil or score > (if best.boss then 1000 else 0) + (best.sizes or 1) then
			best = d
		end
	end
	return best
end

-- A crater left at `at` now.
function Meteor.crater(stats: Stats, at: number, now: number): Crater
	return { at = at, ends = now + Meteor.craterSeconds(stats), frozen = {} }
end

-- s a crater lasts: the build's Crater (s), else Tuning Crater (s).
function Meteor.craterSeconds(stats: Stats): number
	return if stats.craterSeconds > 0 then stats.craterSeconds else Config.Tuning.CraterS
end

function Meteor.craterBurn(stats: Stats): number
	return if stats.burnDps > 0 then stats.burnDps else Config.Tuning.CraterBurnDPS
end

-- Is a dino at `at` inside a live crater (or a Fire Line strip joining two)? Returns the crater.
function Meteor.inCrater(craters: { Crater }, at: number, now: number, fireLine: boolean): Crater?
	local r = Config.Tuning.CraterRadius
	local live = {}
	for _, c in craters do
		if c.ends > now then
			table.insert(live, c)
			if math.abs(at - c.at) <= r then
				return c
			end
		end
	end
	if fireLine then
		local gap = Config.Tuning.FireLineGapStuds
		for _, a in live do
			for _, b in live do
				if a.at < b.at and b.at - a.at <= gap and at >= a.at and at <= b.at then
					return a
				end
			end
		end
	end
	return nil
end

-- New Ice Age: true the first time this dino enters this crater (then it is frozen).
function Meteor.freezeOnce(crater: Crater, dinoId: any): boolean
	if crater.frozen[dinoId] then
		return false
	end
	crater.frozen[dinoId] = true
	return true
end

-- Drop dead craters.
function Meteor.prune(craters: { Crater }, now: number): { Crater }
	local out = {}
	for _, c in craters do
		if c.ends > now then
			table.insert(out, c)
		end
	end
	return out
end

-- Extinction Event (#283 via AutoFire's rule): fire now? A boss in the bunch, or Tuning
-- Extinction min bunch dinos in it, else the round's last spawn; never on an empty track;
-- once per round played (`state` resets each round).
function Meteor.extinctionNow(state: { fired: boolean }, bossInBunch: boolean, inBunch: number, lastSpawned: boolean, onTrack: number): boolean
	if state.fired or onTrack <= 0 then
		return false
	end
	if bossInBunch or inBunch >= Config.Tuning.ExtinctionMinBunch or lastSpawned then
		state.fired = true
		return true
	end
	return false
end

-- Extinction Event's hit on one dino: (damage, breaks). The bunch's dinos break Extinction breaks.
function Meteor.extinctionHit(stats: Stats, inBunch: boolean): (number, number)
	return stats.damage * Config.Tuning.ExtinctionX, if inBunch then Config.Tuning.ExtinctionBreaks else 1
end

return Meteor
