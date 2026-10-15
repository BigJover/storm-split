--[[
	The A/B/C pick (Shared/OptionPick, PLAN T112, DECISIONS #279): when it opens, its
	cards, the confirm button, when it closes, the tier label, and that it fits every
	window with Back, X and the confirm button on screen (DIRECTION: no pop-up may ever
	trap a player).
]]
local Config = require(src.shared.Config)
local OptionPick = require(src.shared.OptionPick)
local Upgrades = require(src.shared.Upgrades)

-- A made-up path with all three options at tier 4 (B/C don't exist in Config yet).
local function threeWay()
	local function row(name, blurb)
		return { name = name, cost = 2400, blurb = blurb }
	end
	return {
		id = "Test",
		tiers = { row("One", ""), row("Two", ""), row("Three", "") },
		t4 = { A = row("Alpha", "Shoots faster"), B = row("Bravo", "Hits harder"), C = row("Charlie", "Reaches further") },
		t5 = { AA = row("Top", "The top") },
	}
end

local function everyPath(visit: (string, any, number) -> ())
	for key, def in Config.Towers do
		for i, path in def.paths do
			visit(`{key} path {i}`, def, i)
		end
	end
	for key, def in Config.Heroes do
		for i, path in def.paths do
			visit(`hero {key} path {i}`, def, i)
		end
	end
end

test("only tier-4 and tier-5 steps open the pick", function()
	for tier = 1, 6 do
		eq(OptionPick.opens(tier), tier == 4 or tier == 5, `tier {tier}`)
	end
end)

-- Paths whose B/C options are in (PLAN 9c: the starters; 9d: Tranq, Supply, Hospital, Armory; 9e: the round-4 four);
-- every other path is still A only.
local HERO_BC = { PISTOL = true, RIFLE = true, SHOTGUN = true, MEDIC = true } -- 9f, hero by hero
local WITH_BC = { SCOUT = true, SNIPER = true, GRENADIER = true, CHILLER = true, QUARTERMASTER = true, HOSPITAL = true, ARMORY = true, COIL = true, FALCON = true, TARPIT = true, BALLISTA = true, RESIN = true, RAPTOR = true, TOTEM = true, BLIMP = true }

test("every tier-4/5 pick shows its options' cards (A only, or A/B/C for 9c), each one the server takes", function()
	local slots, threeWay = 0, 0
	everyPath(function(where, def, i)
		local path = def.paths[i]
		local tower = string.match(where, "^(%u[%u_]*) path") -- nil for a hero
		local hero = string.match(where, "^hero (%u+) path")
		local letters = if (tower and WITH_BC[tower]) or (hero and HERO_BC[hero]) then "ABC" else "A"
		for _, step in { { 4, "" }, { 5, "A" } } do
			local nextTier, picks = step[1], step[2]
			local cards = OptionPick.cards(path, nextTier, picks)
			eq(#cards, #letters, `{where} T{nextTier}: card count`)
			local tiers = { 0, 0, 0 }
			tiers[i] = nextTier - 1
			local allPicks = { "", "", "" }
			allPicks[i] = picks
			for c, card in cards do
				local letter = string.sub(letters, c, c)
				local row = Upgrades.row(path, nextTier, picks .. letter)
				eq(card.letter, letter, `{where} T{nextTier}: letter {c}`)
				eq(card.name, row.name, `{where} T{nextTier}{letter}: name`)
				eq(card.blurb, row.blurb, `{where} T{nextTier}{letter}: blurb`)
				-- The server's check (Shared/Upgrades.stepFor) accepts every card offered.
				local got, why = Upgrades.stepFor(def, tiers, allPicks, i, letter)
				eq(why, "ok", `{where} T{nextTier}: the server takes {letter}`)
				eq(got, row, `{where} T{nextTier}{letter}: the row it buys`)
			end
			if #letters == 1 then
				eq(OptionPick.initial(cards), "A", `{where} T{nextTier}: the one card is chosen`)
				-- ...and refuses a letter with no card.
				local _, refused = Upgrades.stepFor(def, tiers, allPicks, i, "B")
				eq(refused, "no such option", `{where} T{nextTier}: B is refused`)
			else
				eq(OptionPick.initial(cards), nil, `{where} T{nextTier}: no card chosen yet`)
				threeWay += 1
			end
			slots += 1
		end
	end)
	ok(slots >= 90, `every slot seen ({slots})`)
	local heroes, towers = 0, 0
	for _ in HERO_BC do
		heroes += 1
	end
	for _ in WITH_BC do
		towers += 1
	end
	eq(threeWay, 6 * towers + 6 * heroes, "3 paths per tower with B/C (the 11 built, 9c-9e; the 4x towers from 9g) and 3 per 9f hero offer A/B/C at their 2 slots")
end)

test("three options: three cards in order, none chosen until one is tapped", function()
	local cards = OptionPick.cards(threeWay(), 4, "")
	eq(#cards, 3, "three cards")
	eq(cards[1].letter .. cards[2].letter .. cards[3].letter, "ABC", "in order")
	eq(cards[2].name, "Bravo", "name")
	eq(cards[2].blurb, "Hits harder", "blurb")
	eq(OptionPick.initial(cards), nil, "no card chosen")
	eq(OptionPick.rowLine(cards), "one of: A Alpha / B Bravo / C Charlie", "the path row")
	eq(OptionPick.rowLine({ cards[1] }), "A Alpha", "one card")
	eq(#OptionPick.cards(threeWay(), 5, "B"), 0, "no T5 row after B: no cards")
end)

test("the confirm button: tap a card first, can't-afford says so, then Buy B — price", function()
	local text, enabled = OptionPick.confirm(nil, 2400, 5000)
	eq(text, "Tap a card  ·  2,400", "nothing chosen")
	eq(enabled, false, "nothing chosen")
	text, enabled = OptionPick.confirm("B", 2400, 2399)
	eq(text, "Need 2,400 cash for B", "short")
	eq(enabled, false, "short")
	text, enabled = OptionPick.confirm("B", 2400, 2400)
	eq(text, "Buy B — 2,400", "enough")
	eq(enabled, true, "enough")
	text, enabled = OptionPick.confirm("A", 1300, 0, true)
	eq(text, "Buy A — FREE", "mastery free upgrade")
	eq(enabled, true, "free")
	eq(OptionPick.grouped(1234567), "1,234,567", "grouping")
end)

test("a pick closes on any change to its path, owner or block, not on cash", function()
	local pick = { owner = "7", pathIndex = 1, tier = 3, picks = "", chosen = "A" }
	local same = { owner = "7", tier = 3, picks = "", blocked = false }
	eq(OptionPick.stays(pick, same), true, "nothing changed")
	eq(OptionPick.stays(nil, same), false, "no pick")
	eq(OptionPick.stays(pick, { owner = "7", tier = 4, picks = "B", blocked = false }), false, "a teammate bought it")
	eq(OptionPick.stays(pick, { owner = "7", tier = 3, picks = "A", blocked = false }), false, "letters changed")
	eq(OptionPick.stays(pick, { owner = "8", tier = 3, picks = "", blocked = false }), false, "another tower")
	eq(OptionPick.stays(pick, { owner = "7", tier = 3, picks = "", blocked = true }), false, "trampled or blocked")
end)

test("the tower's tier label shows the picked letters", function()
	eq(OptionPick.tierLabel({ 2, 1, 0 }, { "", "", "" }), "2 · 1 · 0", "no picks")
	eq(OptionPick.tierLabel({ 2, 1, 0 }, nil), "2 · 1 · 0", "no picks table")
	eq(OptionPick.tierLabel({ 0, 4, 2 }, { "", "B", "" }), "4B", "tier 4")
	eq(OptionPick.tierLabel({ 5, 0, 2 }, { "BA", "", "" }), "4B · 5A", "tier 5")
end)

-- The 3 window sizes PLAN T112 names, and a spread of others.
local PHONE, SMALL, FULL = { 375, 667 }, { 800, 600 }, { 1920, 1080 }
local WINDOWS = {
	FULL, SMALL, PHONE, { 2560, 1440 }, { 1366, 768 }, { 1024, 768 }, { 812, 375 }, { 667, 375 },
	{ 568, 320 }, { 375, 812 }, { 360, 640 }, { 320, 568 }, { 480, 320 }, { 400, 300 },
}

test("the pick fits every window: header, cards and confirm on screen", function()
	for _, window in WINDOWS do
		for count = 1, 3 do
			local x, y = window[1], window[2]
			local where = `{x}x{y}, {count} card(s)`
			local shape = OptionPick.layout(x, y, count)
			ok(shape.scale >= OptionPick.MIN_SCALE and shape.scale <= 1, `{where}: scale {shape.scale}`)
			ok(shape.width <= OptionPick.WIDTH, `{where}: never wider than the panel`)
			ok(shape.width * shape.scale <= x - OptionPick.EDGE * 2 + 1e-6, `{where}: width {shape.width} x {shape.scale}`)
			ok(shape.height * shape.scale <= y - OptionPick.TOP - OptionPick.BOTTOM + 1e-6, `{where}: height {shape.height} x {shape.scale}`)
			ok(shape.listHeight >= shape.cardHeight - 1e-6, `{where}: at least one whole card shows ({shape.listHeight})`)
			ok(shape.listHeight <= shape.content + 1e-6, `{where}: the list never outgrows the cards`)
			local inner = shape.width - OptionPick.PAD * 2
			ok(shape.cardWidth <= inner + 1e-6, `{where}: a card fits across`)
			if not shape.stacked and count > 1 then
				ok(count * shape.cardWidth + (count - 1) * OptionPick.CARD_GAP <= inner + 1e-6, `{where}: a row of cards fits`)
				ok(shape.cardWidth >= OptionPick.STACK_BELOW, `{where}: cards in a row are wide enough`)
			end
		end
	end
end)

test("the header title ends before Back and the X (Run 8 F9)", function()
	-- Spans as offsets from the header's right edge: [left, right], left more negative.
	local function spans(picking: boolean)
		local h = OptionPick.header(picking)
		local close = { -OptionPick.CLOSE_W, h.closeRight }
		local back = { h.backRight - OptionPick.BACK_W, h.backRight }
		return h, close, back
	end
	local h, close, back = spans(true)
	ok(back[2] <= close[1] - OptionPick.HEADER_GAP, `picking: Back ends {back[2]} before the X at {close[1]}`)
	ok(h.titleRight <= back[1] - OptionPick.HEADER_GAP, `picking: title ends {h.titleRight}, Back starts {back[1]}`)
	local shut = OptionPick.header(false)
	ok(shut.titleRight <= close[1] - OptionPick.HEADER_GAP, `no pick: title ends {shut.titleRight} before the X`)
	ok(shut.titleRight > h.titleRight, "without Back the title gets the room back")
	ok(OptionPick.TITLE_MIN < OptionPick.TITLE_MAX, "the title can shrink")
end)

test("full window: three cards in a row, nothing scaled or scrolled", function()
	local shape = OptionPick.layout(FULL[1], FULL[2], 3)
	eq(shape.scale, 1, "scale")
	eq(shape.width, OptionPick.WIDTH, "full panel")
	eq(shape.stacked, false, "a row")
	eq(shape.listHeight, shape.content, "everything shows")
end)

test("small window: three cards still in a row, nothing scaled", function()
	local shape = OptionPick.layout(SMALL[1], SMALL[2], 3)
	eq(shape.scale, 1, "scale")
	eq(shape.stacked, false, "a row")
	eq(shape.listHeight, shape.content, "everything shows")
end)

test("phone-ish window: the cards stack, full width, and the panel isn't scaled", function()
	local shape = OptionPick.layout(PHONE[1], PHONE[2], 3)
	eq(shape.scale, 1, "scale")
	eq(shape.stacked, true, "stacked")
	eq(shape.cardWidth, shape.width - OptionPick.PAD * 2, "full width")
	eq(shape.cardHeight, OptionPick.CARD_FLAT, "flat cards")
end)

test("a short window scrolls the cards before it scales the panel", function()
	-- Room for the fixed parts and one card but not three stacked: it scrolls, no scale.
	local fixed = OptionPick.PAD * 2 + OptionPick.HEADER + OptionPick.CONFIRM + OptionPick.MESSAGE + OptionPick.GAP * 3
	local y = OptionPick.TOP + OptionPick.BOTTOM + fixed + OptionPick.CARD_FLAT + 20
	local shape = OptionPick.layout(375, y, 3)
	eq(shape.stacked, true, "stacked")
	eq(shape.scale, 1, "not scaled yet")
	ok(shape.listHeight < shape.content, "it scrolls")
	-- Too short for even one card: now it scales.
	local tiny = OptionPick.layout(375, OptionPick.TOP + OptionPick.BOTTOM + fixed, 3)
	ok(tiny.scale < 1, `scaled ({tiny.scale})`)
end)

test("a single card is one full-width card, never a tall one", function()
	for _, window in { PHONE, SMALL, FULL } do
		local shape = OptionPick.layout(window[1], window[2], 1)
		eq(shape.cardWidth, shape.width - OptionPick.PAD * 2, `{window[1]}: full width`)
		eq(shape.cardHeight, OptionPick.CARD_FLAT, `{window[1]}: flat`)
		eq(shape.content, OptionPick.CARD_FLAT, `{window[1]}: one card high`)
	end
end)

test("N20 (T120b, no-trap rule): with Choose hero / Unlocks & Mastery up, the panel stays under them on every window that can fit it", function()
	-- The buttons' bottoms as Shop.client places them (top-anchored, centred).
	local shop = require("@lune/fs").readFile("src/client/Shop.client.luau")
	local function bottom(name: string): number
		local at = shop:find(`{name}.Position = UDim2.new(0.5, 0, 0, `, 1, true)
		assert(at, name)
		local y = tonumber(shop:match("UDim2%.new%(0%.5, 0, 0, (%d+)%)", at))
		local h = tonumber(shop:match("UDim2%.fromOffset%(%d+, (%d+)%)", at))
		return (y :: number) + (h :: number)
	end
	local lowest = math.max(bottom("heroButton"), bottom("masteryButton"))
	ok(OptionPick.BUILD_HUD_BOTTOM >= lowest, `the reserve {OptionPick.BUILD_HUD_BOTTOM} clears the buttons ({lowest})`)
	for _, window in WINDOWS do
		local x, y = window[1], window[2]
		local top = OptionPick.top(y, true)
		-- The plain panel (no pick), with far more rows than fit.
		local list = OptionPick.listHeight(y, 5000, true)
		local panelTop = y - OptionPick.BOTTOM - OptionPick.CHROME - list
		ok(panelTop >= top - 1e-6, `{x}x{y}: panel top {panelTop} under {top}`)
		ok(list <= math.floor(y * OptionPick.LIST_MAX_SCREEN), `{x}x{y}: list capped`)
		if top == OptionPick.BUILD_HUD_BOTTOM then
			ok(panelTop >= lowest, `{x}x{y}: clear of the buttons`)
			ok(list >= OptionPick.LIST_ROOM_MIN, `{x}x{y}: at least {OptionPick.LIST_ROOM_MIN} px of rows`)
			for count = 1, 3 do
				local shape = OptionPick.layout(x, y, count, true)
				ok(y - OptionPick.BOTTOM - shape.height * shape.scale >= lowest - 1e-6, `{x}x{y}, {count} card(s): the pick clears the buttons`)
				ok(shape.listHeight >= shape.cardHeight - 1e-6, `{x}x{y}, {count}: a whole card shows`)
			end
		else
			ok(y - OptionPick.BUILD_HUD_BOTTOM - OptionPick.BOTTOM - OptionPick.CHROME < OptionPick.LIST_ROOM_MIN, `{x}x{y}: whole window only when too short`)
		end
	end
	eq(OptionPick.listHeight(1080, 200, true), 200, "a short panel keeps its own height")
	eq(OptionPick.top(1080, false), OptionPick.TOP, "no buttons: the whole window as before")
	eq(OptionPick.listHeight(720, 5000, false), math.floor(720 * OptionPick.LIST_MAX_SCREEN), "no buttons: the old cap")
	ok(OptionPick.listHeight(720, 5000, true) < OptionPick.listHeight(720, 5000, false), "720 high: the list shrinks under the buttons (the Run 9 overlap)")
end)
