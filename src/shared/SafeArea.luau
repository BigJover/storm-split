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

-- Can a control whose top edge is at screen y `y` be clicked all the way up?
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

-- The build-phase buttons top centre (Hud.client's Start; Shop.client's Choose hero and
-- Unlocks & Mastery), screen coordinates, top edges and the lowest bottom. Start sits on
-- the safe line; the other two keep their old spacing under it (PLAYTEST N20).
SafeArea.START_H = 44
SafeArea.HERO_H = 44
SafeArea.MASTERY_H = 40
function SafeArea.buildHud(insetY: number?): { start: number, hero: number, mastery: number, bottom: number }
	local start = SafeArea.top(insetY)
	local hero = start + 96
	local mastery = start + 146
	return { start = start, hero = hero, mastery = mastery, bottom = mastery + SafeArea.MASTERY_H }
end

return SafeArea
