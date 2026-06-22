local Players = game:GetService("Players")
local player = Players.LocalPlayer
local runService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local pathfindingService = game:GetService("PathfindingService")

local gui = Instance.new("ScreenGui")
gui.Parent = game.CoreGui
gui.Name = "BloxFruitsChestFarm"

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0, 220, 0, 120)
frame.Position = UDim2.new(0.5, -110, 0.5, -60)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel")
title.Parent = frame
title.Size = UDim2.new(1, 0, 0, 25)
title.Text = "Auto Chest Farm (Walk)"
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14

local statusLabel = Instance.new("TextLabel")
statusLabel.Parent = frame
statusLabel.Size = UDim2.new(1, 0, 0, 40)
statusLabel.Position = UDim2.new(0, 0, 0, 30)
statusLabel.Text = "Status: OFF"
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 12
statusLabel.TextWrapped = true

local toggleButton = Instance.new("TextButton")
toggleButton.Parent = frame
toggleButton.Size = UDim2.new(1, -10, 0, 30)
toggleButton.Position = UDim2.new(0, 5, 0, 75)
toggleButton.Text = "START FARM"
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 14

local farmEnabled = false
local currentPath = nil
local isMoving = false

-- Chest detection
local chestKeywords = {
    "chest", "goldenchest", "silverchest", "bronzechest", 
    "treasurechest", "devilfruit", "crate", "barrel", "box"
}

local function findAllChests()
    local chests = {}
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return chests end
    
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
            
            -- Also check ProximityPrompt parents
            if obj:IsA("ProximityPrompt") then
                local parentName = string.lower(obj.Parent.Name)
                for _, keyword in pairs(chestKeywords) do
                    if string.find(parentName, keyword) then
                        targetPart = obj.Parent:FindFirstChildWhichIsA("BasePart") or obj.Parent
                        break
                    end
                end
            end
            
            if targetPart and targetPart:IsA("BasePart") then
                table.insert(chests, targetPart)
            end
        end
    end
    return chests
end

local function findNearestChest(chests)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    local root = character.HumanoidRootPart
    
    local nearest = nil
    local shortestDistance = math.huge
    
    for _, chest in pairs(chests) do
        if chest and chest.Parent then
            local distance = (root.Position - chest.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                nearest = chest
            end
        end
    end
    
    return nearest
end

-- Movement using PathfindingService
local function walkTo(targetPosition)
    local character = player.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return false end
    
    -- Increase walkspeed for faster farming
    local originalSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = 50
    
    local path = pathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentMaxSlope = 45,
        WaypointSpacing = 3
    })
    
    local success, errorMessage = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPosition)
    end)
    
    if not success or path.Status ~= Enum.PathStatus.Success then
        humanoid.WalkSpeed = originalSpeed
        return false
    end
    
    local waypoints = path:GetWaypoints()
    isMoving = true
    
    for _, waypoint in pairs(waypoints) do
        if not farmEnabled then break end
        
        -- Check if chest still exists
        local chests = findAllChests()
        local targetStillExists = false
        for _, c in pairs(chests) do
            if (c.Position - targetPosition).Magnitude < 5 then
                targetStillExists = true
                break
            end
        end
        if not targetStillExists then break end
        
        humanoid:MoveTo(waypoint.Position)
        
        -- Wait until close to waypoint or timeout
        local timeout = 0
        while (rootPart.Position - waypoint.Position).Magnitude > 3 and timeout < 5 do
            wait(0.1)
            timeout = timeout + 0.1
            if not farmEnabled then break end
        end
        
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            humanoid.Jump = true
        end
    end
    
    isMoving = false
    humanoid.WalkSpeed = originalSpeed
    return true
end

local function openChest(chest)
    local character = player.Character
    if not character then return false end
    
    -- Face the chest
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        rootPart.CFrame = CFrame.lookAt(rootPart.Position, Vector3.new(chest.Position.X, rootPart.Position.Y, chest.Position.Z))
    end
    
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
        wait(0.5)
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
        wait(0.5)
        return true
    end
    
    -- Method 3: Move close and interact
    if rootPart then
        rootPart.CFrame = CFrame.new(chest.Position + Vector3.new(0, 2, 0))
        wait(0.3)
        -- Try clicking with virtual input
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(0, 0, 0, true, nil, 0)
        wait(0.1)
        vim:SendMouseButtonEvent(0, 0, 0, false, nil, 0)
        wait(0.5)
    end
    
    return true
end

-- Main farm loop
local function farmLoop()
    while farmEnabled do
        statusLabel.Text = "Status: Scanning for chests..."
        local allChests = findAllChests()
        
        if #allChests == 0 then
            statusLabel.Text = "Status: No chests found. Waiting..."
            wait(5)
        else
            statusLabel.Text = "Status: Found " .. #allChests .. " chests. Moving to nearest..."
            
            -- Get nearest unopened chest
            local target = findNearestChest(allChests)
            
            if target then
                local chestPos = target.Position
                statusLabel.Text = "Status: Walking to " .. target.Name .. "..."
                
                local arrived = walkTo(chestPos)
                
                if arrived or (player.Character and player.Character:FindFirstChild("HumanoidRootPart") and (player.Character.HumanoidRootPart.Position - chestPos).Magnitude < 15) then
                    statusLabel.Text = "Status: Opening " .. target.Name .. "..."
                    openChest(target)
                    statusLabel.Text = "Status: Collected! Moving to next..."
                    wait(1)
                else
                    statusLabel.Text = "Status: Could not reach. Skipping..."
                    wait(2)
                end
            end
            
            wait(0.5)
        end
    end
end

toggleButton.MouseButton1Click:Connect(function()
    farmEnabled = not farmEnabled
    if farmEnabled then
        toggleButton.Text = "STOP FARM"
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        statusLabel.Text = "Status: Farm started! Walking mode."
        spawn(farmLoop)
    else
        toggleButton.Text = "START FARM"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        statusLabel.Text = "Status: OFF"
        isMoving = false
    end
end)

-- Cleanup on character death/respawn
player.CharacterAdded:Connect(function()
    local humanoid = player.Character:WaitForChild("Humanoid")
    humanoid.WalkSpeed = 50 -- Keep speed on respawn if farming
end)