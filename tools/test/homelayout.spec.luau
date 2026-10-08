--[[
	The home screen's bottom rows and the Hunt Board header (DECISIONS #138; Shared/HomeLayout,
	Shared/HuntBoard). Text widths are GothamBold estimates, not measurements; the home column
	scales as a whole, so fitting at 740 means fitting on every window (the #96 rule: no wrap).
]]
local HomeLayout = require(src.shared.HomeLayout)
local HuntBoard = require(src.shared.HuntBoard)
local ProfileScreen = require(src.shared.ProfileScreen)

test("the action row is Choose hero 200, Unlocks & Mastery 240, PLAY 240 at 28 px", function()
	local cards = HomeLayout.actionCards()
	eq(#cards, 3, "three buttons")
	eq(cards[1].width, 200, "Choose hero")
	eq(cards[2].width, 240, "Unlocks & Mastery")
	eq(cards[3].width, 240, "PLAY width")
	eq(cards[3].textSize, 28, "PLAY text")
	eq(cards[3].text, "PLAY", "PLAY label")
end)

test("both rows fit the 740 px column", function()
	local widths = {}
	for _, card in HomeLayout.actionCards() do
		table.insert(widths, card.width)
	end
	local row = HomeLayout.rowWidth(widths)
	eq(row, 700, "action row")
	ok(row <= HomeLayout.COLUMN, `action row {row} > {HomeLayout.COLUMN}`)
	ok(HomeLayout.rowWidth({ HomeLayout.HUNT_WIDTH, HomeLayout.PROFILE_WIDTH }) <= HomeLayout.COLUMN, "Hunt Board row with Profile")
end)

test("no button's text wraps", function()
	for _, card in HomeLayout.actionCards() do
		ok(HomeLayout.fits(card), `"{card.text}" ({math.floor(HomeLayout.textWidth(card.text, card.textSize))} px) in {card.width}`)
	end
	local hunt = { width = HomeLayout.HUNT_WIDTH, textSize = HomeLayout.HUNT_TEXT_SIZE, text = HuntBoard.BUTTON }
	ok(HomeLayout.fits(hunt), `"{hunt.text}" in {hunt.width}`)
	local profile = { width = HomeLayout.PROFILE_WIDTH, textSize = HomeLayout.HUNT_TEXT_SIZE, text = ProfileScreen.BUTTON }
	ok(HomeLayout.fits(profile), `"{profile.text}" in {profile.width}`)
end)

test("the text estimate catches a button that would wrap", function()
	ok(not HomeLayout.fits({ width = 142, textSize = 16, text = "Unlocks & Mastery  (M)" }), "old-size card")
	ok(HomeLayout.textWidth("AB", 10) > HomeLayout.textWidth("ab", 10), "capitals are wider")
end)

test("the Hunt Board header shows the Amber balance", function()
	eq(HuntBoard.balance(1250), "1,250 Amber", "grouped")
	eq(HuntBoard.balance(0), "0 Amber", "zero")
	eq(HuntBoard.balance(nil), "0 Amber", "not loaded yet")
	eq(HuntBoard.balance(-3), "0 Amber", "never negative")
end)

test("the title and a 6-digit balance fit the header on the narrowest board", function()
	for _, width in { HuntBoard.MIN_WIDTH, HuntBoard.WIDTH } do
		local titleWidth, balanceWidth = HuntBoard.headerWidths(width)
		local inner = width - HuntBoard.PAD * 2
		ok(titleWidth + balanceWidth + HuntBoard.HEADER + 16 <= inner, `header overflows at {width}`)
		ok(HomeLayout.textWidth(HuntBoard.TITLE, HuntBoard.TITLE_MIN) <= titleWidth, `title at {width}`)
		ok(HomeLayout.textWidth(HuntBoard.balance(1234), HuntBoard.BALANCE_SIZE) <= balanceWidth, `balance at {width}`)
		ok(HomeLayout.textWidth(HuntBoard.balance(999999), HuntBoard.BALANCE_MIN) <= balanceWidth, `big balance at {width}`)
	end
end)

test("T79b: a mid-battle joiner waits on the home screen with the banner", function()
	eq(HomeLayout.WAITING_BANNER, "A hunt is on — you'll join the next one.")
	eq(HomeLayout.waitingForNextHunt("Playing", "ROYALE", nil), true, "joined during play")
	eq(HomeLayout.waitingForNextHunt("Building", "TEAM", nil), true, "joined during the build phase")
	eq(HomeLayout.waitingForNextHunt("Playing", "TEAM", 2), false, "seated hunters play")
	eq(HomeLayout.waitingForNextHunt("Playing", nil, nil), false, "co-op: drop straight in")
	eq(HomeLayout.waitingForNextHunt("Victory", "TEAM", nil), false, "closes when the hunt ends")
	eq(HomeLayout.waitingForNextHunt("Lobby", nil, nil), false, "the lobby is the normal home screen")
end)

test("T79b: the waiting banner frees the mouse and fits the window", function()
	local fs = require("@lune/fs")
	local home = fs.readFile("src/client/Home.client.luau")
	ok(home:find("waitBanner.Modal = true", 1, true) ~= nil, "Modal: the mouse is free")
	ok(home:find("waitBanner.TextWrapped = true", 1, true) ~= nil, "wraps")
	ok(home:find("waitBanner.Size = UDim2.new(0.8, 0, 0, 0)", 1, true) ~= nil, "a share of the window wide")
	ok(home:find("gui.Enabled = inLobby or wait", 1, true) ~= nil, "shown while waiting")
end)
