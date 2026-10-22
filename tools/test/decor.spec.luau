--[[
	Campsite decorations (PLAN 10e T143c, DECISIONS #415; Shared/Skins `decor`, Shared/Decor,
	Server/Wardrobe): the seven rows and their numbers, owning (level or Amber), placing on
	3 spots (owned only, one of each, a move empties the old spot), the save, the inert
	models (anchored, no touch/query, no scripts, seats, lights or sounds), the footprints
	keeping the spots apart, the Wanted Poster's text, the best clear it reads, and that
	only Wardrobe builds them, on Outpost Campsites (never in a match).
]]
local fs = require("@lune/fs")
local Config = require(src.shared.Config)
local Skins = require(src.shared.Skins)
local Decor = require(src.shared.Decor)
local Outpost = require(src.shared.Outpost)
local Profile = require(src.shared.Profile)

local DECOS = {
	{ "FIRE_PIT", "Fire Pit", nil, 5 },
	{ "STEPPING_STONES", "Stepping Stones", nil, 12 },
	{ "HUNTERS_FLAG", "Hunter's Flag", nil, 18 },
	{ "WANTED_POSTER", "Wanted Poster", 100000, nil },
	{ "HAMMOCK", "Hammock", 150000, nil },
	{ "ROPE_SWING", "Rope Swing", 200000, nil },
	{ "DINO_STATUE", "Dino Statue", 500000, nil },
}

test("the seven decorations, exactly as PLAN T143c: three by level, four for Amber", function()
	local keys = Skins.catalogue("deco", nil)
	eq(#keys, 7, "seven")
	for i, d in DECOS do
		local row = Skins.row(d[1]) :: any
		eq(keys[i], d[1], `order {i}`)
		eq(row.kind, "deco", d[1])
		eq(row.display, d[2], `{d[1]} name`)
		eq(row.price, d[3], `{d[1]} price`)
		eq(row.level, d[4], `{d[1]} level`)
		eq(row.hero, nil, `{d[1]} fits any Campsite`)
	end
	ok(table.find(Skins.KINDS, "deco") ~= nil, "a Skins kind")
end)

test("owning and placing: owned only, 3 spots, one of each (a move empties the old spot), clearable", function()
	local state = Skins.blank()
	local okSet, why = Skins.setDecor(state, 1, "FIRE_PIT", 4)
	ok(not okSet and why == "Not yours yet", "level 4: no Fire Pit")
	ok((Skins.setDecor(state, 1, "FIRE_PIT", 5)), "level 5: placed")
	ok(not (Skins.setDecor(state, 2, "HAMMOCK", 99)), "a bought one only once bought")
	ok(Skins.buy(state, "HAMMOCK"))
	ok((Skins.setDecor(state, 2, "HAMMOCK", 5)), "bought: placed")
	ok(not (Skins.setDecor(state, 4, "HAMMOCK", 5)), "no 4th spot")
	ok(not (Skins.setDecor(state, 0, "HAMMOCK", 5)), "no spot 0")
	ok(not (Skins.setDecor(state, 3, "TREEHOUSE", 99)), "a tower set is not a decoration")
	ok(not (Skins.setDecor(state, 3, "NOPE", 99)), "unknown")
	ok((Skins.setDecor(state, 3, "FIRE_PIT", 5)), "the Fire Pit moves to spot 3")
	eq(state.decor[1], "", "and spot 1 empties: one of each")
	eq(state.decor[3], "FIRE_PIT")
	ok((Skins.setDecor(state, 2, "", 5)), "cleared")
	eq(state.decor[2], "")
	eq(Skins.decorAt(state, 3, 5), "FIRE_PIT", "shown")
	eq(Skins.decorAt(state, 3, 4), nil, "below its level it isn't shown")
end)

test("the save: round trip; not owned, duplicates, unknown and wrong kinds dropped; older save = none", function()
	local state = Skins.blank()
	Skins.buy(state, "DINO_STATUE")
	Skins.setDecor(state, 1, "DINO_STATUE", 0)
	Skins.setDecor(state, 2, "FIRE_PIT", 5)
	local back = Skins.sanitize(Skins.toSave(state), 5)
	eq(table.concat(back.decor, ","), "DINO_STATUE,FIRE_PIT,", "round trip")
	local raw = Skins.toSave(state)
	raw.decor = { "DINO_STATUE", "DINO_STATUE", "HAMMOCK" }
	eq(table.concat(Skins.sanitize(raw, 5).decor, ","), "DINO_STATUE,,", "a duplicate and an unowned one dropped")
	raw.decor = { "TREEHOUSE", 7, "FIRE_PIT" }
	eq(table.concat(Skins.sanitize(raw, 4).decor, ","), ",,", "a set, garbage, and a level deco below its level")
	eq(#Skins.sanitize({ owned = {} }, 0).decor, 0, "older save: none")
	eq(#Skins.toSave(Skins.blank()).decor, Skins.DECOR_SPOTS, "saved as three spots")
end)

local function look(key: string): any
	return Skins.look(key)
end

test("the models are inert: anchored, no touch, no query, no scripts, seats, lights, sounds or prompts", function()
	for _, d in DECOS do
		local model = Decor.build(d[1], look(d[1]), CFrame.new(), { flag = Color3.new(1, 0, 0), poster = "WANTED" }) :: Model
		ok(model ~= nil, `{d[1]} builds`)
		local parts = 0
		for _, item in model:GetDescendants() do
			if item:IsA("BasePart") then
				parts += 1
				ok(item.Anchored, `{d[1]}.{item.Name} anchored`)
				ok(not item.CanTouch, `{d[1]}.{item.Name} no touch`)
				ok(not item.CanQuery, `{d[1]}.{item.Name} can't be hit or clicked`)
				ok(item.Material ~= Enum.Material.Neon and item.Material ~= Enum.Material.ForceField and item.Material ~= Enum.Material.Glass, `{d[1]}.{item.Name} no glow`)
			end
			for _, banned in { "Script", "LocalScript", "ModuleScript", "Seat", "VehicleSeat", "Light", "Sound", "ProximityPrompt", "ClickDetector", "TouchTransmitter", "ParticleEmitter" } do
				ok(not item:IsA(banned), `{d[1]}: no {banned}`)
			end
		end
		ok(parts > 0, `{d[1]}: has parts`)
	end
	eq(Decor.build("TREEHOUSE", look("TREEHOUSE"), CFrame.new()), nil, "not a decoration: nothing")
end)

test("each model stays in its footprint, and the 3 spots, the Display Towers and the pen never overlap", function()
	for _, d in DECOS do
		local size = Decor.SIZE[d[1]]
		local model = Decor.build(d[1], look(d[1]), CFrame.new(), nil) :: Model
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				local p, s = part.CFrame.Position, part.Size
				ok(math.abs(p.X) + s.X / 2 <= size.X / 2 + 1e-4, `{d[1]}.{part.Name} inside x`)
				ok(math.abs(p.Z) + s.Z / 2 <= size.Y / 2 + 1e-4, `{d[1]}.{part.Name} inside z`)
				ok(p.Y - s.Y / 2 >= -1e-4, `{d[1]}.{part.Name} on the ground`)
			end
		end
	end
	local half = 0
	for _, size in Decor.SIZE do
		half = math.max(half, size.X / 2, size.Y / 2)
	end
	eq(#Outpost.DECOR_SPOTS, Skins.DECOR_SPOTS, "three spots")
	for i, a in Outpost.DECOR_SPOTS do
		for j, b in Outpost.DECOR_SPOTS do
			if i < j then
				ok((a - b).Magnitude >= half * 2, `spots {i} and {j} apart`)
			end
		end
		for _, t in Outpost.DECO_SPOTS do
			ok(math.abs(a.X - t.X) >= half + 1.5, `spot {i} clear of a Display Tower`)
		end
		-- The Hatchling Pen: 7x7 at (-6, 5) (Server/Outpost).
		ok(a.X - half >= -6 + 3.5 or math.abs(a.Z - 5) >= 3.5 + half, `spot {i} clear of the pen`)
		ok(math.abs(a.X) + half <= Outpost.CAMPSITE_SIZE / 2 and math.abs(a.Z) + half <= Outpost.CAMPSITE_SIZE / 2, `spot {i} on the Campsite`)
	end
end)

test("the Hunter's Flag wears your Tower flag colour; the Wanted Poster shows your name and best hunt", function()
	local red = Color3.new(1, 0, 0)
	local flag = Decor.build("HUNTERS_FLAG", look("HUNTERS_FLAG"), CFrame.new(), { flag = red }) :: Model
	eq((flag:FindFirstChild("Cloth") :: BasePart).Color, red, "cloth = the flag colour")
	local plain = Decor.build("HUNTERS_FLAG", look("HUNTERS_FLAG"), CFrame.new(), nil) :: Model
	eq((plain:FindFirstChild("Cloth") :: BasePart).Color, look("HUNTERS_FLAG").accent, "no flag worn: the sheet's accent")
	eq(Decor.posterText("Jovan", "Hard", 37), "WANTED\nJovan\nBest hunt: Hard cleared · best round 37")
	eq(Decor.posterText("Jovan", nil, 12), "WANTED\nJovan\nBest hunt: no clear yet · best round 12")
	eq(Decor.posterText("Jovan", nil, 0), "WANTED\nJovan\nBest hunt: no clear yet")
	local poster = Decor.build("WANTED_POSTER", look("WANTED_POSTER"), CFrame.new(), { poster = Decor.posterText("Jovan", "Hard", 37) }) :: Model
	local label = poster:FindFirstChild("Poster", true) :: TextLabel
	eq(label.Text, "WANTED\nJovan\nBest hunt: Hard cleared · best round 37", "on the board")
end)

test("the best clear: the hardest difficulty ever cleared, saved", function()
	local p = Profile.blank(0, function()
		return 0.5
	end)
	eq(p.bestClear, nil, "none yet")
	Profile.recordClear(p, "NORMAL")
	Profile.recordClear(p, "EASY")
	eq(p.bestClear, "NORMAL", "an easier clear never lowers it")
	Profile.recordClear(p, "CHAOS")
	Profile.recordClear(p, "NOPE")
	eq(p.bestClear, "CHAOS")
	local saved = Profile.toSave(p)
	eq(saved.bestClear, "CHAOS", "saved")
	saved.bestClear = "NOPE"
	local back = Profile.sanitize(saved, 0, function()
		return 0.5
	end)
	eq(back.bestClear, nil, "garbage refused")
end)

test("source guards: only Wardrobe builds decorations, on Outpost Campsites; Progression publishes and saves them", function()
	for _, path in { "src/server/Towers.luau", "src/server/MapBuilder.luau", "src/server/Battle.luau", "src/server/Hero.luau" } do
		ok(fs.readFile(path):find("Decor", 1, true) == nil, `{path} never builds decorations`)
	end
	local wardrobe = fs.readFile("src/server/Wardrobe.luau")
	ok(wardrobe:find("for i, spot in OutpostRules.DECOR_SPOTS do", 1, true) ~= nil, "spots from the Outpost layout")
	ok(wardrobe:find("local sites = root and root:FindFirstChild(\"Campsites\")", 1, true) ~= nil, "on the Outpost's Campsites")
	local prog = fs.readFile("src/server/Progression.luau")
	ok(prog:find("Skins.setDecor(profile.skins, a, b, level)", 1, true) ~= nil, "setDecor through skinAction (between matches, saved)")
	ok(prog:find("Skins.decorAt(profile.skins, i, level)", 1, true) ~= nil, "published only while owned")
	ok(prog:find("Profile.recordClear(profile, result.difficulty)", 1, true) ~= nil, "a clear is recorded")
	eq(Config.SkinOrder[#Config.SkinOrder], "DINO_STATUE", "rows 30-36 at the end of the sheet")
end)
