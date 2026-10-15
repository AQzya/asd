-- Layer 4: the creature "أم الدويس" (Umm al-Duwais) - walking AI that hunts the players
--
-- HOW TO RUN
--   Studio > View > Command Bar, paste this whole script, press Enter (Edit mode, not Play).
--   It installs two scripts. The creature appears only when you PRESS PLAY (it is built at runtime).
--   Safe to rerun: it replaces the old copies.
--
-- HOW SHE BEHAVES (my game design, not a faithful retelling of the folk tale)
--   Patrol  : walks between alley crossings in the village.
--   Notices : by SIGHT (clear line of view within range; much farther if your flashlight is on)
--             or by SOUND (running is loud, walking is quiet, standing still is silent).
--   Chase   : runs faster than you walk, but slower than your sprint.
--   Safe zone: nobody within SAFE_RADIUS of the campfire can be targeted.
--   Catch   : if she reaches you, you die and respawn.
--
-- Tune the numbers at the top of the AI script after installing.

local StarterPlayer = game:GetService("StarterPlayer")
local ServerScriptService = game:GetService("ServerScriptService")

local function remove(parent: Instance, name: string)
	local old = parent:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

local function makeScript(className: string, name: string, parent: Instance, source: string)
	remove(parent, name)
	local s = Instance.new(className)
	s.Name = name
	s.Source = source
	s.Parent = parent
end

-- =====================================================================
-- Server: builds the creature and runs the AI
-- =====================================================================
local AI_SRC = [==[
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local CollectionService = game:GetService("CollectionService")

-- ===== settings =====
local GROUND_Y = 4
local SPAWN_POS = Vector3.new(0, 10, -150)  -- north end of the village
local SCALE = 1.55                          -- how tall she is
local PATROL_SPEED = 9
local CHASE_SPEED = 18                      -- player walks 14, sprints 22
local SIGHT_RANGE = 55
local SIGHT_RANGE_LIGHT = 95                -- when the player's flashlight is on
local HEAR_RUN = 70
local HEAR_WALK = 22
local KILL_DISTANCE = 5
local LOSE_INTEREST_AFTER = 6               -- seconds
local SAFE_CENTER = Vector3.new(0, GROUND_Y, 160)  -- the campfire
local SAFE_RADIUS = 38
-- ====================

local TAG = "UmmAlDuwais"

-- ---------- build an R6 style rig from parts ----------
local function newPart(name, size, color, parent, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function motor(name, part0, part1, c0, c1)
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = part0
	m.Part1 = part1
	m.C0 = c0
	m.C1 = c1
	m.Parent = part0
end

local function decor(part0, part1, c0)
	part1.CanCollide = false
	part1.Massless = true
	local w = Instance.new("Weld")
	w.Part0 = part0
	w.Part1 = part1
	w.C0 = c0
	w.Parent = part1
end

local function buildCreature()
	local model = Instance.new("Model")
	model.Name = "UmmAlDuwais"

	local black = Color3.fromRGB(14, 14, 18)
	local pale = Color3.fromRGB(226, 216, 206)

	local hrp = newPart("HumanoidRootPart", Vector3.new(2, 2, 1), pale, model)
	hrp.Transparency = 1
	local torso = newPart("Torso", Vector3.new(2, 2, 1), black, model, Enum.Material.Fabric)
	local head = newPart("Head", Vector3.new(2, 1, 1), pale, model)
	local armR = newPart("Right Arm", Vector3.new(1, 2, 1), black, model, Enum.Material.Fabric)
	local armL = newPart("Left Arm", Vector3.new(1, 2, 1), black, model, Enum.Material.Fabric)
	local legR = newPart("Right Leg", Vector3.new(1, 2, 1), black, model, Enum.Material.Fabric)
	local legL = newPart("Left Leg", Vector3.new(1, 2, 1), black, model, Enum.Material.Fabric)

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Head
	mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	mesh.Parent = head

	local rootRot = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)
	motor("RootJoint", hrp, torso, rootRot, rootRot)
	motor("Neck", torso, head, CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), CFrame.new(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0))
	motor("Right Shoulder", torso, armR, CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0))
	motor("Left Shoulder", torso, armL, CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CFrame.new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))
	motor("Right Hip", torso, legR, CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), CFrame.new(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0))
	motor("Left Hip", torso, legL, CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CFrame.new(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))

	-- long black robe over the hips, long hair, glowing eyes, pale hands, dark hooves
	local robe = newPart("Robe", Vector3.new(2.9, 2.2, 1.7), black, model, Enum.Material.Fabric)
	decor(torso, robe, CFrame.new(0, -1.5, 0))

	local hair = newPart("Hair", Vector3.new(2.3, 5, 0.5), Color3.fromRGB(8, 8, 10), model, Enum.Material.Fabric)
	decor(head, hair, CFrame.new(0, -2.2, 0.95))

	for _, side in ipairs({ -1, 1 }) do
		local eye = newPart("Eye", Vector3.new(0.28, 0.16, 0.1), Color3.fromRGB(255, 205, 100), model, Enum.Material.Neon)
		decor(head, eye, CFrame.new(side * 0.3, 0.1, -0.62))
	end

	for _, arm in ipairs({ armR, armL }) do
		local hand = newPart("Hand", Vector3.new(1.0, 0.5, 1.0), pale, model)
		decor(arm, hand, CFrame.new(0, -0.95, 0))
	end

	for _, leg in ipairs({ legR, legL }) do
		local hoof = newPart("Hoof", Vector3.new(0.9, 0.5, 1.1), Color3.fromRGB(10, 10, 10), model)
		decor(leg, hoof, CFrame.new(0, -1.0, -0.1))
	end

	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R6
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.WalkSpeed = PATROL_SPEED
	hum.Parent = model

	model.PrimaryPart = hrp
	model:SetAttribute("State", "Patrol")
	model.Parent = workspace
	model:PivotTo(CFrame.new(SPAWN_POS))
	model:ScaleTo(SCALE)
	CollectionService:AddTag(model, TAG)

	pcall(function()
		hrp:SetNetworkOwner(nil)
	end)

	return model, hum, hrp, head
end

local model, hum, root, head = buildCreature()

-- ---------- patrol points: alley crossings ----------
local PATROL_POINTS = {}
for _, x in ipairs({ -96, -48, 0, 48, 96 }) do
	for _, z in ipairs({ -72, -24, 24, 72 }) do
		table.insert(PATROL_POINTS, Vector3.new(x, GROUND_Y + 3, z))
	end
end

-- ---------- senses ----------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function canSee(char, range)
	local tRoot = char:FindFirstChild("HumanoidRootPart")
	if not tRoot then
		return false
	end
	local origin = head.Position
	local dir = tRoot.Position - origin
	if dir.Magnitude > range then
		return false
	end
	local ignore = { model }
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			table.insert(ignore, plr.Character)
		end
	end
	rayParams.FilterDescendantsInstances = ignore
	return workspace:Raycast(origin, dir, rayParams) == nil
end

local function flatDistance(a, b)
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function findTarget()
	local best, bestDist = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		local tRoot = char and char:FindFirstChild("HumanoidRootPart")
		local tHum = char and char:FindFirstChildOfClass("Humanoid")
		if tRoot and tHum and tHum.Health > 0 and flatDistance(tRoot.Position, SAFE_CENTER) > SAFE_RADIUS then
			local dist = (tRoot.Position - root.Position).Magnitude
			local v = tRoot.AssemblyLinearVelocity
			local speed = Vector3.new(v.X, 0, v.Z).Magnitude
			local hearRange = (speed > 18 and HEAR_RUN) or (speed > 4 and HEAR_WALK) or 0
			local headPart = char:FindFirstChild("Head")
			local beam = headPart and headPart:FindFirstChild("FlashlightBeam")
			local sightRange = (beam and beam.Enabled) and SIGHT_RANGE_LIGHT or SIGHT_RANGE
			local noticed = dist <= hearRange or (dist <= sightRange and canSee(char, sightRange))
			if noticed and dist < bestDist then
				best, bestDist = char, dist
			end
		end
	end
	return best
end

-- ---------- movement ----------
local PATH_PARAMS = {
	AgentRadius = 2.6,
	AgentHeight = 8,
	AgentCanJump = false,
	WaypointSpacing = 5,
}

local function moveToward(pos)
	local ok = pcall(function()
		local path = PathfindingService:CreatePath(PATH_PARAMS)
		path:ComputeAsync(root.Position, pos)
		if path.Status == Enum.PathStatus.Success then
			local wps = path:GetWaypoints()
			local wp = wps[2] or wps[1]
			if wp then
				hum:MoveTo(wp.Position)
				return
			end
		end
		hum:MoveTo(pos)
	end)
	if not ok then
		hum:MoveTo(pos)
	end
end

local function setState(state)
	model:SetAttribute("State", state)
	hum.WalkSpeed = (state == "Chase") and CHASE_SPEED or PATROL_SPEED
end

-- ---------- main loop ----------
local state = "Patrol"
local target = nil
local lastNoticed = 0
local patrolGoal = nil
local goalSetAt = 0

while model.Parent and hum.Health > 0 do
	task.wait(0.35)

	local found = findTarget()
	if found then
		target = found
		lastNoticed = os.clock()
		if state ~= "Chase" then
			state = "Chase"
			setState(state)
		end
	end

	if state == "Chase" then
		local tRoot = target and target:FindFirstChild("HumanoidRootPart")
		local tHum = target and target:FindFirstChildOfClass("Humanoid")
		local valid = tRoot and tHum and tHum.Health > 0 and flatDistance(tRoot.Position, SAFE_CENTER) > SAFE_RADIUS

		if valid then
			if (tRoot.Position - root.Position).Magnitude <= KILL_DISTANCE then
				tHum.Health = 0
				target = nil
				hum:MoveTo(root.Position)
				task.wait(3)
			else
				moveToward(tRoot.Position)
			end
		else
			target = nil
		end

		if not target or os.clock() - lastNoticed > LOSE_INTEREST_AFTER then
			state = "Patrol"
			setState(state)
			patrolGoal = nil
		end
	else
		if not patrolGoal or flatDistance(root.Position, patrolGoal) < 8 or os.clock() - goalSetAt > 25 then
			patrolGoal = PATROL_POINTS[math.random(#PATROL_POINTS)]
			goalSetAt = os.clock()
		end
		moveToward(patrolGoal)
	end
end
]==]

-- =====================================================================
-- Client: animates her limbs locally (walk cycle, arms reach forward when chasing)
-- =====================================================================
local ANIM_SRC = [==[
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local TAG = "UmmAlDuwais"

local function animate(model)
	local root = model:WaitForChild("HumanoidRootPart", 10)
	local torso = model:WaitForChild("Torso", 10)
	if not root or not torso then
		return
	end
	local rs = torso:WaitForChild("Right Shoulder")
	local ls = torso:WaitForChild("Left Shoulder")
	local rh = torso:WaitForChild("Right Hip")
	local lh = torso:WaitForChild("Left Hip")

	local phase = 0
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		if not model:IsDescendantOf(workspace) then
			conn:Disconnect()
			return
		end
		local v = root.AssemblyLinearVelocity
		local speed = Vector3.new(v.X, 0, v.Z).Magnitude
		local chasing = model:GetAttribute("State") == "Chase"

		phase += dt * math.clamp(speed * 0.9, 0, 18)
		local swing = math.sin(phase) * math.clamp(speed / 12, 0, 1) * 0.8
		local reach = chasing and 1.3 or 0.25

		rs.Transform = CFrame.Angles(0, 0, reach + swing * 0.5)
		ls.Transform = CFrame.Angles(0, 0, -(reach - swing * 0.5))
		rh.Transform = CFrame.Angles(0, 0, -swing)
		lh.Transform = CFrame.Angles(0, 0, -swing)
	end)
end

for _, m in ipairs(CollectionService:GetTagged(TAG)) do
	task.spawn(animate, m)
end
CollectionService:GetInstanceAddedSignal(TAG):Connect(function(m)
	task.spawn(animate, m)
end)
]==]

makeScript("Script", "UmmAlDuwaisAI", ServerScriptService, AI_SRC)
makeScript("LocalScript", "CreatureAnimator", StarterPlayer:WaitForChild("StarterPlayerScripts"), ANIM_SRC)

print("Layer 4 done: creature installed. Press Play and walk toward the village.")
