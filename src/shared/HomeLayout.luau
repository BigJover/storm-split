--!strict
--[[
	The home screen's two bottom rows (DECISIONS #138): the Hunt Board on its own row,
	and under it the action row Choose hero 200 · Unlocks & Mastery 240 · PLAY 240 (28 px
	text). Sizes are visual only. The pure rules here let a spec check that both rows fit
	the 740 px column with no wrapped button text; the column scales as a whole on small
	windows (Home.client's UIScale), so fitting at 740 means fitting at every window.

	Text widths are estimates (GothamBold average advances), not measurements.
]]

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

return HomeLayout
