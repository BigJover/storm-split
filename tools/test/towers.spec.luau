--[[
	Every tower tier does what UPGRADES.md says: each bullet as a TowerStats.compute
	assertion. Tiers are keyed by (tower, path, tier); the name check at the top of each
	test catches a row that moved.
]]

local Config = require(src.shared.Config)
local TowerStats = require(src.shared.TowerStats)

-- The stats of `key` with only `path` bought, up to `tier`, and that tier's name.
local function at(key: string, path: number, tier: number, name: string)
	local def = Config.Towers[key]
	eq(def.paths[path].tiers[tier].name, name, `{key} path {path} T{tier} name`)
	local tiers = { 0, 0, 0 }
	tiers[path] = tier
	return TowerStats.compute(def, tiers), def
end

local function base(key: string)
	return TowerStats.compute(Config.Towers[key], { 0, 0, 0 })
end

-- Hunting Blind -----------------------------------------------------------------

test("Hunting Blind Lookout: Flare Gun +10% rate aura, Signal Tower +20% damage and pierce aura", function()
	local flare = at("SCOUT", 1, 3, "Flare Gun")
	eq(flare.auraRatePercent, 10, "Flare Gun aura rate")
	local signal = at("SCOUT", 1, 5, "Signal Tower")
	eq(signal.auraDamagePercent, 20, "Signal Tower aura damage")
	eq(signal.auraPiercesArmor, true, "Signal Tower aura pierces armour")
	ok(signal.range > base("SCOUT").range, "Lookout grows range")
end)

test("Hunting Blind Trigger Happy: Double Tap 2 shots, Lead Rain fastest fire of any tower tier", function()
	eq(at("SCOUT", 2, 3, "Double Tap").shots, 2, "Double Tap shots")
	local lead = at("SCOUT", 2, 5, "Lead Rain")
	local fastest = lead.shots * lead.rate
	for _, key in Config.TowerOrder do
		for p, path in Config.Towers[key].paths do
			for t in path.tiers do
				local tiers = { 0, 0, 0 }
				tiers[p] = t
				local s = TowerStats.compute(Config.Towers[key], tiers)
				if not (key == "SCOUT" and p == 2 and t == 5) then
					ok(s.shots * s.rate < fastest, `{key} {p}.{t} fires at least as fast as Lead Rain`)
				end
			end
		end
	end
end)

test("Hunting Blind Hardliner: Armor Breaker pierces, Hollow Points x2, Railshot 3, Hide Buster x4/x4", function()
	eq(base("SCOUT").piercesArmor, false, "base can't hurt armour")
	eq(at("SCOUT", 3, 1, "Heavy Slugs").piercesArmor, false, "Heavy Slugs")
	eq(at("SCOUT", 3, 2, "Armor Breaker").piercesArmor, true, "Armor Breaker")
	eq(at("SCOUT", 3, 3, "Hollow Points").armoredMult, 2, "Hollow Points vs armoured")
	eq(at("SCOUT", 3, 4, "Railshot").lineHits, 3, "Railshot line")
	local hide = at("SCOUT", 3, 5, "Hide Buster")
	eq(hide.armoredMult, 4, "Hide Buster vs armoured")
	eq(hide.bossMult, 4, "Hide Buster vs bosses")
	eq(hide.piercesArmor, true, "Hide Buster pierces")
end)

-- Longshot Perch ----------------------------------------------------------------

test("Longshot Perch Deadeye: FMJ 2, Through-and-Through 3 + pierce, Linebreaker 10 and >= 2x Ricochet", function()
	eq(at("SNIPER", 1, 1, "Full Metal Jacket").lineHits, 2, "FMJ line")
	local through = at("SNIPER", 1, 2, "Through-and-Through")
	eq(through.lineHits, 3, "Through-and-Through line")
	eq(through.piercesArmor, true, "Through-and-Through pierces")
	local ricochet = at("SNIPER", 1, 3, "Ricochet")
	local linebreaker = at("SNIPER", 1, 5, "Linebreaker")
	eq(linebreaker.lineHits, 10, "Linebreaker line")
	-- DECISIONS #17: "x2 damage" read as over Ricochet (T3); flagged for Jovan.
	ok(linebreaker.damage >= 2 * ricochet.damage, "Linebreaker damage >= 2x Ricochet")
end)

test("Longshot Perch Spotter: Marked Target mark 25, Eye in the Sky mark 60 and +15% rate aura", function()
	eq(at("SNIPER", 2, 3, "Marked Target").markPercent, 25, "Marked Target mark")
	local eye = at("SNIPER", 2, 5, "Eye in the Sky")
	eq(eye.markPercent, 60, "Eye in the Sky mark")
	eq(eye.auraRatePercent, 15, "Eye in the Sky aura rate")
end)

test("Longshot Perch Big Bore: Bone Breaker boss x3, Concussion stun, Extinction Round boss x10 and stuns bosses", function()
	eq(at("SNIPER", 3, 2, "Bone Breaker").bossMult, 3, "Bone Breaker vs bosses")
	local concussion = at("SNIPER", 3, 3, "Concussion Round")
	ok(concussion.stunSeconds > 0, "Concussion Round stuns")
	eq(concussion.stunsBosses, false, "Concussion Round leaves bosses")
	local sky = at("SNIPER", 3, 5, "Extinction Round")
	eq(sky.bossMult, 10, "Extinction Round vs bosses")
	eq(sky.stunsBosses, true, "Extinction Round stuns bosses")
	ok(sky.stunSeconds > 0, "Extinction Round stuns")
end)

-- Mortar Pit --------------------------------------------------------------------

test("Mortar Pit is area damage, ground only", function()
	eq(Config.Towers.GRENADIER.hitsAir, false, "hits air")
	ok(base("GRENADIER").splashRadius > 0, "splash")
end)

test("Mortar Pit Blast: Napalm burns, Scorched Earth longer and bigger", function()
	local napalm = at("GRENADIER", 1, 3, "Napalm")
	ok(napalm.burnDps > 0 and napalm.burnSeconds > 0, "Napalm burns")
	eq(at("GRENADIER", 1, 2, "Shrapnel").burnDps, 0, "no burn before Napalm")
	local scorched = at("GRENADIER", 1, 5, "Scorched Earth")
	ok(scorched.burnSeconds > napalm.burnSeconds, "Scorched Earth burns longer")
	ok(scorched.splashRadius > napalm.splashRadius, "Scorched Earth burns a bigger stretch")
	ok(scorched.burnDps >= napalm.burnDps, "Scorched Earth burns at least as hot")
end)

test("Mortar Pit Cluster: Cluster Shell 3 bomblets, Chain Reaction 2 generations", function()
	local shell = at("GRENADIER", 2, 1, "Cluster Shell")
	eq(shell.bomblets, 3, "Cluster Shell bomblets")
	eq(shell.bombletGenerations, 1, "Cluster Shell generations")
	eq(at("GRENADIER", 2, 3, "Chain Reaction").bombletGenerations, 2, "Chain Reaction generations")
end)

test("Mortar Pit Concussive: Shockwave, Armor Crack, Stun Grenade, Tectonic Slam 1s", function()
	ok(at("GRENADIER", 3, 1, "Shockwave").knockback > 0, "Shockwave knocks back")
	local crack = at("GRENADIER", 3, 2, "Armor Crack")
	eq(crack.piercesArmor, true, "Armor Crack pierces")
	eq(crack.armoredMult, 2, "Armor Crack vs armoured")
	ok(at("GRENADIER", 3, 3, "Stun Grenade").stunSeconds > 0, "Stun Grenade stuns")
	eq(at("GRENADIER", 3, 5, "Tectonic Slam").stunSeconds, 1, "Tectonic Slam stun")
end)

-- Tranq Station -----------------------------------------------------------------

test("Tranq Station Sedate: slow ladder never drops, Lingering Dose lingers, Deep Sleep slows bosses", function()
	local previous = base("CHILLER").slowPercent
	ok(previous > 0, "base slows")
	local names = { "Mild Dose", "Heavy Dose", "Lingering Dose", "Sedative Cloud", "Deep Sleep" }
	for t, name in names do
		local s = at("CHILLER", 1, t, name)
		ok(s.slowPercent >= previous, `{name} slow doesn't drop`)
		previous = s.slowPercent
	end
	eq(at("CHILLER", 1, 2, "Heavy Dose").slowLinger, 0, "no linger before Lingering Dose")
	ok(at("CHILLER", 1, 3, "Lingering Dose").slowLinger > 0, "Lingering Dose lingers")
	eq(at("CHILLER", 1, 4, "Sedative Cloud").slowsBosses, false, "bosses immune before Deep Sleep")
	eq(at("CHILLER", 1, 5, "Deep Sleep").slowsBosses, true, "Deep Sleep slows bosses")
end)

test("Tranq Station Knockout: periodic knockout, Barbed Darts damage, Big Game Tranq holds bosses", function()
	eq(base("CHILLER").freezeEvery, 0, "no knockout at base")
	local dart = at("CHILLER", 2, 1, "Knockout Dart")
	ok(dart.freezeEvery > 0 and dart.freezeSeconds > 0, "Knockout Dart pulses")
	eq(dart.freezeDamage, 0, "Knockout Dart pulse deals no damage")
	ok(at("CHILLER", 2, 3, "Barbed Darts").freezeDamage > 0, "Barbed Darts pulse damages")
	local big = at("CHILLER", 2, 5, "Big Game Tranq")
	eq(big.freezeHoldsBosses, true, "Big Game Tranq holds bosses")
	ok(big.freezeSeconds > dart.freezeSeconds, "Big Game Tranq knocks out longer")
end)

test("Tranq Station Weak Spot: brittle 25/35/75, Find the Gap strips, auras", function()
	eq(at("CHILLER", 3, 1, "Exposed Hide").brittlePercent, 25, "Exposed Hide")
	local crack = at("CHILLER", 3, 2, "Find the Gap")
	eq(crack.brittlePercent, 35, "Find the Gap")
	eq(crack.stripsArmor, true, "Find the Gap strips armour")
	eq(at("CHILLER", 3, 3, "Hunter's Call").auraRatePercent, 10, "Hunter's Call aura rate")
	local apex = at("CHILLER", 3, 5, "Apex Predator")
	eq(apex.brittlePercent, 75, "Apex Predator")
	eq(apex.auraDamagePercent, 20, "Apex Predator aura damage")
end)

-- Supply Camp -------------------------------------------------------------------

test("Supply Camp never shoots and pays income", function()
	local s = base("QUARTERMASTER")
	ok(s.rate <= 0 or s.damage <= 0, "doesn't shoot")
	ok(Config.Towers.QUARTERMASTER.incomePerRound > 0, "income per round")
end)

test("Supply Camp Yield: income grows, Amber Vault pays interest", function()
	local previous = 1
	local names = { "Supply Crate", "Bigger Budget", "Trade Route", "War Chest", "Amber Vault" }
	for t, name in names do
		local s = at("QUARTERMASTER", 1, t, name)
		ok(s.incomeMult > previous, `{name} raises income`)
		previous = s.incomeMult
	end
	local vault = at("QUARTERMASTER", 1, 5, "Amber Vault")
	ok(vault.interestPercent > 0 and vault.interestCap > 0, "Amber Vault interest")
	eq(at("QUARTERMASTER", 1, 4, "War Chest").interestPercent, 0, "no interest before Amber Vault")
end)

test("Supply Camp Airdrop: Air Drop lands chests, more and richer after", function()
	local drop = at("QUARTERMASTER", 2, 1, "Air Drop")
	ok(drop.chests >= 1 and drop.chestCash > 0, "Air Drop chests")
	local haul = at("QUARTERMASTER", 2, 5, "Treasure Haul")
	ok(haul.chests > drop.chests and haul.chestCash > drop.chestCash, "Treasure Haul more and richer")
end)

test("Supply Camp Logistics: Bulk Order -5%, Recycler 90%, Forward Camp +10% rate, Base Camp -20% and 100%", function()
	eq(at("QUARTERMASTER", 3, 1, "Bulk Order").discountPercent, 5, "Bulk Order")
	eq(at("QUARTERMASTER", 3, 3, "Recycler").sellRefund, 0.9, "Recycler")
	eq(at("QUARTERMASTER", 3, 4, "Forward Camp").auraRatePercent, 10, "Forward Camp aura rate")
	local command = at("QUARTERMASTER", 3, 5, "Base Camp")
	eq(command.discountPercent, 20, "Base Camp discount")
	eq(command.sellRefund, 1, "Base Camp refund")
end)

-- Armory (DECISIONS #16, names per #25) -------------------------------------------

test("Armory: 600, range 15, no attack, 250 HP, 15% resist, unlock 150", function()
	local def = Config.Towers.ARMORY
	eq(def.display, "Armory")
	eq(def.baseCost, 600, "cost")
	eq(def.range, 15, "range")
	eq(def.hitsAir, false, "hits air")
	eq(def.maxHp, 250, "Max HP")
	eq(def.unlockCost, 150, "unlock")
	local s = base("ARMORY")
	ok(s.rate <= 0 or s.damage <= 0, "never shoots")
	eq(s.resistPercent, 15, "resist aura")
end)

test("Armory Plating: 20/25/25/35/45 resist, Thorn Plating 3, Tempered Steel 5, Bulwark stuns 0.5s", function()
	local names = { "Hide Padding", "Iron Plates", "Thorn Plating", "Tempered Steel", "Bulwark" }
	local resist = { 20, 25, 25, 35, 45 }
	local thorns = { 0, 0, 3, 5, 5 }
	local stun = { 0, 0, 0, 0, 0.5 }
	for t, name in names do
		local s = at("ARMORY", 1, t, name)
		eq(s.resistPercent, resist[t], `{name} resist`)
		eq(s.thornsDamage, thorns[t], `{name} thorns`)
		eq(s.stunBitersSeconds, stun[t], `{name} stuns biters`)
		ok(s.resistPercent <= Config.Tuning.MaxResist, `{name} under the resist cap`)
	end
end)

test("Armory Gunsmith: Oiled Actions +5% rate, Hand Loads +10% damage, Piercing Rounds, Match Grade, Master Gunsmith", function()
	local oiled = at("ARMORY", 2, 1, "Oiled Actions")
	eq(oiled.auraRatePercent, 5, "Oiled Actions rate")
	eq(oiled.auraDamagePercent, 0, "no damage yet")
	eq(at("ARMORY", 2, 2, "Hand Loads").auraDamagePercent, 10, "Hand Loads damage")
	eq(at("ARMORY", 2, 2, "Hand Loads").auraPiercesArmor, false, "no pierce yet")
	eq(at("ARMORY", 2, 3, "Piercing Rounds").auraPiercesArmor, true, "Piercing Rounds")
	local match = at("ARMORY", 2, 4, "Match Grade")
	eq(match.auraDamagePercent, 20, "Match Grade damage")
	eq(match.auraRatePercent, 10, "Match Grade rate")
	local master = at("ARMORY", 2, 5, "Master Gunsmith")
	eq(master.auraDamagePercent, 30, "Master Gunsmith damage")
	eq(master.auraRatePercent, 15, "Master Gunsmith rate")
	eq(master.resistPercent, 15, "keeps the base resist")
end)

test("Armory Outfitter: Wide Rack range, Recoil Pads, Ammo Crate, Steady Rests, Full Kit", function()
	local def = Config.Towers.ARMORY
	near(at("ARMORY", 3, 1, "Wide Rack").range, def.range * 1.3, "Wide Rack range x1.3")
	eq(at("ARMORY", 3, 2, "Recoil Pads").hunterRecoilMult, 0.75, "Recoil Pads")
	eq(at("ARMORY", 3, 3, "Ammo Crate").hunterReloadMult, 0.65, "Ammo Crate")
	eq(at("ARMORY", 3, 4, "Steady Rests").hunterSpreadMult, 0.7, "Steady Rests")
	local kit = at("ARMORY", 3, 5, "Full Kit")
	near(kit.range, def.range * 1.5, "Full Kit range x1.5")
	eq(kit.hunterRatePercent, 20, "Full Kit fire rate")
	eq(kit.hunterRecoilMult, 0.75, "keeps Recoil Pads")
end)

test("Armory crossover: Bulwark + Hand Loads keeps both", function()
	local s = TowerStats.compute(Config.Towers.ARMORY, { 5, 2, 0 })
	eq(s.resistPercent, 45, "resist")
	eq(s.stunBitersSeconds, 0.5, "stun")
	eq(s.auraDamagePercent, 10, "aura damage")
end)

-- Field Hospital (DECISIONS #15, names per #25) -----------------------------------

test("Field Hospital: 450, range 15, no attack, 150 HP, heals 3/s, unlock 100", function()
	local def = Config.Towers.HOSPITAL
	eq(def.display, "Field Hospital")
	eq(def.baseCost, 450, "cost")
	eq(def.range, 15, "range")
	eq(def.hitsAir, false, "hits air")
	eq(def.maxHp, 150, "Max HP")
	eq(def.unlockCost, 100, "unlock")
	local s = base("HOSPITAL")
	ok(s.rate <= 0 or s.damage <= 0, "never shoots")
	eq(s.healPerSecond, 3, "heal")
	eq(s.revives, false, "no revive yet")
	eq(s.medKits, 0, "no kits yet")
	eq(s.rescueRespawnMult, 0, "no beacon yet")
	eq(s.auraHpPercent, 0, "no Tonic yet")
	eq(s.lastStand, false, "no Last Stand yet")
end)

test("Field Hospital Ward: heal x1.5/2/2.5/3/4.5, Stitch-Up revives at half speed, Miracle Ward at full", function()
	local names = { "Clean Linens", "Extra Cots", "Stitch-Up", "Night Shift", "Miracle Ward" }
	local heal = { 1.5, 2, 2.5, 3, 4.5 }
	local revives = { false, false, true, true, true }
	local speed = { 0, 0, 0.5, 0.5, 1 }
	for t, name in names do
		local s = at("HOSPITAL", 1, t, name)
		near(s.healPerSecond, 3 * heal[t], `{name} heal`)
		eq(s.revives, revives[t], `{name} revives`)
		eq(s.reviveSpeed, speed[t], `{name} revive speed`)
	end
end)

test("Field Hospital Rescue: range x1.2/1.4, Med Kits 2x30, Pack Mules 3x40, Rescue Beacon x1.8, 50, half respawn", function()
	local def = Config.Towers.HOSPITAL
	near(at("HOSPITAL", 2, 1, "Stretcher Team").range, def.range * 1.2, "Stretcher Team range")
	near(at("HOSPITAL", 2, 2, "Signal Whistle").range, def.range * 1.4, "Signal Whistle range")
	local kits = at("HOSPITAL", 2, 3, "Med Kits")
	eq(kits.medKits, 2, "Med Kits count")
	eq(kits.medKitHeal, 30, "Med Kits heal")
	eq(kits.rescueRespawnMult, 0, "no beacon yet")
	local runs = at("HOSPITAL", 2, 4, "Pack Mules")
	eq(runs.medKits, 3, "Pack Mules count")
	eq(runs.medKitHeal, 40, "Pack Mules heal")
	local beacon = at("HOSPITAL", 2, 5, "Rescue Beacon")
	near(beacon.range, def.range * 1.8, "Rescue Beacon range")
	eq(beacon.medKits, 3, "keeps 3 kits")
	eq(beacon.medKitHeal, 50, "Rescue Beacon kits heal")
	eq(beacon.rescueRespawnMult, 0.5, "half the respawn time")
	near(beacon.healPerSecond, 3, "Rescue doesn't speed healing")
end)

test("Field Hospital Tonic: +10/20% HP, Smelling Salts +10% rate, Bone Broth +35%, Last Stand +50% once a round", function()
	local names = { "Camp Rations", "Iron Tonic", "Smelling Salts", "Bone Broth", "Last Stand" }
	local hp = { 10, 20, 20, 35, 50 }
	local rate = { 0, 0, 10, 10, 10 }
	for t, name in names do
		local s = at("HOSPITAL", 3, t, name)
		eq(s.auraHpPercent, hp[t], `{name} aura HP`)
		eq(s.auraRatePercent, rate[t], `{name} aura rate`)
		eq(s.lastStand, t == 5, `{name} Last Stand`)
	end
end)

test("Field Hospital crossover: Miracle Ward + Iron Tonic keeps both", function()
	local s = TowerStats.compute(Config.Towers.HOSPITAL, { 5, 0, 2 })
	near(s.healPerSecond, 13.5, "heal")
	eq(s.reviveSpeed, 1, "revive speed")
	eq(s.auraHpPercent, 20, "aura HP")
end)

test("PLAN T68: the round-4 towers are released at 2x Amber and their tuned in-match prices", function()
	local ShopRules = require(src.shared.ShopRules)
	-- key = { Amber unlock (#147), in-match cost (#194/#195) }
	local want = { COIL = { 300, 400 }, FALCON = { 200, 400 }, TARPIT = { 250, 450 }, BALLISTA = { 300, 500 } }
	for key, w in want do
		local def = Config.Towers[key]
		eq(ShopRules.Unreleased[key], nil, `{key} is sold and unlockable`)
		eq(table.find(Config.TowerOrder, key) ~= nil, true, `{key} is listed in the shop order`)
		eq(def.unlockCost, w[1], `{key} unlock Amber`)
		eq(def.baseCost, w[2], `{key} in-match cost`)
	end
end)
