--[[
	Eggs and pets on the server (PLAN 10d T140/T141, DECISIONS #375-#379, #392/#393/#396;
	names and strings DINO_REVIEW Round 21). The rules are Shared/Pets; the saved collection
	belongs to Server/Progression (the only saved-data mutator), which this module only calls.

	REQUESTS (the "Pets" RemoteFunction), all between matches (Progression checks):
	  ("view")                  -> true, { state, now } | false, why: the Hatchery Hut's data
	  ("buy", egg)              an egg into a free incubator, for its Amber price
	  ("warm", slot)            "Warm it up": Amber per remaining minute, finishes it now
	  ("hatch", slot)           a ready egg -> a pet (rarity rolled here, on the server)
	  ("fuse", pet, rarity)     3 identical -> 1 of the next rarity
	  ("along", id | 0)         the one pet taken along into hunts (0 = none)
	  ("pen", id, on)           show it in your Hatchling Pen (3 max)
	  Studio only (StudioOnly pets): ("studioegg", egg), ("hatchnow"), ("studiopet", "<PET> <RARITY>", n)
	Server -> client: "PetDown" (text) when your pet runs back to camp.

	PETS IN PLAY (T141). The pet taken along follows its hunter as a small model (in camp and
	in matches). It is never a target: its parts can't be hit, touched or queried, and no
	dino or hunter ever aims at it. When its hunter falls in a match it "ran back to camp —
	it returns when you do": gone until the hunter respawns (so nobody has two targets,
	#378). Its one support effect works only while it is out with its hunter in a match
	(Shared/Pets.inPlay), at Effect value x its rarity, and only ever helps its own hunter
	or side — never touches an enemy hunter:
	  Fern Muncher (regen)      heals its hunter, HP per second (Server/Health.heal)
	  Frill Guard (absorb)      takes its % of the round's first dino BITE on its hunter
	                            (Server/Health's bite guard; hunter shots never reach it)
	  Shiny Snatcher (roundcash)   cash to its hunter's side for each round that side clears
	                            (Main / Battle call roundCleared)
	  Fetcher (fetch)           brings its hunter's side's Airdrop chests from its reach
	                            (Server/Airdrops; a rival's chest is never taken)
	  Honker (spotcamo)         nothing yet: the game has no hidden dinos (Director)
	A blank Effect value (the sheet today) = the effect is off.

	HATCHLING PENS. Each player gets a Campsite (Shared/Outpost.assignCampsite) shown on its
	sign; up to 3 pets from their Hatchling Pen stand in its pen.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PetRules = require(Shared:WaitForChild("Pets"))
local OutpostRules = require(Shared:WaitForChild("Outpost"))

local Progression = require(script.Parent.Progression)
local Health = require(script.Parent.Health)
local Airdrops = require(script.Parent.Airdrops)
local Economy = require(script.Parent.Economy)
local Outpost = require(script.Parent.Outpost)

local Pets = {}

-- Visuals only.
local LOOKS: { [string]: { body: Color3, size: Vector3, flies: boolean } } = {
	HONKER = { body = Color3.fromRGB(120, 150, 90), size = Vector3.new(1.4, 1.4, 2), flies = false },
	FETCHER = { body = Color3.fromRGB(150, 110, 80), size = Vector3.new(1, 0.8, 1.4), flies = true },
	FERN_MUNCHER = { body = Color3.fromRGB(90, 160, 110), size = Vector3.new(1.6, 1.4, 2.2), flies = false },
	SHINY_SNATCHER = { body = Color3.fromRGB(220, 140, 70), size = Vector3.new(1.2, 1.3, 1.8), flies = false },
	FRILL_GUARD = { body = Color3.fromRGB(200, 170, 120), size = Vector3.new(1.6, 1.3, 2.2), flies = false },
}
local RARITY_COLOURS = { -- collar colour (cosmetic, DINO_REVIEW Round 21)
	COMMON = Color3.fromRGB(170, 170, 170),
	UNCOMMON = Color3.fromRGB(90, 200, 100),
	RARE = Color3.fromRGB(80, 150, 255),
	EPIC = Color3.fromRGB(180, 100, 240),
	LEGENDARY = Color3.fromRGB(250, 200, 60),
	MYTHIC = Color3.fromRGB(240, 70, 70),
}
local LEAF = Color3.fromRGB(60, 150, 70)
local FOLLOW = Vector3.new(3, -1.6, 2.5) -- beside and behind its hunter
local REGEN_TICK = 0.5

local folder: Folder
local followers: { [Player]: Model } = {}
local biteUsed: { [Player]: boolean } = {}
local campsites: { [number]: Player } = {}
local penModels: { [Player]: { Model } } = {}
local downEvent: RemoteEvent

local function request(player: Player, action: unknown, a: unknown, b: unknown): (boolean, any)
	if action == "view" then
		return Progression.petView(player)
	end
	return Progression.petAction(player, action, a, b)
end

------------------------------------------------------------------ the model

local function block(name: string, size: Vector3, cframe: CFrame, color: Color3, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false -- never picks up a chest or trips a Touched
	p.CanQuery = false -- never hit by a ray: it can't be targeted
	p.CastShadow = false
	p.Parent = parent
	return p
end

-- A small hatchling: body, head, collar in its rarity's colour and a leaf tag (Round 21).
local function build(pet: PetRules.Pet, at: CFrame, label: boolean): Model
	local look = LOOKS[pet.kind] or LOOKS.HONKER
	local model = Instance.new("Model")
	model.Name = PetRules.name(pet)
	local s = look.size
	local body = block("Body", s, at, look.body, model)
	model.PrimaryPart = body
	local head = block("Head", Vector3.new(s.X * 0.8, s.Y * 0.7, s.Z * 0.45), at * CFrame.new(0, s.Y * 0.55, -s.Z * 0.6), look.body, model)
	block("Collar", Vector3.new(s.X * 0.85, s.Y * 0.2, s.Z * 0.15), at * CFrame.new(0, s.Y * 0.3, -s.Z * 0.42), RARITY_COLOURS[pet.rarity] or LEAF, model)
	block("LeafTag", Vector3.new(0.3, 0.4, 0.1), at * CFrame.new(0, s.Y * 0.05, -s.Z * 0.5), LEAF, model)
	if pet.kind == "HONKER" then
		block("Crest", Vector3.new(0.3, 0.3, 1.2), head.CFrame * CFrame.new(0, 0.5, 0.6) * CFrame.Angles(math.rad(30), 0, 0), look.body:Lerp(Color3.new(1, 1, 1), 0.2), model)
	elseif pet.kind == "FETCHER" then
		for _, x in { -1, 1 } do
			block("Wing", Vector3.new(1.6, 0.1, 0.8), at * CFrame.new(x * (s.X / 2 + 0.7), 0.2, 0), look.body:Lerp(Color3.new(0, 0, 0), 0.2), model)
		end
	elseif pet.kind == "FERN_MUNCHER" then
		block("Neck", Vector3.new(0.5, 1.4, 0.5), at * CFrame.new(0, s.Y * 0.9, -s.Z * 0.45), look.body, model)
	elseif pet.kind == "FRILL_GUARD" then
		block("Frill", Vector3.new(s.X * 1.4, s.Y, 0.2), head.CFrame * CFrame.new(0, 0.3, 0.4), look.body:Lerp(Color3.fromRGB(200, 90, 60), 0.4), model)
	end
	if label then
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(150, 22)
		gui.StudsOffset = Vector3.new(0, s.Y + 0.8, 0)
		gui.MaxDistance = 45
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.GothamBold
		text.TextScaled = true
		text.TextColor3 = RARITY_COLOURS[pet.rarity] or Color3.new(1, 1, 1)
		text.TextStrokeTransparency = 0.4
		text.Text = model.Name
		text.Parent = gui
		gui.Parent = body
	end
	return model
end

------------------------------------------------------------------ in play

local function aliveRoot(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function inPlay(player: Player): boolean
	return PetRules.inPlay(
		ReplicatedStorage:GetAttribute("State"),
		player:GetAttribute("InOutpost") == true,
		player:GetAttribute("Out") == true,
		aliveRoot(player) ~= nil
	)
end

-- This player's pet effect and strength while it's out with them in a match, else nil.
function Pets.effectOf(player: Player): (string?, number?)
	local pet = Progression.petAlong(player)
	if not pet or not inPlay(player) or not followers[player] then
		return nil, nil
	end
	return PetRules.strength(pet)
end

local function dropFollower(player: Player)
	local model = followers[player]
	followers[player] = nil
	if model then
		model:Destroy()
	end
end

local function placeFollower(player: Player)
	dropFollower(player)
	local pet = Progression.petAlong(player)
	local root = aliveRoot(player)
	if not pet or not root then
		return
	end
	local model = build(pet, root.CFrame * CFrame.new(FOLLOW), true)
	model.Parent = folder
	followers[player] = model
end

-- Each round cleared (Main co-op, Battle per cleared side): a Shiny Snatcher out with its
-- hunter digs up cash for that hunter's side.
function Pets.roundCleared(side: number, hunters: { Player })
	for _, hunter in hunters do
		local effect, strength = Pets.effectOf(hunter)
		local cash = if effect == "roundcash" then PetRules.roundCash(strength) else 0
		if cash > 0 then
			Economy.earnFor(side, cash)
		end
	end
end

------------------------------------------------------------------ Hatchling Pens

local function penPart(index: number): BasePart?
	local root = Outpost.model()
	local sites = root and root:FindFirstChild("Campsites")
	local site = sites and sites:FindFirstChild(`Campsite{index}`)
	local pen = site and site:FindFirstChild("HatchlingPen")
	return if pen and pen:IsA("BasePart") then pen else nil
end

local function showPen(player: Player)
	for _, m in (penModels[player] or {}) :: { Model } do
		m:Destroy()
	end
	penModels[player] = {}
	local index = player:GetAttribute("Campsite")
	local pen = if type(index) == "number" then penPart(index) else nil
	if not pen then
		return
	end
	local sign = pen:FindFirstChild("Owner")
	if not sign then
		local gui = Instance.new("BillboardGui")
		gui.Name = "Owner"
		gui.Size = UDim2.fromOffset(220, 26)
		gui.StudsOffset = Vector3.new(0, 4, 0)
		gui.MaxDistance = 70
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.GothamBold
		text.TextScaled = true
		text.TextColor3 = Color3.fromRGB(250, 236, 200)
		text.TextStrokeTransparency = 0.4
		text.Parent = gui
		gui.Parent = pen
		sign = gui
	end
	local text = (sign :: Instance):FindFirstChildOfClass("TextLabel")
	if text then
		text.Text = `{player.DisplayName}'s Hatchling Pen`
	end
	for i, pet in Progression.petPen(player) do
		local spot = pen.CFrame * CFrame.new((i - 2) * 2.2, 1, 0) * CFrame.Angles(0, math.rad(180), 0)
		local model = build(pet, spot, true)
		model.Parent = folder
		table.insert(penModels[player], model)
	end
end

local function freeCampsite(player: Player)
	for i, holder in campsites do
		if holder == player then
			campsites[i] = nil
			local pen = penPart(i)
			local sign = pen and pen:FindFirstChild("Owner")
			if sign then
				sign:Destroy()
			end
		end
	end
	for _, m in (penModels[player] or {}) :: { Model } do
		m:Destroy()
	end
	penModels[player] = nil
end

------------------------------------------------------------------ setup

local function watch(player: Player)
	local index = OutpostRules.assignCampsite(campsites)
	if index then
		campsites[index] = player
		player:SetAttribute("Campsite", index)
	end
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 10)
		task.defer(placeFollower, player)
		if humanoid and humanoid:IsA("Humanoid") then
			humanoid.Died:Connect(function()
				local pet = Progression.petAlong(player)
				local wasOut = followers[player] ~= nil and player:GetAttribute("InOutpost") ~= true
				dropFollower(player)
				if pet and wasOut then
					downEvent:FireClient(player, PetRules.downLine(pet)) -- it returns when you do
				end
			end)
		end
	end)
	player:GetAttributeChangedSignal("PetsVersion"):Connect(function()
		local model = followers[player]
		local pet = Progression.petAlong(player)
		if (model and (not pet or model.Name ~= PetRules.name(pet))) or (not model and pet) then
			placeFollower(player) -- a different pet taken along (or none)
		end
		showPen(player)
	end)
end

function Pets.init(remotes: Folder)
	local fn = Instance.new("RemoteFunction")
	fn.Name = "Pets"
	fn.OnServerInvoke = function(player: Player, action: unknown, a: unknown, b: unknown)
		local ok, success, message = pcall(request, player, action, a, b)
		if not ok then
			warn(`[Pets] {tostring(action)} from {player.Name} failed: {success}`)
			return false, "Something went wrong"
		end
		return success, message
	end
	fn.Parent = remotes
	downEvent = Instance.new("RemoteEvent")
	downEvent.Name = "PetDown" -- (text): your pet ran back to camp
	downEvent.Parent = remotes

	folder = Instance.new("Folder")
	folder.Name = "Pets"
	folder.Parent = workspace

	Health.setBiteGuard(function(player: Player, amount: number): number
		local effect, strength = Pets.effectOf(player)
		if effect ~= "absorb" then
			return amount
		end
		local left, used = PetRules.absorb(strength, amount, biteUsed[player] == true)
		biteUsed[player] = used
		return left
	end)
	Airdrops.setFetch(function(player: Player): number
		local effect, strength = Pets.effectOf(player)
		return if effect == "fetch" then PetRules.fetchReach(strength) else 0
	end)
	ReplicatedStorage:GetAttributeChangedSignal("Round"):Connect(function()
		table.clear(biteUsed) -- a Frill Guard takes one bite a round
	end)

	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		dropFollower(player)
		freeCampsite(player)
		biteUsed[player] = nil
	end)

	local sinceRegen = 0
	RunService.Heartbeat:Connect(function(dt)
		for player, model in followers do
			local root = aliveRoot(player)
			local pet = Progression.petAlong(player)
			if not root or not pet or not model.PrimaryPart then
				dropFollower(player)
				continue
			end
			local look = LOOKS[pet.kind]
			local lift = if look and look.flies then 3.5 + math.sin(os.clock() * 3) * 0.3 else 0
			local goal = root.CFrame * CFrame.new(FOLLOW + Vector3.new(0, lift, 0))
			local from = model:GetPivot()
			-- Snaps after a teleport (camp <-> match), glides otherwise.
			model:PivotTo(if (goal.Position - from.Position).Magnitude > 40 then goal else from:Lerp(goal, math.clamp(dt * 8, 0, 1)))
		end
		sinceRegen += dt
		if sinceRegen >= REGEN_TICK then
			for player in followers do
				local effect, strength = Pets.effectOf(player)
				if effect == "regen" then
					Health.heal(player, PetRules.heal(strength, sinceRegen))
				end
			end
			sinceRegen = 0
		end
	end)
end

return Pets
