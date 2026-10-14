--[[
	The generic tower mechanics of PLAN 9d (DECISIONS #284, #294), reused by 9e/9g. Pure,
	so specs run headlessly; Server/Towers gathers the towers and applies the result.

	  sting       Raider sting (`Raider slow %`, `Raider slow (s)`, `Raider damage`): in a
	              battle, an ENEMY hunter who damages a tower on this side while standing
	              inside a standing Raider tower's range is stung: Raider damage x the PvP
	              hunter lever (x0.5, BattleRules.pvpDamage) and a slow of Raider slow % for
	              Raider slow (s). Several Raider towers covering the hunter don't stack: the
	              strongest of each part. At most once per Tuning Raider sting cooldown (s)
	              per hunter; nothing under Camo Cover; never a stun or a reveal; nothing in
	              co-op (no enemy hunters) and never a teammate. The exporter holds the slow
	              to <= 30 % and <= 3 s (#284).
	  bounty      Bounty cash: a dino taken down (not a shrink) inside the range of a standing
	              Supply Camp on its own side pays that side the camp's Bounty cash; the
	              strongest camp covering it pays, once (no stacking).
]]

local Config = require(script.Parent.Config)
local BattleRules = require(script.Parent.BattleRules)

local TowerPerks = {}

-- One tower as these rules see it: its side, standing (not trampled), whether its range
-- covers the point in question, and its composed stats (Shared/TowerStats).
export type Source = {
	side: number,
	standing: boolean,
	covers: boolean,
	stats: {
		raiderDamage: number,
		raiderSlowPercent: number,
		raiderSlowSeconds: number,
		bountyCash: number,
	},
}

export type Sting = { damage: number, slowPercent: number, slowSeconds: number }

local function counts(source: Source, side: number): boolean
	return source.standing and source.covers and source.side == side
end

-- The sting `hunterSide`'s hunter gets for damaging a tower on `towerSide` (nil = none).
-- `shielded`: the hunter is under Camo Cover. `lastAt`: when this hunter was last stung
-- (nil = never); `now` on the same clock.
function TowerPerks.sting(sources: { Source }, towerSide: number, hunterSide: number, shielded: boolean, lastAt: number?, now: number): Sting?
	-- An enemy hunter only: one who may shoot this side's towers (never co-op, never a teammate).
	if not BattleRules.canDamage(hunterSide, towerSide, "tower") or shielded then
		return nil
	end
	if lastAt and now - lastAt < Config.Tuning.RaiderStingCooldownS then
		return nil
	end
	local damage, slow, seconds = 0, 0, 0
	for _, source in sources do
		if counts(source, towerSide) then
			local s = source.stats
			damage = math.max(damage, s.raiderDamage)
			slow = math.max(slow, s.raiderSlowPercent)
			seconds = math.max(seconds, s.raiderSlowSeconds)
		end
	end
	if damage <= 0 and (slow <= 0 or seconds <= 0) then
		return nil
	end
	return {
		damage = BattleRules.pvpDamage(damage, towerSide, hunterSide, "hunter", { shielded = shielded }),
		slowPercent = if seconds > 0 then slow else 0,
		slowSeconds = if slow > 0 then seconds else 0,
	}
end

-- Bounty cash for a dino of `dinoSide` taken down at a point the sources' `covers` was
-- measured for: the strongest standing own-side camp covering it, once.
function TowerPerks.bounty(sources: { Source }, dinoSide: number): number
	local best = 0
	for _, source in sources do
		if counts(source, dinoSide) then
			best = math.max(best, source.stats.bountyCash)
		end
	end
	return best
end

return TowerPerks
