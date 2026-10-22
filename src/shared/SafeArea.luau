--[[
	Where a player can click (PLAYTEST Run 13 F13). Pure, so it's tested headlessly
	(tools/test/safearea.spec.luau).

	Roblox's CoreGui owns the top of the screen: the top bar (58 px in the current UI,
	`GuiService:GetGuiInset()`), and under it a band the Tester measured at y ≈ 58–140
	where every click "hits CoreGUI" (the chat window and Studio's test overlay sit there).
	A button there can't be pressed, so "Hide menu" and the top halves of the Training and
	Hatchery Hut X were dead. The rule: **every interactive control's top sits at or below
	`SafeArea.top(inset)`** (150 px from the top of the screen on today's top bar).
	Labels may still use the band (the status line, XP rows): nothing there takes a click.

	Coordinates: `top` is measured from the very top of the screen, as a ScreenGui with
	`IgnoreGuiInset = true` sees it; `localTop` is the same line for a ScreenGui that starts
	under the top bar (`IgnoreGuiInset = false`, the default).
]]

local SafeArea = {}

SafeArea.TOP_BAR = 58 -- Roblox's top bar, used when GetGuiInset reports less (or nothing yet)
SafeArea.CORE_BAND = 82 -- the CoreGui band under it that eats clicks (Run 13: y 58–140)
SafeArea.GAP = 10 -- clear space under that band
SafeArea.TOP = SafeArea.TOP_BAR + SafeArea.CORE_BAND + SafeArea.GAP -- 150 on today's top bar

-- The first clickable row, from the top of the screen, for a top bar `insetY` px tall.
function SafeArea.top(insetY: number?): number
	return math.max(insetY or 0, SafeArea.TOP_BAR) + SafeArea.CORE_BAND + SafeArea.GAP
end

-- The same row for a ScreenGui that starts under the top bar (IgnoreGuiInset = false).
function SafeArea.localTop(insetY: number?): number
	return SafeArea.top(insetY) - (insetY or 0)
end

-- Can a control whose top edge is at screen y `y` be clicked all the way up? (Right of
-- the chat window; left of it, use `clickableAt`.)
function SafeArea.clickable(y: number, insetY: number?): boolean
	return y >= SafeArea.top(insetY)
end

-- The band a panel may use on a `viewportY`-tall screen: from the safe top down to
-- `margin` px above the bottom. Screen coordinates. Never upside down on a tiny window.
function SafeArea.band(viewportY: number, insetY: number?, margin: number?): (number, number)
	local top = SafeArea.top(insetY)
	return top, math.max(top + 1, viewportY - (margin or 0))
end

-- Scale for something `contentY` px tall to fit that band (clamped to [minScale, maxScale]).
function SafeArea.fitScale(contentY: number, viewportY: number, insetY: number?, margin: number?, minScale: number?, maxScale: number?): number
	local top, bottom = SafeArea.band(viewportY, insetY, margin)
	return math.clamp((bottom - top) / math.max(contentY, 1), minScale or 0.4, maxScale or 1)
end

-- Y offset for a frame anchored at its middle (AnchorPoint.Y 0.5, Position.Y.Scale 0.5,
-- in a ScreenGui with IgnoreGuiInset = true) that centres it in that band instead.
function SafeArea.centerOffset(viewportY: number, insetY: number?, margin: number?): number
	local top, bottom = SafeArea.band(viewportY, insetY, margin)
	return math.floor((top + bottom) / 2 - viewportY / 2)
end

--[[
	The chat window (PLAYTEST Run 14 F13b). Roblox's chat window sits top left under the
	top bar and eats every click on it even when it looks empty: the Tester read
	`TextChatService.ChatWindowConfiguration` at (8, 12) 283×141 under a 58 px top bar =
	screen x 8–291, y 70–211. So a control whose left edge is left of `chat.right` must
	start at or below `chatTop` (the box's bottom + GAP); one further right only needs the
	usual safe line. The default box is that window plus CHAT_MARGIN; when the live
	configuration is readable its box is added (the bigger of the two wins, so a moved or
	resized window is covered and an unreadable one still is).

	The chat input bar (PLAYTEST Run 15 F13c) sits right under that window and eats clicks
	too: `ChatInputBarConfiguration` read screen y 210–258 under a 58 px bar (152–200 under
	it), so the Menu/Hide toggle's top half was dead. The box covers the window and the
	input bar together; live, both configurations are read and joined.
]]
SafeArea.CHAT_MARGIN = 9
SafeArea.CHAT_RIGHT = 300 -- screen x: 8 + 283 + margin
SafeArea.CHAT_BELOW_BAR = 209 -- px under the top bar: input bar bottom 200 + margin (screen y 267 on 58)

export type ChatRect = { x: number, y: number, w: number, h: number } -- under the top bar

-- One configuration's box (ChatWindowConfiguration / ChatInputBarConfiguration), or nil.
local function readRect(service: any, name: string): ChatRect?
	local okRead, rect = pcall(function()
		local config = service[name]
		if config == nil or config.Enabled == false then
			return nil
		end
		local pos, size = config.AbsolutePosition, config.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then
			return nil
		end
		return { x = pos.X, y = pos.Y, w = size.X, h = size.Y }
	end)
	return if okRead then rect else nil
end

-- The live chat window and input bar from a TextChatService, joined into one box (or nil
-- when neither can be read). Never errors.
function SafeArea.liveChat(service: any): ChatRect?
	if service == nil then
		return nil
	end
	local window, input = readRect(service, "ChatWindowConfiguration"), readRect(service, "ChatInputBarConfiguration")
	if window == nil or input == nil then
		return window or input
	end
	local x, y = math.min(window.x, input.x), math.min(window.y, input.y)
	local x2 = math.max(window.x + window.w, input.x + input.w)
	local y2 = math.max(window.y + window.h, input.y + input.h)
	return { x = x, y = y, w = x2 - x, h = y2 - y }
end

-- The chat box's right edge and bottom, screen coordinates (margin included).
function SafeArea.chatBox(insetY: number?, live: ChatRect?): (number, number)
	local bar = math.max(insetY or 0, SafeArea.TOP_BAR)
	local right, bottom = SafeArea.CHAT_RIGHT, bar + SafeArea.CHAT_BELOW_BAR
	if live then
		right = math.max(right, live.x + live.w + SafeArea.CHAT_MARGIN)
		bottom = math.max(bottom, (insetY or 0) + live.y + live.h + SafeArea.CHAT_MARGIN)
	end
	return right, bottom
end

-- The first clickable row under the chat box (screen): 277 on today's top bar.
function SafeArea.chatTop(insetY: number?, live: ChatRect?): number
	local _, bottom = SafeArea.chatBox(insetY, live)
	return math.max(SafeArea.top(insetY), bottom + SafeArea.GAP)
end

-- The first clickable row (screen) for a control or panel whose left edge is at screen x
-- `left`: under the chat box when it starts left of the box's right edge, else the safe line.
function SafeArea.topFor(left: number, insetY: number?, live: ChatRect?): number
	local right = SafeArea.chatBox(insetY, live)
	return if left < right then SafeArea.chatTop(insetY, live) else SafeArea.top(insetY)
end

-- Can a control at screen (x, y) be clicked all the way: under the CoreGui band, and
-- either right of the chat box or under it.
function SafeArea.clickableAt(x: number, y: number, insetY: number?, live: ChatRect?): boolean
	local right, bottom = SafeArea.chatBox(insetY, live)
	return y >= SafeArea.top(insetY) and (x >= right or y >= bottom)
end

-- Centre x (screen) for a `w`-wide button at the top centre of a `viewportX` window: the
-- middle, or pushed right just clear of the chat box when the middle would put its left
-- edge in it (never past the window's right edge minus 8).
function SafeArea.centreX(viewportX: number, w: number, insetY: number?, live: ChatRect?): number
	local right = SafeArea.chatBox(insetY, live)
	local mid = viewportX / 2
	if mid - w / 2 >= right then
		return mid
	end
	return math.max(mid, math.min(right + SafeArea.GAP + w / 2, viewportX - 8 - w / 2))
end

-- The build-phase buttons top centre (Hud.client's Start; Shop.client's Choose hero and
-- Unlocks & Mastery), screen coordinates, top edges and the lowest bottom. Start sits on
-- the safe line; the other two keep their old spacing under it (PLAYTEST N20). Their x is
-- `centreX` (Run 14 F13b): clear of the chat window on windows ≥ ~540 px wide; narrower
-- (phone-sized) ones keep the stack where N20 needs it and only its right part clears.
SafeArea.START_H = 44
SafeArea.HERO_H = 44
SafeArea.MASTERY_H = 40
SafeArea.HUD_W = 220 -- Start / Choose hero / Unlocks & Mastery width
function SafeArea.buildHud(insetY: number?): { start: number, hero: number, mastery: number, bottom: number }
	local start = SafeArea.top(insetY)
	local hero = start + 96
	local mastery = start + 146
	return { start = start, hero = hero, mastery = mastery, bottom = mastery + SafeArea.MASTERY_H }
end

return SafeArea
