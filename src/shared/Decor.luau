--[[
	Campsite decorations (PLAN 10e T143c, DECISIONS #415): the seven inert models a player
	puts on their Campsite's three decoration spots (Shared/Skins `decor`, Server/Wardrobe
	builds them from the Decor_<i> attributes). Visual only: every part anchored, can't be
	touched, hit or clicked (CanTouch / CanQuery false), no scripts, no seats, no sounds, no
	lights; nothing here is ever built in a match (Wardrobe builds on Outpost Campsites only).

	  build(key, look, at, extra)   the model for decoration `key` standing at CFrame `at`
	                                (its base on the ground), painted with the sheet's colour,
	                                accent and material (`look`, Skins.look). `extra`:
	                                flag = the cloth colour (Hunter's Flag: your worn Tower
	                                flag colour), poster = the Wanted Poster's text.
	  posterText(name, cleared, round)   the Wanted Poster: your name and best hunt, the
	                                hardest difficulty you cleared (display name, or nil) and
	                                your best round, from the saved profile.
	  SIZE                          each model's footprint (studs, x by z) — specs keep all
	                                three spots apart.
]]

local Decor = {}

-- Footprints (x, z) in the spot's frame; every model stays inside its own.
Decor.SIZE = table.freeze({
	FIRE_PIT = Vector2.new(4, 4),
	STEPPING_STONES = Vector2.new(3, 5),
	HUNTERS_FLAG = Vector2.new(2.5, 1),
	WANTED_POSTER = Vector2.new(3, 1),
	HAMMOCK = Vector2.new(2, 5),
	ROPE_SWING = Vector2.new(4, 2),
	DINO_STATUE = Vector2.new(3, 4),
})

type Look = { colour: Color3, accent: Color3, material: Enum.Material }
export type Extra = { flag: Color3?, poster: string? }

local function block(model: Model, name: string, size: Vector3, cf: CFrame, colour: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Material = material
	p.Anchored = true
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

function Decor.posterText(name: string, cleared: string?, round: number?): string
	local best = if cleared then `{cleared} cleared` else "no clear yet"
	local r = if type(round) == "number" and round > 0 then ` · best round {math.floor(round)}` else ""
	return `WANTED\n{name}\nBest hunt: {best}{r}`
end

function Decor.build(key: string, look: Look, at: CFrame, extra: Extra?): Model?
	if not Decor.SIZE[key] then
		return nil
	end
	local m = Instance.new("Model")
	m.Name = `Decor_{key}`
	local c, a, mat = look.colour, look.accent, look.material
	local function put(name: string, size: Vector3, offset: Vector3, colour: Color3, material: Enum.Material?): Part
		return block(m, name, size, at * CFrame.new(offset), colour, material or mat)
	end
	if key == "FIRE_PIT" then
		for i = 0, 7 do
			local angle = i * math.pi / 4
			put("Stone", Vector3.new(0.9, 0.6, 0.9), Vector3.new(math.cos(angle) * 1.5, 0.3, math.sin(angle) * 1.5), c)
		end
		put("Log", Vector3.new(2, 0.4, 0.4), Vector3.new(0, 0.3, 0), Color3.fromRGB(100, 70, 45), Enum.Material.Wood)
		put("Log", Vector3.new(0.4, 0.4, 2), Vector3.new(0, 0.5, 0), Color3.fromRGB(100, 70, 45), Enum.Material.Wood)
		put("Flame", Vector3.new(0.8, 1, 0.8), Vector3.new(0, 1.1, 0), a, Enum.Material.SmoothPlastic)
	elseif key == "STEPPING_STONES" then
		for i, o in { Vector3.new(-0.6, 0.1, -1.8), Vector3.new(0.6, 0.1, -0.6), Vector3.new(-0.5, 0.1, 0.6), Vector3.new(0.5, 0.1, 1.8) } do
			put(`Stone{i}`, Vector3.new(1.4, 0.2, 1.1), o, if i % 2 == 0 then a else c)
		end
	elseif key == "HUNTERS_FLAG" then
		put("Pole", Vector3.new(0.3, 6, 0.3), Vector3.new(-1, 3, 0), c, Enum.Material.Wood)
		put("Cloth", Vector3.new(2, 1.3, 0.1), Vector3.new(0.15, 5.2, 0), if extra and extra.flag then extra.flag else a, Enum.Material.Fabric)
	elseif key == "WANTED_POSTER" then
		put("PostL", Vector3.new(0.3, 3.5, 0.3), Vector3.new(-1.3, 1.75, 0), a, Enum.Material.Wood)
		put("PostR", Vector3.new(0.3, 3.5, 0.3), Vector3.new(1.3, 1.75, 0), a, Enum.Material.Wood)
		local board = put("Board", Vector3.new(2.3, 2.2, 0.15), Vector3.new(0, 2.3, 0), c)
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
			local gui = Instance.new("SurfaceGui")
			gui.Face = face
			gui.CanvasSize = Vector2.new(230, 220)
			gui.Parent = board
			local text = Instance.new("TextLabel")
			text.Name = "Poster"
			text.Size = UDim2.fromScale(1, 1)
			text.BackgroundTransparency = 1
			text.Font = Enum.Font.Antique
			text.TextScaled = true
			text.TextColor3 = Color3.fromRGB(60, 40, 25)
			text.Text = if extra and extra.poster then extra.poster else "WANTED"
			text.Parent = gui
		end
	elseif key == "HAMMOCK" then
		put("PostA", Vector3.new(0.4, 3, 0.4), Vector3.new(0, 1.5, -2.3), a, Enum.Material.Wood)
		put("PostB", Vector3.new(0.4, 3, 0.4), Vector3.new(0, 1.5, 2.3), a, Enum.Material.Wood)
		put("Bed", Vector3.new(1.4, 0.2, 4), Vector3.new(0, 1.4, 0), c)
	elseif key == "ROPE_SWING" then
		put("PostL", Vector3.new(0.4, 4.5, 0.4), Vector3.new(-1.7, 2.25, 0), c)
		put("PostR", Vector3.new(0.4, 4.5, 0.4), Vector3.new(1.7, 2.25, 0), c)
		put("Beam", Vector3.new(3.8, 0.4, 0.4), Vector3.new(0, 4.5, 0), c)
		put("RopeL", Vector3.new(0.12, 3.2, 0.12), Vector3.new(-0.5, 2.8, 0), a, Enum.Material.Fabric)
		put("RopeR", Vector3.new(0.12, 3.2, 0.12), Vector3.new(0.5, 2.8, 0), a, Enum.Material.Fabric)
		put("Board", Vector3.new(1.4, 0.2, 0.6), Vector3.new(0, 1.2, 0), c)
	elseif key == "DINO_STATUE" then
		put("Plinth", Vector3.new(3, 0.8, 3), Vector3.new(0, 0.4, 0), c)
		put("Body", Vector3.new(1.4, 1.6, 2.2), Vector3.new(0, 2, 0.3), c)
		put("Neck", Vector3.new(0.8, 1.4, 0.8), Vector3.new(0, 3.2, -0.6), c)
		put("Head", Vector3.new(1, 0.8, 1.5), Vector3.new(0, 3.9, -1.2), c)
		put("Tail", Vector3.new(0.6, 0.6, 1.6), Vector3.new(0, 1.8, 1.2), c)
		put("Moss", Vector3.new(2.9, 0.15, 2.9), Vector3.new(0, 0.85, 0), a, Enum.Material.Grass)
	end
	m.PrimaryPart = m:FindFirstChildWhichIsA("BasePart")
	m:SetAttribute("Decoration", key)
	return m
end

return Decor
