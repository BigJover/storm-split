--[[
	Meteor Beacon (PLAN 9i T127, DECISIONS #337/#338): the Towers row and Tuning block, every PLAN
	row (Round-19 names, #337's numbers), and the pure rules in Shared/Meteor: a 6-dino bunch beats
	2 single dinos, a boss counts 3, ground only unless Shooting Stars, ties go furthest along,
	n densest points and Scatter's segments, the splash, the biggest dino's extra breaks, craters
	(lifetime, Fire Line joins, New Ice Age once per crater), and Extinction Event firing on a boss,
	on a bunch, else at the last spawn, once per round played, never on an empty track.
]]

local Config = require(src.shared.Config)
local Meteor = require(src.shared.Meteor)
local TowerStats = require(src.shared.TowerStats)

local METEOR = Config.Towers.METEOR
local T = Config.Tuning

local function pathOf(id: string): (any, number)
	for i, path in METEOR.paths do
		if path.id == id then
			return path, i
		end
	end
	error(`no path {id}`)
end

local function stats(id: string, tier: number, picks: string?)
	local _, i = pathOf(id)
	local tiers, all = { 0, 0, 0 }, { "", "", "" }
	tiers[i], all[i] = tier, picks or ""
	return TowerStats.compute(METEOR, tiers, all)
end

local function close(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

test("the Towers row (#337): 600 cash, 600 Amber, 40 a meteor every 8 s on 6, splash 8, ground only, 150 HP", function()
	eq(METEOR.display, "Meteor Beacon")
	eq(METEOR.baseCost, 600)
	eq(METEOR.unlockCost, 600)
	eq(METEOR.baseDamage, 40)
	eq(METEOR.baseRate, 0.125)
	eq(METEOR.baseTargets, 6)
	eq(METEOR.range, 999)
	eq(METEOR.splashRadius, 8)
	eq(METEOR.hitsAir, false)
	eq(METEOR.maxHp, 150)
	eq(METEOR.untouchable, false)
end)

test("the METEOR BEACON Tuning block (#337: Extinction x 3)", function()
	eq(T.BunchRadiusStuds, 8)
	eq(T.StrikeWarningS, 1)
	eq(T.CraterRadius, 6)
	eq(T.CraterS, 5)
	eq(T.CraterBurnDPS, 10)
	eq(T.SmallMeteorX, 0.6)
	eq(T.SmallSplashX, 0.7)
	eq(T.ExtinctionMinBunch, 6)
	eq(T.ExtinctionX, 3)
	eq(T.ExtinctionBreaks, 4)
	eq(T.StarfallMeteors, 20)
	eq(T.FireLineGapStuds, 30)
	eq(T.StreakLengthStuds, 10)
end)

-- PLAN 9i's table (#337 numbers; Starfall's lever stepped 2.8 -> 3.388 by rule 7, T127).
local Y = true
local ROWS = {
	{ "Impact", 1, "", "Heavier Rock", { damageMult = 1.7 } },
	{ "Impact", 2, "", "Iron Core", { damageMult = 3.3 } },
	{ "Impact", 3, "", "Ground Zero", { damageMult = 6, sizeBreaks = 2 } },
	{ "Impact", 4, "A", "Planet Killer", { damageMult = 1.3, sizeBreaks = 3, bossMult = 2 } },
	{ "Impact", 4, "B", "Plate Cracker", { damageMult = 1.8, piercesArmor = Y } },
	{ "Impact", 4, "C", "Quick Call", { damageMult = 1.25, rateMult = 1.5 } },
	{ "Impact", 5, "A", "Extinction Event", { damageMult = 1.4, extinction = Y } },
	{ "Impact", 5, "B", "Dino Killer", { damageMult = 1.9, biggestBreaks = 2 } },
	{ "Impact", 5, "C", "Impact Winter", { damageMult = 1.9, sideSlowPercent = 30, sideSlowSeconds = 3 } },
	{ "Sky Rocks", 1, "", "Rock Chunks", { damageMult = 1.4, meteors = 2 } },
	{ "Sky Rocks", 2, "", "Twin Fall", { damageMult = 2.1, meteors = 3 } },
	{ "Sky Rocks", 3, "", "Fireball Flurry", { damageMult = 2.6, meteors = 5 } },
	{ "Sky Rocks", 4, "A", "Endless Rain", { damageMult = 1.25, meteorEvery = 4 } },
	{ "Sky Rocks", 4, "B", "Scatter Field", { damageMult = 1.75, scatter = Y } },
	{ "Sky Rocks", 4, "C", "Cinder Trail", { damageMult = 1.6, burnStreak = Y, burnDps = 20 } },
	{ "Sky Rocks", 5, "A", "Starfall", { damageMult = 3.388, starfallEvery = 15 } },
	{ "Sky Rocks", 5, "B", "Comet Tail", { damageMult = 1.7, bombingRun = Y, fieldStrikeX = 6 } },
	{ "Sky Rocks", 5, "C", "Shooting Stars", { damageMult = 1.95, hitsAir = Y } },
	{ "Aftermath", 1, "", "Hot Crater", { damageMult = 1.3, burnDps = 20 } },
	{ "Aftermath", 2, "", "Ash Cloud", { damageMult = 1.6, burnDps = 20, throwMissPercent = 30, biteMissPercent = 30 } },
	{ "Aftermath", 3, "", "Shockwave Ring", { damageMult = 2.4, burnDps = 30, throwMissPercent = 30, biteMissPercent = 30, knockback = 6 } },
	{ "Aftermath", 4, "A", "Long Burn", { craterSeconds = 8, burnDps = 45 } },
	{ "Aftermath", 4, "B", "Glass Crater", { stripsArmor = Y, burnDps = 40 } },
	{ "Aftermath", 4, "C", "Scorch Marks", { craterAmpPercent = 15, burnDps = 40 } },
	{ "Aftermath", 5, "A", "Fire Line", { fireLine = Y, burnDps = 54 } },
	{ "Aftermath", 5, "B", "Blinding Dust", { throwMissPercent = 100, biteMissPercent = 100, burnDps = 55 } },
	{ "Aftermath", 5, "C", "New Ice Age", { craterFreezeSeconds = 2, damageMult = 1.6 } },
}
local TIMERS = { meteorEvery = true, starfallEvery = true }

test("every PLAN row: name, letter and cells (T4 over T3, T5 over A4); one price a slot; no Raider option (#320)", function()
	for _, r in ROWS do
		local id, tier, letter, name, cells = r[1], r[2], r[3], r[4], r[5]
		local path = pathOf(id)
		local row = if tier <= 3 then path.tiers[tier] elseif tier == 4 then path.t4[letter] else path.t5["A" .. letter]
		local below = if tier <= 3 then nil elseif tier == 4 then path.tiers[3] else path.t4.A
		ok(row ~= nil, `{id} T{tier}{letter}`)
		eq(row.name, name, `{id} T{tier}{letter} name`)
		for field, value in cells do
			local want: any = value
			if below and string.find(field, "Mult$") then
				want = (below[field] or 1) * value
			elseif below and type(value) == "number" and not TIMERS[field] then
				want = math.max(value, below[field] or 0)
			end
			if type(want) == "number" then
				ok(close(row[field] or 0, want), `{id} T{tier}{letter} {field} = {want} (got {row[field]})`)
			else
				eq(row[field], want, `{id} T{tier}{letter} {field}`)
			end
		end
		if tier >= 4 then
			local slot = if tier == 4 then path.t4 else { A = path.t5.AA, B = path.t5.AB, C = path.t5.AC }
			eq(row.cost, slot.A.cost, `{id} T{tier}{letter}: one price a slot (#277)`)
			ok(row.pvpEffect ~= true, `{id} T{tier}{letter}: no Raider option on the beacon (#320)`)
		end
	end
	eq(stats("Sky Rocks", 5, "AB").fieldStrikeX, 6, "Comet Tail's Field strike x reaches the stats (not a coil)")
	eq(stats("Impact", 3).craterSeconds, 0, "no tier sets Crater (s): 0 = Tuning")
	eq(Meteor.craterSeconds(stats("Impact", 3)), T.CraterS)
	eq(Meteor.craterSeconds(stats("Aftermath", 4, "A")), 8)
end)

local function dinos(list: { { number } }): { Meteor.Dino }
	local out = {}
	for i, d in list do
		table.insert(out, { id = i, at = d[1], boss = d[2] == 1, flying = d[2] == 2, sizes = d[3] or 1 })
	end
	return out
end

test("densest bunch: a 6-dino bunch beats 2 single dinos; a boss counts 3; ties furthest along; empty = nil", function()
	local track = dinos({ { 10 }, { 100 }, { 300 }, { 302 }, { 303 }, { 304 }, { 305 }, { 306 } })
	eq(Meteor.densest(track, false), 306, "the bunch at 300-306 (ties: the furthest along)")
	ok(Meteor.weightAt(track, 303, false) == 6, "6 dinos in the bunch")
	-- a boss alone (3) beats two dinos together (2)
	eq(Meteor.densest(dinos({ { 50 }, { 52 }, { 200, 1 } }), false), 200, "a boss counts 3")
	eq(Meteor.densest(dinos({ { 50 }, { 52 }, { 54 }, { 200, 1 } }), false), 200, "3 = 3: ties go furthest along")
	eq(Meteor.densest({}, false), nil, "never on an empty track")
	-- prove it can fail: a single dino far ahead does not beat a bunch
	ok(Meteor.densest(dinos({ { 10 }, { 12 }, { 14 }, { 900 } }), false) ~= 900, "a lone dino ahead loses to a bunch")
end)

test("ground only unless Shooting Stars (Hits air)", function()
	local track = dinos({ { 10, 2 }, { 11, 2 }, { 12, 2 }, { 400 } })
	eq(Meteor.densest(track, false), 400, "flyers are skipped")
	eq(Meteor.densest(track, true), 12, "Shooting Stars: flyers count")
	eq(#Meteor.hits(track, 11, 8, false), 0, "the splash skips flyers")
	eq(#Meteor.hits(track, 11, 8, true), 3)
	ok(stats("Sky Rocks", 5, "AC").hitsAir and not stats("Sky Rocks", 5, "AA").hitsAir, "only Shooting Stars hits air")
end)

test("n points: the n densest bunches, Scatter's segments; the splash and its breaks", function()
	local track = dinos({ { 10 }, { 12 }, { 14 }, { 200 }, { 202 }, { 500 } })
	local p = Meteor.points(track, 2, false, 600, false)
	eq(#p, 2)
	eq(p[1], 14, "the biggest bunch first")
	eq(p[2], 202, "then the next bunch, not the same one")
	local s = Meteor.points(track, 3, true, 600, false)
	eq(#s, 3, "Scatter: one per segment with dinos")
	ok(s[1] == 14 and s[2] == 202 and s[3] == 500, "Scatter: the densest of each third")
	eq(#Meteor.points(dinos({ { 10 } }), 3, false, 600, false), 3, "fewer bunches than meteors: they repeat")
	local n, dmg, splash = Meteor.strike(stats("Sky Rocks", 3))
	eq(n, 5)
	ok(close(dmg, 40 * 2.6 * T.SmallMeteorX) and close(splash, 8 * T.SmallSplashX), "small meteors")
	local one, big = Meteor.strike(stats("Impact", 3))
	ok(one == 1 and close(big, 240), "Impact: one big meteor")
	eq(#Meteor.hits(track, 12, 8, false), 3, "every dino in the splash is hit")
	eq(Meteor.breaksFor(stats("Impact", 3), false), 2, "every dino in the splash breaks the meteor's Size breaks (#337)")
	local killer = stats("Impact", 5, "AB")
	eq(Meteor.breaksFor(killer, true), 5, "Dino Killer: the biggest breaks 2 more")
	eq(Meteor.breaksFor(killer, false), 3)
	local hit = dinos({ { 1, 0, 3 }, { 2, 0, 5 }, { 3, 0, 2 } })
	eq((Meteor.biggest(hit) :: any).id, 2, "the biggest is the one with the most sizes")
	local every, starfall = Meteor.strikeEvery(stats("Sky Rocks", 5, "AA"))
	ok(every == 15 and starfall, "Starfall replaces the strike every 15 s")
	local gap = Meteor.strikeEvery(stats("Impact", 4, "C"))
	ok(close(gap, 8 / 1.5), "Quick Call: 50% more often")
end)

test("craters: lifetime, Fire Line joins close craters, New Ice Age freezes once per crater", function()
	local s = stats("Aftermath", 5, "AA")
	local a, b, far = Meteor.crater(s, 100, 0), Meteor.crater(s, 125, 0), Meteor.crater(s, 300, 0)
	eq(a.ends, 8, "Long Burn: 8 s")
	ok(Meteor.inCrater({ a }, 104, 1, false) == a, "inside the radius")
	eq(Meteor.inCrater({ a }, 112, 1, false), nil, "outside the radius")
	eq(Meteor.inCrater({ a }, 104, 9, false), nil, "gone after its time")
	ok(Meteor.inCrater({ a, b }, 112, 1, true) ~= nil, "Fire Line: the strip between two close craters burns")
	eq(Meteor.inCrater({ a, far }, 200, 1, true), nil, "craters further apart than the gap don't join")
	eq(Meteor.inCrater({ a, b }, 112, 1, false), nil, "without Fire Line the gap doesn't burn")
	ok(Meteor.freezeOnce(a, "d1"), "first entry freezes")
	ok(not Meteor.freezeOnce(a, "d1"), "once per crater")
	ok(Meteor.freezeOnce(b, "d1"), "a new crater freezes again")
	eq(#Meteor.prune({ a, b, far }, 9), 0)
	eq(Meteor.craterBurn(stats("Impact", 1)), T.CraterBurnDPS, "blank Burn DPS = Tuning")
	eq(Meteor.craterBurn(s), 54)
end)

test("Extinction Event: on a boss, on a bunch, else at the last spawn; once per round played", function()
	local st = { fired = false }
	ok(not Meteor.extinctionNow(st, false, 3, false, 3), "a small bunch waits")
	ok(Meteor.extinctionNow(st, true, 1, false, 1), "a boss fires it")
	ok(not Meteor.extinctionNow(st, true, 9, true, 9), "once per round played")
	st.fired = false -- a new round played
	ok(Meteor.extinctionNow(st, false, T.ExtinctionMinBunch, false, 8), "a bunch of Extinction min bunch fires it")
	st.fired = false
	ok(Meteor.extinctionNow(st, false, 1, true, 1), "else the last spawn")
	st.fired = false
	ok(not Meteor.extinctionNow(st, true, 6, true, 0), "never on an empty track")
	local s = stats("Impact", 5, "AA")
	local dmg, breaks = Meteor.extinctionHit(s, true)
	ok(close(dmg, s.damage * T.ExtinctionX) and breaks == T.ExtinctionBreaks, "the bunch breaks Extinction breaks")
	local _, rest = Meteor.extinctionHit(s, false)
	eq(rest, 1, "the rest of the side breaks 1")
	ok(s.extinction and not stats("Impact", 5, "AB").extinction, "only Extinction Event")
end)
