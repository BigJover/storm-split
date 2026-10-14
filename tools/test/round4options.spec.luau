--[[
	Batch 9e (PLAN Phase 9, DECISIONS #296-#297): the B/C options of the round-4 batch (Storm
	Coil, Falcon Roost, Tar Pit, Harpoon Ballista). Each option's composed row is the build
	under it plus exactly the cells PLAN gives (x columns multiply, amounts take the higher,
	flags add, Freeze every / Sink seconds / Grounding every / Field strike every are set), on every one of the 9 builds per path; and
	the new mechanics: Field strike (Storm Front, Shared/StormCoil), Chain effects (Supercell,
	Superconductor; arc stun capped), the Falcon dive's extra hits (Raking Strike, Strafing
	Run, Shared/Falcon), and the Raider sting on Rod Strike / Guard Falcons.
]]

local Config = require(src.shared.Config)
local TowerStats = require(src.shared.TowerStats)
local TowerPerks = require(src.shared.TowerPerks)
local Upgrades = require(src.shared.Upgrades)
local StormCoil = require(src.shared.StormCoil)
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
}
local TOWERS = { "COIL", "FALCON" }

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

test("Rod Strike / Guard Falcons: sting enemy hunters at x0.5 in battles; their dino part carries co-op", function()
	for _, r in { { "COIL", "Lightning Rod", 8, 20, 1 }, { "FALCON", "Falconer", 6, 20, 1 } } do
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
	eq(stinging, 2, "Rod Strike and Guard Falcons are these towers' only T4 stings")
end)
