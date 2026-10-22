--[[
	Skins and Campsite Display Towers (PLAN 10e T142, DECISIONS #380/#381/#384, names
	DINO_REVIEW Round 22): the catalogue, owning (bought, granted, level), wearing per slot,
	Display Towers, the save, and the readability guards — a tower set changes only colours
	and materials (silhouette, range ring, crown/glow, HP bar untouched), a hunter skin never
	paints the head or root and never changes size or transparency.
]]
local fs = require("@lune/fs")
local Config = require(src.shared.Config)
local Skins = require(src.shared.Skins)
local TowerLook = require(src.shared.TowerLook)
local Profile = require(src.shared.Profile)

local function rng(n: number): number
	return 1 + (7 % n)
end

-- A copy of a sheet row with a price / level, swapped in for one test.
local function withRow(key: string, fields: { [string]: any }, body: () -> ())
	local rows = (Config :: any).Skins
	local row = table.clone(rows[key])
	for k, v in fields do
		row[k] = v
	end
	Skins.rowsOverride = setmetatable({ [key] = row }, { __index = rows }) :: any
	local ok, err = pcall(body)
	Skins.rowsOverride = nil
	assert(ok, err)
end

test("the catalogue is Round 22: 3 hunter skins per hunter, 2 weapon skins per gun, 5 tower sets", function()
	local names = {}
	for _, hero in Config.HeroOrder do
		eq(#Skins.catalogue("hunter", hero), 3, `{hero} hunter skins`)
		eq(#Skins.catalogue("weapon", hero), 2, `{hero} weapon skins`)
	end
	local sets = Skins.catalogue("tower", nil)
	for _, key in sets do
		table.insert(names, Skins.row(key).display)
	end
	eq(table.concat(names, ", "), "Treehouse, Stone Age, Brass Gear, Midnight, Gold Rush", "tower sets")
	eq(Skins.row("SWAMP_STALKER").display, "Swamp Stalker")
	eq(Skins.row("LIFESAVER").hero, "MEDIC")
	for _, key in Config.SkinOrder do
		local look = Skins.look(key)
		ok(look and look.material ~= Enum.Material.Neon and look.material ~= Enum.Material.Glass and look.material ~= Enum.Material.ForceField, `{key}: no glow or see-through`)
	end
end)

test("owning: blank price = not for sale, a price sells it, a level unlocks it, a bundle grants it", function()
	local state = Skins.blank()
	withRow("NIGHT_PROWLER", { price = 0 }, function()
		Skins.rowsOverride.NIGHT_PROWLER.price = nil -- a blank price
		local price, why = Skins.canBuy(state, "NIGHT_PROWLER", 1)
		eq(price, nil)
		eq(why, "Not for sale yet")
	end)
	withRow("NIGHT_PROWLER", { price = 25000 }, function()
		local p = Skins.canBuy(state, "NIGHT_PROWLER", 1)
		eq(p, 25000, "priced")
		ok(Skins.buy(state, "NIGHT_PROWLER"))
		eq(Skins.canBuy(state, "NIGHT_PROWLER", 1), nil, "already yours")
	end)
	ok(Skins.owns(state, "NIGHT_PROWLER", 0))
	withRow("JUNGLE_GHOST", { level = 12 }, function()
		ok(not Skins.owns(state, "JUNGLE_GHOST", 11), "level 11")
		ok(Skins.owns(state, "JUNGLE_GHOST", 12), "level 12 (derived, not stored)")
		eq(state.owned.JUNGLE_GHOST, nil)
	end)
	eq(Skins.grant(state, { "TREEHOUSE", "NOT_A_SKIN", "TREEHOUSE", "NIGHT_PROWLER" }), 1, "one new, unknown skipped")
	eq(state.owned.NOT_A_SKIN, nil)
	ok(not Skins.buy(state, "NOT_A_SKIN"))
end)

test("wearing: one slot per kind and hero; a tower set fits any tower; only what you own", function()
	local state = Skins.blank()
	Skins.grant(state, { "SWAMP_STALKER", "SNAKESKIN_GRIP", "MIDNIGHT" })
	local okWear = Skins.wear(state, "hunter:PISTOL", "SWAMP_STALKER", 0)
	ok(okWear, "Tracker wears Swamp Stalker")
	ok(not (Skins.wear(state, "hunter:RIFLE", "SWAMP_STALKER", 0)), "not on Big Game Hunter")
	ok(not (Skins.wear(state, "weapon:PISTOL", "SWAMP_STALKER", 0)), "a hunter skin isn't a weapon skin")
	ok((Skins.wear(state, "weapon:PISTOL", "SNAKESKIN_GRIP", 0)))
	ok((Skins.wear(state, "tower:SCOUT", "MIDNIGHT", 0)))
	ok((Skins.wear(state, "tower:RANGER", "MIDNIGHT", 0)), "any tower")
	ok(not (Skins.wear(state, "tower:SCOUT", "GOLD_RUSH", 0)), "not owned")
	ok(not (Skins.wear(state, "tower:NOPE", "MIDNIGHT", 0)), "unknown tower")
	ok(not (Skins.wear(state, "hat", "MIDNIGHT", 0)), "not a skin slot")
	eq(Skins.worn(state, "tower:SCOUT", 0), "MIDNIGHT")
	ok((Skins.wear(state, "tower:SCOUT", "", 0)))
	eq(Skins.worn(state, "tower:SCOUT", 0), nil, "taken off")
	eq(Skins.attribute("tower:SCOUT"), "Skin_tower_SCOUT")
end)

test("Display Towers: up to 3, only towers you own, clearable", function()
	local state = Skins.blank()
	local function owns(t: string): boolean
		return t == "SCOUT" or t == "SNIPER"
	end
	ok((Skins.setDeco(state, 2, "SNIPER", owns)), "spot 2")
	eq(state.deco[1], "", "spot 1 left empty")
	ok(not (Skins.setDeco(state, 1, "RESIN", owns)), "not owned")
	ok(not (Skins.setDeco(state, 4, "SCOUT", owns)), "only 3 spots")
	ok(not (Skins.setDeco(state, 1, "NOPE", owns)), "unknown")
	ok((Skins.setDeco(state, 2, "", owns)))
	eq(state.deco[2], "")
end)

test("the save: round trip, a dropped sheet key kept, garbage refused, older save = none", function()
	local state = Skins.blank()
	Skins.grant(state, { "MIDNIGHT", "SWAMP_STALKER" })
	Skins.wear(state, "tower:SCOUT", "MIDNIGHT", 0)
	Skins.setDeco(state, 1, "SCOUT", function()
		return true
	end)
	local saved = Skins.toSave(state)
	saved.owned.GONE_FROM_SHEET = true
	saved.wear["hunter:PISTOL"] = "GOLD_RUSH" -- wrong kind
	saved.wear["weapon:PISTOL"] = "SILVER_SPUR" -- not owned
	local back = Skins.sanitize(saved, 0)
	ok(back.owned.MIDNIGHT and back.owned.GONE_FROM_SHEET, "owned kept, even a dropped key")
	eq(back.wear["tower:SCOUT"], "MIDNIGHT")
	eq(back.wear["hunter:PISTOL"], nil, "wrong kind dropped")
	eq(back.wear["weapon:PISTOL"], nil, "not owned dropped")
	eq(back.deco[1], "SCOUT")
	eq(next(Skins.sanitize("junk", 0).owned), nil)
	local profile = Profile.sanitize({ cores = 5000, amberScale = Profile.AMBER_SCALE }, 0, rng)
	eq(next(profile.skins.owned), nil, "an older save has no skins")
	profile.skins = back
	local again = Profile.sanitize(Profile.toSave(profile), 0, rng)
	ok(again.skins.owned.MIDNIGHT and again.skins.wear["tower:SCOUT"] == "MIDNIGHT", "through the profile")
end)

-- Every visible property of a built tower except colour and material, by part.
local function shape(model: Model): { [string]: string }
	local out = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			out[part.Name .. "@" .. tostring(part.CFrame.Position)] = table.concat({
				tostring(part.Size),
				tostring(part.CFrame),
				tostring(part.Shape),
				tostring(part.Transparency),
				tostring(part.CanCollide),
				tostring(part.CanQuery),
			}, "|")
		elseif part:IsA("BillboardGui") then
			out["gui:" .. part.Name] = tostring(part.Size) .. tostring(part.StudsOffset) .. tostring(part.Enabled)
		end
	end
	return out
end

local function same(a: { [string]: string }, b: { [string]: string }): (boolean, string?)
	for k, v in a do
		if b[k] ~= v then
			return false, k
		end
	end
	for k in b do
		if a[k] == nil then
			return false, k
		end
	end
	return true, nil
end

test("a tower set changes only colours and materials: silhouette, ring, crown/glow and HP bar untouched (#381)", function()
	local base = Vector3.new(0, 0, 0)
	for _, key in Config.TowerOrder do
		local def = Config.Towers[key]
		if TowerLook.hasSilhouette(key) then
			for _, set in Skins.catalogue("tower", nil) do
				local plain = TowerLook.build(key, def.range, base)
				local skinned = TowerLook.build(key, def.range, base)
				TowerLook.applySkin(skinned, Skins.look(set))
				for _, m in { plain, skinned } do
					TowerLook.refresh(m, def.range, { 5, 0, 0 }, 2) -- crowned and glowing
					TowerLook.setHealth(m, 0.5)
				end
				local equal, where = same(shape(plain), shape(skinned))
				ok(equal, `{key} + {set}: {where}`)
				local ring, ring2 = plain:FindFirstChild("Range"), skinned:FindFirstChild("Range")
				eq(ring and (ring :: BasePart).Color, ring2 and (ring2 :: BasePart).Color, `{key} + {set}: ring colour`)
				local crown, crown2 = plain:FindFirstChild("Crown"), skinned:FindFirstChild("Crown")
				ok(crown and crown2 and (crown :: BasePart).Color == (crown2 :: BasePart).Color, `{key} + {set}: crown`)
				local glowing = 0
				for _, part in skinned:GetChildren() do
					if part:IsA("BasePart") and part:GetAttribute("LookMaterial") then
						eq(part.Material, Enum.Material.Neon, `{key} + {set}: tier-5 glow still shows`)
						glowing += 1
					end
				end
				ok(glowing > 0, `{key}: has look parts`)
				TowerLook.refresh(skinned, def.range, { 0, 0, 0 }, 0)
				for _, part in skinned:GetChildren() do
					if part:IsA("BasePart") and part:GetAttribute("LookMaterial") then
						eq(part.Material, Skins.look(set).material, `{key} + {set}: glow off = the set's material`)
					end
				end
			end
		end
	end
end)

test("the shape check can fail: a resized block, a moved block or a hidden ring is caught", function()
	local def = Config.Towers.SCOUT
	local plain = TowerLook.build("SCOUT", def.range, Vector3.zero)
	for _, doctor in {
		function(m: Model)
			for _, p in m:GetChildren() do
				if p:IsA("BasePart") and p:GetAttribute("LookMaterial") then
					p.Size *= 1.1
					return
				end
			end
		end,
		function(m: Model)
			for _, p in m:GetChildren() do
				if p:IsA("BasePart") and p:GetAttribute("LookMaterial") then
					p.CFrame += Vector3.new(0, 0.5, 0)
					return
				end
			end
		end,
		function(m: Model)
			((m:FindFirstChild("Range") :: BasePart)).Transparency = 1
		end,
	} do
		local bad = TowerLook.build("SCOUT", def.range, Vector3.zero)
		doctor(bad)
		ok(not (same(shape(plain), shape(bad))), "doctored tower caught")
	end
end)

test("a hunter skin paints torso, arms and legs only; never the head, root or a hat", function()
	local look = Skins.look("SAFARI_CHIEF") :: Skins.Look
	for _, name in { "Head", "HumanoidRootPart", "Handle", "CosmeticHat" } do
		eq((Skins.hunterPaint(name, look)), nil, name)
	end
	eq((Skins.hunterPaint("UpperTorso", look)), look.colour)
	eq((Skins.hunterPaint("Left Leg", look)), look.accent)
	-- Source guards: the painters set colour and material only.
	local wardrobe = fs.readFile("src/server/Wardrobe.luau")
	local paint = wardrobe:match("local function paintHunter(.-)\nend\n") :: string
	ok(paint ~= nil, "paintHunter found")
	for _, banned in { "Transparency", "Size", "Scale", "DisplayName", "NameDisplay", "CFrame", "Highlight" } do
		ok(paint:find(banned, 1, true) == nil, `paintHunter never touches {banned}`)
	end
	local towerLook = fs.readFile("src/shared/TowerLook.luau")
	local apply = towerLook:match("function TowerLook%.applySkin(.-)\nend\n") :: string
	ok(apply ~= nil, "applySkin found")
	for _, banned in { "Size", "CFrame", "Transparency", "Shape", "Range", "Crown", "Health" } do
		ok(apply:find("." .. banned .. " =", 1, true) == nil, `applySkin never sets {banned}`)
	end
	local hero = fs.readFile("src/server/Hero.luau")
	ok(hero:find("local colour, material, set = Skins.gunPaint(skin, look, maxed)", 1, true) ~= nil, "Hero paints the gun through Skins.gunPaint")
	ok(hero:find("handle.Color = colour", 1, true) ~= nil, "weapon skin: colour")
end)

test("Display Towers are inert: no ring, never registered as towers, not clickable", function()
	local wardrobe = fs.readFile("src/server/Wardrobe.luau")
	ok(wardrobe:find("TowerLook.build(key, 0, at.Position) -- range 0: no ring", 1, true) ~= nil, "range 0")
	ok(wardrobe:find("Towers.", 1, true) == nil, "never handed to Server/Towers")
	ok(wardrobe:find("part.CanQuery = false", 1, true) ~= nil, "can't be clicked or hit")
	local model = TowerLook.build("SCOUT", 0, Vector3.zero)
	eq(model:FindFirstChild("Range"), nil, "no ring at range 0")
end)

-- PLAN T143b (#409): the ladder and the Amber prices, exactly.
test("T143b numbers: level skins at 15/25/35/45/55/65 never sold; every other skin's Amber price", function()
	local levels = { SWAMP_STALKER = 15, SAFARI_CLASSIC = 25, BAMBOO_BASHER = 35, FRONTIER_DOC = 45, WALNUT_CLASSIC = 55, SNAKESKIN_GRIP = 65 }
	local prices = {
		NIGHT_PROWLER = 300000, JUNGLE_GHOST = 500000, SAFARI_CHIEF = 300000, GOLD_RUSH_SAFARI = 900000,
		SWAMP_SMASHER = 300000, CROC_HIDE_CRUSHER = 500000, MOUNTAIN_RESCUE = 300000, LIFELINE = 500000,
		SILVER_SPUR = 250000, ENGRAVED_GOLD = 600000, BAMBOO_BOOMSTICK = 200000, CROC_HIDE = 250000,
		BRASS_SADDLE = 250000, LIFESAVER = 400000,
		TREEHOUSE = 400000, STONE_AGE = 400000, BRASS_GEAR = 600000, MIDNIGHT = 800000, GOLD_RUSH = 1500000,
	}
	local n = 0
	for _, key in Config.SkinOrder do
		local row = Skins.row(key) :: any
		if row.kind == "deco" then
			continue -- T143c (decor.spec)
		end
		n += 1
		if levels[key] then
			eq(row.level, levels[key], `{key} level`)
			eq(row.price, nil, `{key} never sold`)
		else
			eq(row.price, prices[key], `{key} price`)
			eq(row.level, nil, `{key} not on the ladder`)
		end
	end
	eq(n, 25, "25 skins")
end)

test("a level-15 profile owns Swamp Stalker without buying; level 14 is told when", function()
	local state = Skins.blank()
	ok(not Skins.owns(state, "SWAMP_STALKER", 14), "level 14")
	local price, why = Skins.canBuy(state, "SWAMP_STALKER", 14)
	eq(price, nil, "never sold")
	eq(why, "Reach level 15")
	eq(Skins.line(state, "SWAMP_STALKER", 14), "Swamp Stalker — Reach level 15")
	ok(Skins.owns(state, "SWAMP_STALKER", 15), "level 15: yours")
	ok((Skins.wear(state, "hunter:PISTOL", "SWAMP_STALKER", 15)), "and wearable")
	eq(state.owned.SWAMP_STALKER, nil, "derived, not stored")
end)

test("#414 the gun: mastery-20 gold beats a weapon skin; a weapon skin beats sets and tints", function()
	local gold = Color3.fromRGB(250, 200, 60)
	local skin = Skins.look("ENGRAVED_GOLD") :: any
	local set = { colour = Color3.new(0, 0, 1), material = Enum.Material.SmoothPlastic, set = { id = "AURORA" } }
	local tint = { colour = Color3.new(1, 0, 0), material = Enum.Material.SmoothPlastic, set = nil }
	local goldLook = { colour = gold, material = Enum.Material.Neon, set = nil }
	local c, m, s = Skins.gunPaint(skin, goldLook, true)
	ok(c == gold and m == Enum.Material.Neon and s == nil, "maxed: gold, even with a skin")
	c, m, s = Skins.gunPaint(skin, set, false)
	ok(c == skin.colour and m == skin.material and s == nil, "skin over an animated set (set dropped)")
	c, m, s = Skins.gunPaint(skin, tint, false)
	ok(c == skin.colour and m == skin.material, "skin over a tint")
	c, m, s = Skins.gunPaint(nil, set, false)
	ok(c == set.colour and s == "AURORA", "no skin: the set, animated")
	c, m, s = Skins.gunPaint(nil, tint, false)
	ok(c == tint.colour and s == nil, "no skin: the tint")
end)
