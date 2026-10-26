--!strict
--[[
	GENERATED — DO NOT EDIT. tools/art writes this file (upload.py after an Open Cloud
	upload, or write_ids.py after a Studio-import harvest; PLAN 11a T147, DECISIONS #422/#423).

	The art asset ids per kind and key (DinoLook / TowerLook keys):
	  { [kind]: { [key]: { model: number?, parts: { [group]: { mesh: string, size: Vector3 } }?,
	    colors: { [group]: Color3 }? } } }
	A blank or missing model id means that look builds as its blocky fallback (#425).
	colors = the authored colour per paint group (#439); ArtSlot paints the art with them
	(a group without one takes the look's colours).
	Asset ids are not secrets (#431).
]]

export type Entry = {
	model: number?,
	parts: { [string]: { mesh: string, size: Vector3 } }?,
	colors: { [string]: Color3 }?,
}

local ArtIds: { [string]: { [string]: Entry } } = {
	dino = {
		ARMOR = { colors = { accent = Color3.fromRGB(190, 110, 45), belly = Color3.fromRGB(167, 168, 168), body = Color3.fromRGB(95, 105, 120), dark = Color3.fromRGB(50, 50, 56), eye = Color3.fromRGB(25, 20, 20) } },
		BARGE = { colors = { accent = Color3.fromRGB(165, 45, 15), belly = Color3.fromRGB(78, 68, 64), body = Color3.fromRGB(38, 32, 32), dark = Color3.fromRGB(14, 11, 11), eye = Color3.fromRGB(255, 220, 60), glow = Color3.fromRGB(255, 120, 20) } },
		BRUTE = { colors = { accent = Color3.fromRGB(120, 70, 35), belly = Color3.fromRGB(224, 192, 136), body = Color3.fromRGB(205, 140, 70), dark = Color3.fromRGB(70, 52, 38), eye = Color3.fromRGB(25, 20, 20) } },
		HUSK = { colors = { belly = Color3.fromRGB(200, 209, 148), body = Color3.fromRGB(126, 196, 110), dark = Color3.fromRGB(84, 64, 42), eye = Color3.fromRGB(25, 20, 20) } },
		LLAMA = { colors = { accent = Color3.fromRGB(225, 50, 170), belly = Color3.fromRGB(135, 125, 187), body = Color3.fromRGB(70, 55, 150), dark = Color3.fromRGB(35, 25, 55), eye = Color3.fromRGB(25, 20, 20), glow = Color3.fromRGB(90, 245, 255) } },
		SHIELD = { colors = { accent = Color3.fromRGB(190, 75, 45), belly = Color3.fromRGB(207, 183, 140), body = Color3.fromRGB(150, 110, 80), dark = Color3.fromRGB(70, 55, 45), eye = Color3.fromRGB(25, 20, 20) } },
		STORM = { colors = { accent = Color3.fromRGB(250, 215, 40), belly = Color3.fromRGB(190, 235, 240), body = Color3.fromRGB(35, 130, 145), dark = Color3.fromRGB(50, 40, 110), eye = Color3.fromRGB(25, 20, 20) } },
		ZEP = { colors = { accent = Color3.fromRGB(150, 78, 30), belly = Color3.fromRGB(100, 94, 110), body = Color3.fromRGB(48, 40, 62), dark = Color3.fromRGB(22, 18, 28), eye = Color3.fromRGB(255, 120, 30), glow = Color3.fromRGB(255, 175, 45) } },
	},
	tower = {},
}

return ArtIds
