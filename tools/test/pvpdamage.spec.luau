--[[
	PvP damage rules (PLAN phase 7 T78, DECISIONS #211, #212, #228, #231): Shared/BattleRules
	canDamage for every damage / effect source family, the ownDinos targeting filter the
	server hands each source, pvpDamage (shot x the PvP levers), and Camo Cover.

	Source families (the server modules that use each):
	  tower    Server/Towers: shots, splash, bomblets, line pierce, Storm Coil chains,
	           Judgement Bolt, Power Grid, Falcon dives/pecks, Ballista bolts/chains/Tow Line,
	           Chiller slow/Freeze, Hooded Scout marks, Thorn Plating/Bulwark
	  hazard   Server/Hazards burning ground; Server/Towers Tar Pit pools and Tar Tracks
	  ability  Server/Hero: Flare Strike (strike, stun, burn), Tracking Dart (+ extra marks)
	  hunter   Server/Hero shots (pellets, pierce, ricochet, splash, muzzle rounds, ignite)
	  dino     Server/DinoAttacks bites and throws
]]

local Config = require(src.shared.Config)
local BattleRules = require(src.shared.BattleRules)

local T = Config.Tuning
local SCOUT = Config.Towers.SCOUT
local FALCON = Config.Towers.FALCON
local TARPIT = Config.Towers.TARPIT

-- A live table keyed like Server/Enemies' (id -> dino), sides mixed.
local function liveMix(): { [number]: { id: number, side: number } }
	local live = {}
	for id = 1, 12 do
		live[id * 7] = { id = id, side = (id % 3) + 1 }
	end
	return live
end

local function sidesOf(list: { { side: number } }): { [number]: number }
	local count = {}
	for _, d in list do
		count[d.side] = (count[d.side] or 0) + 1
	end
	return count
end

local function onlyOwnDinos(attacker: string)
	local opts = { attacker = attacker :: any }
	for mine = 1, 3 do
		eq(BattleRules.canDamage(mine, mine, "dino", opts), true, `{attacker}: own side's dino`)
		for other = 1, 3 do
			if other ~= mine then
				eq(BattleRules.canDamage(mine, other, "dino", opts), false, `{attacker}: side {mine} vs side {other}'s dino`)
			end
		end
	end
	local live = liveMix()
	for side = 1, 3 do
		local own = BattleRules.ownDinos(live, side, attacker :: any)
		local count = sidesOf(own)
		eq(count[side], 4, `{attacker}: side {side} keeps its 4 dinos`)
		for other = 1, 3 do
			if other ~= side then
				eq(count[other], nil, `{attacker}: side {side} sees none of side {other}'s`)
			end
		end
	end
end

-- Families -----------------------------------------------------------------------------

test("tower family: own side's dinos only; never hunters or towers (targeting filter)", function()
	onlyOwnDinos("tower")
	for _, target in { "hunter", "tower" } do
		eq(BattleRules.canDamage(1, 2, target :: any, { attacker = "tower", tower = SCOUT }), false, `enemy {target}`)
		eq(BattleRules.canDamage(1, 1, target :: any, { attacker = "tower", tower = SCOUT }), false, `own {target}`)
	end
end)

test("hazard family (burning ground, Tar Pit): own side's dinos only; never hunters or towers", function()
	onlyOwnDinos("hazard")
	eq(BattleRules.canDamage(1, 2, "hunter", { attacker = "hazard" }), false, "an invader standing in fire")
	eq(BattleRules.canDamage(1, 2, "tower", { attacker = "hazard", tower = SCOUT }), false)
end)

test("ability family (Flare Strike, Tracking Dart): own side's dinos only; never hunters (#212)", function()
	onlyOwnDinos("ability")
	eq(BattleRules.canDamage(1, 2, "hunter", { attacker = "ability" }), false, "no crowd control on hunters")
	eq(BattleRules.canDamage(1, 1, "hunter", { attacker = "ability" }), false)
	eq(BattleRules.canDamage(1, 2, "tower", { attacker = "ability", tower = SCOUT }), false)
end)

test("hunter shots: own side's dinos, enemy hunters, enemy towers; never their own side", function()
	onlyOwnDinos("hunter")
	eq(BattleRules.canDamage(1, 2, "hunter"), true, "enemy hunter")
	eq(BattleRules.canDamage(1, 2, "tower", { tower = SCOUT }), true, "enemy tower")
	eq(BattleRules.canDamage(1, 1, "hunter"), false, "teammate")
	eq(BattleRules.canDamage(1, 1, "tower", { tower = SCOUT }), false, "own tower")
end)

test("dinos bite anyone in reach, any side (invaders included); never other dinos", function()
	for _, target in { "hunter", "tower" } do
		eq(BattleRules.canDamage(1, 2, target :: any, { attacker = "dino", tower = SCOUT }), true, `invading {target}`)
		eq(BattleRules.canDamage(1, 1, target :: any, { attacker = "dino", tower = SCOUT }), true, `home {target}`)
	end
	eq(BattleRules.canDamage(1, 1, "dino", { attacker = "dino" }), false)
end)

test("co-op is one side: every source still reaches every dino", function()
	local live = liveMix()
	for _, d in live do
		d.side = 1
	end
	for _, attacker in { "hunter", "tower", "hazard", "ability" } do
		eq(#BattleRules.ownDinos(live, 1, attacker :: any), 12, attacker)
	end
end)

-- How much (pvpDamage) ------------------------------------------------------------------

test("the seeds this spec means", function()
	eq(T.PvPTowerDamage, 0.35)
	eq(T.PvPHunterDamage, 0.5)
	eq(T.SpawnShield, 3)
end)

test("damage = shot x lever: enemy tower x PvP tower damage, enemy hunter x PvP hunter damage", function()
	near(BattleRules.pvpDamage(100, 1, 2, "tower", { tower = SCOUT }), 100 * T.PvPTowerDamage)
	near(BattleRules.pvpDamage(100, 1, 2, "hunter"), 100 * T.PvPHunterDamage)
	near(BattleRules.pvpDamage(40, 2, 3, "hunter"), 40 * T.PvPHunterDamage)
	eq(BattleRules.pvpDamage(100, 1, 1, "dino"), 100, "own dino: the full shot")
end)

test("own tower and teammate never damaged; immune towers immune; enemy dinos untouched", function()
	eq(BattleRules.pvpDamage(100, 1, 1, "tower", { tower = SCOUT }), 0, "own tower")
	eq(BattleRules.pvpDamage(100, 1, 1, "hunter"), 0, "teammate")
	eq(BattleRules.pvpDamage(100, 1, 2, "tower", { tower = FALCON }), 0, "Falcon Roost")
	eq(BattleRules.pvpDamage(100, 1, 2, "tower", { tower = TARPIT }), 0, "Tar Pit")
	eq(BattleRules.pvpDamage(100, 1, 2, "dino"), 0, "another side's dino")
end)

test("a shielded hunter (Camo Cover) takes 0; a spectator deals 0", function()
	eq(BattleRules.pvpDamage(100, 1, 2, "hunter", { shielded = true }), 0, "Camo Cover")
	near(BattleRules.pvpDamage(100, 1, 2, "tower", { tower = SCOUT, shielded = true }), 100 * T.PvPTowerDamage, "shield is for hunters")
	eq(BattleRules.pvpDamage(100, 1, 2, "hunter", { attackerOut = true }), 0, "spectator")
	eq(BattleRules.pvpDamage(100, 1, 2, "tower", { attackerOut = true, tower = SCOUT }), 0, "spectator")
end)

test("the levers are for shots: a dino's bite passes through unscaled", function()
	eq(BattleRules.pvpDamage(10, 1, 2, "hunter", { attacker = "dino" }), 10)
	eq(BattleRules.pvpDamage(10, 1, 2, "tower", { attacker = "dino", tower = SCOUT }), 10)
	eq(BattleRules.pvpDamage(10, 1, 2, "hunter", { attacker = "tower" }), 0, "towers never hit hunters")
	eq(BattleRules.pvpDamage(0, 1, 2, "hunter"), 0)
	eq(BattleRules.pvpDamage(-5, 1, 2, "hunter"), 0)
end)

test("Camo Cover lasts Spawn shield seconds from the (re)spawn", function()
	eq(BattleRules.shielded(0), true)
	eq(BattleRules.shielded(T.SpawnShield - 0.01), true)
	eq(BattleRules.shielded(T.SpawnShield), false)
	eq(BattleRules.shielded(T.SpawnShield + 10), false)
	eq(BattleRules.shielded(-1), false, "no spawn time recorded")
end)
