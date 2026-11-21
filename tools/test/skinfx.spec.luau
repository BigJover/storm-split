--[[
	Premium skin effects (Shared/SkinFx, DECISIONS #459 tiers, PREMIUM_SKINS.md).
	1. No-FX fallback: blank, basic and unknown keys give tier 0, no art match, and every server
	   colour is exactly the caller's fallback (no smoke puff, base grenade art).
	2. Tier rule: R$800 / 1,200 / 1,600 -> tiers 1 / 2 / 3; layers grow with the tier; the Studio
	   override only works in Studio and only 0..3.
	3. Looks: the glow animates from tier 1, flows by phase only at tier 3, a stage-2 tower is
	   hotter; embers from tier 2 within the caps, aura / light only at tier 3 (towers: stage 2).
	4. Kinds: ability / grenade colours only for their own hero; attributes use Skins' naming.
]]

local SkinFx = require(src.shared.SkinFx)
local Skins = require(src.shared.Skins)
local GunArt = require(src.shared.GunArt)

local LAVA = SkinFx.THEMES.LAVA_LORD
local WHITE = Color3.new(1, 1, 1)
local function same(a: Color3, b: Color3): boolean
	return math.abs(a.R - b.R) < 1e-6 and math.abs(a.G - b.G) < 1e-6 and math.abs(a.B - b.B) < 1e-6
end
local function sum(c: Color3): number
	return c.R + c.G + c.B
end

test("blank, basic and unknown keys: no effects, today's colours", function()
	for _, key in { nil, "", "GOLD_RUSH_SAFARI", "ENGRAVED_GOLD", "GOLD_RUSH", "NOPE", 5, {} } do
		eq(SkinFx.item(key), nil, `item {key}`)
		eq(SkinFx.tier(key, 3, true), 0, `tier {key}`)
		ok(same(SkinFx.tracerColour(key, WHITE), WHITE), "tracer")
		local blast, smoke = SkinFx.blastColours(key, "RIFLE", WHITE)
		ok(same(blast, WHITE), "blast")
		eq(smoke, nil, "no puff")
		ok(same(SkinFx.abilityColour(key, "RIFLE", WHITE), WHITE), "ability")
		eq(SkinFx.grenadeArtKey("RIFLE", key), nil, "grenade art")
	end
	for _, pair in { { "hunter", "RIFLE" }, { "hunter", "GOLD_RUSH_SAFARI" }, { "weapon", "RIFLE_ENGRAVED_GOLD" },
		{ "tower", "GOLD_RUSH" }, { "grenade", "RIFLE_GRENADE" }, { "weapon", nil } } do
		eq(SkinFx.fromArt(pair[1], pair[2]), nil, `fromArt {pair[1]} {pair[2]}`)
	end
	eq(SkinFx.embers(LAVA, 0, "hunter"), nil, "tier 0: no embers")
	eq(SkinFx.aura(LAVA, 0, "hunter"), nil, "tier 0: no aura")
	ok(same(SkinFx.glowColour(LAVA, 0, 1.7, 0.3, 1), LAVA.glow), "tier 0: the static authored glow")
end)

test("no grenade variant art headless: the prop falls back like today (nil = the ball)", function()
	eq(GunArt.prop("RIFLE", "grenade", "RIFLE_GRENADE_LAVA_LOB"), nil)
	eq(GunArt.prop("RIFLE", "grenade", nil), nil)
end)

test("tier by price (#459)", function()
	eq(SkinFx.tierForPrice(nil), 0)
	eq(SkinFx.tierForPrice(799), 0)
	eq(SkinFx.tierForPrice(800), 1)
	eq(SkinFx.tierForPrice(1199), 1)
	eq(SkinFx.tierForPrice(1200), 2)
	eq(SkinFx.tierForPrice(1600), 3)
	eq(SkinFx.tierForPrice(16000), 3)
end)

test("layers grow with the tier", function()
	local l0, l1, l2, l3 = SkinFx.layers(0), SkinFx.layers(1), SkinFx.layers(2), SkinFx.layers(3)
	eq(l0.pulse or l0.embers or l0.flow or l0.aura or l0.idle, false, "tier 0 nothing")
	eq(l1.pulse and not l1.embers, true, "tier 1 pulse only")
	eq(l2.pulse and l2.embers and not l2.flow and not l2.aura, true, "tier 2 pulse + embers")
	eq(l3.pulse and l3.embers and l3.flow and l3.aura and l3.idle, true, "tier 3 everything")
end)

test("the Studio override: Studio only, 0..3, premium items only", function()
	eq(SkinFx.tier("MAGMA_MONARCH", nil, false), 3)
	eq(SkinFx.tier("MAGMA_MONARCH", 1, false), 3, "ignored outside Studio")
	eq(SkinFx.tier("MAGMA_MONARCH", 1, true), 1)
	eq(SkinFx.tier("MAGMA_MONARCH", 0, true), 0)
	eq(SkinFx.tier("MAGMA_MONARCH", 7, true), 3, "out of range ignored")
	eq(SkinFx.tier("LAVA_LANCE", 3, true), 3)
end)

test("the catalogue: every item has a theme, a known kind and a tier 0..3", function()
	local kinds = {}
	for _, k in SkinFx.KINDS do
		kinds[k] = true
	end
	for key, item in SkinFx.ITEMS do
		ok(SkinFx.THEMES[item.theme] ~= nil, `{key} theme`)
		ok(kinds[item.kind], `{key} kind`)
		ok(item.fxTier >= 0 and item.fxTier <= SkinFx.MAX_TIER, `{key} tier`)
		ok(item.kind == "tower" or item.hero ~= nil, `{key} hero`)
	end
end)

test("art keys -> premium items", function()
	eq(SkinFx.fromArt("hunter", "MAGMA_MONARCH"), "MAGMA_MONARCH")
	eq(SkinFx.fromArt("weapon", "RIFLE_LAVA_LANCE"), "LAVA_LANCE")
	eq(SkinFx.fromArt("tower", "LAVA_LORD"), "LAVA_LORD")
	eq(SkinFx.fromArt("grenade", "RIFLE_GRENADE_LAVA_LOB"), "LAVA_LOB")
	eq(SkinFx.fromArt("weapon", "MAGMA_MONARCH"), nil, "a hunter key is no gun")
	eq(SkinFx.fromArt("hunter", "LAVA_LANCE"), nil, "a gun key is no body")
	eq(SkinFx.grenadeArtKey("RIFLE", "LAVA_LOB"), "RIFLE_GRENADE_LAVA_LOB")
	eq(SkinFx.grenadeArtKey("PISTOL", "LAVA_LOB"), nil, "another hero's grenade")
end)

test("glow animation: pulses from tier 1, flows by phase at tier 3, hotter at stage 2", function()
	local a, b = SkinFx.glowColour(LAVA, 1, 0, 0), SkinFx.glowColour(LAVA, 1, LAVA.pulseSeconds / 4, 0)
	ok(not same(a, b), "tier 1 changes over time")
	ok(same(SkinFx.glowColour(LAVA, 2, 0.4, 0), SkinFx.glowColour(LAVA, 2, 0.4, 0.5)), "tier 2: phase does nothing")
	ok(not same(SkinFx.glowColour(LAVA, 3, 0.4, 0), SkinFx.glowColour(LAVA, 3, 0.4, 0.5)), "tier 3: phase moves the wave")
	for _, tier in { 1, 2, 3 } do
		ok(sum(SkinFx.glowColour(LAVA, tier, 0.4, 0.2, 1)) > sum(SkinFx.glowColour(LAVA, tier, 0.4, 0.2, 0)), `boost {tier}`)
		for i = 0, 20 do
			local c = SkinFx.glowColour(LAVA, tier, i * 0.37, (i * 0.13) % 1, i % 2)
			ok(c.R >= c.G and c.G >= c.B, `stays lava-coloured {tier} {i}`)
		end
	end
	near(SkinFx.phase(LAVA.flowLength * 2.25, LAVA), 0.25, "phase by height", 1e-9)
end)

test("embers, aura and light: tiers, caps, stage 2, low graphics", function()
	eq(SkinFx.embers(LAVA, 1, "hunter"), nil, "tier 1 no particles")
	eq(SkinFx.embers(LAVA, 3, "hunter", 0, true), nil, "low graphics: none")
	for _, tier in { 2, 3 } do
		local h = SkinFx.embers(LAVA, tier, "hunter") :: any
		ok(h.rate > 0 and h.rate <= SkinFx.HUNTER_RATE_CAP, `hunter rate {tier}`)
		local t0, t2 = SkinFx.embers(LAVA, tier, "tower", 0) :: any, SkinFx.embers(LAVA, tier, "tower", 2) :: any
		ok(t2.rate > t0.rate and t2.rate <= SkinFx.TOWER_RATE_CAP, `stage 2 stronger {tier}`)
		ok((SkinFx.embers(LAVA, tier, "weapon") :: any).rate <= 2, "faint at the muzzle")
	end
	eq(SkinFx.aura(LAVA, 2, "hunter"), nil, "aura is tier 3")
	ok(SkinFx.aura(LAVA, 3, "hunter") ~= nil, "tier 3 hunter aura")
	eq(SkinFx.aura(LAVA, 3, "tower", 1), nil, "tower aura only at stage 2")
	ok(SkinFx.aura(LAVA, 3, "tower", 2) ~= nil, "stage 2 tower aura")
	eq(SkinFx.light(2, "hunter"), nil, "light is tier 3")
	ok(SkinFx.light(3, "hunter") ~= nil, "tier 3 light")
end)

test("ability and grenade colours only for their own hero; attributes use Skins' naming", function()
	ok(same(SkinFx.abilityColour("VOLCANO_ROAR", "RIFLE", WHITE), LAVA.ability), "Volcano Roar on the Big Game Hunter")
	ok(same(SkinFx.abilityColour("VOLCANO_ROAR", "PISTOL", WHITE), WHITE), "not on another hero")
	ok(same(SkinFx.abilityColour("LAVA_LANCE", "RIFLE", WHITE), WHITE), "a gun skin is no ability skin")
	local blast, smoke = SkinFx.blastColours("LAVA_LOB", "RIFLE", WHITE)
	ok(same(blast, LAVA.blast) and smoke ~= nil, "Lava Lob: orange blast + dark puff")
	ok(same(SkinFx.blastColours("LAVA_LOB", "MEDIC", WHITE), WHITE), "not on another hero")
	ok(same(SkinFx.tracerColour("LAVA_LANCE", WHITE), LAVA.tracer), "orange tracer")
	ok(same(SkinFx.tracerColour("MAGMA_MONARCH", WHITE), WHITE), "a hunter skin brings no tracer")
	for _, kind in { "weapon", "grenade", "ability" } do
		eq(SkinFx.attribute(kind, "RIFLE"), Skins.attribute(Skins.slot(kind, "RIFLE")), kind)
	end
end)

------------------------------------------------------------------ the pack tier (#462)

local FIRE = SkinFx.ELEMENTS.fire
local PACK = SkinFx.PACKS.LAVA_LORD_RIFLE

test("pack ownership: only a FULL class pack counts (set or list), sorted", function()
	local all = {}
	for _, k in PACK.items do
		all[k] = true
	end
	eq(table.concat(SkinFx.ownedPacks(all), ","), "LAVA_LORD_RIFLE", "every item -> the pack")
	eq(table.concat(SkinFx.ownedPacks(PACK.items), ","), "LAVA_LORD_RIFLE", "a list works too")
	for _, missing in PACK.items do
		local some = table.clone(all)
		some[missing] = nil
		eq(#SkinFx.ownedPacks(some), 0, `missing {missing}: no pack`)
	end
	eq(#SkinFx.ownedPacks(nil), 0)
	eq(#SkinFx.ownedPacks({}), 0)
	eq(#SkinFx.ownedPacks({ MAGMA_MONARCH = true, GOLD_RUSH_SAFARI = true }), 0, "singles are not a pack")
	eq(#SkinFx.ownedPacks({ MAGMA_MONARCH = false, LAVA_LANCE = true, LAVA_LORD = true, LAVA_LOB = true, VOLCANO_ROAR = true }), 0, "false is not owned")
end)

test("pack attribute round trip; unknown keys dropped", function()
	local packs = SkinFx.parsePacks(SkinFx.packsValue({ "LAVA_LORD_RIFLE" }))
	eq(packs.LAVA_LORD_RIFLE, true)
	local junk = SkinFx.parsePacks("NOPE, LAVA_LORD_RIFLE ,,")
	eq(junk.NOPE, nil)
	eq(junk.LAVA_LORD_RIFLE, true)
	eq(next(SkinFx.parsePacks(nil)), nil)
	eq(next(SkinFx.parsePacks(7)), nil)
end)

test("tier 4 only on the owned pack's own items; blank / basic unchanged", function()
	local packs = { LAVA_LORD_RIFLE = true }
	for _, k in PACK.items do
		eq(SkinFx.tier(k, nil, false, packs), SkinFx.PACK_TIER, k)
		eq(SkinFx.tier(k, nil, false, nil), SkinFx.ITEMS[k].fxTier, `{k} without the pack`)
		eq(SkinFx.tier(k, nil, false, {}), SkinFx.ITEMS[k].fxTier, `{k} with no packs`)
	end
	for _, key in { nil, "", "GOLD_RUSH_SAFARI", "ENGRAVED_GOLD", "NOPE" } do
		eq(SkinFx.tier(key, nil, false, packs), 0, `blank / basic {key}`)
		eq(SkinFx.tier(key, 4, true, packs), 0, `override never lights a basic {key}`)
	end
	eq(SkinFx.tier("MAGMA_MONARCH", 4, true), 4, "Studio override reaches the pack tier")
	eq(SkinFx.tier("MAGMA_MONARCH", 4, false), 3, "not outside Studio")
	eq(SkinFx.tier("MAGMA_MONARCH", 1, true, packs), 1, "Studio override wins (to compare)")
	local l3, l4 = SkinFx.packLayers(3), SkinFx.packLayers(4)
	eq(l3.aura or l3.marks or l3.takedown or l3.heat or l3.trail or l3.splash, false, "tier 3: no pack layer")
	eq(l4.aura and l4.marks and l4.takedown and l4.heat and l4.trail and l4.splash, true, "tier 4: all of it")
	local l = SkinFx.layers(4)
	eq(l.pulse and l.embers and l.flow and l.aura and l.idle, true, "tier 4 keeps tier 3's layers")
	ok(SkinFx.embers(LAVA, 4, "hunter") ~= nil and SkinFx.light(4, "hunter") ~= nil, "tier 4 embers + light")
end)

test("every pack's items exist, share its theme, and cover the five kinds once", function()
	for key, pack in SkinFx.PACKS do
		local kinds = {}
		for _, k in pack.items do
			local item = SkinFx.ITEMS[k]
			ok(item ~= nil, `{key}: {k} is a premium item`)
			eq(item.theme, pack.theme, `{key}: {k} theme`)
			ok(item.kind == "tower" or item.hero == pack.hero, `{key}: {k} hero`)
			ok(not kinds[item.kind], `{key}: one {item.kind}`)
			kinds[item.kind] = true
		end
		for _, kind in SkinFx.KINDS do
			ok(kinds[kind], `{key} has a {kind}`)
		end
	end
end)

test("elements: every theme has one, data in every slot; only fire is built", function()
	local themes = { "LAVA_LORD", "CYBER_RAPTOR", "TYRANT_KING", "NEBULA", "GEODE" }
	local seen = {}
	for _, theme in themes do
		local e = SkinFx.element(theme) :: any
		ok(e ~= nil, `{theme} element`)
		ok(not seen[e], `{theme}: its own element (not a reskin)`)
		seen[e] = true
		for _, slot in { "aura", "mark", "takedown", "heat", "muzzle", "puff", "trail", "splash" } do
			ok(e[slot] ~= nil, `{theme} {slot}`)
		end
		ok(type(e.behaviour) == "string", `{theme} behaviour`)
		eq(e.stub, theme ~= "LAVA_LORD", `{theme} stub flag`)
	end
	eq(SkinFx.element("NOPE"), nil)
	eq(SkinFx.element(nil), nil)
	eq(SkinFx.THEME_ELEMENTS.LAVA_LORD, "fire")
	for key in SkinFx.THEMES do
		ok(SkinFx.element(key) ~= nil, `built theme {key} has an element`)
	end
end)

test("reactive weapon: heat climbs per shot, decays, ramps cool -> white-hot", function()
	local h = 0
	for _ = 1, 3 do
		h = SkinFx.heatAfterShots(FIRE, h, 1)
	end
	near(h, 3 * FIRE.heat.perShot, "three shots", 1e-9)
	eq(SkinFx.heatAfterShots(FIRE, 0.95, 5), 1, "capped at 1")
	eq(SkinFx.heatAfterShots(FIRE, 0.3, -2), 0.3, "negative shots ignored")
	near(SkinFx.heatAfter(FIRE, 0.5, 1), 0.5 - FIRE.heat.decay, "decay a second", 1e-9)
	eq(SkinFx.heatAfter(FIRE, 0.1, 10), 0, "never below 0")
	ok(same(SkinFx.heatColour(FIRE, 0), FIRE.heat.cool), "cold = deep red")
	ok(same(SkinFx.heatColour(FIRE, 0.5), FIRE.heat.hot), "warm = the authored glow")
	ok(same(SkinFx.heatColour(FIRE, 1), FIRE.heat.white), "max = white-hot")
	ok(same(SkinFx.heatColour(FIRE, 7), FIRE.heat.white), "clamped")
	local prev = -1
	for i = 0, 10 do
		local s = sum(SkinFx.heatColour(FIRE, i / 10))
		ok(s >= prev, `brighter with heat {i}`)
		prev = s
	end
	eq(SkinFx.muzzleBurst(FIRE, FIRE.heat.burstAt - 0.01), false, "no burst cool")
	eq(SkinFx.muzzleBurst(FIRE, FIRE.heat.burstAt), true, "burst when hot")
	local from = FIRE.heat.puffFrom
	eq(SkinFx.coolPuff(FIRE, from + 0.01, from - 0.01), true, "puff cooling through the line")
	eq(SkinFx.coolPuff(FIRE, from - 0.01, from - 0.02), false, "no puff already cool")
	eq(SkinFx.coolPuff(FIRE, from + 0.2, from + 0.1), false, "no puff still hot")
	eq(SkinFx.coolPuff(FIRE, from + 0.1, from + 0.1, true), true, "reload while hot: puff")
	eq(SkinFx.coolPuff(FIRE, 0.05, 0.05, true), false, "reload cold: none")
	-- one magazine at each class's pace (Config Heroes rate / magazine) reaches the burst; a few
	-- shots don't
	local Config = require(src.shared.Config)
	for hero, row in Config.Heroes do
		local r = row :: any
		local heat, burstAt = 0, nil
		for shot = 1, r.magazine do
			heat = SkinFx.heatAfter(FIRE, SkinFx.heatAfterShots(FIRE, heat, 1, r.rate), 1 / r.rate)
			if not burstAt and SkinFx.muzzleBurst(FIRE, heat) then
				burstAt = shot
			end
		end
		ok(burstAt ~= nil, `{hero}: a full magazine gets hot enough to burst`)
		ok((burstAt or 0) >= 2, `{hero}: not from the first shot`)
	end
	ok(SkinFx.shotHeat(FIRE, 1.2) > SkinFx.shotHeat(FIRE, 8), "slow guns heat more a shot")
	near(SkinFx.shotHeat(FIRE, nil), FIRE.heat.perShot, "unknown rate = the reference", 1e-9)
end)

test("pack perf caps: aura rate, marks, splashes, distance, low graphics", function()
	for name, e in SkinFx.ELEMENTS do
		local a = SkinFx.packAura(e, 4) :: any
		ok(a.rate > 0 and a.rate <= SkinFx.PACK_RATE_CAP, `{name} aura rate`)
		eq(SkinFx.packAura(e, 3), nil, `{name}: no aura below the pack tier`)
		eq(SkinFx.packAura(e, 4, true), nil, `{name}: none on low graphics`)
		ok(e.mark.lifetime <= 4 and e.mark.every >= 1.5, `{name} marks short-lived and spaced`)
		ok(e.splash.lifetime <= 2, `{name} splash brief`)
	end
	ok(SkinFx.MARK_CAP <= 20 and SkinFx.SPLASH_CAP <= 6, "global caps")
	eq(SkinFx.markDue(FIRE, FIRE.mark.every, true), true)
	eq(SkinFx.markDue(FIRE, FIRE.mark.every, false), false, "no marks in the air")
	eq(SkinFx.markDue(FIRE, FIRE.mark.every - 0.1, true), false, "spaced")
	eq(SkinFx.packVisible(SkinFx.PACK_DISTANCE, false), true)
	eq(SkinFx.packVisible(SkinFx.PACK_DISTANCE + 1, false), false, "culled by distance")
	eq(SkinFx.packVisible(5, true), false, "off on low graphics")
end)
