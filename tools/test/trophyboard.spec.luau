--[[
	The Trophy board and arena rewards (PLAN phase 7 T81, DECISIONS #218, #229):
	Shared/TrophyBoard (the level board's rules ranking Trophies, with live rows because
	Trophies can drop), the arena names on the Arenas sheet, and Cosmetics' arena unlocks.
]]

local Config = require(src.shared.Config)
local Cosmetics = require(src.shared.Cosmetics)
local LevelBoard = require(src.shared.LevelBoard)
local TrophyBoard = require(src.shared.TrophyBoard)

test("the eight arena names from the Dino review (#229), floors unchanged, rewards blank", function()
	local names = { "Fern Gully", "Raptor Ridge", "Muddy Springs", "Horn Canyon", "Volcano Rim", "Sky Cliffs", "Misty Jungle", "Rex Kingdom" }
	local floors = { 0, 300, 600, 1000, 1500, 2000, 3000, 4000 }
	eq(#Config.Arenas, 8)
	for i, arena in Config.Arenas do
		eq(arena.display, names[i], `arena {i} name`)
		eq(arena.floor, floors[i], `arena {i} floor`)
		eq(arena.reward, "", `arena {i} reward stays blank (no cosmetic id yet)`)
	end
end)

test("fallback: unpublished / no store -> 'This server', the note, everyone here by Trophies", function()
	local view = TrophyBoard.view(nil, {
		{ userId = 1, name = "A", trophies = 30 },
		{ userId = 2, name = "B", trophies = 320 },
		{ userId = 3, name = "C", trophies = 0 },
	}, 3)
	eq(view.mode, "server")
	eq(view.title, "This server")
	eq(view.note, LevelBoard.NOTE)
	eq(#view.rows, 3)
	eq(view.rows[1].userId, 2)
	eq(view.rows[1].xp, 320, "ranked by Trophies")
	eq(view.rows[3].userId, 3)
	eq(view.mine.userId, 3, "your own row")
end)

test("a live drop beats a stale stored count (Trophies can go down); XP keeps the higher", function()
	local world = { { userId = 7, name = "Old", xp = 500 } }
	local trophies = TrophyBoard.view(world, { { userId = 7, name = "Now", trophies = 470 } }, 7)
	eq(trophies.rows[1].xp, 470, "Trophy board: live count")
	eq(trophies.mode, "world")
	local xp = LevelBoard.view({ { userId = 7, name = "Old", xp = 500 } }, { { userId = 7, name = "Now", xp = 470 } }, 7)
	eq(xp.rows[1].xp, 500, "level board unchanged: the higher XP stands")
end)

test("a drop to 0 Trophies is written over a known value; 0 never written for a new hunter", function()
	local cache = LevelBoard.newCache()
	LevelBoard.queue(cache, 5, 0)
	eq(cache.pending[5], nil, "nothing to write for a fresh 0")
	LevelBoard.seed(cache, 5, 40)
	LevelBoard.queue(cache, 5, 0)
	eq(cache.pending[5], 0, "40 -> 0 is written")
end)

test("the arena badge on the player list", function()
	eq(TrophyBoard.badge(0), "0 · Fern Gully")
	eq(TrophyBoard.badge(320), "320 · Raptor Ridge")
	eq(TrophyBoard.badge(4500), "4500 · Rex Kingdom")
	eq(TrophyBoard.COLUMN, "Trophies")
end)

test("arena rewards unlock on first reach, whatever the level; blank rewards unlock nothing", function()
	local arenas = { { reward = "" }, { reward = "HAT_X" }, { reward = "" } }
	eq(Cosmetics.arenaUnlocked("HAT_X", 1, arenas), false, "not reached yet")
	eq(Cosmetics.arenaUnlocked("HAT_X", 2, arenas), true, "reached")
	eq(Cosmetics.arenaUnlocked("HAT_X", 3, arenas), true, "and kept above it")
	eq(Cosmetics.arenaUnlocked("", 8), false, "the real sheet's blank cells unlock nothing")
end)

test("Server/TrophyBoard runs on its own store and the Trophies attribute; Main starts it", function()
	local fs = require("@lune/fs")
	local server = fs.readFile("src/server/TrophyBoard.luau")
	ok(server:find('attribute = "Trophies", remote = "TrophyBoard"', 1, true) ~= nil, "Trophies, its own remote")
	ok(server:find("live = true", 1, true) ~= nil, "live rows")
	ok(TrophyBoard.STORE ~= LevelBoard.STORE, "its own store")
	local main = fs.readFile("src/server/Main.server.luau")
	ok(main:find("TrophyBoard.init(remotes)", 1, true) ~= nil, "started")
	local board = fs.readFile("src/server/LevelBoard.luau")
	ok(board:find('player:GetAttribute("SaveStatus") == "saved"', 1, true) ~= nil, "only a live save is written")
end)
