--[[
	Shop: the only way clients reach cash and towers (ARCHITECTURE.md §4).

	Clients REQUEST ("build a SCOUT on pad 4", "sell pad 4"). The server checks
	everything itself — the pad, the player's distance to it, the tower, the
	cash — and prices come only from Config. A client sends a pad number and a
	tower key, both validated; never a price or a result.

	Money flow: Economy.trySpend() first, then Towers.place(). Towers never touch
	cash (§5.4). The shop remembers what each tower cost so selling refunds
	SellRefund of it; phase 3 upgrades add to the same total.

	Each pad gets a ProximityPrompt. The client opens its panel when the prompt
	triggers; the server never trusts that the prompt was used and re-checks
	distance on every request.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ShopRules = require(Shared:WaitForChild("ShopRules"))

local Economy = require(script.Parent.Economy)
local Towers = require(script.Parent.Towers)

local Shop = {}

local MIN_REQUEST_GAP = 0.15 -- seconds; drops spammed requests from one player
local DISTANCE_SLACK = 6 -- studs of lag allowance on top of the prompt distance

local pads: { BasePart } = {}
local spent: { [Towers.Tower]: number } = {} -- cash put into each tower
local lastRequest: { [Player]: number } = {}

------------------------------------------------------------------ pads

local function refreshPad(pad: BasePart)
	local prompt = pad:FindFirstChildOfClass("ProximityPrompt")
	local tower = Towers.atPad(pad)
	if tower then
		pad:SetAttribute("Tower", tower.key)
		pad:SetAttribute("Spent", spent[tower] or 0)
	else
		pad:SetAttribute("Tower", nil)
		pad:SetAttribute("Spent", nil)
	end
	if prompt then
		prompt.ActionText = if tower then "Manage" else "Build"
		prompt.ObjectText = if tower then tower.def.display else `Pad {pad:GetAttribute("PadIndex")}`
	end
end

local function addPrompt(pad: BasePart)
	local prompt = Instance.new("ProximityPrompt")
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = ShopRules.PromptDistance
	prompt.Parent = pad
end

local function isNear(player: Player, pad: BasePart): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health <= 0 then
		return false
	end
	return (root.Position - pad.Position).Magnitude <= ShopRules.PromptDistance + DISTANCE_SLACK
end

------------------------------------------------------------------ requests

local function build(pad: BasePart, towerKey: unknown): (boolean, string)
	if typeof(towerKey) ~= "string" then
		return false, "Pick a tower"
	end
	local def = Config.Towers[towerKey]
	if not def or ShopRules.Unreleased[towerKey] then
		return false, "That tower isn't for sale"
	end
	if Towers.atPad(pad) then
		return false, "This pad already has a tower"
	end
	if not Economy.trySpend(def.baseCost) then
		return false, "Not enough cash"
	end

	local tower = Towers.place(towerKey, pad)
	if not tower then
		Economy.earn(def.baseCost) -- give it back; place() refused
		return false, "Couldn't build here"
	end
	spent[tower] = def.baseCost
	refreshPad(pad)
	return true, `Built {def.display}`
end

local function sell(pad: BasePart): (boolean, string)
	local tower = Towers.atPad(pad)
	if not tower then
		return false, "Nothing to sell"
	end
	local refund = math.floor((spent[tower] or 0) * Config.Tuning.SellRefund)
	spent[tower] = nil
	Towers.remove(tower)
	Economy.earn(refund)
	refreshPad(pad)
	return true, `Sold for {refund}`
end

local function handle(player: Player, action: unknown, padIndex: unknown, towerKey: unknown): (boolean, string)
	local now = os.clock()
	if now - (lastRequest[player] or 0) < MIN_REQUEST_GAP then
		return false, "Slow down"
	end
	lastRequest[player] = now

	local state = ReplicatedStorage:GetAttribute("State")
	if state == "GameOver" or state == "Victory" then
		return false, "The game is over"
	end

	if typeof(padIndex) ~= "number" or padIndex ~= math.floor(padIndex) then
		return false, "Unknown pad"
	end
	local pad = pads[padIndex]
	if not pad then
		return false, "Unknown pad"
	end
	if not isNear(player, pad) then
		return false, "Too far from the pad"
	end

	if action == "build" then
		return build(pad, towerKey)
	elseif action == "sell" then
		return sell(pad)
	end
	return false, "Unknown request"
end

------------------------------------------------------------------ public

function Shop.init(mapPads: { BasePart }, remotes: Folder)
	pads = mapPads
	for _, pad in pads do
		addPrompt(pad)
		refreshPad(pad)
	end

	local request = Instance.new("RemoteFunction")
	request.Name = "ShopRequest"
	request.OnServerInvoke = function(player: Player, action: unknown, padIndex: unknown, towerKey: unknown)
		local ok, success, message = pcall(handle, player, action, padIndex, towerKey)
		if not ok then
			warn(`[Shop] request from {player.Name} failed: {success}`)
			return false, "Something went wrong"
		end
		return success, message
	end
	request.Parent = remotes

	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)
end

return Shop
