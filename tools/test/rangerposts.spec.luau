--[[
	Ranger Station posts UI (PLAN 9j T130; Shared/RangerPosts): the rows, the hint, advancing
	post by post, when "Move posts" shows, the no-trap rule (fits PHONE / SMALL / FULL and a
	spread of windows with Back and X on screen; closes on every match-state change
	PanelRules doesn't allow, like placing), and the server's checks (Server/Shop "post",
	Server/Towers.setPost).
]]

local fs = require("@lune/fs")
local OptionPick = require(src.shared.OptionPick)
local PanelRules = require(src.shared.PanelRules)
local RangerPosts = require(src.shared.RangerPosts)
local Config = require(src.shared.Config)

-- The 3 window sizes PLAN T112 names, and a spread of others.
local PHONE, SMALL, FULL = { 375, 667 }, { 800, 600 }, { 1920, 1080 }
local WINDOWS = {
	FULL, SMALL, PHONE, { 2560, 1440 }, { 1366, 768 }, { 1024, 768 }, { 812, 375 }, { 667, 375 },
	{ 568, 320 }, { 375, 812 }, { 360, 640 }, { 320, 568 }, { 480, 320 }, { 400, 300 },
}

test("the posts panel fits every window: header (Back + X) and at least one row on screen", function()
	local most = Config.Tuning.MaxPosts + 1 -- every post and Done
	for _, window in WINDOWS do
		for _, hud in { false, true } do
			local x, y = window[1], window[2]
			local where = `{x}x{y}{if hud then " (build HUD)" else ""}`
			local shape = RangerPosts.layout(x, y, most, hud)
			ok(shape.width <= x - OptionPick.EDGE * 2 + 1e-6, `{where}: width {shape.width}`)
			ok(shape.top + shape.height <= y - OptionPick.BOTTOM + 1e-6, `{where}: bottom {shape.top + shape.height} on screen`)
			ok(shape.listHeight >= RangerPosts.ROW - 1e-6, `{where}: at least one row shows ({shape.listHeight})`)
			local header = OptionPick.header(true)
			ok(-header.titleRight < shape.width, `{where}: the title leaves room for Back and X`)
		end
	end
	local full = RangerPosts.layout(FULL[1], FULL[2], most)
	eq(full.listHeight, most * RangerPosts.ROW + (most - 1) * RangerPosts.ROW_GAP, "FULL: every row without scrolling")
	local phone = RangerPosts.layout(PHONE[1], PHONE[2], most)
	eq(phone.width, PHONE[1] - OptionPick.EDGE * 2, "PHONE: narrower, the X stays on screen")
end)

test("rows: one per post (the one a click sets marked), then Done; advance; hint", function()
	local rows = RangerPosts.rows(3, 2, { [1] = true, [2] = true, [3] = true })
	eq(#rows, 4)
	ok(rows[2].current and not rows[1].current, "post 2 is being set")
	ok(string.find(rows[2].text, "Post 2 of 3", 1, true) ~= nil)
	ok(string.find(rows[1].text, "tap to move", 1, true) ~= nil, "a placed post can be moved")
	eq(rows[4].text, RangerPosts.DONE)
	eq(RangerPosts.advance(1, 3), 2)
	eq(RangerPosts.advance(3, 3), nil, "all set: back")
	ok(string.find(RangerPosts.hint(1, true, nil), "Q to stop", 1, true) ~= nil, "Q stops too")
	eq(RangerPosts.hint(1, false, "Too far from the station"), "Too far from the station")
end)

test("Move posts shows only for an own, standing station whose rangers use posts", function()
	ok(RangerPosts.movable("RANGER", 2, true, true, false))
	ok(not RangerPosts.movable("RAPTOR", 2, true, true, false), "a Raptor Pen")
	ok(not RangerPosts.movable("RANGER", 0, true, true, false), "no posts")
	ok(not RangerPosts.movable("RANGER", 2, false, true, false), "Patrol Jeep / Bodyguards: posts unused")
	ok(not RangerPosts.movable("RANGER", 2, true, false, false), "another camp's")
	ok(not RangerPosts.movable("RANGER", 2, true, true, true), "Trampled")
end)

test("no trap: the posts mode opens and closes exactly where placing does", function()
	for _, state in { "Lobby", "Building", "Playing", "Results", "Countdown" } do
		eq(PanelRules.allowed(RangerPosts.MODE, state, true), PanelRules.allowed("placing", state, true), state)
		eq(PanelRules.keepOnStateChange(RangerPosts.MODE, state, true), PanelRules.keepOnStateChange("placing", state, true), state)
	end
	ok(not PanelRules.allowed(RangerPosts.MODE, "Playing", true, true), "a spectator can't set posts")
	ok(not PanelRules.keepOnStateChange(RangerPosts.MODE, "Lobby", true), "closes when the match ends")
end)

test("wiring: the client asks, the server checks (camp, Trampled, on the track, Range, pools)", function()
	local shop = fs.readFile("src/server/Shop.luau")
	ok(shop:find('elseif action == "post" then', 1, true) ~= nil, "Shop takes a post request")
	ok(shop:find("local onTrack = Placement.check(spot, {}, true, Sides.zone(layout, side))", 1, true) ~= nil, "on the camp's own track")
	ok(shop:find('Sides.manageRefusal("post", side, tower.side)', 1, true) ~= nil, "never an enemy's station")
	local towers = fs.readFile("src/server/Towers.luau")
	ok(towers:find("Ranger.checkPost(onTrack, Vector2.new(offset.X, offset.Z).Magnitude, stats.range, inPool)", 1, true) ~= nil, "Range and pools")
	local client = fs.readFile("src/client/Shop.client.luau")
	ok(client:find('backButton.Visible = picking or mode == "posts"', 1, true) ~= nil, "Back shows in the posts mode")
	ok(client:find('if send("post", body:GetAttribute("TowerId"), postSetting, nil, spot) then', 1, true) ~= nil, "the request")
	ok(client:find('player:SetAttribute("Placing", newMode == "placing" or newMode == "posts")', 1, true) ~= nil, "third person while setting posts, like placing")
end)
