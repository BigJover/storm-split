--!strict
--[[
	Amber Resin Cannon rules (PLAN 9g T123, UPGRADES.md "Amber Resin Cannon"). Pure, so
	specs run headlessly; Server/Towers applies them through Enemies.

	  entomb       each hit adds 1 resin; at resin >= max(1, ceil(Resin hits to entomb x
	               Entomb hits x x its HP-left share)) the dino is entombed for Entomb (s)
	               (a hard stop) and its resin resets: "the more HP is gone, the faster it
	               sets". Ground only. Bosses: at most once per Boss entomb every (s) per
	               boss, x Boss hard stop x (Boss entomb (s), when set, overrides: that
	               length, full)
	  spread       Entomb spread n: the n nearest other dinos within Spread reach (studs)
	  fossil       entombed at or below Fossil below % of its HP (not a boss): a fossil,
	               taken down whole
	  heart        Amber Heart: every n-th fossil this match
	  fuel         Fossil Fuel: +x % attack speed per fossil this round, capped
	  seal         Amber Shield: a tower in range that would be Trampled is left at 1 HP
	               and sealed (no damage) for Seal (s) — once a round per cannon, or with
	               Seal every (s), once per that per tower (Amber Fortress)
]]

local Config = require(script.Parent.Config)
local FourX = require(script.Parent.FourX)

local Resin = {}

-- Resin needed to entomb a dino with `hpShare` (0..1) of its HP left.
function Resin.needed(hitsMult: number, hpShare: number): number
	return math.max(1, math.ceil(Config.Tuning.ResinHitsToEntomb * hitsMult * math.clamp(hpShare, 0, 1) - 1e-9))
end

-- The dino's HP-left share: what's left of its one pool (all sizes).
function Resin.hpShare(hp: number, share: number, sizes: number): number
	local full = share * sizes
	return if full > 0 then math.clamp(hp / full, 0, 1) else 0
end

export type Dino = { resin: number, bossNextAt: number }

-- A hit lands. Returns the entomb length (0 = not entombed yet) and whether this one is a
-- boss's (for the look). `stats`: entombSeconds, entombHitsMult, bossEntombSeconds.
function Resin.hit(dino: Dino, stats: { entombSeconds: number, entombHitsMult: number, bossEntombSeconds: number }, hpShare: number, boss: boolean, flying: boolean, now: number): number
	if flying then
		return 0 -- ground only
	end
	if boss and now < dino.bossNextAt then
		return 0 -- a boss sets at most once per Boss entomb every (s)
	end
	dino.resin += 1
	if dino.resin < Resin.needed(stats.entombHitsMult, hpShare) then
		return 0
	end
	dino.resin = 0
	return Resin.entombFor(stats, boss, now, dino)
end

-- How long an entomb holds this dino (and starts a boss's cooldown).
function Resin.entombFor(stats: { entombSeconds: number, bossEntombSeconds: number }, boss: boolean, now: number, dino: Dino?): number
	if boss then
		if dino then
			dino.bossNextAt = now + Config.Tuning.BossEntombEveryS
		end
		if stats.bossEntombSeconds > 0 then
			return stats.bossEntombSeconds -- Living Amber: the full length
		end
	end
	return FourX.hardStop(stats.entombSeconds, boss)
end

-- Time Capsule: studs an entombed dino is sent back (never a boss: the knockback rule).
function Resin.sendBack(studs: number, boss: boolean): number
	return if boss then 0 else math.max(0, studs)
end

-- Sticky Bed: is a dino `distance` studs from an entombed one in its sticky bed?
function Resin.inStickyBed(distance: number): boolean
	return distance <= Config.Tuning.StickyBedReachStuds
end

-- Is an entomb at `hpShare` a fossil? Never a boss or a flyer.
function Resin.isFossil(fossilBelowPercent: number, hpShare: number, boss: boolean, flying: boolean): boolean
	return fossilBelowPercent > 0 and not boss and not flying and hpShare <= fossilBelowPercent / 100 + 1e-9
end

-- Spreading Amber: the `n` nearest of `distances` (from the entombed dino, studs) within
-- Spread reach; returns their indices, nearest first.
function Resin.spreadTo(distances: { number }, n: number): { number }
	local reach = Config.Tuning.SpreadReachStuds
	local list = {}
	for i, d in distances do
		if d <= reach then
			table.insert(list, i)
		end
	end
	table.sort(list, function(a, b)
		return distances[a] < distances[b]
	end)
	local out = {}
	for i = 1, math.min(n, #list) do
		out[i] = list[i]
	end
	return out
end

-- Amber Heart: does fossil number `count` (this match) set it off?
function Resin.heart(count: number, every: number): boolean
	return every > 0 and count > 0 and count % every == 0
end

-- Fossil Fuel: the rate aura after `fossils` this round.
function Resin.fuel(fossils: number, percent: number): number
	return math.min(Config.Tuning.FossilFuelCap, fossils * percent)
end

-- Seal: may this cannon seal a tower now? `usedThisRound` (the cannon's once-a-round seal
-- is spent), `sealEvery` (Amber Fortress: per tower), `towerSealedAt` (when that tower
-- was last sealed by a Fortress, nil = never).
function Resin.canSeal(sealSeconds: number, sealEvery: number, usedThisRound: boolean, towerSealedAt: number?, now: number): boolean
	if sealSeconds <= 0 then
		return false
	end
	if sealEvery > 0 then
		return towerSealedAt == nil or now - towerSealedAt >= sealEvery
	end
	return not usedThisRound
end

-- The HP a sealed tower gets back when its seal breaks (Self-Sealing).
function Resin.sealHeal(maxHp: number, percent: number): number
	return maxHp * percent / 100
end

-- Resin Wall: does a dino reaching the wall stop? Walls hold every dino until the wall
-- breaks after Wall (s); bosses pass after Wall (s) x Boss hard stop x.
function Resin.wallHolds(wallSeconds: number, sinceRaised: number, boss: boolean): boolean
	return sinceRaised < FourX.hardStop(wallSeconds, boss)
end

return Resin
