--[[
	StandInHunters: the Studio-only stand-in hunter on each stand-in camp (PLAN T93), so one
	Tester client can shoot a "hunter" alone: x PvP hunter damage, "Tranqed by <name>!",
	back on its own camp after Respawn time, and the Camo Cover countdown. Rules in
	Shared/StandInHunter; this builds the dummy and keeps its billboard current.

	Battle spawns one per stand-in camp (only when stand-ins are on, which is Studio only)
	and clears them with the camp (out) or the match (reset). Hero offers them as foes to an
	enemy hunter's shots. A dummy isn't a Player: it is never saved, paid or ranked, dinos
	don't target it, and it never shoots.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local BattleFlow = require(Shared:WaitForChild("BattleFlow"))
local StandInHunter = require(Shared:WaitForChild("StandInHunter"))
local StudioOnly = require(Shared:WaitForChild("StudioOnly"))

local StandInHunters = {}

export type Entry = {
	dummy: StandInHunter.Dummy,
	home: Vector3,
	camp: string,
	model: Model,
	body: BasePart,
	head: BasePart,
	label: TextLabel,
}

local entries: { [number]: Entry } = {} -- by side
local folder: Folder? = nil

local function now(): number
	return workspace:GetServerTimeNow()
end

local BODY = Vector3.new(2, 3, 1.2) -- visual only
local HEAD = Vector3.new(1.4, 1.4, 1.4)

local function build(side: number, camp: string): (Model, BasePart, BasePart, TextLabel)
	local model = Instance.new("Model")
	model.Name = `StandInHunter{side}`
	local color = BrickColor.new(BattleFlow.campColor(side) :: any)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = BODY
	body.Anchored = true
	body.CanCollide = false
	body.BrickColor = color
	body.Parent = model
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = HEAD
	head.Anchored = true
	head.CanCollide = false
	head.Color = Color3.fromRGB(234, 184, 146)
	head.Parent = model
	model.PrimaryPart = body
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(220, 66)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 250
	gui.Adornee = head
	gui.Parent = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = camp
	label.Parent = gui
	return model, body, head, label
end

local function place(entry: Entry)
	local down = entry.dummy.downAt ~= nil
	local base = entry.home + Vector3.new(0, BODY.Y / 2, 0)
	entry.body.CFrame = CFrame.new(base)
		* (if down then CFrame.Angles(0, 0, math.rad(90)) * CFrame.new(-BODY.Y / 2 + 0.6, 0, 0) else CFrame.identity)
	entry.head.CFrame = entry.body.CFrame * CFrame.new(0, (BODY.Y + HEAD.Y) / 2, 0)
	entry.body.Transparency = if down then 0.5 else 0
	entry.head.Transparency = entry.body.Transparency
end

local function refresh(entry: Entry)
	entry.label.Text = StandInHunter.label(entry.dummy, now(), entry.camp)
end

-- One stand-in hunter on `side`'s camp, standing beside its spawn. Studio only.
function StandInHunters.spawn(side: number, spawnAt: Vector3, camp: string)
	if not StudioOnly.allowed(RunService:IsStudio(), "standIns") then
		return
	end
	StandInHunters.remove(side)
	if not folder then
		local f = Instance.new("Folder")
		f.Name = "StandInHunters"
		f.Parent = workspace
		folder = f
	end
	local home = spawnAt + Vector3.new(6, 0, 0)
	local model, body, head, label = build(side, camp)
	local entry: Entry = { dummy = StandInHunter.new(side, now()), home = home, camp = camp, model = model, body = body, head = head, label = label }
	entries[side] = entry
	place(entry)
	refresh(entry)
	model.Parent = folder
	print(`[DinoHunters] Stand-in hunter on {camp} (Studio only): {Config.Tuning.PlayerMaxHealth} HP, never shoots`)
end

function StandInHunters.remove(side: number)
	local entry = entries[side]
	if entry then
		entry.model:Destroy()
		entries[side] = nil
	end
end

function StandInHunters.clear()
	for side in entries do
		StandInHunters.remove(side)
	end
end

-- The standing ones, for Hero's foe list: (side, where to aim).
function StandInHunters.standing(): { { side: number, position: Vector3 } }
	local out = {}
	for side, entry in entries do
		if entry.dummy.downAt == nil then
			table.insert(out, { side = side, position = entry.body.Position })
		end
	end
	return out
end

-- An enemy hunter's pellet into `side`'s stand-in hunter. Returns (dealt, downed).
function StandInHunters.hit(side: number, amount: number, attackerSide: number, attackerName: string): (number, boolean)
	local entry = entries[side]
	if not entry then
		return 0, false
	end
	local dealt, downed = StandInHunter.hit(entry.dummy, amount, attackerSide, now(), attackerName)
	if downed then
		print(`[DinoHunters] {entry.camp}'s stand-in hunter: {(string.gsub(StandInHunter.label(entry.dummy, now(), entry.camp), "\n", " · "))}`)
		place(entry)
		task.delay(Config.Tuning.RespawnTime, function()
			if entries[side] == entry and StandInHunter.respawnDue(entry.dummy, now() + 0.05) then
				StandInHunter.respawn(entry.dummy, now())
				place(entry) -- back on its own camp
				refresh(entry)
			end
		end)
	end
	refresh(entry)
	return dealt, downed
end

-- Keeps the Camo Cover countdown ticking on the billboards.
RunService.Heartbeat:Connect(function()
	for _, entry in entries do
		if StandInHunter.camo(entry.dummy, now()) or entry.label.Text:find("Camo", 1, true) then
			refresh(entry)
		end
	end
end)

return StandInHunters
