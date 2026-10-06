--[[
	Shared/SizeBreaks: one health pool with size thresholds, and pierce-through
	breaks per hit (DECISIONS #125-#128, PLAN T46).

	The oracle for b = 1 is the old Enemies rule, written out below: each size
	has its own HP (= share); a hit lowers it; at 0 or less the size is emptied
	(a pop), overflow is lost and the next size starts full; emptying size 1 kills.
]]

local Config = require(src.shared.Config)
local SizeBreaks = require(src.shared.SizeBreaks)

test("the Tuning levers and sheet columns are the seeds this spec means", function()
	eq(Config.Tuning.BreakLevelStep, 3)
	eq(Config.Tuning.MaxSizeBreaks, 4)
	local resist = {}
	for key, e in Config.Enemies do
		resist[e.display] = e.breakResist
		ok(e.breakResist ~= nil, `{key} has a breakResist`)
	end
	eq(resist.Compy, 0)
	eq(resist.Raptor, 0)
	eq(resist.Pachycephalosaurus, 0)
	eq(resist.Ankylosaurus, 1)
	eq(resist.Gallimimus, 0)
	eq(resist.Pteranodon, 0)
	eq(resist.Triceratops, 1)
	eq(resist["T-Rex"], 2)
end)

-- The old per-size rule (Enemies before T46).
local function oldHit(d, amount)
	if not d.alive then
		return 0
	end
	d.sizeHp -= amount
	if d.sizeHp > 0 then
		return 0
	end
	if d.size > 1 then
		d.size -= 1
		d.sizeHp = d.share
	else
		d.alive = false
		d.sizeHp = 0
	end
	return 1
end

local function newHit(d, amount, b)
	if not d.alive then
		return 0
	end
	local hp, dropped, dead = SizeBreaks.apply(d.hp, d.share, d.size, amount, b)
	d.hp = hp
	d.size -= dropped
	d.alive = not dead
	return dropped
end

local function dino(pool, sizes)
	local share = pool / sizes
	return { share = share, size = sizes, sizeHp = share, hp = pool, alive = true }
end

test("b = 1 reproduces the old per-size rule on the same hits", function()
	local cases = {
		-- pool, sizes, hits
		{ 100, 1, { 30, 30, 30, 30 } },
		{ 100, 1, { 100 } },
		{ 100, 1, { 250 } },
		{ 200, 2, { 99, 1, 50, 50 } }, -- an exact emptying pops
		{ 200, 2, { 150, 10, 95, 5 } }, -- overflow lost: 150 only empties size 2
		{ 300, 3, { 1000, 1000, 1000, 1000 } },
		{ 300, 3, { 33, 33, 33, 33, 33, 33, 33, 33, 33, 33, 33 } },
		{ 400, 4, { 0.1, 99.9, 60, 39.99, 0.01, 250, 1 } },
		{ 1500, 5, { 299, 1, 300, 450, 12.5, 287.5, 1, 1000, 900 } },
	}
	for i, c in cases do
		local old, new = dino(c[1], c[2]), dino(c[1], c[2])
		for j, amount in c[3] do
			local where = `case {i} hit {j}`
			eq(newHit(new, amount, 1), oldHit(old, amount), where .. " pops")
			eq(new.alive, old.alive, where .. " alive")
			if new.alive then
				eq(new.size, old.size, where .. " size")
				near(new.hp - (new.size - 1) * new.share, old.sizeHp, where .. " HP left in the size", 1e-6)
				eq(SizeBreaks.sizeOf(new.hp, new.share), new.size, where .. " sizeOf agrees")
			end
		end
	end
end)

test("b = 1 matches the old rule on a long pseudo-random hit sequence", function()
	local seed = 12345
	local function rand()
		seed = (seed * 1103515245 + 12345) % 2147483648
		return seed / 2147483648
	end
	for trial = 1, 200 do
		local sizes = 1 + trial % 5
		local pool = 50 + math.floor(rand() * 5000)
		local old, new = dino(pool, sizes), dino(pool, sizes)
		local share = pool / sizes
		while old.alive do
			local amount = math.floor(rand() * share * 2.5 * 100 + 1) / 100
			eq(newHit(new, amount, 1), oldHit(old, amount), `trial {trial} pops`)
			eq(new.alive, old.alive, `trial {trial} alive`)
			if new.alive then
				eq(new.size, old.size, `trial {trial} size`)
				near(new.hp - (new.size - 1) * new.share, old.sizeHp, `trial {trial} HP left`, 1e-6)
			end
		end
		eq(new.alive, false, `trial {trial} both dead`)
	end
end)

test("a 2-break hit with enough damage drops 2 sizes and pays 2 Bones + 2 x cash", function()
	local d = dino(300, 3) -- share 100
	local dropped = newHit(d, 250, 2)
	eq(dropped, 2, "two thresholds crossed")
	eq(d.size, 1)
	near(d.hp, 100, "capped at (3 - 2) x share: the last size starts full")
	-- Enemies pays onKilled once per size dropped: cash = share x Cash per eff HP each.
	near(dropped * d.share, 200, "cash basis for two sizes")
end)

test("damage carries across thresholds up to the cap, then the rest is lost", function()
	local d = dino(400, 4)
	eq(newHit(d, 150, 3), 1, "150 on size 4 with b = 3: one threshold, 50 into size 3")
	eq(d.size, 3)
	near(d.hp, 250)
	eq(newHit(d, 1000, 2), 2, "capped at 2: down to size 1, full")
	eq(d.size, 1)
	near(d.hp, 100, "the rest is lost")
	eq(d.alive, true)
end)

test("death only when allowed: k - b <= 0 and the damage reaches 0", function()
	local d = dino(300, 3)
	eq(newHit(d, 10000, 2), 2)
	eq(d.alive, true, "b = 2 on a size-3 dino can't kill it")
	local e = dino(300, 3)
	eq(newHit(e, 299, 3), 2, "b = 3 but the damage stops 1 short of 0")
	eq(e.alive, true)
	near(e.hp, 1)
	local f = dino(300, 3)
	eq(newHit(f, 300, 3), 3, "b = 3 and exactly enough: dead")
	eq(f.alive, false)
	local g = dino(300, 3)
	eq(newHit(g, 1e6, 4), 3, "b above the sizes left drops only what's there")
	eq(g.alive, false)
end)

test("a hit that crosses nothing drops nothing; zero damage does nothing", function()
	local d = dino(300, 3)
	eq(newHit(d, 50, 4), 0)
	eq(d.size, 3)
	near(d.hp, 250)
	eq(newHit(d, 0, 4), 0)
	near(d.hp, 250)
end)

test("breaks: base, the level bonus only when base >= 2, resist, the cap", function()
	eq(SizeBreaks.breaks(nil, 1, 0, false), 1, "blank = 1")
	eq(SizeBreaks.breaks(1, 10, 0, false), 1, "base 1 never grows with level")
	eq(SizeBreaks.breaks(2, 1, 0, false), 2, "Railshot at level 1")
	eq(SizeBreaks.breaks(2, 3, 0, false), 2, "level 3: no bonus yet")
	eq(SizeBreaks.breaks(2, 4, 0, false), 3, "level 4: +1")
	eq(SizeBreaks.breaks(2, 7, 0, false), 4, "level 7: +2")
	eq(SizeBreaks.breaks(3, 4, 0, false), 4, "Linebreaker at level 4 vs Pachys: 3 + 1")
	eq(SizeBreaks.breaks(4, 7, 2, false), 4, "Extinction Round at level 7 vs T-Rex: 4 + 2 - 2")
	eq(SizeBreaks.breaks(4, 7, 1, false), 4, "vs Triceratops: min(4, 5)")
	eq(SizeBreaks.breaks(2, 1, 1, true), 1, "Heart Shot vs Ankylosaurus: 2 - 1")
	eq(SizeBreaks.breaks(2, 7, 0, true), 2, "heroes get no level bonus")
	eq(SizeBreaks.breaks(1, 1, 2, false), 1, "never below 1")
	eq(SizeBreaks.breaks(3, 1, 2, false), 1, "resist down to the floor")
	eq(SizeBreaks.breaks(4, 1, 0, false), 4)
	eq(SizeBreaks.breaks(4, 4, 0, false), 4, "capped at Max size breaks")
end)

test("a dino pays the same cash and Bones whatever kills it", function()
	for _, spec in { { 100, 1 }, { 200, 2 }, { 300, 3 }, { 400, 4 }, { 1500, 5 } } do
		local pool, sizes = spec[1], spec[2]
		for _, plan in {
			{ b = 1, amount = pool }, -- one size per huge hit
			{ b = 4, amount = pool }, -- as many as the cap allows
			{ b = 2, amount = pool / sizes * 0.7 }, -- chip damage
			{ b = 3, amount = pool / sizes * 1.6 },
		} do
			local d = dino(pool, sizes)
			local bones, cash, hits = 0, 0, 0
			while d.alive do
				local dropped = newHit(d, plan.amount, plan.b)
				bones += dropped
				cash += dropped * d.share
				hits += 1
				ok(hits < 1000, "terminates")
			end
			eq(bones, sizes, `{sizes} sizes, b = {plan.b}: a Bone per size`)
			near(cash, pool, `{sizes} sizes, b = {plan.b}: cash for the whole pool`, 1e-6)
		end
	end
end)

test("sizeOf: thresholds belong to the smaller size", function()
	eq(SizeBreaks.sizeOf(300, 100), 3)
	eq(SizeBreaks.sizeOf(200.001, 100), 3)
	eq(SizeBreaks.sizeOf(200, 100), 2)
	eq(SizeBreaks.sizeOf(0.5, 100), 1)
	eq(SizeBreaks.sizeOf(0, 100), 0)
	-- floating-point pools: k x (pool / s) / (pool / s) need not be exactly k
	for _, c in { { 93644.122, 4 }, { 30337.548, 5 }, { 67817.901, 5 }, { 0.3, 3 }, { 1234.567, 5 } } do
		local share = c[1] / c[2]
		for k = 1, c[2] do
			eq(SizeBreaks.sizeOf(k * share, share), k, `pool {c[1]} / {c[2]}, size {k}`)
		end
	end
end)

test("Size breaks per tier are PLAN's seeds and reach the tower and hero stats", function()
	local TowerStats = require(src.shared.TowerStats)
	local HeroStats = require(src.shared.HeroStats)
	local want = {
		["Longshot Perch/Deadeye"] = { 1, 1, 1, 2, 3 },
		["Longshot Perch/Big Bore"] = { 1, 2, 2, 3, 4 }, -- cumulative: T3 keeps T2's 2
		["Hunting Blind/Hardliner"] = { 1, 1, 1, 2, 2 },
	}
	for key, def in Config.Towers do
		for i, path in def.paths do
			local seeds = want[`{def.display}/{path.id}`]
			for tier, step in path.tiers do
				eq(step.sizeBreaks, if seeds then seeds[tier] else 1, `{def.display} {path.id} T{tier}`)
				local tiers = { 0, 0, 0 }
				tiers[i] = tier
				eq(TowerStats.compute(def, tiers).sizeBreaks, step.sizeBreaks, `{key} stats`)
			end
		end
	end
	local perch = Config.Towers.SNIPER
	eq(perch.display, "Longshot Perch")
	local deadeye, bigBore
	for i, path in perch.paths do
		if path.id == "Deadeye" then
			deadeye = i
		elseif path.id == "Big Bore" then
			bigBore = i
		end
	end
	local tiers = { 0, 0, 0 }
	tiers[deadeye], tiers[bigBore] = 5, 2
	eq(TowerStats.compute(perch, tiers).sizeBreaks, 3, "crossover: the highest path wins")
	-- DECISIONS #134: only Heart Shot (Marksman T6) and Thunder Slug (Slug T6) break 2.
	local twos = { ["Tracker Marksman 6"] = true, ["Brush Beater Slug 6"] = true }
	local heroTiers = {}
	for key, hero in Config.Heroes do
		for pathIndex, path in hero.paths do
			for tier, step in path.tiers do
				local name = `{hero.display} {path.id} {tier}`
				eq(step.sizeBreaks, if twos[name] then 2 else 1, `{name}: Size breaks`)
				if twos[name] then
					heroTiers[name] = { key, pathIndex }
				end
			end
		end
	end
	for name, at in heroTiers do
		local tiers = { 0, 0, 0 }
		tiers[at[2]] = 6
		local stats = HeroStats.compute(at[1], tiers)
		eq(stats and stats.sizeBreaks, 2, `{name} reaches HeroStats`)
		tiers[at[2]] = 5
		local before = HeroStats.compute(at[1], tiers)
		eq(before and before.sizeBreaks, 1, `{name}: tier 5 still breaks 1`)
	end
	eq(SizeBreaks.breaks(2, 40, 0, true), 2, "a hero's 2 has no level term")
end)

test("boss pool bar (PLAN T49): fill = hp / pool, notches at k / sizes", function()
	near(SizeBreaks.fill(300, 100, 4), 0.75, "fill 300 of 400", 1e-9)
	near(SizeBreaks.fill(400, 100, 4), 1, "full", 1e-9)
	eq(SizeBreaks.fill(0, 100, 4), 0, "dead")
	eq(SizeBreaks.fill(-5, 100, 4), 0, "clamped low")
	eq(SizeBreaks.fill(500, 100, 4), 1, "clamped high")
	eq(SizeBreaks.fill(10, 0, 4), 0, "no pool")
	local n = SizeBreaks.notches(4)
	eq(#n, 3, "a notch per threshold between sizes")
	near(n[1], 0.25, "k=1", 1e-9)
	near(n[2], 0.5, "k=2", 1e-9)
	near(n[3], 0.75, "k=3", 1e-9)
	eq(#SizeBreaks.notches(1), 0, "one size, no notch")
	-- a 2-break hit on size 4 lands exactly on notch 2
	local hp = SizeBreaks.apply(400, 100, 4, 250, 2)
	near(SizeBreaks.fill(hp, 100, 4), n[2], "two thresholds down", 1e-9)
end)
