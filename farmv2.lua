-- Speed presets (in seconds)
local speedModes = {
    ["Slow"] = {
        teleportSpeed = 1.5,
        openDelay = 1.5,
        collectDelay = 3,
        scanDelay = 5
    },
    ["Normal"] = {
        teleportSpeed = 0.5,
        openDelay = 0.5,
        collectDelay = 2,
        scanDelay = 3
    },
    ["Fast"] = {
        teleportSpeed = 0.2,
        openDelay = 0.2,
        collectDelay = 1,
        scanDelay = 1.5
    },
    ["Instant"] = {
        teleportSpeed = 0,
        openDelay = 0,
        collectDelay = 0.2,
        scanDelay = 0.5
    }
}

local currentSpeedMode = "Normal"
local farmEnabled = false

-- Create GUI
local gui = Instance.new("ScreenGui")
gui.Parent = game.CoreGui
gui.Name = "BloxFruitsChestFarm"

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0, 220, 0, 180)
frame.Position = UDim2.new(0.5, -110, 0.5, -90)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel")
title.Parent = frame
title.Size = UDim2.new(1, 0, 0, 25)
title.Text = "Auto Chest Farm"
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14

local statusLabel = Instance.new("TextLabel")
statusLabel.Parent = frame
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 0, 30)
statusLabel.Text = "Status: OFF"
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 12

-- Speed mode label
local speedLabel = Instance.new("TextLabel")
speedLabel.Parent = frame
speedLabel.Size = UDim2.new(1, 0, 0, 20)
speedLabel.Position = UDim2.new(0, 0, 0, 50)
speedLabel.Text = "Speed: Normal"
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.new(1, 1, 0)
speedLabel.Font = Enum.Font.SourceSans
speedLabel.TextSize = 12

-- Speed mode buttons
local function createSpeedButton(name, positionY)
    local button = Instance.new("TextButton")
    button.Parent = frame
    button.Size = UDim2.new(0, 45, 0, 20)
    button.Position = UDim2.new(0, positionY, 0, 72)
    button.Text = name
    button.BackgroundColor3 = (name == currentSpeedMode) and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(60, 60, 60)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 10
    button.Name = name .. "Button"
    
    button.MouseButton1Click:Connect(function()
        currentSpeedMode = name
        speedLabel.Text = "Speed: " .. name
        -- Update all button colors
        for _, child in pairs(frame:GetChildren()) do
            if child:IsA("TextButton") and child.Name:find("Button") then
                local modeName = child.Name:gsub("Button", "")
                child.BackgroundColor3 = (modeName == currentSpeedMode) and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(60, 60, 60)
            end
        end
    end)
    
    return button
end

local slowBtn = createSpeedButton("Slow", 5)
local normalBtn = createSpeedButton("Normal", 55)
local fastBtn = createSpeedButton("Fast", 105)
local instantBtn = createSpeedButton("Instant", 155)

-- Toggle button
local toggleButton = Instance.new("TextButton")
toggleButton.Parent = frame
toggleButton.Size = UDim2.new(1, -10, 0, 30)
toggleButton.Position = UDim2.new(0, 5, 0, 100)
toggleButton.Text = "START FARM"
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 14

-- Current chest indicator
local chestLabel = Instance.new("TextLabel")
chestLabel.Parent = frame
chestLabel.Size = UDim2.new(1, 0, 0, 20)
chestLabel.Position = UDim2.new(0, 0, 0, 135)
chestLabel.Text = "Chest: None"
chestLabel.BackgroundTransparency = 1
chestLabel.TextColor3 = Color3.new(1, 0.7, 0)
chestLabel.Font = Enum.Font.SourceSans
chestLabel.TextSize = 11

-- Stats
local statsLabel = Instance.new("TextLabel")
statsLabel.Parent = frame
statsLabel.Size = UDim2.new(1, 0, 0, 20)
statsLabel.Position = UDim2.new(0, 0, 0, 155)
statsLabel.Text = "Opened: 0"
statsLabel.BackgroundTransparency = 1
statsLabel.TextColor3 = Color3.new(0.7, 1, 0.7)
statsLabel.Font = Enum.Font.SourceSans
statsLabel.TextSize = 11

local chestsOpened = 0

-- Chest detection
local chestKeywords = {"chest", "goldenchest", "silverchest", "bronzechest", "treasurechest", "devilfruit"}

local function findNearestChest()
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    local root = character.HumanoidRootPart
    local nearest = nil
    local shortestDistance = math.huge
    
    for _, obj in pairs(workspace:GetDescendants()) do
        local name = string.lower(obj.Name)
        local isChest = false
        for _, keyword in pairs(chestKeywords) do
            if string.find(name, keyword) then
                isChest = true
                break
            end
        end
        
        if isChest then
            local targetPart = nil
            
            if obj:IsA("BasePart") and obj.Transparency < 1 then
                targetPart = obj
            elseif obj:IsA("Model") then
                targetPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            end
            
            if targetPart and targetPart.Parent then
                local distance = (root.Position - targetPart.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearest = targetPart
                end
            end
        end
        
        -- ProximityPrompt on chests
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local parentName = string.lower(obj.Parent.Name)
            for _, keyword in pairs(chestKeywords) do
                if string.find(parentName, keyword) then
                    local chestPart = obj.Parent:FindFirstChildWhichIsA("BasePart")
                    if chestPart then
                        local distance = (root.Position - chestPart.Position).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            nearest = chestPart
                        end
                    end
                    break
                end
            end
        end
    end
    
    return nearest
end

local function teleportToChest(chest)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local root = character.HumanoidRootPart
    local targetPos = chest.Position + Vector3.new(0, 3, 0)
    local mode = speedModes[currentSpeedMode]
    
    if mode.teleportSpeed == 0 then
        -- Instant teleport
        root.CFrame = CFrame.new(targetPos)
    else
        -- Tween teleport with speed from mode
        local tweenInfo = TweenInfo.new(mode.teleportSpeed, Enum.EasingStyle.Linear)
        local tween = tweenService:Create(root, tweenInfo, {CFrame = CFrame.new(targetPos)})
        tween:Play()
        tween.Completed:Wait()
    end
end

local function openChest(chest)
    -- Method 1: ProximityPrompt
    local prompt = nil
    if chest.Parent then
        prompt = chest.Parent:FindFirstChildOfClass("ProximityPrompt")
    end
    if not prompt then
        prompt = chest:FindFirstChildOfClass("ProximityPrompt")
    end
    if prompt and prompt.Enabled then
        fireproximityprompt(prompt)
        return true
    end
    
    -- Method 2: ClickDetector
    local clickDetector = nil
    if chest.Parent then
        clickDetector = chest.Parent:FindFirstChildOfClass("ClickDetector")
    end
    if not clickDetector then
        clickDetector = chest:FindFirstChildOfClass("ClickDetector")
    end
    if clickDetector then
        fireclickdetector(clickDetector)
        return true
    end
    
    -- Method 3: Direct interaction via Touch
    local character = player.Character
    if character then
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            -- Move character precisely onto chest
            humanoidRootPart.CFrame = CFrame.new(chest.Position + Vector3.new(0, 1, 0))
            wait(0.1)
        end
    end
    
    -- Method 4: Virtual click as fallback
    local mousePos = camera and camera:WorldToScreenPoint(chest.Position)
    if mousePos then
        virtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, nil, 0)
        wait(0.05)
        virtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, nil, 0)
    end
    
    return true
end

-- Main farm loop
local function farmLoop()
    while farmEnabled do
        local mode = speedModes[currentSpeedMode]
        local chest = findNearestChest()
        
        if chest then
            local chestName = chest.Parent and chest.Parent.Name or chest.Name
            chestLabel.Text = "Chest: " .. chestName .. " (" .. currentSpeedMode .. ")"
            statusLabel.Text = "Status: Moving..."
            
            teleportToChest(chest)
            wait(mode.openDelay)
            
            statusLabel.Text = "Status: Opening..."
            openChest(chest)
            chestsOpened = chestsOpened + 1
            statsLabel.Text = "Opened: " .. chestsOpened
            
            wait(mode.collectDelay)
        else
            chestLabel.Text = "Chest: Searching..."
            statusLabel.Text = "Status: Scanning map..."
            wait(mode.scanDelay)
        end
    end
end

toggleButton.MouseButton1Click:Connect(function()
    farmEnabled = not farmEnabled
    if farmEnabled then
        toggleButton.Text = "STOP FARM"
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        statusLabel.Text = "Status: Farming!"
        spawn(farmLoop)
    else
        toggleButton.Text = "START FARM"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        statusLabel.Text = "Status: OFF"
        chestLabel.Text = "Chest: None"
    end
end)

player.CharacterAdded:Connect(function()
    if farmEnabled then
        statusLabel.Text = "Status: Respawning..."
        wait(2)
    end
end)