--[[
	Economy: the team's cash and lives (ARCHITECTURE.md §4, §5.3).

	OWNERSHIP: the only module that changes cash or lives. Cash is one pot for
	the whole team (design doc: "Co-op 2–4, shared cash").

	Every spend goes through Economy.trySpend(), which checks and deducts in one
	step with no yield in between, so four players clicking at once can never all
	pass the same check.

	Cash is kept fractional internally because kill income is HP destroyed x
	CashPerEffectiveHP (a Husk pays 0.43). Clients see the floor through the
	"Cash" attribute, and trySpend compares against the real value, so what the
	HUD shows is never more than what can be spent.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = {}

local cash = 0
local lives = 0
local onZero: (() -> ())? = nil

local function publishCash()
	ReplicatedStorage:SetAttribute("Cash", math.floor(cash))
end

function Economy.init(startingCash: number, startingLives: number, whenLivesZero: () -> ())
	cash = startingCash
	lives = startingLives
	onZero = whenLivesZero
	publishCash()
	ReplicatedStorage:SetAttribute("Lives", lives)
end

------------------------------------------------------------------ cash

function Economy.earn(amount: number)
	if amount <= 0 then
		return
	end
	cash += amount
	publishCash()
end

-- Returns true and deducts if the team can afford it; otherwise changes nothing.
function Economy.trySpend(amount: number): boolean
	if amount < 0 or cash < amount then
		return false
	end
	cash -= amount
	publishCash()
	return true
end

function Economy.cash(): number
	return cash
end

------------------------------------------------------------------ lives

-- Difficulty sets lives when the match starts.
function Economy.setLives(amount: number)
	lives = amount
	ReplicatedStorage:SetAttribute("Lives", lives)
end

function Economy.lose(amount: number)
	if lives <= 0 then
		return
	end
	lives = math.max(0, lives - amount)
	ReplicatedStorage:SetAttribute("Lives", lives)
	if lives == 0 and onZero then
		onZero()
	end
end

function Economy.lives(): number
	return lives
end

return Economy
