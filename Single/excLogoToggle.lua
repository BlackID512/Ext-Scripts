--[[
    Delta Hider
    Last Updated: 29th July 2026
]]

if identifyexecutor() ~= "Delta" then 
    warn("You are not using Delta.")
    return
end

local i = 0

for _, v in pairs(gethui():GetChildren()) do
    if v:IsA("ScreenGui") then

        local ImageButton = v:FindFirstChildOfClass("ImageButton");

        if ImageButton and tostring(ImageButton.Image):find("Logo.png", 1, true) then
            v.Enabled = false
            i = i + 1
        end

        if v:FindFirstChild("Console") and v:FindFirstChild("IsTween") and v:FindFirstChild("Executor") then
            v.Enabled = false
            i = i + 1
        end

        if i == 2 then 
            break
        end

    end
end
