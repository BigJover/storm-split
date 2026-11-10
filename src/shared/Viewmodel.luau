--!strict
--[[
	First-person viewmodel (PLAN 11c T151b, DECISIONS #435): what the local player sees of
	their own hunter while in first person with a dressed gun — the class's arms (sleeves and
	hands from the body they wear) holding the gun art, on the camera. Client only; everyone
	else sees the third-person body and gun (Server/Wardrobe, Server/Hero).

	Built from what the character already wears, so skins, mastery gold and cosmetic paint
	match the third-person look exactly:
	  * the gun = copies of the Tool's GunArt pieces (Shared/GunArt) at their grip offsets;
	    Dual Pistols add a left copy of the base gun;
	  * the arms = copies of the character's HunterBody pieces on the arm parts, placed the way
	    they sit relative to the held gun in the body's REST pose (HunterBody.restPose + the
	    hand's grip attachment): the arm runs straight back from the grip, as in the tool-hold
	    pose. The left arm shows for two-handed guns (it holds the fore-end) and Dual Pistols.
	No gun art = no viewmodel (today's first-person view, the blocky Handle). No body art =
	the gun alone (#435's fallback). A static pose with a little sway and a recoil kick; no
	animation system. Anchored ghost parts under the camera; nothing is sent anywhere.
]]

local GunArt = require(script.Parent.GunArt)
local HunterBody = require(script.Parent.HunterBody)

local Viewmodel = {}

Viewmodel.NAME = "HunterViewmodel"
-- Where the grip sits in front of the camera (studs: right, up, forward = -Z). Visual only.
Viewmodel.HOLD = table.freeze({
	PISTOL = Vector3.new(0.75, -0.7, -1.45),
	RIFLE = Vector3.new(0.7, -0.75, -1.65),
	SHOTGUN = Vector3.new(0.7, -0.75, -1.65),
	MEDIC = Vector3.new(0.7, -0.75, -1.65),
})
Viewmodel.AIM_DISTANCE = 40 -- studs ahead the gun points at (the crosshair)
-- Dual Pistols: the left gun, in the right gun's frame.
Viewmodel.LEFT_GUN = CFrame.new(-1.45, 0, 0.05) * CFrame.Angles(0, math.rad(-6), 0)
-- Two-handed guns: the left hand on the fore-end, the arm running back-left and down.
Viewmodel.SUPPORT_Z = table.freeze({ RIFLE = -0.95, SHOTGUN = -0.85, MEDIC = -0.85 })
Viewmodel.SUPPORT_TURN = CFrame.Angles(math.rad(20), math.rad(-35), 0)
Viewmodel.KICK_BACK = 0.14 -- studs the gun jumps back per shot (kick 1)
Viewmodel.KICK_PITCH = math.rad(7)
Viewmodel.KICK_DECAY = 14 -- per second
Viewmodel.SWAY_MAX = 0.08 -- studs
Viewmodel.SWAY_GAIN = 0.35 -- studs per radian of camera turn this frame
Viewmodel.SWAY_SETTLE = 10 -- per second

local RIGHT_ARM = { "RightUpperArm", "RightLowerArm", "RightHand" }
local LEFT_ARM = { "LeftUpperArm", "LeftLowerArm", "LeftHand" }

type Item = { part: BasePart, source: BasePart, rel: CFrame }
export type VM = {
	model: Model,
	items: { Item },
	hero: string,
	tool: Tool,
	gunFolder: Instance,
	bodyFolder: Instance?,
	kick: number,
	sway: Vector3,
	look: Vector3?,
}

local function setLocal(part: BasePart, value: number)
	pcall(function()
		(part :: any).LocalTransparencyModifier = value
	end)
end

local function copyOf(source: BasePart): BasePart
	local part = source:Clone()
	for _, d in part:GetDescendants() do
		if not (d:IsA("Attachment") or d:IsA("DataModelMesh")) then
			d:Destroy()
		end
	end
	part.Anchored = true
	part.Massless = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 0
	setLocal(part, 0)
	return part
end

local function arm(names: { string }, character: Instance, rest: { [string]: CFrame }, hand: string, gripName: string, grip: CFrame, frame: CFrame, add: (BasePart, CFrame) -> ())
	local body = character:FindFirstChild(HunterBody.FOLDER)
	local handPart = character:FindFirstChild(hand)
	local att = handPart and handPart:FindFirstChild(gripName)
	if not body or not att or not att:IsA("Attachment") or not rest[hand] then
		return
	end
	local heldAt = rest[hand] * att.CFrame * grip:Inverse() -- the held gun's grip in the rest pose
	local wanted: { [string]: boolean } = {}
	for _, n in names do
		wanted[n] = true
	end
	for _, piece in body:GetChildren() do
		local w = piece:FindFirstChild("BodyWeld")
		local partName = if piece:IsA("BasePart") then HunterBody.parse(piece.Name) else nil
		if partName and wanted[partName] and rest[partName] and w and w:IsA("Weld") then
			add(piece :: BasePart, frame * heldAt:Inverse() * rest[partName] * w.C0)
		end
	end
end

-- Build the viewmodel for this tool (a dressed hero gun) and character, or nil when the gun
-- has no art. Not parented: the caller puts `model` under the camera.
function Viewmodel.build(tool: Tool, character: Instance, hero: string): VM?
	local gunFolder = tool:FindFirstChild(GunArt.FOLDER)
	if not gunFolder then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = Viewmodel.NAME
	local items: { Item } = {}
	local function add(source: BasePart, rel: CFrame)
		local part = copyOf(source)
		part.Parent = model
		table.insert(items, { part = part, source = source, rel = rel })
	end
	local offhand = tool:FindFirstChild(GunArt.OFFHAND) ~= nil
	for _, piece in gunFolder:GetChildren() do
		local w = piece:FindFirstChild("ArtWeld")
		if piece:IsA("BasePart") and w and w:IsA("Weld") then
			add(piece, w.C0)
			if offhand and piece:GetAttribute("ArtKey") == hero then
				add(piece, Viewmodel.LEFT_GUN * w.C0)
			end
		end
	end
	local rest = HunterBody.restPose(character)
	arm(RIGHT_ARM, character, rest, "RightHand", "RightGripAttachment", tool.Grip, CFrame.identity, add)
	local support = Viewmodel.SUPPORT_Z[hero]
	if offhand then
		arm(LEFT_ARM, character, rest, "LeftHand", "LeftGripAttachment", tool.Grip, Viewmodel.LEFT_GUN, add)
	elseif support then
		arm(LEFT_ARM, character, rest, "LeftHand", "LeftGripAttachment", tool.Grip, CFrame.new(0, -0.08, support) * Viewmodel.SUPPORT_TURN, add)
	end
	return {
		model = model,
		items = items,
		hero = hero,
		tool = tool,
		gunFolder = gunFolder,
		bodyFolder = character:FindFirstChild(HunterBody.FOLDER),
		kick = 0,
		sway = Vector3.zero,
		look = nil,
	}
end

-- Has what it was built from changed (a re-dressed gun, a new body, another tool)?
function Viewmodel.stale(vm: VM, tool: Tool?, character: Instance?): boolean
	return tool ~= vm.tool
		or vm.tool:FindFirstChild(GunArt.FOLDER) ~= vm.gunFolder
		or (character and character:FindFirstChild(HunterBody.FOLDER)) ~= vm.bodyFolder
end

-- The gun's grip frame for this camera: HOLD in front, aimed at the crosshair, with sway and kick.
function Viewmodel.gripFrame(vm: VM, camera: CFrame): CFrame
	local hold = Viewmodel.HOLD[vm.hero] or Viewmodel.HOLD.RIFLE
	local at = (camera * CFrame.new(hold + vm.sway)).Position
	local aim = CFrame.lookAt(at, (camera * CFrame.new(0, 0, -Viewmodel.AIM_DISTANCE)).Position, camera.UpVector)
	return aim * CFrame.new(0, 0, Viewmodel.KICK_BACK * vm.kick) * CFrame.Angles(Viewmodel.KICK_PITCH * vm.kick, 0, 0)
end

-- One frame: settle kick and sway, place every part, follow the sources' paint (an animated
-- cosmetic set recolours the tool's accent every frame).
function Viewmodel.step(vm: VM, camera: CFrame, dt: number)
	vm.kick *= math.exp(-Viewmodel.KICK_DECAY * dt)
	local look = camera.LookVector
	if vm.look then
		local turn = vm.look:Cross(look) -- small rotation axis x angle, camera space below
		local push = camera:VectorToObjectSpace(turn) * Viewmodel.SWAY_GAIN
		vm.sway += Vector3.new(push.Y, -push.X, 0)
	end
	vm.look = look
	vm.sway *= math.exp(-Viewmodel.SWAY_SETTLE * dt)
	if vm.sway.Magnitude > Viewmodel.SWAY_MAX then
		vm.sway = vm.sway.Unit * Viewmodel.SWAY_MAX
	end
	local grip = Viewmodel.gripFrame(vm, camera)
	for _, item in vm.items do
		item.part.CFrame = grip * item.rel
		item.part.Color = item.source.Color
		item.part.Material = item.source.Material
	end
end

-- A shot: the gun jumps back and up, then settles.
function Viewmodel.kick(vm: VM)
	vm.kick = math.min(1.5, vm.kick + 1)
end

-- Hide (true) or show (false) the third-person gun on this screen while the viewmodel is up.
function Viewmodel.hideTool(tool: Instance, hidden: boolean)
	for _, name in { GunArt.FOLDER, GunArt.OFFHAND } do
		local folder = tool:FindFirstChild(name)
		if folder then
			for _, piece in folder:GetChildren() do
				if piece:IsA("BasePart") then
					setLocal(piece, if hidden then 1 else 0)
				end
			end
		end
	end
end

function Viewmodel.destroy(vm: VM)
	Viewmodel.hideTool(vm.tool, false)
	vm.model:Destroy()
end

return Viewmodel
