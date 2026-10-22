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
	["src/client/Home.client.luau"] = { "menuToggle.Position = UDim2.fromOffset(DOCK_MARGIN, SafeArea.topFor(DOCK_MARGIN,", "SafeArea.band(viewport.Y", "SafeArea.topFor(left, inset, live)" },
	["src/client/HuntBoard.client.luau"] = { "local top = SafeArea.top(GuiService:GetGuiInset().Y)", "local clear = SafeArea.topFor(" },
	["src/client/Profile.client.luau"] = { "local top = SafeArea.top(GuiService:GetGuiInset().Y)", "local clear = SafeArea.topFor(" },
	["src/client/Training.client.luau"] = { "panel.Position = UDim2.new(1, -16, 0, SafeArea.topFor(", "foldButton.Position = UDim2.new(1, -16, 0, SafeArea.topFor(" },
	["src/client/Pets.client.luau"] = { "local top = SafeArea.topFor(" },
	["src/client/Hud.client.luau"] = { "SafeArea.centreX(viewX, SafeArea.HUD_W, inset, live)", "startButton.Position = UDim2.new(0, x, 0, SafeArea.localTop(inset))", "local RESULTS_TOP = SafeArea.topFor(16,", "button.Position = UDim2.new(0, 12, 0, SafeArea.topFor(12," },
	["src/client/Shop.client.luau"] = { "SafeArea.buildHud(inset)", "SafeArea.centreX(viewX, SafeArea.HUD_W, inset, live)" },
	["src/client/Counter.client.luau"] = { "local top = SafeArea.topFor(" },
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

-- PLAYTEST Run 14 F13b: Roblox's chat window (top left, (8, 12) 283x141 under a 58 px bar =
-- screen x 8-291, y 70-211) eats clicks even when it looks empty.
local CHAT = { x1 = 8, x2 = 291, y1 = 70, y2 = 211 }
local function inChat(x: number, y: number): boolean
	return x >= CHAT.x1 and x <= CHAT.x2 and y >= CHAT.y1 and y <= CHAT.y2
end

test("the chat box covers the measured chat window (no live config, every top bar)", function()
	for _, inset in { 0, 36, 58, 72 } do
		local right, bottom = SafeArea.chatBox(inset)
		ok(right > CHAT.x2, `inset {inset}: right {right} clears x 291`)
		ok(bottom > math.max(inset, 58) + 12 + 141, `inset {inset}: bottom {bottom} under the window`)
		ok(SafeArea.chatTop(inset) > bottom and SafeArea.chatTop(inset) >= SafeArea.top(inset), `inset {inset}: chatTop under both`)
	end
	eq(SafeArea.chatTop(58), 230, "today's top bar: 230")
end)

test("the live chat window wins when it is bigger or moved; an unreadable one falls back", function()
	local right, bottom = SafeArea.chatBox(58, { x = 8, y = 12, w = 500, h = 300 })
	ok(right >= 508 and bottom >= 58 + 312, "a resized window is covered")
	local r2, b2 = SafeArea.chatBox(58, { x = 8, y = 12, w = 10, h = 10 })
	eq(r2, SafeArea.CHAT_RIGHT, "a small live window never shrinks the default (x)")
	eq(b2, 58 + SafeArea.CHAT_BELOW_BAR, "a small live window never shrinks the default (y)")
	eq(SafeArea.liveChat(nil), nil, "no service")
	eq(SafeArea.liveChat({}), nil, "no ChatWindowConfiguration")
	eq(SafeArea.liveChat(setmetatable({}, { __index = function() error("locked") end })), nil, "a read that throws")
	eq(SafeArea.liveChat({ ChatWindowConfiguration = { Enabled = false } }), nil, "chat off")
	local live = SafeArea.liveChat({ ChatWindowConfiguration = { Enabled = true, AbsolutePosition = { X = 8, Y = 12 }, AbsoluteSize = { X = 283, Y = 141 } } })
	ok(live ~= nil and live.w == 283 and live.h == 141, "a readable window")
end)

test("Run 14's dead controls fail clickableAt; their new places pass", function()
	-- Hide menu at GUI (16, 92) 150x40 = screen top 150: in the chat window.
	ok(inChat(16 + 75, 150) and not SafeArea.clickableAt(16, 150, 58), "Hide menu at screen y 150")
	-- The Profile tab, screen x 85, top 204.
	ok(not SafeArea.clickableAt(85, 204, 58), "Profile tab top at 204")
	-- Controls right of it (the Xs at x > 489) were fine and stay fine.
	ok(SafeArea.clickableAt(489, 150, 58), "an X at x 489 on the safe line")
	-- New places: Hide menu at topFor(16), any left control under chatTop.
	local y = SafeArea.topFor(16, 58)
	ok(SafeArea.clickableAt(16, y, 58) and not inChat(16, y), `Hide menu at {y}`)
	eq(SafeArea.topFor(489, 58), SafeArea.top(58), "right of the box: the usual line")
end)

test("no point of a control placed by topFor / centreX is in the chat window", function()
	for _, viewX in { 320, 375, 480, 707, 1024, 1920 } do
		-- The build stack (Start, H, M; 220 wide): on a window ≥ 540 px wide no corner is in
		-- the chat window; narrower (phones; N20 keeps its height) its right end still clears.
		local cx = SafeArea.centreX(viewX, SafeArea.HUD_W, 58)
		local hud = SafeArea.buildHud(58)
		for _, y in { hud.start, hud.hero, hud.mastery } do
			for _, px in { cx - 110, cx, cx + 109 } do
				ok(viewX < 540 or not inChat(px, y), `{viewX}: build button at ({px}, {y})`)
			end
			ok(not inChat(cx + 109, y), `{viewX}: its right end clear at y {y}`)
		end
		ok(cx - 110 >= 0 and cx + 110 <= viewX, `{viewX}: Start inside the window`)
		-- A centred panel w wide: its top from topFor(left) never lies in the window.
		for _, w in { 300, 400, 540 } do
			local pl = (viewX - math.min(w, viewX - 16)) / 2
			local top = SafeArea.topFor(pl, 58)
			for _, px in { pl, pl + 20, viewX / 2 } do
				ok(not inChat(px, top), `{viewX}/{w}: panel top-left ({px}, {top})`)
			end
		end
	end
end)
