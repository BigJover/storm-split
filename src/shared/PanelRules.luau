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

	When the state changes, a panel only survives the step from Building into
	Playing, and only if it's still allowed there. Every other change closes
	it: pressing Play on the home screen, the results screen, going home.

	Also the tower panel's level line (DECISIONS #112), so its wording and its
	percent are tested too, and the hero upgrade panel's tier ladder (six tiers
	since PLAN T53): one line per path, so the panel's height doesn't grow with
	the tier count and the X stays on screen (no-trap rule).
]]

local Theme = require(script.Parent.Theme)
local TrophyBoard = require(script.Parent.TrophyBoard)

local PanelRules = {}

local IN_MATCH = { Building = true, Playing = true }
local BEFORE_ROUND = { Lobby = true, Building = true }

-- May `mode` be opened (or stay open) in `state`?
function PanelRules.allowed(mode: string, state: string?, hasHero: boolean): boolean
	if mode == "closed" then
		return true
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
function PanelRules.keepOnStateChange(mode: string, newState: string?, hasHero: boolean): boolean
	if mode == "closed" then
		return true
	end
	return newState == "Playing" and PanelRules.allowed(mode, newState, hasHero)
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

return PanelRules
