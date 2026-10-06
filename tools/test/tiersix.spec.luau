--[[
	Hero tier 6 (PLAN T52, "Hero tier 6", DECISIONS #132-#134): each of the twelve does
	what PLAN's table says, through HeroStats.compute and the pure gun rules in
	Shared/GunRules. Handling and fire modes, not raw damage: every tier 6 keeps its
	tier 5's Damage x.
]]

local Config = require(src.shared.Config)
local HeroStats = require(src.shared.HeroStats)
local GunRules = require(src.shared.GunRules)
local Combat = require(src.shared.Combat)
local SizeBreaks = require(src.shared.SizeBreaks)

local function stats(key: string, path: number, tier: number): any
	local tiers = { 0, 0, 0 }
	tiers[path] = tier
	return HeroStats.compute(key, tiers)
end

-- (hero, path, tier 6 name): the tier 6 and tier 5 stats.
local function six(key: string, path: number, name: string): (any, any)
	eq(Config.Heroes[key].paths[path].tiers[6].name, name, `{key} path {path} T6 name`)
	return stats(key, path, 6), stats(key, path, 5)
end

test("every hero path has six tiers; tier 6 costs 6,400 and keeps tier 5's damage", function()
	for key, hero in Config.Heroes do
		for _, path in hero.paths do
			eq(#path.tiers, 6, `{key} {path.id} tiers`)
			eq(path.tiers[6].cost, 6400, `{key} {path.id} T6 cost`)
			eq(path.tiers[6].damageMult, path.tiers[5].damageMult, `{key} {path.id} T6 Damage x`)
		end
	end
end)

test("Tracker: Hot Swap, Heart Shot, Bounce Back", function()
	-- Hot Swap: the guns reload one at a time; reload x0.8.
	local s, t5 = six("PISTOL", 1, "Hot Swap")
	ok(s.staggeredReload and not t5.staggeredReload, "Hot Swap staggers the reload")
	near(s.reload, t5.reload * 0.8, "Hot Swap reload x0.8")
	eq(s.guns, 2, "two guns")
	local share = GunRules.gunShare(s)
	ok(not GunRules.swapDue(s, s.magazine - share + 1, false), "not while each gun has rounds")
	ok(GunRules.swapDue(s, s.magazine - share, false), "a gun's share spent: that gun reloads")
	ok(not GunRules.swapDue(s, s.magazine - share, true), "one swap at a time")
	ok(not GunRules.swapDue(s, 0, false), "both empty: a full reload instead")
	ok(not GunRules.swapDue(t5, t5.magazine - share, false), "Akimbo Frenzy doesn't")
	eq(GunRules.swapRefill(s, s.magazine - share), s.magazine, "the gun comes back full")

	-- Heart Shot: scoped shots have no spread and break 2 sizes.
	s, t5 = six("PISTOL", 2, "Heart Shot")
	eq(s.sizeBreaks, 2, "Heart Shot breaks 2")
	ok(s.scope, "it has the scope")
	ok(s.spread > 0, "unscoped spread is left alone")
	eq(GunRules.cone(s, 0, false, true), 0, "scoped: no spread")
	eq(GunRules.cone(s, 0.5, false, true), 0.5, "scoped: recoil still blooms")
	near(GunRules.cone(s, 0, false, false), s.spread, "hip fire: the usual spread")
	near(GunRules.cone(t5, 0, false, true), t5.spread, "Deadshot scoped keeps its spread")

	-- Bounce Back: each ricochet take-down puts a round back.
	s, t5 = six("PISTOL", 3, "Bounce Back")
	eq(s.ricochetReload, 1, "one round per ricochet take-down")
	eq(s.bounces, t5.bounces, "Chain Shot's bounces")
	eq(GunRules.ricochetRefill(s, 3, 2), 5, "two take-downs, two rounds")
	eq(GunRules.ricochetRefill(s, s.magazine - 1, 3), s.magazine, "never past a full cylinder")
	eq(GunRules.ricochetRefill(t5, 3, 2), 3, "Chain Shot gives none back")
end)

test("Big Game Hunter: Big Five, Endless Belt, Dynamite Rounds", function()
	local s, t5 = six("RIFLE", 1, "Big Five")
	eq(s.fireMode, "burst", "burst fire")
	eq(s.burstCount, 5, "bursts of 5")
	near(s.spread, t5.spread, "Precision Burst's grouping (spread)")
	near(s.recoilPerShot, t5.recoilPerShot, "Precision Burst's grouping (recoil)")
	ok(GunRules.burstStarts(s, 0) and GunRules.burstStarts(s, 5) and GunRules.burstStarts(s, 10), "recoil resets at every 5th shot")
	for shot = 1, 4 do
		ok(not GunRules.burstStarts(s, shot), `not mid-burst (shot {shot})`)
	end
	ok(not GunRules.burstStarts(t5, 0), "Precision Burst keeps its recoil")

	s, t5 = six("RIFLE", 2, "Endless Belt")
	ok(s.spunUpBelt and s.beltFed, "Endless Belt is belt fed")
	ok(not GunRules.usesRounds(s, false, 1), "fully spun up: no rounds used")
	ok(GunRules.usesRounds(s, false, 0.99), "still spinning up: rounds used")
	ok(not GunRules.usesRounds(s, true, 0), "Rally Cry still feeds the belt")
	ok(GunRules.usesRounds(t5, false, 1), "Spin-Up alone still reloads")
	ok(not GunRules.usesRounds(t5, true, 0), "Belt Fed's rule unchanged")

	s, t5 = six("RIFLE", 3, "Dynamite Rounds")
	near(s.splashRadius, t5.splashRadius * 1.5, "splash radius x1.5")
	ok(s.piercesArmor, "the round, and so its splash, pierces armour")
end)

-- One direct hero hit of `amount` on a fresh 3-size Pachy (pool 300, share 100),
-- breaking what Server/Hero gives it: GunRules.sizeBreaks, then the dino's resist.
local function pachyDrops(gun: any, scoped: boolean, amount: number): number
	local pachy = Config.Enemies.SHIELD
	eq(pachy.display, "Pachycephalosaurus", "SHIELD is the Pachy")
	local b = SizeBreaks.breaks(GunRules.sizeBreaks(gun, scoped), 1, pachy.breakResist, true)
	local _, dropped = SizeBreaks.apply(300, 100, 3, amount, b)
	return dropped
end

test("Heart Shot breaks 2 only scoped; Thunder Slug every slug (#170)", function()
	local heart = stats("PISTOL", 2, 6)
	eq(GunRules.sizeBreaks(heart, true), 2, "Heart Shot scoped: the gun's 2")
	eq(GunRules.sizeBreaks(heart, false), 1, "Heart Shot unscoped: 1")
	eq(pachyDrops(heart, true, 250), 2, "scoped vs a 3-size Pachy drops 2 sizes")
	eq(pachyDrops(heart, false, 250), 1, "unscoped drops 1")
	local slug = stats("SHOTGUN", 1, 6)
	ok(not slug.scope, "Thunder Slug has no scope")
	eq(pachyDrops(slug, true, 250), 2, "Thunder Slug drops 2 (scoped flag set)")
	eq(pachyDrops(slug, false, 250), 2, "Thunder Slug drops 2 (unscoped)")
end)

test("Brush Beater: Thunder Slug, Wildfire Drum, Quad Barrel", function()
	local s, t5 = six("SHOTGUN", 1, "Thunder Slug")
	eq(s.sizeBreaks, 2, "Thunder Slug breaks 2")
	eq(GunRules.cone(s, 0, true, false), 0, "standing still: no spread")
	near(GunRules.cone(s, 0, false, false), s.spread, "moving: the usual spread")
	near(GunRules.cone(t5, 0, true, false), t5.spread, "Railslug standing still keeps its spread")

	s, t5 = six("SHOTGUN", 2, "Wildfire Drum")
	eq(Combat.burnPatchReach(s.splashRadius, s.burnPatchReach), 4, "Dragon's Breath patch 4 studs")
	eq(Combat.burnPatchReach(t5.splashRadius, t5.burnPatchReach), Config.Tuning.BurnPatchMinReach, "tier 5 keeps 3")
	eq(Config.Tuning.BurnPatchMinReach, 3, "the floor is 3 (#132)")
	eq(s.magazine, math.floor(t5.magazine * 1.5 + 0.5), "the drum holds +50%")

	s, t5 = six("SHOTGUN", 3, "Quad Barrel")
	eq(s.shotsPerTrigger, 4, "four blasts per trigger")
	eq(t5.shotsPerTrigger, 2, "from two")
	near(s.reload, t5.reload * 1.25, "reload x1.25 longer")
end)

test("Field Medic: Rapid Response, Bottomless Tube, Lights Out", function()
	local s, t5 = six("MEDIC", 1, "Rapid Response")
	eq(s.abilityCharges, 2, "two Triage Kit charges")
	eq(t5.abilityCharges, 1, "Second Wind holds one")
	local cd = 10
	eq(GunRules.charges(0, 100, 2, cd), 2, "full at the start")
	local fullAt = GunRules.useCharge(0, 100, cd)
	eq(GunRules.charges(fullAt, 100, 2, cd), 1, "one left after a use")
	near(GunRules.readyAt(fullAt, 100, 2, cd), 100, "and it's ready now")
	fullAt = GunRules.useCharge(fullAt, 100, cd)
	eq(GunRules.charges(fullAt, 100, 2, cd), 0, "both used")
	near(GunRules.readyAt(fullAt, 100, 2, cd), 110, "the first comes back after one cooldown")
	eq(GunRules.charges(fullAt, 110, 2, cd), 1, "one back")
	eq(GunRules.charges(fullAt, 120, 2, cd), 2, "both back")
	local single = GunRules.useCharge(0, 100, cd)
	eq(GunRules.charges(single, 105, 1, cd), 0, "one charge: the old cooldown")
	near(GunRules.readyAt(single, 105, 1, cd), 110, "ready after the cooldown")

	s, t5 = six("MEDIC", 2, "Bottomless Tube")
	eq(s.magazine, math.floor(Config.Heroes.MEDIC.magazine * Config.Heroes.MEDIC.paths[2].tiers[5].magazineMult * 1.5 + 0.5), "magazine +50%")
	near(s.reload, t5.reload * 0.5, "reload x0.5")

	s, t5 = six("MEDIC", 3, "Lights Out")
	eq(s.jawLockSeconds, 4, "Jaw Lock 4s")
	eq(t5.jawLockSeconds, 3, "from 3")
	eq(s.jawLockSpread, 9, "spreads within 9 studs")
	eq(t5.jawLockSpread, 6, "from 6")
	eq(Config.Tuning.BossJawLockX, 0.5, "bosses still half")
end)
