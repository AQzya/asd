-- Layer 2: player systems = Sprint with 23 second stamina + bottom bar, and a dim Flashlight (F)
--
-- HOW TO RUN
--   Studio > View > Command Bar, paste this whole script, press Enter (Edit mode, not Play).
--   It creates the scripts in the right places. Then press Play to test.
--   Safe to rerun: it replaces the old copies.
--
-- CONTROLS
--   Hold Left Shift = run (up to MAX_SPRINT_SECONDS, then you are exhausted until you recover)
--   F = flashlight on/off (a button also appears on phones)
--
-- You can edit the numbers inside the scripts afterwards (top of each script).

local StarterPlayer = game:GetService("StarterPlayer")
local StarterPack = game:GetService("StarterPack")
local ServerScriptService = game:GetService("ServerScriptService")

local function remove(parent: Instance, name: string)
	local old = parent:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

local function makeScript(className: string, name: string, parent: Instance, source: string): Instance
	remove(parent, name)
	local s = Instance.new(className)
	s.Name = name
	s.Source = source
	s.Parent = parent
	return s
end

-- =====================================================================
-- Sprint (LocalScript)
-- =====================================================================
local SPRINT_SRC = [==[
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer

-- ===== settings =====
local MAX_SPRINT_SECONDS = 23     -- how long you can run
local WALK_SPEED = 14
local RUN_SPEED = 22
local REGEN_SECONDS_TO_FULL = 10  -- time to refill from empty
local REGEN_DELAY = 1.5           -- wait after running before refilling
local RESUME_FRACTION = 0.2       -- after being exhausted you need 20% to run again
-- =================

local stamina = MAX_SPRINT_SECONDS
local wantsSprint = false
local exhausted = false
local lastSprintTime = 0

-- ---------- UI: thin line at the bottom of the screen ----------
local gui = Instance.new("ScreenGui")
gui.Name = "StaminaGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

local barBack = Instance.new("Frame")
barBack.Name = "BarBack"
barBack.AnchorPoint = Vector2.new(0.5, 1)
barBack.Position = UDim2.new(0.5, 0, 1, -22)
barBack.Size = UDim2.new(0.3, 0, 0, 6)
barBack.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
barBack.BackgroundTransparency = 0.5
barBack.BorderSizePixel = 0
barBack.Visible = false
barBack.Parent = gui

local backCorner = Instance.new("UICorner")
backCorner.CornerRadius = UDim.new(0.5, 0)
backCorner.Parent = barBack

local barFill = Instance.new("Frame")
barFill.Name = "BarFill"
barFill.Size = UDim2.new(1, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(235, 225, 200)
barFill.BorderSizePixel = 0
barFill.Parent = barBack

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0.5, 0)
fillCorner.Parent = barFill

-- ---------- input (keyboard, gamepad, and an on-screen button on phones) ----------
local function onSprint(_, state)
	wantsSprint = (state == Enum.UserInputState.Begin)
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindActionAtPriority(
	"Sprint",
	onSprint,
	true,
	Enum.ContextActionPriority.High.Value,
	Enum.KeyCode.LeftShift,
	Enum.KeyCode.ButtonL2
)
ContextActionService:SetTitle("Sprint", "RUN")
ContextActionService:SetPosition("Sprint", UDim2.new(1, -100, 1, -180))

player.CharacterAdded:Connect(function()
	stamina = MAX_SPRINT_SECONDS
	exhausted = false
end)

-- ---------- main loop ----------
RunService.RenderStepped:Connect(function(dt)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end

	local moving = hum.MoveDirection.Magnitude > 0.1
	local sprinting = wantsSprint and moving and not exhausted and stamina > 0

	if sprinting then
		stamina = math.max(0, stamina - dt)
		lastSprintTime = os.clock()
		if stamina <= 0 then
			exhausted = true
		end
	elseif os.clock() - lastSprintTime > REGEN_DELAY then
		stamina = math.min(MAX_SPRINT_SECONDS, stamina + (MAX_SPRINT_SECONDS / REGEN_SECONDS_TO_FULL) * dt)
		if exhausted and stamina >= MAX_SPRINT_SECONDS * RESUME_FRACTION then
			exhausted = false
		end
	end

	local targetSpeed = sprinting and RUN_SPEED or WALK_SPEED
	if hum.WalkSpeed ~= targetSpeed then
		hum.WalkSpeed = targetSpeed
	end

	barFill.Size = UDim2.new(stamina / MAX_SPRINT_SECONDS, 0, 1, 0)
	barFill.BackgroundColor3 = exhausted and Color3.fromRGB(190, 60, 50) or Color3.fromRGB(235, 225, 200)
	barBack.Visible = sprinting or stamina < MAX_SPRINT_SECONDS - 0.01
end)
]==]

-- =====================================================================
-- Flashlight: server part (Script inside the Tool)
-- =====================================================================
local FLASH_SERVER_SRC = [==[
local tool = script.Parent
local remote = tool:WaitForChild("Toggle")
local handle = tool:WaitForChild("Handle")

-- ===== settings (dim light) =====
local BRIGHTNESS = 0.9
local RANGE = 38
local ANGLE = 55
local BEAM_COLOR = Color3.fromRGB(255, 235, 200)
-- ================================

local holder = nil
local on = false

local function getBeam(char)
	local head = char:FindFirstChild("Head")
	if not head then
		return nil
	end
	local beam = head:FindFirstChild("FlashlightBeam")
	if not beam then
		beam = Instance.new("SpotLight")
		beam.Name = "FlashlightBeam"
		beam.Face = Enum.NormalId.Front
		beam.Brightness = BRIGHTNESS
		beam.Range = RANGE
		beam.Angle = ANGLE
		beam.Color = BEAM_COLOR
		beam.Shadows = true
		beam.Enabled = false
		beam.Parent = head
	end
	return beam
end

local function apply(enabled)
	on = enabled
	if holder then
		local beam = getBeam(holder)
		if beam then
			beam.Enabled = enabled
		end
	end
	handle.Color = enabled and Color3.fromRGB(255, 232, 170) or Color3.fromRGB(40, 40, 44)
	handle.Material = enabled and Enum.Material.Neon or Enum.Material.Metal
end

tool.Equipped:Connect(function()
	holder = tool.Parent
	apply(false)
end)

tool.Unequipped:Connect(function()
	apply(false)
	holder = nil
end)

remote.OnServerEvent:Connect(function(player)
	if holder and player.Character == holder then
		apply(not on)
	end
end)
]==]

-- =====================================================================
-- Flashlight: client part (LocalScript inside the Tool) - F key
-- =====================================================================
local FLASH_CLIENT_SRC = [==[
local ContextActionService = game:GetService("ContextActionService")

local tool = script.Parent
local remote = tool:WaitForChild("Toggle")
local ACTION = "ToggleFlashlight"

local function onToggle(_, state)
	if state == Enum.UserInputState.Begin then
		remote:FireServer()
	end
	return Enum.ContextActionResult.Sink
end

tool.Equipped:Connect(function()
	ContextActionService:BindAction(ACTION, onToggle, true, Enum.KeyCode.F, Enum.KeyCode.ButtonY)
	ContextActionService:SetTitle(ACTION, "F")
	ContextActionService:SetPosition(ACTION, UDim2.new(1, -100, 1, -270))
end)

tool.Unequipped:Connect(function()
	ContextActionService:UnbindAction(ACTION)
end)
]==]

-- =====================================================================
-- Gives the flashlight and equips it on every spawn
-- =====================================================================
local SETUP_SRC = [==[
local Players = game:GetService("Players")

local function onCharacter(player, char)
	local hum = char:WaitForChild("Humanoid", 10)
	local tool = player:WaitForChild("Backpack"):WaitForChild("Flashlight", 10)
	if hum and tool then
		hum:EquipTool(tool)
	end
end

local function onPlayer(player)
	player.CharacterAdded:Connect(function(char)
		onCharacter(player, char)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	onPlayer(p)
end
]==]

-- ---------- install ----------
local playerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
makeScript("LocalScript", "Sprint", playerScripts, SPRINT_SRC)
makeScript("Script", "PlayerSetup", ServerScriptService, SETUP_SRC)

remove(StarterPack, "Flashlight")
local tool = Instance.new("Tool")
tool.Name = "Flashlight"
tool.RequiresHandle = true
tool.CanBeDropped = false
tool.ToolTip = "Press F"

local handle = Instance.new("Part")
handle.Name = "Handle"
handle.Size = Vector3.new(0.6, 0.6, 1.8)
handle.Material = Enum.Material.Metal
handle.Color = Color3.fromRGB(40, 40, 44)
handle.Parent = tool

local remote = Instance.new("RemoteEvent")
remote.Name = "Toggle"
remote.Parent = tool

makeScript("Script", "FlashlightServer", tool, FLASH_SERVER_SRC)
makeScript("LocalScript", "FlashlightClient", tool, FLASH_CLIENT_SRC)
tool.Parent = StarterPack

-- Shift is used for running, so turn off the default Shift Lock option
StarterPlayer.EnableMouseLockOption = false

print("Layer 2 done: Sprint + Flashlight installed. Press Play to test.")
