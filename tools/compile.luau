--[[
	Compile check (Lune, run by tools/test.sh): compiles every .luau file under src/ with the
	real Luau compiler (@lune/luau's compile) and fails on any compile error. luau-lsp
	(tools/check.sh) type-checks but never compiles, so it misses compiler limits such as
	"Out of local registers ... exceeded limit 200" (PLAYTEST F11: a module with more than
	200 top-level locals crashes the Roblox server at require time).

	It also measures each file's main-chunk headroom: how many more top-level locals it can
	take before it stops compiling (found by prepending dummy locals). The run fails when a
	file's headroom is below MIN_HEADROOM, so a file is split well before it breaks.

	  lune run tools/compile.luau              every file under src/
	  lune run tools/compile.luau a.luau ...   only these files (e.g. an old version in /tmp)
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local LIMIT = 200 -- Luau's register limit per function
local MIN_HEADROOM = 30 -- fail when a main chunk has fewer free registers than this
local REPORT_BELOW = 60 -- list (without failing) files with fewer free registers than this

local function compiles(source: string): (boolean, string?)
	local ok, err = pcall(luau.compile, source)
	if ok then
		return true, nil
	end
	local msg = tostring(err)
	return false, string.match(msg, "syntax error: ([^\n]*)") or string.match(msg, "([^\n]*%S)")
end

-- Free registers left in the main chunk: the largest n for which n dummy locals put in front
-- of the source still compile (they stay live for the whole chunk, like any top-level local).
local function headroom(source: string): number
	local function fits(n: number): boolean
		if n == 0 then
			return true
		end
		-- `= {}`: a local bound to a constant (or to nothing) is folded away and takes no register
		local decls = table.create(n)
		for i = 1, n do
			decls[i] = `local __h{i} = \{}`
		end
		return (compiles(table.concat(decls, "; ") .. "\n" .. source))
	end
	local lo, hi = 0, LIMIT
	while lo < hi do
		local mid = (lo + hi + 1) // 2
		if fits(mid) then
			lo = mid
		else
			hi = mid - 1
		end
	end
	return lo
end

local files: { string } = {}
local function scan(dir: string)
	for _, entry in fs.readDir(dir) do
		local full = dir .. "/" .. entry
		if fs.isDir(full) then
			scan(full)
		elseif string.match(entry, "%.luau$") then
			table.insert(files, full)
		end
	end
end
if #process.args > 0 then
	files = table.clone(process.args)
else
	scan("src")
end
table.sort(files)

local failed = 0
local tight = {}
local tightest, tightestFree = nil, math.huge
for _, path in files do
	local source = fs.readFile(path)
	local ok, err = compiles(source)
	if not ok then
		failed += 1
		print(`COMPILE FAIL {path}: {err}`)
	else
		local free = headroom(source)
		if free < tightestFree then
			tightest, tightestFree = path, free
		end
		if free < MIN_HEADROOM then
			failed += 1
			print(`HEADROOM FAIL {path}: {free} free registers in the main chunk (min {MIN_HEADROOM})`)
		elseif free < REPORT_BELOW then
			table.insert(tight, `{path} ({free} free)`)
		end
	end
end

if #tight > 0 then
	print("Near the limit: " .. table.concat(tight, ", "))
end
local least = if tightest then ` (least headroom: {tightest}, {tightestFree} free registers)` else ""
print(`compile: {#files} files, {failed} failing{least}`)
if failed > 0 then
	process.exit(1)
end
