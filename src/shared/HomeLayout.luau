--!strict
--[[
	The home screen's two bottom rows (DECISIONS #138): the Hunt Board on its own row,
	and under it the action row Choose hero 200 · Unlocks & Mastery 240 · PLAY 240 (28 px
	text). Sizes are visual only. The pure rules here let a spec check that both rows fit
	the 740 px column with no wrapped button text; the column scales as a whole on small
	windows (Home.client's UIScale), so fitting at 740 means fitting at every window.

	Text widths are estimates (GothamBold average advances), not measurements.
]]

local BattleFlow = require(script.Parent.BattleFlow)
local Config = require(script.Parent.Config)
local Modes = require(script.Parent.Modes)

local HomeLayout = {}

HomeLayout.COLUMN = 740 -- the home screen's column, before its UIScale
HomeLayout.GAP = 10 -- between the cards of a row
HomeLayout.CARD_PAD = 10 -- text inset on each side of a card
HomeLayout.ROW_HEIGHT = 56 -- the Hunt Board row and the action row
HomeLayout.HUNT_ROW = "HuntRow" -- its name: HuntBoard.client keeps the board above it

export type Card = { width: number, textSize: number, text: string }

HomeLayout.HERO = { width = 200, textSize = 16, text = "Choose hero  (H)" } :: Card
HomeLayout.UNLOCKS = { width = 240, textSize = 16, text = "Unlocks & Mastery  (M)" } :: Card
HomeLayout.PLAY = { width = 240, textSize = 28, text = "PLAY" } :: Card
HomeLayout.HUNT_WIDTH = 176 -- the Hunt Board button (its text is HuntBoard.BUTTON)
HomeLayout.HUNT_TEXT_SIZE = 16
HomeLayout.PROFILE_WIDTH = 150 -- the Profile button beside it (its text is ProfileScreen.BUTTON; PLAN T57)

-- Estimated advance per character, in em, for GothamBold.
local CAPS_EM = 0.75
local SPACE_EM = 0.3
local OTHER_EM = 0.6

function HomeLayout.textWidth(text: string, size: number): number
	local em = 0
	for _, code in utf8.codes(text) do
		if code == 32 then
			em += SPACE_EM
		elseif code >= 65 and code <= 90 then
			em += CAPS_EM
		else
			em += OTHER_EM
		end
	end
	return em * size
end

-- True when the card's text fits on one line inside its padding.
function HomeLayout.fits(card: Card): boolean
	return HomeLayout.textWidth(card.text, card.textSize) <= card.width - HomeLayout.CARD_PAD * 2
end

-- Width of a row of cards with the gap between them.
function HomeLayout.rowWidth(widths: { number }): number
	local total = 0
	for _, width in widths do
		total += width
	end
	return total + HomeLayout.GAP * math.max(#widths - 1, 0)
end

function HomeLayout.actionCards(): { Card }
	return { HomeLayout.HERO, HomeLayout.UNLOCKS, HomeLayout.PLAY }
end

-- A battle is on and this player isn't seated in it (joined mid-battle): the home screen
-- stays up with the waiting banner (PLAN T79b, DECISIONS #232). Building and Playing only:
-- the results and the Lobby change it (the banner closes on the hunt's end). Co-op never
-- waits: a co-op joiner drops straight in.
HomeLayout.WAITING_BANNER = "A hunt is on \u{2014} you'll join the next one."

function HomeLayout.waitingForNextHunt(state: unknown, battleMode: unknown, seatedSide: unknown): boolean
	return (state == "Building" or state == "Playing") and typeof(battleMode) == "string" and seatedSide == nil
end

------------------------------------------------------------------ battle options (PLAN T82)

--[[
	The battle rows under DIFFICULTY, shown only when Camp Clash or Bone Rush is picked
	(DECISIONS #217-#225, #229-#230, #233):
	  options row  Casual / Ranked, then Camp Clash's 2 / 3 camps, then (Studio only) "Fill
	               with stand-ins". The host's choices; everyone else sees them live.
	  Ranked row   every player's own Ready (#223), never the host's alone. Ready opens an
	               inline confirm in the same card ("Pay 15 Amber to enter?", DINO_REVIEW
	               Round 16) with an X beside it; pressing the card again pays (the server
	               takes the Entry fee when Building starts). Under it: the Entry fee and
	               your balance, then the Practice Hunt line or the refusal, then who's
	               ready against the minimum.
	The confirm lives in the home column, so it scales with it (fits any window), the home
	screen's Modal buttons keep the mouse free, its X and the Ready card close it, and the
	column hides on every state change (no-trap rule; `confirmOpen` is the rule).
]]

HomeLayout.BATTLE_HEADER = "BATTLE OPTIONS"
HomeLayout.OPTION_HEIGHT = 44
HomeLayout.OPTION_TEXT = 16
HomeLayout.CASUAL = { width = 120, textSize = 16, text = "Casual" } :: Card
HomeLayout.RANKED = { width = 120, textSize = 16, text = "Ranked" } :: Card
HomeLayout.SIDES = { -- Camp Clash's side count (Modes.TeamSides)
	{ width = 110, textSize = 16, text = "2 camps" } :: Card,
	{ width = 110, textSize = 16, text = "3 camps" } :: Card,
}
HomeLayout.STAND_INS = { width = 200, textSize = 16, text = "Fill with stand-ins" } :: Card
HomeLayout.READY_WIDTH = 240
HomeLayout.READY_TEXT = 16
HomeLayout.READY_X = 56 -- the confirm's X beside the Ready card
HomeLayout.READY_INFO = 400 -- the lines beside it (they wrap)

HomeLayout.READY = "Ready"
HomeLayout.READY_DONE = "Ready \u{2713}  (cancel)"
HomeLayout.RANKED_NORMAL = "Ranked is always Normal."
HomeLayout.PRACTICE_LINE = "Practice Hunt: session Amber only. Trophies won't change."
HomeLayout.HOARD_LINE = "Winners share the Hoard." -- DINO_REVIEW Round 16 (Amber Hoard)

-- The Ready refusal strings (PLAN T82 exact): Server/Main's "ReadyRefused" reason key.
local REFUSED = {
	offline = "Your save didn't load, so you can't pay the Entry fee. Casual is still open.",
	cantAfford = "You need {fee} {cur} for the Entry fee.",
	loading = "Your save is still loading. Try again in a moment.",
}
local REFUSED_OTHER = "You can't ready up right now."

function HomeLayout.refusalLine(reason: unknown, fee: number, currency: string): string?
	if reason == nil then
		return nil
	end
	local line = if type(reason) == "string" and REFUSED[reason] then REFUSED[reason] else REFUSED_OTHER
	return (string.gsub(string.gsub(line, "{fee}", tostring(fee)), "{cur}", currency))
end

-- The confirm card's text ("Pay 15 Amber to enter?").
function HomeLayout.confirmText(fee: number, currency: string): string
	return `Pay {fee} {currency} to enter?`
end

-- The Entry fee line under Ready.
function HomeLayout.feeLine(fee: number, have: number, currency: string): string
	return `Entry fee: {fee} {currency}  \u{b7}  You have {math.max(0, math.floor(have))} {currency}`
end

-- Is the picked mode a battle (the battle rows show)?
function HomeLayout.isBattle(modeKey: unknown): boolean
	local mode = if type(modeKey) == "string" then Modes.Modes[modeKey] else nil
	return mode ~= nil and mode.sides ~= "one"
end

-- Which host options show: Casual/Ranked for any battle, 2/3 camps for Camp Clash,
-- stand-ins only in Studio.
function HomeLayout.battleOptions(modeKey: unknown, studio: boolean): { queue: boolean, sides: boolean, standIns: boolean, seats: boolean }
	local battle = HomeLayout.isBattle(modeKey)
	return {
		queue = battle,
		sides = battle and Modes.Modes[modeKey :: string].sides == "choice",
		standIns = battle and studio,
		seats = battle and studio and Modes.Modes[modeKey :: string].sides == "perPlayer",
	}
end

-- The Ranked row (Ready, fee, who's ready) shows for a Ranked battle only.
function HomeLayout.readyRowVisible(modeKey: unknown, ranked: unknown): boolean
	return HomeLayout.isBattle(modeKey) and ranked == true
end

-- May the inline confirm stay open? Only on the home screen with the Ranked row up and
-- the player not yet Ready (Ready closes it, as does every state change).
function HomeLayout.confirmOpen(wanted: boolean, state: unknown, modeKey: unknown, ranked: unknown, ready: unknown): boolean
	return wanted and state == "Lobby" and HomeLayout.readyRowVisible(modeKey, ranked) and ready ~= true
end

-- Can the host press PLAY? The server's own seating rule (BattleFlow.seat): Ranked seats
-- the Ready hunters, casual everyone. Returns (ok, the fewest hunters it needs). Co-op
-- always can.
function HomeLayout.canPlay(modeKey: unknown, ranked: boolean, players: number, ready: number, picked: number?, standIns: boolean?): (boolean, number)
	if not HomeLayout.isBattle(modeKey) then
		return players >= 1, 1
	end
	local key = modeKey :: string
	local count = if ranked then ready else players
	local ids = {}
	for i = 1, count do
		ids[i] = i
	end
	local seating = BattleFlow.seat(key, ids, picked, standIns, ranked)
	local need = if standIns then 1 else Modes.minPlayers(key, ranked)
	if not standIns and Modes.Modes[key].sides == "choice" and picked then
		need = math.max(need, picked) -- 3 camps need 3 hunters
	end
	return seating ~= nil, need
end

-- The line under the battle rows: who's ready and the minimum (Ranked), or the minimum
-- alone (casual) when it isn't met.
function HomeLayout.readyLine(names: { string }, need: number): string
	if #names == 0 then
		return `Ready: nobody yet ({need} needed)`
	end
	return `Ready: {table.concat(names, ", ")} ({#names} of {need} needed)`
end

function HomeLayout.needLine(display: string, need: number): string
	return `{display} needs at least {need} hunter{if need == 1 then "" else "s"}.`
end

-- Studio stand-ins in Bone Rush: the seat count chip cycles 2..BattleMaxPlayers (T77's
-- "sides" request), so one client can test a lobby of stand-ins.
HomeLayout.SEATS = { width = 110, textSize = 16, text = "Seats: 10" } :: Card -- its widest text

function HomeLayout.seatsText(n: number): string
	return `Seats: {n}`
end

function HomeLayout.nextSeats(n: unknown): number
	local most = Config.Tuning.BattleMaxPlayers
	local current = if type(n) == "number" then math.floor(n) else 1
	return if current >= 2 and current < most then current + 1 else 2
end

function HomeLayout.optionCards(): { Card }
	return { HomeLayout.CASUAL, HomeLayout.RANKED, HomeLayout.SIDES[1], HomeLayout.SIDES[2], HomeLayout.STAND_INS }
end

return HomeLayout
