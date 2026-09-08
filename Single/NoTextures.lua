local function StripTextures()
    for _, obj in ipairs(workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceAppearance") then
                obj.Transparency = 1
            end
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Sparkles") or obj:IsA("Smoke") or obj:IsA("Fire") then
                obj.Enabled = false
            end
            if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                obj.Material = Enum.Material.Plastic
                obj.Reflectance = 0
                obj.CastShadow = false
            end
        end)
    end
end

-- Initial wipe
StripTextures()

-- Continuous wipe (Rivals spawns weapons/skins constantly)
workspace.DescendantAdded:Connect(function(obj)
    task.wait() -- wait one frame so object fully loads
    pcall(function()
        if obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceAppearance") then
            obj.Transparency = 1
        end
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Sparkles") then
            obj.Enabled = false
        end
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            obj.Material = Enum.Material.Plastic
            obj.Reflectance = 0
            obj.CastShadow = false
        end
    end)
end)

-- Lighting clean
game:GetService("Lighting").GlobalShadows = false
for _, v in ipairs(game:GetService("Lighting"):GetChildren()) do
    if v:IsA("Sky") or v:IsA("Atmosphere") then v:Destroy() end
end

print("notextures executed")
print("all textures n stuff gone for fps")
