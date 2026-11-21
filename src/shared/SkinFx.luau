--!strict
--[[
	Premium skin effects (PREMIUM_SKINS.md "What's new", DECISIONS #459 animation tiers): one pure
	table of themes + premium items and the rules that turn them into looks. Visual only: nothing
	here changes a hit, a radius, a timing or a sound. Pure (spec: tools/test/skinfx.spec.luau);
	the effects themselves are drawn on each client by Client/SkinFx.client (one Heartbeat loop),
	and the server only asks this module for a colour (tracers, grenade blasts, ability VFX).

	Tiers (#459, by the item's price; USD at Roblox's ~R$80 per $1):
	  0  no animation (blank / unknown key, or an item under ~$10): today's static Neon `glow`
	  1  >= R$800  ($10): the `glow` pieces breathe slowly (Pulse)
	  2  >= R$1,200 ($15): pulse + a few ember particles drifting up
	  3  >= R$1,600 ($20): multi-layer: pulse + a colour wave flowing along the seams + embers +
	     an aura (low heat glow, a light, a short trail when moving) + idle flares
	  4  "pack" (#462): the wearer owns the item's whole class pack - tier 3 + the theme element's
	     pack layer (see "pack tier" below)
	`fxTier` on each item is the tier its planned price gives; `tierForPrice` is the rule, so when
	the Store sheet gets the real prices the tier can be read from them instead.

	Keys: premium items use their Skins key (hunter MAGMA_MONARCH, weapon LAVA_LANCE, tower set
	LAVA_LORD, grenade LAVA_LOB, ability VOLCANO_ROAR). They are NOT in the Skins sheet yet (prices
	wait for Jovan's look at the sample), so nothing in play wears them: a blank or unknown key is
	always today's behaviour (every lookup falls back to what the caller passes).

	Grenade and ability skins are new skin kinds (slots `grenade:<HERO>`, `ability:<HERO>`, read
	from the player's `Skin_grenade_<HERO>` / `Skin_ability_<HERO>` attributes like the other
	kinds). The rules are here and the server reads the attributes; owning, wearing, saving and the
	Store wiring come later (nothing sets those attributes yet).
]]

local SkinFx = {}

export type Theme = {
	display: string,
	glow: Color3, -- the seam colour at rest (= the art's authored `glow`)
	hot: Color3, -- the pulse's bright end
	deep: Color3, -- the flow's dark end (cooling lava)
	ember: Color3, -- particles: start colour
	emberEnd: Color3, -- particles: end colour
	tracer: Color3,
	blast: Color3, -- grenade blast colour
	blastSmoke: Color3, -- the dark puff with it
	ability: Color3, -- ability VFX colour
	pulseSeconds: number,
	flowSeconds: number,
	flowLength: number, -- studs per wave of the tier-3 flow
}

export type Item = { kind: string, hero: string?, theme: string, display: string, fxTier: number }

export type Layers = { pulse: boolean, embers: boolean, flow: boolean, aura: boolean, idle: boolean }

export type Emitter = {
	rate: number,
	lifetime: { number },
	speed: { number },
	size: { number }, -- start, end
	spread: number,
	colour: { Color3 }, -- start, end
	lightEmission: number,
	rise: number, -- upward acceleration
}

SkinFx.KINDS = table.freeze({ "hunter", "weapon", "tower", "grenade", "ability" })
SkinFx.TIER_ROBUX = table.freeze({ 800, 1200, 1600 }) -- tier 1, 2, 3 from this price up (#459)
SkinFx.MAX_TIER = 3
SkinFx.FX_DISTANCE = 160 -- studs from the camera: farther models keep their static glow
SkinFx.TOWER_EMITTER_CAP = 20 -- premium tower emitters on at once, nearest first
SkinFx.HUNTER_RATE_CAP = 4 -- particles a second on one hunter (PREMIUM_SKINS caps)
SkinFx.TOWER_RATE_CAP = 6
SkinFx.IDLE_FLARE_SECONDS = 6 -- tier 3: a flare from the seams (+ a light pop) this often
SkinFx.IDLE_FLARE_COUNT = 8

-- Built-in particle textures that ship with every Roblox client (content/textures/particles):
-- no upload needed. None is a flipbook sheet, so flames "lick" through size / squash / spin.
SkinFx.TEXTURES = table.freeze({
	fire = "rbxasset://textures/particles/fire_main.dds",
	sparks = "rbxasset://textures/particles/fire_sparks_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
	plume = "rbxasset://textures/particles/explosion01_smoke_main.dds",
	core = "rbxasset://textures/particles/explosion01_core_main.dds",
	shock = "rbxasset://textures/particles/explosion01_shockwave_main.dds",
	sparkles = "rbxasset://textures/particles/sparkles_main.dds",
})

-- Graphics quality (UserGameSettings.SavedQualityLevel: 0 = Automatic, 1..10) -> the share of
-- particle rates / burst counts to draw: 0 = none (1-3, "low graphics"), else 0.5 / 0.75 / 1.
function SkinFx.qualityScale(level: unknown): number
	if type(level) ~= "number" then
		return 0.75
	end
	if level <= 0 then
		return 0.75 -- Automatic: middle ground
	elseif level <= 3 then
		return 0
	elseif level <= 5 then
		return 0.5
	elseif level <= 7 then
		return 0.75
	end
	return 1
end

-- A burst count at this quality: 0 when the quality draws nothing, else at least 1.
function SkinFx.scaleCount(count: number, quality: number): number
	if quality <= 0 or count <= 0 then
		return 0
	end
	return math.max(1, math.floor(count * math.min(quality, 1) + 0.5))
end

-- Tier 3's hunter trail (lifetime, width; richer than tier 2's none) and the pack tier's longer,
-- wider one; nil below tier 3.
function SkinFx.hunterTrail(tier: number): (number?, number?)
	if tier >= 4 then
		return 0.55, 1.3
	elseif tier >= 3 then
		return 0.4, 0.9
	end
	return nil, nil
end
SkinFx.OVERRIDE_ATTRIBUTE = "SkinFxTier" -- Studio-only aid (ReplicatedStorage): force a tier to compare

SkinFx.THEMES = table.freeze({
	LAVA_LORD = table.freeze({
		display = "Lava Lord",
		glow = Color3.fromRGB(255, 112, 20),
		hot = Color3.fromRGB(255, 222, 130),
		deep = Color3.fromRGB(150, 26, 6),
		ember = Color3.fromRGB(255, 170, 60),
		emberEnd = Color3.fromRGB(150, 30, 8),
		tracer = Color3.fromRGB(255, 128, 32),
		blast = Color3.fromRGB(255, 104, 20),
		blastSmoke = Color3.fromRGB(46, 38, 40),
		ability = Color3.fromRGB(255, 120, 28),
		pulseSeconds = 3,
		flowSeconds = 2.4,
		flowLength = 3,
	}),
} :: { [string]: Theme })

-- Tiers here are the planned ones for the sample (hunter $20, gun $15, set $20; grenade and
-- ability are under $10: static glow); Jovan's prices may move them (`tierForPrice`).
SkinFx.ITEMS = table.freeze({
	MAGMA_MONARCH = table.freeze({ kind = "hunter", hero = "RIFLE", theme = "LAVA_LORD", display = "Magma Monarch", fxTier = 3 }),
	LAVA_LANCE = table.freeze({ kind = "weapon", hero = "RIFLE", theme = "LAVA_LORD", display = "Lava Lance", fxTier = 2 }),
	LAVA_LORD = table.freeze({ kind = "tower", theme = "LAVA_LORD", display = "Lava Lord", fxTier = 3 }),
	LAVA_LOB = table.freeze({ kind = "grenade", hero = "RIFLE", theme = "LAVA_LORD", display = "Lava Lob", fxTier = 0 }),
	VOLCANO_ROAR = table.freeze({ kind = "ability", hero = "RIFLE", theme = "LAVA_LORD", display = "Volcano Roar", fxTier = 0 }),
} :: { [string]: Item })

------------------------------------------------------------------ pack tier (#462)
--[[
	Tier 4, "pack": the player owns a theme's FULL class pack (#459: tower set + that class's weapon +
	hunter skin + grenade + ability). Every item of that pack then also draws the theme ELEMENT's
	pack-only layer, on top of tier 3's: an elemental aura on the hunter, short-lived footstep
	marks, a take-down burst, a reactive weapon (heat per shot, decaying: the `glow` ramps cool ->
	white-hot, a muzzle burst when hot, a puff when it cools or reloads) and a reactive grenade (a
	trail in flight, a short splash where it lands). Visual only, like every tier: no hit, radius,
	timing or sound changes.

	Data-driven per element (ELEMENTS): Lava Lord = "fire" (built); "electric" (Cyber Raptor),
	"primal" (Tyrant King), "cosmic" (Nebula) and "crystal" (Geode) have their param slots filled
	with placeholder colours and `stub = true` until their themes are built; Client/SkinFx reads
	only these params, so a new theme is a data change (+ its `behaviour` if it's a new motion).

	Ownership: `ownedPacks(ownedKeys)` is the pure rule (a pack counts only when EVERY item in it
	is owned). The server will publish the result as the player attribute PACKS_ATTRIBUTE (comma
	list of pack keys) from the saved skins - that store / save wiring is a later task (nothing sets
	it yet), so in play nobody has tier 4. Studio: the `SkinFxTier` override now takes 0..4.

	v3 (#465, "premium paid-skin" pass): each element also carries flame tongues off the helm horns +
	pauldrons, swirling embers, a flickering heat light, lava drips, a standing-still ground ring,
	molten footprints that crust, a layered take-down (fireball, shockwave ring, ground crack, light
	flash), per-shot muzzle flash / casings / tracer bolts, heat haze, the overheat moment, reload
	steam, and a layered grenade impact. The pure rules for those are below ("pack layer v3"); every
	texture / sound is a built-in rbxasset path (TEXTURES, `sound`): nothing to upload. Rates and burst
	counts scale with the graphics quality (`qualityScale`, `scaleCount`).
]]

SkinFx.PACK_TIER = 4
SkinFx.PACKS_ATTRIBUTE = "SkinFxPacks" -- player attribute: "LAVA_LORD_RIFLE,..." (set by the store wiring, later)
SkinFx.TAKEDOWN_ATTRIBUTE = "SkinFxTakedownAt" -- player attribute (server time), stamped on a take-down
SkinFx.GRENADE_ATTRIBUTE = "SkinFxGrenade" -- on a thrown grenade: the worn premium grenade skin key
SkinFx.OWNER_ATTRIBUTE = "SkinFxOwner" -- on a thrown grenade: the thrower's UserId
SkinFx.PACK_RATE_CAP = 30 -- particles a second from one hunter's whole pack layer (flames + embers + aura)
SkinFx.MARK_CAP = 16 -- footstep marks on screen at once (all hunters; the oldest goes first)
SkinFx.SPLASH_CAP = 4 -- grenade splashes at once
SkinFx.DRIP_CAP = 6 -- lava drips falling at once (all hunters)
SkinFx.RING_CAP = 6 -- standing-still ground rings at once (nearest hunters)
SkinFx.BOLT_CAP = 8 -- glowing tracer bolts in flight at once
SkinFx.TAKEDOWN_CAP = 3 -- take-down shockwave + ground crack sets at once
SkinFx.HAZE_RATE_CAP = 8 -- heat-haze smoke a second from one hot gun
SkinFx.PACK_DISTANCE = 120 -- studs: pack emitters / marks / bursts only this close to the camera
SkinFx.HEAT_REF_RATE = 8 -- shots a second `perShot` is tuned for (the Big Game Hunter's auto rifle)

export type Burst = { count: number, colour: { Color3 }, size: number, speed: number }
export type Element = {
	display: string,
	stub: boolean, -- true = placeholder params until the theme is built
	behaviour: string, -- how the client moves it: "flicker" (fire) | "crackle" | "shockwave" | "drift" | "shards"
	aura: Emitter, -- round the hunter's torso
	-- tongues licking up off the hunter's `hosts` (R15 parts: helm horns + pauldrons); `colour` is
	-- the colour over life (white-yellow -> orange -> red -> smoke), `size` start / peak / end
	flames: { rate: number, lifetime: { number }, speed: { number }, size: { number }, spread: number, rise: number,
		colour: { Color3 }, hosts: { string } },
	rising: { rate: number, lifetime: { number }, speed: { number }, size: number, spread: number, rise: number,
		drag: number, colour: { Color3 } }, -- slow embers drifting / swirling up off the body
	glow: { colour: Color3, brightness: number, range: number, flicker: number }, -- the flickering heat light
	drip: { every: { number }, colour: Color3, crust: Color3, size: number, hiss: number }, -- off the pauldrons
	ring: { after: number, fade: number, radius: number, rate: number, scorch: Color3 }, -- standing still
	-- footsteps: a molten print `hot` -> `rim` -> crusts to `colour` while it fades, + a small flame lick
	mark: { colour: Color3, rim: Color3, hot: Color3, size: number, lifetime: number, every: number, lick: number },
	takedown: { count: number, colour: { Color3 }, size: number, speed: number, fireball: number, shower: number,
		ring: { radius: number, seconds: number }, crack: { arms: number, length: number, seconds: number },
		flash: { brightness: number, range: number, seconds: number } },
	heat: { cool: Color3, hot: Color3, white: Color3, perShot: number, decay: number, burstAt: number, puffFrom: number,
		hazeFrom: number, hazeRate: number, overheatAt: number, rearmBelow: number },
	-- per-shot flash: `min`..`max` particles by heat (+ a light flash), the flame burst from burstAt
	muzzle: { count: number, colour: { Color3 }, size: number, speed: number, min: number, max: number,
		light: number, lightHot: number, range: number },
	puff: Burst, -- steam / embers when cooling
	shell: { count: number, colour: { Color3 }, speed: number }, -- molten casing / ember kicked out a shot
	steam: { overheat: number, reloadRate: number, size: number, colour: { Color3 } }, -- overheat blast / reload steam
	trail: { colour: { Color3 }, lifetime: number, width: number, rate: number, smoke: Color3, smokeLifetime: number },
	splash: { colour: Color3, radius: number, lifetime: number, count: number, fireball: number, plume: number,
		linger: number, bubbles: number, crust: Color3, flash: { brightness: number, range: number, seconds: number } },
	sound: { boom: string?, volume: number }, -- built-in client sounds only (crackle / hiss / whoosh need an upload)
}

local function stubElement(display: string, behaviour: string, a: Color3, b: Color3, c: Color3): Element
	return table.freeze({
		display = display,
		stub = true,
		behaviour = behaviour,
		aura = table.freeze({ rate = 6, lifetime = { 0.5, 0.9 }, speed = { 0.5, 1.2 }, size = { 0.5, 0 }, spread = 40,
			colour = { a, b }, lightEmission = 0.6, rise = 2 }),
		flames = table.freeze({ rate = 6, lifetime = { 0.3, 0.5 }, speed = { 1, 2 }, size = { 0.3, 0.7, 0.1 }, spread = 20,
			rise = 4, colour = { c, a, b, b }, hosts = { "Head", "LeftUpperArm", "RightUpperArm" } }),
		rising = table.freeze({ rate = 4, lifetime = { 1.4, 2.2 }, speed = { 0.5, 1.2 }, size = 0.15, spread = 60, rise = 1,
			drag = 0.8, colour = { c, a } }),
		glow = table.freeze({ colour = a, brightness = 1.2, range = 10, flicker = 0.3 }),
		drip = table.freeze({ every = { 2, 4 }, colour = a, crust = b, size = 0.2, hiss = 3 }),
		ring = table.freeze({ after = 0.7, fade = 0.5, radius = 2.4, rate = 8, scorch = b }),
		mark = table.freeze({ colour = b, rim = a, hot = c, size = 1.1, lifetime = 2.5, every = 2.2, lick = 2 }),
		takedown = table.freeze({ count = 18, colour = { a, b }, size = 0.5, speed = 9, fireball = 4, shower = 18,
			ring = { radius = 6, seconds = 0.5 }, crack = { arms = 6, length = 3, seconds = 2 },
			flash = { brightness = 5, range = 16, seconds = 0.3 } }),
		heat = table.freeze({ cool = b, hot = a, white = c, perShot = 0.08, decay = 0.25, burstAt = 0.7, puffFrom = 0.45,
			hazeFrom = 0.55, hazeRate = 5, overheatAt = 0.95, rearmBelow = 0.6 }),
		muzzle = table.freeze({ count = 8, colour = { c, a }, size = 0.35, speed = 6, min = 3, max = 10,
			light = 2, lightHot = 6, range = 10 }),
		puff = table.freeze({ count = 6, colour = { c, b }, size = 0.45, speed = 1.5 }),
		shell = table.freeze({ count = 1, colour = { c, a }, speed = 7 }),
		steam = table.freeze({ overheat = 18, reloadRate = 14, size = 1, colour = { c, b } }),
		trail = table.freeze({ colour = { a, b }, lifetime = 0.35, width = 0.5, rate = 12, smoke = b, smokeLifetime = 0.8 }),
		splash = table.freeze({ colour = a, radius = 2.2, lifetime = 1.8, count = 14, fireball = 5, plume = 5, linger = 1.5,
			bubbles = 8, crust = b, flash = { brightness = 5, range = 16, seconds = 0.35 } }),
		sound = table.freeze({ boom = nil, volume = 0 }),
	})
end

local rgb = Color3.fromRGB
SkinFx.ELEMENTS = table.freeze({
	fire = table.freeze({
		display = "Fire",
		stub = false,
		behaviour = "flicker",
		aura = table.freeze({ -- low flames licking round the torso
			rate = 4, lifetime = { 0.4, 0.7 }, speed = { 0.8, 1.6 }, size = { 0.8, 0.1 }, spread = 30,
			colour = { rgb(255, 214, 110), rgb(220, 50, 10) }, lightEmission = 0.75, rise = 4,
		}),
		flames = table.freeze({ -- tongues off the helm horns + pauldrons
			rate = 7, lifetime = { 0.32, 0.6 }, speed = { 1.4, 2.8 }, size = { 0.35, 1.0, 0.2 }, spread = 12, rise = 7,
			colour = { rgb(255, 250, 215), rgb(255, 196, 70), rgb(255, 108, 18), rgb(190, 32, 8), rgb(70, 60, 60) },
			hosts = { "Head", "LeftUpperArm", "RightUpperArm" },
		}),
		rising = table.freeze({ -- slow embers swirling up
			rate = 5, lifetime = { 1.8, 2.8 }, speed = { 0.6, 1.5 }, size = 0.16, spread = 70, rise = 1.6, drag = 0.9,
			colour = { rgb(255, 226, 130), rgb(255, 84, 10) },
		}),
		glow = table.freeze({ colour = rgb(255, 128, 44), brightness = 1.6, range = 12, flicker = 0.45 }),
		drip = table.freeze({ every = { 1.4, 3 }, colour = rgb(255, 156, 40), crust = rgb(60, 26, 16), size = 0.24, hiss = 4 }),
		ring = table.freeze({ after = 0.7, fade = 0.5, radius = 2.6, rate = 10, scorch = rgb(22, 14, 12) }),
		mark = table.freeze({
			colour = rgb(40, 22, 18), rim = rgb(255, 104, 20), hot = rgb(255, 236, 170),
			size = 0.8, lifetime = 2.6, every = 2.4, lick = 3,
		}),
		takedown = table.freeze({
			count = 22, colour = { rgb(255, 226, 140), rgb(230, 60, 10) }, size = 0.6, speed = 10,
			fireball = 6, shower = 26,
			ring = { radius = 7, seconds = 0.55 }, crack = { arms = 7, length = 3.4, seconds = 2.2 },
			flash = { brightness = 7, range = 18, seconds = 0.35 },
		}),
		heat = table.freeze({
			cool = rgb(150, 26, 6), -- cold magma: deep red
			hot = rgb(255, 112, 20), -- the authored glow
			white = rgb(255, 246, 214), -- white-hot
			perShot = 0.08, -- heat a shot adds (0..1) at HEAT_REF_RATE shots a second (slower guns: more a shot)
			decay = 0.25, -- heat lost a second
			burstAt = 0.7, -- a muzzle flame burst from this heat up
			puffFrom = 0.45, -- cooling below this from above (or a reload while above it): a steam / ember puff
			hazeFrom = 0.55, -- heat haze / smoke curls from the vents from this heat up
			hazeRate = 7, -- ... at this rate a second at full heat
			overheatAt = 0.95, -- the overheat moment (vents flare + steam blast) ...
			rearmBelow = 0.6, -- ... once, until the gun cools below this
		}),
		muzzle = table.freeze({
			count = 7, colour = { rgb(255, 240, 180), rgb(255, 90, 10) }, size = 0.35, speed = 7,
			min = 3, max = 12, light = 2.5, lightHot = 8, range = 12,
		}),
		puff = table.freeze({ count = 8, colour = { rgb(236, 232, 228), rgb(120, 110, 110) }, size = 0.6, speed = 1.8 }),
		shell = table.freeze({ count = 1, colour = { rgb(255, 230, 150), rgb(255, 80, 10) }, speed = 8 }),
		steam = table.freeze({ overheat = 26, reloadRate = 20, size = 1.3, colour = { rgb(244, 242, 240), rgb(150, 146, 146) } }),
		trail = table.freeze({
			colour = { rgb(255, 210, 100), rgb(200, 40, 8) }, lifetime = 0.4, width = 0.6, rate = 16,
			smoke = rgb(70, 62, 62), smokeLifetime = 0.9,
		}),
		splash = table.freeze({
			colour = rgb(255, 104, 20), radius = 2.6, lifetime = 2, count = 18,
			fireball = 7, plume = 7, linger = 1.8, bubbles = 10, crust = rgb(55, 24, 14),
			flash = { brightness = 7, range = 20, seconds = 0.4 },
		}),
		sound = table.freeze({ boom = "rbxasset://sounds/impact_explosion_03.mp3", volume = 0.35 }),
	}),
	electric = stubElement("Electric", "crackle", rgb(60, 230, 255), rgb(230, 60, 255), rgb(240, 255, 255)),
	primal = stubElement("Primal", "shockwave", rgb(220, 30, 30), rgb(110, 10, 14), rgb(255, 214, 110)),
	cosmic = stubElement("Cosmic", "drift", rgb(150, 110, 255), rgb(40, 200, 200), rgb(250, 250, 255)),
	crystal = stubElement("Crystal", "shards", rgb(190, 110, 255), rgb(90, 70, 110), rgb(245, 230, 255)),
} :: { [string]: Element })

-- Each theme's element (#462: themes differ by element, not by recolour). Only Lava Lord is built.
SkinFx.THEME_ELEMENTS = table.freeze({
	LAVA_LORD = "fire",
	CYBER_RAPTOR = "electric",
	TYRANT_KING = "primal",
	NEBULA = "cosmic",
	GEODE = "crystal",
} :: { [string]: string })

-- Class packs (#459): a theme's tower set + one class's hunter, weapon, grenade and ability.
export type Pack = { theme: string, hero: string, display: string, items: { string } }
SkinFx.PACKS = table.freeze({
	LAVA_LORD_RIFLE = table.freeze({
		theme = "LAVA_LORD",
		hero = "RIFLE",
		display = "Lava Lord - Big Game Hunter Pack",
		items = table.freeze({ "MAGMA_MONARCH", "LAVA_LANCE", "LAVA_LORD", "LAVA_LOB", "VOLCANO_ROAR" }),
	}),
} :: { [string]: Pack })

local HEROES = { "PISTOL", "RIFLE", "SHOTGUN", "MEDIC" }

-- The element a theme draws its pack layer with, or nil.
function SkinFx.element(themeKey: unknown): Element?
	local e = if type(themeKey) == "string" then SkinFx.THEME_ELEMENTS[themeKey] else nil
	return if e then SkinFx.ELEMENTS[e] else nil
end

-- The pure ownership rule: the packs whose EVERY item is in `owned` (a set {key = true} or a
-- list of keys), sorted. Partial packs never count.
function SkinFx.ownedPacks(owned: unknown): { string }
	local have: { [string]: boolean } = {}
	if type(owned) == "table" then
		for k, v in owned :: { [any]: any } do
			if type(k) == "string" and v == true then
				have[k] = true
			elseif type(v) == "string" then
				have[v] = true
			end
		end
	end
	local out = {}
	for key, pack in SkinFx.PACKS do
		local all = #pack.items > 0
		for _, item in pack.items do
			if not have[item] then
				all = false
				break
			end
		end
		if all then
			table.insert(out, key)
		end
	end
	table.sort(out)
	return out
end

-- The attribute value the server publishes, and the client's reading of it (unknown keys dropped).
function SkinFx.packsValue(packs: { string }): string
	return table.concat(packs, ",")
end

function SkinFx.parsePacks(value: unknown): { [string]: boolean }
	local out: { [string]: boolean } = {}
	if type(value) == "string" then
		for key in string.gmatch(value, "[^,%s]+") do
			if SkinFx.PACKS[key] then
				out[key] = true
			end
		end
	end
	return out
end

-- Does this premium item belong to one of the owned packs?
function SkinFx.inOwnedPack(itemKey: unknown, packs: { [string]: boolean }?): boolean
	if type(itemKey) ~= "string" or not packs then
		return false
	end
	for key in packs do
		local pack = SkinFx.PACKS[key]
		if pack then
			for _, item in pack.items do
				if item == itemKey then
					return true
				end
			end
		end
	end
	return false
end

-- The pack layer's parts for a tier (all from tier 4).
export type PackLayers = { aura: boolean, marks: boolean, takedown: boolean, heat: boolean, trail: boolean, splash: boolean }
function SkinFx.packLayers(tier: number): PackLayers
	local on = tier >= SkinFx.PACK_TIER
	return { aura = on, marks = on, takedown = on, heat = on, trail = on, splash = on }
end

-- The pack aura emitter (rate capped), or nil below tier 4 / on low graphics.
function SkinFx.packAura(element: Element, tier: number, lowGraphics: boolean?): Emitter?
	if tier < SkinFx.PACK_TIER or lowGraphics then
		return nil
	end
	local a = element.aura
	return {
		rate = math.min(a.rate, SkinFx.PACK_RATE_CAP),
		lifetime = a.lifetime,
		speed = a.speed,
		size = a.size,
		spread = a.spread,
		colour = a.colour,
		lightEmission = a.lightEmission,
		rise = a.rise,
	}
end

-- Reactive weapon heat, 0..1: up per shot, down over time. `rate` = the gun's shots a second
-- (Config Heroes `rate`): a slow gun heats more a shot, so every class can reach white-hot.
function SkinFx.shotHeat(element: Element, rate: number?): number
	local r = if type(rate) == "number" and rate > 0 then rate else SkinFx.HEAT_REF_RATE
	return element.heat.perShot * math.clamp(SkinFx.HEAT_REF_RATE / r, 1, 6)
end

function SkinFx.heatAfterShots(element: Element, heat: number, shots: number, rate: number?): number
	return math.clamp(heat + SkinFx.shotHeat(element, rate) * math.max(0, shots), 0, 1)
end

function SkinFx.heatAfter(element: Element, heat: number, dt: number): number
	return math.clamp(heat - element.heat.decay * math.max(0, dt), 0, 1)
end

-- The weapon's `glow` colour at this heat: cool (0) -> the authored glow (0.5) -> white-hot (1).
function SkinFx.heatColour(element: Element, heat: number): Color3
	local h = element.heat
	local x = math.clamp(heat, 0, 1)
	if x < 0.5 then
		return h.cool:Lerp(h.hot, x * 2)
	end
	return h.hot:Lerp(h.white, (x - 0.5) * 2)
end

-- A shot at this heat (after the shot) throws a muzzle burst?
function SkinFx.muzzleBurst(element: Element, heat: number): boolean
	return heat >= element.heat.burstAt
end

-- A cooling puff: heat fell through `puffFrom` since the last look, or a reload just started
-- while the gun was at least that hot.
function SkinFx.coolPuff(element: Element, before: number, after: number, reloadStarted: boolean?): boolean
	local from = element.heat.puffFrom
	if reloadStarted then
		return before >= from
	end
	return before >= from and after < from
end

-- Footsteps: a mark when the hunter has walked `every` studs on the ground since the last one.
function SkinFx.markDue(element: Element, walked: number, grounded: boolean): boolean
	return grounded and walked >= element.mark.every
end

-- Within the pack layer's distance (and not on low graphics)?
function SkinFx.packVisible(distance: number, lowGraphics: boolean?): boolean
	return not lowGraphics and distance <= SkinFx.PACK_DISTANCE
end

------------------------------------------------------------------ pack layer v3 (#465): the rules

-- The pack hunter's continuous rates at this quality (0..1): flames per host, rising embers and
-- the torso aura, scaled down together so the whole layer stays <= PACK_RATE_CAP.
export type PackRates = { flames: number, rising: number, aura: number, total: number }
function SkinFx.packRates(element: Element, quality: number): PackRates
	local q = math.clamp(quality, 0, 1)
	local hosts = math.max(1, #element.flames.hosts)
	local flames, rising, aura = element.flames.rate * q, element.rising.rate * q, element.aura.rate * q
	local total = flames * hosts + rising + aura
	if total > SkinFx.PACK_RATE_CAP then
		local k = SkinFx.PACK_RATE_CAP / total
		flames, rising, aura = flames * k, rising * k, aura * k
		total = SkinFx.PACK_RATE_CAP
	end
	return { flames = flames, rising = rising, aura = aura, total = total }
end

-- A footprint's colour `u` (0..1) into its life: molten `hot` -> glowing `rim` (by 0.25) ->
-- crusted `colour` (by 0.6), then it only fades.
function SkinFx.markColour(element: Element, u: number): Color3
	local m = element.mark
	local x = math.clamp(u, 0, 1)
	if x < 0.25 then
		return m.hot:Lerp(m.rim, x / 0.25)
	elseif x < 0.6 then
		return m.rim:Lerp(m.colour, (x - 0.25) / 0.35)
	end
	return m.colour
end

-- The standing-still ground ring's strength 0..1: nothing while moving / in the air, then it fades
-- in over `fade` seconds once the hunter has stood still `after` seconds.
function SkinFx.ringAlpha(element: Element, still: number, grounded: boolean): number
	if not grounded then
		return 0
	end
	local r = element.ring
	return math.clamp((still - r.after) / math.max(r.fade, 1e-3), 0, 1)
end

-- The overheat moment: fires once when the heat reaches `overheatAt` while armed, then re-arms
-- only after the gun cools below `rearmBelow`. Returns (fire now, armed next).
function SkinFx.overheat(element: Element, armed: boolean, heat: number): (boolean, boolean)
	local h = element.heat
	if armed and heat >= h.overheatAt then
		return true, false
	end
	if not armed and heat < h.rearmBelow then
		return false, true
	end
	return false, armed
end

-- A shot's muzzle flash at this heat (after the shot): particle count min..max and the light
-- flash's brightness, both growing with the heat.
function SkinFx.muzzleFlash(element: Element, heat: number): (number, number)
	local m = element.muzzle
	local x = math.clamp(heat, 0, 1)
	return math.floor(m.min + (m.max - m.min) * x + 0.5), m.light + (m.lightHot - m.light) * x
end

-- Heat-haze smoke a second from the vents: none below `hazeFrom`, up to `hazeRate` at full heat
-- (<= HAZE_RATE_CAP).
function SkinFx.hazeRate(element: Element, heat: number): number
	local h = element.heat
	if heat < h.hazeFrom then
		return 0
	end
	local x = (math.clamp(heat, 0, 1) - h.hazeFrom) / math.max(1 - h.hazeFrom, 1e-3)
	return math.min(h.hazeRate * x, SkinFx.HAZE_RATE_CAP)
end

-- The take-down shockwave ring `u` (0..1) into its life: (radius, transparency); eases out.
function SkinFx.shockwave(element: Element, u: number): (number, number)
	local x = math.clamp(u, 0, 1)
	local eased = 1 - (1 - x) ^ 3
	return element.takedown.ring.radius * (0.15 + 0.85 * eased), 0.05 + 0.95 * x ^ 1.5
end

-- The ground crack `u` (0..1) into its life: white-hot -> the glow -> cooled crust; (colour,
-- transparency): solid while it cools, fading out over the last 40%.
function SkinFx.crackColour(element: Element, u: number): (Color3, number)
	local h = element.heat
	local x = math.clamp(u, 0, 1)
	local colour
	if x < 0.15 then
		colour = h.white:Lerp(h.hot, x / 0.15)
	elseif x < 0.6 then
		colour = h.hot:Lerp(element.mark.colour, (x - 0.15) / 0.45)
	else
		colour = element.mark.colour
	end
	return colour, if x < 0.6 then 0 else (x - 0.6) / 0.4
end

-- Seconds to the hunter's next lava drip for a random r (0..1): between the element's bounds.
function SkinFx.dripDelay(element: Element, r: number): number
	local e = element.drip.every
	return e[1] + (e[2] - e[1]) * math.clamp(r, 0, 1)
end

-- The premium item for a key, or nil (blank / basic / unknown = no effects).
function SkinFx.item(key: unknown): Item?
	return if type(key) == "string" then SkinFx.ITEMS[key] else nil
end

function SkinFx.theme(key: unknown): Theme?
	local item = SkinFx.item(key)
	return if item then SkinFx.THEMES[item.theme] else nil
end

-- #459: the animation tier a Robux price buys (nil / below R$800 = 0).
function SkinFx.tierForPrice(robux: unknown): number
	if type(robux) ~= "number" then
		return 0
	end
	local tier = 0
	for i, from in SkinFx.TIER_ROBUX do
		if robux >= from then
			tier = i
		end
	end
	return tier
end

-- The tier to draw: PACK_TIER when the item is in one of the wearer's owned packs (#462), else
-- the item's; (Studio only) the comparison override 0..PACK_TIER wins over both.
function SkinFx.tier(key: unknown, override: unknown, isStudio: boolean?, packs: { [string]: boolean }?): number
	local item = SkinFx.item(key)
	if not item then
		return 0
	end
	if isStudio and type(override) == "number" and override >= 0 and override <= SkinFx.PACK_TIER then
		return math.floor(override)
	end
	if SkinFx.inOwnedPack(key, packs) then
		return SkinFx.PACK_TIER
	end
	return item.fxTier
end

function SkinFx.layers(tier: number): Layers
	return {
		pulse = tier >= 1,
		embers = tier >= 2,
		flow = tier >= 3,
		aura = tier >= 3,
		idle = tier >= 3,
	}
end

-- The premium item an art model shows, from what the runtime already stamps on it:
-- hunter bodies `HunterKey` (the variant's key), gun pieces `ArtKey` (`<HERO>_<SKIN>`), towers the
-- worn set (`SkinSet`), grenade props `<HERO>_GRENADE_<SKIN>`. nil = no effects.
function SkinFx.fromArt(kind: string, artKey: unknown): (string?, Item?)
	if type(artKey) ~= "string" then
		return nil, nil
	end
	local key: string? = nil
	if kind == "hunter" or kind == "tower" then
		key = artKey
	elseif kind == "weapon" or kind == "grenade" then
		for _, hero in HEROES do
			local prefix = if kind == "weapon" then hero .. "_" else hero .. "_GRENADE_"
			if string.sub(artKey, 1, #prefix) == prefix then
				key = string.sub(artKey, #prefix + 1)
			end
		end
	end
	local item = SkinFx.item(key)
	if item and item.kind == kind then
		return key, item
	end
	return nil, nil
end

-- The phase (0..1) of a seam piece in the tier-3 flow: by height above the model's base, so the
-- colour wave rises like lava welling up.
function SkinFx.phase(height: number, theme: Theme): number
	return (height / theme.flowLength) % 1
end

local function ramp(theme: Theme, x: number): Color3
	x = math.clamp(x, 0, 1)
	if x < 0.5 then
		return theme.deep:Lerp(theme.glow, x * 2)
	end
	return theme.glow:Lerp(theme.hot, (x - 0.5) * 2)
end

-- A `glow` piece's colour `t` seconds in. Tier 0 = the static glow. `boost` (0..1) brightens it:
-- a premium tower at stage 2 (tier 5) glows hotter.
function SkinFx.glowColour(theme: Theme, tier: number, t: number, phase: number?, boost: number?): Color3
	if tier <= 0 then
		return theme.glow
	end
	local b = boost or 0
	local k = (math.sin(t * 2 * math.pi / theme.pulseSeconds) + 1) / 2
	if tier < 3 then
		return ramp(theme, 0.5 + (0.32 + 0.12 * b) * k + 0.1 * b)
	end
	local f = (math.sin((t / theme.flowSeconds - (phase or 0)) * 2 * math.pi) + 1) / 2
	return ramp(theme, 0.28 + 0.46 * f + 0.18 * k + 0.12 * b)
end

-- Ember particles for a premium piece, or nil (tier < 2, or low graphics). `where` = "hunter",
-- "weapon" (the muzzle) or "tower" (stage 2 doubles the rate, within the cap).
function SkinFx.embers(theme: Theme, tier: number, where: string, stage: number?, lowGraphics: boolean?): Emitter?
	if tier < 2 or lowGraphics then
		return nil
	end
	local rate
	if where == "hunter" then
		rate = math.min(if tier >= 3 then 4 else 2, SkinFx.HUNTER_RATE_CAP)
	elseif where == "weapon" then
		rate = if tier >= 3 then 2 else 1.5
	else
		rate = (if tier >= 3 then 2 else 1.5) * (if (stage or 0) >= 2 then 2 else 1)
		rate = math.min(rate, SkinFx.TOWER_RATE_CAP)
	end
	return {
		rate = rate,
		lifetime = { 0.9, 1.6 },
		speed = { 0.6, 1.4 },
		size = { if where == "weapon" then 0.12 elseif where == "hunter" then 0.22 else 0.3, 0 },
		spread = 25,
		colour = { theme.ember, theme.emberEnd },
		lightEmission = 0.35, -- not fully additive: embers must read against a bright sky too
		rise = 1.2,
	}
end

-- Tier 3's aura: a low, soft heat glow round the hunter's feet / a stage-2 tower's base (kept small
-- and low: never over a name tag), or nil.
function SkinFx.aura(theme: Theme, tier: number, where: string, stage: number?, lowGraphics: boolean?): Emitter?
	if tier < 3 or lowGraphics or (where == "tower" and (stage or 0) < 2) then
		return nil
	end
	return {
		rate = 2,
		lifetime = { 0.8, 1.2 },
		speed = { 0.3, 0.7 },
		size = { if where == "hunter" then 1.2 else 1.6, 0.2 },
		spread = 180,
		colour = { theme.glow, theme.deep },
		lightEmission = 0.6,
		rise = 0.4,
	}
end

-- A soft light on tier 3 pieces: (brightness at rest, pulse amount, range) or nil.
function SkinFx.light(tier: number, where: string, stage: number?): (number?, number?, number?)
	if tier < 3 or (where == "tower" and (stage or 0) < 2) then
		return nil, nil, nil
	end
	return 0.8, 0.6, if where == "hunter" then 8 else 10
end

------------------------------------------------------------------ server colours

-- A shot's tracer: the worn premium weapon skin's colour, else `fallback` (today's rule).
function SkinFx.tracerColour(weaponSkin: unknown, fallback: Color3): Color3
	local item, theme = SkinFx.item(weaponSkin), SkinFx.theme(weaponSkin)
	return if item and theme and item.kind == "weapon" then theme.tracer else fallback
end

-- A grenade blast's colour (+ the smoke puff's, or nil): the worn premium grenade skin's for
-- this hero, else `fallback` and no puff.
function SkinFx.blastColours(grenadeSkin: unknown, hero: string, fallback: Color3): (Color3, Color3?)
	local item, theme = SkinFx.item(grenadeSkin), SkinFx.theme(grenadeSkin)
	if item and theme and item.kind == "grenade" and item.hero == hero then
		return theme.blast, theme.blastSmoke
	end
	return fallback, nil
end

-- The hero ability's VFX colour: the worn premium ability skin's (for this hero), else
-- `fallback`. Colour only: radius, shape, timing, sound and the warning ring never change.
function SkinFx.abilityColour(abilitySkin: unknown, hero: string, fallback: Color3): Color3
	local item, theme = SkinFx.item(abilitySkin), SkinFx.theme(abilitySkin)
	return if item and theme and item.kind == "ability" and item.hero == hero then theme.ability else fallback
end

-- The player attribute a premium kind's worn key lives in (Skins' `Skin_<kind>_<HERO>` naming).
function SkinFx.attribute(kind: string, hero: string): string
	return `Skin_{kind}_{hero}`
end

-- The grenade art to throw for a worn grenade skin: `<HERO>_GRENADE_<SKIN>`, or nil (the base).
function SkinFx.grenadeArtKey(hero: string, grenadeSkin: unknown): string?
	local item = SkinFx.item(grenadeSkin)
	if item and item.kind == "grenade" and item.hero == hero then
		return `{hero}_GRENADE_{grenadeSkin}`
	end
	return nil
end

return SkinFx
