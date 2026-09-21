local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local flying = false
local speed = 50

-- =========================================================
-- 1. DAFTAR ANIMASI (Ganti ID dengan milikmu)
-- =========================================================
local anims = {
	Idle = Instance.new("Animation"),
	Forward = Instance.new("Animation"),
	Backward = Instance.new("Animation"),
	Left = Instance.new("Animation"),
	Right = Instance.new("Animation")
}

anims.Idle.AnimationId     = "rbxassetid://13541167203" -- ID Melayang Diam
anims.Forward.AnimationId  = "rbxassetid://13541166419" -- ID Maju (W)
anims.Backward.AnimationId = "rbxassetid://13541161355" -- ID Mundur (S)
anims.Left.AnimationId     = "rbxassetid://13541162586" -- ID Kiri (A)
anims.Right.AnimationId    = "rbxassetid://13541163709" -- ID Kanan (D)

local tracks = {}
local activeTrack = nil

local bodyVelocity = Instance.new("BodyVelocity")
bodyVelocity.MaxForce = Vector3.new(4e5, 4e5, 4e5)

local bodyGyro = Instance.new("BodyGyro")
bodyGyro.MaxTorque = Vector3.new(4e5, 4e5, 4e5)

-- Fungsi pembantu buat ganti animasi tanpa bentrok
local function setAnimation(targetTrack)
	if activeTrack ~= targetTrack then
		if activeTrack then 
			activeTrack:Stop(0.2) -- Hentikan animasi lama dengan transisi halus
		end
		activeTrack = targetTrack
		if activeTrack then 
			activeTrack:Play(0.2) -- Jalankan animasi baru
		end
	end
end

local function toggleFly()
	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not rootPart or not humanoid or not animator then return end

	flying = not flying

	if flying then
		bodyVelocity.Parent = rootPart
		bodyGyro.Parent = rootPart
		humanoid:ChangeState(Enum.HumanoidStateType.Flying)

		-- Load semua animasi ke karakter
		tracks.Idle = animator:LoadAnimation(anims.Idle)
		tracks.Forward = animator:LoadAnimation(anims.Forward)
		tracks.Backward = animator:LoadAnimation(anims.Backward)
		tracks.Left = animator:LoadAnimation(anims.Left)
		tracks.Right = animator:LoadAnimation(anims.Right)

		setAnimation(tracks.Idle)
	else
		bodyVelocity.Parent = nil
		bodyGyro.Parent = nil
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

		setAnimation(nil)
		tracks = {}
	end
end

player.CharacterAdded:Connect(function()
	tracks = {}
	activeTrack = nil
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.P then
		toggleFly()
	end
end)

-- =========================================================
-- 2. DETEKSI TOMBOL & PENENTUAN ANIMASI
-- =========================================================
RunService.RenderStepped:Connect(function()
	if flying and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local rootPart = player.Character.HumanoidRootPart
		bodyGyro.CFrame = camera.CFrame

		local moveDirection = Vector3.new(0, 0, 0)
		local isW = UserInputService:IsKeyDown(Enum.KeyCode.W)
		local isS = UserInputService:IsKeyDown(Enum.KeyCode.S)
		local isA = UserInputService:IsKeyDown(Enum.KeyCode.A)
		local isD = UserInputService:IsKeyDown(Enum.KeyCode.D)

		if isW then moveDirection = moveDirection + camera.CFrame.LookVector end
		if isS then moveDirection = moveDirection - camera.CFrame.LookVector end
		if isA then moveDirection = moveDirection - camera.CFrame.RightVector end
		if isD then moveDirection = moveDirection + camera.CFrame.RightVector end

		bodyVelocity.Velocity = moveDirection * speed

		-- Cek tombol mana yang ditekan buat muter animasi yang sesuai
		if isW then
			setAnimation(tracks.Forward)
		elseif isS then
			setAnimation(tracks.Backward)
		elseif isA then
			setAnimation(tracks.Left)
		elseif isD then
			setAnimation(tracks.Right)
		else
			setAnimation(tracks.Idle)
		end
	end
end)
