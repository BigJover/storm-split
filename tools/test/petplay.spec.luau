--[[
	Pets in play (PLAN 10d T141, DECISIONS #378/#379/#392): each species' support effect at
	each rarity, the pet only working while out with its hunter in a match, the bite guard
	(one dino bite a round, never a hunter's shot), the worth cap, Campsites, and source
	guards that no pet effect reaches an enemy hunter.

	Effect values and Worth refs are the Director's (T141b, #408); the per-rarity specs also
	use a test row. The Honker's honk (#407) has its own specs below.
]]
local fs = require("@lune/fs")
local Config = require(src.shared.Config)
local Pets = require(src.shared.Pets)
local Outpost = require(src.shared.Outpost)

local MULTS = { COMMON = 1, UNCOMMON = 1.25, RARE = 1.5, EPIC = 1.75, LEGENDARY = 2, MYTHIC = 2.25 }

test("each species: one effect, scaled by rarity x1 .. x2.25; blank = off", function()
	local want = { HONKER = "honk", FETCHER = "fetch", FERN_MUNCHER = "regen", SHINY_SNATCHER = "roundcash", FRILL_GUARD = "absorb" }
	-- #408: Common value / Worth ref; Mythic = x2.25, every Mythic worth <= the 40 % cap.
	local values = { HONKER = { 5, 33 }, FETCHER = { 4, 25 }, FERN_MUNCHER = { 0.2, 3 }, SHINY_SNATCHER = { 8, 60 }, FRILL_GUARD = { 40, 250 } }
	for kind, effect in want do
		local row = (Config :: any).Pets[kind]
		eq(row.effect, effect, `{kind}'s effect`)
		eq(row.effectValue, values[kind][1], `{kind}'s Common value`)
		eq(row.worthRef, values[kind][2], `{kind}'s Worth ref`)
		local e, mythic = Pets.strength({ kind = kind, rarity = "MYTHIC" })
		eq(e, effect)
		near(mythic :: number, values[kind][1] * 2.25, `{kind} Mythic`, 1e-9)
		ok(100 * (mythic :: number) / row.worthRef <= Config.Tuning.MasteryPerkWorthCap, `{kind} Mythic worth <= the cap`)
		local off, none = Pets.strength({ kind = kind, rarity = "MYTHIC" }, { effect = effect, effectValue = nil })
		eq(off, effect)
		eq(none, nil, `{kind}: a blank Effect value = off`)
		for rarity, mult in MULTS do
			local e, s = Pets.strength({ kind = kind, rarity = rarity }, { effect = effect, effectValue = 4 })
			eq(e, effect)
			eq(s, 4 * mult, `{kind} {rarity}`)
		end
	end
	eq(select(2, Pets.strength({ kind = "HONKER", rarity = "SHINY" }, { effect = "honk", effectValue = 4 })), nil, "unknown rarity: nothing")
end)

test("the effect rules: regen per second, one bite a round, whole round cash, fetch reach", function()
	eq(Pets.heal(2.25, 0.5), 1.125, "Mythic 1 HP/s for half a second")
	eq(Pets.heal(nil, 1), 0, "off")
	local left, used = Pets.absorb(40, 50, false)
	eq(left, 30, "takes 40 % of the first bite")
	eq(used, true)
	eq(select(1, Pets.absorb(40, 50, true)), 50, "second bite this round: all of it lands")
	eq(select(1, Pets.absorb(225, 50, false)), 0, "never more than the whole bite")
	eq(select(1, Pets.absorb(nil, 50, false)), 50, "off")
	eq(Pets.roundCash(37.5), 37, "whole cash")
	eq(Pets.roundCash(nil), 0)
	eq(Pets.fetchReach(18), 18)
	eq(Pets.fetchReach(nil), 0)
end)

test("in play only out with its hunter in a match: not in camp, the Lobby, out or fallen", function()
	ok(Pets.inPlay("Playing", false, false, true))
	ok(Pets.inPlay("Building", false, false, true))
	ok(not Pets.inPlay("Lobby", false, false, true), "Lobby")
	ok(not Pets.inPlay("Playing", true, false, true), "in the Hunters' Outpost")
	ok(not Pets.inPlay("Playing", false, true, true), "out of the battle")
	ok(not Pets.inPlay("Playing", false, false, false), "fallen: it ran back to camp")
	ok(not Pets.inPlay(nil, false, false, true))
	eq(Pets.downLine({ kind = "HONKER" }), "Your Honker ran back to camp — it returns when you do.")
end)

test("worth cap: the exporter measures Mythic worth against the mastery-perk cap", function()
	local exporter = fs.readFile("tools/export_constants.py")
	ok(string.find(exporter, "Mythic worth {worth:g}% is above the Mastery perk worth cap", 1, true), "validate_pets refuses past the cap (doctested)")
	ok(string.find(exporter, "validate_pets(data, problems, notes)", 1, true), "and runs on every export")
	ok(Config.Tuning.MasteryPerkWorthCap > 0)
end)

test("Campsites: each arrival gets the lowest free one; none past 10", function()
	local taken = {}
	for i = 1, Outpost.CAMPSITES do
		local got = Outpost.assignCampsite(taken)
		eq(got, i)
		taken[got :: number] = true
	end
	eq(Outpost.assignCampsite(taken), nil, "all 10 taken")
	taken[4] = nil
	eq(Outpost.assignCampsite(taken), 4, "a leaver's Campsite is reused")
end)

test("PvP guards: a pet never touches an enemy hunter, is never a target, works only for its own side", function()
	local server = fs.readFile("src/server/Pets.luau")
	local health = fs.readFile("src/server/Health.luau")
	local attacks = fs.readFile("src/server/DinoAttacks.luau")
	local airdrops = fs.readFile("src/server/Airdrops.luau")
	for _, banned in { "Health.damage", "Health.pvpHit", "Health.slow", "BattleRules.pvpDamage", "Enemies.mark", "Enemies.damage" } do
		ok(not string.find(server, banned, 1, true), `Server/Pets never calls {banned}`)
	end
	for call in string.gmatch(server, "Enemies%.(%w+)") do
		eq(call, "getLive", "Server/Pets only reads the dino list (the honk picks a dino; Hero/Kit deal the damage)")
	end
	ok(string.find(server, "p.CanQuery = false", 1, true) and string.find(server, "p.CanTouch = false", 1, true) and string.find(server, "p.CanCollide = false", 1, true), "pet parts can't be hit, touched or bumped")
	ok(string.find(health, "if source and source.bite and biteGuard then", 1, true), "only a dino bite reaches the Frill Guard")
	ok(string.find(health, "local dealt = Health.damage(player, amount, nil)", 1, true), "a hunter's shot passes no source")
	local _, bites = string.gsub(attacks, "bite = true", "")
	eq(bites, 1, "only the melee bite is marked a bite (throws aren't)")
	ok(string.find(airdrops, 'if part.Name == "AirdropChest" then math.max(reach, fetch) else reach', 1, true), "Fetcher reach is for chests only")
	ok(string.find(airdrops, "if taken or not onSide(player, side) then", 1, true), "and a chest still checks its side")
	ok(string.find(server, "Economy.earnFor(side, cash)", 1, true), "round cash goes to the hunter's own side")
	ok(string.find(fs.readFile("src/server/Battle.luau"), "Pets.roundCleared(side, huntersOf(side))", 1, true), "battles: each cleared side's own hunters")
	ok(string.find(fs.readFile("src/server/Main.server.luau"), "Pets.roundCleared(1, hunters())", 1, true), "co-op: side 1")
	ok(string.find(server, "local wasOut = followers[player] ~= nil and player:GetAttribute(\"InOutpost\") ~= true", 1, true), "dies with its hunter in a match")
end)

local function dino(boss: boolean, hp: number, distance: number)
	return { dino = true, boss = boss, hp = hp, distance = distance }
end

test("honk target (#407): nearest boss in reach, else most HP left; never a hunter", function()
	eq(Config.Tuning.HonkEveryS, 10)
	eq(Config.Tuning.HonkMarkS, 3)
	eq(Config.Tuning.HonkReachStuds, 40)
	eq(Pets.honkTarget({ dino(false, 900, 5), dino(true, 100, 30), dino(true, 500, 20) }), 3, "the nearest boss, over a bigger plain dino")
	eq(Pets.honkTarget({ dino(true, 5000, 41), dino(false, 50, 10), dino(false, 80, 39) }), 3, "a boss out of reach: the most HP left in reach")
	eq(Pets.honkTarget({ dino(false, 80, 30), dino(false, 80, 12) }), 2, "a tie on HP: the nearer")
	eq(Pets.honkTarget({ dino(false, 80, 40) }), 1, "40 studs is in reach")
	eq(Pets.honkTarget({ dino(false, 80, 40.5), dino(true, 80, 60) }), nil, "nothing in reach: no honk")
	eq(Pets.honkTarget({ { dino = false, boss = true, hp = 100, distance = 1 }, dino(false, 10, 30) }), 2, "a hunter is never honked")
	eq(Pets.honkTarget({ { dino = false, boss = false, hp = 100, distance = 1 } }), nil, "only hunters near: no honk")
	eq(Pets.honkTarget({ dino(true, 0, 2), dino(false, 10, 30) }), 2, "a dino with no HP left isn't picked")
end)

test("honk timing and bonus (#407): every 10 s, 3 s mark, own hunter only, off when down", function()
	eq(Pets.honkReady(nil, 100), true, "the first honk is ready at once")
	eq(Pets.honkReady(100, 109.9), false, "not before 10 s")
	eq(Pets.honkReady(100, 110), true, "every 10 s")
	local hunter, rival, target, other = {}, {}, {}, {}
	local honk = Pets.honk(hunter, target, 100)
	eq(honk.untilAt, 103, "marked 3 s")
	local mythic = select(2, Pets.strength({ kind = "HONKER", rarity = "MYTHIC" })) :: number
	near(mythic, 11.25, "Mythic Honker 11.25 %", 1e-9)
	near(Pets.honkX(mythic, honk, hunter, target, 102.9), 1.1125, "its own hunter's hit on the honked dino", 1e-9)
	eq(Pets.honkX(5, honk, hunter, target, 100), 1.05, "Common +5 %")
	eq(Pets.honkX(5, honk, hunter, target, 103), 1, "the mark is over after 3 s")
	eq(Pets.honkX(5, honk, rival, target, 101), 1, "anyone else's hit: no bonus (owner only)")
	eq(Pets.honkX(5, honk, hunter, other, 101), 1, "another dino: no bonus")
	eq(Pets.honkX(nil, honk, hunter, target, 101), 1, "its hunter down / in camp (effect off): no bonus")
	eq(Pets.honkX(5, nil, hunter, target, 101), 1, "no honk yet: no bonus")
end)

test("honk wiring: gun, melee and grenade only; dinos of its hunter's side; not a tower or dart mark", function()
	local server = fs.readFile("src/server/Pets.luau")
	local hero = fs.readFile("src/server/Hero.luau")
	local kit = fs.readFile("src/server/Kit.luau")
	ok(string.find(hero, "Enemies.damage(enemy, damage * Hero.petBonus(player, enemy), stats.piercesArmor, breaks)", 1, true), "a gun round on its target")
	ok(string.find(hero, "Enemies.damage(other, damage * Hero.petBonus(player, other), stats.piercesArmor)", 1, true), "a gun round's splash")
	ok(string.find(kit, "Enemies.damage(enemy, damage * Hero.petBonus(player, enemy), pierces, HunterKit.BREAKS)", 1, true), "melee and grenade (Kit.hitDino)")
	local _, uses = string.gsub(hero .. kit, "%* Hero%.petBonus%(player", "")
	eq(uses, 3, "nowhere else (no ability, tower, burn or hunter hit)")
	for _, file in { "Towers.luau", "Health.luau", "Hazards.luau" } do
		ok(not string.find(fs.readFile("src/server/" .. file), "petBonus", 1, true), `{file} never reads the honk`)
	end
	ok(string.find(server, 'BattleRules.ownDinos(Enemies.getLive(), side, "hunter")', 1, true), "candidates: its hunter's own side's dinos")
	ok(string.find(server, "dino = true,", 1, true), "only dinos are candidates")
	ok(string.find(server, "clearHonk(player) -- off when its hunter is down, in camp or not in a match", 1, true), "off when down or in camp (effectOf is nil then)")
	ok(string.find(server, "clearHonk(player) -- its hunter fell or left the match", 1, true), "a fallen hunter's honk ends")
	ok(string.find(server, 'PetRules.honkX(if effect == "honk" then strength else nil, honks[player], player, enemy, os.clock())', 1, true), "the bonus asks the honk's own owner, live")
end)
