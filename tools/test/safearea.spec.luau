--[[
	Every interactive control sits under the CoreGui band (PLAYTEST Run 13 F13, Shared/SafeArea):
	clicks at screen y ≈ 58–140 "hit CoreGUI", so "Hide menu" and the top halves of the
	Training and Hatchery Hut X couldn't be pressed. The rule, and a source check that every
	panel and top button reads it instead of a fixed offset in that band.
]]
local fs = require("@lune/fs")
local SafeArea = require(src.shared.SafeArea)
local OptionPick = require(src.shared.OptionPick)

test("the safe line clears the measured band on every top bar", function()
	for _, inset in { 0, 36, 58, 72 } do
		local top = SafeArea.top(inset)
		ok(top > 140, `inset {inset}: top {top} below the band (y ≤ 140)`)
		ok(top >= inset + SafeArea.CORE_BAND, `inset {inset}: under the top bar and the band`)
		eq(SafeArea.localTop(inset) + inset, top, `inset {inset}: local and screen agree`)
	end
	eq(SafeArea.top(58), 150, "today's top bar: 150")
	eq(SafeArea.top(nil), SafeArea.TOP, "unknown inset = the default")
end)

test("the controls Run 13 found dead fail the rule; their new places pass", function()
	-- Old places (screen y of each control's top edge, 58 px top bar).
	ok(not SafeArea.clickable(64, 58), "Hide menu at (16, 64) on a full-screen gui")
	ok(not SafeArea.clickable(58 + 64, 58), "Training toggle / panel X at local 64")
	ok(not SafeArea.clickable(58 + 60, 58), "Start at local 60")
	ok(SafeArea.clickable(SafeArea.top(58), 58), "on the safe line")
	ok(SafeArea.clickable(58 + SafeArea.localTop(58), 58), "local safe line")
end)

test("panels fit the band on short windows and never start above it", function()
	for _, h in { 360, 480, 720, 1080 } do
		local top, bottom = SafeArea.band(h, 58, 16)
		ok(top >= SafeArea.top(58), `{h}: top`)
		ok(bottom > top, `{h}: not upside down`)
		local scale = SafeArea.fitScale(500, h, 58, 16, 0.2, 1)
		ok(500 * scale <= bottom - top + 1e-6 or scale == 0.2, `{h}: 500 px content fits (x{scale})`)
		-- A frame centred in the band (Home's column): its top edge is on or under the line.
		local offset = SafeArea.centerOffset(h, 58, 16)
		local content = math.min(400, bottom - top)
		ok(h / 2 + offset - content / 2 >= top - 1, `{h}: centred content starts in the band`)
	end
end)

test("the build-phase stack (Start, H, M) starts on the safe line, in order, without overlap", function()
	for _, inset in { 0, 36, 58 } do
		local hud = SafeArea.buildHud(inset)
		eq(hud.start, SafeArea.top(inset), `{inset}: Start on the line`)
		ok(hud.hero >= hud.start + SafeArea.START_H, `{inset}: H under Start`)
		ok(hud.mastery >= hud.hero + SafeArea.HERO_H, `{inset}: M under H`)
		eq(hud.bottom, hud.mastery + SafeArea.MASTERY_H, `{inset}: bottom`)
	end
	ok(OptionPick.BUILD_HUD_BOTTOM > SafeArea.buildHud(nil).bottom, "the shop panel's reserve clears M")
	ok(OptionPick.TOP >= SafeArea.TOP, "the shop panel's X never rises into the band")
end)

-- Source guard: each panel/top control places itself from SafeArea (a regression to a fixed
-- offset in the band fails here).
local USES = {
	["src/client/Home.client.luau"] = { "menuToggle.Position = UDim2.fromOffset(DOCK_MARGIN, SafeArea.top(", "SafeArea.band(viewport.Y" },
	["src/client/HuntBoard.client.luau"] = { "local top = SafeArea.top(GuiService:GetGuiInset().Y)" },
	["src/client/Profile.client.luau"] = { "local top = SafeArea.top(GuiService:GetGuiInset().Y)" },
	["src/client/Training.client.luau"] = { "panel.Position = UDim2.new(1, -16, 0, SafeArea.localTop(", "foldButton.Position = UDim2.new(1, -16, 0, SafeArea.localTop(" },
	["src/client/Pets.client.luau"] = { "panel.Position = UDim2.new(0.5, 0, 0, SafeArea.localTop(" },
	["src/client/Hud.client.luau"] = { "startButton.Position = UDim2.new(0.5, 0, 0, SafeArea.localTop(", "battleResults.Position = UDim2.new(0.5, 0, 0, SafeArea.localTop(" },
	["src/client/Shop.client.luau"] = { "SafeArea.buildHud(inset)" },
}

test("every panel and top button reads SafeArea (Home, Hunt Board, Profile, Training, Hatchery, HUD, Shop)", function()
	for path, needles in USES do
		local source = fs.readFile(path)
		for _, needle in needles do
			ok(source:find(needle, 1, true) ~= nil, `{path}: {needle}`)
		end
	end
	-- The old dead places are gone.
	ok(fs.readFile("src/client/Home.client.luau"):find("fromOffset(DOCK_MARGIN, 64)", 1, true) == nil, "Home: Hide menu at 64")
	ok(fs.readFile("src/client/Training.client.luau"):find("UDim2.new(1, -16, 0, 64)", 1, true) == nil, "Training at 64")
	ok(fs.readFile("src/client/Hud.client.luau"):find("UDim2.new(0.5, 0, 0, 60)", 1, true) == nil, "Start at 60")
end)
