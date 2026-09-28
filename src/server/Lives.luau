--[[
	Lives. Phase 1 stand-in: in phase 2 this folds into Economy, which owns
	both cash and lives (ARCHITECTURE.md §3). Replicates to clients through
	a ReplicatedStorage attribute so the HUD needs no remotes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Lives = {}

local lives = 0
local onZero: (() -> ())? = nil

function Lives.init(startingLives: number, whenZero: () -> ())
	lives = startingLives
	onZero = whenZero
	ReplicatedStorage:SetAttribute("Lives", lives)
end

function Lives.lose(amount: number)
	if lives <= 0 then
		return
	end
	lives = math.max(0, lives - amount)
	ReplicatedStorage:SetAttribute("Lives", lives)
	if lives == 0 and onZero then
		onZero()
	end
end

function Lives.get(): number
	return lives
end

return Lives
