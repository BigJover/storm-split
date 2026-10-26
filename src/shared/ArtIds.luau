--!strict
--[[
	GENERATED — DO NOT EDIT. tools/art writes this file (upload.py after an Open Cloud
	upload, or write_ids.py after a Studio-import harvest; PLAN 11a T147, DECISIONS #422/#423).

	The art asset ids per kind and key (DinoLook / TowerLook keys):
	  { [kind]: { [key]: { model: number?, parts: { [group]: { mesh: string, size: Vector3 } }? } } }
	A blank or missing entry means that look builds as its blocky fallback (#425).
	Asset ids are not secrets (#431).
]]

export type Entry = {
	model: number?,
	parts: { [string]: { mesh: string, size: Vector3 } }?,
}

local ArtIds: { [string]: { [string]: Entry } } = {
	dino = {},
	tower = {},
}

return ArtIds
