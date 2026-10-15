--[[
	Animated sets (PLAN T57, the legendary cosmetics): Server/Hero marks a gun's handle
	with the set's id ("CosmeticSet"); this colours every such gun in hand, on this screen,
	with Shared/Cosmetics.animatedColour. Looks only: nothing here is sent anywhere.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cosmetics = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Cosmetics"))

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for _, other in Players:GetPlayers() do
		local tool = other.Character and other.Character:FindFirstChildOfClass("Tool")
		local handle = tool and tool:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			local set = Cosmetics.item(handle:GetAttribute("CosmeticSet"))
			if set and set.kind == "set" then
				handle.Color = Cosmetics.animatedColour(set, t)
			end
		end
	end
end)

-- Spotter's Map (PLAN 9h T125b, #319): while a standing Spotter Blimp of your side has Dino
-- outlines, every dino on your side's track shows through walls on this screen. Only dino
-- models (the map's Enemies folder), only your side's; never a player. Looks only.
local Blimp = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Blimp"))
local Sides = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Sides"))
local OUTLINE = "SpotterOutline"
local OUTLINE_EVERY = 0.5 -- s between refreshes
local outlineClock = 0

RunService.Heartbeat:Connect(function(dt)
	outlineClock += dt
	if outlineClock < OUTLINE_EVERY then
		return
	end
	outlineClock = 0
	local map = workspace:FindFirstChild("StormSplitMap")
	local dinos = map and map:FindFirstChild("Enemies")
	if not dinos then
		return
	end
	local me = Players.LocalPlayer
	local mySide = Sides.playerSide(me:GetAttribute("Side"), ReplicatedStorage:GetAttribute("Sides"))
	local on = ReplicatedStorage:GetAttribute(Blimp.outlineAttribute(mySide)) == true
	for _, model in dinos:GetChildren() do
		local side = model:GetAttribute("Side")
		local want = Blimp.outlined(model:IsA("Model"), if typeof(side) == "number" then side else nil, mySide, on)
		local have = model:FindFirstChild(OUTLINE)
		if want and not have then
			local h = Instance.new("Highlight")
			h.Name = OUTLINE
			h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			h.FillTransparency = 1
			h.OutlineColor = Color3.fromRGB(255, 245, 200)
			h.Parent = model
		elseif have and not want then
			have:Destroy()
		end
	end
end)
