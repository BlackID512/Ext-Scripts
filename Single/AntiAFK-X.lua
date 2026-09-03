-- AntiAFK-X
repeat wait() until game:IsLoaded() and game.Players and game.Players.LocalPlayer and game.Players.LocalPlayer.Character

if getgenv().AntiAfkExecuted and MainGUI then 
    getgenv().AntiAfkExecuted = false
	getgenv().RunningTimer = false
	game.CoreGui.MainGUI:Destroy()
end

getgenv().AntiAfkExecuted = true

local MainGUI = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local UICornerw = Instance.new("UICorner")
local DestroyButton = Instance.new("TextButton")
local TitleLabel = Instance.new("TextLabel")
local timerlabel = Instance.new("TextLabel")
local LabelPing = Instance.new("TextLabel")
local CountFPS = Instance.new("TextLabel")
local LabelFPS = Instance.new("TextLabel")
local CountPing = Instance.new("TextLabel")
local FrameSplitter = Instance.new("Frame")
local UICornerww = Instance.new("UICorner")
-- local FooterLabel = Instance.new("TextLabel")

MainGUI.Name = "MainGUI"
MainGUI.Parent = game.CoreGui
MainGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

MainFrame.Name = "MainFrame"
MainFrame.Parent = MainGUI
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Position = UDim2.new(0.0854133144, 0, 0.13128835, 0)
MainFrame.Size = UDim2.new(0, 225, 0, 96)

UICornerw.Name = "UICornerw"
UICornerw.Parent = MainFrame

DestroyButton.Name = "DestroyButton"
DestroyButton.Parent = MainFrame
DestroyButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
DestroyButton.BackgroundTransparency = 1.000
DestroyButton.Position = UDim2.new(0.871702373, 0, 0.0245379955, 0)
DestroyButton.Size = UDim2.new(0, 27, 0, 15)
DestroyButton.Font = Enum.Font.SourceSans
DestroyButton.Text = "X"
DestroyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DestroyButton.TextSize = 14.000

DestroyButton.MouseButton1Click:connect(function()
	getgenv().AntiAfkExecuted = false
	
	wait(0.1)
	MainGUI:Destroy()
end)

TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = MainFrame
TitleLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.BackgroundTransparency = 1.000
TitleLabel.Position = UDim2.new(0.302473009, 0, 0, 0)
TitleLabel.Size = UDim2.new(0, 95, 0, 24)
TitleLabel.Font = Enum.Font.SourceSans
TitleLabel.Text = "AntiAFK-X by FathurBlackID"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 14.000

timerlabel.Name = "timerlabel"
timerlabel.Parent = MainFrame
timerlabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
timerlabel.BackgroundTransparency = 1.000
timerlabel.Position = UDim2.new(0.65344125, 0, 0.68194294, 0)
timerlabel.Size = UDim2.new(0, 60, 0, 24)
timerlabel.Font = Enum.Font.SourceSans
timerlabel.Text = "00:00:00"
timerlabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerlabel.TextSize = 14.000

LabelPing.Name = "LabelPing"
LabelPing.Parent = MainFrame
LabelPing.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
LabelPing.BackgroundTransparency = 1.000
LabelPing.Position = UDim2.new(0.038864471, 0, 0.373806685, 0)
LabelPing.Size = UDim2.new(0, 29, 0, 24)
LabelPing.Font = Enum.Font.SourceSans
LabelPing.Text = "Ping: "
LabelPing.TextColor3 = Color3.fromRGB(255, 255, 255)
LabelPing.TextSize = 14.000

CountFPS.Name = "CountFPS"
CountFPS.Parent = MainFrame
CountFPS.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CountFPS.BackgroundTransparency = 1.000
CountFPS.Position = UDim2.new(0.724226236, 0, 0.358796299, 0)
CountFPS.Size = UDim2.new(0, 55, 0, 24)
CountFPS.Font = Enum.Font.SourceSans
CountFPS.Text = "..."
CountFPS.TextColor3 = Color3.fromRGB(255, 255, 255)
CountFPS.TextSize = 14.000

LabelFPS.Name = "LabelFPS"
LabelFPS.Parent = MainFrame
LabelFPS.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
LabelFPS.BackgroundTransparency = 1.000
LabelFPS.Position = UDim2.new(0.506917477, 0, 0.352585167, 0)
LabelFPS.Size = UDim2.new(0, 26, 0, 24)
LabelFPS.Font = Enum.Font.SourceSans
LabelFPS.Text = "FPS: "
LabelFPS.TextColor3 = Color3.fromRGB(255, 255, 255)
LabelFPS.TextSize = 14.000

CountPing.Name = "CountPing"
CountPing.Parent = MainFrame
CountPing.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CountPing.BackgroundTransparency = 1.000
CountPing.Position = UDim2.new(0.20330891, 0, 0.371578127, 0)
CountPing.Size = UDim2.new(0, 55, 0, 24)
CountPing.Font = Enum.Font.SourceSans
CountPing.Text = "..."
CountPing.TextColor3 = Color3.fromRGB(255, 255, 255)
CountPing.TextSize = 14.000
CountPing.TextWrapped = true

FrameSplitter.Name = "FrameSplitter"
FrameSplitter.Parent = MainFrame
FrameSplitter.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FrameSplitter.Position = UDim2.new(0.00444444455, 0, 0.243312627, 0)
FrameSplitter.Size = UDim2.new(0, 224, 0, 5)

UICornerww.CornerRadius = UDim.new(0, 50)
UICornerww.Name = "UICornerww"
UICornerww.Parent = FrameSplitter

--[[
FooterLabel.Name = "FooterLabel"
FooterLabel.Parent = MainFrame
FooterLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FooterLabel.BackgroundTransparency = 1.000
FooterLabel.Position = UDim2.new(0.0580285639, 0, 0.8125, 0)
FooterLabel.Size = UDim2.new(0, 95, 0, 12)
FooterLabel.Font = Enum.Font.SourceSans
FooterLabel.Text = "AntiAFK-X Enabled"
FooterLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FooterLabel.TextSize = 14.000
]]--

local Drag = game.CoreGui.MainGUI.MainFrame
gsCoreGui = game:GetService("CoreGui")
gsTween = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local dragging
local dragInput
local dragStart
local startPos
local function update(input)
	local delta = input.Position - dragStart
	local dragTime = 0.04
	local SmoothDrag = {}
	SmoothDrag.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	local dragSmoothFunction = gsTween:Create(Drag, TweenInfo.new(dragTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), SmoothDrag)
	dragSmoothFunction:Play()
end
Drag.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = Drag.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)
Drag.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging and Drag.Size then
		update(input)
	end
end)

local virtualUser = game:service'VirtualUser'
game:service'Players'.LocalPlayer.Idled:connect(function()
	virtualUser:CaptureController()
	virtualUser:ClickButton2(Vector2.new())
end)

local FPSsLabel = CountFPS
local RunService = game:GetService("RunService")
local RenderStepped = RunService.RenderStepped
local sec = nil
local FPS = {}

local function fre()
	local fr = tick()
	for index = #FPS,1,-1 do
		FPS[index + 1] = (FPS[index] >= fr - 1) and FPS[index] or nil
	end
	FPS[1] = fr
	local fps = (tick() - sec >= 1 and #FPS) or (#FPS / (tick() - sec))
	fps = math.floor(fps)
	CountFPS.Text = fps
end

sec = tick()
RenderStepped:Connect(fre)
spawn(function()
	repeat
		wait(1)
		local ping = tonumber(game:GetService("Stats"):FindFirstChild("PerformanceStats").Ping:GetValue())
		ping = math.floor(ping)
		CountPing.Text = ping
	until CountPing == nil
end)

local seconds = 0
local minutes = 0
local hours = 0
local labelSeconds = ""..seconds
local labelMinutes = ""..minutes
local labelHours = ""..hours
getgenv().RunningTimer = true

while true do
		if getgenv().RunningTimer then
			seconds = seconds + 1
			wait(1)
		end
		if seconds >= 60 then
			seconds = 0
			minutes = minutes + 1
		end
		if minutes >= 60 then
			minutes = 0
			hours = hours + 1
		end
		labelSeconds = seconds
		labelMinutes = minutes
		labelHours = hours
		if seconds < 10 then
			labelSeconds = "0"..seconds
		end
		if minutes < 10 then
			labelMinutes = "0"..minutes
		end
		if hours < 10 then
			labelHours = "0"..hours
		end
		timerlabel.Text = labelHours..":"..labelMinutes..":"..labelSeconds
	end
