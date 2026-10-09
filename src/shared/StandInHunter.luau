--[[
	The stand-in hunter's rules (PLAN T93): a Studio-only dummy on each stand-in camp, so
	one Tester client can check hunter-vs-hunter damage alone. Pure; Server/StandInHunters
	builds and moves the dummy.

	It plays by a real hunter's PvP rules and nothing else: Tuning Player max health, an
	enemy hunter's shot through BattleRules.pvpDamage (x PvP hunter damage, 0 under Camo
	Cover, never from its own side), down at 0 HP, back after Tuning Respawn time at its own
	camp with full HP and a fresh Camo Cover (BattleRules.shielded). It never shoots, moves,
	earns, saves, pays or ranks: it isn't a Player.

	  new(side, now)                      a dummy standing, just (re)spawned
	  camo(dummy, now)                    under Camo Cover?
	  camoLeft(dummy, now)                Camo Cover seconds left (0 = none)
	  hit(dummy, amount, attackerSide, now)   (damage dealt, downed by this hit)
	  respawnDue(dummy, now)              down for Respawn time?
	  respawn(dummy, now)                 back up: full HP, Camo Cover again
	  label(dummy, now, campName)         its billboard text
]]

local Config = require(script.Parent.Config)
local BattleRules = require(script.Parent.BattleRules)
local BattleFlow = require(script.Parent.BattleFlow)

local StandInHunter = {}

export type Dummy = {
	side: number,
	hp: number,
	spawnedAt: number,
	downAt: number?,
	downBy: string?, -- who tranqed it ("Tranqed by <name>!")
}

function StandInHunter.new(side: number, now: number): Dummy
	return { side = side, hp = Config.Tuning.PlayerMaxHealth, spawnedAt = now, downAt = nil, downBy = nil }
end

function StandInHunter.camo(dummy: Dummy, now: number): boolean
	return dummy.downAt == nil and BattleRules.shielded(now - dummy.spawnedAt)
end

function StandInHunter.camoLeft(dummy: Dummy, now: number): number
	if not StandInHunter.camo(dummy, now) then
		return 0
	end
	return Config.Tuning.SpawnShield - (now - dummy.spawnedAt)
end

-- One enemy hunter's pellet of `amount` (before the PvP lever). A downed dummy takes nothing.
function StandInHunter.hit(dummy: Dummy, amount: number, attackerSide: number, now: number, attackerName: string?): (number, boolean)
	if dummy.downAt ~= nil then
		return 0, false
	end
	local damage = BattleRules.pvpDamage(amount, attackerSide, dummy.side, "hunter", { shielded = StandInHunter.camo(dummy, now) })
	if damage <= 0 then
		return 0, false
	end
	local dealt = math.min(dummy.hp, damage)
	dummy.hp -= dealt
	if dummy.hp <= 0 then
		dummy.hp = 0
		dummy.downAt = now
		dummy.downBy = attackerName
		return dealt, true
	end
	return dealt, false
end

function StandInHunter.respawnDue(dummy: Dummy, now: number): boolean
	return dummy.downAt ~= nil and now - dummy.downAt >= Config.Tuning.RespawnTime
end

function StandInHunter.respawn(dummy: Dummy, now: number)
	dummy.hp = Config.Tuning.PlayerMaxHealth
	dummy.spawnedAt = now
	dummy.downAt = nil
	dummy.downBy = nil
end

function StandInHunter.label(dummy: Dummy, now: number, campName: string): string
	local head = `{campName} stand-in hunter`
	if dummy.downAt ~= nil then
		return `{head}\n{BattleFlow.tranqLine(dummy.downBy or "?")}`
	end
	local text = `{head}\nHP {math.ceil(dummy.hp)} / {Config.Tuning.PlayerMaxHealth}`
	local left = StandInHunter.camoLeft(dummy, now)
	if left > 0 then
		text ..= `\nCamo Cover {string.format("%.1f", left)}s`
	end
	return text
end

return StandInHunter
