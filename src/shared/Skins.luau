--[[
	Skins and Campsite Display Towers (PLAN 10e T142, DECISIONS #380/#381/#384; names
	DINO_REVIEW Round 22). Pure: Config in, answers out, so tools/test/skins.spec.luau runs
	it headlessly. Server/Progression is the only thing that changes a player's skins.

	The catalogue is the Skins sheet (Config.Skins, in SkinOrder):
	  hunter   a hunter skin for one hero (Tracker: Swamp Stalker · Night Prowler · Jungle Ghost …)
	  weapon   a weapon skin for one hero's gun (Revolver: Snakeskin Grip · Silver Spur …)
	  tower    a tower set (Treehouse, Stone Age, Brass Gear, Midnight, Gold Rush): fits every tower
	A skin is yours once it's in `owned` (bought with Amber, or from a bundle: Shared/Store) or
	your player level reaches its Level (derived, never stored). A blank price = not in the
	shop yet; a blank level = not on the ladder (the Director fills them in).

	Slots (`wear`): "hunter:<HERO>", "weapon:<HERO>", "tower:<TOWER>" -> skin key. Each slot
	takes only a skin of its kind (and its hero). Display Towers (`deco`): up to DECO_SLOTS
	towers you own, shown on your Campsite for show only (they never shoot).

	Looks only (#381): a skin is two colours and a material, nothing else. `paintTower` and
	`hunterPaint` say which parts change and to what; sizes, shapes, positions, transparency,
	the range ring, crown/glow, HP bar, name tag and hitboxes are never touched (spec'd). No
	skin material glows or is see-through (the exporter refuses Neon/Glass/ForceField).

	Saved as { owned = { [key] = true }, wear = { [slot] = key }, deco = { towerKey, ... } }.
	An owned key the sheet no longer lists is KEPT as stored (never lose a purchase), just
	not shown or worn.
]]

local Config = require(script.Parent.Config)
local Theme = require(script.Parent.Theme)

local Skins = {}

Skins.KINDS = table.freeze({ "hunter", "weapon", "tower" })
Skins.KIND_LABELS = table.freeze({ hunter = "Hunter skins", weapon = "Weapon skins", tower = "Tower sets" })
Skins.DECO_SLOTS = 3
Skins.OWNED_MAX = 500 -- stored keys kept at most (a corrupt save can't grow without bound)
Skins.ATTRIBUTE_PREFIX = "Skin_" -- Skin_hunter_PISTOL, Skin_weapon_PISTOL, Skin_tower_SCOUT
Skins.DECO_PREFIX = "Deco_" -- Deco_1 .. Deco_3: the Display Towers' tower keys

export type Row = {
	kind: string,
	hero: string?,
	display: string,
	price: number?,
	level: number?,
	colour: { number },
	accent: { number },
	material: string,
}
export type State = { owned: { [string]: boolean }, wear: { [string]: string }, deco: { string } }
export type Look = { colour: Color3, accent: Color3, material: Enum.Material }

-- The catalogue rows: Config.Skins, or (specs only) a stand-in so prices and levels can be
-- tested before the Director fills them. Nothing in the game sets this.
Skins.rowsOverride = nil :: { [string]: Row }?

local function rows(): { [string]: Row }
	return Skins.rowsOverride or (Config :: any).Skins or {}
end

local function order(): { string }
	return (Config :: any).SkinOrder or {}
end

function Skins.row(key: unknown): Row?
	return if type(key) == "string" then rows()[key] else nil
end

local function isHero(key: unknown): boolean
	return type(key) == "string" and (Config.Heroes :: any)[key] ~= nil
end

local function isTower(key: unknown): boolean
	return type(key) == "string" and (Config.Towers :: any)[key] ~= nil
end

-- The slot for a kind and its hero / tower key: "hunter:PISTOL", "tower:SCOUT".
function Skins.slot(kind: string, forKey: string): string
	return `{kind}:{forKey}`
end

-- A slot string -> (kind, key) when it is a real slot, else nil.
function Skins.parseSlot(slot: unknown): (string?, string?)
	if type(slot) ~= "string" then
		return nil, nil
	end
	local kind, forKey = string.match(slot, "^(%a+):([%w_]+)$")
	if (kind == "hunter" or kind == "weapon") and isHero(forKey) then
		return kind, forKey
	elseif kind == "tower" and isTower(forKey) then
		return kind, forKey
	end
	return nil, nil
end

-- The attribute a slot is published as (Server/Progression), read by Wardrobe, Hero, Towers.
function Skins.attribute(slot: string): string
	return Skins.ATTRIBUTE_PREFIX .. string.gsub(slot, ":", "_")
end

-- Does skin `key` fit `slot`?
function Skins.fits(key: unknown, slot: unknown): boolean
	local row = Skins.row(key)
	local kind, forKey = Skins.parseSlot(slot)
	if not row or not kind or row.kind ~= kind then
		return false
	end
	return kind == "tower" or row.hero == forKey
end

-- The catalogue for a kind (and a hero for hunter/weapon), in sheet order.
function Skins.catalogue(kind: string, hero: string?): { string }
	local out = {}
	for _, key in order() do
		local row = rows()[key]
		if row and row.kind == kind and (kind == "tower" or row.hero == hero) then
			table.insert(out, key)
		end
	end
	return out
end

function Skins.blank(): State
	return { owned = {}, wear = {}, deco = {} }
end

-- Any stored value -> a valid state. Owned keys are kept even when the sheet dropped them.
function Skins.sanitize(raw: unknown, level: number?): State
	local state = Skins.blank()
	if type(raw) ~= "table" then
		return state
	end
	local r = raw :: any
	if type(r.owned) == "table" then
		local count = 0
		for key, value in r.owned do
			if value == true and type(key) == "string" and #key <= 64 and count < Skins.OWNED_MAX then
				state.owned[key] = true
				count += 1
			end
		end
	end
	if type(r.wear) == "table" then
		for slot, key in r.wear do
			if Skins.fits(key, slot) and Skins.owns(state, key, level or 0) then
				state.wear[slot] = key
			end
		end
	end
	if type(r.deco) == "table" then
		for i = 1, Skins.DECO_SLOTS do
			local key = r.deco[i]
			state.deco[i] = if isTower(key) then key else ""
		end
	end
	return state
end

function Skins.toSave(state: State): { [string]: any }
	local deco = {}
	for i = 1, Skins.DECO_SLOTS do
		deco[i] = state.deco[i] or ""
	end
	return { owned = state.owned, wear = state.wear, deco = deco }
end

-- Is skin `key` yours: bought / granted, or unlocked by your player level.
function Skins.owns(state: State, key: unknown, level: number): boolean
	local row = Skins.row(key)
	if not row then
		return false
	end
	if state.owned[key :: string] == true then
		return true
	end
	return row.level ~= nil and level >= row.level
end

-- The Amber price to buy `key` now, or nil and why not.
function Skins.canBuy(state: State, key: unknown, level: number): (number?, string)
	local row = Skins.row(key)
	if not row then
		return nil, "Unknown skin"
	end
	if Skins.owns(state, key, level) then
		return nil, "Already yours"
	end
	if row.price == nil then
		return nil, if row.level then `Reach level {row.level}` else "Not for sale yet"
	end
	return row.price, `Buy — {Theme.amberExact(row.price)} {Theme.Currency}`
end

-- Adds `key` to what you own (after paying). False for an unknown key.
function Skins.buy(state: State, key: unknown): boolean
	if not Skins.row(key) then
		return false
	end
	state.owned[key :: string] = true
	return true
end

-- A bundle (Shared/Store): every listed key that's a real skin is added. Returns how many
-- were new. Unknown keys are skipped, never stored.
function Skins.grant(state: State, keys: { string }): number
	local added = 0
	for _, key in keys do
		if Skins.row(key) and not state.owned[key] then
			state.owned[key] = true
			added += 1
		end
	end
	return added
end

-- Wear `key` in `slot`, or take it off ("" / nil).
function Skins.wear(state: State, slot: unknown, key: unknown, level: number): (boolean, string)
	local kind = Skins.parseSlot(slot)
	if not kind then
		return false, "Unknown slot"
	end
	if key == nil or key == "" then
		state.wear[slot :: string] = nil
		return true, "Taken off"
	end
	if not Skins.fits(key, slot) then
		return false, "That skin doesn't fit there"
	end
	if not Skins.owns(state, key, level) then
		return false, "Not yours yet"
	end
	state.wear[slot :: string] = key :: string
	return true, "Wearing it"
end

-- What `slot` shows: its skin key while it's still yours, else nil.
function Skins.worn(state: State, slot: string, level: number): string?
	local key = state.wear[slot]
	return if key and Skins.fits(key, slot) and Skins.owns(state, key, level) then key else nil
end

-- Put one of your towers on Display Tower spot `index` (1..DECO_SLOTS), or clear it ("").
function Skins.setDeco(state: State, index: unknown, tower: unknown, ownsTower: (string) -> boolean): (boolean, string)
	if type(index) ~= "number" or index ~= math.floor(index) or index < 1 or index > Skins.DECO_SLOTS then
		return false, "Unknown spot"
	end
	if tower == nil or tower == "" then
		state.deco[index] = ""
		return true, "Spot cleared"
	end
	if not isTower(tower) then
		return false, "Unknown tower"
	end
	if not ownsTower(tower :: string) then
		return false, "Unlock that tower first"
	end
	for i = #state.deco + 1, index - 1 do
		state.deco[i] = ""
	end
	state.deco[index] = tower :: string
	return true, "On show at your Campsite"
end

------------------------------------------------------------------ looks (visual only)

local function colour(c: { number }): Color3
	return Color3.fromRGB(c[1] or 0, c[2] or 0, c[3] or 0)
end

-- A skin's look: its two colours and material. nil for an unknown key.
function Skins.look(key: unknown): Look?
	local row = Skins.row(key)
	if not row then
		return nil
	end
	local ok, material = pcall(function()
		return (Enum.Material :: any)[row.material]
	end)
	return {
		colour = colour(row.colour),
		accent = colour(row.accent),
		material = if ok and material then material else Enum.Material.SmoothPlastic,
	}
end

-- A tower set on one silhouette block: the block in the tower's own colour takes the set's
-- colour, every other block its accent; all take the set's material. Colour and material
-- only — the block's size, shape and place never change (#381).
function Skins.paintTower(look: Look, blockColour: Color3, towerColour: Color3): (Color3, Enum.Material)
	local own = blockColour == towerColour
	return if own then look.colour else look.accent, look.material
end

-- Which character parts a hunter skin paints: torso and arms its colour, legs its accent.
-- Head (the face and name tag) and HumanoidRootPart are never painted; accessories keep
-- theirs. R15 and R6 names.
local PAINT = table.freeze({
	UpperTorso = "colour",
	LowerTorso = "colour",
	Torso = "colour",
	LeftUpperArm = "colour",
	LeftLowerArm = "colour",
	LeftHand = "colour",
	RightUpperArm = "colour",
	RightLowerArm = "colour",
	RightHand = "colour",
	["Left Arm"] = "colour",
	["Right Arm"] = "colour",
	LeftUpperLeg = "accent",
	LeftLowerLeg = "accent",
	LeftFoot = "accent",
	RightUpperLeg = "accent",
	RightLowerLeg = "accent",
	RightFoot = "accent",
	["Left Leg"] = "accent",
	["Right Leg"] = "accent",
})

function Skins.hunterPaint(partName: string, look: Look): (Color3?, Enum.Material?)
	local which = PAINT[partName]
	if not which then
		return nil, nil
	end
	return if which == "colour" then look.colour else look.accent, look.material
end

-- The gun's paint (#414): mastery 20's gold beats everything; else a worn weapon skin beats
-- the Cosmetics gun look (an animated set, or tint + pattern); else that look. Returns the
-- colour, material and the animated set id to keep (nil when the skin or gold covers it).
-- `cosmetic` is Shared/Cosmetics.gunLook's answer (already gold when `maxed`).
function Skins.gunPaint(skin: Look?, cosmetic: { colour: Color3, material: Enum.Material, set: any }, maxed: boolean): (Color3, Enum.Material, string?)
	if maxed or not skin then
		local set = if maxed or not cosmetic.set then nil else cosmetic.set.id
		return cosmetic.colour, cosmetic.material, set
	end
	return skin.colour, skin.material, nil
end

-- The shop line for one skin: "Swamp Stalker — 25K Amber" / "— yours" / "— not for sale yet"
-- / "— Reach level 15" (a level skin: earned, never sold, #409).
function Skins.line(state: State, key: string, level: number): string
	local row = Skins.row(key)
	if not row then
		return key
	end
	if Skins.owns(state, key, level) then
		return `{row.display} — yours`
	elseif row.price then
		return `{row.display} — {Theme.formatAmber(row.price)} {Theme.Currency}`
	elseif row.level then
		return `{row.display} — Reach level {row.level}`
	end
	return `{row.display} — not for sale yet`
end

return Skins
