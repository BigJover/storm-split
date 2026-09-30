--[[
	Every hero tier does what HEROES.md says: each claim as a HeroStats.compute assertion,
	keyed by (hero, path, tier) with the tier name checked first. Plus the combine rules:
	damage per shot is conserved across pellet counts, and when two paths set pellets or
	fire mode the most-upgraded path wins, ties to the earlier path.
]]

local Config = require(src.shared.Config)
local HeroStats = require(src.shared.HeroStats)

local function at(key: string, path: number, tier: number, name: string)
	local hero = Config.Heroes[key]
	eq(hero.paths[path].tiers[tier].name, name, `{key} path {path} T{tier} name`)
	local tiers = { 0, 0, 0 }
	tiers[path] = tier
	return (HeroStats.compute(key, tiers) :: any)
end

local function base(key: string)
	return (HeroStats.compute(key, { 0, 0, 0 }) :: any)
end

-- Every legal tier set (two paths at most, one past tier 2).
local function legalTierSets(): { { number } }
	local sets = {}
	for a = 0, 5 do
		for b = 0, 5 do
			for c = 0, 5 do
				local open, past = 0, 0
				for _, t in { a, b, c } do
					open += if t > 0 then 1 else 0
					past += if t > 2 then 1 else 0
				end
				if open <= 2 and past <= 1 then
					table.insert(sets, { a, b, c })
				end
			end
		end
	end
	return sets
end

-- Tracker -------------------------------------------------------------------------

test("Tracker Gunslinger: Quick Draw / Hair Trigger rate, Dual Pistols, Akimbo Frenzy auto", function()
	local b = base("PISTOL")
	local quick = at("PISTOL", 1, 1, "Quick Draw")
	local hair = at("PISTOL", 1, 2, "Hair Trigger")
	ok(quick.rate > b.rate and hair.rate > quick.rate, "rate climbs")
	local dual = at("PISTOL", 1, 3, "Dual Pistols")
	eq(dual.guns, 2, "Dual Pistols guns")
	eq(dual.magazine, 2 * b.magazine, "Dual Pistols doubles the magazine")
	local akimbo = at("PISTOL", 1, 5, "Akimbo Frenzy")
	eq(akimbo.fireMode, "auto", "Akimbo Frenzy fire mode")
	eq(akimbo.guns, 2, "Akimbo Frenzy guns")
end)

test("Tracker Marksman: Scope flag and reach, Hollow Tips pierce, Deadshot marked x3", function()
	eq(at("PISTOL", 2, 2, "Steady Hands").scope, false, "no scope before Scope")
	local scope = at("PISTOL", 2, 3, "Scope")
	eq(scope.scope, true, "Scope flag")
	ok(scope.range > base("PISTOL").range, "Scope reach")
	eq(at("PISTOL", 2, 4, "Hollow Tips").piercesArmor, true, "Hollow Tips pierces")
	eq(at("PISTOL", 2, 5, "Deadshot").markedDamageMult, 3, "Deadshot vs marked")
end)

test("Tracker Trick Shot: Ricochet bounces, Quick Mark cooldown, Chain Shot 4", function()
	ok(at("PISTOL", 3, 3, "Ricochet").bounces >= 1, "Ricochet bounces")
	eq(at("PISTOL", 3, 2, "Extended Mag").bounces, 0, "no bounce before Ricochet")
	ok(at("PISTOL", 3, 4, "Quick Mark").abilityCooldown < base("PISTOL").abilityCooldown, "Quick Mark cooldown")
	eq(at("PISTOL", 3, 5, "Chain Shot").bounces, 4, "Chain Shot bounces")
end)

-- Big Game Hunter -----------------------------------------------------------------

test("Big Game Hunter Tactical: Burst Fire 3-round bursts, tighter", function()
	local burst = at("RIFLE", 1, 3, "Burst Fire")
	eq(burst.fireMode, "burst", "Burst Fire mode")
	eq(burst.burstCount, 3, "Burst Fire count")
	ok(burst.spread < base("RIFLE").spread, "tight grouping")
end)

test("Big Game Hunter Heavy: Belt Fed, Bipod still recoil, Spin-Up", function()
	eq(at("RIFLE", 2, 2, "Fast Hands").beltFed, false, "not before Belt Fed")
	eq(at("RIFLE", 2, 3, "Belt Fed").beltFed, true, "Belt Fed")
	ok(at("RIFLE", 2, 4, "Bipod").stillRecoilMult < 1, "Bipod less recoil standing still")
	ok(at("RIFLE", 2, 5, "Spin-Up").spinUp > 1, "Spin-Up climbs")
end)

test("Big Game Hunter Special Ammo: Tracer mark, Incendiary burn, AP pierce, Explosive Tips splash", function()
	ok(at("RIFLE", 3, 1, "Tracer Rounds").markPercent > 0, "Tracer marks")
	local incendiary = at("RIFLE", 3, 2, "Incendiary")
	ok(incendiary.burnDps > 0 and incendiary.burnSeconds > 0, "Incendiary burns")
	eq(at("RIFLE", 3, 3, "AP Rounds").piercesArmor, true, "AP pierces")
	ok(at("RIFLE", 3, 5, "Explosive Tips").splashRadius > 0, "Explosive Tips splash")
	eq(at("RIFLE", 3, 4, "Hot Load").splashRadius, 0, "no splash before Explosive Tips")
end)

-- Brush Beater --------------------------------------------------------------------

test("Brush Beater Slug: Slug Rounds 1 pellet through 2, Rifled Barrel air, Sabot, Railslug 6", function()
	eq(base("SHOTGUN").hitsAir, false, "buckshot can't reach air")
	local slug = at("SHOTGUN", 1, 1, "Slug Rounds")
	eq(slug.pellets, 1, "Slug Rounds pellets")
	eq(slug.pierce, 2, "Slug Rounds pierce")
	ok(slug.spread < base("SHOTGUN").spread, "Slug Rounds accurate")
	eq(at("SHOTGUN", 1, 2, "Rifled Barrel").hitsAir, true, "Rifled Barrel reaches air")
	eq(at("SHOTGUN", 1, 3, "Sabot").piercesArmor, true, "Sabot pierces armour")
	eq(at("SHOTGUN", 1, 5, "Railslug").pierce, 6, "Railslug pierce")
end)

test("Brush Beater Buckshot: Dragon's Breath ignite 0.35, Street Sweeper auto", function()
	local dragon = at("SHOTGUN", 2, 3, "Dragon's Breath")
	eq(dragon.igniteShare, 0.35, "Dragon's Breath ignite share")
	ok(dragon.igniteSeconds > 0, "Dragon's Breath ignite delay")
	ok(dragon.burnDps > 0, "Dragon's Breath burning ground")
	eq(at("SHOTGUN", 2, 5, "Street Sweeper").fireMode, "auto", "Street Sweeper auto")
end)

test("Brush Beater Breacher: Double Barrel 2 shots, Kickback knockback, Frag splash", function()
	eq(at("SHOTGUN", 3, 3, "Double Barrel").shotsPerTrigger, 2, "Double Barrel")
	ok(at("SHOTGUN", 3, 4, "Kickback").knockback > 0, "Kickback knocks back")
	ok(at("SHOTGUN", 3, 5, "Frag Shells").splashRadius > 0, "Frag Shells explode")
end)

-- Combine rules -------------------------------------------------------------------

test("damage per shot is conserved across pellet counts (every hero, every legal tier set)", function()
	for _, key in Config.HeroOrder do
		local hero = Config.Heroes[key]
		for _, tiers in legalTierSets() do
			local s = HeroStats.compute(key, tiers) :: any
			local where = `{key} {table.concat(tiers, "/")}`
			near(s.damage * s.pellets, s.shotDamage, `{where} pellets x damage`, 1e-9)
			-- the shot is the base shot times the x columns, however it's split
			local mult = 1
			for p, t in tiers do
				if t > 0 then
					mult *= hero.paths[p].tiers[t].damageMult
				end
			end
			near(s.shotDamage, hero.damage * hero.pellets * mult, `{where} shot damage`, 1e-9)
		end
	end
end)

test("pellets: the most-upgraded path wins, ties to the earlier path", function()
	-- Brush Beater: Slug (path 1) sets 1 pellet, Buckshot (path 2) sets 9 from Extra Pellets.
	eq(Config.Heroes.SHOTGUN.paths[2].tiers[2].name, "Extra Pellets")
	eq((HeroStats.compute("SHOTGUN", { 1, 2, 0 }) :: any).pellets, 9, "Buckshot 2 beats Slug 1")
	eq((HeroStats.compute("SHOTGUN", { 3, 2, 0 }) :: any).pellets, 1, "Slug 3 beats Buckshot 2")
	eq((HeroStats.compute("SHOTGUN", { 2, 2, 0 }) :: any).pellets, 1, "tie 2/2 goes to Slug (earlier)")
	eq((HeroStats.compute("SHOTGUN", { 1, 1, 0 }) :: any).pellets, 1, "tie 1/1: Tight Choke sets none, Slug's 1")
	eq((HeroStats.compute("SHOTGUN", { 0, 0, 2 }) :: any).pellets, Config.Heroes.SHOTGUN.pellets, "base pellets")
end)

test("fire mode: a path that sets it wins over the base; others leave it", function()
	-- In Config only one path per hero sets a fire mode, so the tie rule for fire
	-- mode can't be exercised with real rows; it shares the pellets ordering above.
	eq((HeroStats.compute("SHOTGUN", { 0, 5, 2 }) :: any).fireMode, "auto", "Street Sweeper with Breacher 2")
	eq((HeroStats.compute("SHOTGUN", { 2, 5, 0 }) :: any).fireMode, "auto", "Street Sweeper with Slug 2")
	eq((HeroStats.compute("RIFLE", { 3, 2, 0 }) :: any).fireMode, "burst", "Burst Fire with Heavy 2")
	eq((HeroStats.compute("RIFLE", { 2, 5, 0 }) :: any).fireMode, "auto", "Tactical 2 sets no mode: base auto")
	eq((HeroStats.compute("PISTOL", { 5, 0, 2 }) :: any).fireMode, "auto", "Akimbo Frenzy")
	eq((HeroStats.compute("PISTOL", { 2, 0, 5 }) :: any).fireMode, "semi", "base semi")
end)
