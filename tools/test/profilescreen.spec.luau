--[[
	Shared/ProfileScreen: what the Profile screen draws (PLAN round 4 T57) and the no-trap
	rule (DIRECTION): it fits every window with its X on screen, shows on the home screen
	only, and never labels the player level "Lv N" (DECISIONS #118).
]]

local ProfileScreen = require(src.shared.ProfileScreen)
local PlayerLevel = require(src.shared.PlayerLevel)
local Cosmetics = require(src.shared.Cosmetics)

test("shown on the home screen only, while its mode is open", function()
	ok(ProfileScreen.shown(true, "Lobby"), "Lobby")
	for _, state in { "Building", "Playing", "GameOver", "Victory" } do
		eq(ProfileScreen.shown(true, state), false, state)
	end
	eq(ProfileScreen.shown(false, "Lobby"), false, "closed")
end)

test("the level line says the player level, never Lv", function()
	eq(ProfileScreen.levelLine(PlayerLevel.xpFor(12)), "Player level 12", "level 12")
	eq(ProfileScreen.levelLine(nil), "Player level 1", "not loaded yet")
	ok(not string.find(ProfileScreen.levelLine(6300), "Lv", 1, true), "no Lv")
	local line, fraction = ProfileScreen.xpLine(PlayerLevel.xpFor(12) + 340)
	eq(line, `340 / {ProfileScreen.grouped(PlayerLevel.cost(12))} XP to level 13`, "the XP line")
	near(fraction, 340 / PlayerLevel.cost(12), "the bar")
	eq(ProfileScreen.grouped(1082750), "1,082,750", "grouped")
end)

test("next rewards list the coming levels and what they give", function()
	local lines = ProfileScreen.upcoming(PlayerLevel.xpFor(9))
	eq(#lines, ProfileScreen.UPCOMING, "three")
	ok(string.find(lines[1], "^Level 10 · Bush Hat %(Hunting hat%) · title ") ~= nil, lines[1])
end)

test("slot rows: None + every unlocked item, the worn one selected; locked slots say when", function()
	local rows = ProfileScreen.slotRows(PlayerLevel.xpFor(10), { hat = "HAT_BUSH" })
	eq(#rows, #Cosmetics.SLOTS, "a row per slot")
	local byslot = {}
	for _, row in rows do
		byslot[row.slot] = row
	end
	local hat = byslot.hat
	eq(hat.chips[1].text, ProfileScreen.NONE, "None first")
	eq(hat.chips[1].selected, false, "None not selected")
	eq(hat.chips[2].id, "HAT_BUSH", "the bush hat")
	eq(hat.chips[2].selected, true, "worn")
	eq(byslot.set.locked, "Unlocks at player level 150", "sets say when")
	eq(#byslot.set.chips, 0, "no chips")
	eq(byslot.title.chips[1].selected, true, "no title worn: None selected")
end)

test("the screen fits every window with the X on screen (no-trap rule)", function()
	for _, content in { ProfileScreen.listContent(3, #Cosmetics.SLOTS), ProfileScreen.boardContent(51, true), ProfileScreen.boardContent(1, true) } do
	local smallest = (ProfileScreen.fixedHeight() + ProfileScreen.MIN_LIST) * ProfileScreen.MIN_SCALE
	for _, size in { { 1920, 1080 }, { 1280, 720 }, { 800, 600 }, { 480, 320 }, { 320, 240 }, { 360, 800 }, { 1024, 300 } } do
		local x, y = size[1], size[2]
		local top, bottom = 44, y - 100 -- under the top bar, above the Hunt Board row
		local layout = ProfileScreen.layout(x, top, bottom, content)
		ok(layout.width * layout.scale <= x - 2 * ProfileScreen.EDGE + 0.5, `{x}x{y}: fits across`)
		-- Fits down, X included, unless the window is smaller than MIN_SCALE can serve.
		ok(layout.height * layout.scale <= math.max(bottom - top, smallest) + 0.5, `{x}x{y}: fits down`)
		ok(layout.listHeight <= content, `{x}x{y}: the list never outgrows its content`)
	end
	end
	local content = ProfileScreen.listContent(3, #Cosmetics.SLOTS)
	local S = ProfileScreen
	ok(S.fixedHeight() >= S.PAD * 2 + S.HEADER + S.TABS + S.LEVEL + S.MESSAGE, "every fixed part is counted, so the X can't be pushed off")
	local big = ProfileScreen.layout(1920, 44, 980, content)
	eq(big.scale, 1, "full size on a big window")
	ok(big.listHeight < content, "the list scrolls rather than overflow")
end)

-- PLAN T83: the Trophies tab -------------------------------------------------------------

test("T83 Trophies tab: the Trophies line, the ladder lowest first, reached up to your arena", function()
	eq(ProfileScreen.TAB_TROPHIES, "Trophies")
	eq(ProfileScreen.trophyLine(340), "340 Trophies · Raptor Ridge")
	eq(ProfileScreen.trophyLine(-5), "0 Trophies · Fern Gully")
	local rows = ProfileScreen.arenaRows(620)
	eq(#rows, 8)
	eq(rows[1].text, "0 · Fern Gully")
	eq(rows[8].text, "4000 · Rex Kingdom")
	local marks = {}
	for _, row in rows do
		table.insert(marks, if row.current then "C" elseif row.reached then "r" else "-")
	end
	eq(table.concat(marks), "rrC-----", "Muddy Springs at 620")
	eq(rows[3].reached, true, "your own arena counts as reached")
	eq(rows[4].reached, false)
	eq(ProfileScreen.arenaRows(0)[1].current, true, "everyone starts in Fern Gully")
end)

test("T83 Trophy board rows: the badge is the Trophy count, the band its arena (capped)", function()
	local line = ProfileScreen.trophyBoardLine({ userId = 1, name = "Ava", xp = 1600, rank = 2, self = true } :: any, "Trapper", 4)
	eq(line.level, 1600, "badge = Trophies")
	eq(line.band, 4, "Volcano Rim is arena 5, capped to 4 bands")
	eq(line.self, true)
	eq(ProfileScreen.trophyBoardLine({ userId = 2, name = "Bo", xp = 300, rank = 3 } :: any, nil, 4).band, 2)
	eq(ProfileScreen.trophyContent(8, 100), ProfileScreen.SECTION + (ProfileScreen.ARENA + ProfileScreen.GAP) * 8 + ProfileScreen.GAP + 100)
end)
