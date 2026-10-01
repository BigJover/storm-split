--[[
	The private hit notice (DECISIONS #39): when a dino hurts you, one short line
	beside your own HP bar says what it was — "Raptor · Slash −4". Pure, so the
	text and the merging can be tested; Hud shows it, Server/Health sends it to
	the hunter who was hit and nobody else.

	A new hit replaces the line. A repeat of the same attack while the line is
	still showing adds up ("−8"). The line fades FADE seconds after the last hit.
]]

local HitNotice = {}

HitNotice.FADE = 1.5 -- seconds (UI timing, not a gameplay number)

export type State = {
	species: string,
	attack: string,
	total: number,
	at: number, -- when the last hit landed
}

-- The notice after a hit of `amount` from `species`'s `attack` at time `now`.
function HitNotice.merge(current: State?, species: string, attack: string, amount: number, now: number): State
	if current and current.species == species and current.attack == attack and now - current.at < HitNotice.FADE then
		return { species = species, attack = attack, total = current.total + amount, at = now }
	end
	return { species = species, attack = attack, total = amount, at = now }
end

-- "Raptor · Slash −4" (a real minus sign; whole numbers, at least 1).
function HitNotice.text(state: State): string
	local shown = math.max(1, math.floor(state.total + 0.5))
	return `{state.species} · {state.attack} −{shown}`
end

function HitNotice.visible(state: State?, now: number): boolean
	return state ~= nil and now - state.at < HitNotice.FADE
end

return HitNotice
