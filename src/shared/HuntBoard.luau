--[[
	What the Hunt Board screen shows (HuntBoard.client): the Daily Haul tiles, the bounty
	cards and their buttons, the countdown and notice lines, and how the board fits a
	window. Pure — no services, no clock — so tools/test/huntboard.spec.luau runs it
	headlessly. The rules themselves (what may be claimed or swapped) are Shared/Bounties
	and the server's; this only decides what to draw from the server's answer.

	Wording comes from Shared/Theme and the Bounties sheet (Title, Text); amounts from
	Config.Bounties and Config.DailyHaul. Sizes below are pixels: visuals only.

	  shown        is the board on screen (Shared/PanelRules: the home screen only)
	  countdown    "5h 12m", "3d 4h", "12m" — minutes rounded up, so it never reads 0m
	  resetLine    "New bounties in 5h 12m"
	  remaining    seconds left, `elapsed` seconds after the server said `seconds`
	  payoutLine   "Unclaimed bounties paid: +35 Amber", or nil when nothing was paid
	  haulNote     the line under the Daily Haul, or nil when missed days do reset it
	  card         one bounty card, or nil for a bounty this client doesn't know
	  cards        the cards of one pool, in board order
	  haul         the Daily Haul tiles, day 1 to the last
	  tileRects    where each Haul tile sits in a strip `width` wide: one row, or two
	               (4 + 3 for seven days) when the strip is narrow
	  stripHeight  the Haul strip's height, one row or two
	  fixedHeight  everything on the board except the scrolling bounty list
	  layout       scale, width and list height so the whole board — the X included —
	               fits between `top` and `bottom` of a window `viewportX` wide

	`inFlight` is what a request is in flight for: a bounty id, HAUL, or nil. While one
	is, every button is disabled and the one that was pressed reads "…".
]]

local Config = require(script.Parent.Config)
local PanelRules = require(script.Parent.PanelRules)
local Theme = require(script.Parent.Theme)

local Tuning = Config.Tuning

export type Entry = { id: string, progress: number, claimed: boolean }
export type Action = "none" | "claim" | "swap" | "wait"
export type Card = {
	id: string,
	title: string,
	text: string, -- the sheet's Text with {n} filled in
	chip: string, -- "+15"
	progress: string, -- "12 / 40"
	fraction: number, -- 0..1, for the bar
	state: "progress" | "done" | "claimed",
	species: string?, -- the species key of a pop bounty, for the colour dot
	action: Action,
	actionText: string,
	enabled: boolean,
}
export type Tile = {
	day: number,
	label: string, -- "Day 3", or Big Haul for the last day
	chip: string, -- "+10"
	state: "claimed" | "open" | "future", -- open = today's, waiting to be claimed
	today: boolean,
	big: boolean,
	action: Action,
	actionText: string,
	enabled: boolean,
}
export type Rect = { x: number, y: number, width: number, height: number }
export type Layout = { scale: number, width: number, wrap: boolean, listHeight: number, height: number }

local HuntBoard = {}

HuntBoard.MODE = "huntBoard" -- its Shared/PanelRules mode
HuntBoard.KEY = "G" -- toggles it (DECISIONS #70)
HuntBoard.HAUL = "haul" -- `inFlight` for the Daily Haul claim

HuntBoard.TITLE = string.upper(Theme.HuntBoard)
HuntBoard.BUTTON = `{Theme.HuntBoard} [{HuntBoard.KEY}]` -- the home-screen button
HuntBoard.CLAIM = "Claim"
HuntBoard.WAIT = "…"
HuntBoard.BAGGED = "BAGGED" -- the stamp on a claimed bounty
HuntBoard.UNREACHABLE = "Couldn't reach the server"

-- Pixels, before the board's scale.
HuntBoard.WIDTH = 560 -- on windows wide enough
HuntBoard.MIN_WIDTH = 300 -- narrower than this and the board scales down instead
HuntBoard.EDGE = 16 -- kept clear on each side of the window
HuntBoard.PAD = 12 -- inside the board's rim
HuntBoard.GAP = 6 -- between the board's sections, and between Haul tiles
HuntBoard.HEADER = 36 -- the title bar with the X
HuntBoard.LINE = 18 -- the countdown line; the note under the Haul
HuntBoard.SECTION = 20 -- a section title
HuntBoard.TILE = 62 -- a Haul tile's height
HuntBoard.MESSAGE = 20 -- the line at the bottom
HuntBoard.CARD = 76 -- a bounty card's height
HuntBoard.MIN_LIST = 100 -- the bounty list never shows less than a card and a title
HuntBoard.MIN_SCALE = 0.4 -- the home screen's own floor
HuntBoard.BIG_TILE = 1.5 -- Big Haul's width, in tiles
HuntBoard.WRAP_BELOW = 440 -- a Haul strip narrower than this wraps to two rows

-- Is the board on screen? `open` is what Shop.client's panel mode says.
function HuntBoard.shown(open: boolean, state: string?): boolean
	return open and PanelRules.allowed(HuntBoard.MODE, state, false)
end

-- Text -------------------------------------------------------------------------

local function grouped(n: number): string
	local digits = tostring(math.floor(n))
	local out = digits
	repeat
		local replaced
		out, replaced = string.gsub(out, "^(%d+)(%d%d%d)", "%1,%2")
	until replaced == 0
	return out
end

function HuntBoard.countdown(seconds: number): string
	local minutes = math.max(1, math.ceil(math.max(seconds, 0) / 60))
	local days = minutes // 1440
	local hours = minutes % 1440 // 60
	if days > 0 then
		return `{days}d {hours}h`
	elseif hours > 0 then
		return `{hours}h {minutes % 60}m`
	end
	return `{minutes}m`
end

function HuntBoard.resetLine(seconds: number): string
	return `New bounties in {HuntBoard.countdown(seconds)}`
end

function HuntBoard.remaining(seconds: number, elapsed: number): number
	return math.max(0, seconds - math.max(elapsed, 0))
end

function HuntBoard.payoutLine(amber: number?): string?
	if type(amber) ~= "number" or amber <= 0 then
		return nil
	end
	return `Unclaimed bounties paid: +{grouped(amber)} {Theme.Currency}`
end

function HuntBoard.haulNote(): string?
	if Tuning.HaulResetsAfterMissedDays > 0 then
		return nil
	end
	return "Missed days don't reset your Haul."
end

-- Bounty cards -----------------------------------------------------------------

function HuntBoard.card(entry: Entry, swapsLeft: number, inFlight: string?): Card?
	local def = (Config.Bounties :: any)[entry.id]
	if not def then
		return nil
	end
	local progress = math.clamp(entry.progress, 0, def.count)
	local done = progress >= def.count
	local state: "progress" | "done" | "claimed" = if entry.claimed then "claimed" elseif done then "done" else "progress"

	local action: Action, actionText = "none", ""
	if state == "done" then
		action, actionText = "claim", HuntBoard.CLAIM
	elseif state == "progress" and swapsLeft > 0 then
		action, actionText = "swap", `{Theme.Swap} ({swapsLeft} left)`
	end
	if action ~= "none" and inFlight == entry.id then
		action, actionText = "wait", HuntBoard.WAIT
	end

	return {
		id = entry.id,
		title = def.title,
		text = (string.gsub(def.text, "{n}", grouped(def.count))),
		chip = `+{grouped(def.amber)}`,
		progress = `{grouped(progress)} / {grouped(def.count)}`,
		fraction = if def.count > 0 then progress / def.count else 1,
		state = state,
		species = if def.event == "pop" and def.target ~= "" then def.target else nil,
		action = action,
		actionText = actionText,
		enabled = (action == "claim" or action == "swap") and inFlight == nil,
	}
end

function HuntBoard.cards(entries: { Entry }?, swapsLeft: number, inFlight: string?): { Card }
	local out = {}
	local all: { any } = entries or {}
	for _, entry in all do
		if type(entry) == "table" and type(entry.id) == "string" and type(entry.progress) == "number" then
			local card = HuntBoard.card(entry, swapsLeft, inFlight)
			if card then
				table.insert(out, card)
			end
		end
	end
	return out
end

-- Daily Haul -------------------------------------------------------------------

-- `haulDay`, `haulClaimed`: today's Haul day and whether it's been claimed
-- (Bounties.haulToday).
function HuntBoard.haul(haulDay: number, haulClaimed: boolean, inFlight: string?): { Tile }
	local days = #Config.DailyHaul
	local out = {}
	for day = 1, days do
		local today = day == haulDay
		local state: "claimed" | "open" | "future" = if day < haulDay or (today and haulClaimed)
			then "claimed"
			elseif today then "open"
			else "future"
		local action: Action, actionText = "none", ""
		if state == "open" then
			action, actionText = "claim", HuntBoard.CLAIM
			if inFlight == HuntBoard.HAUL then
				action, actionText = "wait", HuntBoard.WAIT
			end
		end
		out[day] = {
			day = day,
			label = if day == days then Theme.BigHaul else `Day {day}`,
			chip = `+{grouped(Config.DailyHaul[day].amber)}`,
			state = state,
			today = today,
			big = day == days,
			action = action,
			actionText = actionText,
			enabled = action == "claim" and inFlight == nil,
		}
	end
	return out
end

-- Layout -----------------------------------------------------------------------

local function haulRows(wrap: boolean): { { number } }
	local days = #Config.DailyHaul
	local first = if wrap then math.ceil(days / 2) else days
	local rows: { { number } } = { {} }
	for day = 1, days do
		if day > first and #rows == 1 then
			table.insert(rows, {})
		end
		table.insert(rows[#rows], day)
	end
	return rows
end

local function wraps(width: number): boolean
	return width - HuntBoard.PAD * 2 < HuntBoard.WRAP_BELOW and #Config.DailyHaul > 1
end

-- `width` = the strip's width (the board's, less its padding).
function HuntBoard.tileRects(width: number): { Rect }
	local days = #Config.DailyHaul
	local gap = HuntBoard.GAP
	local out = {}
	for index, row in haulRows(width < HuntBoard.WRAP_BELOW and days > 1) do
		local units = 0
		for _, day in row do
			units += if day == days then HuntBoard.BIG_TILE else 1
		end
		local unit = math.max(0, width - gap * (#row - 1)) / units
		local x = 0
		for _, day in row do
			local w = unit * (if day == days then HuntBoard.BIG_TILE else 1)
			out[day] = { x = x, y = (index - 1) * (HuntBoard.TILE + gap), width = w, height = HuntBoard.TILE }
			x += w + gap
		end
	end
	return out
end

function HuntBoard.stripHeight(wrap: boolean): number
	local rows = #haulRows(wrap)
	return rows * HuntBoard.TILE + (rows - 1) * HuntBoard.GAP
end

-- The board's height without the bounty list: header, countdown, Haul title, Haul
-- strip, Haul note, message, the gaps between those and the list, and the padding.
function HuntBoard.fixedHeight(wrap: boolean): number
	return HuntBoard.PAD * 2
		+ HuntBoard.HEADER
		+ HuntBoard.LINE
		+ HuntBoard.SECTION
		+ HuntBoard.stripHeight(wrap)
		+ HuntBoard.LINE
		+ HuntBoard.MESSAGE
		+ HuntBoard.GAP * 6
end

-- Fit the board between `top` and `bottom` (screen pixels; the home screen's Play row
-- sits below `bottom`) in a window `viewportX` wide. `listContent` = the bounty list's
-- full height. The list gives way first (it scrolls); if even MIN_LIST of it doesn't
-- fit, the whole board scales down. `scale * height <= bottom - top` unless the window
-- is smaller than MIN_SCALE can serve.
function HuntBoard.layout(viewportX: number, top: number, bottom: number, listContent: number): Layout
	local availX = math.max(1, viewportX - HuntBoard.EDGE * 2)
	local availY = math.max(1, bottom - top)
	local scale = math.clamp(availX / HuntBoard.MIN_WIDTH, HuntBoard.MIN_SCALE, 1)
	local width, wrap, fixed = 0, false, 0
	for _ = 1, 2 do
		width = math.min(HuntBoard.WIDTH, availX / scale)
		wrap = wraps(width)
		fixed = HuntBoard.fixedHeight(wrap)
		local need = fixed + math.min(listContent, HuntBoard.MIN_LIST)
		local fits = math.clamp(availY / need, HuntBoard.MIN_SCALE, 1)
		if fits >= scale then
			break
		end
		scale = fits -- a smaller scale only widens the board, so this pass settles it
	end
	local listHeight = math.clamp(availY / scale - fixed, 0, math.max(listContent, 0))
	return {
		scale = scale,
		width = math.floor(width),
		wrap = wrap,
		listHeight = math.floor(listHeight),
		height = fixed + math.floor(listHeight),
	}
end

return HuntBoard
