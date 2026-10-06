--[[
	Headless test runner (Lune). Runs every tools/test/*.spec.luau, or only the specs whose
	file name contains one of the command-line arguments.

	Modules under src/ are loaded with @lune/luau's load(), not Lune's own require, so they
	run exactly as written for Roblox:
	  - `script` is a shim for the module's file: `script.Parent.X` (and :WaitForChild("X"),
	    :FindFirstChild("X")) resolve to the sibling file X.luau / X.server.luau /
	    X.client.luau or to the folder X, the way Rojo lays them out.
	  - `require(shim)` loads that file once and caches it, like Roblox's require.
	  - Vector3, Vector2, CFrame, Color3, ColorSequence, NumberSequence, UDim, UDim2, Enum
	    and Instance come from @lune/roblox, so visual builders (TowerLook, DinoLook) can build real instances;
	    `task` is @lune/task.
	Only pure modules work this way (the shared ones); anything that calls game:GetService
	needs Studio.

	A spec is loaded the same way, plus:
	  src                  the shim for the src/ folder: require(src.shared.Upgrades)
	  test(name, fn)       one test; a failing check stops that test only
	  eq(actual, expected, what?)      equality (numbers, strings, booleans, nil)
	  near(actual, expected, what?, eps?)   numbers within eps (default 1e-9)
	  ok(condition, what?)
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local task = require("@lune/task")

local SPEC_DIR = "tools/test"
local SRC = "src"

-- Instance-like shims ---------------------------------------------------------

-- fs calls yield, and a metamethod can't, so the tree is listed once up front.
local isFile: { [string]: boolean } = {}
local isDir: { [string]: boolean } = {}
local function scan(dir: string)
	isDir[dir] = true
	for _, entry in fs.readDir(dir) do
		local full = dir .. "/" .. entry
		if fs.isDir(full) then
			scan(full)
		else
			isFile[full] = true
		end
	end
end
scan(SRC)

local shims: { [string]: any } = {}
local shimPaths: { [any]: string } = {}
local shimParents: { [string]: string? } = {}

local function basename(path: string): string
	return string.match(path, "([^/]+)$") or path
end

local function dirname(path: string): string?
	return string.match(path, "^(.*)/[^/]+$")
end

-- The shim for a file or folder path (one table per path, so identity holds).
local function shimFor(path: string): any
	if shims[path] then
		return shims[path]
	end
	local shim = {}
	shims[path] = shim
	shimPaths[shim] = path

	local name = basename(path)
	name = string.gsub(name, "%.server%.luau$", "")
	name = string.gsub(name, "%.client%.luau$", "")
	name = string.gsub(name, "%.luau$", "")

	local function child(childName: string): any?
		if not isDir[path] then
			return nil
		end
		for _, suffix in { ".luau", ".server.luau", ".client.luau", "" } do
			local candidate = path .. "/" .. childName .. suffix
			if (suffix == "" and isDir[candidate]) or (suffix ~= "" and isFile[candidate]) then
				return shimFor(candidate)
			end
		end
		return nil
	end

	local methods = {
		FindFirstChild = function(_, childName: string)
			return child(childName)
		end,
		WaitForChild = function(_, childName: string)
			return child(childName) or error(`{childName} is not a child of {path}`, 2)
		end,
		GetFullName = function()
			return path
		end,
	}

	setmetatable(shim, {
		__index = function(_, key: string)
			if key == "Name" then
				return name
			elseif key == "Parent" then
				local parent = shimParents[path] or dirname(path)
				return parent and shimFor(parent) or nil
			elseif methods[key] then
				return methods[key]
			end
			return child(key) or error(`{key} is not a valid member of {path}`, 2)
		end,
		__tostring = function()
			return path
		end,
	})
	return shim
end

-- Module loading -------------------------------------------------------------

local loaded: { [string]: any } = {}
local loading: { [string]: boolean } = {}
local shimRequire

local function environment(path: string, extra: { [string]: any }?): { [string]: any }
	local env = {
		script = shimFor(path),
		require = shimRequire,
		Vector3 = roblox.Vector3,
		Vector2 = roblox.Vector2,
		CFrame = roblox.CFrame,
		Color3 = roblox.Color3,
		ColorSequence = roblox.ColorSequence,
		NumberSequence = roblox.NumberSequence,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Enum = roblox.Enum,
		Instance = roblox.Instance,
		task = task,
	}
	if extra then
		for k, v in extra do
			env[k] = v
		end
	end
	return env
end

local function compile(path: string, extra: { [string]: any }?)
	return luau.load(fs.readFile(path), { debugName = path, environment = environment(path, extra) })
end

function shimRequire(target: any): any
	local path = shimPaths[target]
	if not path then
		return require(target) -- a real Lune require (e.g. "@lune/fs")
	end
	if loaded[path] ~= nil then
		return loaded[path]
	end
	assert(not loading[path], `require cycle at {path}`)
	assert(isFile[path], `{path} is a folder, not a module`)
	loading[path] = true
	local result = compile(path)()
	loading[path] = nil
	loaded[path] = result
	return result
end

-- Assertions -----------------------------------------------------------------

local function show(v: any): string
	if type(v) == "string" then
		return string.format("%q", v)
	end
	return tostring(v)
end

local function label(what: string?): string
	return if what then what .. ": " else ""
end

local function eq(actual: any, expected: any, what: string?)
	if actual ~= expected then
		error(`{label(what)}expected {show(expected)}, got {show(actual)}`, 2)
	end
end

local function near(actual: number, expected: number, what: string?, eps: number?)
	local tolerance = eps or 1e-9
	if type(actual) ~= "number" or math.abs(actual - expected) > tolerance then
		error(`{label(what)}expected {show(expected)} (±{tolerance}), got {show(actual)}`, 2)
	end
end

local function ok(condition: any, what: string?)
	if not condition then
		error(`{label(what)}check failed`, 2)
	end
end

-- Running --------------------------------------------------------------------

local filters = process.args
local specs = {}
for _, file in fs.readDir(SPEC_DIR) do
	if string.match(file, "%.spec%.luau$") then
		local wanted = #filters == 0
		for _, f in filters do
			wanted = wanted or string.find(file, f, 1, true) ~= nil
		end
		if wanted then
			table.insert(specs, file)
		end
	end
end
table.sort(specs)

local passed, failed = 0, 0
for _, file in specs do
	local specPassed, specFailed = 0, 0
	local function test(name: string, fn: () -> ())
		local success, err = pcall(fn)
		if success then
			specPassed += 1
		else
			specFailed += 1
			print(`  FAIL {name}\n       {err}`)
		end
	end

	local success, err = pcall(function()
		compile(`{SPEC_DIR}/{file}`, {
			src = shimFor(SRC),
			test = test,
			eq = eq,
			near = near,
			ok = ok,
		})()
	end)
	if not success then
		specFailed += 1
		print(`  ERROR {file} did not finish\n       {err}`)
	end

	print(`{if specFailed == 0 then "ok  " else "FAIL"} {file}: {specPassed} passed, {specFailed} failed`)
	passed += specPassed
	failed += specFailed
end

if #specs == 0 then
	print("no specs matched")
	process.exit(1)
end
print(`{passed} passed, {failed} failed`)
process.exit(if failed == 0 then 0 else 1)
