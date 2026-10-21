--[[
	Melee (PLAN 10b T136, DECISIONS #366-#370, names DINO_REVIEW Round 20): Shared/Melee's
	hit rule and Shared/HunterKit's data and PvP rules over the `Hunter Kit` sheet. The
	exporter's refusal of a stun or knockback on hunters is a doctest (validate_kit).
]]
local Config = require(src.shared.Config)
local HunterKit = require(src.shared.HunterKit)
local Melee = require(src.shared.Melee)

local NAMES = { -- Round 20
	PISTOL = "Hunting Knife",
	RIFLE = "Stock Swing",
	SHOTGUN = "Brush Machete",
	MEDIC = "Splint Stick",
}

local ORIGIN = Vector3.new(0, 3, 0)
local NORTH = Vector3.new(0, 0, -1)

test("every hunter has a melee with its Round 20 name and the seeds", function()
	for key, hero in Config.Heroes do
		local row = HunterKit.row(key)
		ok(row ~= nil, `{key} has a kit`)
		eq(row.meleeName, NAMES[key], `{key} melee name`)
		eq(row.display, hero.display, `{key} hunter name`)
	end
	-- One-line effects: quickest knife, heaviest stock, the machete sweeps 3, the stick slows.
	local knife, stock, machete, stick = HunterKit.row("PISTOL"), HunterKit.row("RIFLE"), HunterKit.row("SHOTGUN"), HunterKit.row("MEDIC")
	for _, other in { stock, machete, stick } do
		ok(knife.swingTime < other.swingTime, "the Hunting Knife swings fastest")
	end
	for _, other in { knife, machete, stick } do
		ok(stock.meleeDamage > other.meleeDamage, "the Stock Swing hits hardest")
	end
	eq(machete.meleeTargets, 3)
	ok(machete.arc > knife.arc and machete.arc > stock.arc, "the Brush Machete sweeps widest")
	eq(stick.meleeEffect, "slow")
	ok(stick.meleeEffectPercent > 0 and stick.meleeEffectSeconds > 0, "the Splint Stick slows dinos")
	eq(HunterKit.row(nil), nil)
	eq(HunterKit.row("NOPE"), nil)
end)

test("reach: the base, + trained Reach % capped at Trained reach max (20 %, #370 / #395)", function()
	eq(Config.Tuning.TrainedReachMax, 20)
	local base = HunterKit.row("PISTOL").reach
	eq(Melee.reach("PISTOL"), base)
	eq(Melee.reach("PISTOL", 0), base)
	near(Melee.reach("PISTOL", 10), base * 1.1)
	near(Melee.reach("PISTOL", 20), base * 1.2)
	near(Melee.reach("PISTOL", 500), base * 1.2, "never past the cap")
	eq(Melee.reach("PISTOL", -5), base)
	eq(Melee.reach("PISTOL", "lots" :: any), base, "an unset or bad stat reads 0 (10c fills it)")
	eq(Melee.reach("PISTOL", 0 / 0), base)
	eq(Melee.reach(nil), 0, "no hunter: no melee")
	eq(HunterKit.REACH_ATTRIBUTE, "TrainedReach")
end)

test("a swing hits in reach and misses past it (to the target's near edge)", function()
	ok(Melee.inArc(ORIGIN, NORTH, ORIGIN + NORTH * 5.9, 6, 60), "in reach")
	ok(not Melee.inArc(ORIGIN, NORTH, ORIGIN + NORTH * 6.1, 6, 60), "just past reach")
	ok(Melee.inArc(ORIGIN, NORTH, ORIGIN + NORTH * 7.5, 6, 60, 2), "a big dino's near edge is in reach")
	ok(not Melee.inArc(ORIGIN, NORTH, ORIGIN + NORTH * 8.5, 6, 60, 2), "...not past it")
	local trained = Melee.reach("PISTOL", 20)
	local point = ORIGIN + NORTH * (HunterKit.row("PISTOL").reach + 0.5)
	ok(not Melee.inArc(ORIGIN, NORTH, point, Melee.reach("PISTOL"), 60), "untrained misses")
	ok(Melee.inArc(ORIGIN, NORTH, point, trained, 60), "trained Reach reaches it")
end)

test("a swing hits inside its arc only", function()
	local function at(degrees: number): Vector3
		local r = math.rad(degrees)
		return ORIGIN + Vector3.new(math.sin(r), 0, -math.cos(r)) * 4
	end
	ok(Melee.inArc(ORIGIN, NORTH, at(29), 6, 60), "inside half the arc")
	ok(not Melee.inArc(ORIGIN, NORTH, at(31), 6, 60), "outside half the arc")
	ok(not Melee.inArc(ORIGIN, NORTH, at(180), 6, 120), "behind")
	ok(Melee.inArc(ORIGIN, NORTH, at(59), 6, 120), "a wide sweep reaches the side")
	ok(Melee.inArc(ORIGIN, Vector3.new(0, -1, 0), at(170), 6, 60), "looking straight down: reach only")
	ok(Melee.inArc(ORIGIN, NORTH, ORIGIN + Vector3.new(0, -2, 0), 6, 60), "right underfoot")
	ok(Melee.inArc(ORIGIN, NORTH * 3 + Vector3.new(0, -2, 0), at(20), 6, 60), "looking down at a small dino still aims by heading")
end)

test("pick: nearest first, at most Melee targets", function()
	local points = { ORIGIN + NORTH * 5, ORIGIN + NORTH * 2, ORIGIN + NORTH * 4, ORIGIN + NORTH * 3, ORIGIN - NORTH * 2 }
	local one = Melee.pick(ORIGIN, NORTH, points, nil, 6, 60, 1)
	eq(#one, 1)
	eq(one[1], 2, "the nearest")
	local three = Melee.pick(ORIGIN, NORTH, points, nil, 6, 120, 3)
	eq(#three, 3)
	eq(three[1], 2)
	eq(three[2], 4)
	eq(three[3], 3)
	eq(#Melee.pick(ORIGIN, NORTH, points, nil, 6, 120, 10), 4, "the one behind is never hit")
	eq(#Melee.pick(ORIGIN, NORTH, {}, nil, 6, 60, 3), 0)
end)

test("swing time: one swing per Swing time (20 % network slack), the first always", function()
	ok(Melee.ready(nil, 10, 0.5))
	ok(not Melee.ready(10, 10.3, 0.5), "too soon")
	ok(Melee.ready(10, 10.4, 0.5), "at the slack")
	ok(Melee.ready(10, 10.5, 0.5))
	eq(Melee.readyAt(10, 0.5), 10.5)
	eq(Melee.readyAt(nil, 0.5), 0)
end)

test("dino effects: a slow or an amp; none is nothing", function()
	local stick = HunterKit.row("MEDIC")
	local e = HunterKit.dinoEffect(stick.meleeEffect, stick.meleeEffectPercent, stick.meleeEffectSeconds)
	ok(e ~= nil and e.kind == "slow", "the Splint Stick slows")
	eq(HunterKit.dinoEffect("none", 30, 2), nil)
	eq(HunterKit.dinoEffect("stun", 30, 2), nil, "no other kind exists")
	eq(HunterKit.dinoEffect("slow", 0, 2), nil)
	eq(HunterKit.dinoEffect("slow", 150, 2).percent, 100)
	eq(HunterKit.dinoEffect("amp", 20, 1).percent, 20)
	eq(HunterKit.BREAKS, 1, "a kit hit breaks at most 1 size")
end)

test("PvP: x PvP hunter damage (0.5), 0 for the own side and under Camo Cover", function()
	eq(Config.Tuning.PvPHunterDamage, 0.5)
	near(HunterKit.vsHunter(10, 1, 2, false), 5, "an enemy hunter")
	eq(HunterKit.vsHunter(10, 1, 1, false), 0, "no friendly fire")
	eq(HunterKit.vsHunter(10, 1, 2, true), 0, "Camo Cover")
end)

test("PvP: no stun or knockback on hunters; a slow at most 30 % for 2 s (#368)", function()
	eq(Config.Tuning.KitHunterSlowMax, 30)
	eq(Config.Tuning.KitHunterSlowMaxS, 2)
	local p, s = HunterKit.hunterSlow("slow", 30, 2)
	eq(p, 30)
	eq(s, 2)
	p, s = HunterKit.hunterSlow("slow", 80, 9)
	eq(p, 30, "clamped")
	eq(s, 2, "clamped")
	for _, kind in { "stun", "knockback", "none", "amp", nil :: any } do
		p, s = HunterKit.hunterSlow(kind, 30, 2)
		eq(p, 0, `{tostring(kind)} on a hunter is nothing`)
		eq(s, 0)
	end
	for key in Config.Heroes do
		local row = HunterKit.row(key)
		ok(row.meleeHunterEffect == "none" or row.meleeHunterEffect == "slow", `{key} melee hunter effect`)
		ok(row.meleeHunterPercent <= 30 and row.meleeHunterSeconds <= 2, `{key} melee hunter slow within the caps`)
	end
end)
