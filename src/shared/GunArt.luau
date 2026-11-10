--!strict
--[[
	Gun, melee and grenade art at runtime (PLAN 11c T151, DECISIONS #449; models in
	tools/art/models/gun + kit, README "Guns and kit").

	GUNS: Server/Hero's gun Tool keeps its 0.4 x 0.5 x 2 Handle exactly as today (size, grip,
	collision, mass). When ArtSlot.template("gun", HERO) is loaded, `dressTool` hides the
	Handle (Transparency 1) and welds the art to it AT IDENTITY: every piece is authored in
	studs about today's Handle origin (the grip), barrel along -Z, so the holding never changes.
	Attachments are additive pieces in the same frame, added when the hunter's stats show them
	(`ATTACHMENTS`: Marksman's scope, Belt Fed's drum + belt, Point Blank's second barrel,
	Thicket Sweeper's drum). Dual Pistols (`guns` >= 2) = a second PISTOL in the LEFT hand,
	welded to the LeftHand's LeftGripAttachment the way a Tool's grip is (C0 = the attachment,
	C1 = the Tool's Grip). Paint per group: the authored colour (ArtIds), except `accent` =
	the class colour / weapon skin / cosmetic (Server/Hero's paint), and at max mastery `steel`
	+ `brass` turn gold (#449). Pieces are Massless, no collide / query / touch, no shadows,
	no scripts.
	MUZZLES: an Attachment `Muzzle` (and `Muzzle2`, the double barrel's left barrel) on the
	Handle at the art's muzzle piece centre; `muzzles(tool, side)` gives the tracer starts
	(side -1 = the left gun's muzzle). nil = no art: Server/Hero keeps today's origin.
	No template (no id, not loaded, ArtOff) = the blocky Handle exactly as today.

	KIT: `prop(hero, "melee" | "grenade")` = an anchored ghost copy of kind "kit"
	`<HERO>_MELEE` / `<HERO>_GRENADE` with its origin (the grip / the ball's centre) at the
	Model's pivot, or nil (the caller draws today's block / ball).

	Visual only: hits, aim and every number stay where they are (Server/Hero, Server/Kit).
]]

local ArtSlot = require(script.Parent.ArtSlot)

local GunArt = {}

GunArt.KIND = "gun"
GunArt.KIT = "kit"
GunArt.FOLDER = "GunArt" -- the Model in the Tool holding the main gun's pieces
GunArt.OFFHAND = "GunArtOffhand" -- the Model in the Tool holding the left gun's pieces
GunArt.MUZZLE = "Muzzle"
GunArt.MUZZLE2 = "Muzzle2"
GunArt.GOLD_GROUPS = table.freeze({ steel = true, brass = true })

-- The stats an attachment reads (a subset of HeroStats.Stats).
export type Shows = {
	scope: boolean,
	beltFed: boolean,
	shotsPerTrigger: number,
	fireMode: string,
	guns: number,
}

-- How the gun is painted: `accent` = the class colour / skin / cosmetic; `gold` at max mastery.
export type Paint = {
	accent: Color3,
	accentMaterial: Enum.Material,
	gold: Color3?,
}

GunArt.ATTACHMENTS = table.freeze({
	{ key = "PISTOL_SCOPE", base = "PISTOL", shows = function(s: Shows): boolean
		return s.scope == true
	end },
	{ key = "RIFLE_BELT", base = "RIFLE", shows = function(s: Shows): boolean
		return s.beltFed == true
	end },
	{ key = "SHOTGUN_DOUBLE", base = "SHOTGUN", shows = function(s: Shows): boolean
		return s.shotsPerTrigger >= 2
	end },
	{ key = "SHOTGUN_DRUM", base = "SHOTGUN", shows = function(s: Shows): boolean
		return s.fireMode == "auto"
	end },
})

-- The art keys to wear for `hero` with these stats: the gun, then each attachment showing.
function GunArt.keys(hero: string, stats: Shows): { string }
	local keys = { hero }
	for _, a in GunArt.ATTACHMENTS do
		if a.base == hero and a.shows(stats) then
			table.insert(keys, a.key)
		end
	end
	return keys
end

-- A second gun in the left hand: Dual Pistols (README: no extra model).
function GunArt.dual(hero: string, stats: Shows): boolean
	return hero == "PISTOL" and stats.guns >= 2
end

-- One group's (colour, material).
function GunArt.paint(group: string, authored: { [string]: Color3 }, paint: Paint, fallback: Color3): (Color3, Enum.Material)
	if paint.gold and GunArt.GOLD_GROUPS[group] then
		return paint.gold, Enum.Material.SmoothPlastic
	elseif group == "accent" then
		return paint.accent, paint.accentMaterial
	end
	return authored[group] or fallback, if group == "glow" then Enum.Material.Neon else Enum.Material.SmoothPlastic
end

local function strip(part: BasePart)
	for _, d in part:GetDescendants() do
		if not (d:IsA("Attachment") or d:IsA("DataModelMesh")) then
			d:Destroy()
		end
	end
end

local function ghost(part: BasePart, anchored: boolean)
	part.Anchored = anchored
	part.Massless = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
end

-- Copies of every piece of kind/key's loaded template, painted, at their authored CFrames
-- (about the origin), each tagged PaintGroup / ArtRole / ArtPiece / ArtKey. {} when not loaded.
local function pieces(kind: string, key: string, paint: Paint?): { BasePart }
	local template = ArtSlot.template(kind, key)
	if not template then
		return {}
	end
	local authored = (ArtSlot.colors(kind, key) or {}) :: { [string]: Color3 }
	local made: { BasePart } = {}
	for _, piece in template:GetDescendants() do
		if piece:IsA("BasePart") then
			local clone = piece:Clone()
			strip(clone)
			ghost(clone, true)
			local group, role = ArtSlot.pieceInfo(kind, key, piece)
			if paint then
				clone.Color, clone.Material = GunArt.paint(group, authored, paint, piece.Color)
			else
				clone.Color = authored[group] or piece.Color
				clone.Material = if group == "glow" then Enum.Material.Neon else Enum.Material.SmoothPlastic
			end
			clone.Name = `Art_{group}`
			clone.CFrame = piece.CFrame
			clone:SetAttribute("PaintGroup", group)
			if role then
				clone:SetAttribute("ArtRole", role)
			end
			clone:SetAttribute("ArtPiece", true)
			clone:SetAttribute("ArtKey", key)
			table.insert(made, clone)
		end
	end
	return made
end

-- The gun's pieces (base + showing attachments) about the grip, or nil when the base gun's
-- art isn't loaded. An attachment whose art isn't loaded is simply left off.
function GunArt.build(hero: string, stats: Shows, paint: Paint): { BasePart }?
	local base = pieces(GunArt.KIND, hero, paint)
	if #base == 0 then
		return nil
	end
	local keys = GunArt.keys(hero, stats)
	for i = 2, #keys do
		for _, p in pieces(GunArt.KIND, keys[i], paint) do
			table.insert(base, p)
		end
	end
	return base
end

local function weld(part0: BasePart, part1: BasePart, c0: CFrame)
	local w = Instance.new("Weld")
	w.Name = "ArtWeld"
	w.Part0 = part0
	w.Part1 = part1
	w.C0 = c0
	w.Parent = part1
end

-- Take the art off a tool: the Handle as today.
function GunArt.clear(tool: Tool, handle: BasePart)
	for _, child in tool:GetChildren() do
		if child.Name == GunArt.FOLDER or child.Name == GunArt.OFFHAND then
			child:Destroy()
		end
	end
	for _, name in { GunArt.MUZZLE, GunArt.MUZZLE2 } do
		local a = handle:FindFirstChild(name)
		if a then
			a:Destroy()
		end
	end
	if handle:GetAttribute("GunArt") then
		handle:SetAttribute("GunArt", nil)
		handle.Transparency = 0
	end
end

-- Dress a hero gun Tool (see the header). `leftHand` = the character's LeftHand for Dual
-- Pistols (nil: no left gun). Returns true when dressed; false = the Handle as today.
function GunArt.dressTool(tool: Tool, handle: BasePart, hero: string, stats: Shows, paint: Paint, leftHand: BasePart?): boolean
	GunArt.clear(tool, handle)
	local made = GunArt.build(hero, stats, paint)
	if not made then
		return false
	end
	local folder = Instance.new("Model")
	folder.Name = GunArt.FOLDER
	for _, piece in made do
		local rel = piece.CFrame
		piece.Anchored = false
		piece.CFrame = handle.CFrame * rel
		weld(handle, piece, rel)
		piece.Parent = folder
		local role = piece:GetAttribute("ArtRole")
		if role == "muzzle" or role == "muzzle2" then
			local name = if role == "muzzle" then GunArt.MUZZLE else GunArt.MUZZLE2
			if not handle:FindFirstChild(name) then
				local a = Instance.new("Attachment")
				a.Name = name
				a.CFrame = CFrame.new(rel.Position)
				a.Parent = handle
			end
		end
	end
	folder.Parent = tool
	handle:SetAttribute("GunArt", hero)
	handle.Transparency = 1

	local grip = leftHand and leftHand:FindFirstChild("LeftGripAttachment")
	if leftHand and grip and grip:IsA("Attachment") and GunArt.dual(hero, stats) then
		local left = Instance.new("Model")
		left.Name = GunArt.OFFHAND
		local hold = grip.CFrame * tool.Grip:Inverse()
		for _, piece in pieces(GunArt.KIND, hero, paint) do
			local rel = hold * piece.CFrame
			piece.Anchored = false
			piece.CFrame = leftHand.CFrame * rel
			weld(leftHand, piece, rel)
			piece.Parent = left
		end
		left.Parent = tool
	end
	return true
end

-- Where tracers leave from: { world positions } (the double barrel gives two, to alternate),
-- or nil when the gun has no art (then today's origin). side -1 = the left gun of a pair.
function GunArt.muzzles(tool: Instance, side: number?): { Vector3 }?
	if side == -1 then
		local left = tool:FindFirstChild(GunArt.OFFHAND)
		if not left then
			return nil
		end
		for _, piece in left:GetChildren() do
			if piece:IsA("BasePart") and piece:GetAttribute("ArtRole") == "muzzle" then
				return { piece.CFrame.Position }
			end
		end
		return nil
	end
	local handle = tool:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") or not handle:GetAttribute("GunArt") then
		return nil
	end
	local out: { Vector3 } = {}
	for _, name in { GunArt.MUZZLE, GunArt.MUZZLE2 } do
		local a = handle:FindFirstChild(name)
		if a and a:IsA("Attachment") then
			table.insert(out, (handle.CFrame * a.CFrame).Position)
		end
	end
	return if #out > 0 then out else nil
end

-- A kit prop ("melee" / "grenade") as an anchored ghost Model, its origin at the pivot
-- (Model:PivotTo places it), or nil (no art: the caller draws today's look).
function GunArt.prop(hero: string, which: string): Model?
	local key = `{hero}_{if which == "melee" then "MELEE" else "GRENADE"}`
	local made = pieces(GunArt.KIT, key, nil)
	if #made == 0 then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = key
	for _, piece in made do
		piece.Parent = model
	end
	model.WorldPivot = CFrame.identity
	return model
end

-- An anchored copy of a dressed tool's main gun (its pieces at their grip offsets), for a
-- swing that swings the gun itself (Big Game Hunter's Stock Swing, #449), or nil.
function GunArt.copy(tool: Instance): Model?
	local folder = tool:FindFirstChild(GunArt.FOLDER)
	if not folder then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = GunArt.FOLDER
	for _, piece in folder:GetChildren() do
		local w = piece:FindFirstChild("ArtWeld")
		if piece:IsA("BasePart") and w and w:IsA("Weld") then
			local clone = piece:Clone()
			strip(clone)
			ghost(clone, true)
			clone.CFrame = w.C0
			clone.Parent = model
		end
	end
	model.WorldPivot = CFrame.identity
	return model
end

return GunArt
