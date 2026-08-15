-- Delta Executor Compatible | Permanent Memory Mobile UI Editor V50 (Perfected Core & Zero Lag)
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

if not game:IsLoaded() then game.Loaded:Wait() end

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ==========================================
-- FAILSAFE UI LOADER & CLEANUP
-- ==========================================
local TargetParent = PlayerGui
pcall(function()
    if gethui and gethui() then TargetParent = gethui()
    elseif CoreGui then TargetParent = CoreGui end
end)

pcall(function()
    for _, v in pairs(TargetParent:GetChildren()) do
        if v.Name == "PerfectUIManager_Shield" or v.Name == "PerfectUIManager_UI" then v:Destroy() end
    end
    RunService:UnbindFromRenderStep("OmniTracker_Enforce")
end)

-- Main Variables
local EditModeActive = false
local SelectedElement = nil
local SelectedCluster = {} 
local RuleMap = {} 
local KnownTrackedObjects = {} 
local isMenuLocked = false 
local Connections = {} 
local isDraggingElement = false

-- NEW: Store true originals BEFORE any script modification
local OriginalPositions = {}
local OriginalSizes = {}
local BakedParents = {} -- Track which parents had layouts destroyed

-- ==========================================
-- V50 CORE: OMNI-TRACKER KEY GENERATOR
-- ==========================================
local function GetKey(obj)
    local keyStr = obj.Name
    local trait = ""
    
    if obj.Name == "ContextActionButton" then
        local title = obj:FindFirstChild("ActionTitle")
        if title and title:IsA("TextLabel") and title.Text ~= "" then 
            keyStr = "CAB_" .. title.Text 
        else
            local icon = obj:FindFirstChild("ActionIcon")
            if icon and icon:IsA("ImageLabel") and icon.Image ~= "" then 
                local imgId = string.match(icon.Image, "%d+")
                keyStr = "CAB_IMG_" .. (imgId or "ICO")
            end
        end
    else
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            if obj.Text ~= "" then trait = trait .. "_" .. string.sub(obj.Text, 1, 10) end
        elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
            if obj.Image ~= "" then 
                local id = string.match(obj.Image, "%d+")
                if id then trait = trait .. "_IMG" .. id end
            end
        end
    end
    
    local siblingIndex = 1
    if obj.Parent then
        local baseKey = obj.Parent.Name .. "_" .. keyStr
        keyStr = baseKey
        for _, child in ipairs(obj.Parent:GetChildren()) do
            if child == obj then break end
            if child.Name == obj.Name and child.ClassName == obj.ClassName then
                siblingIndex = siblingIndex + 1
            end
        end
        if siblingIndex > 1 then
            trait = trait .. "_IDX" .. siblingIndex
        end
    end

    return keyStr .. trait
end

local function GetSafeVisualPosition(gui)
    local parent = gui.Parent
    if parent and parent:IsA("GuiObject") then
        local pX, pY = parent.AbsolutePosition.X, parent.AbsolutePosition.Y
        if parent:IsA("ScrollingFrame") then
            pX = pX - parent.CanvasPosition.X
            pY = pY - parent.CanvasPosition.Y
        end
        local aX, aY = gui.AnchorPoint.X, gui.AnchorPoint.Y
        local w, h = gui.AbsoluteSize.X, gui.AbsoluteSize.Y
        local dX, dY = gui.AbsolutePosition.X, gui.AbsolutePosition.Y
        return UDim2.new(0, (dX - pX) + (aX * w), 0, (dY - pY) + (aY * h))
    else
        return gui.Position
    end
end

-- ==========================================
-- SAFE ORIGINAL CAPTURE
-- Captures position/size ONLY if not yet stored, 
-- and ONLY before the layout is destroyed
-- ==========================================
local function CaptureOriginalIfNeeded(obj)
    local key = GetKey(obj)
    if not OriginalPositions[key] then
        -- Store the real game-assigned position/size before we touch anything
        OriginalPositions[key] = obj.Position
        OriginalSizes[key] = obj.Size
    end
end

-- ZERO-LAG EVENT SYSTEM
local function ScanSingleObject(obj)
    if obj:IsA("GuiObject") and not obj:IsDescendantOf(TargetParent) then
        local key = GetKey(obj)
        if RuleMap[key] then KnownTrackedObjects[obj] = key end
    end
end

local function ForceScanUI()
    pcall(function()
        for _, obj in ipairs(PlayerGui:GetDescendants()) do
            ScanSingleObject(obj)
        end
    end)
end

local descAddedConn = PlayerGui.DescendantAdded:Connect(function(obj)
    if not next(RuleMap) then return end
    task.defer(function() ScanSingleObject(obj) end)
end)
table.insert(Connections, descAddedConn)

-- ==========================================
-- EDITOR UI CREATION
-- ==========================================
local ShieldGui = Instance.new("ScreenGui")
ShieldGui.Name = "PerfectUIManager_Shield"
ShieldGui.ResetOnSpawn = false
ShieldGui.DisplayOrder = 99998 
ShieldGui.Parent = TargetParent

local TapShield = Instance.new("TextButton")
TapShield.Size = UDim2.new(1, 0, 1, 0)
TapShield.BackgroundTransparency = 1 
TapShield.Text = ""
TapShield.Active = false
TapShield.Visible = false
TapShield.Parent = ShieldGui

local EditorGui = Instance.new("ScreenGui")
EditorGui.Name = "PerfectUIManager_UI"
EditorGui.ResetOnSpawn = false
EditorGui.DisplayOrder = 99999 
EditorGui.Parent = TargetParent

local function CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius == "100%" and UDim.new(1, 0) or UDim.new(0, radius)
    corner.Parent = parent
end

local function MakeDraggable(gui, isActionPopup)
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if isActionPopup and isMenuLocked then return end 
            dragging = true; dragInput = input; dragStart = input.Position; startPos = gui.Position
        end
    end)
    local dragConn = UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    local endConn = UserInputService.InputEnded:Connect(function(input)
        if input == dragInput then dragging = false; dragInput = nil end
    end)
    table.insert(Connections, dragConn); table.insert(Connections, endConn) 
end

local OpenCloseBtn = Instance.new("TextButton")
OpenCloseBtn.Size = UDim2.new(0, 45, 0, 45)
OpenCloseBtn.Position = UDim2.new(1, -60, 0.5, -22) 
OpenCloseBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
OpenCloseBtn.BackgroundTransparency = 0.4
OpenCloseBtn.Text = "⚙️"
OpenCloseBtn.TextSize = 22
OpenCloseBtn.ZIndex = 999
OpenCloseBtn.Parent = EditorGui
CreateCorner(OpenCloseBtn, "100%") 
MakeDraggable(OpenCloseBtn, false)

local MainHub = Instance.new("Frame")
MainHub.Size = UDim2.new(0, 150, 0, 165)
MainHub.Position = UDim2.new(0, 10, 0.5, -82)
MainHub.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainHub.BackgroundTransparency = 0.4
MainHub.Active = true
MainHub.Visible = false
MainHub.Parent = EditorGui
CreateCorner(MainHub, 20) 
MakeDraggable(MainHub, false)

local function createHubButton(name, pos, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 25)
    btn.Position = UDim2.new(0.05, 0, 0, pos)
    btn.BackgroundColor3 = color
    btn.BackgroundTransparency = 0.4 
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = MainHub
    CreateCorner(btn, "100%") 
    return btn
end

local ToggleEditBtn = createHubButton("Edit Mode: OFF", 10, Color3.fromRGB(50, 150, 255))
local SaveConfigBtn = createHubButton("Save Config", 40, Color3.fromRGB(50, 200, 100))
local LoadConfigBtn = createHubButton("Load Config", 70, Color3.fromRGB(200, 150, 0))
local TrashBtn      = createHubButton("Trash (0)", 100, Color3.fromRGB(255, 70, 70))
local DestroyScriptBtn = createHubButton("Remove Script ❌", 130, Color3.fromRGB(200, 40, 40))

-- CONFIRMATION POPUP UI
local ConfirmPopup = Instance.new("Frame")
ConfirmPopup.Size = UDim2.new(0, 260, 0, 120)
ConfirmPopup.Position = UDim2.new(0.5, -130, 0.5, -60)
ConfirmPopup.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
ConfirmPopup.Visible = false
ConfirmPopup.ZIndex = 9999999
ConfirmPopup.Active = true
ConfirmPopup.Parent = EditorGui
CreateCorner(ConfirmPopup, 15)

local ConfirmText = Instance.new("TextLabel")
ConfirmText.Size = UDim2.new(0.9, 0, 0.5, 0)
ConfirmText.Position = UDim2.new(0.05, 0, 0.05, 0)
ConfirmText.BackgroundTransparency = 1
ConfirmText.TextWrapped = true
ConfirmText.TextColor3 = Color3.fromRGB(255, 255, 255)
ConfirmText.Font = Enum.Font.GothamBold
ConfirmText.ZIndex = 9999999
ConfirmText.Parent = ConfirmPopup

local ConfirmYesBtn = Instance.new("TextButton")
ConfirmYesBtn.Size = UDim2.new(0.4, 0, 0.3, 0)
ConfirmYesBtn.Position = UDim2.new(0.06, 0, 0.6, 0)
ConfirmYesBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ConfirmYesBtn.Text = "Yes"
ConfirmYesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ConfirmYesBtn.Font = Enum.Font.GothamBold
ConfirmYesBtn.ZIndex = 9999999
ConfirmYesBtn.Parent = ConfirmPopup
CreateCorner(ConfirmYesBtn, 8)

local ConfirmNoBtn = Instance.new("TextButton")
ConfirmNoBtn.Size = UDim2.new(0.4, 0, 0.3, 0)
ConfirmNoBtn.Position = UDim2.new(0.54, 0, 0.6, 0)
ConfirmNoBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
ConfirmNoBtn.Text = "Cancel"
ConfirmNoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ConfirmNoBtn.Font = Enum.Font.GothamBold
ConfirmNoBtn.ZIndex = 9999999
ConfirmNoBtn.Parent = ConfirmPopup
CreateCorner(ConfirmNoBtn, 8)

local currentYesConn, currentNoConn = nil, nil
local function ShowConfirm(text, onYes)
    ConfirmText.Text = text
    ConfirmPopup.Visible = true
    if currentYesConn then currentYesConn:Disconnect() end
    if currentNoConn then currentNoConn:Disconnect() end

    currentYesConn = ConfirmYesBtn.MouseButton1Click:Connect(function()
        ConfirmPopup.Visible = false
        if currentYesConn then currentYesConn:Disconnect() end
        if currentNoConn then currentNoConn:Disconnect() end
        if onYes then onYes() end
    end)
    currentNoConn = ConfirmNoBtn.MouseButton1Click:Connect(function()
        ConfirmPopup.Visible = false
        if currentYesConn then currentYesConn:Disconnect() end
        if currentNoConn then currentNoConn:Disconnect() end
    end)
end

local function createPanel(titleText, width)
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, width or 240, 0, 250)
    panel.Position = UDim2.new(0.5, -(width or 240)/2, 0.5, -125) 
    panel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    panel.BackgroundTransparency = 0.4 
    panel.Visible = false
    panel.Active = true
    panel.Parent = EditorGui
    CreateCorner(panel, 20)
    MakeDraggable(panel, false)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 25)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Parent = panel

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -10, 1, -35)
    scroll.Position = UDim2.new(0, 5, 0, 30)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = scroll
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)
    return panel, scroll, title
end

local TrashPanel, TrashScroll, TrashTitle = createPanel("Deleted UI", 240)
local LoadPanel, LoadScroll, LoadTitle = createPanel("Choose a Save File", 280)

local ActionPopup = Instance.new("Frame")
ActionPopup.Size = UDim2.new(0, 245, 0, 50) 
ActionPopup.Position = UDim2.new(0.5, -122, 0.15, 0)
ActionPopup.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
ActionPopup.BackgroundTransparency = 0.4 
ActionPopup.Active = true
ActionPopup.Visible = false
ActionPopup.Parent = EditorGui
CreateCorner(ActionPopup, "100%") 
MakeDraggable(ActionPopup, true) 

local function createActionButton(name, pos, width, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, width, 0, 40)
    btn.Position = UDim2.new(0, pos, 0, 5)
    btn.BackgroundColor3 = color
    btn.BackgroundTransparency = 0.4 
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = ActionPopup
    CreateCorner(btn, "100%") 
    return btn
end

local BtnLock = createActionButton("🔓", 5, 40, Color3.fromRGB(60, 60, 70))
local BtnPlus = createActionButton("+ Size", 50, 60, Color3.fromRGB(50, 150, 255))
local BtnMinus = createActionButton("- Size", 115, 60, Color3.fromRGB(50, 150, 255))
local BtnDelete = createActionButton("Delete", 180, 60, Color3.fromRGB(255, 50, 50))

local SelectionFrame = Instance.new("Frame")
SelectionFrame.Name = "PerfectUI_SelectionFrame"
SelectionFrame.BackgroundTransparency = 1
SelectionFrame.Visible = false
SelectionFrame.ZIndex = 999999
SelectionFrame.Active = false 
pcall(function() SelectionFrame.Interactable = false end)
SelectionFrame.Parent = EditorGui

local SelectionStroke = Instance.new("UIStroke")
SelectionStroke.Color = Color3.fromRGB(0, 255, 255)
SelectionStroke.Thickness = 2
SelectionStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
SelectionStroke.Parent = SelectionFrame

local function ClearSelection()
    SelectedElement = nil
    SelectedCluster = {}
    isDraggingElement = false
    SelectionFrame.Visible = false
end

-- ==========================================
-- 60FPS RENDER LOOP (Zero Lag version)
-- ==========================================
RunService:BindToRenderStep("OmniTracker_Enforce", 2000, function()
    if EditModeActive and SelectedElement and SelectedElement.Parent and SelectedElement.Visible then
        SelectionFrame.Visible = true
        SelectionFrame.Size = UDim2.new(0, SelectedElement.AbsoluteSize.X, 0, SelectedElement.AbsoluteSize.Y)
        SelectionFrame.Position = UDim2.new(0, SelectedElement.AbsolutePosition.X, 0, SelectedElement.AbsolutePosition.Y)
    else
        SelectionFrame.Visible = false
    end

    if not next(RuleMap) then return end 

    for obj, key in pairs(KnownTrackedObjects) do
        if not obj.Parent then
            KnownTrackedObjects[obj] = nil
            continue
        end

        local rule = RuleMap[key]
        if rule then
            if rule.IsDeleted then
                if obj.Visible then obj.Visible = false end
            else
                local parent = obj.Parent
                -- ==========================================
                -- FIXED LAYOUT BAKER
                -- Now captures originals BEFORE destroying layout
                -- ==========================================
                if parent and not parent:GetAttribute("Baked_Layout") then
                    local layout = parent:FindFirstChildWhichIsA("UILayout") or parent:FindFirstChildWhichIsA("UIGridStyleLayout")
                    if layout then
                        if parent.AbsoluteSize.X > 0 then
                            local ready = true
                            local cache = {}
                            for _, child in ipairs(parent:GetChildren()) do
                                if child:IsA("GuiObject") then
                                    if child.AbsoluteSize.X == 0 and child.Visible then ready = false break end
                                    if child.Visible then
                                        cache[child] = { X=child.AbsolutePosition.X, Y=child.AbsolutePosition.Y, W=child.AbsoluteSize.X, H=child.AbsoluteSize.Y }
                                    end
                                end
                            end
                            if ready then
                                parent:SetAttribute("Baked_Layout", true)
                                
                                -- Capture originals for ALL children BEFORE we modify anything
                                for c, d in pairs(cache) do
                                    local cKey = GetKey(c)
                                    if not OriginalPositions[cKey] then
                                        OriginalPositions[cKey] = c.Position
                                        OriginalSizes[cKey] = c.Size
                                    end
                                end
                                
                                for c, d in pairs(cache) do c.Size = UDim2.new(0, d.W, 0, d.H) end
                                layout:Destroy()
                                
                                local pX, pY = parent.AbsolutePosition.X, parent.AbsolutePosition.Y
                                if parent:IsA("ScrollingFrame") then
                                    pX = pX - parent.CanvasPosition.X
                                    pY = pY - parent.CanvasPosition.Y
                                end
                                for c, d in pairs(cache) do
                                    local aX, aY = c.AnchorPoint.X, c.AnchorPoint.Y
                                    local bakedPos = UDim2.new(0, (d.X - pX) + (aX * d.W), 0, (d.Y - pY) + (aY * d.H))
                                    c.Position = bakedPos
                                    
                                    -- Update originals to reflect the baked position
                                    -- (since the layout is gone, baked = original from now on)
                                    local cKey = GetKey(c)
                                    OriginalPositions[cKey] = bakedPos
                                    OriginalSizes[cKey] = UDim2.new(0, d.W, 0, d.H)
                                end
                            end
                        end
                    else
                        parent:SetAttribute("Baked_Layout", true)
                    end
                end

                local isBeingDragged = false
                if isDraggingElement then
                    for _, clusterEl in ipairs(SelectedCluster) do
                        if clusterEl == obj then
                            isBeingDragged = true
                            break
                        end
                    end
                end

                if not isBeingDragged then
                    if obj.Position ~= rule.Position then obj.Position = rule.Position end
                    if rule.SizeModified and obj.Size ~= rule.Size then obj.Size = rule.Size end
                end
            end
        else
            KnownTrackedObjects[obj] = nil
        end
    end
end)

-- ==========================================
-- SAVE / LOAD / AUTO-EXECUTE HELPERS
-- ==========================================
local GameID = tostring(game.GameId > 0 and game.GameId or game.PlaceId)
local FolderName = "PerfectUIManager_Configs"
local CleanGameName = "UnknownGame"

local UpdateTrashUI

pcall(function()
    local info = MarketplaceService:GetProductInfo(game.PlaceId)
    if info and info.Name then CleanGameName = string.gsub(info.Name, '[\\/:*?"<>|]', '') end
end)

local function SafeMakeFolder()
    if makefolder and not isfolder(FolderName) then pcall(function() makefolder(FolderName) end) end
end

local function GetAutoExecuteData()
    local path = FolderName .. "/AutoExecuteData.json"
    if isfile and isfile(path) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if success and type(data) == "table" then return data end
    end
    return {}
end

local function SaveAutoExecuteData(data)
    local path = FolderName .. "/AutoExecuteData.json"
    if writefile then pcall(function() writefile(path, HttpService:JSONEncode(data)) end) end
end

local function LoadSpecificFile(filePath)
    local success, result = pcall(function() return HttpService:JSONDecode(readfile(filePath)) end)
    if success and result then
        for key, savedData in pairs(result) do
            RuleMap[key] = {
                Name = savedData.Name,
                IsDeleted = savedData.IsDeleted,
                Position = UDim2.new(unpack(savedData.Position)),
                Size = UDim2.new(unpack(savedData.Size)),
                SizeModified = savedData.SizeModified or false 
            }
        end
        ForceScanUI() 
        if UpdateTrashUI then UpdateTrashUI() end
        LoadPanel.Visible = false
        LoadConfigBtn.Text = "Load Complete!"
        task.wait(1.5)
        LoadConfigBtn.Text = "Load Config"
    end
end

local function RefreshLoadMenu()
    if not listfiles then return end
    for _, child in pairs(LoadScroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    
    local files = listfiles(FolderName)
    local foundSaves = false
    local autoData = GetAutoExecuteData()
    
    for _, file in ipairs(files) do
        if string.find(file, GameID .. ".json") then
            foundSaves = true
            local displayName = file:match("([^/]+)_" .. GameID .. ".json$")
            
            local row = Instance.new("Frame")
            row.Size = UDim2.new(0.95, 0, 0, 30)
            row.BackgroundTransparency = 1
            row.Parent = LoadScroll
            
            local loadBtn = Instance.new("TextButton")
            loadBtn.Size = UDim2.new(0.55, 0, 1, 0)
            loadBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
            loadBtn.BackgroundTransparency = 0.4
            loadBtn.Text = "📥 Load: " .. (displayName or "Save File")
            loadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            loadBtn.Font = Enum.Font.GothamBold
            loadBtn.TextSize = 10
            loadBtn.TextScaled = true
            loadBtn.Parent = row
            CreateCorner(loadBtn, "100%")
            
            local isAuto = (autoData[GameID] == file)
            local autoBtn = Instance.new("TextButton")
            autoBtn.Size = UDim2.new(0.24, 0, 1, 0)
            autoBtn.Position = UDim2.new(0.58, 0, 0, 0)
            autoBtn.BackgroundColor3 = isAuto and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(80, 80, 100)
            autoBtn.BackgroundTransparency = 0.4
            autoBtn.Text = isAuto and "Auto: ON" or "Auto: OFF"
            autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            autoBtn.Font = Enum.Font.GothamBold
            autoBtn.TextSize = 10
            autoBtn.Parent = row
            CreateCorner(autoBtn, "100%")
            
            local delFileBtn = Instance.new("TextButton")
            delFileBtn.Size = UDim2.new(0.15, 0, 1, 0)
            delFileBtn.Position = UDim2.new(0.85, 0, 0, 0)
            delFileBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
            delFileBtn.BackgroundTransparency = 0.4
            delFileBtn.Text = "🗑️"
            delFileBtn.Parent = row
            CreateCorner(delFileBtn, "100%")
            
            loadBtn.MouseButton1Click:Connect(function() LoadSpecificFile(file) end)
            
            autoBtn.MouseButton1Click:Connect(function()
                local currentData = GetAutoExecuteData()
                if currentData[GameID] == file then currentData[GameID] = nil
                else currentData[GameID] = file end
                SaveAutoExecuteData(currentData)
                RefreshLoadMenu()
            end)
            
            delFileBtn.MouseButton1Click:Connect(function()
                ShowConfirm("Are you sure you want to delete this setting?", function()
                    if delfile then pcall(function() delfile(file) end) end
                    RefreshLoadMenu()
                end)
            end)
        end
    end
    LoadTitle.Text = foundSaves and "Choose a Save File" or "No saves for this game!"
end

UpdateTrashUI = function()
    for _, child in pairs(TrashScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    local delCount = 0
    for key, data in pairs(RuleMap) do
        if data.IsDeleted then
            delCount = delCount + 1
            local restoreBtn = Instance.new("TextButton")
            restoreBtn.Size = UDim2.new(0.95, 0, 0, 30)
            restoreBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 200)
            restoreBtn.BackgroundTransparency = 0.4
            restoreBtn.Text = "  ↺ Restore: " .. (data.Name or "Element")
            restoreBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            restoreBtn.Font = Enum.Font.GothamBold
            restoreBtn.TextSize = 12
            restoreBtn.TextXAlignment = Enum.TextXAlignment.Left
            restoreBtn.Parent = TrashScroll
            CreateCorner(restoreBtn, "100%")
            
            restoreBtn.MouseButton1Click:Connect(function()
                -- ==========================================
                -- FIXED RESTORE: Puts element back to its
                -- true original position/size, not a broken one
                -- ==========================================
                for obj, matchedKey in pairs(KnownTrackedObjects) do
                    if matchedKey == key then
                        if obj.Parent then 
                            obj.Visible = true
                            -- Restore to original captured position if we have it
                            if OriginalPositions[key] then
                                obj.Position = OriginalPositions[key]
                            end
                            -- Restore to original captured size if we have it
                            if OriginalSizes[key] then
                                obj.Size = OriginalSizes[key]
                            end
                        end
                        KnownTrackedObjects[obj] = nil -- Stop enforcing position
                    end
                end
                
                RuleMap[key] = nil -- Remove our override entirely
                -- Keep OriginalPositions/OriginalSizes so if it gets touched again it still has reference
                
                UpdateTrashUI()
            end)
        end
    end
    TrashBtn.Text = "Trash (" .. delCount .. ")"
    TrashTitle.Text = "Deleted UI (" .. delCount .. ")"
end

task.spawn(function()
    SafeMakeFolder()
    local autoData = GetAutoExecuteData()
    if autoData[GameID] and isfile(autoData[GameID]) then LoadSpecificFile(autoData[GameID]) end
end)

-- ==========================================
-- MENU LOGIC & EDITOR INTERACTIONS
-- ==========================================
local activeDragInput = nil
local dragStartInputPos = nil
local initialClusterPositions = {}

local toggleDragStart = nil
OpenCloseBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then toggleDragStart = input.Position end
end)
OpenCloseBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if toggleDragStart and (input.Position - toggleDragStart).Magnitude < 10 then
            MainHub.Visible = not MainHub.Visible
            if not MainHub.Visible then
                TrashPanel.Visible = false; LoadPanel.Visible = false; ActionPopup.Visible = false
                if EditModeActive then
                    EditModeActive = false
                    ToggleEditBtn.Text = "Edit Mode: OFF"
                    ToggleEditBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
                    TapShield.Visible = false; TapShield.Active = false
                    ClearSelection()
                    activeDragInput = nil
                end
            end
        end
    end
end)

ToggleEditBtn.MouseButton1Click:Connect(function()
    EditModeActive = not EditModeActive
    if EditModeActive then
        ToggleEditBtn.Text = "Edit Mode: ON"
        ToggleEditBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        TapShield.Visible = true; TapShield.Active = true; ActionPopup.Visible = true 
    else
        ToggleEditBtn.Text = "Edit Mode: OFF"
        ToggleEditBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
        TapShield.Visible = false; TapShield.Active = false; ActionPopup.Visible = false 
        ClearSelection() 
        activeDragInput = nil
    end
end)

BtnLock.MouseButton1Click:Connect(function()
    isMenuLocked = not isMenuLocked
    if isMenuLocked then BtnLock.Text = "🔒" else BtnLock.Text = "🔓" end
end)

local function ModifySize(increment)
    if SelectedElement and #SelectedCluster > 0 then
        for _, el in ipairs(SelectedCluster) do
            local key = GetKey(el)
            
            local currentVisualSize = el.Size
            if currentVisualSize == UDim2.new(0,0,0,0) then
                currentVisualSize = UDim2.new(0, el.AbsoluteSize.X, 0, el.AbsoluteSize.Y)
            end
            
            if not RuleMap[key] then 
                RuleMap[key] = { Name = el.Name, IsDeleted = false, Position = GetSafeVisualPosition(el), Size = currentVisualSize, SizeModified = false } 
            end
            
            RuleMap[key].SizeModified = true 
            local s = RuleMap[key].Size
            local newSize = UDim2.new(s.X.Scale, s.X.Offset + increment, s.Y.Scale, s.Y.Offset + increment)
            RuleMap[key].Size = newSize
            el.Size = newSize
        end
    end
end

BtnPlus.MouseButton1Click:Connect(function() ModifySize(15) end)
BtnMinus.MouseButton1Click:Connect(function() ModifySize(-15) end)

BtnDelete.MouseButton1Click:Connect(function()
    if SelectedElement and #SelectedCluster > 0 then
        for _, el in ipairs(SelectedCluster) do
            local key = GetKey(el)
            local currentVisualSize = el.Size
            if currentVisualSize == UDim2.new(0,0,0,0) then currentVisualSize = UDim2.new(0, el.AbsoluteSize.X, 0, el.AbsoluteSize.Y) end
            
            if not RuleMap[key] then RuleMap[key] = { Name = el.Name, Position = GetSafeVisualPosition(el), Size = currentVisualSize, SizeModified = false } end
            RuleMap[key].IsDeleted = true
            el.Visible = false 
        end
        ClearSelection()
        UpdateTrashUI()
    end
end)

TrashBtn.MouseButton1Click:Connect(function() LoadPanel.Visible = false; TrashPanel.Visible = not TrashPanel.Visible end)
LoadConfigBtn.MouseButton1Click:Connect(function() TrashPanel.Visible = false; LoadPanel.Visible = not LoadPanel.Visible; if LoadPanel.Visible then RefreshLoadMenu() end end)

DestroyScriptBtn.MouseButton1Click:Connect(function()
    ShowConfirm("Are you sure you want to delete the script?", function()
        for _, conn in pairs(Connections) do if conn and conn.Connected then conn:Disconnect() end end
        pcall(function() RunService:UnbindFromRenderStep("OmniTracker_Enforce") end)
        if ShieldGui then ShieldGui:Destroy() end
        if EditorGui then EditorGui:Destroy() end
        KnownTrackedObjects = nil
        RuleMap = nil
    end)
end)

SaveConfigBtn.MouseButton1Click:Connect(function()
    if writefile then
        SafeMakeFolder()
        local versionNumber = 1
        local savePath = ""
        while true do
            savePath = FolderName .. "/" .. CleanGameName .. "_v" .. versionNumber .. "_" .. GameID .. ".json"
            if not isfile(savePath) then break end
            versionNumber = versionNumber + 1
        end
        local dataToSave = {}
        for key, rule in pairs(RuleMap) do
            dataToSave[key] = {
                Name = rule.Name, 
                IsDeleted = rule.IsDeleted, 
                Position = {rule.Position.X.Scale, rule.Position.X.Offset, rule.Position.Y.Scale, rule.Position.Y.Offset},
                Size = {rule.Size.X.Scale, rule.Size.X.Offset, rule.Size.Y.Scale, rule.Size.Y.Offset},
                SizeModified = rule.SizeModified or false
            }
        end
        writefile(savePath, HttpService:JSONEncode(dataToSave))
        RefreshLoadMenu()
        SaveConfigBtn.Text = "Saved as v" .. versionNumber .. "!"
        task.wait(1.5)
        SaveConfigBtn.Text = "Save Config"
    end
end)

local function isJoystick(gui)
    local curr = gui
    while curr and curr:IsA("GuiObject") do
        local n = string.lower(curr.Name)
        if string.find(n, "thumbstick") or string.find(n, "joystick") then
            return true
        end
        curr = curr.Parent
    end
    return false
end

local function GetPerfectTarget(elementsAtTap, viewport)
    local maxW = viewport.X * 0.8
    local maxH = viewport.Y * 0.8
    
    local topElement = nil
    
    for _, gui in ipairs(elementsAtTap) do
        if gui:IsDescendantOf(EditorGui) or gui:IsDescendantOf(ShieldGui) then continue end
        if gui.AbsoluteSize.X >= maxW or gui.AbsoluteSize.Y >= maxH then continue end
        if isJoystick(gui) then continue end
        
        if gui:IsA("GuiButton") or gui:FindFirstChildWhichIsA("TouchTransmitter") then
            topElement = gui
            break
        end
    end
    
    if not topElement then
        for _, gui in ipairs(elementsAtTap) do
            if gui:IsDescendantOf(EditorGui) or gui:IsDescendantOf(ShieldGui) then continue end
            if gui.AbsoluteSize.X >= maxW or gui.AbsoluteSize.Y >= maxH then continue end
            if isJoystick(gui) then continue end
            
            if gui.Visible and (gui.BackgroundTransparency < 1 or gui:IsA("ImageLabel") or gui:IsA("TextLabel") or gui:IsA("TextBox") or gui:IsA("Frame")) then
                topElement = gui
                break
            end
        end
    end
    
    if topElement then
        local current = topElement.Parent
        local highestValid = topElement
        
        while current and current:IsA("GuiObject") do
            if current.AbsoluteSize.X >= maxW or current.AbsoluteSize.Y >= maxH then break end
            if isJoystick(current) then break end
            
            local hasOtherButtons = false
            for _, child in ipairs(current:GetChildren()) do
                if child ~= highestValid and child:IsA("GuiObject") and child.Visible then
                    if child:IsA("GuiButton") or child:FindFirstChildWhichIsA("TouchTransmitter") or child:FindFirstChildWhichIsA("GuiButton", true) or child:FindFirstChildWhichIsA("TouchTransmitter", true) then
                        hasOtherButtons = true
                        break
                    end
                end
            end
            
            if hasOtherButtons then
                break
            end

            local isBtn = current:IsA("GuiButton") or current:FindFirstChildWhichIsA("TouchTransmitter")
            local n = string.lower(current.Name)
            local isNamedBtn = string.find(n, "button") or string.find(n, "btn") or string.find(n, "shutter") or string.find(n, "action")
            
            if isBtn or isNamedBtn then
                highestValid = current
            elseif current.AbsoluteSize.X <= highestValid.AbsoluteSize.X + 30 and current.AbsoluteSize.Y <= highestValid.AbsoluteSize.Y + 30 then
                highestValid = current
            else
                break
            end
            
            current = current.Parent
        end
        
        return highestValid
    end
    
    return nil
end

local function GetCluster(target)
    local cluster = {target}
    local added = {[target] = true}

    if target.Parent then
        for _, child in ipairs(target.Parent:GetChildren()) do
            if child:IsA("GuiObject") and not added[child] then
                local cx1 = child.AbsolutePosition.X + child.AbsoluteSize.X/2
                local cy1 = child.AbsolutePosition.Y + child.AbsoluteSize.Y/2
                local cx2 = target.AbsolutePosition.X + target.AbsoluteSize.X/2
                local cy2 = target.AbsolutePosition.Y + target.AbsoluteSize.Y/2
                local dist = math.sqrt((cx1 - cx2)^2 + (cy1 - cy2)^2)
                
                if dist <= 10 and child.AbsoluteSize.X < 350 and child.AbsoluteSize.Y < 350 then
                    table.insert(cluster, child)
                    added[child] = true
                end
            end
        end
    end

    local parent = target.Parent
    if parent and parent:IsA("GuiObject") and not added[parent] then
        local px = parent.AbsolutePosition.X + parent.AbsoluteSize.X/2
        local py = parent.AbsolutePosition.Y + parent.AbsoluteSize.Y/2
        local tx = target.AbsolutePosition.X + target.AbsoluteSize.X/2
        local ty = target.AbsolutePosition.Y + target.AbsoluteSize.Y/2
        local pdist = math.sqrt((px - tx)^2 + (py - ty)^2)
        
        if pdist <= 10 and parent.AbsoluteSize.X <= target.AbsoluteSize.X * 1.5 and parent.AbsoluteSize.Y <= target.AbsoluteSize.Y * 1.5 then
            table.insert(cluster, parent)
            added[parent] = true
        end
    end

    local pureCluster = {}
    for _, el in ipairs(cluster) do
        local isChildOfAnother = false
        for _, other in ipairs(cluster) do
            if el ~= other and el:IsDescendantOf(other) then
                isChildOfAnother = true
                break
            end
        end
        if not isChildOfAnother then
            table.insert(pureCluster, el)
        end
    end

    return pureCluster
end

local inputBeganConn = UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if ConfirmPopup.Visible then return end 
        if not isMenuLocked then isDraggingElement = false; activeDragInput = nil end
        
        local guis = {MainHub, TrashPanel, LoadPanel, ActionPopup, OpenCloseBtn}
        for _, ui in ipairs(guis) do
            if ui.Visible then
                local p = ui.AbsolutePosition; local s = ui.AbsoluteSize; local pos = input.Position
                if pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y then return end
            end
        end
        if not EditModeActive then return end

        TapShield.Visible = false; SelectionFrame.Visible = false 
        
        local success, elementsAtTap = pcall(function() return PlayerGui:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y) end)
        local validElement = nil
        if success and elementsAtTap then validElement = GetPerfectTarget(elementsAtTap, game.Workspace.CurrentCamera.ViewportSize) end
        
        TapShield.Visible = true 
        
        if validElement then
            SelectedElement = validElement
            SelectedCluster = GetCluster(validElement) 
            
            isDraggingElement = true
            activeDragInput = input 
            dragStartInputPos = input.Position
            initialClusterPositions = {}
            
            for _, el in ipairs(SelectedCluster) do
                local key = GetKey(el)
                local currentVisualPos = GetSafeVisualPosition(el)
                
                local currentVisualSize = el.Size
                if currentVisualSize == UDim2.new(0,0,0,0) then
                    currentVisualSize = UDim2.new(0, el.AbsoluteSize.X, 0, el.AbsoluteSize.Y)
                end
                
                -- Capture original BEFORE we ever create a RuleMap entry
                if not OriginalPositions[key] then
                    OriginalPositions[key] = currentVisualPos
                    OriginalSizes[key] = currentVisualSize
                end
                
                if not RuleMap[key] then 
                    RuleMap[key] = { 
                        Name = el.Name, 
                        IsDeleted = false,
                        Position = currentVisualPos,
                        Size = currentVisualSize,
                        SizeModified = false
                    } 
                end
                
                initialClusterPositions[el] = RuleMap[key].Position 
                KnownTrackedObjects[el] = key 
                el.Position = RuleMap[key].Position
            end
        else
            ClearSelection()
        end
    end
end)
table.insert(Connections, inputBeganConn)

local inputChangedConn = UserInputService.InputChanged:Connect(function(input)
    if isDraggingElement and SelectedElement and input == activeDragInput and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        pcall(function()
            local totalDelta = input.Position - dragStartInputPos
            
            for _, el in ipairs(SelectedCluster) do
                local key = GetKey(el)
                local startPos = initialClusterPositions[el]
                local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + totalDelta.X, startPos.Y.Scale, startPos.Y.Offset + totalDelta.Y)
                
                RuleMap[key].Position = newPos
                el.Position = newPos
            end
        end)
    end
end)
table.insert(Connections, inputChangedConn)

local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
    if input == activeDragInput and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        isDraggingElement = false
        activeDragInput = nil 
    end
end)
table.insert(Connections, inputEndedConn)
