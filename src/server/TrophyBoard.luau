--[[
	TrophyBoard: the Trophy leaderboard (PLAN phase 7 T81, DECISIONS #218). The level
	board's machinery (Server/LevelBoard.start, rules in Shared/LevelBoard) on its own
	OrderedDataStore (Shared/TrophyBoard.STORE), cache and "TrophyBoard" RemoteFunction,
	ranking the "Trophies" attribute Server/Progression publishes. Top 50 across servers
	when published; "This server" unpublished, in Studio, or while the store fails. Only a
	live save is ever written (SaveStatus "saved"), so Practice and J sessions never are.
	Trophies can drop, so this server's saved hunters show their live count.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TrophyBoard"))
local LevelBoard = require(script.Parent.LevelBoard)

local TrophyBoard = {}

function TrophyBoard.init(remotes: Folder)
	LevelBoard.start(remotes, { store = Rules.STORE, attribute = "Trophies", remote = "TrophyBoard", label = "Trophy board", live = true })
end

return TrophyBoard
