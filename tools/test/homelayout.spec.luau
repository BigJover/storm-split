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

-- PLAN T82: the battle options, Ready and its confirm ------------------------------------

local Config = require(src.shared.Config)
local FEE = Config.Tuning.CompetitiveBuyIn

test("T82 the options row and the Ranked row fit the column; no chip text wraps", function()
	local widths = {}
	for _, card in HomeLayout.optionCards() do
		table.insert(widths, card.width)
		ok(HomeLayout.fits(card), `"{card.text}" in {card.width}`)
	end
	ok(HomeLayout.rowWidth(widths) <= HomeLayout.COLUMN, `options row {HomeLayout.rowWidth(widths)}`)
	ok(HomeLayout.rowWidth({ HomeLayout.READY_WIDTH, HomeLayout.READY_X, HomeLayout.READY_INFO }) <= HomeLayout.COLUMN, "Ranked row")
	for _, text in { HomeLayout.READY, HomeLayout.READY_DONE, HomeLayout.confirmText(FEE, "Amber"), HomeLayout.confirmText(20, "Amber") } do
		local card = { width = HomeLayout.READY_WIDTH, textSize = HomeLayout.READY_TEXT, text = text }
		ok(HomeLayout.fits(card), `"{text}" in the Ready card`)
	end
end)

test("T82 the battle rows show for battles only; camps for Camp Clash; stand-ins in Studio", function()
	local coop = HomeLayout.battleOptions("COOP", true)
	eq(coop.queue or coop.sides or coop.standIns, false, "co-op: none")
	local team = HomeLayout.battleOptions("TEAM", false)
	eq(team.queue, true)
	eq(team.sides, true)
	eq(team.standIns, false, "never outside Studio")
	local royale = HomeLayout.battleOptions("ROYALE", true)
	eq(royale.sides, false, "Bone Rush seats one camp per hunter")
	eq(royale.standIns, true)
	eq(royale.seats, true, "Studio: stand-in seats for Bone Rush")
	eq(team.seats, false)
	eq(HomeLayout.nextSeats(2), 3)
	eq(HomeLayout.nextSeats(Config.Tuning.BattleMaxPlayers), 2, "wraps")
	eq(HomeLayout.nextSeats(nil), 2)
	ok(HomeLayout.fits(HomeLayout.SEATS), "Seats chip")
	eq(HomeLayout.seatsText(Config.Tuning.BattleMaxPlayers), HomeLayout.SEATS.text, "the widest seat text is the one checked")
	eq(HomeLayout.readyRowVisible("TEAM", true), true)
	eq(HomeLayout.readyRowVisible("TEAM", false), false, "casual has no Ready")
	eq(HomeLayout.readyRowVisible("COOP", true), false, "co-op never stakes")
end)

test("T82 Ready refusal strings are PLAN's exact text", function()
	eq(HomeLayout.refusalLine("offline", FEE, "Amber"), "Your save didn't load, so you can't pay the Entry fee. Casual is still open.")
	eq(HomeLayout.refusalLine("cantAfford", 15, "Amber"), "You need 15 Amber for the Entry fee.")
	eq(HomeLayout.refusalLine("loading", FEE, "Amber"), "Your save is still loading. Try again in a moment.")
	eq(HomeLayout.refusalLine("somethingNew", FEE, "Amber"), "You can't ready up right now.")
	eq(HomeLayout.refusalLine(nil, FEE, "Amber"), nil, "not refused")
	eq(HomeLayout.PRACTICE_LINE, "Practice Hunt: session Amber only. Trophies won't change.")
end)

test("T82 the confirm closes on Ready, a state change, or the Ranked row going away", function()
	eq(HomeLayout.confirmOpen(true, "Lobby", "TEAM", true, false), true)
	eq(HomeLayout.confirmOpen(true, "Lobby", "TEAM", true, true), false, "Ready")
	for _, state in { "Building", "Playing", "Victory", "GameOver" } do
		eq(HomeLayout.confirmOpen(true, state, "TEAM", true, false), false, state)
	end
	eq(HomeLayout.confirmOpen(true, "Lobby", "TEAM", false, false), false, "Casual")
	eq(HomeLayout.confirmOpen(true, "Lobby", "COOP", true, false), false, "co-op")
	eq(HomeLayout.confirmOpen(false, "Lobby", "TEAM", true, false), false, "closed by its X")
end)

test("T82 PLAY enables at the minimum: Ranked counts Ready hunters, casual everyone", function()
	local okPlay, need = HomeLayout.canPlay("ROYALE", true, 5, 2, nil, false)
	eq(okPlay, false, "Ranked Bone Rush, 2 ready")
	eq(need, Config.Tuning.RoyaleMinPlayers)
	eq((HomeLayout.canPlay("ROYALE", true, 5, Config.Tuning.RoyaleMinPlayers, nil, false)), true)
	eq((HomeLayout.canPlay("ROYALE", false, 2, 0, nil, false)), true, "casual Bone Rush, 2 here")
	eq((HomeLayout.canPlay("TEAM", true, 4, 1, nil, false)), false, "1 ready")
	eq((HomeLayout.canPlay("TEAM", true, 4, 2, nil, false)), true, "1v1 allowed")
	local three, need3 = HomeLayout.canPlay("TEAM", false, 2, 0, 3, false)
	eq(three, false, "3 camps need 3 hunters")
	eq(need3, 3)
	eq((HomeLayout.canPlay("TEAM", false, 1, 0, nil, true)), true, "Studio stand-ins seat a solo host")
	eq((HomeLayout.canPlay("COOP", false, 1, 0, nil, false)), true, "co-op unchanged")
	eq(HomeLayout.readyLine({}, 3), "Ready: nobody yet (3 needed)")
	eq(HomeLayout.readyLine({ "Ann", "Bo" }, 3), "Ready: Ann, Bo (2 of 3 needed)")
end)
