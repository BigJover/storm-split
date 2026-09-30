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

test("Longshot Perch Siege: Anti-Materiel boss x3, Concussion stun, Skybreaker boss x10 and stuns bosses", function()
	eq(at("SNIPER", 3, 2, "Anti-Materiel").bossMult, 3, "Anti-Materiel vs bosses")
	local concussion = at("SNIPER", 3, 3, "Concussion Round")
	ok(concussion.stunSeconds > 0, "Concussion Round stuns")
	eq(concussion.stunsBosses, false, "Concussion Round leaves bosses")
	local sky = at("SNIPER", 3, 5, "Skybreaker")
	eq(sky.bossMult, 10, "Skybreaker vs bosses")
	eq(sky.stunsBosses, true, "Skybreaker stuns bosses")
	ok(sky.stunSeconds > 0, "Skybreaker stuns")
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

test("Tranq Station Sedate: slow ladder never drops, Lingering Dose lingers, Hibernation slows bosses", function()
	local previous = base("CHILLER").slowPercent
	ok(previous > 0, "base slows")
	local names = { "Mild Dose", "Heavy Dose", "Lingering Dose", "Sedative Cloud", "Hibernation" }
	for t, name in names do
		local s = at("CHILLER", 1, t, name)
		ok(s.slowPercent >= previous, `{name} slow doesn't drop`)
		previous = s.slowPercent
	end
	eq(at("CHILLER", 1, 2, "Heavy Dose").slowLinger, 0, "no linger before Lingering Dose")
	ok(at("CHILLER", 1, 3, "Lingering Dose").slowLinger > 0, "Lingering Dose lingers")
	eq(at("CHILLER", 1, 4, "Sedative Cloud").slowsBosses, false, "bosses immune before Hibernation")
	eq(at("CHILLER", 1, 5, "Hibernation").slowsBosses, true, "Hibernation slows bosses")
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

test("Tranq Station Weak Spot: brittle 25/35/75, Crack Armor strips, auras", function()
	eq(at("CHILLER", 3, 1, "Exposed Hide").brittlePercent, 25, "Exposed Hide")
	local crack = at("CHILLER", 3, 2, "Crack Armor")
	eq(crack.brittlePercent, 35, "Crack Armor")
	eq(crack.stripsArmor, true, "Crack Armor strips armour")
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

test("Supply Camp Logistics: Bulk Order -5%, Recycler 90%, Forward Base +10% rate, Command Center -20% and 100%", function()
	eq(at("QUARTERMASTER", 3, 1, "Bulk Order").discountPercent, 5, "Bulk Order")
	eq(at("QUARTERMASTER", 3, 3, "Recycler").sellRefund, 0.9, "Recycler")
	eq(at("QUARTERMASTER", 3, 4, "Forward Base").auraRatePercent, 10, "Forward Base aura rate")
	local command = at("QUARTERMASTER", 3, 5, "Command Center")
	eq(command.discountPercent, 20, "Command Center discount")
	eq(command.sellRefund, 1, "Command Center refund")
end)
