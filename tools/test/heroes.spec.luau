--[[
	Every hero tier does what HEROES.md says: each claim as a HeroStats.compute assertion,
	keyed by (hero, path, tier) with the tier name checked first. Plus the combine rules:
	damage per shot is conserved across pellet counts, and when two paths set pellets or
	fire mode the most-upgraded path wins, ties to the earlier path.
]]

local Config = require(src.shared.Config)
local HeroStats = require(src.shared.HeroStats)
local Combat = require(src.shared.Combat)

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

test("Tracker Trick Shot: Ricochet bounces, Quick Dart cooldown, Chain Shot 4", function()
	ok(at("PISTOL", 3, 3, "Ricochet").bounces >= 1, "Ricochet bounces")
	eq(at("PISTOL", 3, 2, "Extended Mag").bounces, 0, "no bounce before Ricochet")
	ok(at("PISTOL", 3, 4, "Quick Dart").abilityCooldown < base("PISTOL").abilityCooldown, "Quick Dart cooldown")
	eq(at("PISTOL", 3, 5, "Chain Shot").bounces, 4, "Chain Shot bounces")
end)

-- Big Game Hunter -----------------------------------------------------------------

test("Big Game Hunter Stalker: Burst Fire 3-round bursts, tighter", function()
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

test("Brush Beater Buckshot: Dragon's Breath ignite 0.35, Thicket Sweeper auto", function()
	local dragon = at("SHOTGUN", 2, 3, "Dragon's Breath")
	eq(dragon.igniteShare, 0.35, "Dragon's Breath ignite share")
	ok(dragon.igniteSeconds > 0, "Dragon's Breath ignite delay")
	ok(dragon.burnDps > 0, "Dragon's Breath burning ground")
	eq(at("SHOTGUN", 2, 5, "Thicket Sweeper").fireMode, "auto", "Thicket Sweeper auto")
end)

test("Brush Beater Point Blank: Double Barrel 2 shots, Kickback knockback, Frag splash", function()
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
	eq((HeroStats.compute("SHOTGUN", { 0, 5, 2 }) :: any).fireMode, "auto", "Thicket Sweeper with Point Blank 2")
	eq((HeroStats.compute("SHOTGUN", { 2, 5, 0 }) :: any).fireMode, "auto", "Thicket Sweeper with Slug 2")
	eq((HeroStats.compute("RIFLE", { 3, 2, 0 }) :: any).fireMode, "burst", "Burst Fire with Heavy 2")
	eq((HeroStats.compute("RIFLE", { 2, 5, 0 }) :: any).fireMode, "auto", "Stalker 2 sets no mode: base auto")
	eq((HeroStats.compute("PISTOL", { 5, 0, 2 }) :: any).fireMode, "auto", "Akimbo Frenzy")
	eq((HeroStats.compute("PISTOL", { 2, 0, 5 }) :: any).fireMode, "semi", "base semi")
end)

test("Incendiary's burning ground is readable: patch reach >= 3 (DECISIONS #32)", function()
	local incendiary = at("RIFLE", 3, 2, "Incendiary")
	eq(Config.Tuning.BurnPatchMinReach, 3, "Tuning Burn patch min reach")
	-- Hazards.burn: reach = max(splash radius, BurnPatchMinReach)
	ok(math.max(incendiary.splashRadius, Config.Tuning.BurnPatchMinReach) >= 3, "Incendiary patch reach")
end)

test("Dragon's Breath ground patch is 3 studs (DECISIONS #37, #132), tiers 3-5", function()
	for tier = 3, 5 do
		local stats = HeroStats.compute("SHOTGUN", { 0, tier, 0 }) :: any
		ok(stats.burnDps > 0, `Buckshot {tier} lays burning ground`)
		eq(Combat.burnPatchReach(stats.splashRadius), 3, `Buckshot {tier} patch reach`)
	end
end)

test("Outfitter gear changes handling, never damage (HeroStats.compute with gear)", function()
	local plain = HeroStats.compute("RIFLE", { 0, 0, 0 }) :: any
	local gear = { recoilMult = 0.75, reloadMult = 0.65, spreadMult = 0.7, ratePercent = 20 }
	local geared = HeroStats.compute("RIFLE", { 0, 0, 0 }, gear) :: any
	near(geared.recoilPerShot, plain.recoilPerShot * 0.75, "recoil per shot")
	near(geared.recoilMax, plain.recoilMax * 0.75, "recoil max")
	near(geared.reload, plain.reload * 0.65, "reload")
	near(geared.spread, plain.spread * 0.7, "spread")
	near(geared.rate, plain.rate * 1.2, "fire rate +20%")
	eq(geared.shotDamage, plain.shotDamage, "damage unchanged")
	local none = HeroStats.compute("RIFLE", { 0, 0, 0 }, HeroStats.NO_GEAR) :: any
	eq(none.rate, plain.rate, "no gear = plain")
end)

-- Field Medic (PLAN T16; DECISIONS #13, #14, names per #25) -------------------------

test("Field Medic base: Lever-Action Carbine, Triage Kit HEAL 40 HP in 20 studs, 35s, 75 Amber", function()
	local m = Config.Heroes.MEDIC
	eq(m.display, "Field Medic")
	eq(m.role, "Support")
	eq(m.weapon, "Lever-Action Carbine")
	eq(m.ability, "Triage Kit")
	eq(m.abilityKind, "HEAL")
	eq(m.unlockCost, 75, "unlock (Amber)")
	eq(m.damage, 1, "damage")
	eq(m.rate, 3, "fire rate")
	eq(m.fireMode, "semi")
	eq(m.magazine, 10)
	eq(m.reload, 1.8)
	eq(m.pellets, 1)
	eq(m.spread, 0.8)
	eq(m.recoilPerShot, 1)
	eq(m.recoilMax, 6)
	eq(m.recoilRecovery, 12)
	eq(m.range, 45)
	eq(m.hitsAir, true, "hits air")
	eq(m.piercesArmor, false)
	local b = base("MEDIC")
	eq(b.heal, 40, "heal")
	eq(b.healRadius, 20, "heal radius")
	eq(b.abilityCooldown, 35, "cooldown")
	eq(b.healRepairsTowers, false, "no tower heal before Patch Up")
	eq(b.guardPercent, 0, "no guard before Second Wind")
	eq(b.slowPercent, 0, "no slow before Tranq Tips")
	eq(b.jawLockSeconds, 0, "no lock before Jaw Lock")
	-- support: below the Tracker's damage per second
	local tracker = base("PISTOL")
	ok(b.shotDamage * b.rate < tracker.shotDamage * tracker.rate, "Medic DPS < Tracker DPS")
	eq(Config.HeroOrder[4], "MEDIC", "hero select lists 4, Medic last")
end)

test("Field Medic Triage: Clean Bandages x1.25, Belt Pouch x0.8 cooldown, Patch Up, Triage Tent x1.5, Second Wind 30%/8s", function()
	eq(Config.Heroes.MEDIC.paths[1].id, "Triage")
	local t1 = at("MEDIC", 1, 1, "Clean Bandages")
	near(t1.heal, 50, "heal x1.25")
	eq(t1.abilityCooldown, 35, "cooldown unchanged")
	local t2 = at("MEDIC", 1, 2, "Belt Pouch")
	near(t2.abilityCooldown, 28, "cooldown x0.8")
	near(t2.heal, 50, "keeps heal")
	local t3 = at("MEDIC", 1, 3, "Patch Up")
	eq(t3.healRepairsTowers, true, "Patch Up heals towers")
	eq(at("MEDIC", 1, 2, "Belt Pouch").healRepairsTowers, false, "not before Patch Up")
	local t4 = at("MEDIC", 1, 4, "Triage Tent")
	near(t4.healRadius, 30, "radius x1.5")
	eq(t4.guardPercent, 0, "no guard before Second Wind")
	local t5 = at("MEDIC", 1, 5, "Second Wind")
	eq(t5.guardPercent, 30, "Second Wind 30% less damage")
	eq(t5.guardSeconds, 8, "for 8s")
	eq(t5.healRepairsTowers, true, "keeps Patch Up")
	near(t5.healRadius, 30, "keeps Triage Tent")
	near(t5.heal, 50, "keeps Clean Bandages")
	near(t5.abilityCooldown, 28, "keeps Belt Pouch")
	-- the heal is about the ability, never the gun
	for tier = 1, 5 do
		local s = HeroStats.compute("MEDIC", { tier, 0, 0 }) :: any
		eq(s.shotDamage, base("MEDIC").shotDamage, `Triage T{tier} damage unchanged`)
		eq(s.rate, base("MEDIC").rate, `Triage T{tier} rate unchanged`)
	end
end)

test("Field Medic Lever Action: Oiled Lever x1.2, Loading Gate mag x1.5 reload x0.75, Rapid Cycle 2-burst, Smooth Action recoil x0.5, Runaway Lever auto x1.6", function()
	eq(Config.Heroes.MEDIC.paths[2].id, "Lever Action")
	local b = base("MEDIC")
	near(at("MEDIC", 2, 1, "Oiled Lever").rate, b.rate * 1.2, "rate x1.2")
	local gate = at("MEDIC", 2, 2, "Loading Gate")
	eq(gate.magazine, 15, "magazine x1.5")
	near(gate.reload, b.reload * 0.75, "reload x0.75")
	near(gate.rate, b.rate * 1.2, "keeps Oiled Lever")
	local cycle = at("MEDIC", 2, 3, "Rapid Cycle")
	eq(cycle.fireMode, "burst", "Rapid Cycle bursts")
	eq(cycle.burstCount, 2, "2-round burst")
	local smooth = at("MEDIC", 2, 4, "Smooth Action")
	near(smooth.recoilPerShot, b.recoilPerShot * 0.5, "recoil x0.5")
	near(smooth.recoilMax, b.recoilMax * 0.5, "recoil max x0.5")
	eq(smooth.fireMode, "burst", "still bursts")
	local hip = at("MEDIC", 2, 5, "Runaway Lever")
	eq(hip.fireMode, "auto", "Runaway Lever full auto")
	near(hip.rate, b.rate * 1.6, "Runaway Lever rate x1.6")
	near(hip.recoilPerShot, b.recoilPerShot * 0.5, "keeps Smooth Action")
	eq(hip.magazine, 15, "keeps Loading Gate")
	for tier = 1, 5 do
		eq((HeroStats.compute("MEDIC", { 0, tier, 0 }) :: any).shotDamage, b.shotDamage, `Lever Action T{tier} damage per shot unchanged`)
	end
end)

test("Field Medic Muzzle: Tranq Tips 20%/1s, Double Dose 30%/1.5s, Jaw Lock 2s, Long Dose 3s, Lullaby Rounds 6 studs", function()
	eq(Config.Heroes.MEDIC.paths[3].id, "Muzzle", "Pacifier renamed Muzzle (#25)")
	local tips = at("MEDIC", 3, 1, "Tranq Tips")
	eq(tips.slowPercent, 20)
	eq(tips.slowSeconds, 1)
	eq(tips.jawLockSeconds, 0, "no lock yet")
	local dose = at("MEDIC", 3, 2, "Double Dose")
	eq(dose.slowPercent, 30)
	eq(dose.slowSeconds, 1.5)
	local lock = at("MEDIC", 3, 3, "Jaw Lock")
	eq(lock.jawLockSeconds, 2, "Jaw Lock 2s")
	eq(lock.jawLockSpread, 0, "no spread yet")
	eq(lock.slowPercent, 30, "keeps Double Dose")
	local long = at("MEDIC", 3, 4, "Long Dose")
	eq(long.jawLockSeconds, 3, "Long Dose 3s")
	local lullaby = at("MEDIC", 3, 5, "Lullaby Rounds")
	eq(lullaby.jawLockSpread, 6, "lock spreads 6 studs")
	eq(lullaby.jawLockSeconds, 3, "keeps Long Dose")
	-- Bosses ignore the slow (Hero passes affectsBosses = false) and are locked half as long.
	eq(Config.Tuning.BossJawLockX, 0.5, "Tuning Boss jaw lock x")
	for tier = 1, 5 do
		eq((HeroStats.compute("MEDIC", { 0, 0, tier }) :: any).shotDamage, base("MEDIC").shotDamage, `Muzzle T{tier} damage unchanged`)
	end
end)

test("Field Medic crossover: Triage 5 + Muzzle 2 keeps both; Second Wind guard obeys the resist rule (DECISIONS #12)", function()
	local s = HeroStats.compute("MEDIC", { 5, 0, 2 }) :: any
	eq(s.guardPercent, 30)
	eq(s.slowPercent, 30)
	near(s.heal, 50)
	local Combat = require(src.shared.Combat)
	-- Second Wind (30) under an Armory aura (45): the strongest wins, no stacking.
	eq(Combat.combineResist({ 45, s.guardPercent }), 45, "Armory 45 beats Second Wind 30")
	eq(Combat.combineResist({ 0, s.guardPercent }), 30, "Second Wind alone")
	near(Combat.afterResist(100, Combat.combineResist({ s.guardPercent })), 70, "30% less damage")
end)

-- Mastery perks (PLAN round 3 T32): the sheet's rows as Config.MasteryPerks.
local PERK_FIELDS = {
	"abilitySecondsAdd",
	"abilityRadiusAdd",
	"abilityPowerAdd",
	"markExtra",
	"markExtraPowerMult",
	"markExtraReach",
	"strikeBurnPercent",
	"strikeBurnSeconds",
}

test("mastery perks: every hero has a named perk at mastery 10 and 15, sorted by level, every field a number", function()
	for _, key in Config.HeroOrder do
		local perks = Config.MasteryPerks[key]
		ok(perks ~= nil, `{key} has perks`)
		local levels = {}
		local last = 0
		for _, perk in perks do
			ok(perk.level > last, `{key} perks are sorted by level, none repeated`)
			last = perk.level
			levels[perk.level] = perk
			ok(perk.level >= 1 and perk.level <= #Config.Mastery, `{key} level {perk.level} is a mastery level`)
			ok(perk.name ~= "" and perk.text ~= "", `{key} level {perk.level} has a name and a text`)
			local set = 0
			for _, field in PERK_FIELDS do
				eq(type(perk[field]), "number", `{key} level {perk.level} {field}`)
				set += if perk[field] ~= 0 then 1 else 0
			end
			ok(set > 0, `{key} level {perk.level} does something`)
		end
		ok(levels[10] ~= nil, `{key} has a level-10 perk`)
		ok(levels[15] ~= nil, `{key} has a level-15 perk`)
	end
	for key in Config.MasteryPerks do
		ok(Config.Heroes[key] ~= nil, `{key} is a hero`)
	end
end)

-- Mastery perks in play (PLAN round 3 T33): HeroStats.compute(key, tiers, gear, mastery).

-- heal / healRadius are the ability power / radius times the Medic's path multipliers,
-- computed for every hero but read only by the HEAL ability: for the other heroes they
-- just mirror the ability fields, so the "what changed" lists leave them out.
local function mirrors(key: string): { [string]: boolean }
	return if Config.Heroes[key].abilityKind == "HEAL" then {} else { heal = true, healRadius = true }
end

-- The Stats fields that differ between two computed stats, sorted, as "a,b,c".
local function changed(a: any, b: any, ignore: { [string]: boolean }?): string
	local fields = {}
	for field, value in a do
		if ignore and ignore[field] then
			continue
		end
		local other = b[field]
		local same = if type(value) == "number" and type(other) == "number"
			then math.abs(value - other) < 1e-9
			else value == other
		if not same then
			table.insert(fields, field)
		end
	end
	for field in b do
		if a[field] == nil then
			table.insert(fields, field)
		end
	end
	table.sort(fields)
	return table.concat(fields, ",")
end

local function mastered(key: string, mastery: number?, tiers: { number }?)
	return (HeroStats.compute(key, tiers or { 0, 0, 0 }, nil, mastery) :: any)
end

local function perkAt(key: string, level: number)
	for _, perk in Config.MasteryPerks[key] do
		if perk.level == level then
			return perk
		end
	end
	error(`{key} has no level-{level} perk`)
end

test("mastery perks: perksAt gives every perk at or below the mastery level, none without mastery", function()
	for _, key in Config.HeroOrder do
		local names = function(level: number?): string
			local out = {}
			for _, perk in HeroStats.perksAt(key, level) do
				table.insert(out, perk.name)
			end
			return table.concat(out, "+")
		end
		local ten, fifteen = perkAt(key, 10), perkAt(key, 15)
		eq(names(nil), "", `{key} no mastery`)
		eq(names(0), "", `{key} mastery 0`)
		eq(names(9), "", `{key} mastery 9`)
		eq(names(10), ten.name, `{key} mastery 10`)
		eq(names(14), ten.name, `{key} mastery 14`)
		eq(names(15), `{ten.name}+{fifteen.name}`, `{key} mastery 15 has both`)
		eq(names(20), `{ten.name}+{fifteen.name}`, `{key} mastery 20 has both`)
		eq(HeroStats.hasPerk(ten, 9), false, `{key} level-10 perk at 9`)
		eq(HeroStats.hasPerk(ten, 10), true, `{key} level-10 perk at 10`)
		eq(HeroStats.hasPerk(fifteen, 14), false, `{key} level-15 perk at 14`)
		eq(HeroStats.hasPerk(fifteen, 15), true, `{key} level-15 perk at 15`)
		eq(HeroStats.hasPerk(fifteen, nil), false, `{key} level-15 perk with no mastery`)
		eq(#HeroStats.perksOf(key), #Config.MasteryPerks[key], `{key} perksOf lists them all`)
	end
	eq(#HeroStats.perksAt("NOBODY", 20), 0, "an unknown hero has none")
	eq(#HeroStats.perksOf("NOBODY"), 0, "perksOf an unknown hero")
end)

test("mastery perks: below 10 the stats are exactly the stats without mastery (every hero, every legal tier set)", function()
	for _, key in Config.HeroOrder do
		local hero = Config.Heroes[key]
		for _, tiers in legalTierSets() do
			local plain = (HeroStats.compute(key, tiers) :: any)
			for _, mastery in { 0, 1, 5, 9 } do
				eq(changed(plain, mastered(key, mastery, tiers)), "", `{key} mastery {mastery} tiers {table.concat(tiers, "-")}`)
			end
		end
		local plain = base(key)
		eq(plain.abilityPower, hero.abilityPower, `{key} base ability power`)
		eq(plain.abilitySeconds, hero.abilitySeconds, `{key} base ability seconds`)
		eq(plain.abilityRadius, hero.abilityRadius, `{key} base ability radius`)
		for _, field in { "markExtra", "markExtraPowerMult", "markExtraReach", "strikeBurnPercent", "strikeBurnSeconds" } do
			eq(plain[field], 0, `{key} {field} without mastery`)
		end
	end
end)

test("mastery 10: only the level-10 lever moves, by the sheet value (and stays to 14)", function()
	-- hero -> the fields that change at 10, and the lever's new value (PLAN round 3)
	local want = {
		PISTOL = { fields = "abilitySeconds", lever = "abilitySeconds", add = "abilitySecondsAdd", value = 10 }, -- Sticky Dart 8 -> 10
		RIFLE = { fields = "abilityRadius", lever = "abilityRadius", add = "abilityRadiusAdd", value = 30 }, -- Hunting Horn 25 -> 30
		SHOTGUN = { fields = "abilityRadius", lever = "abilityRadius", add = "abilityRadiusAdd", value = 11.5 }, -- Wide Flare 10 -> 11.5
		MEDIC = { fields = "abilityRadius,healRadius", lever = "healRadius", add = "abilityRadiusAdd", value = 24 }, -- Far Reach 20 -> 24
	}
	for _, key in Config.HeroOrder do
		local w = want[key]
		ok(w ~= nil, `{key} is covered by this spec`)
		local before, at10 = mastered(key, 9), mastered(key, 10)
		eq(changed(before, at10, mirrors(key)), w.fields, `{key}: what changes at mastery 10`)
		near(at10[w.lever], w.value, `{key} {w.lever} at mastery 10`)
		near(at10[w.lever] - before[w.lever], perkAt(key, 10)[w.add], `{key} moves by the sheet value`)
		eq(changed(at10, mastered(key, 14)), "", `{key}: nothing more until 15`)
	end
end)

test("mastery 15: both perks (and nothing more at 20); perks never touch the gun", function()
	local want = {
		-- Sticky Dart + Spare Dart: 10s, 1 extra mark at 0.4x within 10 studs
		PISTOL = { fields = "abilitySeconds,markExtra,markExtraPowerMult,markExtraReach",
			values = { abilitySeconds = 10, abilityPower = 50, markExtra = 1, markExtraPowerMult = 0.4, markExtraReach = 10 } },
		-- Hunting Horn + Long Rally: 30 studs, 13s, still +40%
		RIFLE = { fields = "abilityRadius,abilitySeconds", values = { abilityRadius = 30, abilitySeconds = 13, abilityPower = 40 } },
		-- Wide Flare + Smoulder: 11.5 studs, 12% a second for 3s; the stun and the damage don't move
		SHOTGUN = { fields = "abilityRadius,strikeBurnPercent,strikeBurnSeconds",
			values = { abilityRadius = 11.5, strikeBurnPercent = 12, strikeBurnSeconds = 3, abilitySeconds = 2, abilityPower = 30 } },
		-- Far Reach + Stocked Kit: 24 studs, 50 HP
		MEDIC = { fields = "abilityPower,abilityRadius,heal,healRadius", values = { healRadius = 24, heal = 50, abilityPower = 50 } },
	}
	local gun = { "damage", "shotDamage", "rate", "magazine", "reload", "pellets", "spread", "recoilPerShot", "recoilMax", "range",
		"pierce", "bounces", "burnDps", "burnSeconds", "splashRadius", "knockback", "markPercent", "markedDamageMult", "abilityCooldown" }
	for _, key in Config.HeroOrder do
		local w = want[key]
		ok(w ~= nil, `{key} is covered by this spec`)
		local none, at15 = mastered(key, 0), mastered(key, 15)
		eq(changed(none, at15, mirrors(key)), w.fields, `{key}: what changes by mastery 15`)
		for field, value in w.values do
			near(at15[field], value, `{key} {field} at mastery 15`)
		end
		eq(changed(at15, mastered(key, 20)), "", `{key}: mastery 20 adds no perk`)
		for _, tiers in legalTierSets() do
			local plain, maxed = (HeroStats.compute(key, tiers) :: any), mastered(key, 20, tiers)
			for _, field in gun do
				eq(maxed[field], plain[field], `{key} {field} at mastery 20, tiers {table.concat(tiers, "-")}`)
			end
		end
	end
end)

test("mastery perks add to the base before path multipliers: Stocked Kit x Clean Bandages, Far Reach x Triage Tent", function()
	eq(Config.Heroes.MEDIC.paths[1].tiers[1].name, "Clean Bandages")
	eq(Config.Heroes.MEDIC.paths[1].tiers[4].name, "Triage Tent")
	near(mastered("MEDIC", 15, { 1, 0, 0 }).heal, 50 * 1.25, "Stocked Kit + Clean Bandages = 50 x 1.25")
	near(mastered("MEDIC", 10, { 1, 0, 0 }).heal, 40 * 1.25, "no Stocked Kit at 10")
	near(mastered("MEDIC", 10, { 4, 0, 0 }).healRadius, 24 * 1.5, "Far Reach + Triage Tent = 24 x 1.5")
	near(mastered("MEDIC", 9, { 4, 0, 0 }).healRadius, 20 * 1.5, "no Far Reach at 9")
	near(mastered("MEDIC", 15, { 4, 0, 0 }).heal, 50 * 1.25, "both, through the whole Triage path")
	near(mastered("MEDIC", 15, { 4, 0, 0 }).healRadius, 24 * 1.5, "both, through the whole Triage path")
end)

test("Rally Cry: the radius and seconds Server/Hero hands towerRateBoost are the merged ones", function()
	-- Hero.ability copies stats.abilityRadius / abilitySeconds / abilityPower into the
	-- overdrive state that Hero.towerRateBoost reads.
	eq(Config.Heroes.RIFLE.abilityKind, "OVERDRIVE")
	near(mastered("RIFLE", 0).abilityRadius, 25, "no mastery")
	near(mastered("RIFLE", 10).abilityRadius, 30, "Hunting Horn")
	near(mastered("RIFLE", 10).abilitySeconds, 10, "not longer yet")
	near(mastered("RIFLE", 15).abilitySeconds, 13, "Long Rally")
	near(mastered("RIFLE", 15).abilityPower, 40, "never stronger")
end)

-- Names and wording from Dino review round 11 (PLAN round 3 T36b, DECISIONS #114-#115).

test("the mastery perks carry their reviewed names and texts", function()
	local want = {
		PISTOL = { [10] = "Sticky Dart", [15] = "Spare Dart" },
		RIFLE = { [10] = "Hunting Horn", [15] = "Long Rally" },
		SHOTGUN = { [10] = "Wide Flare", [15] = "Smoulder" },
		MEDIC = { [10] = "Far Reach", [15] = "Stocked Kit" },
	}
	local texts = {}
	for key, names in want do
		local seen = 0
		for _, perk in Config.MasteryPerks[key] do
			eq(perk.name, names[perk.level], `{key} mastery {perk.level}`)
			texts[perk.name] = perk.text
			seen += 1
		end
		eq(seen, 2, `{key}: one perk at 10, one at 15`)
	end
	eq(texts["Wide Flare"], "Flare Strike reaches 1.5 studs further", "Wide Flare")
	eq(texts["Smoulder"], "Flare Strike leaves burning ground for 3s (12% of the strike's damage each second)", "Smoulder")
	eq(Config.Mastery[10].unlock, "Start every match with your first upgrade free, plus this hero's mastery-10 ability perk", "mastery 10")
	eq(Config.Mastery[15].unlock, "Ability cooldown -30%, plus this hero's mastery-15 ability perk", "mastery 15")
end)
