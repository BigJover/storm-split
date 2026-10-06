--[[
	What the Profile screen shows (Profile.client, PLAN round 4 T57): the player level, the
	XP bar, the next rewards and an equip row per slot. Pure — no services — so
	tools/test/profilescreen.spec.luau runs it headlessly. What may be worn is
	Shared/Cosmetics' rule and the server's call; this only decides what to draw.

	No-trap rules (DIRECTION): `layout` fits the screen between the top bar and the home
	screen's Hunt Board row on any window — the list scrolls first, then the whole screen
	scales down; the header and its X are outside the list. Open and close with KEY, the
	home screen's button or the X; Shared/PanelRules closes it on every state change.

	Wording is working wording until the Dino review (T59). Sizes are pixels: visuals only.
]]

local PanelRules = require(script.Parent.PanelRules)
local PlayerLevel = require(script.Parent.PlayerLevel)
local Cosmetics = require(script.Parent.Cosmetics)
local Theme = require(script.Parent.Theme)

local ProfileScreen = {}

ProfileScreen.MODE = "profile" -- its Shared/PanelRules mode
ProfileScreen.KEY = "P" -- toggles it (working key, PLAN T57)
ProfileScreen.TITLE = string.upper(Theme.Profile)
ProfileScreen.BUTTON = `{Theme.Profile}  ({ProfileScreen.KEY})` -- like "Hunt Board  (G)"
ProfileScreen.NONE = "None" -- the chip that takes a slot's item off
ProfileScreen.NEXT = "Next rewards"
ProfileScreen.WEAR = "Wear"
ProfileScreen.UPCOMING = 3 -- reward levels listed under "Next rewards"

ProfileScreen.WIDTH = 560
ProfileScreen.MIN_WIDTH = 300
ProfileScreen.EDGE = 16
ProfileScreen.PAD = 12
ProfileScreen.GAP = 6
ProfileScreen.HEADER = 36
ProfileScreen.LEVEL = 54 -- the level line, the bar and its XP line
ProfileScreen.MESSAGE = 20
ProfileScreen.SECTION = 20
ProfileScreen.REWARD = 20 -- one "Next rewards" line
ProfileScreen.SLOT = 58 -- a slot's label and its row of chips
ProfileScreen.MIN_LIST = 100
ProfileScreen.MIN_SCALE = 0.4

-- Is the screen up? `open` is what Shop.client's panel mode says.
function ProfileScreen.shown(open: boolean, state: string?): boolean
	return open and PanelRules.allowed(ProfileScreen.MODE, state, false)
end

local function grouped(n: number): string
	local out = tostring(math.floor(n))
	repeat
		local replaced
		out, replaced = string.gsub(out, "^(%d+)(%d%d%d)", "%1,%2")
	until replaced == 0
	return out
end
ProfileScreen.grouped = grouped

-- "Player level 12". Never "Lv N" (DECISIONS #118).
function ProfileScreen.levelLine(xp: number?): string
	return `{Theme.PlayerLevel} {PlayerLevel.level(xp or 0)}`
end

-- "340 / 1,050 XP to level 13", and how full the bar is (0..1).
function ProfileScreen.xpLine(xp: number?): (string, number)
	local into, cost, level = PlayerLevel.progress(xp or 0)
	return `{grouped(into)} / {grouped(cost)} XP to level {level + 1}`, if cost > 0 then into / cost else 0
end

-- One reward level: "Level 10 · Bush Hat (Hunting hat) · title Greenhorn".
function ProfileScreen.rewardLine(level: number, items: { Cosmetics.Item }): string
	local parts = { `Level {level}` }
	for _, item in items do
		if item.kind == "title" then
			table.insert(parts, `title {item.name}`)
		else
			table.insert(parts, `{item.name} ({Cosmetics.LABELS[item.kind]})`)
		end
	end
	return table.concat(parts, " · ")
end

function ProfileScreen.upcoming(xp: number?): { string }
	local out = {}
	for _, entry in Cosmetics.upcoming(PlayerLevel.level(xp or 0), ProfileScreen.UPCOMING) do
		table.insert(out, ProfileScreen.rewardLine(entry.level, entry.items))
	end
	return out
end

export type Chip = { id: string, text: string, selected: boolean }
export type SlotRow = { slot: string, label: string, chips: { Chip }, locked: string? }

-- One row per slot: "None" and every unlocked item, the worn one selected; a slot with
-- nothing unlocked yet says when it unlocks instead.
function ProfileScreen.slotRows(xp: number?, equipped: { [string]: string? }): { SlotRow }
	local level = PlayerLevel.level(xp or 0)
	local rows = {}
	for _, slot in Cosmetics.SLOTS do
		local items = Cosmetics.itemsFor(slot, level)
		local worn = equipped[slot]
		local row: SlotRow = { slot = slot, label = Cosmetics.LABELS[slot], chips = {}, locked = nil }
		if #items == 0 then
			local first = Cosmetics.firstLevel(slot)
			row.locked = if first then `Unlocks at {string.lower(Theme.PlayerLevel)} {first}` else nil
		else
			table.insert(row.chips, { id = "", text = ProfileScreen.NONE, selected = worn == nil })
			for _, item in items do
				table.insert(row.chips, { id = item.id, text = item.name, selected = worn == item.id })
			end
		end
		table.insert(rows, row)
	end
	return rows
end

-- Everything but the scrolling list: header, level block, message, gaps and padding.
function ProfileScreen.fixedHeight(): number
	return ProfileScreen.PAD * 2 + ProfileScreen.HEADER + ProfileScreen.LEVEL + ProfileScreen.MESSAGE + ProfileScreen.GAP * 3
end

-- The list's full height for `rewardLines` next-reward lines and `slots` slot rows
-- (two section titles).
function ProfileScreen.listContent(rewardLines: number, slots: number): number
	local heights = ProfileScreen.SECTION * 2 + ProfileScreen.REWARD * rewardLines + ProfileScreen.SLOT * slots
	local count = 2 + rewardLines + slots
	return heights + ProfileScreen.GAP * math.max(count - 1, 0)
end

export type Layout = { scale: number, width: number, listHeight: number, height: number }

-- Fit between `top` and `bottom` (screen pixels) in a window `viewportX` wide; the same
-- rule as the Hunt Board: the list gives way first, then the whole screen scales down.
function ProfileScreen.layout(viewportX: number, top: number, bottom: number, listContent: number): Layout
	local availX = math.max(1, viewportX - ProfileScreen.EDGE * 2)
	local availY = math.max(1, bottom - top)
	local scale = math.clamp(availX / ProfileScreen.MIN_WIDTH, ProfileScreen.MIN_SCALE, 1)
	local fixed = ProfileScreen.fixedHeight()
	local need = fixed + math.min(listContent, ProfileScreen.MIN_LIST)
	scale = math.min(scale, math.clamp(availY / need, ProfileScreen.MIN_SCALE, 1))
	local width = math.min(ProfileScreen.WIDTH, availX / scale)
	local listHeight = math.clamp(availY / scale - fixed, 0, math.max(listContent, 0))
	return {
		scale = scale,
		width = math.floor(width),
		listHeight = math.floor(listHeight),
		height = fixed + math.floor(listHeight),
	}
end

return ProfileScreen
