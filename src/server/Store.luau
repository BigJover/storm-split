--[[
	The Robux store (PLAN 10e T143, DECISIONS #387-#389/#395): Developer Products and Game
	Passes through MarketplaceService. The rules are Shared/Store; grants go only through
	Server/Progression (the one saved-data mutator).

	Works only in a published game (Store.isOpen: not Studio, PlaceId > 0). Otherwise the
	"StoreOpen" attribute is false, the shop shows "The store opens when the game is
	published", no purchase is ever prompted, ProcessReceipt is not even set, and nothing is
	granted: there is no test-grant path (#388).

	  ProcessReceipt   the receipt's player must be here with a profile that loaded
	                   (else NotProcessedYet: Roblox retries later); the product id maps to a
	                   Store row; Progression.storeReceipt grants it once per PurchaseId and
	                   answers PurchaseGranted only after the save went through.
	  Game Passes      UserOwnsGamePassAsync once per player on join (cached), and
	                   PromptGamePassPurchaseFinished for a pass bought here; the effects
	                   (2× training, an extra training spot, a second Hatchery Hut) reach
	                   Progression.setPasses. A failed ownership check counts as not owned
	                   and is retried on the next join.
	  PolicyService    a player whose policy restricts paid random items never sees or can
	                   prompt "Hatch now" (a hatch rolls a rarity). A failed policy check
	                   counts as restricted.
	  StoreRequest     ("view") -> { open, restricted, passes, credits } ; ("buy", key) ->
	                   ok, message: the server checks the row is shown to this player, it's
	                   between matches (nothing bought mid-match, #389), a pass isn't owned
	                   yet and a Hatch now has an egg of its kind warming, then prompts.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local StoreRules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Store"))
local Progression = require(script.Parent.Progression)

local Store = {}

local owned: { [Player]: { [string]: boolean } } = {}
local restricted: { [Player]: boolean } = {}

local function checkPlayer(player: Player, open: boolean)
	local passes = {}
	if open then
		for _, key in StoreRules.order() do
			local row = StoreRules.row(key)
			if row and row.type == "pass" and row.id and StoreRules.ready(row) then
				local ok, has = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, row.id :: number)
				end)
				if ok and has then
					passes[key] = true
				end
			end
		end
		local ok, info = pcall(function()
			return PolicyService:GetPolicyInfoForPlayerAsync(player)
		end)
		restricted[player] = not ok or (type(info) == "table" and info.ArePaidRandomItemsRestricted == true)
	else
		restricted[player] = true
	end
	if not player.Parent then
		return
	end
	owned[player] = passes
	Progression.setPasses(player, passes)
end

local function betweenMatches(player: Player): boolean
	return ReplicatedStorage:GetAttribute("State") == "Lobby" or player:GetAttribute("InOutpost") == true
end

local function buy(player: Player, open: boolean, key: unknown): (boolean, string)
	if not open then
		return false, StoreRules.CLOSED_LINE
	end
	if type(key) ~= "string" or not StoreRules.shown(key, restricted[player] ~= false) then
		return false, "Not in the store"
	end
	if not betweenMatches(player) then
		return false, "The store opens between matches"
	end
	local row = StoreRules.row(key) :: StoreRules.Row
	if row.type == "pass" then
		if (owned[player] or {})[key] then
			return false, "Already yours"
		end
		MarketplaceService:PromptGamePassPurchase(player, row.id :: number)
		return true, ""
	end
	if row.grant == "hatch" and not Progression.hasWarmingEgg(player, row.items[1]) then
		return false, "No egg of that kind is warming"
	end
	MarketplaceService:PromptProductPurchase(player, row.id :: number)
	return true, ""
end

function Store.init(remotes: Folder)
	local open = StoreRules.isOpen(RunService:IsStudio(), game.PlaceId)
	ReplicatedStorage:SetAttribute("StoreOpen", open)

	local request = Instance.new("RemoteFunction")
	request.Name = "StoreRequest"
	request.OnServerInvoke = function(player: Player, action: unknown, key: unknown)
		local ok, success, message = pcall(function(): (any, any)
			if action == "view" then
				local passes = {}
				for k in (owned[player] or {}) :: { [string]: boolean } do
					passes[k] = true
				end
				return true, {
					open = open,
					restricted = restricted[player] ~= false,
					passes = passes,
					credits = Progression.storeView(player),
				}
			elseif action == "buy" then
				return buy(player, open, key)
			end
			return false, "Unknown request"
		end)
		if not ok then
			warn(`[Store] {tostring(action)} from {player.Name} failed: {success}`)
			return false, "Something went wrong"
		end
		return success, message
	end
	request.Parent = remotes

	Players.PlayerAdded:Connect(function(player)
		checkPlayer(player, open)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(checkPlayer, player, open)
	end
	Players.PlayerRemoving:Connect(function(player)
		owned[player] = nil
		restricted[player] = nil
	end)

	if not open then
		return -- unpublished or Studio: no receipts, no prompts, no grants
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, purchased: boolean)
		local key = StoreRules.byId("pass", passId)
		if purchased and key and owned[player] then
			owned[player][key] = true
			Progression.setPasses(player, owned[player])
		end
	end)

	MarketplaceService.ProcessReceipt = function(receipt): Enum.ProductPurchaseDecision
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local key = StoreRules.byId("product", receipt.ProductId)
		if not key then
			warn(`[Store] Receipt for product {receipt.ProductId} matches no Store row; kept for later`)
		end
		local decision = Progression.storeReceipt(player, tostring(receipt.PurchaseId), key)
		return if decision == StoreRules.GRANTED
			then Enum.ProductPurchaseDecision.PurchaseGranted
			else Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

return Store
