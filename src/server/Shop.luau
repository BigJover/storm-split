--[[
	Shop: the only way clients reach cash and towers (ARCHITECTURE.md §4).

	Clients REQUEST ("build a SCOUT here", "sell tower 7"). The server checks
	everything itself — the spot (Shared/Placement, the same rule the client's
	ghost uses), the player's distance to it, the tower, the cash — and prices
	come only from Config. A client sends a tower key and a position, or a tower
	id; never a price or a result.

	Money flow: Economy.trySpend() first, then Towers.place(). Towers never touch
	cash (§5.4). The shop remembers what each tower cost so selling refunds
	SellRefund of it; phase 3 upgrades add to the same total.

	Each built tower gets a ProximityPrompt for managing it. The server never
	trusts that the prompt was used and re-checks distance on every request.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ShopRules = require(Shared:WaitForChild("ShopRules"))
local Placement = require(Shared:WaitForChild("Placement"))

local Economy = require(script.Parent.Economy)
local Towers = require(script.Parent.Towers)

local Shop = {}

local MIN_REQUEST_GAP = 0.15 -- seconds; drops spammed requests from one player
local DISTANCE_SLACK = 6 -- studs of lag allowance on top of client-side distances

local spent: { [Towers.Tower]: number } = {} -- cash put into each tower
local lastRequest: { [Player]: number } = {}

------------------------------------------------------------------ towers

-- Tags a built tower so clients can find and manage it, and keeps the refund
-- the panel shows up to date.
local function decorate(tower: Towers.Tower)
	local body = tower.model.PrimaryPart
	if not body then
		return
	end
	body:SetAttribute("TowerId", tower.id)
	body:SetAttribute("Tower", tower.key)
	body:SetAttribute("Spent", spent[tower] or 0)

	local prompt = body:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = ShopRules.PromptDistance
		prompt.ActionText = "Manage"
		prompt.Parent = body
	end
	prompt.ObjectText = tower.def.display
end

local function isWithin(player: Player, point: Vector3, distance: number): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health <= 0 then
		return false
	end
	local offset = root.Position - point
	return Vector2.new(offset.X, offset.Z).Magnitude <= distance + DISTANCE_SLACK
end

------------------------------------------------------------------ requests

local function build(player: Player, towerKey: unknown, position: unknown): (boolean, string)
	if typeof(towerKey) ~= "string" then
		return false, "Pick a tower"
	end
	local def = Config.Towers[towerKey]
	if not def or ShopRules.Unreleased[towerKey] then
		return false, "That tower isn't for sale"
	end
	if typeof(position) ~= "Vector3" then
		return false, "Pick a spot"
	end

	local spot = Placement.ground(position)
	local fits, reason = Placement.check(spot, Towers.positions())
	if not fits then
		return false, reason or "Can't build there"
	end
	if not isWithin(player, spot, ShopRules.PlaceRange) then
		return false, "Too far from you"
	end
	if not Economy.trySpend(def.baseCost) then
		return false, "Not enough cash"
	end

	local tower = Towers.place(towerKey, spot)
	if not tower then
		Economy.earn(def.baseCost) -- give it back; place() refused
		return false, "Couldn't build there"
	end
	spent[tower] = def.baseCost
	decorate(tower)
	return true, `Built {def.display}`
end

local function sell(player: Player, towerId: unknown): (boolean, string)
	if typeof(towerId) ~= "number" then
		return false, "Unknown tower"
	end
	local tower = Towers.byId(towerId)
	if not tower then
		return false, "Nothing to sell"
	end
	if not isWithin(player, tower.base, ShopRules.PromptDistance) then
		return false, "Too far from the tower"
	end

	local refund = math.floor((spent[tower] or 0) * Config.Tuning.SellRefund)
	spent[tower] = nil
	Towers.remove(tower)
	Economy.earn(refund)
	return true, `Sold for {refund}`
end

local function handle(player: Player, action: unknown, a: unknown, b: unknown): (boolean, string)
	local now = os.clock()
	if now - (lastRequest[player] or 0) < MIN_REQUEST_GAP then
		return false, "Slow down"
	end
	lastRequest[player] = now

	local state = ReplicatedStorage:GetAttribute("State")
	if state == "GameOver" or state == "Victory" then
		return false, "The game is over"
	end

	if action == "build" then
		return build(player, a, b)
	elseif action == "sell" then
		return sell(player, a)
	end
	return false, "Unknown request"
end

------------------------------------------------------------------ public

function Shop.init(remotes: Folder)
	local request = Instance.new("RemoteFunction")
	request.Name = "ShopRequest"
	-- ("build", towerKey, position) or ("sell", towerId)
	request.OnServerInvoke = function(player: Player, action: unknown, a: unknown, b: unknown)
		local ok, success, message = pcall(handle, player, action, a, b)
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
