# Luau snippets for map generation

Run in the Studio **command bar** (View > Command Bar) or as a Script in
ServerScriptService while in Edit mode via a plugin. Command bar code runs in Edit mode,
so changes persist in the place. All snippets assume they create into a Folder that is
removed first, so they can be rerun.

## Cleanup helper

```lua
local function freshFolder(name: string, parent: Instance): Folder
	local old = parent:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end
```

## Terrain: rolling hills with noise

Notes: `math.noise` returns roughly -0.5 to 0.5 and is exactly 0 at integer inputs,
so always add a non-integer offset. Terrain voxels are 4 studs.

```lua
local Terrain = workspace.Terrain
local SIZE = 256        -- studs on X and Z
local RES = 4           -- voxel size
local MAX_HEIGHT = 40   -- tallest hill in studs
local SCALE = 80        -- bigger = wider, smoother hills
local SEED = 12.37      -- change for a different map (keep a decimal part)

Terrain:Clear()

local count = 0
for x = 0, SIZE - RES, RES do
	for z = 0, SIZE - RES, RES do
		local n = math.noise(x / SCALE, z / SCALE, SEED) + 0.5
		local h = math.max(RES, math.clamp(n, 0, 1) * MAX_HEIGHT)
		h = math.floor(h / RES) * RES
		local cf = CFrame.new(x + RES / 2, h / 2, z + RES / 2)
		Terrain:FillBlock(cf, Vector3.new(RES, h, RES), Enum.Material.Grass)
		count += 1
		if count % 200 == 0 then
			task.wait()
		end
	end
end
```

Variations: make high spots `Enum.Material.Rock` (`if h > MAX_HEIGHT * 0.7`), low spots
`Enum.Material.Sand`, add `Enum.Material.Snow` caps.

## Terrain: flat arena with a lake

```lua
local Terrain = workspace.Terrain
Terrain:Clear()

-- ground slab, top surface at y = 0
Terrain:FillBlock(CFrame.new(0, -8, 0), Vector3.new(300, 16, 300), Enum.Material.Grass)

-- lake: carve then fill with water
Terrain:FillBall(Vector3.new(60, 0, 40), 30, Enum.Material.Air)
Terrain:FillBlock(CFrame.new(60, -4, 40), Vector3.new(60, 8, 60), Enum.Material.Water)
```

Tune the lake so the water surface sits slightly below the shore. Check from the side.

## Prop scatter with raycast (trees, rocks, crystals)

Put the template Models in `ServerStorage/Templates`. Each needs a PrimaryPart.

```lua
local ServerStorage = game:GetService("ServerStorage")
local templates = ServerStorage:WaitForChild("Templates")

local function freshFolder(name, parent)
	local old = parent:FindFirstChild(name)
	if old then old:Destroy() end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local folder = freshFolder("Gen_Props", workspace)
local rng = Random.new(1234)

local AREA_MIN = Vector2.new(-120, -120)
local AREA_MAX = Vector2.new(120, 120)
local COUNT = 150
local MIN_SPACING = 12
local placed = {}

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { workspace.Terrain }

local names = {}
for _, t in ipairs(templates:GetChildren()) do
	table.insert(names, t)
end

local attempts = 0
while #placed < COUNT and attempts < COUNT * 10 do
	attempts += 1
	local x = rng:NextNumber(AREA_MIN.X, AREA_MAX.X)
	local z = rng:NextNumber(AREA_MIN.Y, AREA_MAX.Y)

	local tooClose = false
	for _, p in ipairs(placed) do
		if (p - Vector2.new(x, z)).Magnitude < MIN_SPACING then
			tooClose = true
			break
		end
	end

	if not tooClose then
		local hit = workspace:Raycast(Vector3.new(x, 500, z), Vector3.new(0, -1000, 0), params)
		-- only on grass, only on gentle slopes
		if hit and hit.Material == Enum.Material.Grass and hit.Normal.Y > 0.9 then
			local model = names[rng:NextInteger(1, #names)]:Clone()
			local yaw = rng:NextNumber(0, math.pi * 2)
			model:PivotTo(CFrame.new(hit.Position) * CFrame.Angles(0, yaw, 0))
			model.Parent = folder
			table.insert(placed, Vector2.new(x, z))
		end
	end
	if attempts % 50 == 0 then task.wait() end
end
print(("Placed %d props"):format(#placed))
```

For tree and rock models, set the pivot at the base so they sit on the ground.

## Lighting and atmosphere presets

```lua
local Lighting = game:GetService("Lighting")

local function clearEffects()
	for _, c in ipairs(Lighting:GetChildren()) do
		if c:IsA("Atmosphere") or c:IsA("Sky") or c:IsA("PostEffect") then
			c:Destroy()
		end
	end
end

local function applyPreset(name: string)
	clearEffects()
	local atmo = Instance.new("Atmosphere")
	local bloom = Instance.new("BloomEffect")
	local cc = Instance.new("ColorCorrectionEffect")
	local rays = Instance.new("SunRaysEffect")

	if name == "sunny" then
		Lighting.ClockTime = 14
		Lighting.Brightness = 3
		Lighting.ExposureCompensation = 0
		atmo.Density = 0.3
		atmo.Haze = 1
		atmo.Color = Color3.fromRGB(199, 220, 255)
		bloom.Intensity = 0.3
		cc.Saturation = 0.15
	elseif name == "sunset" then
		Lighting.ClockTime = 18.2
		Lighting.Brightness = 2
		atmo.Density = 0.35
		atmo.Color = Color3.fromRGB(255, 190, 150)
		atmo.Decay = Color3.fromRGB(120, 60, 40)
		atmo.Glare = 0.5
		bloom.Intensity = 0.5
		cc.TintColor = Color3.fromRGB(255, 235, 220)
	elseif name == "horror" then
		Lighting.ClockTime = 0
		Lighting.Brightness = 0.5
		Lighting.Ambient = Color3.fromRGB(10, 10, 20)
		Lighting.OutdoorAmbient = Color3.fromRGB(15, 15, 30)
		atmo.Density = 0.6
		atmo.Haze = 2
		atmo.Color = Color3.fromRGB(40, 45, 60)
		bloom.Intensity = 0.2
		cc.Saturation = -0.3
		cc.Contrast = 0.2
	end

	atmo.Parent = Lighting
	bloom.Parent = Lighting
	cc.Parent = Lighting
	rays.Intensity = 0.1
	rays.Parent = Lighting
end

applyPreset("sunny")
```

These are starting points. Ask the user for a screenshot and adjust by feel.
Set `Lighting.Technology` (Future is the prettiest, heavier on low-end devices)
in the Properties panel.

## Checkpoint system (server Script in ServerScriptService)

Tag each checkpoint part with `Checkpoint` and give it an `Order` number attribute
(use the Tag Editor plugin or `CollectionService:AddTag`).

```lua
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local progress: { [Player]: number } = {}

local function setup(part: BasePart)
	part.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then return end
		local order = part:GetAttribute("Order") or 0
		if order > (progress[player] or 0) then
			progress[player] = order
			player.RespawnLocation = part :: any -- must be a SpawnLocation to be valid
		end
	end)
end

for _, part in ipairs(CollectionService:GetTagged("Checkpoint")) do
	setup(part)
end
CollectionService:GetInstanceAddedSignal("Checkpoint"):Connect(setup)
Players.PlayerRemoving:Connect(function(p) progress[p] = nil end)
```

`Player.RespawnLocation` only accepts a `SpawnLocation`, so make each checkpoint a
SpawnLocation (set `Neutral = true`, `Duration = 0`, `Transparency` as desired).

## Kill brick

```lua
local CollectionService = game:GetService("CollectionService")

local function setup(part: BasePart)
	part.Touched:Connect(function(hit)
		local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			hum.Health = 0
		end
	end)
end

for _, p in ipairs(CollectionService:GetTagged("KillBrick")) do setup(p) end
CollectionService:GetInstanceAddedSignal("KillBrick"):Connect(setup)
```

## Obby stage generator (platforms with fair gaps)

```lua
local function freshFolder(name, parent)
	local old = parent:FindFirstChild(name)
	if old then old:Destroy() end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local folder = freshFolder("Gen_Obby", workspace)
local rng = Random.new(777)

local STAGES = 10
local pos = Vector3.new(0, 10, 0)

for i = 1, STAGES do
	local gap = 6 + i * 0.8           -- gets harder, stay under ~70% of max jump distance
	local size = math.max(3, 8 - i * 0.4)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = Vector3.new(size, 1, size)
	p.Position = pos + Vector3.new(0, rng:NextNumber(-1, 2), -gap - size)
	p.Material = Enum.Material.SmoothPlastic
	p.Color = Color3.fromHSV((i / STAGES) * 0.8, 0.6, 1)
	p.Name = "Stage" .. i
	p.Parent = folder
	pos = p.Position
	if i % 5 == 0 then
		p.Size = Vector3.new(14, 1, 14)
		p:AddTag("CheckpointPad")
	end
end
```

Keep vertical changes within about 4 studs up and keep gaps readable on mobile.
Playtest every stage, since jump distance depends on WalkSpeed and gravity.
