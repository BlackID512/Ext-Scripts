local replicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = game:GetService("Players").LocalPlayer
local infenergy = false
local autoconvert = false
local killall = false
local instantkill = false
local multiplier = 500
local gunmods = false
local collectmoney = false
local automerge = false
local autobuy = false
local buyamount = ""
local autoupgrade = false
local tycoon
for _,v in workspace.Tycoon.Tycoons:GetChildren() do
    if v.Owner.Value == localPlayer then
        tycoon = v
    end
end

local Library = loadstring(Game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wizard"))()
local Window = Library:NewWindow("Credit: Neutral")
 
local CurrencyTab = Window:NewSection("Currency")
 
CurrencyTab:CreateToggle("infinite energy", function(value)
infenergy = value
end)

CurrencyTab:CreateToggle("auto convert energy", function(value)
autoconvert = value
end)

CurrencyTab:CreateToggle("money aura", function(value)
collectmoney = value
end)

local WeaponsTab = Window:NewSection("Weapons")

WeaponsTab:CreateToggle("kill all zombies", function(value)
killall = value
end)

WeaponsTab:CreateToggle("instant kill", function(value)
instantkill = value
end)

WeaponsTab:CreateSlider("Multiplier",1,10,1,false,function(value)
multiplier = value
end)

WeaponsTab:CreateToggle("gun modifications", function(value)
gunmods = value
end)

local TycoonTab = Window:NewSection("Tycoon")

TycoonTab:CreateToggle("auto buy towers", function(value)
autobuy = value
end)

TycoonTab:CreateDropdown("Amount", {"","3","10","30","50","100","1000","10000"},1,function(amount)
buyamount = amount
end)

TycoonTab:CreateToggle("auto merge towers", function(value)
automerge = value
end)

TycoonTab:CreateToggle("auto upgrade convert", function(value)
autoupgrade = value
end)


game:GetService("RunService").RenderStepped:Connect(function(delta)
    local character = localPlayer.Character
    local tier = localPlayer:GetAttribute("Tier")
    local tool = character:FindFirstChildWhichIsA("Tool")
    local gun 
    if tool and tool:FindFirstChild("GunClient") and tool:FindFirstChild("Configuration") then
        gun = tool
    end

    if infenergy then
        replicatedStorage.Signals.RemoteEvents.GetWoolRemote:FireServer(tier)
    end
    if autoconvert then
        replicatedStorage.Signals.RemoteEvents.PutRemote:FireServer()
    end
    if collectmoney then
        for _,v in workspace:GetChildren() do
            if v.Name == "Money" then
                firetouchinterest(v,character.HumanoidRootPart,0)
                firetouchinterest(v,character.HumanoidRootPart,1)
            end
        end
    end
    if gunmods and gun then
        if gun.Configuration:FindFirstChild("Automatic") and tool.Configuration.Automatic.Value == false then
            gun.Configuration.Automatic.Value = true
        end
        if gun.Configuration:FindFirstChild("Firerate") and gun.Configuration.Firerate.Value > 0 then
            gun.Configuration.Firerate.Value = 0
        end
        if gun.Configuration:FindFirstChild("ReloadTime") and gun.Configuration.ReloadTime.Value > 0 then
            gun.Configuration.ReloadTime.Value = 0
        end
    end
    for i = 1,multiplier do
        if killall and gun then
            for _,v in tycoon.Round:GetChildren() do
                if v:FindFirstChild("Humanoid") then
                    gun.Remotes.CastRay:FireServer(vector.create(1,1,1),v.Humanoid,true)
                    if instantkill then
                        v.Humanoid.Health = 0
                    end
                end
            end
        end
    end
    if autobuy and tycoon then
        firetouchinterest(tycoon.Buttons_E["Add"..buyamount].Head,character.HumanoidRootPart,0)
        firetouchinterest(tycoon.Buttons_E["Add"..buyamount].Head,character.HumanoidRootPart,1)
    end
    if automerge and tycoon then
        firetouchinterest(tycoon.Buttons_E.Merge.Head,character.HumanoidRootPart,0)
        firetouchinterest(tycoon.Buttons_E.Merge.Head,character.HumanoidRootPart,1)
    end
    if autoupgrade and tycoon then
        firetouchinterest(tycoon.Buttons_E.Upgrade.Head,character.HumanoidRootPart,0)
        firetouchinterest(tycoon.Buttons_E.Upgrade.Head,character.HumanoidRootPart,1)
    end
end)
