--[[
	Harpoon Ballista (PLAN T66, UPGRADES.md): the volley's spread and Chain Harpoons' pairs,
	Skewer's line, Tow Line's pick, the boss knockback rule (only Tow Line moves a boss),
	and the sheet's tiers.
]]

local fs = require("@lune/fs")

local Ballista = require(src.shared.Ballista)
local Config = require(src.shared.Config)
local TowerStats = require(src.shared.TowerStats)

local BALLISTA = Config.Towers.BALLISTA
local T = Config.Tuning

local function at(pathIndex: number, tier: number)
	local tiers = { 0, 0, 0 }
	tiers[pathIndex] = tier
	return TowerStats.compute(BALLISTA, tiers)
end

local function list(t: { number }): string
	local parts = {}
	for _, v in t do
		table.insert(parts, tostring(v))
	end
	return table.concat(parts, ",")
end

test("the Tuning levers are the seeds", function()
	eq(T.TowLineEvery, 15)
	eq(T.TowLinePull, 10)
	eq(T.BoltWidth, 3)
end)

test("the tower: 600 cash, 300 Amber, 12 x 0.4/s, 24 studs, air, damageable, harpoons (#191)", function()
	eq(BALLISTA.display, "Harpoon Ballista")
	eq(BALLISTA.baseCost, 600)
	eq(BALLISTA.unlockCost, 300)
	eq(BALLISTA.baseDamage, 12)
	eq(BALLISTA.baseRate, 0.4)
	eq(BALLISTA.range, 24)
	eq(BALLISTA.hitsAir, true)
	eq(BALLISTA.untouchable, false)
	eq(BALLISTA.chains, false)
	eq(BALLISTA.birds, 0)
	eq(BALLISTA.harpoons, true)
	for key, def in Config.Towers do
		eq(def.harpoons, key == "BALLISTA", `{key} has harpoons`)
		if key ~= "BALLISTA" then
			eq(def.baseDamage < BALLISTA.baseDamage, true, `{key}: the Ballista is the heaviest single hit`)
		end
	end
	local base = TowerStats.compute(BALLISTA, { 0, 0, 0 })
	eq(base.sizeBreaks, 1, "breaks 1 at tier 0")
	eq(base.shots, 1, "one bolt")
	eq(base.piercesArmor, false, "no armour until Great Harpoon")
	eq(base.skewer or base.towLine or base.chainHarpoons, false, "no tier-5 ability")
end)

test("the paths and names are TOWERS_NEXT's Final names", function()
	local names = {
		Spearhead = { "Steel Head", "Saw Tip", "Crusher Bolt", "Great Harpoon", "Skewer" },
		Reel = { "Rope Line", "Winch", "Pin Down", "Reel In", "Tow Line" },
		Volley = { "Twin Bolts", "Fast Crank", "Spread Volley", "Steam Crank", "Chain Harpoons" },
	}
	eq(#BALLISTA.paths, 3)
	for i, id in { "Spearhead", "Reel", "Volley" } do
		eq(BALLISTA.paths[i].id, id)
		for tier, name in names[id] do
			eq(BALLISTA.paths[i].tiers[tier].name, name, `{id} T{tier}`)
		end
	end
end)

test("Spearhead: breaks 1/1/2/3/3, armour from Great Harpoon, Skewer at tier 5 only", function()
	local breaks, pierce, skewer = {}, {}, {}
	for tier = 1, 5 do
		local s = at(1, tier)
		table.insert(breaks, s.sizeBreaks)
		table.insert(pierce, if s.piercesArmor then 1 else 0)
		table.insert(skewer, if s.skewer then 1 else 0)
		ok(s.damage > at(1, tier - 1).damage, `T{tier} hits harder than T{tier - 1}`)
	end
	eq(list(breaks), "1,1,2,3,3", "Crusher Bolt 2, Great Harpoon 3, Skewer keeps 3 (#149)")
	eq(list(pierce), "0,0,0,1,1")
	eq(list(skewer), "0,0,0,0,1")
end)

test("Reel: Pin Down holds 1s (not bosses), Reel In 6 studs, Tow Line at tier 5", function()
	local stun, knock, tow = {}, {}, {}
	for tier = 1, 5 do
		local s = at(2, tier)
		table.insert(stun, s.stunSeconds)
		table.insert(knock, s.knockback)
		table.insert(tow, if s.towLine then 1 else 0)
		eq(s.stunsBosses, false, `T{tier}: never holds a boss`)
	end
	eq(list(stun), "0,0,1,1,1")
	eq(list(knock), "0,0,0,6,6")
	eq(list(tow), "0,0,0,0,1")
end)

test("Volley: 2/2/3/3/4 bolts, Steam Crank fires twice as fast, Chain Harpoons at tier 5", function()
	local shots, chain = {}, {}
	for tier = 1, 5 do
		local s = at(3, tier)
		table.insert(shots, s.shots)
		table.insert(chain, if s.chainHarpoons then 1 else 0)
	end
	eq(list(shots), "2,2,3,3,4", "Spread Volley 3; two linked pairs at tier 5")
	eq(list(chain), "0,0,0,0,1")
	near(at(3, 4).rate, 2 * at(3, 3).rate, "Steam Crank: twice Spread Volley's rate")
	eq(#Ballista.pairs(at(3, 5).shots), 2, "two chains a volley")
end)

test("harpoon abilities only on a tower with harpoons", function()
	for key, def in Config.Towers do
		if not def.harpoons then
			local tiers = {}
			for i in def.paths do
				tiers[i] = #def.paths[i].tiers
			end
			local s = TowerStats.compute(def, tiers)
			eq(s.skewer or s.towLine or s.chainHarpoons, false, key)
		end
	end
	-- The same tiers on a copy without harpoons: TowerStats turns them off.
	local copy = table.clone(BALLISTA)
	copy.harpoons = false
	for i, tier in { { 1, 5 }, { 2, 5 }, { 3, 5 } } do
		local tiers = { 0, 0, 0 }
		tiers[tier[1]] = tier[2]
		local s = TowerStats.compute(copy, tiers)
		eq(s.skewer or s.towLine or s.chainHarpoons, false, `path {i} T5 without harpoons`)
	end
end)

test("volley: bolts spread furthest first and start again when dinos run out", function()
	eq(list(Ballista.volley({ 10, 50, 30 }, 1)), "2", "one bolt: the first dino")
	eq(list(Ballista.volley({ 10, 50, 30 }, 3)), "2,3,1", "three bolts, three dinos")
	eq(list(Ballista.volley({ 10, 50 }, 3)), "2,1,2", "more bolts than dinos: around again")
	eq(list(Ballista.volley({ 40, 40 }, 2)), "1,2", "a tie: the earlier first")
	eq(#Ballista.volley({}, 4), 0, "nothing in range: no bolts")
end)

test("Chain Harpoons: each pair spans the crowd, front and back", function()
	-- furthest first: 2 (90), 4 (70), 1 (50), 5 (30), 3 (10)
	local d = { 50, 90, 10, 70, 30 }
	eq(list(Ballista.volley(d, 4, true)), "2,3,4,5", "pair 1: first and last; pair 2: second and second-last")
	eq(list(Ballista.volley(d, 2, true)), "2,3")
	eq(list(Ballista.volley({ 5 }, 2, true)), "1,1", "one dino: both ends on it")
	eq(list(Ballista.volley({ 5, 9 }, 4, true)), "2,1,1,2", "two dinos: every pair spans both")
	local pairs = Ballista.pairs(4)
	eq(#pairs, 2)
	eq(list(pairs[1]) .. "|" .. list(pairs[2]), "1,2|3,4")
	eq(#Ballista.pairs(3), 1, "an odd last bolt flies alone")
	eq(#Ballista.pairs(1), 0)
end)

test("onLine: within Bolt width of the segment, nearest the start first, height ignored", function()
	local from, to = Vector3.new(0, 5, 0), Vector3.new(20, 5, 0)
	local points = {
		Vector3.new(15, 0, 1), -- 1: on it
		Vector3.new(5, 30, -2.9), -- 2: on it, a flier
		Vector3.new(10, 0, 3.5), -- 3: too wide
		Vector3.new(25, 0, 0), -- 4: past the end
		Vector3.new(-2, 0, 0), -- 5: behind the start, 2 studs away
		Vector3.new(10, 0, 0), -- 6: dead centre
	}
	eq(list(Ballista.onLine(points, from, to)), "5,2,6,1", "Bolt width 3")
	eq(list(Ballista.onLine(points, from, to, 4)), "5,2,3,6,1", "a wider line (a tie along it: the earlier)")
	eq(list(Ballista.onLine(points, from, from, 3)), "5", "a zero-length chain: only what's at its point")
end)

test("lineEnd: Skewer flies out to the tower's range, never short of the target", function()
	local e = Ballista.lineEnd(Vector3.new(0, 4, 0), Vector3.new(3, 1, 4), 20)
	near(e.X, 12, "x", 1e-4)
	near(e.Z, 16, "z", 1e-4)
	local far = Ballista.lineEnd(Vector3.new(0, 4, 0), Vector3.new(30, 1, 40), 20)
	near(far.X, 30, "a target past the range: the line reaches it", 1e-4)
	near(far.Z, 40, "z", 1e-4)
end)

test("towPick: the boss furthest along; nil without one", function()
	eq(Ballista.towPick({ 10, 50, 30 }, { [1] = true, [3] = true }), 3)
	eq(Ballista.towPick({ 10, 50, 30 }, {}), nil, "no boss in range: the pull stays ready")
end)

test("only Tow Line moves a boss (PLAN T66)", function()
	eq(Ballista.movesBoss(false, false), true, "a dino: any knockback")
	eq(Ballista.movesBoss(false, nil), true)
	eq(Ballista.movesBoss(true, false), false, "a boss: too heavy")
	eq(Ballista.movesBoss(true, nil), false)
	eq(Ballista.movesBoss(true, true), true, "Tow Line")
	-- Every caller of Enemies.knockback passes two arguments, except Tow Line's one call.
	local enemies = fs.readFile("src/server/Enemies.luau")
	ok(string.find(enemies, "Ballista.movesBoss(enemy.def.boss == true, towLine)", 1, true), "Enemies.knockback asks the rule")
	local third = {}
	local function scan(dir: string)
		for _, name in fs.readDir(dir) do
			local path = `{dir}/{name}`
			if fs.isDir(path) then
				scan(path)
			elseif string.match(name, "%.luau$") then
				for args in string.gmatch(fs.readFile(path), "Enemies%.knockback(%b())") do
					local _, commas = string.gsub(args, ",", ",")
					if commas >= 2 and not string.find(args, ":", 1, true) then -- a call, not the definition
						table.insert(third, `{path} {args}`)
					end
				end
			end
		end
	end
	scan("src")
	eq(#third, 1, "one call passes the boss flag: " .. table.concat(third, "; "))
	ok(string.find(third[1], "src/server/Towers.luau (boss, tuning.TowLinePull, true)", 1, true), third[1])
end)
