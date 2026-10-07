--[[
	The battle modes' rules (PLAN phase 7 T71, DECISIONS #210-#214). Pure: Config in,
	answers out, so the server (T77/T78) only calls them and specs run headlessly.
	Co-op is one side, so none of this changes it.

	A side is a number (1, 2, ...). Kinds: "hunter", "tower", "dino".

	  canDamage(attackerSide, targetSide, targetKind, opts?)
	      whether a hit may land. No friendly fire, ever: a hunter never hurts their own
	      side's hunters or towers. Towers shoot dinos only (never hunters, never towers).
	      A tower that can't be damaged (def.untouchable: Falcon Roost, Tar Pit) is immune
	      to everyone. Dinos bite any hunter or tower in reach, invaders included. A hunter
	      whose side is out (a spectator) deals no damage. opts = { attacker: Kind?
	      (default "hunter"), tower: def? (the target tower's Config def), attackerOut:
	      boolean? }. How much a hit does (PvP multipliers) is T78's.
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
	  teamResult(eliminationOrder, bones)
	      `bones` has every side (side -> Bones, 0 if none); `eliminationOrder` lists the
	      falls in order, each a list of the sides that fell in that same step. Not over
	      while two or more sides stand. One standing = it wins. None standing = the sides
	      of the last step fell together: most Bones wins; equal Bones = a tie (every tied
	      side wins and the pot is split across them). Returns { over, winners, losers,
	      tie }; winners/losers sorted by side.
	  royaleResult(players, roundsDone)
	      players: { id, bones, fence, outAt? } with outAt nil while alive, else when the
	      player went out (bigger = later). Over when at most one is alive or the last
	      round of the table is done (`roundsDone`). The one player still alive at the end
	      by elimination gets Tuning SurvivorBonus x Bones on top (rounded down; nobody
	      when several are alive at the last round or none is). Ranking: final Bones, then
	      survived longer (alive beats out; later out beats earlier), then more Fence, then
	      the order given (deterministic). Returns { over, ranking (ids, 1st first),
	      bones (id -> final Bones), survivor (id?) }.
]]

local Config = require(script.Parent.Config)

export type Side = number
export type Kind = "hunter" | "tower" | "dino"
export type DamageOpts = { attacker: Kind?, tower: { untouchable: boolean? }?, attackerOut: boolean? }
export type TeamResult = { over: boolean, winners: { Side }, losers: { Side }, tie: boolean }
export type RoyalePlayer<Id> = { id: Id, bones: number, fence: number, outAt: number? }
export type RoyaleResult<Id> = { over: boolean, ranking: { Id }, bones: { [Id]: number }, survivor: Id? }

local BattleRules = {}

function BattleRules.canDamage(attackerSide: Side, targetSide: Side, targetKind: Kind, opts: DamageOpts?): boolean
	local attacker: Kind = if opts and opts.attacker then opts.attacker else "hunter"
	if opts and opts.attackerOut then
		return false
	end
	if targetKind == "tower" and opts and opts.tower and opts.tower.untouchable then
		return false
	end
	if attacker == "dino" then
		return targetKind ~= "dino"
	elseif attacker == "tower" then
		return targetKind == "dino"
	end
	-- A hunter: dinos anywhere; enemy hunters and enemy towers only.
	if targetKind == "dino" then
		return true
	end
	return attackerSide ~= targetSide
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

function BattleRules.teamResult(eliminationOrder: { { Side } }, bones: { [Side]: number }): TeamResult
	local fell: { [Side]: boolean } = {}
	for _, step in eliminationOrder do
		for _, side in step do
			fell[side] = true
		end
	end
	local standing, all = {}, {}
	for side in bones do
		table.insert(all, side)
		if not fell[side] then
			table.insert(standing, side)
		end
	end
	if #standing >= 2 then
		return { over = false, winners = {}, losers = {}, tie = false }
	end
	local winners: { Side }
	if #standing == 1 then
		winners = standing
	else
		local last = eliminationOrder[#eliminationOrder] or {}
		local best = -math.huge
		for _, side in last do
			best = math.max(best, bones[side] or 0)
		end
		winners = {}
		for _, side in last do
			if (bones[side] or 0) == best then
				table.insert(winners, side)
			end
		end
	end
	local won: { [Side]: boolean } = {}
	for _, side in winners do
		won[side] = true
	end
	local losers = {}
	for _, side in all do
		if not won[side] then
			table.insert(losers, side)
		end
	end
	return { over = #winners > 0, winners = sorted(winners), losers = sorted(losers), tie = #winners > 1 }
end

function BattleRules.royaleResult<Id>(players: { RoyalePlayer<Id> }, roundsDone: boolean): RoyaleResult<Id>
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
	local index: { [Id]: number } = {}
	for i, p in players do
		index[p.id] = i
		final[p.id] = if p.id == survivor then math.floor(p.bones * (1 + Config.Tuning.SurvivorBonus)) else p.bones
	end
	local order = table.clone(players)
	table.sort(order, function(a, b)
		if final[a.id] ~= final[b.id] then
			return final[a.id] > final[b.id]
		end
		local aOut, bOut = a.outAt or math.huge, b.outAt or math.huge
		if aOut ~= bOut then
			return aOut > bOut
		end
		if a.fence ~= b.fence then
			return a.fence > b.fence
		end
		return index[a.id] < index[b.id]
	end)
	local ranking = {}
	for _, p in order do
		table.insert(ranking, p.id)
	end
	return { over = over, ranking = ranking, bones = final, survivor = survivor }
end

return table.freeze(BattleRules)
