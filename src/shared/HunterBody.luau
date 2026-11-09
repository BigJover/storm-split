--!strict
--[[
	Hunter hero bodies at runtime (PLAN 11c T150 + T150b, DECISIONS #434/#436/#442/#445).

	When ArtSlot.template("hunter", KEY) is loaded (KEY = a HunterStats key: PISTOL Tracker,
	RIFLE Big Game Hunter, SHOTGUN Brush Beater, MEDIC Field Medic), `apply` dresses an R15
	character in that class's body:
	  * the avatar's visuals are hidden — every R15 part and its clothes (Transparency 1), the
	    face decal, accessory handles — but the R15 parts stay exactly as they were: the same
	    size, CFrame, CanCollide / CanQuery / CanTouch and mass, so hitboxes, the Humanoid
	    (MaxHealth, WalkSpeed: Server/Health's) and animations never change (#434);
	  * each template piece `<R15Part>__<group>` (tools/art/models/hunter/_body.py) is cloned
	    and welded to that R15 part. Pieces are authored about the HumanoidRootPart's centre in
	    the rest pose, so the weld's C0 is the piece's offset from the part's REST CFrame,
	    derived from the live rig's joints — Motor6D C0 / C1 or AnimationConstraint attachments
	    (never from the current, animated pose);
	  * paint per group: the authored colour (ArtIds), except `skin` = the avatar's own skin
	    colour (BodyColors, #442; the class tone when there is none, e.g. stand-ins);
	  * pieces are Massless, no collide / query / touch, no shadows, no scripts.
	Hunter skins (#436): a skin's own body variant is the template "hunter"/<skin key>; when
	its id is blank, the class body is recoloured instead — `shirt` takes the skin's colour and
	`pants` its accent, in its material (like Skins.hunterPaint: torso/arms colour, legs accent).
	No template (no id, not loaded, ArtOff) = the avatar exactly as today.

	Server/Wardrobe applies it to players (CharacterAdded, appearance, hero and skin changes);
	Server/StandInHunters to its Studio dummies with `applyStandIn` (a block body, no R15 rig:
	the whole body is welded to the dummy's Body at the HumanoidRootPart's rest height).
	Name tags and HP bars are BillboardGuis / the Humanoid's and are never touched.
]]

local Config = require(script.Parent.Config)
local ArtSlot = require(script.Parent.ArtSlot)

local HunterBody = {}

HunterBody.KIND = "hunter"
HunterBody.FOLDER = "HunterBody" -- the Model under the character that holds the pieces
HunterBody.DEFAULT = (Config.HeroOrder :: { string })[1] -- no hero picked yet: the free starter's body
HunterBody.PARTS = table.freeze({
	"Head", "UpperTorso", "LowerTorso",
	"LeftUpperArm", "LeftLowerArm", "LeftHand",
	"RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
	"RightUpperLeg", "RightLowerLeg", "RightFoot",
})
-- A stand-in dummy's Body is 3 studs tall standing on the ground; an R15 HumanoidRootPart's
-- centre stands 3 studs up (_body.GROUND = -3), so it sits 1.5 above the Body's centre.
HunterBody.STAND_IN_ROOT = CFrame.new(0, 1.5, 0)

local SAVED = "BodyArtTransparency" -- the avatar part's own Transparency while hidden
local isPart: { [string]: boolean } = {}
for _, name in HunterBody.PARTS do
	isPart[name] = true
end

export type Options = {
	look: { colour: Color3, accent: Color3, material: Enum.Material }?, -- the worn hunter skin
	variant: string?, -- the worn hunter skin's key (its own body variant, if loaded)
}

-- The body key for a hero attribute: the hero's own, or the default for none / unknown.
function HunterBody.key(hero: unknown): string
	if type(hero) == "string" and (Config.HunterStats :: any)[hero] then
		return hero
	end
	return HunterBody.DEFAULT
end

-- "LeftUpperArm__shirt" -> ("LeftUpperArm", "shirt"); nil for anything else.
function HunterBody.parse(name: string): (string?, string?)
	local part, group = string.match(name, "^(%w+)__(%w+)$")
	if part and isPart[part] then
		return part, group
	end
	return nil, nil
end

-- The template to wear and the key it was found under: the skin's variant first, then the class.
function HunterBody.template(key: string, variant: string?): (Model?, string?)
	if variant then
		local t = ArtSlot.template(HunterBody.KIND, variant)
		if t then
			return t, variant
		end
	end
	local t = ArtSlot.template(HunterBody.KIND, key)
	return t, if t then key else nil
end

-- Each R15 part's REST CFrame relative to the HumanoidRootPart, from the rig's joints:
-- Motor6Ds (Part1 = Part0 * C0 * C1:Inverse(), Transform ignored) or, on avatars with
-- Roblox's upgraded joints (seen in Studio 2026-11-09), AnimationConstraints (Attachment0's
-- part * Attachment0.CFrame * Attachment1.CFrame:Inverse()). Animation never moves it.
type Link = { part0: BasePart, c0: CFrame, c1: CFrame }
function HunterBody.restPose(character: Instance): { [string]: CFrame }
	local root = character:FindFirstChild("HumanoidRootPart")
	local links: { [BasePart]: Link } = {}
	for _, d in character:GetDescendants() do
		if d:IsA("Motor6D") and d.Part0 and d.Part1 then
			links[d.Part1 :: BasePart] = { part0 = d.Part0 :: BasePart, c0 = d.C0, c1 = d.C1 }
		elseif d:IsA("AnimationConstraint") then
			local a0, a1 = d.Attachment0, d.Attachment1
			local p0, p1 = a0 and a0.Parent, a1 and a1.Parent
			if a0 and a1 and p0 and p1 and p0:IsA("BasePart") and p1:IsA("BasePart") then
				links[p1] = { part0 = p0, c0 = a0.CFrame, c1 = a1.CFrame }
			end
		end
	end
	local rest: { [string]: CFrame } = {}
	local function resolve(part: BasePart, depth: number): CFrame?
		if part == root then
			return CFrame.identity
		end
		local link = links[part]
		if not link or depth > 20 then
			return nil
		end
		local parent = resolve(link.part0, depth + 1)
		return if parent then parent * link.c0 * link.c1:Inverse() else nil
	end
	for _, name in HunterBody.PARTS do
		local part = character:FindFirstChild(name)
		local at = if part and part:IsA("BasePart") then resolve(part, 0) else nil
		if at then
			rest[name] = at
		end
	end
	return rest
end

-- The colour of the `skin` group: the avatar's own skin (#442), else the class tone.
function HunterBody.skinTone(character: Instance, authored: Color3?): Color3
	local colours = character:FindFirstChildWhichIsA("BodyColors")
	if colours then
		return (colours :: BodyColors).HeadColor3
	end
	return authored or Color3.fromRGB(205, 150, 108)
end

-- One group's paint: (colour, material).
function HunterBody.paint(group: string, authored: { [string]: Color3 }, skin: Color3, look: any?, fallback: Color3): (Color3, Enum.Material)
	if group == "skin" then
		return skin, Enum.Material.SmoothPlastic
	elseif look and group == "shirt" then
		return look.colour, look.material
	elseif look and group == "pants" then
		return look.accent, look.material
	end
	return authored[group] or fallback, if group == "glow" then Enum.Material.Neon else Enum.Material.SmoothPlastic
end

local function hide(inst: any)
	if inst:GetAttribute(SAVED) == nil then
		inst:SetAttribute(SAVED, inst.Transparency)
	end
	inst.Transparency = 1
end

local function unhide(inst: any)
	local had = inst:GetAttribute(SAVED)
	if type(had) == "number" then
		inst.Transparency = had
		inst:SetAttribute(SAVED, nil)
	end
end

-- Hide the avatar's look: R15 parts (and so their clothes), face decals, accessory handles.
-- Sizes, CFrames, collision, query, touch and mass are never touched. Safe to call again
-- (an accessory that loads late).
function HunterBody.hideAvatar(character: Instance)
	for _, child in character:GetChildren() do
		if child:IsA("BasePart") and isPart[child.Name] then
			hide(child)
			for _, d in child:GetChildren() do
				if d:IsA("Decal") then
					hide(d) -- the face
				end
			end
		elseif child:IsA("Accoutrement") then
			for _, d in child:GetDescendants() do
				if d:IsA("BasePart") then
					hide(d)
				end
			end
		end
	end
end

local function showAvatar(character: Instance)
	for _, d in character:GetDescendants() do
		if d:GetAttribute(SAVED) ~= nil and (d:IsA("BasePart") or d:IsA("Decal")) then
			unhide(d)
		end
	end
end

-- Strip anything a cloned piece must not carry (scripts, joints, child parts).
local function strip(part: BasePart)
	for _, d in part:GetDescendants() do
		if not (d:IsA("Attachment") or d:IsA("DataModelMesh")) then
			d:Destroy()
		end
	end
end

local function ghost(part: BasePart)
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
end

-- Clone the template's pieces; `place(partName, rel)` returns (the part to weld to, the
-- weld's C0) or nil to skip the piece. Returns the folder and the pieces.
local function build(template: Model, usedKey: string, skin: Color3, look: any?, place: (string, CFrame) -> (BasePart?, CFrame?)): (Model, { BasePart })
	local authored = (ArtSlot.colors(HunterBody.KIND, usedKey) or {}) :: { [string]: Color3 }
	local folder = Instance.new("Model")
	folder.Name = HunterBody.FOLDER
	folder:SetAttribute("HunterKey", usedKey)
	local made: { BasePart } = {}
	for _, piece in template:GetDescendants() do
		if piece:IsA("BasePart") then
			local partName, group = HunterBody.parse(piece.Name)
			if partName and group then
				local to, c0 = place(partName, piece.CFrame)
				if to and c0 then
					local clone = piece:Clone()
					strip(clone)
					ghost(clone)
					clone.Name = piece.Name
					clone.Color, clone.Material = HunterBody.paint(group, authored, skin, look, piece.Color)
					clone.CFrame = to.CFrame * c0
					clone:SetAttribute("PaintGroup", group)
					clone:SetAttribute("ArtPiece", true)
					local weld = Instance.new("Weld")
					weld.Name = "BodyWeld"
					weld.Part0 = to
					weld.Part1 = clone
					weld.C0 = c0
					weld.Parent = clone
					clone.Parent = folder
					table.insert(made, clone)
				end
			end
		end
	end
	return folder, made
end

-- Is this character (or stand-in) wearing a hunter body? The key it wears, or nil.
function HunterBody.worn(character: Instance): string?
	local folder = character:FindFirstChild(HunterBody.FOLDER)
	local key = folder and folder:GetAttribute("HunterKey")
	return if type(key) == "string" then key else nil
end

-- Take the body off and show the avatar again, exactly as it was.
function HunterBody.remove(character: Instance)
	for _, child in character:GetChildren() do
		if child.Name == HunterBody.FOLDER then
			child:Destroy()
		end
	end
	showAvatar(character)
end

-- Dress an R15 character in `key`'s body (see the header). Returns true when dressed; false
-- (and the avatar shown as today) when there's no loaded template or the rig isn't R15.
function HunterBody.apply(character: Model, key: string, options: Options?): boolean
	local opts: Options = options or {}
	local template, usedKey = HunterBody.template(key, opts.variant)
	local root = character:FindFirstChild("HumanoidRootPart")
	local rest = HunterBody.restPose(character)
	local complete = root ~= nil
	for _, name in HunterBody.PARTS do
		complete = complete and (rest[name] :: any) ~= nil
	end
	if not template or not usedKey or not complete then
		HunterBody.remove(character)
		return false
	end
	for _, child in character:GetChildren() do
		if child.Name == HunterBody.FOLDER then
			child:Destroy() -- a hero or skin change: the old body goes
		end
	end
	local authored = (ArtSlot.colors(HunterBody.KIND, usedKey) or {}) :: { [string]: Color3 }
	local skin = HunterBody.skinTone(character, authored.skin)
	-- A skin's own variant carries its colours; only the class body is recoloured.
	local look = if usedKey == key then opts.look else nil
	local folder = build(template, usedKey, skin, look, function(partName, rel)
		local part = character:FindFirstChild(partName) :: BasePart?
		local at = rest[partName]
		if part and at then
			return part, at:Inverse() * rel
		end
		return nil, nil
	end)
	HunterBody.hideAvatar(character)
	folder.Parent = character
	return true
end

-- A Studio stand-in dummy (Server/StandInHunters): the whole body welded to its block Body,
-- the HumanoidRootPart's rest centre at STAND_IN_ROOT above the Body's centre; Body and
-- Head hidden (they stay its hit / billboard parts). Returns the pieces, or nil (no template:
-- the blocks as today). Class tone for the skin: a dummy has no avatar.
function HunterBody.applyStandIn(model: Model, body: BasePart, head: BasePart?, key: string): { BasePart }?
	local template, usedKey = HunterBody.template(key, nil)
	if not template or not usedKey then
		return nil
	end
	local authored = (ArtSlot.colors(HunterBody.KIND, usedKey) or {}) :: { [string]: Color3 }
	local folder, made = build(template, usedKey, HunterBody.skinTone(model, authored.skin), nil, function(_, rel)
		return body, HunterBody.STAND_IN_ROOT * rel
	end)
	body.Transparency = 1
	if head then
		head.Transparency = 1
	end
	folder.Parent = model
	return made
end

-- A downed stand-in fades its body like the blocks did (0.5), and comes back (0).
function HunterBody.fade(model: Instance, transparency: number)
	local folder = model:FindFirstChild(HunterBody.FOLDER)
	if folder then
		for _, piece in folder:GetChildren() do
			if piece:IsA("BasePart") then
				piece.Transparency = transparency
			end
		end
	end
end

return HunterBody
