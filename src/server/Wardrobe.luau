--[[
	Wardrobe: the cosmetics a hunter wears on their character (PLAN T57): the hunting hat
	and the sprint trail (the trail shows while they run). The only thing that adds or
	removes them. What's worn comes from the Equip_<slot> attributes Server/Progression
	publishes; the parts come from Shared/Cosmetics and can't collide, be hit, be touched
	or weigh anything, so they change nothing in play (no hitbox, no size, no speed).
	The gun, tracers and crosshair are Server/Hero's and Hero.client's; tower flags are
	Server/Towers'.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cosmetics = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Cosmetics"))

local Wardrobe = {}

local HAT = "CosmeticHat"
local TRAIL = "CosmeticTrail"
local TRAIL_TOP, TRAIL_BOTTOM = "CosmeticTrailTop", "CosmeticTrailBottom"
local RUNNING = 4 -- studs/s: the trail shows above this (visual only)

local function wearing(player: Player, slot: string): Cosmetics.Item?
	return Cosmetics.worn(function(name)
		return player:GetAttribute(name)
	end, slot)
end

local function dress(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local head = character:FindFirstChild("Head")
	local root = character:FindFirstChild("HumanoidRootPart")

	local oldHat = character:FindFirstChild(HAT)
	if oldHat then
		oldHat:Destroy()
	end
	local hat = wearing(player, "hat")
	if hat and head and head:IsA("BasePart") then
		local model = Cosmetics.buildHat(hat, head.Size)
		local pivot = head.CFrame
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.CFrame = pivot * part.CFrame -- built around the head's centre
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = head
				weld.Part1 = part
				weld.Parent = part
			end
		end
		model.Parent = character
	end

	if root and root:IsA("BasePart") then
		for _, name in { TRAIL, TRAIL_TOP, TRAIL_BOTTOM } do
			local old = root:FindFirstChild(name)
			if old then
				old:Destroy()
			end
		end
		local trail = wearing(player, "trail")
		if trail then
			local top = Instance.new("Attachment")
			top.Name = TRAIL_TOP
			top.Position = Vector3.new(0, 0.5, 0.6)
			top.Parent = root
			local bottom = Instance.new("Attachment")
			bottom.Name = TRAIL_BOTTOM
			bottom.Position = Vector3.new(0, -1.6, 0.6)
			bottom.Parent = root
			local effect = Cosmetics.buildTrail(trail, top, bottom)
			effect.Enabled = false
			effect.Parent = root
		end
	end
end

function Wardrobe.init()
	local function watch(player: Player)
		player.CharacterAdded:Connect(function()
			task.defer(dress, player) -- once the head and root are in
		end)
		player.AttributeChanged:Connect(function(name)
			if name == "Equip_hat" or name == "Equip_trail" then
				dress(player)
			end
		end)
		dress(player)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	-- The trail only while running.
	RunService.Heartbeat:Connect(function()
		for _, player in Players:GetPlayers() do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local trail = root and root:FindFirstChild(TRAIL)
			if trail and trail:IsA("Trail") and root:IsA("BasePart") then
				local v = root.AssemblyLinearVelocity
				trail.Enabled = Vector3.new(v.X, 0, v.Z).Magnitude > RUNNING
			end
		end
	end)
end

return Wardrobe
