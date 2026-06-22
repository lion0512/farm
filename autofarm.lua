local Players = game:GetService("Players")
local player = Players.LocalPlayer
local runService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local tweenService = game:GetService("TweenService")

local gui = Instance.new("ScreenGui")
gui.Parent = game.CoreGui
gui.Name = "BloxFruitsChestFarm"

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(0.5, -100, 0.5, -50)
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

local toggleButton = Instance.new("TextButton")
toggleButton.Parent = frame
toggleButton.Size = UDim2.new(1, -10, 0, 30)
toggleButton.Position = UDim2.new(0, 5, 0, 55)
toggleButton.Text = "START FARM"
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 14

local farmEnabled = false
local currentChest = nil

-- Chest detection function (Blox Fruits chests are usually named "Chest" or contain "Chest" in name)
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
        
        if isChest and obj:IsA("BasePart") then
            -- Check if chest is visible and valid (not opened/gone)
            if obj.Transparency < 1 and obj.Parent then
                local distance = (root.Position - obj.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearest = obj
                end
            end
        end
        
        -- Also check for chests as Models
        if isChest and obj:IsA("Model") then
            local primaryPart = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("BasePart") or obj:FindFirstChildWhichIsA("BasePart")
            if primaryPart then
                local distance = (root.Position - primaryPart.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearest = primaryPart
                end
            end
        end
        
        -- Check for ProximityPrompts (chests often have these)
        if obj:IsA("ProximityPrompt") then
            local parentName = string.lower(obj.Parent.Name)
            for _, keyword in pairs(chestKeywords) do
                if string.find(parentName, keyword) then
                    local chestPart = obj.Parent:FindFirstChildWhichIsA("BasePart") or obj.Parent
                    if chestPart and chestPart:IsA("BasePart") then
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

local function teleportTo(part)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local root = character.HumanoidRootPart
    
    -- Calculate position slightly above the chest
    local targetPos = part.Position + Vector3.new(0, 3, 0)
    
    -- Tween teleport for smooth movement
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
    local tween = tweenService:Create(root, tweenInfo, {CFrame = CFrame.new(targetPos)})
    tween:Play()
    tween.Completed:Wait()
end

local function openChest(chest)
    -- Method 1: Fire ProximityPrompt if chest has one
    local prompt = chest.Parent and chest.Parent:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        prompt = chest:FindFirstChildOfClass("ProximityPrompt")
    end
    if prompt then
        fireproximityprompt(prompt)
        return true
    end
    
    -- Method 2: Fire ClickDetector if chest has one
    local clickDetector = chest.Parent and chest.Parent:FindFirstChildOfClass("ClickDetector")
    if not clickDetector then
        clickDetector = chest:FindFirstChildOfClass("ClickDetector")
    end
    if clickDetector then
        fireclickdetector(clickDetector)
        return true
    end
    
    -- Method 3: Simulate click on the part itself (some chests use Touched or MouseClick)
    if chest then
        -- Try firing TouchInterest
        local touchInterest = chest:FindFirstChildOfClass("TouchTransmitter")
        if touchInterest then
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    -- Create a fake touch
                    local fakePart = Instance.new("Part")
                    fakePart.Size = Vector3.new(1, 1, 1)
                    fakePart.Position = chest.Position
                    fakePart.Anchored = true
                    fakePart.CanCollide = false
                    fakePart.Parent = workspace
                    local touchConnection = fakePart.Touched:Connect(function(hit)
                        -- This might trigger chest interaction
                    end)
                    wait(0.5)
                    fakePart:Destroy()
                    return true
                end
            end
        end
    end
    
    return false
end

-- Main farm loop
local function farmLoop()
    while farmEnabled do
        local chest = findNearestChest()
        if chest then
            currentChest = chest
            statusLabel.Text = "Status: Teleporting to chest..."
            teleportTo(chest)
            wait(0.3)
            statusLabel.Text = "Status: Opening chest..."
            local opened = openChest(chest)
            wait(1)
            if opened then
                statusLabel.Text = "Status: Chest opened! Collecting..."
            else
                statusLabel.Text = "Status: Attempting click..."
                -- Fallback: use virtual input to click
                local vim = game:GetService("VirtualInputManager")
                vim:SendMouseButtonEvent(0, 0, 0, true, nil, 0)
                wait(0.1)
                vim:SendMouseButtonEvent(0, 0, 0, false, nil, 0)
            end
            wait(2)
        else
            statusLabel.Text = "Status: No chest found... scanning..."
            wait(3)
        end
    end
end

toggleButton.MouseButton1Click:Connect(function()
    farmEnabled = not farmEnabled
    if farmEnabled then
        toggleButton.Text = "STOP FARM"
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        statusLabel.Text = "Status: Farming started!"
        spawn(farmLoop)
    else
        toggleButton.Text = "START FARM"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        statusLabel.Text = "Status: OFF"
        currentChest = nil
    end
end)

-- Cleanup on character respawn
player.CharacterAdded:Connect(function()
    currentChest = nil
end)