--!strict
--[[
	Raptor Pen rules (PLAN 9g T124, UPGRADES.md "Raptor Pen"). Pure, so specs run
	headlessly; Server/Towers and Server/Walkers apply them.

	  params       one raptor's Shared/Walker params from the pen's composed stats and the
	               RAPTOR PEN Tuning block (HP = Raptor HP x Walker HP x x (1 + Tower HP per
	               tier x tiers bought); the swarm's are x Swarm share)
	  swarm        Raptor Swarm: Swarm raptors small raptors for Swarm (s), anywhere on the
	               side's track (within the side's walker cap)
	  charge       Raptor Charge: every standing raptor runs the side's track from the exit
	               end back at x2 speed, biting each dino it passes once and knocking small
	               dinos back Charge knockback (studs) (never a boss)
	  guardPosts   Guard Raptors: each raptor is posted beside a tower in range, the most
	               damaged first
	  roared       Rex Tamer: the small dinos within Roar reach of the alpha
	  stack        Hungry Alpha: + Take-down stack % per take-down this round, capped
	  avenger      Raider Hounds: with no raider stung in the last 3 s, the raptors go for
	               the last dino that hurt a tower in range, bites x Avenger x
	  packBond     Pack Bond: own side's hunters in range +x % to dinos only, while 3+
	               raptors are out (#319: never to hunters or towers)
	  diveAura     towers in range attack Dive aura rate % faster while a raptor is in a fight
]]

local Config = require(script.Parent.Config)
local FourX = require(script.Parent.FourX)
local Walker = require(script.Parent.Walker)

local Raptor = {}

Raptor.AVENGER_QUIET = 3 -- s with no raider stung before Raider Hounds hunt dinos (PLAN)
Raptor.PACK_BOND_OUT = 3 -- raptors out for Pack Bond (PLAN)
Raptor.CHARGE_SPEED_X = 2 -- x a raptor's speed on a charge (PLAN)

export type Stats = {
	range: number,
	rate: number,
	walkerHpMult: number,
	walkerSpeedMult: number,
	walkerResistPercent: number,
	walkerRespawnMult: number,
	holdSeconds: number,
	bossHoldSeconds: number,
	firstDiveX: number,
	flanking: boolean,
	targetsFirst: boolean,
	hitsAir: boolean,
	dodge: boolean,
}

-- One raptor's walker params. `tiersBought`: every tier on every path (towers' HP rule);
-- `swarm`: a Raptor Swarm raptor (x Swarm share HP; it hunts the whole track).
function Raptor.params(stats: Stats, tiersBought: number, swarm: boolean?): Walker.Params
	local t = Config.Tuning
	local share = if swarm then t.SwarmShare else 1
	return {
		maxHp = Walker.maxHp(t.RaptorHP, stats.walkerHpMult, t.TowerHPPerTier, tiersBought) * share,
		speed = t.RaptorSpeed * stats.walkerSpeedMult,
		reach = t.RaptorReach,
		range = if swarm then math.huge else stats.range,
		leash = t.LeashX,
		retreatShare = if swarm then 0 else t.RetreatHPShare,
		respawn = t.RaptorRespawnS * stats.walkerRespawnMult,
		homeHeal = t.PenHealHPS,
		rate = stats.rate,
		hold = stats.holdSeconds,
		bossHold = stats.bossHoldSeconds,
		firstDiveX = stats.firstDiveX,
		flanking = stats.flanking,
		targetsFirst = stats.targetsFirst,
		hitsAir = stats.hitsAir,
		resist = stats.walkerResistPercent,
		dodge = stats.dodge,
		dodgeEvery = t.DodgeEveryS,
		trampleSize = t.TrampleSize,
		trampleShare = t.TrampleShare,
		smallSize = t.SmallSize,
	}
end

-- Raptor Swarm: how many swarm raptors may come out with `onSide` walkers already out.
function Raptor.swarmCount(onSide: number): number
	return Walker.room(Config.Tuning.SwarmRaptors, onSide, Config.Tuning.WalkerCapPerSide)
end

-- A swarm raptor's bite: x Swarm share of a raptor's.
function Raptor.swarmBite(): number
	return Config.Tuning.SwarmShare
end

-- Raptor Charge: the sweep's position after `elapsed` s, from the track's exit end
-- (`length`) back toward 0 at x2 a raptor's `speed`; nil once it has run the whole track.
function Raptor.chargeAt(length: number, speed: number, elapsed: number): number?
	local at = length - speed * Raptor.CHARGE_SPEED_X * elapsed
	return if at >= 0 then at else nil
end

-- What a charging raptor does to a dino it passes: always a bite; a knockback only on a
-- small dino (never a boss).
function Raptor.chargeKnock(size: number, boss: boolean): number
	return if FourX.isSmall(size, boss) then Config.Tuning.ChargeKnockbackStuds else 0
end

-- Guard Raptors: which tower each of `raptors` guards. `towers`: the towers in range as
-- {hp share}, any order; returns tower indices, the most damaged first, wrapping round
-- when there are more raptors than towers. Empty if there are no towers.
function Raptor.guardPosts(raptors: number, hpShares: { number }): { number }
	local order = {}
	for i in hpShares do
		table.insert(order, i)
	end
	table.sort(order, function(a, b)
		if hpShares[a] ~= hpShares[b] then
			return hpShares[a] < hpShares[b]
		end
		return a < b
	end)
	local out = {}
	if #order == 0 then
		return out
	end
	for i = 1, raptors do
		out[i] = order[(i - 1) % #order + 1]
	end
	return out
end

-- Guard Raptors: is a dino `distance` studs from the guarded tower close enough to answer?
function Raptor.guardAnswers(distance: number): boolean
	return distance <= Config.Tuning.GuardReachStuds
end

-- Rex Tamer: which of the dinos (distance from the alpha, size, boss) its roar stuns.
function Raptor.roared(distances: { number }, sizes: { number }, bosses: { boolean }): { number }
	local out = {}
	for i, d in distances do
		if d <= Config.Tuning.RoarReachStuds and FourX.isSmall(sizes[i], bosses[i]) then
			table.insert(out, i)
		end
	end
	return out
end

-- Hungry Alpha: the round's stack after `takeDowns` by its raptors.
function Raptor.stack(takeDowns: number, percent: number): number
	return math.min(Config.Tuning.HungryAlphaCap, takeDowns * percent)
end

-- Raider Hounds: the dino the raptors go for (nil = their normal pick) and the bite x.
-- `lastStung`: when this pen last stung a raider (nil = never).
function Raptor.avenger(avengerX: number, lastStung: number?, now: number, attacker: any?): (any?, number)
	if avengerX <= 0 or attacker == nil then
		return nil, 1
	end
	if lastStung and now - lastStung < Raptor.AVENGER_QUIET then
		return nil, 1
	end
	return attacker, avengerX
end

-- Pack Bond: the bonus a hunter gets against a dino (never against hunters or towers, #319).
function Raptor.packBond(percent: number, raptorsOut: number, targetIsDino: boolean): number
	if not targetIsDino or raptorsOut < Raptor.PACK_BOND_OUT then
		return 0
	end
	return percent
end

-- The pen's Dive aura while one of its raptors is in a fight.
function Raptor.diveAura(percent: number, fighting: number): number
	return if fighting > 0 then percent else 0
end

return Raptor
