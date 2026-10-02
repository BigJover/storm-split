--[[
	Shared/Combat: size scaling of dino attacks, the resistance cap, tower max HP per tier
	bought, and repair cost (DECISIONS #4, #8, #10, #12).
]]

local Config = require(src.shared.Config)
local Combat = require(src.shared.Combat)

test("the Tuning levers are the seeds this spec means", function()
	eq(Config.Tuning.PlayerMaxHealth, 100)
	eq(Config.Tuning.HealPerRound, 25)
	eq(Config.Tuning.SpawnProtection, 3)
	eq(Config.Tuning.MaxResist, 60)
	eq(Config.Tuning.MaxProjectiles, 80)
	eq(Config.Tuning.TowerHPPerTier, 0.15)
	eq(Config.Tuning.RepairCost, 0.3)
end)

test("attack damage scales with size and difficulty", function()
	near(Combat.attackDamage(10, 4, 4, 1), 10, "full size, Easy")
	near(Combat.attackDamage(10, 2, 4, 1), 5, "half-shrunk hits half as hard")
	near(Combat.attackDamage(10, 1, 4, 1), 2.5, "smallest size")
	near(Combat.attackDamage(10, 1, 1, 1), 10, "one-size species")
	near(Combat.attackDamage(10, 4, 4, 2.2), 22, "Chaos x2.2")
	near(Combat.attackDamage(50, 3, 6, 1.25), 31.25, "T-Rex at half size on Normal")
end)

test("resistance: strongest source wins, capped at Max resist", function()
	eq(Combat.combineResist({}), 0, "no sources")
	eq(Combat.combineResist({ 15 }), 15, "one source")
	eq(Combat.combineResist({ 15, 30, 20 }), 30, "strongest wins, no stacking")
	eq(Combat.combineResist({ 45, 30 }), 45, "Bulwark 45 + Second Wind 30 is 45, not 75")
	eq(Combat.combineResist({ 90 }), 60, "capped at 60")
	near(Combat.afterResist(100, 30), 70, "30% off")
	near(Combat.afterResist(100, 0), 100, "none")
	near(Combat.afterResist(100, 60), 40, "at the cap")
end)

test("tower max HP: +15% of base per tier bought, then aura %", function()
	local def = { maxHp = 100 }
	near(Combat.towerMaxHp(def, { 0, 0, 0 }), 100, "0 tiers")
	near(Combat.towerMaxHp(def, { 3, 0, 0 }), 145, "3 tiers")
	near(Combat.towerMaxHp(def, { 5, 2, 0 }), 205, "7 tiers (+105%)")
	near(Combat.towerMaxHp(def, { 2, 1, 0 }), 145, "3 tiers over two paths")
	near(Combat.towerMaxHp({ maxHp = 80 }, { 5, 2, 0 }), 164, "Longshot Perch, 7 tiers")
	near(Combat.towerMaxHp(def, { 0, 0, 0 }, 20), 120, "Iron Tonic aura +20%")
	near(Combat.towerMaxHp(def, { 3, 0, 0 }, 10), 159.5, "3 tiers and +10%")
end)

test("repair cost: 0.3 x spent x HP missing, discount, rounded", function()
	eq(Combat.repairCost(1000, 0, 100), 300, "0% HP (trampled): 30% of spent")
	eq(Combat.repairCost(1000, 50, 100), 150, "50% HP")
	eq(Combat.repairCost(1000, 100, 100), 0, "100% HP: free, nothing to do")
	eq(Combat.repairCost(1000, 120, 100), 0, "over max: nothing to do")
	eq(Combat.repairCost(1000, 0, 100, 20), 240, "Command Center 20% off")
	eq(Combat.repairCost(1000, 50, 100, 5), 143, "Bulk Order 5% off 150 = 142.5, rounds up")
	eq(Combat.repairCost(659, 25, 80), 136, "0.3 x 659 x 0.6875 = 135.9")
	eq(Combat.repairCost(1000, 0, 0), 0, "no max HP")
end)

test("Config tower Max HP (DECISIONS #8) and what upgrades add", function()
	local want = { SCOUT = 100, SNIPER = 80, GRENADIER = 150, CHILLER = 120, QUARTERMASTER = 200 }
	for key, hp in want do
		local def = Config.Towers[key]
		eq(def.maxHp, hp, `{key} ({def.display}) Max HP`)
		near(Combat.towerMaxHp(def, { 0, 0, 0 }), hp, `{key} at 0 tiers`)
		near(Combat.towerMaxHp(def, { 2, 1, 0 }), hp * 1.45, `{key} at 3 tiers`)
		near(Combat.towerMaxHp(def, { 5, 2, 0 }), hp * 2.05, `{key} at 7 tiers`)
	end
end)

test("bites in Config (DECISIONS #2/#3) and Dino damage x (#4)", function()
	local bites = {
		HUSK = { "Nip", 2, 1, 8 },
		BRUTE = { "Slash", 4, 1.2, 9 },
		SHIELD = { "Head-Butt", 6, 1.5, 9 },
		ARMOR = { "Tail Club", 10, 2, 10 },
		STORM = { "Kick", 6, 1, 9 },
		ZEP = { "Gore", 25, 2, 12 },
		BARGE = { "Chomp", 50, 2.5, 14 },
	}
	for key, want in bites do
		local e = Config.Enemies[key]
		eq(e.meleeName, want[1], `{key} ({e.display}) melee name`)
		eq(e.meleeDamage, want[2], `{key} melee damage`)
		eq(e.meleeEvery, want[3], `{key} melee every`)
		eq(e.meleeReach, want[4], `{key} melee reach`)
	end
	eq(Config.Enemies.LLAMA.meleeDamage, 0, "Pteranodon can't bite (it flies)")
	local mult = { EASY = 1, NORMAL = 1.25, HARD = 1.6, CHAOS = 2.2 }
	for key, m in mult do
		eq(Config.Difficulties[key].dinoDamageMult, m, `{key} Dino damage x`)
	end
	local rex = Config.Enemies.BARGE
	near(Combat.attackDamage(rex.meleeDamage, rex.sizes, rex.sizes, 2.2), 110, "full T-Rex Chomp on Chaos")
	near(Combat.attackDamage(rex.meleeDamage, 1, rex.sizes, 1), 10, "smallest T-Rex on Easy")
end)

local function target(x: number, z: number, standing: boolean, name: string, y: number?): Combat.Target
	return { position = Vector3.new(x, y or 0, z), standing = standing, ref = name }
end

test("pickTarget: the nearest standing target in reach, sideways only", function()
	local dino = Vector3.new(0, 3, 0)
	eq(Combat.pickTarget(dino, {}, 10), nil, "nothing to bite")
	local a, b = target(8, 0, true, "tower 8"), target(5, 0, true, "player 5")
	eq((Combat.pickTarget(dino, { a, b }, 10) :: any).ref, "player 5", "nearest wins, towers and players alike")
	eq(Combat.pickTarget(dino, { a, b }, 4), nil, "out of reach")
	eq((Combat.pickTarget(dino, { a }, 8) :: any).ref, "tower 8", "exactly at reach counts")
	local trampled, dead = target(1, 0, false, "trampled tower"), target(2, 0, false, "dead player")
	eq((Combat.pickTarget(dino, { trampled, dead, a }, 10) :: any).ref, "tower 8", "trampled towers and the dead are ignored")
	eq(Combat.pickTarget(dino, { trampled, dead }, 10), nil, "only down targets: none")
	local high = target(3, 4, true, "on a ledge", 40)
	eq((Combat.pickTarget(dino, { a, high }, 10) :: any).ref, "on a ledge", "height doesn't count: 5 sideways")
	local tie1, tie2 = target(0, 6, true, "first"), target(6, 0, true, "second")
	eq((Combat.pickTarget(dino, { tie1, tie2 }, 10) :: any).ref, "first", "ties go to the earlier candidate")
end)

test("mergeMark: the stronger mark wins outright; an equal one keeps the longer time (DECISIONS #106)", function()
	local function merged(percent: number, remaining: number, newPercent: number, newSeconds: number): string
		local p, r = Combat.mergeMark(percent, remaining, newPercent, newSeconds)
		return `{p} for {r}`
	end
	-- Weaker: nothing changes, neither the strength nor the time.
	eq(merged(50, 2, 20, 3), "50 for 2", "a weaker, longer mark doesn't extend the stronger one")
	eq(merged(50, 9, 20, 3), "50 for 9", "a weaker, shorter mark doesn't cut the stronger one short")
	-- Equal: the strength stays, the longer of the two times stands.
	eq(merged(50, 2, 50, 3), "50 for 3", "an equal, longer mark extends the time")
	eq(merged(50, 5, 50, 3), "50 for 5", "an equal, shorter mark doesn't cut the time")
	-- Stronger: replaces both, even when it is shorter.
	eq(merged(20, 5, 50, 3), "50 for 3", "a stronger, shorter mark replaces strength and time")
	eq(merged(20, 2, 50, 3), "50 for 3", "a stronger, longer mark replaces strength and time")
	-- Expired (or never marked): the new mark stands, whatever its strength.
	eq(merged(0, 0, 50, 8), "50 for 8", "an unmarked dino takes the mark")
	eq(merged(50, 0, 20, 3), "20 for 3", "a mark that has just run out is gone: the weaker new one stands")
	eq(merged(50, -2, 20, 10), "20 for 10", "an expired mark is gone: the new one stands")
	eq(merged(50, -2, 50, 3), "50 for 3", "expired + equal: the new one")
	eq(merged(20, -2, 50, 3), "50 for 3", "expired + stronger: the new one")
end)

test("nearestWithin: the nearest few points in reach, nearest first, ties to the earlier", function()
	local at = Vector3.new(0, 0, 0)
	local points = { Vector3.new(9, 0, 0), Vector3.new(0, 0, 4), Vector3.new(0, 10, 0), Vector3.new(11, 0, 0), Vector3.new(4, 0, 0) }
	local function picked(reach: number, count: number): string
		return table.concat(Combat.nearestWithin(at, points, reach, count), ",")
	end
	eq(picked(10, 1), "2", "one: the nearest, the earlier of a tie")
	eq(picked(10, 2), "2,5", "two: both at 4 studs")
	eq(picked(10, 9), "2,5,1,3", "exactly at reach counts (height too); 11 studs is out")
	eq(picked(3, 2), "", "nothing in reach")
	eq(picked(10, 0), "", "no marks asked for")
	eq(#Combat.nearestWithin(at, {}, 10, 1), 0, "no other dinos")
end)
