--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
-- Delta Executor Anti-Fling Hub Script (Versão Otimizada e Resistente a Bloqueios)

-- =========================================================================
-- Parte 1: Biblioteca da UI (INCORPORADA para evitar erros de carregamento)
-- A maioria das UI libraries usa um padrão similar. Esta é uma versão funcional.
-- =========================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AntiFlingHubUI"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- Garante que a UI se comporta bem com outras GUIs

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 250, 0, 150) -- Tamanho padrão do hub
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 1
MainFrame.BorderColor3 = Color3.fromRGB(20, 20, 20)
-- MainFrame.Draggable = true -- REMOVIDO: Hub não será arrastável
-- Posiciona o hub no centro vertical e encostado no limite direito da tela
-- O '-10' é um pequeno espaçamento da borda
MainFrame.Position = UDim2.new(1, -MainFrame.Size.X.Offset - 10, 0.5, -MainFrame.Size.Y.Offset / 2)
MainFrame.Parent = ScreenGui

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 25)
TitleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -25, 1, 0)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 18
TitleLabel.Text = "Anti-Fling Hub"
TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
TitleLabel.Parent = TitleBar

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 25, 1, 0)
CloseButton.Position = UDim2.new(1, -25, 0, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.TextSize = 18
CloseButton.Text = "X"
CloseButton.Parent = TitleBar

CloseButton.MouseButton1Click:Connect(function()
    -- NOVO COMPORTAMENTO: Destrói a UI e efetivamente para o script
    if _G.positionCheckConnection then
        _G.positionCheckConnection:Disconnect() -- Desconecta a verificação de posição
        _G.positionCheckConnection = nil
    end
    if _G.antiFlingActive and rootPart then
        -- Tenta reverter o NetworkOwner se o anti-fling estava ativo
        pcall(function()
            rootPart:SetNetworkOwner(player)
        end)
    end
    ScreenGui:Destroy() -- Destrói a ScreenGui, removendo o hub
    print("Anti-Fling Hub e Script Desativados Completamente.")
    -- Você pode querer adicionar um 'return' aqui dependendo do executor
    -- para garantir que nenhuma linha de código subsequente seja executada,
    -- mas Destroy já é bem eficaz.
end)

local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, 0, 1, -25)
ContentFrame.Position = UDim2.new(0, 0, 0, 25)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Adiciona um UIListLayout para gerenciar o posicionamento dos toggles automaticamente
local ListLayout = Instance.new("UIListLayout")
ListLayout.Parent = ContentFrame
ListLayout.FillDirection = Enum.FillDirection.Vertical
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.Padding = UDim.new(0, 5) -- Espaçamento entre os itens
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Função simplificada para adicionar um Toggle (alternador)
local function AddToggle(parentFrame, name, defaultValue, callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(0.95, 0, 0, 30) -- Ajustado para caber melhor e ter margem
    ToggleFrame.BackgroundTransparency = 1
    ToggleFrame.Parent = parentFrame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.Position = UDim2.new(0, 5, 0, 0) -- Pequena margem para o texto
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.Font = Enum.Font.SourceSans
    Label.TextSize = 16
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = name
    Label.Parent = ToggleFrame

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 50, 0, 20)
    ToggleButton.Position = UDim2.new(1, -55, 0.5, -10)
    ToggleButton.BackgroundColor3 = defaultValue and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.Font = Enum.Font.SourceSansBold
    ToggleButton.TextSize = 14
    ToggleButton.Text = defaultValue and "ATIVO" or "INATIVO"
    ToggleButton.Parent = ToggleFrame

    local currentValue = defaultValue
    ToggleButton.MouseButton1Click:Connect(function()
        currentValue = not currentValue
        ToggleButton.BackgroundColor3 = currentValue and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
        ToggleButton.Text = currentValue and "ATIVO" or "INATIVO"
        if callback then
            callback(currentValue)
        end
    end)
    return { SetValue = function(value) currentValue = value; ToggleButton.BackgroundColor3 = value and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0); ToggleButton.Text = value and "ATIVO" or "INATIVO" end }
end

-- =========================================================================
-- Parte 2: Lógica Anti-Fling (Otimizada)
-- =========================================================================

-- Usando _G para variáveis chave, pois alguns anti-cheats ignoram _G
_G.antiFlingActive = false
_G.lastPosition = Vector3.new(0, 0, 0)
_G.positionCheckConnection = nil

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait() -- Garante que o personagem existe
local rootPart = character and character:FindFirstChild("HumanoidRootPart")

-- Wait for character and rootPart if they aren't immediately available
if not rootPart then
    player.CharacterAdded:Connect(function(newChar)
        character = newChar
        rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then
            rootPart = character:WaitForChild("HumanoidRootPart")
        end
    end)
    -- If character is already added but rootPart isn't, wait for it
    if character and not rootPart then
        rootPart = character:WaitForChild("HumanoidRootPart")
    end
end


-- Função para verificar a posição e teleportar se necessário
-- Usando _G para a função para tentar evitar detecção
_G.checkPositionAndTeleport = function()
    -- Checagens de segurança adicionais
    if not _G.antiFlingActive or not rootPart or not rootPart.Parent or not rootPart.Parent:IsA("Model") or not rootPart.Parent:FindFirstChild("Humanoid") then
        return
    end

    local currentPosition = rootPart.Position
    local distance = (currentPosition - _G.lastPosition).Magnitude

    -- O 'flingThreshold' é crucial. Ajuste este valor.
    local flingThreshold = 60
    local minMovementForTeleport = 0.5

    if distance > flingThreshold and (currentPosition - _G.lastPosition).Magnitude > minMovementForTeleport then
        local success, err = pcall(function()
            rootPart.CFrame = CFrame.new(_G.lastPosition)
            wait(0.01)
        end)
        if success then
            print("Fling detectado! Personagem teleportado de volta para a posição anterior.")
        else
            warn("Erro ao teleportar: " .. (err or "Desconhecido"))
        end
    end
    _G.lastPosition = currentPosition
end

-- Adiciona o botão de alternância para o recurso Anti-Fling
local AntiFlingToggle = AddToggle(ContentFrame, "Anti-Fling", false, function(state)
    _G.antiFlingActive = state

    if _G.antiFlingActive then
        player = game.Players.LocalPlayer
        character = player.Character or player.CharacterAdded:Wait()
        rootPart = character and character:FindFirstChild("HumanoidRootPart")

        if not rootPart then
            rootPart = character:WaitForChild("HumanoidRootPart")
        end

        if character and character.Parent and rootPart then
            local success, err = pcall(function()
                rootPart:SetNetworkOwner(nil)
            end)
            if success then
                print("Anti-Fling Primário Ativado (Desabilitando NetworkOwner).")
            else
                warn("Falha ao definir NetworkOwner: " .. (err or "Desconhecido"))
            end

            _G.lastPosition = rootPart.Position
            if not _G.positionCheckConnection then
                _G.positionCheckConnection = game:GetService("RunService").Heartbeat:Connect(_G.checkPositionAndTeleport)
                print("Teleporte de Recuperação Ativado (Verificação de Posição).")
            end
        else
            warn("Personagem ou HumanoidRootPart não encontrados. Anti-Fling não pode ser ativado.")
            _G.antiFlingActive = false
            AntiFlingToggle:SetValue(false)
        end
    else
        if rootPart then
            local success, err = pcall(function()
                rootPart:SetNetworkOwner(player)
            end)
            if not success then
                warn("Falha ao reverter NetworkOwner: " .. (err or "Desconhecido"))
            end
        end
        if _G.positionCheckConnection then
            _G.positionCheckConnection:Disconnect()
            _G.positionCheckConnection = nil
            print("Teleporte de Recuperação Desativado.")
        end
        print("Anti-Fling Desativado!")
    end
end)

print("Anti-Fling Hub Script Carregado! (Versão Aprimorada e Posicionada)")

