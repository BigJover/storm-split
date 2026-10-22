--[[
	Wardrobe: the cosmetics a hunter wears on their character (PLAN T57): the hunting hat
	and the sprint trail (the trail shows while they run). The only thing that adds or
	removes them. What's worn comes from the Equip_<slot> attributes Server/Progression
	publishes; the parts come from Shared/Cosmetics and can't collide, be hit, be touched
	or weigh anything, so they change nothing in play (no hitbox, no size, no speed).
	The gun, tracers and crosshair are Server/Hero's and Hero.client's; tower flags are
	Server/Towers'.

	Hunter skins (PLAN 10e T142, Shared/Skins): the skin worn for the hunter's current hero
	paints torso and arms its colour and legs its accent (Skins.hunterPaint) and hides the
	avatar's shirt and pants while it's worn (put back when it comes off). Colour and
	material only: the head and name tag, accessories, sizes, transparency and the root
	part are never touched (#381; spec: tools/test/skins.spec.luau).

	Display Towers (T142, #384): the towers a player put on show stand on their Campsite
	(the Campsite attribute Server/Pets gives), wearing that player's tower set. Built by
	Shared/TowerLook with no range ring, never registered as towers (they never fire, take
	no hits and can't be clicked), and gone when the player leaves.

	Campsite decorations (T143c, #415): the decoration on each of the Campsite's three
	decoration spots (Decor_<i> attributes) built by Shared/Decor — inert (anchored, no
	touch, no query, no scripts or seats), on Outpost Campsites only, so never in a match.
	The Hunter's Flag wears the player's Tower flag colour; the Wanted Poster shows their
	name and best hunt (BestClear, HighestRound).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cosmetics = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Cosmetics"))
local Skins = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Skins"))
local TowerLook = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TowerLook"))
local OutpostRules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Outpost"))
local Decor = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Decor"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Outpost = require(script.Parent.Outpost)

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

local stashed: { [Player]: { Instance } } = {} -- the avatar's clothes hidden under a hunter skin
local displays: { [Player]: { Model } } = {}
local displayFolder: Folder? = nil
local decorFolder: Folder? = nil

local function isClothing(item: Instance): boolean
	return item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic")
end

local function hunterLook(player: Player): Skins.Look?
	local hero = player:GetAttribute("Hero")
	if type(hero) ~= "string" then
		return nil
	end
	return Skins.look(player:GetAttribute(Skins.attribute(Skins.slot("hunter", hero))))
end

-- Paint (or unpaint) this hunter's body for the hunter skin they wear with their hero.
local function paintHunter(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local look = hunterLook(player)
	for _, part in character:GetChildren() do
		if part:IsA("BasePart") then
			local colour: Color3?, material: Enum.Material? = nil, nil
			if look then
				colour, material = Skins.hunterPaint(part.Name, look)
			end
			local base = part:GetAttribute("SkinBaseColor")
			if colour and material then
				if typeof(base) ~= "Color3" then
					part:SetAttribute("SkinBaseColor", part.Color)
					part:SetAttribute("SkinBaseMaterial", part.Material.Name)
				end
				part.Color = colour
				part.Material = material
			elseif typeof(base) == "Color3" then
				part.Color = base
				local old = part:GetAttribute("SkinBaseMaterial")
				part.Material = if type(old) == "string" then (Enum.Material :: any)[old] else Enum.Material.Plastic
				part:SetAttribute("SkinBaseColor", nil)
				part:SetAttribute("SkinBaseMaterial", nil)
			end
		end
	end
	local hidden = stashed[player] or {}
	stashed[player] = hidden
	if look then
		for _, item in character:GetChildren() do
			if isClothing(item) then
				table.insert(hidden, item)
				item.Parent = nil
			end
		end
	else
		for _, item in hidden do
			item.Parent = character
		end
		stashed[player] = {}
	end
end

-- The Display Towers on this player's Campsite, rebuilt from their Deco_ attributes.
local function showDisplays(player: Player)
	for _, model in (displays[player] or {}) :: { Model } do
		model:Destroy()
	end
	displays[player] = {}
	local index = player:GetAttribute("Campsite")
	local root = Outpost.model()
	local sites = root and root:FindFirstChild("Campsites")
	local site = sites and type(index) == "number" and sites:FindFirstChild(`Campsite{index}`)
	local ground = site and site:FindFirstChild("Ground")
	if not ground or not ground:IsA("BasePart") then
		return
	end
	if not displayFolder then
		local folder = Instance.new("Folder")
		folder.Name = "DisplayTowers"
		folder.Parent = workspace
		displayFolder = folder
	end
	for i, spot in OutpostRules.DECO_SPOTS do
		local key = player:GetAttribute(`{Skins.DECO_PREFIX}{i}`)
		if type(key) == "string" and (Config.Towers :: any)[key] then
			local at = ground.CFrame * CFrame.new(spot + Vector3.new(0, ground.Size.Y / 2, 0))
			local model = TowerLook.build(key, 0, at.Position) -- range 0: no ring
			TowerLook.applySkin(model, Skins.look(player:GetAttribute(Skins.attribute(Skins.slot("tower", key)))))
			for _, part in model:GetDescendants() do
				if part:IsA("BasePart") then
					part.CanQuery = false
					part.CanTouch = false
				end
			end
			model.Name = `Display_{key}`
			model:SetAttribute("DisplayTower", true)
			model:SetAttribute("Owner", player.UserId)
			model.Parent = displayFolder
			table.insert(displays[player], model)
		end
	end
	if not decorFolder then
		local folder = Instance.new("Folder")
		folder.Name = "CampsiteDecor"
		folder.Parent = workspace
		decorFolder = folder
	end
	for i, spot in OutpostRules.DECOR_SPOTS do
		local key = player:GetAttribute(`{Skins.DECOR_PREFIX}{i}`)
		local look = if Skins.isDecor(key) then Skins.look(key) else nil
		if look then
			local flag = wearing(player, "towerFlag")
			local cleared = player:GetAttribute("BestClear")
			local def = if type(cleared) == "string" then (Config.Difficulties :: any)[cleared] else nil
			local model = Decor.build(key :: string, look, ground.CFrame * CFrame.new(spot + Vector3.new(0, ground.Size.Y / 2, 0)), {
				flag = if flag then Cosmetics.colour(flag) else nil,
				poster = Decor.posterText(player.DisplayName, if def then def.display else nil, player:GetAttribute("HighestRound") :: number?),
			})
			if model then
				model:SetAttribute("Owner", player.UserId)
				model.Parent = decorFolder
				table.insert(displays[player], model)
			end
		end
	end
end

local function dress(player: Player)
	local character = player.Character
	if not character then
		return
	end
	paintHunter(player)
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
			stashed[player] = {} -- a new body: its clothes are its own
			task.defer(dress, player) -- once the head and root are in
		end)
		player.CharacterAppearanceLoaded:Connect(function()
			paintHunter(player) -- clothes that arrived after the body
		end)
		player.AttributeChanged:Connect(function(name)
			if name == "Equip_hat" or name == "Equip_trail" then
				dress(player)
			elseif name == "Hero" or string.sub(name, 1, #Skins.ATTRIBUTE_PREFIX + 7) == `{Skins.ATTRIBUTE_PREFIX}hunter_` then
				paintHunter(player)
			end
			if name == "Campsite" or string.sub(name, 1, #Skins.DECO_PREFIX) == Skins.DECO_PREFIX or string.sub(name, 1, #Skins.ATTRIBUTE_PREFIX + 6) == `{Skins.ATTRIBUTE_PREFIX}tower_`
				or string.sub(name, 1, #Skins.DECOR_PREFIX) == Skins.DECOR_PREFIX or name == "BestClear" or name == "HighestRound" or name == "Equip_towerFlag" then
				showDisplays(player)
			end
		end)
		dress(player)
		showDisplays(player)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		for _, model in (displays[player] or {}) :: { Model } do
			model:Destroy()
		end
		displays[player] = nil
		stashed[player] = nil
	end)
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
