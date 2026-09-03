--[[
  AntiAFK-X (All-in-One) — V0.0.1_1A
  * Draggable UI, RightShift toggle, Splash + bottom-right hint
  * FPS / Session minutes / approx CPU% / RAM MB / Ping ms
  * Anti-AFK (Idled + periodic tick)
  * Lag Watchdog: None | Respawn | Rejoin (Server Hop)
  * Manual Respawn (show times), Manual Rejoin (Server Hop)
  * Auto Rejoin on disconnect (toggle)
  * Log inside menu (read-only), colored tags, auto-scroll
  * Expanded title bar + non-overlapping RGB credits:
       - Dev/DisCord: FathurBlackID  (top line, RGB)
       - Made By FathurBlackID (bottom line, RGB)
]]--

--// Services
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local StatsSvc        = game:GetService("Stats")
local HttpService     = game:GetService("HttpService")
local VirtualUser     = game:GetService("VirtualUser")
local CoreGui         = game:GetService("CoreGui")

local player = Players.LocalPlayer

-- Parent GUI: try CoreGui, fallback PlayerGui
local UIParent
do
  local ok = pcall(function() local _ = CoreGui.Name end)
  if ok then UIParent = CoreGui else UIParent = player:WaitForChild("PlayerGui") end
end

--// Settings
-- local VERSION = "3.22.8"
local VERSION = "0.0.1_1A"
local settings = {
  antiAFK = true,
  afkClickInterval = 240,
  checkInterval = 1.0,
  heartbeatThreshold = 0.5,
  glitchCountThreshold = 3,
  autoAction = "None",    -- "None" | "Respawn" | "Rejoin"
  rejoinDelay = 2,
  serverHop = true,
  showSplash = true,
  autoReconnect = true,
}

--// State
local startTime   = os.clock()
local lastAfkTick  = 0
local fps          = 60
local glitchCount  = 0
local expanded     = true
local reconnectConn

--// Helpers (time / http / server hop)
local function nowUTC() return os.time(os.date("!*t")) end
--[[
local function localTimeStr()   return os.date("%Y-%m-%d %H:%M:%S") end
local function utcTimeStr()     return os.date("!%Y-%m-%d %H:%M:%S") end
local function bangkokTimeStr() return os.date("!%Y-%m-%d %H:%M:%S", nowUTC()+7*3600) end
]]--
local function localTimeStr()   return os.date("%d/%m/%Y %H:%M:%S") end
local function utcTimeStr()     return os.date("!%d/%m/%Y %H:%M:%S") end
local function bangkokTimeStr() return os.date("!%d/%m/%Y %H:%M:%S", nowUTC()+7*3600) end

local function http_get(url)
  if syn and syn.request then
    local r = syn.request({Url=url, Method="GET"}); if r and r.Body then return true, r.Body end
  elseif request then
    local r = request({Url=url, Method="GET"}); if r and r.Body then return true, r.Body end
  elseif http_request then
    local r = http_request({Url=url, Method="GET"}); if r and r.Body then return true, r.Body end
  end
  return false, "no-http"
end

local function serverHop(placeId)
  if not settings.serverHop then TeleportService:Teleport(placeId, player) return end
  local cursor = ""
  for _=1,5 do
    local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s")
      :format(placeId, (#cursor>0 and ("&cursor="..HttpService:UrlEncode(cursor)) or ""))
    local ok, body = http_get(url)
    if not ok then TeleportService:Teleport(placeId, player) return end
    local data; pcall(function() data = HttpService:JSONDecode(body) end)
    if data and data.data then
      for _,srv in ipairs(data.data) do
        if srv.id and srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
          TeleportService:TeleportToPlaceInstance(placeId, srv.id, player) return
        end
      end
      cursor = data.nextPageCursor or ""; if cursor == "" then break end
    else break end
  end
  TeleportService:Teleport(placeId, player)
end

--// UI Root
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AntiAFK-X_UI"
screenGui.ResetOnSpawn = false
screenGui.Parent = UIParent

-- Main Frame (expanded so credits never overlap)
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 330, 0, 500)
frame.Position = UDim2.new(0.02, 0, 0.12, 0)
frame.BackgroundColor3 = Color3.fromRGB(20,20,25)
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
local frStroke = Instance.new("UIStroke", frame); frStroke.Color = Color3.fromRGB(80,80,95); frStroke.Thickness = 1

-- Title Bar (taller to host credits)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 76)
titleBar.BackgroundColor3 = Color3.fromRGB(35,35,44)
titleBar.Parent = frame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -12, 0, 30)
titleText.Position = UDim2.new(0, 8, 0, 6)
titleText.BackgroundTransparency = 1
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 22
-- titleText.TextColor3 = Color3.fromRGB(255,130,95)
titleText.TextColor3 = Color3.fromRGB(255,0,0)
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Text = "AntiAFK-X"
titleText.Parent = titleBar

-- Version badge (top-right)
local verBadge = Instance.new("TextLabel")
verBadge.AnchorPoint = Vector2.new(1,0)
verBadge.Position = UDim2.new(1, -8, 0, 6)
verBadge.Size = UDim2.new(0, 86, 0, 18)
verBadge.BackgroundColor3 = Color3.fromRGB(45,48,58)
verBadge.Text = 'v' .. VERSION
verBadge.Font = Enum.Font.GothamBold
verBadge.TextSize = 12
verBadge.TextColor3 = Color3.fromRGB(230,230,230)
verBadge.Parent = titleBar
Instance.new("UICorner", verBadge).CornerRadius = UDim.new(0,6)

-- Credits (left side, stacked, RGB)
local devLbl = Instance.new("TextLabel")
devLbl.Position = UDim2.new(0, 10, 0, 38)
devLbl.Size = UDim2.new(0.6, 0, 0, 18)
devLbl.BackgroundTransparency = 1
devLbl.Font = Enum.Font.GothamBold
devLbl.TextSize = 12
devLbl.TextColor3 = Color3.fromRGB(88,101,242)
devLbl.TextXAlignment = Enum.TextXAlignment.Left
devLbl.Text = "Dev | DisCord: FathurBlackID"
devLbl.Parent = titleBar

local authorLbl = Instance.new("TextLabel")
authorLbl.Position = UDim2.new(0, 10, 0, 56)
authorLbl.Size = UDim2.new(0.6, 0, 0, 18)
authorLbl.BackgroundTransparency = 1
authorLbl.Font = Enum.Font.GothamBold
authorLbl.TextSize = 12
authorLbl.TextColor3 = Color3.fromRGB(0,230,230)
authorLbl.TextXAlignment = Enum.TextXAlignment.Left
authorLbl.Text = "Made By FathurBlackID"
authorLbl.Parent = titleBar

-- RGB animate credits
--[[
task.spawn(function()
  local h = 0
  while devLbl.Parent and authorLbl.Parent do
    devLbl.TextColor3    = Color3.fromHSV(h, 1, 1)
    authorLbl.TextColor3 = Color3.fromHSV((h+0.5)%1, 1, 1)
    h = (h + 0.008) % 1
    task.wait(0.03)
  end
end)
]]--

-- Make draggable by title bar
do
  local dragging, dragStart, startPos
  titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
      dragging = true; dragStart = input.Position; startPos = frame.Position
      input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then dragging = false end
      end)
    end
  end)
  UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
      local delta = input.Position - dragStart
      frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
    end
  end)
end

-- RightShift show/hide
UserInputService.InputBegan:Connect(function(input,gpe)
  if gpe then return end
  if input.KeyCode == Enum.KeyCode.RightShift then
    frame.Visible = not frame.Visible
  end
end)

-- little helper makers
local function makeLabel(text, x, y, w, h, bold)
  local l = Instance.new("TextLabel")
  l.Position = UDim2.new(0, x, 0, y)
  l.Size = UDim2.new(0, w, 0, h)
  l.BackgroundTransparency = 1
  l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
  l.TextSize = 14
  l.TextXAlignment = Enum.TextXAlignment.Left
  l.TextColor3 = Color3.fromRGB(220,220,230)
  l.Text = text
  l.Parent = frame
  return l
end
local function makeBtn(text, x, y, w, h, bg)
  local b = Instance.new("TextButton")
  b.Position = UDim2.new(0, x, 0, y)
  b.Size = UDim2.new(0, w, 0, h)
  b.Font = Enum.Font.GothamBold
  b.TextSize = 14
  b.TextColor3 = Color3.fromRGB(240,240,240)
  b.Text = text
  b.BackgroundColor3 = bg or Color3.fromRGB(45,45,55)
  b.Parent = frame
  Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
  return b
end

-- Rows / Controls
-- local statusLbl  = makeLabel("Status: Starting...", 10, 84, 300, 22)
local statusLbl  = makeLabel("♻", 10, 84, 300, 22)
local antiBtn    = makeBtn("AntiAFK: ON",            10, 110, 155, 32, Color3.fromRGB(45,80,55))
local expandBtn  = makeBtn("Collapse",              175, 110, 145, 32, Color3.fromRGB(55,55,65))
local actionBtn  = makeBtn("Action: None",           10, 150, 155, 32)
local reconnBtn  = makeBtn("Auto Rejoin: ON",       175, 150, 145, 32, Color3.fromRGB(55,75,55))

-- local sessionLbl = makeLabel("In server: 0 min", 10, 188, 300, 22)
local sessionLbl = makeLabel("In server: 0d 00:00:00", 10, 188, 300, 22)
local threshLbl  = makeLabel("Lag threshold (s): 0.5", 10, 212, 160, 22)
local plusBtn    = makeBtn("+",                   180, 210, 45, 24, Color3.fromRGB(52,52,62))
local minusBtn   = makeBtn("-",                   230, 210, 45, 24, Color3.fromRGB(52,52,62))

local sysLbl     = makeLabel("CPU: --% | RAM: --MB | Ping: --ms", 10, 240, 300, 22)

local respawnBtn = makeBtn("Manual Respawn (show time)", 10, 270, 250, 30, Color3.fromRGB(90,60,60))
local rejoinBtn  = makeBtn("Manual Rejoin (Server Hop)", 10, 306, 250, 30, Color3.fromRGB(90,60,60))

-- Log area (read-only, inside menu)
local header = makeLabel("Log", 10, 342, 300, 20, true)
local logFrame = Instance.new("ScrollingFrame")
logFrame.Position = UDim2.new(0, 10, 0, 364)
logFrame.Size = UDim2.new(0, 310, 0, 118)
logFrame.BackgroundColor3 = Color3.fromRGB(25,25,32)
logFrame.BorderSizePixel = 0
logFrame.ScrollBarThickness = 6
logFrame.Parent = frame
Instance.new("UICorner", logFrame).CornerRadius = UDim.new(0,10)
local logStroke = Instance.new("UIStroke", logFrame); logStroke.Color = Color3.fromRGB(70,70,90); logStroke.Thickness=1
local layout = Instance.new("UIListLayout", logFrame); layout.Padding = UDim.new(0,3); layout.SortOrder = Enum.SortOrder.LayoutOrder

local function addLog(kind, text)
  local color = Color3.fromRGB(220,220,220)
  if kind=="AFK" then color=Color3.fromRGB(160,230,160) end
  if kind=="WATCH" then color=Color3.fromRGB(230,210,160) end
  if kind=="ACTION" then color=Color3.fromRGB(220,160,160) end
  if kind=="INFO" then color=Color3.fromRGB(190,210,255) end

  local row = Instance.new("Frame")
  row.Size = UDim2.new(1, -4, 0, 20)
  row.BackgroundTransparency = 1
  row.Parent = logFrame

  local tag = Instance.new("TextLabel")
  tag.Size = UDim2.new(0, 62, 1, 0)
  tag.BackgroundColor3 = Color3.fromRGB(45,48,58)
  tag.Text = "["..kind.."]"
  tag.Font = Enum.Font.GothamBold
  tag.TextSize = 12
  tag.TextColor3 = color
  tag.BorderSizePixel = 0
  tag.Parent = row
  Instance.new("UICorner", tag).CornerRadius = UDim.new(0,6)

  local msg = Instance.new("TextLabel")
  msg.Position = UDim2.new(0, 66, 0, 0)
  msg.Size = UDim2.new(1, -66, 1, 0)
  msg.BackgroundTransparency = 1
  msg.TextXAlignment = Enum.TextXAlignment.Left
  msg.Font = Enum.Font.Gotham
  msg.TextSize = 12
  msg.TextColor3 = Color3.fromRGB(220,220,230)
  msg.Text = os.date("%X").." "..text
  msg.Parent = row

  logFrame.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y+6)
  logFrame.CanvasPosition = Vector2.new(0, logFrame.CanvasSize.Y.Offset)
end

-- Expand/Collapse sizing
local function applyExpandState()
  if expanded then
    expandBtn.Text = "Collapse"
    frame.Size = UDim2.new(0, 330, 0, 500)
    logFrame.Size = UDim2.new(0, 310, 0, 118)
  else
    expandBtn.Text = "Expand"
    frame.Size = UDim2.new(0, 330, 0, 430)
    logFrame.Size = UDim2.new(0, 310, 0, 48)
  end
end
applyExpandState()

-- Buttons logic
antiBtn.MouseButton1Click:Connect(function()
  settings.antiAFK = not settings.antiAFK
  antiBtn.Text = settings.antiAFK and "AntiAFK: ON" or "AntiAFK: OFF"
  antiBtn.BackgroundColor3 = settings.antiAFK and Color3.fromRGB(45,80,55) or Color3.fromRGB(75,55,55)
  addLog("INFO","AntiAFK toggled -> "..tostring(settings.antiAFK))
end)

local actions = {"None","Respawn","Rejoin"}
local idx = 1
actionBtn.MouseButton1Click:Connect(function()
  idx = idx % #actions + 1
  settings.autoAction = actions[idx]
  actionBtn.Text = "Action: "..settings.autoAction
  addLog("INFO","AutoAction -> "..settings.autoAction)
end)

expandBtn.MouseButton1Click:Connect(function()
  expanded = not expanded
  applyExpandState()
end)

local function setReconnButtonVisual()
  reconnBtn.Text = settings.autoReconnect and "Auto Rejoin: ON" or "Auto Rejoin: OFF"
  reconnBtn.BackgroundColor3 = settings.autoReconnect and Color3.fromRGB(55,75,55) or Color3.fromRGB(75,55,55)
end
setReconnButtonVisual()

-- Auto Reconnect watcher attach/detach
local function attachReconnectWatcher()
  if reconnectConn then reconnectConn:Disconnect(); reconnectConn=nil end
  local ok = pcall(function()
    local overlay = CoreGui:FindFirstChild("RobloxPromptGui") or CoreGui:WaitForChild("RobloxPromptGui", 5)
    if overlay then overlay = overlay:FindFirstChild("promptOverlay") or overlay:WaitForChild("promptOverlay", 5) end
    if not overlay then return end
    reconnectConn = overlay.ChildAdded:Connect(function(obj)
      if not settings.autoReconnect then return end
      if obj.Name == "ErrorPrompt" then
        addLog("ACTION","Disconnect detected -> Auto Rejoin")
        task.delay(0.2, function()
          local placeId, jobId = game.PlaceId, game.JobId
          pcall(function() TeleportService:TeleportToPlaceInstance(placeId, jobId, player) end)
          task.delay(1.0, function() pcall(function() TeleportService:Teleport(placeId, player) end) end)
        end)
      end
    end)
  end)
  if ok then addLog("INFO","Auto Rejoin watcher attached") else addLog("INFO","Auto Rejoin watcher failed") end
end

local function detachReconnectWatcher()
  if reconnectConn then reconnectConn:Disconnect(); reconnectConn=nil end
  addLog("INFO","Auto Rejoin watcher detached")
end

reconnBtn.MouseButton1Click:Connect(function()
  settings.autoReconnect = not settings.autoReconnect
  setReconnButtonVisual()
  if settings.autoReconnect then attachReconnectWatcher() else detachReconnectWatcher() end
end)

plusBtn.MouseButton1Click:Connect(function()
  settings.heartbeatThreshold = math.floor((settings.heartbeatThreshold + 0.1)*10)/10
  threshLbl.Text = "Lag threshold (s): "..tostring(settings.heartbeatThreshold)
end)
minusBtn.MouseButton1Click:Connect(function()
  settings.heartbeatThreshold = math.max(0.1, math.floor((settings.heartbeatThreshold - 0.1)*10)/10)
  threshLbl.Text = "Lag threshold (s): "..tostring(settings.heartbeatThreshold)
end)

respawnBtn.MouseButton1Click:Connect(function()
  addLog("ACTION", ("Respawn @ Local:%s | UTC:%s | BKK:%s"):format(localTimeStr(), utcTimeStr(), bangkokTimeStr()))
  pcall(function() player:LoadCharacter() end)
end)
rejoinBtn.MouseButton1Click:Connect(function()
  addLog("ACTION", "Rejoin requested (ServerHop="..tostring(settings.serverHop)..")")
  task.delay(settings.rejoinDelay, function() pcall(function() serverHop(game.PlaceId) end) end)
end)

-- Anti-AFK
player.Idled:Connect(function()
  if not settings.antiAFK then return end
  VirtualUser:Button2Down(Vector2.new(0,0)); task.wait(0.1); VirtualUser:Button2Up(Vector2.new(0,0))
  addLog("AFK","Idled tick")
end)
pcall(function() VirtualUser:CaptureController() end)

task.spawn(function()
  while true do
    if settings.antiAFK then
      local now = os.clock()
      if now - lastAfkTick >= settings.afkClickInterval then
        pcall(function() VirtualUser:Button2Down(Vector2.new(0,0)); task.wait(0.05); VirtualUser:Button2Up(Vector2.new(0,0)) end)
        lastAfkTick = now
        addLog("AFK","Periodic tick")
      end
    end
    task.wait(1)
  end
end)

-- FPS smoothing + stats/watchdog loop
RunService.RenderStepped:Connect(function(dt)
  local inst = 1/math.max(dt, 1/240)
  fps = fps + (inst - fps)*0.2
end)

task.spawn(function()
  while true do
    local t1 = os.clock(); task.wait(settings.checkInterval); local t2 = os.clock()
    local d = t2 - t1
    if d > settings.heartbeatThreshold then
      glitchCount += 1
      addLog("WATCH", ("Lag: %.2fs (%d)"):format(d, glitchCount))
    else
      glitchCount = math.max(0, glitchCount-1)
    end

    if glitchCount >= settings.glitchCountThreshold then
      if settings.autoAction == "Respawn" then
        addLog("ACTION","Threshold -> Respawn")
        task.delay(settings.rejoinDelay, function() pcall(function() player:LoadCharacter() end) end)
      elseif settings.autoAction == "Rejoin" then
        addLog("ACTION","Threshold -> Rejoin")
        task.delay(settings.rejoinDelay, function() pcall(function() serverHop(game.PlaceId) end) end)
      else
        addLog("WATCH","Threshold -> None")
      end
      glitchCount = 0
    end

    local elapsed = os.clock() - startTime
	local days = math.floor(elapsed / 86400)
	local remaining = elapsed % 86400
    local hours = math.floor(remaining / 3600)
	remaining = remaining % 3600
    local minutes = math.floor(remaining / 60)
    local seconds = math.floor(remaining % 60)
    local pingItem = StatsSvc.Network.ServerStatsItem["Data Ping"]
    local ping = pingItem and pingItem:GetValue() or 0
    local ram  = math.floor(StatsSvc:GetTotalMemoryUsageMb())
    local cpu  = math.min(100, math.floor((60/math.max(fps,1))*25)) -- approx
    local strHours = string.format("%02d", hours)
    local strMinutes = string.format("%02d", minutes)
    local strSeconds = string.format("%02d", seconds)

    -- statusLbl.Text = ("Status: Running | AFK: %s | FPS: %d | Action: %s | Rejoin: %s")
    statusLbl.Text = ("✅|AFK: %s|FPS: %d|Action: %s|Rejoin: %s")
      :format(tostring(settings.antiAFK), math.floor(fps+0.5), settings.autoAction, settings.autoReconnect and "ON" or "OFF")
    -- sessionLbl.Text = ("In server: %d min"):format(minutes)
    sessionLbl.Text = ("In server: %dd %s:%s:%s"):format(days, strHours, strMinutes, strSeconds)
    sysLbl.Text = ("CPU: %d%% | RAM: %dMB | Ping: %dms"):format(cpu, ram, ping)
  end
end)

-- Splash + bottom-right hint
if settings.showSplash then
  local splash = Instance.new("TextLabel")
  splash.Size = UDim2.new(0, 430, 0, 100)
  splash.Position = UDim2.new(0.5, -215, 0.18, -50)
  splash.BackgroundColor3 = Color3.fromRGB(25,25,32)
  splash.BorderSizePixel = 0
  splash.Font = Enum.Font.GothamBold
  splash.TextSize = 38
  splash.Text = "AntiAFK-X"
  splash.TextColor3 = Color3.fromRGB(255,140,100)
  splash.Parent = screenGui
  Instance.new("UICorner", splash).CornerRadius = UDim.new(0,16)
  local sStroke = Instance.new("UIStroke", splash); sStroke.Thickness=1; sStroke.Color=Color3.fromRGB(90,90,110)
  splash.TextTransparency = 1; splash.BackgroundTransparency = 1
  TweenService:Create(splash, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    {TextTransparency=0, BackgroundTransparency=0.08}):Play()
  task.wait(1.0)
  TweenService:Create(splash, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
    {TextTransparency=1, BackgroundTransparency=1}):Play()
  task.wait(0.26); splash:Destroy()

  -- bottom-right hint
  local note = Instance.new("TextLabel")
  note.AnchorPoint = Vector2.new(1,1)
  note.Position = UDim2.new(1, -10, 1, -10)
  note.Size = UDim2.new(0, 280, 0, 36)
  note.BackgroundColor3 = Color3.fromRGB(25,25,32)
  note.Text = "Press RightShift to open/close the menu"
  note.TextColor3 = Color3.fromRGB(240,240,240)
  note.TextSize = 14
  note.Font = Enum.Font.Gotham
  note.Parent = screenGui
  Instance.new("UICorner", note).CornerRadius = UDim.new(0,8)
  note.TextTransparency = 1; note.BackgroundTransparency = 1
  TweenService:Create(note, TweenInfo.new(0.35), {TextTransparency=0, BackgroundTransparency=0.1}):Play()
  task.wait(3.5)
  TweenService:Create(note, TweenInfo.new(0.4), {TextTransparency=1, BackgroundTransparency=1}):Play()
  task.wait(0.45); note:Destroy()
end

-- Show with slide-in & init
frame.Visible = true
frame.Position = UDim2.new(0.02, -24, 0.10, -12)
TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
  {Position=UDim2.new(0.02,0,0.12,0)}):Play()

addLog("INFO","AntiAFK-X initialized")
if settings.autoReconnect then attachReconnectWatcher() end
