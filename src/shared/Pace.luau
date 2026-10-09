--[[
	Pace: how long a match is (PLAN Phase 8 batch 2 T100, DECISIONS #250-#254). Pure:
	Config in, answers out. Wiring into play is T103 (Waves/Enemies/Battle), the clock T104,
	joiners T105.

	Every played round is co-op's round, time-compressed by Tuning RoundPace (#250):
	  S = the round's enemies x spawn gap (the spawn phase; count scaling and density shrink
	      the gap by the same factor they grow the count, so S never changes)
	  W = Tuning TrackWalkSeconds / the difficulty's speed (the Rounds sheet's "+14")
	  paced length = pace x S + W; dino HP x hpX = (pace x S + W) / (S + W)
	so Required DPS (EHP / length) is unchanged. Kill cash comes from the UNPACED HP.
	Past the last row (Final Stampede) the last row's numbers apply.

	  hpX(round, difficulty)          the HP multiplier above (difficulty: { speedMult })
	  spawnGap(round)                 the row's spawn gap x pace (Waves still / count x)
	  roundLength(round, difficulty)  pace x S + W, seconds
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

function Pace.spawnGap(round: number): number
	return row(round).spawnGap * T.RoundPace
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
			local each = Config.Enemies[key].effectiveHp
			local up = promotion[key]
			if up and p > 0 then
				each = (1 - p) * each + p * Config.Enemies[up].effectiveHp
			end
			ehp += math.max(1, math.floor(n * countX + 0.5)) * each
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
