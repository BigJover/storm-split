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
local Upgrades = require(Shared:WaitForChild("Upgrades"))

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
heroButton.Position = UDim2.new(0.5, 0, 0, 156)
heroButton.Size = UDim2.fromOffset(220, 44)
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
masteryButton.Position = UDim2.new(0.5, 0, 0, 206)
masteryButton.Size = UDim2.fromOffset(220, 40)
masteryButton.BackgroundColor3 = Color3.fromRGB(120, 90, 200)
masteryButton.Font = Enum.Font.GothamBold
masteryButton.TextSize = 18
masteryButton.TextColor3 = TEXT
masteryButton.Text = "Unlocks & Mastery  (M)"
masteryButton.Modal = true -- only shown between matches, when the mouse is free anyway
masteryButton.Visible = false
masteryButton.Parent = gui
corner(masteryButton, 8)

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
local function canPickHero(): boolean
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
title.Size = UDim2.new(1, -36, 1, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = TEXT
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, 0, 0, 0)
closeButton.Size = UDim2.fromOffset(28, 28)
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

-- The rows scroll inside a box capped at LIST_MAX_SCREEN of the screen height,
-- so however many rows a panel has (Unlocks & Mastery has a dozen), its header
-- and the X button always stay on screen. A panel you can't close leaves the
-- mouse unlocked and the game unplayable.
local LIST_MAX_SCREEN = 0.55

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

do
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local function fit()
		local viewport = workspace.CurrentCamera.ViewportSize
		local content = layout.AbsoluteContentSize.Y
		local cap = math.floor(viewport.Y * LIST_MAX_SCREEN)
		list.Size = UDim2.new(1, 0, 0, math.min(content, cap))
		-- Narrow screens (a phone held upright): keep the X on screen too.
		panel.Size = UDim2.fromOffset(math.min(PANEL_WIDTH, viewport.X - PANEL_EDGE * 2), 0)
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fit)
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	fit()
end

local message = Instance.new("TextLabel")
message.Name = "Message"
message.Size = UDim2.new(1, 0, 0, 20)
message.BackgroundTransparency = 1
message.Font = Enum.Font.Gotham
message.TextSize = 15
message.TextColor3 = TEXT_DIM
message.TextXAlignment = Enum.TextXAlignment.Left
message.Text = ""
message.LayoutOrder = 3
message.Parent = panel

------------------------------------------------------------------ state

-- "huntBoard" is HuntBoard.client's screen, not this panel. It's a mode here so
-- that only one screen is open at a time and it closes by the same rules.
-- "profile" is Profile.client's screen (PLAN T57), owned here the same way.
type Mode = "closed" | "list" | "placing" | "manage" | "heroPick" | "heroUpgrade" | "mastery" | "huntBoard" | "profile"

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
local function describeAbilities(now, nextStep, parts: { string })
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
	if burn then
		table.insert(parts, `burning patch {fmt(burn)}/s for {fmt(nextStep.burnSeconds or 0)}s`)
	end
	local bomb = changed("bomblets", 0)
	if bomb then
		table.insert(parts, `{bomb} bomblets`)
	end
	if changed("bombletGenerations", 0) and (nextStep.bombletGenerations or 0) > 1 then
		table.insert(parts, "bomblets split again")
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

	-- Tranq Station (CHILLER)
	local slow = changed("slowPercent", 0)
	if slow then
		table.insert(parts, `slows {slow}%`)
	end
	local linger = changed("slowLinger", 0)
	if linger then
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
		table.insert(parts, `sedated dinos take +{brittle}% damage`)
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
		table.insert(parts, `{nextStep.medKits} med kits land nearby each round, {fmt(nextStep.medKitHeal)} HP each`)
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
end

-- "+30% damage · +15% rate · 2 shots per trigger" for going from `current`
-- to `current + 1` on a path.
local function describeStep(path, current: number): string
	local now = if current > 0 then path.tiers[current] else nil
	local nextStep = path.tiers[current + 1]
	local parts = {}
	describeAbilities(now, nextStep, parts)
	for _, stat in { { "damageMult", "damage" }, { "rateMult", "rate" }, { "targetsMult", "targets" }, { "rangeMult", "range" }, { "splashMult", "blast radius" } } do
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
local function describeHeroStep(path, current: number): string
	local now = if current > 0 then path.tiers[current] else nil
	local nextStep = path.tiers[current + 1]
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

local function addRow(order: number, text: string, color: Color3, enabled: boolean, onClick: (() -> ())?)
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

	if enabled and onClick then
		button.Activated:Connect(onClick)
	end
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
	local model = TowerLook.build(key, def.range, Vector3.zero)
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
	for _, instance in { player.Character, ghost, mapFolder("Enemies"), towerFolder() } do
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
	local fits, reason = Placement.check(spot, builtPositions(), placingDef ~= nil and placingDef.onTrack)
	local root = characterRoot()
	if fits and root then
		local offset = root.Position - spot
		if Vector2.new(offset.X, offset.Z).Magnitude > ShopRules.PlaceRange then
			fits, reason = false, "Too far from you — walk closer"
		end
	end
	ghostFits = fits

	ghost:PivotTo(CFrame.new(spot + Vector3.new(0, TowerLook.BODY_HEIGHT / 2, 0)))
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

local function setMode(newMode: Mode)
	if newMode ~= "placing" then
		destroyGhost()
		placingKey = nil
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
	list.CanvasPosition = Vector2.zero -- a new panel starts scrolled to the top
	-- Hero.client: first person always, third person only while placing.
	player:SetAttribute("PanelOpen", newMode ~= "closed")
	player:SetAttribute("Placing", newMode == "placing")
	player:SetAttribute("HuntBoardOpen", newMode == HuntBoard.MODE) -- HuntBoard.client shows it
	player:SetAttribute("ProfileOpen", newMode == ProfileScreen.MODE) -- Profile.client shows it
	say("")
	render()
end

local function send(action: string, a: any, b: any, remote: RemoteFunction?): boolean
	if busy then
		return false
	end
	busy = true
	say("…")
	local ok, success, text = pcall(function()
		return (remote or request):InvokeServer(action, a, b)
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
	end
end

render = function()
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	panel.Visible = mode ~= "closed" and mode ~= HuntBoard.MODE and mode ~= ProfileScreen.MODE
	title.TextColor3 = TEXT -- the tower panel turns it red for a trampled tower
	buildButton.Text = if mode == "list" or mode == "placing" then "Close  (B)" else "Build  (B)"
	local state = ReplicatedStorage:GetAttribute("State")
	local inMatch = state == "Building" or state == "Playing"
	-- The home screen (Home.client) has its own buttons for heroes and unlocks.
	buildButton.Visible = inMatch
	heroButton.Visible = canPickHero() and inMatch
	heroButton.Text = if mode == "heroPick" then "Close  (H)" else "Choose hero  (H)"
	upgradesButton.Visible = myHero() ~= nil and inMatch
	upgradesButton.Text = if mode == "heroUpgrade" then "Close  (U)" else "Upgrades  (U)"
	masteryButton.Visible = state == "Building"
	masteryButton.Text = if mode == "mastery" then "Close  (M)" else "Unlocks & Mastery  (M)"
	local cash = math.floor(ReplicatedStorage:GetAttribute("Cash") or 0)

	if mode == "list" then
		title.Text = `Build  ·  Cash {cash}`
		for order, key in Config.TowerOrder do
			local def = Config.Towers[key]
			local name = escape(def.display)
			if ShopRules.Unreleased[key] then
				addRow(order, `<b>{name}</b>  ·  coming later`, LOCKED_COLOR, false)
			elseif not ownsTower(key) then
				addRow(order, `<b>{name}</b>  ·  unlock for {def.unlockCost} {CUR} (M)\n<font size="13">{escape(def.role)}. You can still upgrade a teammate's.</font>`, LOCKED_COLOR, false)
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
	elseif mode == "heroPick" then
		local current = player:GetAttribute("Hero") or ""
		title.Text = "Choose your hero"
		for order, key in Config.HeroOrder do
			local hero = Config.Heroes[key]
			local chosen = key == current
			local owned = ownsHero(key)
			local blurb = ABILITY_BLURB[hero.abilityKind] or ""
			local status = if chosen then "  ·  your hero" elseif not owned then `  ·  unlock for {hero.unlockCost} {CUR} (M)` else ""
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
			local tiers = {}
			for i = 1, 3 do
				tiers[i] = player:GetAttribute(`HeroPath{i}`) or 0
			end
			for pathIndex, path in hero.paths do
				local current = tiers[pathIndex]
				local name = escape(path.id)
				local why = Upgrades.check(tiers, pathIndex, #path.tiers, if rewards then rewards.crossoverCap else nil)
				-- All six tiers on one line per path (PLAN T53), so the panel never grows.
				local ladder = PanelRules.tierLadder(current, #path.tiers)
				if why == "maxed" then
					addRow(pathIndex, `<b>{name}</b>  ·  maxed  ·  {escape(path.tiers[#path.tiers].name)}\n<font size="13">{ladder}</font>`, LOCKED_COLOR, false)
				elseif why ~= "ok" then
					addRow(pathIndex, `<b>{name}</b>  ·  {ladder}\n<font size="13">{LOCK_REASONS[why] or "locked"}</font>`, LOCKED_COLOR, false)
				else
					local step = path.tiers[current + 1]
					local cost = if free then 0 else math.floor(step.cost * (1 - discount / 100) + 0.5)
					local affordable = cash >= cost
					local price = if free then "FREE" elseif discount > 0 then `{cost} <font size="13">(-{discount}%)</font>` else tostring(cost)
					local text = `<b>{escape(step.name)}</b>  ·  {price}\n<font size="13">{name} {ladder}  ·  {escape(describeHeroStep(path, current))}</font>`
					addRow(pathIndex, text, if affordable then HERO_COLOR else LOCKED_COLOR, affordable, function()
						send("upgrade", pathIndex, nil, heroRequest)
					end)
				end
			end
			-- Mastery perks this hunter has for the ability: one line, only if any.
			local heroKey = player:GetAttribute("Hero") or ""
			local perks = ownedPerkLine(heroKey, player:GetAttribute(`Mastery_{heroKey}`) or 0)
			if perks then
				addRow(#hero.paths + 1, perks, PANEL_COLOR, false)
			end
		end
	elseif mode == "mastery" then
		local cores = player:GetAttribute("Cores") or 0
		local status = player:GetAttribute("SaveStatus")
		title.Text = `{cores} {Theme.Currency}`
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
				addRow(order, `<b>{name}</b>  ·  unlock  ·  {hero.unlockCost} {CUR}\n<font size="13">{escape(hero.role)} · {escape(hero.ability)}</font>`, if affordable then UNLOCK_COLOR else LOCKED_COLOR, affordable, function()
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
				local text = `<b>{name}</b>  ·  mastery {level} → {level + 1}  ·  {nextLevel.coreCost} {CUR}\n<font size="13">{toward}</font>{perkLines(key, level)}`
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
				addRow(order, `<b>{name}</b>  ·  unlock  ·  {def.unlockCost} {CUR}\n<font size="13">{escape(def.role)}</font>`, if affordable then UNLOCK_COLOR else LOCKED_COLOR, affordable, function()
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
		local tiers = {}
		for pathIndex = 1, 3 do
			tiers[pathIndex] = managed:GetAttribute(`Path{pathIndex}`) or 0
		end
		local hp = (managed:GetAttribute("HP") or 0) :: number
		local maxHp = (managed:GetAttribute("MaxHP") or 0) :: number
		local trampled = managed:GetAttribute("KO") == true
		if trampled then
			title.Text = `Trampled — repair it  ·  {if def then def.display else "Tower"}`
			title.TextColor3 = TRAMPLED_COLOR
		else
			title.Text = `{if def then def.display else "Tower"}  ·  {tiers[1]} · {tiers[2]} · {tiers[3]}`
		end

		-- Health, and a repair row when it's damaged. Mirrors Server/Shop:
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
		if trampled or (maxHp > 0 and hp < maxHp) then
			local discount = managed:GetAttribute("Discount") or 0
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
				local why = Upgrades.check(tiers, pathIndex, #path.tiers)
				if trampled and why ~= "maxed" then
					-- Mirrors Server/Shop: no upgrades until it's repaired.
					addRow(pathIndex, `<b>{name}</b>  ·  tier {current}\n<font size="13">Repair it first</font>`, LOCKED_COLOR, false)
				elseif why == "maxed" then
					addRow(pathIndex, `<b>{name}</b>  ·  maxed  ·  {escape(path.tiers[#path.tiers].name or "")}`, LOCKED_COLOR, false)
				elseif why ~= "ok" then
					addRow(pathIndex, `<b>{name}</b>  ·  tier {current}\n<font size="13">{LOCK_REASONS[why] or "locked"}</font>`, LOCKED_COLOR, false)
				else
					local step = path.tiers[current + 1]
					-- Mirrors Server/Shop: a Supply Camp's Logistics discount (Shared/Pricing).
					local discount = managed:GetAttribute("Discount") or 0
					local cost = Pricing.upgradeCost(step, discount)
					local affordable = cash >= cost
					local price = if discount > 0 then `{cost} <font size="13">(-{discount}%)</font>` else tostring(cost)
					local text = `<b>{escape(step.name or path.id)}</b>  ·  {price}\n<font size="13">{name} {current + 1}  ·  {escape(describeStep(path, current))}</font>`
					addRow(pathIndex, text, if affordable then BUY_COLOR else LOCKED_COLOR, affordable, function()
						send("upgrade", towerId, pathIndex)
					end)
				end
			end
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

local function openManage(body: BasePart, prompt: ProximityPrompt)
	setMode("manage")
	managed, managedPrompt = body, prompt
	for _, name in { "Spent", "Tower", "Path1", "Path2", "Path3", "Discount", "RefundRate", "HP", "MaxHP", "KO" } do
		table.insert(managedConnections, body:GetAttributeChangedSignal(name):Connect(render))
	end
	table.insert(managedConnections, body.AncestryChanged:Connect(function()
		if not body:IsDescendantOf(workspace) then
			setMode("closed") -- sold, possibly by a teammate
		end
	end))
	render()
end

------------------------------------------------------------------ input

-- Open `wanted` if Shared/PanelRules allows it in the current state.
local function openIfAllowed(wanted: Mode)
	if PanelRules.allowed(wanted, ReplicatedStorage:GetAttribute("State"), myHero() ~= nil) then
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
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
	if who ~= player or mode == "placing" then
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

ReplicatedStorage:GetAttributeChangedSignal("Cash"):Connect(function()
	if mode == "list" or mode == "manage" or mode == "heroUpgrade" then
		render()
	end
end)

-- Shared/PanelRules decides what survives a state change: only match panels,
-- only from Building into Playing. Pressing Play, the results screen and
-- going home close everything.
ReplicatedStorage:GetAttributeChangedSignal("State"):Connect(function()
	local state = ReplicatedStorage:GetAttribute("State")
	if not PanelRules.keepOnStateChange(mode, state, myHero() ~= nil) then
		setMode("closed")
	else
		render() -- button visibility
	end
end)

player.AttributeChanged:Connect(function(name)
	if
		name == "Hero"
		or name == "Cores"
		or name == "FreeUpgrade"
		or string.sub(name, 1, 8) == "HeroPath"
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
