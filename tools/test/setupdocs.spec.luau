--[[
	SETUP.md's publish checklist (PLAN T88): the table of data store names must match the
	code exactly, so Jovan's "never rename these" list can't drift from what's saved.
]]
local fs = require("@lune/fs")

local setup = fs.readFile("SETUP.md")
local progression = fs.readFile("src/server/Progression.luau")

-- Every name the code stores under: Progression's STORE_NAME and the boards' STORE.
local function codeStores(): { string }
	local names = {}
	table.insert(names, string.match(progression, 'local STORE_NAME = "([^"]+)"'))
	for _, file in { "src/shared/LevelBoard.luau", "src/shared/TrophyBoard.luau" } do
		table.insert(names, string.match(fs.readFile(file), '%.STORE = "([^"]+)"'))
	end
	return names
end

test("T88: every data store the code uses is in SETUP.md's never-rename table", function()
	local names = codeStores()
	eq(#names, 3, "three stores found in the code")
	for _, name in names do
		ok(setup:find("| `" .. name .. "` |", 1, true) ~= nil, `{name} listed in SETUP.md`)
	end
end)

test("T88: SETUP.md lists no store the code doesn't use", function()
	local known = {}
	for _, name in codeStores() do
		known[name] = true
	end
	local listed = 0
	for name in string.gmatch(setup, "\n| `([%w_]+_v%d+)` |") do
		listed += 1
		ok(known[name], `{name} is a real store`)
	end
	eq(listed, 3, "three rows in the table")
end)

test("T88: the code opens stores only through those names", function()
	-- A new GetDataStore / GetOrderedDataStore call must use a listed constant.
	for _, file in fs.readDir("src/server") do
		local text = fs.readFile("src/server/" .. file)
		for arg in string.gmatch(text, "GetDataStore%(([^)]*)%)") do
			eq(arg, "STORE_NAME", `{file}: GetDataStore uses STORE_NAME`)
		end
		for arg in string.gmatch(text, "GetOrderedDataStore%(([^)]*)%)") do
			eq(arg, "spec.store", `{file}: GetOrderedDataStore uses the board's STORE`)
		end
	end
end)
