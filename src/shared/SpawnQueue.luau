--[[
	SpawnQueue: the capped spawn queue, one FIFO per side (ARCHITECTURE §5.1, PLAN T75).
	Pure; Server/Enemies owns the only instance and is still the only spawner.

	Nothing spawns directly: Enemies.enqueue(side, ...) pushes here, and every frame Enemies
	takes items while take() hands one out. The live cap (Tuning MaxConcurrentEnemies) is
	shared by every side and split evenly (Shared/Sides.sideCap), so one side's backlog never
	holds back another side's dinos. Sides take turns (round robin) for fairness.

	With one side (co-op) take() is exactly the old rule: first in, first out, while the
	live count is under the cap.

	  new(sides)                         -> Queue
	  push(q, side, item)
	  size(q, side?)                     -> queued for that side, or for every side
	  take(q, liveTotal, liveBySide, cap) -> the next item and its side, or nil
]]

local Sides = require(script.Parent.Sides)

local SpawnQueue = {}

type Fifo = { items: { any }, head: number, tail: number }

export type Queue = { sides: number, lists: { Fifo }, nextSide: number }

local function fifo(): Fifo
	return { items = {}, head = 1, tail = 0 }
end

function SpawnQueue.new(sides: number): Queue
	local lists = {}
	for side = 1, math.max(1, sides) do
		lists[side] = fifo()
	end
	return { sides = #lists, lists = lists, nextSide = 1 }
end

-- An unknown side is refused (returns false): a dino always belongs to a real side.
function SpawnQueue.push(q: Queue, side: number, item: any): boolean
	local list = q.lists[side]
	if not list then
		return false
	end
	list.tail += 1
	list.items[list.tail] = item
	return true
end

local function count(list: Fifo): number
	return list.tail - list.head + 1
end

function SpawnQueue.size(q: Queue, side: number?): number
	if side then
		local list = q.lists[side]
		return if list then count(list) else 0
	end
	local total = 0
	for _, list in q.lists do
		total += count(list)
	end
	return total
end

local function pop(list: Fifo): any
	local item = list.items[list.head]
	list.items[list.head] = nil
	list.head += 1
	if list.head > list.tail then
		list.head, list.tail = 1, 0
	end
	return item
end

function SpawnQueue.take(q: Queue, liveTotal: number, liveBySide: { [number]: number }, cap: number): (any, number?)
	if liveTotal >= cap then
		return nil, nil
	end
	local share = Sides.sideCap(cap, q.sides)
	for step = 0, q.sides - 1 do
		local side = (q.nextSide - 1 + step) % q.sides + 1
		local list = q.lists[side]
		if count(list) > 0 and (liveBySide[side] or 0) < share then
			q.nextSide = side % q.sides + 1
			return pop(list), side
		end
	end
	return nil, nil
end

return SpawnQueue
