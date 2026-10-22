--[[
	Every action a client sends on ProgressRequest is routed by the server's dispatcher
	(PLAYTEST Run 15 F15: the Counter sent "setDecor", skinAction handled it, but the
	dispatcher never routed it, so the toast said "Unknown request" and no decoration could
	be placed). Table-driven: the client action names are read from the sources, the routed
	names from the dispatcher, so a new client button can't silently miss its route.
]]
local fs = require("@lune/fs")

-- ProgressRequest callers and the name each gives that RemoteFunction.
local CLIENTS = {
	{ "src/client/Counter.client.luau", { 'act%("([%w_]+)"', 'request:InvokeServer%("([%w_]+)"' } },
	{ "src/client/HuntBoard.client.luau", { 'progressRequest:InvokeServer%("([%w_]+)"' } },
	{ "src/client/Profile.client.luau", { 'progressRequest:InvokeServer%("([%w_]+)"' } },
}

local function dispatcherRoutes(): ({ [string]: boolean }, { [string]: boolean })
	local prog = fs.readFile("src/server/Progression.luau")
	local first = prog:find('request.Name = "ProgressRequest"', 1, true)
	assert(first, "ProgressRequest built in Server/Progression")
	local stop = prog:find('return false, "Unknown request"', first, true)
	assert(stop, "dispatcher ends in Unknown request")
	local body = prog:sub(first, stop)
	local routed, toSkin = {}, {}
	for line in body:gmatch("[^\n]+") do
		for name in line:gmatch('action == "([%w_]+)"') do
			routed[name] = true
		end
	end
	-- the skinAction branch: from the last `elseif` before `return skinAction(` to that call
	local call = body:find("return skinAction(", 1, true)
	assert(call, "dispatcher has a skinAction branch")
	local from = 1
	while true do
		local nextAt = body:find("elseif", from, true)
		if not nextAt or nextAt > call then
			break
		end
		from = nextAt + 1
	end
	local skinLine = body:sub(from, call)
	for name in skinLine:gmatch('action == "([%w_]+)"') do
		toSkin[name] = true
	end
	return routed, toSkin
end

local function skinActions(): { [string]: boolean }
	local prog = fs.readFile("src/server/Progression.luau")
	local start = prog:find("local function skinAction(", 1, true)
	assert(start, "skinAction exists")
	local stop = prog:find("\nend\n", start, true)
	local handled = {}
	for name in prog:sub(start, stop):gmatch('action == "([%w_]+)"') do
		handled[name] = true
	end
	return handled
end

test("every client ProgressRequest action is routed by the server dispatcher", function()
	local routed = dispatcherRoutes()
	local seen = 0
	for _, entry in CLIENTS do
		local src = fs.readFile(entry[1])
		for _, pattern in entry[2] do
			for name in src:gmatch(pattern) do
				seen += 1
				ok(routed[name] == true, `{entry[1]} sends "{name}" and the dispatcher routes it`)
			end
		end
	end
	ok(seen >= 8, "found the client action names")
end)

test("every action skinAction handles is routed to it, and every name routed to it is handled", function()
	local _, toSkin = dispatcherRoutes()
	local handled = skinActions()
	for name in handled do
		ok(toSkin[name] == true, `skinAction handles "{name}" and the dispatcher routes it there`)
	end
	for name in toSkin do
		ok(handled[name] == true, `dispatcher routes "{name}" to skinAction, which handles it`)
	end
	ok(handled.setDecor and toSkin.setDecor, "setDecor (Campsite decorations) reaches skinAction")
end)
