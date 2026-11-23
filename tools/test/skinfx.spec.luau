--[[
	Premium skin effects (Shared/SkinFx, DECISIONS #459 tiers, PREMIUM_SKINS.md).
	1. No-FX fallback: blank, basic and unknown keys give tier 0, no art match, and every server
	   colour is exactly the caller's fallback (no smoke puff, base grenade art).
	2. Tier rule: R$800 / 1,200 / 1,600 -> tiers 1 / 2 / 3; layers grow with the tier; the Studio
	   override only works in Studio and only 0..3.
	3. Looks: the glow animates from tier 1, flows by phase only at tier 3, a stage-2 tower is
	   hotter; embers from tier 2 within the caps, aura / light only at tier 3 (towers: stage 2).
	4. Kinds: ability / grenade colours only for their own hero; attributes use Skins' naming.
	5. Pack layer v3 (#465): quality scaling, the whole-layer rate cap, footprint crusting, the
	   standing-still ring, overheat once per heat-up, muzzle flash / haze growing with heat, the
	   take-down shockwave + crack, drip timing, built-in textures only, tier 3 vs pack trail.
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

test("elements: every theme has one, data in every slot; all five built", function()
	local themes = { "LAVA_LORD", "CYBER_RAPTOR", "TYRANT_KING", "NEBULA", "GEODE" }
	local seen = {}
	for _, theme in themes do
		local e = SkinFx.element(theme) :: any
		ok(e ~= nil, `{theme} element`)
		ok(not seen[e], `{theme}: its own element (not a reskin)`)
		seen[e] = true
		for _, slot in { "aura", "flames", "rising", "glow", "drip", "ring", "mark", "takedown", "heat", "muzzle", "puff",
			"shell", "steam", "trail", "splash", "sound" } do
			ok(e[slot] ~= nil, `{theme} {slot}`)
		end
		ok(type(e.behaviour) == "string", `{theme} behaviour`)
		eq(e.stub, false, `{theme} built`)
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

------------------------------------------------------------------ pack layer v3 (#465)

test("graphics quality: low = nothing, otherwise a share of the rates; counts never 0 when drawn", function()
	for level = 1, 3 do
		eq(SkinFx.qualityScale(level), 0, `level {level} draws nothing`)
	end
	local prev = 0
	for level = 4, 10 do
		local q = SkinFx.qualityScale(level)
		ok(q > 0 and q <= 1 and q >= prev, `level {level} scale {q}`)
		prev = q
	end
	eq(SkinFx.qualityScale(10), 1)
	ok(SkinFx.qualityScale(0) > 0, "Automatic draws")
	ok(SkinFx.qualityScale(nil) > 0, "unknown draws")
	eq(SkinFx.scaleCount(10, 0), 0, "low: no burst")
	eq(SkinFx.scaleCount(10, 1), 10)
	eq(SkinFx.scaleCount(10, 0.5), 5)
	eq(SkinFx.scaleCount(1, 0.25), 1, "a drawn burst keeps one")
	eq(SkinFx.scaleCount(0, 1), 0)
end)

test("pack hunter rates: the whole layer <= PACK_RATE_CAP, scaled by quality", function()
	for name, e in SkinFx.ELEMENTS do
		for _, q in { 0, 0.5, 0.75, 1, 3 } do
			local r = SkinFx.packRates(e, q)
			local total = r.flames * #e.flames.hosts + r.rising + r.aura + r.extra
			near(total, r.total, `{name} total adds up at {q}`, 1e-6)
			ok(r.total <= SkinFx.PACK_RATE_CAP + 1e-9, `{name} capped at {q}`)
		end
		eq(SkinFx.packRates(e, 0).total, 0, `{name}: nothing at quality 0`)
		ok(SkinFx.packRates(e, 0.5).total < SkinFx.packRates(e, 1).total, `{name}: lower quality, fewer`)
		ok(#e.flames.hosts >= 1 and #e.flames.colour >= 2, `{name} flames have hosts + a colour ramp`)
	end
	local f = FIRE.flames.colour
	ok(sum(f[1]) > sum(f[3]) and sum(f[3]) > sum(f[4]), "fire: white-yellow -> orange -> red over life")
end)

test("footprints: molten -> glowing rim -> crust, never brighter as they age", function()
	ok(same(SkinFx.markColour(FIRE, 0), FIRE.mark.hot), "starts molten")
	ok(same(SkinFx.markColour(FIRE, 0.25), FIRE.mark.rim), "then the glow")
	ok(same(SkinFx.markColour(FIRE, 0.6), FIRE.mark.colour), "crusted")
	ok(same(SkinFx.markColour(FIRE, 5), FIRE.mark.colour), "clamped")
	local prev = math.huge
	for i = 0, 20 do
		local s = sum(SkinFx.markColour(FIRE, i / 20))
		ok(s <= prev + 1e-9, `cooling {i}`)
		prev = s
	end
end)

test("standing-still ring: only grounded and still, fades in after the wait", function()
	local r = FIRE.ring
	eq(SkinFx.ringAlpha(FIRE, 0, true), 0, "moving: none")
	eq(SkinFx.ringAlpha(FIRE, r.after, true), 0, "just stopped: none yet")
	near(SkinFx.ringAlpha(FIRE, r.after + r.fade / 2, true), 0.5, "fading in", 1e-9)
	eq(SkinFx.ringAlpha(FIRE, r.after + r.fade, true), 1, "full")
	eq(SkinFx.ringAlpha(FIRE, 60, true), 1, "clamped")
	eq(SkinFx.ringAlpha(FIRE, 60, false), 0, "in the air: none")
	ok(SkinFx.RING_CAP <= 10, "ring cap")
end)

test("overheat: once at max heat, re-armed only after cooling", function()
	local h = FIRE.heat
	local fire, armed = SkinFx.overheat(FIRE, true, h.overheatAt - 0.01)
	eq(fire, false, "not yet")
	eq(armed, true)
	fire, armed = SkinFx.overheat(FIRE, true, h.overheatAt)
	eq(fire, true, "the moment")
	eq(armed, false, "spent")
	fire, armed = SkinFx.overheat(FIRE, false, 1)
	eq(fire, false, "held at max: no repeat")
	fire, armed = SkinFx.overheat(FIRE, false, h.rearmBelow + 0.01)
	eq(fire or armed, false, "still warm: not re-armed")
	fire, armed = SkinFx.overheat(FIRE, false, h.rearmBelow - 0.01)
	eq(fire, false)
	eq(armed, true, "cooled: re-armed")
	-- a full Big Game Hunter magazine reaches the overheat moment
	local Config = require(src.shared.Config)
	local row = (Config.Heroes :: any).RIFLE
	local heat, hit = 0, false
	armed = true
	for _ = 1, row.magazine do
		heat = SkinFx.heatAfter(FIRE, SkinFx.heatAfterShots(FIRE, heat, 1, row.rate), 1 / row.rate)
		local f
		f, armed = SkinFx.overheat(FIRE, armed, heat)
		hit = hit or f
	end
	ok(hit, "a full magazine overheats")
end)

test("muzzle flash and heat haze grow with heat, within caps", function()
	local c0, b0 = SkinFx.muzzleFlash(FIRE, 0)
	local c1, b1 = SkinFx.muzzleFlash(FIRE, 1)
	eq(c0, FIRE.muzzle.min)
	eq(c1, FIRE.muzzle.max)
	ok(b1 > b0 and c1 > c0, "bigger and brighter when hot")
	local prevC, prevB = -1, -1
	for i = 0, 10 do
		local c, b = SkinFx.muzzleFlash(FIRE, i / 10)
		ok(c >= prevC and b >= prevB, `monotonic {i}`)
		prevC, prevB = c, b
	end
	eq(SkinFx.hazeRate(FIRE, FIRE.heat.hazeFrom - 0.01), 0, "no haze cool")
	ok(SkinFx.hazeRate(FIRE, 1) > SkinFx.hazeRate(FIRE, (1 + FIRE.heat.hazeFrom) / 2), "more haze hotter")
	for name, e in SkinFx.ELEMENTS do
		ok(SkinFx.hazeRate(e, 1) <= SkinFx.HAZE_RATE_CAP, `{name} haze cap`)
		ok(e.muzzle.max <= 16, `{name} flash count small`)
	end
end)

test("take-down: the shockwave grows and fades; the crack cools then fades", function()
	local prevR, prevT = -1, -1
	for i = 0, 10 do
		local r, tr = SkinFx.shockwave(FIRE, i / 10)
		ok(r > prevR and tr >= prevT, `ring grows + fades {i}`)
		prevR, prevT = r, tr
	end
	local rEnd, tEnd = SkinFx.shockwave(FIRE, 1)
	near(rEnd, FIRE.takedown.ring.radius, "full radius", 1e-9)
	near(tEnd, 1, "gone", 1e-9)
	local c0, t0 = SkinFx.crackColour(FIRE, 0)
	ok(same(c0, FIRE.heat.white) and t0 == 0, "white-hot and solid")
	local c5, t5 = SkinFx.crackColour(FIRE, 0.5)
	ok(sum(c5) < sum(c0) and t5 == 0, "cooling, still solid")
	local _, t1 = SkinFx.crackColour(FIRE, 1)
	near(t1, 1, "faded", 1e-9)
	ok(FIRE.takedown.crack.arms <= 9, "crack arms fit the pooled set")
	ok(SkinFx.TAKEDOWN_CAP <= 4 and SkinFx.BOLT_CAP <= 10 and SkinFx.DRIP_CAP <= 8, "pool caps")
end)

test("drips: delay within the element's bounds", function()
	local e = FIRE.drip.every
	near(SkinFx.dripDelay(FIRE, 0), e[1], "min", 1e-9)
	near(SkinFx.dripDelay(FIRE, 1), e[2], "max", 1e-9)
	near(SkinFx.dripDelay(FIRE, 7), e[2], "clamped", 1e-9)
	ok(e[1] >= 1, "not a stream")
end)

test("built-in assets only: rbxasset textures + sounds (nothing to upload)", function()
	for name, path in SkinFx.TEXTURES do
		ok(string.sub(path, 1, 30) == "rbxasset://textures/particles/", `{name} texture is built in`)
	end
	for name, e in SkinFx.ELEMENTS do
		local boom = e.sound.boom
		ok(boom == nil or string.sub(boom, 1, 18) == "rbxasset://sounds/", `{name} sound is built in`)
		ok(e.sound.volume <= 0.5, `{name} sound is quiet`)
	end
end)

test("tier 3 is richer than tier 2; the pack tier richer than tier 3", function()
	eq(SkinFx.hunterTrail(2), nil, "no trail at tier 2")
	local l3, w3 = SkinFx.hunterTrail(3)
	local l4, w4 = SkinFx.hunterTrail(4)
	ok(l3 ~= nil and w3 ~= nil and l4 ~= nil and w4 ~= nil, "trails from tier 3")
	ok((l4 :: number) > (l3 :: number) and (w4 :: number) > (w3 :: number), "pack trail longer + wider")
	ok((SkinFx.embers(LAVA, 3, "hunter") :: any).rate > (SkinFx.embers(LAVA, 2, "hunter") :: any).rate, "tier 3 more embers")
	ok(SkinFx.packRates(FIRE, 1).total > (SkinFx.embers(LAVA, 3, "hunter") :: any).rate + (SkinFx.aura(LAVA, 3, "hunter") :: any).rate,
		"the pack layer draws more than tier 3")
end)

------------------------------------------------------------------ element behaviours (#466)

local ELEMENT_THEMES = { fire = "LAVA_LORD", electric = "CYBER_RAPTOR", primal = "TYRANT_KING", cosmic = "NEBULA", crystal = "GEODE" }

test("elements differ in behaviour, not just colour (#462)", function()
	local seen = { behaviour = {}, charge = {}, shape = {}, takedown = {}, splash = {} }
	local function once(kind: string, v: string, name: string)
		ok(not seen[kind][v], `{name}: own {kind} ({v})`)
		seen[kind][v] = true
	end
	for name, e in SkinFx.ELEMENTS do
		once("behaviour", e.behaviour, name)
		once("charge", e.charge, name)
		once("splash", e.splash.style, name)
		ok(SkinFx.THEME_ELEMENTS[ELEMENT_THEMES[name]] == name, `{name} is {ELEMENT_THEMES[name]}'s element`)
	end
	-- footprints / take-downs: at most one shared look (fire + cosmic both draw a disc; fire + primal both crack)
	local shapes, styles = {}, {}
	for _, e in SkinFx.ELEMENTS do
		shapes[e.mark.shape] = (shapes[e.mark.shape] or 0) + 1
		styles[e.takedown.style] = (styles[e.takedown.style] or 0) + 1
	end
	for k, n in shapes do
		ok(n <= 2, `mark shape {k} used by {n}`)
	end
	for k, n in styles do
		ok(n <= 2, `take-down style {k} used by {n}`)
	end
end)

test("element data: textures built in, world kinds known, styles known, caps", function()
	local kinds = {}
	for _, k in SkinFx.WORLD_KINDS do
		kinds[k] = true
	end
	local styles = {
		behaviour = { flicker = true, crackle = true, heartbeat = true, drift = true, shards = true },
		mark = { disc = true, hex = true, crack = true, spike = true },
		takedown = { crack = true, traces = true, spikes = true, none = true },
		splash = { lava = true, emp = true, roar = true, implode = true, shatter = true },
		tracer = { bolt = true, chain = true, comet = true, prism = true },
		seams = { scroll = true, beat = true, drift = true },
	}
	for name, e in SkinFx.ELEMENTS do
		for slot, tex in e.look :: any do
			ok(SkinFx.TEXTURES[tex] ~= nil, `{name} look.{slot} = {tex} is a built-in texture`)
		end
		ok(kinds[e.drip.puff] and kinds[e.takedown.blast] and kinds[e.takedown.rain], `{name} world kinds known`)
		ok(styles.behaviour[e.behaviour], `{name} behaviour`)
		ok(styles.mark[e.mark.shape], `{name} mark shape`)
		ok(styles.takedown[e.takedown.style], `{name} take-down style`)
		ok(styles.splash[e.splash.style], `{name} splash style`)
		ok(styles.tracer[e.tracer.style], `{name} tracer style`)
		ok(e.seams == nil or styles.seams[e.seams.mode], `{name} seams mode`)
		ok(e.takedown.crack.arms <= 9, `{name} take-down arms fit the pool`)
		ok(e.orbit == nil or e.orbit.count <= 6, `{name} orbit small`)
		ok(e.arcs == nil or e.arcs.count <= 3, `{name} arcs few`)
		ok(e.sound.pitch > 0 and e.sound.pitch <= 2, `{name} pitch`)
		ok(e.extra >= 0, `{name} extra`)
	end
	eq(SkinFx.ELEMENTS.fire.seams, nil, "fire keeps tier 3's flow")
	eq(SkinFx.ELEMENTS.fire.extra, 0)
end)

test("every theme is a full Big Game Hunter pack with tier-4 items", function()
	for name, theme in ELEMENT_THEMES do
		ok(SkinFx.THEMES[theme] ~= nil, `{theme} theme`)
		local found = false
		for _, pack in SkinFx.PACKS do
			if pack.theme == theme and pack.hero == "RIFLE" then
				found = true
				local packs = SkinFx.parsePacks(SkinFx.packsValue(SkinFx.ownedPacks(pack.items)))
				for _, item in pack.items do
					eq(SkinFx.tier(item, nil, false, packs), SkinFx.PACK_TIER, `{name}: {item} reaches the pack tier`)
					eq(SkinFx.element(SkinFx.ITEMS[item].theme), SkinFx.ELEMENTS[name], `{item} draws {name}`)
				end
			end
		end
		ok(found, `{theme} has a pack`)
	end
	local wk, wi = SkinFx.fromArt("weapon", "RIFLE_RAIL_RIFLE")
	ok(wk == "RAIL_RIFLE" and wi ~= nil, "a Cyber Raptor gun is read from its art key")
	local gk = SkinFx.grenadeArtKey("RIFLE", "MOON_ROCK")
	eq(gk, "RIFLE_GRENADE_MOON_ROCK")
end)

test("heartbeat: lub at the beat, softer dub, quiet between, periodic", function()
	near(SkinFx.heartbeat(0, 1), 1, "lub", 1e-6)
	near(SkinFx.heartbeat(0.3, 1), 0.7, "dub", 1e-3)
	ok(SkinFx.heartbeat(0.65, 1) < 0.05, "rest")
	near(SkinFx.heartbeat(2.3, 1), SkinFx.heartbeat(0.3, 1), "periodic", 1e-6)
	for i = 0, 40 do
		local k = SkinFx.heartbeat(i / 17, 0.83)
		ok(k >= 0 and k <= 1, `bounded {i}`)
	end
end)

test("seams: scroll moves along the seams, beat throbs, drift is slow; fire none", function()
	local E, P, C = SkinFx.ELEMENTS.electric, SkinFx.ELEMENTS.primal, SkinFx.ELEMENTS.cosmic
	eq(SkinFx.seamColour(SkinFx.ELEMENTS.fire, 1, 0), nil)
	local s = E.seams :: any
	ok(same(SkinFx.seamColour(E, 0, 0) :: Color3, s.colours[1]), "electric starts cyan")
	ok(same(SkinFx.seamColour(E, s.cycle / 2, 0) :: Color3, s.colours[3]), "magenta half a cycle on")
	ok(same(SkinFx.seamColour(E, s.cycle * 0.25, 0.25) :: Color3, s.colours[1]), "the wave travels with phase")
	local p = P.seams :: any
	ok(same(SkinFx.seamColour(P, 0, 0) :: Color3, p.colours[3]), "primal flashes on the beat")
	ok(same(SkinFx.seamColour(P, p.cycle * 0.65, 0) :: Color3, p.colours[1]:Lerp(p.colours[2], SkinFx.heartbeat(p.cycle * 0.65, p.cycle) / 0.7)), "rests dark between")
	local a, b = SkinFx.seamColour(C, 0, 0) :: Color3, SkinFx.seamColour(C, 0.1, 0) :: Color3
	ok(math.abs(sum(a) - sum(b)) < 0.1, "cosmic drifts slowly")
end)

test("orbit, glitch, arcs: within their bounds", function()
	local C = SkinFx.ELEMENTS.cosmic
	local o = C.orbit :: any
	for i = 1, o.count do
		local v = SkinFx.orbitOffset(C, i, o.count, 1.7)
		near(Vector3.new(v.X, 0, v.Z).Magnitude, o.radius, `orbit radius {i}`, 1e-6)
		ok(math.abs(v.Y) <= o.bob + 1e-9, `bob {i}`)
	end
	local a, b = SkinFx.orbitOffset(C, 1, 3, 0), SkinFx.orbitOffset(C, 2, 3, 0)
	near(math.atan2(b.Z, b.X) - math.atan2(a.Z, a.X), 2 * math.pi / 3, "evenly spaced", 1e-6)
	eq(SkinFx.orbitOffset(SkinFx.ELEMENTS.fire, 1, 1, 0), Vector3.zero, "no orbit for fire")
	local E = SkinFx.ELEMENTS.electric
	local g = E.glitch :: any
	local on, hits = 0, 0
	local steps = 20000
	local period = (g.every[1] + g.every[2]) / 2
	for i = 0, steps - 1 do
		local pop, off = SkinFx.glitch(E, i * 0.002, 0.3)
		if pop then
			on += 1
			ok(math.abs(off) == g.offset, "offset")
		end
	end
	hits = on * 0.002
	ok(hits <= (steps * 0.002 / period + 1) * g.seconds + 1e-6, "pops are brief")
	ok(hits > 0, "it does pop")
	local pop = SkinFx.glitch(SkinFx.ELEMENTS.fire, 1, 0)
	eq(pop, false, "fire never glitches")
	for _ = 1, 20 do
		local c0, c1 = SkinFx.arcCurve(E, math.random(), math.random())
		ok(math.abs(c0) <= (E.arcs :: any).jitter and math.abs(c1) <= (E.arcs :: any).jitter, "arc jitter bounded")
	end
end)

test("primal fury: take-downs feed it; the others don't", function()
	local P = SkinFx.ELEMENTS.primal
	near(SkinFx.heatAfterKill(P, 0.2), 0.2 + P.heat.perKill, "a take-down adds fury", 1e-9)
	eq(SkinFx.heatAfterKill(P, 0.95), 1, "capped")
	for name, e in SkinFx.ELEMENTS do
		if name ~= "primal" then
			eq(SkinFx.heatAfterKill(e, 0.4), 0.4, `{name}: no kill charge`)
		end
	end
	-- every element's build-up still reaches its burst within a Big Game Hunter magazine
	local Config = require(src.shared.Config)
	local row = (Config.Heroes :: any).RIFLE
	for name, e in SkinFx.ELEMENTS do
		local heat, burst = 0, false
		for _ = 1, row.magazine do
			heat = SkinFx.heatAfter(e, SkinFx.heatAfterShots(e, heat, 1, row.rate), 1 / row.rate)
			burst = burst or SkinFx.muzzleBurst(e, heat)
		end
		ok(burst, `{name}: a magazine reaches the burst`)
	end
end)

test("spikes and grenade shapes", function()
	eq(SkinFx.spike(0), 0, "sprouts from nothing")
	eq(SkinFx.spike(0.18), 1, "full")
	eq(SkinFx.spike(0.5), 1, "holds")
	near(SkinFx.spike(1), 0, "shattered", 1e-9)
	for name, e in SkinFx.ELEMENTS do
		local _, tEnd = SkinFx.splashShape(e, 1)
		near(tEnd, 1, `{name} splash gone at the end`, 1e-9)
		for i = 0, 10 do
			local r, tr = SkinFx.splashShape(e, i / 10)
			ok(r >= 0 and tr >= 0 and tr <= 1, `{name} shape bounded {i}`)
		end
	end
	local C = SkinFx.ELEMENTS.cosmic
	local r1 = SkinFx.splashShape(C, 0.12)
	local r2 = SkinFx.splashShape(C, 0.4)
	ok(r1 > r2 and r2 > 0, "the black hole collapses")
	eq(SkinFx.splashShape(C, SkinFx.IMPLODE_AT), 0, "gone at the implosion")
	local E = SkinFx.ELEMENTS.electric
	ok(SkinFx.splashShape(E, 0.5) > SkinFx.splashShape(E, 0.2), "the EMP ring races out")
end)
