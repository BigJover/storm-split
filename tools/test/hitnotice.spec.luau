--[[
	Shared/HitNotice: the private "Raptor · Slash −4" line (DECISIONS #39).
]]

local HitNotice = require(src.shared.HitNotice)

test("text", function()
	eq(HitNotice.text(HitNotice.merge(nil, "Raptor", "Slash", 4, 0)), "Raptor · Slash −4")
	eq(HitNotice.text(HitNotice.merge(nil, "Pachycephalosaurus", "Skull Toss", 5, 0)), "Pachycephalosaurus · Skull Toss −5", "ranged too")
	eq(HitNotice.text(HitNotice.merge(nil, "Compy", "Nip", 0.5, 0)), "Compy · Nip −1", "never shows 0")
	eq(HitNotice.text(HitNotice.merge(nil, "T-Rex", "Chomp", 27.5, 0)), "T-Rex · Chomp −28", "rounded")
end)

test("a repeat of the same attack adds up while showing", function()
	local s = HitNotice.merge(nil, "Raptor", "Slash", 4, 10)
	s = HitNotice.merge(s, "Raptor", "Slash", 4, 10.8)
	eq(HitNotice.text(s), "Raptor · Slash −8")
	s = HitNotice.merge(s, "Raptor", "Slash", 4, 12.2) -- 1.4s after the last: still showing
	eq(s.total, 12, "the fade counts from the last hit")
end)

test("a new attack replaces the line; an old line starts over", function()
	local s = HitNotice.merge(nil, "Raptor", "Slash", 4, 0)
	s = HitNotice.merge(s, "Compy", "Nip", 2, 0.5)
	eq(HitNotice.text(s), "Compy · Nip −2", "another dino replaces it")
	s = HitNotice.merge(s, "Compy", "Kick", 3, 0.6)
	eq(s.total, 3, "another attack replaces it")
	s = HitNotice.merge(s, "Compy", "Kick", 3, 0.6 + HitNotice.FADE)
	eq(s.total, 3, "after the fade it starts over")
end)

test("visible for FADE seconds after the last hit", function()
	eq(HitNotice.FADE, 1.5)
	local s = HitNotice.merge(nil, "Raptor", "Slash", 4, 0)
	eq(HitNotice.visible(s, 1.4), true)
	eq(HitNotice.visible(s, 1.5), false)
	eq(HitNotice.visible(nil, 0), false)
end)
