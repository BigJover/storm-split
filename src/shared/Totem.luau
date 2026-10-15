--!strict
--[[
	Bone Totem rules (PLAN 9h T126, UPGRADES.md "Bone Totem"). Pure, so specs run headlessly;
	Server/Towers applies them.

	  charge     every pop (a dino losing a size) inside the totem's range on its side, made by
	             anyone on its side, adds 1 x Charge x (a hunter's pop x Hunter charge x; a boss's
	             pop Totem charge x Boss charge % / 100 instead, if set). Pops made by any Bone
	             Totem's roar, skulls or spirit hunters never charge a totem (#316: no loop).
	  full       Totem charge x Charge needed x; on full the path's effect fires and the charge
	             restarts with the overflow kept. The charge carries over between rounds and
	             starts at 0 with the match (a new totem starts empty).
	  scores     the totem only READS pops: Bones, the Bone Rush score, Ranked results and Hunt
	             Board counts never change because of it (`observe` returns charge and cash only;
	             Bounty charge x is the owner's Bounties progress, an extra report). No Amber.
	  roar       the Spirit Roar: every dino in range (Roar whole track: on its side) takes the
	             totem's damage, breaking max(Roar breaks, Size breaks), armour only if it
	             pierces; Skull Storm: instead Skulls skulls, each a different dino anywhere on the
	             side, Skull x the damage, breaking 1; Echo Roar: again 1 s later; Fear knocks
	             small dinos back (never a boss); Shatter strips armour first. A Bone Market build
	             (Full cash) never roars: a full charge pays instead (+ Payday per hunter).
	  finisher   Finishing Roar: a boss in range dropping below Finisher % of its HP gets one
	             free roar, once per boss; it uses no charge.
	  auras      Old Bones: towers in range + Charge aura damage % x the charge share; Totem Pole:
	             every tower on the side at half strength (towers in range: full).
]]

local Config = require(script.Parent.Config)
local FourX = require(script.Parent.FourX)

local Totem = {}

Totem.ECHO_DELAY = 1 -- s between a roar and its echo (PLAN)

export type Stats = {
	chargeMult: number,
	hunterChargeX: number,
	bossChargePercent: number,
	bountyChargeX: number,
	chargeNeededMult: number,
	sizeBreaks: number,
	knockback: number,
	fullCash: number,
	paydayCash: number,
	treasure: boolean,
	chargeAuraDamagePercent: number,
	sideAuraHalf: boolean,
	bankCashPerCharge: number,
}

-- Who made a pop: a tower or walker ("tower"), a hunter ("hunter"), or any Bone Totem's own
-- roar, skulls or spirit hunters ("totem": never charges a totem).
export type Source = "tower" | "hunter" | "totem"

export type State = {
	charge: number,
	fills: number, -- full charges this match
	treasureDone: boolean,
	bounty: number, -- Bounty Wall: the owner's extra take-downs not yet reported (fractions)
}

function Totem.new(): State
	return { charge = 0, fills = 0, treasureDone = false, bounty = 0 }
end

-- The charge a full totem needs.
function Totem.full(stats: Stats): number
	return Config.Tuning.TotemChargeBones * stats.chargeNeededMult
end

-- What one pop in range adds.
function Totem.popCharge(stats: Stats, source: Source, boss: boolean): number
	if source == "totem" then
		return 0 -- no loop (#316)
	end
	if boss and stats.bossChargePercent > 0 then
		return Config.Tuning.TotemChargeBones * stats.bossChargePercent / 100
	end
	return stats.chargeMult * (if source == "hunter" then math.max(1, stats.hunterChargeX) else 1)
end

-- Adds `amount` to the charge; returns how many times it filled (the overflow is kept).
function Totem.add(state: State, stats: Stats, amount: number): number
	if amount <= 0 then
		return 0
	end
	local full = Totem.full(stats)
	state.charge += amount
	local fills = 0
	while full > 0 and state.charge >= full - 1e-9 and fills < 100 do
		state.charge = math.max(0, state.charge - full)
		fills += 1
	end
	state.fills += fills
	return fills
end

-- One pop seen by a totem whose range holds it: (charge added, full charges it caused). It
-- never returns or touches a score: a pop is counted for Bones and Bounties elsewhere, the same
-- with or without a totem.
function Totem.observe(state: State, stats: Stats, source: Source, boss: boolean): (number, number)
	local amount = Totem.popCharge(stats, source, boss)
	return amount, Totem.add(state, stats, amount)
end

-- Does a full charge roar? Not on a Bone Market build: it pays instead.
function Totem.roars(stats: Stats): boolean
	return stats.fullCash <= 0
end

-- The sizes the Spirit Roar may drop on each dino (a Size breaks tier raises Roar breaks).
function Totem.roarBreaks(stats: Stats): number
	return math.max(Config.Tuning.RoarBreaks, stats.sizeBreaks)
end

-- Fear: studs a roar knocks this dino back (small dinos only, never a boss; at most Tuning
-- Fear knockback (studs)).
function Totem.knock(stats: Stats, size: number, boss: boolean): number
	if stats.knockback <= 0 or not FourX.isSmall(size, boss) then
		return 0
	end
	return math.min(stats.knockback, Config.Tuning.FearKnockbackStuds)
end

-- Bone Market / Camp Payday: what one full charge pays the side with `hunters` hunters.
function Totem.fullPay(stats: Stats, hunters: number): number
	if stats.fullCash <= 0 then
		return 0
	end
	return stats.fullCash + stats.paydayCash * math.max(0, hunters)
end

-- Ancient Treasure: the Treasure cash chest the first full charge of the match drops (0 after).
function Totem.treasure(state: State, stats: Stats): number
	if not stats.treasure or state.treasureDone then
		return 0
	end
	state.treasureDone = true
	return Config.Tuning.TreasureCash
end

-- Bone Bank: what the charge held pays at a round's end.
function Totem.bank(state: State, stats: Stats): number
	return stats.bankCashPerCharge * state.charge
end

-- The charge share (0..1) the Old Bones aura scales with.
function Totem.share(state: State, stats: Stats): number
	local full = Totem.full(stats)
	return if full > 0 then math.clamp(state.charge / full, 0, 1) else 0
end

-- An aura's strength on a tower: full in range; Totem Pole: half anywhere else on the side.
function Totem.auraAt(percent: number, inRange: boolean, sideHalf: boolean): number
	if inRange then
		return percent
	end
	return if sideHalf then percent / 2 else 0
end

-- Old Bones on a tower: Charge aura damage % x the charge share (Totem.auraAt's reach).
function Totem.chargeAura(state: State, stats: Stats, inRange: boolean): number
	return Totem.auraAt(stats.chargeAuraDamagePercent * Totem.share(state, stats), inRange, stats.sideAuraHalf)
end

-- Finishing Roar: does this boss (HP share left, 0..1) get its free roar now?
function Totem.finishes(hpShare: number, done: boolean): boolean
	return not done and hpShare < Config.Tuning.Finisher / 100
end

-- Skull Storm: which dinos the skulls hit (indices into `distances`, along the track): one each,
-- the furthest along first, at most `skulls`.
function Totem.skullTargets(distances: { number }, skulls: number): { number }
	local order = {}
	for i in distances do
		table.insert(order, i)
	end
	table.sort(order, function(a, b)
		return distances[a] > distances[b]
	end)
	local out = {}
	for i = 1, math.min(skulls, #order) do
		out[i] = order[i]
	end
	return out
end

-- Bounty Wall: a take-down in range adds Bounty charge x - 1 to the owner's Bounties; returns
-- the whole extra take-downs to report now (the fraction waits).
function Totem.bountyExtra(state: State, stats: Stats): number
	if stats.bountyChargeX <= 1 then
		return 0
	end
	state.bounty += stats.bountyChargeX - 1
	local whole = math.floor(state.bounty + 1e-9)
	state.bounty -= whole
	return whole
end

return Totem
