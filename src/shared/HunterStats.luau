--[[
	Hunter bodies (PLAN 10a T135, DECISIONS #364/#365/#370): each hunter's Max HP and Walk
	speed from the `Hunter Stats` sheet, with trained bonuses on top. Pure: Server/Health
	applies it to the Humanoid on spawn and on a hero pick; the HUD shows its HP line.

	  body(heroKey, trained?)  { maxHealth, walkSpeed }: the hunter's row (no hunter / an
	                    unknown key: Tuning Player max health / Player walk speed), times
	                    1 + trained % (health and speed, each clamped to 0..Tuning Trained
	                    health max / Trained speed max; account-wide training, T139)
	  score(body)       HP / Player max health x (speed / Player walk speed) ^ Body speed
	                    weight: the parity score the exporter holds to Body parity max
	  slowed(base, %)   a slow multiplies the class base (#365), never 16; 0..100 %
	  carryHealth(health, oldMax, newMax)   a hero pick changes Max HP: keep the same share
	                    of it (full stays full), never above the new max
	  hpText(health, max)   the HUD line "HP 95 / 95"
]]

local Config = require(script.Parent.Config)

local HunterStats = {}

export type Body = { maxHealth: number, walkSpeed: number }
export type Trained = { healthPercent: number?, speedPercent: number? }

local function percent(value: unknown, cap: number): number
	if type(value) ~= "number" or value ~= value then
		return 0
	end
	return math.clamp(value, 0, cap)
end

function HunterStats.base(heroKey: unknown): Body
	local row = if type(heroKey) == "string" then (Config.HunterStats :: any)[heroKey] else nil
	if row then
		return { maxHealth = row.maxHealth, walkSpeed = row.walkSpeed }
	end
	return { maxHealth = Config.Tuning.PlayerMaxHealth, walkSpeed = Config.Tuning.PlayerWalkSpeed }
end

function HunterStats.body(heroKey: unknown, trained: Trained?): Body
	local base = HunterStats.base(heroKey)
	local t = Config.Tuning
	local health = percent(trained and trained.healthPercent, t.TrainedHealthMax)
	local speed = percent(trained and trained.speedPercent, t.TrainedSpeedMax)
	return {
		maxHealth = base.maxHealth * (1 + health / 100),
		walkSpeed = base.walkSpeed * (1 + speed / 100),
	}
end

function HunterStats.score(body: Body): number
	local t = Config.Tuning
	return body.maxHealth / t.PlayerMaxHealth * (body.walkSpeed / t.PlayerWalkSpeed) ^ t.BodySpeedWeight
end

function HunterStats.slowed(base: number, slowPercent: number): number
	return base * (1 - math.clamp(if slowPercent == slowPercent then slowPercent else 0, 0, 100) / 100)
end

function HunterStats.carryHealth(health: number, oldMax: number, newMax: number): number
	if oldMax <= 0 or health ~= health then
		return newMax
	end
	return math.clamp(health / oldMax * newMax, 0, newMax)
end

function HunterStats.hpText(health: number, max: number): string
	return `HP {math.ceil(math.max(0, health))} / {math.floor(math.max(1, max))}`
end

return HunterStats
