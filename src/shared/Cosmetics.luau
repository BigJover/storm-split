--[[
	Cosmetics and titles: the player level's rewards (PLAN round 4 T57, DECISIONS #121).
	Pure: Config in, answers out, so tools/test/cosmetics.spec.luau runs it headlessly.

	The items are the Cosmetics sheet (Config.Cosmetics, in level order). Unlocks are
	derived from the player level, never stored: an item is yours once your level reaches
	its Level. Past level 200 the one repeating title row (`every` > 0) gives a new title
	every `every` levels, forever; those have ids "<row id>_<level>" and "{n}" in the name
	becomes the level.

	What a player wears is `equipped`: slot -> item id, one slot per kind (the title is a
	slot too). Server/Progression is the only thing that changes it (on load: `clean`; on a
	request: `check`), and it publishes each slot as an `Equip_<slot>` attribute on the
	Player so every client and server module can show it.

	No gameplay effect, ever: the look helpers below only pick colours, materials and
	glyphs; `buildHat` and `buildTrail` make parts and effects that can't collide, be hit,
	be touched or weigh anything (no size or hitbox change). Gold is mastery 20's alone,
	and the exporter keeps it off this sheet.
]]

local Config = require(script.Parent.Config)

local Cosmetics = {}

export type Item = {
	id: string,
	level: number,
	kind: string,
	name: string,
	rarity: string,
	colour: { number },
	material: string,
	pattern: string,
	every: number,
}
export type Equipped = { [string]: string }

-- The slots, in the order the Profile screen lists them, with their labels.
Cosmetics.SLOTS = table.freeze({
	"title",
	"nameColour",
	"banner",
	"gunTint",
	"gunFinish",
	"tracer",
	"crosshair",
	"hitMarker",
	"towerFlag",
	"hat",
	"trail",
	"set",
})
Cosmetics.LABELS = table.freeze({
	title = "Title",
	nameColour = "Name colour",
	banner = "Leaderboard banner",
	gunTint = "Gun tint",
	gunFinish = "Gun pattern",
	tracer = "Tracers",
	crosshair = "Crosshair",
	hitMarker = "Hit-marker",
	towerFlag = "Tower flag",
	hat = "Hunting hat",
	trail = "Sprint trail",
	set = "Animated set",
} :: { [string]: string })

local MAX_ID = 64 -- longest slot or id kept from a save or a request

-- Index ------------------------------------------------------------------------------

local byId: { [string]: Item } = {}
local listed: { Item } = {} -- every row but the repeating one, in level order
local repeating: Item? = nil
for _, row in Config.Cosmetics :: { any } do
	local item = row :: Item
	byId[item.id] = item
	if item.every > 0 then
		repeating = item
	else
		table.insert(listed, item)
	end
end

-- A past-200 title at `level`, or nil if the repeating row gives none there.
local function repeatAt(level: number): Item?
	local rule = repeating
	if not rule or level < rule.level or (level - rule.level) % rule.every ~= 0 then
		return nil
	end
	return {
		id = `{rule.id}_{level}`,
		level = level,
		kind = rule.kind,
		name = (string.gsub(rule.name, "{n}", tostring(level))),
		rarity = rule.rarity,
		colour = rule.colour,
		material = rule.material,
		pattern = rule.pattern,
		every = 0,
	}
end

-- The item with this id, or nil (unknown ids, the bare repeating row, garbage).
function Cosmetics.item(id: unknown): Item?
	if type(id) ~= "string" or #id > MAX_ID then
		return nil
	end
	local item = byId[id]
	if item then
		return if item.every > 0 then nil else item
	end
	local rule = repeating
	if rule then
		local level = string.match(id, `^{rule.id}_(%d+)$`)
		local n = tonumber(level)
		if n and tostring(n) == level then
			return repeatAt(n)
		end
	end
	return nil
end

-- Is `slot` one of the slots?
function Cosmetics.isSlot(slot: unknown): boolean
	return type(slot) == "string" and Cosmetics.LABELS[slot] ~= nil
end

-- The rewards that unlock at exactly `level`: its listed rows (cosmetic first, then the
-- title) or the repeating title.
function Cosmetics.at(level: number): { Item }
	local l = math.floor(level)
	local out = {}
	for _, item in listed do
		if item.level == l then
			table.insert(out, item)
		elseif item.level > l then
			break
		end
	end
	if #out == 0 then
		local title = repeatAt(l)
		if title then
			table.insert(out, title)
		end
	end
	return out
end

-- The reward tier at `level` (PlayerLevel.rewardAt): the cosmetic's rarity, "title"
-- when a title is all there is, or "none".
function Cosmetics.tierAt(level: number): string
	local items = Cosmetics.at(level)
	for _, item in items do
		if item.kind ~= "title" then
			return item.rarity
		end
	end
	return if #items > 0 then "title" else "none"
end

-- Unlocks ----------------------------------------------------------------------------

function Cosmetics.unlocked(item: Item, level: number): boolean
	return math.floor(level) >= item.level
end

-- Everything `level` has unlocked for `slot`, oldest first.
function Cosmetics.itemsFor(slot: string, level: number): { Item }
	local out = {}
	for _, item in listed do
		if item.level > level then
			break
		end
		if item.kind == slot then
			table.insert(out, item)
		end
	end
	local rule = repeating
	if rule and rule.kind == slot then
		local l = rule.level
		while l <= level do
			table.insert(out, repeatAt(l) :: Item)
			l += rule.every
		end
	end
	return out
end

-- The lowest level that unlocks anything for `slot`, or nil.
function Cosmetics.firstLevel(slot: string): number?
	for _, item in listed do
		if item.kind == slot then
			return item.level
		end
	end
	local rule = repeating
	return if rule and rule.kind == slot then rule.level else nil
end

-- The next `count` levels above `level` that unlock something, with what they unlock.
function Cosmetics.upcoming(level: number, count: number): { { level: number, items: { Item } } }
	local out = {}
	local l = math.floor(level) + 1
	local rule = repeating
	while #out < count do
		local items = Cosmetics.at(l)
		if #items > 0 then
			table.insert(out, { level = l, items = items })
		end
		if rule and l >= rule.level then
			l += rule.every - (l - rule.level) % rule.every -- jump to the next repeat
		else
			l += 1
		end
		if not rule and l > 10000 then
			break
		end
	end
	return out
end

-- Equipping --------------------------------------------------------------------------

-- May a player at `level` wear item `id` in `slot`? `id` "" or nil = take it off (always
-- allowed). The reason is for the player, from the server's refusal.
function Cosmetics.check(slot: unknown, id: unknown, level: number): (boolean, string)
	if not Cosmetics.isSlot(slot) then
		return false, "Unknown slot"
	end
	if id == nil or id == "" then
		return true, ""
	end
	local item = Cosmetics.item(id)
	if not item then
		return false, "Unknown item"
	end
	if item.kind ~= slot then
		return false, "That doesn't go there"
	end
	if not Cosmetics.unlocked(item, level) then
		return false, `Unlocks at player level {item.level}`
	end
	return true, ""
end

-- `equipped` with every unknown slot, unknown id, wrong kind or locked item dropped (an
-- old or edited save, or a level that somehow went down). Anything that isn't a table
-- comes back as {}.
function Cosmetics.clean(equipped: unknown, level: number): Equipped
	local out: Equipped = {}
	if type(equipped) ~= "table" then
		return out
	end
	for slot, id in equipped :: { [any]: any } do
		if type(id) == "string" and id ~= "" and Cosmetics.check(slot, id, level) then
			out[slot] = id
		end
	end
	return out
end

-- Looks (visual only) ----------------------------------------------------------------

function Cosmetics.colour(item: Item?): Color3?
	if not item or #item.colour ~= 3 then
		return nil
	end
	return Color3.fromRGB(item.colour[1], item.colour[2], item.colour[3])
end

function Cosmetics.material(item: Item?): Enum.Material?
	if not item or item.material == "" then
		return nil
	end
	local ok, material = pcall(function()
		return (Enum.Material :: any)[item.material]
	end)
	return if ok then material else nil
end

-- What a slot's attribute holds (Equip_<slot> on a Player) -> the item, or nil.
function Cosmetics.worn(getAttribute: (string) -> any, slot: string): Item?
	local item = Cosmetics.item(getAttribute(`Equip_{slot}`))
	return if item and item.kind == slot then item else nil
end

export type GunLook = { colour: Color3, material: Enum.Material, set: Item? }

-- The gun's look: mastery 20's gold first (gold stays its own), then an animated set,
-- then the tint and the pattern on top of the hero's own colour.
function Cosmetics.gunLook(
	worn: (string) -> Item?,
	heroColour: Color3,
	maxed: boolean,
	gold: Color3
): GunLook
	if maxed then
		return { colour = gold, material = Enum.Material.Neon, set = nil }
	end
	local set = worn("set")
	if set then
		return {
			colour = Cosmetics.colour(set) or heroColour,
			material = Cosmetics.material(set) or Enum.Material.SmoothPlastic,
			set = set,
		}
	end
	local tint, finish = worn("gunTint"), worn("gunFinish")
	return {
		colour = Cosmetics.colour(tint) or Cosmetics.colour(finish) or heroColour,
		material = Cosmetics.material(finish) or Enum.Material.SmoothPlastic,
		set = nil,
	}
end

-- A shot's tracer colour: the set's, then the tracer colour, then the hero's.
function Cosmetics.tracerColour(worn: (string) -> Item?, heroColour: Color3): Color3
	return Cosmetics.colour(worn("set")) or Cosmetics.colour(worn("tracer")) or heroColour
end

-- The crosshair's colour: the set's, then the crosshair colour, then `default`.
function Cosmetics.crosshairColour(worn: (string) -> Item?, default: Color3): Color3
	return Cosmetics.colour(worn("set")) or Cosmetics.colour(worn("crosshair")) or default
end

local GLYPHS = { Cross = "×", Plus = "+", Diamond = "◆", Star = "✦" }

-- The hit-marker: its glyph and the colour of a plain hit (a take-down keeps the game's
-- own colour, so the two still read apart).
function Cosmetics.hitMarker(worn: (string) -> Item?, default: Color3): (string, Color3)
	local item = worn("hitMarker")
	if not item then
		return GLYPHS.Cross, default
	end
	return GLYPHS[item.pattern] or GLYPHS.Cross, Cosmetics.colour(item) or default
end

-- An animated set's colour `t` seconds in: Pulse breathes between its colour and a
-- lighter one; Cycle turns its hue slowly round the wheel.
local PULSE_SECONDS = 2
local CYCLE_SECONDS = 8
function Cosmetics.animatedColour(item: Item, t: number): Color3
	local base = Cosmetics.colour(item) or Color3.new(1, 1, 1)
	if item.pattern == "Cycle" then
		local h, s, v = base:ToHSV()
		return Color3.fromHSV((h + t / CYCLE_SECONDS) % 1, math.max(s, 0.5), math.max(v, 0.6))
	end
	local k = (math.sin(t * 2 * math.pi / PULSE_SECONDS) + 1) / 2
	return base:Lerp(Color3.new(1, 1, 1), 0.15 + 0.35 * k)
end

-- A title's text, or nil.
function Cosmetics.titleOf(getAttribute: (string) -> any): string?
	local item = Cosmetics.worn(getAttribute, "title")
	return if item then item.name else nil
end

-- Parts that change nothing in play: no collision, no raycast or touch hits, no mass.
local function inert(part: BasePart)
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = false
end

-- A hunting hat for a head of `headSize`, welded on by the caller (Server/Wardrobe).
-- Pattern: Brim (a wide-brimmed bush hat), Cap (a peaked cap), Crest (a helm with a ridge).
function Cosmetics.buildHat(item: Item, headSize: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "CosmeticHat"
	local colour = Cosmetics.colour(item) or Color3.new(1, 1, 1)
	local material = Cosmetics.material(item) or Enum.Material.Fabric
	local w, h = headSize.X, headSize.Y
	local function block(name: string, size: Vector3, offset: CFrame): Part
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.CFrame = offset
		part.Color = colour
		part.Material = material
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		inert(part)
		part.Parent = model
		return part
	end
	local top = h / 2
	local crown = block("Crown", Vector3.new(w * 1.02, h * 0.35, w * 1.02), CFrame.new(0, top + h * 0.12, 0))
	if item.pattern == "Brim" then
		block("Brim", Vector3.new(w * 1.6, 0.08, w * 1.6), CFrame.new(0, top - h * 0.02, 0))
	elseif item.pattern == "Cap" then
		block("Peak", Vector3.new(w * 0.9, 0.08, w * 0.5), CFrame.new(0, top - h * 0.02, -w * 0.7))
	else -- Crest
		block("Ridge", Vector3.new(w * 0.15, h * 0.25, w * 1.0), CFrame.new(0, top + h * 0.4, 0))
	end
	model.PrimaryPart = crown
	return model
end

-- A sprint trail between two attachments the caller puts on the hunter.
function Cosmetics.buildTrail(item: Item, a0: Attachment, a1: Attachment): Trail
	local trail = Instance.new("Trail")
	trail.Name = "CosmeticTrail"
	local colour = Cosmetics.colour(item) or Color3.new(1, 1, 1)
	trail.Color = ColorSequence.new(colour)
	trail.Transparency = NumberSequence.new(0.35, 1)
	trail.Lifetime = 0.35
	trail.MinLength = 0.2
	trail.FaceCamera = true
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	return trail
end

return Cosmetics
