--[[
	The Studio-only stand-in hunter (PLAN T93): Shared/StandInHunter's rules go through
	BattleRules.pvpDamage exactly like a real hunter, and Server/StandInHunters only exists
	behind Shared/StudioOnly's "standIns".
]]
local fs = require("@lune/fs")
local Config = require(src.shared.Config)
local BattleRules = require(src.shared.BattleRules)
local StandInHunter = require(src.shared.StandInHunter)

local T = Config.Tuning
local LATER = T.SpawnShield + 1 -- past Camo Cover

test("T93: a shot lands x PvP hunter damage, the same as BattleRules.pvpDamage on a hunter", function()
	local d = StandInHunter.new(2, 0)
	local dealt, downed = StandInHunter.hit(d, 40, 1, LATER, "Tester")
	near(dealt, 40 * T.PvPHunterDamage, "x PvP hunter damage")
	near(dealt, BattleRules.pvpDamage(40, 1, 2, "hunter"), "pvpDamage")
	eq(downed, false)
	near(d.hp, T.PlayerMaxHealth - dealt, "HP")
	eq(T.PlayerMaxHealth, 100, "100 HP like a hunter")
end)

test("T93: Camo Cover after each (re)spawn takes no damage; the countdown runs down", function()
	local d = StandInHunter.new(2, 0)
	eq(StandInHunter.camo(d, 0.5), true)
	eq((StandInHunter.hit(d, 40, 1, 0.5, "Tester")), 0, "shielded")
	eq(d.hp, T.PlayerMaxHealth, "untouched")
	near(StandInHunter.camoLeft(d, 1), T.SpawnShield - 1, "countdown")
	ok(StandInHunter.label(d, 1, "Blue Camp"):find("Camo Cover", 1, true) ~= nil, "shown")
	eq(StandInHunter.camoLeft(d, LATER), 0, "gone")
	ok(StandInHunter.label(d, LATER, "Blue Camp"):find("Camo Cover", 1, true) == nil, "not shown")
end)

test("T93: its own side can't hurt it", function()
	local d = StandInHunter.new(2, 0)
	eq((StandInHunter.hit(d, 40, 2, LATER, "Friend")), 0)
	eq(d.hp, T.PlayerMaxHealth)
end)

test("T93: down at 0 HP, 'Tranqed by <name>!', back after Respawn time with Camo Cover", function()
	local d = StandInHunter.new(3, 0)
	local shots, downed = 0, false
	while not downed and shots < 100 do
		shots += 1
		downed = select(2, StandInHunter.hit(d, 30, 1, LATER, "Tester"))
	end
	eq(shots, math.ceil(T.PlayerMaxHealth / (30 * T.PvPHunterDamage)), "shots to tranq")
	eq(d.hp, 0)
	ok(StandInHunter.label(d, LATER, "Green Camp"):find("Tranqed by Tester!", 1, true) ~= nil, "the tranq line")
	eq((StandInHunter.hit(d, 30, 1, LATER, "Tester")), 0, "a downed dummy takes nothing")
	eq(StandInHunter.respawnDue(d, LATER + T.RespawnTime - 0.1), false, "not yet")
	eq(StandInHunter.respawnDue(d, LATER + T.RespawnTime), true, "Respawn time")
	StandInHunter.respawn(d, LATER + T.RespawnTime)
	eq(d.hp, T.PlayerMaxHealth, "full HP")
	eq(StandInHunter.camo(d, LATER + T.RespawnTime + 0.1), true, "fresh Camo Cover")
end)

test("T93: Studio only, through StudioOnly; real hunters' path unchanged", function()
	local server = fs.readFile("src/server/StandInHunters.luau")
	ok(server:find('StudioOnly.allowed(RunService:IsStudio(), "standIns")', 1, true) ~= nil, "gated by T89's helper")
	local battle = fs.readFile("src/server/Battle.luau")
	local seatAt = battle:find("local function seatStandIn(side: number)\n\t\tstandInSeats[side] = true", 1, true)
	local spawnAt = battle:find("StandInHunters.spawn(", 1, true)
	ok(seatAt ~= nil and spawnAt ~= nil and spawnAt > seatAt, "spawned only by seatStandIn")
	local _, seats = battle:gsub("seatStandIn%(side%)", "")
	eq(seats, 2, "seatStandIn: the stand-in camps at the start and a Studio late stand-in's plot (T105)")
	ok(battle:find("if not player then\n\t\t\t\tseating.standIn[side] = true", 1, true) ~= nil, "a late stand-in plot only when no player joined")
	local hero = fs.readFile("src/server/Hero.luau")
	ok(hero:find('BattleRules.pvpDamage(amount, mySide, sideOf(victim), "hunter", { shielded = Health.camoCover(victim) })', 1, true) ~= nil,
		"a real hunter's hit is unchanged")
	ok(hero:find("StandInHunters.standing()", 1, true) ~= nil, "offered as foes")
	-- Co-op: foesOf returns nothing with one side, before the stand-in list.
	local early = hero:find("sides <= 1 then\n\t\treturn foes", 1, true)
	ok(early ~= nil and early < hero:find("StandInHunters.standing()", 1, true), "co-op never sees one")
end)
