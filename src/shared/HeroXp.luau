--[[
	Hero XP: the rule that turns cleared rounds and pops into a hunter's level
	(PLAN round 3 T34, DECISIONS #100-#103). Pure: Config in, numbers out. It reads no
	clock, no player and no attribute, so the server (Server/Hero, the only mutator of
	a hunter's XP) and the headless specs run the same code.

	  Clearing a round banks Round XP (XPPerLevel / RoundsPerLevel) for every hunter,
	  plus pop XP: XPPerPop x (own pops + TeamPopShare x teammates' pops), rounded
	  down, at most PopXPCapPerRound. Pop XP is pending until the round is cleared;
	  a lost round or leaving drops it (the caller simply never banks it).

	  Level = 1 + floor(XP / XPPerLevel), held between the ROUND LEVEL
	  (1 + rounds cleared / RoundsPerLevel: the old curve, and what towers use) and
	  the round level + HeroLevelLeadCap.

	XP is per match: nothing here is saved.
]]

local Config = require(script.Parent.Config)

local HeroXp = {}

local function whole(n: number): number
	return math.max(0, math.floor(n))
end

-- XP every hunter banks for a cleared round.
function HeroXp.roundXp(): number
	return Config.Tuning.XPPerLevel / Config.Tuning.RoundsPerLevel
end

-- The old every-RoundsPerLevel-rounds level: the floor for hunters, and the level
-- towers fight at.
function HeroXp.roundLevel(roundsCleared: number): number
	return 1 + math.floor(whole(roundsCleared) / Config.Tuning.RoundsPerLevel)
end

-- Pop XP for one round. `teamPops` is everyone's pops this round, own included.
function HeroXp.popXp(ownPops: number, teamPops: number): number
	local own = whole(ownPops)
	local mates = math.max(0, whole(teamPops) - own)
	local xp = math.floor(Config.Tuning.XPPerPop * (own + Config.Tuning.TeamPopShare * mates))
	return math.min(xp, Config.Tuning.PopXPCapPerRound)
end

-- The XP of a hunter with no pops at all: where late joiners and re-joiners start.
function HeroXp.floorXp(roundsCleared: number): number
	return whole(roundsCleared) * HeroXp.roundXp()
end

-- The most XP a hunter may hold: one short of the level past the lead cap.
local function ceilingXp(roundsCleared: number): number
	return (HeroXp.roundLevel(roundsCleared) + Config.Tuning.HeroLevelLeadCap) * Config.Tuning.XPPerLevel - 1
end

-- The XP after clearing a round: `xp` before it, the round's pops, and how many
-- rounds are cleared now (this one included). Never below the floor, never at or
-- above the XP of round level + lead cap + 1.
function HeroXp.bank(xp: number, ownPops: number, teamPops: number, roundsClearedAfter: number): number
	local banked = whole(xp) + HeroXp.roundXp() + HeroXp.popXp(ownPops, teamPops)
	return math.clamp(banked, HeroXp.floorXp(roundsClearedAfter), ceilingXp(roundsClearedAfter))
end

-- The hunter's level, held between the round level and the lead cap above it.
function HeroXp.level(xp: number, roundsCleared: number): number
	local floorLevel = HeroXp.roundLevel(roundsCleared)
	local raw = 1 + math.floor(whole(xp) / Config.Tuning.XPPerLevel)
	return math.clamp(raw, floorLevel, floorLevel + Config.Tuning.HeroLevelLeadCap)
end

return HeroXp
