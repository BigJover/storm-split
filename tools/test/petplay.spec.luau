--[[
	Pets in play (PLAN 10d T141, DECISIONS #378/#379/#392): each species' support effect at
	each rarity, the pet only working while out with its hunter in a match, the bite guard
	(one dino bite a round, never a hunter's shot), the worth cap, Campsites, and source
	guards that no pet effect reaches an enemy hunter.

	Effect values are blank on the sheet until the Director sets them (effect off), so the
	per-rarity specs use a test row.
]]
local fs = require("@lune/fs")
local Config = require(src.shared.Config)
local Pets = require(src.shared.Pets)
local Outpost = require(src.shared.Outpost)

local MULTS = { COMMON = 1, UNCOMMON = 1.25, RARE = 1.5, EPIC = 1.75, LEGENDARY = 2, MYTHIC = 2.25 }

test("each species: one effect, scaled by rarity x1 .. x2.25; blank = off", function()
	local want = { HONKER = "spotcamo", FETCHER = "fetch", FERN_MUNCHER = "regen", SHINY_SNATCHER = "roundcash", FRILL_GUARD = "absorb" }
	for kind, effect in want do
		local row = (Config :: any).Pets[kind]
		eq(row.effect, effect, `{kind}'s effect`)
		local off, none = Pets.strength({ kind = kind, rarity = "MYTHIC" })
		eq(off, effect)
		eq(none, nil, `{kind}: blank Effect value = off until the Director sets it`)
		for rarity, mult in MULTS do
			local e, s = Pets.strength({ kind = kind, rarity = rarity }, { effect = effect, effectValue = 4 })
			eq(e, effect)
			eq(s, 4 * mult, `{kind} {rarity}`)
		end
	end
	eq(select(2, Pets.strength({ kind = "HONKER", rarity = "SHINY" }, { effect = "spotcamo", effectValue = 4 })), nil, "unknown rarity: nothing")
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
	for _, banned in { "Health.damage", "Health.pvpHit", "Health.slow", "BattleRules.pvpDamage", "Enemies." } do
		ok(not string.find(server, banned, 1, true), `Server/Pets never calls {banned}`)
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
