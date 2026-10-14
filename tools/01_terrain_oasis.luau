-- Layer 1: terrain, oasis pond, palms, campfire, spawn, night lighting
-- Map: "الديرة المهجورة" (Saudi heritage horror)
--
-- HOW TO RUN
--   1. Open a new Baseplate in Roblox Studio (delete the default Baseplate part).
--   2. View > Command Bar, paste this whole script, press Enter. (Edit mode, not Play.)
--   3. Wait until the Output window prints "Layer 1 done". It takes a little while.
--
-- WARNING: this clears ALL terrain in the place. It is safe to rerun.
-- Coordinates: map is centered at (0,0). North = -Z (village and fort), South = +Z (oasis, spawn).

local Lighting = game:GetService("Lighting")
local Terrain = workspace.Terrain

-- ===== settings you can change =====
local SIZE = 600            -- map width and length in studs
local RES = 8               -- terrain cell size; use 4 for smoother dunes (slower)
local SEED = 31.7           -- change the number for different dunes (keep a decimal)
local PLATEAU_Y = 4         -- flat ground height where the village will be built
local DUNE_HEIGHT = 28      -- height of the surrounding dunes
local DUNE_SCALE = 140      -- bigger = wider dunes
local OASIS = Vector2.new(0, 220) -- pond center (x, z)
local PALM_COUNT = 24
local PALM_SEED = 2024
-- ===================================

local function smoothstep(a: number, b: number, x: number): number
	local t = math.clamp((x - a) / (b - a), 0, 1)
	return t * t * (3 - 2 * t)
end

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

-- ---------- folders ----------
local map = child(workspace, "Map")
local zones = child(map, "Zones")
local zone = freshFolder("1_Oasis", zones)
local props = child(zone, "Props")
local gameplay = child(zone, "Gameplay")

-- ---------- terrain ----------
local function heightAt(x: number, z: number): (number, number)
	local n = math.clamp(math.noise(x / DUNE_SCALE, z / DUNE_SCALE, SEED) + 0.5, 0, 1)
	local dBox = math.max(math.abs(x), math.abs(z))
	local inner = 1 - smoothstep(230, 285, dBox) -- 1 inside the flat plateau
	local h = n * DUNE_HEIGHT * (1 - inner) + PLATEAU_Y * inner
	h += smoothstep(270, 300, dBox) * 22 -- dune wall around the map edge
	local od = (Vector2.new(x, z) - OASIS).Magnitude
	local t = 1 - smoothstep(25, 50, od) -- pond depression
	h = h * (1 - t) + (-4) * t
	return h, od
end

local function materialAt(h: number, od: number): Enum.Material
	if od < 30 then
		return Enum.Material.Mud
	elseif od < 62 then
		return Enum.Material.Grass
	elseif h > 30 then
		return Enum.Material.Sandstone
	end
	return Enum.Material.Sand
end

Terrain:Clear()
local HALF = SIZE / 2
local BOTTOM = -20
local count = 0
for x = -HALF, HALF - RES, RES do
	for z = -HALF, HALF - RES, RES do
		local cx, cz = x + RES / 2, z + RES / 2
		local h, od = heightAt(cx, cz)
		local top = math.max(h, BOTTOM + 2)
		local height = top - BOTTOM
		Terrain:FillBlock(
			CFrame.new(cx, BOTTOM + height / 2, cz),
			Vector3.new(RES, height, RES),
			materialAt(h, od)
		)
		count += 1
		if count % 150 == 0 then
			task.wait()
		end
	end
end

-- pond water (surface at y = 0)
Terrain:FillCylinder(CFrame.new(OASIS.X, -2, OASIS.Y), 4, 34, Enum.Material.Water)
Terrain.WaterColor = Color3.fromRGB(30, 70, 70)
Terrain.WaterTransparency = 0.8
Terrain.WaterWaveSize = 0.1
Terrain.WaterWaveSpeed = 4
Terrain.WaterReflectance = 0.6

-- ---------- palms ----------
local function makePalm(base: Vector3, rng: Random, parent: Instance)
	local model = Instance.new("Model")
	model.Name = "Palm"

	local segments = 6
	local totalHeight = rng:NextNumber(22, 34)
	local segH = totalHeight / segments
	local cf = CFrame.new(base) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	local bend = rng:NextNumber(0.02, 0.06)

	for i = 1, segments do
		local radius = 1.5 - 0.13 * i
		local trunk = Instance.new("Part")
		trunk.Name = "Trunk"
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Size = Vector3.new(segH + 0.4, radius * 2, radius * 2)
		trunk.Material = Enum.Material.Wood
		trunk.Color = Color3.fromRGB(104, 78, 54)
		trunk.Anchored = true
		trunk.CanTouch = false
		trunk.CFrame = cf * CFrame.new(0, segH / 2, 0) * CFrame.Angles(0, 0, math.pi / 2)
		trunk.Parent = model
		cf = cf * CFrame.new(0, segH, 0) * CFrame.Angles(bend, 0, 0)
	end

	local FROND_COUNT = 9
	for k = 1, FROND_COUNT do
		local frondLen = rng:NextNumber(11, 15)
		local frond = Instance.new("Part")
		frond.Name = "Frond"
		frond.Size = Vector3.new(0.5, 0.15, frondLen)
		frond.Material = Enum.Material.Grass
		frond.Color = Color3.fromRGB(48, 74, 44)
		frond.Anchored = true
		frond.CanCollide = false
		frond.CanTouch = false
		frond.CanQuery = false
		frond.CFrame = cf
			* CFrame.Angles(0, (k / FROND_COUNT) * math.pi * 2, 0)
			* CFrame.Angles(math.rad(rng:NextNumber(18, 32)), 0, 0)
			* CFrame.new(0, 0, frondLen / 2)
		frond.Parent = model
	end

	model.Parent = parent
end

local rng = Random.new(PALM_SEED)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { Terrain }

local placed, attempts = 0, 0
while placed < PALM_COUNT and attempts < PALM_COUNT * 12 do
	attempts += 1
	local angle = rng:NextNumber(0, math.pi * 2)
	local radius = rng:NextNumber(40, 68)
	local x = OASIS.X + math.cos(angle) * radius
	local z = OASIS.Y + math.sin(angle) * radius
	if math.abs(x) < HALF - 12 and math.abs(z) < HALF - 12 then
		local hit = workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -400, 0), rayParams)
		if hit and hit.Normal.Y > 0.85 and hit.Position.Y > 0 then
			makePalm(hit.Position - Vector3.new(0, 0.5, 0), rng, props)
			placed += 1
		end
	end
	if attempts % 20 == 0 then
		task.wait()
	end
end

-- ---------- campfire (safe zone) ----------
local function makeCampfire(pos: Vector3, parent: Instance)
	local model = Instance.new("Model")
	model.Name = "Campfire"
	for i = 1, 8 do
		local a = (i / 8) * math.pi * 2
		local rock = Instance.new("Part")
		rock.Size = Vector3.new(1.6, 1.2, 1.6)
		rock.Material = Enum.Material.Slate
		rock.Color = Color3.fromRGB(90, 85, 80)
		rock.Anchored = true
		rock.CanTouch = false
		rock.CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * 2.4, 0.5, math.sin(a) * 2.4))
			* CFrame.Angles(0, a, 0)
		rock.Parent = model
	end
	for i = 1, 3 do
		local log = Instance.new("Part")
		log.Size = Vector3.new(3.5, 0.7, 0.7)
		log.Material = Enum.Material.Wood
		log.Color = Color3.fromRGB(70, 48, 30)
		log.Anchored = true
		log.CanTouch = false
		log.CFrame = CFrame.new(pos + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, i * 1.05, math.rad(12))
		log.Parent = model
	end
	local core = Instance.new("Part")
	core.Name = "FireCore"
	core.Size = Vector3.new(1, 1, 1)
	core.Transparency = 1
	core.Anchored = true
	core.CanCollide = false
	core.CanTouch = false
	core.CanQuery = false
	core.Position = pos + Vector3.new(0, 1.5, 0)
	core.Parent = model

	local fire = Instance.new("Fire")
	fire.Size = 7
	fire.Heat = 8
	fire.Color = Color3.fromRGB(255, 150, 50)
	fire.SecondaryColor = Color3.fromRGB(200, 60, 20)
	fire.Parent = core

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 160, 80)
	light.Brightness = 2
	light.Range = 32
	light.Shadows = true
	light.Parent = core

	model.Parent = parent
end

makeCampfire(Vector3.new(0, PLATEAU_Y, 160), props)

-- ---------- spawn ----------
local spawn = Instance.new("SpawnLocation")
spawn.Name = "MainSpawn"
spawn.Anchored = true
spawn.Neutral = true
spawn.Size = Vector3.new(10, 1, 10)
spawn.Position = Vector3.new(0, PLATEAU_Y + 0.5, 172)
spawn.Transparency = 1
spawn.Parent = gameplay

-- ---------- night lighting ----------
for _, c in ipairs(Lighting:GetChildren()) do
	if c.Name:sub(1, 4) == "Gen_" then
		c:Destroy()
	end
end

Lighting.ClockTime = 23.5
Lighting.Brightness = 0.6
Lighting.Ambient = Color3.fromRGB(20, 24, 40)
Lighting.OutdoorAmbient = Color3.fromRGB(35, 42, 68)
Lighting.ExposureCompensation = 0.2
Lighting.GlobalShadows = true

local atmo = Instance.new("Atmosphere")
atmo.Name = "Gen_Atmosphere"
atmo.Density = 0.45
atmo.Haze = 1.8
atmo.Color = Color3.fromRGB(70, 85, 120)
atmo.Decay = Color3.fromRGB(20, 25, 45)
atmo.Glare = 0
atmo.Parent = Lighting

local bloom = Instance.new("BloomEffect")
bloom.Name = "Gen_Bloom"
bloom.Intensity = 0.35
bloom.Size = 24
bloom.Threshold = 1.2
bloom.Parent = Lighting

local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "Gen_ColorCorrection"
cc.Saturation = -0.1
cc.Contrast = 0.15
cc.TintColor = Color3.fromRGB(225, 235, 255)
cc.Parent = Lighting

print(("Layer 1 done. Palms placed: %d"):format(placed))
