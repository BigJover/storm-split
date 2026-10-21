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

	Saved per profile as { receipts = { PurchaseId, ... } (newest last, at most LEDGER_MAX),
	hatchCredits = { [egg] = n } } — a paid "Hatch now" that found no egg of its kind waiting
	is kept as a credit and used on the next one, never lost.
]]

local Config = require(script.Parent.Config)
local Theme = require(script.Parent.Theme)

local Store = {}

Store.CLOSED_LINE = "The store opens when the game is published"
Store.TABS = table.freeze({ "Amber", "Passes", "Hatchery", "Skins" })
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
export type State = { receipts: { string }, hatchCredits: { [string]: number } }
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
	return { receipts = {}, hatchCredits = {} }
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
	return state
end

function Store.toSave(state: State): { [string]: any }
	return { receipts = table.clone(state.receipts), hatchCredits = table.clone(state.hatchCredits) }
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

-- What a product row's card says (Round 22: the exact Amber; a bundle lists every item
-- and says "saves X Amber" only when every item is sold for Amber, so the figure is true).
function Store.cardLine(key: string, skinName: (string) -> string?, skinPrice: (string) -> number?): string
	local row = Store.row(key)
	if not row then
		return ""
	end
	if row.grant == "amber" and row.amount then
		return `{Theme.amberExact(row.amount)} {Theme.Currency}`
	elseif row.grant == "skins" then
		local names, total, all = {}, 0, true
		for _, item in row.items do
			table.insert(names, skinName(item) or item)
			local price = skinPrice(item)
			if price then
				total += price
			else
				all = false
			end
		end
		local line = `Inside: {table.concat(names, ", ")}`
		return if all and total > 0 then `{line} · saves {Theme.amberExact(total)} {Theme.Currency}` else line
	end
	return row.line
end

-- The price label: "R$ 49".
function Store.priceLabel(key: string): string
	local row = Store.row(key)
	return if row and row.robux then `R$ {row.robux}` else ""
end

return Store
