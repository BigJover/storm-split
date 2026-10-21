--[[
	Eggs and pets on the server (PLAN 10d T140/T141, DECISIONS #375-#379, #392/#393/#396).
	The rules are Shared/Pets; the saved collection belongs to Server/Progression (the only
	saved-data mutator), which this module only calls.

	REQUESTS (the "Pets" RemoteFunction), all between matches (Progression checks):
	  ("view")                  -> true, { state, now } | false, why: the Hatchery Hut's data
	  ("buy", egg)              an egg into a free incubator, for its Amber price
	  ("warm", slot)            "Warm it up": Amber per remaining minute, finishes it now
	  ("hatch", slot)           a ready egg -> a pet (rarity rolled here, on the server)
	  ("fuse", pet, rarity)     3 identical -> 1 of the next rarity
	  ("along", id | 0)         the one pet taken along into hunts (0 = none)
	  ("pen", id, on)           show it in your Hatchling Pen (3 max)
	  Studio only (StudioOnly pets): ("studioegg", egg), ("hatchnow"), ("studiopet", "<PET> <RARITY>", n)
]]

local Progression = require(script.Parent.Progression)

local Pets = {}

local function request(player: Player, action: unknown, a: unknown, b: unknown): (boolean, any)
	if action == "view" then
		return Progression.petView(player)
	end
	return Progression.petAction(player, action, a, b)
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
	local down = Instance.new("RemoteEvent")
	down.Name = "PetDown" -- (text): your pet ran back to camp (T141)
	down.Parent = remotes
end

return Pets
