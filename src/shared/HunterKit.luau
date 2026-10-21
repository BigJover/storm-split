--[[
	Hunter kit (PLAN 10b T136/T137, DECISIONS #366-#370): each hunter's melee and grenade,
	from the `Hunter Kit` sheet. Pure: the data and the PvP rules both sides share. The
	geometry is Shared/Melee (and Shared/Grenade); Server/Kit acts on it.

	  row(heroKey)                 that hunter's kit row, or nil (no hunter / unknown key)
	  trained(value, cap)          a trained stat in %: a number clamped to 0..cap, else 0
	                               (T139 fills the attributes below; until then every hunter
	                               reads 0, the untrained base)
	  REACH_ATTRIBUTE / THROW_ATTRIBUTE   the Player attributes the saved Reach / Throw
	                               training is published on (percent; the server sets them)
	  dinoEffect(kind, %, s)       { kind, percent, seconds } for "slow" / "amp", else nil
	  hunterSlow(kind, %, s)       (percent, seconds) a hit may slow an ENEMY hunter: only a
	                               "slow", clamped to Kit hunter slow max % / (s); anything else
	                               (none, and the stun / knockback the exporter refuses) is 0, 0
	                               (#368: no stun or knockback on hunters)
	  vsHunter(amount, mySide, theirSide, shielded)   the damage an enemy hunter takes: x PvP
	                               hunter damage, 0 for the own side (no friendly fire) or under
	                               Camo Cover (BattleRules.pvpDamage, a hunter's hit)
	  BREAKS                       a melee hit or grenade breaks at most 1 size (like splash)
]]

local Config = require(script.Parent.Config)
local BattleRules = require(script.Parent.BattleRules)

local HunterKit = {}

HunterKit.REACH_ATTRIBUTE = "TrainedReach"
HunterKit.THROW_ATTRIBUTE = "TrainedThrow"
HunterKit.BREAKS = 1

export type Effect = { kind: string, percent: number, seconds: number }

function HunterKit.row(heroKey: unknown): any?
	if type(heroKey) ~= "string" then
		return nil
	end
	return (Config.HunterKit :: any)[heroKey]
end

function HunterKit.trained(value: unknown, cap: number): number
	if type(value) ~= "number" or value ~= value then
		return 0
	end
	return math.clamp(value, 0, math.max(0, cap))
end

function HunterKit.dinoEffect(kind: unknown, percent: unknown, seconds: unknown): Effect?
	if (kind ~= "slow" and kind ~= "amp") or type(percent) ~= "number" or type(seconds) ~= "number" then
		return nil
	end
	if percent <= 0 or seconds <= 0 then
		return nil
	end
	return { kind = kind :: string, percent = if kind == "slow" then math.min(percent, 100) else percent, seconds = seconds }
end

function HunterKit.hunterSlow(kind: unknown, percent: unknown, seconds: unknown): (number, number)
	if kind ~= "slow" or type(percent) ~= "number" or type(seconds) ~= "number" or percent ~= percent or seconds ~= seconds then
		return 0, 0
	end
	local t = Config.Tuning
	local p, s = math.clamp(percent, 0, t.KitHunterSlowMax), math.clamp(seconds, 0, t.KitHunterSlowMaxS)
	if p <= 0 or s <= 0 then
		return 0, 0
	end
	return p, s
end

function HunterKit.vsHunter(amount: number, mySide: number, theirSide: number, shielded: boolean): number
	return BattleRules.pvpDamage(amount, mySide, theirSide, "hunter", { attacker = "hunter", shielded = shielded })
end

return HunterKit
