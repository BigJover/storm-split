--[[
	Which shop panel may be open in which match state (Shop.client). Pure, so
	it's tested headlessly (tools/test/panelrules.spec.luau).

	  list, placing, manage, heroUpgrade   in a match only (Building, Playing)
	  heroPick                             before the round starts (Lobby,
	                                       Building), or any time without a hero
	  mastery                              before the round starts (Lobby, Building)
	  huntBoard                            on the home screen only (Lobby); it's
	                                       HuntBoard.client's screen, but Shop.client
	                                       still owns which panel is open
	  profile                              on the home screen only (Lobby); the
	                                       Profile screen (Profile.client, PLAN T57),
	                                       owned the same way as the Hunt Board

	A spectator (their battle camp is out, PLAN T83) can't open build, hero, upgrade or
	mastery panels; the read-only tower panel (Inspect) stays.

	When the state changes, a panel only survives the step from Building into
	Playing, and only if it's still allowed there. Every other change closes
	it: pressing Play on the home screen, the results screen, going home.

	Also the tower panel's level line (DECISIONS #112), so its wording and its
	percent are tested too, and the hero upgrade panel's tier ladder (six tiers
	since PLAN T53): one line per path, so the panel's height doesn't grow with
	the tier count and the X stays on screen (no-trap rule).
]]

local BattleFlow = require(script.Parent.BattleFlow)
local HomeLayout = require(script.Parent.HomeLayout)
local Modes = require(script.Parent.Modes)
local Theme = require(script.Parent.Theme)
local TrophyBoard = require(script.Parent.TrophyBoard)

local PanelRules = {}

local IN_MATCH = { Building = true, Playing = true }
local BEFORE_ROUND = { Lobby = true, Building = true }

-- Panels a spectator can't use (PLAN T83): their camp is out, so they can't build, pick
-- or upgrade a hero, or spend mastery. The tower panel stays: every tower left is another
-- camp's, and it opens read-only (Inspect).
local SPECTATOR_CLOSED = { list = true, placing = true, heroUpgrade = true, heroPick = true, mastery = true }

-- May `mode` be opened (or stay open) in `state`? `out`: this hunter's battle camp is out.
function PanelRules.allowed(mode: string, state: string?, hasHero: boolean, out: boolean?): boolean
	if mode == "closed" then
		return true
	end
	if out and SPECTATOR_CLOSED[mode] then
		return false
	end
	local s = state or ""
	if mode == "list" or mode == "placing" or mode == "manage" then
		return IN_MATCH[s] == true
	elseif mode == "heroUpgrade" then
		return IN_MATCH[s] == true and hasHero
	elseif mode == "heroPick" then
		return BEFORE_ROUND[s] == true or (s == "Playing" and not hasHero)
	elseif mode == "mastery" then
		return BEFORE_ROUND[s] == true
	elseif mode == "huntBoard" or mode == "profile" then
		return s == "Lobby"
	end
	return false
end

-- Does an open `mode` stay open when the match moves to `newState`?
function PanelRules.keepOnStateChange(mode: string, newState: string?, hasHero: boolean, out: boolean?): boolean
	if mode == "closed" then
		return true
	end
	return newState == "Playing" and PanelRules.allowed(mode, newState, hasHero, out)
end

-- The tower panel's level line, or nil at level 1 (nothing to say yet). `perLevel`
-- is Config.Tuning.TowerDamagePerLevel; levels compound, as Server/Towers applies them.
function PanelRules.towerLevelLine(level: number, perLevel: number): string?
	local whole = math.floor(level)
	if whole <= 1 then
		return nil
	end
	local percent = math.floor((1 + perLevel) ^ (whole - 1) * 100 - 100 + 0.5)
	return `Tower level {whole} · +{percent}% damage`
end

-- The tower panel's Repair row (PLAYTEST F2): a tower that can be damaged always has
-- one, greyed out at full HP, so the upgrade rows below it never move under the cursor
-- as it's bitten and healed. nil = no row (a tower that can't be damaged never has HP
-- to lose); "full" = the greyed row; "needed" = a repair to buy.
function PanelRules.repairRow(maxHp: number, hp: number, trampled: boolean): ("needed" | "full")?
	if trampled or (maxHp > 0 and hp < maxHp) then
		return "needed"
	elseif maxHp > 0 then
		return "full"
	end
	return nil
end

-- The hunter's HP bar (PLAYTEST F1): only with a character, and never on the home
-- screen, where the match is over and the home screen's cards sit in its corner.
function PanelRules.hpBarVisible(state: string?, hasCharacter: boolean): boolean
	return hasCharacter and state ~= "Lobby"
end

-- A path's tier ladder for the hero upgrade panel: one filled pip per bought tier,
-- one hollow per tier left, then "current/max" (e.g. "●●●○○○ 3/6").
function PanelRules.tierLadder(current: number, maxTier: number): string
	local whole = math.clamp(math.floor(current), 0, maxTier)
	return `{string.rep("●", whole)}{string.rep("○", maxTier - whole)} {whole}/{maxTier}`
end

-- A tower's prompt (PLAN T83, DECISIONS #233): your own camp's tower keeps the server's
-- "Upgrade" / "Upgrade / Repair"; another camp's says "Inspect" and opens the read-only
-- tower panel (T78). Co-op is side 1 everywhere, so every prompt keeps its text.
PanelRules.INSPECT = "Inspect"

function PanelRules.towerPrompt(mySide: number, towerSide: unknown, serverText: string): string
	if typeof(towerSide) == "number" and towerSide ~= mySide then
		return PanelRules.INSPECT
	end
	return serverText
end

-- Roblox's player list shows four stats (PLAN T83, DECISIONS #233), in this order:
-- Bones, the player level, Trophies ("<n> · <Arena>") and the Title. Mastery isn't one:
-- it stays on the Mastery screen, the Profile screen and the hero card.
function PanelRules.playerListColumns(): { string }
	return { Theme.Bones, Theme.PlayerLevel, TrophyBoard.COLUMN, "Title" }
end

-- In-match battle screens (PLAN T83, DECISIONS #223) --------------------------------------
-- All of them are labels: nothing to click, no mouse, nothing to close, so nothing can trap
-- a player (DIRECTION no-trap rule). Wording: DINO_REVIEW Round 16 (accepted in #229).

PanelRules.SPECTATE_LINE = "Your Fence is down — you're watching now."
PanelRules.STAMPEDE_LINE = "Final Stampede! Dinos get tougher every round."
PanelRules.CAMO_LINE = "Camo Cover: can't be hit"

export type BattleHud = { camps: boolean, spectate: boolean, stampede: boolean, camo: boolean }

-- Which battle labels show. `battle` = ReplicatedStorage BattleMode (nil in co-op, so
-- co-op never shows any); `out` = this hunter's camp is out; `overtime` = the Final
-- Stampede repeat (nil before it); `camoLeft` = seconds of Camo Cover left.
function PanelRules.battleHud(state: string?, battle: string?, out: boolean, overtime: number?, camoLeft: number): BattleHud
	local inBattle = battle ~= nil and IN_MATCH[state or ""] == true
	return {
		camps = inBattle, -- every camp's Fence and Bones: the scoreboard by side
		spectate = inBattle and out,
		stampede = inBattle and state == "Playing" and (overtime or 0) > 0,
		camo = inBattle and not out and camoLeft > 0,
	}
end

export type Camp = { side: number, camp: string, fence: number, bones: number, out: boolean }

-- The camps board, top left: the camps still in first, then by Bones (most first), then
-- by side; `mine` marks your camp. A new table: the input isn't reordered.
function PanelRules.campRows(camps: { Camp }, mySide: number): { { side: number, camp: string, fence: number, bones: number, out: boolean, mine: boolean } }
	local rows = {}
	for _, c in camps do
		table.insert(rows, { side = c.side, camp = c.camp, fence = c.fence, bones = c.bones, out = c.out, mine = c.side == mySide })
	end
	table.sort(rows, function(a, b)
		if a.out ~= b.out then
			return not a.out
		elseif a.bones ~= b.bones then
			return a.bones > b.bones
		end
		return a.side < b.side
	end)
	return rows
end

-- One camp's line: "Red Camp · Fence 12 · 40 Bones", or "Red Camp · out · 40 Bones".
function PanelRules.campLine(row: { camp: string, fence: number, bones: number, out: boolean }): string
	local fence = if row.out then "out" else `{Theme.Fence} {math.max(0, math.floor(row.fence))}`
	return `{row.camp} · {fence} · {math.floor(row.bones)} {Theme.Bones}`
end

-- The board's header: how many camps are still in.
function PanelRules.campsHeader(rows: { { out: boolean } }): string
	local alive = 0
	for _, row in rows do
		if not row.out then
			alive += 1
		end
	end
	return `{alive}/{#rows} camps left`
end

-- The battle results screen (PLAN T83, DECISIONS #218, #223) -----------------------------
-- A panel with an X: it frees the mouse, fits any window (its body scrolls) and closes on
-- its X or when the match leaves the results (going home). No key opened it, so no key
-- closes it. Co-op keeps its own result label.

-- Is the battle results panel open? `dismissed`: the hunter pressed its X this match.
function PanelRules.resultsOpen(state: string?, battle: string?, dismissed: boolean): boolean
	return battle ~= nil and (state == "Victory" or state == "GameOver") and not dismissed
end

function PanelRules.ordinal(n: number): string
	local whole = math.floor(n)
	local tens = whole % 100
	local suffix = "th"
	if tens < 11 or tens > 13 then
		suffix = ({ "st", "nd", "rd" })[whole % 10] or "th"
	end
	return `{whole}{suffix}`
end

export type ResultsIn = {
	mode: string, -- "TEAM" / "ROYALE"
	place: number?, -- your camp's placement
	mySide: number,
	camps: { { side: number, camp: string, place: number, bones: number } },
	payout: number?, -- LastPayout (casual payout + Hoard share)
	share: number?, -- LastPotShare: Ranked only
	pot: number?, -- BattlePot: the Amber Hoard, Ranked only
	trophies: number?, -- LastTrophies: the change (Ranked, not Practice)
	trophiesNow: number?, -- your Trophies after it
	newArena: string?, -- the arena first reached this match (its name)
	practice: boolean, -- a Practice Hunt (unpublished Ranked)
	xp: number?,
	levelFrom: number?,
	levelTo: number?,
}

export type ResultsOut = { title: string, won: boolean, placements: { { text: string, mine: boolean } }, lines: { string } }

function PanelRules.battleResults(r: ResultsIn): ResultsOut
	local mode = Modes.Modes[r.mode]
	local display = if mode then mode.display else ""
	local winTitle = BattleFlow.resultTitle(r.mode, r.place)
	local title = winTitle
	if not title then
		title = if r.place == nil
			then `{display} — GAME OVER`
			elseif r.mode == "ROYALE" then `{display} — {PanelRules.ordinal(r.place)} Hunter`
			else `{display} — {PanelRules.ordinal(r.place)} place`
	end
	local order = table.clone(r.camps)
	table.sort(order, function(a, b)
		return if a.place ~= b.place then a.place < b.place else a.side < b.side
	end)
	local placements = {}
	for _, c in order do
		table.insert(placements, { text = `{c.place}. {c.camp} · {math.floor(c.bones)} {Theme.Bones}`, mine = c.side == r.mySide })
	end
	local lines = {}
	if r.payout ~= nil then
		table.insert(lines, `+{math.floor(r.payout)} {Theme.Currency}`)
	end
	if r.share ~= nil then
		table.insert(lines, if r.pot ~= nil
			then `Amber Hoard {math.floor(r.pot)} {Theme.Currency} · your share +{math.floor(r.share)}`
			else `Amber Hoard share +{math.floor(r.share)}`)
	end
	if r.practice then
		table.insert(lines, HomeLayout.PRACTICE_LINE)
	elseif r.trophies ~= nil then
		local n = math.floor(r.trophies)
		local change = if n < 0 then `−{-n}` else `+{n}`
		local arena = if r.trophiesNow ~= nil then ` · {TrophyBoard.arenaName(r.trophiesNow)}` else ""
		table.insert(lines, `{change} Trophies{arena}`)
	end
	if r.newArena ~= nil and not r.practice then
		table.insert(lines, `New arena: {r.newArena}!`)
	end
	if r.xp ~= nil then
		table.insert(lines, `+{math.floor(r.xp)} player XP`)
		if r.levelFrom ~= nil and r.levelTo ~= nil then
			table.insert(lines, `Player level up! {r.levelFrom} → {r.levelTo}`)
		end
	end
	return { title = title, won = winTitle ~= nil, placements = placements, lines = lines }
end

return PanelRules
