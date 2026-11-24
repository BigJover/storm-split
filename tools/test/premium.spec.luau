--[[
	Premium skins wired into the game (DECISIONS #459/#462/#464/#467; PREMIUM_SKINS.md): the 5
	themes x 17 Robux-only items on the Skins sheet, the 110 Store products (85 singles, 20 class
	packs, 5 theme bundles) at the #467 schedule, granting through the one receipt path (packs and
	bundles grant every item not owned yet, once per PurchaseId), owning a whole class pack ->
	SkinFxPacks -> FX tier 4, the new grenade / ability slots (wear rules, attributes, the save and
	an older save), Robux only (never Amber), and the shop counter's pure Premium rules.
]]
local fs = require("@lune/fs")
local Config = require(src.shared.Config)
local Skins = require(src.shared.Skins)
local Store = require(src.shared.Store)
local SkinFx = require(src.shared.SkinFx)
local Profile = require(src.shared.Profile)

local THEMES = { "LAVA_LORD", "CYBER_RAPTOR", "TYRANT_KING", "NEBULA", "GEODE" }
local PRICE = { hunter = 1600, weapon = 800, tower = 800, grenade = 240, ability = 240 }
local TIER = { hunter = 3, weapon = 1, tower = 1, grenade = 0, ability = 0 }

local function rng(n: number): number
	return 1 + (7 % n)
end

local function premiumKeys(): { string }
	local out = {}
	for _, key in Config.SkinOrder do
		if (Config :: any).Skins[key].robuxOnly then
			table.insert(out, key)
		end
	end
	return out
end

local function sorted(list: { string }): string
	local copy = table.clone(list)
	table.sort(copy)
	return table.concat(copy, ",")
end

local function heroName(hero: string): string
	return (Config.Heroes :: any)[hero].display
end

local NOBODY = function(_: string): boolean
	return false
end

test("#467 sheet: 5 themes x 17 Robux-only items, FX tier by kind, element by theme, every one in SkinFx", function()
	local keys = premiumKeys()
	eq(#keys, 85, "85 premium items")
	eq(table.concat(Skins.themes(), ","), table.concat(THEMES, ","), "theme order = the sheet")
	for _, theme in THEMES do
		eq(#Skins.themeItems(theme), 17, `{theme}: 17 items`)
		eq(#Skins.themeItems(theme, "tower"), 1, `{theme}: one tower set`)
		for _, hero in Config.HeroOrder do
			for _, kind in { "hunter", "weapon", "grenade", "ability" } do
				eq(#Skins.themeItems(theme, kind, hero), 1, `{theme} {hero} {kind}`)
			end
		end
	end
	for _, key in keys do
		local row = Skins.row(key) :: any
		eq(row.price, nil, `{key}: no Amber price`)
		eq(row.level, nil, `{key}: not on the ladder`)
		eq(row.fxTier, TIER[row.kind], `{key}: FX tier`)
		eq(row.element, SkinFx.ELEMENTS[SkinFx.THEME_ELEMENTS[row.theme]] and SkinFx.THEME_ELEMENTS[row.theme], `{key}: element`)
		local item = SkinFx.item(key) :: any
		ok(item ~= nil, `{key} is a SkinFx item`)
		eq(item.kind, row.kind, `{key} kind`)
		eq(item.hero, row.hero, `{key} hero`)
		eq(item.theme, row.theme, `{key} theme`)
		eq(item.fxTier, row.fxTier, `{key}: SkinFx tier = the sheet's`)
		ok(Skins.isPremium(key), `{key} premium`)
	end
	local n = 0
	for _ in SkinFx.ITEMS do
		n += 1
	end
	eq(n, 85, "SkinFx.ITEMS = exactly the sheet's premium rows")
	eq(Skins.isPremium("GOLD_RUSH_SAFARI"), false, "the basic line stays basic")
	eq(SkinFx.item("GOLD_RUSH_SAFARI"), nil)
end)

test("#467 Store: 110 products at the schedule, ids blank, the Premium tab, packs = SkinFx packs", function()
	local singles, packs, bundles = 0, 0, 0
	for _, key in Store.order() do
		if Store.isPremium(key) then
			local row = Store.row(key) :: any
			eq(row.tab, "Premium", `{key} tab`)
			eq(row.id, nil, `{key}: id blank until Jovan creates it`)
			eq(Store.shown(key, false), false, `{key}: hidden until published`)
			local kind = Store.premiumKind(key)
			if kind == "single" then
				singles += 1
				local s = Skins.row(row.items[1]) :: any
				eq(row.robux, PRICE[s.kind], `{key} single`)
				eq(SkinFx.tierForPrice(row.robux), s.fxTier, `{key}: the tier its price buys (#459)`)
				eq(Store.singleFor(row.items[1]), key)
			elseif kind == "pack" then
				packs += 1
				eq(row.robux, 3200, `{key} pack`)
				eq(#row.items, 5, `{key}: hunter + gun + grenade + ability + tower set`)
			else
				bundles += 1
				eq(row.robux, 9600, `{key} bundle`)
				eq(#row.items, 17, `{key}: the whole theme`)
			end
		end
	end
	eq(singles, 85, "every item sold alone")
	eq(packs, 20, "4 class packs per theme")
	eq(bundles, 5, "1 bundle per theme")
	local fxPacks = 0
	for packKey, pack in SkinFx.PACKS do
		fxPacks += 1
		local products = Store.premiumProducts(pack.theme, Config.HeroOrder)
		local found = false
		for _, key in products.packs do
			if sorted((Store.row(key) :: any).items) == sorted(pack.items) then
				found = true
			end
		end
		ok(found, `{packKey}: a Store pack sells exactly its items`)
		eq(sorted(pack.items), sorted(Skins.classPack(pack.theme, pack.hero) :: any), `{packKey} = Skins.classPack`)
	end
	eq(fxPacks, 20, "SkinFx.PACKS = 5 themes x 4 classes")
	for _, theme in THEMES do
		local p = Store.premiumProducts(theme, Config.HeroOrder)
		ok(p.bundle ~= nil, `{theme} bundle`)
		eq(#p.packs, 4, `{theme} packs`)
		eq(#p.singles, 17, `{theme} singles`)
	end
end)

test("#467 savings: a pack saves R$480 vs its singles, a bundle R$800 vs its packs (tower set once)", function()
	local pack = Store.premiumProducts("LAVA_LORD", Config.HeroOrder).packs[2]
	eq(pack, "LAVA_LORD_RIFLE_PACK")
	eq(Store.singlesTotal(pack), 3680, "1,600 + 800 + 800 + 240 + 240")
	local saved, against = Store.savings(pack, Config.HeroOrder)
	eq(saved, 480)
	eq(against, "singles")
	saved, against = Store.savings("LAVA_LORD_BUNDLE", Config.HeroOrder)
	eq(saved, 800, "4 x 3,200 - 3 x 800 - 9,600")
	eq(against, "packs")
	eq(Store.savings("MAGMA_MONARCH", Config.HeroOrder), nil, "a single saves nothing")
	eq(Store.priceLabel("LAVA_LORD_BUNDLE"), "R$9,600")
	eq(Store.priceLabel("AMBER_SACK"), "R$49", "small prices unchanged")
end)

test("Robux only: a premium skin can't be bought with Amber, whatever the wallet", function()
	local state = Skins.blank()
	for _, key in premiumKeys() do
		local price, why = Skins.canBuy(state, key, 999)
		eq(price, nil, `{key}: no Amber price`)
		ok(string.find(why, "Robux only", 1, true) ~= nil, `{key}: says Robux only`)
		ok(not Skins.owns(state, key, 999), `{key}: no level unlocks it`)
	end
	eq(Skins.line(state, "MAGMA_MONARCH", 1, 1600), "Magma Monarch — Robux only: R$1,600")
	eq(Skins.line(state, "MAGMA_MONARCH", 1), "Magma Monarch — Robux only")
	-- Server/Progression's buySkin refuses through canBuy before any Amber moves.
	local prog = fs.readFile("src/server/Progression.luau")
	local buy = string.find(prog, "Skins.canBuy(profile.skins, a, level)", 1, true)
	local pay = string.find(prog, "profile.cores -= price", 1, true)
	ok(buy ~= nil and pay ~= nil and buy < pay, "canBuy gates the Amber payment")
end)

test("grant: a pack grants every item, one you partly own grants the rest, once per PurchaseId", function()
	local state = Skins.blank()
	local ledger = Store.blank()
	local row = Store.row("LAVA_LORD_RIFLE_PACK") :: any
	Skins.grant(state, { "MAGMA_MONARCH", "LAVA_LORD" }) -- bought two singles earlier
	local calls, added = 0, 0
	local function receipt(id: string): string
		return Store.processReceipt(true, ledger, id, "LAVA_LORD_RIFLE_PACK", function(): boolean
			calls += 1
			added += Skins.grant(state, row.items)
			return true
		end, function(): boolean
			return true
		end)
	end
	eq(receipt("P1"), Store.GRANTED)
	eq(added, 3, "the three it lacked")
	for _, item in row.items do
		ok(state.owned[item], `{item} owned`)
	end
	eq(receipt("P1"), Store.GRANTED, "a retry answers Granted")
	eq(calls, 1, "...and grants nothing twice")
	-- a failed save: kept, retried, still granted once
	local failed = Store.processReceipt(true, ledger, "P2", "LAVA_LORD_BUNDLE", function(): boolean
		calls += 1
		Skins.grant(state, (Store.row("LAVA_LORD_BUNDLE") :: any).items)
		return true
	end, function(): boolean
		return false
	end)
	eq(failed, Store.NOT_YET)
	eq(#Skins.themeItems("LAVA_LORD"), 17)
	for _, item in Skins.themeItems("LAVA_LORD") do
		ok(state.owned[item], `bundle: {item}`)
	end
	eq(Store.processReceipt(true, ledger, "P2", "LAVA_LORD_BUNDLE", function(): boolean
		calls += 1
		return true
	end, function(): boolean
		return true
	end), Store.GRANTED)
	eq(calls, 2, "the bundle granted once across the retry")
	ok(Store.hasAll("LAVA_LORD_BUNDLE", function(item)
		return state.owned[item] == true
	end), "now fully owned: not prompted again")
	eq(Store.processReceipt(false, ledger, "P3", "LAVA_LORD_BUNDLE", function(): boolean
		error("a profile that didn't load is never granted")
	end, function(): boolean
		return true
	end), Store.NOT_YET)
	-- the server refuses a product you own whole, and grants through Progression only
	local server = fs.readFile("src/server/Store.luau")
	ok(string.find(server, "StoreRules.hasAll(key", 1, true) ~= nil, "Server/Store: fully owned -> Already yours")
	local prog = fs.readFile("src/server/Progression.luau")
	ok(string.find(prog, "Skins.grant(p.skins, r.items)", 1, true) ~= nil, "the receipt's skins grant")
end)

test("pack => SkinFxPacks => tier 4: whole packs only, from singles too; a bundle owns all four", function()
	local state = Skins.blank()
	local pack = SkinFx.PACKS.CYBER_RAPTOR_SHOTGUN
	ok(pack ~= nil, "Cyber Raptor - Brush Beater pack")
	eq(pack.display, "Cyber Raptor - Brush Beater Pack")
	for i, item in pack.items do
		eq(#SkinFx.ownedPacks(state.owned), 0, `{i - 1} of 5: no pack`)
		Skins.grant(state, { item })
	end
	eq(SkinFx.packsValue(SkinFx.ownedPacks(state.owned)), "CYBER_RAPTOR_SHOTGUN", "five singles = the pack")
	local packs = SkinFx.parsePacks(SkinFx.packsValue(SkinFx.ownedPacks(state.owned)))
	for _, item in pack.items do
		eq(SkinFx.tier(item, nil, false, packs), SkinFx.PACK_TIER, `{item}: pack tier`)
	end
	eq(SkinFx.tier("PLASMA_SIX", nil, false, packs), 1, "another class's gun: its own tier")
	eq(SkinFx.tier("PIXEL_PREDATOR", nil, false, packs), 3)
	local whole = Skins.blank()
	Skins.grant(whole, (Store.row("GEODE_BUNDLE") :: any).items)
	eq(SkinFx.packsValue(SkinFx.ownedPacks(whole.owned)), "GEODE_MEDIC,GEODE_PISTOL,GEODE_RIFLE,GEODE_SHOTGUN", "a bundle = 4 packs")
	local prog = fs.readFile("src/server/Progression.luau")
	ok(string.find(prog, "player:SetAttribute(SkinFx.PACKS_ATTRIBUTE, SkinFx.packsValue(SkinFx.ownedPacks(profile.skins.owned)))", 1, true) ~= nil,
		"Progression publishes SkinFxPacks with the skins (load, wear, receipt)")
end)

test("wear: grenade / ability slots per hero, own kind and hero only, published like the rest", function()
	local state = Skins.blank()
	Skins.grant(state, { "LAVA_LOB", "VOLCANO_ROAR", "MAGMA_CHERRY" })
	eq(select(1, Skins.parseSlot("grenade:RIFLE")), "grenade")
	eq(select(1, Skins.parseSlot("ability:MEDIC")), "ability")
	eq(Skins.parseSlot("grenade:NOPE"), nil, "unknown hero")
	eq(Skins.parseSlot("grenade:SCOUT"), nil, "a tower is no hero")
	ok((Skins.wear(state, "grenade:RIFLE", "LAVA_LOB", 1)), "worn")
	ok((Skins.wear(state, "ability:RIFLE", "VOLCANO_ROAR", 1)), "worn")
	ok(not (Skins.wear(state, "grenade:PISTOL", "LAVA_LOB", 1)), "another hero's grenade")
	ok(not (Skins.wear(state, "ability:RIFLE", "LAVA_LOB", 1)), "a grenade isn't an ability")
	ok(not (Skins.wear(state, "grenade:RIFLE", "VOLCANO_ROAR", 1)), "an ability isn't a grenade")
	ok(not (Skins.wear(state, "grenade:SHOTGUN", "BLAST_FURNACE", 1)), "not owned")
	ok((Skins.wear(state, "grenade:SHOTGUN", "MAGMA_CHERRY", 1)))
	eq(Skins.worn(state, "grenade:RIFLE", 1), "LAVA_LOB")
	eq(Skins.attribute("grenade:RIFLE"), SkinFx.attribute("grenade", "RIFLE"), "Kit reads what Progression writes")
	eq(Skins.attribute("ability:RIFLE"), SkinFx.attribute("ability", "RIFLE"), "Hero reads what Progression writes")
	eq(#Skins.heroSlots(Config.HeroOrder), 16, "4 heroes x hunter, weapon, grenade, ability")
	-- what the worn keys do (visual only)
	eq(SkinFx.grenadeArtKey("RIFLE", Skins.worn(state, "grenade:RIFLE", 1)), "RIFLE_GRENADE_LAVA_LOB", "kit art")
	local white = Color3.new(1, 1, 1)
	ok(SkinFx.blastColours(Skins.worn(state, "grenade:RIFLE", 1), "RIFLE", white) == SkinFx.THEMES.LAVA_LORD.blast, "blast colour")
	ok(SkinFx.abilityColour(Skins.worn(state, "ability:RIFLE", 1), "RIFLE", white) == SkinFx.THEMES.LAVA_LORD.ability, "ability colour")
	ok(SkinFx.abilityColour("VOLCANO_ROAR", "PISTOL", white) == white, "only on its own hero")
	eq(Skins.look("MAGMA_MONARCH") ~= nil, true, "a premium hunter has fallback paint")
	local m = (Skins.look("MAGMA_MONARCH") :: any).material
	ok(m ~= Enum.Material.Neon and m ~= Enum.Material.Glass and m ~= Enum.Material.ForceField, "no glow material (#381)")
	-- Server/Progression publishes every hero slot (incl. grenade / ability)
	local prog = fs.readFile("src/server/Progression.luau")
	ok(string.find(prog, "for _, slot in Skins.heroSlots(Config.HeroOrder) do", 1, true) ~= nil, "published")
end)

test("save: grenade / ability slots round-trip; an older save gains empty slots, keeps everything", function()
	local state = Skins.blank()
	Skins.grant(state, { "PULSE_PUCK", "OVERCLOCK", "MIDNIGHT" })
	Skins.wear(state, "grenade:RIFLE", "PULSE_PUCK", 0)
	Skins.wear(state, "ability:RIFLE", "OVERCLOCK", 0)
	Skins.wear(state, "tower:SCOUT", "MIDNIGHT", 0)
	local back = Skins.sanitize(Skins.toSave(state), 0)
	eq(back.wear["grenade:RIFLE"], "PULSE_PUCK")
	eq(back.wear["ability:RIFLE"], "OVERCLOCK")
	-- an older save (before #467): hunter / weapon / tower slots only, plus junk
	local old = {
		owned = { MIDNIGHT = true, NIGHT_PROWLER = true },
		wear = { ["tower:SCOUT"] = "MIDNIGHT", ["hunter:PISTOL"] = "NIGHT_PROWLER", ["grenade:NOPE"] = "LAVA_LOB" },
		deco = { "SCOUT", "", "" },
		decor = { "", "", "" },
	}
	local migrated = Skins.sanitize(old, 0)
	eq(migrated.wear["tower:SCOUT"], "MIDNIGHT", "kept")
	eq(migrated.wear["hunter:PISTOL"], "NIGHT_PROWLER", "kept")
	eq(migrated.wear["grenade:NOPE"], nil, "junk slot dropped")
	for _, hero in Config.HeroOrder do
		eq(Skins.worn(migrated, `grenade:{hero}`, 0), nil, `{hero}: no grenade skin`)
		eq(Skins.worn(migrated, `ability:{hero}`, 0), nil, `{hero}: no ability skin`)
	end
	eq(#SkinFx.ownedPacks(migrated.owned), 0, "no packs")
	-- a premium key worn but not owned (a doctored save) is dropped
	local doctored = Skins.sanitize({ owned = {}, wear = { ["grenade:RIFLE"] = "LAVA_LOB" } }, 0)
	eq(doctored.wear["grenade:RIFLE"], nil, "not owned: dropped")
	-- through the whole profile
	local profile = Profile.sanitize({ cores = 5000, amberScale = Profile.AMBER_SCALE, skins = old }, 0, rng)
	eq(profile.skins.wear["hunter:PISTOL"], "NIGHT_PROWLER")
	profile.skins = back
	local again = Profile.sanitize(Profile.toSave(profile), 0, rng)
	eq(again.skins.wear["ability:RIFLE"], "OVERCLOCK", "through the profile")
	ok(again.skins.owned.PULSE_PUCK, "owned premium kept")
end)

test("UI rules: the Premium card's button and text (closed, no id, yours, open)", function()
	local key = "TYRANT_KING_MEDIC_PACK"
	local text, can = Store.premiumButton(key, false, false, NOBODY)
	eq(text, "R$3,200", "unpublished: the price, no Buy")
	eq(can, false)
	text, can = Store.premiumButton(key, true, false, NOBODY)
	eq(text, "R$3,200", "no Creator Hub id yet: the price, no Buy")
	eq(can, false)
	local rows = (Config :: any).Store
	local row = table.clone(rows[key])
	row.id = 424242
	Store.rowsOverride = setmetatable({ [key] = row }, { __index = rows }) :: any
	local okRun, err = pcall(function()
		text, can = Store.premiumButton(key, true, false, NOBODY)
		eq(text, "Buy R$3,200", "published with an id")
		eq(can, true)
		text, can = Store.premiumButton(key, false, false, NOBODY)
		eq(can, false, "...but never while the store is closed")
	end)
	Store.rowsOverride = nil
	assert(okRun, err)
	text, can = Store.premiumButton(key, true, false, function()
		return true
	end)
	eq(text, "Yours")
	eq(can, false)
	eq(Store.premiumLine(key, Config.HeroOrder, heroName, NOBODY),
		"Inside: Royal Remedy, Royal Rattler, Tyrant King, Royal Nap, Royal Balm · saves R$480 vs singles · unlocks the full pack effects")
	eq(Store.premiumLine(key, Config.HeroOrder, heroName, function(item)
		return item == "TYRANT_KING"
	end), "New for you: 4 of 5 (you have 1) · saves R$480 vs singles · unlocks the full pack effects")
	eq(Store.premiumLine("TYRANT_KING_BUNDLE", Config.HeroOrder, heroName, NOBODY),
		"All 4 class packs, 17 items (tower set once) · saves R$800 vs packs · every pack's full effects")
	eq(Store.premiumLine("REX_ROYAL", Config.HeroOrder, heroName, NOBODY),
		"Hunter skin for the Big Game Hunter · animated glow, particles and trail · cosmetic only")
	eq(Store.premiumLine("TYRANT_KING", Config.HeroOrder, heroName, NOBODY), "Tower set for every tower · animated glow · cosmetic only")
	eq(Store.premiumLine("ROYAL_BALM", Config.HeroOrder, heroName, NOBODY), "Ability skin for the Field Medic · recoloured effects · cosmetic only")
	eq(Store.premiumLine(key, Config.HeroOrder, heroName, function()
		return true
	end), "You have everything inside")
	for _, theme in THEMES do
		for _, k in Store.order() do
			if Store.premiumTheme(k) == theme then
				local line = string.lower(Store.premiumLine(k, Config.HeroOrder, heroName, NOBODY))
				for _, words in { "free", "guaranteed", "best deal", "limited", "hurry", "last chance" } do
					ok(not string.find(line, words, 1, true), `{k}: no "{words}" (Round 22 wording)`)
				end
			end
		end
	end
end)

test("source guards: the counter never sells premium for Amber; Premium tab shows the closed line; SafeArea kept", function()
	local counter = fs.readFile("src/client/Counter.client.luau")
	ok(string.find(counter, "elseif Skins.isPremium(key) then\n\t\taction = premiumJump(f, key)", 1, true) ~= nil, "skin rows: premium -> the Store, not buySkin")
	ok(string.find(counter, "heading(StoreRules.CLOSED_LINE)", 1, true) ~= nil, "closed line")
	ok(string.find(counter, "StoreRules.premiumButton(key, isOpen", 1, true) ~= nil, "buttons from the pure rule")
	ok(string.find(counter, "SafeArea.topFor(", 1, true) ~= nil, "panel under the CoreGui band / chat (SafeArea)")
	ok(string.find(counter, "{ \"store:Premium\", \"Premium\" }", 1, true) ~= nil, "a Premium store tab")
	ok(string.find(counter, "{ \"grenade\", \"Grenade skins\" }", 1, true) ~= nil, "grenade equip tab")
	ok(string.find(counter, "{ \"ability\", \"Ability skins\" }", 1, true) ~= nil, "ability equip tab")
	local prog = fs.readFile("src/server/Progression.luau")
	ok(string.find(prog, "StudioOnly.allowed(RunService:IsStudio(), \"skins\")", 1, true) ~= nil, "the pack aid is Studio only")
end)
