--!strict
--[[
	The Hunters' Outpost (PLAN 10c T138, DECISIONS #382-#384, names DINO_REVIEW Round 20): the
	walkable camp of the same place, where characters stand between matches. Pure layout and
	rules, so specs can check them; Server/Outpost builds it and moves people in and out.

	The area sits away from every track copy (battle camps grow toward +X / +Z from the co-op
	map; the Outpost is at -Z, past the co-op build area's edge). Every size here is layout
	(studs), not a gameplay number.

	  CENTRE, RADIUS            the camp's middle (ground level) and the floor's radius
	  STATIONS                  the four training stations, in order: { key (the stat),
	                            name, stat (shown), line, offset (from CENTRE) }
	  STATION_RADIUS            how near a station's centre counts as "at" it (flat)
	  stationAt(position)       the stat key of the station this point stands at, else nil
	  station(key)              that station's row, or nil
	  CAMPSITES                 how many Campsites ring the camp (10, one per player seat)
	  campsite(i)               Campsite i's centre (1..CAMPSITES), else nil
	  HATCHERY_HUT, SHOP        the Hatchery Hut and the shop counter (placeholders until
	                            10d / 10e), offsets from CENTRE
	  atHut(position)           standing at the Hatchery Hut (T140: E opens it), HUT_RADIUS
	  atShop(position)          standing at the shop counter (T142: E opens it), SHOP_RADIUS
	  DECO_SPOTS                a Campsite's three Display Tower spots (T142), in its frame
  assignCampsite(taken)     the lowest free Campsite for a new arrival (T141), else nil
  spawnPoint(i)             where the i-th arrival appears (a ring by the camp fire)
	  inside(position)          is this point over the camp's floor (and not far above it)
	  thirdPerson(inOutpost)    the camera rule: third person allowed only in the Outpost
	                            (#383); everywhere else first person (Hero.client)
	  homeView(state, inCamp, collapsed, waiting)   how the home screen shows (docked panel)
	  waitsInCamp(state, seated)   whether a player belongs in the camp right now: the Lobby,
	                            or a match they aren't playing in (a Ranked late joiner waits
	                            here); never pulled out of a match they're playing
  campSpawns()              which character is a camp arrival, independent of the order
                            deferred CharacterAdded handlers run in (F12; see below)
]]

local Outpost = {}

Outpost.NAME = "Hunters' Outpost"
Outpost.CENTRE = Vector3.new(0, 0, -420)
Outpost.RADIUS = 110
Outpost.FLOOR_TOP = 0.1 -- the floor's top, like the tracks' ground
Outpost.CEILING = 60 -- studs above the floor still counted as inside

export type Station = { key: string, name: string, stat: string, line: string, offset: Vector3 }

-- Round 20 names and lines; the key is the trained stat (Shared/Training).
Outpost.STATIONS = table.freeze({
	table.freeze({ key = "reach", name = "Raptor Dummy", stat = "Reach", line = "Hit the padded raptor; your melee reaches further", offset = Vector3.new(-30, 0, -14) }),
	table.freeze({ key = "speed", name = "Raptor Chase", stat = "Speed", line = "Run from the wind-up raptor; you run faster", offset = Vector3.new(-12, 0, -32) }),
	table.freeze({ key = "health", name = "Herb Kitchen", stat = "Health", line = "Mix fern smoothies; more health", offset = Vector3.new(12, 0, -32) }),
	table.freeze({ key = "throw", name = "Coconut Toss", stat = "Throw", line = "Hit the far targets; grenades fly further", offset = Vector3.new(30, 0, -14) }),
}) :: { Station }
Outpost.STATION_RADIUS = 8

Outpost.CAMPSITES = 10
Outpost.CAMPSITE_RING = 82 -- studs from the centre to each Campsite's centre
Outpost.CAMPSITE_SIZE = 22 -- each Campsite is a square this wide
-- Display Towers (T142): three spots on each Campsite, in the Campsite's own frame (its
-- Ground part faces the camp's centre, -Z), clear of the Hatchling Pen at (-6, 5).
Outpost.DECO_SPOTS = table.freeze({ Vector3.new(6, 0, -6), Vector3.new(6, 0, 0), Vector3.new(6, 0, 6) })
Outpost.SHOP_RADIUS = 8 -- how near the shop counter counts as "at" it (flat; T142: E opens it)
Outpost.HATCHERY_HUT = Vector3.new(0, 0, 30)
Outpost.SHOP = Vector3.new(-24, 0, 26)
Outpost.SPAWN_RING = 10
Outpost.HUT_RADIUS = 12 -- how near the Hatchery Hut's centre counts as "at" it (flat)

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

function Outpost.station(key: unknown): Station?
	for _, row in Outpost.STATIONS do
		if row.key == key then
			return row
		end
	end
	return nil
end

function Outpost.stationAt(position: unknown): string?
	if typeof(position) ~= "Vector3" then
		return nil
	end
	local p = position :: Vector3
	if p.Y < Outpost.CENTRE.Y - 5 or p.Y > Outpost.CENTRE.Y + Outpost.CEILING then
		return nil
	end
	for _, row in Outpost.STATIONS do
		if (flat(p) - flat(Outpost.CENTRE + row.offset)).Magnitude <= Outpost.STATION_RADIUS then
			return row.key
		end
	end
	return nil
end

function Outpost.campsite(i: number): Vector3?
	if type(i) ~= "number" or i ~= math.floor(i) or i < 1 or i > Outpost.CAMPSITES then
		return nil
	end
	-- Evenly round the ring, starting south (behind the spawn), clear of the stations' north side.
	local angle = math.pi / 2 + (i - 1) * 2 * math.pi / Outpost.CAMPSITES
	return Outpost.CENTRE + Vector3.new(math.cos(angle), 0, math.sin(angle)) * Outpost.CAMPSITE_RING
end

function Outpost.spawnPoint(i: number): Vector3
	local n = if type(i) == "number" and i == i then math.floor(i) else 1
	local angle = (n % 12) * 2 * math.pi / 12
	return Outpost.CENTRE + Vector3.new(math.cos(angle) * Outpost.SPAWN_RING, 3, 12 + math.sin(angle) * Outpost.SPAWN_RING)
end

function Outpost.inside(position: unknown): boolean
	if typeof(position) ~= "Vector3" then
		return false
	end
	local p = position :: Vector3
	return (flat(p) - flat(Outpost.CENTRE)).Magnitude <= Outpost.RADIUS
		and p.Y >= Outpost.CENTRE.Y - 5
		and p.Y <= Outpost.CENTRE.Y + Outpost.CEILING
end

-- Standing at the Hatchery Hut (T140): in camp, within HUT_RADIUS of it (flat).
function Outpost.atHut(position: unknown): boolean
	if not Outpost.inside(position) then
		return false
	end
	local p = position :: Vector3
	return (flat(p) - flat(Outpost.CENTRE + Outpost.HATCHERY_HUT)).Magnitude <= Outpost.HUT_RADIUS
end

-- Standing at the shop counter (T142: E opens the shop; never overlaps the hut's circle).
function Outpost.atShop(position: unknown): boolean
	if not Outpost.inside(position) then
		return false
	end
	local p = position :: Vector3
	return (flat(p) - flat(Outpost.CENTRE + Outpost.SHOP)).Magnitude <= Outpost.SHOP_RADIUS
end

-- The Campsite a new arrival gets (T141: their Hatchling Pen): the lowest free one,
-- nil when all are taken. `taken` maps a Campsite number to its holder.
function Outpost.assignCampsite(taken: { [number]: any }): number?
	for i = 1, Outpost.CAMPSITES do
		if taken[i] == nil then
			return i
		end
	end
	return nil
end

function Outpost.thirdPerson(inOutpost: unknown): boolean
	return inOutpost == true
end

export type HomeView = { backdrop: boolean, docked: boolean, column: boolean, toggle: boolean, banner: "none" | "centre" | "top" }

-- The home screen over the camp (Home.client): with a character in camp the home controls
-- dock to one side over a clear view (walk around; the menu button is always there to bring
-- them back: no-trap rule); without one (still spawning) it's the old full home screen.
-- A player waiting for the next hunt sees the banner on top in camp (they can walk), or
-- centred over the backdrop otherwise.
function Outpost.homeView(state: unknown, inCamp: boolean, collapsed: boolean, waiting: boolean): HomeView
	local inLobby = state == "Lobby"
	if not inCamp then
		return { backdrop = inLobby or waiting, docked = false, column = inLobby, toggle = false, banner = if waiting then "centre" else "none" }
	end
	return { backdrop = false, docked = true, column = inLobby and not collapsed, toggle = inLobby, banner = if waiting then "top" else "none" }
end

function Outpost.waitsInCamp(state: unknown, seated: boolean): boolean
	if state == "Lobby" then
		return true
	end
	return not seated
end

--[[
	Which character is a camp arrival (PLAYTEST F12). Server/Outpost asks for a camp spawn,
	then LoadCharacterAsync; CharacterAdded handlers run DEFERRED, so they may run before or
	after LoadCharacterAsync returns. The rule therefore never depends on that order: a
	pending camp spawn is bound to the first character that reports in (from either side),
	and that character stays a camp character for as long as it lives. Any other character
	is a match spawn.

	  ledger:expect(owner)            a camp spawn is starting (refused while one is pending)
	  ledger:arrived(owner, char)     a character exists: binds a pending spawn to it; true
	                                  if it's the camp character (same answer every call)
	  ledger:failed(owner)            the spawn failed: drop the pending request
	  ledger:pending(owner)           a camp spawn is under way
	  ledger:forget(owner)            the owner left
]]
export type CampSpawns = {
	expect: (self: CampSpawns, owner: any) -> boolean,
	arrived: (self: CampSpawns, owner: any, character: any) -> boolean,
	failed: (self: CampSpawns, owner: any) -> (),
	pending: (self: CampSpawns, owner: any) -> boolean,
	forget: (self: CampSpawns, owner: any) -> (),
}

function Outpost.campSpawns(): CampSpawns
	local waiting: { [any]: boolean } = {}
	local bound: { [any]: any } = {}
	local ledger = {}
	function ledger.expect(_, owner: any): boolean
		if waiting[owner] then
			return false
		end
		waiting[owner] = true
		return true
	end
	function ledger.arrived(_, owner: any, character: any): boolean
		if character == nil then
			return false
		end
		if waiting[owner] then
			waiting[owner] = nil
			bound[owner] = character
			return true
		end
		return bound[owner] == character
	end
	function ledger.failed(_, owner: any)
		waiting[owner] = nil
	end
	function ledger.pending(_, owner: any): boolean
		return waiting[owner] == true
	end
	function ledger.forget(_, owner: any)
		waiting[owner] = nil
		bound[owner] = nil
	end
	return (ledger :: any) :: CampSpawns
end

return Outpost
