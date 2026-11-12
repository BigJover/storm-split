--!strict
--[[
	Outpost props in their art (PLAN 11f T156, DECISIONS #426/#450/#455; the tools/art/README
	"Outpost props" contract). Visual only: a prop's art is a Model of ghost pieces (anchored,
	Massless, no collide / query / touch, no scripts) standing with its origin on the prop's
	ANCHOR (the CFrame the blocky code builds from). The blocky parts it replaces are kept
	exactly as they are — size, CFrame, collision, attributes, BillboardGuis, lights — and only
	turned invisible (Transparency 1, the old value saved in attribute ArtHidden), so walking,
	distance checks, signs and the camp's collision never change. No loaded art (blank id, not
	loaded, ArtOff) = nothing added, nothing hidden: today's camp exactly.

	  dress(parent, key, anchor, replaces, opts)   the art of prop `key` (kind "prop") at
	                             `anchor`, parented under `parent` (a Model named Art_<key>,
	                             attribute PropArt), its `replaces` hidden; nil (nothing changed)
	                             without art. opts: colors / materials per paint group (over the
	                             authored ones, e.g. a decoration's Skins look), castShadow.
	  face(model, title, line?, faces?)   a SurfaceGui sign on every `face` piece (Face Front
	                             = the prop's front, -Z; `faces` adds e.g. Back), text sized to
	                             the plate; returns the TextLabels.
	  undress(root)              every PropArt model under `root` removed and every hidden part's
	                             Transparency put back exactly (art switched off / re-dressed).
	  loaded(key)                is prop `key`'s art loaded (optional props are art-only)
	Group `glow` is Neon (ArtSlot); every other group SmoothPlastic unless opts say otherwise.
]]

local ArtSlot = require(script.Parent.ArtSlot)

local PropArt = {}

PropArt.KIND = "prop"
PropArt.HIDDEN = "ArtHidden" -- attribute: a replaced blocky part's own Transparency
PropArt.MARK = "PropArt" -- attribute on an art Model

export type Options = {
	colors: { [string]: Color3 }?,
	materials: { [string]: Enum.Material }?,
	castShadow: boolean?,
}

function PropArt.loaded(key: string): boolean
	return ArtSlot.template(PropArt.KIND, key) ~= nil
end

local function hide(part: BasePart)
	if part:GetAttribute(PropArt.HIDDEN) == nil then
		part:SetAttribute(PropArt.HIDDEN, part.Transparency)
	end
	part.Transparency = 1
	for _, d in part:GetChildren() do
		if d:IsA("Decal") then -- a Texture is a Decal
			local decal = d :: Decal
			if decal:GetAttribute(PropArt.HIDDEN) == nil then
				decal:SetAttribute(PropArt.HIDDEN, decal.Transparency)
			end
			decal.Transparency = 1
		end
	end
end

function PropArt.dress(parent: Instance, key: string, anchor: CFrame, replaces: { BasePart }, options: Options?): Model?
	if not PropArt.loaded(key) then
		return nil
	end
	local opts: Options = options or {}
	local holder = Instance.new("Part") -- the anchor, for ArtSlot (never parented)
	holder.CFrame = anchor
	holder.Anchored = true
	local model = Instance.new("Model")
	model.Name = `Art_{key}`
	local dressed, parts = ArtSlot.dress(model, PropArt.KIND, key, 1, holder, ArtSlot.paints(Color3.fromRGB(122, 88, 56)), {
		anchored = true,
		castShadow = opts.castShadow ~= false,
	})
	holder:Destroy()
	if not dressed then
		model:Destroy()
		return nil
	end
	local colors = opts.colors or {}
	local materials = opts.materials or {}
	for _, part in parts do
		local group = part:GetAttribute("PaintGroup") :: string
		if colors[group] then
			part.Color = colors[group]
		end
		if materials[group] then
			part.Material = materials[group]
		end
	end
	model:SetAttribute(PropArt.MARK, true)
	model.WorldPivot = anchor
	model.Parent = parent
	for _, part in replaces do
		hide(part)
	end
	return model
end

-- Dark text on a light plate, light text on a dark one.
local function ink(plate: Color3): Color3
	local light = plate.R * 0.3 + plate.G * 0.59 + plate.B * 0.11
	return if light > 0.5 then Color3.fromRGB(60, 40, 25) else Color3.fromRGB(250, 236, 200)
end

function PropArt.face(model: Model, title: string, line: string?, faces: { Enum.NormalId }?): { TextLabel }
	local labels = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute("PaintGroup") == "face" then
			local sides: { Enum.NormalId } = faces or { Enum.NormalId.Front }
			for _, face in sides do
				local gui = Instance.new("SurfaceGui")
				gui.Name = "Sign"
				gui.Face = face
				gui.CanvasSize = Vector2.new(math.max(part.Size.X, 0.5) * 100, math.max(part.Size.Y, 0.2) * 100)
				gui.Parent = part
				local text = Instance.new("TextLabel")
				text.Name = "Text"
				text.Size = UDim2.fromScale(1, 1)
				text.BackgroundTransparency = 1
				text.Font = Enum.Font.Antique
				text.TextScaled = true
				text.RichText = line ~= nil
				text.TextColor3 = ink(part.Color)
				text.Text = if line then `{title}\n<font size="14">{line}</font>` else title
				text.Parent = gui
				table.insert(labels, text)
			end
		end
	end
	return labels
end

function PropArt.undress(root: Instance)
	for _, d in root:GetDescendants() do
		if d:IsA("Model") and d:GetAttribute(PropArt.MARK) then
			d:Destroy()
		end
	end
	for _, d in root:GetDescendants() do
		local was = d:GetAttribute(PropArt.HIDDEN)
		if type(was) == "number" and (d:IsA("BasePart") or d:IsA("Decal")) then
			(d :: any).Transparency = was
			d:SetAttribute(PropArt.HIDDEN, nil)
		end
	end
end

return PropArt
