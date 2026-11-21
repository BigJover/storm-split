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
SkinFx.IDLE_FLARE_SECONDS = 6 -- tier 3: a small flare from the seams this often
SkinFx.IDLE_FLARE_COUNT = 5
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

local HEROES = { "PISTOL", "RIFLE", "SHOTGUN", "MEDIC" }

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

-- The tier to draw: the item's, or (Studio only) the comparison override 0..3.
function SkinFx.tier(key: unknown, override: unknown, isStudio: boolean?): number
	local item = SkinFx.item(key)
	if not item then
		return 0
	end
	if isStudio and type(override) == "number" and override >= 0 and override <= SkinFx.MAX_TIER then
		return math.floor(override)
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
		rate = math.min(if tier >= 3 then 3 else 2, SkinFx.HUNTER_RATE_CAP)
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
		size = { if where == "weapon" then 0.07 else 0.12, 0 },
		spread = 25,
		colour = { theme.ember, theme.emberEnd },
		lightEmission = 1,
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
		rate = if where == "hunter" then 1.5 else 2,
		lifetime = { 1.0, 1.4 },
		speed = { 0.2, 0.5 },
		size = { if where == "hunter" then 1.1 else 1.6, 0.2 },
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
