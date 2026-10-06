--[[
	Gun rules for the hero tier 6s (PLAN T52, DECISIONS #133): pure, so the
	server (Server/Hero, the only one whose answer counts) and the client's
	crosshair agree, and so specs can hold them headlessly.

	  sizeBreaks      Heart Shot: the gun's Size breaks only on a scoped shot;
	                  unscoped shots break 1 (#170). Guns without a scope
	                  (Thunder Slug) break their Size breaks on every shot
	  cone            the spread cone: base spread x Still spread x (standing
	                  still, Thunder Slug) x Scoped spread x (zoomed, Heart Shot),
	                  plus recoil bloom
	  usesRounds      Belt Fed: no rounds used during Rally Cry; Endless Belt:
	                  none while fully spun up either
	  swapDue /       Hot Swap: dual guns reload one at a time. When a gun's
	  swapRefill      share of the magazine is spent, that gun reloads in the
	                  background (stats.reload) while the other keeps firing
	  ricochetRefill  Bounce Back: rounds back for each ricochet take-down
	  burstStarts     Big Five: recoil resets when a new burst starts
	  charges /       ability charges (Rapid Response holds 2): `fullAt` is when
	  useCharge /     every charge is back; charges come back one cooldown apart
	  readyAt
]]

local GunRules = {}

export type GunStats = {
	spread: number,
	stillSpreadMult: number,
	scopedSpreadMult: number,
	scope: boolean,
	magazine: number,
	guns: number,
	beltFed: boolean,
	spunUpBelt: boolean,
	staggeredReload: boolean,
	ricochetReload: number,
	fireMode: string,
	burstCount: number,
	burstRecoilReset: boolean,
}

-- The cone (degrees) a pellet scatters in. `scoped` only counts on a gun with a scope.
function GunRules.cone(stats: GunStats, bloom: number, still: boolean, scoped: boolean): number
	local base = stats.spread
	if still then
		base *= stats.stillSpreadMult
	end
	if scoped and stats.scope then
		base *= stats.scopedSpreadMult
	end
	return base + bloom
end

-- The Size breaks a direct hit gets. On a gun with a scope it counts only when
-- the shot was fired scoped (the same flag `cone` reads); unscoped shots break 1.
function GunRules.sizeBreaks(stats: { sizeBreaks: number, scope: boolean }, scoped: boolean): number
	if stats.scope and not scoped then
		return 1
	end
	return stats.sizeBreaks
end

-- Does this pull use rounds? `spin` is the Spin-Up progress, 0..1.
function GunRules.usesRounds(stats: GunStats, overdrive: boolean, spin: number): boolean
	if stats.beltFed and overdrive then
		return false
	end
	if stats.spunUpBelt and spin >= 1 then
		return false
	end
	return true
end

-- One gun's share of the magazine.
function GunRules.gunShare(stats: GunStats): number
	return math.floor(stats.magazine / math.max(1, stats.guns))
end

-- Hot Swap: should a background reload of one gun start now? Only with two or more
-- guns, while none is running, once a whole gun's share is spent and rounds remain.
function GunRules.swapDue(stats: GunStats, rounds: number, swapping: boolean): boolean
	if not stats.staggeredReload or stats.guns < 2 or swapping then
		return false
	end
	return rounds > 0 and rounds <= stats.magazine - GunRules.gunShare(stats)
end

-- Hot Swap: the rounds once that gun's reload is done.
function GunRules.swapRefill(stats: GunStats, rounds: number): number
	return math.min(stats.magazine, rounds + GunRules.gunShare(stats))
end

-- Bounce Back: the rounds after `takeDowns` ricochet take-downs.
function GunRules.ricochetRefill(stats: GunStats, rounds: number, takeDowns: number): number
	if stats.ricochetReload <= 0 or takeDowns <= 0 then
		return rounds
	end
	return math.min(stats.magazine, rounds + stats.ricochetReload * takeDowns)
end

-- Big Five: does the shot after `shotsFired` (since the last reload) start a
-- new burst whose recoil resets?
function GunRules.burstStarts(stats: GunStats, shotsFired: number): boolean
	return stats.burstRecoilReset and stats.fireMode == "burst" and shotsFired % math.max(1, stats.burstCount) == 0
end

-- Ability charges. `fullAt` = when every charge is back (0 or past = full).
function GunRules.charges(fullAt: number, now: number, max: number, cooldown: number): number
	if now >= fullAt then
		return max
	end
	if cooldown <= 0 then
		return max
	end
	return math.clamp(max - math.ceil((fullAt - now) / cooldown - 1e-9), 0, max)
end

-- Spend a charge (the caller has checked one is there): the new `fullAt`.
function GunRules.useCharge(fullAt: number, now: number, cooldown: number): number
	return math.max(fullAt, now) + cooldown
end

-- When the next charge can be used (now or earlier if one is there).
function GunRules.readyAt(fullAt: number, now: number, max: number, cooldown: number): number
	if GunRules.charges(fullAt, now, max, cooldown) > 0 then
		return now
	end
	return fullAt - (max - 1) * cooldown
end

return GunRules
