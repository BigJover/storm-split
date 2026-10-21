--[[
	Big Amber (PLAN 10a T134, DECISIONS #385/#386/#394): every Amber value is the old one
	x Tuning.AmberScale (ratios unchanged), and Theme's Amber formatters.

	tools/test/amber_snapshot.json was written from the sheet BEFORE the rescale (every
	Amber value the exporter's AMBER_FIELDS / AMBER_TUNING name, 87 of them).
]]
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local Config = require(src.shared.Config)
local Theme = require(src.shared.Theme)

local SNAPSHOT = serde.decode("json", fs.readFile("tools/test/amber_snapshot.json"))
local A = Config.Tuning.AmberScale

local function current(row): any
	local block = (Config :: any)[row.block]
	if row.block == "Tuning" then
		return block[row.key]
	end
	local item = if type(row.key) == "number" then block[row.key] else block[row.key]
	return item and item[row.field]
end

test("the scale is x1000 (#394)", function()
	eq(A, 1000)
	eq(#SNAPSHOT.values, 87, "every Amber value in the snapshot")
end)

test("every Amber value is exactly the old one x the scale (ratios unchanged)", function()
	for _, row in SNAPSHOT.values do
		local where = `{row.block}.{row.key}{if row.field then "." .. row.field else ""}`
		local now = current(row)
		eq(type(now), "number", `{where} exists`)
		eq(now, row.old * A, where)
		eq(now / A, row.old, `{where} / scale`)
	end
end)

test("the unlock-all total and a Normal clear match #394 (5.325M, 100K)", function()
	local total = 0
	for _, t in Config.Towers do
		total += t.unlockCost
	end
	for _, h in Config.Heroes do
		total += h.unlockCost
	end
	eq(total, 5325000, "unlock-all")
	eq(Config.Difficulties.NORMAL.clearReward, 100000, "Normal clear")
	-- the same number of Normal clears as before (#355: 53.25)
	eq(total / Config.Difficulties.NORMAL.clearReward, 53.25, "clears to unlock all")
end)

test("formatAmber: under 1,000 as is; K / M / B, one decimal, '.0' dropped (#394 examples)", function()
	local cases = {
		{ 0, "0" }, { 7, "7" }, { 999, "999" }, { 999.9, "999" },
		{ 1000, "1K" }, { 1099, "1K" }, { 1100, "1.1K" }, { 12500, "12.5K" }, { 100000, "100K" },
		{ 999999, "999.9K" }, { 1000000, "1M" }, { 1250000, "1.2M" }, { 1299999, "1.2M" },
		{ 5325000, "5.3M" }, { 999999999, "999.9M" }, { 1000000000, "1B" }, { 2500000000000, "2500B" },
	}
	for _, c in cases do
		eq(Theme.formatAmber(c[1]), c[2], `formatAmber({c[1]})`)
	end
end)

test("formatAmber rounds DOWN: it never shows more than you have", function()
	for _, n in { 1999, 12599, 999999, 1999999, 5399999, 1999999999 } do
		local shown = Theme.formatAmber(n)
		local head, unit = string.match(shown, "^([%d.]+)([KMB]?)$")
		local mult = if unit == "K" then 1e3 elseif unit == "M" then 1e6 elseif unit == "B" then 1e9 else 1
		ok(tonumber(head) * mult <= n, `{n} shows {shown}, not more`)
	end
	eq(Theme.formatAmber(-12500), "-12.5K", "negative")
	eq(Theme.formatAmber(0 / 0), "0", "NaN")
end)

test("amberExact groups thousands; amberPrice is short only when exact", function()
	eq(Theme.amberExact(0), "0")
	eq(Theme.amberExact(999), "999")
	eq(Theme.amberExact(1000), "1,000")
	eq(Theme.amberExact(5325000), "5,325,000")
	eq(Theme.amberExact(1250000.7), "1,250,000", "floored")
	eq(Theme.amberPrice(300000), "300K")
	eq(Theme.amberPrice(15000), "15K")
	eq(Theme.amberPrice(12500), "12.5K")
	eq(Theme.amberPrice(12550), "12,550", "would round: exact")
	eq(Theme.amberPrice(1250000), "1,250,000", "1.2M would hide 50K: exact")
	eq(Theme.amberPrice(1200000), "1.2M")
	eq(Theme.amberPrice(950), "950")
	-- every price in the sheet today is shown exactly in short form
	for key, t in Config.Towers do
		eq(Theme.amberPrice(t.unlockCost), Theme.formatAmber(t.unlockCost), `{key} unlock short and exact`)
	end
	for i, m in Config.Mastery do
		eq(Theme.amberPrice(m.coreCost), Theme.formatAmber(m.coreCost), `mastery {i} short and exact`)
	end
end)
