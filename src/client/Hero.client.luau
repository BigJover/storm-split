--[[
	Hero weapons on the client: hold click (or touch) with a weapon equipped to
	keep firing at where you're aiming; F or the ability button uses the
	equipped weapon's ability.

	Both are only requests. The server (Server/Hero) checks the weapon, fire
	rate, range and cooldown and decides what gets hit, so firing faster here
	gains nothing.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local heroRequest = remotes:WaitForChild("HeroRequest") :: RemoteFunction
local heroFire = remotes:WaitForChild("HeroFire") :: RemoteEvent

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Visuals only.
local TEXT = Color3.fromRGB(240, 236, 250)
local READY = Color3.fromRGB(200, 90, 110)
local WAITING = Color3.fromRGB(70, 66, 82)

------------------------------------------------------------------ ability button

local gui = Instance.new("ScreenGui")
gui.Name = "StormSplitHero"
gui.ResetOnSpawn = false

local abilityButton = Instance.new("TextButton")
abilityButton.Name = "Ability"
abilityButton.AnchorPoint = Vector2.new(1, 1)
abilityButton.Position = UDim2.new(1, -24, 1, -136)
abilityButton.Size = UDim2.fromOffset(140, 48)
abilityButton.Font = Enum.Font.GothamBold
abilityButton.TextSize = 18
abilityButton.TextColor3 = TEXT
abilityButton.Visible = false
abilityButton.Parent = gui

do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = abilityButton
end

local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.AnchorPoint = Vector2.new(1, 1)
toast.Position = UDim2.new(1, -24, 1, -192)
toast.Size = UDim2.fromOffset(260, 24)
toast.BackgroundTransparency = 1
toast.Font = Enum.Font.GothamBold
toast.TextSize = 16
toast.TextColor3 = TEXT
toast.TextStrokeTransparency = 0.5
toast.TextXAlignment = Enum.TextXAlignment.Right
toast.Text = ""
toast.Parent = gui

local toastToken = 0
local function showToast(text: string)
	toastToken += 1
	local token = toastToken
	toast.Text = text
	task.delay(2, function()
		if toastToken == token then
			toast.Text = ""
		end
	end)
end

------------------------------------------------------------------ equipped weapon

local function equippedTool(): Tool?
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	if tool and typeof(tool:GetAttribute("WeaponType")) == "string" then
		return tool
	end
	return nil
end

local function weaponRow(tool: Tool)
	local key = tool:GetAttribute("WeaponType") :: string
	local tier = player:GetAttribute(`Weapon_{key}`) or 0
	local weapon = Config.Weapons[key]
	return weapon, if weapon and tier > 0 then weapon.tiers[tier] else nil, tier
end

-- Where the player is aiming. Towers don't block the aim.
local function aimPoint(): Vector3
	local map = workspace:FindFirstChild("StormSplitMap")
	mouse.TargetFilter = map and map:FindFirstChild("Towers")
	return mouse.Hit.Position
end

------------------------------------------------------------------ firing

local holding = false
local firing = false
local hooked: { [Tool]: boolean } = {}

local function fireLoop(tool: Tool)
	if firing then
		return
	end
	firing = true
	while holding and tool.Parent == player.Character do
		local _, row = weaponRow(tool)
		if not row then
			break
		end
		heroFire:FireServer(aimPoint())
		local overdrive = (player:GetAttribute("OverdriveUntil") or 0) > workspace:GetServerTimeNow()
		local rate = row.rate * (if overdrive then Config.Tuning.OverdriveFireRateX else 1)
		task.wait(1 / rate)
	end
	firing = false
end

local function hook(tool: Instance)
	if not tool:IsA("Tool") or hooked[tool] or typeof(tool:GetAttribute("WeaponType")) ~= "string" then
		return
	end
	hooked[tool] = true
	tool.Activated:Connect(function()
		holding = true
		task.spawn(fireLoop, tool)
	end)
	tool.Deactivated:Connect(function()
		holding = false
	end)
	tool.Unequipped:Connect(function()
		holding = false
	end)
	tool.Destroying:Connect(function()
		hooked[tool] = nil
	end)
end

local function watch(container: Instance)
	for _, child in container:GetChildren() do
		hook(child)
	end
	container.ChildAdded:Connect(hook)
end

local function onCharacter(character: Model)
	holding = false
	watch(character)
	watch(player:WaitForChild("Backpack"))
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then
	onCharacter(player.Character)
end

------------------------------------------------------------------ ability

local function useAbility()
	if not equippedTool() then
		return
	end
	local ok, _, text = pcall(function()
		return heroRequest:InvokeServer("ability", aimPoint())
	end)
	showToast(if ok then tostring(text) else "Couldn't reach the server")
end

abilityButton.Activated:Connect(useAbility)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.F then
		useAbility()
	end
end)

-- Keep the button showing the equipped weapon's ability and its cooldown.
RunService.Heartbeat:Connect(function()
	local tool = equippedTool()
	if not tool then
		abilityButton.Visible = false
		return
	end
	local key = tool:GetAttribute("WeaponType") :: string
	local weapon, _, tier = weaponRow(tool)
	if not weapon or tier < 2 then
		abilityButton.Visible = false
		return
	end
	abilityButton.Visible = true
	local remaining = (player:GetAttribute(`AbilityReadyAt_{key}`) or 0) - workspace:GetServerTimeNow()
	if remaining > 0 then
		abilityButton.Text = `{weapon.ability}  {math.ceil(remaining)}s`
		abilityButton.BackgroundColor3 = WAITING
	else
		abilityButton.Text = `{weapon.ability}  (F)`
		abilityButton.BackgroundColor3 = READY
	end
end)

gui.Parent = player:WaitForChild("PlayerGui")
