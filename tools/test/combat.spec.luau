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
