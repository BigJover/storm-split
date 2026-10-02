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

	When the state changes, a panel only survives the step from Building into
	Playing, and only if it's still allowed there. Every other change closes
	it: pressing Play on the home screen, the results screen, going home.

	Also the tower panel's level line (DECISIONS #112), so its wording and its
	percent are tested too.
]]

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
	elseif mode == "huntBoard" then
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

return PanelRules
