--[[
	The A/B/C pick (PLAN T112, DECISIONS #279): what the tower panel and the hero U panel
	show when a path's next step is tier 4 or 5. Pure, so the specs can check it.

	  opens(nextTier)       a tier-4/5 step opens the pick instead of buying at once
	  cards(path, ...)      one card per option with a Config row: letter, name, Blurb
	  initial(cards)        the card chosen when the pick opens (the only one, if one)
	  confirm(...)          the confirm button: "Buy B — 2,400", greyed with a reason
	  stays(pick, now)      whether an open pick survives what just changed
	  layout(x, y, n)       panel width, scale, card size and list height on a window

	No-trap rule (DIRECTION): Back and X sit in the header outside the scroll and the
	confirm button under it, so all three are on screen on every window; the cards scroll
	first, then the whole panel scales; below STACK_BELOW the cards stack vertically.
	The price is shown once, on the confirm button (every option at a tier costs the
	same, #277).
]]

local Upgrades = require(script.Parent.Upgrades)

local OptionPick = {}

export type Card = { letter: string, name: string, blurb: string }
export type Pick = {
	owner: string, -- the tower id or hero key the pick was opened for
	pathIndex: number,
	tier: number, -- the path's tier when the pick opened
	picks: string, -- the path's letters when the pick opened
	chosen: string?, -- the tapped card
}
export type Now = { owner: string, tier: number, picks: string, blocked: boolean }
export type Layout = {
	width: number, -- the panel's width before its scale
	scale: number,
	stacked: boolean,
	cardWidth: number,
	cardHeight: number,
	content: number, -- the cards' full height
	listHeight: number, -- the scrolling box's height (content when it all fits)
	height: number, -- the whole panel's height before its scale
}

-- Pixels, before the panel's scale. They match Shop.client's panel.
OptionPick.WIDTH = 400 -- the panel on windows wide enough
OptionPick.EDGE = 16 -- kept clear on each side of the window
OptionPick.PAD = 12 -- inside the panel's rim
OptionPick.GAP = 8 -- between the header, the cards, the confirm button and the message
OptionPick.HEADER = 28 -- the title, Back and X
OptionPick.CONFIRM = 44
OptionPick.MESSAGE = 20
OptionPick.CARD_GAP = 6
OptionPick.CARD_TALL = 132 -- a card in a row of three: name and a wrapped Blurb
OptionPick.CARD_FLAT = 64 -- a stacked card, full width
OptionPick.STACK_BELOW = 108 -- a card narrower than this in a row: stack them instead
OptionPick.BOTTOM = 24 -- the panel sits this far above the window's bottom
OptionPick.TOP = 44 -- Roblox's top bar
OptionPick.LIST_MAX_SCREEN = 0.55 -- the scroll box never takes more of the window than this
OptionPick.MIN_SCALE = 0.4
OptionPick.CLOSE_W = 28 -- the X, at the header's right edge
OptionPick.BACK_W = 60 -- Back, left of the X
OptionPick.HEADER_GAP = 6 -- clear space between the title, Back and the X
OptionPick.TITLE_MAX = 18 -- the title's text size, shrunk to fit (never below TITLE_MIN,
OptionPick.TITLE_MIN = 11 -- then cut with "…")

-- The header's title box ends before Back and the X (Run 8 F9: it ran under Back).
-- Offsets from the header's right edge; `titleRight` is the title's (negative) width offset.
function OptionPick.header(picking: boolean): { titleRight: number, backRight: number, closeRight: number }
	local backRight = OptionPick.CLOSE_W + OptionPick.HEADER_GAP
	local titleRight = if picking
		then backRight + OptionPick.BACK_W + OptionPick.HEADER_GAP
		else OptionPick.CLOSE_W + OptionPick.HEADER_GAP
	return { titleRight = -titleRight, backRight = -backRight, closeRight = 0 }
end

OptionPick.BACK = "Back"
OptionPick.CHOOSE = "Tap a card"

local function grouped(n: number): string
	local text = tostring(math.floor(n))
	local out = text
	repeat
		local changed
		out, changed = string.gsub(out, "^(-?%d+)(%d%d%d)", "%1,%2")
	until changed == 0
	return out
end
OptionPick.grouped = grouped

-- A tier-4 or tier-5 step opens the pick; every other step buys at once.
function OptionPick.opens(nextTier: number): boolean
	return nextTier == 4 or nextTier == 5
end

-- The cards for a path's step up to `nextTier` after `picks`: one per option with a
-- Config row, A, B, C in order. Only option A exists until batch 9c, so one card.
function OptionPick.cards(path, nextTier: number, picks: string): { Card }
	local out = {}
	for _, letter in Upgrades.options(path, nextTier, picks) do
		local row = Upgrades.row(path, nextTier, picks .. letter)
		table.insert(out, {
			letter = letter,
			name = tostring(row.name or path.id),
			blurb = tostring(row.blurb or ""),
		})
	end
	return out
end

-- The card chosen as the pick opens: the only one when there's one (you still confirm),
-- none when there's a choice to make.
function OptionPick.initial(cards: { Card }): string?
	return if #cards == 1 then cards[1].letter else nil
end

-- The confirm button: its text and whether it can be pressed. `cost` is after discounts;
-- `free` is the hero mastery free upgrade. Can't-afford shows the price it needs.
function OptionPick.confirm(chosen: string?, cost: number, cash: number, free: boolean?): (string, boolean)
	local price = if free then "FREE" else grouped(cost)
	if chosen == nil then
		return `{OptionPick.CHOOSE}  ·  {price}`, false
	end
	if not free and cash < cost then
		return `Need {price} cash for {chosen}`, false
	end
	return `Buy {chosen} — {price}`, true
end

-- The path row's second line before the pick opens: the options' names ("one of: ...").
function OptionPick.rowLine(cards: { Card }): string
	local names = {}
	for _, card in cards do
		table.insert(names, `{card.letter} {card.name}`)
	end
	if #names == 1 then
		return names[1]
	end
	return `one of: {table.concat(names, " / ")}`
end

-- The tower's tier label (#279): the picked path's letters ("4B · 5A") once it has any,
-- else every path's tier ("2 · 1 · 0"). Only one path can pass tier 3 (crossover).
function OptionPick.tierLabel(tiers: { number }, picks: { string }?): string
	for i = 1, 3 do
		local letters = if picks then picks[i] or "" else ""
		if letters ~= "" then
			local parts = {}
			for i = 1, #letters do
				table.insert(parts, `{i + 3}{string.sub(letters, i, i)}`)
			end
			return table.concat(parts, " · ")
		end
	end
	return `{tiers[1]} · {tiers[2]} · {tiers[3]}`
end

-- Does an open pick survive what just changed? It closes on every change to its path
-- (a tier or letter bought, by you or a teammate), a different tower or hero, or the
-- path getting blocked (trampled, crossover, maxed). Cash changes keep it open.
function OptionPick.stays(pick: Pick?, now: Now): boolean
	return pick ~= nil
		and not now.blocked
		and now.owner == pick.owner
		and now.tier == pick.tier
		and now.picks == pick.picks
end

-- Fit the pick on a `viewportX` × `viewportY` window with `count` cards. Like the Hunt
-- Board (#87): the cards scroll first, down to one card's height, then the whole panel
-- scales (never below MIN_SCALE). Header, confirm and message never scroll.
function OptionPick.layout(viewportX: number, viewportY: number, count: number): Layout
	local fixed = OptionPick.PAD * 2 + OptionPick.HEADER + OptionPick.CONFIRM + OptionPick.MESSAGE + OptionPick.GAP * 3
	local availX = math.max(viewportX - OptionPick.EDGE * 2, 1)
	local availY = math.max(viewportY - OptionPick.TOP - OptionPick.BOTTOM, 1)
	local n = math.max(count, 1)

	local function shape(width: number)
		local inner = width - OptionPick.PAD * 2
		local across = (inner - OptionPick.CARD_GAP * (n - 1)) / n
		local stacked = n > 1 and across < OptionPick.STACK_BELOW
		local cardWidth = if stacked then inner elseif n == 1 then inner else across
		local cardHeight = if stacked or n == 1 then OptionPick.CARD_FLAT else OptionPick.CARD_TALL
		local content = if stacked then n * cardHeight + (n - 1) * OptionPick.CARD_GAP else cardHeight
		return stacked, cardWidth, cardHeight, content
	end

	local scale = 1
	local width = math.min(OptionPick.WIDTH, availX)
	local stacked, cardWidth, cardHeight, content = shape(width)
	local cap = math.floor(viewportY * OptionPick.LIST_MAX_SCREEN)
	local listHeight = math.min(content, cap, availY - fixed)
	local least = math.min(content, cardHeight) -- at least one card shows
	if listHeight < least then
		scale = math.clamp(availY / (fixed + least), OptionPick.MIN_SCALE, 1)
		width = math.min(OptionPick.WIDTH, availX / scale)
		stacked, cardWidth, cardHeight, content = shape(width)
		listHeight = math.clamp(availY / scale - fixed, math.min(content, cardHeight), content)
	end
	return {
		width = width,
		scale = scale,
		stacked = stacked,
		cardWidth = cardWidth,
		cardHeight = cardHeight,
		content = content,
		listHeight = math.max(listHeight, 0),
		height = fixed + math.max(listHeight, 0),
	}
end

return OptionPick
