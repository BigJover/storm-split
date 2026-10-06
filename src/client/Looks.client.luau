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
