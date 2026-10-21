--[[
	Hunters' Outpost (PLAN 10c T138, DECISIONS #382-#384, names DINO_REVIEW Round 20): the
	walkable camp between matches, in the same place (no teleport until publishing). Layout
	and rules are Shared/Outpost; this module builds the area once and moves people in.

	Built as one self-contained model ("HuntersOutpost") + this module, so T96's lobby place
	can lift it whole: the floor and a fence ring (nobody wanders onto a track), the camp
	fire, 10 Campsites (each with its Hatchling Pen placeholder; decorations come in 10e),
	the four training stations (Raptor Dummy, Raptor Chase, Herb Kitchen, Coconut Toss;
	Server/Training owns what happens at them), the Hatchery Hut and the shop counter
	(placeholders until 10d / 10e).

	IN AND OUT. Main calls enterAll() every time the server goes back to the Lobby (results
	over, board reset: every character is new) and enter(player) for someone who belongs in
	camp during a match (a Ranked late joiner waiting for the next hunt, T105; a camp
	player who fell or reset). enter() spawns a fresh character at a camp spawn point and
	marks the Player "InOutpost" (true): third person is allowed there (Hero.client), no
	gun is handed out and no shot, swing or throw counts (Server/Hero, Server/Kit). Any
	other spawn — the match loop's — clears "InOutpost" on the spot, so Play always moves
	people to the match in first person; nothing here ever pulls a player out of a match.
	spawning(player, character) tells Main's spawn hook not to move a camp arrival to a battle
	side. Deferred CharacterAdded handlers may run before or after LoadCharacterAsync returns
	(PLAYTEST F12: the old flag was cleared on return, so the late handler took the camp
	spawn for a match spawn); Shared/Outpost.campSpawns binds the camp spawn to its
	character, so the answer is the same in either order.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local OutpostRules = require(Shared:WaitForChild("Outpost"))

local Outpost = {}

local MODEL_NAME = "HuntersOutpost"
local ATTRIBUTE = "InOutpost"

-- Visuals only.
local GRASS = Color3.fromRGB(86, 124, 64)
local DIRT = Color3.fromRGB(128, 98, 66)
local WOOD = Color3.fromRGB(120, 84, 52)
local ROPE = Color3.fromRGB(196, 170, 120)
local LEAF = Color3.fromRGB(60, 140, 70)
local TEXT = Color3.fromRGB(250, 236, 200)
local FIRE = Color3.fromRGB(255, 140, 50)
local RAPTOR = Color3.fromRGB(150, 170, 80)
local PAD = Color3.fromRGB(230, 190, 90)
local FENCE_HEIGHT = 12

local campSpawns = OutpostRules.campSpawns() -- which character is a camp arrival (F12)
local arrivals = 0
local model: Model? = nil

local function part(name: string, size: Vector3, cframe: CFrame, color: Color3, parent: Instance, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- A floating label over a prop (visual).
local function label(parent: BasePart, title: string, line: string?, height: number)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Sign"
	gui.Size = UDim2.fromOffset(240, if line then 64 else 34)
	gui.StudsOffset = Vector3.new(0, height, 0)
	gui.MaxDistance = 90
	gui.AlwaysOnTop = false
	gui.Adornee = parent
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextColor3 = TEXT
	text.TextStrokeTransparency = 0.4
	text.TextScaled = true
	text.RichText = true
	text.Text = if line then `{title}\n<font size="14">{line}</font>` else title
	text.Parent = gui
	gui.Parent = parent
end

local function at(offset: Vector3, lift: number): CFrame
	return CFrame.new(OutpostRules.CENTRE + offset + Vector3.new(0, OutpostRules.FLOOR_TOP + lift, 0))
end

-- One station's placeholder prop and its pad (Shared/Outpost.STATION_RADIUS).
local function buildStation(row: OutpostRules.Station, parent: Instance)
	local folder = Instance.new("Model")
	folder.Name = row.name
	local pad = part("Pad", Vector3.new(OutpostRules.STATION_RADIUS * 2, 0.2, OutpostRules.STATION_RADIUS * 2), at(row.offset, 0.1), PAD, folder, Enum.Material.Sand)
	pad.Shape = Enum.PartType.Cylinder
	pad.Size = Vector3.new(0.2, OutpostRules.STATION_RADIUS * 2, OutpostRules.STATION_RADIUS * 2)
	pad.CFrame = at(row.offset, 0.1) * CFrame.Angles(0, 0, math.rad(90))
	pad:SetAttribute("Station", row.key)
	local base = at(row.offset, 0)
	if row.key == "reach" then
		-- A padded raptor on a post.
		part("Post", Vector3.new(0.8, 5, 0.8), base * CFrame.new(0, 2.5, -4), WOOD, folder)
		part("Body", Vector3.new(2.4, 2.6, 3.6), base * CFrame.new(0, 5.5, -4), RAPTOR, folder, Enum.Material.Fabric)
		part("Head", Vector3.new(1.6, 1.4, 2), base * CFrame.new(0, 7.2, -2.6), RAPTOR, folder, Enum.Material.Fabric)
		part("Padding", Vector3.new(2.6, 1, 3.8), base * CFrame.new(0, 4.6, -4), ROPE, folder, Enum.Material.Fabric)
	elseif row.key == "speed" then
		-- A running lane with the wind-up raptor at its end.
		part("Lane", Vector3.new(4, 0.3, 14), base * CFrame.new(0, 0.25, 0), DIRT, folder, Enum.Material.Ground)
		part("Raptor", Vector3.new(2, 2.4, 3), base * CFrame.new(0, 1.5, 6.5), RAPTOR, folder)
		part("Key", Vector3.new(0.3, 1.6, 1.6), base * CFrame.new(1.2, 2.6, 6.5), Color3.fromRGB(200, 200, 210), folder, Enum.Material.Metal)
	elseif row.key == "health" then
		-- A table with a pot of fern smoothie.
		part("Table", Vector3.new(6, 0.5, 3), base * CFrame.new(0, 3, -4), WOOD, folder, Enum.Material.Wood)
		for _, x in { -2.5, 2.5 } do
			part("Leg", Vector3.new(0.5, 3, 0.5), base * CFrame.new(x, 1.5, -4), WOOD, folder, Enum.Material.Wood)
		end
		local pot = part("Pot", Vector3.new(2, 2, 2), base * CFrame.new(-1, 4.25, -4), Color3.fromRGB(80, 80, 90), folder, Enum.Material.Metal)
		pot.Shape = Enum.PartType.Ball
		part("Ferns", Vector3.new(1.6, 1.2, 1.2), base * CFrame.new(1.6, 3.85, -4), LEAF, folder, Enum.Material.Grass)
	else
		-- A throwing line and far targets.
		part("Line", Vector3.new(8, 0.25, 0.5), base * CFrame.new(0, 0.2, 2), Color3.new(1, 1, 1), folder)
		for i, z in { -10, -16, -22 } do
			local target = part("Target", Vector3.new(0.4, 3, 3), base * CFrame.new((i - 2) * 3, 2, z) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(220, 70, 60), folder)
			target.Shape = Enum.PartType.Cylinder
		end
		local nut = part("Coconut", Vector3.new(1.2, 1.2, 1.2), base * CFrame.new(-3, 0.8, 3), Color3.fromRGB(110, 76, 44), folder)
		nut.Shape = Enum.PartType.Ball
	end
	label(pad, `{row.name} — {row.stat}`, row.line, 7)
	folder.Parent = parent
end

local function build(): Model
	local root = Instance.new("Model")
	root.Name = MODEL_NAME
	local centre = OutpostRules.CENTRE
	do -- floor, fence ring, camp fire
		local floor = part("Floor", Vector3.new(1, OutpostRules.RADIUS * 2, OutpostRules.RADIUS * 2), CFrame.new(centre + Vector3.new(0, OutpostRules.FLOOR_TOP - 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), GRASS, root, Enum.Material.Grass)
		floor.Shape = Enum.PartType.Cylinder
		local posts = 48
		for i = 1, posts do
			local angle = i * 2 * math.pi / posts
			local edge = centre + Vector3.new(math.cos(angle), 0, math.sin(angle)) * (OutpostRules.RADIUS - 1)
			part("FencePost", Vector3.new(1, 5, 1), CFrame.new(edge + Vector3.new(0, 2.5, 0)), WOOD, root, Enum.Material.Wood)
			-- An invisible wall between posts keeps everyone inside (no falling off, no walking onto a track).
			local chord = 2 * (OutpostRules.RADIUS - 1) * math.sin(math.pi / posts) + 1
			local mid = centre + Vector3.new(math.cos(angle + math.pi / posts), 0, math.sin(angle + math.pi / posts)) * (OutpostRules.RADIUS - 1)
			local wall = part("Fence", Vector3.new(chord, FENCE_HEIGHT, 1), CFrame.lookAt(mid + Vector3.new(0, FENCE_HEIGHT / 2, 0), centre + Vector3.new(0, FENCE_HEIGHT / 2, 0)), WOOD, root)
			wall.Transparency = 1
			part("Rail", Vector3.new(chord, 0.4, 0.4), CFrame.lookAt(mid + Vector3.new(0, 3.5, 0), centre + Vector3.new(0, 3.5, 0)), ROPE, root).CanCollide = false
		end
		local fire = part("CampFire", Vector3.new(3, 1.2, 3), CFrame.new(centre + Vector3.new(0, 0.7, 12)), FIRE, root, Enum.Material.Neon)
		fire.Shape = Enum.PartType.Ball
		local light = Instance.new("PointLight")
		light.Color = FIRE
		light.Range = 24
		light.Parent = fire
		label(fire, OutpostRules.NAME, nil, 8)
	end
	do -- the four training stations
		local stations = Instance.new("Folder")
		stations.Name = "Stations"
		stations.Parent = root
		for _, row in OutpostRules.STATIONS do
			buildStation(row, stations)
		end
	end
	do -- Campsites, each with its Hatchling Pen placeholder (pets: 10d; decorations: 10e)
		local sites = Instance.new("Folder")
		sites.Name = "Campsites"
		sites.Parent = root
		local size = OutpostRules.CAMPSITE_SIZE
		for i = 1, OutpostRules.CAMPSITES do
			local spot = OutpostRules.campsite(i) :: Vector3
			local facing = CFrame.lookAt(spot, Vector3.new(centre.X, spot.Y, centre.Z))
			local site = Instance.new("Model")
			site.Name = `Campsite{i}`
			local ground = part("Ground", Vector3.new(size, 0.2, size), facing + Vector3.new(0, OutpostRules.FLOOR_TOP + 0.1, 0), DIRT, site, Enum.Material.Ground)
			ground:SetAttribute("Campsite", i)
			local pen = part("HatchlingPen", Vector3.new(7, 0.25, 7), facing * CFrame.new(-6, OutpostRules.FLOOR_TOP + 0.3, 5), Color3.fromRGB(150, 120, 80), site, Enum.Material.WoodPlanks)
			for _, corner in { Vector3.new(-3.5, 0, -3.5), Vector3.new(3.5, 0, -3.5), Vector3.new(-3.5, 0, 3.5), Vector3.new(3.5, 0, 3.5) } do
				part("PenPost", Vector3.new(0.5, 2, 0.5), pen.CFrame * CFrame.new(corner + Vector3.new(0, 1, 0)), WOOD, site, Enum.Material.Wood)
			end
			label(ground, `Campsite {i}`, "Hatchling Pen — pets coming soon", 5)
			site.Parent = sites
		end
	end
	do -- Hatchery Hut (10d: Client/Pets opens it with E nearby) and shop counter placeholder (10e)
		local hut = part("HatcheryHut", Vector3.new(10, 7, 8), at(OutpostRules.HATCHERY_HUT, 3.5), Color3.fromRGB(170, 130, 80), root, Enum.Material.WoodPlanks)
		part("HutRoof", Vector3.new(12, 1, 10), at(OutpostRules.HATCHERY_HUT, 7.5), LEAF, root, Enum.Material.Grass)
		label(hut, "Hatchery Hut", "Eggs and pets — press E here", 6)
		local counter = part("ShopCounter", Vector3.new(8, 3, 2.5), at(OutpostRules.SHOP, 1.5), WOOD, root, Enum.Material.Wood)
		label(counter, "Shop", "Coming soon", 4)
	end
	root.Parent = workspace
	return root
end

------------------------------------------------------------------ in and out

-- Is this character a camp arrival (Main's spawn hook: never move it to a battle side)?
-- Same answer whichever CharacterAdded handler asks first (Shared/Outpost.campSpawns, F12).
function Outpost.spawning(player: Player, character: Model?): boolean
	return campSpawns:pending(player) or (character ~= nil and campSpawns:arrived(player, character))
end

-- A character reported in (from enter() or a deferred CharacterAdded, either order): the
-- camp character marks the player in camp; anything else is a match spawn: out of camp.
local function settle(player: Player, character: Model): boolean
	local camp = campSpawns:arrived(player, character)
	player:SetAttribute(ATTRIBUTE, camp)
	return camp
end

-- A fresh character in camp (third person allowed, no gun, no combat).
function Outpost.enter(player: Player)
	if not player.Parent or not campSpawns:expect(player) then
		return
	end
	player:SetAttribute(ATTRIBUTE, true)
	task.spawn(function()
		local ok, err = pcall(function()
			player:LoadCharacterAsync()
		end)
		local character = player.Character
		if not ok then
			campSpawns:failed(player)
			warn(`[Outpost] Couldn't spawn {player.Name} in camp: {err}`)
		elseif character and settle(player, character) then
			arrivals += 1
			character:PivotTo(CFrame.new(OutpostRules.spawnPoint(arrivals)))
		end
	end)
end

function Outpost.enterAll()
	for _, player in Players:GetPlayers() do
		Outpost.enter(player)
	end
end

function Outpost.inCamp(player: Player): boolean
	return player:GetAttribute(ATTRIBUTE) == true
end

function Outpost.init()
	model = build()
	local function watch(player: Player)
		player.CharacterAdded:Connect(function(character)
			settle(player, character) -- a match spawn clears the flag; a camp arrival keeps it
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		campSpawns:forget(player)
	end)
end

function Outpost.model(): Model?
	return model
end

return Outpost
