--[[
	Tar Pit rules (PLAN T67, DECISIONS #150, #152, #189). Pure, so the specs can run
	them headlessly; Server/Towers acts on them and Server/Enemies applies the size drops.

	A pit stands ON the track (Shared/Placement). Its pool is the stretch of track centred
	on the point of the track nearest the pit: `length` studs long (the tower's range), so
	a dino `distance` studs along the track is in it when |distance - at| <= length / 2.

	  overlaps   a new pit's pool may not overlap another pit's pool at its current length
	             (#189: checked on the pool, not the footprint). Touching ends are allowed.
	  strongest  a dino in several pools (a Tar Lake upgrade can make pools touch) gets the
	             strongest one only: no stacking slow, burn, sinking or Eruption (#189). The
	             strongest is the pit with the most cash in it (base + every tier bought),
	             ties to the pit placed first.
	  sinks      a dino at its last size that has stayed in the tar `sinkSeconds` sinks (a
	             take-down); never a boss, never a flying dino (Pteranodons).
	  drop       Eruption: every dino in the pool drops `sizes` sizes outright, whatever its
	             HP, bosses included; Break resist doesn't reduce it (#150). It lands at the
	             top of its new size; dropping its last size takes it down.
	  onTracks   Tar Tracks: the footprints cover `tracksLength` studs of track past the
	             pool's far end.
	  tick       a repeating timer (Eruption every s): fires once each time it fills.
]]

local TarPit = {}

export type Pool = { at: number, length: number }

function TarPit.contains(distance: number, at: number, length: number): boolean
	return math.abs(distance - at) <= length / 2
end

-- Would a pool at `at`, `length` long, overlap any of `pools`? Ends that just touch don't.
function TarPit.overlaps(at: number, length: number, pools: { Pool }): boolean
	for _, pool in pools do
		if math.abs(at - pool.at) < (length + pool.length) / 2 then
			return true
		end
	end
	return false
end

-- The cash in a pit: its price plus every tier bought on each path.
function TarPit.strength(def, pathTiers: { number }): number
	local cash = def.baseCost or 0
	for pathIndex, tier in pathTiers do
		local path = def.paths[pathIndex]
		for t = 1, math.min(tier, if path then #path.tiers else 0) do
			cash += path.tiers[t].cost or 0
		end
	end
	return cash
end

-- Index of the strongest of `strengths` (the pools a dino stands in, in placing order);
-- the first wins a tie. nil when there are none.
function TarPit.strongest(strengths: { number }): number?
	local best = nil
	for i, s in strengths do
		if best == nil or s > strengths[best] then
			best = i
		end
	end
	return best
end

function TarPit.sinks(size: number, boss: boolean, flying: boolean, soaked: number, sinkSeconds: number): boolean
	return size <= 1 and not boss and not flying and sinkSeconds > 0 and soaked >= sinkSeconds
end

-- An Eruption on a dino: its HP pool after dropping `sizes` sizes, how many it dropped,
-- and whether that was its last.
function TarPit.drop(hp: number, share: number, size: number, sizes: number): (number, number, boolean)
	local dropped = math.clamp(math.floor(sizes), 0, size)
	if dropped <= 0 then
		return hp, 0, false
	end
	if dropped >= size then
		return 0, dropped, true
	end
	return math.min(hp, (size - dropped) * share), dropped, false
end

-- Tar Tracks: is `distance` on the footprints past the pool's far end?
function TarPit.onTracks(distance: number, at: number, length: number, tracksLength: number): boolean
	local from = at + length / 2
	return distance > from and distance <= from + tracksLength
end

-- A repeating timer: the time carried over and whether it fired this step.
function TarPit.tick(timer: number, dt: number, every: number): (number, boolean)
	if every <= 0 then
		return 0, false
	end
	timer += dt
	if timer >= every then
		return timer - every, true
	end
	return timer, false
end

-- Distances along the track to draw a pool at, about `step` studs apart, both ends included.
function TarPit.samples(at: number, length: number, step: number): { number }
	local n = math.max(1, math.ceil(length / math.max(0.5, step)))
	local out = {}
	for i = 0, n do
		table.insert(out, at - length / 2 + length * i / n)
	end
	return out
end

return TarPit
