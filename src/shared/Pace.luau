--[[
	Pace: how long a match is (PLAN Phase 8 batch 2 T100, DECISIONS #250-#254). Pure:
	Config in, answers out. Wiring into play is T103 (Waves/Enemies/Battle), the clock T104,
	joiners T105.

	Every played round is co-op's round, time-compressed by Tuning RoundPace (#250; in play
	since #258 by fewer, tougher dinos: plan() below):
	  S = the round's enemies x spawn gap (the spawn phase; count scaling and density shrink
	      the gap by the same factor they grow the count, so S never changes)
	  W = Tuning TrackWalkSeconds / the difficulty's speed (the Rounds sheet's "+14")
	  paced length = pace x S + W; dino HP x hpX = (pace x S + W) / (S + W)
	so Required DPS (EHP / length) is unchanged. Kill cash comes from the UNPACED HP.
	Past the last row (Final Stampede) the last row's numbers apply.

	  hpX(round, difficulty)          the HP multiplier above (difficulty: { speedMult })
	  roundLength(round, difficulty)  pace x S + W, seconds (the model length; in play the spawn
	                                  gap is unchanged and the counts shrink, #258)
	  playedRounds(modeKey, competitive)
	      co-op: 1 .. last. Battles (#251): every step-th round ending at the last, step =
	      Tuning CasualRoundStep / RankedRoundStep, first = last - step x floor((last - 1) / step)
	  isPlayed(round, modeKey, competitive)
	  expectedIncome(round, hunters, difficulty, density?)
	      one side's expected cash for a round, the maths of tools/value.py's income: kill cash
	      on the unpaced effective HP of every dino it spawns (count x and HP x from the side's
	      hunters, as BattleFlow.sideScale; promotions at their expected EHP; x density, the
	      Shared/Sides count multiplier) + the round bonus, all x the difficulty's cash x
	  skippedIncome(fromRound, toRound, hunters, difficulty, density?)
	      the sum of expectedIncome over fromRound..toRound (0 when from > to): what a battle
	      side is paid at a played round's start for the rounds skipped before it (#251)
	  catchUpCash(roundReached, hunters, difficulty, density?)
	      a late joiner's cash (#254): Tuning LateJoinCashX x the expected income ONE more
	      hunter would have added over rounds 1 .. roundReached - 1, i.e. income with
	      hunters + 1 minus income with `hunters` (the side's hunters before the join; 0 =
	      a new camp of its own, which adds its whole income); never below Tuning
	      StartingCashPerExtraPlayer (co-op's old flat amount)
	  crowd(modeKey)                  #258: Tuning BattleCrowdX in a battle, 1 in co-op
  plan(round, countMult, promoteChance, difficulty, crowd?)
      #258, how a round is paced in play: fewer, tougher dinos (spawn gaps unchanged).
      counts: species -> spawns. Unpaced = max(1, round half up(n x countMult)) (Server/Waves'
      old count; countMult = difficulty x hunters x density); paced = max(1, round half
      up(n x countMult x Round pace x crowd)), bosses keep the unpaced count. ratio = unpaced
      round EHP / paced round EHP (expected EHP per spawn, promotions included) and
        hpX    = hpX(round) x ratio  each dino's extra HP x: the round's EHP = unpaced x hpX(round)
        cashX  = 1 / hpX(round)      kill cash per HP x: kill cash per dino = unpaced HP x ratio,
                                      so the round's cash is unchanged
        leakX  = ratio               Fence a leak costs x (species EHP x ratio): a round's Fence
                                      at stake is unchanged (fewer dinos, each costs more)
  nextRound(round, modeKey, competitive)
      the played round after `round` (#251); past the last row, round + 1 (Final Stampede)
  firstRound(modeKey, competitive, wanted?)
      the first played round at or after `wanted` (default 1): Studio "Start at round N" snaps
      to the next played round; the last row at most
  skippedBefore(round, modeKey, competitive)
      (from, to): the rounds skipped right before played round `round` (from > to when none),
      whose skippedIncome the side gets as the round starts; none past the last row
  abilityCooldown(seconds)        #259: a hero ability's cooldown / Tuning AbilityTempo (on top
                                  of the mastery cut; Triage Kit included). Tower timers aren't
  healRate(perSecond)             #259: a Field Hospital's heal rate x AbilityTempo (its revive,
                                  heal rate x revive speed, follows)
  matchCap(modeKey, competitive)  seconds from Building: Tuning CasualMatchCap or
	                                  RankedMatchCap; nil in co-op (no clock, #252)
	  clockWarning(elapsed, cap?)     true in the last Tuning ClockWarning seconds before the
	                                  cap (not at or after it); false with no cap
]]

local Config = require(script.Parent.Config)

export type PaceDifficulty = { speedMult: number }
export type IncomeDifficulty = { countMult: number, hpMult: number, promoteChance: number, cashMult: number }

local Pace = {}

local T = Config.Tuning
local LAST = #Config.Rounds

-- Server/Waves' promotion: each ground, non-boss species promotes to the next one in EnemyOrder.
local promotion: { [string]: string } = {}
do
	local previous: string? = nil
	for _, key in Config.EnemyOrder do
		local def = Config.Enemies[key]
		if def and not def.flying and not def.boss then
			if previous then
				promotion[previous] = key
			end
			previous = key
		end
	end
end

local function row(round: number)
	return Config.Rounds[math.clamp(round, 1, LAST)]
end

-- (S, W) of a round.
local function parts(round: number, difficulty: PaceDifficulty): (number, number)
	local rd = row(round)
	local enemies = 0
	for _, n in rd.counts do
		enemies += n
	end
	return enemies * rd.spawnGap, T.TrackWalkSeconds / difficulty.speedMult
end

function Pace.roundLength(round: number, difficulty: PaceDifficulty): number
	local s, w = parts(round, difficulty)
	return T.RoundPace * s + w
end

function Pace.hpX(round: number, difficulty: PaceDifficulty): number
	local s, w = parts(round, difficulty)
	if s + w <= 0 then
		return 1
	end
	return (T.RoundPace * s + w) / (s + w)
end

local function step(modeKey: string, competitive: boolean?): number?
	if modeKey == "COOP" then
		return nil
	end
	return if competitive then T.RankedRoundStep else T.CasualRoundStep
end

function Pace.playedRounds(modeKey: string, competitive: boolean?): { number }
	local list = {}
	local by = step(modeKey, competitive) or 1
	for round = LAST - by * math.floor((LAST - 1) / by), LAST, by do
		table.insert(list, round)
	end
	return list
end

function Pace.isPlayed(round: number, modeKey: string, competitive: boolean?): boolean
	local by = step(modeKey, competitive) or 1
	return round >= 1 and round <= LAST and round % 1 == 0 and (LAST - round) % by == 0
end

-- One spawn of `key`'s expected effective HP (promotions at their chance).
local function expectedEhp(key: string, promoteChance: number): number
	local each = Config.Enemies[key].effectiveHp
	local up = promotion[key]
	if up and promoteChance > 0 then
		each = (1 - promoteChance) * each + promoteChance * Config.Enemies[up].effectiveHp
	end
	return each
end

function Pace.crowd(modeKey: string): number
	return if modeKey == "COOP" then 1 else T.BattleCrowdX
end

export type Plan = { counts: { [string]: number }, hpX: number, cashX: number, leakX: number }

function Pace.plan(round: number, countMult: number, promoteChance: number, difficulty: PaceDifficulty, crowd: number?): Plan
	local rd = row(round)
	local counts = {}
	local unpaced, paced = 0, 0
	for key, n in rd.counts do
		if n > 0 then
			local before = math.max(1, math.floor(n * countMult + 0.5))
			local after = if Config.Enemies[key].boss
				then before
				else math.max(1, math.floor(n * countMult * T.RoundPace * (crowd or 1) + 0.5))
			counts[key] = after
			local each = expectedEhp(key, promoteChance)
			unpaced += before * each
			paced += after * each
		end
	end
	local ratio = if paced > 0 then unpaced / paced else 1
	local x = Pace.hpX(round, difficulty)
	return { counts = counts, hpX = x * ratio, cashX = 1 / x, leakX = ratio }
end

function Pace.nextRound(round: number, modeKey: string, competitive: boolean?): number
	if round >= LAST then
		return round + 1
	end
	local by = step(modeKey, competitive) or 1
	local nextUp = round + 1
	while (LAST - nextUp) % by ~= 0 do
		nextUp += 1
	end
	return nextUp
end

function Pace.firstRound(modeKey: string, competitive: boolean?, wanted: number?): number
	local at = math.clamp(math.floor(wanted or 1), 1, LAST)
	return if Pace.isPlayed(at, modeKey, competitive) then at else Pace.nextRound(at, modeKey, competitive)
end

function Pace.skippedBefore(round: number, modeKey: string, competitive: boolean?): (number, number)
	if round > LAST or round < 1 then
		return 1, 0
	end
	local by = step(modeKey, competitive) or 1
	return math.max(1, round - by + 1), round - 1
end

function Pace.expectedIncome(round: number, hunters: number, difficulty: IncomeDifficulty, density: number?): number
	if round < 1 or round > LAST then
		return 0
	end
	local rd = Config.Rounds[round]
	local extra = math.max(0, hunters - 1)
	local countX = difficulty.countMult * (1 + T.ExtraEnemiesPerPlayer * extra) * (density or 1)
	local hpX = difficulty.hpMult * (1 + T.ExtraHPPerPlayer * extra)
	local p = difficulty.promoteChance
	local ehp = 0
	for key, n in rd.counts do
		if n > 0 then
			ehp += math.max(1, math.floor(n * countX + 0.5)) * expectedEhp(key, p)
		end
	end
	local kill = ehp * rd.hpMult * hpX * T.CashPerEffectiveHP
	return (kill + T.RoundBonusBase + T.RoundBonusPerRound * round) * difficulty.cashMult
end

function Pace.skippedIncome(fromRound: number, toRound: number, hunters: number, difficulty: IncomeDifficulty, density: number?): number
	local total = 0
	for round = math.max(1, fromRound), math.min(LAST, toRound) do
		total += Pace.expectedIncome(round, hunters, difficulty, density)
	end
	return total
end

function Pace.catchUpCash(roundReached: number, hunters: number, difficulty: IncomeDifficulty, density: number?): number
	local before = roundReached - 1
	local with = Pace.skippedIncome(1, before, hunters + 1, difficulty, density)
	local without = if hunters >= 1 then Pace.skippedIncome(1, before, hunters, difficulty, density) else 0
	return math.max(T.StartingCashPerExtraPlayer, T.LateJoinCashX * (with - without))
end

function Pace.abilityCooldown(seconds: number): number
	return seconds / T.AbilityTempo
end

function Pace.healRate(perSecond: number): number
	return perSecond * T.AbilityTempo
end

function Pace.matchCap(modeKey: string, competitive: boolean?): number?
	if modeKey == "COOP" then
		return nil
	end
	return if competitive then T.RankedMatchCap else T.CasualMatchCap
end

function Pace.clockWarning(elapsed: number, cap: number?): boolean
	if not cap then
		return false
	end
	return elapsed >= cap - T.ClockWarning and elapsed < cap
end

return table.freeze(Pace)
