--[[
	Upgrade rules. Shared so the client's buttons grey out exactly what the
	server will refuse — but only the server's answer counts.

	The crossover rule (strict version): a tower may open at most two of its
	three paths, and only one of them may go past tier 2. `secondaryCap` raises
	that 2 (hero mastery level 20 makes it 3).
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

-- The next tier's Config row for a path, or nil if it's maxed.
function Upgrades.nextStep(def, tiers: { number }, pathIndex: number): any?
	local path = def.paths[pathIndex]
	if not path then
		return nil
	end
	return path.tiers[(tiers[pathIndex] or 0) + 1]
end

return Upgrades
