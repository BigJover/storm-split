--!strict
--[[
	Eggs and pets (PLAN 10d T140/T141, DECISIONS #375-#379, #392/#393/#396; names and strings
	DINO_REVIEW Round 21): pure rules and the saved collection, so specs can run the roll,
	the fuse, the timers and the save round trip headlessly. Server/Progression holds the
	state (the only saved-data mutator) and calls these; Server/Pets runs the pet in play.

	Callers pass `now` (server time, os.time()) and `rng` (function(n) -> 1..n), like
	Shared/Profile.

	THE NUMBERS are on the Eggs / Pets / Pet Rarities sheets and Tuning (Pet inventory cap,
	Pets taken along, Incubators, Hatchling Pen pets, Pet fuse count, Egg warm Amber per
	min). A blank egg price or blank odds = not for sale; a blank Effect value = the effect
	is off; a blank warm price = no "Warm it up" (the Director sets them).

	EGGS are timers in real time (#396): an egg bought at `now` is ready at now + its Hatch
	(min), and keeps counting while the player is away. A save's ready time is never more
	than one full hatch ahead of the clock (a skewed clock can't strand an egg). The rarity
	is rolled at hatch, on the server (#375): rng(1000) against the odds in tenths of a %
	(the exporter holds each egg to exactly 100 % in tenths, Mythic <= 2 %); the species is
	picked evenly from the Pets sheet.

	FUSING (#393): Pet fuse count identical pets (same species + rarity) -> one of the next
	rarity, Legendary -> Mythic included; Mythic can't fuse; the species never changes.
	Pets taken along or in the Hatchling Pen are used last; if the pet taken along is
	used, the new one is taken along instead.

	THE SAVE (`pets` in the profile): { v, nextId, pets = { {id, kind, rarity} }, eggs =
	{ {egg, readyAt} }, along = id?, pen = { id } }. sanitize throws on anything it can't
	read in full (a newer version, an unknown pet, egg or rarity, a broken entry): Shared/
	Profile then keeps the stored value untouched and writes it back as it was, so no pet
	is ever lost to a bad read. A save without pets (older) starts empty.

	  blank()                       an empty collection
	  sanitize(raw, now) / toSave   the save round trip (see above)
	  rarities()                    the six rarity rows in fuse order { key, display, mult }
	  rarityMult(key) / nextRarity(key)   effect x / the next rarity (nil for Mythic)
	  name(pet) / plural(kind)      "Epic Honker" / "Honkers"
	  odds(egg) / oddsLine(egg)     the odds rows / "Hatch odds: Common 55 % · … · Mythic 0.5 %"
	  price(egg)                    Amber for an egg, nil if it isn't for sale
	  rollRarity(egg, rng) / rollKind(rng)   the hatch roll
	  canBuy(state, egg) / buy(state, egg, now)   a free incubator and a price; buy starts it
	  remaining(state, slot, now)   seconds left on an incubator (0 = ready)
	  warmPrice / warm              "Warm it up": Amber per remaining minute, rounded up
	  hatch(state, slot, now, rng)  a ready egg -> a new pet (refused when full)
	  canFuse / fuse                3 identical -> 1 of the next rarity
	  takeAlong(state, id?)         the one pet in hunts (nil = none)
	  setPen(state, id, on)         show a pet in the Hatchling Pen (3 max)
	  along(state)                  the pet taken along, or nil
	  strength(pet, row?)           the effect strength: Effect value x rarity, nil if off
	  groups(state)                 the collection grouped by species + rarity, for the UI
	  timerLine / fuseLine / downLine / fullLine   the Round 21 strings
]]

local Config = require(script.Parent.Config)

local Pets = {}

export type Pet = { id: number, kind: string, rarity: string }
export type Incubating = { egg: string, readyAt: number }
export type State = {
	v: number,
	nextId: number,
	pets: { Pet },
	eggs: { Incubating },
	along: number?,
	pen: { number },
}
export type Rarity = { key: string, display: string, mult: number }
export type Odds = { rarity: string, display: string, percent: number }
export type Group = { kind: string, rarity: string, count: number, ids: { number }, along: boolean, pen: number }

Pets.VERSION = 1

local function tuning(): any
	return Config.Tuning :: any
end

local function eggRow(egg: unknown): any?
	return if type(egg) == "string" then (Config :: any).Eggs[egg] else nil
end

local function petRow(kind: unknown): any?
	return if type(kind) == "string" then (Config :: any).Pets[kind] else nil
end

function Pets.rarities(): { Rarity }
	return (Config :: any).PetRarities
end

local function rarityIndex(key: unknown): number?
	for i, row in Pets.rarities() do
		if row.key == key then
			return i
		end
	end
	return nil
end

function Pets.rarityMult(key: unknown): number?
	local i = rarityIndex(key)
	return if i then Pets.rarities()[i].mult else nil
end

function Pets.nextRarity(key: unknown): string?
	local i = rarityIndex(key)
	local rows = Pets.rarities()
	return if i and i < #rows then rows[i + 1].key else nil
end

local function rarityName(key: string): string
	local i = rarityIndex(key)
	return if i then Pets.rarities()[i].display else key
end

function Pets.name(pet: { kind: string, rarity: string }): string
	local row = petRow(pet.kind)
	return `{rarityName(pet.rarity)} {if row then row.display else pet.kind}`
end

function Pets.plural(kind: string): string
	local row = petRow(kind)
	return `{if row then row.display else kind}s`
end

------------------------------------------------------------------ eggs

function Pets.cap(): number
	return math.floor(tuning().PetInventoryCap)
end

function Pets.incubators(): number
	return math.max(1, math.floor(tuning().Incubators))
end

function Pets.hatchSeconds(egg: unknown): number?
	local row = eggRow(egg)
	return if row and type(row.hatchMinutes) == "number" then row.hatchMinutes * 60 else nil
end

function Pets.odds(egg: unknown): { Odds }?
	local row = eggRow(egg)
	if not row or type(row.odds) ~= "table" then
		return nil
	end
	local out = {}
	for _, r in Pets.rarities() do
		table.insert(out, { rarity = r.key, display = r.display, percent = row.odds[r.key] or 0 })
	end
	return out
end

local function percentText(p: number): string
	local tenths = math.round(p * 10)
	return if tenths % 10 == 0 then tostring(tenths // 10) else string.format("%.1f", tenths / 10)
end

function Pets.oddsLine(egg: unknown): string
	local odds = Pets.odds(egg)
	if not odds then
		return "Hatch odds: coming soon"
	end
	local parts = {}
	for _, o in odds do
		table.insert(parts, `{o.display} {percentText(o.percent)} %`)
	end
	return "Hatch odds: " .. table.concat(parts, " · ")
end

function Pets.price(egg: unknown): number?
	local row = eggRow(egg)
	if not row or type(row.price) ~= "number" or row.price <= 0 or type(row.odds) ~= "table" then
		return nil
	end
	return row.price
end

-- The hatch roll: rng(1000) against the odds in tenths of a % (exactly 1000 in all, the
-- exporter's rule). Falls back to the first rarity if the odds can't be read.
function Pets.rollRarity(egg: unknown, rng: (number) -> number): string
	local odds = Pets.odds(egg)
	local rows = Pets.rarities()
	if not odds then
		return rows[1].key
	end
	local roll = rng(1000)
	local upTo = 0
	for _, o in odds do
		upTo += math.round(o.percent * 10)
		if roll <= upTo then
			return o.rarity
		end
	end
	return rows[1].key
end

function Pets.rollKind(rng: (number) -> number): string
	local order = (Config :: any).PetOrder :: { string }
	return order[math.clamp(rng(#order), 1, #order)]
end

------------------------------------------------------------------ the collection

function Pets.blank(): State
	return { v = Pets.VERSION, nextId = 1, pets = {}, eggs = {}, along = nil, pen = {} }
end

local function whole(x: unknown): number?
	if type(x) ~= "number" or x ~= x or x == math.huge or x == -math.huge or x ~= math.floor(x) then
		return nil
	end
	return x
end

local function find(state: State, id: unknown): (Pet?, number?)
	for i, pet in state.pets do
		if pet.id == id then
			return pet, i
		end
	end
	return nil, nil
end

-- Throws on anything it can't read in full (the caller keeps the stored value untouched).
function Pets.sanitize(raw: unknown, now: number): State
	local state = Pets.blank()
	if raw == nil then
		return state -- an older save: no pets yet
	end
	assert(type(raw) == "table", "pets: not a table")
	local t = raw :: any
	local version = whole(t.v)
	assert(version and version >= 1 and version <= Pets.VERSION, `pets: version {tostring(t.v)} unknown`)
	local seen: { [number]: boolean } = {}
	local top = 0
	assert(type(t.pets) == "table", "pets: no list")
	for _, p in t.pets do
		local id = whole(type(p) == "table" and p.id)
		assert(id and id >= 1 and not seen[id], "pets: bad or repeated id")
		assert(petRow(p.kind), `pets: unknown pet {tostring(p.kind)}`)
		assert(rarityIndex(p.rarity), `pets: unknown rarity {tostring(p.rarity)}`)
		seen[id] = true
		top = math.max(top, id)
		table.insert(state.pets, { id = id, kind = p.kind, rarity = p.rarity })
	end
	if t.eggs ~= nil then
		assert(type(t.eggs) == "table", "pets: eggs not a list")
		for _, e in t.eggs do
			local length = Pets.hatchSeconds(type(e) == "table" and e.egg)
			local readyAt = type(e) == "table" and e.readyAt
			assert(length, `pets: unknown egg`)
			assert(type(readyAt) == "number" and readyAt == readyAt and math.abs(readyAt) < math.huge, "pets: bad egg timer")
			-- Real time keeps running (#396); a clock that jumped back never makes it longer
			-- than one full hatch.
			table.insert(state.eggs, { egg = e.egg, readyAt = math.min(readyAt, now + (length :: number)) })
		end
	end
	local nextId = whole(t.nextId)
	state.nextId = math.max(top + 1, if nextId then nextId else 1)
	if t.along ~= nil and find(state, t.along) then
		state.along = t.along
	end
	if type(t.pen) == "table" then
		local room = math.floor(tuning().HatchlingPenPets)
		for _, id in t.pen do
			if #state.pen < room and find(state, id) and not table.find(state.pen, id) then
				table.insert(state.pen, id)
			end
		end
	end
	return state
end

function Pets.toSave(state: State): { [string]: any }
	local pets = {}
	for _, p in state.pets do
		table.insert(pets, { id = p.id, kind = p.kind, rarity = p.rarity })
	end
	local eggs = {}
	for _, e in state.eggs do
		table.insert(eggs, { egg = e.egg, readyAt = e.readyAt })
	end
	return { v = state.v, nextId = state.nextId, pets = pets, eggs = eggs, along = state.along, pen = table.clone(state.pen) }
end

function Pets.full(state: State): boolean
	return #state.pets >= Pets.cap()
end

function Pets.fullLine(state: State): string
	return `Pets full ({#state.pets}/{Pets.cap()}). Fuse some to make room.`
end

-- Price (Amber) if this egg can be bought now, else nil and why.
function Pets.canBuy(state: State, egg: unknown): (number?, string)
	local price = Pets.price(egg)
	if not price then
		return nil, if eggRow(egg) then "Not for sale yet" else "Unknown egg"
	end
	if #state.eggs >= Pets.incubators() then
		return nil, "Your incubator is busy"
	end
	return price, ""
end

-- Starts the egg (the caller took the Amber).
function Pets.buy(state: State, egg: unknown, now: number): (boolean, string)
	local price, why = Pets.canBuy(state, egg)
	if not price then
		return false, why
	end
	table.insert(state.eggs, { egg = egg :: string, readyAt = now + (Pets.hatchSeconds(egg) :: number) })
	return true, "Warming up!"
end

function Pets.remaining(state: State, slot: unknown, now: number): number?
	local e = type(slot) == "number" and state.eggs[slot] or nil
	if not e then
		return nil
	end
	return math.max(0, e.readyAt - now)
end

function Pets.warmPrice(state: State, slot: unknown, now: number): number?
	local perMinute = tuning().EggWarmAmberPerMin
	local left = Pets.remaining(state, slot, now)
	if type(perMinute) ~= "number" or perMinute <= 0 or not left then
		return nil
	end
	local minutes = math.ceil(left / 60) -- a started minute counts
	return if minutes > 0 then minutes * perMinute else nil
end

-- Finishes the hatch now (the caller took the Amber, or a Studio aid).
function Pets.warm(state: State, slot: unknown, now: number): boolean
	local left = Pets.remaining(state, slot, now)
	if not left then
		return false
	end
	state.eggs[slot :: number].readyAt = math.min(state.eggs[slot :: number].readyAt, now)
	return true
end

function Pets.timerLine(state: State, slot: number, now: number): string
	local left = Pets.remaining(state, slot, now) or 0
	if left <= 0 then
		return "Ready to hatch!"
	end
	local s = math.ceil(left)
	local h, m, sec = s // 3600, (s // 60) % 60, s % 60
	local clock = if h > 0 then string.format("%d:%02d:%02d", h, m, sec) else string.format("%d:%02d", m, sec)
	return `Hatching… {clock} left`
end

local function add(state: State, kind: string, rarity: string): Pet
	local pet = { id = state.nextId, kind = kind, rarity = rarity }
	state.nextId += 1
	table.insert(state.pets, pet)
	return pet
end

function Pets.hatch(state: State, slot: unknown, now: number, rng: (number) -> number): (boolean, string, Pet?)
	local left = Pets.remaining(state, slot, now)
	if not left then
		return false, "No egg there", nil
	end
	if left > 0 then
		return false, "Not ready yet", nil
	end
	if Pets.full(state) then
		return false, Pets.fullLine(state), nil
	end
	local e = table.remove(state.eggs, slot :: number) :: Incubating
	local pet = add(state, Pets.rollKind(rng), Pets.rollRarity(e.egg, rng))
	return true, `New pet: {Pets.name(pet)}!`, pet
end

------------------------------------------------------------------ fuse, take along, pen

local function matching(state: State, kind: unknown, rarity: unknown): { Pet }
	local out = {}
	for _, p in state.pets do
		if p.kind == kind and p.rarity == rarity then
			table.insert(out, p)
		end
	end
	-- Used first: plain ones; last: the pen's, then the one taken along.
	table.sort(out, function(a, b)
		local function weight(p: Pet): number
			return (if state.along == p.id then 2 else 0) + (if table.find(state.pen, p.id) then 1 else 0)
		end
		local wa, wb = weight(a), weight(b)
		if wa ~= wb then
			return wa < wb
		end
		return a.id < b.id
	end)
	return out
end

function Pets.fuseCount(): number
	return math.floor(tuning().PetFuseCount)
end

function Pets.canFuse(state: State, kind: unknown, rarity: unknown): (boolean, string)
	if not petRow(kind) or not rarityIndex(rarity) then
		return false, "Unknown pet"
	end
	if not Pets.nextRarity(rarity) then
		return false, `{rarityName(rarity :: string)} is the top — it can't fuse.`
	end
	if #matching(state, kind, rarity) < Pets.fuseCount() then
		return false, `Need {Pets.fuseCount()} of the same pet and rarity.`
	end
	return true, ""
end

function Pets.fuse(state: State, kind: unknown, rarity: unknown): (boolean, string, Pet?)
	local ok, why = Pets.canFuse(state, kind, rarity)
	if not ok then
		return false, why, nil
	end
	local used = matching(state, kind, rarity)
	local wasAlong = false
	for i = 1, Pets.fuseCount() do
		local id = used[i].id
		local _, at = find(state, id)
		table.remove(state.pets, at :: number)
		local inPen = table.find(state.pen, id)
		if inPen then
			table.remove(state.pen, inPen)
		end
		if state.along == id then
			state.along = nil
			wasAlong = true
		end
	end
	local pet = add(state, kind :: string, Pets.nextRarity(rarity) :: string)
	if wasAlong then
		state.along = pet.id
	end
	return true, `New pet: {Pets.name(pet)}!`, pet
end

function Pets.fuseLine(kind: string, rarity: string): string
	local nextKey = Pets.nextRarity(rarity)
	if not nextKey then
		return "Mythic is the top — it can't fuse."
	end
	return `Fuse — {Pets.fuseCount()} {rarityName(rarity)} {Pets.plural(kind)} → 1 {rarityName(nextKey)} {(petRow(kind) :: any).display}`
end

function Pets.takeAlong(state: State, id: unknown): (boolean, string)
	if id == nil then
		state.along = nil
		return true, "No pet taken along"
	end
	local pet = find(state, id)
	if not pet then
		return false, "Unknown pet"
	end
	state.along = pet.id
	return true, `Taking along your {Pets.name(pet)}`
end

function Pets.setPen(state: State, id: unknown, on: boolean): (boolean, string)
	local pet = find(state, id)
	if not pet then
		return false, "Unknown pet"
	end
	local at = table.find(state.pen, pet.id)
	if not on then
		if at then
			table.remove(state.pen, at)
		end
		return true, "Back from the Hatchling Pen"
	end
	if at then
		return true, "Already in your Hatchling Pen"
	end
	local room = math.floor(tuning().HatchlingPenPets)
	if #state.pen >= room then
		return false, `Your Hatchling Pen is full ({room} max)`
	end
	table.insert(state.pen, pet.id)
	return true, "In your Hatchling Pen"
end

function Pets.along(state: State): Pet?
	return (find(state, state.along))
end

------------------------------------------------------------------ effects (T141)

-- The pet's one support effect and its strength: Effect value x the rarity's Effect x.
-- nil strength = the effect is off (a blank cell). `row` defaults to the Pets sheet row.
function Pets.strength(pet: { kind: string, rarity: string }, row: any?): (string?, number?)
	local r = row or petRow(pet.kind)
	local mult = Pets.rarityMult(pet.rarity)
	if not r or not mult then
		return nil, nil
	end
	if type(r.effectValue) ~= "number" or r.effectValue <= 0 then
		return r.effect, nil
	end
	return r.effect, r.effectValue * mult
end

function Pets.downLine(pet: { kind: string }): string
	local row = petRow(pet.kind)
	return `Your {if row then row.display else "pet"} ran back to camp — it returns when you do.`
end

-- The collection for the UI: one entry per species + rarity, best rarity first.
function Pets.groups(state: State): { Group }
	local byKey: { [string]: Group } = {}
	local out: { Group } = {}
	for _, p in state.pets do
		local k = `{p.kind}|{p.rarity}`
		local g: Group = byKey[k]
		if not g then
			local fresh: Group = { kind = p.kind, rarity = p.rarity, count = 0, ids = {}, along = false, pen = 0 }
			byKey[k] = fresh
			table.insert(out, fresh)
			g = fresh
		end
		g.count += 1
		table.insert(g.ids, p.id)
		if state.along == p.id then
			g.along = true
		end
		if table.find(state.pen, p.id) then
			g.pen += 1
		end
	end
	local order = (Config :: any).PetOrder :: { string }
	table.sort(out, function(a, b)
		local ra, rb = rarityIndex(a.rarity) or 0, rarityIndex(b.rarity) or 0
		if ra ~= rb then
			return ra > rb
		end
		return (table.find(order, a.kind) or 0) < (table.find(order, b.kind) or 0)
	end)
	return out
end

return Pets
