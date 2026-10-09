--[[
	The battle modes' rules (PLAN phase 7 T71, DECISIONS #210-#214). Pure: Config in,
	answers out, so the server (T77/T78) only calls them and specs run headlessly.
	Co-op is one side, so none of this changes it.

	A side is a number (1, 2, ...). Target kinds: "hunter", "tower", "dino". Attacker
	kinds (every damage or effect source, PLAN T78, DECISIONS #228, #231):
	  "hunter"   a hero shot (pellets, pierce, ricochet, splash, muzzle rounds)
	  "tower"    every tower effect: shots, splash, bomblets, Storm Coil chains and bolts,
	             Power Grid, Falcon dives and pecks, Ballista bolts and chains, Chiller slow
	             and Freeze, marks, Thorn Plating and Bulwark
	  "hazard"   burning ground, fires on a dino, Tar Pit pools (slow, burn, sink, Eruption)
	  "ability"  hunter abilities: Flare Strike (strike, stun, burn), Tracking Dart
	  "dino"     bites and throws

	  canDamage(attackerSide, targetSide, targetKind, opts?)
	      whether a hit or effect may land. No friendly fire, ever: a hunter never hurts
	      their own side's hunters or towers. Dinos are only ever touched by their own
	      side: a hunter, tower, hazard or ability never reaches another side's dinos (no
	      Bone-stealing, no propping up a rival, no crowd control by the back door).
	      Towers, hazards and abilities touch dinos only (never hunters, never towers). A
	      hunter's shot reaches enemy hunters and enemy towers. A tower that can't be
	      damaged (def.untouchable: Falcon Roost, Tar Pit) is immune to everyone. Dinos
	      bite any hunter or tower in reach, invaders included. A spectator (side out)
	      deals no damage. opts = { attacker: Kind? (default "hunter"), tower: def? (the
	      target tower's Config def), attackerOut: boolean? }.
	  ownDinos(live, side, attacker)
	      the dinos in `live` this attacker kind on `side` may touch (a targeting filter:
	      towers never even aim across the strip)
	  pvpDamage(amount, attackerSide, targetSide, targetKind, opts?)
	      what a hit does: 0 where canDamage says no or the target hunter is shielded
	      (opts.shielded: Camo Cover, Tuning SpawnShield); else, for a hunter's shot (the
	      PvP levers are for shots only; other allowed sources pass through) an enemy tower takes
	      amount x PvPTowerDamage, an enemy hunter amount x PvPHunterDamage (0 = hunter
	      vs hunter off, #228), a dino the full amount
	  shielded(sinceSpawn)        Camo Cover: a hunter takes no PvP damage for Tuning SpawnShield
                              seconds after (re)spawning (#212)
  canSupport(sourceSide, targetSide)
      whether a helpful effect reaches a target: only its own side's (a chest or med kit
      picked up, a heal, an aura, Rally Cry). Co-op: always (one side). (T77, #212, #231)
  nextRoundDue(sidesCleared, elapsed)
	      lockstep: round N+1 starts for every live side once each has cleared round N
	      (`sidesCleared`: live side -> cleared?) or Tuning BattleRoundTime seconds after
	      round N started, whichever comes first
	  sideOut(fence)              a side is out at Fence 0
	  overtimeRepeat(round)       0 up to the last round of the table; then 1, 2, ...
	  overtimeHpMult(n)           Tuning OvertimeHPStep ^ n (1 when n <= 0)
	  teamResult(eliminationOrder, bones, stats?)
	      `bones` has every side (side -> Bones, 0 if none); `eliminationOrder` lists the
	      falls in order, each a list of the sides that fell in that same step. Not over
	      while two or more sides stand. One standing = it wins. None standing = the sides
	      of the last step fell together and the tie-break chain (#253) picks one. `stats`
	      = { fence, damage, clearTime (side -> number), seed (matchId) }, missing = 0.
	      Returns { over, winners (always one when over), losers (sorted), tie (always
	      false), ranking (every side, 1st first), decidedBy }.
	  royaleResult(players, roundsDone, seed?)
	      players: { id, bones, fence, outAt?, damage?, clearTime? } with outAt nil while
	      alive, else when the player went out (bigger = later). Over when at most one is
	      alive or the last round of the table is done (`roundsDone`). The one player still
	      alive at the end gets Tuning SurvivorBonus x Bones on top (rounded down; nobody
	      when several are alive at the end or none is). Ranked by the Bone Rush chain.
	      Returns { over, ranking (ids, 1st first), bones (id -> final Bones), survivor
	      (id?), decidedBy }.
	  atClock(input)
	      the match clock ran out (#252): over at once. TEAM: { eliminationOrder, bones,
	      fence, damage, clearTime, seed }: everyone standing ranked by the chain from Fence
	      on, then the fallen sides, latest fall first. ROYALE: { players, seed } =
	      royaleResult(players, true, seed). Returns teamResult's / royaleResult's shape.

	TIE-BREAK CHAIN (DECISIONS #253; every queue, so no result is ever a tie)
	  Camp Clash: standing / fell later -> more Fence -> more Bones -> more damage dealt to
	      its own dinos (capped by the caller at each dino's HP) -> lower total round-clear
	      seconds -> a coin flip seeded by matchId
	  Bone Rush: final Bones -> survived longer -> more Fence -> more damage -> lower clear
	      time -> seeded coin flip
	  The coin flip is a seeded shuffle of the still-level group (ids sorted first), so the
	  same inputs and seed always give the same order. decidedBy: "standing", "fence",
	  "bones", "survived", "damage", "clearTime" or "coinFlip": the step that set 1st apart
	  from 2nd (the results line, T104); nil when not over or alone.
]]

local Config = require(script.Parent.Config)

export type Side = number
export type Kind = "hunter" | "tower" | "dino"
export type Attacker = "hunter" | "tower" | "hazard" | "ability" | "dino"
export type DamageOpts = { attacker: Attacker?, tower: { untouchable: boolean? }?, attackerOut: boolean?, shielded: boolean? }
export type TeamResult = { over: boolean, winners: { Side }, losers: { Side }, tie: boolean, ranking: { Side }, decidedBy: string? }
-- Per-side tie-break inputs (#253): Fence left, damage dealt to its own dinos (capped at each
-- dino's HP), total round-clear seconds, and the match seed (matchId) for the coin flip.
export type TeamStats = { fence: { [Side]: number }?, damage: { [Side]: number }?, clearTime: { [Side]: number }?, seed: any? }
export type RoyalePlayer<Id> = { id: Id, bones: number, fence: number, outAt: number?, damage: number?, clearTime: number? }
export type RoyaleResult<Id> = { over: boolean, ranking: { Id }, bones: { [Id]: number }, survivor: Id?, decidedBy: string? }
export type ClockInput = {
	modeKey: string,
	eliminationOrder: { { Side } }?,
	bones: { [Side]: number }?,
	fence: { [Side]: number }?,
	damage: { [Side]: number }?,
	clearTime: { [Side]: number }?,
	players: { RoyalePlayer<any> }?,
	seed: any?,
}

local BattleRules = {}

function BattleRules.canDamage(attackerSide: Side, targetSide: Side, targetKind: Kind, opts: DamageOpts?): boolean
	local attacker: Attacker = if opts and opts.attacker then opts.attacker else "hunter"
	if opts and opts.attackerOut then
		return false
	end
	if targetKind == "tower" and opts and opts.tower and opts.tower.untouchable then
		return false
	end
	if attacker == "dino" then
		return targetKind ~= "dino"
	end
	-- Every other source: its own side's dinos only (#228, #231).
	if targetKind == "dino" then
		return attackerSide == targetSide
	end
	if attacker ~= "hunter" then
		return false -- towers, hazards and abilities never touch hunters or towers
	end
	-- A hero shot: enemy hunters and enemy towers only.
	return attackerSide ~= targetSide
end

function BattleRules.ownDinos<T>(live: { [any]: T }, side: Side, attacker: Attacker): { T }
	local opts: DamageOpts = { attacker = attacker }
	local list = {}
	for _, enemy in live do
		if BattleRules.canDamage(side, (enemy :: any).side, "dino", opts) then
			table.insert(list, enemy)
		end
	end
	return list
end

function BattleRules.pvpDamage(amount: number, attackerSide: Side, targetSide: Side, targetKind: Kind, opts: DamageOpts?): number
	if amount <= 0 or not BattleRules.canDamage(attackerSide, targetSide, targetKind, opts) then
		return 0
	end
	if opts and opts.attacker and opts.attacker ~= "hunter" then
		return amount -- the PvP levers are for hunters' shots
	end
	if targetKind == "tower" then
		return amount * Config.Tuning.PvPTowerDamage
	elseif targetKind == "hunter" then
		if opts and opts.shielded then
			return 0 -- Camo Cover
		end
		return amount * Config.Tuning.PvPHunterDamage
	end
	return amount
end

function BattleRules.shielded(sinceSpawn: number): boolean
	return sinceSpawn >= 0 and sinceSpawn < Config.Tuning.SpawnShield
end

function BattleRules.canSupport(sourceSide: Side, targetSide: Side): boolean
	return sourceSide == targetSide
end

function BattleRules.nextRoundDue(sidesCleared: { [Side]: boolean }, elapsed: number): boolean
	if elapsed >= Config.Tuning.BattleRoundTime then
		return true
	end
	for _, cleared in sidesCleared do
		if not cleared then
			return false
		end
	end
	return true
end

function BattleRules.sideOut(fence: number): boolean
	return fence <= 0
end

function BattleRules.overtimeRepeat(round: number): number
	return math.max(0, round - #Config.Rounds)
end

function BattleRules.overtimeHpMult(n: number): number
	if n <= 0 then
		return 1
	end
	return Config.Tuning.OvertimeHPStep ^ n
end

local function sorted(list: { Side }): { Side }
	table.sort(list)
	return list
end

-- Tie-break chain (DECISIONS #253). The last step is a coin flip seeded by the match: a
-- seeded shuffle of the still-equal group, so it is reproducible and never leaves a tie.
local MODULUS = 2147483647 -- Park-Miller: every product stays below 2^53

local function seedOf(seed: any): number
	local h = 5381
	for i = 1, #tostring(seed) do
		h = (h * 33 + string.byte(tostring(seed), i)) % MODULUS
	end
	return if h == 0 then 1 else h
end

local function idBefore(a: any, b: any): boolean
	if type(a) == "number" and type(b) == "number" then
		return a < b
	end
	return tostring(a) < tostring(b)
end

-- id -> its coin-flip position among `ids` (1 = wins the flip), from the match seed.
local function coinFlip(ids: { any }, seed: any): { [any]: number }
	local order = table.clone(ids)
	table.sort(order, idBefore)
	local state = seedOf(seed)
	for i = #order, 2, -1 do
		state = (state * 48271) % MODULUS
		local j = state % i + 1
		order[i], order[j] = order[j], order[i]
	end
	local at = {}
	for i, id in order do
		at[id] = i
	end
	return at
end

export type Step = { key: string, value: (any) -> number, higher: boolean }

-- Ranks `items` by `steps` (first difference wins), then the coin flip. Returns the
-- ranked items and the step that set 1st apart from 2nd ("coinFlip" if none did).
local function chain<T>(items: { T }, steps: { Step }, idOf: (T) -> any, seed: any): ({ T }, string?)
	local ids = {}
	for _, item in items do
		table.insert(ids, idOf(item))
	end
	local flip = coinFlip(ids, seed)
	local function decide(a: T, b: T): (boolean?, string)
		for _, step in steps do
			local x, y = step.value(a), step.value(b)
			if x ~= y then
				return if step.higher then x > y else x < y, step.key
			end
		end
		return flip[idOf(a)] < flip[idOf(b)], "coinFlip"
	end
	local order = table.clone(items)
	table.sort(order, function(a, b)
		return (decide(a, b))
	end)
	local decidedBy: string? = nil
	if #order >= 2 then
		local _, key = decide(order[1], order[2])
		decidedBy = key
	end
	return order, decidedBy
end

local function teamSteps(bones: { [Side]: number }, stats: TeamStats?): { Step }
	local fence = stats and stats.fence or {}
	local damage = stats and stats.damage or {}
	local clear = stats and stats.clearTime or {}
	return {
		{ key = "fence", value = function(side)
			return fence[side] or 0
		end, higher = true },
		{ key = "bones", value = function(side)
			return bones[side] or 0
		end, higher = true },
		{ key = "damage", value = function(side)
			return damage[side] or 0
		end, higher = true },
		{ key = "clearTime", value = function(side)
			return clear[side] or 0
		end, higher = false },
	}
end

local function same(side: Side): Side
	return side
end

-- Every side, best first: the standing ones (ranked by the chain from Fence on), then each
-- elimination step from the latest, each ranked by the chain. decidedBy = "standing" when
-- 1st stood and 2nd had fallen, else the chain step between them.
local function teamRanking(eliminationOrder: { { Side } }, bones: { [Side]: number }, stats: TeamStats?): ({ Side }, string?)
	local fell: { [Side]: boolean } = {}
	for _, step in eliminationOrder do
		for _, side in step do
			fell[side] = true
		end
	end
	local standing = {}
	for side in bones do
		if not fell[side] then
			table.insert(standing, side)
		end
	end
	local steps = teamSteps(bones, stats)
	local seed = if stats then stats.seed else nil
	local ranking, decidedBy = chain(standing, steps, same, seed)
	for i = #eliminationOrder, 1, -1 do
		local group, by = chain(table.clone(eliminationOrder[i]), steps, same, seed)
		if #ranking == 1 and #group > 0 then
			decidedBy = "standing"
		elseif #ranking == 0 then
			decidedBy = by
		end
		for _, side in group do
			table.insert(ranking, side)
		end
	end
	return ranking, decidedBy
end

local function teamFrom(ranking: { Side }, decidedBy: string?): TeamResult
	local losers = {}
	for i = 2, #ranking do
		table.insert(losers, ranking[i])
	end
	return {
		over = #ranking > 0,
		winners = if #ranking > 0 then { ranking[1] } else {},
		losers = sorted(losers),
		tie = false,
		ranking = ranking,
		decidedBy = if #ranking >= 2 then decidedBy else nil,
	}
end

function BattleRules.teamResult(eliminationOrder: { { Side } }, bones: { [Side]: number }, stats: TeamStats?): TeamResult
	local fell: { [Side]: boolean } = {}
	for _, step in eliminationOrder do
		for _, side in step do
			fell[side] = true
		end
	end
	local standing = 0
	for side in bones do
		if not fell[side] then
			standing += 1
		end
	end
	if standing >= 2 then
		return { over = false, winners = {}, losers = {}, tie = false, ranking = {}, decidedBy = nil }
	end
	return teamFrom(teamRanking(eliminationOrder, bones, stats))
end

local function royaleSteps<Id>(final: { [Id]: number }): { Step }
	return {
		{ key = "bones", value = function(p)
			return final[p.id]
		end, higher = true },
		{ key = "survived", value = function(p)
			return p.outAt or math.huge
		end, higher = true },
		{ key = "fence", value = function(p)
			return p.fence
		end, higher = true },
		{ key = "damage", value = function(p)
			return p.damage or 0
		end, higher = true },
		{ key = "clearTime", value = function(p)
			return p.clearTime or 0
		end, higher = false },
	}
end

function BattleRules.royaleResult<Id>(players: { RoyalePlayer<Id> }, roundsDone: boolean, seed: any?): RoyaleResult<Id>
	local alive = {}
	for _, p in players do
		if p.outAt == nil then
			table.insert(alive, p)
		end
	end
	local over = #alive <= 1 or roundsDone
	local survivor: Id? = nil
	if over and #alive == 1 then
		survivor = alive[1].id
	end
	local final: { [Id]: number } = {}
	for _, p in players do
		final[p.id] = if p.id == survivor then math.floor(p.bones * (1 + Config.Tuning.SurvivorBonus)) else p.bones
	end
	local order, decidedBy = chain(players, royaleSteps(final), function(p)
		return p.id
	end, seed)
	local ranking = {}
	for _, p in order do
		table.insert(ranking, p.id)
	end
	return { over = over, ranking = ranking, bones = final, survivor = survivor, decidedBy = if over then decidedBy else nil }
end

function BattleRules.atClock(input: ClockInput): any
	if input.modeKey == "ROYALE" then
		return BattleRules.royaleResult(input.players or {}, true, input.seed)
	end
	local stats: TeamStats = { fence = input.fence, damage = input.damage, clearTime = input.clearTime, seed = input.seed }
	return teamFrom(teamRanking(input.eliminationOrder or {}, input.bones or {}, stats))
end

return table.freeze(BattleRules)
