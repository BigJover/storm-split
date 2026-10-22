--!strict
--[[
	The Ranger Station's posts UI (PLAN 9j T130): "Move posts" in the tower panel, and right
	after a station is placed. Pure, so the specs can check it; Shop.client draws it,
	Server/Shop + Server/Towers validate every post (Shared/Ranger.checkPost).

	  rows(n, setting, set)  one row per post (tap one to move it) and Done
	  hint(...)              the message line: what a click does, or why the spot is refused
	  advance(setting, n)    the post to set next after one is set (nil = all set: back)
	  movable(...)           whether the panel offers "Move posts" (not on a jeep or bodyguards)
	  layout(x, y, rows)     the panel on a window: width, scroll height, its top

	No-trap rule (DIRECTION): the panel is the tower panel in its own mode: Back and X sit in
	the header outside the scroll (OptionPick.header), the rows scroll, Q stops too, and the
	mode closes on every match-state change Shared/PanelRules doesn't allow ("posts" is
	allowed exactly where placing is).
]]

local OptionPick = require(script.Parent.OptionPick)

local RangerPosts = {}

RangerPosts.MODE = "posts"
RangerPosts.ROW = 48 -- px: one row (Shop.client's addRow)
RangerPosts.ROW_GAP = 6 -- px between rows (the list's padding)
RangerPosts.DONE = "Done"

export type Row = { text: string, current: boolean }

-- One row per post plus Done. `setting`: the post a click sets now; `set[k]`: post k has a
-- spot (the server's).
function RangerPosts.rows(n: number, setting: number, set: { [number]: boolean }): { Row }
	local out: { Row } = {}
	for k = 1, n do
		local state = if k == setting then "click the track to place it" elseif set[k] then "placed  ·  tap to move" else "not placed"
		table.insert(out, { text = `Post {k} of {n}  ·  {state}`, current = k == setting })
	end
	table.insert(out, { text = RangerPosts.DONE, current = false })
	return out
end

-- The message line under the rows.
function RangerPosts.hint(setting: number, fits: boolean, reason: string?): string
	if fits then
		return `Click or tap the track for post {setting}  ·  Q to stop`
	end
	return reason or "Posts go on the track"
end

-- After post `setting` is set: the next one, or nil when every post has been set once.
function RangerPosts.advance(setting: number, n: number): number?
	if setting < n then
		return setting + 1
	end
	return nil
end

-- Does the tower panel offer "Move posts"? A Ranger Station with posts whose rangers use
-- them (not Patrol Jeep, not Bodyguards), on your own camp, not Trampled.
function RangerPosts.movable(key: string?, postCount: number, usesPosts: boolean, ownCamp: boolean, trampled: boolean): boolean
	return key == "RANGER" and postCount > 0 and usesPosts and ownCamp and not trampled
end

export type Layout = { width: number, listHeight: number, height: number, top: number }

-- The posts panel on a `viewportX` × `viewportY` window with `rows` rows: the tower panel's
-- width, its scroll box capped like every panel (OptionPick.listHeight), header (Back + X)
-- and message never scroll.
function RangerPosts.layout(viewportX: number, viewportY: number, rows: number, buildHud: boolean?): Layout
	local content = rows * RangerPosts.ROW + math.max(0, rows - 1) * RangerPosts.ROW_GAP
	local listHeight = OptionPick.listHeight(viewportY, content, buildHud, viewportX)
	return {
		width = math.min(OptionPick.WIDTH, viewportX - OptionPick.EDGE * 2),
		listHeight = listHeight,
		height = OptionPick.CHROME + listHeight,
		top = OptionPick.top(viewportY, buildHud, viewportX),
	}
end

return RangerPosts
