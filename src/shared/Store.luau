--[[
	The Robux store (PLAN 10e T143, DECISIONS #387-#389/#395; names DINO_REVIEW Round 22).
	Pure: Config in, answers out, so tools/test/store.spec.luau runs the receipt rules
	headlessly. Server/Store talks to MarketplaceService; Server/Progression is the only
	thing that grants (through `grant` below, on the profile it holds) and saves.

	The catalogue is the Store sheet (Config.Store, in StoreOrder): Developer Products (Amber
	Sack / Crate / Wagon, Hatch now, {Set} Bundles) and Game Passes (2× Training, Extra
	Training Spot, Second Hatchery Hut). A row shows only once it has its Creator Hub id and
	everything it grants (`shown`); a blank id = hidden (Jovan pastes ids after publishing).

	  isOpen(isStudio, placeId)   the store works only in a published game: never in Studio,
	                              never in an unpublished place (CLOSED_LINE shows instead).
	                              There is no test-grant path (#388).
	  processReceipt(...)          the one receipt rule: never grants on a profile that didn't
	                              load (NotProcessedYet), grants a PurchaseId once (the ledger),
	                              and answers PurchaseGranted only after the save went through.
	  passEffects(owned)          training speed, training slots, incubators: the base from the
	                              sheet plus each owned pass. Same caps for everyone (#389).

	  finishTarget(active, pick)  which training stat a paid "Finish this level" (#414) finishes:
	                              the one picked (two training) or the only one; nil = nothing
	                              training, so the receipt saves a credit instead.

	Saved per profile as { receipts = { PurchaseId, ... } (newest last, at most LEDGER_MAX),
	hatchCredits = { [egg] = n }, trainCredits = n } — a paid "Hatch now" that found no egg of
	its kind waiting is kept as a credit and used on the next one; a paid "Finish this level"
	that found nothing training finishes the next level started. Never lost.
]]

local Config = require(script.Parent.Config)
local Theme = require(script.Parent.Theme)
local Skins = require(script.Parent.Skins)

local Store = {}

Store.CLOSED_LINE = "The store opens when the game is published"
Store.TABS = table.freeze({ "Amber", "Passes", "Hatchery", "Skins", "Premium" })
Store.LEDGER_MAX = 200 -- receipts remembered (Roblox only re-sends unacknowledged ones)
Store.GRANTED = "PurchaseGranted"
Store.NOT_YET = "NotProcessedYet"

export type Row = {
	tab: string,
	type: string,
	display: string,
	robux: number?,
	id: number?,
	grant: string,
	amount: number?,
	items: { string },
	random: boolean,
	line: string,
}
export type State = { receipts: { string }, hatchCredits: { [string]: number }, trainCredits: number }
export type Effects = { trainRate: number, trainSlots: number, incubators: number }

-- Specs only: a stand-in catalogue (ids can't be on the sheet before publishing).
Store.rowsOverride = nil :: { [string]: Row }?
Store.orderOverride = nil :: { string }?

local function rows(): { [string]: Row }
	return Store.rowsOverride or (Config :: any).Store or {}
end

function Store.order(): { string }
	return Store.orderOverride or (Config :: any).StoreOrder or {}
end

function Store.row(key: unknown): Row?
	return if type(key) == "string" then rows()[key] else nil
end

function Store.isOpen(isStudio: boolean, placeId: number): boolean
	return isStudio == false and type(placeId) == "number" and placeId > 0
end

-- Is the row complete (the id aside): a price and what it grants.
function Store.ready(row: Row): boolean
	if row.robux == nil then
		return false
	end
	local g = row.grant
	if g == "amber" or g == "trainRate" or g == "trainSlots" or g == "incubators" then
		return row.amount ~= nil
	elseif g == "hatch" or g == "skins" then
		return #row.items > 0
	elseif g == "trainFinish" then
		return true
	end
	return false
end

-- Does `key` show to this player: an id, complete, and (a paid random item) not for a
-- PolicyService-restricted player.
function Store.shown(key: string, restricted: boolean): boolean
	local row = Store.row(key)
	return row ~= nil and row.id ~= nil and Store.ready(row) and not (restricted and row.random)
end

-- The row a receipt's ProductId (a Developer Product) or a pass id belongs to.
function Store.byId(kind: string, id: unknown): string?
	if type(id) ~= "number" then
		return nil
	end
	for _, key in Store.order() do
		local row = rows()[key]
		if row and row.type == kind and row.id == id then
			return key
		end
	end
	return nil
end

function Store.blank(): State
	return { receipts = {}, hatchCredits = {}, trainCredits = 0 }
end

function Store.sanitize(raw: unknown): State
	local state = Store.blank()
	if type(raw) ~= "table" then
		return state
	end
	local r = raw :: any
	if type(r.receipts) == "table" then
		for _, id in r.receipts do
			if type(id) == "string" and #id <= 128 then
				table.insert(state.receipts, id)
			end
		end
		while #state.receipts > Store.LEDGER_MAX do
			table.remove(state.receipts, 1)
		end
	end
	if type(r.hatchCredits) == "table" then
		for egg, n in r.hatchCredits do
			if type(egg) == "string" and type(n) == "number" and n >= 1 and n < 1e6 then
				state.hatchCredits[egg] = math.floor(n)
			end
		end
	end
	if type(r.trainCredits) == "number" and r.trainCredits >= 1 and r.trainCredits < 1e6 then
		state.trainCredits = math.floor(r.trainCredits)
	end
	return state
end

function Store.toSave(state: State): { [string]: any }
	return {
		receipts = table.clone(state.receipts),
		hatchCredits = table.clone(state.hatchCredits),
		trainCredits = state.trainCredits,
	}
end

function Store.ledgerHas(state: State, purchaseId: string): boolean
	return table.find(state.receipts, purchaseId) ~= nil
end

function Store.ledgerAdd(state: State, purchaseId: string)
	if not Store.ledgerHas(state, purchaseId) then
		table.insert(state.receipts, purchaseId)
		while #state.receipts > Store.LEDGER_MAX do
			table.remove(state.receipts, 1)
		end
	end
end

-- The receipt rule. `loaded`: this player's profile loaded and may be saved (a failed load
-- never gets a grant: Roblox keeps the receipt and retries). `grant()` applies the row's
-- grant to the profile (false = couldn't); `save()` writes the profile now (false = the
-- write failed). The PurchaseId goes into the ledger together with the grant, so the same
-- receipt again (a retry after a failed save, or a duplicate) is never granted twice; it
-- only tries the save again.
function Store.processReceipt(
	loaded: boolean,
	state: State?,
	purchaseId: unknown,
	key: string?,
	grant: () -> boolean,
	save: () -> boolean
): string
	if not loaded or not state or type(purchaseId) ~= "string" or purchaseId == "" or not key then
		return Store.NOT_YET
	end
	if not Store.ledgerHas(state, purchaseId) then
		if not grant() then
			return Store.NOT_YET
		end
		Store.ledgerAdd(state, purchaseId)
	end
	return if save() then Store.GRANTED else Store.NOT_YET
end

-- Pass effects for the passes this player owns (keys). Base values are the sheet's.
function Store.passEffects(owned: { [string]: boolean }): Effects
	local tuning = Config.Tuning :: any
	local effects = {
		trainRate = 1,
		trainSlots = math.max(1, math.floor(tuning.TrainingSlots or 1)),
		incubators = math.max(1, math.floor(tuning.Incubators or 1)),
	}
	for _, key in Store.order() do
		local row = rows()[key]
		if row and row.type == "pass" and owned[key] and row.amount then
			if row.grant == "trainRate" then
				effects.trainRate = math.max(effects.trainRate, row.amount)
			elseif row.grant == "trainSlots" then
				effects.trainSlots += math.floor(row.amount)
			elseif row.grant == "incubators" then
				effects.incubators += math.floor(row.amount)
			end
		end
	end
	return effects
end

-- The most training slots any player can have (base + every slot pass): a save keeps that
-- many active stats; Progression trims to the player's own count.
function Store.maxTrainingSlots(): number
	local all = {}
	for _, key in Store.order() do
		all[key] = true
	end
	return Store.passEffects(all).trainSlots
end

-- "Finish this level" (#414): the stat a paid finish goes to. `active`: the stats training
-- now; `pick`: the stat the buyer chose (asked only when two are training). The pick wins
-- while it is still training; else the only stat training, else the first; nil when nothing
-- is training (the grant saves a credit). Never a maxed stat: a maxed stat isn't training.
function Store.finishTarget(active: { string }, pick: unknown): string?
	if type(pick) == "string" and table.find(active, pick) then
		return pick
	end
	return active[1]
end

-- Does buying "Finish this level" need the buyer to pick a stat first (two training)?
function Store.needsPick(active: { string }): boolean
	return #active >= 2
end

-- What a product row's card says (Round 22: the exact Amber; #412: a bundle you partly own
-- is still sold, the card lists what you'd get new, and "saves X Amber" counts only the
-- unowned items, and only when each of them is sold for Amber, so the figure is true).
-- `owns` (optional): is that skin already yours.
function Store.cardLine(
	key: string,
	skinName: (string) -> string?,
	skinPrice: (string) -> number?,
	owns: ((string) -> boolean)?
): string
	local row = Store.row(key)
	if not row then
		return ""
	end
	if row.grant == "amber" and row.amount then
		-- The sheet's line starts with the exact Amber (the exporter checks, #411).
		return if row.line ~= "" then row.line else `{Theme.amberExact(row.amount)} {Theme.Currency}`
	elseif row.grant == "skins" then
		local names, have, total, all = {}, {}, 0, true
		for _, item in row.items do
			if owns and owns(item) then
				table.insert(have, skinName(item) or item)
				continue
			end
			table.insert(names, skinName(item) or item)
			local price = skinPrice(item)
			if price then
				total += price
			else
				all = false
			end
		end
		if #names == 0 then
			return `You have everything inside: {table.concat(have, ", ")}`
		end
		local line = if #have > 0 then `New for you: {table.concat(names, ", ")} (you have {table.concat(have, ", ")})` else `Inside: {table.concat(names, ", ")}`
		return if all and total > 0 then `{line} · saves {Theme.amberExact(total)} {Theme.Currency}` else line
	end
	return row.line
end

-- The price label: "R$49", "R$1,600" (Round 22/23 spelling).
function Store.priceLabel(key: string): string
	local row = Store.row(key)
	return if row and row.robux then Store.robuxLabel(row.robux) else ""
end

function Store.robuxLabel(robux: number): string
	return `R${Theme.amberExact(robux)}`
end

------------------------------------------------------------------ premium (#467)
--[[
	The Premium tab: the five themes' Robux-only skins (Shared/Skins `robuxOnly`), each sold as a
	single, in a class pack (hunter + gun + grenade + ability + the theme's tower set) and in a
	theme bundle (all four packs, the tower set once). Cosmetic only. Granting is the ordinary
	`skins` grant: Skins.grant adds every item not owned yet, so a pack bought over items you
	already have still grants the rest; the receipt ledger makes it once per PurchaseId.
	Owning a whole class pack lifts its items to the FX pack tier (Shared/SkinFx.ownedPacks,
	published by Server/Progression as SkinFxPacks).
]]

Store.PREMIUM_TAB = "Premium"

local function skinRow(key: string): any
	return Skins.row(key)
end

-- Is `key` a premium product: a Premium-tab skins grant.
function Store.isPremium(key: unknown): boolean
	local row = Store.row(key)
	return row ~= nil and row.tab == Store.PREMIUM_TAB and row.grant == "skins" and #row.items > 0
end

-- "single" (one item), "pack" (a class pack: 5 items with the tower set) or "bundle" (a whole theme).
function Store.premiumKind(key: unknown): string?
	if not Store.isPremium(key) then
		return nil
	end
	local items = (Store.row(key) :: Row).items
	if #items == 1 then
		return "single"
	end
	local first = skinRow(items[1])
	local hero = nil
	for _, item in items do
		local r = skinRow(item)
		hero = hero or (r and r.hero)
	end
	local pack = if first and first.theme and hero then Skins.classPack(first.theme, hero) else nil
	if pack and #pack == #items then
		local same = true
		for _, item in items do
			if not table.find(pack, item) then
				same = false
			end
		end
		if same then
			return "pack"
		end
	end
	return "bundle"
end

-- The theme a premium product belongs to (its first item's).
function Store.premiumTheme(key: unknown): string?
	if not Store.isPremium(key) then
		return nil
	end
	local row = skinRow((Store.row(key) :: Row).items[1])
	return row and row.theme
end

-- The single product that sells skin `item` alone, or nil.
function Store.singleFor(item: string): string?
	for _, key in Store.order() do
		local row = rows()[key]
		if row and row.grant == "skins" and #row.items == 1 and row.items[1] == item then
			return key
		end
	end
	return nil
end

-- A theme's products: its bundle, its class packs (in hero order) and its singles (sheet order).
export type Premium = { bundle: string?, packs: { string }, singles: { string } }
function Store.premiumProducts(theme: string, heroOrder: { string }): Premium
	local out: Premium = { bundle = nil, packs = {}, singles = {} }
	local byHero: { [string]: string } = {}
	for _, key in Store.order() do
		if Store.premiumTheme(key) == theme then
			local kind = Store.premiumKind(key)
			if kind == "bundle" then
				out.bundle = key
			elseif kind == "pack" then
				local hunter = nil
				for _, item in (Store.row(key) :: Row).items do
					local r = skinRow(item)
					if r and r.hero then
						hunter = r.hero
					end
				end
				if hunter then
					byHero[hunter] = key
				end
			else
				table.insert(out.singles, key)
			end
		end
	end
	for _, hero in heroOrder do
		if byHero[hero] then
			table.insert(out.packs, byHero[hero])
		end
	end
	return out
end

-- The Robux the items would cost one by one (their singles), or nil when one isn't sold alone.
function Store.singlesTotal(key: string): number?
	local row = Store.row(key)
	if not row then
		return nil
	end
	local total = 0
	for _, item in row.items do
		local single = Store.singleFor(item)
		local r = single and Store.row(single)
		if not r or not r.robux then
			return nil
		end
		total += r.robux
	end
	return total
end

-- What a pack or bundle saves: a pack against its singles; a bundle against its class packs
-- (the tower set counted once). (saved Robux, "singles" | "packs"), or nil.
function Store.savings(key: string, heroOrder: { string }): (number?, string?)
	local row = Store.row(key)
	local kind = Store.premiumKind(key)
	if not row or not row.robux or (kind ~= "pack" and kind ~= "bundle") then
		return nil, nil
	end
	if kind == "pack" then
		local total = Store.singlesTotal(key)
		return if total then total - row.robux else nil, "singles"
	end
	local theme = Store.premiumTheme(key) :: string
	local products = Store.premiumProducts(theme, heroOrder)
	local tower = Skins.themeItems(theme, "tower")[1]
	local single = tower and Store.singleFor(tower)
	local towerPrice = single and (Store.row(single) :: Row).robux
	local packs = 0
	for _, pack in products.packs do
		local r = Store.row(pack) :: Row
		if not r.robux then
			return nil, nil
		end
		packs += r.robux
	end
	if #products.packs == 0 or not towerPrice then
		return nil, nil
	end
	return packs - (#products.packs - 1) * towerPrice - row.robux, "packs"
end

-- Does the player already have every item inside (a fully owned product isn't sold again)?
function Store.hasAll(key: string, owns: (string) -> boolean): boolean
	local row = Store.row(key)
	if not row or #row.items == 0 then
		return false
	end
	for _, item in row.items do
		if not owns(item) then
			return false
		end
	end
	return true
end

local KIND_WORDS = { hunter = "hunter skin", weapon = "gun skin", tower = "tower set", grenade = "grenade skin", ability = "ability skin" }

-- A premium card's text: what's inside (and what you have), the saving, the FX it brings.
-- `heroName(hero)` names a class ("Big Game Hunter"); `owns(item)` = already yours.
function Store.premiumLine(key: string, heroOrder: { string }, heroName: (string) -> string, owns: (string) -> boolean): string
	local row = Store.row(key)
	local kind = Store.premiumKind(key)
	if not row or not kind then
		return ""
	end
	if kind == "single" then
		local s = skinRow(row.items[1])
		if not s then
			return ""
		end
		local who = if s.hero then ` for the {heroName(s.hero)}` else " for every tower"
		local fx = if (s.fxTier or 0) >= 3
			then "animated glow, particles and trail"
			elseif (s.fxTier or 0) >= 1 then "animated glow"
			elseif s.kind == "ability" then "recoloured effects"
			else "glowing"
		return `{string.upper(string.sub(KIND_WORDS[s.kind] or s.kind, 1, 1))}{string.sub(KIND_WORDS[s.kind] or s.kind, 2)}{who} · {fx} · cosmetic only`
	end
	local new, have = {}, {}
	for _, item in row.items do
		local s = skinRow(item)
		local name = if s then s.display else item
		table.insert(if owns(item) then have else new, name)
	end
	local saved, against = Store.savings(key, heroOrder)
	local save = if saved and saved > 0 then ` · saves {Store.robuxLabel(saved)} vs {against}` else ""
	local inside = if kind == "bundle"
		then `All {#Store.premiumProducts(Store.premiumTheme(key) :: string, heroOrder).packs} class packs, {#row.items} items (tower set once)`
		else `Inside: {table.concat(new, ", ")}`
	if #new == 0 then
		return `You have everything inside`
	elseif #have > 0 then
		inside = `New for you: {#new} of {#row.items} (you have {#have})`
	end
	local fx = if kind == "pack" then " · unlocks the full pack effects" else " · every pack's full effects"
	return `{inside}{save}{fx}`
end

-- The card's button: (text, can buy). Yours -> "Yours"; the store closed (Studio / unpublished)
-- or the product without its Creator Hub id yet -> the price, not buyable; else "Buy R$...".
function Store.premiumButton(key: string, open: boolean, restricted: boolean, owns: (string) -> boolean): (string, boolean)
	if Store.hasAll(key, owns) then
		return "Yours", false
	end
	local price = Store.priceLabel(key)
	if not open or not Store.shown(key, restricted) then
		return price, false
	end
	return `Buy {price}`, true
end

return Store
