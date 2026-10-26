--!strict
--[[
	Art slots (PLAN 11a T148, DECISIONS #422/#425/#426): a look dresses itself in its uploaded
	art when the asset's id is in Shared/ArtIds AND Server/Art has loaded it into
	ReplicatedStorage.Art.<kind>.<key> (a Model tagged with attribute ArtId = that id).
	Otherwise dress() returns false and the caller builds today's blocky look, unchanged.

	Visual only (#426): the gameplay part (dino Root, tower Body) is never touched. Every art
	piece is a clone, sized x scale, placed at its offset from the origin x scale (a template
	is authored with the gameplay part's centre at the origin, tools/art fit-to-box),
	Massless, CanCollide / CanQuery / CanTouch off, no scripts or joints of its own, welded to
	the gameplay part (or anchored where the look anchors, towers). Pieces are coloured by
	paint group (attribute PaintGroup, else the piece's name: body / belly / accent / dark /
	eye) from the look's colours. A piece with attribute ArtRole = "head" / "jaw" is named
	Head / Jaw, so the status effects that find those (flashHead, setMuzzled) still show;
	a look can require roles, and a template missing one falls back to blocky.

	Kinds: "dino" (DinoLook), "tower" (TowerLook). Hunters get full R15 bodies in 11c (#434),
	a different mechanism, not this slot.
]]

local ArtIds = require(script.Parent.ArtIds)

local ArtSlot = {}

ArtSlot.FOLDER = "Art"

export type Options = {
	anchored: boolean?, -- towers anchor their look parts; dinos weld to the Root
	castShadow: boolean?,
	roles: { string }?, -- ArtRole values the template must have
}

local ids: { [string]: { [string]: ArtIds.Entry } } = ArtIds
local source: Instance? = nil
local warned: { [string]: boolean } = {}

-- Specs: a fake ids map and a fake ReplicatedStorage.Art folder. nil restores the defaults.
function ArtSlot.setIds(map: { [string]: { [string]: ArtIds.Entry } }?)
	ids = map or ArtIds
end
function ArtSlot.setSource(folder: Instance?)
	source = folder
end

local function artFolder(): Instance?
	if source then
		return source
	end
	local g: any = game
	if g == nil then
		return nil -- headless (Lune): no DataModel, always the blocky look
	end
	return g:GetService("ReplicatedStorage"):FindFirstChild(ArtSlot.FOLDER)
end

-- The asset id for kind/key, or nil (blank = blocky).
function ArtSlot.id(kind: string, key: string): number?
	local byKey = ids[kind]
	local entry = byKey and byKey[key]
	return entry and entry.model or nil
end

-- The loaded template for kind/key, or nil: no id, not loaded (yet), loaded for another id,
-- or art switched off (attribute ArtOff on the Art folder, for A/B looks).
function ArtSlot.template(kind: string, key: string): Model?
	local id = ArtSlot.id(kind, key)
	local folder = artFolder()
	if not id or not folder or folder:GetAttribute("ArtOff") then
		return nil
	end
	local byKind = folder:FindFirstChild(kind)
	local template = byKind and byKind:FindFirstChild(key)
	if template and template:IsA("Model") and template:GetAttribute("ArtId") == id then
		return template
	end
	return nil
end

local function warnOnce(kind: string, key: string, why: string)
	local tag = `{kind}/{key}`
	if not warned[tag] then
		warned[tag] = true
		warn(`[Art] {tag}: {why} — blocky look used`)
	end
end

-- The paint group colours for a look: its body colour and an optional accent.
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local EYE = Color3.fromRGB(25, 20, 20)
function ArtSlot.paints(body: Color3, accent: Color3?): { [string]: Color3 }
	local dark = body:Lerp(BLACK, 0.45)
	return { body = body, belly = body:Lerp(WHITE, 0.35), dark = dark, accent = accent or dark, eye = EYE }
end

-- Anything a cloned piece must not carry: scripts, joints, constraints, child parts.
local function strip(part: BasePart)
	for _, d in part:GetDescendants() do
		if not (d:IsA("Attachment") or d:IsA("DataModelMesh")) then
			d:Destroy()
		end
	end
end

-- Dress `model` in kind/key's art around `gameplay` (never changed). Returns false (nothing
-- added) when there is no loaded art; then the caller builds its blocky look. On true, also
-- returns the art parts.
function ArtSlot.dress(
	model: Model,
	kind: string,
	key: string,
	scale: number,
	gameplay: BasePart,
	paints: { [string]: Color3 },
	options: Options?
): (boolean, { BasePart })
	local template = ArtSlot.template(kind, key)
	if not template then
		return false, {}
	end
	local opts: Options = options or {}
	local pieces: { BasePart } = {}
	for _, d in template:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(pieces, d)
		end
	end
	if #pieces == 0 then
		warnOnce(kind, key, "template has no parts")
		return false, {}
	end
	local roles: { string } = opts.roles or {}
	for _, role in roles do
		local found = false
		for _, piece in pieces do
			found = found or piece:GetAttribute("ArtRole") == role
		end
		if not found then
			warnOnce(kind, key, `no piece with ArtRole '{role}'`)
			return false, {}
		end
	end

	local named: { [string]: boolean } = {}
	local made: { BasePart } = {}
	for _, piece in pieces do
		local part = piece:Clone()
		strip(part)
		local group = piece:GetAttribute("PaintGroup")
		if type(group) ~= "string" then
			group = piece.Name
		end
		local role = piece:GetAttribute("ArtRole")
		local roleName = if role == "head" then "Head" elseif role == "jaw" then "Jaw" else nil
		if roleName and not named[roleName] then
			named[roleName] = true
			part.Name = roleName
		else
			part.Name = `Art_{group}`
		end
		local rel = piece.CFrame -- authored about the origin = the gameplay part's centre
		part.Size = piece.Size * scale
		part.CFrame = gameplay.CFrame * CFrame.new(rel.Position * scale) * rel.Rotation
		part.Color = paints[group :: string] or paints.body or piece.Color
		part.Material = Enum.Material.SmoothPlastic
		part.Anchored = opts.anchored == true
		part.Massless = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = opts.castShadow == true
		part:SetAttribute("PaintGroup", group)
		part:SetAttribute("ArtPiece", true)
		if not part.Anchored then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = gameplay
			weld.Part1 = part
			weld.Parent = part
		end
		part.Parent = model
		table.insert(made, part)
	end
	model:SetAttribute("ArtKey", key)
	return true, made
end

-- How high the parts reach above `origin` (a tower's crown sits there).
function ArtSlot.top(parts: { BasePart }, origin: CFrame): number
	local top = 0
	for _, part in parts do
		local rel = origin:ToObjectSpace(part.CFrame)
		local half = part.Size / 2
		local reach = math.abs(rel.XVector.Y) * half.X + math.abs(rel.YVector.Y) * half.Y + math.abs(rel.ZVector.Y) * half.Z
		top = math.max(top, rel.Position.Y + reach)
	end
	return top
end

return ArtSlot
