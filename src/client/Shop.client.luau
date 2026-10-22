--[[
	Building and managing towers.

	Build: the Build button (or B) opens the tower list. Picking one starts
	placement: a see-through ghost follows the mouse (or the last tap), green
	where Shared/Placement says it fits and red where it doesn't. Click or tap
	to place; Q or Cancel to stop.

	Manage: walking up to a tower shows its prompt; triggering it opens a panel
	with its three upgrade paths and Sell. Paths the crossover rule
	(Shared/Upgrades) or the team's cash won't allow are greyed out.

	Hero select (Choose hero button by Start, or H): the heroes only — pick one
	for free and the screen closes. Open until the game starts (switching
	refunds upgrades), and any time for a player who hasn't picked yet.

	Upgrades (U, once you have a hero): only your hero's three paths with the
	next tier, price and what it changes (HEROES.md, Server/Hero). Same
	crossover rule as towers; prices include your mastery discount.

	Unlocks & Mastery (M, between matches): Amber, buying the heroes and
	towers you don't own yet, and each owned hero's mastery level with what the
	next level gives (Server/Progression) and its level-10 and level-15 ability
	perks (Config.MasteryPerks; the U panel lists the ones you have). Unowned towers and heroes show their
	price in the Build list and hero select.

	Hunt Board (G, home screen): drawn by HuntBoard.client, but it's one of this
	script's panel modes, so opening it closes the others and Shared/PanelRules
	closes it like them. The Profile screen (P, home screen; Profile.client, PLAN T57)
	is a mode here the same way.

	Everything here is a request. The server re-checks the spot, the distance
	and the cash with the same rules and has the final say. Prices shown come
	from Config for display only.
]]

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TextChatService = game:GetService("TextChatService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Combat = require(Shared:WaitForChild("Combat"))
local Config = require(Shared:WaitForChild("Config"))
local HeroStats = require(Shared:WaitForChild("HeroStats"))
local Pricing = require(Shared:WaitForChild("Pricing"))
local SmallPerks = require(Shared:WaitForChild("SmallPerks"))
local Theme = require(Shared:WaitForChild("Theme"))
local CUR = string.lower(Theme.Currency) -- "amber" in running text
local Placement = require(Shared:WaitForChild("Placement"))
local ShopRules = require(Shared:WaitForChild("ShopRules"))
local PanelRules = require(Shared:WaitForChild("PanelRules"))
local HuntBoard = require(Shared:WaitForChild("HuntBoard"))
local ProfileScreen = require(Shared:WaitForChild("ProfileScreen"))
local TowerLook = require(Shared:WaitForChild("TowerLook"))
local TarPit = require(Shared:WaitForChild("TarPit"))
local Path = require(Shared:WaitForChild("Path"))
local Sides = require(Shared:WaitForChild("Sides"))
local Upgrades = require(Shared:WaitForChild("Upgrades"))
local OptionPick = require(Shared:WaitForChild("OptionPick"))
local SafeArea = require(Shared:WaitForChild("SafeArea"))
local Ranger = require(Shared:WaitForChild("Ranger"))
local RangerPosts = require(Shared:WaitForChild("RangerPosts"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local request = remotes:WaitForChild("ShopRequest") :: RemoteFunction
local heroRequest = remotes:WaitForChild("HeroRequest") :: RemoteFunction
local progressRequest = remotes:WaitForChild("ProgressRequest") :: RemoteFunction

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Visuals only.
local PANEL_COLOR = Color3.fromRGB(24, 20, 34)
local BUY_COLOR = Color3.fromRGB(60, 110, 190)
local SELL_COLOR = Color3.fromRGB(190, 80, 90)
local LOCKED_COLOR = Color3.fromRGB(70, 66, 82)
local REPAIR_COLOR = Color3.fromRGB(200, 140, 60)
local TRAMPLED_COLOR = Color3.fromRGB(255, 110, 100)
local HP_BAR_CELLS = 10 -- visual only: the read-only panel's HP bar on another camp's tower (T78)
local BUILD_COLOR = Color3.fromRGB(70, 180, 110)
local TEXT = Color3.fromRGB(240, 236, 250)
local TEXT_DIM = Color3.fromRGB(150, 145, 165)
local GOOD = Color3.fromRGB(140, 240, 170)
local BAD = Color3.fromRGB(255, 120, 140)
local GHOST_OK = Color3.fromRGB(90, 230, 120)
local GHOST_BAD = Color3.fromRGB(240, 70, 80)
local GHOST_TRANSPARENCY = 0.5

------------------------------------------------------------------ layout

local gui = Instance.new("ScreenGui")
gui.Name = "StormSplitShop"
gui.ResetOnSpawn = false

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local buildButton = Instance.new("TextButton")
buildButton.Name = "Build"
buildButton.AnchorPoint = Vector2.new(1, 1)
buildButton.Position = UDim2.new(1, -24, 1, -24)
buildButton.Size = UDim2.fromOffset(140, 48)
buildButton.BackgroundColor3 = BUILD_COLOR
buildButton.Font = Enum.Font.GothamBold
buildButton.TextSize = 20
buildButton.TextColor3 = TEXT
buildButton.Text = "Build  (B)"
buildButton.Parent = gui
corner(buildButton, 8)

local HERO_COLOR = Color3.fromRGB(200, 90, 110)
-- Hero select sits with the build-phase HUD, under Start and the difficulty picker.
local heroButton = Instance.new("TextButton")
heroButton.Name = "ChooseHero"
heroButton.AnchorPoint = Vector2.new(0.5, 0)
heroButton.Position = UDim2.new(0.5, 0, 0, SafeArea.buildHud(nil).hero) -- placed under the top bar below
heroButton.Size = UDim2.fromOffset(220, SafeArea.HERO_H)
heroButton.BackgroundColor3 = HERO_COLOR
heroButton.Font = Enum.Font.GothamBold
heroButton.TextSize = 20
heroButton.TextColor3 = TEXT
heroButton.Text = "Choose hero  (H)"
heroButton.Modal = true -- build phase: free mouse in first person to click it
heroButton.Visible = false
heroButton.Parent = gui
corner(heroButton, 8)

local upgradesButton = Instance.new("TextButton")
upgradesButton.Name = "Upgrades"
upgradesButton.AnchorPoint = Vector2.new(1, 1)
upgradesButton.Position = UDim2.new(1, -24, 1, -80)
upgradesButton.Size = UDim2.fromOffset(140, 48)
upgradesButton.BackgroundColor3 = HERO_COLOR
upgradesButton.Font = Enum.Font.GothamBold
upgradesButton.TextSize = 20
upgradesButton.TextColor3 = TEXT
upgradesButton.Text = "Upgrades  (U)"
upgradesButton.Visible = false
upgradesButton.Parent = gui
corner(upgradesButton, 8)

local masteryButton = Instance.new("TextButton")
masteryButton.Name = "Mastery"
masteryButton.AnchorPoint = Vector2.new(0.5, 0)
masteryButton.Position = UDim2.new(0.5, 0, 0, SafeArea.buildHud(nil).mastery)
masteryButton.Size = UDim2.fromOffset(220, SafeArea.MASTERY_H)
masteryButton.BackgroundColor3 = Color3.fromRGB(120, 90, 200)
masteryButton.Font = Enum.Font.GothamBold
masteryButton.TextSize = 18
masteryButton.TextColor3 = TEXT
masteryButton.Text = "Unlocks & Mastery  (M)"
masteryButton.Modal = true -- only shown between matches, when the mouse is free anyway
masteryButton.Visible = false
masteryButton.Parent = gui
corner(masteryButton, 8)

-- Under the CoreGui band that eats clicks (Run 13 F13): the stack under Hud.client's Start.
do
	local function place()
		local inset = GuiService:GetGuiInset().Y
		-- In line with Start, which moves right, clear of the chat window (Run 14 F13b).
		local live = SafeArea.liveChat(TextChatService)
		local viewX = workspace.CurrentCamera.ViewportSize.X
		local hud = SafeArea.buildHud(inset)
		local x = SafeArea.centreX(viewX, SafeArea.HUD_W, inset, live)
		heroButton.Position = UDim2.new(0, x, 0, hud.hero - inset)
		masteryButton.Position = UDim2.new(0, x, 0, hud.mastery - inset)
	end
	place()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(place)
end

-- This player's mastery rewards with their hero (nil below level 1).
local function myMastery()
	local key = player:GetAttribute("Hero") or ""
	local level = player:GetAttribute(`Mastery_{key}`) or 0
	return Config.Mastery[level]
end

-- The next mastery level after `level` that says what it unlocks.
local function nextMilestone(level: number): (number?, string?)
	for l = level + 1, #Config.Mastery do
		local text = Config.Mastery[l].unlock
		if text and text ~= "" then
			return l, text
		end
	end
	return nil, nil
end

local function ownsTower(key: string): boolean
	return player:GetAttribute(`OwnsTower_{key}`) == true
end

local function ownsHero(key: string): boolean
	return player:GetAttribute(`OwnsHero_{key}`) == true
end

-- One line per ability for the hero cards. Display text only.
local ABILITY_BLURB = {
	MARK = "dart a dino so everything hits it harder",
	OVERDRIVE = "you and nearby towers fire faster",
	AIRBURST = "call a flare strike down on the track",
	HEAL = "heal yourself and hunters near you",
}
local FIRE_MODE_NAME = { semi = "semi-auto", auto = "full-auto", burst = "burst" }

local function myHero()
	return Config.Heroes[player:GetAttribute("Hero") or ""]
end

-- Picking is open until the game starts, and always for someone without a hero.
-- A spectator: this hunter's battle camp is out (Server/Battle, PLAN T77/T83).
local function spectating(): boolean
	return player:GetAttribute("Out") == true
end

local function canPickHero(): boolean
	if spectating() then
		return false
	end
	local state = ReplicatedStorage:GetAttribute("State")
	if state == "GameOver" or state == "Victory" then
		return false
	end
	return state ~= "Playing" or myHero() == nil
end

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -24)
local PANEL_WIDTH = 400 -- px, on screens wide enough
local PANEL_EDGE = 16 -- px kept clear on each side when the screen is narrower
panel.Size = UDim2.fromOffset(PANEL_WIDTH, 0)
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.BackgroundColor3 = PANEL_COLOR
panel.BackgroundTransparency = 0.1
panel.Visible = false
panel.Parent = gui
corner(panel, 10)

do
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = panel
end

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 28)
header.BackgroundTransparency = 1
header.LayoutOrder = 1
header.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, OptionPick.header(false).titleRight, 1, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = OptionPick.TITLE_MAX
-- A long title shrinks to fit its box (which ends before Back and the X, OptionPick.header),
-- then is cut with "…" — never under the buttons (Run 8 F9).
title.TextScaled = true
title.TextWrapped = false
title.TextTruncate = Enum.TextTruncate.AtEnd
title.TextColor3 = TEXT
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header
do
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = OptionPick.TITLE_MAX
	fit.MinTextSize = OptionPick.TITLE_MIN
	fit.Parent = title
end

-- Back from the A/B/C pick to the panel (PLAN T112): in the header beside the X, outside
-- the scroll, shown only while a pick is open.
local backButton = Instance.new("TextButton")
backButton.Name = "Back"
backButton.AnchorPoint = Vector2.new(1, 0)
backButton.Position = UDim2.new(1, OptionPick.header(true).backRight, 0, 0)
backButton.Size = UDim2.fromOffset(OptionPick.BACK_W, OptionPick.HEADER)
backButton.BackgroundColor3 = LOCKED_COLOR
backButton.Font = Enum.Font.GothamBold
backButton.TextSize = 14
backButton.TextColor3 = TEXT
backButton.Text = OptionPick.BACK
backButton.Visible = false
backButton.Parent = header
corner(backButton, 6)

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, 0, 0, 0)
closeButton.Size = UDim2.fromOffset(OptionPick.CLOSE_W, OptionPick.HEADER)
closeButton.BackgroundColor3 = LOCKED_COLOR
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.TextColor3 = TEXT
closeButton.Text = "X"
-- Modal: while the panel is showing, the mouse is free in first person so its
-- buttons can be clicked.
closeButton.Modal = true
closeButton.Parent = header
corner(closeButton, 6)

-- The rows scroll inside a box capped at OptionPick.LIST_MAX_SCREEN of the screen height,
-- so however many rows a panel has (Unlocks & Mastery has a dozen), its header
-- and the X button always stay on screen. A panel you can't close leaves the
-- mouse unlocked and the game unplayable.

local list = Instance.new("ScrollingFrame")
list.Name = "List"
list.Size = UDim2.new(1, 0, 0, 0)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.ScrollingDirection = Enum.ScrollingDirection.Y
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.LayoutOrder = 2
list.Parent = panel

-- The whole panel scales down only for an A/B/C pick on a short window (OptionPick.layout).
local panelScale = Instance.new("UIScale")
panelScale.Parent = panel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = list

-- The A/B/C cards (PLAN T112): kept across renders like the rows (PLAYTEST F3), so a
-- tap during a cash re-render still lands. A grid: three across, or one per row when
-- OptionPick.layout stacks them.
local cardsFrame = Instance.new("Frame")
cardsFrame.Name = "Cards"
cardsFrame.BackgroundTransparency = 1
cardsFrame.Size = UDim2.new(1, 0, 0, 0)
cardsFrame.LayoutOrder = -100
cardsFrame.Visible = false
cardsFrame.Parent = list
local cardsGrid = Instance.new("UIGridLayout")
cardsGrid.CellPadding = UDim2.fromOffset(OptionPick.CARD_GAP, OptionPick.CARD_GAP)
cardsGrid.SortOrder = Enum.SortOrder.LayoutOrder
cardsGrid.Parent = cardsFrame
local cardButtons: { TextButton } = {}
local cardHandlers: { [TextButton]: (() -> ())? } = {}
for i = 1, #Upgrades.LETTERS do
	local card = Instance.new("TextButton")
	card.Name = `Card{i}`
	card.LayoutOrder = i
	card.RichText = true
	card.Font = Enum.Font.Gotham
	card.TextSize = 15
	card.TextColor3 = TEXT
	card.TextWrapped = true
	card.TextXAlignment = Enum.TextXAlignment.Left
	card.TextYAlignment = Enum.TextYAlignment.Top
	card.Visible = false
	corner(card, 8)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = 3
	stroke.Color = TEXT
	stroke.Enabled = false
	stroke.Parent = card
	card.Activated:Connect(function()
		local handler = cardHandlers[card]
		if handler then
			handler()
		end
	end)
	card.Parent = cardsFrame
	cardButtons[i] = card
end

-- The confirm button sits under the scroll, so it's always in reach (PLAN T112).
local confirmButton = Instance.new("TextButton")
confirmButton.Name = "Confirm"
confirmButton.Size = UDim2.new(1, 0, 0, OptionPick.CONFIRM)
confirmButton.Font = Enum.Font.GothamBold
confirmButton.TextSize = 17
confirmButton.TextColor3 = TEXT
confirmButton.BackgroundColor3 = BUY_COLOR
confirmButton.LayoutOrder = 3
confirmButton.Visible = false
confirmButton.Parent = panel
corner(confirmButton, 8)
local confirmHandler: (() -> ())? = nil
confirmButton.Activated:Connect(function()
	if confirmHandler then
		confirmHandler()
	end
end)

-- The open A/B/C pick, if any (`pickCount` cards). Every setMode closes it.
local pick: OptionPick.Pick? = nil
local pickCount = 0

-- The build-phase buttons are up: a panel keeps its top under them (PLAYTEST N20).
local function buildHud(): boolean
	return heroButton.Visible or masteryButton.Visible
end

local function fit()
	local viewport = workspace.CurrentCamera.ViewportSize
	if pick then
		local shape = OptionPick.layout(viewport.X, viewport.Y, pickCount, buildHud())
		panelScale.Scale = shape.scale
		panel.Size = UDim2.fromOffset(shape.width, 0)
		list.Size = UDim2.new(1, 0, 0, shape.listHeight)
		cardsFrame.Size = UDim2.new(1, 0, 0, shape.content)
		cardsGrid.CellSize = UDim2.fromOffset(shape.cardWidth, shape.cardHeight)
		return
	end
	panelScale.Scale = 1
	-- Capped at LIST_MAX_SCREEN of the window and kept under Choose hero / Unlocks (N20).
	list.Size = UDim2.new(1, 0, 0, OptionPick.listHeight(viewport.Y, listLayout.AbsoluteContentSize.Y, buildHud(), viewport.X))
	-- Narrow screens (a phone held upright): keep the X on screen too.
	panel.Size = UDim2.fromOffset(math.min(PANEL_WIDTH, viewport.X - PANEL_EDGE * 2), 0)
end
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fit)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
heroButton:GetPropertyChangedSignal("Visible"):Connect(fit)
masteryButton:GetPropertyChangedSignal("Visible"):Connect(fit)
fit()

local message = Instance.new("TextLabel")
message.Name = "Message"
message.Size = UDim2.new(1, 0, 0, 20)
message.BackgroundTransparency = 1
message.Font = Enum.Font.Gotham
message.TextSize = 15
message.TextColor3 = TEXT_DIM
message.TextXAlignment = Enum.TextXAlignment.Left
message.Text = ""
message.LayoutOrder = 4
message.Parent = panel

------------------------------------------------------------------ state

-- "huntBoard" is HuntBoard.client's screen, not this panel. It's a mode here so
-- that only one screen is open at a time and it closes by the same rules.
-- "profile" is Profile.client's screen (PLAN T57), owned here the same way.
type Mode = "closed" | "list" | "placing" | "manage" | "posts" | "heroPick" | "heroUpgrade" | "mastery" | "huntBoard" | "profile"

local mode: Mode = "closed"
local placingKey: string? = nil
local ghost: Model? = nil
local ghostSpot: Vector3? = nil
local ghostFits = false
local holstered: Tool? = nil -- the gun put away while placing
local managed: BasePart? = nil -- body of the tower being managed
local managedPrompt: ProximityPrompt? = nil
local managedConnections: { RBXScriptConnection } = {}
local busy = false
-- "posts" (PLAN 9j T130): a Ranger Station's posts, set by clicking its side's track.
local postsBody: BasePart? = nil
local postsPrompt: ProximityPrompt? = nil -- set when opened from the tower panel (Back returns there)
local postSetting = 1 -- the post a click sets
local postGhost: BasePart? = nil
local postSpot: Vector3? = nil
local postFits = false
local postsConnections: { RBXScriptConnection } = {}

local function escape(text: string): string
	return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

-- A hero's mastery ability perks for the Unlocks & Mastery row: one small line per
-- perk (name and text from Config.MasteryPerks), the ones this mastery level has
-- marked as owned. Starts with a line break; "" for a hero without perks.
local function perkLines(key: string, level: number): string
	local lines = ""
	for _, perk in HeroStats.perksOf(key) do
		local owned = if HeroStats.hasPerk(perk, level) then " (owned)" else ""
		lines ..= `\n<font size="13">Mastery {perk.level} perk  ·  <b>{escape(perk.name)}</b>{owned}: {escape(perk.text)}</font>`
	end
	return lines
end

-- The perks this mastery level has, as one line for the hero-upgrades panel, or nil.
local function ownedPerkLine(key: string, level: number): string?
	local names = {}
	for _, perk in HeroStats.perksAt(key, level) do
		table.insert(names, escape(perk.name))
	end
	if #names == 0 then
		return nil
	end
	return `<font size="13">{escape(Config.Heroes[key].ability)} perks: {table.concat(names, "  ·  ")}</font>`
end

local function say(text: string, color: Color3?)
	message.Text = text
	message.TextColor3 = color or TEXT_DIM
end

local LOCK_REASONS = {
	["third path"] = "locked · only two paths per tower",
	crossover = "locked · only one path past tier 2",
}

-- Ability text for what a tier newly grants (UPGRADES.md). Only fields that
-- change from the previous tier are mentioned.
-- Upgrade paths of towers placed on the track (the Tar Pit), whose damage, slow and range
-- read as the pool's.
local TAR_PATHS: { [any]: boolean } = {}
-- The Spotter Blimp's paths (PLAN 9h T125b): its drops come every lap, below the blimp.
local BLIMP_PATHS: { [any]: boolean } = {}
-- The Meteor Beacon's paths (PLAN 9i T127): its burn and misses are its craters'.
local METEOR_PATHS: { [any]: boolean } = {}
for key, def in Config.Towers do
	if def.onTrack then
		for _, path in def.paths do
			TAR_PATHS[path] = true
		end
	end
	if key == "BLIMP" then
		for _, path in def.paths do
			BLIMP_PATHS[path] = true
		end
	end
	if key == "METEOR" then
		for _, path in def.paths do
			METEOR_PATHS[path] = true
		end
	end
end

local function describeAbilities(now, nextStep, parts: { string }, tar: boolean?, blimp: boolean?, meteor: boolean?)
	local function changed(field: string, default: any): any?
		local before = if now then now[field] else nil
		local after = nextStep[field]
		if after == nil or after == default or after == before then
			return nil
		end
		return after
	end
	local function fmt(n: number): string
		return if n == math.floor(n) then tostring(n) else string.format("%.1f", n)
	end

	if changed("piercesArmor", false) then
		table.insert(parts, "pierces armour")
	end
	local shots = changed("shots", 1)
	if shots then
		table.insert(parts, `{shots} shots per trigger`)
	end
	local line = changed("lineHits", 1)
	if line then
		table.insert(parts, `hits {line} in a line`)
	end
	local armored = changed("armoredMult", 1)
	if armored then
		table.insert(parts, `x{fmt(armored)} vs armoured`)
	end
	local boss = changed("bossMult", 1)
	if boss then
		table.insert(parts, `x{fmt(boss)} vs bosses`)
	end
	local mark = changed("markPercent", 0)
	if mark then
		table.insert(parts, `marks target +{mark}% damage taken`)
	end
	local stun = changed("stunSeconds", 0)
	if stun then
		table.insert(parts, `stuns {fmt(stun)}s`)
	end
	if changed("stunsBosses", false) then
		table.insert(parts, "stuns bosses")
	end
	local knock = changed("knockback", 0)
	if knock then
		table.insert(parts, `knockback {fmt(knock)}`)
	end
	local burn = changed("burnDps", 0)
	if burn and tar then
		table.insert(parts, `the tar deals {fmt(burn)}/s to dinos in it`)
	elseif burn then
		table.insert(parts, `burning patch {fmt(burn)}/s for {fmt(nextStep.burnSeconds or 0)}s`)
	end
	local tarFire = if tar then changed("burnSeconds", 0) else nil
	if tarFire then
		table.insert(parts, `dinos walk out burning: {fmt(tarFire)}s of the tar's damage`)
	end
	local bomb = changed("bomblets", 0)
	if bomb then
		table.insert(parts, `{bomb} bomblets`)
	end
	if changed("bombletGenerations", 0) and (nextStep.bombletGenerations or 0) > 1 then
		table.insert(parts, "bomblets burst again")
	end
	local auraRate = changed("auraRatePercent", 0)
	if auraRate then
		table.insert(parts, `towers in range +{auraRate}% attack speed`)
	end
	local auraDamage = changed("auraDamagePercent", 0)
	if auraDamage then
		table.insert(parts, `towers in range +{auraDamage}% damage`)
	end
	if changed("auraPiercesArmor", false) then
		table.insert(parts, "towers in range pierce armour")
	end

	-- Storm Coil (PLAN T64): tier columns (Config), so a blank one means "unchanged"
	local arcs = changed("arcs", 0)
	if arcs then
		table.insert(parts, `chains {arcs} arcs`)
	end
	local reach = changed("arcReach", 0)
	if reach then
		table.insert(parts, `arcs reach {fmt(reach)} studs`)
	end
	local forks = changed("arcForks", 0)
	if forks and forks > 1 then
		table.insert(parts, `each arc forks in {forks}`)
	end
	if changed("arcJumps", false) then
		table.insert(parts, "arcs jump into other Storm Coils' range")
	end
	if changed("powerGrid", false) then
		table.insert(parts, `grid strike every {fmt(Config.Tuning.PowerGridEvery)}s: stronger and wider the more Storm Coils you have (one alone is weaker)`)
	end
	local static = changed("staticPercent", 0)
	if static then
		table.insert(parts, `struck dinos take +{static}% from its next strike`)
	end
	if changed("judgementBolt", false) then
		table.insert(parts, `every {fmt(Config.Tuning.JudgementBoltEvery)}s a x{fmt(Config.Tuning.JudgementBoltX)} bolt on the biggest dino: drops it up to {Config.Tuning.JudgementBoltBreaks} sizes, stuns bosses too`)
	end
	local grounding = changed("groundingEvery", 0)
	if grounding then
		table.insert(parts, `every {fmt(grounding)}s strikes down a throw aimed at a tower in range`)
	end
	local auraArc = changed("auraArcPercent", 0)
	if auraArc then
		table.insert(parts, `towers in range: each shot arcs to one more dino at {auraArc}%`)
	end

	-- Falcon Roost (PLAN T65): tier columns (Config), so a blank one means "unchanged"
	local birds = changed("birds", 0)
	if birds then
		table.insert(parts, `{birds} birds`)
	end
	local firstDive = changed("firstDiveX", 1)
	if firstDive then
		table.insert(parts, `the first dive on each dino x{fmt(firstDive)}`)
	end
	if changed("eagle", false) then
		table.insert(parts, `one giant eagle instead of the flock: x{fmt(Config.Tuning.EagleDiveX)} dives`)
	end
	if changed("murmuration", false) then
		table.insert(parts, "a swarm pecks every dino in range, no more dives")
	end
	local bossMark = changed("bossMarkPercent", 0)
	if bossMark then
		table.insert(parts, `bosses in range marked +{bossMark}% damage taken`)
	end
	local diveAura = changed("diveAuraRatePercent", 0)
	if diveAura then
		table.insert(parts, `towers in range +{diveAura}% attack speed while a bird dives`)
	end

	-- Harpoon Ballista (PLAN T66)
	if changed("skewer", false) then
		table.insert(parts, "each bolt passes through every dino in its line")
	end
	if changed("towLine", false) then
		table.insert(parts, `every {fmt(Config.Tuning.TowLineEvery)}s pulls a boss {fmt(Config.Tuning.TowLinePull)} studs back`)
	end
	if changed("chainHarpoons", false) then
		table.insert(parts, "bolts fly in chained pairs: the chain hits every dino between them")
	end

	-- Tar Pit (PLAN T67)
	local sink = changed("sinkSeconds", 0)
	if sink then
		table.insert(parts, `the smallest dinos sink in {fmt(sink)}s`)
	end
	local sinkCash = changed("sinkCash", 0)
	if sinkCash then
		table.insert(parts, `+{fmt(sinkCash)} cash for each dino that sinks`)
	end
	local sinkChest = changed("sinkChestCash", 0)
	if sinkChest then
		table.insert(parts, `each dino that sinks leaves a chest worth {fmt(sinkChest)}`)
	end
	if changed("eruption", false) then
		table.insert(parts, `every {fmt(Config.Tuning.EruptionEvery)}s a geyser drops every dino in the tar {fmt(Config.Tuning.EruptionSizes)} sizes, bosses too`)
	end
	local tracks = changed("tracksSlowPercent", 0)
	if tracks then
		table.insert(parts, `dinos walking out leave tar tracks that slow the ones behind {tracks}%`)
	end
	local totem = changed("auraSlowedPercent", 0)
	if totem then
		table.insert(parts, `towers in range +{totem}% damage against slowed dinos`)
	end

	-- Tranq Station (CHILLER)
	local slow = changed("slowPercent", 0)
	if slow and tar then
		table.insert(parts, `the tar slows {slow}%`)
	elseif slow then
		table.insert(parts, `slows {slow}%`)
	end
	local linger = changed("slowLinger", 0)
	if linger and tar then
		table.insert(parts, `dinos walking out stay slowed {fmt(linger)}s`)
	elseif linger then
		table.insert(parts, `slow lingers {fmt(linger)}s`)
	end
	if changed("slowsBosses", false) then
		table.insert(parts, "slows bosses")
	end
	local freeze = changed("freezeSeconds", 0)
	if freeze then
		table.insert(parts, `knocks out {fmt(freeze)}s every {fmt(nextStep.freezeEvery or 0)}s`)
	elseif changed("freezeEvery", 0) then
		table.insert(parts, `knocks out every {fmt(nextStep.freezeEvery)}s`)
	end
	local shards = changed("freezeDamage", 0)
	if shards then
		table.insert(parts, `darts deal {fmt(shards)} damage`)
	end
	if changed("freezeHoldsBosses", false) then
		table.insert(parts, "knocks out bosses")
	end
	local brittle = changed("brittlePercent", 0)
	if brittle then
		table.insert(parts, if blimp then `dinos under the light take +{brittle}% damage` else `sedated dinos take +{brittle}% damage`)
	end
	if changed("stripsArmor", false) then
		table.insert(parts, "sedated dinos lose their armour")
	end

	-- Quartermaster
	local income = changed("incomeMult", 1)
	if income then
		table.insert(parts, `income x{fmt(income)}`)
	end
	local interest = changed("interestPercent", 0)
	if interest then
		table.insert(parts, `{interest}% interest on banked cash (max {nextStep.interestCap or 0})`)
	end
	local chests = changed("chests", 0)
	if chests then
		table.insert(parts, `{chests} airdrop chest{if chests == 1 then "" else "s"} a round`)
	end
	local chestCash = changed("chestCash", 0)
	if chestCash then
		table.insert(parts, `chests hold {chestCash}`)
	end
	local discount = changed("discountPercent", 0)
	if discount then
		table.insert(parts, `towers in range -{discount}% upgrades`)
	end
	local refund = changed("sellRefund", 0)
	if refund then
		table.insert(parts, `towers in range sell for {math.floor(refund * 100 + 0.5)}%`)
	end

	-- Armory
	local resist = changed("resistPercent", 0)
	if resist then
		table.insert(parts, `towers and hunters in range take {resist}% less damage`)
	end
	local thorns = changed("thornsDamage", 0)
	if thorns then
		table.insert(parts, `dinos that bite in range take {fmt(thorns)} damage back`)
	end
	local stunBiters = changed("stunBitersSeconds", 0)
	if stunBiters then
		table.insert(parts, `biters are stunned {fmt(stunBiters)}s (not bosses)`)
	end
	local recoil = changed("hunterRecoilMult", 1)
	if recoil then
		table.insert(parts, `hunters in range: {math.floor((1 - recoil) * 100 + 0.5)}% less recoil`)
	end
	local reload = changed("hunterReloadMult", 1)
	if reload then
		table.insert(parts, `hunters in range: {math.floor((1 - reload) * 100 + 0.5)}% faster reload`)
	end
	local spread = changed("hunterSpreadMult", 1)
	if spread then
		table.insert(parts, `hunters in range: {math.floor((1 - spread) * 100 + 0.5)}% tighter spread`)
	end
	local hunterRate = changed("hunterRatePercent", 0)
	if hunterRate then
		table.insert(parts, `hunters in range fire {hunterRate}% faster`)
	end

	-- Field Hospital
	local heal = changed("healMult", 1)
	if heal then
		table.insert(parts, `heals {fmt(heal)}× faster`)
	end
	local reviveSpeed = changed("reviveSpeed", 0)
	if reviveSpeed then
		local pace = if reviveSpeed >= 1 then "at full speed" else `at {math.floor(reviveSpeed * 100 + 0.5)}% speed`
		table.insert(parts, `raises trampled towers in range {pace}`)
	end
	local kits = changed("medKits", 0)
	local kitHeal = changed("medKitHeal", 0)
	if kits or kitHeal then
		local when = if blimp then "below the blimp every lap" else "nearby each round"
		table.insert(parts, `{nextStep.medKits} med kits land {when}, {fmt(nextStep.medKitHeal)} HP each`)
	end
	local rescue = changed("rescueRespawnMult", 0)
	if rescue then
		table.insert(parts, `fallen hunters respawn at this tent in {math.floor(rescue * 100 + 0.5)}% of the usual time`)
	end
	local hpAura = changed("auraHpPercent", 0)
	if hpAura then
		table.insert(parts, `towers in range get +{hpAura}% max HP`)
	end
	if changed("lastStand", false) then
		table.insert(parts, "once a round, a tower in range that would be trampled stays at 1 HP")
	end

	-- Spotter Blimp (PLAN 9h T125b; Shared/Blimp)
	local speedX = changed("blimpSpeedMult", 1)
	if speedX then
		table.insert(parts, `the blimp flies x{fmt(speedX)} faster`)
	end
	if changed("bombingRun", false) then
		local what = if meteor then "a comet sweeps your track" else "bombs every dino on your track"
		table.insert(parts, `once a round {what} for x{fmt(nextStep.fieldStrikeX or 0)} a hit`)
	end

	-- Meteor Beacon (PLAN 9i T127; Shared/Meteor)
	local meteors = changed("meteors", 0)
	if meteors then
		table.insert(parts, `each strike is {meteors} smaller meteors`)
	end
	if changed("scatter", false) then
		table.insert(parts, "the meteors land all along your track")
	end
	local rain = changed("meteorEvery", 0)
	if rain then
		table.insert(parts, `one more small meteor every {fmt(rain)}s`)
	end
	local starfall = changed("starfallEvery", 0)
	if starfall then
		table.insert(parts, `every {fmt(starfall)}s, {Config.Tuning.StarfallMeteors} meteors across your track instead`)
	end
	local craterS = changed("craterSeconds", 0)
	if craterS then
		table.insert(parts, `craters last {fmt(craterS)}s`)
	end
	local amp = changed("craterAmpPercent", 0)
	if amp then
		table.insert(parts, `dinos crossing a crater take +{amp}% for 3s`)
	end
	local biteMiss = changed("biteMissPercent", 0)
	if biteMiss then
		table.insert(parts, `dinos in a crater miss {biteMiss}% of their bites`)
	end
	local craterFreeze = changed("craterFreezeSeconds", 0)
	if craterFreeze then
		table.insert(parts, `a dino entering a crater is frozen {fmt(craterFreeze)}s, once`)
	end
	if changed("fireLine", false) then
		table.insert(parts, "close craters join into one burning strip")
	end
	if changed("burnStreak", false) then
		table.insert(parts, "small meteors leave a burning streak")
	end
	if changed("extinction", false) then
		table.insert(parts, `once a round a giant meteor hits every dino on your track for x{fmt(Config.Tuning.ExtinctionX)}`)
	end
	local sideSlow = changed("sideSlowPercent", 0)
	if sideSlow then
		table.insert(parts, `after each meteor every dino on your track is slowed {sideSlow}% for {fmt(nextStep.sideSlowSeconds or 0)}s`)
	end
	local biggest = changed("biggestBreaks", 0)
	if biggest then
		table.insert(parts, `the biggest dino hit breaks {biggest} more sizes`)
	end

	-- Volcano Vent (PLAN 9i T128; Shared/Vent)
	local flowS = changed("flowSeconds", 0)
	if flowS then
		table.insert(parts, `the lava stays {fmt(flowS)}s`)
	end
	local flowLength = changed("flowLengthMult", 1)
	if flowLength then
		table.insert(parts, `the lava runs x{fmt(flowLength)} as far`)
	end
	if changed("burnBreaks", false) then
		table.insert(parts, "the lava's burn breaks a size a tick")
	end
	local geyser = changed("geyserEvery", 0)
	if geyser then
		table.insert(parts, `a geyser bursts every {fmt(geyser)}s between eruptions`)
	end
	local vents = changed("extraVents", 0)
	if vents then
		table.insert(parts, `{vents} small vents erupt in turn`)
	end
	if changed("lavaBombs", false) then
		table.insert(parts, `each eruption throws {Config.Tuning.LavaBombs} lava bombs at the biggest dinos`)
	end
	if changed("bossErupt", false) then
		table.insert(parts, "erupts at once when a boss comes into range")
	end
	local ash = changed("sideThrowMissPercent", 0)
	if ash then
		table.insert(parts, `after each eruption dinos on your track miss {ash}% of their throws`)
	end
	if changed("supervolcano", false) then
		table.insert(parts, "once a round your whole track floods with lava")
	end
	if changed("crust", false) then
		table.insert(parts, `the lava leaves crust that slows dinos {Config.Tuning.CrustSlow}%`)
	end
	local crustDps = changed("crustDps", 0)
	if crustDps then
		table.insert(parts, `the crust cuts dinos {fmt(crustDps)} a second`)
	end
	local maze = changed("mazeStuds", 0)
	if maze then
		table.insert(parts, `dinos crossing the crust walk {fmt(maze)} studs further`)
	end
	local frozen = changed("freezeFlowSeconds", 0)
	if frozen then
		table.insert(parts, `when the lava ends its dinos freeze {fmt(frozen)}s`)
	end
	local throwResist = changed("throwResistPercent", 0)
	if throwResist then
		table.insert(parts, `towers in range take {throwResist}% less from throws`)
	end

	-- Ranger Station (PLAN 9j T129; Shared/Ranger)
	local regen = changed("walkerRegen", 0)
	if regen then
		table.insert(parts, `rangers heal {fmt(regen)} HP a second at their posts`)
	end
	if changed("heavyRanger", false) then
		table.insert(parts, `one ranger gets a heavy rifle: x{fmt(Config.Tuning.HeavyX)}, breaks 3`)
	end
	if changed("legend", false) then
		table.insert(parts, `one ranger is the Legend: x{fmt(Config.Tuning.LegendX)} damage, x{fmt(Config.Tuning.LegendHPX)} HP, its own dart every {fmt(Config.Tuning.LegendDartEveryS)}s`)
	end
	if changed("jeep", false) then
		table.insert(parts, "the rangers drive your track in a jeep, firing as they pass")
	end
	if changed("trap", false) then
		table.insert(parts, `a trap at each post slows the first dino {Config.Tuning.TrapSlow}% for {fmt(Config.Tuning.TrapSlowS)}s`)
	end
	local trapEvery = changed("trapEvery", 0)
	if trapEvery then
		table.insert(parts, `traps spring every {fmt(trapEvery)}s`)
	end
	local trapStun = changed("trapStunSeconds", 0)
	if trapStun then
		table.insert(parts, `traps hold a dino {fmt(trapStun)}s (not bosses)`)
	end
	if changed("trapLine", false) then
		table.insert(parts, `each round {Config.Tuning.TrapLineTraps} traps are set along your whole track`)
	end
	local decoy = changed("decoySeconds", 0)
	if decoy then
		table.insert(parts, `a dino walking up to a ranger stops {fmt(decoy)}s`)
	end
	if changed("postAura", false) then
		table.insert(parts, `towers within {fmt(Config.Tuning.RangerGuardReachStuds)} studs of a post get the HP aura`)
	end
	if changed("bossRoundGuard", false) then
		table.insert(parts, "rangers can't fall while a boss is out")
	end
	local hook = changed("hookEvery", 0)
	if hook then
		table.insert(parts, `every {fmt(hook)}s lifts the smallest dino under it off the track`)
	end
	local miss = changed("throwMissPercent", 0)
	if miss then
		local where = if meteor then "in a crater" else "in the light"
		table.insert(parts, `dinos {where} miss {miss}% of their throws`)
	end
	local auraReach = changed("auraReachX", 1)
	if auraReach then
		table.insert(parts, `its damage aura reaches x{fmt(auraReach)} further`)
	end
	if changed("dinoOutlines", false) then
		table.insert(parts, "your camp sees every dino on your track through walls")
	end
	if changed("lapChests", false) then
		table.insert(parts, "a crate every lap instead of one a round")
	end
	local repairs = changed("lapRepairs", 0)
	if repairs then
		table.insert(parts, `each lap fixes {repairs} trampled tower{if repairs == 1 then "" else "s"} near its path`)
	end
	local crateHeal = changed("crateHealPercent", 0)
	if crateHeal then
		table.insert(parts, `a crate heals the nearest tower {crateHeal}% of its HP`)
	end
	local paras = changed("paratroopers", 0)
	if paras then
		table.insert(parts, `{paras} paratroopers drop and fight each round`)
	end
	if changed("airlift", false) then
		table.insert(parts, "the first tower trampled each round is lifted and fixed")
	end
end

-- "+30% damage · +15% rate · 2 shots per trigger" for going from `current`
-- to `current + 1` on a path, with the path's picks so far and the option bought.
local function describeStep(path, current: number, picks: string, option: string?): string
	local now = Upgrades.row(path, current, picks)
	local nextStep = Upgrades.row(path, current + 1, Upgrades.pickAfter(picks, current + 1, option or "A"))
	local parts = {}
	local tar = TAR_PATHS[path] == true
	describeAbilities(now, nextStep, parts, tar, BLIMP_PATHS[path] == true, METEOR_PATHS[path] == true)
	for _, stat in { { "damageMult", "damage" }, { "rateMult", "rate" }, { "targetsMult", "targets" }, { "rangeMult", if tar then "pool length" else "range" }, { "splashMult", "blast radius" } } do
		local before = if now then (now[stat[1]] or 1) else 1
		local after = nextStep[stat[1]] or 1
		local change = after / before - 1
		if math.abs(change) >= 0.005 then
			table.insert(parts, `{if change > 0 then "+" else ""}{math.floor(change * 100 + 0.5)}% {stat[2]}`)
		end
	end
	return if #parts > 0 then table.concat(parts, " · ") else path.focus
end

-- What a hero upgrade tier changes, in words (HEROES.md). Only fields that
-- differ from the previous tier are mentioned.
local function describeHeroStep(path, current: number, picks: string, option: string?): string
	local now = Upgrades.row(path, current, picks)
	local nextStep = Upgrades.row(path, current + 1, Upgrades.pickAfter(picks, current + 1, option or "A"))
	local parts = {}
	local function before(field: string, default: any): any
		return if now and now[field] ~= nil then now[field] else default
	end
	local function percent(field: string, label: string)
		local change = (nextStep[field] or 1) / before(field, 1) - 1
		if math.abs(change) >= 0.005 then
			local shown = math.floor(math.abs(change) * 100 + 0.5)
			table.insert(parts, `{if change < 0 then "-" else "+"}{shown}% {label}`)
		end
	end
	local function newly(field: string, default: any): any?
		local after = nextStep[field]
		if after == nil or after == default or after == before(field, default) then
			return nil
		end
		return after
	end

	local mode = newly("fireMode", "")
	if mode == "auto" then
		table.insert(parts, "full-auto")
	elseif mode == "burst" then
		table.insert(parts, `{nextStep.burstCount}-round burst`)
	end
	if newly("guns", 0) then
		table.insert(parts, "dual guns")
	end
	local pellets = newly("pellets", 0)
	if pellets then
		table.insert(parts, if pellets == 1 then "fires a slug" else `{pellets} pellets`)
	end
	local blasts = newly("shotsPerTrigger", 0)
	if blasts then
		table.insert(parts, `{blasts} blasts per trigger`)
	end
	local pierce = newly("pierce", 0)
	if pierce then
		table.insert(parts, `through {pierce} dinos`)
	end
	local bounces = newly("bounces", 0)
	if bounces then
		table.insert(parts, if bounces == 1 then "ricochets" else `ricochets {bounces} times`)
	end
	if newly("piercesArmor", false) then
		table.insert(parts, "pierces armour")
	end
	if newly("hitsAir", false) then
		table.insert(parts, "hits air")
	end
	if newly("scope", false) then
		table.insert(parts, "scope (right-click)")
	end
	if newly("beltFed", false) then
		table.insert(parts, "no reloading during Rally Cry")
	end
	local burn = newly("burnDps", 0)
	if burn then
		table.insert(parts, `burning ground {burn}/s`)
	end
	local ignite = newly("igniteShare", 0)
	if ignite then
		table.insert(parts, `sets dinos on fire (a {math.floor(ignite * 100 + 0.5)}%-of-shot burn tick)`)
	end
	local splash = newly("splashRadius", 0)
	if splash then
		table.insert(parts, `explodes ({splash} studs)`)
	end
	local knock = newly("knockback", 0)
	if knock then
		table.insert(parts, "knocks back")
	end
	local mark = newly("markPercent", 0)
	if mark then
		table.insert(parts, `hits mark +{mark}%`)
	end
	local marked = newly("markedDamageMult", 1)
	if marked then
		table.insert(parts, `x{marked} vs marked`)
	end
	local burst = newly("burstCount", 0)
	if burst and not mode then
		table.insert(parts, `{burst}-round burst`)
	end
	-- Tier 6 (PLAN T52; Shared/GunRules).
	local breaks = newly("sizeBreaks", 1)
	if breaks then
		table.insert(parts, `breaks {breaks} sizes`)
	end
	if newly("staggeredReload", false) then
		table.insert(parts, "the guns reload one at a time, so firing never stops")
	end
	local back = newly("ricochetReload", 0)
	if back then
		table.insert(parts, `each ricochet take-down puts {back} round back`)
	end
	if newly("burstRecoilReset", false) then
		table.insert(parts, "recoil resets between bursts")
	end
	if newly("spunUpBelt", false) then
		table.insert(parts, "no reloading while fully spun up")
	end
	if nextStep.stillSpreadMult == 0 and before("stillSpreadMult", 1) ~= 0 then
		table.insert(parts, "no spread standing still")
	end
	if nextStep.scopedSpreadMult == 0 and before("scopedSpreadMult", 1) ~= 0 then
		table.insert(parts, "no spread scoped")
	end
	local patch = newly("burnPatchReach", 0)
	if patch then
		table.insert(parts, `burning ground {patch} studs wide`)
	end
	local charges = newly("abilityCharges", 0)
	if charges and charges > 1 then
		table.insert(parts, `the ability holds {charges} charges`)
	end
	local spin = newly("spinUp", 1)
	if spin then
		table.insert(parts, `spins up to x{spin} fire rate`)
	end
	-- Field Medic.
	if newly("healRepairsTowers", false) then
		table.insert(parts, "the heal also patches up towers")
	end
	if newly("guardPercent", 0) or newly("guardSeconds", 0) then
		table.insert(parts, `everything healed takes {nextStep.guardPercent}% less damage for {nextStep.guardSeconds}s`)
	end
	if newly("slowPercent", 0) or newly("slowSeconds", 0) then
		table.insert(parts, `dinos you hit are slowed {nextStep.slowPercent}% for {nextStep.slowSeconds}s (not bosses)`)
	end
	local lock = newly("jawLockSeconds", 0)
	if lock then
		local bossLock = math.floor(lock * Config.Tuning.BossJawLockX * 10 + 0.5) / 10
		table.insert(parts, `hit dinos can't bite or shoot for {lock}s (bosses {bossLock}s)`)
	end
	local spreadLock = newly("jawLockSpread", 0)
	if spreadLock then
		table.insert(parts, `the lock spreads to dinos within {spreadLock} studs`)
	end
	percent("rateMult", "fire rate")
	percent("magazineMult", "magazine")
	percent("reloadMult", "reload time")
	percent("spreadMult", "spread")
	percent("recoilMult", "recoil")
	percent("stillRecoilMult", "recoil standing still")
	percent("rangeMult", "range")
	percent("damageMult", "damage")
	percent("abilityCooldownMult", "ability cooldown")
	percent("healMult", "heal")
	percent("healRadiusMult", "heal radius")
	return if #parts > 0 then table.concat(parts, " · ") else path.focus
end

-- Rows are reused across renders, keyed by LayoutOrder (PLAYTEST F3). Mid-round the
-- panel re-renders on every Cash and HP change; destroying the rows then meant a
-- button pressed before a re-render was gone by the release, so its click never
-- fired. A reused button keeps its press, and its one Activated connection calls
-- whatever handler the latest render gave it (nil while disabled).
local rowHandlers: { [TextButton]: (() -> ())? } = {}
local staleRows: { [number]: TextButton } = {}

local function addRow(order: number, text: string, color: Color3, enabled: boolean, onClick: (() -> ())?)
	local reused = staleRows[order]
	if reused then
		staleRows[order] = nil
		reused.BackgroundColor3 = color
		reused.BackgroundTransparency = if enabled then 0 else 0.5
		reused.AutoButtonColor = enabled
		reused.TextColor3 = if enabled then TEXT else TEXT_DIM
		reused.Text = text
		rowHandlers[reused] = if enabled then onClick else nil
		return
	end

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 48)
	button.BackgroundColor3 = color
	button.BackgroundTransparency = if enabled then 0 else 0.5
	button.AutoButtonColor = enabled
	button.RichText = true
	button.Font = Enum.Font.Gotham
	button.TextSize = 16
	button.TextColor3 = if enabled then TEXT else TEXT_DIM
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.TextWrapped = true
	button.AutomaticSize = Enum.AutomaticSize.Y -- grows past 48 for long ability text
	button.Text = text
	button.LayoutOrder = order
	corner(button, 8)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.Parent = button

	rowHandlers[button] = if enabled then onClick else nil
	button.Activated:Connect(function()
		local handler = rowHandlers[button]
		if handler then
			handler()
		end
	end)
	button.Destroying:Connect(function()
		rowHandlers[button] = nil
	end)
	button.Parent = list
end

------------------------------------------------------------------ ghost

local function mapFolder(name: string): Instance?
	local map = workspace:FindFirstChild("StormSplitMap")
	return map and map:FindFirstChild(name)
end

local function towerFolder(): Instance?
	return mapFolder("Towers")
end

local function builtPositions(): { Vector3 }
	local positions = {}
	local folder = towerFolder()
	if folder then
		for _, model in folder:GetChildren() do
			if model:IsA("Model") and model.PrimaryPart then
				table.insert(positions, Placement.ground(model.PrimaryPart.Position))
			end
		end
	end
	return positions
end

-- My side and the layout (Shared/Sides; co-op: side 1, the whole build area). The same rule
-- the server's Shop uses, from the attributes MapBuilder and Main publish.
local function mySide(): (number, Sides.Layout)
	local layout = Sides.fromAttributes(ReplicatedStorage:GetAttribute("Sides"), ReplicatedStorage:GetAttribute("SideGrid"))
	return Sides.sideOf(player:GetAttribute("Side"), layout.sides), layout
end

-- My side's track as the server builds it (MapBuilder), for a Tar Pit ghost's pool.
local trackPaths: { [string]: Path.Path } = {}
local function myTrack(): Path.Path
	local side, layout = mySide()
	local key = `{layout.sides}/{layout.grid}/{side}`
	local path = trackPaths[key]
	if not path then
		path = Path.new(Sides.waypoints(layout, side))
		trackPaths[key] = path
	end
	return path
end

-- Pools of the pits already built on one side's track, from their bodies (Server/Towers
-- publishes them).
local function builtPools(side: number): { TarPit.Pool }
	local pools = {}
	local folder = towerFolder()
	if folder then
		for _, model in folder:GetChildren() do
			local body = model:IsA("Model") and model.PrimaryPart
			local at, length = body and body:GetAttribute("PoolAt"), body and body:GetAttribute("PoolLength")
			if typeof(at) == "number" and typeof(length) == "number" and (body :: BasePart):GetAttribute("PoolSide") == side then
				table.insert(pools, { at = at, length = length })
			end
		end
	end
	return pools
end

local function characterRoot(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function destroyGhost()
	if ghost then
		ghost:Destroy()
	end
	ghost, ghostSpot, ghostFits = nil, nil, false
end

local function makeGhost(key: string)
	destroyGhost()
	local def = Config.Towers[key]
	local model = TowerLook.build(key, if def.onTrack then 0 else def.range, Vector3.zero) -- a pit shows its pool instead
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.CastShadow = false
			-- The body is the invisible hitbox when the tower has a silhouette.
			if part.Name ~= "Range" and part.Transparency < 1 then
				part.Transparency = math.max(part.Transparency, GHOST_TRANSPARENCY)
			end
		end
	end
	model.Parent = camera -- local only; never replicates
	ghost = model
end

-- Where a screen point lands on the ground, ignoring enemies, towers and us.
local function groundUnder(screenPoint: Vector2, includesInset: boolean): Vector3?
	local ray = if includesInset
		then camera:ViewportPointToRay(screenPoint.X, screenPoint.Y)
		else camera:ScreenPointToRay(screenPoint.X, screenPoint.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = {}
	for _, instance in { player.Character, ghost, postGhost, mapFolder("Enemies"), towerFolder() } do
		if instance then
			table.insert(ignore, instance)
		end
	end
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
	return hit and Placement.ground(hit.Position)
end

local function moveGhost(spot: Vector3?)
	if not ghost or not ghost.PrimaryPart then
		return
	end
	ghostSpot = spot
	if not spot then
		ghostFits = false
		ghost.Parent = nil
		return
	end
	ghost.Parent = camera

	local placingDef = if placingKey then Config.Towers[placingKey] else nil
	local side, layout = mySide()
	local trackPath = myTrack()
	local fits, reason = Placement.check(spot, builtPositions(), placingDef ~= nil and placingDef.onTrack, Sides.zone(layout, side))
	local poolAt = if placingDef and placingDef.onTrack then trackPath:closest(spot) else nil
	if fits and poolAt and placingDef then
		fits, reason = Placement.checkPool(poolAt, placingDef.range, builtPools(side))
	end
	if fits and placingDef and (placingDef.nearTrack or 0) > 0 then -- the Volcano Vent (PLAN 9i T128)
		fits, reason = Placement.checkNear(spot, placingDef.nearTrack, Sides.zone(layout, side))
	end
	local root = characterRoot()
	if fits and root then
		local offset = root.Position - spot
		if Vector2.new(offset.X, offset.Z).Magnitude > ShopRules.PlaceRange then
			fits, reason = false, "Too far from you — walk closer"
		end
	end
	ghostFits = fits

	ghost:PivotTo(CFrame.new(spot + Vector3.new(0, TowerLook.BODY_HEIGHT / 2, 0)))
	if poolAt and placingDef then
		local points = {}
		for _, d in TarPit.samples(poolAt, placingDef.range, 3) do
			table.insert(points, (trackPath:sample(math.clamp(d, 0, trackPath.length))))
		end
		TowerLook.setPool(ghost, points)
	end
	local color = if fits then GHOST_OK else GHOST_BAD
	for _, part in ghost:GetDescendants() do
		if part:IsA("BasePart") then
			part.Color = color
		end
	end
	if not busy then
		say(if fits then "Click or tap to place  ·  Q to cancel" else (reason or "Can't build here"), if fits then TEXT_DIM else BAD)
	end
end

------------------------------------------------------------------ panel

local render: () -> ()
local renderRows: () -> () -- the rows of whichever panel is open (render reuses them)

local function setMode(newMode: Mode)
	if newMode ~= "posts" then
		if postGhost then
			postGhost:Destroy()
		end
		postGhost, postSpot, postFits = nil, nil, false
		for _, connection in postsConnections do
			connection:Disconnect()
		end
		table.clear(postsConnections)
		postsBody, postsPrompt = nil, nil
	end
	if newMode ~= "placing" then
		destroyGhost()
		placingKey = nil
	end
	if newMode ~= "placing" and newMode ~= "posts" then
		-- Back from placing: gun back in hand.
		local tool = holstered
		holstered = nil
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if tool and humanoid and tool.Parent == player:FindFirstChildOfClass("Backpack") then
			humanoid:EquipTool(tool)
		end
	end
	if newMode ~= "manage" then
		for _, connection in managedConnections do
			connection:Disconnect()
		end
		table.clear(managedConnections)
		managed, managedPrompt = nil, nil
	end
	mode = newMode
	pick = nil -- every state change closes an A/B/C pick (#279)
	list.CanvasPosition = Vector2.zero -- a new panel starts scrolled to the top
	-- Hero.client: first person always, third person only while placing.
	player:SetAttribute("PanelOpen", newMode ~= "closed")
	player:SetAttribute("Placing", newMode == "placing" or newMode == "posts") -- third person while setting posts too
	player:SetAttribute("HuntBoardOpen", newMode == HuntBoard.MODE) -- HuntBoard.client shows it
	player:SetAttribute("ProfileOpen", newMode == ProfileScreen.MODE) -- Profile.client shows it
	say("")
	render()
end

local function send(action: string, a: any, b: any, remote: RemoteFunction?, c: any?): boolean
	if busy then
		return false
	end
	busy = true
	say("…")
	local ok, success, text = pcall(function()
		return (remote or request):InvokeServer(action, a, b, c)
	end)
	busy = false
	if not ok then
		say("Couldn't reach the server", BAD)
		return false
	end
	say(tostring(text), if success then GOOD else BAD)
	return success == true
end

local function startPlacing(key: string)
	-- Put the gun away so the placing click doesn't also shoot; setMode hands
	-- it back when placing ends.
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		holstered = character:FindFirstChildOfClass("Tool")
		humanoid:UnequipTools()
	end
	setMode("placing")
	placingKey = key
	makeGhost(key)
	render()
	moveGhost(groundUnder(UserInputService:GetMouseLocation(), true))
end

------------------------------------------------------------------ Ranger Station posts (PLAN 9j T130)

local startPosts: (body: BasePart, prompt: ProximityPrompt?) -> ()
local openManage: (body: BasePart, prompt: ProximityPrompt) -> ()

-- The station's posts as the server published them (Server/Towers: Posts, PostCount, PostRange).
local function postsOf(body: BasePart): ({ number }, number, number)
	local list = {}
	for at in string.gmatch(tostring(body:GetAttribute("Posts") or ""), "[^,]+") do
		table.insert(list, tonumber(at) or 0)
	end
	return list, (body:GetAttribute("PostCount") or 0) :: number, (body:GetAttribute("PostRange") or 0) :: number
end

-- The post ghost: snapped to the track point nearest the mouse, green where Shared/Ranger.checkPost
-- passes (on your track, within the station's range, not in a tar pool), red where it doesn't.
local function movePostGhost(spot: Vector3?)
	local body = postsBody
	if not body then
		return
	end
	if not postGhost then
		local part = Instance.new("Part")
		part.Name = "PostGhost"
		part.Size = Vector3.new(0.6, 3, 0.6)
		part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
		part.Material = Enum.Material.Neon
		part.Transparency = GHOST_TRANSPARENCY
		postGhost = part
	end
	local ghostPart = postGhost :: BasePart
	postSpot = spot
	if not spot then
		postFits = false
		ghostPart.Parent = nil
		return
	end
	local side, layout = mySide()
	local track = myTrack()
	local at = track:closest(spot)
	local point = track:sample(math.clamp(at, 0, track.length))
	local onTrack = Placement.check(spot, {}, true, Sides.zone(layout, side))
	local _, _, range = postsOf(body)
	local offset = point - body.Position
	local inPool = false
	for _, pool in builtPools(side) do
		inPool = inPool or TarPit.contains(at, pool.at, pool.length)
	end
	local fits, reason = Ranger.checkPost(onTrack, Vector2.new(offset.X, offset.Z).Magnitude, range, inPool)
	postFits = fits
	ghostPart.Parent = camera
	ghostPart.CFrame = CFrame.new(Placement.ground(point) + Vector3.new(0, 1.5, 0))
	ghostPart.Color = if fits then GHOST_OK else GHOST_BAD
	if not busy then
		say(RangerPosts.hint(postSetting, fits, reason), if fits then TEXT_DIM else BAD)
	end
end

-- Back (or Q): to the tower panel it was opened from, else closed.
local function postsBack()
	local body, prompt = postsBody, postsPrompt
	if body and prompt and prompt.Enabled and body:IsDescendantOf(workspace) then
		openManage(body, prompt)
	else
		setMode("closed")
	end
end

local function tryPost()
	local body, spot = postsBody, postSpot
	if busy or not body or not spot or not postFits then
		return
	end
	if send("post", body:GetAttribute("TowerId"), postSetting, nil, spot) then
		local _, n = postsOf(body)
		local nextPost = RangerPosts.advance(postSetting, n)
		if nextPost then
			postSetting = nextPost
			render()
		else
			postsBack() -- every post set
		end
	end
end

local function tryPlace()
	local key, spot = placingKey, ghostSpot
	if busy or not key or not spot then
		return
	end
	if not ghostFits then
		return -- the message already says why
	end
	if send("build", key, spot) then
		setMode("closed")
		if key == "RANGER" then
			-- A new Ranger Station: set its posts straight away (PLAN 9j T130). Its body
			-- replicates a moment later; give up quietly if it doesn't.
			task.spawn(function()
				for _ = 1, 20 do
					local folder = towerFolder()
					for _, model in if folder then folder:GetChildren() else {} do
						local body = model:IsA("Model") and model.PrimaryPart
						if body and body:GetAttribute("Tower") == "RANGER" and body:GetAttribute("OwnerId") == player.UserId
							and (body.Position - spot).Magnitude < 4 and (body:GetAttribute("PostCount") or 0) > 0 then
							if mode == "closed" then
								startPosts(body, nil)
							end
							return
						end
					end
					task.wait(0.1)
				end
			end)
		end
	end
end

render = function()
	-- Every row is stale until this render's addRow reuses it; the rest go at the end.
	table.clear(staleRows)
	for _, child in list:GetChildren() do
		if child == cardsFrame then
			continue -- the A/B/C cards are kept (shown by renderPick)
		elseif child:IsA("TextButton") and staleRows[child.LayoutOrder] == nil then
			staleRows[child.LayoutOrder] = child
		elseif child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local hadPick = pick ~= nil
	renderRows()
	for _, row in staleRows do
		row:Destroy()
	end
	table.clear(staleRows)
	-- The pick's own controls: Back, the cards and the confirm button (PLAN T112).
	local picking = pick ~= nil and mode ~= "closed"
	backButton.Visible = picking or mode == "posts"
	title.Size = UDim2.new(1, OptionPick.header(picking or mode == "posts").titleRight, 1, 0)
	cardsFrame.Visible = picking
	confirmButton.Visible = picking
	if not picking then
		pick = nil
		confirmHandler = nil
		table.clear(cardHandlers)
	end
	if hadPick ~= picking then
		list.CanvasPosition = Vector2.zero
	end
	fit()
end

-- Draw an open pick: one card per option, the chosen one outlined, and the confirm
-- button. `buy(letter)` asks the server; on success the pick closes (the attribute
-- change re-renders the panel).
local function renderPick(cards: { OptionPick.Card }, cost: number, cash: number, free: boolean, buy: (string) -> ())
	local open = pick :: OptionPick.Pick
	pickCount = #cards
	for i, card in cardButtons do
		local info = cards[i]
		card.Visible = info ~= nil
		if info then
			local chosen = open.chosen == info.letter
			card.BackgroundColor3 = if chosen then BUY_COLOR else LOCKED_COLOR
			local stroke = card:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Enabled = chosen
			end
			local blurb = if info.blurb ~= "" then `\n<font size="13">{escape(info.blurb)}</font>` else ""
			card.Text = `<b>{info.letter} · {escape(info.name)}</b>{blurb}`
			cardHandlers[card] = function()
				open.chosen = info.letter
				render()
			end
		else
			cardHandlers[card] = nil
		end
	end
	local text, enabled = OptionPick.confirm(open.chosen, cost, cash, free)
	confirmButton.Text = text
	confirmButton.BackgroundColor3 = if enabled then BUY_COLOR else LOCKED_COLOR
	confirmButton.BackgroundTransparency = if enabled then 0 else 0.5
	confirmButton.AutoButtonColor = enabled
	confirmButton.TextColor3 = if enabled then TEXT else TEXT_DIM
	local letter = open.chosen
	confirmHandler = if enabled and letter then function()
		buy(letter)
	end else nil
end

renderRows = function()

	panel.Visible = mode ~= "closed" and mode ~= HuntBoard.MODE and mode ~= ProfileScreen.MODE
	title.TextColor3 = TEXT -- the tower panel turns it red for a trampled tower
	buildButton.Text = if mode == "list" or mode == "placing" then "Close  (B)" else "Build  (B)"
	local state = ReplicatedStorage:GetAttribute("State")
	local inMatch = state == "Building" or state == "Playing"
	-- The home screen (Home.client) has its own buttons for heroes and unlocks.
	-- A spectator's camp is out: no build or hero buttons (PanelRules.allowed refuses them).
	local watching = spectating()
	buildButton.Visible = inMatch and not watching
	heroButton.Visible = canPickHero() and inMatch and mode ~= "placing" and mode ~= "posts" -- a click there is for the world (#358)
	heroButton.Text = if mode == "heroPick" then "Close  (H)" else "Choose hero  (H)"
	upgradesButton.Visible = myHero() ~= nil and inMatch and not watching
	upgradesButton.Text = if mode == "heroUpgrade" then "Close  (U)" else "Upgrades  (U)"
	masteryButton.Visible = state == "Building" and not watching and mode ~= "placing" and mode ~= "posts"
	masteryButton.Text = if mode == "mastery" then "Close  (M)" else "Unlocks & Mastery  (M)"
	local cash = math.floor(ReplicatedStorage:GetAttribute(Sides.attr("Cash", (mySide()))) or 0) -- your side's cash (T76)

	if mode == "list" then
		title.Text = `Build  ·  Cash {cash}`
		for order, key in Config.TowerOrder do
			local def = Config.Towers[key]
			local name = escape(def.display)
			if ShopRules.Unreleased[key] then
				addRow(order, `<b>{name}</b>  ·  coming later`, LOCKED_COLOR, false)
			elseif not ownsTower(key) then
				addRow(order, `<b>{name}</b>  ·  unlock for {Theme.amberPrice(def.unlockCost)} {CUR} (M)\n<font size="13">{escape(def.role)}. You can still upgrade a teammate's.</font>`, LOCKED_COLOR, false)
			else
				local affordable = cash >= def.baseCost
				local text = `<b>{name}</b>  ·  {def.baseCost}\n<font size="13">{escape(def.role)}</font>`
				addRow(order, text, if affordable then BUY_COLOR else LOCKED_COLOR, affordable, function()
					startPlacing(key)
				end)
			end
		end
	elseif mode == "placing" and placingKey then
		local def = Config.Towers[placingKey]
		title.Text = `Placing {def.display}  ·  {def.baseCost}`
		addRow(1, "<b>Cancel</b>  (Q)", LOCKED_COLOR, true, function()
			setMode("list")
		end)
	elseif mode == "posts" and postsBody then
		local body = postsBody :: BasePart
		local _, n = postsOf(body)
		title.Text = `Posts  ·  {Config.Towers.RANGER.display}`
		local set = {}
		for k = 1, n do
			set[k] = true -- every post has a spot (the nearest ones until moved)
		end
		for k, row in RangerPosts.rows(n, postSetting, set) do
			if row.text == RangerPosts.DONE then
				addRow(k, `<b>{RangerPosts.DONE}</b>  (Q)`, LOCKED_COLOR, true, postsBack)
			else
				addRow(k, if row.current then `<b>{row.text}</b>` else row.text, if row.current then BUY_COLOR else PANEL_COLOR, true, function()
					postSetting = k -- tap a post to move it
					render()
				end)
			end
		end
	elseif mode == "heroPick" then
		local current = player:GetAttribute("Hero") or ""
		title.Text = "Choose your hero"
		for order, key in Config.HeroOrder do
			local hero = Config.Heroes[key]
			local chosen = key == current
			local owned = ownsHero(key)
			local blurb = ABILITY_BLURB[hero.abilityKind] or ""
			local status = if chosen then "  ·  your hero" elseif not owned then `  ·  unlock for {Theme.amberPrice(hero.unlockCost)} {CUR} (M)` else ""
			local text = `<b>{escape(hero.display)}</b>  ·  {escape(hero.role)}{status}\n<font size="13">{escape(hero.ability)}: {escape(blurb)}  ·  {FIRE_MODE_NAME[hero.fireMode] or hero.fireMode} · {hero.magazine} rounds</font>`
			addRow(order, text, if chosen then HERO_COLOR elseif owned then BUY_COLOR else LOCKED_COLOR, owned and not chosen, function()
				if send("pick", key, nil, heroRequest) then
					setMode("closed")
				end
			end)
		end
		addRow(20, `<font size="13">Free. Switch any time before Start.</font>`, PANEL_COLOR, false)
	elseif mode == "heroUpgrade" then
		local hero = myHero()
		if not hero then
			title.Text = "Choose a hero first (H)"
		else
			title.Text = `{hero.display} upgrades  ·  Cash {cash}`
			-- Mirrors Server/Hero: mastery discount, free first upgrade, crossover cap.
			local rewards = myMastery()
			local discount = if rewards then rewards.upgradeDiscountPercent else 0
			local free = player:GetAttribute("FreeUpgrade") == true
			local tiers, picks = {}, {}
			for i = 1, 3 do
				tiers[i] = player:GetAttribute(`HeroPath{i}`) or 0
				picks[i] = player:GetAttribute(`HeroPicks{i}`) or ""
			end
			local function priceOf(step): number
				return if free then 0 else math.floor(step.cost * (1 - discount / 100) + 0.5)
			end
			-- An open A/B/C pick replaces the rows until it's bought, backed out of or
			-- overtaken by a change to its path (OptionPick.stays).
			local heroKey = tostring(player:GetAttribute("Hero") or "")
			local open = pick
			if open then
				local path = hero.paths[open.pathIndex]
				local blocked = path == nil
					or Upgrades.check(tiers, open.pathIndex, Upgrades.tierCount(path), if rewards then rewards.crossoverCap else nil) ~= "ok"
				if path and OptionPick.stays(open, { owner = heroKey, tier = tiers[open.pathIndex], picks = picks[open.pathIndex], blocked = blocked }) then
					local nextTier = open.tier + 1
					local cards = OptionPick.cards(path, nextTier, open.picks)
					if #cards > 0 then
						for _, card in cards do
							if card.blurb == "" then
								card.blurb = describeHeroStep(path, open.tier, open.picks, card.letter)
							end
						end
						title.Text = `{path.id} {nextTier}  ·  pick one  ·  Cash {cash}`
						local cost = priceOf(Upgrades.row(path, nextTier, open.picks .. cards[1].letter))
						renderPick(cards, cost, cash, free, function(letter)
							send("upgrade", open.pathIndex, letter, heroRequest)
						end)
						return
					end
				end
				pick = nil
			end
			for pathIndex, path in hero.paths do
				local current = tiers[pathIndex]
				local name = escape(path.id)
				local why = Upgrades.check(tiers, pathIndex, Upgrades.tierCount(path), if rewards then rewards.crossoverCap else nil)
				-- All six tiers on one line per path (PLAN T53), so the panel never grows.
				local ladder = PanelRules.tierLadder(current, Upgrades.tierCount(path))
				if why == "maxed" then
					addRow(pathIndex, `<b>{name}</b>  ·  maxed  ·  {escape(Upgrades.row(path, current, picks[pathIndex]).name)}\n<font size="13">{ladder}</font>`, LOCKED_COLOR, false)
				elseif why ~= "ok" then
					addRow(pathIndex, `<b>{name}</b>  ·  {ladder}\n<font size="13">{LOCK_REASONS[why] or "locked"}</font>`, LOCKED_COLOR, false)
				elseif OptionPick.opens(current + 1) then
					-- Tiers 4 and 5: the row opens the A/B/C pick (PLAN T112).
					local cards = OptionPick.cards(path, current + 1, picks[pathIndex])
					local step = cards[1] and Upgrades.row(path, current + 1, picks[pathIndex] .. cards[1].letter)
					if step then
						local cost = priceOf(step)
						local affordable = cash >= cost
						local price = if free then "FREE" elseif discount > 0 then `{cost} <font size="13">(-{discount}%)</font>` else tostring(cost)
						local text = `<b>{name} {current + 1}: pick one</b>  ·  {price}\n<font size="13">{ladder}  ·  {escape(OptionPick.rowLine(cards))}</font>`
						addRow(pathIndex, text, if affordable then HERO_COLOR else LOCKED_COLOR, true, function()
							pick = { owner = heroKey, pathIndex = pathIndex, tier = current, picks = picks[pathIndex], chosen = OptionPick.initial(cards) }
							render()
						end)
					else
						addRow(pathIndex, `<b>{name}</b>  ·  {ladder}\n<font size="13">locked</font>`, LOCKED_COLOR, false)
					end
				else
					local step = Upgrades.row(path, current + 1, picks[pathIndex])
					local cost = priceOf(step)
					local affordable = cash >= cost
					local price = if free then "FREE" elseif discount > 0 then `{cost} <font size="13">(-{discount}%)</font>` else tostring(cost)
					local text = `<b>{escape(step.name)}</b>  ·  {price}\n<font size="13">{name} {ladder}  ·  {escape(describeHeroStep(path, current, picks[pathIndex], nil))}</font>`
					addRow(pathIndex, text, if affordable then HERO_COLOR else LOCKED_COLOR, affordable, function()
						send("upgrade", pathIndex, nil, heroRequest)
					end)
				end
			end
			-- Mastery perks this hunter has for the ability: one line, only if any.
			local perks = ownedPerkLine(heroKey, player:GetAttribute(`Mastery_{heroKey}`) or 0)
			if perks then
				addRow(#hero.paths + 1, perks, PANEL_COLOR, false)
			end
		end
	elseif mode == "mastery" then
		local cores = player:GetAttribute("Cores") or 0
		local status = player:GetAttribute("SaveStatus")
		title.Text = `{Theme.formatAmber(cores)} {Theme.Currency}`
		local between = ReplicatedStorage:GetAttribute("State") ~= "Playing"
		local UNLOCK_COLOR = Color3.fromRGB(70, 150, 120)
		local order = 0

		local function section(label: string)
			order += 1
			addRow(order, `<b>{label}</b>`, PANEL_COLOR, false)
		end

		-- HEROES: buy the ones you don't own; mastery for the ones you do.
		section("Heroes")
		for _, key in Config.HeroOrder do
			order += 1
			local hero = Config.Heroes[key]
			local name = escape(hero.display)
			if not ownsHero(key) then
				local affordable = between and cores >= hero.unlockCost
				addRow(order, `<b>{name}</b>  ·  unlock  ·  {Theme.amberPrice(hero.unlockCost)} {CUR}\n<font size="13">{escape(hero.role)} · {escape(hero.ability)}</font>`, if affordable then UNLOCK_COLOR else LOCKED_COLOR, affordable, function()
					send("unlock", "hero", key, progressRequest)
				end)
				continue
			end
			local level = player:GetAttribute(`Mastery_{key}`) or 0
			local nextLevel = Config.Mastery[level + 1]
			if not nextLevel then
				addRow(order, `<b>{name}</b>  ·  mastery {level}  ·  maxed{perkLines(key, level)}`, LOCKED_COLOR, false)
			else
				local milestone, reward = nextMilestone(level)
				local toward = if milestone == level + 1
					then escape(reward or "")
					elseif milestone then `toward level {milestone}: {escape(reward or "")}`
					else ""
				local affordable = between and cores >= nextLevel.coreCost
				local text = `<b>{name}</b>  ·  mastery {level} → {level + 1}  ·  {Theme.amberPrice(nextLevel.coreCost)} {CUR}\n<font size="13">{toward}</font>{perkLines(key, level)}`
				addRow(order, text, if affordable then Color3.fromRGB(120, 90, 200) else LOCKED_COLOR, affordable, function()
					send("mastery", key, nil, progressRequest)
				end)
			end
		end

		-- TOWERS: every tower that has to be bought, owned or not.
		section("Towers")
		for _, key in Config.TowerOrder do
			local def = Config.Towers[key]
			if (def.unlockCost or 0) <= 0 or ShopRules.Unreleased[key] then
				continue -- free for everyone, or not out yet (the server refuses it too)
			end
			order += 1
			local name = escape(def.display)
			if ownsTower(key) then
				addRow(order, `<b>{name}</b>  ·  owned\n<font size="13">{escape(def.role)}</font>`, LOCKED_COLOR, false)
			else
				local affordable = between and cores >= def.unlockCost
				addRow(order, `<b>{name}</b>  ·  unlock  ·  {Theme.amberPrice(def.unlockCost)} {CUR}\n<font size="13">{escape(def.role)}</font>`, if affordable then UNLOCK_COLOR else LOCKED_COLOR, affordable, function()
					send("unlock", "tower", key, progressRequest)
				end)
			end
		end

		local note = if status == "offline"
			then "Progress isn't saving right now."
			else `Clear a track to earn {Theme.Currency} (more on harder difficulties). Mastery perks boost your ability, never your gun's damage.`
		addRow(50, `<font size="13">{note}</font>`, PANEL_COLOR, false)
	elseif mode == "manage" and managed then
		local key = managed:GetAttribute("Tower") :: string
		local def = Config.Towers[key]
		local towerId = managed:GetAttribute("TowerId")
		local tiers, picks = {}, {}
		for pathIndex = 1, 3 do
			tiers[pathIndex] = managed:GetAttribute(`Path{pathIndex}`) or 0
			picks[pathIndex] = managed:GetAttribute(`Picks{pathIndex}`) or ""
		end
		local hp = (managed:GetAttribute("HP") or 0) :: number
		local maxHp = (managed:GetAttribute("MaxHP") or 0) :: number
		local trampled = managed:GetAttribute("KO") == true
		-- Another camp's tower (PLAN T78, DECISIONS #231): read-only. Name, tier, whose
		-- camp, HP bar; no upgrade, repair or sell (the server refuses them anyway).
		local towerSide = managed:GetAttribute("Side")
		if typeof(towerSide) == "number" and Sides.isEnemyTower((mySide()), towerSide) then
			local camp = ReplicatedStorage:GetAttribute(Sides.attr("Camp", towerSide))
			title.Text = `{if def then def.display else "Tower"}  ·  {tiers[1]} · {tiers[2]} · {tiers[3]}`
			if trampled then
				title.TextColor3 = TRAMPLED_COLOR
			end
			addRow(1, `<b>{escape(if typeof(camp) == "string" then camp else "Another camp")}'s tower</b>`, PANEL_COLOR, false)
			if maxHp > 0 then
				local share = math.clamp(hp / maxHp, 0, 1)
				local filled = math.floor(share * HP_BAR_CELLS + 0.5)
				local bar = string.rep("█", filled) .. string.rep("░", HP_BAR_CELLS - filled)
				addRow(2, `<font size="13">HP {bar}  {math.ceil(hp)} / {math.floor(maxHp + 0.5)}</font>`, PANEL_COLOR, false)
			elseif def and def.untouchable then
				addRow(2, `<font size="13">Can't be damaged: dinos ignore it, no repairs</font>`, PANEL_COLOR, false)
			end
			return
		end
		if trampled then
			title.Text = `Trampled — repair it  ·  {if def then def.display else "Tower"}`
			title.TextColor3 = TRAMPLED_COLOR
		else
			-- The tiers, and the picked letters once there are any (#279).
			local label = OptionPick.tierLabel(tiers, picks)
			local plain = `{tiers[1]} · {tiers[2]} · {tiers[3]}`
			title.Text = `{if def then def.display else "Tower"}  ·  {plain}{if label ~= plain then `  ·  {label}` else ""}`
		end

		-- Mirrors Server/Shop: a Supply Camp's Logistics discount (Shared/Pricing).
		local discount = managed:GetAttribute("Discount") or 0
		-- An open A/B/C pick replaces the rows until it's bought, backed out of or overtaken
		-- by a change to its path, a trampling or another tower (OptionPick.stays).
		local open = pick
		if open and def then
			local path = def.paths[open.pathIndex]
			local blocked = path == nil or trampled or Upgrades.check(tiers, open.pathIndex, Upgrades.tierCount(path)) ~= "ok"
			if path and OptionPick.stays(open, { owner = tostring(towerId), tier = tiers[open.pathIndex], picks = picks[open.pathIndex], blocked = blocked }) then
				local nextTier = open.tier + 1
				local cards = OptionPick.cards(path, nextTier, open.picks)
				if #cards > 0 then
					for _, card in cards do
						if card.blurb == "" then
							card.blurb = describeStep(path, open.tier, open.picks, card.letter)
						end
					end
					title.Text = `{def.display}  ·  {path.id} {nextTier}: pick one`
					local cost = Pricing.upgradeCost(Upgrades.row(path, nextTier, open.picks .. cards[1].letter), discount)
					renderPick(cards, cost, cash, false, function(letter)
						send("upgrade", towerId, open.pathIndex, nil, letter)
					end)
					return
				end
			end
			pick = nil
		end
		-- Health, and a repair row that keeps its slot (greyed at full HP, PLAYTEST F2). Mirrors Server/Shop:
		-- Shared/Combat's price with the Logistics discount.
		-- The tower level (DECISIONS #112): every tower shares it, so it's the match's
		-- "Level" attribute, not the tower's. No row at level 1. A row wraps, and the
		-- list scrolls under the header, so the panel still fits and X stays in reach.
		local levelLine = PanelRules.towerLevelLine(
			(ReplicatedStorage:GetAttribute("Level") or 1) :: number,
			Config.Tuning.TowerDamagePerLevel
		)
		if levelLine then
			addRow(-2, `<font size="13">{levelLine}</font>`, PANEL_COLOR, false)
		end
		if maxHp > 0 then
			addRow(-1, `<font size="13">HP {math.ceil(hp)} / {math.floor(maxHp + 0.5)}</font>`, PANEL_COLOR, false)
		elseif def and def.untouchable then
			addRow(-1, `<font size="13">Can't be damaged: dinos ignore it, no repairs</font>`, PANEL_COLOR, false)
		end
		local repairRow = PanelRules.repairRow(maxHp, hp, trampled)
		if repairRow == "full" then
			addRow(0, `<b>Repair</b>  ·  full HP`, LOCKED_COLOR, false)
		elseif repairRow == "needed" then
			local cost = Combat.repairCost((managed:GetAttribute("Spent") or 0) :: number, hp, maxHp, discount, SmallPerks.ofPlayer(player).repairCostMult)
			local affordable = cash >= cost
			local price = if discount > 0 then `{cost} <font size="13">(-{discount}%)</font>` else tostring(cost)
			addRow(0, `<b>Repair</b>  —  {price}`, if affordable then REPAIR_COLOR else LOCKED_COLOR, affordable, function()
				send("repair", towerId)
			end)
		end

		if def then
			for pathIndex, path in def.paths do
				local current = tiers[pathIndex]
				local name = escape(path.id)
				local why = Upgrades.check(tiers, pathIndex, Upgrades.tierCount(path))
				if trampled and why ~= "maxed" then
					-- Mirrors Server/Shop: no upgrades until it's repaired.
					addRow(pathIndex, `<b>{name}</b>  ·  tier {current}\n<font size="13">Repair it first</font>`, LOCKED_COLOR, false)
				elseif why == "maxed" then
					addRow(pathIndex, `<b>{name}</b>  ·  maxed  ·  {escape(Upgrades.row(path, current, picks[pathIndex]).name or "")}`, LOCKED_COLOR, false)
				elseif why ~= "ok" then
					addRow(pathIndex, `<b>{name}</b>  ·  tier {current}\n<font size="13">{LOCK_REASONS[why] or "locked"}</font>`, LOCKED_COLOR, false)
				elseif OptionPick.opens(current + 1) then
					-- Tiers 4 and 5: the row opens the A/B/C pick (PLAN T112).
					local cards = OptionPick.cards(path, current + 1, picks[pathIndex])
					local step = cards[1] and Upgrades.row(path, current + 1, picks[pathIndex] .. cards[1].letter)
					if step then
						local cost = Pricing.upgradeCost(step, discount)
						local affordable = cash >= cost
						local price = if discount > 0 then `{cost} <font size="13">(-{discount}%)</font>` else tostring(cost)
						local text = `<b>{name} {current + 1}: pick one</b>  ·  {price}\n<font size="13">{escape(OptionPick.rowLine(cards))}</font>`
						addRow(pathIndex, text, if affordable then BUY_COLOR else LOCKED_COLOR, true, function()
							pick = { owner = tostring(towerId), pathIndex = pathIndex, tier = current, picks = picks[pathIndex], chosen = OptionPick.initial(cards) }
							render()
						end)
					else
						addRow(pathIndex, `<b>{name}</b>  ·  tier {current}\n<font size="13">locked</font>`, LOCKED_COLOR, false)
					end
				else
					local step = Upgrades.row(path, current + 1, picks[pathIndex])
					local cost = Pricing.upgradeCost(step, discount)
					local affordable = cash >= cost
					local price = if discount > 0 then `{cost} <font size="13">(-{discount}%)</font>` else tostring(cost)
					local text = `<b>{escape(step.name or path.id)}</b>  ·  {price}\n<font size="13">{name} {current + 1}  ·  {escape(describeStep(path, current, picks[pathIndex], nil))}</font>`
					addRow(pathIndex, text, if affordable then BUY_COLOR else LOCKED_COLOR, affordable, function()
						send("upgrade", towerId, pathIndex)
					end)
				end
			end
		end

		-- A walker tower short of what it bought: the side's walker cap (#359, Server/Walkers.showCap).
		local capLine = PanelRules.walkerCapLine((managed:GetAttribute("WalkersOut") or 0) :: number,
			(managed:GetAttribute("WalkersWant") or 0) :: number, (managed:GetAttribute("WalkerCap") or 0) :: number)
		if capLine then
			addRow(8, `<font size="13">{capLine}</font>`, PANEL_COLOR, false)
		end

		-- A Ranger Station's posts (PLAN 9j T130).
		local postCount = (managed:GetAttribute("PostCount") or 0) :: number
		if RangerPosts.movable(key, postCount, managed:GetAttribute("UsesPosts") ~= false, true, trampled) then
			local body, prompt = managed, managedPrompt
			addRow(9, `<b>Move posts</b>  ·  {postCount} on the track`, PANEL_COLOR, true, function()
				if body then
					startPosts(body, prompt)
				end
			end)
		end

		local refundRate = managed:GetAttribute("RefundRate") or Config.Tuning.SellRefund
		-- Mirrors Server/Shop: a damaged tower refunds less its repair price.
		local spentHere = (managed:GetAttribute("Spent") or 0) :: number
		local repairPrice = Combat.repairCost(spentHere, hp, maxHp, (managed:GetAttribute("Discount") or 0) :: number)
		local refund = Pricing.sellRefund(spentHere, refundRate, repairPrice)
		local ownerId = managed:GetAttribute("OwnerId") or 0
		local ownerName = managed:GetAttribute("OwnerName") or ""
		-- Mirrors the server rule: only the builder sells, unless they've left.
		local canSell = ownerId == 0 or ownerId == player.UserId or Players:GetPlayerByUserId(ownerId) == nil
		if canSell then
			local damaged = if repairPrice > 0 then `  <font size="13">(-{repairPrice} for damage)</font>` else ""
			addRow(10, `<b>Sell</b>  for {refund}{damaged}`, SELL_COLOR, true, function()
				if send("sell", towerId) then
					setMode("closed")
				end
			end)
		else
			addRow(10, `<b>Sell</b>  ·  only {escape(ownerName)} can sell this`, LOCKED_COLOR, false)
		end
		if ownerName ~= "" then
			addRow(11, `<font size="13">Built by {escape(ownerName)}</font>`, PANEL_COLOR, false)
		end
	end
end

openManage = function(body: BasePart, prompt: ProximityPrompt)
	setMode("manage")
	managed, managedPrompt = body, prompt
	for _, name in { "Spent", "Tower", "Path1", "Path2", "Path3", "Picks1", "Picks2", "Picks3", "Discount", "RefundRate", "HP", "MaxHP", "KO", "WalkersOut", "WalkersWant", "WalkerCap" } do
		table.insert(managedConnections, body:GetAttributeChangedSignal(name):Connect(render))
	end
	table.insert(managedConnections, body.AncestryChanged:Connect(function()
		if not body:IsDescendantOf(workspace) then
			setMode("closed") -- sold, possibly by a teammate
		end
	end))
	render()
end

-- The posts mode (PLAN 9j T130): the tower panel's rows become the station's posts; clicking
-- the track sets the highlighted one. Back / Q / X, and it closes like placing does.
startPosts = function(body: BasePart, prompt: ProximityPrompt?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and not holstered then
		holstered = character:FindFirstChildOfClass("Tool") -- so the click doesn't also shoot
		humanoid:UnequipTools()
	end
	setMode("posts")
	postsBody, postsPrompt, postSetting = body, prompt, 1
	if humanoid then
		-- Taking damage closes posts mode (#350, T131 step 5).
		local last = humanoid.Health
		table.insert(postsConnections, humanoid.HealthChanged:Connect(function(health)
			if PanelRules.closesOnHurt(mode, last, health) then
				setMode("closed")
			end
			last = health
		end))
	end
	for _, name in { "Posts", "PostCount", "PostRange", "UsesPosts", "KO" } do
		table.insert(postsConnections, body:GetAttributeChangedSignal(name):Connect(function()
			local _, n = postsOf(body)
			if n <= 0 or body:GetAttribute("UsesPosts") == false or body:GetAttribute("KO") == true then
				postsBack() -- a jeep, bodyguards or a Trampled cabin: no posts to set
			else
				postSetting = math.min(postSetting, n)
				render()
			end
		end))
	end
	table.insert(postsConnections, body.AncestryChanged:Connect(function()
		if not body:IsDescendantOf(workspace) then
			setMode("closed") -- sold, possibly by a teammate
		end
	end))
	render()
	movePostGhost(groundUnder(UserInputService:GetMouseLocation(), true))
end

------------------------------------------------------------------ input

-- Open `wanted` if Shared/PanelRules allows it in the current state.
local function openIfAllowed(wanted: Mode)
	if PanelRules.allowed(wanted, ReplicatedStorage:GetAttribute("State"), myHero() ~= nil, spectating()) then
		setMode(wanted)
	end
end

local function toggleBuild()
	if mode == "list" or mode == "placing" then
		setMode("closed")
	else
		openIfAllowed("list") -- nothing to build on from the home screen
	end
end

local function toggleHeroPick()
	if mode == "heroPick" then
		setMode("closed")
	elseif canPickHero() then
		openIfAllowed("heroPick")
	end
end

local function toggleHeroUpgrade()
	if mode == "heroUpgrade" then
		setMode("closed")
	else
		openIfAllowed("heroUpgrade") -- in a match only
	end
end

buildButton.Activated:Connect(toggleBuild)
heroButton.Activated:Connect(toggleHeroPick)
upgradesButton.Activated:Connect(toggleHeroUpgrade)

local function toggleMastery()
	if mode == "mastery" then
		setMode("closed")
	else
		openIfAllowed("mastery") -- before the round starts
	end
end
masteryButton.Activated:Connect(toggleMastery)

local function toggleHuntBoard()
	if mode == HuntBoard.MODE then
		setMode("closed")
	else
		openIfAllowed(HuntBoard.MODE) -- on the home screen only
	end
end
local function toggleProfile()
	if mode == ProfileScreen.MODE then
		setMode("closed")
	else
		openIfAllowed(ProfileScreen.MODE) -- on the home screen only
	end
end
closeButton.Activated:Connect(function()
	setMode("closed")
end)
backButton.Activated:Connect(function()
	if mode == "posts" then
		postsBack()
		return
	end
	pick = nil -- back to the panel it was opened from
	render()
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return -- typing in chat, or clicking our own buttons
	end
	if input.KeyCode == Enum.KeyCode.B then
		toggleBuild()
	elseif input.KeyCode == Enum.KeyCode.H then
		toggleHeroPick()
	elseif input.KeyCode == Enum.KeyCode.M then
		toggleMastery()
	elseif input.KeyCode == Enum.KeyCode.U then
		toggleHeroUpgrade()
	elseif input.KeyCode.Name == HuntBoard.KEY then
		toggleHuntBoard()
	elseif input.KeyCode.Name == ProfileScreen.KEY then
		toggleProfile()
	elseif mode == "posts" then
		if input.KeyCode == Enum.KeyCode.Q then
			postsBack()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			tryPost()
		elseif input.UserInputType == Enum.UserInputType.Touch then
			movePostGhost(groundUnder(Vector2.new(input.Position.X, input.Position.Y), false))
			tryPost()
		end
	elseif mode == "placing" then
		if input.KeyCode == Enum.KeyCode.Q then
			setMode("list")
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			tryPlace()
		elseif input.UserInputType == Enum.UserInputType.Touch then
			moveGhost(groundUnder(Vector2.new(input.Position.X, input.Position.Y), false))
			tryPlace()
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if mode == "placing" and ghost and UserInputService.MouseEnabled then
		moveGhost(groundUnder(UserInputService:GetMouseLocation(), true))
	elseif mode == "posts" and UserInputService.MouseEnabled then
		movePostGhost(groundUnder(UserInputService:GetMouseLocation(), true))
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
	if who ~= player or mode == "placing" or mode == "posts" then
		return
	end
	local body = prompt.Parent
	if body and body:IsA("BasePart") and body:GetAttribute("TowerId") then
		openManage(body, prompt)
	end
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
	if mode == "manage" and prompt == managedPrompt then
		setMode("closed")
	end
end)

ReplicatedStorage:GetAttributeChangedSignal("Level"):Connect(function()
	if mode == "manage" then
		render() -- the tower panel's level line
	end
end)

-- Another camp's tower says "Inspect" (PLAN T83, DECISIONS #233; Shared/PanelRules.towerPrompt)
-- and opens the read-only tower panel (T78); your own camp's keeps the server's "Upgrade"
-- (and the server's refusal stays). Local only; co-op is side 1 everywhere.
local serverPromptText: { [ProximityPrompt]: string } = {}
local function labelPrompt(prompt: Instance)
	local body = prompt.Parent
	if prompt:IsA("ProximityPrompt") and body and body:GetAttribute("TowerId") then
		local text = PanelRules.towerPrompt(mySide(), body:GetAttribute("Side"), serverPromptText[prompt] or prompt.ActionText)
		if prompt.ActionText ~= text then
			prompt.ActionText = text
		end
	end
end
local function watchPrompt(prompt: Instance)
	if not prompt:IsA("ProximityPrompt") or serverPromptText[prompt] then
		return
	end
	serverPromptText[prompt] = prompt.ActionText
	prompt:GetPropertyChangedSignal("ActionText"):Connect(function()
		if prompt.ActionText ~= PanelRules.INSPECT then
			serverPromptText[prompt] = prompt.ActionText -- the server's new text ("Upgrade / Repair")
		end
		labelPrompt(prompt)
	end)
	prompt.AncestryChanged:Connect(function()
		if not prompt:IsDescendantOf(workspace) then
			serverPromptText[prompt] = nil
		end
	end)
	labelPrompt(prompt)
end
local function labelTowerPrompt(prompt: Instance)
	watchPrompt(prompt)
	labelPrompt(prompt)
end
task.spawn(function()
	local map = workspace:WaitForChild("StormSplitMap")
	local folder = map:WaitForChild("Towers")
	local function refreshPrompts()
		for _, item in folder:GetDescendants() do
			labelTowerPrompt(item)
		end
	end
	folder.DescendantAdded:Connect(function(item)
		if item:IsA("ProximityPrompt") then
			labelTowerPrompt(item)
		end
	end)
	player:GetAttributeChangedSignal("Side"):Connect(refreshPrompts)
	ReplicatedStorage:GetAttributeChangedSignal("Sides"):Connect(refreshPrompts)
	refreshPrompts()
end)

-- Your side's cash: "Cash" (co-op, side 1) or "Cash2"... (Shared/Sides.attr).
ReplicatedStorage.AttributeChanged:Connect(function(name: string)
	if name == Sides.attr("Cash", (mySide())) and (mode == "list" or mode == "manage" or mode == "heroUpgrade") then
		render()
	end
end)

-- Shared/PanelRules decides what survives a state change: only match panels,
-- only from Building into Playing. Pressing Play, the results screen and
-- going home close everything.
ReplicatedStorage:GetAttributeChangedSignal("State"):Connect(function()
	local state = ReplicatedStorage:GetAttribute("State")
	if not PanelRules.keepOnStateChange(mode, state, myHero() ~= nil, spectating()) then
		setMode("closed")
	else
		render() -- button visibility
	end
end)

player.AttributeChanged:Connect(function(name)
	if name == "Out" then
		-- Your camp just went out: build, hero and mastery panels close (PanelRules).
		if not PanelRules.allowed(mode, ReplicatedStorage:GetAttribute("State"), myHero() ~= nil, spectating()) then
			setMode("closed")
		else
			render()
		end
		return
	end
	if
		name == "Hero"
		or name == "Cores"
		or name == "FreeUpgrade"
		or string.sub(name, 1, 8) == "HeroPath"
		or string.sub(name, 1, 9) == "HeroPicks"
		or string.sub(name, 1, 8) == "Mastery_"
		or string.sub(name, 1, 4) == "Owns"
	then
		render() -- button visibility, and whichever screen is open
	end
end)

-- The home screen asks for a panel by setting this local attribute; the Hunt
-- Board's X asks for "closed".
player:GetAttributeChangedSignal("OpenPanel"):Connect(function()
	local wanted = player:GetAttribute("OpenPanel")
	if wanted == nil or wanted == "" then
		return
	end
	player:SetAttribute("OpenPanel", "")
	if wanted == "heroPick" and canPickHero() then
		openIfAllowed("heroPick")
	elseif wanted == "mastery" then
		openIfAllowed("mastery")
	elseif wanted == HuntBoard.MODE then
		toggleHuntBoard()
	elseif wanted == ProfileScreen.MODE then
		toggleProfile()
	elseif wanted == "closed" and (mode == HuntBoard.MODE or mode == ProfileScreen.MODE) then
		setMode("closed")
	end
end)

gui.DisplayOrder = 10 -- panels draw above the home screen
render()
gui.Parent = player:WaitForChild("PlayerGui")
