--[[
	Shop: the only way clients reach cash and towers (ARCHITECTURE.md §4).

	Clients REQUEST ("build a SCOUT here", "upgrade tower 7 path 2", "repair tower 7", "sell tower 7"). The server checks
	everything itself — the spot (Shared/Placement, the same rule the client's
	ghost uses), the player's distance to it, the tower, the cash — and prices
	come only from Config. A client sends a tower key and a position, or a tower
	id; never a price or a result.

	Money flow: Economy.trySpendFor(your side) first, then Towers.place(). Towers never touch
	cash (§5.4); upgrades likewise pay first, then call Towers.upgrade(). The
	shop remembers what each tower cost, upgrades included, so selling refunds
	SellRefund of all of it. Repairs (anyone's tower, like upgrades) cost
	Repair cost x that amount x the share of HP missing (Shared/Combat, less a
	Logistics discount); they pay first, then Towers.repair(), and are NOT
	added to it, so a repair never raises the sell refund. Selling a damaged
	tower refunds less its repair price (DECISIONS #35), so selling and
	rebuying never beats repairing. A trampled tower can't be upgraded until
	it's repaired.

	Each built tower gets a ProximityPrompt for managing it. The server never
	trusts that the prompt was used and re-checks distance on every request.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Combat = require(Shared:WaitForChild("Combat"))
local Config = require(Shared:WaitForChild("Config"))
local ShopRules = require(Shared:WaitForChild("ShopRules"))
local Placement = require(Shared:WaitForChild("Placement"))
local Pricing = require(Shared:WaitForChild("Pricing"))
local Sides = require(Shared:WaitForChild("Sides"))
local SmallPerks = require(Shared:WaitForChild("SmallPerks"))
local Theme = require(Shared:WaitForChild("Theme"))
local Upgrades = require(Shared:WaitForChild("Upgrades"))

local Economy = require(script.Parent.Economy)
local Progression = require(script.Parent.Progression)
local Towers = require(script.Parent.Towers)

local Shop = {}

local MIN_REQUEST_GAP = 0.15 -- seconds; drops spammed requests from one player
local DISTANCE_SLACK = 6 -- studs of lag allowance on top of client-side distances

local spent: { [Towers.Tower]: number } = {} -- cash put into each tower
-- Studio stand-in sides' towers (PLAN T77, DECISIONS #221): the owner id and name to show.
local standIns: { [Towers.Tower]: { id: number, name: string } } = {}
-- (hunter, a Bounties event): "build", "upgrade" or "repair", once the purchase went through
local onBounty: ((Player, string) -> ())? = nil
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
	local standIn = standIns[tower]
	body:SetAttribute("OwnerId", if standIn then standIn.id elseif tower.owner then tower.owner.UserId else 0)
	body:SetAttribute("OwnerName", if standIn then standIn.name elseif tower.owner then tower.owner.DisplayName else "")
	body:SetAttribute("Side", tower.side) -- whose camp (the panel is read-only on another camp's, T78)
	for pathIndex, tier in tower.pathTiers do
		body:SetAttribute(`Path{pathIndex}`, tier)
	end

	local prompt = body:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = ShopRules.PromptDistance
		prompt.Parent = body
		-- "Upgrade", or "Upgrade / Repair" while it's damaged (Towers publishes HP).
		local function label()
			local hp, maxHp = body:GetAttribute("HP"), body:GetAttribute("MaxHP")
			local damaged = typeof(hp) == "number" and typeof(maxHp) == "number" and hp < maxHp
			prompt.ActionText = if damaged then "Upgrade / Repair" else "Upgrade"
		end
		body:GetAttributeChangedSignal("HP"):Connect(label)
		body:GetAttributeChangedSignal("MaxHP"):Connect(label)
		label()
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

-- The hunter's side and its build zone (Shared/Sides; co-op: side 1, the whole build area).
-- MapBuilder publishes the layout; Main sets each hunter's "Side".
local function sideOf(player: Player): (number, Sides.Layout)
	local layout = Sides.fromAttributes(ReplicatedStorage:GetAttribute("Sides"), ReplicatedStorage:GetAttribute("SideGrid"))
	return Sides.sideOf(player:GetAttribute("Side"), layout.sides), layout
end

local function build(player: Player, towerKey: unknown, position: unknown): (boolean, string)
	if typeof(towerKey) ~= "string" then
		return false, "Pick a tower"
	end
	local def = Config.Towers[towerKey]
	if not def or ShopRules.Unreleased[towerKey] then
		return false, "That tower isn't for sale"
	end
	-- You can only place towers you own; upgrading anyone's tower is fine.
	if not Progression.ownsTower(player, towerKey) then
		return false, `Unlock {def.display} with {Theme.Currency} first (M)`
	end
	if typeof(position) ~= "Vector3" then
		return false, "Pick a spot"
	end

	local spot = Placement.ground(position)
	local side, layout = sideOf(player)
	local fits, reason = Placement.check(spot, Towers.positions(), def.onTrack, Sides.zone(layout, side))
	if fits and def.onTrack then
		-- The pool, not just the footprint, must not overlap another pit's (#189).
		fits, reason = Placement.checkPool(Towers.poolAtFor(spot, side), def.range, Towers.pools(side))
	end
	if not fits then
		return false, reason or "Can't build there"
	end
	if not isWithin(player, spot, ShopRules.PlaceRange) then
		return false, "Too far from you"
	end
	if not Economy.trySpendFor(side, def.baseCost) then -- your own side's cash (T76)
		return false, "Not enough cash"
	end

	local tower = Towers.place(towerKey, spot, player, side)
	if not tower then
		Economy.earnFor(side, def.baseCost) -- give it back; place() refused
		return false, "Couldn't build there"
	end
	spent[tower] = def.baseCost
	decorate(tower)
	if onBounty then
		onBounty(player, "build")
	end
	return true, `Built {def.display}`
end

local UPGRADE_REFUSALS = {
	maxed = "That path is maxed",
	["third path"] = "Only two paths can be opened",
	crossover = "Only one path can go past tier 2",
}

local function upgrade(player: Player, towerId: unknown, pathIndex: unknown): (boolean, string)
	if typeof(towerId) ~= "number" or typeof(pathIndex) ~= "number" then
		return false, "Unknown upgrade"
	end
	local tower = Towers.byId(towerId)
	if not tower then
		return false, "That tower is gone"
	end
	local side = sideOf(player)
	local refusal = Sides.manageRefusal("upgrade", side, tower.side) -- never an enemy's tower (T76)
	if refusal then
		return false, refusal
	end
	local path = tower.def.paths[pathIndex]
	if not path then
		return false, "Unknown upgrade"
	end
	if not isWithin(player, tower.base, ShopRules.PromptDistance) then
		return false, "Too far from the tower"
	end
	if tower.knockedOut then
		return false, "Repair it first"
	end

	local why = Upgrades.check(tower.pathTiers, pathIndex, #path.tiers)
	if why ~= "ok" then
		return false, UPGRADE_REFUSALS[why] or "Can't upgrade that"
	end
	local step = Upgrades.nextStep(tower.def, tower.pathTiers, pathIndex)
	if not step then
		return false, "That path is maxed"
	end
	-- A Quartermaster's Logistics aura discounts upgrades on towers in its range.
	local cost = Pricing.upgradeCost(step, tower.buff.discountPercent)
	if not Economy.trySpendFor(side, cost) then
		return false, "Not enough cash"
	end

	if not Towers.upgrade(tower, pathIndex) then
		Economy.earnFor(side, cost) -- give it back; upgrade() refused
		return false, "Can't upgrade that"
	end
	spent[tower] = (spent[tower] or 0) + cost
	decorate(tower)
	if onBounty then
		onBounty(player, "upgrade") -- the buyer's, whoever owns the tower (DECISIONS #83)
	end
	return true, `{step.name or path.id}!`
end

-- Anyone on the tower's side can repair it, in the build phase or mid-round (DECISIONS #10;
-- battle sides: only its own side, T76).
local function repair(player: Player, towerId: unknown): (boolean, string)
	if typeof(towerId) ~= "number" then
		return false, "Unknown tower"
	end
	local tower = Towers.byId(towerId)
	if not tower then
		return false, "That tower is gone"
	end
	local side = sideOf(player)
	local refusal = Sides.manageRefusal("repair", side, tower.side) -- never an enemy's tower (T76)
	if refusal then
		return false, refusal
	end
	if not isWithin(player, tower.base, ShopRules.PromptDistance) then
		return false, "Too far from the tower"
	end
	if tower.def.untouchable then
		return false, "It can't be damaged" -- no HP, never repaired (DECISIONS #148)
	end
	if tower.hp >= tower.maxHp and not tower.knockedOut then
		return false, "It doesn't need repairs"
	end
	-- A Supply Camp's Logistics discount applies, as it does to upgrades, and the
	-- repairing hunter's Handyman mastery perk (Shared/SmallPerks).
	local cost = Combat.repairCost(spent[tower] or 0, tower.hp, tower.maxHp, tower.buff.discountPercent, SmallPerks.ofPlayer(player).repairCostMult)
	if cost > 0 and not Economy.trySpendFor(side, cost) then
		return false, "Not enough cash"
	end
	local trampled = tower.knockedOut
	Towers.repair(tower) -- not added to spent: a repair doesn't raise the refund
	if trampled and onBounty then
		onBounty(player, "repair") -- only a trampled tower put back up counts (DECISIONS #75)
	end
	return true, if cost > 0 then `Repaired for {cost}` else "Repaired"
end

local function sell(player: Player, towerId: unknown): (boolean, string)
	if typeof(towerId) ~= "number" then
		return false, "Unknown tower"
	end
	local tower = Towers.byId(towerId)
	if not tower then
		return false, "Nothing to sell"
	end
	local refusal = Sides.manageRefusal("sell", sideOf(player), tower.side) -- never an enemy's tower (T76)
	if refusal then
		return false, refusal
	end
	if not isWithin(player, tower.base, ShopRules.PromptDistance) then
		return false, "Too far from the tower"
	end
	-- Anyone can upgrade (it helps the team); only the builder can sell, unless
	-- they've left. Stops one player cashing out a teammate's tower.
	if tower.owner and tower.owner ~= player and tower.owner.Parent then
		return false, `Only {tower.owner.DisplayName} can sell this`
	end

	-- Recycler / Base Camp raise the refund for towers in their range.
	-- A damaged tower refunds less its repair price (DECISIONS #35).
	local repairPrice = Combat.repairCost(spent[tower] or 0, tower.hp, tower.maxHp, tower.buff.discountPercent)
	local refund = Pricing.sellRefund(spent[tower] or 0, tower.buff.sellRefund, repairPrice)
	spent[tower] = nil
	Towers.remove(tower)
	Economy.earnFor(tower.side, refund) -- back to the tower's side (yours: checked above)
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
	-- A spectator (their battle side is out, PLAN T77) can't build, upgrade, repair or sell.
	if ReplicatedStorage:GetAttribute(Sides.attr("Out", (sideOf(player)))) == true then
		return false, "The game is over"
	end

	if action == "build" then
		return build(player, a, b)
	elseif action == "upgrade" then
		return upgrade(player, a, b)
	elseif action == "repair" then
		return repair(player, a)
	elseif action == "sell" then
		return sell(player, a)
	end
	return false, "Unknown request"
end

------------------------------------------------------------------ public

-- Between matches (after Towers.clearAll): forget what every tower cost.
function Shop.reset()
	table.clear(spent)
	table.clear(standIns)
end

-- A Studio stand-in side's pre-placed tower (PLAN T77, DECISIONS #221): free, no player
-- owner (`ownerId` is negative), never paid back; managed like any tower of its side.
function Shop.placeStandIn(key: string, spot: Vector3, side: number, ownerId: number, ownerName: string): Towers.Tower?
	local tower = Towers.place(key, spot, nil, side)
	if tower then
		spent[tower] = 0
		standIns[tower] = { id = ownerId, name = ownerName }
		decorate(tower)
	end
	return tower
end

function Shop.init(remotes: Folder, hooks: { onBounty: ((Player, string) -> ())? }?)
	onBounty = hooks and hooks.onBounty
	local request = Instance.new("RemoteFunction")
	request.Name = "ShopRequest"
	-- ("build", towerKey, position), ("upgrade", towerId, pathIndex), ("repair", towerId) or ("sell", towerId)
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
