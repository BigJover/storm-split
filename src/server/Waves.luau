--[[
	Waves: runs the 40-round table from Config.Rounds.

	Spawns each round weakest-tier first at the round's spawn gap, waits for
	every enemy (including queued split children) to be dealt with, then
	moves on. Main pays the round-end bonus from onRoundEnd.

	SCALING (VISION.md): before each round, options.scale() says how much
	denser, tougher and more promoted this round is — difficulty and player
	count combined. Counts go up and the spawn gap shrinks by the same factor,
	so rounds get busier rather than longer. A promoted enemy spawns one ground
	tier up (Husk > Brute > Shielded > Armored > Storm); air and bosses never are.

	SIDES (PLAN T75): a run belongs to one side (`side`, default 1 = co-op) and waits only
	for that side's dinos. `density` (Shared/Sides.density: Royale and 3-side Team)
	multiplies the counts on top of the scale, so many tracks fit under the shared cap.
	Battles (PLAN T77) don't use run(): Server/Battle starts every living side's round
	together with spawnRound() (lockstep, Shared/BattleRules.nextRoundDue).

	PACE (PLAN T103, DECISIONS #250, #258): every round is paced by Shared/Pace.plan: the
	gap is not paced (a battle's is / Battle crowd x, which thins the round like density),
	the counts x Round pace (x Battle crowd x in battles; bosses kept),
	each dino tougher by plan.hpX, kill cash x plan.cashX and leak cost x plan.leakX, so a
	round's EHP, required DPS, cash and Fence at stake are co-op's unpaced round's.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Pace = require(Shared:WaitForChild("Pace"))
local RoundFlow = require(Shared:WaitForChild("RoundFlow"))

local Enemies = require(script.Parent.Enemies)

local Waves = {}

local INTERMISSION = 5 -- seconds between rounds
local POLL = 0.25 -- seconds between "every dino dealt with?" checks

export type Scale = { countMult: number, hpMult: number, promoteChance: number }

export type RunOptions = {
	startRound: number?,
	speedMult: number, -- the difficulty's dino speed (the pace factor's walk, #250)
	side: number?, -- whose track (default 1, co-op)
	density: number?, -- count multiplier per side (default 1)
	isOver: () -> boolean,
	scale: (() -> Scale)?,
	onRoundStart: ((number) -> ())?,
	onRoundEnd: ((number) -> ())?,
}

-- The next ground tier up for each promotable tier, in Config.EnemyOrder.
local promotion: { [string]: string } = {}
do
	local previous: string? = nil
	for _, key in Config.EnemyOrder do
		local def = Config.Enemies[key]
		if def and not def.flying and not def.boss then
			if previous then
				promotion[previous] = key
			end
			previous = key
		end
	end
end

local random = Random.new()

local NO_SCALE: Scale = table.freeze({ countMult = 1, hpMult = 1, promoteChance = 0 })

export type RoundOptions = {
	side: number, -- whose track
	index: number, -- the row of Config.Rounds
	scale: Scale,
	density: number?, -- count multiplier per side (default 1)
	hpMult: number?, -- extra HP multiplier (battle overtime, Shared/BattleFlow; default 1)
	speedMult: number, -- the difficulty's dino speed (Shared/Pace.plan)
	crowd: number?, -- Shared/Pace.crowd: Battle crowd x in battles (default 1, co-op)
	random: Random?, -- promotion rolls (battles: one seed per round, so every side gets the same dinos)
	isOver: () -> boolean,
}

-- Spawns one round's dinos on one side's track, weakest tier first at the round's spawn
-- gap (yields). Returns false if `isOver` stopped it part-way.
function Waves.spawnRound(options: RoundOptions): boolean
	local round = Config.Rounds[options.index]
	local scale = options.scale
	local countMult = scale.countMult * (options.density or 1)
	-- Not x pace (#258); Battle crowd x thins a battle round like density does: fewer dinos,
	-- the gap / crowd, so the spawn phase stays pace x S and the live peak drops x crowd.
	local gap = round.spawnGap / math.max(countMult * (options.crowd or 1), 0.01)
	local plan = Pace.plan(options.index, countMult, scale.promoteChance, { speedMult = options.speedMult }, options.crowd)
	local hpMult = round.hpMult * scale.hpMult * (options.hpMult or 1) * plan.hpX
	local roll = options.random or random

	for _, key in Config.EnemyOrder do
		local count = plan.counts[key]
		if count then
			for _ = 1, count do
				if options.isOver() then
					return false
				end
				local spawnKey = key
				if promotion[key] and roll:NextNumber() < scale.promoteChance then
					spawnKey = promotion[key]
				end
				Enemies.enqueue(options.side, spawnKey, hpMult, plan.cashX, plan.leakX)
				task.wait(gap)
			end
		end
	end
	return true
end

-- Returns true if every round was cleared. The loop is Shared/RoundFlow's (specced): a
-- round whose last dino breaks the Fence is a loss, not a clear (PLAYTEST F4).
function Waves.run(options: RunOptions): boolean
	local side = options.side or 1
	local density = options.density or 1

	return RoundFlow.run({
		first = options.startRound or 1,
		last = #Config.Rounds,
		isOver = options.isOver,
		spawn = function(index)
			ReplicatedStorage:SetAttribute("Round", index)
			if options.onRoundStart then
				options.onRoundStart(index)
			end
			local scale = if options.scale then options.scale() else NO_SCALE
			return Waves.spawnRound({
				side = side,
				index = index,
				scale = scale,
				density = density,
				speedMult = options.speedMult,
				isOver = options.isOver,
			})
		end,
		remaining = function()
			return Enemies.remaining(side)
		end,
		onRoundEnd = options.onRoundEnd,
		wait = function(seconds)
			task.wait(seconds)
		end,
		poll = POLL,
		intermission = INTERMISSION,
	})
end

return Waves
