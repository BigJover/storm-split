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
	square = "rbxasset://textures/particles/SquareParticle.png", -- pixels (electric)
	implosion = "rbxasset://textures/particles/explosion01_implosion_main.dds", -- black hole (cosmic)
	vortex = "rbxasset://textures/particles/forcefield_vortex_main.dds", -- gravity swirl (cosmic)
	glow = "rbxasset://textures/particles/forcefield_glow_main.dds", -- soft halo (primal runes, charge)
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
	-- The other four themes (PREMIUM_SKINS "The themes"; #462: each its own element). Colours for
	-- tiers 0-3; their art lands batch by batch, and until then nothing wears them.
	CYBER_RAPTOR = table.freeze({
		display = "Cyber Raptor",
		glow = Color3.fromRGB(60, 230, 255),
		hot = Color3.fromRGB(235, 255, 255),
		deep = Color3.fromRGB(230, 60, 255), -- the flow runs cyan <-> magenta
		ember = Color3.fromRGB(120, 240, 255),
		emberEnd = Color3.fromRGB(230, 60, 255),
		tracer = Color3.fromRGB(80, 240, 255),
		blast = Color3.fromRGB(90, 230, 255),
		blastSmoke = Color3.fromRGB(30, 34, 52),
		ability = Color3.fromRGB(60, 230, 255),
		pulseSeconds = 2,
		flowSeconds = 1.6,
		flowLength = 2,
	}),
	TYRANT_KING = table.freeze({
		display = "Tyrant King",
		glow = Color3.fromRGB(220, 30, 30),
		hot = Color3.fromRGB(255, 200, 110),
		deep = Color3.fromRGB(90, 6, 10),
		ember = Color3.fromRGB(255, 120, 60),
		emberEnd = Color3.fromRGB(120, 10, 10),
		tracer = Color3.fromRGB(230, 40, 30),
		blast = Color3.fromRGB(210, 30, 30),
		blastSmoke = Color3.fromRGB(96, 78, 62),
		ability = Color3.fromRGB(220, 30, 30),
		pulseSeconds = 1.6,
		flowSeconds = 3,
		flowLength = 3,
	}),
	NEBULA = table.freeze({
		display = "Nebula",
		glow = Color3.fromRGB(150, 110, 255),
		hot = Color3.fromRGB(250, 244, 255),
		deep = Color3.fromRGB(40, 20, 110),
		ember = Color3.fromRGB(225, 215, 255),
		emberEnd = Color3.fromRGB(90, 60, 200),
		tracer = Color3.fromRGB(245, 245, 255),
		blast = Color3.fromRGB(160, 120, 255),
		blastSmoke = Color3.fromRGB(30, 20, 60),
		ability = Color3.fromRGB(150, 110, 255),
		pulseSeconds = 4,
		flowSeconds = 3.5,
		flowLength = 4,
	}),
	GEODE = table.freeze({
		display = "Geode",
		glow = Color3.fromRGB(190, 110, 255),
		hot = Color3.fromRGB(250, 236, 255),
		deep = Color3.fromRGB(90, 40, 150),
		ember = Color3.fromRGB(232, 204, 255),
		emberEnd = Color3.fromRGB(140, 80, 220),
		tracer = Color3.fromRGB(210, 150, 255),
		blast = Color3.fromRGB(190, 110, 255),
		blastSmoke = Color3.fromRGB(80, 76, 84),
		ability = Color3.fromRGB(190, 110, 255),
		pulseSeconds = 2.6,
		flowSeconds = 2,
		flowLength = 2.5,
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
	-- The Big Game Hunter's pieces of the other four themes (PREMIUM_SKINS names), same planned
	-- tiers as the Lava Lord sample; not in the Skins sheet yet, so nobody wears them in play.
	MECHA_MARKSMAN = table.freeze({ kind = "hunter", hero = "RIFLE", theme = "CYBER_RAPTOR", display = "Mecha Marksman", fxTier = 3 }),
	RAIL_RIFLE = table.freeze({ kind = "weapon", hero = "RIFLE", theme = "CYBER_RAPTOR", display = "Rail Rifle", fxTier = 2 }),
	CYBER_RAPTOR = table.freeze({ kind = "tower", theme = "CYBER_RAPTOR", display = "Cyber Raptor", fxTier = 3 }),
	PULSE_PUCK = table.freeze({ kind = "grenade", hero = "RIFLE", theme = "CYBER_RAPTOR", display = "Pulse Puck", fxTier = 0 }),
	OVERCLOCK = table.freeze({ kind = "ability", hero = "RIFLE", theme = "CYBER_RAPTOR", display = "Overclock", fxTier = 0 }),
	REX_ROYAL = table.freeze({ kind = "hunter", hero = "RIFLE", theme = "TYRANT_KING", display = "Rex Royal", fxTier = 3 }),
	KINGS_CLAW = table.freeze({ kind = "weapon", hero = "RIFLE", theme = "TYRANT_KING", display = "King's Claw", fxTier = 2 }),
	TYRANT_KING = table.freeze({ kind = "tower", theme = "TYRANT_KING", display = "Tyrant King", fxTier = 3 }),
	CROWN_JEWEL = table.freeze({ kind = "grenade", hero = "RIFLE", theme = "TYRANT_KING", display = "Crown Jewel", fxTier = 0 }),
	TYRANT_ROAR = table.freeze({ kind = "ability", hero = "RIFLE", theme = "TYRANT_KING", display = "Tyrant Roar", fxTier = 0 }),
	COSMIC_CAPTAIN = table.freeze({ kind = "hunter", hero = "RIFLE", theme = "NEBULA", display = "Cosmic Captain", fxTier = 3 }),
	STAR_GAZER = table.freeze({ kind = "weapon", hero = "RIFLE", theme = "NEBULA", display = "Star Gazer", fxTier = 2 }),
	NEBULA = table.freeze({ kind = "tower", theme = "NEBULA", display = "Nebula", fxTier = 3 }),
	MOON_ROCK = table.freeze({ kind = "grenade", hero = "RIFLE", theme = "NEBULA", display = "Moon Rock", fxTier = 0 }),
	COSMIC_CALL = table.freeze({ kind = "ability", hero = "RIFLE", theme = "NEBULA", display = "Cosmic Call", fxTier = 0 }),
	GEM_GAMEKEEPER = table.freeze({ kind = "hunter", hero = "RIFLE", theme = "GEODE", display = "Gem Gamekeeper", fxTier = 3 }),
	PRISM_RIFLE = table.freeze({ kind = "weapon", hero = "RIFLE", theme = "GEODE", display = "Prism Rifle", fxTier = 2 }),
	GEODE = table.freeze({ kind = "tower", theme = "GEODE", display = "Geode", fxTier = 3 }),
	GEODE_GRENADE = table.freeze({ kind = "grenade", hero = "RIFLE", theme = "GEODE", display = "Geode Grenade", fxTier = 0 }),
	CRYSTAL_CHIME = table.freeze({ kind = "ability", hero = "RIFLE", theme = "GEODE", display = "Crystal Chime", fxTier = 0 }),
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

	Data-driven per element (ELEMENTS): Lava Lord = "fire", Cyber Raptor = "electric", Tyrant King
	= "primal", Nebula = "cosmic", Geode = "crystal" - all built (#466). Every element fills the same
	slots (aura, flames, rising, drips, ring, footprints, take-down, the reactive weapon, grenade),
	but each moves differently: `behaviour` picks a small client handler (flicker / crackle / heartbeat
	/ drift / shards) and the style fields pick how a slot is drawn (mark.shape, takedown.style,
	splash.style, tracer.style, look = textures). The reactive weapon's `heat` is the element's own
	build-up, named by `charge`: fire heat, electric charge, primal fury (kills add `perKill`),
	cosmic gravity, crystal resonance.

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
-- The client's world bursts (Client/SkinFx recipes): every element's drip.puff / takedown.blast /
-- takedown.rain names one of these.
SkinFx.WORLD_KINDS = table.freeze({ "fireball", "plume", "sparks", "shower", "lick", "hiss", "blast", "rain", "puff", "zap" })
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
	behaviour: string, -- the client handler: "flicker" (fire) | "crackle" | "heartbeat" | "drift" | "shards"
	charge: string, -- what the reactive weapon builds: "heat" | "charge" | "fury" | "gravity" | "resonance"
	-- built-in textures (TEXTURES keys) per slot: the flames / rising / aura emitters, the standing
	-- ring's pops, the muzzle flash, the hot-shot burst and the vents' haze
	look: { flames: string, rising: string, aura: string, ring: string, muzzle: string, core: string, haze: string },
	tracer: { style: string, colour: { Color3 }, lifetime: number, width: number }, -- "bolt" | "chain" | "comet" | "prism"
	fx: { [string]: { Color3 } }, -- world burst colours by kind (blast, rain, puff...), start -> end
	-- the pack tier's own seam animation ("scroll" | "beat" | "drift"), nil = tier 3's flow (fire)
	seams: { mode: string, colours: { Color3 }, cycle: number }?,
	arcs: { count: number, every: { number }, life: number, width: number, jitter: number, colour: { Color3 } }?, -- electric
	glitch: { every: { number }, seconds: number, offset: number, colour: Color3 }?, -- electric
	eyes: { colour: Color3, size: number, brightness: number, rate: number }?, -- primal
	orbit: { kind: string, count: number, radius: number, speed: number, bob: number, size: number, colour: { Color3 }, rate: number }?,
	glint: { every: { number }, colour: Color3 }?, -- a seam piece flashes (crystal glints, cosmic twinkle)
	aura: Emitter, -- round the hunter's torso
	-- tongues licking up off the hunter's `hosts` (R15 parts: helm horns + pauldrons); `colour` is
	-- the colour over life (white-yellow -> orange -> red -> smoke), `size` start / peak / end
	flames: { rate: number, lifetime: { number }, speed: { number }, size: { number }, spread: number, rise: number,
		colour: { Color3 }, hosts: { string } },
	rising: { rate: number, lifetime: { number }, speed: { number }, size: number, spread: number, rise: number,
		drag: number, colour: { Color3 } }, -- slow embers drifting / swirling up off the body
	glow: { colour: Color3, brightness: number, range: number, flicker: number }, -- the flickering heat light
	-- off the pauldrons; `puff` = the world burst where it lands
	drip: { every: { number }, colour: Color3, crust: Color3, size: number, hiss: number, puff: string },
	ring: { after: number, fade: number, radius: number, rate: number, scorch: Color3, glow: Color3, edge: Color3 }, -- standing still
	-- footsteps: a print `hot` -> `rim` -> `colour` while it fades, + a small lick; `shape` = "disc" |
	-- "hex" (circuit print) | "crack" (stomp) | "spike" (crystal spikes that sprout and shatter)
	mark: { colour: Color3, rim: Color3, hot: Color3, size: number, lifetime: number, every: number, lick: number, shape: string },
	-- `style` = "crack" (ground crack) | "traces" (circuit traces) | "spikes" (crystal eruption) | "none";
	-- `blast` / `rain` = the world bursts (fireball + ember shower for fire)
	takedown: { count: number, colour: { Color3 }, size: number, speed: number, fireball: number, shower: number,
		style: string, blast: string, rain: string,
		ring: { radius: number, seconds: number }, crack: { arms: number, length: number, seconds: number, width: number },
		flash: { brightness: number, range: number, seconds: number } },
	heat: { cool: Color3, hot: Color3, white: Color3, perShot: number, decay: number, burstAt: number, puffFrom: number,
		hazeFrom: number, hazeRate: number, overheatAt: number, rearmBelow: number, perKill: number },
	-- per-shot flash: `min`..`max` particles by heat (+ a light flash), the flame burst from burstAt
	muzzle: { count: number, colour: { Color3 }, size: number, speed: number, min: number, max: number,
		light: number, lightHot: number, range: number },
	puff: Burst, -- steam / embers when cooling
	shell: { count: number, colour: { Color3 }, speed: number }, -- molten casing / ember kicked out a shot
	steam: { overheat: number, reloadRate: number, size: number, colour: { Color3 } }, -- overheat blast / reload steam
	trail: { colour: { Color3 }, lifetime: number, width: number, rate: number, smoke: Color3, smokeLifetime: number },
	-- `style` = "lava" | "emp" (pulse ring) | "roar" (dust ring) | "implode" (black hole, then stars) | "shatter"
	splash: { colour: Color3, radius: number, lifetime: number, count: number, fireball: number, plume: number,
		linger: number, bubbles: number, crust: Color3, flash: { brightness: number, range: number, seconds: number }, style: string },
	-- built-in client sounds only (crackle / hiss / whoosh need an upload): `pitch` reshapes the one
	-- explosion (high = a snap / shatter, low = a deep thrum)
	sound: { boom: string?, volume: number, pitch: number },
	extra: number, -- particles a second from the behaviour's own emitters (eyes, orbiting stars), inside PACK_RATE_CAP
}

local rgb = Color3.fromRGB
local HOSTS = { "Head", "LeftUpperArm", "RightUpperArm" } -- helm + pauldrons (R15 parts)
local BOOM = "rbxasset://sounds/impact_explosion_03.mp3" -- the only fitting built-in sound
SkinFx.ELEMENTS = table.freeze({
	fire = table.freeze({
		display = "Fire",
		stub = false,
		behaviour = "flicker",
		charge = "heat",
		look = table.freeze({ flames = "fire", rising = "sparks", aura = "fire", ring = "fire", muzzle = "fire", core = "core", haze = "smoke" }),
		tracer = table.freeze({ style = "bolt", colour = { rgb(255, 240, 190), rgb(200, 40, 8) }, lifetime = 0.14, width = 0.36 }),
		fx = table.freeze({}), -- fire keeps the base world bursts' own colours
		extra = 0,
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
		drip = table.freeze({ every = { 1.4, 3 }, colour = rgb(255, 156, 40), crust = rgb(60, 26, 16), size = 0.24, hiss = 4, puff = "hiss" }),
		ring = table.freeze({ after = 0.7, fade = 0.5, radius = 2.6, rate = 10, scorch = rgb(22, 14, 12), glow = rgb(255, 112, 20), edge = rgb(255, 112, 20) }),
		mark = table.freeze({
			colour = rgb(40, 22, 18), rim = rgb(255, 104, 20), hot = rgb(255, 236, 170),
			size = 0.8, lifetime = 2.6, every = 2.4, lick = 3, shape = "disc",
		}),
		takedown = table.freeze({
			count = 22, colour = { rgb(255, 226, 140), rgb(230, 60, 10) }, size = 0.6, speed = 10,
			fireball = 6, shower = 26, style = "crack", blast = "fireball", rain = "shower",
			ring = { radius = 7, seconds = 0.55 }, crack = { arms = 7, length = 3.4, seconds = 2.2, width = 0.16 },
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
			perKill = 0, -- heat a take-down adds (fire: none)
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
			flash = { brightness = 7, range = 20, seconds = 0.4 }, style = "lava",
		}),
		sound = table.freeze({ boom = BOOM, volume = 0.35, pitch = 1 }),
	}),

	-- Cyber Raptor: circuit seams scrolling cyan -> magenta, crackling arcs between body points,
	-- glitch pops (seams flash + displaced scanline slices), pixel sparks. The gun CHARGES: a
	-- capacitor glow that whines up, an arcing muzzle and chain-lightning tracers; the grenade is
	-- an EMP pulse ring.
	electric = table.freeze({
		display = "Electric",
		stub = false,
		behaviour = "crackle",
		charge = "charge",
		look = table.freeze({ flames = "sparks", rising = "square", aura = "sparkles", ring = "sparks", muzzle = "sparks", core = "glow", haze = "sparks" }),
		tracer = table.freeze({ style = "chain", colour = { rgb(245, 255, 255), rgb(60, 230, 255), rgb(230, 60, 255) }, lifetime = 0.12, width = 0.22 }),
		fx = table.freeze({
			blast = { rgb(245, 255, 255), rgb(60, 230, 255) }, rain = { rgb(120, 240, 255), rgb(230, 60, 255) },
			puff = { rgb(200, 250, 255), rgb(60, 230, 255) }, sparks = { rgb(245, 255, 255), rgb(60, 230, 255) },
			lick = { rgb(245, 255, 255), rgb(60, 230, 255) }, plume = { rgb(60, 80, 130), rgb(20, 24, 44) },
		}),
		seams = table.freeze({ mode = "scroll", colours = { rgb(60, 230, 255), rgb(120, 130, 255), rgb(230, 60, 255), rgb(120, 130, 255) }, cycle = 2.2 }),
		arcs = table.freeze({ count = 2, every = { 0.3, 0.8 }, life = 0.12, width = 0.14, jitter = 1.4, colour = { rgb(245, 255, 255), rgb(60, 230, 255) } }),
		glitch = table.freeze({ every = { 2.4, 4.2 }, seconds = 0.1, offset = 0.45, colour = rgb(230, 60, 255) }),
		extra = 0,
		aura = table.freeze({ -- static crackle hugging the torso
			rate = 3, lifetime = { 0.12, 0.25 }, speed = { 0.2, 0.6 }, size = { 0.5, 0.1 }, spread = 180,
			colour = { rgb(200, 250, 255), rgb(230, 60, 255) }, lightEmission = 1, rise = 0,
		}),
		flames = table.freeze({ -- spark crackle snapping off the visor + shoulder plates
			rate = 5, lifetime = { 0.1, 0.22 }, speed = { 3, 6 }, size = { 0.18, 0.35, 0 }, spread = 70, rise = 0,
			colour = { rgb(255, 255, 255), rgb(60, 230, 255), rgb(230, 60, 255) }, hosts = HOSTS,
		}),
		rising = table.freeze({ -- square pixels drifting off and fading
			rate = 4, lifetime = { 0.6, 1.1 }, speed = { 0.4, 1 }, size = 0.13, spread = 90, rise = 0.8, drag = 1.5,
			colour = { rgb(120, 240, 255), rgb(230, 60, 255) },
		}),
		glow = table.freeze({ colour = rgb(60, 230, 255), brightness = 1.4, range = 11, flicker = 0.6 }),
		drip = table.freeze({ every = { 1.8, 3.4 }, colour = rgb(200, 250, 255), crust = rgb(20, 44, 70), size = 0.15, hiss = 5, puff = "zap" }),
		ring = table.freeze({ after = 0.7, fade = 0.4, radius = 2.6, rate = 8, scorch = rgb(10, 14, 30), glow = rgb(60, 230, 255), edge = rgb(230, 60, 255) }),
		mark = table.freeze({
			colour = rgb(30, 40, 80), rim = rgb(60, 230, 255), hot = rgb(245, 255, 255),
			size = 0.9, lifetime = 2.2, every = 2.4, lick = 3, shape = "hex",
		}),
		takedown = table.freeze({ -- digital dissolve: a pixel burst, a shock ring, circuit traces racing out
			count = 24, colour = { rgb(245, 255, 255), rgb(230, 60, 255) }, size = 0.4, speed = 12,
			fireball = 14, shower = 18, style = "traces", blast = "blast", rain = "rain",
			ring = { radius = 7.5, seconds = 0.35 }, crack = { arms = 8, length = 3.6, seconds = 1.2, width = 0.08 },
			flash = { brightness = 8, range = 18, seconds = 0.2 },
		}),
		heat = table.freeze({ -- CHARGE: the capacitor whines up, bleeds off fast
			cool = rgb(16, 56, 84), hot = rgb(60, 230, 255), white = rgb(255, 225, 255),
			perShot = 0.08, decay = 0.3, burstAt = 0.7, puffFrom = 0.45, hazeFrom = 0.5, hazeRate = 7,
			overheatAt = 0.95, rearmBelow = 0.6, perKill = 0,
		}),
		muzzle = table.freeze({
			count = 8, colour = { rgb(255, 255, 255), rgb(60, 230, 255) }, size = 0.24, speed = 10,
			min = 4, max = 14, light = 3, lightHot = 9, range = 12,
		}),
		puff = table.freeze({ count = 8, colour = { rgb(200, 250, 255), rgb(230, 60, 255) }, size = 0.3, speed = 4 }), -- discharge
		shell = table.freeze({ count = 1, colour = { rgb(255, 255, 255), rgb(60, 230, 255) }, speed = 9 }), -- a spent cell spark
		steam = table.freeze({ overheat = 24, reloadRate = 16, size = 0.5, colour = { rgb(255, 255, 255), rgb(60, 230, 255) } }),
		trail = table.freeze({
			colour = { rgb(60, 230, 255), rgb(230, 60, 255) }, lifetime = 0.3, width = 0.5, rate = 14,
			smoke = rgb(50, 40, 100), smokeLifetime = 0.4,
		}),
		splash = table.freeze({ -- EMP: a fast pulse ring + spark and pixel bursts
			colour = rgb(60, 230, 255), radius = 3.2, lifetime = 1.2, count = 20, fireball = 12, plume = 0,
			linger = 0.8, bubbles = 12, crust = rgb(20, 30, 50), flash = { brightness = 8, range = 22, seconds = 0.25 }, style = "emp",
		}),
		sound = table.freeze({ boom = BOOM, volume = 0.2, pitch = 1.9 }),
	}),

	-- Tyrant King: red runes that throb like a heartbeat, crimson eyes, bone dust + red embers; a
	-- roar shockwave on a take-down. The gun builds FURY (shots + take-downs): a red aura flare,
	-- shockwave puffs at the muzzle, blood-red tracer trails (no gore); a roaring dust-ring grenade.
	primal = table.freeze({
		display = "Primal",
		stub = false,
		behaviour = "heartbeat",
		charge = "fury",
		look = table.freeze({ flames = "smoke", rising = "sparks", aura = "glow", ring = "smoke", muzzle = "fire", core = "shock", haze = "sparks" }),
		tracer = table.freeze({ style = "bolt", colour = { rgb(255, 210, 150), rgb(200, 12, 12), rgb(80, 0, 0) }, lifetime = 0.3, width = 0.4 }),
		fx = table.freeze({
			blast = { rgb(255, 190, 120), rgb(200, 20, 20) }, rain = { rgb(232, 220, 196), rgb(120, 100, 86) },
			puff = { rgb(220, 200, 170), rgb(110, 90, 76) }, sparks = { rgb(255, 200, 140), rgb(200, 20, 20) },
			lick = { rgb(255, 120, 80), rgb(150, 10, 10) }, plume = { rgb(150, 126, 100), rgb(80, 64, 52) },
		}),
		seams = table.freeze({ mode = "beat", colours = { rgb(90, 6, 10), rgb(255, 36, 30), rgb(255, 196, 120) }, cycle = 60 / 72 }),
		eyes = table.freeze({ colour = rgb(255, 30, 20), size = 0.14, brightness = 2.2, rate = 1.5 }),
		extra = 3, -- two eyes x 1.5 wisps a second
		aura = table.freeze({ -- the red runic glow round the torso (soft halo)
			rate = 4, lifetime = { 0.6, 1 }, speed = { 0.2, 0.5 }, size = { 1.3, 0.4 }, spread = 180,
			colour = { rgb(255, 40, 30), rgb(90, 0, 0) }, lightEmission = 0.7, rise = 0.5,
		}),
		flames = table.freeze({ -- bone dust shaking off the helm + pauldrons
			rate = 3, lifetime = { 0.8, 1.4 }, speed = { 0.6, 1.2 }, size = { 0.3, 0.8, 1.1 }, spread = 40, rise = 0.5,
			colour = { rgb(236, 224, 200), rgb(200, 180, 150), rgb(120, 100, 90) }, hosts = HOSTS,
		}),
		rising = table.freeze({ -- red embers
			rate = 6, lifetime = { 1.2, 2 }, speed = { 0.8, 1.6 }, size = 0.14, spread = 60, rise = 1.4, drag = 0.8,
			colour = { rgb(255, 96, 50), rgb(160, 10, 10) },
		}),
		glow = table.freeze({ colour = rgb(255, 40, 30), brightness = 1.5, range = 12, flicker = 0.15 }),
		drip = table.freeze({ every = { 2.2, 4 }, colour = rgb(255, 64, 40), crust = rgb(60, 40, 32), size = 0.14, hiss = 5, puff = "puff" }),
		ring = table.freeze({ after = 0.7, fade = 0.6, radius = 3, rate = 6, scorch = rgb(40, 26, 20), glow = rgb(220, 30, 30), edge = rgb(255, 190, 110) }),
		mark = table.freeze({
			colour = rgb(60, 42, 34), rim = rgb(220, 30, 30), hot = rgb(255, 180, 120),
			size = 1.3, lifetime = 3, every = 2.8, lick = 5, shape = "crack",
		}),
		takedown = table.freeze({ -- the roar: a huge ground shockwave, dust, a cracked crater
			count = 20, colour = { rgb(255, 200, 150), rgb(200, 20, 20) }, size = 0.6, speed = 11,
			fireball = 6, shower = 18, style = "crack", blast = "blast", rain = "rain",
			ring = { radius = 11, seconds = 0.7 }, crack = { arms = 8, length = 4.2, seconds = 2.4, width = 0.2 },
			flash = { brightness = 6, range = 20, seconds = 0.3 },
		}),
		heat = table.freeze({ -- FURY: builds with shots and take-downs, lingers
			cool = rgb(70, 6, 8), hot = rgb(220, 30, 30), white = rgb(255, 200, 120),
			perShot = 0.07, decay = 0.15, burstAt = 0.7, puffFrom = 0.45, hazeFrom = 0.55, hazeRate = 6,
			overheatAt = 0.95, rearmBelow = 0.55, perKill = 0.18,
		}),
		muzzle = table.freeze({
			count = 6, colour = { rgb(255, 210, 160), rgb(200, 20, 20) }, size = 0.4, speed = 6,
			min = 3, max = 10, light = 2, lightHot = 7, range = 12,
		}),
		puff = table.freeze({ count = 8, colour = { rgb(230, 214, 190), rgb(110, 90, 80) }, size = 0.7, speed = 2 }), -- dust
		shell = table.freeze({ count = 1, colour = { rgb(255, 200, 150), rgb(200, 30, 20) }, speed = 7 }),
		steam = table.freeze({ overheat = 20, reloadRate = 12, size = 1.4, colour = { rgb(230, 214, 190), rgb(120, 100, 90) } }),
		trail = table.freeze({
			colour = { rgb(255, 60, 40), rgb(110, 0, 0) }, lifetime = 0.5, width = 0.6, rate = 12,
			smoke = rgb(120, 100, 84), smokeLifetime = 1,
		}),
		splash = table.freeze({ -- a roaring crimson burst with a dust ring
			colour = rgb(220, 30, 30), radius = 3, lifetime = 1.8, count = 16, fireball = 8, plume = 8, linger = 1,
			bubbles = 0, crust = rgb(60, 40, 32), flash = { brightness = 7, range = 20, seconds = 0.35 }, style = "roar",
		}),
		sound = table.freeze({ boom = BOOM, volume = 0.4, pitch = 0.7 }),
	}),

	-- Nebula: star speckles that twinkle on the seams, slow nebula clouds, stars orbiting the
	-- hunter with comet tails. The gun builds GRAVITY: a vortex swirling at the muzzle, comet
	-- tracers; the grenade is a mini black hole that implodes, then bursts into stars.
	cosmic = table.freeze({
		display = "Cosmic",
		stub = false,
		behaviour = "drift",
		charge = "gravity",
		look = table.freeze({ flames = "sparkles", rising = "sparkles", aura = "smoke", ring = "sparkles", muzzle = "sparkles", core = "implosion", haze = "vortex" }),
		tracer = table.freeze({ style = "comet", colour = { rgb(255, 255, 255), rgb(180, 160, 255), rgb(80, 50, 200) }, lifetime = 0.35, width = 0.45 }),
		fx = table.freeze({
			blast = { rgb(255, 255, 255), rgb(150, 110, 255) }, rain = { rgb(255, 255, 255), rgb(160, 130, 255) },
			puff = { rgb(255, 255, 255), rgb(170, 150, 255) }, sparks = { rgb(255, 255, 255), rgb(150, 110, 255) },
			lick = { rgb(255, 255, 255), rgb(170, 150, 255) }, plume = { rgb(110, 60, 200), rgb(220, 90, 180) },
		}),
		seams = table.freeze({ mode = "drift", colours = { rgb(90, 60, 220), rgb(150, 110, 255), rgb(80, 200, 220), rgb(230, 120, 220) }, cycle = 6 }),
		orbit = table.freeze({ kind = "stars", count = 3, radius = 1.7, speed = 1.4, bob = 0.4, size = 0.25,
			colour = { rgb(255, 255, 255), rgb(160, 130, 255) }, rate = 4 }),
		glint = table.freeze({ every = { 0.15, 0.4 }, colour = rgb(255, 255, 255) }), -- star twinkle
		extra = 12, -- three orbiting stars x 4 a second (their comet tails)
		aura = table.freeze({ -- slow nebula clouds, indigo -> pink
			rate = 3, lifetime = { 1.6, 2.4 }, speed = { 0.2, 0.5 }, size = { 1.4, 2.4 }, spread = 180,
			colour = { rgb(110, 60, 200), rgb(230, 90, 180) }, lightEmission = 0.45, rise = 0.2,
		}),
		flames = table.freeze({ -- little comet streaks off the helm + shoulders
			rate = 2.5, lifetime = { 0.5, 0.9 }, speed = { 1, 2 }, size = { 0.25, 0.4, 0 }, spread = 30, rise = 0.5,
			colour = { rgb(255, 255, 255), rgb(180, 160, 255), rgb(90, 60, 200) }, hosts = HOSTS,
		}),
		rising = table.freeze({ -- star speckles that hang and twinkle
			rate = 5, lifetime = { 0.8, 1.6 }, speed = { 0.1, 0.4 }, size = 0.16, spread = 180, rise = 0, drag = 1,
			colour = { rgb(255, 255, 255), rgb(170, 150, 255) },
		}),
		glow = table.freeze({ colour = rgb(150, 110, 255), brightness = 1.3, range = 12, flicker = 0.2 }),
		drip = table.freeze({ every = { 1.8, 3.6 }, colour = rgb(240, 236, 255), crust = rgb(60, 40, 140), size = 0.14, hiss = 4, puff = "rain" }),
		ring = table.freeze({ after = 0.7, fade = 0.8, radius = 2.8, rate = 6, scorch = rgb(14, 8, 40), glow = rgb(150, 110, 255), edge = rgb(240, 160, 255) }),
		mark = table.freeze({
			colour = rgb(70, 50, 170), rim = rgb(170, 140, 255), hot = rgb(255, 255, 255),
			size = 0.8, lifetime = 2.4, every = 2.4, lick = 3, shape = "disc",
		}),
		takedown = table.freeze({ -- supernova: a white flash, a star burst, a ring
			count = 26, colour = { rgb(255, 255, 255), rgb(160, 120, 255) }, size = 0.5, speed = 12,
			fireball = 8, shower = 20, style = "none", blast = "blast", rain = "rain",
			ring = { radius = 9, seconds = 0.6 }, crack = { arms = 0, length = 0, seconds = 1, width = 0.1 },
			flash = { brightness = 12, range = 24, seconds = 0.45 },
		}),
		heat = table.freeze({ -- GRAVITY: pulls in from early, eases off
			cool = rgb(30, 20, 80), hot = rgb(150, 110, 255), white = rgb(250, 245, 255),
			perShot = 0.08, decay = 0.2, burstAt = 0.7, puffFrom = 0.45, hazeFrom = 0.35, hazeRate = 8,
			overheatAt = 0.95, rearmBelow = 0.6, perKill = 0,
		}),
		muzzle = table.freeze({
			count = 6, colour = { rgb(255, 255, 255), rgb(150, 110, 255) }, size = 0.3, speed = 5,
			min = 3, max = 12, light = 2, lightHot = 7, range = 12,
		}),
		puff = table.freeze({ count = 8, colour = { rgb(200, 180, 255), rgb(60, 30, 140) }, size = 0.5, speed = 1.5 }),
		shell = table.freeze({ count = 1, colour = { rgb(255, 255, 255), rgb(150, 110, 255) }, speed = 6 }),
		steam = table.freeze({ overheat = 22, reloadRate = 14, size = 1.2, colour = { rgb(160, 110, 255), rgb(230, 90, 180) } }),
		trail = table.freeze({
			colour = { rgb(255, 255, 255), rgb(120, 90, 255) }, lifetime = 0.6, width = 0.5, rate = 14,
			smoke = rgb(70, 40, 140), smokeLifetime = 1,
		}),
		splash = table.freeze({ -- a mini black hole: pulls in, collapses, bursts into stars
			colour = rgb(20, 10, 40), radius = 2.4, lifetime = 1.8, count = 24, fireball = 8, plume = 4, linger = 0.6,
			bubbles = 10, crust = rgb(40, 20, 90), flash = { brightness = 10, range = 24, seconds = 0.4 }, style = "implode",
		}),
		sound = table.freeze({ boom = BOOM, volume = 0.3, pitch = 0.55 }),
	}),

	-- Geode: amethyst glints popping on the facets, crystal shards orbiting the hunter (pooled
	-- Parts), refracted colours drifting through the seams. The gun builds RESONANCE: glints
	-- growing at the vents, a shard-burst muzzle and prism tracers; the grenade shatters into
	-- shards that grow then fade.
	crystal = table.freeze({
		display = "Crystal",
		stub = false,
		behaviour = "shards",
		charge = "resonance",
		look = table.freeze({ flames = "sparkles", rising = "sparkles", aura = "glow", ring = "sparkles", muzzle = "sparkles", core = "sparks", haze = "sparkles" }),
		tracer = table.freeze({ style = "prism",
			colour = { rgb(255, 255, 255), rgb(255, 110, 120), rgb(255, 210, 90), rgb(120, 255, 150), rgb(100, 180, 255), rgb(190, 110, 255) },
			lifetime = 0.25, width = 0.4 }),
		fx = table.freeze({
			blast = { rgb(255, 255, 255), rgb(190, 110, 255) }, rain = { rgb(240, 220, 255), rgb(150, 90, 230) },
			puff = { rgb(255, 255, 255), rgb(200, 150, 255) }, sparks = { rgb(255, 255, 255), rgb(190, 110, 255) },
			lick = { rgb(255, 255, 255), rgb(200, 150, 255) }, plume = { rgb(170, 160, 190), rgb(90, 84, 100) },
		}),
		seams = table.freeze({ mode = "drift", colours = { rgb(190, 110, 255), rgb(140, 170, 255), rgb(255, 150, 230), rgb(220, 190, 255) }, cycle = 4 }),
		orbit = table.freeze({ kind = "shards", count = 5, radius = 1.7, speed = 0.9, bob = 0.35, size = 0.55,
			colour = { rgb(200, 130, 255), rgb(245, 230, 255) }, rate = 0 }),
		glint = table.freeze({ every = { 0.35, 0.8 }, colour = rgb(255, 255, 255) }),
		extra = 0, -- the shards are Parts, not particles
		aura = table.freeze({ -- refracted light motes (soft halo)
			rate = 3, lifetime = { 0.6, 1 }, speed = { 0.2, 0.5 }, size = { 0.7, 0.1 }, spread = 180,
			colour = { rgb(255, 170, 240), rgb(140, 200, 255) }, lightEmission = 0.8, rise = 0.4,
		}),
		flames = table.freeze({ -- glints popping on the helm + pauldron facets
			rate = 3, lifetime = { 0.2, 0.35 }, speed = { 0, 0.2 }, size = { 0.1, 0.55, 0 }, spread = 180, rise = 0,
			colour = { rgb(255, 255, 255), rgb(220, 180, 255), rgb(190, 110, 255) }, hosts = HOSTS,
		}),
		rising = table.freeze({
			rate = 3, lifetime = { 1, 1.6 }, speed = { 0.3, 0.8 }, size = 0.12, spread = 60, rise = 0.6, drag = 1,
			colour = { rgb(240, 220, 255), rgb(150, 90, 230) },
		}),
		glow = table.freeze({ colour = rgb(190, 110, 255), brightness = 1.2, range = 11, flicker = 0.1 }),
		drip = table.freeze({ every = { 2.4, 4.2 }, colour = rgb(220, 170, 255), crust = rgb(90, 70, 110), size = 0.16, hiss = 4, puff = "blast" }),
		ring = table.freeze({ after = 0.7, fade = 0.6, radius = 2.6, rate = 6, scorch = rgb(50, 40, 64), glow = rgb(190, 110, 255), edge = rgb(240, 220, 255) }),
		mark = table.freeze({
			colour = rgb(120, 80, 170), rim = rgb(190, 110, 255), hot = rgb(250, 240, 255),
			size = 0.9, lifetime = 2.6, every = 2.6, lick = 4, shape = "spike",
		}),
		takedown = table.freeze({ -- a ring of crystals erupting from the ground, then shattering
			count = 20, colour = { rgb(255, 255, 255), rgb(190, 110, 255) }, size = 0.45, speed = 10,
			fireball = 8, shower = 16, style = "spikes", blast = "blast", rain = "rain",
			ring = { radius = 7, seconds = 0.5 }, crack = { arms = 9, length = 1.8, seconds = 1.8, width = 0.35 },
			flash = { brightness = 7, range = 18, seconds = 0.3 },
		}),
		heat = table.freeze({ -- RESONANCE: the crystal hums brighter
			cool = rgb(90, 60, 130), hot = rgb(190, 110, 255), white = rgb(250, 240, 255),
			perShot = 0.08, decay = 0.22, burstAt = 0.7, puffFrom = 0.45, hazeFrom = 0.5, hazeRate = 6,
			overheatAt = 0.95, rearmBelow = 0.6, perKill = 0,
		}),
		muzzle = table.freeze({
			count = 6, colour = { rgb(255, 255, 255), rgb(190, 110, 255) }, size = 0.3, speed = 9,
			min = 3, max = 12, light = 2, lightHot = 7, range = 11,
		}),
		puff = table.freeze({ count = 8, colour = { rgb(240, 220, 255), rgb(150, 90, 230) }, size = 0.35, speed = 3 }),
		shell = table.freeze({ count = 1, colour = { rgb(255, 255, 255), rgb(190, 110, 255) }, speed = 7 }),
		steam = table.freeze({ overheat = 20, reloadRate = 12, size = 0.6, colour = { rgb(255, 255, 255), rgb(190, 110, 255) } }),
		trail = table.freeze({
			colour = { rgb(250, 240, 255), rgb(150, 90, 230) }, lifetime = 0.4, width = 0.45, rate = 10,
			smoke = rgb(160, 140, 200), smokeLifetime = 0.5,
		}),
		splash = table.freeze({ -- crystal shatter: shards grow from the ground, then fade
			colour = rgb(190, 110, 255), radius = 2.6, lifetime = 1.9, count = 16, fireball = 8, plume = 3, linger = 0.8,
			bubbles = 8, crust = rgb(90, 70, 110), flash = { brightness = 7, range = 18, seconds = 0.35 }, style = "shatter",
		}),
		sound = table.freeze({ boom = BOOM, volume = 0.22, pitch = 1.6 }),
	}),
} :: { [string]: Element })

-- Each theme's element (#462: themes differ by element, not by recolour).
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
	CYBER_RAPTOR_RIFLE = table.freeze({
		theme = "CYBER_RAPTOR",
		hero = "RIFLE",
		display = "Cyber Raptor - Big Game Hunter Pack",
		items = table.freeze({ "MECHA_MARKSMAN", "RAIL_RIFLE", "CYBER_RAPTOR", "PULSE_PUCK", "OVERCLOCK" }),
	}),
	TYRANT_KING_RIFLE = table.freeze({
		theme = "TYRANT_KING",
		hero = "RIFLE",
		display = "Tyrant King - Big Game Hunter Pack",
		items = table.freeze({ "REX_ROYAL", "KINGS_CLAW", "TYRANT_KING", "CROWN_JEWEL", "TYRANT_ROAR" }),
	}),
	NEBULA_RIFLE = table.freeze({
		theme = "NEBULA",
		hero = "RIFLE",
		display = "Nebula - Big Game Hunter Pack",
		items = table.freeze({ "COSMIC_CAPTAIN", "STAR_GAZER", "NEBULA", "MOON_ROCK", "COSMIC_CALL" }),
	}),
	GEODE_RIFLE = table.freeze({
		theme = "GEODE",
		hero = "RIFLE",
		display = "Geode - Big Game Hunter Pack",
		items = table.freeze({ "GEM_GAMEKEEPER", "PRISM_RIFLE", "GEODE", "GEODE_GRENADE", "CRYSTAL_CHIME" }),
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
-- `extra` = the behaviour's own emitters (primal eyes, cosmic orbiting stars), in the same cap.
export type PackRates = { flames: number, rising: number, aura: number, extra: number, total: number }
function SkinFx.packRates(element: Element, quality: number): PackRates
	local q = math.clamp(quality, 0, 1)
	local hosts = math.max(1, #element.flames.hosts)
	local flames, rising, aura = element.flames.rate * q, element.rising.rate * q, element.aura.rate * q
	local extra = (element.extra or 0) * q
	local total = flames * hosts + rising + aura + extra
	if total > SkinFx.PACK_RATE_CAP then
		local k = SkinFx.PACK_RATE_CAP / total
		flames, rising, aura, extra = flames * k, rising * k, aura * k, extra * k
		total = SkinFx.PACK_RATE_CAP
	end
	return { flames = flames, rising = rising, aura = aura, extra = extra, total = total }
end

------------------------------------------------------------------ element behaviours (#466): the rules

-- A heartbeat 0..1 with period `period` seconds: a strong "lub" at the start of each beat, a
-- softer "dub" (0.7) at 30 %, near 0 for the rest.
function SkinFx.heartbeat(t: number, period: number): number
	local u = (t / math.max(period, 1e-3)) % 1
	local lubD = math.min(u, 1 - u) / 0.06
	local dubD = (u - 0.3) / 0.06
	return math.clamp(math.max(math.exp(-lubD * lubD), 0.7 * math.exp(-dubD * dubD)), 0, 1)
end

local function loopLerp(colours: { Color3 }, x: number, smooth: boolean): Color3
	local n = #colours
	if n == 1 then
		return colours[1]
	end
	local p = (x % 1) * n
	local i = math.floor(p)
	local f = p - i
	if smooth then
		f = f * f * (3 - 2 * f)
	end
	return colours[i % n + 1]:Lerp(colours[(i + 1) % n + 1], f)
end

-- The pack tier's own seam colour `t` seconds in for a piece at `phase` (0..1), or nil (fire: tier
-- 3's flow stays). "scroll" runs the colours along the seams (circuit lines), "beat" throbs rest ->
-- peak -> flash on the heartbeat (runes), "drift" fades slowly through them (nebula, refraction).
function SkinFx.seamColour(element: Element, t: number, phase: number?): Color3?
	local s = element.seams
	if not s then
		return nil
	end
	local c, cycle = s.colours, math.max(s.cycle, 1e-3)
	if s.mode == "beat" then
		local k = SkinFx.heartbeat(t, cycle)
		if k < 0.7 then
			return c[1]:Lerp(c[2], k / 0.7)
		end
		return c[2]:Lerp(c[3] or c[2], (k - 0.7) / 0.3)
	elseif s.mode == "scroll" then
		return loopLerp(c, t / cycle - (phase or 0), false)
	end
	return loopLerp(c, t / cycle + 0.5 * (phase or 0), true)
end

-- Orbiting item `i` of `n` `t` seconds in: its offset from the torso (evenly spaced round a
-- horizontal circle of the orbit's radius, each bobbing up and down).
function SkinFx.orbitOffset(element: Element, i: number, n: number, t: number): Vector3
	local o = element.orbit
	if not o then
		return Vector3.zero
	end
	local a = t * o.speed + (i - 1) / math.max(n, 1) * 2 * math.pi
	return Vector3.new(math.cos(a) * o.radius, math.sin(t * 1.3 + i * 2.1) * o.bob, math.sin(a) * o.radius)
end

-- Electric glitch: (popping now, sideways offset). One pop of `seconds` per window of the mean
-- `every`, at a start that moves window to window; the offset flips side each window. Never for
-- an element without `glitch`.
function SkinFx.glitch(element: Element, t: number, seed: number?): (boolean, number)
	local g = element.glitch
	if not g then
		return false, 0
	end
	local period = math.max((g.every[1] + g.every[2]) / 2, g.seconds * 2)
	local x = t + (seed or 0)
	local k = math.floor(x / period)
	local start = ((k * 7919) % 97) / 97 * (period - g.seconds)
	local within = x - k * period
	local on = within >= start and within < start + g.seconds
	return on, if on then g.offset * (if k % 2 == 0 then 1 else -1) else 0
end

-- An arc's bend for two randoms (0..1): the Beam's CurveSize0 / CurveSize1, within +-jitter.
function SkinFx.arcCurve(element: Element, r1: number, r2: number): (number, number)
	local j = if element.arcs then element.arcs.jitter else 0
	return (math.clamp(r1, 0, 1) * 2 - 1) * j, (math.clamp(r2, 0, 1) * 2 - 1) * j
end

-- Primal fury: a take-down adds `perKill` to the reactive weapon (0 for the other elements).
function SkinFx.heatAfterKill(element: Element, heat: number): number
	return math.clamp(heat + (element.heat.perKill or 0), 0, 1)
end

-- A crystal spike (footprint spikes, the eruption, grenade shards) `u` into its life, 0..1 tall:
-- sprouts fast (ease out by 18 %), holds, then shatters away over the last 35 %.
function SkinFx.spike(u: number): number
	local x = math.clamp(u, 0, 1)
	if x < 0.18 then
		local g = x / 0.18
		return 1 - (1 - g) ^ 3
	elseif x < 0.65 then
		return 1
	end
	return 1 - (x - 0.65) / 0.35
end

SkinFx.IMPLODE_AT = 0.55 -- cosmic grenade: the black hole has collapsed (the star burst) at this share of its life

-- The grenade splash's main shape `u` into its life by the element's style: (radius, transparency).
--   lava     the molten pool grows fast (ease out by 12 %), solid, fades over the last 30 %
--   emp      a pulse ring racing out to 2.2x, fading as it goes
--   roar     a dust ring rolling out to 2x, ease out, fading
--   implode  the black hole swells (by 12 %) then collapses to nothing at IMPLODE_AT
--   shatter  shards grow out of the ground, hold, then shatter away (`spike`)
function SkinFx.splashShape(element: Element, u: number): (number, number)
	local s = element.splash
	local x = math.clamp(u, 0, 1)
	local style = s.style
	if style == "emp" then
		return s.radius * 2.2 * (1 - (1 - x) ^ 2), x ^ 0.8
	elseif style == "roar" then
		return s.radius * 2 * (1 - (1 - x) ^ 3), 0.1 + 0.9 * x ^ 1.5
	elseif style == "implode" then
		if x < 0.12 then
			return s.radius * 0.8 * (1 - (1 - x / 0.12) ^ 2), 0
		elseif x < SkinFx.IMPLODE_AT then
			local k = (x - 0.12) / (SkinFx.IMPLODE_AT - 0.12)
			return s.radius * 0.8 * (1 - k * k), 0
		end
		return 0, 1
	elseif style == "shatter" then
		local h = SkinFx.spike(x)
		return s.radius * h, if x < 0.65 then 0 else (x - 0.65) / 0.35
	end
	local grow = math.min(1, x / 0.12)
	return s.radius * (0.6 + 1.4 * (1 - (1 - grow) ^ 3)), if x < 0.7 then 0.05 else math.min(1, 0.05 + 0.95 * (x - 0.7) / 0.3)
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
