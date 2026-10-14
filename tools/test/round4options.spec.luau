--[[
	Batch 9e (PLAN Phase 9, DECISIONS #296-#297): the B/C options of the round-4 batch (Storm
	Coil, Falcon Roost, Tar Pit, Harpoon Ballista). Each option's composed row is the build
	under it plus exactly the cells PLAN gives (x columns multiply, amounts take the higher,
	flags add, Freeze every / Sink seconds / Grounding every / Field strike every are set), on every one of the 9 builds per path; and
	the new mechanics: Field strike (Storm Front, Shared/StormCoil), Chain effects (Supercell,
	Superconductor; arc stun capped), the Falcon dive's extra hits (Raking Strike, Strafing
	Run, Shared/Falcon), Targets biggest (Heartseeker, Shared/Ballista), the T120 wirings (La
	Brea's sink, Pitch Coat's strip, bolts' mark / slow / burn) and the Raider sting on Rod
	Strike, Guard Falcons, Bog Boots and Snag Line.
]]

local Config = require(src.shared.Config)
local TowerStats = require(src.shared.TowerStats)
local TowerPerks = require(src.shared.TowerPerks)
local Upgrades = require(src.shared.Upgrades)
local StormCoil = require(src.shared.StormCoil)
local Ballista = require(src.shared.Ballista)
local TarPit = require(src.shared.TarPit)
local Combat = require(src.shared.Combat)
local Falcon = require(src.shared.Falcon)

-- PLAN 9e, cell by cell: tower key, path, tier, letter, name, cells (own step), Raider?
local MULT = {
	damageMult = true, rateMult = true, targetsMult = true, rangeMult = true, armoredMult = true, bossMult = true,
	splashMult = true, incomeMult = true, healMult = true, hunterRecoilMult = true, hunterReloadMult = true, hunterSpreadMult = true,
}
local SET = { freezeEvery = true, sinkSeconds = true, groundingEvery = true, fieldStrikeEvery = true } -- intervals: a step sets them
local OPTIONS = {
	{ "COIL", "Arc", 4, "B", "Branching Bolt", { damageMult = 1.15, arcForks = 3 } },
	{ "COIL", "Arc", 4, "C", "Chain Surge", { damageMult = 1.4, arcs = 9 } },
	{ "COIL", "Arc", 5, "B", "Storm Front", { damageMult = 1.45, fieldStrikeEvery = 8, fieldStrikeX = 0.5 } },
	{ "COIL", "Arc", 5, "C", "Supercell", { damageMult = 1.5, arcs = 14, slowPercent = 20, slowLinger = 1, chainEffects = true } },
	{ "COIL", "Charge", 4, "B", "Overcharge", { damageMult = 1.35, piercesArmor = true, stunSeconds = 0.8 } },
	{ "COIL", "Charge", 4, "C", "Static Storm", { damageMult = 1.3, piercesArmor = true, staticPercent = 30 } },
	{ "COIL", "Charge", 5, "B", "Superconductor", { damageMult = 1.85, piercesArmor = true, chainEffects = true } },
	{ "COIL", "Charge", 5, "C", "Thunderstrike", { damageMult = 2, piercesArmor = true, sizeBreaks = 2 } },
	{ "COIL", "Lightning Rod", 4, "B", "Ground Wire", { damageMult = 1.3, groundingEvery = 2 } },
	{ "COIL", "Lightning Rod", 4, "C", "Rod Strike", { damageMult = 1.3, auraRatePercent = 15, raiderSlowPercent = 20, raiderSlowSeconds = 1, raiderDamage = 8 }, true },
	{ "COIL", "Lightning Rod", 5, "B", "Lightning Shield", { damageMult = 1.3, groundingEvery = 1, auraDamagePercent = 10 } },
	{ "COIL", "Lightning Rod", 5, "C", "Thunder Drums", { damageMult = 1.3, auraRatePercent = 25 } },
	{ "FALCON", "Talons", 4, "B", "Raking Strike", { damageMult = 1.2, targetsMult = 2, piercesArmor = true } },
	{ "FALCON", "Talons", 4, "C", "Stoop Strike", { damageMult = 1.35, firstDiveX = 6, piercesArmor = true } },
	{ "FALCON", "Talons", 5, "B", "Harpy Strike", { damageMult = 2.1, sizeBreaks = 4, bossMult = 2 } },
	{ "FALCON", "Talons", 5, "C", "Hide Ripper", { damageMult = 3.2, armoredMult = 2.5 } },
	{ "FALCON", "Flock", 4, "B", "Swift Wings", { damageMult = 1.85, rateMult = 1.6 } },
	{ "FALCON", "Flock", 4, "C", "Second Flock", { damageMult = 2.7, birds = 7 } },
	{ "FALCON", "Flock", 5, "B", "Sky Hunters", { damageMult = 3.3, rangeMult = 2, birds = 12 } },
	{ "FALCON", "Flock", 5, "C", "Strafing Run", { damageMult = 1.05, lineHits = 3 } },
	{ "FALCON", "Falconer", 4, "B", "Loud Bells", { damageMult = 1.3, markPercent = 25 } },
	{ "FALCON", "Falconer", 4, "C", "Guard Falcons", { damageMult = 1.3, bossMarkPercent = 40, raiderSlowPercent = 20, raiderSlowSeconds = 1, raiderDamage = 6 }, true },
	{ "FALCON", "Falconer", 5, "B", "Royal Hood", { damageMult = 1.3, bossMarkPercent = 60 } },
	{ "FALCON", "Falconer", 5, "C", "Bell Chorus", { damageMult = 1.3, markPercent = 40 } },
	{ "TARPIT", "Deep Tar", 4, "B", "Thick Mire", { slowPercent = 55 } },
	{ "TARPIT", "Deep Tar", 4, "C", "Bog Boots", { rangeMult = 1.5, slowPercent = 45, raiderSlowPercent = 30, raiderSlowSeconds = 2 }, true },
	{ "TARPIT", "Deep Tar", 5, "B", "La Brea", { sinkSeconds = 0.05, slowPercent = 62, rangeMult = 1.15, slowLinger = 3 } },
	{ "TARPIT", "Deep Tar", 5, "C", "Black Glue", { slowPercent = 50, slowLinger = 5 } },
	{ "TARPIT", "Bubbling", 4, "B", "Boiling Splash", { rangeMult = 1.3 } },
	{ "TARPIT", "Bubbling", 4, "C", "Pitch Coat", { stripsArmor = true, burnDps = 85, burnSeconds = 1 } },
	{ "TARPIT", "Bubbling", 5, "B", "Ever-Burn", { burnSeconds = 2.75 } },
	{ "TARPIT", "Bubbling", 5, "C", "Tar Inferno", { burnDps = 120 } },
	{ "TARPIT", "Dig Site", 4, "B", "Bone Yard", { sinkCash = 28, sinkChestCash = 36 } },
	{ "TARPIT", "Dig Site", 4, "C", "Fossil Finder", { sinkCash = 15, sinkChestCash = 55 } },
	{ "TARPIT", "Dig Site", 5, "B", "Preserved Specimens", { sinkCash = 36, sinkChestCash = 40 } },
	{ "TARPIT", "Dig Site", 5, "C", "Amber Seep", { sinkCash = 25, sinkChestCash = 60 } },
	{ "BALLISTA", "Spearhead", 4, "B", "Serrated Head", { damageMult = 1.7, piercesArmor = true, markPercent = 20 } },
	{ "BALLISTA", "Spearhead", 4, "C", "Whale Lance", { damageMult = 1.6, piercesArmor = true, bossMult = 1.4 } },
	{ "BALLISTA", "Spearhead", 5, "B", "Leviathan Bolt", { damageMult = 2.5, rateMult = 1.4, sizeBreaks = 4, bossMult = 3 } },
	{ "BALLISTA", "Spearhead", 5, "C", "Heartseeker", { damageMult = 3, rateMult = 2.1, sizeBreaks = 3, targetsBiggest = true } },
	{ "BALLISTA", "Reel", 4, "B", "Tether", { damageMult = 1.3, stunSeconds = 2 } },
	{ "BALLISTA", "Reel", 4, "C", "Snag Line", { damageMult = 1.3, stunSeconds = 1.75, raiderSlowPercent = 30, raiderSlowSeconds = 3, raiderDamage = 12 }, true },
	{ "BALLISTA", "Reel", 5, "B", "Anchor Line", { damageMult = 1.3, slowPercent = 30, slowLinger = 2, slowsBosses = true } },
	{ "BALLISTA", "Reel", 5, "C", "Winch Haul", { damageMult = 1.3, knockback = 7.5 } },
	{ "BALLISTA", "Volley", 4, "B", "Wide Volley", { damageMult = 1.15, shots = 5 } },
	{ "BALLISTA", "Volley", 4, "C", "Fire Bolts", { rateMult = 1.6, burnDps = 6, burnSeconds = 3 } },
	{ "BALLISTA", "Volley", 5, "B", "Siege Battery", { damageMult = 2.4, shots = 6 } },
	{ "BALLISTA", "Volley", 5, "C", "Firestorm Volley", { damageMult = 2, rateMult = 1.8, burnDps = 12, burnSeconds = 3 } },
}
local TOWERS = { "COIL", "FALCON", "TARPIT", "BALLISTA" }

local function pathOf(key: string, id: string): (any, number)
	for i, path in Config.Towers[key].paths do
		if path.id == id then
			return path, i
		end
	end
	error(`{key} has no path {id}`)
end

local function close(a: number, b: number): boolean
	return math.abs(a - b) <= 1e-5 * math.max(1, math.abs(b))
end

-- The build under a pick: tier 3 for a T4 option, each T4 letter for a T5 option.
local function belows(path, tier: number): { [string]: any }
	if tier == 4 then
		return { [""] = Upgrades.row(path, 3) }
	end
	return { A = Upgrades.row(path, 4, "A"), B = Upgrades.row(path, 4, "B"), C = Upgrades.row(path, 4, "C") }
end

test("9e options: each row is the build under it plus PLAN's cells, nothing else (all 9 builds per path)", function()
	local seen = 0
	for _, o in OPTIONS do
		local key, id, tier, letter, name, cells, raider = o[1], o[2], o[3], o[4], o[5], o[6], o[7] == true
		local path = pathOf(key, id)
		for before, below in belows(path, tier) do
			local picks = before .. letter
			local row = Upgrades.row(path, tier, picks)
			local where = `{key} {id} {tier}{picks}`
			ok(row ~= nil and below ~= nil, `{where}: has a row`)
			eq(row.name, name, `{where}: name`)
			eq(row.option, letter, `{where}: letter`)
			eq(row.cost, Upgrades.row(path, tier, if tier == 4 then "A" else "AA").cost, `{where}: same price as A (#277)`)
			eq(row.pvpEffect == true, raider, `{where}: PvP effect`)
			for field, value in below do
				if type(value) == "number" and field ~= "cost" then
					local cell = cells[field]
					local want = if MULT[field] then value * (cell or 1)
						elseif SET[field] and cell then cell
						elseif cell then math.max(value, cell)
						else value
					ok(close(row[field], want), `{where}: {field} {row[field]} ~= {want}`)
				elseif type(value) == "boolean" and field ~= "swapsModel" and field ~= "pvpEffect" then
					eq(row[field], value or cells[field] == true, `{where}: {field}`)
				end
			end
			for field in cells do
				ok(below[field] ~= nil, `{where}: {field} is a Config column`)
			end
		end
		seen += 1
	end
	eq(seen, #OPTIONS, "every option checked")
	for _, key in TOWERS do
		for _, path in Config.Towers[key].paths do
			eq(table.concat(Upgrades.options(path, 4, ""), ""), "ABC", `{key} {path.id} T4`)
			eq(table.concat(Upgrades.options(path, 5, "C"), ""), "ABC", `{key} {path.id} T5 after C`)
		end
	end
end)

local function stats(key: string, id: string, tier: number, picks: string)
	local _, i = pathOf(key, id)
	local tiers, all = { 0, 0, 0 }, { "", "", "" }
	tiers[i], all[i] = tier, picks
	return TowerStats.compute(Config.Towers[key], tiers, all)
end

test("9e wirings reach the stats: Storm Front, Chain effects, Thunderstrike, Raking Strike, Strafing Run", function()
	for _, before in { "A", "B", "C" } do
		local front = stats("COIL", "Arc", 5, before .. "B")
		ok(front.fieldStrikeEvery == 8 and front.fieldStrikeX == 0.5, `Storm Front after {before}: every 8 s at x0.5`)
		eq(stats("COIL", "Arc", 5, before .. "A").fieldStrikeEvery, 0, `Power Grid after {before}: no field strike`)
		local cell = stats("COIL", "Arc", 5, before .. "C")
		ok(cell.chainEffects and cell.slowPercent == 20 and cell.slowLinger == 1 and cell.arcs == 14, `Supercell after {before}`)
		local sc = stats("COIL", "Charge", 5, before .. "B")
		ok(sc.chainEffects and sc.stunSeconds > 0 and not sc.stunsBosses, `Superconductor after {before}: chain stun, never a boss`)
		eq(stats("COIL", "Charge", 5, before .. "C").sizeBreaks, 2, `Thunderstrike after {before}: breaks 2`)
	end
	eq(stats("COIL", "Charge", 4, "B").stunSeconds, 0.8, "Overcharge stuns 0.8 s")
	ok(not stats("COIL", "Charge", 4, "B").chainEffects, "Overcharge: the first dino only")
	eq(stats("FALCON", "Talons", 4, "B").targets, 2, "Raking Strike: two dinos per dive")
	eq(stats("FALCON", "Flock", 5, "AC").lineHits, 3, "Strafing Run: a line of 3")
	local sky = stats("FALCON", "Flock", 5, "AB")
	ok(sky.birds == 12 and close(sky.range, stats("FALCON", "Flock", 4, "A").range * 2), "Sky Hunters: 12 birds, twice as far")
	eq(stats("FALCON", "Falconer", 5, "AB").bossMarkPercent, 60, "Royal Hood boss mark")
	-- Grounding every is an interval: Ground Wire's 2 s beats Grounding Spike's 4 s, and rides the T5 A/C.
	eq(stats("COIL", "Lightning Rod", 3, "").groundingEvery, 4, "Grounding Spike every 4 s")
	eq(stats("COIL", "Lightning Rod", 4, "B").groundingEvery, 2, "Ground Wire every 2 s")
	eq(stats("COIL", "Lightning Rod", 5, "BA").groundingEvery, 2, "Ground Wire then Lightning Rodeo: still 2 s")
	eq(stats("COIL", "Lightning Rod", 5, "AB").groundingEvery, 1, "Lightning Shield every 1 s")
	eq(stats("COIL", "Lightning Rod", 5, "AC").groundingEvery, 4, "Thunder Drums keeps Grounding Spike's 4 s")
	-- A non-coil never field-strikes or chains (the exporter refuses those columns elsewhere).
	local falcon = stats("FALCON", "Talons", 5, "AA")
	ok(falcon.fieldStrikeEvery == 0 and not falcon.chainEffects, "a roost: no field strike, no chain effects")
end)

test("Field strike: every dino on the coil's side's field, fliers too; armour only with pierce (or bare)", function()
	local dinos: { StormCoil.FieldDino } = {
		{ side = 1, flying = false, armored = false, bare = false }, -- far outside any range: still hit
		{ side = 1, flying = true, armored = false, bare = false },
		{ side = 1, flying = false, armored = true, bare = false },
		{ side = 1, flying = false, armored = true, bare = true }, -- stripped
		{ side = 2, flying = false, armored = false, bare = false }, -- the rival camp's
	}
	eq(table.concat(StormCoil.fieldTargets(dinos, 1, false), ","), "1,2,4", "no pierce: plain, flier and the stripped one")
	eq(table.concat(StormCoil.fieldTargets(dinos, 1, true), ","), "1,2,3,4", "pierce: every own-side dino")
	eq(table.concat(StormCoil.fieldTargets(dinos, 2, true), ","), "5", "side 2's coil: only side 2's dino")
	-- Every 8 s, carrying the overshoot; two coils keep their own timers.
	local t, fired, fires = 0, false, 0
	for _ = 1, 170 do
		t, fired = StormCoil.fieldTick(t, 0.1, 8)
		fires += if fired then 1 else 0
	end
	eq(fires, 2, "17 s: two strikes")
	local a, fa = StormCoil.fieldTick(7.95, 0.1, 8)
	local b, fb = StormCoil.fieldTick(0, 0.1, 8)
	ok(fa and not fb and close(a, 0.05) and close(b, 0.1), "each coil fires on its own timer")
	local z, fz = StormCoil.fieldTick(5, 1, 0)
	ok(z == 0 and not fz, "no Field strike: never fires")
	-- The game calls it: Server/Towers steps every coil's field strike.
	local towers = require("@lune/fs").readFile("src/server/Towers.luau")
	ok(towers:find("StormCoil.fieldTargets(dinos, tower.side, piercing(tower))", 1, true) ~= nil, "Towers picks the field strike's dinos with fieldTargets")
	ok(towers:find("stepField(tower, dt, own)", 1, true) ~= nil, "Towers steps each coil's field strike")
end)

test("Chain effects: the first dino keeps its stun, arcs get it capped at Chain stun cap (s); slow on every link", function()
	local cap = Config.Tuning.ChainStunCapS
	eq(cap, 0.3, "Tuning Chain stun cap (s) seed")
	eq(StormCoil.linkStun(0, 0.8, true), 0.8, "first dino: full stun")
	eq(StormCoil.linkStun(1, 0.8, true), cap, "an arc: capped")
	eq(StormCoil.linkStun(5, 0.2, true), 0.2, "a short stun stays under the cap")
	eq(StormCoil.linkStun(1, 0.8, false), 0, "no Chain effects: arcs don't stun (Thunderclap, Overcharge)")
	eq(StormCoil.linkStun(0, 0, true), 0, "no stun: nothing")
	ok(StormCoil.linkSlows(0, false) and not StormCoil.linkSlows(2, false), "no Chain effects: the slow lands on the first dino only")
	ok(StormCoil.linkSlows(3, true), "Chain effects: every link is slowed")
	local towers = require("@lune/fs").readFile("src/server/Towers.luau")
	ok(towers:find("StormCoil.linkStun(link.hop, stats.stunSeconds, stats.chainEffects), stats.stunsBosses)", 1, true) ~= nil, "fireChain stuns each link by linkStun, bosses only if the build stuns bosses")
end)

test("Falcon dives: Raking Strike also hits the nearest other dino; Strafing Run the 2 right behind", function()
	local reach = Config.Tuning.LinePierceReach
	local c: { Falcon.Candidate } = {
		{ position = Vector3.new(0, 0, 0), distance = 100 }, -- the struck dino
		{ position = Vector3.new(9, 0, 0), distance = 100 - reach / 2 },
		{ position = Vector3.new(2, 0, 0), distance = 104 }, -- nearest, but ahead on the track
		{ position = Vector3.new(30, 0, 0), distance = 100 - reach / 4 },
		{ position = Vector3.new(5, 0, 0), distance = 100 - reach * 2 }, -- out of line reach
	}
	local extra, line = Falcon.extraHits(c, 1, 2, 1)
	ok(#extra == 1 and extra[1] == 3 and not line, "Raking Strike: one more, the nearest (breaks 1)")
	extra, line = Falcon.extraHits(c, 1, 1, 3)
	ok(#extra == 2 and extra[1] == 4 and extra[2] == 2 and line, "Strafing Run: the 2 right behind, nearest first, with the dive's breaks")
	extra = Falcon.extraHits(c, 1, 1, 1)
	eq(#extra, 0, "a plain dive hits one dino")
	extra = Falcon.extraHits({ c[1] }, 1, 2, 1)
	eq(#extra, 0, "nobody beside: just the one")
end)

-- A Raider tower as TowerPerks sees it.
local function source(side: number, s): TowerPerks.Source
	return { side = side, standing = true, covers = true, stats = s }
end

test("Rod Strike / Guard Falcons / Bog Boots / Snag Line: sting enemy hunters at x0.5 in battles; their dino part carries co-op", function()
	for _, r in { { "COIL", "Lightning Rod", 8, 20, 1 }, { "FALCON", "Falconer", 6, 20, 1 }, { "TARPIT", "Deep Tar", 0, 30, 2 }, { "BALLISTA", "Reel", 12, 30, 3 } } do
		local key, id, damage, slow, seconds = r[1], r[2], r[3], r[4], r[5]
		local s = stats(key, id, 4, "C")
		local sting = TowerPerks.sting({ source(1, s) }, 1, 2, false, nil, 100)
		ok(sting ~= nil and sting.damage == damage * 0.5 and sting.slowPercent == slow and sting.slowSeconds == seconds, `{key} 4C stings x0.5`)
		eq(TowerPerks.sting({ source(1, s) }, 1, 2, true, nil, 100), nil, `{key} 4C: nothing through Camo Cover`)
		eq(TowerPerks.sting({ source(1, s) }, 1, 1, false, nil, 100), nil, `{key} 4C: nothing in co-op / on a teammate`)
		for _, picks in { "C", "CA", "CB", "CC" } do
			local b = stats(key, id, if #picks == 1 then 4 else 5, picks)
			ok(b.raiderDamage == damage and b.raiderSlowPercent == slow, `{key} {id} {picks}: the sting rides every T5 after it`)
		end
	end
	-- The dino part (co-op): Rod Strike's rate aura, Guard Falcons' boss mark, on every build.
	for _, picks in { "C", "CA", "CB", "CC" } do
		ok(stats("COIL", "Lightning Rod", if #picks == 1 then 4 else 5, picks).auraRatePercent >= 15, `Rod Strike {picks}: towers in range fire faster`)
		ok(stats("FALCON", "Falconer", if #picks == 1 then 4 else 5, picks).bossMarkPercent >= 40, `Guard Falcons {picks}: bosses marked`)
		local tier = if #picks == 1 then 4 else 5
		local bog = stats("TARPIT", "Deep Tar", tier, picks)
		ok(bog.slowPercent >= 45 and bog.range >= stats("TARPIT", "Deep Tar", 3, "").range * 1.5 - 1e-6, `Bog Boots {picks}: a longer, slower pool`)
		ok(stats("BALLISTA", "Reel", tier, picks).stunSeconds >= 1.75, `Snag Line {picks}: holds dinos 1.75 s`)
	end
	local stinging = 0
	for _, key in TOWERS do
		for _, path in Config.Towers[key].paths do
			for _, row in path.t4 do
				stinging += if (row.raiderSlowPercent or 0) > 0 or (row.raiderDamage or 0) > 0 then 1 else 0
			end
			for picks, row in path.t5 do
				ok((row.raiderSlowPercent or 0) <= 30 and (row.raiderSlowSeconds or 0) <= 3, `{key} {path.id} {picks}: sting within #284`)
			end
		end
	end
	eq(stinging, 4, "Rod Strike, Guard Falcons, Bog Boots and Snag Line are these towers' only T4 stings")
end)

test("T120 wirings reach the stats: Heartseeker, La Brea, Pitch Coat, Anchor Line, Winch Haul, Serrated Head, Fire Bolts", function()
	for _, before in { "A", "B", "C" } do
		ok(stats("BALLISTA", "Spearhead", 5, before .. "C").targetsBiggest, `Heartseeker after {before}: targets biggest`)
		ok(not stats("BALLISTA", "Spearhead", 5, before .. "B").targetsBiggest, `Leviathan Bolt after {before}: furthest along`)
		eq(stats("TARPIT", "Deep Tar", 5, before .. "B").sinkSeconds, 0.05, `La Brea after {before}: sinks at once`)
		local anchor = stats("BALLISTA", "Reel", 5, before .. "B")
		ok(anchor.slowPercent == 30 and anchor.slowLinger == 2 and anchor.slowsBosses, `Anchor Line after {before}: 30% for 2 s, bosses too`)
		eq(stats("BALLISTA", "Reel", 5, before .. "C").knockback, 7.5, `Winch Haul after {before}: 7.5 studs`)
	end
	eq(stats("TARPIT", "Deep Tar", 3, "").sinkSeconds, 0.5, "Fast Sink 0.5 s")
	ok(stats("TARPIT", "Bubbling", 4, "C").stripsArmor, "Pitch Coat strips armour")
	eq(stats("BALLISTA", "Spearhead", 4, "B").markPercent, 20, "Serrated Head marks 20%")
	local fire = stats("BALLISTA", "Volley", 4, "C")
	ok(fire.burnDps == 6 and fire.burnSeconds == 3, "Fire Bolts burn 6/s for 3 s")
end)

test("Targets biggest: Heartseeker's bolt flies at the dino with the most HP in range", function()
	local distances = { 50, 90, 70 } -- the second is furthest along
	local hps = { 400, 20, 900 } -- the third is biggest
	eq(Ballista.volley(Ballista.aimKeys(distances, hps, false), 1)[1], 2, "plain: the furthest along")
	eq(Ballista.volley(Ballista.aimKeys(distances, hps, true), 1)[1], 3, "Targets biggest: the most HP")
	eq(table.concat(Ballista.volley(Ballista.aimKeys(distances, hps, true), 3), ","), "3,1,2", "a volley: biggest first")
	local towers = require("@lune/fs").readFile("src/server/Towers.luau")
	ok(towers:find("Ballista.volley(Ballista.aimKeys(distances, hps, stats.targetsBiggest)", 1, true) ~= nil, "fireBallista aims by aimKeys")
end)

test("La Brea sinks a last-size dino at once; Pitch Coat strips armour in the pool; bolts mark, slow and burn", function()
	local frame = 1 / 60
	ok(TarPit.sinks(1, false, false, frame * 3, 0.05), "La Brea: a last-size dino sinks within a few frames")
	ok(not TarPit.sinks(1, false, false, frame * 3, 0.5), "Fast Sink alone: not yet")
	ok(not TarPit.sinks(1, true, false, 5, 0.05), "never a boss")
	-- A stripped armoured dino can be hurt by anyone for Strip (s) (9c's generic strip).
	ok(Combat.canHurt(true, false, false, 10 + (Config.Tuning.StripS or 0), 10.5), "stripped: hurt without pierce")
	local towers = require("@lune/fs").readFile("src/server/Towers.luau")
	ok(towers:find("if stats.stripsArmor then\n%s*Enemies.strip%(enemy, tuning.StripS or 0%)") ~= nil, "stepTar strips a dino in a Pitch Coat pool")
	ok(towers:find("affectsBosses = stats.slowsBosses", towers:find("local function fireBallista", 1, true), true) ~= nil, "bolts slow bosses only with Slows bosses")
	local ballista = towers:sub(towers:find("local function fireBallista", 1, true), towers:find("local function stepTow", 1, true))
	ok(ballista:find("Enemies.mark(enemy, stats.markPercent", 1, true) ~= nil, "bolts mark what they hit")
	ok(ballista:find("Enemies.chill(enemy, slow)", 1, true) ~= nil, "bolts slow what they hit")
	ok(ballista:find("addBurn(tower, target)", 1, true) ~= nil, "bolts leave a burning patch")
	ok(towers:find("tower.def.chains or tower.def.harpoons or tower.def.onTrack", 1, true) ~= nil, "a pit, coil or ballista never chills in a ring")
end)
