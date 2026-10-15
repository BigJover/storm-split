--!strict
--[[
	Volcano Vent (PLAN 9i T128, DECISIONS #339). Pure.
	It must stand within Near track studs of its side's track (Shared/Placement.checkNear) and
	owns one stretch of it: Tuning Flow length x Flow length x studs, centred on the track point
	nearest the vent.
	  - Eruption (every 1 / Fire rate s): Targets dinos on the stretch take Damage (breaks 1),
	    and a lava flow covers the stretch for Flow (s) (Tuning when blank). Dinos in the lava
	    burn Flow burn DPS x Damage x x the tower level (Lava Lake: ticks break 1) and are shoved
	    sideways Flow shove studs/s up to Shove max (bosses aren't shoved; it is not a slow);
	    after the flow they walk back (offset / speed). Two vents' flows on one dino: the
	    strongest only (Tar Pit #189's rule).
	  - Geyser every: a burst on the stretch for Geyser x the damage between eruptions. Extra
	    vents (Ring of Fire): n small vents erupt in turn between the main eruptions at Extra
	    vent x size (no bombs). Lava Bombs: each eruption also throws Tuning Lava bombs bombs at
	    the biggest dinos in range for Lava bomb x the damage. Boss erupt: erupts at once when a
	    boss enters range, once per boss. Ash Blanket: after each eruption the side's dinos miss
	    Side throw miss % of throws for Tuning Ash s. Supervolcano (once per round played,
	    AutoFire): every dino on the side is in lava for Tuning Supervolcano s.
	    Rumble (Slow %): dinos in range while no lava is down. Knockback at the eruption (small dinos).
	  - Crust (Obsidian): after each flow its stretch is crust for Tuning Crust s: dinos on it
	    are slowed Tuning Crust slow %, lose armour (Strips armour), take Crust DPS (x level),
	    miss Throw miss % of throws, walk Maze studs further (Glass Maze), and when the flow ends
	    every dino on it is hard-stopped Freeze flow s once (Frozen Fire; bosses x Boss hard stop
	    x). Obsidian Wall: once a round (AutoFire) a wall at the stretch's far end (the Resin
	    Wall's rule). Obsidian Armour: towers in range take Throw resist % less from throws.
	Own side only; the server (Towers) erupts, shoves and draws it (rule 4).
]]

local Config = require(script.Parent.Config)

local Vent = {}

type Stats = {
	damage: number,
	rate: number,
	flowSeconds: number,
	flowLengthMult: number,
	geyserEvery: number,
	extraVents: number,
	crust: boolean,
}

export type Flow = { from: number, to: number, ends: number, dps: number, frozen: boolean }

-- The stretch (from, to) along a track `length` long: Flow length x Flow length x, centred on `at`.
function Vent.stretch(stats: Stats, at: number, length: number): (number, number)
	local half = Config.Tuning.FlowLengthStuds * stats.flowLengthMult / 2
	return math.max(0, at - half), math.min(length, at + half)
end

-- s the lava stays down.
function Vent.flowSeconds(stats: Stats): number
	return if stats.flowSeconds > 0 then stats.flowSeconds else Config.Tuning.FlowS
end

-- The lava's burn a second (before the tower level): Flow burn DPS x Damage / base Damage.
function Vent.flowBurn(stats: Stats, baseDamage: number): number
	return Config.Tuning.FlowBurnDPS * stats.damage / math.max(1e-9, baseDamage)
end

function Vent.inStretch(at: number, from: number, to: number): boolean
	return at >= from and at <= to
end

-- The shove: a dino `offset` studs off its path moves Flow shove studs/s further, up to Shove
-- max. Bosses aren't shoved.
function Vent.shove(offset: number, dt: number, boss: boolean): number
	if boss then
		return offset
	end
	return math.min(Config.Tuning.ShoveMaxStuds, offset + Config.Tuning.FlowShoveStudsS * dt)
end

-- Seconds a shoved dino needs to walk back to its path (it doesn't move along meanwhile).
function Vent.rejoinSeconds(offset: number, speed: number): number
	return if speed > 0 then offset / speed else 0
end

-- Overlapping flows of two vents: the strongest only.
function Vent.strongest(flows: { Flow }, at: number, now: number): Flow?
	local best: Flow? = nil
	for _, f in flows do
		if f.ends > now and at >= f.from and at <= f.to and (best == nil or f.dps > best.dps) then
			best = f
		end
	end
	return best
end

-- Frozen Fire: true once per flow, the moment it ends.
function Vent.freezeAtEnd(flow: Flow, now: number): boolean
	if flow.frozen or now < flow.ends then
		return false
	end
	flow.frozen = true
	return true
end

-- The crust after a flow: (ends, slow %).
function Vent.crust(stats: Stats, flowEnds: number): (number, number)
	if not stats.crust then
		return flowEnds, 0
	end
	return flowEnds + Config.Tuning.CrustS, Config.Tuning.CrustSlow
end

-- Glass Maze: seconds a crossing dino loses walking Maze studs further.
function Vent.mazeSeconds(studs: number, speed: number): number
	return if speed > 0 then studs / speed else 0
end

-- Ring of Fire: s after a main eruption each of n small vents erupts (in turn, evenly between).
function Vent.ringTimes(n: number, gap: number): { number }
	local out = {}
	for i = 1, math.floor(n) do
		out[i] = gap * i / (math.floor(n) + 1)
	end
	return out
end

function Vent.extraSize(): number
	return Config.Tuning.ExtraVentX
end

function Vent.geyserDamage(stats: Stats): number
	return stats.damage * Config.Tuning.GeyserX
end

-- Lava Bombs: the bombs' targets, the biggest dinos first (`sizes` per dino; a boss first).
function Vent.bombTargets(dinos: { { sizes: number, boss: boolean? } }): ({ number }, number)
	local order = {}
	for i in dinos do
		table.insert(order, i)
	end
	table.sort(order, function(a, b)
		local da, db = dinos[a], dinos[b]
		if (da.boss == true) ~= (db.boss == true) then
			return da.boss == true
		end
		return da.sizes > db.sizes
	end)
	local out = {}
	for k = 1, math.min(#order, Config.Tuning.LavaBombs) do
		out[k] = order[k]
	end
	return out, Config.Tuning.LavaBombX
end

-- Pressure Valve: erupt now for this boss? Once per boss (`seen` is the vent's set).
function Vent.bossErupts(seen: { [any]: boolean }, boss: any): boolean
	if seen[boss] then
		return false
	end
	seen[boss] = true
	return true
end

-- Ash Blanket: the ash lasts this long after each eruption.
function Vent.ashSeconds(): number
	return Config.Tuning.AshS
end

-- Supervolcano: every dino on the side is in lava this long.
function Vent.supervolcanoSeconds(): number
	return Config.Tuning.SupervolcanoS
end

return Vent
