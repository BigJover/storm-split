--[[
	What the Hunt Board screen shows (Shared/HuntBoard): when it's on screen, its text,
	the state of every button, and that it always fits the window (DIRECTION: no pop-up
	may ever trap a player).
]]
local Config = require(src.shared.Config)
local HuntBoard = require(src.shared.HuntBoard)
local Theme = require(src.shared.Theme)

local function firstBounty(pool: string, event: string?): string
	for _, id in Config.BountyOrder do
		local def = Config.Bounties[id]
		if def.pool == pool and (event == nil or def.event == event) then
			return id
		end
	end
	error(`no {pool} bounty for {event}`)
end

test("the board shows on the home screen only, and only when it's open", function()
	eq(HuntBoard.shown(true, "Lobby"), true, "open in Lobby")
	eq(HuntBoard.shown(false, "Lobby"), false, "closed in Lobby")
	for _, state in { "Building", "Playing", "GameOver", "Victory" } do
		eq(HuntBoard.shown(true, state), false, `open in {state}`)
	end
	eq(HuntBoard.shown(true, nil), false, "before the state is known")
end)

test("names come from Theme", function()
	eq(HuntBoard.TITLE, string.upper(Theme.HuntBoard), "title")
	eq(HuntBoard.BUTTON, "Hunt Board [G]", "home button (DECISIONS #76)")
end)

test("countdown text", function()
	eq(HuntBoard.countdown(5 * 3600 + 12 * 60), "5h 12m", "hours and minutes")
	eq(HuntBoard.countdown(5 * 3600 + 11 * 60 + 1), "5h 12m", "minutes round up")
	eq(HuntBoard.countdown(3 * 86400 + 4 * 3600), "3d 4h", "days and hours")
	eq(HuntBoard.countdown(86400), "1d 0h", "exactly a day")
	eq(HuntBoard.countdown(12 * 60), "12m", "minutes only")
	eq(HuntBoard.countdown(3600), "1h 0m", "exactly an hour")
	eq(HuntBoard.countdown(1), "1m", "the last minute")
	eq(HuntBoard.countdown(0), "1m", "never 0m")
	eq(HuntBoard.countdown(-50), "1m", "never negative")
	eq(HuntBoard.resetLine(5 * 3600 + 12 * 60), "New bounties in 5h 12m", "the line")
end)

test("the countdown runs down locally and stops at zero", function()
	eq(HuntBoard.remaining(100, 30), 70, "30 s in")
	eq(HuntBoard.remaining(100, 130), 0, "past the reset")
	eq(HuntBoard.remaining(100, -5), 100, "a clock that went backwards")
end)

test("the reset payout line shows only when something was paid", function()
	eq(HuntBoard.payoutLine(35), `Unclaimed bounties paid: +35 {Theme.Currency}`, "35")
	eq(HuntBoard.payoutLine(0), nil, "nothing paid")
	eq(HuntBoard.payoutLine(nil), nil, "missing")
	eq(HuntBoard.payoutLine(-5), nil, "negative")
end)

test("the Haul note matches the lever", function()
	local expected = if Config.Tuning.HaulResetsAfterMissedDays > 0 then nil else "Missed days don't reset your Haul."
	eq(HuntBoard.haulNote(), expected, "note")
end)

test("a card in progress: text from the sheet, a bar, and Swap while swaps are left", function()
	local id = firstBounty("daily", "pop")
	local def = Config.Bounties[id]
	local card = HuntBoard.card({ id = id, progress = 12, claimed = false }, 1, nil)
	ok(card ~= nil, "card")
	eq(card.title, def.title, "title")
	ok(not string.find(card.text, "{n}", 1, true), "{n} filled in")
	ok(string.find(card.text, tostring(def.count), 1, true) ~= nil, "the count is in the text")
	eq(card.chip, `+{def.amber}`, "Amber chip")
	eq(card.progress, `12 / {def.count}`, "progress text")
	near(card.fraction, 12 / def.count, "bar")
	eq(card.state, "progress", "state")
	eq(card.species, def.target, "colour dot species")
	eq(card.action, "swap", "action")
	eq(card.actionText, "Swap (1 left)", "swap text")
	eq(card.enabled, true, "enabled")

	local none = HuntBoard.card({ id = id, progress = 12, claimed = false }, 0, nil)
	eq(none.action, "none", "out of swaps: no button")
	eq(none.enabled, false, "out of swaps: nothing to press")
end)

test("a finished card offers Claim, never Swap; progress never reads past the count", function()
	local id = firstBounty("daily")
	local def = Config.Bounties[id]
	local card = HuntBoard.card({ id = id, progress = def.count + 7, claimed = false }, 1, nil)
	eq(card.state, "done", "state")
	eq(card.action, "claim", "action")
	eq(card.actionText, "Claim", "text")
	eq(card.enabled, true, "enabled")
	eq(card.fraction, 1, "bar is full, not past full")
	ok(string.find(card.progress, " / ", 1, true) ~= nil, "progress text")
	eq(string.match(card.progress, "^(.-) / "), string.match(card.progress, " / (.+)$"), "12 / 12, not 19 / 12")
end)

test("a claimed card has no button", function()
	local id = firstBounty("weekly")
	local def = Config.Bounties[id]
	local card = HuntBoard.card({ id = id, progress = def.count, claimed = true }, 1, nil)
	eq(card.state, "claimed", "state")
	eq(card.action, "none", "action")
	eq(card.enabled, false, "enabled")
end)

test("while a request is in flight every button is disabled and the pressed one waits", function()
	local a, b = Config.BountyOrder[1], Config.BountyOrder[2]
	local pressed = HuntBoard.card({ id = a, progress = Config.Bounties[a].count, claimed = false }, 1, a)
	eq(pressed.action, "wait", "pressed claim")
	eq(pressed.actionText, "…", "pressed text")
	eq(pressed.enabled, false, "pressed disabled")
	local swapping = HuntBoard.card({ id = a, progress = 0, claimed = false }, 1, a)
	eq(swapping.action, "wait", "pressed swap")
	local other = HuntBoard.card({ id = b, progress = 0, claimed = false }, 1, a)
	eq(other.action, "swap", "another card keeps its button")
	eq(other.enabled, false, "but disabled")
	local duringHaul = HuntBoard.card({ id = b, progress = Config.Bounties[b].count, claimed = false }, 1, HuntBoard.HAUL)
	eq(duringHaul.action, "claim", "claim shown during a Haul claim")
	eq(duringHaul.enabled, false, "but disabled")
	local claimed = HuntBoard.card({ id = a, progress = Config.Bounties[a].count, claimed = true }, 1, a)
	eq(claimed.action, "none", "a claimed card never shows the wait mark")
end)

test("big numbers get a comma", function()
	for _, id in Config.BountyOrder do
		local def = Config.Bounties[id]
		if def.count >= 1000 then
			local card = HuntBoard.card({ id = id, progress = 0, claimed = false }, 0, nil)
			local head = tostring(def.count // 1000)
			ok(string.find(card.text, head .. ",", 1, true) ~= nil, `{id}: {card.text}`)
			return
		end
	end
end)

test("unknown or broken entries are left off the board", function()
	eq(HuntBoard.card({ id = "NOT_A_BOUNTY", progress = 0, claimed = false }, 1, nil), nil, "unknown id")
	local id = Config.BountyOrder[1]
	local list: any = {
		{ id = id, progress = 0, claimed = false },
		{ id = "NOT_A_BOUNTY", progress = 0, claimed = false },
		"junk",
		{ id = 5, progress = 0 },
		{ id = id },
	}
	local cards = HuntBoard.cards(list, 1, nil)
	eq(#cards, 1, "only the valid one")
	eq(cards[1].id, id, "it's the valid one")
	eq(#HuntBoard.cards(nil, 1, nil), 0, "no list at all")
end)

test("Haul tiles: past days claimed, today open, the rest to come, Big Haul last", function()
	local days = #Config.DailyHaul
	local tiles = HuntBoard.haul(3, false, nil)
	eq(#tiles, days, "one tile per Haul day")
	for day, tile in tiles do
		local expected = if day < 3 then "claimed" elseif day == 3 then "open" else "future"
		eq(tile.state, expected, `day {day} state`)
		eq(tile.today, day == 3, `day {day} today`)
		eq(tile.chip, `+{Config.DailyHaul[day].amber}`, `day {day} Amber`)
		eq(tile.big, day == days, `day {day} big`)
		eq(tile.label, if day == days then Theme.BigHaul else `Day {day}`, `day {day} label`)
		eq(tile.action, if day == 3 then "claim" else "none", `day {day} action`)
		eq(tile.enabled, day == 3, `day {day} enabled`)
	end
	eq(tiles[3].actionText, "Claim", "today's button")
end)

test("Haul tiles: once claimed, today is stamped and nothing can be pressed", function()
	for day, tile in HuntBoard.haul(3, true, nil) do
		eq(tile.state, if day <= 3 then "claimed" else "future", `day {day} state`)
		eq(tile.today, day == 3, `day {day} today`)
		eq(tile.action, "none", `day {day} action`)
		eq(tile.enabled, false, `day {day} enabled`)
	end
end)

test("Haul tiles: in flight", function()
	local own = HuntBoard.haul(1, false, HuntBoard.HAUL)[1]
	eq(own.action, "wait", "the Haul claim waits")
	eq(own.actionText, "…", "text")
	eq(own.enabled, false, "disabled")
	local other = HuntBoard.haul(1, false, Config.BountyOrder[1])[1]
	eq(other.action, "claim", "Claim shown during a bounty request")
	eq(other.enabled, false, "but disabled")
end)

test("Haul tiles stay inside the strip: one row when wide, 4 + 3 when narrow", function()
	local days = #Config.DailyHaul
	for _, width in { 200, 276, 311, 439, 440, 536 } do
		local rects = HuntBoard.tileRects(width)
		eq(#rects, days, `{width}: a rect per day`)
		local rows = {}
		for day, rect in rects do
			ok(rect.x >= 0 and rect.x + rect.width <= width + 1e-6, `{width}: day {day} inside the strip`)
			ok(rect.width > 0, `{width}: day {day} has a width`)
			rows[rect.y] = (rows[rect.y] or 0) + 1
		end
		local wrap = width < HuntBoard.WRAP_BELOW
		eq(rows[0], if wrap then math.ceil(days / 2) else days, `{width}: first row`)
		near(rects[days].width, rects[days - 1].width * HuntBoard.BIG_TILE, `{width}: Big Haul is wider`, 1e-6)
		for day = 2, days do
			if rects[day].y == rects[day - 1].y then
				ok(rects[day].x >= rects[day - 1].x + rects[day - 1].width, `{width}: day {day} doesn't overlap`)
			end
		end
	end
end)

-- The no-trap rule: on every window the whole board, header and X included, sits
-- between the top of the screen and the home screen's Play row.
local WINDOWS = {
	{ 1920, 1080 }, { 1366, 768 }, { 1024, 768 }, { 800, 600 }, { 812, 375 }, { 667, 375 },
	{ 568, 320 }, { 375, 812 }, { 360, 640 }, { 320, 568 }, { 480, 320 }, { 2560, 1440 },
}

test("the board fits every window, above the Play row", function()
	local content = 2 * HuntBoard.SECTION + 6 * HuntBoard.CARD + 8 * HuntBoard.GAP
	for _, window in WINDOWS do
		local x, y = window[1], window[2]
		-- The Play row is in the bottom part of the home screen; try a few places for it.
		for _, band in { { 44, y - 16 }, { 44, y * 0.85 }, { 8, y * 0.7 }, { 60, y * 0.6 } } do
			local top, bottom = band[1], band[2]
			local where = `{x}x{y} band {top}-{bottom}`
			local layout = HuntBoard.layout(x, top, bottom, content)
			ok(layout.scale >= HuntBoard.MIN_SCALE and layout.scale <= 1, `{where}: scale {layout.scale}`)
			ok(layout.width * layout.scale <= x - HuntBoard.EDGE * 2 + 1e-6, `{where}: width {layout.width} x {layout.scale}`)
			ok(layout.width <= HuntBoard.WIDTH, `{where}: never wider than the full board`)
			ok(layout.listHeight >= 0 and layout.listHeight <= content, `{where}: list {layout.listHeight}`)
			eq(layout.height, HuntBoard.fixedHeight(layout.wrap) + layout.listHeight, `{where}: height adds up`)
			if layout.scale > HuntBoard.MIN_SCALE then
				ok(layout.height * layout.scale <= bottom - top + 1e-6, `{where}: height {layout.height} x {layout.scale}`)
				ok(layout.listHeight >= HuntBoard.MIN_LIST - 1, `{where}: at least a card of the list shows ({layout.listHeight})`)
			end
			-- The strip the tiles are laid into matches the wrap the height was worked out for.
			local rects = HuntBoard.tileRects(layout.width - HuntBoard.PAD * 2)
			local last = rects[#rects]
			eq(last.y > 0, layout.wrap, `{where}: wrap agrees with the tiles`)
			eq(last.y + last.height, HuntBoard.stripHeight(layout.wrap), `{where}: the tiles fill the strip exactly`)
		end
	end
end)

test("a roomy window gets the full board with nothing to scroll", function()
	local content = 2 * HuntBoard.SECTION + 6 * HuntBoard.CARD + 8 * HuntBoard.GAP
	local layout = HuntBoard.layout(1920, 44, 1000, content)
	eq(layout.scale, 1, "scale")
	eq(layout.width, HuntBoard.WIDTH, "width")
	eq(layout.wrap, false, "one Haul row")
	eq(layout.listHeight, content, "the whole list shows")
end)

test("a short list makes a short board", function()
	local layout = HuntBoard.layout(1920, 44, 1000, 40)
	eq(layout.listHeight, 40, "list")
	eq(layout.scale, 1, "scale")
	local empty = HuntBoard.layout(1920, 44, 1000, 0)
	eq(empty.listHeight, 0, "empty list")
end)

test("a narrow window wraps the Haul and a short one scrolls the list before scaling", function()
	local content = 2 * HuntBoard.SECTION + 6 * HuntBoard.CARD + 8 * HuntBoard.GAP
	local narrow = HuntBoard.layout(375, 44, 700, content)
	eq(narrow.wrap, true, "wraps")
	eq(narrow.scale, 1, "no need to scale")
	eq(narrow.width, 375 - HuntBoard.EDGE * 2, "fills the width")
	local short = HuntBoard.layout(1366, 44, 44 + HuntBoard.fixedHeight(false) + 150, content)
	eq(short.scale, 1, "scrolls instead of scaling")
	eq(short.listHeight, 150, "list takes what's left")
end)
