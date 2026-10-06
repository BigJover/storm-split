--[[
	Shared/Cosmetics: the player level's rewards (PLAN round 4 T57, DECISIONS #121, #178).
	Unlock by level, the ladder by band, the past-200 titles, equip validation, the looks
	(mastery 20's gold stays its own) and parts that change nothing in play.
]]

local Config = require(src.shared.Config)
local Cosmetics = require(src.shared.Cosmetics)
local PlayerLevel = require(src.shared.PlayerLevel)

local function count(level: number, rarity: string): number
	local n = 0
	for _, item in Cosmetics.at(level) do
		if item.rarity == rarity then
			n += 1
		end
	end
	return n
end

test("the ladder by band: 89 commons to 99, a rare + a title every 10 to 100, legendary + title at 150 and 200", function()
	local commons, rares, titles, legendaries = 0, 0, 0, 0
	for level = 1, 200 do
		commons += count(level, "common")
		rares += count(level, "rare")
		titles += count(level, "title")
		legendaries += count(level, "legendary")
		if level < 100 and level % 10 ~= 0 and level >= 2 then
			eq(#Cosmetics.at(level), 1, `level {level}: one common`)
		elseif level <= 100 and level % 10 == 0 then
			eq(count(level, "rare") + count(level, "title"), 2, `level {level}: a rare and a title`)
		elseif level == 150 or level == 200 then
			eq(count(level, "legendary") + count(level, "title"), 2, `level {level}: a legendary and a title`)
		else
			eq(#Cosmetics.at(level), 0, `level {level}: nothing`)
		end
	end
	eq(commons, 89, "commons")
	eq(rares, 10, "rares")
	eq(titles, 12, "titles to 200")
	eq(legendaries, 2, "legendaries")
end)

test("PlayerLevel.rewardAt reads the sheet", function()
	for level = 1, 400 do
		eq(PlayerLevel.rewardAt(level), Cosmetics.tierAt(level), `level {level}`)
	end
	eq(PlayerLevel.rewardAt(37), "common", "37")
	eq(PlayerLevel.rewardAt(250), "title", "250")
end)

test("past 200: a new title every 50 levels, forever, each with its own name", function()
	local t250, t300 = Cosmetics.at(250)[1], Cosmetics.at(300)[1]
	eq(t250.kind, "title", "250 is a title")
	eq(t250.id, "TITLE_ELDER_250", "id carries the level")
	ok(not string.find(t250.name, "{n}", 1, true), "the level is filled in")
	ok(t250.name ~= t300.name, "300's title differs")
	eq(#Cosmetics.at(275), 0, "275: nothing")
	eq(Cosmetics.at(10000)[1].id, "TITLE_ELDER_10000", "level 10,000")
	eq(Cosmetics.item("TITLE_ELDER_300").level, 300, "found by id")
	eq(Cosmetics.item("TITLE_ELDER_275"), nil, "not a repeat level")
	eq(Cosmetics.item("TITLE_ELDER_0250"), nil, "no leading zeros")
	eq(Cosmetics.item("TITLE_ELDER"), nil, "the bare row isn't wearable")
	eq(Cosmetics.item("TITLE_ELDER_200"), nil, "below the first repeat")
end)

test("unlock by level: an item is yours from its level on", function()
	local hat = Cosmetics.item("HAT_BUSH") :: Cosmetics.Item
	eq(hat.level, 10, "the bush hat is level 10's")
	ok(not Cosmetics.unlocked(hat, 9), "not at 9")
	ok(Cosmetics.unlocked(hat, 10), "at 10")
	eq(#Cosmetics.itemsFor("hat", 9), 0, "no hats at 9")
	eq(#Cosmetics.itemsFor("hat", 10), 1, "one at 10")
	eq(#Cosmetics.itemsFor("hat", 100), 3, "three by 100")
	eq(#Cosmetics.itemsFor("title", 200), 12, "twelve titles by 200")
	eq(#Cosmetics.itemsFor("title", 349), 14, "and 250 and 300 by 349")
	eq(Cosmetics.firstLevel("set"), 150, "sets from 150")
	eq(Cosmetics.firstLevel("title"), 10, "titles from 10")
	local next3 = Cosmetics.upcoming(98, 3)
	eq(next3[1].level, 99, "next after 98")
	eq(next3[2].level, 100, "then 100")
	eq(next3[3].level, 150, "then nothing until 150")
	local past = Cosmetics.upcoming(260, 2)
	eq(past[1].level, 300, "past 200: the next repeat")
	eq(past[2].level, 350, "and the one after")
end)

test("equip validation: unknown ids, wrong kind and locked items are refused", function()
	ok(Cosmetics.check("hat", "HAT_BUSH", 10), "allowed")
	local refused, why = Cosmetics.check("hat", "HAT_RANGER", 49)
	eq(refused, false, "level 50's hat at 49")
	eq(why, "Unlocks at player level 50", "the reason")
	eq((Cosmetics.check("title", "HAT_BUSH", 100)), false, "wrong kind")
	eq((Cosmetics.check("hat", "NOPE", 100)), false, "unknown id")
	eq((Cosmetics.check("cape", "HAT_BUSH", 100)), false, "unknown slot")
	eq((Cosmetics.check(nil, "HAT_BUSH", 100)), false, "no slot")
	eq((Cosmetics.check("title", "TITLE_ELDER_300", 299)), false, "a repeat title above the level")
	ok(Cosmetics.check("title", "TITLE_ELDER_300", 300), "and at it")
	ok(Cosmetics.check("set", "", 1), "taking off is always allowed")
	local clean = Cosmetics.clean({ hat = "HAT_BUSH", set = "SET_METEOR", title = 5, [1] = "HAT_BUSH" }, 10)
	eq(clean.hat, "HAT_BUSH", "kept")
	eq(clean.set, nil, "locked dropped")
	eq(clean.title, nil, "junk dropped")
	eq(next(Cosmetics.clean("HAT_BUSH", 100)), nil, "not a table: {}")
end)

test("every slot has items, a label, and a first level", function()
	for _, slot in Cosmetics.SLOTS do
		ok(Cosmetics.LABELS[slot] ~= nil, `{slot} label`)
		ok(Cosmetics.firstLevel(slot) ~= nil, `{slot} unlocks somewhere`)
	end
	for _, row in Config.Cosmetics do
		ok(Cosmetics.isSlot(row.kind), `{row.id}: its kind is a slot`)
	end
end)

local GOLD = Color3.fromRGB(250, 200, 60)
local HERO = Color3.fromRGB(100, 100, 255)
local function wearing(map: { [string]: string }): (string) -> Cosmetics.Item?
	return function(slot)
		return Cosmetics.item(map[slot])
	end
end

test("the gun: mastery 20's gold always wins; a set beats tint and pattern", function()
	local all = wearing({ set = "SET_METEOR", gunTint = "TINT_OCHRE", gunFinish = "GUN_IRONWOOD" })
	local gold = Cosmetics.gunLook(all, HERO, true, GOLD)
	eq(gold.colour, GOLD, "maxed: gold")
	eq(gold.material, Enum.Material.Neon, "maxed: neon")
	local set = Cosmetics.gunLook(all, HERO, false, GOLD)
	eq(set.set and set.set.id, "SET_METEOR", "the set")
	local plain = Cosmetics.gunLook(wearing({ gunTint = "TINT_OCHRE", gunFinish = "GUN_IRONWOOD" }), HERO, false, GOLD)
	eq(plain.colour, Cosmetics.colour(Cosmetics.item("TINT_OCHRE")), "the tint")
	eq(plain.material, Enum.Material.Wood, "the pattern's material")
	local none = Cosmetics.gunLook(wearing({}), HERO, false, GOLD)
	eq(none.colour, HERO, "nothing worn: the hero's colour")
	eq(none.material, Enum.Material.SmoothPlastic, "and plastic")
end)

test("tracers, crosshair and hit-marker follow what's worn; a take-down colour is the game's", function()
	eq(Cosmetics.tracerColour(wearing({}), HERO), HERO, "default tracer")
	ok(Cosmetics.tracerColour(wearing({ tracer = "TRACER_OCHRE" }), HERO) ~= HERO, "a tracer colour")
	local white = Color3.new(1, 1, 1)
	ok(Cosmetics.crosshairColour(wearing({ crosshair = "SIGHT_SLATE" }), white) ~= white, "a crosshair colour")
	local glyph, colour = Cosmetics.hitMarker(wearing({}), white)
	eq(glyph, "×", "default glyph")
	eq(colour, white, "default colour")
	local star = Cosmetics.hitMarker(wearing({ hitMarker = "MARK_STAR" }), white)
	eq(star, "✦", "the star marker")
end)

test("no cosmetic is gold, and an animated set moves", function()
	for _, row in Config.Cosmetics do
		local c = Cosmetics.colour(row :: any)
		if c then
			local d = math.sqrt((c.R - GOLD.R) ^ 2 + (c.G - GOLD.G) ^ 2 + (c.B - GOLD.B) ^ 2) * 255
			ok(d >= 80, `{row.id} is too close to gold`)
		end
		ok(row.material ~= "Neon", `{row.id}: no neon`)
	end
	for _, id in { "SET_TARPIT", "SET_METEOR" } do
		local set = Cosmetics.item(id) :: Cosmetics.Item
		ok(Cosmetics.animatedColour(set, 0) ~= Cosmetics.animatedColour(set, 1.3), `{id} changes over time`)
	end
end)

local function inert(model: Instance, what: string)
	local parts = 0
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			parts += 1
			eq(part.CanCollide, false, `{what} {part.Name}: no collision`)
			eq(part.CanQuery, false, `{what} {part.Name}: can't be hit`)
			eq(part.CanTouch, false, `{what} {part.Name}: no touch`)
		end
	end
	ok(parts > 0, `{what} has parts`)
end

test("hats and tower flags change nothing in play (no hitbox, no collision, no weight)", function()
	for _, id in { "HAT_BUSH", "HAT_RANGER", "HAT_CREST" } do
		local hat = Cosmetics.buildHat(Cosmetics.item(id) :: Cosmetics.Item, Vector3.new(2, 1, 1))
		inert(hat, id)
		for _, part in hat:GetDescendants() do
			if part:IsA("BasePart") then
				eq(part.Massless, true, `{id} {part.Name}: massless`)
			end
		end
	end
	local TowerLook = require(src.shared.TowerLook)
	local Track = require(src.shared.Track)
	local model = TowerLook.build("SCOUT", 20, Vector3.zero)
	TowerLook.addFlag(model, Color3.new(1, 0, 0))
	local flag = Instance.new("Model")
	for _, part in model:GetChildren() do
		if part:GetAttribute("OwnerFlag") then
			part.Parent = flag
			local reach = Vector3.new(part.CFrame.Position.X, 0, part.CFrame.Position.Z).Magnitude + math.max(part.Size.X, part.Size.Z) / 2
			ok(reach <= Track.TowerRadius, `{part.Name} stays inside the tower's footprint ({reach})`)
		end
	end
	inert(flag, "flag")
end)
