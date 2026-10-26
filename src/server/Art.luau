--!strict
--[[
	Loads the uploaded art once at boot (PLAN 11a T148, DECISIONS #422/#425): every id in
	Shared/ArtIds through InsertService:LoadAsset, into ReplicatedStorage.Art.<kind>.<key> as
	a Model tagged ArtId = id, which Shared/ArtSlot's looks clone. Runs in its own thread, so
	it never holds up the match; looks built before an asset arrives (or when one fails, is
	blank or still in moderation) are today's blocky ones. Each failure is logged once.
]]

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArtIds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ArtIds"))

local Art = {}

local TRIES = 3
local RETRY_WAIT = 2 -- seconds, doubled each try

local function folderIn(parent: Instance, name: string): Instance
	local found = parent:FindFirstChild(name)
	if found then
		return found
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

-- One asset: the Model LoadAsset wraps it in (or that wrapper's single Model child).
local function load(id: number): (Model?, string?)
	local pause = RETRY_WAIT
	local why = "?"
	for try = 1, TRIES do
		local ok, result = pcall(function()
			return InsertService:LoadAsset(id)
		end)
		if ok and result then
			local inner = result:FindFirstChildWhichIsA("Model")
			local model = if inner and #result:GetChildren() == 1 then inner else result
			return model :: Model, nil
		end
		why = tostring(result)
		if try < TRIES then
			task.wait(pause)
			pause *= 2
		end
	end
	return nil, why
end

function Art.init()
	local root = folderIn(ReplicatedStorage, "Art")
	task.spawn(function()
		for kind, byKey in ArtIds do
			for key, entry in byKey do
				local id = entry.model
				if id then
					local model, why = load(id)
					if model then
						model.Name = key
						model:SetAttribute("ArtId", id)
						for _, d in model:GetDescendants() do
							if d:IsA("LuaSourceContainer") then
								d:Destroy() -- art carries no scripts (#426)
							end
						end
						model.Parent = folderIn(root, kind)
					else
						warn(`[Art] {kind}/{key} (asset {id}) failed to load: {why} — blocky look used`)
					end
				end
			end
		end
	end)
end

return Art
