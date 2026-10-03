--[[
	Mastery small perks (PLAN T51, DECISIONS #135): the levels 6-9, 11-14 and
	16-19 give four small, non-damage lines, each in three steps. Pure, so the
	rules have headless specs; the server applies them, the client shows the
	same numbers.

	  at          the perks at a mastery level (level 0 or unknown: none):
	                pickupReach   studs added to how far a hunter grabs
	                              chests and med kits (Server/Airdrops)
	                healPerRound  HP added to the round-clear heal (Main)
	                respawnMult   x respawn time (Main; stacks with a
	                              Rescue Beacon's)
	                repairCostMult  x a repair's price (Server/Shop and the
	                              tower panel)
	  ofPlayer    the perks of the hero a player is playing, from the
	              server-set "Hero" and "Mastery_{hero}" attributes (the
	              attributes the client already reads; a client can't set them)
	  gap         how far a hunter's root part is from touching a drop, on the
	              ground plane: the distance from the root's centre to the
	              drop's box footprint, less the root's half width (drops are
	              axis-aligned boxes sitting on the ground)
	  inReach     a drop counts as picked up when the gap is within the reach
	              (reach 0 = touching only, which Touched already handles)

	Values come from the Mastery sheet (cumulative per level); none of them
	touches damage, fire rate, reload, recoil, spread, max HP or move speed.
]]

local Config = require(script.Parent.Config)

local SmallPerks = {}

export type Perks = {
	pickupReach: number,
	healPerRound: number,
	respawnMult: number,
	repairCostMult: number,
}

SmallPerks.NONE = table.freeze({ pickupReach = 0, healPerRound = 0, respawnMult = 1, repairCostMult = 1 }) :: Perks

function SmallPerks.at(level: number?): Perks
	local row = Config.Mastery[math.floor(level or 0)]
	if not row then
		return SmallPerks.NONE
	end
	return {
		pickupReach = math.max(0, row.pickupReachAdd or 0),
		healPerRound = math.max(0, row.healPerRoundAdd or 0),
		respawnMult = math.clamp(row.respawnMult or 1, 0, 1),
		repairCostMult = math.clamp(row.repairCostMult or 1, 0, 1),
	}
end

function SmallPerks.ofPlayer(player: Player): Perks
	local hero = player:GetAttribute("Hero")
	if typeof(hero) ~= "string" or hero == "" then
		return SmallPerks.NONE
	end
	local level = player:GetAttribute(`Mastery_{hero}`)
	return SmallPerks.at(if typeof(level) == "number" then level else 0)
end

function SmallPerks.gap(root: Vector3, rootHalfWidth: number, centre: Vector3, size: Vector3): number
	local half = size / 2
	local dx = math.max(0, math.abs(root.X - centre.X) - half.X)
	local dz = math.max(0, math.abs(root.Z - centre.Z) - half.Z)
	return math.max(0, math.sqrt(dx * dx + dz * dz) - rootHalfWidth)
end

function SmallPerks.inReach(gap: number, reach: number): boolean
	return reach > 0 and gap <= reach
end

return SmallPerks
