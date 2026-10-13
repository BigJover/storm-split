--[[
	Upgrade rules. Shared so the client's buttons grey out exactly what the
	server will refuse — but only the server's answer counts.

	The crossover rule (strict version): a tower may open at most two of its
	three paths, and only one of them may go past tier 2. `secondaryCap` raises
	that 2 (hero mastery level 20 makes it 3).

	`maxTier` is the path's tier count: 5 for towers, 6 for hero paths (DECISIONS
	#133). Tiers go up one at a time, so tier 6 always needs tier 5 on the same
	path; hero max builds are 6/2/0, or 6/3/0 at mastery level 20.
]]

local Upgrades = {}

export type Why = "ok" | "maxed" | "third path" | "crossover"

-- Can path `pathIndex` go up one tier, given the tower's current tiers?
function Upgrades.check(tiers: { number }, pathIndex: number, maxTier: number, secondaryCap: number?): Why
	local cap = secondaryCap or 2
	local current = tiers[pathIndex]
	if current == nil or current >= maxTier then
		return "maxed"
	end

	local maxOther, nonZeroOthers = 0, 0
	for i, tier in tiers do
		if i ~= pathIndex then
			maxOther = math.max(maxOther, tier)
			if tier > 0 then
				nonZeroOthers += 1
			end
		end
	end

	if current == 0 and nonZeroOthers >= 2 then
		return "third path" -- a third path may never open
	end
	if current >= cap and maxOther > cap then
		return "crossover" -- only one path may go past the cap (with cap 2: the classic rule)
	end
	return "ok"
end

-- A/B/C options (PLAN Phase 9, DECISIONS #275-#278). Config keeps tiers 1-3 in
-- `path.tiers` and the precomposed builds above them: `path.t4[o4]`, `path.t5[o4 .. o5]`
-- and, on hero paths, `path.t6[o4 .. o5]` (the exporter composes each option's step onto
-- the build under it). `picks` is a path's letters so far: "" below tier 4, "B" at tier
-- 4, "BA" at tier 5 and 6. A missing `picks` means option A (stand-ins and scripted
-- builds take A, #287).

-- How many tiers a path has: 5 on towers, 6 on hero paths.
function Upgrades.tierCount(path): number
	return #path.tiers + (if path.t4 then 1 else 0) + (if path.t5 then 1 else 0) + (if path.t6 then 1 else 0)
end

-- The cumulative Config row of a path at `tier` with these picks, or nil (tier 0, past the
-- top, or a pick with no row).
function Upgrades.row(path, tier: number, picks: string?): any
	if tier <= 0 then
		return nil
	elseif tier <= #path.tiers then
		return path.tiers[tier]
	end
	local letters = picks or "AA"
	if tier == 4 then
		return path.t4 and path.t4[string.sub(letters, 1, 1)]
	elseif tier == 5 then
		return path.t5 and #letters >= 2 and path.t5[string.sub(letters, 1, 2)] or nil
	elseif tier == 6 then
		return path.t6 and #letters >= 2 and path.t6[string.sub(letters, 1, 2)] or nil
	end
	return nil
end

-- A path's rows from tier 1 to the top for these picks (option A by default).
function Upgrades.line(path, picks: string?): { any }
	local out = {}
	for tier = 1, Upgrades.tierCount(path) do
		out[tier] = Upgrades.row(path, tier, picks)
	end
	return out
end

-- The next tier's Config row for a path with option A at tiers 4 and 5, or nil if it's
-- maxed.
function Upgrades.nextStep(def, tiers: { number }, pathIndex: number): any?
	local path = def.paths[pathIndex]
	if not path then
		return nil
	end
	return Upgrades.row(path, (tiers[pathIndex] or 0) + 1)
end

return Upgrades
