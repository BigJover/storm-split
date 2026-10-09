--[[
	Battle pacing + Studio test aids (PLAN T91b, #245): Battle round time is battles only;
	stand-in towers pierce armour, "Start at round N" and "Stand-ins hold" exist only behind
	Shared/StudioOnly, and their chips show only in Studio.
]]
local fs = require("@lune/fs")
local Config = require(src.shared.Config)
local HomeLayout = require(src.shared.HomeLayout)

local function read(path: string): string
	return fs.readFile(path)
end

test("T91b: Battle round time is battles only (co-op pacing unchanged)", function()
	for _, path in { "src/server/Waves.luau", "src/server/Main.server.luau", "src/server/Enemies.luau" } do
		eq(read(path):find("BattleRoundTime", 1, true), nil, `{path} never reads Battle round time`)
	end
	ok(read("src/shared/BattleRules.luau"):find("Config.Tuning.BattleRoundTime", 1, true) ~= nil, "the lockstep rule reads it")
end)

test("T91b: stand-in towers pierce armour only through StudioOnly", function()
	local shop = read("src/server/Shop.luau")
	local gate = shop:find('if StudioOnly.allowed(RunService:IsStudio(), "standInPierce") then', 1, true)
	local call = shop:find("Towers.pierceArmourForStandIn(tower)", 1, true)
	ok(gate ~= nil and call ~= nil and call > gate, "Shop.placeStandIn asks first")
	local _, uses = string.gsub(shop, "pierceArmourForStandIn", "")
	eq(uses, 1, "only the stand-in placement sets it")
	local towers = read("src/server/Towers.luau")
	ok(towers:find("standInPierce = false,", 1, true) ~= nil, "every tower starts without it")
	ok(towers:find("or tower.standInPierce", 1, true) ~= nil, "piercing() honours it")
end)

test("T91b: the Lobby's Studio actions are refused live; battles and co-op read the same start round", function()
	local main = read("src/server/Main.server.luau")
	ok(main:find('action == "startround" and typeof(key) == "number" and StudioOnly.allowed(RunService:IsStudio(), "startRound")', 1, true) ~= nil, "startround gated")
	ok(main:find('action == "standinshold" and typeof(key) == "boolean" and StudioOnly.allowed(RunService:IsStudio(), "standInsHold")', 1, true) ~= nil, "standinshold gated")
	ok(main:find("startRound = studioStartRound(),", 1, true) ~= nil, "battles get it")
	ok(main:find("local startAt = studioStartRound()", 1, true) ~= nil, "co-op gets it")
	ok(main:find("Battle.leakCost(enemy.side, Enemies.leakCost(enemy))", 1, true) ~= nil, "every leak asks Battle (hold)")
	local battle = read("src/server/Battle.luau")
	ok(battle:find("startRound(firstRound)", 1, true) ~= nil, "a battle starts at its first round")
	ok(battle:find("standInSeats[side] == true", 1, true) ~= nil, "hold is for stand-in seats only")
end)

test("T91b: the Studio chips show only in Studio; Stand-ins hold only for a battle with stand-ins", function()
	eq(HomeLayout.studioOptions("COOP", false, false).row, false, "live: hidden")
	eq(HomeLayout.studioOptions("TEAM", false, true).hold, false, "live: no hold")
	eq(HomeLayout.studioOptions("COOP", true, false).row, true, "Studio co-op: Start at round")
	eq(HomeLayout.studioOptions("COOP", true, true).hold, false, "co-op has no stand-ins")
	eq(HomeLayout.studioOptions("TEAM", true, false).hold, false, "stand-ins off")
	eq(HomeLayout.studioOptions("TEAM", true, true).hold, true)
	ok(HomeLayout.fits(HomeLayout.START_AT) and HomeLayout.fits(HomeLayout.HOLD), "chip text fits")
	ok(HomeLayout.rowWidth({ HomeLayout.START_AT.width, HomeLayout.HOLD.width }) <= HomeLayout.COLUMN, "row fits")
	local widest = HomeLayout.START_ROUNDS[#HomeLayout.START_ROUNDS]
	eq(HomeLayout.startText(widest), HomeLayout.START_AT.text, "the widest text is the one checked")
	eq(HomeLayout.nextStartRound(nil), 10, "from round 1")
	eq(HomeLayout.nextStartRound(30), 38, "to Final Stampede's doorstep")
	eq(HomeLayout.nextStartRound(38), 1, "wraps")
	ok(widest <= #Config.Rounds, "presets are real rounds")
end)
