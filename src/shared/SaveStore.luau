--[[
	How Progression talks to the save data store (PLAN T90), with the store passed in so a
	spec can fake it (tools/test/savestore.spec.luau). Pure: no Roblox services.

	Every request is an UpdateAsync, so a read and its write are one step and the session
	lock (Shared/Profile.mayTake / mayWrite) is checked against what is stored right now.

	  SaveStore.load(store, key, session, env)
	      "ok", raw      took the lock; `raw` is the stored record (nil for a new player)
	      "locked", nil  another live server still holds it (after LOCK_WAITS tries)
	      "failed", err  the store wouldn't answer (after ATTEMPTS tries)
	  SaveStore.write(store, key, session, env, data, release)
	      "ok"           written (`data()` is read at write time, so it's the newest);
	                     data = nil only refreshes the lock; release = true frees it
	      "lost"         the stored lock isn't ours: nothing written, never retried
	      "failed", err  the store wouldn't answer (after ATTEMPTS tries)

	Retries: a throwing request, or no request budget left, waits SaveStore.backoff(n)
	(1, 2, 4, 8 s… capped) and tries again, at most ATTEMPTS requests. A request is never
	made while the budget is below 1. Nothing here throws.
]]

local Profile = require(script.Parent.Profile)

local SaveStore = {}

SaveStore.ATTEMPTS = 3 -- requests per load / write before giving up (store errors, no budget)
SaveStore.LOCK_WAITS = 6 -- how often a load asks again while another server holds the save
SaveStore.BASE_DELAY = 1 -- seconds before the first retry; doubles each time
SaveStore.MAX_DELAY = 8

export type Store = {
	-- UpdateAsync: calls transform(old) (maybe more than once); a nil return writes nothing.
	-- Returns the stored value after. May throw.
	update: (key: string, transform: (old: any) -> any) -> any,
	-- Requests left now (DataStoreService:GetRequestBudgetForRequestType); nil = no limit.
	budget: (() -> number)?,
}
export type Env = {
	now: () -> number,
	wait: (seconds: number) -> (),
	log: ((text: string) -> ())?,
}

function SaveStore.backoff(attempt: number): number
	return math.min(SaveStore.MAX_DELAY, SaveStore.BASE_DELAY * 2 ^ (math.max(1, attempt) - 1))
end

local function hasBudget(store: Store): boolean
	if not store.budget then
		return true
	end
	local ok, left = pcall(store.budget)
	return ok and type(left) == "number" and left >= 1
end

local function copy(raw: any): { [string]: any }
	local out = {}
	if type(raw) == "table" then
		for k, v in raw do
			out[k] = v
		end
	end
	return out
end

-- One UpdateAsync with retries. `transform(old)` returns (value to store | nil, verdict);
-- a nil value with a verdict ("locked" / "lost") stops without retrying store errors.
local function run(store: Store, key: string, env: Env, transform: (old: any) -> (any, string?)): (string, any)
	local lastErr: any = "no request made"
	for attempt = 1, SaveStore.ATTEMPTS do
		if hasBudget(store) then
			local verdict: string? = nil
			local stored: any = nil
			local ok, err = pcall(function()
				store.update(key, function(old: any): any
					local value, why = transform(old)
					verdict = why
					stored = if value ~= nil then value else old
					return value
				end)
			end)
			if ok then
				return verdict or "ok", stored
			end
			lastErr = err
			if env.log then
				env.log(`[SaveStore] {key}: request {attempt}/{SaveStore.ATTEMPTS} failed: {err}`)
			end
		else
			lastErr = "no request budget"
		end
		if attempt < SaveStore.ATTEMPTS then
			env.wait(SaveStore.backoff(attempt))
		end
	end
	return "failed", lastErr
end

function SaveStore.load(store: Store, key: string, session: string, env: Env): (string, any)
	for wait = 1, SaveStore.LOCK_WAITS do
		local status, stored = run(store, key, env, function(old: any): (any, string?)
			if not Profile.mayTake(old, session, env.now()) then
				return nil, "locked"
			end
			local record = copy(old)
			record.lock = { session = session, at = env.now() }
			return record, nil
		end)
		if status ~= "locked" then
			if status == "ok" then
				local raw = copy(stored)
				raw.lock = nil
				return "ok", if next(raw) == nil then nil else raw -- only a lock: a new player
			end
			return status, stored
		end
		if wait < SaveStore.LOCK_WAITS then
			env.wait(SaveStore.backoff(wait))
		end
	end
	return "locked", nil
end

function SaveStore.write(
	store: Store,
	key: string,
	session: string,
	env: Env,
	data: (() -> { [string]: any })?,
	release: boolean?
): (string, any)
	local status, err = run(store, key, env, function(old: any): (any, string?)
		if not Profile.mayWrite(old, session) then
			return nil, "lost"
		end
		local record = if data then copy(data()) else copy(old)
		record.lock = if release then nil else { session = session, at = env.now() }
		return record, nil
	end)
	if status == "ok" or status == "lost" then
		return status, nil
	end
	return status, err
end

return SaveStore
