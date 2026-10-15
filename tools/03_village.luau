-- Layer 3: the mud-brick village (Najdi style houses with stepped parapets)
--
-- HOW TO RUN
--   Run tools/01_terrain_oasis.luau first (it creates the flat ground at y = 4).
--   Then: Studio > View > Command Bar, paste this whole script, press Enter (Edit mode).
--   Safe to rerun: it deletes the old Map/Zones/2_Village folder and rebuilds it.
--
-- WHAT YOU GET
--   About 18 houses on a grid of alleys (12 studs wide), each with an open door,
--   faux windows, flat roof with stepped triangular parapets, a floor,
--   some with a dim hanging lantern, plus rubble in the alleys.
--   A main street runs north-south through the middle (x = 0) from the oasis.
--
-- Change the numbers below for a different village. Same SEED = same village.

-- ===== settings =====
local GROUND_Y = 4
local SEED = 5150
local WALL_T = 2
local DOOR_W, DOOR_H = 7, 10
local COLUMNS = { -72, -24, 24, 72 }
local ROWS = { -96, -48, 0, 48, 96 }
local ALLEY_X = { -96, -48, 0, 48, 96 }
local ALLEY_Z = { -120, -72, -24, 24, 72, 120 }
local LANTERN_HOUSES = 5
local RUBBLE_COUNT = 90
-- ====================

local function child(parent: Instance, name: string): Instance
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

local function freshFolder(name: string, parent: Instance): Folder
	local old = parent:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local map = child(workspace, "Map")
local zones = child(map, "Zones")
local zone = freshFolder("2_Village", zones)
local structures = child(zone, "Structures")
local rubbleFolder = child(zone, "Rubble")
local rng = Random.new(SEED)

local function jitter(c: Color3, amt: number): Color3
	local d = rng:NextNumber(-amt, amt)
	return Color3.new(math.clamp(c.R + d, 0, 1), math.clamp(c.G + d, 0, 1), math.clamp(c.B + d, 0, 1))
end

local function buildHouse(index: number, cx: number, cz: number, withLamp: boolean)
	local model = Instance.new("Model")
	model.Name = "House_" .. index

	local w = rng:NextInteger(20, 30)
	local d = rng:NextInteger(20, 30)
	local h = rng:NextInteger(14, 18)
	local T = WALL_T
	local P = 1.2 -- parapet thickness
	local yaw = rng:NextInteger(0, 3) * (math.pi / 2)
	local base = CFrame.new(cx, GROUND_Y, cz) * CFrame.Angles(0, yaw, 0)
	local wallColor = jitter(Color3.fromRGB(178, 144, 106), 0.04)
	local roofColor = Color3.fromRGB(104, 82, 62)
	local WALL_MAT = Enum.Material.Sandstone

	local function block(name: string, lcf: CFrame, size: Vector3, color: Color3, material: Enum.Material, solid: boolean)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.Size = size
		p.CFrame = base * lcf
		p.Color = color
		p.Material = material
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.CanTouch = false
		if not solid then
			p.CanCollide = false
			p.CanQuery = false
		end
		p.Parent = model
		return p
	end

	local iw = w - 2 * T

	-- walls
	block("WallL", CFrame.new(-(w / 2 - T / 2), h / 2, 0), Vector3.new(T, h, d), wallColor, WALL_MAT, true)
	block("WallR", CFrame.new(w / 2 - T / 2, h / 2, 0), Vector3.new(T, h, d), wallColor, WALL_MAT, true)
	block("WallB", CFrame.new(0, h / 2, -(d / 2 - T / 2)), Vector3.new(iw, h, T), wallColor, WALL_MAT, true)

	-- front wall with a door opening
	local gx = rng:NextNumber(-3, 3)
	local fz = d / 2 - T / 2
	local leftW = iw / 2 + gx - DOOR_W / 2
	local rightW = iw / 2 - gx - DOOR_W / 2
	block("WallFL", CFrame.new((-iw / 2 + (gx - DOOR_W / 2)) / 2, h / 2, fz), Vector3.new(leftW, h, T), wallColor, WALL_MAT, true)
	block("WallFR", CFrame.new(((gx + DOOR_W / 2) + iw / 2) / 2, h / 2, fz), Vector3.new(rightW, h, T), wallColor, WALL_MAT, true)
	block("Lintel", CFrame.new(gx, DOOR_H + (h - DOOR_H) / 2, fz), Vector3.new(DOOR_W, h - DOOR_H, T), wallColor, WALL_MAT, true)

	-- roof and floor
	block("Roof", CFrame.new(0, h + 0.5, 0), Vector3.new(w, 1, d), roofColor, Enum.Material.Concrete, true)
	block("Floor", CFrame.new(0, 0.2, 0), Vector3.new(iw, 0.4, d - 2 * T), Color3.fromRGB(96, 80, 64), Enum.Material.Slate, true)

	-- parapet band
	local bandY = h + 1 + 0.7
	block("ParapetBack", CFrame.new(0, bandY, -(d / 2 - P / 2)), Vector3.new(w, 1.4, P), wallColor, WALL_MAT, true)
	block("ParapetFront", CFrame.new(0, bandY, d / 2 - P / 2), Vector3.new(w, 1.4, P), wallColor, WALL_MAT, true)
	block("ParapetLeft", CFrame.new(-(w / 2 - P / 2), bandY, 0), Vector3.new(P, 1.4, d - 2 * P), wallColor, WALL_MAT, true)
	block("ParapetRight", CFrame.new(w / 2 - P / 2, bandY, 0), Vector3.new(P, 1.4, d - 2 * P), wallColor, WALL_MAT, true)

	-- stepped triangular merlons (Najdi crenellations)
	local function merlons(len: number, alongX: boolean, fixed: number)
		local count = math.floor(len / 4.6)
		local step = len / count
		for k = 1, count do
			local pos = -len / 2 + (k - 0.5) * step
			local midY = h + 1 + 1.4 + 0.7
			local topY = h + 1 + 2.8 + 0.7
			if alongX then
				block("MerlonMid", CFrame.new(pos, midY, fixed), Vector3.new(2.2, 1.4, P), wallColor, WALL_MAT, false)
				block("MerlonTop", CFrame.new(pos, topY, fixed), Vector3.new(1.0, 1.4, P), wallColor, WALL_MAT, false)
			else
				block("MerlonMid", CFrame.new(fixed, midY, pos), Vector3.new(P, 1.4, 2.2), wallColor, WALL_MAT, false)
				block("MerlonTop", CFrame.new(fixed, topY, pos), Vector3.new(P, 1.4, 1.0), wallColor, WALL_MAT, false)
			end
		end
	end
	merlons(w, true, -(d / 2 - P / 2))
	merlons(w, true, d / 2 - P / 2)
	merlons(d - 2 * P, false, -(w / 2 - P / 2))
	merlons(d - 2 * P, false, w / 2 - P / 2)

	-- faux windows (dark insets on the outside)
	local dark = Color3.fromRGB(18, 14, 12)
	block("WindowL", CFrame.new(-w / 2 - 0.05, 9, rng:NextNumber(-d / 4, d / 4)), Vector3.new(0.3, 3.6, 2.4), dark, Enum.Material.Slate, false)
	block("WindowR", CFrame.new(w / 2 + 0.05, 9, rng:NextNumber(-d / 4, d / 4)), Vector3.new(0.3, 3.6, 2.4), dark, Enum.Material.Slate, false)
	block("WindowB", CFrame.new(rng:NextNumber(-w / 4, w / 4), 9, -d / 2 - 0.05), Vector3.new(2.4, 3.6, 0.3), dark, Enum.Material.Slate, false)

	-- open wooden door leaf
	local sign = (rng:NextInteger(0, 1) == 0) and 1 or -1
	local angle = math.rad(rng:NextInteger(65, 100)) * sign
	block(
		"Door",
		CFrame.new(gx - DOOR_W / 2, 4.9, fz) * CFrame.Angles(0, angle, 0) * CFrame.new(3.3, 0, 0),
		Vector3.new(6.6, 9.6, 0.5),
		Color3.fromRGB(70, 48, 32),
		Enum.Material.WoodPlanks,
		true
	)

	-- dim hanging lantern inside
	if withLamp then
		block("LanternCord", CFrame.new(0, h - 1.02, 0), Vector3.new(0.12, 2.0, 0.12), Color3.fromRGB(30, 26, 24), Enum.Material.Metal, false)
		local bulb = block("LanternBulb", CFrame.new(0, h - 2.5, 0), Vector3.new(0.7, 0.9, 0.7), Color3.fromRGB(255, 190, 110), Enum.Material.Neon, false)
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 170, 90)
		light.Brightness = 0.9
		light.Range = 20
		light.Shadows = true
		light.Parent = bulb
	end

	model.Parent = structures
end

-- ---------- choose plots and which houses get lanterns ----------
local plots = {}
for _, cx in ipairs(COLUMNS) do
	for _, cz in ipairs(ROWS) do
		-- leave the central plaza open
		if not (cz == 0 and (cx == -24 or cx == 24)) then
			table.insert(plots, Vector2.new(cx, cz))
		end
	end
end

local lampSet = {}
local lamps = 0
while lamps < math.min(LANTERN_HOUSES, #plots) do
	local i = rng:NextInteger(1, #plots)
	if not lampSet[i] then
		lampSet[i] = true
		lamps += 1
	end
end

for i, plot in ipairs(plots) do
	buildHouse(i, plot.X, plot.Y, lampSet[i] == true)
	if i % 3 == 0 then
		task.wait()
	end
end

-- ---------- rubble in the alleys ----------
for _ = 1, RUBBLE_COUNT do
	local x, z
	if rng:NextNumber() < 0.5 then
		x = ALLEY_X[rng:NextInteger(1, #ALLEY_X)] + rng:NextNumber(-4, 4)
		z = rng:NextNumber(-125, 125)
	else
		z = ALLEY_Z[rng:NextInteger(1, #ALLEY_Z)] + rng:NextNumber(-4, 4)
		x = rng:NextNumber(-125, 125)
	end
	local s = rng:NextNumber(1, 3)
	local rock = Instance.new("Part")
	rock.Name = "Rubble"
	rock.Anchored = true
	rock.Size = Vector3.new(s * rng:NextNumber(0.8, 1.6), s * rng:NextNumber(0.5, 1), s * rng:NextNumber(0.8, 1.6))
	rock.Material = Enum.Material.Sandstone
	rock.Color = jitter(Color3.fromRGB(165, 132, 98), 0.05)
	rock.CFrame = CFrame.new(x, GROUND_Y + rock.Size.Y * 0.25, z)
		* CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, math.pi * 2), rng:NextNumber(-0.4, 0.4))
	rock.CanCollide = false
	rock.CanTouch = false
	rock.CanQuery = false
	rock.Parent = rubbleFolder
end

print(("Layer 3 done: %d houses built."):format(#plots))
