--[[
	The walker module (PLAN 9g, DECISIONS #315; Shared/Walker): the state machine (each
	transition), leash, retreat + heal + respawn, Flanking, Targets first, bite-back with
	resist, trample (and Dodge), boss hold once per boss, the side cap, never off its side,
	and that a sold tower clears its walkers (Server/Walkers).
]]

local fs = require("@lune/fs")
local Walker = require(src.shared.Walker)

local function params(over: { [string]: any }?): Walker.Params
	local p: { [string]: any } = {
		maxHp = 60, speed = 30, reach = 4, range = 22, leash = 1.5, retreatShare = 0.3,
		respawn = 8, homeHeal = 15, rate = 1.5, hold = 0.5, bossHold = 0, firstDiveX = 1,
		flanking = false, targetsFirst = false, hitsAir = false, resist = 0, dodge = false,
		dodgeEvery = 3, trampleSize = 3, trampleShare = 0.25, smallSize = 2,
	}
	for k, v in over or {} do
		p[k] = v
	end
	return p :: any
end

local function dino(id: any, at: number, fromHome: number, over: { [string]: any }?): Walker.Dino
	local d: { [string]: any } = { id = id, at = at, side = 1, boss = false, flying = false, sizesLeft = 1, fromHome = fromHome }
	for k, v in over or {} do
		d[k] = v
	end
	return d :: any
end

local HOME = 100

test("home -> out -> fight (pounce, then bites every 1 / rate) -> back -> home", function()
	local p = params()
	local w = Walker.new(1, p, HOME)
	eq(w.state, "home")
	eq(#Walker.step(w, 0.1, 0, p, HOME, {}), 0, "nothing in range: stays home")
	eq(w.state, "home")
	local raptor = dino("a", 130, 15)
	Walker.step(w, 0.1, 0, p, HOME, { raptor })
	eq(w.state, "out", "a target in range: runs out")
	eq(w.target, "a")
	local hits = Walker.step(w, 0.5, 0.5, p, HOME, { raptor })
	eq(w.at, 115, "runs 30 studs/s along the track")
	eq(#hits, 0)
	hits = Walker.step(w, 0.5, 1, p, HOME, { raptor })
	eq(w.state, "fight", "in reach: fight")
	ok(#hits == 1 and hits[1].pounce and hits[1].hold == 0.5, "the first contact is a pounce that holds a non-boss")
	eq(#Walker.step(w, 0.1, 1.1, p, HOME, { raptor }), 0, "next bite not due")
	hits = Walker.step(w, 0.1, 1 + 1 / 1.5 + 1e-6, p, HOME, { raptor })
	ok(#hits == 1 and not hits[1].pounce and hits[1].hold == 0, "a plain bite 1 / rate later")
	raptor.at = 140
	Walker.step(w, 0.1, 2, p, HOME, { raptor })
	eq(w.at, 140, "follows its target")
	Walker.step(w, 0, 2.1, p, HOME, {})
	eq(w.state, "back", "target gone: back")
	Walker.step(w, 0.5, 2.6, p, HOME, {})
	eq(w.at, 140 - 22.5, "runs home at speed x 1.5")
	Walker.step(w, 1, 3.6, p, HOME, {})
	eq(w.state, "home", "home again")
end)

test("First dive x only on the first pounce after leaving home", function()
	local p = params({ firstDiveX = 2 })
	local w = Walker.new(1, p, HOME)
	local a = dino("a", HOME, 5)
	Walker.step(w, 0.1, 0, p, HOME, { a })
	local hits = Walker.step(w, 0.1, 0.1, p, HOME, { a })
	eq(hits[1].x, 2, "first pounce x2")
	Walker.step(w, 0.1, 0.2, p, HOME, {}) -- a gone: back (already home: arrives)
	eq(w.state, "home")
	local b = dino("b", HOME + 2, 5)
	Walker.step(w, 0.1, 0.3, p, HOME, { b })
	hits = Walker.step(w, 0.1, 0.4, p, HOME, { b })
	eq(hits[1].x, 2, "left home again: fresh")
	w.state = "out"
	w.target = "c"
	local c = dino("c", HOME + 3, 5)
	hits = Walker.step(w, 0.1, 0.5, p, HOME, { c })
	eq(hits[1].x, 1, "a second pounce on the same outing: x1")
end)

test("leash: a target further than range x leash from home is let go", function()
	local p = params()
	local w = Walker.new(1, p, HOME)
	local a = dino("a", 130, 20)
	Walker.step(w, 0.1, 0, p, HOME, { a })
	eq(w.state, "out")
	a.fromHome = 22 * 1.5 - 0.1
	Walker.step(w, 0.1, 0.1, p, HOME, { a })
	eq(w.state, "out", "just inside the leash")
	a.fromHome = 22 * 1.5 + 0.1
	Walker.step(w, 0, 0.2, p, HOME, { a })
	eq(w.state, "back", "past the leash: back")
end)

test("retreat at the HP share, heal at home, leave again at 80 %; down -> respawn", function()
	local p = params()
	local w = Walker.new(1, p, HOME)
	local a = dino("a", HOME + 2, 5)
	Walker.step(w, 0.1, 0, p, HOME, { a })
	Walker.step(w, 0.1, 0.1, p, HOME, { a })
	eq(w.state, "fight")
	Walker.bitten(w, 60 * 0.7, p, 0.2)
	Walker.step(w, 0.1, 0.3, p, HOME, { a })
	ok(w.state == "back" or w.state == "home", "HP <= 30 %: runs home")
	Walker.step(w, 1, 1.3, p, HOME, { a })
	eq(w.state, "home")
	w.hp = 20
	Walker.step(w, 1, 2.3, p, HOME, { a })
	ok(math.abs(w.hp - 35) < 1e-6 and w.state == "home", "heals 15 HP/s, stays home below 80 %")
	Walker.step(w, 1, 3.3, p, HOME, { a })
	eq(w.state, "out", "at 80 %+ with a target: out again")
	Walker.step(w, 0.1, 4.4, p, HOME, { a })
	Walker.bitten(w, 1000, p, 5)
	eq(w.state, "down", "0 HP: down")
	eq(w.hp, 0)
	Walker.step(w, 1, 12.9, p, HOME, { a })
	eq(w.state, "down", "respawn 8 s not over")
	Walker.step(w, 0.1, 13, p, HOME, { a })
	ok(w.state == "home" and w.hp == 60 and w.at == HOME, "back at home with full HP after 8 s")
	Walker.down(w, params({ respawn = 8 * 0.7 }), 20)
	eq(w.downUntil, 20 + 5.6, "Walker respawn x shortens it")
end)

test("targets: nearest to home by default; Targets first = furthest along; ground only unless Hits air; own side and range only", function()
	local p = params()
	local w = Walker.new(1, p, HOME)
	local near, far = dino("near", 90, 5), dino("far", 140, 18)
	eq((Walker.pick(w, { far, near }, p) :: any).id, "near")
	eq((Walker.pick(w, { far, near }, params({ targetsFirst = true })) :: any).id, "far")
	local bird = dino("bird", 150, 3, { flying = true })
	eq((Walker.pick(w, { bird, far }, p) :: any).id, "far", "a flyer is skipped")
	eq((Walker.pick(w, { bird, far }, params({ hitsAir = true })) :: any).id, "bird", "Hits air (Sky Leap)")
	eq(Walker.pick(w, { dino("x", 100, 5, { side = 2 }) }, p), nil, "never another camp's dino")
	eq(Walker.pick(w, { dino("x", 100, 23) }, p), nil, "outside the range")
	-- Never off its side: a target that turns out to be on another side is let go.
	local a = dino("a", HOME, 3)
	Walker.step(w, 0.1, 0, p, HOME, { a })
	a.side = 2
	Walker.step(w, 0, 0.1, p, HOME, { a })
	ok(w.target == nil and (w.state == "back" or w.state == "home"), "let go: runs home")
end)

test("Flanking: no two walkers of a tower on one dino while another is free", function()
	local p = params({ flanking = true })
	local w = Walker.new(1, p, HOME)
	local a, b = dino("a", 95, 3), dino("b", 120, 15)
	eq((Walker.pick(w, { a, b }, p, { a = true }) :: any).id, "b", "a is taken: b")
	eq((Walker.pick(w, { a }, p, { a = true }) :: any).id, "a", "nothing else free: a anyway")
	eq((Walker.pick(w, { a, b }, params(), { a = true }) :: any).id, "a", "without Flanking: the nearest")
end)

test("bite-back with Walker resist %; Dodge ignores one bite per Dodge every (s)", function()
	local p = params({ resist = 25 })
	local w = Walker.new(1, p, HOME)
	eq(Walker.bitten(w, 10, p, 0), 0, "at home: nothing bites it")
	w.state = "fight"
	eq(Walker.bitten(w, 10, p, 0), 7.5, "x (1 - 25 %)")
	local d = params({ dodge = true })
	local x = Walker.new(1, d, HOME)
	x.state = "fight"
	eq(Walker.bitten(x, 10, d, 0), 0, "dodged")
	eq(Walker.bitten(x, 10, d, 1), 10, "the next bite inside 3 s lands")
	eq(Walker.bitten(x, 10, d, 3), 0, "3 s later: dodged again")
end)

test("trample: big dinos (>= Trample size sizes left) in its path take Trample share of its max HP, once per dino; not its target; Dodge: never (#328)", function()
	local p = params()
	local w = Walker.new(1, p, HOME)
	w.state = "out"
	w.at = 120
	w.target = "t"
	local big = dino("big", 121, 10, { sizesLeft = 3 })
	eq(Walker.trample(w, big, p, 0), 15, "25 % of 60")
	eq(Walker.trample(w, big, p, 0.1), 0, "once per dino")
	eq(Walker.trample(w, dino("small", 121, 10, { sizesLeft = 2 }), p, 0), 0, "too small to trample")
	eq(Walker.trample(w, dino("t", 121, 10, { sizesLeft = 5 }), p, 0), 0, "not the one it fights")
	eq(Walker.trample(w, dino("far", 130, 10, { sizesLeft = 5 }), p, 0), 0, "not in its path")
	local d = params({ dodge = true, trampleSize = 1 })
	local x = Walker.new(1, d, HOME)
	x.state = "out"
	x.at = 120
	eq(Walker.trample(x, dino("s", 120, 1, { sizesLeft = 2 }), d, 0), 0, "Dodge: never from small dinos")
	eq(Walker.trample(x, dino("b", 120, 1, { sizesLeft = 3 }), d, 0), 0, "Dodge: a 3-size dino passes, no trample (#328)")
	eq(Walker.trample(x, dino("boss", 120, 1, { sizesLeft = 5, boss = true }), d, 0), 0, "Dodge: not even a boss")
	eq(x.hp, 60, "untouched")
end)

test("boss hold: Boss hold (s) once per boss; no Hold on bosses otherwise", function()
	local p = params({ bossHold = 0.5 })
	local w = Walker.new(1, p, HOME)
	local boss = dino("boss", HOME, 3, { boss = true })
	Walker.step(w, 0.1, 0, p, HOME, { boss })
	local hits = Walker.step(w, 0.1, 0.1, p, HOME, { boss })
	eq(hits[1].hold, 0.5, "first pounce on this boss: held")
	w.state = "out"
	hits = Walker.step(w, 0.1, 0.2, p, HOME, { boss })
	eq(hits[1].hold, 0, "the same boss again: no hold")
	local q = params()
	local y = Walker.new(1, q, HOME)
	Walker.step(y, 0.1, 0, q, HOME, { boss })
	hits = Walker.step(y, 0.1, 0.1, q, HOME, { boss })
	eq(hits[1].hold, 0, "no Boss hold: a boss is never held (Hold is non-bosses only)")
end)

test("post (rangers, 9j): walks out to its point, hits in range, never chases, patches up at home", function()
	local p = params({ regen = 5 })
	local w = Walker.new(1, p, HOME, 80)
	eq(w.state, "home", "starts at the cabin")
	Walker.step(w, 0.1, 0, p, HOME, {})
	eq(w.state, "out", "leaves with no target: it walks to its post")
	Walker.step(w, 0.5, 0.5, p, HOME, {})
	ok(w.state == "out" and w.at == 85, "walks 30 studs/s toward the post")
	Walker.step(w, 0.5, 1, p, HOME, {})
	ok(w.state == "post" and w.at == 80, "arrives")
	local a = dino("a", 130, 10)
	local hits = Walker.step(w, 0.1, 1.1, p, HOME, { a })
	ok(#hits == 1 and w.at == 80, "hits without moving")
	a.at = 60
	Walker.step(w, 1, 2.1, p, HOME, { a })
	eq(w.at, 80, "never chases")
	w.hp = 30
	Walker.step(w, 1, 3.1, p, HOME, {})
	eq(w.hp, 35, "Walker regen heals at the post")
	eq(Walker.trample(w, dino("big", 80, 0, { sizesLeft = 5 }), p, 3.2), 0, "never trampled at a post")
	w.hp = 18
	Walker.step(w, 0.1, 3.3, p, HOME, {})
	eq(w.state, "back", "bitten to the retreat share: walks home")
	Walker.step(w, 1, 4.3, p, HOME, {})
	eq(w.state, "home")
	Walker.step(w, 3, 7.3, p, HOME, {})
	ok(w.state == "out" or w.state == "home", "heals at home, then goes back out")
	Walker.down(w, p, 8)
	Walker.step(w, 0.1, 17, p, HOME, {})
	ok(w.state == "home" and w.at == HOME, "respawns at the cabin, then walks out again")
	Walker.step(w, 0.1, 17.1, p, HOME, {})
	Walker.step(w, 1, 18.1, p, HOME, {})
	eq(w.state, "post")
	Walker.setPost(w, 120)
	eq(w.state, "out", "a moved post: it walks there")
	Walker.step(w, 2, 20.1, p, HOME, {})
	ok(w.state == "post" and w.at == 120, "at the new post")
end)

test("the side cap: walkers past it aren't spawned; Heals between rounds; HP grows per tier like towers", function()
	eq(Walker.room(5, 20, 24), 4)
	eq(Walker.room(5, 24, 24), 0)
	eq(Walker.room(3, 0, 24), 3)
	eq(Walker.room(10, 30, 24), 0, "never negative")
	local p = params()
	local w = Walker.new(1, p, HOME)
	Walker.down(w, p, 0)
	Walker.roundEnd(w, p, HOME, false)
	eq(w.state, "down", "no Heals between rounds: still down")
	Walker.roundEnd(w, p, HOME, true)
	ok(w.state == "home" and w.hp == 60, "Heals between rounds: back and full")
	eq(Walker.maxHp(60, 3, 0.15, 3), 60 * 3 * 1.45)
end)

test("Server/Walkers: a sold or removed tower clears its walkers; Towers asks it", function()
	local server = fs.readFile("src/server/Walkers.luau")
	ok(server:find("function Walkers.clear(tower", 1, true) ~= nil, "Walkers.clear exists")
	local towers = fs.readFile("src/server/Towers.luau")
	local remove = towers:find("function Towers.remove(", 1, true)
	ok(remove ~= nil, "Towers.remove")
	local body = towers:sub(remove :: number, (towers:find("\nend\n", remove :: number, true) or #towers))
	ok(body:find("Walkers.clear(tower)", 1, true) ~= nil, "removing a tower clears its walkers")
end)
