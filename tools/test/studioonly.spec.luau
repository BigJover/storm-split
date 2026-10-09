--[[
	Studio-only gating (PLAN T89, Shared/StudioOnly): every Studio test feature is refused
	in a live server, and a grep over src/server fails if a new Studio remote or IsStudio
	check skips the helper.
]]
local fs = require("@lune/fs")
local StudioOnly = require(src.shared.StudioOnly)

local EXPECTED = { "cash", "amber", "towerHit", "standIns", "startRound", "standInsHold", "standInPierce", "clockCap", "lateStandIn" }

test("T89: each Studio-only feature is allowed in Studio and refused in a live server", function()
	local count = 0
	for feature in StudioOnly.FEATURES do
		count += 1
		eq(StudioOnly.allowed(true, feature), true, `{feature} in Studio`)
		eq(StudioOnly.allowed(false, feature), false, `{feature} live`)
	end
	eq(count, #EXPECTED, "the feature list")
	for _, feature in EXPECTED do
		ok(StudioOnly.FEATURES[feature] ~= nil, `{feature} listed`)
	end
end)

test("T89: an unlisted feature is refused even in Studio (fails closed)", function()
	eq(StudioOnly.allowed(true, "cahs"), false, "typo")
	eq(StudioOnly.allowed(true, "godMode"), false, "unlisted")
	eq(StudioOnly.allowed(nil :: any, "cash"), false, "no answer = live")
	eq(StudioOnly.allowed("true" :: any, "cash"), false, "only a real true")
end)

test("T89: the START_ROUND skip is Studio only", function()
	eq(StudioOnly.startRound(true, 25), 25, "Studio skips")
	eq(StudioOnly.startRound(false, 25), 1, "live always round 1")
	eq(StudioOnly.startRound(true, 0), 1, "never below 1")
	eq(StudioOnly.startRound(true, 1), 1, "default")
	eq(StudioOnly.startRound(true, 38, 40), 38, "T91b: Start at round 38")
	eq(StudioOnly.startRound(true, 99, 40), 40, "never past the last round")
	eq(StudioOnly.startRound(true, 12.7, 40), 12, "whole rounds")
	eq(StudioOnly.startRound(true, nil, 40), 1, "not picked = round 1")
	eq(StudioOnly.startRound(true, "38" :: any, 40), 1, "only a number")
	eq(StudioOnly.startRound(true, math.huge, 40), 1, "not infinity")
	eq(StudioOnly.startRound(false, 38, 40), 1, "T91b: refused live")
end)

test("T91b: Stand-ins hold keeps a stand-in camp's Fence at 1, Studio only", function()
	eq(StudioOnly.heldLoss(true, true, true, 30, 19, true), 19, "a leak the Fence can take")
	eq(StudioOnly.heldLoss(true, true, true, 10, 19, true), 9, "stops at 1")
	eq(StudioOnly.heldLoss(true, true, true, 1, 19, true), 0, "at 1 it holds")
	eq(StudioOnly.heldLoss(false, true, true, 10, 19, true), 19, "refused live: the full leak")
	eq(StudioOnly.heldLoss(true, false, true, 10, 19, true), 19, "hold off")
	eq(StudioOnly.heldLoss(true, "true" :: any, true, 10, 19, true), 19, "only a real true")
	eq(StudioOnly.heldLoss(true, true, false, 10, 19, true), 19, "a real camp always pays in full")
	eq(StudioOnly.allowed(false, "standInPierce"), false, "stand-in pierce refused live")
end)

test("N7: Stand-ins hold lets go once every real hunter's camp is out", function()
	eq(StudioOnly.heldLoss(true, true, true, 1, 19, true), 0, "a real camp in: held at 1")
	eq(StudioOnly.heldLoss(true, true, true, 1, 19, false), 19, "all real camps out: the stand-in can fall")
	eq(StudioOnly.heldLoss(true, true, true, 10, 19, false), 19, "no real camp in: the full leak")
	eq(StudioOnly.heldLoss(true, true, true, 10, 19, nil), 19, "not told = not held (fails closed)")
	eq(StudioOnly.heldLoss(false, true, true, 10, 19, true), 19, "still refused live")
end)

test("N7 grep: the host can flip Stand-ins hold mid-match, Studio only", function()
	local main = fs.readFile("src/server/Main.server.luau")
	local handler = main:find("lobby.OnServerEvent:Connect(function", 1, true)
	ok(handler ~= nil, "the Lobby handler")
	local hold = main:find('action == "standinshold"', handler, true)
	local lobbyOnly = main:find('GetAttribute("State") ~= "Lobby"', handler, true)
	ok(hold ~= nil and lobbyOnly ~= nil and hold < lobbyOnly, "standinshold is handled before the Lobby-only return")
	local line = main:sub(hold, (main:find("\n", hold, true) or #main) - 1)
	ok(line:find('StudioOnly.allowed(RunService:IsStudio(), "standInsHold")', 1, true) ~= nil, "gated by StudioOnly")
	ok(main:sub(hold, lobbyOnly):find("isHost(player)", 1, true) ~= nil, "host only")
	local battle = fs.readFile("src/server/Battle.luau")
	ok(battle:find("Economy.livesOf(side), cost, realCampIn)", 1, true) ~= nil, "Battle passes whether a real camp is in")
end)

-- The server code, comments stripped, as lines.
local function serverFiles(): { [string]: { string } }
	local files = {}
	for _, name in fs.readDir("src/server") do
		if string.match(name, "%.luau$") then
			local text = fs.readFile("src/server/" .. name)
			text = string.gsub(text, "%-%-%[(=*)%[.-%]%1%]", "") -- block comments
			local lines = {}
			for line in string.gmatch(text .. "\n", "([^\n]*)\n") do
				table.insert(lines, (string.gsub(line, "%-%-.*$", "")))
			end
			files[name] = lines
		end
	end
	return files
end

test("T89 grep: every IsStudio() on the server goes through StudioOnly (or is the not-live gate)", function()
	local checked = 0
	for name, lines in serverFiles() do
		for i, line in lines do
			if string.find(line, "IsStudio()", 1, true) then
				checked += 1
				local viaHelper = string.find(line, 'StudioOnly.allowed(RunService:IsStudio(), "', 1, true)
					or string.find(line, "StudioOnly.startRound(RunService:IsStudio(),", 1, true)
					or string.find(line, "StudioOnly.heldLoss(RunService:IsStudio(),", 1, true)
					or string.find(line, "StudioOnly.matchCap(RunService:IsStudio(),", 1, true) -- T104
				-- "Studio or unpublished" only ever turns live features OFF (Practice, This-server boards)
				local notLive = string.find(line, "RunService:IsStudio() or game.PlaceId == 0", 1, true)
				ok(viaHelper or notLive, `{name}:{i} uses IsStudio() without Shared/StudioOnly`)
				for feature in string.gmatch(line, 'StudioOnly%.allowed%(RunService:IsStudio%(%), "(%w+)"%)') do
					ok(StudioOnly.FEATURES[feature] ~= nil, `{name}:{i} feature "{feature}" is listed`)
				end
			end
		end
	end
	ok(checked >= 8, `found the Studio checks ({checked})`)
end)

test("T89 grep: every Studio remote is made inside a StudioOnly block and its handler asks again", function()
	local remotes = 0
	for name, lines in serverFiles() do
		for i, line in lines do
			local remote = string.match(line, '%.Name = "(Studio%w+)"')
			if remote then
				remotes += 1
				-- Walk up to the enclosing `if StudioOnly.allowed(...) then` at a lower indent.
				local indent = #string.match(line, "^%s*")
				local gate: string? = nil
				for j = i - 1, 1, -1 do
					local above = lines[j]
					local ind = #string.match(above, "^%s*")
					if string.match(above, "%S") and ind < indent then
						gate = string.match(above, '^%s*if StudioOnly%.allowed%(RunService:IsStudio%(%), "(%w+)"%) then%s*$')
						break
					end
				end
				ok(gate ~= nil, `{name}:{i} {remote} is made outside a StudioOnly block`)
				-- Its OnServerEvent handler's first line re-checks the same feature.
				local found = false
				for j = i + 1, math.min(#lines, i + 6) do
					if string.find(lines[j], "OnServerEvent:Connect(function", 1, true) then
						local first = lines[j + 1] or ""
						found = gate ~= nil
							and string.find(first, `if not StudioOnly.allowed(RunService:IsStudio(), "{gate}") then`, 1, true) ~= nil
						break
					end
				end
				ok(found, `{name}:{i} {remote}'s handler re-checks StudioOnly first`)
			end
		end
	end
	eq(remotes, 3, "StudioCash, StudioTowerHit, StudioProgress")
end)

test("T89: the client only shows Studio buttons for remotes the server made", function()
	local hud = fs.readFile("src/client/Hud.client.luau")
	ok(hud:find('remotes:FindFirstChild("StudioCash")', 1, true) ~= nil, "K button needs the remote")
	ok(hud:find('remotes:FindFirstChild("StudioProgress")', 1, true) ~= nil, "J needs the remote")
	ok(hud:find('remotes:FindFirstChild("StudioTowerHit")', 1, true) ~= nil, "L needs the remote")
end)
