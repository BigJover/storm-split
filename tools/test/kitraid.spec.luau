--[[
	Kit raids and kit vs armour (PLAN 10b T137b, DECISIONS #400-#402): melee and grenades hit
	rival towers under the gun's raid rule and tower-damage multiplier (never in co-op, never
	the own side, never an untouchable tower; Camo Cover still shields hunters); the Splint
	Stick stays dino-only; kit never damages flyers or armour, but its effects land on
	armoured ground dinos. Server wiring is checked by reading Server/Kit and Server/Hero.
]]
local fs = require("@lune/fs")
local Config = require(src.shared.Config)
local BattleRules = require(src.shared.BattleRules)
local Combat = require(src.shared.Combat)
local HunterKit = require(src.shared.HunterKit)

local mult = Config.Tuning.PvPTowerDamage

test("a kit hit on a rival tower = the gun's raid damage (x PvP tower damage)", function()
	ok(mult > 0, "raiding is on")
	for _, amount in { 1, 37.5, 400 } do
		local gun = BattleRules.pvpDamage(amount, 1, 2, "tower", { tower = {} })
		eq(HunterKit.vsTower(amount, 1, 2, {}), gun, `kit = gun for {amount}`)
		eq(HunterKit.vsTower(amount, 1, 2, {}), amount * mult, `x {mult}`)
	end
	eq(HunterKit.vsTower(100, 3, 1, nil), 100 * mult, "no def: still a rival tower")
end)

test("no kit raid on the own side (co-op = one side), an untouchable tower or 0 damage", function()
	eq(HunterKit.vsTower(100, 1, 1, {}), 0, "co-op / own camp")
	eq(HunterKit.vsTower(100, 2, 2, {}), 0, "own camp in a battle")
	eq(HunterKit.vsTower(100, 1, 2, { untouchable = true }), 0, "Falcon Roost / Tar Pit")
	eq(HunterKit.vsTower(0, 1, 2, {}), 0, "nothing")
end)

test("Camo Cover still shields a hunter from the kit; the Splint Stick never slows a hunter", function()
	eq(HunterKit.vsHunter(100, 1, 2, true), 0, "Camo Cover")
	ok(HunterKit.vsHunter(100, 1, 2, false) > 0, "an open rival hunter is hit")
	local stick = HunterKit.row("MEDIC")
	local p, s = HunterKit.hunterSlow(stick.meleeHunterEffect, stick.meleeHunterPercent, stick.meleeHunterSeconds)
	eq(p, 0, "Splint Stick: no hunter slow (#401)")
	eq(s, 0)
end)

test("kit vs dinos: flyers untouched, armoured ground dinos take the effect only", function()
	eq(HunterKit.dinoTouch(true, true), "none", "a flyer, even if hurtable")
	eq(HunterKit.dinoTouch(true, false), "none", "an armoured flyer")
	eq(HunterKit.dinoTouch(false, true), "hit", "a plain ground dino")
	-- An armoured ground dino the kit can't pierce: Combat says no damage, so effect only.
	local hurtable = Combat.canHurt(true, false, false, 0, 0)
	eq(hurtable, false, "kit doesn't pierce armour")
	eq(HunterKit.dinoTouch(false, hurtable), "effect", "armoured ground dino: slowed / stunk, 0 damage")
	for key in Config.Heroes do
		local row = HunterKit.row(key)
		eq(row.meleePiercesArmor == true, false, `{key} melee: no pierce (#402)`)
		eq(row.grenadePiercesArmor == true, false, `{key} grenade: no pierce (#402)`)
	end
end)

test("Server/Kit raids through Hero.raidTower and keeps armoured ground dinos as effect targets", function()
	local kit = fs.readFile("src/server/Kit.luau")
	local hero = fs.readFile("src/server/Hero.luau")
	ok(string.find(kit, "HunterKit.dinoTouch(enemy.def.flying == true, Enemies.canHurt(enemy, pierces)) ~= \"none\"", 1, true), "dinoTargets asks dinoTouch")
	ok(not string.find(kit, "not enemy.def.flying and Enemies.canHurt", 1, true), "the old armour skip is gone")
	ok(string.find(kit, "Hero.raidTower(player, tower, HunterKit.vsTower(damage, mySide, tower.side, tower.def))", 1, true), "kit raid = vsTower")
	ok(string.find(kit, "for _, tower in Towers.all() do", 1, true), "kit foes include rival towers")
	ok(string.find(hero, "Hero.raidTower(player, tower, BattleRules.pvpDamage(", 1, true), "the gun raids through the same function")
	-- The effect lands before the damage call (which deals 0 to armour it can't pierce).
	local a = string.find(kit, "Kit.affectDino(enemy, effect)\n\tEnemies.setSource", 1, true)
	ok(a ~= nil, "effect first, then Enemies.damage")
end)
